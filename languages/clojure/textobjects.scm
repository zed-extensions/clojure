;; Functions: defn-style forms and anonymous #(...) literals.
;; inside = body without the head symbol and parens.

(list_lit
  .
  (sym_lit
    (sym_name) @_fn-head)
  .
  (_)* @function.inside
  (#any-of? @_fn-head "defn" "defn-" "defmacro" "definline" "fn" "fn*")) @function.around

(anon_fn_lit
  value: (_)* @function.inside) @function.around

;; Classes: namespace and type/protocol definitions

(list_lit
  .
  (sym_lit
    (sym_name) @_class-head)
  .
  (_)* @class.inside
  (#any-of? @_class-head
    "ns" "defprotocol" "defrecord" "deftype" "definterface")) @class.around

;; Comments: line comments, discarded forms and (comment ...) blocks

(comment)+ @comment.around

(dis_expr) @comment.around

(list_lit
  .
  (sym_lit
    (sym_name) @_comment-head)
  (#eq? @_comment-head "comment")) @comment.around
