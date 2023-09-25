targets = index.html ysmu.tsv experimental/index.html

words = $(wildcard w/*) $(wildcard x/*)
# $(wildcard) becomes empty if no files match

all: $(targets)

$(targets): p/* $(words)
	perl -Mutf8 -CDSA p/make.pl

.PHONY: clean

clean:
	rm -f $(targets)
