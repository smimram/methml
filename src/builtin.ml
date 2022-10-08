open Type

(** Suppose that we have some builtins already defined. *)
let builtin =
  [
    "concat", Arr (Ground String, Ground String)
  ]
let builtin = List.map (fun (x,a) -> (x,(-1,a))) builtin

let get () = builtin
