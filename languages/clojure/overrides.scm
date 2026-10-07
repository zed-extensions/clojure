;; Scopes where editing behaves differently from plain code; see the
;; [overrides.*] tables and bracket not_in in config.toml. Discarded
;; forms are omitted: they are still ordinary code you edit.

[
  (str_lit)
  (regex_lit)
] @string

(comment) @comment.inclusive
