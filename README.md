# MethodML

This is an experiment to add _methods_ to ML values, in order to provide a
satisfying implementation of what is used in
[Liquidsoap](http://www.liquidsoap.info). We add a construction

```ocaml
t.{l = u}
```

which means the value `t` decorated with a method with label `l` whose value is
`u`. We can also use

```ocaml
t.l
```

to call the method of label `l` to `t`.

We use the clear notation

```ocaml
t.{l₁ = u₁, l₂ = u₂, …, lₙ = uₙ}
```

as a shortcut for

```ocaml
t.{l₁ = u₁}.{l₂ = u₂}.….{lₙ = uₙ}
```

In particular, a record

```ocaml
{l₁ = u₁, …, lₙ = uₙ}
```

is the particular case of a decorated unit

```ocaml
().{l₁ = u₁, …, lₙ = uₙ}
```

The typing of an expression of the form `t.{l = u}` should be

```
a.{l : b}
```

where `a` is a type for `t` and `b` is a type for `u`. To be precise, `b` should
actually be a _type scheme_ so that our records can also act as modules.

The implementation should be based on previous work about records, objects and
subtyping in ML. One should remark that having expressions decorated with
methods (instead of only records) allows treating row variables as a special
case of universal variable.

## Requirements

We want to keep usual properties of typing

- we should have _principal types_,
- we should be able to _infer_ it.

### Basic methods

We should of course be able to type _method invocation_:

```ocaml
fun x -> x.l
```

should have type `'a.{l : 'b} -> 'b` (this is akin to polymorphic records).

We should also be able to type adding _method decorations_:

```ocaml
fun x y -> x.{l = y}
```

should have type `'a -> 'b -> 'a.{l : 'b}`.

### Commutativity of methods

The order of methods should not matter. For instance, both the following should
type:

```ocaml
let f x = ignore x.l; ignore x.m

let g x = ignore x.m; ignore x.l

let () =
  let r = {l = 1; m = 2} in
  f r;
  g r
```

However, we should either not be able to have the same label twice, or forbid
that two methods with the same label commute.

### Dropping methods / subtyping

We should be able to use `t.{l = u}` in every place where `t` should be accepted
(without using the method `l`). This means that, we should accept

```ocaml
1.{l = "a"} + 2
```

From the point of view of types, this means that we want to have _implicit
subtyping_. This means that we should have

```
a.{l : b} <: a
```

This also mean that we should accept heterogeneous lists as long as the
underlying undecorated values agree : we should accept

```ocaml
[1.{a = 2, b = "a", c = 1.2}, 2.{a = 0, c = "x"}]
```

we should be of type

```
int.{a : int} list
```

Note that we drop the `b` method of the first element because the second one
does not have it, and we drop the `c` method because the types for both elements
don't match (actually this last point can be debated: if we don't allow fields
with same name and different types, we should at least allow masking methods in
order to still be able to force forgetting the methods and still be able to
define such lists).

This means that we can have surprising effects of this. For instance, the
following should return `true`:

```ocaml
{a = 5, b = 6} == {a = 5, c = "x"}
```

### Masking methods

Masking methods is complicated. In a first pass, we could ensure that labels are
present only once by adding constraints to variables. We write `a!l` for a
variable with the constraint that there should be no method labeled `l`.

### Subtyping vs polymorphism

A problem is that subtyping does not mix well with polymorphism. For instance,
consider

```ocaml
fun x -> [x, {l = 5}]
```

could be given the types

- `'a.{l : int} -> {l : int} list`
- `'a.{l : string} -> unit list`
- `'a!l -> unit list`

where the first in incompatible with the two last. The problem here is that we
should be able to express that

- if the argument has a field `l` then it should be of type `int` and in this
  case we have such a field in the output
- if the argument has no field `l` then the output is `unit list`.

A natural representation of the type would be something like

```
'a → ('a ∧ {l : int})
```

which is quite heavy.

Let us provide another way of representing this. We write `a?` for the type "`a`
or absent". We can maybe think of `a?` as being `'a + ⊥` where `⊥` is the empty
type. The above function could then have the type

```
'a.{l : int?} as 'b -> 'b
```

### Supremums

We want the return value of `if` to be the supremum of the two branches. For instance,

```ocaml
fun b ->
  if b then
    {a : 4, b : 5}
  else
    {a : 2, c : 1}
```

should be of type

```
bool -> {a : int}
```

where

```
{a : int} = {a : int, b : int} ∨ {a : int, c : int}
```

Another example is

```ocaml
fun b -> if b then 12 else null
```

which should have type `int nullable`. And, of course, the situation would be
similar with `::` (cons), etc.

