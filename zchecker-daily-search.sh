#!/bin/bash
#
# example crontab line:
#
# 02 10 * * * cd /path/to/zchecker && /bin/bash zchecker-daily-search.sh
#
# Must be run from base zchecker working directory.
#
source .venv/bin/activate && \
source zchecker.env && \
export LOGROTATE ZDIR ZDATA ZWEB ZBROWSER_SCRIPTS SLACK_USER_POST_URL \
  SLACK_ZTFSSWG_POST_URL MPLBACKEND && \
${LOGROTATE} ${ZDATA}/logrotate.config -s ${ZDATA}/logrotate.state && \
zchecker ztf-update && \
zchecker search && \
zchecker download-cutouts && \
zproject && \
zstack && \
zphot measure && \
${ZDIR}/regenerate-zbrowserdb.sh && \
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/img/pointing --frame=equatorial && \
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/img/pointing --frame=ecliptic && \
python3 ${ZBROWSER_SCRIPTS}/pointing.py ${ZWEB}/img/pointing --frame=galactic && \
python3 ${ZBROWSER_SCRIPTS}/stack2web.py ${ZWEB}/img/stacks # && \
#python3 ${ZDIR}/slack-zchecker-daily.py
