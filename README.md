# 🏙️ Smart City AI Platform — Complete System Documentation

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![Terraform](https://img.shields.io/badge/Terraform-1.17+-7B42BC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20EIP-FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

An enterprise-ready, AI-augmented municipal management ecosystem designed to streamline citizen issue reporting, municipal service coordination, IoT infrastructure monitoring (Energy, Water, Waste, Traffic), and automated AI-driven urban analytics.

---

## 📋 Table of Contents
- [🌟 Key Capabilities](#-key-capabilities)
- [🏛️ System Architecture](#️-system-architecture)
- [🗄️ Database Entity-Relationship Diagram](#️-database-entity-relationship-diagram)
- [🔄 Core Workflow Diagram](#-core-workflow-diagram)
- [💻 Technology Stack](#-technology-stack)
- [🚀 Quick Start (Local Development)](#-quick-start-local-development)
- [☁️ Cloud Deployment via Terraform (AWS)](#️-cloud-deployment-via-terraform-aws)
- [📱 Mobile Application (Flutter) Setup & APK](#-mobile-application-flutter-setup--apk)
- [📡 API Reference Summary](#-api-reference-summary)
- [🔐 Security & Compliance](#-security--compliance)
- [👥 Contributing & Team](#-contributing--team)

---

## 🌟 Key Capabilities

### 📱 Citizen Mobile Portal
* **One-Tap Issue Reporting**: Geotagged incident reporting with category selection (Roads, Waste, Water, Electricity, Public Safety) and photo upload attachments.
* **Real-Time Issue Lifecycle Tracking**: Transparent status progression (`SUBMITTED` ➔ `ASSIGNED` ➔ `IN_PROGRESS` ➔ `RESOLVED` ➔ `CLOSED`).
* **Municipal Safety Broadcasts**: Real-time push advisories, weather warnings, and emergency SOS guidelines.
* **AI City Assistant**: 24/7 intelligent conversational bot powered by Google Gemini to answer municipal inquiries and assist with city services.

### 🏢 Municipal Operations & Officer Dashboard
* **Department Routing**: Automated department filtering (Water, Energy, Waste, Traffic, Police).
* **Officer Workflow & Internal Notes**: Department-restricted internal triage notes invisible to citizens.
* **IoT Resource Monitors**:
  * **⚡ Energy Management**: Grid load monitoring, transformer capacity, smart meter readings.
  * **💧 Water Utilities**: Reservoir capacity, pipeline flow velocity, anomaly detection.
  * **🗑️ Waste Logistics**: Fill-level telemetry, collection route status, truck allocation.
  * **🚦 Traffic & Safety**: Congestion index, traffic light priority control, safety alerts.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Clients["📱 Client Layer"]
        A["Flutter Mobile App (Android / iOS)"]
        B["Municipal Web Portal (Admin / Officer)"]
    end

    subgraph Gateway["🛡️ Edge & Gateway Layer"]
        C["AWS Elastic IP / DNS"]
        D["Caddy Reverse Proxy (Auto-TLS / Gzip)"]
    end

    subgraph BackendCluster["⚙️ Application Layer (Docker Compose)"]
        E["FastAPI Application (Async ASGI)"]
        F["JWT Authentication & RBAC Engine"]
        G["Alembic Auto-Migration Manager"]
        H["Gemini 2.5 AI Service Engine"]
    end

    subgraph StorageLayer["💾 Data Persistence Layer"]
        I[("MySQL 8.0 Database (EBS Volume)")]
        J[("Media & Asset Storage")]
    end

    subgraph CloudServices["☁️ External Cloud Services"]
        K["Google Gemini API (LLM Analytics)"]
    end

    A -->|"HTTP / REST (Port 80/443)"| C
    B -->|"HTTP / REST (Port 80/443)"| C
    C --> D
    D -->|"Proxy to :8000"| E
    E --> F
    E --> G
    E --> H
    E -->|"SQLAlchemy 2.0 ORM"| I
    E --> J
    H -->|"gRPC / HTTPS"| K
```

---

## 🗄️ Database Entity-Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ ISSUES : reports
    USERS ||--o{ OFFICER_NOTES : writes
    DEPARTMENTS ||--o{ USERS : employs
    DEPARTMENTS ||--o{ ISSUES : manages
    ISSUES ||--o{ ISSUE_PHOTOS : contains
    ISSUES ||--o{ OFFICER_NOTES : has
    USERS ||--o{ SAFETY_ALERTS : broadcasts

    USERS {
        int id PK
        string email UK
        string hashed_password
        string full_name
        string phone
        string role "CITIZEN | OFFICER | ADMIN"
        int department_id FK
        datetime created_at
    }

    DEPARTMENTS {
        int id PK
        string name UK
        string description
        string contact_phone
        string contact_email
    }

    ISSUES {
        int id PK
        string title
        string description
        string category
        string subcategory
        string status "SUBMITTED | ASSIGNED | IN_PROGRESS | RESOLVED"
        string priority "LOW | MEDIUM | HIGH | CRITICAL"
        float latitude
        float longitude
        int citizen_id FK
        int assigned_department_id FK
        int assigned_officer_id FK
        datetime created_at
    }

    ISSUE_PHOTOS {
        int id PK
        int issue_id FK
        string photo_url
        datetime uploaded_at
    }

    OFFICER_NOTES {
        int id PK
        int issue_id FK
        int officer_id FK
        string note_text
        boolean is_internal_only
        datetime created_at
    }

    SAFETY_ALERTS {
        int id PK
        string title
        string alert_level "INFO | WARNING | SEVERE"
        string safety_instructions
        int issued_by FK
        datetime created_at
    }
```

---

## 🔄 Core Workflow Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Citizen as 📱 Citizen
    participant App as Flutter Mobile
    participant Proxy as Caddy Gateway
    participant API as FastAPI Backend
    participant AI as Gemini LLM
    participant DB as MySQL 8.0
    actor Officer as 👮 Municipal Officer

    Citizen->>App: Submits Issue (Photo + GPS + Description)
    App->>Proxy: POST /api/v1/issues
    Proxy->>API: Forward payload
    API->>AI: Analyze sentiment & classify priority
    AI-->>API: Returns Recommended Priority & Category
    API->>DB: INSERT issue record
    DB-->>API: Confirm transaction
    API-->>App: 201 Created (Issue #ID)
    
    Officer->>App: Reviews Department Queue
    App->>API: GET /api/v1/issues?department_id=2
    API->>DB: Query pending tickets
    DB-->>API: Ticket dataset
    API-->>Officer: Display list
    
    Officer->>API: PATCH /api/v1/issues/{id} (Status: RESOLVED)
    API->>DB: UPDATE status & write audit log
    DB-->>API: Updated
    API-->>Citizen: Push Notification ("Issue #ID Resolved")
```

---

## 💻 Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.x / Dart | Cross-platform citizen mobile app (Android & iOS) |
| **Backend API** | FastAPI (Python 3.12) | High-performance asynchronous REST microservices |
| **ASGI Engine** | Uvicorn / Starlette | High-throughput async web server |
| **Database** | MySQL 8.0 Community | ACID-compliant relational data store |
| **ORM & Migrations** | SQLAlchemy 2.0 & Alembic | Schema definition, versioned migrations |
| **AI / Machine Learning** | Google GenAI SDK | Intelligent categorization, chatbots, predictive analytics |
| **Reverse Proxy** | Caddy 2 (Alpine) | Reverse proxy with automatic HTTPS & HTTP/2-3 |
| **Containerization** | Docker & Docker Compose | Multi-container reproducible runtime environment |
| **Cloud Infrastructure** | AWS EC2 & Elastic IP | Cloud hosting on AWS `eu-north-1` |
| **Infra as Code (IaC)** | Terraform 1.17+ | Declarative cloud resource provisioning |
| **CI / CD** | GitHub Actions | Automated linting, pytest validation, container testing |

---

## 🚀 Quick Start (Local Development)

### Prerequisites
* [Docker Desktop](https://www.docker.com/products/docker-desktop) & [Docker Compose](https://docs.docker.com/compose/)
* [Python 3.12+](https://www.python.org/downloads/)
* [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)

### 1. Clone the Repository
```bash
git clone https://github.com/kavishi-dev-team/smartcity-ai-platform.git
cd smartcity-ai-platform
```

### 2. Configure Environment Variables
Copy the template files and fill in your credentials:
```bash
cp backend/.env.example backend/.env
```
Key configuration settings:
```ini
APP_NAME=SmartCityAI
APP_ENV=development
DEBUG=true
API_V1_PREFIX=/api/v1

# MySQL Database
MYSQL_ROOT_PASSWORD=smartcity_root_pw
MYSQL_DATABASE=smart_city_db
MYSQL_USER=smartcity_user
MYSQL_PASSWORD=smartcity_pw
DATABASE_URL=mysql+pymysql://smartcity_user:smartcity_pw@localhost:3306/smart_city_db

# Security & Tokens
SECRET_KEY=generate_a_minimum_32_char_cryptographic_secret
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7

# Optional Google AI / Gemini API
AI_API_KEY=your_gemini_api_key_here
AI_MODEL=gemini-2.5-flash
```

### 3. Run with Docker Compose
Start the backend, database, and reverse proxy in one command:
```bash
docker compose --env-file backend/.env -f docker-compose.prod.yml up -d --build
```
Verify container health:
```bash
docker compose ps
```
The API is immediately available at `http://localhost:8000/docs`.

---

## ☁️ Cloud Deployment via Terraform (AWS)

The platform includes production-grade Infrastructure as Code (IaC) configuration using Terraform.

### Resources Provisioned
* **AWS EC2 Instance**: Ubuntu 24.04 LTS (`t3.small`) with 25GB gp3 storage & 2GB Swap.
* **AWS Elastic IP (EIP)**: Permanent static IPv4 address.
* **Security Group Rules**: Inbound ports `22` (SSH), `80` (HTTP), `443` (HTTPS), and `8000` (FastAPI).
* **Automated Cloud-Init**: Installs Docker, clones the repository, configures `.env.prod`, and starts the production stack.

### Deployment Steps
```bash
cd terraform

# 1. Initialize Terraform providers
terraform init

# 2. Preview the plan (7 resources)
terraform plan

# 3. Apply infrastructure
terraform apply -auto-approve
```

### Terraform Outputs
After provisioning completes, Terraform provides your live endpoints:
```text
Outputs:
api_docs_url        = "http://<YOUR_EIP>/docs"
api_url_http        = "http://<YOUR_EIP>"
api_url_direct_port = "http://<YOUR_EIP>:8000"
ec2_public_ip       = "<YOUR_EIP>"
ssh_command         = "ssh ubuntu@<YOUR_EIP>"
```

---

## 📱 Mobile Application (Flutter) Setup & APK

### 1. Run Flutter App Locally
```bash
cd frontend/smart_city_app

# Fetch dependencies
flutter pub get

# Run on connected simulator or device
flutter run --dart-define=API_BASE_URL=http://<YOUR_API_IP_OR_DOMAIN>
```

### 2. Build Production Release APK
Compile a fully standalone, signed production Android package compatible with Android 7.0 (API 24) through Android 14 (API 34):

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://<YOUR_EC2_PUBLIC_IP>
```

The APK binary will be produced at:
```text
frontend/smart_city_app/build/app/outputs/flutter-apk/app-release.apk
```

### 3. Install on Android Device
Connect your physical phone via USB with USB Debugging enabled:
```bash
adb install -r frontend/smart_city_app/build/app/outputs/flutter-apk/app-release.apk
```
*Or copy `app-release.apk` directly to your phone's storage via USB / Google Drive and tap to install.*

---

## 📡 API Reference Summary

Interactive Swagger UI documentation is available at `/docs` and ReDoc at `/redoc`.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | System health probe | Public |
| `POST` | `/api/v1/auth/register` | Register citizen or officer account | Public |
| `POST` | `/api/v1/auth/login` | Authenticate and obtain JWT access tokens | Public |
| `GET` | `/api/v1/auth/me` | Fetch active user profile | Authenticated |
| `GET` | `/api/v1/issues` | Query reported issues with filters | Authenticated |
| `POST` | `/api/v1/issues` | Report a new issue with geolocation | Citizen / Officer |
| `PATCH` | `/api/v1/issues/{id}` | Update issue status or assign officer | Officer / Admin |
| `POST` | `/api/v1/issues/{id}/notes`| Add internal department note | Officer Only |
| `GET` | `/api/v1/departments` | List municipal departments | Public |
| `GET` | `/api/v1/energy/metrics` | Fetch electrical grid consumption data | Officer / Admin |
| `GET` | `/api/v1/water/status` | Fetch water reservoir & supply metrics | Officer / Admin |
| `GET` | `/api/v1/waste/bins` | Fetch waste bin fill telemetry | Officer / Admin |
| `POST` | `/api/v1/safety/alerts` | Broadcast municipal emergency alert | Admin Only |
| `POST` | `/api/v1/ai/chat` | Send prompt to Gemini City Assistant | Authenticated |

---

## 🔐 Security & Compliance

> [!IMPORTANT]
> The Smart City AI Platform enforces defense-in-depth principles across every architectural tier:

1. **Role-Based Access Control (RBAC)**: Fine-grained authorization differentiating `CITIZEN`, `OFFICER`, and `ADMIN` privileges.
2. **Cryptographic Integrity**: Passwords hashed with `bcrypt` (12 rounds) and access tokens issued using `RS256` / `HS256` JWTs.
3. **Internal Note Isolation**: Officer triage notes and sensitive municipal audit logs are strictly filtered at the database query level to prevent data leakage.
4. **Network Hardening**: Database port `3306` is bound strictly to `127.0.0.1` and internal Docker network, ensuring no direct public exposure.
5. **Cleartext Resilience**: APK includes strict network security config allowing cleartext only for approved development IP addresses, transitioning to strict HTTPS upon custom domain attachment.

---

## 👥 Contributing & Team

Developed as an advanced municipal innovation project by **Kavishi Dev Team**.

* **Repository:** [kavishi-dev-team/smartcity-ai-platform](https://github.com/kavishi-dev-team/smartcity-ai-platform)
* **License:** [MIT License](LICENSE)
