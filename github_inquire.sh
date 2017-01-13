#!/bin/bash

TAR_DIR=/home/ws327/public_html/lowrisc_stat

# get number of clones
curl -u ${GITID}:${GITIDPASSWD} https://api.github.com/repos/lowrisc/lowrisc-chip/traffic/clones > ${TAR_DIR}/clone.log
sed -n 's/[^0-9]*\([0-9]*\)-\([0-9]*\)-\([0-9]*\)T.*/\1\2\3/p' ${TAR_DIR}/clone.log > ${TAR_DIR}/clone_date.log
sed -n 's/[^0-9]*count[^0-9]*\([0-9]*\)[^0-9]*/\1/p' ${TAR_DIR}/clone.log > ${TAR_DIR}/clone_count.log

# get number of website views
curl -u ${GITID}:${GITIDPASSWD} https://api.github.com/repos/lowrisc/lowrisc-chip/traffic/views > ${TAR_DIR}/view.log
sed -n 's/[^0-9]*\([0-9]*\)-\([0-9]*\)-\([0-9]*\)T.*/\1\2\3/p' ${TAR_DIR}/view.log > ${TAR_DIR}/view_date.log
sed -n 's/[^0-9]*count[^0-9]*\([0-9]*\)[^0-9]*/\1/p' ${TAR_DIR}/view.log > ${TAR_DIR}/view_count.log
