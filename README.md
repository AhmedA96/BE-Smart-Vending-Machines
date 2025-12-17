## VNDG-ME Backend – New Joiner Guide

Welcome! This guide helps you clone, build, run, and seed the app quickly. Keep it simple: Docker is the easiest path; local is supported too.

---

### Naming Conventions

Across all docs and code comments, we use explicit service names and avoid internal codenames. Examples:

- DNS: Cloudflare DNS
- Load Balancer: AWS Application Load Balancer (ALB)
- Auto Scaling: AWS Auto Scaling Groups (ASG)

If you see any alias in older materials, prefer the explicit service name.

---

### 1) Project Overview

Backend API for VNDG-ME powering ordering, users, payments, catalog, and admin.

- Orders and payments
- Users auth (email/OTP, OAuth) and roles
- Catalog, search, and locations
- Admin via Avo

---

### 2) Tech Stack

- Ruby 3.4.2, Rails 8
- PostgreSQL + PostGIS
- Devise, Doorkeeper (OAuth2), Pundit, Rolify
- Avo (admin)
- Solid Queue (background jobs)
- Ransack, pg_search (search/filter)
- PaperTrail (auditing)
- Rswag (API docs/specs)

---

### 3) Getting Started (Docker – recommended)

Prerequisite: Docker Desktop installed.

1. Clone the repo

```bash
git clone <https://github.com/yourusername/vndgme-backend.git>
cd backend
```

2. Start Postgres (PostGIS)

```bash
docker run -d --name vndgme-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgis/postgis:16-3.4
```

3. Build the app image

```bash
make build
# or
docker build -t vndgme:latest .
```

4. Run the app
   Set your Rails master key (required for production boot). If you have `config/master.key`:

```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
```

Then start the container (connects to DB via host.docker.internal):

```bash
docker run -d --name vndgme -p 80:80 \
  -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  -e POSTGRES_HOST=host.docker.internal \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  vndgme:latest
```

The entrypoint runs `bin/rails db:prepare` on boot. Visit http://localhost

5. Seed the database

```bash
docker exec vndgme ./bin/rails db:seed
```

Handy Docker commands:

```bash
docker logs -f vndgme        # tail logs
docker stop vndgme           # stop app
docker rm vndgme             # remove app container
docker stop vndgme-db && docker rm vndgme-db   # remove DB
docker rmi vndgme:latest     # remove image
```

Makefile shortcuts:

```bash
make build   # build image
make logs    # docker logs
make stop    # docker stop
make clean   # remove container and image
```

---

### 4) Getting Started (Local – optional)

Prerequisites: Ruby 3.4.2, PostgreSQL + PostGIS.

```bash
make setup   # bundle install + db:prepare + db:seed
make dev     # run dev server (bin/dev)
```

App runs on http://localhost:3000 in dev.

---

### 5) Tests, Lint, Security

```bash
make test         # RSpec
make lint         # RuboCop
make lint-fix     # RuboCop auto-correct
make security     # Brakeman + bundle-audit
```

---

### 6) API Docs

If enabled, Swagger UI (Rswag) is typically available at /api-docs when running locally.

---

### 7) Troubleshooting

- Missing master key: export `RAILS_MASTER_KEY` (matches `config/credentials.yml.enc`).
- DB connection: ensure DB is running and `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD` match. With Docker Desktop on macOS, `host.docker.internal` points to the host where the DB port 5432 is published.
