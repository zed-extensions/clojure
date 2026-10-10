(
  (source
    [
      (num_lit)
      (kwd_lit)
      (str_lit)
      (char_lit)
      (nil_lit)
      (bool_lit)
      (sym_lit)
      (list_lit)
      (map_lit)
      (vec_lit)
      (set_lit)
      (anon_fn_lit)
      (regex_lit)
      (read_cond_lit)
      (splicing_read_cond_lit)
      (ns_map_lit)
      (var_quoting_lit)
      (sym_val_lit)
      (evaling_lit)
      (tagged_or_ctor_lit)
      (derefing_lit)
      (quoting_lit)
      (syn_quoting_lit)
      (unquote_splicing_lit)
      (unquoting_lit)
    ] @run @form)
  (#not-match? @form "^((\\^|#\\^)([^\\s,{]+|\\{[^}]*\\})[\\s,]+)*\\([\\s,]*(clojure\\.core/)?comment([\\s,]|\\))")
  (#set! tag clojure-eval)
)

(
  (source
    (list_lit
      meta: [
        (meta_lit)
        (old_meta_lit)
      ]*
      .
      value: (sym_lit) @_comment
      value: (_) @run @form))
  (#match? @_comment "^(clojure\\.core/)?comment$")
  (#set! tag clojure-eval)
)
