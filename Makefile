all: test

build:
	@dune build

test:
	@dune runtest

ci:
	git ci . -m "More."
	git push
