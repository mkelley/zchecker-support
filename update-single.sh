#!/bin/bash
source zchecker.env
export ZDIR ZBROWSER_SCRIPTS ZWEB
export target=$1
export searchopts=$2
zchecker clean-eph "$target" && \
zchecker clean-found "$target" && \
zchecker clean-files && \
zchecker eph "$target" --start=2017-10-15 --stop=2020-12-31 && \
zchecker search "$target" $searchopts --full && \
zchecker cutouts "$target" && \
zproject "$target" -f && \
zstack "$target" -f && \
zphot measure "$target" -f && \
zphot outburst --object="$target" --update && \
${ZDIR}/regenerate-zbrowserdb.sh && \
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/img/stacks --desg="$target" --force --full-update
