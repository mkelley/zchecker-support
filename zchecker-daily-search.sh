#!/bin/bash
#
# example crontab line:
#
# 02 10 * * * cd /oort/msk && /bin/bash zchecker-daily-search.sh
#
source zchecker.env
export LOGROTATE ZDIR ZDATA ZWEB ZBROWSER_SCRIPTS
source ${ZDIR}/.venv/bin/activate
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
