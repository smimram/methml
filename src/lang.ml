(** Programs. *)

module Pos = struct
  type t = Lexing.position * Lexing.position
end

(** A variable. *)
type var = string

(** Terms of the language. *)
type t =
  {
    pos : Pos.t;
    descr : descr
  }

and descr =
  | Int of int
  | String of string
  | List of t list
  | Var of var
  | Abs of var * t (** a function *)
  | App of t * t
  | Meth of string * t * t (** a method on a value *)
  | Invoke of t * string (** invoke a method *)
  | Let of bool * string * t * t (* let (recursive?) x = t in u *)

let mk ~pos descr = { pos; descr }

let rec abs ~pos l t =
  match l with
  | x::l -> mk ~pos (Abs (x, abs ~pos l t))
  | [] -> t

(** String representation of a program. *)
let rec to_string t =
  match t.descr with
  | Int n -> string_of_int n
  | String s -> "\"" ^ s ^ "\""
  | List l ->
    l
    |> List.map to_string
    |> String.concat ", "
    |> Printf.sprintf "[%s]"
  | Var x -> x
  | Abs (x, t) -> Printf.sprintf "(fun %s -> %s)" x (to_string t)
  | App (t, u) -> Printf.sprintf "(%s %s)" (to_string t) (to_string u)
  | Meth (l, v, t) -> Printf.sprintf "%s.{%s = %s}" (to_string t) l (to_string v)
  | Invoke (t, l) -> Printf.sprintf "(%s.%s)" (to_string t) l
  | Let (r, x, t, u) -> Printf.sprintf "let%s %s = %s in %s" (if r then " rec" else "") x (to_string t) (to_string u)
