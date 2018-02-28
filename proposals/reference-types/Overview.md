# Reference Types for WebAssembly

TODO: more text, motivation, explanation

## Introduction

Motivation:

* Easier and more efficient interop with host environment
  - allow host references to be represented directly by type `anyref`
  - without having to go through tables, allocating slots, and maintaining index bijections at the boundaries

* Basic manipulation of tables inside Wasm
  - allow representing data structures containing references
by repurposing tables as a general memory for opaque data types
  - allow manipulating function tables from within Wasm.

* Set the stage for later additions:

  - Typed function references (see below)
  - Exception references (see exception handling proposal)
  - A smoother transition path to GC (see GC proposal)

Get the most important parts soon!

Summary:

* Add a new type `anyref` that can be used as both a value type and a table element type.

* Also allow `anyfunc` as a value type.

* Introduce instructions to get and set table slots.

* Allow multiple tables.

Notes:

* This extension does not imply GC by itself, only if host refs are GCed pointers!

* Reference types are *opaque*, i.e., their value is abstract and they cannot be stored into linear memory. Tables are used as the equivalent.


## Language Extensions

Typing extensions:

* Introduce `anyref`, `anyfunc`, and `nullref` as a new class of *reference types*.
  - `reftype ::= anyref | anyfunc | nullref`

* Value types (of locals, globals, function parameters and results) can now be either numeric types or reference types.
  - `numtype ::= i32 | i64 | f32 | f64`
  - `valtype ::= <numtype> | <reftype>`
  - locals with reference type are initialised with `null`

* Element types (of tables) are equated with reference types.
  - `elemtype ::= <reftype>`

* Introduce a simple subtype relation between reference types.
  - reflexive transitive closure of the following rules
  - `n < anyref` for all reftypes `t`
  - `anyfunc < anyref`
  - Note: No rule `nullref < t` for all reftypes `t` -- while that is derivable from the above given the current set of types it might not hold for future reference types which don't allow null.


New/extended instructions:

* The new instruction `ref.null` evaluates to the null reference constant.
  - `ref.null : [] -> [nullref]`
  - allowed in constant expressions

* The new instructions `table.get` and `table.set` access tables.
  - `table.get $x : [i32] -> [t]` iff `t` is the element type of table `$x`
  - `table.set $x : [i32 t] -> []` iff `t` is the element type of table `$x`
  - `table.fill $x : [i32 i32 t] -> []` iff `t` is the element type of table `$x`

* The `call_indirect` instruction takes a table index as immediate that identifies the table it calls through.
  - `call_indirect (type $t) $x : [t1* i32] -> [t2*]` iff `$t` denotes the function type `[t1*] -> [t2*]` and the element type of table `$x` is a subtype of `anyfunc`.
  - In the binary format, space for the index is already reserved.
  - For backwards compatibility, the index may be omitted in the text format, in which case it defaults to 0.


Table extensions:

* A module may define, import, and export multiple tables.
  - As usual, the imports come first in the index space.
  - This is already representable in the binary format.

* Element segments take a table index as immediate that identifies the table they apply to.
  - In the binary format, space for the index is already reserved.
  - For backwards compatibility, the index may be omitted in the text format, in which case it defaults to 0.


API extensions:

* Any JS object (non-primitive value) or `null` can be passed as `anyref` to a Wasm function, stored in a global, or in a table.

* Any JS function object or `null` can be passed as `anyfunc` to a Wasm function, stored in a global, or in a table.

* Only `null` can be passed as a `nullref` to a Wasm function, stored in a global, or in a table.

TODO: Perhaps allow other JS values (especially strings) as well, provided we don't support equality on `anyref`.


## Possible Future Extensions


### Typed function references

Motivation:

* Allow function pointers to be expressed directly without going through table and dynamic type check.
* Enable functions to be passed to other modules easily.

Additions:

* Add `(ref $t)` as a reference type
  - `reftype ::= ... | ref <typeidx>`
* Add `(ref.func $f)` and `(call_ref)` instructions
  - `ref.func $f : [] -> (ref $t)  iff $f : $t`
  - `call_ref : [ts1 (ref $t)] -> [ts2]` iff `$t = [ts1] -> [ts2]`
* Introduce subtyping `ref <functype> < anyfunc`
* Subtying between concrete and universal reference types
  - `ref $t < anyref`
  - `ref <functype> < anyfunc`

* Typed function references cannot be null!

* The `table.grow` instruction (see bulk operation proposal) needs to take an initialisation argument.

* Likewise `WebAssembly.Table#grow` takes an additional initialisation argument.
  - optional for backwards compatibility, defaults to `null`


Question:

* General function have no reasonable default, do we need scoped variables like `let`?
* Should there be a down cast instruction?
* Should there be depth subtyping for function types?


### Type Import/Export

Motivation:

* Allow the host (or Wasm modules) to distinguish different reference types.

Additions:

* Add `(type)` external type, enables types to be imported and exported
  - `externtype ::= ... | type`
  - `(ref $t)` can now denote an abstract type or a function reference
  - imported types have index starting from 0.
  - reserve byte in binary format to allow refinements later

* Add abstract type definitions in type section
  - `deftype ::= <functype> | new`
  - creates unique abstract type

* Add `WebAssembly.Type` class to JS API
  - constructor `new WebAssembly.Type(name)` creates unique abstract type

* Subtyping `ref <abstype>` < `anyref`

Questions:

* Do we need to impose constraints on the order of imports, to stratify section dependencies?

* Do we need a nullable `(ref opt $t)` type to allow use with locals etc.?

* Should we add `(new)` definitional type to enable Wasm modules to define new types, too?

* Should we add a `(cast $t)` instruction for down casts?

* Should JS API allow specifying subtyping between new types?

* Should type import and export be separate sections instead?


### Down Casts

Motivation:

* Allow to implement generics by using `anyref` as a top type.

Addition:

* Add a `cast` instruction
  - `cast <reftype1> <reftype2 : [<reftypet1>] -> [<reftype2>]` iff `<reftype2> < <reftype1>`
  - could later be generalised to non-reference types?

Note:

* Can decompose `call_indirect`
  - `(call_indirect $t $x)` reduces to `(table.get $x) (cast anyref (ref $t)) (call_ref (ref $t))`


### GC Types

See GC proposal.


### Further possible generalisations

* Introduce reference types pointing to tables, memories, or globals.
  - `deftype ::= ... | global <globaltype> | table <tabletype> | memory <memtype>`
  - `ref.global $g : [] -> (ref $t)` iff `$g : $t`
  - `ref.table $x : [] -> (ref $t)` iff `$x : $t`
  - `ref.mem $m : [] -> (ref $t)` iff `$m : $t`
  - yields first-class tables, memories, globals
  - would requires duplicating all respective instructions

* Allow all value types as element types.
  - `deftype := ... | globaltype | tabletype | memtype`
  - would unify element types with value types
