# Network Monitoring Server

Network monitoring server for broadcast video flypacks with meta-orchestration capabilities. Each flypack server manages one broadcast network segment while providing centralized monitoring and automation across multiple segments.

## Architecture

**Meta-Orchestration Pattern:**
- **Outer Ansible**: Deploys identical monitoring servers across broadcast segments
- **Inner Ansible**: Embedded within each server for segment-specific device management
- **Flask Web UI**: Unified interface for cross-segment monitoring and orchestration

## Key Features

- **Broadcast Video Optimized**: SRT protocol monitoring, multicast awareness, QoS metrics
- **Real-time Monitoring**: WebSocket-powered dashboards for live video network health
- **Video Device Integration**: SNMP collectors for encoders/decoders/routers
- **Automated Orchestration**: ansible-runner integration for network automation
- **Mobile-First Web UI**: Responsive design for field deployment operations

## Technology Stack

- **Infrastructure**: Debian Bookworm with Netplan systemd-networkd
- **Containerization**: Docker Compose for reliable field deployments
- **Monitoring**: Prometheus + VictoriaMetrics + Grafana 11+
- **Automation**: Ansible 2.17+ with Execution Environments
- **Web Framework**: Flask 3.0+ with Celery async processing

## Quick Start

1. **Prerequisites**
   ```bash
   sudo apt update
   sudo apt install python3.11 python3.11-venv
   ```

2. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd network-monitoring-server
   python3.11 -m venv venv
   source venv/bin/activate
   pip install -e .[dev]
   ```

3. **Run Network Setup Script**
   ```bash
   # On target Debian server via SSH
   sudo ./scripts/setup_network.sh
   ```

4. **Deploy Monitoring Stack**
   ```bash
   ansible-playbook ansible/playbooks/deploy.yml
   ```

## Project Structure

```
network-monitoring-server/
├── memory-bank/             # Persistent project knowledge
├── ansible/                 # Outer orchestration playbooks
│   ├── playbooks/          # Deployment automation
│   ├── roles/              # Reusable automation units
│   └── inventory/          # Server definitions
├── scripts/                # Shell utilities and setup
├── src/                    # Python Flask application
│   ├── monitor_server/    # Core web application
│   └── tests/              # Unit and integration tests
├── docker/                 # Container configurations
│   ├── compose/            # Multi-service stacks
│   └── configs/            # Individual service configs
├── docs/                   # Documentation
└── venv/                   # Python virtual environment
```

## Development

This project follows **strict atomic development** principles:

- Each stage = One complete, working increment (max 3-5 commits)
- All changes must pass quality gates before proceeding
- No "big leaps" - methodical, testable progress only

See `memory-bank/patterns.md` for the complete Atomic Development Manifesto.

### Branching Strategy

- `main`: Production-ready releases
- `stage-N-*`: Feature branches for each atomic stage

### Commit Standards

- **Atomic**: One logical change per commit
- **Verbose**: Detailed commit messages with context
- **Indexed**: Links to changelog and memory bank updates

## Memory Bank

Comprehensive project knowledge stored in `memory-bank/`:
- `patterns.md`: Atomic development manifesto
- `architecture.md`: System design decisions
- `changelog.md`: Detailed change log with git indexing
- `code_style.md`: Coding standards and practices

## Deployment

Three-phase deployment for broadcast flypacks:

1. **Server Provisioning**: Base OS configuration via Ansible
2. **Container Deployment**: Docker Compose stack with monitoring services
3. **Application Setup**: Flask UI and embedded Ansible configuration

## Monitoring Capabilities

- **Network Discovery**: Automatic detection of video devices
- **Real-time Metrics**: Live SRT streams, packet loss, jitter
- **Alerting**: Grafana alerts for video broadcast issues
- **Historical Analysis**: VictoriaMetrics for trend analysis
- **Multi-segment Views**: Cross-flypack monitoring dashboards

## Contributing

1. Review `memory-bank/patterns.md` - Atomic Development Manifesto
2. Create feature branch from latest main
3. Develop in atomic stages with comprehensive testing
4. Update memory bank for all architectural decisions
5. Submit PR with complete changelog documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Changelog

See [memory-bank/changelog.md](memory-bank/changelog.md) for complete change history.
