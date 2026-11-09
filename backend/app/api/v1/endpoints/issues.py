from datetime import date
import json
import math
from typing import Optional
import urllib.parse
import urllib.request

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, or_, select, text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import Issue, IssueLocation
from app.models.issue_attachment import IssueAttachment
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User
from app.services.ai_analysis_service import analyze_issue
from app.services.issue_details_service import get_issue_details
from app.services.traffic_service import get_traffic_issue, list_traffic_issues
from app.services.waste_service import (
    _build_response as build_waste_response,
    get_waste_issue,
    list_waste_issues,
)

router = APIRouter(prefix="/issues")

# Comprehensive Sri Lankan Towns, Zones & Landmarks Gazetteer
SRI_LANKA_GAZETTEER: list[dict] = [
    {"city": "Colombo 1", "address": "Fort, Colombo 01", "lat": 6.9344, "lon": 79.8428},
    {"city": "Colombo 2", "address": "Slave Island, Colombo 02", "lat": 6.9219, "lon": 79.8507},
    {"city": "Colombo 3", "address": "Kollupitiya, Galle Road, Colombo 03", "lat": 6.9022, "lon": 79.8530},
    {"city": "Colombo 4", "address": "Bambalapitiya, Galle Road, Colombo 04", "lat": 6.8935, "lon": 79.8555},
    {"city": "Colombo 5", "address": "Havelock Town, Colombo 05", "lat": 6.8842, "lon": 79.8665},
    {"city": "Colombo 6", "address": "Wellawatte, Galle Road, Colombo 06", "lat": 6.8741, "lon": 79.8605},
    {"city": "Colombo 7", "address": "Cinnamon Gardens, Independence Ave, Colombo 07", "lat": 6.9099, "lon": 79.8648},
    {"city": "Colombo 8", "address": "Borella Junction, Colombo 08", "lat": 6.9147, "lon": 79.8778},
    {"city": "Colombo 9", "address": "Dematagoda, Colombo 09", "lat": 6.9288, "lon": 79.8789},
    {"city": "Colombo 10", "address": "Maradana Road, Colombo 10", "lat": 6.9271, "lon": 79.8612},
    {"city": "Colombo 11", "address": "Pettah Main Street, Colombo 11", "lat": 6.9367, "lon": 79.8515},
    {"city": "Colombo 12", "address": "Hulftsdorp, Colombo 12", "lat": 6.9364, "lon": 79.8594},
    {"city": "Colombo 13", "address": "Kotahena, Colombo 13", "lat": 6.9478, "lon": 79.8602},
    {"city": "Colombo 14", "address": "Grandpass, Colombo 14", "lat": 6.9475, "lon": 79.8732},
    {"city": "Colombo 15", "address": "Mutwal / Modara, Colombo 15", "lat": 6.9633, "lon": 79.8617},
    {"city": "Dehiwala", "address": "Galle Road, Dehiwala", "lat": 6.8511, "lon": 79.8654},
    {"city": "Mount Lavinia", "address": "Hotel Road, Mount Lavinia", "lat": 6.8301, "lon": 79.8633},
    {"city": "Moratuwa", "address": "Galle Road, Moratuwa", "lat": 6.7730, "lon": 79.8816},
    {"city": "Nugegoda", "address": "High Level Road, Nugegoda", "lat": 6.8649, "lon": 79.8997},
    {"city": "Maharagama", "address": "High Level Road, Maharagama", "lat": 6.8480, "lon": 79.9265},
    {"city": "Kottawa", "address": "High Level Road, Kottawa", "lat": 6.8412, "lon": 79.9654},
    {"city": "Homagama", "address": "High Level Road, Homagama", "lat": 6.8440, "lon": 80.0024},
    {"city": "Sri Jayawardenepura Kotte", "address": "Parliament Road, Kotte", "lat": 6.8905, "lon": 79.9018},
    {"city": "Rajagiriya", "address": "Sri Jayawardenepura Mawatha, Rajagiriya", "lat": 6.9100, "lon": 79.8947},
    {"city": "Battaramulla", "address": "Denzil Kobbekaduwa Mawatha, Battaramulla", "lat": 6.8984, "lon": 79.9222},
    {"city": "Malabe", "address": "New Kandy Road, Malabe", "lat": 6.9061, "lon": 79.9696},
    {"city": "Kaduwela", "address": "Avissawella Road, Kaduwela", "lat": 6.9355, "lon": 79.9843},
    {"city": "Peliyagoda", "address": "Negombo Road, Peliyagoda", "lat": 6.9685, "lon": 79.8836},
    {"city": "Kelaniya", "address": "Kandy Road, Kelaniya", "lat": 6.9553, "lon": 79.9220},
    {"city": "Kiribathgoda", "address": "Kandy Road, Kiribathgoda", "lat": 6.9781, "lon": 79.9272},
    {"city": "Kadawatha", "address": "Kandy Road, Kadawatha", "lat": 7.0013, "lon": 79.9513},
    {"city": "Wattala", "address": "Negombo Road, Wattala", "lat": 6.9892, "lon": 79.8917},
    {"city": "Ja-Ela", "address": "Negombo Road, Ja-Ela", "lat": 7.0744, "lon": 79.8919},
    {"city": "Negombo", "address": "Main Street, Negombo", "lat": 7.2008, "lon": 79.8737},
    {"city": "Gampaha", "address": "Yakkala Road, Gampaha", "lat": 7.0873, "lon": 79.9990},
    {"city": "Veyangoda", "address": "Main Street, Veyangoda", "lat": 7.1520, "lon": 80.0588},
    {"city": "Panadura", "address": "Galle Road, Panadura", "lat": 6.7132, "lon": 79.9026},
    {"city": "Kalutara", "address": "Galle Road, Kalutara", "lat": 6.5854, "lon": 79.9607},
    {"city": "Beruwala", "address": "Galle Road, Beruwala", "lat": 6.4788, "lon": 79.9828},
    {"city": "Aluthgama", "address": "Galle Road, Aluthgama", "lat": 6.4356, "lon": 80.0004},
    {"city": "Bentota", "address": "Galle Road, Bentota", "lat": 6.4213, "lon": 80.0055},
    {"city": "Ambalangoda", "address": "Galle Road, Ambalangoda", "lat": 6.2355, "lon": 80.0538},
    {"city": "Hikkaduwa", "address": "Galle Road, Hikkaduwa", "lat": 6.1408, "lon": 80.1028},
    {"city": "Galle", "address": "Wakwella Road, Galle", "lat": 6.0329, "lon": 80.2168},
    {"city": "Weligama", "address": "Matara Road, Weligama", "lat": 5.9750, "lon": 80.4297},
    {"city": "Matara", "address": "Anagarika Dharmapala Mawatha, Matara", "lat": 5.9549, "lon": 80.5550},
    {"city": "Tangalle", "address": "Tissa Road, Tangalle", "lat": 6.0244, "lon": 80.7941},
    {"city": "Hambantota", "address": "Main Street, Hambantota", "lat": 6.1246, "lon": 81.1185},
    {"city": "Kandy", "address": "Peradeniya Road, Kandy", "lat": 7.2906, "lon": 80.6337},
    {"city": "Peradeniya", "address": "Galaha Road, Peradeniya", "lat": 7.2631, "lon": 80.5928},
    {"city": "Katugastota", "address": "Kurunegala Road, Katugastota", "lat": 7.3235, "lon": 80.6214},
    {"city": "Gampola", "address": "Nuwara Eliya Road, Gampola", "lat": 7.1644, "lon": 80.5767},
    {"city": "Matale", "address": "Trincomalee Street, Matale", "lat": 7.4675, "lon": 80.6234},
    {"city": "Dambulla", "address": "Kandy-Jaffna Highway, Dambulla", "lat": 7.8742, "lon": 80.6511},
    {"city": "Nuwara Eliya", "address": "Badulla Road, Nuwara Eliya", "lat": 6.9497, "lon": 80.7891},
    {"city": "Hatton", "address": "Main Street, Hatton", "lat": 6.8917, "lon": 80.5955},
    {"city": "Kurunegala", "address": "Colombo Road, Kurunegala", "lat": 7.4818, "lon": 80.3609},
    {"city": "Kuliyapitiya", "address": "Main Street, Kuliyapitiya", "lat": 7.4688, "lon": 80.0401},
    {"city": "Puttalam", "address": "Colombo Road, Puttalam", "lat": 8.0362, "lon": 79.8283},
    {"city": "Chilaw", "address": "Colombo Road, Chilaw", "lat": 7.5758, "lon": 79.7953},
    {"city": "Kegalle", "address": "Kandy Road, Kegalle", "lat": 7.2513, "lon": 80.3464},
    {"city": "Ratnapura", "address": "Main Street, Ratnapura", "lat": 6.7056, "lon": 80.3847},
    {"city": "Balangoda", "address": "Badulla Road, Balangoda", "lat": 6.6494, "lon": 80.6989},
    {"city": "Avissawella", "address": "Colombo Road, Avissawella", "lat": 6.9522, "lon": 80.2125},
    {"city": "Badulla", "address": "Lower Street, Badulla", "lat": 6.9934, "lon": 81.0550},
    {"city": "Bandarawela", "address": "Main Street, Bandarawela", "lat": 6.8304, "lon": 80.9889},
    {"city": "Monaragala", "address": "Wellawaya Road, Monaragala", "lat": 6.8728, "lon": 81.3507},
    {"city": "Anuradhapura", "address": "Maithripala Senanayake Mawatha, Anuradhapura", "lat": 8.3114, "lon": 80.4037},
    {"city": "Polonnaruwa", "address": "Hospital Junction, Polonnaruwa", "lat": 7.9403, "lon": 81.0188},
    {"city": "Trincomalee", "address": "Dockyard Road, Trincomalee", "lat": 8.5874, "lon": 81.2152},
    {"city": "Batticaloa", "address": "Trinco Road, Batticaloa", "lat": 7.7310, "lon": 81.6747},
    {"city": "Kalmunai", "address": "Batticaloa Road, Kalmunai", "lat": 7.4145, "lon": 81.8257},
    {"city": "Ampara", "address": "D.S. Senanayake Street, Ampara", "lat": 7.2975, "lon": 81.6820},
    {"city": "Jaffna", "address": "Hospital Road, Jaffna", "lat": 9.6615, "lon": 80.0255},
    {"city": "Chavakachcheri", "address": "Kandy Road, Chavakachcheri", "lat": 9.6606, "lon": 80.1636},
    {"city": "Point Pedro", "address": "Main Street, Point Pedro", "lat": 9.8167, "lon": 80.2333},
    {"city": "Kilinochchi", "address": "A9 Highway, Kilinochchi", "lat": 9.3803, "lon": 80.3770},
    {"city": "Vavuniya", "address": "Kandy Road, Vavuniya", "lat": 8.7542, "lon": 80.4982},
    {"city": "Mannar", "address": "Main Street, Mannar", "lat": 8.9810, "lon": 79.9044},
    {"city": "Mullaitivu", "address": "Main Street, Mullaitivu", "lat": 9.2671, "lon": 80.8142},
]


class GeneralIssueCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=5, max_length=2000)
    category: str = Field(default="waste")
    subcategory: Optional[str] = None
    priority: str = Field(default="medium")
    reported_by: Optional[int] = None
    latitude: float = Field(default=6.9271)
    longitude: float = Field(default=79.8612)
    address: str = Field(default="Colombo")
    city: str = Field(default="Colombo")
    attachment_url: Optional[str] = None
    attachment_name: Optional[str] = None


@router.get("/geocode", tags=["Issues"])
def geocode_location(
    q: str = Query(..., min_length=1, max_length=200),
):
    term = q.strip().lower()
    results: list[dict] = []

    # 1. Match against Sri Lankan Gazetteer first, ranking exact/prefix town matches first
    scored_gazetteer: list[tuple[int, dict]] = []
    for entry in SRI_LANKA_GAZETTEER:
        city_l = entry["city"].lower()
        addr_l = entry["address"].lower()
        if term == city_l:
            score = 0
        elif city_l.startswith(term):
            score = 1
        elif term in city_l:
            score = 2
        elif addr_l.startswith(term):
            score = 3
        elif term in addr_l or city_l in term:
            score = 4
        else:
            continue
        custom_addr = (
            q.strip()
            if (len(q.strip()) > len(entry["city"]) and "," in q)
            else entry["address"]
        )
        scored_gazetteer.append(
            (
                score,
                {
                    "display_name": f"{entry['address']}, Sri Lanka",
                    "address": custom_addr,
                    "city": entry["city"],
                    "latitude": entry["lat"],
                    "longitude": entry["lon"],
                },
            )
        )
    scored_gazetteer.sort(key=lambda pair: pair[0])
    results.extend(item for _, item in scored_gazetteer)

    # 2. Query OpenStreetMap Nominatim for street-level / custom town accuracy
    try:
        search_q = q.strip()
        if "sri lanka" not in search_q.lower():
            search_q = f"{search_q}, Sri Lanka"
        encoded = urllib.parse.quote(search_q)
        nom_url = (
            f"https://nominatim.openstreetmap.org/search"
            f"?format=json&addressdetails=1&countrycodes=lk&limit=5&q={encoded}"
        )
        req = urllib.request.Request(
            nom_url,
            headers={"User-Agent": "SmartCityAIPlatform/1.0 (smartcity.lk)"},
        )
        with urllib.request.urlopen(req, timeout=4.0) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            if isinstance(payload, list):
                for item in payload:
                    lat = float(item.get("lat", 6.9271))
                    lon = float(item.get("lon", 79.8612))
                    addr_obj = item.get("address") or {}
                    city_name = (
                        addr_obj.get("city")
                        or addr_obj.get("town")
                        or addr_obj.get("suburb")
                        or addr_obj.get("village")
                        or addr_obj.get("municipality")
                        or addr_obj.get("state_district")
                        or "Colombo"
                    )
                    road = (
                        addr_obj.get("road")
                        or addr_obj.get("neighbourhood")
                        or addr_obj.get("suburb")
                        or item.get("name")
                        or q.strip()
                    )
                    results.append(
                        {
                            "display_name": item.get("display_name")
                            or f"{road}, {city_name}",
                            "address": str(road),
                            "city": str(city_name),
                            "latitude": lat,
                            "longitude": lon,
                        }
                    )
    except Exception:
        pass

    # 3. If still empty (e.g., custom address in a town), find best partial match or default
    if not results:
        words = [w.strip() for w in term.replace(",", " ").split() if len(w.strip()) >= 3]
        for entry in SRI_LANKA_GAZETTEER:
            city_l = entry["city"].lower()
            addr_l = entry["address"].lower()
            if any(w in city_l or w in addr_l for w in words):
                results.append(
                    {
                        "display_name": f"{q.strip()}, {entry['city']}, Sri Lanka",
                        "address": q.strip(),
                        "city": entry["city"],
                        "latitude": entry["lat"],
                        "longitude": entry["lon"],
                    }
                )
                break

    if not results:
        results.append(
            {
                "display_name": f"{q.strip()}, Colombo, Sri Lanka",
                "address": q.strip(),
                "city": q.strip().title() if len(q.strip()) < 28 else "Colombo",
                "latitude": 6.9271,
                "longitude": 79.8612,
            }
        )

    # Deduplicate by rounded lat/lon
    seen: set[tuple[float, float]] = set()
    unique: list[dict] = []
    for r in results:
        key = (round(float(r["latitude"]), 4), round(float(r["longitude"]), 4))
        if key not in seen:
            seen.add(key)
            unique.append(r)

    return {"items": unique[:8]}


