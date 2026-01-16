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

## Phone Number Crawler

A standalone Ruby script that crawls Latvian government websites to extract phone numbers and stores them in Redis.

### Usage

```bash
# Run the crawler
ruby crawler.rb

# Clear Redis data before crawling (optional)
CLEAR_REDIS=true ruby crawler.rb

# Specify custom Redis URL (optional)
REDIS_URL=redis://localhost:6379 ruby crawler.rb
```

### Features

- Crawls all URLs from `government_websites.json`
- Extracts Latvian phone numbers in various formats:
  - Local: `22811907`
  - International: `+37122811907`, `0037122811907`
  - With separators: `22-81-19-07`, `(22) 81 19 07`
- Normalizes all numbers to international format: `37122811907`
- Stores results in Redis with phone number as key and URLs as values
- Handles network errors and timeouts gracefully
- Progress logging and error reporting

## Environment Variables

- `REDIS_URL`: Redis connection string (default: `redis://localhost:6379`)
- `CLEAR_REDIS`: Set to 'true' to clear Redis before crawling

## Endpoints

- `GET /` - Health check, returns "OK"
- `GET /search?number=<phone>` - Search for phone number

## Phone Number Formats

Supports Latvian phone numbers in formats:
- Local: `22811907`
- International: `+37122811907`

All numbers are normalized to: `37122811907`
