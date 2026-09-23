# 🛡️ smSpamHaus

### Spamhaus DROP IPv4 Protection for Linux

A lightweight Bash-based solution that automatically downloads the official Spamhaus DROP IPv4 feed, loads CIDR networks into an `ipset`, and blocks them through `iptables`.

Designed to work alongside **Plesk Firewall and Fail2Ban** without restarting, reconfiguring, or interfering with either service.

---

## ✨ What is smSpamHaus?

smSpamHaus is a simple Linux firewall integration for the Spamhaus DROP IPv4 feed.

It downloads the feed, ignores the metadata record, extracts only valid `cidr` entries, and places the networks into a single `hash:net` ipset named `smSpamHaus`.

The firewall then uses one `iptables` rule to block every network contained in that set.

```text
                         Spamhaus DROP
                              │
                              ▼
                       drop_v4.json
                              │
                              ▼
                       smSpamHaus.sh
                              │
                              ▼
                  ┌─────────────────────┐
                  │     smSpamHaus      │
                  │     ipset hash:net  │
                  └─────────────────────┘
                              │
                              ▼
                          iptables
                              │
                              ▼
                            DROP
```

---

## 🚀 Features

| Feature                              | Status |
| ------------------------------------ | ------ |
| Spamhaus DROP IPv4 feed              | 🟢     |
| JSON / NDJSON feed support           | 🟢     |
| Ignore `type=metadata` records       | 🟢     |
| CIDR-based blocking                  | 🟢     |
| `ipset hash:net`                     | 🟢     |
| Single iptables DROP rule            | 🟢     |
| Automatic weekly updates             | 🟢     |
| Automatic startup update             | 🟢     |
| Atomic-style feed validation         | 🟢     |
| Concurrent update protection         | 🟢     |
| `jq` dependency check/install        | 🟢     |
| `curl` dependency check/install      | 🟢     |
| `ipset` dependency check/install     | 🟢     |
| `iptables` dependency check/install  | 🟢     |
| systemd service                      | 🟢     |
| `/etc/cron.d/` scheduled update      | 🟢     |
| Update logging                       | 🟢     |
| Manual update support                | 🟢     |
| Plesk Firewall coexistence           | 🟢     |
| Fail2Ban coexistence                 | 🟢     |
| Fail2Ban restart/reload required     | 🔴     |
| Plesk GUI integration                | 🔴     |
| IPv6 / DROP IPv6 feed                | 🔴     |
| Spamhaus DBL / ZEN / SBL integration | 🔴     |
| Automatic email notifications        | 🔴     |

> 🔴 means the feature is not included in this project.

---

## 📋 Requirements

| Requirement   | Required | Notes                              |
| ------------- | -------- | ---------------------------------- |
| Linux         | 🟢       | Debian/Ubuntu-style system         |
| Ubuntu 22.04+ | 🟢       | Primary target                     |
| Root access   | 🟢       | Required                           |
| Bash          | 🟢       | Required                           |
| `curl`        | 🟢       | Installed automatically if missing |
| `jq`          | 🟢       | Installed automatically if missing |
| `ipset`       | 🟢       | Installed automatically if missing |
| `iptables`    | 🟢       | Installed automatically if missing |
| systemd       | 🟢       | Used for startup loading           |
| cron          | 🟢       | Used for weekly updates            |
| IPv4 firewall | 🟢       | Current implementation             |
| IPv6 blocking | 🔴       | Not implemented                    |

---

## 📦 Project Structure

```text
smspamhaus/
├── install.sh
├── uninstall.sh
├── smSpamHaus.sh
├── README.md
├── LICENSE
├── cron/
│   └── smSpamHaus
└── systemd/
    └── smSpamHaus.service
```

### Files

| File                         | Purpose                                   |
| ---------------------------- | ----------------------------------------- |
| `install.sh`                 | Complete one-command installation         |
| `uninstall.sh`               | Complete removal of smSpamHaus components |
| `smSpamHaus.sh`              | Downloads and updates the Spamhaus ipset  |
| `systemd/smSpamHaus.service` | Loads the feed during system startup      |
| `cron/smSpamHaus`            | Weekly update schedule                    |
| `README.md`                  | Documentation                             |

---

## ⚡ Installation

Clone the repository:

