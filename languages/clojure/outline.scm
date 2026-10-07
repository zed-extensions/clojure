;; ns form

(list_lit
  .
  (sym_lit
    (sym_name) @_ns) @context
  .
  (sym_lit
    (sym_name) @name)
  (#eq? @_ns "ns")) @item

;; def-family: the name is the symbol (or keyword, for s/def) after the
;; head. defn- lives only in the private pattern below to avoid
;; duplicate items. Bare "def" also covers ns-qualified s/def, whose
;; name is a keyword.

(list_lit
  .
  (sym_lit
    (sym_name) @_def-head) @context
  .
  [
    (sym_lit
      (sym_name) @name)
    (kwd_lit) @name
  ]
  (#any-of? @_def-head
    "def" "defonce" "declare" "defn" "definline" "defmacro"
    "defmulti" "deftest" "defprotocol" "defrecord" "deftype"
    "definterface")) @item

;; Specifier forms whose bare heads are too generic (fdef, malli =>):
;; require a namespace on the head.

(list_lit
  .
  (sym_lit
    (sym_ns)
    (sym_name) @_spec-head) @context
  .
  [
    (sym_lit
      (sym_name) @name)
    (kwd_lit) @name
  ]
  (#any-of? @_spec-head "fdef" "=>")) @item

;; defmethod: name plus dispatch value

(list_lit
  .
  (sym_lit
    (sym_name) @_defmethod) @context
  .
  (sym_lit
    (sym_name) @name)
  .
  (_) @name
  (#eq? @_defmethod "defmethod")) @item

;; Method signatures nested in defprotocol/defrecord/deftype/definterface.
;; The item is the method form only; nesting under the type's own item
;; comes from range containment, and the type name stays out of this
;; match so labels don't concatenate.

(list_lit
  .
  (sym_lit
    (sym_name) @_def-type) @context
  (list_lit
    .
    (sym_lit
      (sym_name) @name)
    .
    (vec_lit)) @item
  (#any-of? @_def-type "defprotocol" "defrecord" "deftype" "definterface"))

;; Top-level rich comment blocks only

(source
  (list_lit
    .
    (sym_lit
      (sym_name) @_comment) @name
    (#eq? @_comment "comment")) @item)

;; Private vars: defn- gets an extra context marker

(list_lit
  .
  (sym_lit
    (sym_name) @_private) @context.extra
  .
  (sym_lit
    (sym_name) @name)
  (#eq? @_private "defn-")) @item
