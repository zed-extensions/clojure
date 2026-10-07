(ns outline.fixture
  "One of every outline head."
  (:require [clojure.string :as str]))

(def plain-def 42)

(defonce initialized? (atom false))

(declare forward-reference)

(defn public-fn
  "Docstring."
  [x] x)

(defn- private-fn [y] y)

(defmacro simple-macro [& body] `(do ~@body))

(defmulti dispatch :type)

(defmethod dispatch :circle
  [shape] :circle-drawn)

(defmulti area :shape)

(defmethod area :multi-arity
  ([s] s)
  ([s _] s))

(deftest ^:integration meta-test
  (is true))

(defprotocol Shape
  (area [shape] "Area of the shape.")
  (perimeter [shape]))

(defrecord Point [x y]
  Shape
  (area [this] 0)
  (perimeter [this] 0))

(deftype Vec2 [dx dy]
  Shape
  (area [this] 0)
  (perimeter [this] 0))

(definterface IWidget
  (render [widget]))

(deftest addition-test
  (is (= 2 (+ 1 1))))

(s/def ::pos-int (s/and int? pos?))

(s/fdef area-fn
  :args (s/cat :shape any?))

(m/=> typed-fn [:=> :cat int?])

(comment
  (defn rich-comment-fn [] :rich)
  (+ 1 2))
