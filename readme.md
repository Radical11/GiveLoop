# GiveLoop — Backend API

**GiveLoop** is a charity donation platform that connects donors with verified charities. Built with Django & Django REST Framework, it features real-time WebSocket updates, gamification (GiveCoins & badges), team challenges, and a secure donation pledge system.

---

## 🚀 Features

| Feature | Description |
| --- | --- |
| **JWT Authentication** | Secure registration & login with SimpleJWT (access + refresh tokens) |
| **Role-Based Access** | Donors & Charity Admins have distinct permissions |
| **Charity Management** | Charity Admins can create charities and post need requests |
| **Secure Donations** | Atomic, race-condition-safe pledge system using F() expressions |
| **Gamification** | GiveCoins awarded on donation confirmation with urgency multipliers |
| **Badge System** | Auto-unlocking badges based on donation count, coins earned, streaks |
| **Team Challenges** | Create/join teams with shared donation goals |
| **Impact Updates** | Charities post photos & updates for completed donations |
| **Real-Time WebSockets** | Live progress updates via Django Channels |
| **Swagger Docs** | Interactive API docs via drf-spectacular |

---

## 📁 Project Structure

```
giveloop/
├── api/
│   ├── models.py          # User, Charity, NeedRequest, Donation, etc.
│   ├── serializers.py      # DRF serializers with validation
│   ├── views.py            # API views & viewsets
│   ├── urls.py             # API URL routing
│   ├── signals.py          # Business logic (pledging, gamification, badges)
│   ├── consumers.py        # WebSocket consumer for live progress
│   ├── routing.py          # WebSocket URL routing
│   ├── permissions.py      # Custom role-based permissions
│   ├── admin.py            # Django admin registration
│   ├── tests.py            # Comprehensive test suite
│   └── management/
│       └── commands/
│           └── seed_data.py  # Demo data seeder
├── giveloop/
│   ├── settings.py         # Django settings (env-configurable)
│   ├── urls.py             # Root URL config
│   ├── asgi.py             # ASGI + WebSocket protocol routing
│   └── wsgi.py             # WSGI application
├── requirements.txt
├── Procfile                # Deployment (Railway/Render)
├── manage.py
└── .env                    # Environment variables (not committed)
```

---

## 🛠️ Setup

### Prerequisites
- Python 3.10+
- pip

### Installation

```bash
# Clone the repository
git clone https://github.com/Radical11/GiveLoop.git
cd GiveLoop

# Switch to backend branch
git checkout backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
echo 'DATABASE_URL=your_database_url_here' > .env
# Or leave empty to use SQLite

# Run migrations
python manage.py migrate

# Seed demo data
python manage.py seed_data

# Start development server
python manage.py runserver
```

### Running Tests

```bash
python manage.py test api -v2
```

---

## 📡 API Endpoints

| Endpoint | Method | Auth | Description |
| --- | --- | --- | --- |
| `/api/auth/register/` | POST | — | Register new user |
| `/api/auth/login/` | POST | — | Get JWT tokens |
| `/api/auth/token/refresh/` | POST | — | Refresh access token |
| `/api/users/profile/` | GET, PATCH | ✅ | View/edit own profile |
| `/api/users/leaderboard/` | GET | — | Top donors by GiveCoins |
| `/api/charities/` | GET, POST | —/Admin | List/create charities |
| `/api/charities/<id>/needs/` | GET, POST | —/Admin | List/create need requests |
| `/api/needs/` | GET | — | List all need requests |
| `/api/donations/pledge/` | POST | Donor | Create donation pledge |
| `/api/donations/history/` | GET | ✅ | View donation history |
| `/api/teams/` | GET, POST | ✅ | List/create teams |
| `/api/teams/<id>/join/` | POST | ✅ | Join a team |
| `/api/teams/<id>/leave/` | POST | ✅ | Leave a team |
| `/api/badges/` | GET | — | List all badges |
| `/api/badges/mine/` | GET | ✅ | View earned badges |
| `/api/impact-updates/` | GET, POST | —/Admin | Impact updates |
| `/api/schema/swagger-ui/` | GET | — | Interactive API docs |

### WebSocket

```
ws://<host>/ws/needs/<need_id>/progress/
```

Receives live JSON updates:
```json
{"qty_pledged": 25, "qty_needed": 50}
```

---

## 🎮 Gamification Rules

- **Base Coins:** 10 per item donated
- **Urgency Multiplier:** Need urgency (1–5) applied as multiplier
- **Fulfilment Bonus:** +100 coins when your donation completes a need
- **Badges:** Auto-unlock based on donation count, coin thresholds, and streaks

---

## 🚢 Deployment

Ready for **Railway** or **Render** deployment:

1. Set environment variables:
   - `DATABASE_URL` — PostgreSQL connection string
   - `DJANGO_SECRET_KEY` — Production secret key
   - `DJANGO_DEBUG` — `False`
   - `DJANGO_ALLOWED_HOSTS` — Your domain(s)

2. Uses `uvicorn` via `Procfile` for ASGI (HTTP + WebSocket support)

---

## 🔐 Demo Credentials

After running `python manage.py seed_data`:

| Username | Password | Role |
| --- | --- | --- |
| `hopeorg_admin` | `giveloop2026` | Charity Admin |
| `greenearth_admin` | `giveloop2026` | Charity Admin |
| `alice_donor` | `giveloop2026` | Donor |
| `bob_donor` | `giveloop2026` | Donor |
| `carol_donor` | `giveloop2026` | Donor |
| `dave_donor` | `giveloop2026` | Donor |
| `eve_donor` | `giveloop2026` | Donor |

---

## 📄 License

MIT