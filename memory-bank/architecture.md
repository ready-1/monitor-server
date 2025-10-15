# System Architecture

Network Monitoring Server for Broadcast Video Flypacks

## Meta-Orchestration Pattern

### Outer Ansible Layer (Deployment)
- Deploys identical flypack monitoring servers across broadcast segments
- Uses Ansible 2.17+ Execution Environments for containerized automation
- Targets: Fresh Debian Bookworm installations in Parallels VM environments
- Pattern: Replicable server deployment via SSH bootstrapping

### Inner Ansible Layer (Management)
- Embedded ansible-runner within each server for segment operations
- Manages network devices specific to each broadcast segment
- Flask web UI triggers ansible-runner via subprocess/API calls
- Focus: Device configuration, monitoring automation, incident response

### Flask Web Layer (Interface)
- Mobile-first responsive UI for field operations
- WebSocket real-time dashboards for video metrics
- RESTful API for cross-flypack orchestration
- Celery async processing for long-running Ansible jobs

## Technology Stack Rationale

### Infrastructure (Debian Bookworm)
- **Netplan + systemd-networkd**: Official Debian 12+ networking approach
- **Static IP Focus**: Supports broadcast video segment isolation
- **systemd Integration**: Reliable service management for field deployments

### Containerization (Docker Compose)
- **Reliability**: Simpler than K8s, perfect for single-server flypack deployments
- **Isolation**: Clean separation of monitoring stack components
- **Persistence**: Docker volumes for time-series data retention
- **Updates**: Container-based updates without full server redeployment

### Monitoring Stack
- **VictoriaMetrics**: Superior Prometheus integration, better resource usage than InfluxDB
- **Grafana 11+**: AI-assisted dashboard creation, WebSocket real-time updates
- **Prometheus**: Industry standard metrics collection with video-specific exporters
- **Blackbox Exporter**: ICMP/TCP/UDP monitoring for network health

### Automation Stack
- **Ansible Execution Environments**: Modern containerized automation (replaces virtualenvs)
- **ansible-runner**: Embedded execution within Flask application
- **Roles Architecture**: Modular, reusable automation components

## Broadcast Video Optimizations

### Network Requirements
- **Real-time Constraints**: Sub-10ms latency requirements for live video
- **Multicast Support**: IGMP-aware monitoring and configuration
- **QoS Awareness**: DSCP tagging, traffic prioritization
- **Redundancy Patterns**: Dual-path video routing awareness

### Video-Specific Monitoring
- **SRT Metrics**: Secure Reliable Transport stream health
- **MPEG-TS Analysis**: Transport stream error detection
- **Device Discovery**: Automatic identification of encoders, decoders, routers
- **Stream Continuity**: End-to-end video path monitoring

### Field Deployment Considerations
- **Flypack Mobility**: Portable, self-contained server units
- **Resource Constraints**: Optimize for limited compute resources
- **Operational Simplicity**: Touch interfaces, minimal keyboard interaction
- **Environmental Hardening**: Temperature, vibration resistance

## Flypack Deployment Pattern

```
Broadcast Segment A (Flypack-01)
├── Server: Debian + Docker Stack
├── Monitor: Networks 192.168.1.0/24, 10.0.0.0/16
├── Devices: 50 encoders, 20 routers, 100 endpoints
└── Management: Embedded Ansible + Web UI

Broadcast Segment B (Flypack-02)
├── Server: Debian + Docker Stack
├── Monitor: Networks 192.168.2.0/24, 10.0.32.0/19
├── Devices: 75 encoders, 30 routers, 150 endpoints
└── Management: Embedded Ansible + Web UI

Central Coordination (Future)
├── Web UI: Cross-flypack monitoring overview
├── Federation: Metrics aggregation across all flypacks
└── Orchestration: Coordinated network-wide changes
```

## Integration Patterns

### Real-time WebSocket Streaming
```python
# Flask + WebSockets for live metrics
@sock.route('/metrics/stream/<flypack_id>')
def stream_metrics(flypack_id):
    while True:
        # Stream VictoriaMetrics data via WebSocket
        yield f"data: {prometheus_query('video_stream_health{flypack_id}')}\n\n"
        time.sleep(0.1)  # 10Hz updates for video monitoring
```

### Embedded Ansible Execution
```python
# Flask endpoint triggers ansible-runner
@app.route('/ansible/run/<playbook>')
def run_ansible(playbook):
    job = celery_run_ansible.delay(playbook, request.args)
    return {'job_id': job.id, 'status': 'queued'}
```

### Docker Compose Isolation
```yaml
# docker-compose.yml - Self-contained monitoring stack
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - monitoring

  victoriametrics:
    image: victoriametrics/victoriametrics:latest
    volumes:
      - vm_data:/victoriametrics-data
    networks:
      - monitoring
```

## Scaling Considerations

### Horizontal Scaling (Multiple Flypacks)
- **Metrics Federation**: Prometheus Federation for cross-flypack aggregation
- **Web UI Federation**: Single pane of glass for all flypack monitoring
- **Ansible Tower/AWX**: Centralized job scheduling (future enhancement)

### Vertical Scaling (Larger Segments)
- **VictoriaMetrics Clustering**: Distributed time-series storage
- **Prometheus Federation**: Hierarchical monitoring architecture
- **Resource Optimization**: Container resource limits and QoS

## Security Architecture

### Network Isolation
- **Flypack Segmentation**: Each monitoring server isolated to its segment
- **Management VPN**: Secure access to web UIs across flypacks
- **Encrypted Communications**: TLS 1.3 for all external interfaces

### Application Security
- **User Authentication**: Role-based access (viewer/operator/admin)
- **API Security**: JWT tokens with expiration and refresh
- **Ansible Execution**: Sandboxed playbook execution with resource limits

### Operational Security
- **Updates**: Automated security patching in containers
- **Auditing**: Comprehensive logging and audit trails
- **Backup**: Encrypted backups with integrity verification

---
Last Updated: Stage 0 (Project Initialization)
