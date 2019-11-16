#!/bin/bash
#
# example crontab line:
#
# 02 10 * * * cd /path/to/zchecker && /bin/bash zchecker-daily-search.sh
#
# Must be run from base zchecker working directory.
#
source .venv/bin/activate
source zchecker.env
export LOGROTATE ZDIR ZDATA ZWEB ZBROWSER_SCRIPTS
${LOGROTATE} ${ZDATA}/logrotate.config -s ${ZDATA}/logrotate.state
zchecker ztf-update
zchecker search
zchecker download-cutouts
zproject
/bin/sensors
zstack
zphot measure
${ZDIR}/regenerate-zbrowserdb.sh
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/pointing --frame=equatorial
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/pointing --frame=ecliptic
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/pointing --frame=galactic
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/stacks
python3 ${ZDIR}/reporting/slack-zchecker-daily.py
