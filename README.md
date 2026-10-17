# DuckDNS updater

A single Bash script, `duck.sh`, that keeps one or more DuckDNS hostnames pointed at the current public IPv4 address of the machine it runs on. Home connections get a new address whenever the router reconnects; without an updater, any service hosted at home (mail, web, SSH) stops being reachable by name. The script is meant to be run from cron every few minutes and keeps a simple log of every attempt.

## Where it is used

In Abrar's setup it runs on the laptop that hosts a self-made mail bridge and a few web endpoints. The DuckDNS names it maintains are what external MX and A records point to, so the script is the piece that keeps inbound mail and HTTPS working after the ISP changes the address.

## How it works

1. Resolves its own directory (`DIR`) so it can be invoked from cron with any working directory.
2. Reads the DuckDNS account token from the file `token` in the same directory (one line, no quotes).
3. Appends an ISO-8601 timestamp to `duck.log`.
4. Calls `https://www.duckdns.org/update?domains=<DOMAINS>&token=<TOKEN>&ip=` with `curl -fsS`. Leaving `ip` empty makes DuckDNS use the address the request arrived from, which is exactly the router's current public IP, so the script never has to detect the IP itself.
5. Writes the response body (`OK` or `KO`) to `duck.last` and appends it to the same log line.

`DOMAINS` is a comma-separated list of DuckDNS subdomain labels (without `.duckdns.org`), set at the top of the script. A comment in the script warns never to pass a Tailscale/CGNAT or ULA address explicitly, since those are unroutable from the internet and would break inbound mail.

| File | Role |
|---|---|
| `duck.sh` | the updater |
| `token` | DuckDNS token, mode 600, not committed |
| `duck.log` | one line per run: `<timestamp> OK` / `KO` (runtime) |
| `duck.last` | last raw response (runtime) |

## Setup

Requirements: `bash`, `curl`, `cron`, a DuckDNS account with the subdomains already created.

```bash
mkdir -p ~/duckdns && cd ~/duckdns
# copy duck.sh here, then:
sed -i 's/^DOMAINS=.*/DOMAINS="sub1,sub2"/' duck.sh
echo 'your-duckdns-token' > token
chmod 600 token
chmod +x duck.sh
```

Add to the user's crontab (`crontab -e`) to run every five minutes:

```cron
*/5 * * * * $HOME/duckdns/duck.sh >/dev/null 2>&1
```

## Usage

```bash
~/duckdns/duck.sh            # run once by hand
cat ~/duckdns/duck.last      # OK or KO
tail -n 3 ~/duckdns/duck.log # recent attempts
```

Example log lines:

```
2026-01-01T12:00:01+00:00 OK
2026-01-01T12:05:01+00:00 OK
```

A line with only a timestamp and no result means `curl` failed (no network or DuckDNS unreachable); `-f` makes curl exit non-zero on HTTP errors so nothing misleading is logged.

## Project structure

```
duckdns/
├── duck.sh
├── token        # not committed
├── duck.log     # runtime
└── duck.last    # runtime
```

## Limitations and notes

- IPv4 only; no `ipv6=` parameter is sent.
- The log grows without bound (a line every five minutes); rotate or truncate it occasionally.
- No retry or alerting: a `KO` or a missing result is only visible in the log.
- The token is passed in the URL query string, as DuckDNS requires; keep the `token` file private and out of version control.
