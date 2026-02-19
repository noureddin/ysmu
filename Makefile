targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

$(targets): .p/* .t/* $(words) notes/src etc/style.min.css
	perl -Mutf8 -CDSA .p/build

%.min.css: %.css
	deno run --quiet --allow-read --allow-env=HTTP_PROXY,http_proxy npm:clean-css-cli "$<" > "$@"

commit: ysmu.tsv
	git add .
	git commit
	@# rebuild and re-commit to correct the dates in the atom feed
	perl -Mutf8 -CDSA .p/build
	git add .
	git commit --amend --no-edit
	@# update the suami glossary
	cp -f ysmu.tsv ../suami
	(cd ../suami; make; git add index.html ysmu.tsv; git commit -m🌄 ;)

push:
	git push && (cd ../suami; pwd; git push;)

.PHONY: clean commit push

define newline


endef

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -f etc/style.min.css
	rm -fr link/