@router.get("/reverse-geocode", tags=["Issues"])
def reverse_geocode_location(
    lat: float = Query(...),
    lon: float = Query(...),
):
    # Find nearest Sri Lankan Gazetteer entry as immediate baseline
    nearest = min(
        SRI_LANKA_GAZETTEER,
        key=lambda e: math.hypot(e["lat"] - lat, e["lon"] - lon),
    )
    address = nearest["address"]
    city = nearest["city"]
    display_name = f"{address}, {city}"

    try:
        nom_url = (
            f"https://nominatim.openstreetmap.org/reverse"
            f"?format=json&addressdetails=1&lat={lat}&lon={lon}"
        )
        req = urllib.request.Request(
            nom_url,
            headers={"User-Agent": "SmartCityAIPlatform/1.0 (smartcity.lk)"},
        )
        with urllib.request.urlopen(req, timeout=3.5) as resp:
            item = json.loads(resp.read().decode("utf-8"))
            if isinstance(item, dict) and "address" in item:
                addr_obj = item.get("address") or {}
                city = (
                    addr_obj.get("city")
                    or addr_obj.get("town")
                    or addr_obj.get("suburb")
                    or addr_obj.get("village")
                    or addr_obj.get("municipality")
                    or city
                )
                road = (
                    addr_obj.get("road")
                    or addr_obj.get("neighbourhood")
                    or addr_obj.get("suburb")
                    or item.get("name")
                )
                if road:
                    address = f"{road}, {city}" if road.lower() != city.lower() else road
                display_name = item.get("display_name") or f"{address}, {city}"
    except Exception:
        pass

    return {
        "display_name": display_name,
        "address": address,
        "city": city,
        "latitude": lat,
        "longitude": lon,
    }


