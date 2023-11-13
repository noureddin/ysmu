targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

all: $(targets)

$(targets): p/* w/ c/ x/ u/ $(words) notes/src longnames.tsv etc/style.min.css
	perl -Mutf8 -CDSA p/make.pl

%.min.css: %.css
	deno run --quiet --allow-read npm:clean-css-cli "$<" > "$@"

.PHONY: clean force all

define newline


endef

force: clean all
# `make -B` would re-build once for each target,
# but only one time for all targets is needed.

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -fr link/
