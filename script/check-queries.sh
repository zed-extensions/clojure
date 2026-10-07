#!/usr/bin/env bash
# Compile the pinned tree-sitter-clojure grammar and run every query
# file against every fixture. Fails on any query error (unknown node
# types are the common failure after a grammar bump).
#
# Usage: script/check-queries.sh
# Requires: git, a C compiler, tree-sitter-cli >= 0.25.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
grammar_dir="${TREE_SITTER_CLOJURE_DIR:-$root/../tree-sitter-clojure}"
commit="$(grep -A2 '\[grammars.clojure\]' "$root/extension.toml" | grep commit | cut -d'"' -f2)"

if [ ! -d "$grammar_dir" ]; then
  git clone --quiet https://github.com/sogaiu/tree-sitter-clojure "$grammar_dir"
fi
git -C "$grammar_dir" fetch --quiet origin
git -C "$grammar_dir" checkout --quiet "$commit"

lib="$grammar_dir/tree-sitter-clojure.so"
echo "Building grammar at $(git -C "$grammar_dir" rev-parse --short HEAD)"
tree-sitter build -o "$lib" "$grammar_dir"

fail=0
for query in "$root"/languages/clojure/*.scm; do
  for fixture in "$root"/test/fixtures/*; do
    if ! out=$(tree-sitter query --lib-path "$lib" --lang-name clojure "$query" "$fixture" 2>&1); then
      echo "FAIL: $(basename "$query") × $(basename "$fixture")"
      echo "$out" | head -5
      fail=1
    fi
  done
  echo "ok: $(basename "$query")"
done

# A query can parse cleanly and still match nothing, so require at
# least one capture for a designated query × fixture pair.
sanity='brackets.scm outline.clj
highlights.scm syntax_test.cljc
indents.scm indent.clj
injections.scm syntax_test.cljc
outline.scm outline.clj
overrides.scm edn_sample.edn
runnables.scm outline.clj
textobjects.scm outline.clj'
while read -r query fixture; do
  if [ -z "$(tree-sitter query --lib-path "$lib" --lang-name clojure \
      "$root/languages/clojure/$query" "$root/test/fixtures/$fixture")" ]; then
    echo "FAIL: $query matched nothing in $fixture"
    fail=1
  else
    echo "matched: $query × $fixture"
  fi
done <<<"$sanity"

exit $fail
