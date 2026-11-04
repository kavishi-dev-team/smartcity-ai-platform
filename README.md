# Smart City AI Platform

An AI-enabled Smart City Management Platform developed as a university group project. The platform aims to improve urban services through a mobile application, backend APIs, database management, and AI-assisted features.

## Project Goals

- Centralize smart city services.
- Support citizen issue reporting and tracking.
- Provide dashboards and analytics.
- Explore AI-assisted urban management.
- Build a modular and maintainable platform.

## Technology Stack

- **Mobile App:** Flutter, Dart
- **Backend:** Python, FastAPI
- **Database:** MySQL
- **ORM:** SQLAlchemy
- **Database Migrations:** Alembic
- **Containerization:** Docker, Docker Compose
- **CI/CD:** GitHub Actions

## Project Structure

```text
smartcity-ai-platform/
├── backend/             # FastAPI backend
├── frontend/
│   └── smart_city_app/  # Flutter mobile application
├── deployment/          # Deployment scripts
├── docs/                # Project documentation
├── migrations/          # Database migrations
├── tests/
│   ├── api/             # API tests
│   ├── integration/     # Integration tests
│   └── unit/            # Unit tests
├── .github/workflows/   # GitHub Actions
├── docker-compose.yml
├── .env.example
└── README.md
\
