# Cloudflare + ALB Integration Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           INTERNET                               │
│                      User's Browser                              │
│                   (requests api.example.com)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ https://api.example.com
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      CLOUDFLARE EDGE                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ DNS Resolution (CNAME)                                   │  │
│  │ api.example.com → vnd-abc123.me-central-1.elb.aws...    │  │
│  │                                                           │  │
│  │ Features:                                                 │  │
│  │ • DDoS Protection                                         │  │
│  │ • Caching (optional)                                      │  │
│  │ • Rate Limiting                                           │  │
│  │ • WAF Rules (optional)                                    │  │
│  │ • SSL/TLS (Flexible, Full, or Full Strict)              │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS/HTTP (based on Cloudflare setting)
                             │ Proxied via Cloudflare or DNS Only
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│         AWS REGION: me-central-1 (Middle East - UAE)             │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │     APPLICATION LOAD BALANCER (ALB)                        │  │
│  │                                                             │  │
│  │  - Internal: false (internet-facing)                       │  │
│  │  - Subnets: public_a, public_b (2 AZs)                    │  │
│  │  - Port 80: HTTP → 301 Redirect to HTTPS                 │  │
│  │  - Port 443: HTTPS (ACM Certificate)                      │  │
│  │  - Target Group: App servers (port 80)                    │  │
│  │  - Health Check: /up (every 30s)                          │  │
│  │  - Sticky Sessions: 24 hours                              │  │
│  └────────┬──────────────────────────────────────┬───────────┘  │
│           │                                      │                │
│      AZ-a │                                AZ-b │                │
│           │                                      │                │
│           ↓                                      ↓                │
│  ┌─────────────────────┐          ┌──────────────────────┐      │
│  │ PRIVATE APP SUBNET  │          │ PRIVATE APP SUBNET   │      │
│  │ (10.0.2.x)          │          │ (10.0.3.x)           │      │
│  │                     │          │                      │      │
│  │ App Servers (ASG)   │          │ App Servers (ASG)    │      │
│  │ 2-4 instances       │          │ (standby)            │      │
│  │ t3.micro            │          │ t3.micro             │      │
│  │ Port 80: kamal-proxy│          │ Port 80: kamal-proxy │      │
│  │                     │          │                      │      │
│  │ Docker Containers   │          │ Docker Containers    │      │
│  │ • Rails app         │          │ • Rails app          │      │
│  │ • Puma web server   │          │ • Puma web server    │      │
│  │                     │          │                      │      │
│  └─────────────────────┘          └──────────────────────┘      │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         MANAGED SERVICES (Single AZ: AZ-a)              │    │
│  │                                                           │    │
│  │  Aurora PostgreSQL (RDS)                                │    │
│  │  • Endpoint: xxx.cluster-xxx.rds.amazonaws.com          │    │
│  │  • Port: 5432                                           │    │
│  │  • Database: vendingdb                                  │    │
│  │  • Backup retention: 7 days                             │    │
│  │                                                           │    │
│  │  ElastiCache Redis                                      │    │
│  │  • Endpoint: xxx.cache.amazonaws.com                    │    │
│  │  • Port: 6379                                           │    │
│  │  • Replication group: Yes (primary + replica)          │    │
│  │                                                           │    │
│  │  S3 + Cloudflare R2 (Storage)                           │    │
│  │  • Backups                                              │    │
│  │  • Media uploads                                        │    │
│  │  • CDN via Cloudflare                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              BASTION HOST (Jump Host)                    │    │
│  │                                                           │    │
│  │  • Public IP: 40.172.242.129                            │    │
│  │  • Used for SSH to private app servers                  │    │
│  │  • SSH proxy in kamal config                            │    │
│  │  • Kamal deployment gateway                             │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Traffic Flow Sequence

### 1. DNS Resolution

```
Client Browser              Cloudflare DNS           AWS Route53
    │                            │                        │
    │ resolve api.example.com    │                        │
    │──────────────────────────→ │                        │
    │                            │                        │
    │                   (CNAME record exists)             │
    │                            │                        │
    │        returns ALB DNS      │                        │
    │ ←──────────────────────────│                        │
    │                            │                        │
    │ ← ← ← → → → → → → → → → → → → → ALB IP Address → → → → →
```

### 2. HTTPS Connection

