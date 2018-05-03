(module
  (func $f1 (export "eqref") (param $x eqref) (result i32)
    (ref.isnull (get_local $x))
  )
  (func $f2 (export "anyref") (param $x anyref) (result i32)
    (ref.isnull (get_local $x))
  )
  (func $f3 (export "anyfunc") (param $x anyfunc) (result i32)
    (ref.isnull (get_local $x))
  )

  (table $t1 2 eqref)
  (table $t2 2 anyref)
  (table $t3 2 anyfunc) (elem $t3 (i32.const 1) $dummy)
  (func $dummy)

  (func (export "init") (param $r eqref)
    (table.set $t1 (i32.const 1) (get_local $r))
    (table.set $t2 (i32.const 1) (get_local $r))
  )
  (func (export "deinit")
    (table.set $t1 (i32.const 1) (ref.null))
    (table.set $t2 (i32.const 1) (ref.null))
    (table.set $t3 (i32.const 1) (ref.null))
  )

  (func (export "eqref-elem") (param $x i32) (result i32)
    (call $f1 (table.get $t1 (get_local $x)))
  )
  (func (export "anyref-elem") (param $x i32) (result i32)
    (call $f2 (table.get $t2 (get_local $x)))
  )
  (func (export "anyfunc-elem") (param $x i32) (result i32)
    (call $f3 (table.get $t3 (get_local $x)))
  )
)

(assert_return (invoke "eqref" (ref.null)) (i32.const 1))
(assert_return (invoke "anyref" (ref.null)) (i32.const 1))
(assert_return (invoke "anyfunc" (ref.null)) (i32.const 1))

(assert_return (invoke "eqref" (ref.host 1)) (i32.const 0))
(assert_return (invoke "anyref" (ref.host 1)) (i32.const 0))
(assert_return (invoke "anyfunc" (ref.host 1)) (i32.const 0))

(invoke "init" (ref.host 0))

(assert_return (invoke "eqref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "anyref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "anyfunc-elem" (i32.const 0)) (i32.const 1))

(assert_return (invoke "eqref-elem" (i32.const 1)) (i32.const 0))
(assert_return (invoke "anyref-elem" (i32.const 1)) (i32.const 0))
(assert_return (invoke "anyfunc-elem" (i32.const 1)) (i32.const 0))

(invoke "deinit")

(assert_return (invoke "eqref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "anyref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "anyfunc-elem" (i32.const 0)) (i32.const 1))

(assert_return (invoke "eqref-elem" (i32.const 1)) (i32.const 1))
(assert_return (invoke "anyref-elem" (i32.const 1)) (i32.const 1))
(assert_return (invoke "anyfunc-elem" (i32.const 1)) (i32.const 1))
