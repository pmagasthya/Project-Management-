# Project Deployment Guide

## Local Development Setup

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- PostgreSQL 14+ (if not using Docker)
- Redis 7+ (if not using Docker)
- Git

### Quick Start with Docker Compose

```bash
# Clone repository
git clone https://github.com/yourusername/Project-Management-.git
cd Project-Management-

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop all services
docker-compose down
```

Services will be available at:
- Frontend: http://localhost:3000
- Backend: http://localhost:3001
- Database: localhost:5432
- Redis: localhost:6379

---

## Production Deployment

### Option 1: Vercel (Frontend) + Railway (Backend)

**Frontend Deployment**:
```bash
# Deploy to Vercel
npm install -g vercel
cd frontend
vercel --prod
```

**Backend Deployment**:
```bash
# Via Railway CLI
cd backend
railway link
railway up --detach
```

### Option 2: AWS Deployment

**Frontend** (S3 + CloudFront):
```bash
cd frontend
npm run build
aws s3 sync out/ s3://your-bucket/
```

**Backend** (ECS/Fargate):
```bash
# Build Docker image
docker build -t pm-backend:latest .

# Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag pm-backend:latest <account>.dkr.ecr.us-east-1.amazonaws.com/pm-backend:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/pm-backend:latest

# Update ECS service
aws ecs update-service --cluster pm-cluster --service pm-backend --force-new-deployment
```

### Option 3: Kubernetes (GKE/AKS/EKS)

**Build and Push Images**:
```bash
# Frontend
docker build -t gcr.io/project-id/pm-frontend:v1.0 frontend/
docker push gcr.io/project-id/pm-frontend:v1.0

# Backend
docker build -t gcr.io/project-id/pm-backend:v1.0 backend/
docker push gcr.io/project-id/pm-backend:v1.0
```

**Deploy with Helm**:
```bash
# Add Helm repository
helm repo add project-management https://charts.example.com
helm repo update

# Install
helm install pm project-management/pm-platform \
  --namespace production \
  --values values.yaml

# Upgrade
helm upgrade pm project-management/pm-platform \
  --namespace production \
  --values values.yaml
```

**Kubernetes Manifests**:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pm-frontend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pm-frontend
  template:
    metadata:
      labels:
        app: pm-frontend
    spec:
      containers:
      - name: frontend
        image: gcr.io/project-id/pm-frontend:v1.0
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "https://api.projecthub.io/api"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pm-backend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pm-backend
  template:
    metadata:
      labels:
        app: pm-backend
    spec:
      containers:
      - name: backend
        image: gcr.io/project-id/pm-backend:v1.0
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: REDIS_URL
          value: "redis://redis:6379"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: pm-frontend-svc
  namespace: production
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  selector:
    app: pm-frontend
---
apiVersion: v1
kind: Service
metadata:
  name: pm-backend-svc
  namespace: production
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3001
  selector:
    app: pm-backend
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pm-backend-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pm-backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## Environment Configuration

### Frontend (.env.production)
```bash
NEXT_PUBLIC_API_URL=https://api.projecthub.io/api
NEXT_PUBLIC_WS_URL=https://api.projecthub.io
NEXT_PUBLIC_ENV=production
NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

### Backend (.env.production)
```bash
NODE_ENV=production
PORT=3001

# Database
DATABASE_URL=postgresql://user:password@db-host:5432/pm_db
DATABASE_SSL=true

# Redis
REDIS_URL=redis://redis-host:6379

# JWT
JWT_SECRET=<very-long-random-secret>
JWT_EXPIRATION=3600

# OAuth
GOOGLE_CLIENT_ID=<from-gcp>
GOOGLE_CLIENT_SECRET=<from-gcp>
GITHUB_CLIENT_ID=<from-github>
GITHUB_CLIENT_SECRET=<from-github>

# AWS S3
AWS_ACCESS_KEY_ID=<from-aws>
AWS_SECRET_ACCESS_KEY=<from-aws>
AWS_REGION=us-east-1
AWS_S3_BUCKET=project-management-prod

# Email (SendGrid)
SENDGRID_API_KEY=<from-sendgrid>

# Sentry
SENTRY_DSN=<from-sentry>
```

---

## Database Migrations

### Running Migrations
```bash
# Generate migration from schema changes
npm run typeorm migration:generate src/migrations/MigrationName

# Run pending migrations
npm run typeorm migration:run

# Revert last migration
npm run typeorm migration:revert

# Show migration status
npm run typeorm migration:show
```

### Backup Strategy
```bash
# PostgreSQL backup
pg_dump -h host -U user dbname > backup_$(date +%Y%m%d).sql

# Restore from backup
psql -h host -U user dbname < backup_20240115.sql

# Automated backup with AWS RDS
aws rds create-db-snapshot \
  --db-instance-identifier pm-db \
  --db-snapshot-identifier pm-db-backup-$(date +%Y%m%d)
```

---

## Monitoring & Observability

### Prometheus Metrics
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'pm-backend'
    static_configs:
      - targets: ['localhost:9090']
```

### Grafana Dashboard
- CPU usage
- Memory usage
- Request latency
- Error rates
- Database query performance
- Redis cache hit ratio

### Logging with ELK Stack
```bash
# Start ELK stack
docker-compose -f docker-compose.elk.yml up -d

# Forward backend logs to Elasticsearch
# Configure in NestJS:
import { ElasticsearchModule } from '@nestjs/elasticsearch';
```

### Error Tracking (Sentry)
```typescript
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});
```

---

## CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm run test
      
      - name: Run linter
        run: npm run lint

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy frontend
        run: npm run deploy:frontend
      
      - name: Deploy backend
        run: npm run deploy:backend
```

---

## Scaling Considerations

### Horizontal Scaling
1. **Multiple API Instances** behind load balancer
2. **Database Read Replicas** for read-heavy queries
3. **Redis Cluster** for distributed caching
4. **CDN** for static asset delivery

### Vertical Scaling
- Increase instance memory/CPU
- Upgrade database tier
- Optimize database queries
- Implement caching strategies

### Load Balancing
```nginx
upstream backend {
    server api1.example.com:3001;
    server api2.example.com:3001;
    server api3.example.com:3001;
}

server {
    listen 80;
    server_name api.projecthub.io;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Security Hardening

### SSL/TLS
```bash
# Generate certificates with Let's Encrypt
certbot certonly --standalone -d api.projecthub.io

# Auto-renewal
certbot renew --quiet --no-self-upgrade
```

### DDoS Protection
- CloudFlare or AWS Shield
- Rate limiting middleware
- IP whitelist for internal services

### Database Security
- Enable encryption at rest
- Use strong passwords
- Restrict network access
- Enable audit logging

---

## Disaster Recovery

### Backup Strategy
- Daily automated backups
- Weekly snapshots
- Monthly archive to cold storage
- Test restore procedures monthly

### RTO/RPO Targets
- RTO: 1 hour
- RPO: 15 minutes

### Failover Procedure
1. Alert operations team
2. Promote read replica to primary
3. Update DNS/load balancer
4. Verify data consistency
5. Resume normal operations

---

**Last Updated**: July 20, 2026
**Version**: 1.0.0