# NOTE: Must be declared BEFORE "/{issue_id}" so "map" is not parsed as an ID.
@router.get("/map", tags=["Issues"])
def get_issue_map(
    category: str = Query(default="all"),
    subcategory: str | None = Query(None),
    reported_by: int | None = Query(None),
    search: str | None = Query(None),
    db: Session = Depends(get_db),
):
    query = (
        db.query(Issue, IssueLocation)
        .join(IssueLocation, IssueLocation.issue_id == Issue.id)
        .filter(
            Issue.is_active.is_(True),
        )
    )

    cat = category.strip().lower()
    if cat and cat != "all":
        query = query.filter(func.lower(Issue.category) == cat)

    if subcategory:
        query = query.filter(Issue.subcategory == subcategory)
    if reported_by is not None:
        query = query.filter(Issue.reported_by == reported_by)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Issue.title.ilike(term),
                IssueLocation.address.ilike(term),
                IssueLocation.city.ilike(term),
            )
        )

    rows = query.order_by(Issue.created_at.desc()).all()

    return {
        "total": len(rows),
        "items": [
            {
                "id": issue.id,
                "title": issue.title,
                "description": issue.description,
                "category": issue.category,
                "subcategory": issue.subcategory,
                "status": issue.status,
                "priority": issue.priority,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address,
                "city": location.city,
            }
            for issue, location in rows
        ],
    }


