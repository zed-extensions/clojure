# Zed Clojure

A [Clojure](https://clojure.org/) extension for [Zed](https://zed.dev), with
`clojure-lsp` integration, syntax-aware runnable forms, and an optional nREPL
evaluation workflow.

## Language support

The extension recognizes Clojure, ClojureScript, Clojure Common, ClojureDart,
EDN, Babashka, and `.repl` output files. It installs `clojure-lsp`
automatically when the executable is not already available on `PATH`.

## Evaluate a form through nREPL

The extension marks each top-level Clojure form as a runnable and associates it
with the `Clojure: Evaluate form` task. Direct forms inside a top-level
`(comment ...)` are independently runnable instead of evaluating the entire
comment block. The task sends the complete form to an nREPL server and writes
its output to `.zed/repl.repl`, with the newest evaluation at the top.

Place runnable comment-body forms on separate lines because Zed indexes
runnables by their starting row.

JVM Clojure works through normal nREPL discovery. Configured targets and
per-connection setup code can route ClojureScript forms through middleware such
as shadow-cljs.

### Install the evaluator

Install [Babashka](https://babashka.org/) and
[bbin](https://github.com/babashka/bbin), then install the standalone
evaluator:

```sh
bbin install https://github.com/JJ-Atkinson/zed-clojure-eval.git --latest-sha
```

This installs `zed-clojure-eval` into the bbin executable directory, normally
`~/.local/bin`. Ensure that directory is on the environment `PATH` inherited by
Zed.

### Start nREPL

Start a JVM nREPL server that writes its port to `.nrepl-port` in the project
root. For example, projects with an nREPL dependency can run:

```sh
clojure -M:nrepl
```

The evaluator searches for `.nrepl-port` in the source file's ancestors. These
environment variables can override discovery:

| Variable | Purpose |
| --- | --- |
| `ZED_CLOJURE_NREPL_HOST` | nREPL host; defaults to `127.0.0.1` |
| `ZED_CLOJURE_NREPL_PORT` | nREPL port |
| `ZED_CLOJURE_NREPL_PORT_FILE` | explicit port-file path |
| `ZED_CLOJURE_OUTPUT_FILE` | output path; defaults to `.zed/repl.repl` beside the port file |
| `ZED_CLOJURE_CONFIG` | explicit REPL configuration path |

### Add an evaluation keybinding

Add this to your Zed keymap:

```json
[
  {
    "context": "Editor && (extension == clj || extension == cljs || extension == cljc || extension == cljd || extension == edn || extension == bb)",
    "bindings": {
      "ctrl-enter": [
        "editor::SpawnNearestTask",
        { "reveal": "never" }
      ]
    }
  }
]
```

Open `.zed/repl.repl` in a split once, then place the cursor in a top-level form
and use the keybinding. Evaluation does not open or focus the task terminal.
Successful task terminals are removed automatically. After a failure, use
<kbd>Ctrl</kbd>+<kbd>`</kbd> or `terminal_panel::Toggle` to inspect the retained
task terminal.

Before evaluating a non-`ns` form, the evaluator evaluates the source file's
`ns` declaration so its aliases, refers, and imports are available.

Consider ignoring `.zed/repl.repl*` in the project: the evaluator also keeps a
small lock file beside the output to serialize simultaneous evaluations.

### Configure the evaluator

Targets, snippets, persistent state, formatting, status rendering, and output
behavior are configured by the standalone
[`zed-clojure-eval`](https://github.com/JJ-Atkinson/zed-clojure-eval)
package. Its README documents the complete EDN configuration and environment
variable interfaces.

## Structural editing with clojure-lsp

Zed versions that provide the parameterized `editor::ExecuteLspCommand` action
can bind structural editing commands directly. For example:

```json
[
  {
    "context": "Editor && (extension == clj || extension == cljc || extension == cljs || extension == bb)",
    "bindings": {
      "ctrl-alt-right": [
        "editor::ExecuteLspCommand",
        {
          "server": "clojure-lsp",
          "command": "forward-slurp",
          "arguments": ["$uri", "$line", "$column"]
        }
      ],
      "ctrl-alt-left": [
        "editor::ExecuteLspCommand",
        {
          "server": "clojure-lsp",
          "command": "forward-barf",
          "arguments": ["$uri", "$line", "$column"]
        }
      ]
    }
  }
]
```

Other available `clojure-lsp` structural commands include `backward-slurp`,
`backward-barf`, `drag-backward`, `drag-forward`, `raise-sexp`, `kill-sexp`,
`forward`, `backward`, `forward-select`, and `backward-select`.

## Development

Install this repository through `zed: Install Dev Extension`. After changing
Rust code, language configuration, tasks, or Tree-sitter queries, run
`zed: Rebuild Dev Extension`.

Useful checks:

```sh
cargo fmt --check
cargo build --target wasm32-wasip2
cargo clippy --target wasm32-wasip2 -- -D warnings
```

See [Developing Extensions](https://zed.dev/docs/extensions/developing-extensions)
for the complete extension development workflow.
