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

The typing of an expression of the form

`t.{l = u}`{.ocaml}

The implementation should be based on previous work about records, objects and
subtyping in ML.

## Requirements

We should be able to use `t.{l = u}` in every place where `t` should be accepted
(without using the method `l`). This means that, we should accept

```ocaml
1.{l = "a"} + 2
```

This also mean that we should accept heterogeneous lists as long as the
underlying undecorated values agree : we should accept

```ocaml
[1.{a = 2, b = "a", c = 1.2}, 2.{a = 0}
```

<!-- ## Records with subtyping -->

<!-- There are several approaches to (sub)typing records. -->

<!-- ### MLsub -->

<!-- In _MLsub_ the idea is that every type variable is attached with an interval. -->

<!-- The one of [MLsub](https://dl.acm.org/doi/10.1145/3093333.3009882) (see also -->
<!-- [this](https://github.com/stedolan/mlsub) and -->
<!-- [this](https://github.com/smimram/mlsub) implementations) is nice but leads to -->
<!-- unreadable types -->
