;; Indent fixture: Zed indents line-relative +2 while typing;
;; cljfmt (via clojure-lsp on save) reflows vectors/maps to +1 from
;; the bracket. Both behaviors are intentional — see docs/formatting.md.

(ns indent.fixture
  (:require [clojure.string :as str]))

(let [a 1
      b 2]
  (when a
    (println b)))

(defn wide-fn
  [argument-one argument-two]
  (-> argument-one
      (str/replace "x" "y")
      (str/split #",")))

(def example-map
  {:first-key  :first-value
   :second-key :second-value})
