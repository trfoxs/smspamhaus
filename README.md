# smSpamHaus

Spamhaus DROP IPv4 integration for Linux using `ipset` + `iptables`, designed to coexist with Plesk Firewall and Plesk Fail2Ban.

## Plesk compatibility

This project does **not** restart, reload, enable, disable, or reconfigure Fail2Ban. It also does not call the Plesk Firewall CLI or restart `psa-firewall`.

On Plesk for Linux, the Plesk Firewall manages the underlying OS firewall rules, while Fail2Ban adds its own firewall rules. smSpamHaus adds only one independent rule:

`INPUT -> match-set smSpamHaus src -> DROP`

The project does not flush `INPUT`, does not create or modify Fail2Ban chains, and does not remove unrelated Plesk firewall rules.

The systemd unit waits for `psa-firewall.service` when that service is present, so the initial boot-time Spamhaus rule is installed after the Plesk firewall service.

## Safety during updates

The updater downloads the current Spamhaus DROP IPv4 JSON feed into `/run`, validates the CIDRs, loads them into a temporary ipset, and then atomically swaps the temporary set with the live `smSpamHaus` set. If download or validation fails, the currently active set remains unchanged.

A `flock` prevents concurrent cron/systemd/manual updates.

## Install

```bash
chmod +x install.sh
./install.sh
```

The installer installs only required packages (`curl`, `jq`, `ipset`, `iptables`), creates the dedicated ipset and DROP rule, installs the systemd unit and weekly cron job, and performs an initial update.

It does **not** restart Fail2Ban or Plesk Firewall.

## Verify

```bash
ipset list smSpamHaus
iptables -L INPUT -n --line-numbers | grep smSpamHaus
systemctl status smSpamHaus --no-pager
fail2ban-client status
```

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes only the smSpamHaus service, cron entry, script, ipset and its exact INPUT DROP rule. It does not stop/restart Fail2Ban or Plesk Firewall and does not remove their chains.

## Data source

Official Spamhaus DROP IPv4 JSON feed:

https://www.spamhaus.org/drop/drop_v4.json

This project is independent and is not affiliated with, sponsored by, or endorsed by Spamhaus.

## Scope

- IPv4 DROP feed
- `ipset hash:net`
- one dedicated `iptables` DROP rule
- systemd startup update
- weekly cron update
- no Fail2Ban integration
- no Plesk GUI integration
- no IPv6 DROP feed
