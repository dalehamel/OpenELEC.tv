#!/bin/sh

git archive --format=tar --prefix=rasplex-source-$1/ tags/$1 | bzip2 > rasplex.tar.bz2
