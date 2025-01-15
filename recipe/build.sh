#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

autoreconf -vfi
./configure --prefix=$PREFIX

# Workaround for long shebang lines
find $SRC_DIR -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,$PREFIX/bin/perl,/usr/bin/env perl,;"

export TEXINDEX_AWK=${BUILD_PREFIX}/bin/awk
make -j${CPU_COUNT} install
# if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
# make check
# fi
