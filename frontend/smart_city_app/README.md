## Waste Issues API — Manual Testing

Tested locally on 24 October 2026 using FastAPI and MySQL.

| Test | Observed result | Status |
|---|---|---|
| List waste issues before adding test data | Empty items list with total 0 | Passed |
| Get issue 1 before adding test data | Waste issue not found | Passed |
| List waste issues after adding test data | Test report returned with Colombo location | Passed |
| Get existing waste issue 1 | Correct report details and location returned | Passed |

### Endpoints

- GET /api/v1/issues?category=waste&offset=0&limit=20
- GET /api/v1/issues/{issue_id}

### Local setup

Run these commands from the backend directory:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload