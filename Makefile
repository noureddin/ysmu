targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

$(targets): .p/* .t/* $(words) notes/src etc/style.min.css
	perl -Mutf8 -CDSA .p/build

%.min.css: %.css
	deno run --quiet --allow-read --allow-env=HTTP_PROXY,http_proxy npm:clean-css-cli "$<" > "$@"

.PHONY: clean

define newline


endef

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -f etc/style.min.css
	rm -fr link/