```bash
git clone https://github.com/trfoxs/smspamhaus.git
cd smspamhaus
```

Run the installer as root:

```bash
chmod +x install.sh
./install.sh
```

The installer automatically handles:

```text
Dependencies
     ↓
ipset
     ↓
iptables DROP rule
     ↓
systemd service
     ↓
weekly cron
     ↓
initial Spamhaus download
     ↓
CIDR validation
     ↓
CIDR loading
```

No manual configuration is required for the default setup.

### Important

smSpamHaus does **not**:

* restart Fail2Ban
* reload Fail2Ban
* modify Fail2Ban jails
* restart Plesk Firewall
* flush the `INPUT` chain
* delete existing firewall chains
* replace Plesk Firewall
* modify Plesk configuration

It manages only its own:

```text
smSpamHaus ipset
        +
smSpamHaus iptables DROP rule
```

---

## 🛡️ Plesk Compatibility

smSpamHaus is designed to coexist with **Plesk Firewall** and **Fail2Ban**.

The architecture is intentionally separated:

```text
                         Plesk
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
      Plesk Firewall                 Fail2Ban
             │                           │
             └─────────────┬─────────────┘
                           │
                           ▼
                        iptables
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
        Plesk rules                smSpamHaus
                                        │
                                        ▼
                                     ipset
                                        │
                                        ▼
                                      DROP
```

smSpamHaus does not require Fail2Ban to be running.

It does not restart or reload Fail2Ban after an update.

This is important for Plesk systems because restarting Fail2Ban during every Spamhaus update can cause unnecessary service interruptions and dependency/order problems.

### Plesk Firewall

smSpamHaus does not attempt to become a Plesk Firewall extension or add a Plesk GUI configuration page.

It operates at the Linux firewall layer and maintains its own dedicated rule.

On systems where Plesk Firewall and the system firewall layer are active through `iptables`, the smSpamHaus rule can coexist with the existing Plesk and Fail2Ban rules.

> Always verify your firewall configuration before deploying any third-party blocking list.

---

## 🧹 Uninstallation

Run the included uninstaller as root:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

The uninstaller removes only smSpamHaus components:

* smSpamHaus systemd service
* weekly cron entry
* installed `smSpamHaus.sh`
* `smSpamHaus` ipset
* smSpamHaus iptables DROP rule
* smSpamHaus log file

It does **not**:

* remove Fail2Ban
* modify Fail2Ban jails
* restart Fail2Ban
* remove Plesk Firewall
* flush the `INPUT` chain
* remove unrelated iptables rules
* remove system packages required by other services

System packages such as `curl`, `jq`, `ipset` and `iptables` are not removed because they may be required by other services.

> If iptables rules were manually saved to `/etc/iptables/rules.v4`, review that file separately after uninstalling.

---

## 📜 Spamhaus Data & License Information

smSpamHaus retrieves network records from the official Spamhaus DROP IPv4 JSON feed:

```text
https://www.spamhaus.org/drop/drop_v4.json
```

This project currently processes IPv4 CIDR networks only. IPv6 / DROPv6 is not included.

The Spamhaus DROP dataset is provided by The Spamhaus Project. Spamhaus states that DROP data is available free of charge. When used in a product, credit must be given to The Spamhaus Project, and the date and copyright text should remain with the file and data.

The DROP data remains subject to Spamhaus intellectual-property rights and applicable terms of use.

### Spamhaus attribution

> Data source: The Spamhaus Project — DROP IPv4
>
> https://www.spamhaus.org/drop/drop_v4.json

For the current terms, see the official Spamhaus DROP Terms of Use:

https://www.spamhaus.org/blocklists/drop-fair-use-policy/

smSpamHaus is an independent integration project and is not affiliated with, sponsored by, or endorsed by Spamhaus.

---

## 🔄 Update Schedule

The default cron schedule is:

```cron
0 4 * * 0 root /usr/local/sbin/smSpamHaus.sh
```

This means:

**Every Sunday at 04:00**

The update process:

1. Downloads the current Spamhaus DROP IPv4 feed.
2. Validates the downloaded data.
3. Extracts only records containing `cidr`.
4. Ignores the `type=metadata` record.
5. Builds the updated network set.
6. Verifies that valid CIDR entries were found.
7. Updates the `smSpamHaus` ipset.
8. Ensures the smSpamHaus iptables DROP rule exists.
9. Writes the result to the log.

