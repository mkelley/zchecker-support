#!/bin/bash
source zchecker.env
export ZDIR ZWEB ZBROWSER_SCRIPTS
export target=$1
zchecker eph "$target" --start=2017-10-15 --stop=2020-12-31 && \
zchecker search "$target" --full && \
zchecker cutouts "$target" && \
zproject "$target" && \
zstack "$target" && \
zphot measure "$target" -f && \
zphot outburst --object="$target" --update && \
${ZDIR}/regenerate-zbrowserdb.sh && \
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/img/stacks --desg="$target"
