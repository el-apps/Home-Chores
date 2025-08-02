# Home-Chores
*A simple, self-hosted family chore tracker*

Home-Chores is a lightweight web application for managing household tasks. Designed for families, it prioritizes offline functionality, data privacy, and seamless synchronization across devices without relying on third-party services.

![Elm](https://img.shields.io/badge/Elm-0.19.1-1293D8) ![Go](https://img.shields.io/badge/Go-1.24-00ADD8) ![simple-sync](https://img.shields.io/badge/simple--sync-Alpha-orange)

## Features

### 🎯 MVP
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
- **Backend**: [simple-sync](https://github.com/kwila-cloud/simple-sync) (Go-based sync server)
- **Database**: [SQLite](https://www.sqlite.org/) (File-based, zero config - *managed by simple-sync*)
- **Deployment**: [Docker](https://www.docker.com/) (Single container setup)

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/el-apps/Home-Chores.git
   cd Home-Chores
   ```
2.  **Clone the simple-sync repository**:
    ```bash
    git clone https://github.com/kwila-cloud/simple-sync.git
    ```
3. **Start the applications**:
   ```bash
   docker-compose up -d
   ```
4. **Access the app**:
   - Frontend: http://localhost:8000
   - simple-sync API: http://localhost:8080
5. **Your data persists** in `./data/chores.db` - even after container restarts! (*managed by simple-sync*)

## Development Setup

### Frontend (Elm)
```bash
cd frontend
elm reactor  # Development server at http://localhost:8000
elm make src/Main.elm --output=main.js  # Build for production
```

### Backend (simple-sync)
See the [simple-sync](https://github.com/kwila-cloud/simple-sync) repository for instructions on how to run the backend.

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
| `POST` | `/events`         | Push client's diff history to the server |
| `GET`  | `/events`         | Retrieve the authoritative event history |

*These endpoints are provided by `simple-sync`. See the [simple-sync API documentation](https://github.com/kwila-cloud/simple-sync/blob/main/docs/api.md) for more details.*

### Example Usage

To sync your chores data, you'll interact with the `/events` endpoint. Here's an example of pushing local changes:

```bash
curl -X POST http://localhost:8080/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_JWT_TOKEN>" \
  -d '[
    {
      "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "timestamp": 1678886400,
      "userUuid": "user123",
      "itemUuid": "chore-abc123",
      "action": "create",
      "payload": "{ \"title\": \"Take out trash\", \"recurrence\": \"weekly\", \"due_day\": 2 }"
    }
  ]'
```

## Deployment

### Production Docker Stack
```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    image: ghcr.io/kwila-cloud/simple-sync:latest
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
   Device A (Home) → simple-sync → Device B (Phone)
        ↑                  ↓                 ↑
   Local Storage         Sync Engine        Local Storage
   ```

### Synchronization Process
1. Devices store data locally.
2. Periodically (or when network reconnects), the client:
   - Sends local changes to the `/events` endpoint.
   - Receives the latest authoritative event history from the `/events` endpoint.
   - Updates local storage with the merged data.

*This synchronization is handled by `simple-sync`. See the [simple-sync documentation](https://github.com/kwila-cloud/simple-sync/blob/main/README.md) for more details.*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
