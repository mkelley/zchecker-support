#!/bin/bash
source zchecker.env
export ZDIR ZWEB ZBROWSER_SCRIPTS
export date=$1
zchecker ztf --date=$date && \
zchecker clean-files && \
zchecker search --date=$date && \
zchecker cutouts && \
zproject && \
zstack && \
zphot measure && \
bash ${ZDIR}/regenerate-zbrowserdb.sh && \
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/stacks --date=$date --full-update
