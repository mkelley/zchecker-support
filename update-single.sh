#!/bin/bash
source zchecker.env
export ZDIR ZBROWSER_SCRIPTS ZWEB
export target=$1
export searchopts=$2
zchecker clean-eph "$target" && \
zchecker clean-found "$target" && \
zchecker clean-files && \
zchecker eph "$target" --start=2017-10-15 --stop=2019-12-31 && \
zchecker search "$target" $searchopts --full && \
zchecker cutouts "$target" && \
zproject "$target" -f && \
zstack "$target" -f && \
zphot measure "$target" -f && \
${ZDIR}/regenerate-zbrowserdb.sh && \
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/stacks --desg="$target" --force --full-update