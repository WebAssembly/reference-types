(module
  (func $f1 (export "anyref") (param $x anyref) (result i32)
    (ref.is_null (local.get $x))
  )
  (func $f2 (export "funcref") (param $x funcref) (result i32)
    (ref.is_null (local.get $x))
  )

  (table $t1 2 anyref)
  (table $t2 2 funcref)
  (elem (table $t2) (i32.const 1) func $dummy)
  (func $dummy)

  (func (export "init") (param $r anyref)
    (table.set $t1 (i32.const 1) (local.get $r))
  )
  (func (export "deinit")
    (table.set $t1 (i32.const 1) (ref.null any))
    (table.set $t2 (i32.const 1) (ref.null func))
  )

  (func (export "anyref-elem") (param $x i32) (result i32)
    (call $f1 (table.get $t1 (local.get $x)))
  )
  (func (export "funcref-elem") (param $x i32) (result i32)
    (call $f2 (table.get $t2 (local.get $x)))
  )
)

(assert_return (invoke "anyref" (ref.null any)) (i32.const 1))
(assert_return (invoke "funcref" (ref.null func)) (i32.const 1))

(assert_return (invoke "anyref" (ref.host 1)) (i32.const 0))

(invoke "init" (ref.host 0))

(assert_return (invoke "anyref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "funcref-elem" (i32.const 0)) (i32.const 1))

(assert_return (invoke "anyref-elem" (i32.const 1)) (i32.const 0))
(assert_return (invoke "funcref-elem" (i32.const 1)) (i32.const 0))

(invoke "deinit")

(assert_return (invoke "anyref-elem" (i32.const 0)) (i32.const 1))
(assert_return (invoke "funcref-elem" (i32.const 0)) (i32.const 1))

(assert_return (invoke "anyref-elem" (i32.const 1)) (i32.const 1))
(assert_return (invoke "funcref-elem" (i32.const 1)) (i32.const 1))
