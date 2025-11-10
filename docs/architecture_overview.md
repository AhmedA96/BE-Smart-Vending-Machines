# VNDG-ME Backend Architecture Overview

## Deployment Architecture

The VNDG-ME backend is deployed using **Kamal**, a container orchestration tool that manages application containers and their dependencies across servers.

### Service Information

- **Service Name**: `vndgme`
- **Container Image**: `vndg-me/backend`
- **Image Registry**: GitHub Container Registry (ghcr.io)

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT REQUESTS                         │
│                       (Web Browser/API)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REVERSE PROXY & SSL                          │
│                  (HTTPS with Let's Encrypt)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER NETWORK / SERVER                      │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │          RAILS WEB CONTAINER (vndgme)                  │     │
│  │                                                        │     │
│  │  ┌────────────────┐          ┌─────────────────┐       │     │
│  │  │  Puma Server   │          │  Solid Queue    │       │     │
│  │  │                │          │  (Job Processor)│       │     │
│  │  │ WEB_CONCUR: 2  │          │ JOB_CONCUR: 3   │       │     │
│  │  └────────┬───────┘          └────────┬────────┘       │     │
│  │           │                           │                │     │
│  └───────────┼───────────────────────────┼────────────────┘     │
│              │                           │                      │
│     ┌────────▼──────────┐     ┌──────────▼────────┐             │
│     │   PostgreSQL      │     │   Redis Cache     │             │
│     │   Container       │     │   Container       │             │
│     │ (postgis:latest)  │     │  (redis:7.0)      │             │
│     │   Port: 5432      │     │  Port: 6379       │             │
│     └────────┬──────────┘     └──────────┬────────┘             │
│              │                           │                      │
│  ┌───────────▼───────────────────────────▼────────┐             │
│  │        PERSISTENT VOLUMES                      │             │
│  │                                                │             │
│  │  • DB Data: /var/lib/postgresql/data           │             │
│  │  • Cache Data: /data                           │             │
│  │  • Rails Storage: /rails/storage               │             │
│  └────────────────────────────────────────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Infrastructure Components

#### Web Server

- **Server IP**: Configured in deployment
- **Protocol**: HTTPS (SSL enabled via Let's Encrypt)
- **Web Concurrency**: 2 processes per server
- **Container Runtime**: Docker

#### Database Layer

- **Type**: PostgreSQL with PostGIS extension
- **Image**: `postgis/postgis:latest`
- **Port**: 5432
- **Database User**: `vndgme`
- **Storage**: Persistent volume (`data:/var/lib/postgresql/data`)

#### Cache Layer

- **Type**: Redis
- **Image**: `redis:7.0`
- **Port**: 6379
- **Storage**: Persistent volume (`data:/data`)

#### Application Storage

- **Volume**: `vndgme_storage:/rails/storage`
- **Purpose**: Persistent storage for Solid Queue and Active Storage files
- **Recommendation**: Should be backed up off-server in production

### Job Processing

- **Job Queue**: Solid Queue (built into Rails 8)
- **Execution Mode**: In-Puma mode (runs within the web server process)
- **Job Concurrency**: 3 dedicated processes
- **Note**: When scaling to multiple servers, job processing should be moved to a dedicated server

### Environment Configuration

#### Environment Variables (Secrets)

- `RAILS_MASTER_KEY` - Rails encryption key
- `POSTGRES_PASSWORD` - Database password

#### Environment Variables (Clear)

- `SOLID_QUEUE_IN_PUMA: true` - Run job supervisor in Puma
- `JOB_CONCURRENCY: 3` - Dedicated job processes
- `WEB_CONCURRENCY: 2` - Web server processes
- `POSTGRES_HOST: vndgme-db` - Database host (via Kamal docker network)
- `POSTGRES_USER: vndgme` - Database user
- `RAILS_ENV` - Rails environment (dev/staging/production)
- `RAILS_LOG_LEVEL: debug` - Logging level

### Docker Build Configuration

- **Architecture**: amd64
- **Build Context**: Repository root (`.`)
- **SSH User**: ubuntu (for remote operations)

### Deployment Tools & Commands

Kamal provides convenient aliases for common operations:

- `bin/kamal console` - Access Rails console in container
- `bin/kamal shell` - Access shell in container
- `bin/kamal logs` - View application logs
- `bin/kamal dbc` - Access database console

### Network & Security

- **SSL/TLS**: Enabled via Let's Encrypt auto-certification
- **Docker Network**: Uses Kamal's internal docker network for service-to-service communication
- **Registry Authentication**: GitHub Container Registry with personal access token
- **Proxy Configuration**: Reverse proxy with SSL termination

## Development & Deployment Flow

1. Docker image is built and pushed to `ghcr.io/vndg-me/backend`
2. Image is pulled to server
3. Services are orchestrated via Kamal:
   - PostgreSQL container (with PostGIS)
   - Redis container
   - Rails application container (web + job processing)
4. All services communicate through Kamal's docker network
5. Reverse proxy handles SSL termination and routing to web server
