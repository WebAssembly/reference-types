(module
  (func (export "f") (param $x i32) (result i32) (local.get $x))
)
(register "M")

(module
  (func $f (import "M" "f") (param i32) (result i32))
  (func $g (param $x i32) (result i32) (i32.add (local.get $x) (i32.const 1)))
  (global $x (mut funcref) (ref.null))

  (table $t 1 funcref)

  (func (export "is_null-f") (result i32)
    (ref.isnull (ref.func $f))
  )
  (func (export "is_null-g") (result i32)
    (ref.isnull (ref.func $g))
  )
  (func (export "is_null-x") (result i32)
    (ref.isnull (global.get $x))
  )

  (func (export "set-f") (global.set $x (ref.func $f)))
  (func (export "set-g") (global.set $x (ref.func $g)))

  (func (export "call-f") (param $x i32) (result i32)
    (table.set $t (i32.const 0) (ref.func $f))
    (call_indirect $t (param i32) (result i32) (local.get $x) (i32.const 0))
  )
  (func (export "call-g") (param $x i32) (result i32)
    (table.set $t (i32.const 0) (ref.func $g))
    (call_indirect $t (param i32) (result i32) (local.get $x) (i32.const 0))
  )
  (func (export "call-x") (param $x i32) (result i32)
    (table.set $t (i32.const 0) (global.get $x))
    (call_indirect $t (param i32) (result i32) (local.get $x) (i32.const 0))
  )
)

(assert_return (invoke "is_null-f") (i32.const 0))
(assert_return (invoke "is_null-g") (i32.const 0))
(assert_return (invoke "is_null-x") (i32.const 1))

(assert_return (invoke "call-f" (i32.const 4)) (i32.const 4))
(assert_return (invoke "call-g" (i32.const 4)) (i32.const 5))
(assert_trap (invoke "call-x" (i32.const 4)) "uninitialized element")

(invoke "set-f")
(assert_return (invoke "call-x" (i32.const 4)) (i32.const 4))
(invoke "set-g")
(assert_return (invoke "call-x" (i32.const 4)) (i32.const 5))
