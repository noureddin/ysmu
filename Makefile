all: index.html ysmu.tsv

ysmu.tsv: p/* w/* x/*
	perl -Mutf8 -CDSA p/make.pl

index.html: p/* w/* x/*
	perl -Mutf8 -CDSA p/make.pl

experimental/index.html: p/* w/* x/*
	perl -Mutf8 -CDSA p/make.pl
