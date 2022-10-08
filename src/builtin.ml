(** Suppose that we have some builtins already defined. *)

open Type

let a = var 0

let bool =
  [
    "true", Ground Bool;
    "false", Ground Bool;
    "if", Arr (Ground Bool, Arr (a, Arr (a, a)))
  ]

let string =
  [
    "concat", Arr (Ground String, Ground String);
  ]

let builtin = bool@string

let builtin = List.map (fun (x,a) -> (x,(-1,a))) builtin

let get () = builtin
