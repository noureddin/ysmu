targets = index.html ysmu.tsv candidate/index.html experimental/index.html unstaged/index.html notes/index.html

words = $(wildcard w/*) $(wildcard c/*) $(wildcard x/*) $(wildcard u/*)
# $(wildcard) becomes empty if no files match

$(targets): .p/* .t/* $(words) notes/src etc/style.min.css
	perl -Mutf8 -CDSA .p/build -
# ^ exclude the Atom feed by default, because it takes time

feed.atom.xml: index.html candidate/index.html  # other stages are not included in the feed
	perl -Mutf8 -CDSA .p/build

%.min.css: %.css
	deno run --quiet --allow-read --allow-env=HTTP_PROXY,http_proxy npm:clean-css-cli "$<" > "$@"

commit: ysmu.tsv
	@echo perl .p/build
	@perl -Mutf8 -CDSA .p/build  # build (including the Atom feed, because it's excluded from the default build)
	git add .; git commit
	@echo perl .p/build
	@perl -Mutf8 -CDSA .p/build  # rebuild and re-commit to correct the dates in the Atom feed
	git add .; git commit --amend --no-edit
	@# update the suami glossary
	cp -f ysmu.tsv ../suami; (msg="$$(git log -1 --format=%s)"; cd ../suami; make; git add index.html ysmu.tsv; git commit -m"🌄 $$msg" ;)

push:
	git push && git push aosus && (cd ../suami; pwd; git push;)

.PHONY: clean commit push

define newline


endef

clean:
	$(addprefix ${newline}rm -f ,${targets})
	rm -f etc/style.min.css
	rm -fr link/
