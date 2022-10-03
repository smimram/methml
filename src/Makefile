all: test

build:
	$(MAKE) -C ..

test: build
	@dune runtest

conflicts:
	@rm -f parser.conflicts
	@menhir --explain parser.mly
	@rm -f parser.ml parser.mli
	@less parser.conflicts
	@rm -f parser.conflicts
