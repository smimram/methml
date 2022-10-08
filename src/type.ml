(** Operations on types. *)

(** Ground types. *)
module Ground = struct
  type t = Int | String

  let to_string = function
    | Int -> "int"
    | String -> "string"
end

(** Level for type variables. *)
type level = int

(** Variables. *)
type var = {
  id : int; (* a unique identifier *)
  mutable level : level; (* level for generalization *)
  mutable link : t option; (* substituted value of the variable *)
}

(** Types. *)
and t =
  | Var of var
  | Ground of Ground.t
  | Arr of t * t
  | List of t

(** Type scheme: non-substituted variables strictly above the level should be
   instantiated. *)
and scheme = level * t


(*
(** Given a strictly positive integer, generate a name in [a-z]+: a, b, ... z,
    aa, ab, ... az, ba, ... *)
let string_of_univ =
  let base = 26 in
  let c i = char_of_int (int_of_char 'a' + i - 1) in
  let add i suffix = Printf.sprintf "%c%s" (c i) suffix in
  let rec n suffix i =
    if i <= base then
      add i suffix
    else
      let head = i mod base in
      let head = if head = 0 then base else head in
      n (add head suffix) ((i-head)/base)
  in
  n ""

let to_string a =
  let var =
    let n = ref 0 in
    let v = ref [] in
    fun x ->
      match List.find_map (fun (y,s) -> if Type.var_eq x y then Some s else None) !v with
      | Some s -> s
      | None ->
        incr n;
        let s = "`" ^ string_of_univ !n in
        v := (x,s) :: !v;
        s
  in
  let rec aux = function
    | Ground Int -> "int"
    | Ground String -> "string"
    | Var x -> var x
    | Arr (a, b) -> Printf.sprintf "(%s -> %s)" (to_string a) (to_string b)
    | List a -> Printf.
  in
  aux a
*)

let rec to_string = function
  | Var x -> "'a" ^ string_of_int x.id
  | Ground g -> Ground.to_string g
  | Arr (a, b) -> Printf.sprintf "(%s -> %s)" (to_string a) (to_string b)
  | List a -> Printf.sprintf "[%s]" (to_string a)

(** Equality between variables. *)
let var_eq (x:var) (y:var) =
  (* we want _physical_ equality here *)
  x == y

let invar =
  let id = ref (-1) in
  fun ?link level ->
    incr id;
    { id = !id; level; link }

(** Create a fresh variable. *)
let var ?link level =
  Var (invar ?link level)

(** A typing error. *)
exception Error of string

(** Ensure that the first type is a subtype of the second. *)
let rec ( <: ) a b =
  match a, b with
  | Var x, b when x.link <> None -> Option.get x.link <: b
  | a, Var x when x.link <> None -> a <: Option.get x.link
  | Ground a, Ground b when a = b -> ()
  | Arr (a, b), Arr (a', b') -> a' <: a; b <: b'
  | Var x, b -> x.link <- Some b
  | a, Var x -> x.link <- Some a
  | _ -> raise (Error (Printf.sprintf "got %s but %s expected" (to_string a) (to_string b)))

exception Cyclic_type

let rec occurs x a =
  match a with
  | Var y when y.link = None ->
    if var_eq x y then raise Cyclic_type;
    y.level <- min x.level y.level
  | Var y -> occurs x (Option.get y.link)
  | Ground _ -> ()
  | Arr (a, b) -> occurs x a; occurs x b
  | List a -> occurs x a

(** Instantiate a type scheme as a type. *)
let instantiate level ((l,a):scheme) =
  let fresh = ref [] in
  let rec aux = function
    | Var x ->
      if x.level <= l then Var x else
        (
          match List.find_map (fun (y, y') -> if var_eq x y then Some y' else None) !fresh with
          | Some x' -> x'
          | None ->
            let x' = var level in
            fresh := (x, x') :: !fresh;
            x'
        )
    | Ground g -> Ground g
    | List _ -> failwith "TODO"
    | Arr (a, b) -> Arr (aux a, aux b)
  in
  if l = max_int then a else aux a

let scheme_of_type a : scheme = max_int, a

(** Infer the type of a term. *)
let rec infer ?(level=0) (env:(string*scheme) list) t =
  let infer ?(level=level) = infer ~level in
  match t.Lang.descr with
  | Lang.Int _ -> Ground Int
  | Lang.String _ -> Ground String
  | Var x -> (try instantiate level (List.assoc x env) with Not_found -> failwith ("Unbound variable " ^ x))
  | Abs (x, t) ->
    let a = var level in
    let b = infer ((x,(scheme_of_type a))::env) t in
    Arr (a, b)
  | App (t, u) ->
    let a = infer env u in
    let b = var level in
    infer env t <: Arr (a, b);
    b
  | Meth _ ->
    failwith "TODO"
  | Invoke _ ->
    failwith "TODO"
  | List _ ->
    failwith "TODO"
  | Let (r, x, t, u) ->
    let a =
      if r then
        let a = var (level+1) in
        let env = (x,(scheme_of_type a))::env in
        let a' = infer ~level:(level+1) env t in
        a' <: a;
        a'
      else
        infer ~level:(level+1) env t
    in
    infer ((x,(level,a))::env) u
