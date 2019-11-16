#!/bin/bash
source zchecker.env
export ZDATA ZBROWSER_SCRIPTS ZWEB
rm -f ${ZDATA}/new_zbrowser.db && \
  ${ZBROWSER_SCRIPTS}/dump-foundobs.sh ${ZDATA}/zchecker.db ${ZDATA}/new_zbrowser.db && \
  mv ${ZDATA}/{new_zbrowser,zbrowser}.db
