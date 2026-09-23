<div align="center">

# 🛡️ smSpamHaus

### Spamhaus DROP IPv4 Protection for Linux

A lightweight Bash-based solution that automatically downloads the official **Spamhaus DROP IPv4 feed**, loads CIDR networks into an `ipset`, and blocks them through `iptables`.

<br>

[![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](#requirements)
[![Shell](https://img.shields.io/badge/shell-Bash-121011?style=for-the-badge&logo=gnubash&logoColor=white)](#how-it-works)
[![Firewall](https://img.shields.io/badge/firewall-iptables-blue?style=for-the-badge)](#how-it-works)
[![IPSet](https://img.shields.io/badge/ipset-hash%3Anet-green?style=for-the-badge)](#how-it-works)
[![Spamhaus](https://img.shields.io/badge/feed-Spamhaus%20DROP-red?style=for-the-badge)](https://www.spamhaus.org/drop/)

</div>

---

## ✨ What is smSpamHaus?

**smSpamHaus** is a simple Linux firewall integration for the **Spamhaus DROP IPv4** feed.

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
              ┌─────────────────┐
              │ smSpamHaus      │
              │ ipset hash:net  │
              └─────────────────┘
                       │
                       ▼
                  iptables
                       │
                       ▼
                     DROP
```

---

## 🚀 Features

| Feature | Status |
|---|:---:|
| Spamhaus DROP IPv4 feed | 🟢 |
| JSON / NDJSON feed support | 🟢 |
| Ignore `type=metadata` records | 🟢 |
| CIDR-based blocking | 🟢 |
| `ipset hash:net` | 🟢 |
| Single iptables DROP rule | 🟢 |
| Automatic weekly updates | 🟢 |
| Automatic startup update | 🟢 |
| `jq` dependency check/install | 🟢 |
| `curl` dependency check/install | 🟢 |
| `ipset` dependency check/install | 🟢 |
| `iptables` dependency check/install | 🟢 |
| systemd service | 🟢 |
| `/etc/cron.d/` scheduled update | 🟢 |
| Update logging | 🟢 |
| Manual update support | 🟢 |
| IPv6 / DROP IPv6 feed | 🔴 |
| Spamhaus DBL / ZEN / SBL integration | 🔴 |
| Web UI | 🔴 |
| Plesk GUI integration | 🔴 |
| Automatic email notifications | 🔴 |

> 🔴 means the feature is **not included in this project**.

---

## 📋 Requirements

| Requirement | Required | Notes |
|---|:---:|---|
| Linux | 🟢 | Debian/Ubuntu-style system |
| Ubuntu 22.04+ | 🟢 | Primary target |
| Root access | 🟢 | Required |
| Bash | 🟢 | Required |
| `curl` | 🟢 | Installed automatically if missing |
| `jq` | 🟢 | Installed automatically if missing |
| `ipset` | 🟢 | Installed automatically if missing |
| `iptables` | 🟢 | Installed automatically if missing |
| systemd | 🟢 | Used for startup loading |
| cron | 🟢 | Used for weekly updates |
| IPv4 firewall | 🟢 | Current implementation |
| IPv6 blocking | 🔴 | Not implemented |

---

## 📦 Project Structure

```text
smspamhaus/
├── install.sh
├── uninstall.sh
├── smSpamHaus.sh
├── README.md
├── cron/
│   └── smSpamHaus
└── systemd/
    └── smSpamHaus.service
```

### Files

| File | Purpose |
|---|---|
| `install.sh` | Complete one-command installation |
| `uninstall.sh` | Complete removal of smSpamHaus components |
| `smSpamHaus.sh` | Downloads and updates the Spamhaus ipset |
| `systemd/smSpamHaus.service` | Loads the feed during system startup |
| `cron/smSpamHaus` | Weekly update schedule |
| `README.md` | Documentation |

---

## ⚡ Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/smspamhaus.git
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
CIDR loading
```

No manual configuration is required for the default setup.

---

## 🧹 Uninstallation

Run the included uninstaller as root:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

The uninstaller removes:

- smSpamHaus systemd service
- weekly cron entry
- installed `smSpamHaus.sh`
- `smSpamHaus` ipset
- smSpamHaus iptables DROP rule
- smSpamHaus log file

System packages such as `curl`, `jq`, `ipset` and `iptables` are **not removed**, because they may be required by other services.

> If iptables rules were manually saved to `/etc/iptables/rules.v4`, review that file separately after uninstalling.

---

## 📜 Spamhaus Data & License Information

smSpamHaus retrieves network records from the official **Spamhaus DROP IPv4 JSON feed**:

```text
https://www.spamhaus.org/drop/drop_v4.json
```

This project currently processes **IPv4 CIDR networks only**. IPv6 / DROPv6 is not included.

The Spamhaus DROP dataset is provided by **The Spamhaus Project**. Spamhaus states that DROP data is available free of charge. When used in a product, credit must be given to The Spamhaus Project, and the date and copyright text should remain with the file and data. The DROP data remains subject to Spamhaus intellectual-property rights and applicable terms of use.

**Spamhaus attribution:**

> Data source: The Spamhaus Project — DROP IPv4
> 
> https://www.spamhaus.org/drop/drop_v4.json

For the current terms, see the official Spamhaus DROP Terms of Use:

https://www.spamhaus.org/blocklists/drop-fair-use-policy/

smSpamHaus is an independent integration project and is **not affiliated with, sponsored by, or endorsed by Spamhaus**.

---

## 🔄 Update Schedule

The default cron schedule is:

```cron
0 4 * * 0 root /usr/local/sbin/smSpamHaus.sh
```

This means:

**Every Sunday at 04:00**

The update process:

1. Removes the previous JSON file.
2. Downloads the current Spamhaus DROP IPv4 feed.
3. Extracts only records containing `cidr`.
4. Ignores the `type=metadata` record.
5. Flushes the existing `smSpamHaus` ipset.
6. Loads the new CIDR networks.
7. Verifies that the set contains entries.
8. Ensures the iptables DROP rule exists.
9. Restarts Fail2Ban if it is currently active.
10. Writes the result to the log.

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
Populate smSpamHaus
```

---

## 🧱 Firewall Rule

The project uses one iptables rule:

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

---

## 📝 Logging

Update logs are stored at:

```text
/var/log/smSpamHaus.log
```

Example:

```text
[2026-09-23 04:00:00] Güncelleme başladı.
[2026-09-23 04:00:02] Spamhaus: 1711 benzersiz CIDR yüklendi. Kaynak kayıt: 1712.
[2026-09-23 04:00:02] Fail2Ban yeniden başlatıldı.
[2026-09-23 04:00:02] Güncelleme tamamlandı.
```

---

## 🧩 Feed Format

Spamhaus DROP uses newline-delimited JSON records.

Example:

```json
{"cidr":"1.10.16.0/20","sblid":"SBL256894","rir":"apnic"}
```

The feed also contains a metadata record.

smSpamHaus deliberately does **not** process the metadata record:

```json
{"type":"metadata", "...":"..."}
```

Only records containing a `cidr` field are sent to the ipset.

---

## 🔐 Safety Notes

smSpamHaus is designed around the conservative **Spamhaus DROP** IPv4 feed.

Before deploying it to a production firewall:

- Review your existing firewall rules.
- Make sure your own public/management networks are not unexpectedly included.
- Test the installation on a non-critical system first.
- Keep SSH access through a separate trusted path.
- Verify the loaded CIDR count after installation.

The project does not attempt to expand CIDRs into individual IP addresses.

---

## 🌐 Spamhaus

This project uses the official Spamhaus DROP IPv4 feed:

**https://www.spamhaus.org/drop/drop_v4.json**

Spamhaus DROP terms:

**https://www.spamhaus.org/drop/terms/**

Please review the current Spamhaus terms and attribution requirements before distributing or embedding the feed in another product.

---

## 📄 License

The **smSpamHaus scripts and installation files** are provided as an open-source project.

The Spamhaus DROP data itself remains subject to the **Spamhaus terms of use**.

---

<div align="center">

### 🛡️ Simple. Lightweight. Automated.

**Spamhaus DROP → ipset → iptables**

</div>
