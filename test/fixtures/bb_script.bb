#!/usr/bin/env bb

;; Babashka script: shebang + .bb suffix exercise path_suffixes.

(require '[babashka.process :refer [shell]])

(defn greet
  [name]
  (println (str "Hello, " name "!")))

(greet "bb")

(comment
  (greet "from rich comment"))
