(* Types *)

type num_type = I32Type | I64Type | F32Type | F64Type
type ref_type = NullRefType | AnyRefType | FuncRefType
type value_type = NumType of num_type | RefType of ref_type
type stack_type = value_type list
type func_type = FuncType of stack_type * stack_type

type 'a limits = {min : 'a; max : 'a option}
type mutability = Immutable | Mutable
type table_type = TableType of Int32.t limits * ref_type
type memory_type = MemoryType of Int32.t limits
type global_type = GlobalType of value_type * mutability
type extern_type =
  | ExternFuncType of func_type
  | ExternTableType of table_type
  | ExternMemoryType of memory_type
  | ExternGlobalType of global_type


(* Attributes *)

let size = function
  | I32Type | F32Type -> 4
  | I64Type | F64Type -> 8


(* Subtyping *)

let match_num_type t1 t2 =
  t1 = t2

let match_ref_type t1 t2 =
  match t1, t2 with
  | _, AnyRefType -> true
  | NullRefType, _ -> true
  | _, _ -> t1 = t2

let match_value_type t1 t2 =
  match t1, t2 with
  | NumType t1', NumType t2' -> match_num_type t1' t2'
  | RefType t1', RefType t2' -> match_ref_type t1' t2'
  | _, _ -> false

let match_limits lim1 lim2 =
  I32.ge_u lim1.min lim2.min &&
  match lim1.max, lim2.max with
  | _, None -> true
  | None, Some _ -> false
  | Some i, Some j -> I32.le_u i j

let match_func_type ft1 ft2 =
  ft1 = ft2

let match_table_type (TableType (lim1, et1)) (TableType (lim2, et2)) =
  et1 = et2 && match_limits lim1 lim2

let match_memory_type (MemoryType lim1) (MemoryType lim2) =
  match_limits lim1 lim2

let match_global_type (GlobalType (t1, mut1)) (GlobalType (t2, mut2)) =
  mut1 = mut2 &&
  (t1 = t2 || mut2 = Immutable && match_value_type t1 t2)

let match_extern_type et1 et2 =
  match et1, et2 with
  | ExternFuncType ft1, ExternFuncType ft2 -> match_func_type ft1 ft2
  | ExternTableType tt1, ExternTableType tt2 -> match_table_type tt1 tt2
  | ExternMemoryType mt1, ExternMemoryType mt2 -> match_memory_type mt1 mt2
  | ExternGlobalType gt1, ExternGlobalType gt2 -> match_global_type gt1 gt2
  | _, _ -> false


(* Meet and join *)

let join_num_type t1 t2 =
  if t1 = t2 then Some t1 else None

let join_ref_type t1 t2 =
  match t1, t2 with
  | AnyRefType, _ | _, NullRefType -> Some t1
  | _, AnyRefType | NullRefType, _ -> Some t2
  | _, _ when t1 = t2 -> Some t1
  | _, _ -> Some AnyRefType

let join_value_type t1 t2 =
  match t1, t2 with
  | NumType t1', NumType t2' ->
    Lib.Option.map (fun t' -> NumType t') (join_num_type t1' t2')
  | RefType t1', RefType t2' ->
    Lib.Option.map (fun t' -> RefType t') (join_ref_type t1' t2')
  | _, _ -> None


let meet_num_type t1 t2 =
  if t1 = t2 then Some t1 else None

let meet_ref_type t1 t2 =
  match t1, t2 with
  | _, AnyRefType | NullRefType, _ -> Some t1
  | AnyRefType, _ | _, NullRefType -> Some t2
  | _, _ when t1 = t2 -> Some t1
  | _, _ -> Some NullRefType

let meet_value_type t1 t2 =
  match t1, t2 with
  | NumType t1', NumType t2' ->
    Lib.Option.map (fun t' -> NumType t') (meet_num_type t1' t2')
  | RefType t1', RefType t2' ->
    Lib.Option.map (fun t' -> RefType t') (meet_ref_type t1' t2')
  | _, _ -> None

let meet_stack_type ts1 ts2 =
  try Some (List.map Lib.Option.force (List.map2 meet_value_type ts1 ts2))
  with Invalid_argument _ -> None


(* Filters *)

let funcs =
  Lib.List.map_filter (function ExternFuncType t -> Some t | _ -> None)
let tables =
  Lib.List.map_filter (function ExternTableType t -> Some t | _ -> None)
let memories =
  Lib.List.map_filter (function ExternMemoryType t -> Some t | _ -> None)
let globals =
  Lib.List.map_filter (function ExternGlobalType t -> Some t | _ -> None)


(* String conversion *)

let string_of_num_type = function
  | I32Type -> "i32"
  | I64Type -> "i64"
  | F32Type -> "f32"
  | F64Type -> "f64"

let string_of_ref_type = function
  | NullRefType -> "nullref"
  | AnyRefType -> "anyref"
  | FuncRefType -> "funcref"

let string_of_value_type = function
  | NumType t -> string_of_num_type t
  | RefType t -> string_of_ref_type t

let string_of_value_types = function
  | [t] -> string_of_value_type t
  | ts -> "[" ^ String.concat " " (List.map string_of_value_type ts) ^ "]"


let string_of_limits {min; max} =
  I32.to_string_u min ^
  (match max with None -> "" | Some n -> " " ^ I32.to_string_u n)

let string_of_memory_type = function
  | MemoryType lim -> string_of_limits lim

let string_of_table_type = function
  | TableType (lim, t) -> string_of_limits lim ^ " " ^ string_of_ref_type t

let string_of_global_type = function
  | GlobalType (t, Immutable) -> string_of_value_type t
  | GlobalType (t, Mutable) -> "(mut " ^ string_of_value_type t ^ ")"

let string_of_stack_type ts =
  "[" ^ String.concat " " (List.map string_of_value_type ts) ^ "]"

let string_of_func_type (FuncType (ins, out)) =
  string_of_stack_type ins ^ " -> " ^ string_of_stack_type out

let string_of_extern_type = function
  | ExternFuncType ft -> "func " ^ string_of_func_type ft
  | ExternTableType tt -> "table " ^ string_of_table_type tt
  | ExternMemoryType mt -> "memory " ^ string_of_memory_type mt
  | ExternGlobalType gt -> "global " ^ string_of_global_type gt
