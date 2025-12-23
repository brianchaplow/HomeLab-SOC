---
title: "HomeLab SOC"
summary: "Enterprise-grade security monitoring across cloud and home infrastructure"
date: 2025-12-22
layout: project.njk
status: active
featured: true
github: https://github.com/brianchaplow/HomeLab-SOC
technologies:
  - OpenSearch
  - Suricata
  - Fluent Bit
  - Cloudflare
  - Tailscale
  - Docker
  - Python
  - GCP
description: "A fully operational Security Operations Center spanning Cloudflare edge security, Google Cloud web hosting, and home lab infrastructure—with automated threat intelligence enrichment and real-time blocking."
---

## Overview

This project is a production security monitoring stack protecting two live websites ([brianchaplow.com](https://brianchaplow.com) and [bytesbourbonbbq.com](https://bytesbourbonbbq.com)) and a home network. It spans three infrastructure layers: Cloudflare edge security, a Google Cloud VM serving web traffic, and a QNAP NAS running the SOC stack.

This isn't a tutorial lab—it processes real traffic, blocks real threats, and requires real maintenance.

**Current metrics:**
- 47,290 Suricata IDS rules active (ET Open)
- 100+ malicious IPs auto-blocked at Cloudflare
- Threat intelligence enrichment every 15 minutes
- GeoIP enrichment on all security alerts
- Real-time Discord alerts for security events
- Navy-style watch turnover reports at 0600/1800
- Mobile dashboard access via Tailscale mesh

## Architecture

The infrastructure spans three layers with data flowing from edge to SIEM:

```
                         ┌─────────────────────┐
                         │      INTERNET       │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │     CLOUDFLARE      │
                         │  ┌───────────────┐  │
                         │  │ WAF & Bot     │  │
                         │  │ Fight Mode    │  │
                         │  │ JA3 Fingerprint│  │
                         │  │ Auto-Block API │  │
                         │  └───────────────┘  │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   GOOGLE CLOUD VM   │
                         │  ┌───────────────┐  │
                         │  │ Apache + SSL  │  │
                         │  │ Umami Analytics│  │
                         │  │ Fluent Bit    │──────┐
                         │  └───────────────┘  │   │
                         └─────────────────────┘   │
                                                   │ Tailscale VPN
                                    ┌──────────────┤ (encrypted mesh)
                                    │              │
                              ┌─────▼─────┐        │
                              │  Mobile   │        │
                              │  (iPhone) │        │
                              └───────────┘        │
                                                   │
┌──────────────────────────────────────────────────▼───────────────┐
│                        HOME NETWORK                              │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ ASUS Router │    │  TP-Link    │    │     QNAP NAS        │  │
│  │ ZenWiFi     │───▶│  Switch     │───▶│  ┌───────────────┐  │  │
│  │ BQ16 Pro    │    │ (SPAN/Mirror)│    │  │ OpenSearch    │  │  │
│  └─────────────┘    └─────────────┘    │  │ Suricata      │  │  │
│        │                   │           │  │ soc-automation│  │  │
│        │                   │           │  │ Fluent Bit    │  │  │
│  ┌─────▼─────┐      ┌─────▼─────┐     │  └───────────────┘  │  │
│  │  Windows  │      │   Kali    │     └─────────────────────┘  │
│  │  Endpoint │      │  Machine  │                              │
│  │  (Sysmon) │      │           │                              │
│  └───────────┘      └───────────┘                              │
└──────────────────────────────────────────────────────────────────┘
```

## Components

### Edge Layer: Cloudflare

Both websites are proxied through Cloudflare with:

- **WAF Rules:** Custom rules for known attack patterns
- **Bot Fight Mode:** Automated bot detection and challenges
- **JA3 Fingerprinting:** TLS fingerprint tracking for visitor identification
- **Managed Transforms:** Geo headers (city, region, country, coordinates) passed to origin
- **Auto-Block Integration:** SOC automation pushes blocks via API for IPs with AbuseIPDB score ≥90

The edge layer stops attacks before they reach the origin server and provides geographic context for all traffic.

### Web Hosting: Google Cloud

An e2-small VM in us-east4-a running:

- **Apache 2.4** with HTTP/2 and Let's Encrypt SSL
- **Umami** for privacy-focused web analytics
- **Cusdis** for comment management
- **Fluent Bit** (systemd service) shipping parsed Apache logs to OpenSearch

Apache logs are parsed with custom regex extracting client IP, geo data from Cloudflare headers, user agent, and request details—then shipped over encrypted Tailscale mesh to the home lab SIEM.

### Secure Connectivity: Tailscale

The GCP VM can't reach the home network directly without exposing ports to the internet. Tailscale provides a zero-config WireGuard mesh that solves this:

| Device | Tailscale IP | Role |
|--------|--------------|------|
| QNAP NAS | 100.110.112.98 | SOC platform (OpenSearch) |
| GCP VM | 100.125.40.97 | Log source (Fluent Bit) |
| iPhone | Dynamic | Mobile monitoring |

**Key benefits:**
- **Cloud → Home:** Fluent Bit ships logs over encrypted tunnel to OpenSearch
- **Mobile Access:** Dashboard access from anywhere without VPN configuration
- **No Port Forwarding:** Home network stays unexposed to internet
- **Automatic NAT Traversal:** Works through firewalls without configuration

The mesh handles connectivity automatically—logs flow from cloud to home lab without any firewall rules or public IP exposure.

### Network Monitoring: TP-Link Managed Switch

A TP-Link TL-SG108E (192.168.50.250) configured for port mirroring:

| Port | Device | Purpose |
|------|--------|---------|
| 1 | Router uplink | All traffic enters here |
| 2 | Windows laptop | Endpoint monitoring |
| 3 | Kali machine | Attack simulation |
| 4 | Hue Bridge | IoT monitoring |
| 5 | Eufy Security Hub | IoT monitoring |
| 8 | QNAP eth4 | SPAN destination |

Ports 1-7 mirror to port 8, giving Suricata visibility into all switched traffic. Household WiFi traffic is intentionally excluded for privacy—the SOC monitors the lab environment only.

### SOC Platform: QNAP NAS

Seven Docker containers running the core SOC stack:

| Container | Port | Purpose |
|-----------|------|---------|
| **OpenSearch** | 9200 | Log storage, search, SIEM |
| **OpenSearch Dashboards** | 5601 | Visualization and hunting |
| **Suricata** | — (host network) | Network IDS on eth4 (SPAN port) |
| **Fluent Bit** | 5514 | Log aggregation from all sources |
| **soc-automation** | — | Threat intel enrichment and response |
| **Zeek** | — | Network security monitor |
| **CyberChef** | 8000 | Data analysis toolkit |

The QNAP has dual network connections:
- **eth5** (10Gbps): Main traffic to router at 192.168.50.10
- **eth4** (1Gbps): SPAN capture interface (no IP assigned)

A startup script ensures eth4 has no IP and Suricata rules are updated on every boot.

### Automated Threat Response: soc-automation

A Python-based automation container running on cron:

| Schedule | Script | Function |
|----------|--------|----------|
| Every 15 min | `enrichment.py` | Query AbuseIPDB for new IPs |
| Hourly | `autoblock.py` | Push high-threat IPs to Cloudflare |
| 0600/1800 | `digest.py` | Watch turnover reports to Discord |
| Sunday 0800 | `digest.py --weekly` | Weekly threat summary |

When a new IP appears in Apache logs, enrichment queries AbuseIPDB. If the confidence score is ≥90 with ≥5 reports, autoblock adds it to Cloudflare's account-level firewall—blocking the IP across all domains automatically.

### GeoIP Enrichment

Geographic context is added at two layers:

**Web Traffic (Cloudflare → Apache):**
Cloudflare's Managed Transforms inject geo headers that Apache logs and Fluent Bit parses into searchable fields.

**Network Alerts (OpenSearch Ingest Pipeline):**
Suricata alerts are enriched at index time using MaxMind GeoLite2 databases. The ingest pipeline adds city, region, country, and coordinates to any external IP in alert data.

GeoLite2 databases are updated weekly via cron job to maintain accuracy.

## Data Pipeline

### Apache Logs (Web Traffic)

```
Visitor → Cloudflare (geo headers) → Apache (combined_geo format)
       → Fluent Bit (regex parse) → Tailscale → OpenSearch (apache-parsed-v2)
       → enrichment.py (AbuseIPDB) → autoblock.py (Cloudflare API)
```

### Network Traffic (IDS)

```
Network → TP-Link SPAN → QNAP eth4 → Suricata (47,290 rules)
       → eve.json → Fluent Bit → OpenSearch (fluentbit-default)
       → GeoIP ingest pipeline → Dashboards
```

### Windows Endpoints

```
Windows Events → Sysmon (detailed telemetry) → Fluent Bit
             → Custom Lua parser → OpenSearch (winlog-*)
```

## Dashboards

### NIDS Overview
Real-time network intrusion detection:
- Alert timeline and volume
- Top signatures triggered
- Traffic by protocol
- Source/destination analysis
- Geographic origin of alerts

### Windows Security
Endpoint visibility via Sysmon:
- Process execution chains
- Network connections per process
- DNS query logging
- Parent-child relationships

### Threat Intelligence
Web traffic risk assessment:
- AbuseIPDB score distribution
- Malicious ISPs and countries
- Auto-blocked IP tracking
- Risk breakdown by category

### Website Overview
Traffic analysis and security:
- Visitor geography (city-level)
- Top pages and referrers
- Scanner/bot detection
- Status code monitoring

### Stalker Monitor
Fingerprint-based visitor tracking:
- Specific visitor patterns across IP changes
- Activity timeline and frequency
- Pages of interest
- Mobile carrier NAT detection

## Detection Capabilities

### Network (Suricata)
- 47,290 ET Open detection rules
- GeoIP enrichment via OpenSearch ingest pipeline
- Protocol anomaly detection
- Known malware signatures
- Exploit attempt detection
- Reconnaissance patterns

### Endpoint (Sysmon)
- Process creation with full command line
- Parent-child process relationships
- Network connections per process
- DNS query logging
- File creation monitoring

### Web Application
- Scanner fingerprinting (Nmap, Nikto, SQLMap, WPScan)
- Malicious path probing (/wp-admin, /admin.php, etc.)
- Bot behavior patterns
- Geographic anomalies
- Visitor fingerprint tracking

## What This Demonstrates

**Security Engineering:**
- Multi-layer defense architecture (edge → origin → endpoint)
- Log pipeline design across network boundaries
- Threat intelligence integration and automated response
- Detection rule tuning and false positive management
- GeoIP enrichment for threat attribution

**Cloud & Infrastructure:**
- GCP VM administration and Apache configuration
- Cloudflare WAF and API integration
- Docker orchestration on NAS platform
- Tailscale mesh networking for secure hybrid connectivity

**Automation & Development:**
- Python scripts for threat enrichment
- Cron-based automation scheduling
- API integration (AbuseIPDB, Cloudflare)
- Custom log parsing with Lua and regex
- OpenSearch ingest pipelines

**Operational Discipline:**
- Daily monitoring via watch turnover reports
- Alert triage and investigation workflows
- Documentation of configurations and changes
- Continuous improvement based on real traffic
- Mobile monitoring capability for 24/7 awareness

## Lessons Learned

1. **Edge blocking is efficient.** Stopping threats at Cloudflare means they never consume origin resources or generate noise in logs.

2. **Enrichment transforms data into intelligence.** Raw IPs are just strings. Adding AbuseIPDB context and GeoIP data turns them into actionable threat indicators.

3. **Automation scales defense.** Manual IP blocking doesn't scale. The enrichment→autoblock pipeline handles threats while I sleep.

4. **Visibility requires investment.** Each data source (Apache, Suricata, Sysmon) required custom parsing. The payoff is comprehensive visibility.

5. **Tailscale simplifies hybrid architecture.** Connecting cloud to home lab securely would otherwise require complex VPN setup or exposed ports. Tailscale just works.

6. **Documentation is operational necessity.** Three infrastructure layers means lots of configuration. Past-me's notes save present-me hours.

## Repository

The [HomeLab-SOC GitHub repository](https://github.com/brianchaplow/HomeLab-SOC) contains:

- Fluent Bit configurations (Windows and Linux)
- Custom Lua parsers for Sysmon
- OpenSearch dashboard exports
- OpenSearch ingest pipeline definitions
- soc-automation scripts
- Docker compose files
- Architecture documentation

---

*This project is actively maintained and processing live traffic. For questions about the architecture or implementation, [reach out](/contact/).*