This means that we should either

1. give `if` the type `bool -> 'a -> 'b -> 'a ∨ 'b`,
2. give `if` the usual type `bool -> 'a -> 'a -> 'a` but allow the type `'a` to
   "grow" if needed.

The first solution is currently implemented in Liquidsoap, but this causes
problems. Namely, because some variables are in contravariant position (on the
left of an arrow for instance), some variables are allowed to grow and some are
allowed to get smaller, and it is not clear what happens when we substitute a
growing variable with a diminishing one.

Let us investigate the first one here. We should

- allow simplifying types: `int ∨ int = int`, `int ∨ (X ∨ int) = int ∨ X`, etc.
- when substituting universal variables, we should make sure that supremums
  still exist, e.g. in `if ... then 1 else "a"` we should see as early as
  possible that the return value would be `int ∨ string` which does not exist.

Actually, as soon as we have supremums the two types `'a -> 'a -> 'a` and `'a ->
'b -> 'a ∨ 'b` are equivalent, in the sense that each one subsumes the other, as
noted in the MLsub paper (section 3.2).

## Compared to OCaml

This is akin records in OCaml excepting that we want extensible records:

- we don't want to have to declare the type of records beforehand,
- we want to be able the same label in multiple records,
- we want to be able to build records gradually.

This is akin objects in OCaml excepting that we want to be able to drop
methods. For instance, the program

```ocaml
let x = object method a = 1 method b = 2 end
let y = object method a = 0 end
let l = [x; y]
```

raises (on `y`)

```
Error: This expression has type < a : int >
       but an expression was expected of type < a : int; b : int >
       The first object type has no method b
```

This however goes through with explicit coercions

```ocaml
let l = [(x :> <a : int>); y]
```

which we don't want to have to use here.

### Row polymorphism

In _row polymorphism_, we have a special universal variable for records which
indicates "all the remaining fields". Here, this corresponds to the type of the
main value, so that we don't have to have two kinds of universal variables (row
variables and traditional ones). For instance,

```ocaml
fun x -> {x with l = 3}
```

has type `'a -> {'a, l : int}`. Usually, row variables are special universal
variables, distinct from other ones (they can only be substituted with
records). Here, this is nicer because we use traditional universal variables.

<!-- ## The other ways of implementing this  -->

<!-- ## Records with subtyping -->

<!-- There are several approaches to (sub)typing records. -->

<!-- ### MLsub -->

<!-- In _MLsub_ the idea is that every type variable is attached with an interval. -->

<!-- The one of [MLsub](https://dl.acm.org/doi/10.1145/3093333.3009882) (see also -->
<!-- [this](https://github.com/stedolan/mlsub) and -->
<!-- [this](https://github.com/smimram/mlsub) implementations) is nice but leads to -->
<!-- unreadable types -->

## Literature

1. Wand (1989): _Type inference for record concatenation and multiple
   inheritance_

   > Here, we suppose that we have a _finite_ set of labels. In a record, each
   > label is assigned with a type `pre(a)` (the label is present and has type
   > `a`) or `abs` (the label is absent). There is no principal type, but there
   > is a finite set of generators, which can be computed. Records are
   > extensible and concatenation is supported. The absence of principal type is
   > due to concatenation: in `fun r₁ r₂ → (r₁@r₂).l` we don't know whether `l`
   > belongs to `r₁` or `r₂`.
  
1. Rémy (1993): _Type Inference for Records in a Natural Extension of ML_

   > Here, we have `pre` / `abs` types for labels, there are types variables and
   > field type variables (which can be substituted by `pre` / `abs`). There are
   > also row variables. The type system admits principal types. There is no
   > subtyping.
   
1. Ohory (1995): _A Polymorphic Record Calculus and Its Compilation_

   > Universal variables have constraints indicating which fields (with which
   > type) are supposed to be present (this is called _kinded polymorphism_). For
   > instance `fun r → r.l + r.m` has type `∀ (a : {l : int, m : int}), a →
   > int`. We have principal types which can be inferred. It cannot (contrarily
   > to row variables) represent adding a field or removing a field.

1. Alves, Ramos (2021): _An ML-style Record Calculus with Extensible Records_

   > Extends Ohory in order to have extensible records. Has good references to
   > literature.
   
1. Dolan, Mycroft (2017): _Polymorphism, Subtyping, and Type Inference in MLsub_

   > ...

We list below whether

- we have principal types
- we can infer the principal types
- we have implicit subtyping

Paper | Principal | Inference | Subtyping |
--------|-----------|-----------|-----------|
Wand'89 | ✗ | ✓ |
