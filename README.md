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

### Basic methods

We should of course be able to type _method invocation_:

```ocaml
fun x -> x.l
```

should have type `'a.{l : 'b} -> 'b` (this is akin to polymorphic records).

We should be able to type _method decoration_:

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

### Dropping methods

We should be able to use `t.{l = u}` in every place where `t` should be accepted
(without using the method `l`). This means that, we should accept

```ocaml
1.{l = "a"} + 2
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
don't match.

This means that we can have surprising effects of this. For instance, the
following should return `true`:

```ocaml
{a = 5, b = 6} == {a = 5, c = "x"}
```

## Subtyping

One way of implementing this is by using _subtyping_. This means that we should
have

```
a.{l : b} <: a
```


<!-- ## Records with subtyping -->

<!-- There are several approaches to (sub)typing records. -->

<!-- ### MLsub -->

<!-- In _MLsub_ the idea is that every type variable is attached with an interval. -->

<!-- The one of [MLsub](https://dl.acm.org/doi/10.1145/3093333.3009882) (see also -->
<!-- [this](https://github.com/stedolan/mlsub) and -->
<!-- [this](https://github.com/smimram/mlsub) implementations) is nice but leads to -->
<!-- unreadable types -->
