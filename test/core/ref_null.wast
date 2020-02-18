(module
  (func (export "anyref") (result anyref) (ref.null any))
  (func (export "funcref") (result funcref) (ref.null func))

  (global anyref (ref.null any))
  (global funcref (ref.null func))
)

(assert_return (invoke "anyref") (ref.null any))
(assert_return (invoke "funcref") (ref.null func))