### Fail2Ban

Fail2Ban is **not restarted or reloaded** during updates.

smSpamHaus is completely independent from the Fail2Ban service.

---

## 🔁 Startup Protection

`smSpamHaus.service` runs during system startup.

This is important because an `ipset` is held in memory. After a reboot, the Spamhaus networks need to be loaded again.

The startup flow is:

```text
Server Boot
     │
     ▼
systemd
     │
     ▼
smSpamHaus.service
     │
     ▼
smSpamHaus.sh
     │
     ▼
Download Spamhaus DROP
     │
     ▼
Validate feed
     │
     ▼
Populate smSpamHaus
     │
     ▼
iptables DROP
```

The service does not require Fail2Ban to restart or reload.

---

## 🧱 Firewall Rule

The project uses one dedicated iptables rule:

```bash
iptables -I INPUT 1 -m set --match-set smSpamHaus src -j DROP
```

The rule references the ipset instead of creating thousands of individual firewall rules.

Conceptually:

```text
Incoming IPv4
     │
     ▼
Is source IP inside smSpamHaus?
     │
   ┌─┴─┐
  YES  NO
   │    │
   ▼    ▼
 DROP  Continue
```

The rule belongs exclusively to smSpamHaus.

The project does not flush or rebuild the complete `INPUT` chain.

---

## 🔍 Useful Commands

### Check the ipset

```bash
ipset list smSpamHaus
```

### Show the number of loaded networks

```bash
ipset list smSpamHaus | grep "Number of entries"
```

### Check the firewall rule

```bash
iptables -S INPUT | grep smSpamHaus
```

### Check the systemd service

```bash
systemctl status smSpamHaus.service --no-pager
```

### Check the cron entry

```bash
cat /etc/cron.d/smSpamHaus
```

### Run an update manually

```bash
/usr/local/sbin/smSpamHaus.sh
```

### View logs

```bash
tail -50 /var/log/smSpamHaus.log
```

### Check Fail2Ban separately

```bash
systemctl status fail2ban --no-pager
```

smSpamHaus does not require any Fail2Ban restart after an update.

---

## 📝 Logging

Update logs are stored at:

```text
/var/log/smSpamHaus.log
```

Example:

```text
[2026-09-23 04:00:00] Update started.
[2026-09-23 04:00:02] Spamhaus: 1711 unique CIDRs loaded. Source records: 1712.
[2026-09-23 04:00:02] iptables DROP rule verified.
[2026-09-23 04:00:02] Update completed successfully.
```

No Fail2Ban restart is performed or logged.

---

## 🧩 Feed Format

Spamhaus DROP uses newline-delimited JSON records.

Example:

```json
{"cidr":"1.10.16.0/20","sblid":"SBL256894","rir":"apnic"}
```

The feed also contains a metadata record.

smSpamHaus deliberately does not process the metadata record:

```json
{"type":"metadata","...":"..."}
```

Only records containing a `cidr` field are sent to the ipset.

---

## 🔐 Safety Notes

smSpamHaus is designed around the Spamhaus DROP IPv4 feed.

Before deploying it to a production firewall:

* Review your existing firewall rules.
* Make sure your own public/management networks are not unexpectedly included.
* Test the installation on a non-critical system first.
* Keep SSH access through a separate trusted path.
* Verify the loaded CIDR count after installation.
* Verify the `smSpamHaus` iptables rule after installation.
* Make sure Plesk Firewall and Fail2Ban continue to show their expected rules.

The project does not attempt to expand CIDRs into individual IP addresses.

The project also does not flush existing firewall rules.

---

## 🌐 Spamhaus

This project uses the official Spamhaus DROP IPv4 feed:

https://www.spamhaus.org/drop/drop_v4.json

Spamhaus DROP terms:

https://www.spamhaus.org/drop/terms/

Please review the current Spamhaus terms and attribution requirements before distributing or embedding the feed in another product.

---

## 📄 License

The smSpamHaus scripts and installation files are provided as an open-source project under the MIT License.

The Spamhaus DROP data itself remains subject to the Spamhaus terms of use.

---

<div align="center">

### 🛡️ Simple. Lightweight. Automated.

**Spamhaus DROP → ipset → iptables**

</div>
