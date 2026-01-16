# Latvian Phone Number Search App

A web application for searching Latvian phone numbers on government websites, featuring a Sinatra backend and a single-file HTML frontend.

## Setup

```bash
bundle install
```

## Local Development

```bash
# Create .env file with Redis URL
cp .env.example .env
# Edit .env with your Redis configuration

# Start the backend server
ruby app.rb

# Open the frontend in your browser
open index.html
# Or simply double-click the index.html file
```

The backend runs on `http://localhost:4567` by default.

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

## Web Frontend

A single-file HTML frontend (`index.html`) that provides a user-friendly interface for searching phone numbers.

### Features

- Single, self-contained HTML file (no build process required)
- Mobile-responsive design
- Client-side phone number validation
- Supports both local and international formats
- Real-time search with loading states
- Clear error messages and user feedback
- Clickable results that open in new tabs

### Usage

Simply open `index.html` in your browser:

```bash
open index.html
```

Or double-click the file in your file explorer.

### Configuration

To change the backend URL, edit line 307 in `index.html`:

```javascript
const BACKEND_URL = 'http://localhost:4567';
```

For production deployment, change this to your backend's URL.

### Phone Number Input

The frontend accepts phone numbers in various formats:
- Local: `22811907`
- International: `+37122811907`
- With separators: `+371 228 11907`, `22-81-19-07`, `(22) 81 19 07`

All formats are automatically normalized before searching.
