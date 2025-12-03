# Docker Deployment Guide

This guide explains how to deploy the application with Docker and configure the API URL.

## Understanding Vite Environment Variables

**Important**: Vite environment variables are embedded at **build time**, not runtime. This means the API URL is baked into the JavaScript bundle during the build process.

## Building with Docker

### Method 1: Docker Build Command

Build with custom API URL:

```bash
docker build --build-arg VITE_API_URL=https://api.production.com -t minhasenhavazou-ui .
```

Build with default (localhost:3000):

```bash
docker build -t minhasenhavazou-ui .
```

Run the container:

```bash
docker run -p 80:80 minhasenhavazou-ui
```

### Method 2: Docker Compose

1. Create a `.env` file (or copy from `.env.docker`):

```bash
VITE_API_URL=https://api.production.com
```

2. Build and run:

```bash
docker-compose up --build
```

## Dockerfile Explanation

The Dockerfile accepts `VITE_API_URL` as a build argument:

```dockerfile
ARG VITE_API_URL=http://localhost:3000
ENV VITE_API_URL=$VITE_API_URL
RUN yarn build
```

- `ARG`: Defines a build-time variable
- `ENV`: Sets it as an environment variable so Vite can access it
- Default value: `http://localhost:3000`

## Environment Files

- `.env` - Local development (used by Vite dev server)
- `.env.example` - Template for developers
- `.env.docker` - Template for Docker deployment
- `.gitignore` - Excludes `.env` and `.env.local` from git

## Production Deployment

For production, set the API URL during build:

```bash
docker build --build-arg VITE_API_URL=https://api.yourdomain.com -t app .
```

Or use docker-compose with environment variables in your CI/CD pipeline.
