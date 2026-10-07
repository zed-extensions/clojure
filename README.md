# Zed Clojure

A [Clojure](https://clojure.org/) extension for [Zed](https://zed.dev):
tree-sitter syntax that understands `#_`, `(comment …)`, metadata and
quoting; a rich outline; form-aware text objects; [clojure-lsp] as the
default language server; [clj-kondo] as an optional lint-only server.

[clojure-lsp]: https://clojure-lsp.io
[clj-kondo]: https://github.com/clj-kondo/clj-kondo

## Language servers

`clojure-lsp` runs by default. clj-kondo's server is opt-in (it lints
only — no code actions, no formatting) because clojure-lsp already
embeds clj-kondo and running both duplicates diagnostics. Both binaries
are resolved in this order:

1. `lsp.<name>.binary.path` from your Zed settings, if set
2. `clojure-lsp` / `clj-kondo` found on the worktree's `PATH`
3. Latest GitHub release, downloaded and cached in the extension's work
   directory

To use clj-kondo instead of clojure-lsp:

```json
"languages": {
  "Clojure": {
    "language_servers": ["clj-kondo", "!clojure-lsp"]
  }
}
```

Per-user server settings pass through to the server (clojure-lsp also
reads `.lsp/config.edn` from the project root on its own):

```json
"lsp": {
  "clojure-lsp": {
    "initialization_options": { "cljfmt-config-path": "cljfmt.edn" }
  }
}
```

## What clojure-lsp gives you in Zed

| Feature | How |
| --- | --- |
| Go to definition / references / rename | `editor: go to definition`, `find all references`, `rename` — works cross-file |
| Hover docs, signature help | hover, `editor: show signature help` |
| Completion | ns-qualified candidates with polished labels |
| Code actions | `editor: toggle code actions` — clean-ns, move to let, extract function, thread/unwind, cycle coll, add missing require |
| Diagnostics (clj-kondo inside clojure-lsp) | problems panel, inline |
| Format / range format | cljfmt via clojure-lsp — see [docs/formatting.md](docs/formatting.md) |
| Workspace symbols | project symbols |

Not surfaced by Zed (known gaps): code lens reference counts, semantic
tokens (tree-sitter queries carry highlighting), call hierarchy. The
REPL is out of scope for this extension; `kernel_language_names` is set
so a future Clojure kernel can attach.

## Syntax highlighting

The query set is ported from [Clojure Sublimed]'s scope decisions and
covers: discarded forms (`#_`, including stacked), rich `(comment …)`
blocks (inner forms keep their colors), metadata (`^:kw`, `^{…}`),
quoting/syntax-quote/unquote markers, regex literals, namespaced
keywords and symbols, `def*` names, special forms and core macros,
reader conditionals (`#?`/`#?@` with `:clj`/`:cljs` branch keys), tagged
literals (`#inst`, `#uuid`), var-quote and deref.

[Clojure Sublimed]: https://github.com/tonsky/Clojure-Sublimed

## Outline

`ns`, `def`, `defonce`, `declare`, `defn`, `defn-` (tagged private),
`defmacro`, `defmulti`, `defmethod` (name + dispatch value, multi-arity
bodies included), `deftest` (metadata excluded from the label),
`defprotocol`, `defrecord`, `deftype`, `definterface`, `s/def`, `s/fdef`,
`m/=>`, method signatures nested in protocol/record/interface forms, and
top-level `(comment …)` blocks.

## Text objects (Vim mode)

`af`/`if` on `defn`-style forms and anonymous `#(…)`, `ac`/`ic` on `ns`,
protocol, record and type forms, `gc` on comments, discarded forms and
`(comment …)` blocks. For arbitrary form navigation, `editor: select
larger/smaller syntax node` is the closest thing to slurp/barf —
structural editing is not possible from an extension.

## Running tests

`deftest` forms get a ▶ in the gutter (tag `clojure-test`; the name is
exposed as `$ZED_CUSTOM_test_name`, and `$ZED_RUNNABLE_SYMBOL` is set
when spawned from the gutter). Wire it to a task template in your
settings, e.g. for Kaocha:

```json
"task": {
  "templates": [
    {
      "label": "clojure: run test",
      "command": "clojure -M:test -v $ZED_CUSTOM_test_name",
      "tags": ["clojure-test"]
    }
  ]
}
```

The namespace is omitted on purpose — derive it from the file or add
`-n $(sed 's|/|.|g; s|\.clj.$||' <<< $ZED_FILE)` if your runner needs it.

## Development

To develop this extension, see the [Developing Extensions](https://zed.dev/docs/extensions/developing-extensions)
section of the Zed docs. Useful extras:

- `script/check-queries.sh` compiles the pinned
  [sogaiu/tree-sitter-clojure](https://github.com/sogaiu/tree-sitter-clojure)
  grammar and runs every query in `languages/clojure/` against every
  fixture in `test/fixtures/`. It is also a CI job.
- `test/fixtures/syntax_test.cljc` is copied from Clojure Sublimed's
  test suite and is the most complete reader-syntax torture file
  available.

### Manual smoke list

1. Open `test/fixtures/syntax_test.cljc` — check `#_`, stacked `#_#_`,
   `(comment …)`, metadata, reader conditionals, tagged literals.
2. Open `test/fixtures/outline.clj` — toggle the outline panel; every
   def-family head appears, including nested protocol methods.
3. On a `defn`, `editor: select larger syntax node` grows through
   symbol → vector → form.
4. Hover, then go-to-definition across two files.
5. Format-on-save on `test/fixtures/indent.clj` (needs a project with
   clojure-lsp and `.cljfmt.edn` — see [docs/formatting.md](docs/formatting.md)).
6. The clj-kondo-only profile from the settings above.
