(list_lit
    (sym_lit name: (sym_name) @symbol) @context
    (#any-of? @symbol "declare" "def" "defmethod" "defmulti" "defn" "defn-" "defprotocol" "defrecord" "ns")
    . _ @name
    ((_)*)) @item
