targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

all: $(targets)

$(targets): p/* $(words) notes/src longnames.tsv
	perl -Mutf8 -CDSA p/make.pl

.PHONY: clean force all

define newline


endef

force: clean all
# `make -B` would re-build once for each target,
# but only one time for all targets is needed.

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -fr link/
