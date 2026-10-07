use std::{collections::HashMap, fs};
use zed_extension_api::{self as zed, LanguageServerId, Result};

struct ToolSpec {
    repo: &'static str,
    binary: &'static str,
    asset_prefix: &'static str,
}

impl ToolSpec {
    fn is_outdated_version(&self, name: &str, current_version: &str) -> bool {
        name.starts_with(&format!("{}-", self.binary)) && name != current_version
    }
}

struct ClojureExtension {
    cached_binary_paths: HashMap<String, String>,
}

impl ClojureExtension {
    fn language_server_binary_path(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
        tool: ToolSpec,
    ) -> Result<String> {
        if let Some(path) = worktree.which(tool.binary) {
            return Ok(path);
        }

        if let Some(path) = self.cached_binary_paths.get(language_server_id.as_ref()) {
            if fs::metadata(path).is_ok_and(|stat| stat.is_file()) {
                return Ok(path.clone());
            }
        }

        zed::set_language_server_installation_status(
            language_server_id,
            &zed::LanguageServerInstallationStatus::CheckingForUpdate,
        );
        let release = zed::latest_github_release(
            tool.repo,
            zed::GithubReleaseOptions {
                require_assets: true,
                pre_release: false,
            },
        )?;

        let (platform, arch) = zed::current_platform();
        let asset_prefix = if tool.binary == "clj-kondo" {
            format!(
                "{}-{}",
                tool.asset_prefix,
                release.version.trim_start_matches('v')
            )
        } else {
            tool.asset_prefix.to_string()
        };
        let asset_name = format!(
            "{asset_prefix}-{os}-{arch}.zip",
            os = match platform {
                zed::Os::Mac => "macos",
                zed::Os::Linux => "linux",
                zed::Os::Windows => "windows",
            },
            arch = match arch {
                zed::Architecture::Aarch64 => "aarch64",
                zed::Architecture::X8664 => "amd64",
                zed::Architecture::X86 =>
                    return Err(format!("unsupported architecture: {arch:?}")),
            },
        );

        let asset = release
            .assets
            .iter()
            .find(|asset| asset.name == asset_name)
            .ok_or_else(|| format!("no asset found matching {asset_name:?}"))?;

        let tool_prefix = format!("{}-", tool.binary);
        let version_dir = format!("{tool_prefix}{}", release.version);
        let binary_path = format!(
            "{version_dir}/{}{suffix}",
            tool.binary,
            suffix = if platform == zed::Os::Windows {
                ".exe"
            } else {
                ""
            },
        );

        if !fs::metadata(&binary_path).is_ok_and(|stat| stat.is_file()) {
            zed::set_language_server_installation_status(
                language_server_id,
                &zed::LanguageServerInstallationStatus::Downloading,
            );

            zed::download_file(
                &asset.download_url,
                &version_dir,
                zed::DownloadedFileType::Zip,
            )
            .map_err(|e| format!("failed to download file: {e}"))?;

            zed::make_file_executable(&binary_path)?;

            let entries =
                fs::read_dir(".").map_err(|e| format!("failed to list working directory {e}"))?;
            for entry in entries {
                let entry = entry.map_err(|e| format!("failed to load directory entry {e}"))?;
                if entry.file_type().is_ok_and(|kind| kind.is_dir())
                    && entry
                        .file_name()
                        .to_str()
                        .is_some_and(|name| tool.is_outdated_version(name, &version_dir))
                {
                    fs::remove_dir_all(entry.path()).ok();
                }
            }
        }

        self.cached_binary_paths
            .insert(language_server_id.as_ref().to_string(), binary_path.clone());
        Ok(binary_path)
    }
}

impl zed::Extension for ClojureExtension {
    fn new() -> Self {
        Self {
            cached_binary_paths: HashMap::new(),
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let (tool, mut args) = match language_server_id.as_ref() {
            "clojure-lsp" => (
                ToolSpec {
                    repo: "clojure-lsp/clojure-lsp",
                    binary: "clojure-lsp",
                    asset_prefix: "clojure-lsp-native",
                },
                Vec::new(),
            ),
            "clj-kondo" => (
                ToolSpec {
                    repo: "clj-kondo/clj-kondo",
                    binary: "clj-kondo",
                    asset_prefix: "clj-kondo",
                },
                vec!["--lsp".to_string()],
            ),
            id => return Err(format!("unsupported language server: {id}")),
        };

        // An explicitly configured binary wins over PATH and downloads.
        // The tool's own args (e.g. clj-kondo's --lsp) stay in front.
        if let Some(binary) =
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?
                .binary
        {
            if let Some(path) = binary.path {
                args.extend(binary.arguments.unwrap_or_default());
                return Ok(zed::Command {
                    command: path,
                    args,
                    env: binary.env.unwrap_or_default().into_iter().collect(),
                });
            }
        }

        Ok(zed::Command {
            command: self.language_server_binary_path(language_server_id, worktree, tool)?,
            args,
            env: Default::default(),
        })
    }

    fn language_server_initialization_options(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        let settings =
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        Ok(settings.initialization_options)
    }

    fn language_server_workspace_configuration(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        let settings =
            zed::settings::LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        Ok(settings.settings)
    }

    fn label_for_completion(
        &self,
        _language_server_id: &LanguageServerId,
        completion: zed::lsp::Completion,
    ) -> Option<zed::CodeLabel> {
        let mut spans = vec![zed::CodeLabelSpan::literal(&completion.label, None)];
        if let Some(detail) = completion.detail {
            spans.push(zed::CodeLabelSpan::literal(
                format!(" {detail}"),
                Some("comment".to_string()),
            ));
        }
        Some(zed::CodeLabel {
            code: completion.label.clone(),
            spans,
            filter_range: (0..completion.label.len()).into(),
        })
    }
}

zed::register_extension!(ClojureExtension);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cleanup_preserves_other_tools_and_current_version() {
        for (binary, other) in [("clojure-lsp", "clj-kondo"), ("clj-kondo", "clojure-lsp")] {
            let tool = ToolSpec {
                repo: "",
                binary,
                asset_prefix: "",
            };
            let current = format!("{binary}-new");
            assert!(tool.is_outdated_version(&format!("{binary}-old"), &current));
            assert!(!tool.is_outdated_version(&current, &current));
            assert!(!tool.is_outdated_version(&format!("{other}-old"), &current));
            assert!(!tool.is_outdated_version("unrelated", &current));
        }
    }
}
