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

## End-to-End Testing

Comprehensive Playwright-based end-to-end tests that verify the complete user flow: frontend input → backend search → Redis lookup → results display.

### Test Setup

```bash
# Install dependencies (includes Playwright)
bundle install

# Install Playwright browsers
npx playwright install

# Start Redis (required for tests)
redis-server

# In a separate terminal, start the backend server
ruby app.rb
```

### Running Tests

```bash
# Run all e2e tests
bundle exec ruby spec/e2e_test.rb

# Run tests with verbose output
bundle exec ruby spec/e2e_test.rb --verbose
```

### Test Coverage

The e2e tests include 18+ test cases covering:

**Happy Path Tests:**
- ✅ Local format phone number search (22811907)
- ✅ International format with plus (+37122811907) 
- ✅ International format with spaces (+371 228 119 07)
- ✅ Search with Enter key
- ✅ URL links are clickable and properly formatted

**No Results Tests:**
- ✅ Phone number not found (37199999999)
- ✅ Invalid phone number format validation

**UI/UX Interaction Tests:**
- ✅ Loading state visible during search
- ✅ Clear button resets form
- ✅ Multiple searches without page refresh
- ✅ New search clears previous results
- ✅ Input validation error cleared on new input
- ✅ Page title and headers present
- ✅ Focus on input field on page load

**Additional Format Tests:**
- ✅ Phone numbers with dashes (22-81-19-07)
- ✅ Phone numbers with parentheses ((22) 81 19 07)
- ✅ Empty search submission validation

### Test Data

Before each test run, Redis is automatically populated with test data:

```json
{
  "37122811907": ["https://example.gov.lv", "https://test.gov.lv"],
  "37166123456": ["https://another.gov.lv"],
  "37167890123": ["https://ministry.gov.lv", "https://office.gov.lv", "https://info.gov.lv"],
  "37129123456": ["https://health.gov.lv"],
  "37123456789": ["https://education.gov.lv"]
}
```

### Test Features

- **Fresh Browser Instance**: Each test starts with a clean browser state
- **Automatic Redis Setup**: Test data is populated before each test
- **Explicit Waits**: Tests wait for elements to appear (no hardcoded delays)
- **Screenshot on Failure**: Failed tests automatically save screenshots to `spec/screenshots/`
- **JavaScript Error Detection**: Tests check for console errors
- **Clean Test Isolation**: Each test is independent with proper setup/teardown

### Test Structure

```
spec/
├── e2e_test.rb          # Main test suite with 18+ test cases
└── test_helper.rb       # Test utilities and Redis setup
```

### Requirements

- **Backend Server**: Must be running on `localhost:4567`
- **Redis**: Must be available and running
- **Playwright Browsers**: Chromium browser installed via `npx playwright install`
