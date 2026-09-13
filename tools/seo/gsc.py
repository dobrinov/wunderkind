#!/usr/bin/env python3
"""Search Console queries, run as the signed-in gcloud user.

Setup, once (the scope is the part that is easy to get wrong — a plain
`gcloud auth application-default login` grants cloud-platform only, and every
Search Console call then answers 403 ACCESS_TOKEN_SCOPE_INSUFFICIENT):

    gcloud services enable searchconsole.googleapis.com
    gcloud auth application-default login \
      --scopes=https://www.googleapis.com/auth/cloud-platform,\
https://www.googleapis.com/auth/webmasters.readonly
    gcloud auth application-default set-quota-project <project>

The quota project matters twice: it has to be set on the ADC file *and* sent as
the x-goog-user-project header, because raw HTTP does not read the ADC file the
way a client library does.

    tools/seo/gsc.py sites
    tools/seo/gsc.py queries sc-domain:wunderkind.bg [days]
    tools/seo/gsc.py pages   sc-domain:wunderkind.bg [days]
"""
import datetime as dt
import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://searchconsole.googleapis.com/webmasters/v3"


def shell(*args):
    return subprocess.run(args, capture_output=True, text=True).stdout.strip()


def project():
    return shell("gcloud", "config", "get-value", "project")


def token():
    value = shell("gcloud", "auth", "application-default", "print-access-token")
    if not value:
        sys.exit("No ADC token. Run the `gcloud auth application-default login` above.")
    return value


def call(path, body=None):
    request = urllib.request.Request(
        f"{API}/{path}",
        data=json.dumps(body).encode() if body else None,
        headers={
            "Authorization": f"Bearer {token()}",
            "x-goog-user-project": project(),
            "Content-Type": "application/json",
        },
        method="POST" if body else "GET",
    )
    try:
        return json.load(urllib.request.urlopen(request))
    except urllib.error.HTTPError as error:
        detail = json.load(error).get("error", {}).get("message", "")
        sys.exit(f"HTTP {error.code}: {detail}")


def sites():
    for entry in call("sites").get("siteEntry", []):
        print(f"{entry['permissionLevel']:20} {entry['siteUrl']}")


def report(site, dimension, days):
    end = dt.date.today()
    start = end - dt.timedelta(days=days)
    rows = call(
        f"sites/{urllib.parse.quote(site, safe='')}/searchAnalytics/query",
        {
            "startDate": start.isoformat(),
            "endDate": end.isoformat(),
            "dimensions": [dimension],
            "rowLimit": 100,
        },
    ).get("rows", [])

    if not rows:
        print(f"No {dimension} data for {site} in the last {days} days.")
        return

    print(f"{'clicks':>7} {'impr':>7} {'ctr':>6} {'pos':>6}  {dimension}")
    for row in rows:
        print(f"{row['clicks']:7.0f} {row['impressions']:7.0f} "
              f"{row['ctr'] * 100:5.1f}% {row['position']:6.1f}  {row['keys'][0]}")


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "sites"
    if command == "sites":
        sites()
    elif command in ("queries", "pages"):
        if len(sys.argv) < 3:
            sys.exit(f"usage: {sys.argv[0]} {command} <site> [days]")
        dimension = "query" if command == "queries" else "page"
        report(sys.argv[2], dimension, int(sys.argv[3]) if len(sys.argv) > 3 else 28)
    else:
        sys.exit(__doc__)
