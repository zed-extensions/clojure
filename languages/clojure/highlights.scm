;; Literals

(num_lit) @number

(char_lit) @string.special

(str_lit) @string

(regex_lit) @string.regex

[
  (bool_lit)
  (nil_lit)
] @constant.builtin

;; Keywords and symbols: color the namespace part separately.

(kwd_lit) @constant
(kwd_lit
  (kwd_ns) @namespace)

(sym_lit
  (sym_ns) @namespace)

;; Function and macro calls

(list_lit
  .
  (sym_lit) @function)

;; Definition names

(list_lit
  .
  (sym_lit
    (sym_name) @_def-head)
  .
  (sym_lit) @function.definition
  (#any-of? @_def-head
    "defn" "defn-" "definline" "defmacro" "defmulti" "defmethod" "deftest"))

(list_lit
  .
  (sym_lit
    (sym_name) @_type-head)
  .
  (sym_lit) @type
  (#any-of? @_type-head "defprotocol" "defrecord" "deftype" "definterface"))

(list_lit
  .
  (sym_lit
    (sym_name) @_def-head)
  .
  (sym_lit) @variable
  (#any-of? @_def-head "def" "defonce" "declare"))

;; Special forms and core macros

(list_lit
  .
  (sym_lit
    (sym_name) @_special) @keyword
  (#any-of? @_special
    "def" "defn" "defn-" "definline" "defmacro" "defmulti" "defmethod"
    "deftest" "defprotocol" "defrecord" "deftype" "definterface" "declare"
    "ns" "require" "import" "refer" "use" "in-ns"
    "fn" "fn*" "letfn" "let" "loop" "loop*" "recur" "binding" "with-open"
    "with-redefs" "with-local-vars" "dosync" "doto" "locking"
    "if" "if-let" "if-not" "if-some" "when" "when-let" "when-not" "when-some"
    "when-first" "cond" "condp" "case" "cond->" "cond->>"
    "->" "->>" "as->" "some->" "some->>"
    "var" "set!" "new" "quote"
    "throw" "try" "catch" "finally"
    "is" "testing" "are"))

;; Quoting, deref, evaluation and reader macros.
;; Capture the markers only; the quoted form keeps its own scopes.

[
  "'"
  "`"
  "~"
  "~@"
  "@"
  "#="
] @operator

(var_quoting_lit) @variable.special

(meta_lit) @attribute
(old_meta_lit) @attribute

[
  "#?"
  "#?@"
] @preproc

(read_cond_lit
  (kwd_lit
    (kwd_name) @label
    (#any-of? @label "clj" "cljs" "cljc" "bb" "default" "nodejs" "lumo" "graalvm" "native")))

(splicing_read_cond_lit
  (kwd_lit
    (kwd_name) @label
    (#any-of? @label "clj" "cljs" "cljc" "bb" "default" "nodejs" "lumo" "graalvm" "native")))

(tagged_or_ctor_lit
  tag: (sym_lit) @tag)

;; Brackets

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

;; Comments and discarded forms last, so they override inner captures.

(comment) @comment

(dis_expr) @comment

(list_lit
  .
  (sym_lit
    (sym_name) @_comment-head) @comment.doc
  (#eq? @_comment-head "comment")) @comment.doc
