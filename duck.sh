#!/usr/bin/env bash
# DuckDNS updater - keeps BOTH domains pointed at this machine's current PUBLIC IP.
# NOTE: never set these to Tailscale addresses (100.64/10 or fd7a::/48) - those are
# CGNAT/ULA and unroutable from the internet, which breaks inbound mail.
DIR="$(cd "$(dirname "$0")" && pwd)"
DOMAINS="arety-mailbridge,aretytech"
TOKEN="REDACTED"$DIR/token")"
echo -n "$(date -Iseconds) " >> "$DIR/duck.log"
curl -fsS "https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=" \
  -o "$DIR/duck.last" && cat "$DIR/duck.last" >> "$DIR/duck.log"
echo "" >> "$DIR/duck.log"