```
Client Browser                                      AWS ALB
    │                                                 │
    │ TLS Handshake                                  │
    │ (ClientHello)                                  │
    │────────────────────────────────────────────→  │
    │                                                │
    │                          Server Certificate    │
    │ ←──────────────────────────────────────────── │
    │ (ACM Certificate: *.example.com)              │
    │                                                │
    │ TLS Handshake Complete                        │
    │ (shared encryption key established)           │
    │────────────────────────────────────────────→  │
    │                                                │
    │ HTTPS Request                                  │
    │ (encrypted with TLS)                          │
    │────────────────────────────────────────────→  │
    │                                                │
    │                          Forward to App Server │
    │                          (port 80 HTTP)        │
    │                                │               │
    │                                ↓               │
    │                           App Server           │
    │                           (docker container)   │
    │                                │               │
    │                         Process Request        │
    │                                │               │
    │                         HTTP 200 OK            │
    │ ←──────────────────────────────────────────── │
    │                                                │
    │ HTTPS Response                                 │
    │ (encrypted with TLS)                          │
    │ ←──────────────────────────────────────────── │
    │                                                │
    │ ← ← ← ← ← (display in browser)
```

### 3. Deployment Flow

```
Developer Machine           Bastion Host         AWS Instances
    │                           │                    │
    │ kamal deploy               │                    │
    │──────────────────────────→ │                    │
    │                            │ SSH through proxy  │
    │                            │──────────────────→ │
    │                            │                    │
    │                            │    Fetch docker    │
    │                            │ ←──────────────────│
    │                            │ from ghcr.io       │
    │                            │                    │
    │                            │ Start container    │
    │                            │──────────────────→ │
    │                            │                    │
    │                            │ Health check: /up  │
    │                            │ ←──────────────────│
    │                            │    200 OK          │
    │                            │                    │
    │ ← ← ← deployment complete ←│ ← ← ← ← ← ← ← ← ←│
    │
    │ kamal logs (watch)
    │──────────────────────────→ (tail logs from docker)
```

---

## Infrastructure Components

### DNS Layer (Cloudflare)

| Component        | Function                                  | Notes                     |
| ---------------- | ----------------------------------------- | ------------------------- |
| **DNS Record**   | CNAME: api.example.com → ALB DNS          | Terraform managed         |
| **Proxy Status** | Orange Cloud (proxied) or Gray (DNS only) | Configurable              |
| **SSL/TLS**      | Flexible, Full, or Full (strict)          | Recommend: Full (strict)  |
| **TTL**          | 3600 seconds (1 hour)                     | Terraform managed         |
| **Validation**   | ACM validation records (CNAMEs)           | Auto-created by Terraform |

### Load Balancer Layer (AWS ALB)

| Component                | Configuration                   | Purpose                  |
| ------------------------ | ------------------------------- | ------------------------ |
| **Type**                 | Application Load Balancer (ALB) | Layer 7 routing          |
| **Subnets**              | public_a, public_b              | 2 AZs for HA             |
| **Security Group**       | Allow 80, 443 from world        | Internet-facing          |
| **HTTP Listener**        | Port 80                         | Redirects to HTTPS (301) |
| **HTTPS Listener**       | Port 443 + ACM cert             | Terminates TLS           |
| **Target Group**         | App servers on port 80          | Health check: /up        |
| **Stickiness**           | 24-hour cookie                  | Session affinity         |
| **Deregistration Delay** | 30 seconds                      | Connection draining      |

### Application Layer (Docker)

| Component              | Configuration                    | Details                |
| ---------------------- | -------------------------------- | ---------------------- |
| **Container Registry** | GHCR (GitHub Container Registry) | Private Docker images  |
| **Base Image**         | Ubuntu 22.04                     | kamal-managed          |
| **Web Server**         | Puma (Rails default)             | Port 80 in container   |
| **Proxy**              | kamal-proxy                      | HTTP/WebSocket support |
| **Process Manager**    | systemd                          | Service auto-restart   |
| **Deployment**         | Kamal                            | Rails deployment tool  |

### Database Layer (AWS Aurora)

| Component       | Configuration              | Details                 |
| --------------- | -------------------------- | ----------------------- |
| **Engine**      | PostgreSQL 16.x compatible | Aurora PostgreSQL       |
| **Instance**    | db.t3.small                | Single instance (AZ-a)  |
| **Backup**      | 7-day retention            | Automated snapshots     |
| **Maintenance** | Sunday 04:00-05:00 UTC     | Auto updates            |
| **Connection**  | Single AZ (cost optimized) | No cross-AZ replication |

