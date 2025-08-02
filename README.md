# Home-Chores
*A simple, self-hosted family chore tracker*

Home-Chores is a lightweight web application for managing household tasks. Designed for families, it prioritizes offline functionality, data privacy, and seamless synchronization across devices without relying on third-party services.

![Elm](https://img.shields.io/badge/Elm-0.19.1-1293D8) ![simple-sync](https://img.shields.io/badge/simple--sync-Alpha-orange)

**NOTE** - This project is in the alpha stage. Many of the things documented here and elsewhere in this repo do not actually exist yet.

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
- **Deployment**: [Docker](https://www.docker.com/) (Single container setup)

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/el-apps/Home-Chores.git
   cd Home-Chores
   ```
1. **Start the applications**:
   ```bash
   docker-compose up -d
   ```
1. **Access the app**:
   - Frontend: http://localhost:8000
   - simple-sync API: http://localhost:8080

1. **Your data persists** in `./data/chores.db` - even after container restarts! (*managed by simple-sync*)

## Development Setup

### Frontend (Elm)
```bash
cd frontend
elm reactor  # Development server at http://localhost:8000
elm make src/Main.elm --output=main.js  # Build for production
```
TODO - add information on how to configure and integrate with [simple-sync](https://github.com/kwila-cloud/simple-sync).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
