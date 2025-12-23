# HomeLab SOC Configuration Files

This directory contains the configuration files for the HomeLab SOC infrastructure.

## Directory Structure

```
configs/
├── .env.example           # Environment variables template
├── docker-compose.yml     # SOC container stack definition
├── fluent-bit/
│   ├── fluent-bit-qnap.conf   # QNAP NAS log aggregation
│   ├── fluent-bit-vm.conf     # GCP VM Apache log shipping
│   ├── parsers-qnap.conf      # QNAP parsers (syslog, json)
│   └── parsers-vm.conf        # VM parsers (Apache with geo)
└── opensearch/
    └── geoip-pipeline.json    # GeoIP enrichment pipeline
```

## Setup Instructions

### 1. Environment Variables

```bash
cp .env.example .env
# Edit .env with your actual credentials
```

### 2. QNAP Fluent Bit

Copy to QNAP:
```bash
scp -P 2222 fluent-bit/fluent-bit-qnap.conf bchaplow@192.168.50.10:/share/Container/SOC/ingestion/fluentbit/fluent-bit.conf
scp -P 2222 fluent-bit/parsers-qnap.conf bchaplow@192.168.50.10:/share/Container/SOC/ingestion/fluentbit/parsers.conf
```

### 3. GCP VM Fluent Bit

Copy to VM:
```bash
gcloud compute scp fluent-bit/fluent-bit-vm.conf wordpress-1-vm:/etc/fluent-bit/fluent-bit.conf --zone=us-east4-a
gcloud compute scp fluent-bit/parsers-vm.conf wordpress-1-vm:/etc/fluent-bit/parsers.conf --zone=us-east4-a
```

Then restart:
```bash
gcloud compute ssh wordpress-1-vm --zone=us-east4-a --command="sudo systemctl restart fluent-bit"
```

### 4. OpenSearch GeoIP Pipeline

Create the ingest pipeline:
```bash
curl -sk -u admin -X PUT 'https://192.168.50.10:9200/_ingest/pipeline/geoip-enrichment' \
  -H 'Content-Type: application/json' \
  -d @opensearch/geoip-pipeline.json
```

### 5. Docker Compose

Deploy the stack:
```bash
cd /share/Container/SOC/compose
docker-compose up -d
```

## Security Notes

- **Never commit `.env` to version control**
- All configs use environment variables for sensitive data
- Tailscale IP (100.110.112.98) is used for VM → QNAP communication
- TLS verification is disabled for self-signed certs (lab environment only)

## Network Requirements

| Source | Destination | Port | Purpose |
|--------|-------------|------|---------|
| GCP VM | QNAP (Tailscale) | 9200 | Fluent Bit → OpenSearch |
| Browser | QNAP | 5601 | OpenSearch Dashboards |
| Syslog sources | QNAP | 5514 | Syslog ingestion |
| Browser | QNAP | 8000 | CyberChef |
