#!/usr/bin/env python3
import os
import json
import argparse
import requests
import sqlite3
import math
from astropy.time import Time
from zchecker import ZChecker, Config

parser = argparse.ArgumentParser(epilog='Requires environment variables ZBROWSER_BASE_URL, '
                                 'SLACK_USER_POST_URL, and SLACK_ZTFSSWG_POST_URL')
parser.add_argument('--date', help='generate report for this date')
parser.add_argument('-n', action='store_true', dest='debug', help='no-op mode for testing')
parser.add_argument('--user', action='store_true', help='post message to user for testing')
args = parser.parse_args()

base_url = os.getenv('ZBROWSER_BASE_URL')
user_post_url = os.getenv('SLACK_USER_POST_URL')
ztfsswg_post_url = os.getenv('SLACK_ZTFSSWG_POST_URL')

config = Config.from_file()
with ZChecker(config=config, save_log=False) as z:
    targets = {}
    for i, d in z.db.execute('SELECT objid,desg FROM obj').fetchall():
        targets[i] = d

    rows = z.db.execute('''
SELECT objid,desg FROM obj
WHERE desg GLOB '[CP]*'
   OR desg GLOB '*[0-9]P'
   OR desg in ('2060', '4015', '7968', '60558', '118401', 
               '323137', '300163', '457175')
''').fetchall()
    comets = {}
    for i, d in rows:
        comets[i] = d

    is_comet = 'objid IN ({})'.format(','.join(
        [str(i) for i in comets.keys()]))

    if args.date is None:
        last_nightid, last_night, exposures = z.db.execute('''
        SELECT nightid,date,exposures FROM ztf_nights ORDER BY date DESC LIMIT 1
        ''').fetchone()
    else:
        last_nightid, last_night, exposures = z.db.execute('''
        SELECT nightid,date,exposures FROM ztf_nights WHERE date=:date
        ''', {'date': args.date}).fetchone()

    in_last_night = 'nightid={}'.format(last_nightid)

    observed = []
    for vmin, vmax in zip([22, 20, 18, -99], [23, 22, 20, 18]):
        observed.append(z.db.execute('''
        SELECT COUNT(DISTINCT objid) FROM ztf_found
        WHERE ''' + is_comet + '''
          AND vmag > ?
          AND vmag <= ?
          AND (ra3sig*ra3sig + dec3sig*dec3sig) < 22500
          AND ''' + in_last_night, [vmin, vmax]).fetchone()[0])

    total = z.db.execute('''
        SELECT COUNT(DISTINCT objid) FROM ztf_found
        WHERE ''' + is_comet + '''
          AND (ra3sig*ra3sig + dec3sig*dec3sig) < 22500
          AND ''' + in_last_night).fetchone()[0]

    rows = z.db.execute('''
    SELECT objid,AVG(vmag) AS meanv FROM ztf_found
    WHERE ''' + is_comet.format(col='desg') + '''
    AND vmag IS NOT NULL
    AND (ra3sig*ra3sig + dec3sig*dec3sig) < 22500
    AND ''' + in_last_night + '''
    GROUP BY objid
    ORDER BY meanv LIMIT 5
    ''').fetchall()

    if len(rows) == 0:
        brightest_comets = '(not applicable)'
    else:
        brightest_comets = '\n'.join([
            ('<' + base_url + '?obs-by-target={target}|{target}> ({v:.1f})')
            .format(target=comets[row[0]], v=row[1])
        for row in rows])

    rows = z.db.execute('''
    SELECT objid,MAX(ostat) AS max_ostat FROM ztf_phot
    INNER JOIN ztf_found USING (foundid)
    WHERE ''' + in_last_night + '''
      AND ostat NOT NULL
      AND ostat >= 3
    GROUP BY objid
    ''').fetchall()

    if len(rows) == 0:
        outbursts = 'No suspected outbursts.'
    else:
        outbursts = 'Possible outbursts:\n  ' + '\n  '.join([
            ('<' + base_url + '?obs-by-target={target}|{target}> ({ostat:.1f})')
            .format(target=targets[row[0]], ostat=row[1])
            for row in rows])

summary = f'On the night of <{base_url}?obs-by-date={last_night}|{last_night}>, out of {exposures} exposure{"" if exposures == 1 else "s"}, {total} comet{" was" if total == 1 else "s were"} found.\n{outbursts}\n\n'

if exposures == 0:
    text = 'No exposures were taken on {}.'.format(last_night)
    msg = {
        'attachments': [
            {
                'fallback': text,
                'title': f'<{base_url}|ZChecker> Daily Summary',
                'text': text
            }
        ]
    }
else:
    msg = {
        'attachments': [
            {
                'fallback': 'ZChecker daily summary for ' + last_night,
                'title': f'<{base_url}|ZChecker> Daily Summary',
                'text': summary,
                'fields': [
                    {
                        'title': 'V (mag)',
                        'value': '22<V≤23\n20<V≤22\n18<V≤20\n≤18',
                        'short': True
                    },
                    {
                        'title': 'Comets covered',
                        'value': '\n'.join([str(n) for n in observed]),
                        'short': True
                    },
                    {
                        'title': 'Brightest comets:',
                        'value': brightest_comets,
                        'short': False
                    }
                ]
            }
        ]
    }

if args.debug:
    print(json.dumps(msg, indent='  '))
elif args.user:
    r = requests.post(user_post_url, data=json.dumps(msg))
else:
    r = requests.post(ztfsswg_post_url, data=json.dumps(msg))
