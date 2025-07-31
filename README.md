# Home-Chores
*A simple, self-hosted family chore tracker*

Home-Chores is a lightweight web application for managing household tasks. Designed for families, it prioritizes offline functionality, data privacy, and seamless synchronization across devices without relying on third-party services.

![Elm](https://img.shields.io/badge/Elm-0.19.1-blue) ![Go](https://img.shields.io/badge/Go-1.24-blue)

## Features

### MVP
- **Weekly chores**: Create repeating tasks that reset every week
- **Offline-first**: Fully functional without internet connection
- **Cross-device sync**: Automatic synchronization when devices reconnect
- **Self-hosted**: Your data stays in your home (no third-party providers)

### 🔜 Upcoming Versions
- **One-time tasks**: Add non-repeating chores
- **Task assignments**: Assign chores to family members
- **Completion history**: Track who completed which tasks

## Architecture

- **Frontend**: [Elm](https://elm-lang.org/) (Reliable UI with no runtime errors)
- **Backend**: [Go](https://go.dev/) (Single binary, lightweight server)
- **Database**: [SQLite](https://www.sqlite.org/) (File-based, zero config)
- **Deployment**: [Docker](https://www.docker.com/) (Single container setup)

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/el-apps/home-chores.git
   cd home-chores
   ```
2. **Start the application**:
   ```bash
   docker-compose up -d
   ```
3. **Access the app**:
   - Frontend: http://localhost:8000
   - Backend API: http://localhost:8080
4. **Your data persists** in `./data/chores.db` - even after container restarts!

## Development Setup

### Frontend (Elm)
```bash
cd frontend
elm reactor  # Development server at http://localhost:8000
elm make src/Main.elm --output=main.js  # Build for production
```

### Backend (Go)
```bash
cd backend
go run main.go  # Development server at http://localhost:8080
go build -o home-chores-server  # Build binary
```

### Environment Variables
| Variable              | Description                     | Default          |
|-----------------------|---------------------------------|------------------|
| `PORT`                | Backend server port             | `8080`           |
| `DB_PATH`             | SQLite database file path       | `./data/chores.db` |
| `SYNC_TOKEN`          | Authentication token (optional) | (none)          |

## API Reference

### Core Endpoints
| Method | Endpoint          | Description                     |
|--------|-------------------|---------------------------------|
| `POST` | `/sync`           | Bidirectional data sync         |
| `GET`  | `/initial-sync`   | Initial data load for new devices |

### Sync Example
```bash
curl -X POST http://localhost:8080/sync \
  -H "Content-Type: application/json" \
  -H "X-Sync-Token: your-secret-token" \
  -d '{
    "last_sync": "2024-06-20T10:30:00Z",
    "client_id": "device-123",
    "chores": [
      {
        "id": "chor-abc123",
        "title": "Take out trash",
        "recurrence": "weekly",
        "due_day": 2,  // Tuesday (0=Sunday)
        "assigned_to": null
      }
    ],
    "completions": []
  }'
```

## Deployment

### Production Docker Stack
```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - SYNC_TOKEN=${SYNC_TOKEN}
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "80:8000"
    depends_on:
      - backend
    restart: unless-stopped
```

### Securing Your Instance
1. **Generate a sync token**:
   ```bash
   openssl rand -base64 32
   ```
2. **Set environment variable**:
   ```bash
   echo "SYNC_TOKEN=your_generated_token" >> .env
   ```
3. **Start with production config**:
   ```bash
   docker-compose --env-file .env up -d
   ```

## How It Works

### Offline-First Architecture
1. **Data Flow**:
   ```
   Device A (Home) → Backend Sync → Device B (Phone)
        ↑                  ↓                 ↑
   Local Storage → Conflict Resolution → Local Storage
   ```

2. **Conflict Resolution**:
   - Simple last-write-wins using timestamps
   - Perfect for family usage (minimal conflicts expected)

3. **Data Storage**:
   ```
   data/
   └── chores.db  (SQLite database file)
   ```

### Synchronization Process
1. Devices store data locally (IndexedDB/browser storage)
2. Every 5 minutes + when network reconnects:
   - Send local changes to backend
   - Receive latest updates from backend
   - Resolve conflicts automatically
   - Update local storage

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

