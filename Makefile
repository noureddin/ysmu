targets = index.html ysmu.tsv candidate/index.html experimental/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*)
# $(wildcard) becomes empty if no files match

all: $(targets)

$(targets): p/* $(words) notes/src
	perl -Mutf8 -CDSA p/make.pl

.PHONY: clean

clean:
	rm -f $(targets)