@router.get("", tags=["Issues"])
def read_issues(
    category: str = Query(default="traffic"),
    reported_by: Optional[int] = Query(default=None),
    search: Optional[str] = Query(default=None, max_length=200),
    status: Optional[str] = Query(default=None, max_length=50),
    priority: Optional[str] = Query(default=None, max_length=50),
    city: Optional[str] = Query(default=None, max_length=100),
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    cat = category.strip().lower()
    if cat == "traffic":
        if date_from and date_to and date_from > date_to:
            raise HTTPException(
                status_code=422, detail="date_from must be on or before date_to"
            )
        return list_traffic_issues(
            db,
            search=search,
            status=status,
            priority=priority,
            city=city,
            date_from=date_from,
            date_to=date_to,
            reported_by=reported_by,
            limit=limit,
            offset=offset,
        )

    if reported_by is not None or cat == "all":
        query = db.query(Issue).filter(Issue.is_active.is_(True))
        if reported_by is not None:
            query = query.filter(Issue.reported_by == reported_by)
        if cat != "all":
            query = query.filter(func.lower(Issue.category) == cat)
        if search and search.strip():
            term = f"%{search.strip()}%"
            query = query.filter(
                or_(Issue.title.ilike(term), Issue.description.ilike(term))
            )
        if status and status.strip():
            norm_status = status.strip().lower()
            if norm_status in ("active", "open"):
                query = query.filter(func.lower(Issue.status) != "resolved")
            else:
                query = query.filter(func.lower(Issue.status) == norm_status)
        if priority and priority.strip():
            query = query.filter(
                func.lower(Issue.priority) == priority.strip().lower()
            )
        total = query.count()
        issues = (
            query.order_by(Issue.created_at.desc(), Issue.id.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        locations_by_issue: dict[int, list[IssueLocation]] = {}
        if issues:
            issue_ids = [item.id for item in issues]
            locs = db.scalars(
                select(IssueLocation)
                .where(IssueLocation.issue_id.in_(issue_ids))
                .order_by(IssueLocation.id)
            ).all()
            for loc in locs:
                locations_by_issue.setdefault(loc.issue_id, []).append(loc)
        return {
            "total": total,
            "offset": offset,
            "limit": limit,
            "items": [
                build_waste_response(
                    item, locations_by_issue.get(item.id, [])
                ).model_dump()
                for item in issues
            ],
        }

    if cat == "waste":
        return list_waste_issues(
            db,
            offset=offset,
            limit=limit,
        )

    if cat == "traffic":
        if date_from and date_to and date_from > date_to:
            raise HTTPException(
                status_code=422, detail="date_from must be on or before date_to"
            )
        return list_traffic_issues(
            db,
            search=search,
            status=status,
            priority=priority,
            city=city,
            date_from=date_from,
            date_to=date_to,
            limit=limit,
            offset=offset,
        )

    raise HTTPException(
        status_code=400,
        detail="Unsupported category filter",
    )


@router.post("", status_code=201, tags=["Issues"])
def create_general_issue(
    data: GeneralIssueCreate,
    db: Session = Depends(get_db),
):
    if data.attachment_url and len(data.attachment_url) > 900:
        try:
            db.execute(
                text(
                    "ALTER TABLE issue_attachments MODIFY COLUMN file_url LONGTEXT NOT NULL"
                )
            )
            db.commit()
        except Exception:
            db.rollback()

    reporter_id = data.reported_by
    if reporter_id is None:
        first_user = db.scalar(select(User).order_by(User.id).limit(1))
        reporter_id = first_user.id if first_user else 1

    issue = Issue(
        title=data.title.strip(),
        description=data.description.strip(),
        category=data.category.strip().lower(),
        subcategory=data.subcategory,
        priority=data.priority.strip().lower(),
        status="reported",
        reported_by=reporter_id,
        is_active=True,
    )
    db.add(issue)
    db.flush()

    location = IssueLocation(
        issue_id=issue.id,
        latitude=data.latitude,
        longitude=data.longitude,
        address=data.address.strip(),
        city=data.city.strip(),
    )
    db.add(location)

    if data.attachment_url and data.attachment_url.strip():
        db.add(
            IssueAttachment(
                issue_id=issue.id,
                uploaded_by=reporter_id,
                file_name=(data.attachment_name or "evidence_photo.jpg").strip(),
                file_url=data.attachment_url.strip(),
                file_type="image/jpeg",
            )
        )

    db.add(
        IssueStatusHistory(
            issue_id=issue.id,
            changed_by=reporter_id,
            previous_status=None,
            new_status="reported",
            note="Issue submitted via Smart City mobile app.",
        )
    )
    db.commit()
    db.refresh(issue)
    db.refresh(location)

    try:
        analyze_issue(db, issue.id)
    except Exception:
        pass

    return build_waste_response(issue, [location])


@router.get("/{issue_id}", tags=["Issues"])
def read_issue(
    issue_id: int = Path(gt=0),
    db: Session = Depends(get_db),
):
    issue_row = db.scalar(
        select(Issue).where(Issue.id == issue_id, Issue.is_active.is_(True))
    )
    if issue_row is None:
        raise HTTPException(
            status_code=404,
            detail="Issue not found",
        )

    if issue_row.category == "waste":
        details = get_issue_details(db, issue_id)
        if details is not None:
            return details
        issue = get_waste_issue(db, issue_id)
        if issue is not None:
            return issue

    if issue_row.category == "traffic":
        traffic_issue = get_traffic_issue(db, issue_id)
        if traffic_issue is not None:
            return traffic_issue

    details = get_issue_details(db, issue_id)
    if details is not None:
        return details

    raise HTTPException(
        status_code=404,
        detail="Issue not found",
    )