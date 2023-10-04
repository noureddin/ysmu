targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

all: $(targets)

$(targets): p/* $(words) notes/src longnames.tsv
	perl -Mutf8 -CDSA p/make.pl

.PHONY: clean

define newline


endef

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -rf link/
