#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Workaround for long shebang lines
find $SRC_DIR -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,$PREFIX/bin/perl,/usr/bin/env perl,;"
export TEXINDEX_AWK=${BUILD_PREFIX}/bin/awk

make_args=""

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CC=${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    autoreconf --force --verbose --install
    ./configure --prefix=$BUILD_PREFIX

    # Workaround for randomly occuring failure due to incorrect dep-graph in Makefile
    # /usr/bin/install: cannot stat './font/devpdf/download': No such file or directory
    make -j${CPU_COUNT} font/devpdf/build_font_files
    make -j${CPU_COUNT} install
    make clean

    LDFLAGS="${CROSS_LDFLAGS}"
    CC=${CROSS_CC}
    LD=${CROSS_LD}

    make_args="GROFFBIN=${BUILD_PREFIX}/bin/groff GROFF_BIN_PATH=${BUILD_PREFIX}/bin PDFMOMBIN=${BUILD_PREFIX}/bin/pdfmom"
fi

autoreconf --force --verbose --install
./configure --prefix=$PREFIX

# Workaround for randomly occuring failure due to incorrect dep-graph in Makefile
# /usr/bin/install: cannot stat './font/devpdf/download': No such file or directory
make -j${CPU_COUNT} font/devpdf/build_font_files
make -j${CPU_COUNT} install "${make_args}"
# if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
# make check
# fi
