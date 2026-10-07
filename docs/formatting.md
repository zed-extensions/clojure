# Formatting

Formatting runs through [clojure-lsp]'s `textDocument/formatting`, which
uses [cljfmt] internally and reads the project's cljfmt configuration.
The extension ships no formatting code; this page is the recipe.

[clojure-lsp]: https://clojure-lsp.io
[cljfmt]: https://github.com/weavejester/cljfmt

## 1. Project config: `.cljfmt.edn`

By default clojure-lsp looks for `.cljfmt.edn` in the project root (no
parent-directory walk, unlike the cljfmt CLI). The recommended starting
point is Tonsky's [Better Clojure Formatting]:

```clojure
{:indents {#re ".*" [[:inner 0]]}
 :remove-surrounding-whitespace?  false
 :remove-trailing-whitespace?     false
 :remove-consecutive-blank-lines? false}
```

The extension ships this as a snippet (`cljfmt-tonsky` in a `.cljfmt.edn`
buffer) so you can drop it in without leaving Zed.

If your file is named differently, point clojure-lsp at it in
`.lsp/config.edn`:

```clojure
{:cljfmt-config-path "cljfmt.edn"}
```

`.lsp/config.edn` is read from the project root by clojure-lsp itself;
use Zed settings (below) only for per-user overrides.

[Better Clojure Formatting]: https://tonsky.me/blog/clojurefmt/

## 2. Zed settings

In `settings.json`:

```json
{
  "languages": {
    "Clojure": {
      "format_on_save": "on",
      "formatter": "language_server"
    }
  }
}
```

## 3. What to expect while typing

Zed's indentation engine is line-relative: it can only indent a new line
one level (2 spaces) past a reference line, never align to an open
bracket column. So while you type, Zed approximates the "always +2"
style:

```clojure
(let [a 1
  b 2]   ; Zed's typing-time indent
  ...)
```

On save, cljfmt reflows to the real rules (vectors align to the bracket
column +1 under the default config, or follow your `:indents`):

```clojure
(let [a 1
      b 2]
  ...)
```

This typing-vs-save split is intentional. If the reflow on save bothers
you, the alternative is running cljfmt as an external formatter with the
same config file — same result, still only on save:

```json
"Clojure": {"formatter": {"external": {"command": "cljfmt", "arguments": ["fix", "-"]}}}
```

## Verifying

1. Paste a badly indented `(let [a 1 b 2] (when a (println b)))` across
   lines, save, and confirm it reflows.
2. Compare against the CLI on the same file — output must be identical:

   ```sh
   cljfmt fix --dry-run file.clj
   ```

3. Range formatting (`editor: select format` / format selections) works;
   clojure-lsp advertises `rangeFormattingProvider`.
