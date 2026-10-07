;; deftest forms: run button on the test name.
;; The tag matches a user-defined task template (see README). The
;; test_name capture is exposed as $ZED_CUSTOM_test_name.

((list_lit
  .
  (sym_lit
    (sym_name) @_deftest)
  .
  (sym_lit
    (sym_name) @run @test_name)
  (#eq? @_deftest "deftest")) @_
  (#set! tag clojure-test))
