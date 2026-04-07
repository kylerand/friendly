# Friendly — Deployed Architecture

> Last updated: 2026-02-13

## System Overview

```mermaid
graph TB
  subgraph Clients
    Mobile["📱 Mobile App<br/><i>React Native + Expo</i><br/><i>TestFlight / App Store</i>"]
    Web["🖥️ Web Portal<br/><i>React 19 + Vite</i><br/><i>Vercel</i>"]
    Device["💡 Ambient Device<br/><i>TypeScript</i><br/><i>Not yet deployed</i>"]
  end

  subgraph "Railway"
    Backend["⚙️ Backend API<br/><i>FastAPI · Python 3.12+</i><br/><i>Docker on Railway</i>"]
  end

  subgraph "Supabase (Managed)"
    Auth["🔐 Supabase Auth<br/><i>Email/Password · Magic Link</i>"]
    DB["🗄️ PostgreSQL<br/><i>RLS Enabled</i>"]
  end

  Mobile -- "REST + JWT" --> Backend
  Web -- "REST + JWT<br/>(admin endpoints)" --> Backend
  Device -. "REST polling<br/>(planned)" .-> Backend

  Mobile -- "Auth SDK<br/>(signup/login/OTP)" --> Auth
  Web -- "Auth SDK<br/>(admin login)" --> Auth

  Backend -- "supabase-py<br/>service_role key" --> DB
  Auth -- "trigger: handle_new_user" --> DB

  style Device stroke-dasharray: 5 5
```

## Deployment Map

```mermaid
graph LR
  subgraph "App Distribution"
    EAS["Expo EAS Build"]
    TF["TestFlight / App Store"]
    EAS --> TF
  end

  subgraph "Hosting"
    Railway["Railway<br/>(Backend Docker)"]
    Vercel["Vercel<br/>(Web Portal)"]
    Supabase["Supabase<br/>(DB + Auth)"]
  end

  TF -. "users install" .-> Railway
  Vercel -. "admin traffic" .-> Railway
  Railway --> Supabase
```

## Authentication Flow

```mermaid
sequenceDiagram
  participant U as User
  participant App as Mobile / Web
  participant SA as Supabase Auth
  participant API as Backend (Railway)
  participant DB as Supabase Postgres

  U->>App: Enter email + password (or magic link)
  App->>SA: signUp / signIn / signInWithOtp
  SA-->>App: JWT (access_token + refresh_token)
  App->>App: Store session (AsyncStorage / localStorage)

  U->>App: Use the app
  App->>API: REST request + Authorization: Bearer <JWT>
  API->>API: Verify JWT (HS256 w/ Supabase secret)
  API->>DB: Query via supabase-py (service_role)
  DB-->>API: Data
  API-->>App: JSON response
```

## Data Flow

```mermaid
flowchart LR
  subgraph "Mobile App"
    UI[Screens & Components]
    Nav[Navigation]
    Svc[Services Layer]
    WE[Warmth Engine<br/><i>client-side</i>]
    LN[Local Notifications<br/><i>expo-notifications</i>]
  end

  subgraph "Backend API"
    R[Routers]
    S[Services]
    MW[Auth Middleware]
  end

  subgraph "Supabase"
    PG[(PostgreSQL)]
  end

  UI --> Nav --> Svc
  Svc -- "fetch + JWT" --> MW --> R --> S --> PG
  WE -- "/nudges/warmth" --> R
  LN -. "scheduled locally" .-> UI
```

## Backend API Surface

```mermaid
graph LR
  subgraph "Public"
    Health["/health"]
  end

  subgraph "Authenticated"
    AuthR["/auth<br/>me, profile"]
    Profiles["/profiles<br/>CRUD, search"]
    Friends["/friendships<br/>create, accept, pause"]
    Interactions["/interactions<br/>log contacts"]
    CheckIns["/check-ins<br/>self-assessments"]
    Ambient["/ambient<br/>signals"]
    Nudges["/nudges<br/>warmth tiers"]
    Signals["/signals<br/>care signals, beacons"]
    FriendNotes["/friend-notes<br/>private notes"]
    Tester["/tester<br/>bug reports"]
  end

  subgraph "Admin Only"
    Admin["/admin<br/>metrics, users,<br/>friendships, admins"]
  end
```

## Database Schema

```mermaid
erDiagram
  auth_users ||--|| profiles : "trigger creates"
  profiles ||--o{ friendships : "user_id"
  profiles ||--o{ friendships : "friend_id"
  profiles ||--o{ check_ins : "user_id"
  profiles ||--o{ interactions : "user_id"
  profiles ||--o{ interactions : "target_id"
  profiles ||--o{ ambient_signals : "user_id"
  profiles ||--o{ friend_notes : "user_id"
  profiles ||--o{ tester_reports : "user_id"
  profiles ||--o| device_state : "owner_id"
  profiles ||--o| admin_users : "user_id"
  profiles ||--o| user_roles : "user_id"

  profiles {
    uuid id PK
    text display_name
    text avatar_url
    text phone_number
    text email
  }

  friendships {
    uuid id PK
    uuid user_id FK
    uuid friend_id FK
    text status "pending | confirmed | paused | archived"
  }

  check_ins {
    uuid id PK
    uuid user_id FK
    int comfort "1-5"
    int connection "1-5"
    int energy "1-5"
    text notes
  }

  interactions {
    uuid id PK
    uuid user_id FK
    uuid target_id FK
    text type
    jsonb metadata
  }

  ambient_signals {
    uuid id PK
    uuid user_id FK
    text signal_type
    float value
    text[] tags
  }

  friend_notes {
    uuid id PK
    uuid user_id FK
    uuid friend_id FK
    text content
  }

  tester_reports {
    uuid id PK
    uuid user_id FK
    text type
    text title
    text description
    text severity
    text status
  }

  device_state {
    uuid id PK
    uuid owner_id FK
    text device_name
    jsonb state
  }

  admin_users {
    uuid user_id PK
    text role "admin | super_admin"
  }

  user_roles {
    uuid user_id PK
    text role "pilot | tester"
  }
```

## Infrastructure Summary

| Component | Stack | Host | Notes |
|-----------|-------|------|-------|
| **Mobile App** | React Native + Expo (TS) | TestFlight / App Store | Bundle ID: `com.kylerand.friendly` |
| **Web Portal** | React 19 + Vite (TS) | Vercel | Admin dashboard |
| **Backend API** | FastAPI (Python 3.12+) | Railway (Docker) | `/health` endpoint for probes |
| **Database** | PostgreSQL | Supabase | RLS enabled on all tables |
| **Auth** | Supabase Auth | Supabase | Email/password + magic link + OTP |
| **Build Pipeline** | Expo EAS | Expo | Project: `ea2d376b-...` |
| **Ambient Device** | TypeScript | _Not deployed_ | State machine scaffold for hardware display |

## Key Design Decisions

- **No direct DB writes from clients** — all data mutations go through the backend API
- **Supabase client on mobile/web is auth-only** — used for signup, login, token management
- **Backend uses service_role key** — bypasses RLS for cross-user queries (nudges, admin)
- **No server-side push notifications yet** — client-side local scheduling via `expo-notifications`
- **No background jobs or cron** — all computation is request-driven
- **Anti-metrics by design** — engagement metrics explicitly forbidden (no DAU, session length, CTR)
