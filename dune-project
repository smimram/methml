(lang dune 2.9)
(name methml)
(source (github smimram/methml))
(license GPL-3.0)
(authors "Samuel Mimram <smimram@gmail.com>")
(maintainers "Samuel Mimram <smimram@gmail.com>")

(generate_opam_files true)

(package
 (name methml)
 (synopsis "An ML language with methods")
 (description "An ML language with methods.")
 (depends
   menhir)
)
(using menhir 2.0)
