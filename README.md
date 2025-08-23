# Home-Chores
*A simple, self-hosted family chore tracker*

Home-Chores is a lightweight web application for managing household chores. Designed for families, it prioritizes offline functionality, data privacy, and seamless synchronization across devices without relying on third-party services.

![Elm](https://img.shields.io/badge/Elm-0.19.1-1293D8) ![simple-sync](https://img.shields.io/badge/simple--sync-Alpha-orange)

**NOTE** - This project is in the alpha stage. Many of the things documented here and elsewhere in this repo do not actually exist yet.

## Features

### 🎯 MVP
- **One-time chores**: Add non-repeating chores
- **Offline-first**: Fully functional without internet connection
- **Cross-device sync**: Automatic synchronization when devices reconnect
- **Self-hosted**: Your data stays in your home (no third-party providers)

### 🔜 Future Ideas
- **Weekly chores**: Create repeating tasks that reset every week
- **Chore assignments**: Assign chores to family members
- **Completion history**: Track who completed which chores

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
1.  **Create a `.env` file** in the root directory with the following content:
   ```
   JWT_SECRET=your_generated_jwt_secret
   ```
   Replace `your_generated_jwt_secret` with a securely generated random string. You can generate one using `openssl rand -base64 32`.
1. **Start the applications**:
   ```bash
   docker-compose up -d
   ```
1. **Access the app**:
   - Frontend: http://localhost:8000
   - simple-sync API: http://localhost:8080

1. **Your data persists** in the `data` volume - even after container restarts! (*managed by simple-sync*)

## Development Setup

### Frontend (Elm)
```bash
cd app
./run.sh  # Development server with auto-reload at http://localhost:8000
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
