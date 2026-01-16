# Latvian Phone Number Search App

A minimal Sinatra backend for searching Latvian phone numbers on government websites.

## Setup

```bash
bundle install
```

## Local Development

```bash
# Create .env file with Redis URL
cp .env.example .env
# Edit .env with your Redis configuration

# Run locally
ruby app.rb
```

## Environment Variables

- `REDIS_URL`: Redis connection string (default: `redis://localhost:6379`)

## Endpoints

- `GET /` - Health check, returns "OK"
- `GET /search?number=<phone>` - Search for phone number

## Phone Number Formats

Supports Latvian phone numbers in formats:
- Local: `22811907`
- International: `+37122811907`

All numbers are normalized to: `37122811907`