### Cache Layer (ElastiCache)

| Component    | Configuration           | Details                     |
| ------------ | ----------------------- | --------------------------- |
| **Engine**   | Redis 7.0               | Session + job queue storage |
| **Instance** | cache.t3.micro          | Cost optimized              |
| **Mode**     | Cluster mode disabled   | Single primary + replicas   |
| **Nodes**    | 2 (primary + 1 replica) | Automatic failover          |
| **Snapshot** | Daily 03:00-05:00 UTC   | Data persistence            |

---

## Security Layers

### Network Security

```
┌──────────────────────────────────────────────────┐
│ LAYER 1: Cloudflare                              │
│ • DDoS Protection                                │
│ • Rate Limiting (optional)                       │
│ • WAF Rules (optional)                           │
│ • Geographic Blocking (optional)                 │
└──────────────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────────────┐
│ LAYER 2: AWS Security Groups                     │
│ • ALB: Allow 80, 443 from world                 │
│ • App: Allow 80 from ALB only                   │
│ • DB: Allow 5432 from app servers only          │
│ • Redis: Allow 6379 from app servers only       │
│ • Bastion: Allow 22 from admin IPs only         │
└──────────────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────────────┐
│ LAYER 3: TLS/SSL                                 │
│ • Client ↔ Cloudflare: HTTPS                    │
│ • Cloudflare ↔ ALB: HTTP or HTTPS (configurable)│
│ • ALB ↔ App: HTTP (private subnet)              │
│ • App ↔ DB: Encrypted connection (via RDS)      │
└──────────────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────────────┐
│ LAYER 4: Application Security                    │
│ • Rails CSRF Protection                          │
│ • JWT Token Authentication                       │
│ • API Rate Limiting (controller level)           │
│ • Secrets Management (AWS Secrets Manager)       │
└──────────────────────────────────────────────────┘
```

---

## Scaling Architecture

### Horizontal Scaling

```
Normal Traffic
────────────────────────────
         │
    ALB + Health Check
         │
    ┌────┴────┐
    │          │
    ↓          ↓
 App-1      App-2      ← 2 instances running
(healthy)  (healthy)

High Traffic
────────────────────────────
         │
    ALB + Health Check
         │
    ┌────┬────┬─────┐
    │    │    │     │
    ↓    ↓    ↓     ↓
 App-1 App-2 App-3 App-4  ← ASG scales to 4 instances
(all healthy)

Low Traffic
────────────────────────────
         │
    ALB + Health Check
         │
    ┌────┘
    │
    ↓
  App-1      ← ASG scales down to 1 instance
(healthy)
```

### Auto Scaling Groups

| Group            | Min | Desired | Max | Trigger   |
| ---------------- | --- | ------- | --- | --------- |
| **App (Web)**    | 1   | 2       | 4   | CPU > 70% |
| **Worker (Job)** | 1   | 2       | 5   | CPU > 60% |

---

## Certificate Management

### ACM Certificate Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│ Day 1: Create Certificate Request                       │
│   aws_acm_certificate created in Terraform              │
│   Status: PENDING_VALIDATION                            │
│                                                          │
│ ↓                                                        │
│                                                          │
│ Day 1: Create Validation Records                        │
│   Cloudflare DNS records created for validation         │
│   Status: ACM waiting for DNS validation                │
│                                                          │
│ ↓                                                        │
│                                                          │
│ Day 1-3: Validation                                     │
│   AWS checks for DNS records                            │
│   Cloudflare has the records                            │
│   Status: ISSUED                                        │
│                                                          │
│ ↓                                                        │
│                                                          │
│ Days 1-364: Active Certificate                          │
│   ALB uses certificate for HTTPS                        │
│   Clients trust the certificate                         │
│                                                          │
│ ↓                                                        │
│                                                          │
│ Days 335-364: Auto-Renewal (30 days before expiry)      │
│   AWS ACM automatically renews                          │
│   No action needed                                      │
│   Certificate swapped seamlessly                        │
│                                                          │
│ ↓                                                        │
│                                                          │
│ Day 365: New Certificate Active                         │
│   Process repeats                                       │
│   Clients never see expiry                              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow Example: User Request to Health Check

