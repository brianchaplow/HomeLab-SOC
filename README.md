# 🛡️ HomeLab SOC

[![OpenSearch](https://img.shields.io/badge/OpenSearch-2.x-blue?logo=opensearch)](https://opensearch.org/)
[![Suricata](https://img.shields.io/badge/Suricata-IDS%2FIPS-orange)](https://suricata.io/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)](https://docker.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-WAF%20%2B%20Bot%20Fight-F38020?logo=cloudflare)](https://cloudflare.com/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Zero%20Trust-000000?logo=tailscale)](https://tailscale.com/)

A production-grade Security Operations Center built on consumer hardware, demonstrating enterprise security monitoring capabilities in a home lab environment.

**Live Infrastructure:** This SOC actively monitors [brianchaplow.com](https://brianchaplow.com) and [bytesbourbonbbq.com](https://bytesbourbonbbq.com), processing real attack traffic and automatically blocking threats.

---

##  Project Overview

This project implements a full security monitoring stack across three architectural layers:

| Layer | Platform | Components |
|-------|----------|------------|
| **Edge Security** | Cloudflare | WAF, Bot Fight Mode, JA3 Fingerprinting, Auto-blocking |
| **Web Hosting** | Google Cloud | Apache/HTTP2, Umami Analytics, Fluent Bit |
| **SOC Infrastructure** | QNAP NAS | OpenSearch SIEM, Suricata IDS, Automated Threat Intel |

### Key Metrics

-  **47,290** Suricata detection rules (ET Open ruleset)
-  **100+** malicious IPs automatically blocked at edge
-  **15-minute** threat intelligence enrichment cycle
-  **Real-time** dashboards with GeoIP visualization
-  **Zero-trust** connectivity via Tailscale mesh

---

##  Architecture

```
                              ┌─────────────────┐
                              │    INTERNET     │
                              └────────┬────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
                    │         CLOUDFLARE (Edge)           │
                    │  • WAF + Managed Rules              │
                    │  • Bot Fight Mode                   │
                    │  • JA3 TLS Fingerprinting           │
                    │  • Auto-block API (score ≥90)       │
                    │  • Geo Headers → Origin             │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
                    │      GOOGLE CLOUD VM (Web)          │
                    │  • Apache + Let's Encrypt           │
                    │  • Umami Analytics                  │
                    │  • Fluent Bit → Tailscale → NAS     │
                    └──────────────────┬──────────────────┘
                                       │
                            TAILSCALE VPN MESH
                          (Encrypted WireGuard)
                                       │
┌──────────────────────────────────────▼─────────────────────────────────────┐
│                          QNAP NAS (SOC Stack)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ OpenSearch  │  │  Suricata   │  │ Fluent Bit  │  │    SOC      │        │
│  │   (SIEM)    │  │   (NIDS)    │  │  (Ingest)   │  │ Automation  │        │
│  │  Port 9200  │  │ SPAN Port   │  │  Port 5514  │  │  (Python)   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                         │
│  │ OpenSearch  │  │    Zeek     │  │  CyberChef  │   + GeoIP Enrichment    │
│  │ Dashboards  │  │   (NSM)     │  │  (Analysis) │   + AbuseIPDB Lookup    │
│  │  Port 5601  │  │             │  │  Port 8000  │   + Discord Alerts      │
│  └─────────────┘  └─────────────┘  └─────────────┘                         │
└────────────────────────────────────────────────────────────────────────────┘
```

---

##  Components

### Network Monitoring

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Suricata** | Network IDS with 47K+ rules | SPAN port capture via managed switch |
| **Zeek** | Network Security Monitor | Protocol analysis and conn logs |
| **Fluent Bit** | Log aggregation | Multi-source collection to OpenSearch |

### SIEM & Visualization

| Tool | Purpose | Features |
|------|---------|----------|
| **OpenSearch** | Log storage & search | Ingest pipelines, GeoIP enrichment |
| **OpenSearch Dashboards** | Visualization | Custom security dashboards |

### Automation

| Script | Schedule | Function |
|--------|----------|----------|
| `enrichment.py` | Every 15 min | Query AbuseIPDB for threat scores |
| `autoblock.py` | Hourly | Push high-risk IPs to Cloudflare block list |
| `digest.py` | 0600/1800 daily | Navy-style watch turnover reports |

### Network Infrastructure

```
┌────────────────────────────────────────────────────────────┐
│              TP-Link TL-SG108E Managed Switch              │
│                                                            │
│  Port 1: Router uplink     Port 5: Eufy Security Hub       │
│  Port 2: Windows Laptop    Port 6: Available               │
│  Port 3: Kali Machine      Port 7: Available               │
│  Port 4: Hue Bridge        Port 8: SPAN → QNAP eth4        │
│                                                            │
│  Mirror Config: Ports 1-7 (ingress+egress) → Port 8        │
└────────────────────────────────────────────────────────────┘
```

---

##  Repository Structure

```
HomeLab-SOC/
├── README.md
├── configs/
│   ├── .env.example              # Environment variables template
│   ├── docker-compose.yml        # Full SOC container stack
│   ├── fluent-bit/
│   │   ├── fluent-bit-qnap.conf  # NAS-side log collection
│   │   ├── fluent-bit-vm.conf    # GCP VM Apache logs
│   │   ├── parsers-qnap.conf     # Syslog & JSON parsers
│   │   └── parsers-vm.conf       # Apache log parser with geo
│   └── opensearch/
│       └── geoip-pipeline.json   # MaxMind GeoLite2 enrichment
├── scripts/
│   └── soc-startup.sh            # QNAP boot initialization
├── dashboards/
│   └── (exported .ndjson files)
├── docs/
│   └── architecture.md           # Detailed documentation
└── screenshots/
    └── (dashboard images)
```

---

##  Quick Start

### Prerequisites

- Docker & Docker Compose
- QNAP NAS (or any Linux server with Docker)
- Cloudflare account (free tier works)
- AbuseIPDB API key (free tier: 1000 checks/day)
- MaxMind GeoLite2 license (free)

### Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/brianchaplow/HomeLab-SOC.git
   cd HomeLab-SOC
   ```

2. **Configure environment variables**
   ```bash
   cp configs/.env.example configs/.env
   # Edit .env with your credentials
   ```

3. **Deploy the stack**
   ```bash
   cd configs
   docker-compose up -d
   ```

4. **Access dashboards**
   - OpenSearch Dashboards: `http://<your-ip>:5601`
   - CyberChef: `http://<your-ip>:8000`

See [docs/architecture.md](docs/architecture.md) for detailed setup instructions.

---

##  Dashboards

> Screenshots coming soon

- **NIDS Overview** - Suricata alerts, traffic volume, protocol distribution
- **Web Traffic Analysis** - Visitor fingerprints, geo distribution, threat scores
- **Windows Security** - Sysmon events, process execution, network connections

---

##  Roadmap

- [x] Core SIEM infrastructure (OpenSearch + Fluent Bit)
- [x] Network IDS (Suricata with ET Open rules)
- [x] Automated threat intelligence (AbuseIPDB)
- [x] Edge auto-blocking (Cloudflare API)
- [x] GeoIP enrichment (MaxMind + Cloudflare headers)
- [x] Secure remote access (Tailscale mesh)
- [ ] Sigma rules for Windows detection
- [ ] Atomic Red Team validation
- [ ] Index lifecycle management
- [ ] Additional detection dashboards

---

##  Tech Stack

| Category | Technologies |
|----------|-------------|
| **SIEM** | OpenSearch, OpenSearch Dashboards |
| **Network Security** | Suricata, Zeek |
| **Log Pipeline** | Fluent Bit |
| **Edge Security** | Cloudflare WAF, Bot Fight Mode |
| **Threat Intel** | AbuseIPDB, MaxMind GeoLite2 |
| **Connectivity** | Tailscale (WireGuard) |
| **Containers** | Docker, Docker Compose |
| **Automation** | Python, Cron |
| **Alerting** | Discord Webhooks, Email |

---

##  Author

**Brian Chaplow**

- Website: [brianchaplow.com](https://brianchaplow.com)
- LinkedIn: [linkedin.com/in/brianchaplow](https://linkedin.com/in/brianchaplow)
- GitHub: [@brianchaplow](https://github.com/brianchaplow)

---

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

##  Acknowledgments

- [Emerging Threats Open](https://rules.emergingthreats.net/) - Suricata ruleset
- [SwiftOnSecurity](https://github.com/SwiftOnSecurity/sysmon-config) - Sysmon configuration inspiration
- [AbuseIPDB](https://abuseipdb.com) - Threat intelligence API
- [MaxMind](https://maxmind.com) - GeoIP databases