```
1. User (Browser)                           api.example.com/up
                                           │
                                     DNS lookup
                                           │
2. Cloudflare Edge                   api.example.com
                                     CNAME record
                                           │
                                vnd-xyz123.elb.aws...
                                           │
3. AWS ALB (Public IP)              203.0.113.45:443
                                    TLS Handshake
                                           │
                         ACM Certificate validation
                                           │
4. ALB HTTPS Listener                 PORT 443
                              SSL/TLS Termination
                                           │
                           Forward to Target Group
                                           │
5. Target Group Health Check               /up
                                     GET /up HTTP/1.1
                                           │
6. App Server (Private IP)         10.0.2.46:80
                                   kamal-proxy
                                           │
                                   Rails app
                                           │
                          HTTP 200 OK
                         {"status":"ok"}
                                           │
7. ALB Response Processing           Wrap in HTTPS
                                           │
                         HTTP 200 with HTML/JSON
                                           │
8. User Browser              Unwrap HTTPS
                                    Display
                                           │
9. Display Result           ✓ UP and healthy
```

---

## Deployment Sequence

```
┌─────────────────────────────────────────────────────────────────┐
│ TERRAFORM APPLY (Initial Setup)                                  │
│                                                                   │
│ 1. Create VPC and Subnets                                        │
│ 2. Create Security Groups                                        │
│ 3. Create ALB in public subnets                                 │
│ 4. Create Target Group with health checks                       │
│ 5. Create ACM Certificate (PENDING_VALIDATION)                  │
│ 6. Create Cloudflare DNS record                                 │
│ 7. Create Cloudflare ACM validation records                     │
│ 8. Enable ACM validation (wait for certificate)                 │
│ 9. Create Aurora RDS Database                                   │
│ 10. Create ElastiCache Redis                                    │
│ 11. Create Auto Scaling Groups (app + workers)                  │
│ 12. Create Bastion Host (jump server)                           │
│ 13. Outputs: ALB DNS, RDS endpoint, Redis endpoint              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ KAMAL DEPLOY (Application Deployment)                            │
│                                                                   │
│ 1. Pre-deploy hook: Sync instance IPs from AWS                  │
│ 2. Build Docker image (with BuildKit cache)                     │
│ 3. Push image to GHCR (GitHub Container Registry)               │
│ 4. SSH to instances via Bastion (proxy)                         │
│ 5. Pull image from GHCR                                         │
│ 6. Stop old container (if exists)                               │
│ 7. Start new container with:                                    │
│    - Database credentials                                       │
│    - Redis connection                                           │
│    - Rails master key                                           │
│    - Environment variables                                      │
│ 8. Run health check: GET /up                                    │
│ 9. Wait for ALB health checks to pass                           │
│ 10. Remove old image (cleanup)                                  │
│ 11. Log output from deployment                                  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ SERVICE RUNNING (Steady State)                                   │
│                                                                   │
│ Client Requests:                                                 │
│  → Cloudflare DNS (CNAME) → ALB → Target Group → App → Response │
│                                                                   │
│ Health Checks (Every 30 seconds):                                │
│  → ALB → App (/up endpoint) → HTTP 200 OK → Mark healthy        │
│                                                                   │
│ Auto Scaling (Continuous):                                       │
│  → Monitor CPU usage                                             │
│  → Scale up if CPU > 70% (app) or > 60% (worker)               │
│  → Scale down if CPU < 30% (app) or < 20% (worker)             │
│                                                                   │
│ Database & Cache:                                                │
│  → Automated backups (daily)                                     │
│  → Connection pooling                                            │
│  → Automatic failover (if enabled)                              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Reference Diagram: Complete Network Map

```
                          ┌─────────────────────┐
                          │   INTERNET USERS    │
                          │  (Global)           │
                          └──────────┬──────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
          ┌─────────▼────────┐      │       ┌────────▼──────────┐
          │  Cloudflare      │      │       │  Cloudflare       │
          │  (US-based)      │      │       │  (EU-based)       │
          │  Edge Server     │      │       │  Edge Server      │
          │  • DNS Cache     │      │       │  • DNS Cache      │
          │  • DDoS Protect  │      │       │  • DDoS Protect   │
          └─────────┬────────┘      │       └────────┬──────────┘
                    └────────────────┼────────────────┘
                                     │
                    (CNAME: api.example.com)
                    (Points to ALB DNS name)
                                     │
                    ┌────────────────┼────────────────┐
                    │   AWS Region: me-central-1      │
                    │   (Middle East - UAE)           │
                    │                                 │
            ┌───────▼────────────────────────────────────────┐
            │ PUBLIC SUBNETS (for ALB)                       │
            │                                                 │
            │  AZ-a (public_a)    │    AZ-b (public_b)      │
            │                     │                          │
            │  ┌──────────────┐   │   ┌──────────────┐     │
            │  │ NAT Gateway  │   │   │ NAT Gateway  │     │
            │  │ (outbound)   │   │   │ (outbound)   │     │
            │  └──────────────┘   │   └──────────────┘     │
            │                     │                          │
            │  ┌───────────────────────────────────────────┐│
            │  │    APPLICATION LOAD BALANCER (ALB)         ││
            │  │    Internal: false (internet-facing)       ││
            │  │    Scheme: internet-facing                 ││
            │  │    Port 80 (HTTP) → 301 to HTTPS          ││
            │  │    Port 443 (HTTPS) → Forward to targets  ││
            │  │    SSL Certificate: *.example.com (ACM)   ││
            │  │    Target Group: app-targets              ││
            │  │    Health Check: /up (30s interval)       ││
            │  └────────┬──────────────┬─────────────────┘ │
            │           │              │                    │
            └───────────┼──────────────┼────────────────────┘
                        │              │
        ┌───────────────┼──────────────┼───────────────┐
        │               │              │               │
     AZ-a           Private subnet  Private subnet    AZ-b
        │            (app_1)         (app_2)          │
        │               │              │               │
    ┌───▼────────────┐  │   ┌──────────▼──────┐   ┌──┴───────────┐
    │ PRIVATE APP    │  │   │ PRIVATE APP      │   │ PRIVATE APP  │
    │ SUBNET AZ-a    │  │   │ SUBNET AZ-b      │   │ SUBNET AZ-b  │
    │ (10.0.2.x)     │  │   │ (10.0.3.x)       │   │ (10.0.3.x)   │
    │                │  │   │                  │   │              │
    │ App Servers    │  │   │ App Servers      │   │ Worker       │
    │ (ASG)          │  │   │ (ASG)            │   │ Servers      │
    │ • 10.0.2.46    │  │   │ • 10.0.3.78      │   │ (ASG)        │
    │ • 10.0.2.50    │  │   │ • 10.0.3.200     │   │ • 10.0.3.x   │
    │                │  │   │                  │   │              │
    │ Docker:        │  │   │ Docker:          │   │ Docker:      │
    │ • Rails        │  │   │ • Rails          │   │ • Sidekiq    │
    │ • kamal-proxy  │  │   │ • kamal-proxy    │   │ • Async jobs │
    │ • Port 80      │  │   │ • Port 80        │   │ • Port 80    │
    └────────────────┘  │   └──────────────────┘   └──────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    ┌───▼────────┐  ┌──▼──────┐  ┌────▼─────────┐
    │  PRIVATE   │  │ PRIVATE │  │  PRIVATE DB  │
    │  DB SUBNET │  │ CACHE   │  │  SUBNET      │
    │  AZ-a      │  │ SUBNET  │  │  (both AZs)  │
    │  (10.0.4.x)│  │ AZ-a    │  │  (10.0.5.x)  │
    │            │  │(10.0.6.)│  │              │
    │ Aurora RDS │  │         │  │ Aurora RDS   │
    │ PostgreSQL │  │ Redis   │  │ PostgreSQL   │
    │ • Primary  │  │ Cache   │  │ • Replica    │
    │ • db.t3... │  │ t3.micro│  │ • Standby    │
    │ • Port5432 │  │ Port6379│  │ • Port 5432  │
    └────────────┘  └─────────┘  └──────────────┘
                        │
                ┌───────┴───────┐
                │               │
            S3 + Cloudflare R2 Storage
            • Backups
            • Media uploads
            • CDN
```

---

This architecture provides:

- ✅ High Availability (Multi-AZ)
- ✅ Auto-Scaling (load-based)
- ✅ Security (TLS, private subnets)
- ✅ Managed Services (RDS, ElastiCache)
- ✅ Global CDN (Cloudflare)
- ✅ Cost Optimization (t3 instances)
