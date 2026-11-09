import re
from sqlalchemy.orm import Session
try:
    from google import genai
    from google.genai import types
except ImportError:  # pragma: no cover
    genai = None
    types = None

from app.models.ai_chat_session import AIChatSession
from app.models.ai_chat_message import AIChatMessage
from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.models.collection_schedule import CollectionSchedule
from app.models.safety_alert import SafetyAlert
from app.models.department import Department
from app.services import air_quality_service
from app.core.config import settings


SMART_CITY_KEYWORDS = {
    # Waste & Environment
    "waste", "garbage", "trash", "bin", "bins", "recycling", "recycle", "compost",
    "collection", "pickup", "schedule", "schedules", "dumping", "litter", "sanitation",
    "separation", "biodegradable", "plastic", "glass", "hazardous", "landfill",
    # Energy & Water
    "water", "leak", "leakage", "pipe", "pipeline", "burst", "supply", "pressure",
    "drainage", "sewage", "flood", "flooding", "canal", "energy", "power", "electricity",
    "outage", "blackout", "grid", "transformer", "voltage", "streetlight", "streetlights",
    "lamp", "lighting", "ceb", "leco", "nwsdb", "meter",
    # Traffic & Roads
    "traffic", "road", "roads", "street", "highway", "lane", "pothole", "potholes",
    "pavement", "sidewalk", "bridge", "signal", "signals", "light", "lights", "junction",
    "intersection", "congestion", "jam", "accident", "collision", "parking", "crosswalk",
    "pedestrian", "rda",
    # Air Quality & Pollution
    "air", "aqi", "quality", "pollution", "pollutant", "pollutants", "smog", "smoke",
    "dust", "emission", "emissions", "odor", "odour", "fumes", "burning", "pm2.5",
    "pm10", "no2", "so2", "co", "o3", "ozone", "atmosphere", "breathe", "breathing",
    # Public Safety & Emergency
    "safety", "safe", "alert", "alerts", "emergency", "hazard", "hazards", "danger",
    "dangerous", "crime", "theft", "vandalism", "fire", "rescue", "ambulance", "police",
    "disaster", "landslide", "cyclone", "weather", "storm", "fallen", "tree", "wire",
    "cable", "stray", "public",
    # Platform, Reporting, Governance & Cities
    "smart city", "smartcity", "city", "municipal", "municipality", "council", "urban",
    "citizen", "report", "reports", "reporting", "issue", "issues", "complaint",
    "complaints", "status", "track", "tracking", "ticket", "resolved", "active",
    "pending", "in progress", "priority", "critical", "high", "department", "departments",
    "officer", "authority", "office", "contact", "hotline", "helpline", "dashboard",
    "app", "platform", "service", "services", "location", "map", "gps", "address",
    "sri lanka", "province", "district", "town",
}

OFF_TOPIC_PATTERNS = [
    r"\b(write|code|program|implement|debug)\b.*\b(python|java|javascript|c\+\+|html|css|sql|react|flutter|algorithm|function|script|sort|fibonacci|leetcode)\b",
    r"\b(recipe|cook|bake|ingredients|pasta|pizza|cake|biryani|curry)\b",
    r"\b(movie|film|actor|actress|netflix|hollywood|bollywood|anime|song|lyrics|album|singer|concert)\b",
    r"\b(football|cricket|soccer|basketball|tennis|fifa|ipl|world cup|olympics|match score|player)\b",
    r"\b(bitcoin|crypto|ethereum|stock market|forex|trading|nft)\b",
    r"\b(horoscope|astrology|zodiac|tarot)\b",
    r"\b(joke|riddle|poem|haiku|story|essay|novel|sonnet)\b",
    r"\b(who won|who is the president|capital of|prime minister|celebrity|elon musk|taylor swift|messi|ronaldo)\b",
    r"\b(solve|calculate|integral|derivative|equation|math|algebra|calculus)\b",
    r"\b(video game|minecraft|fortnite|valorant|gta|playstation|xbox)\b",
]

GREETING_WORDS = {
    "hi", "hello", "hey", "ayubowan", "vanakkam", "good morning", "good afternoon",
    "good evening", "help", "what can you do", "who are you", "thanks", "thank you",
    "ok", "okay", "great",
}


def create_chat_session(db: Session, user_id: int, title: str | None = None):
    session = AIChatSession(
        user_id=user_id,
        title=title,
        status="active",
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


def get_user_chat_sessions(db: Session, user_id: int):
    return (
        db.query(AIChatSession)
        .filter(
            AIChatSession.user_id == user_id,
            AIChatSession.status == "active",
        )
        .order_by(AIChatSession.updated_at.desc())
        .all()
    )


def get_chat_session(db: Session, session_id: int, user_id: int):
    return (
        db.query(AIChatSession)
        .filter(
            AIChatSession.id == session_id,
            AIChatSession.user_id == user_id,
        )
        .first()
    )


def get_chat_messages(db: Session, session_id: int):
    return (
        db.query(AIChatMessage)
        .filter(AIChatMessage.session_id == session_id)
        .order_by(AIChatMessage.created_at.asc())
        .all()
    )


def save_chat_message(
    db: Session,
    session_id: int,
    role: str,
    content: str,
):
    message = AIChatMessage(
        session_id=session_id,
        role=role,
        content=content,
    )

    db.add(message)
    db.commit()
    db.refresh(message)

    return message


def delete_chat_session(db: Session, session: AIChatSession):
    session.status = "deleted"
    db.commit()


def _get_sri_lanka_city_names() -> list[str]:
    return [c["area"].lower() for c in air_quality_service.SRI_LANKA_CITIES]


def _is_smart_city_query(message: str, history: list) -> tuple[bool, bool]:
    """
    Returns (is_allowed, is_greeting).
    Strictly allows ONLY Smart City topics, Sri Lankan city service queries,
    citizen report inquiries, or polite greetings/follow-ups.
    """
    msg = message.lower().strip()
    clean = re.sub(r"[^\w\s]", " ", msg)
    clean_spaces = " ".join(clean.split())

    # 1. Explicit off-topic patterns are always rejected unless combined with strong smart-city intent
    for pattern in OFF_TOPIC_PATTERNS:
        if re.search(pattern, msg):
            return False, False

    # 2. Pure greeting check
    if clean_spaces in GREETING_WORDS or any(
        clean_spaces == g for g in GREETING_WORDS
    ):
        return True, True

    # 3. Check Smart City keywords
    for kw in SMART_CITY_KEYWORDS:
        if kw in msg or kw in clean_spaces.split():
            return True, False

    # 4. Check Sri Lankan city names (44 cities)
    for city_name in _get_sri_lanka_city_names():
        if city_name in msg:
            return True, False

    # 5. Check short contextual follow-ups if there is recent Smart City conversation history
    follow_up_phrases = (
        "how do i", "where can i", "what about", "tell me more", "and in",
        "how long", "who handles", "contact", "phone", "number", "urgent",
        "my", "show me", "list", "check", "update", "why", "when",
    )
    if history and len(clean_spaces.split()) <= 8:
        if any(p in clean_spaces for p in follow_up_phrases):
            return True, False

    # 6. Check if greeting with extra words (e.g., "hi there", "hello assistant")
    words = set(clean_spaces.split())
    if words and words.issubset(
        {"hi", "hello", "hey", "there", "assistant", "ai", "bot", "good", "morning", "afternoon", "evening", "thanks", "thank", "you"}
    ):
        return True, True

    return False, False


def _off_topic_refusal_reply() -> str:
    return (
        "I am the **Smart City AI Assistant**, and I am strictly designed to answer **Smart City–related questions only**.\n\n"
        "I cannot help with general trivia, coding, entertainment, sports, recipes, or non-municipal topics.\n\n"
        "Here is what you can ask me about:\n"
        "• **Live Sri Lanka Air Quality (AQI):** Real-time AQI, PM2.5, PM10, NO₂, O₃ & health advice for all 44 Sri Lankan cities\n"
        "• **Your Citizen Reports:** Live status of your submitted Waste, Energy, Water, Traffic, Air Quality & Safety reports\n"
        "• **Waste Management:** Garbage collection schedules by area, recycling & waste separation guides\n"
        "• **Energy & Water Services:** Power outages, streetlight faults, water pipe leaks & supply issues\n"
        "• **Traffic & Roads:** Potholes, damaged roads, broken traffic signals & accident hazard reporting\n"
        "• **Public Safety & Departments:** Active safety alerts, emergency contacts & municipal department details\n\n"
        "Try asking: *\"What is the live air quality in Kandy?\"*, *\"Show my active reports\"*, or *\"When is waste collection in Colombo?\"*"
    )


def _gather_live_context(
    db: Session | None,
    user_id: int | None,
    message: str,
) -> dict:
    context = {
        "user_issues": [],
        "matched_cities_aqi": [],
        "island_aqi_summary": None,
        "schedules": [],
        "safety_alerts": [],
        "departments": [],
    }
    if db is None:
        return context

    msg_lower = message.lower()

    # 1. Citizen's own reports
    if user_id:
        try:
            issues = (
                db.query(Issue)
                .filter(Issue.reported_by == user_id, Issue.is_active == True)  # noqa: E712
                .order_by(Issue.created_at.desc())
                .limit(15)
                .all()
            )
            for iss in issues:
                loc = (
                    db.query(IssueLocation)
                    .filter(IssueLocation.issue_id == iss.id)
                    .first()
                )
                loc_str = (
                    f"{loc.address or ''}, {loc.city or ''}".strip(", ")
                    if loc
                    else "Location pinned"
                )
                context["user_issues"].append(
                    {
                        "id": iss.id,
                        "title": iss.title,
                        "category": iss.category,
                        "subcategory": iss.subcategory or "General",
                        "status": iss.status,
                        "priority": iss.priority,
                        "location": loc_str or "Sri Lanka",
                        "date": iss.created_at.strftime("%Y-%m-%d")
                        if iss.created_at
                        else "",
                    }
                )
        except Exception:
            pass

    # 2. Live Air Quality (check if AQI/air/pollution or a Sri Lankan city is mentioned)
    matched_city_names = [
        c["area"]
        for c in air_quality_service.SRI_LANKA_CITIES
        if c["area"].lower() in msg_lower
    ]
    wants_aqi = any(
        w in msg_lower
        for w in ("air", "aqi", "pollution", "pm2.5", "pm10", "smog", "smoke", "quality", "breathe")
    ) or bool(matched_city_names)

    if wants_aqi:
        try:
            latest_readings = air_quality_service.get_latest(db)
            if latest_readings:
                for city_name in matched_city_names:
                    for r in latest_readings:
                        if r.area.lower() == city_name.lower():
                            context["matched_cities_aqi"].append(r)
                            break

                avg_aqi = round(
                    sum(r.aqi for r in latest_readings) / len(latest_readings)
                )
                best_city = min(latest_readings, key=lambda x: x.aqi)
                worst_city = max(latest_readings, key=lambda x: x.aqi)
                context["island_aqi_summary"] = {
                    "total_cities": len(latest_readings),
                    "avg_aqi": avg_aqi,
                    "best": f"{best_city.area} (AQI {best_city.aqi} - {best_city.category})",
                    "highest": f"{worst_city.area} (AQI {worst_city.aqi} - {worst_city.category})",
                    "sample_top": [
                        f"{r.area}: AQI {r.aqi} ({r.category}, PM2.5 {r.pm2_5} µg/m³)"
                        for r in latest_readings[:6]
                    ],
                }
        except Exception:
            pass

    # 3. Waste collection schedules
    try:
        schedules = (
            db.query(CollectionSchedule)
            .filter(CollectionSchedule.is_active == True)  # noqa: E712
            .limit(10)
            .all()
        )
        for s in schedules:
            context["schedules"].append(
                {
                    "area": s.area,
                    "day": s.collection_day,
                    "time": s.collection_time or "06:00 AM - 11:00 AM",
                    "waste_types": s.waste_types or "General, Organic & Recyclables",
                }
            )
    except Exception:
        pass

    # 4. Active Safety Alerts
    try:
        alerts = (
            db.query(SafetyAlert)
            .filter(SafetyAlert.is_active == True)  # noqa: E712
            .order_by(SafetyAlert.created_at.desc())
            .limit(5)
            .all()
        )
        for a in alerts:
            context["safety_alerts"].append(
                {
                    "title": a.title,
                    "area": a.area,
                    "severity": a.severity.upper(),
                    "description": a.description,
                    "instructions": a.safety_instructions or "Follow municipal safety guidelines.",
                }
            )
    except Exception:
        pass

    # 5. City Departments
    try:
        depts = (
            db.query(Department)
            .filter(Department.is_active == True)  # noqa: E712
            .all()
        )
        for d in depts:
            context["departments"].append(
                {
                    "name": d.name,
                    "phone": d.contact_phone or "1919 (Gov Info Center)",
                    "email": d.contact_email or "support@smartcity.lk",
                    "hours": d.operating_hours or "Mon-Fri 8:30 AM - 4:30 PM (24/7 Emergency)",
                    "responsibilities": d.responsibilities or d.description or "",
                }
            )
    except Exception:
        pass

    return context


def _format_context_for_llm(ctx: dict) -> str:
    sections = []

    issues = ctx.get("user_issues", [])
    if issues:
        total = len(issues)
        active = sum(1 for i in issues if i["status"] in ("reported", "in_progress"))
        resolved = sum(1 for i in issues if i["status"] == "resolved")
        lines = [
            f"LOGGED-IN CITIZEN'S REPORTS (Total: {total}, Active: {active}, Resolved: {resolved}):"
        ]
        for i in issues[:8]:
            lines.append(
                f"- [#{i['id']}] {i['title']} | Category: {i['category']} | Status: {i['status'].upper()} | Priority: {i['priority'].upper()} | Location: {i['location']} ({i['date']})"
            )
        sections.append("\n".join(lines))
    else:
        sections.append(
            "LOGGED-IN CITIZEN'S REPORTS: This citizen currently has 0 submitted reports."
        )

    matched_aqi = ctx.get("matched_cities_aqi", [])
    if matched_aqi:
        lines = ["LIVE SRI LANKA CITY AQI READINGS (Open-Meteo CAMS Live Telemetry):"]
        for r in matched_aqi:
            lines.append(
                f"- {r.area} ({r.district} District, {r.province} Province): AQI {r.aqi} ({r.category}), PM2.5: {r.pm2_5} µg/m³, PM10: {r.pm10} µg/m³, NO₂: {r.nitrogen_dioxide} µg/m³, O₃: {r.ozone} µg/m³, CO: {r.carbon_monoxide} µg/m³. Advice: {r.health_recommendation}"
            )
        sections.append("\n".join(lines))

    summary = ctx.get("island_aqi_summary")
    if summary:
        sections.append(
            f"ISLANDWIDE SRI LANKA AQI SUMMARY ({summary['total_cities']} cities monitored): "
            f"Average AQI: {summary['avg_aqi']} | Cleanest Air: {summary['best']} | Highest AQI: {summary['highest']}. "
            f"Major Cities: {'; '.join(summary['sample_top'])}"
        )

    schedules = ctx.get("schedules", [])
    if schedules:
        lines = ["MUNICIPAL WASTE COLLECTION SCHEDULES:"]
        for s in schedules:
            lines.append(
                f"- {s['area']}: {s['day']} ({s['time']}) — Types: {s['waste_types']}"
            )
        sections.append("\n".join(lines))

    alerts = ctx.get("safety_alerts", [])
    if alerts:
        lines = ["ACTIVE PUBLIC SAFETY ALERTS:"]
        for a in alerts:
            lines.append(
                f"- [{a['severity']}] {a['title']} ({a['area']}): {a['description']} | Advice: {a['instructions']}"
            )
        sections.append("\n".join(lines))

    depts = ctx.get("departments", [])
    if depts:
        lines = ["SMART CITY DEPARTMENTS & CONTACTS:"]
        for d in depts:
            lines.append(
                f"- {d['name']}: Phone {d['phone']} | Email {d['email']} | Hours: {d['hours']}"
            )
        sections.append("\n".join(lines))

    return "\n\n".join(sections)


def _smart_city_local_reply(
    message: str,
    ctx: dict,
    is_greeting: bool = False,
) -> str:
    msg = message.lower()

    if is_greeting:
        issues = ctx.get("user_issues", [])
        active_count = sum(
            1 for i in issues if i["status"] in ("reported", "in_progress")
        )
        report_note = (
            f"\n\n📊 **Your Account Snapshot:** You currently have **{len(issues)} total report(s)** ({active_count} active)."
            if issues
            else ""
        )
        return (
            "Hello! I am your **Smart City AI Assistant** for Sri Lanka. I exclusively answer Smart City questions with live platform data:\n\n"
            "• **Live Sri Lanka Air Quality (AQI):** Check real-time AQI, PM2.5, PM10 & health advisories across 44 Sri Lankan cities\n"
            "• **My Reports & Tracking:** Check the status and priority of your submitted citizen issues\n"
            "• **Waste Management:** Collection schedules, missed pickups, waste separation & recycling\n"
            "• **Energy & Water:** Power grid outages, streetlight faults & water leakage reporting\n"
            "• **Traffic & Roads:** Potholes, signal malfunctions & traffic incidents\n"
            "• **Public Safety & Departments:** Active alerts and municipal department hotlines"
            f"{report_note}\n\n"
            "How can I help you with your city services today?"
        )

    # 1. Check if asking about user's own reports / status / tickets
    if any(
        phrase in msg
        for phrase in (
            "my report", "my reports", "my issue", "my issues", "my complaint",
            "status of my", "active report", "total report", "resolved report",
            "submitted report", "track my", "show my",
        )
    ) or ("report" in msg and any(w in msg for w in ("my", "status", "check", "list", "active", "total"))):
        issues = ctx.get("user_issues", [])
        if not issues:
            return (
                "📋 **Your Citizen Reports**\n\n"
                "You do not have any submitted reports yet.\n\n"
                "**How to submit a new report:**\n"
                "1. Tap **Report an Issue** on the Citizen Dashboard or open any service card (**Waste**, **Energy & Water**, **Traffic**, **Public Safety**, or **Air Quality**).\n"
                "2. Tap **New Report**, select the subcategory and severity, and pin the problem location using **Search Town/Address** or **Auto-Detect GPS**.\n"
                "3. Submit to receive live status tracking (`Reported` → `In Progress` → `Resolved`)."
            )

        active = [i for i in issues if i["status"] in ("reported", "in_progress")]
        resolved = [i for i in issues if i["status"] == "resolved"]
        lines = [
            f"📋 **Your Citizen Reports Summary**\n"
            f"• **Total Reports:** {len(issues)}  |  **Active:** {len(active)}  |  **Resolved:** {len(resolved)}\n\n"
            f"**Recent Submissions:**"
        ]
        for i in issues[:6]:
            status_badge = i["status"].replace("_", " ").title()
            lines.append(
                f"• **#{i['id']} {i['title']}** ({i['category']})\n"
                f"  Status: `{status_badge}` | Priority: `{i['priority'].upper()}` | Location: {i['location']}"
            )
        lines.append(
            "\n💡 *Tip: Tap **Total Reports** or **Active Reports** on your Citizen Dashboard to filter and inspect full report details.*"
        )
        return "\n".join(lines)

    # 2. Check if asking about Air Quality / AQI or a specific Sri Lankan city's air quality
    matched_aqi = ctx.get("matched_cities_aqi", [])
    summary = ctx.get("island_aqi_summary")
    if matched_aqi or any(
        w in msg for w in ("air", "aqi", "pollution", "pm2.5", "pm10", "smog", "breathe")
    ):
        if matched_aqi:
            lines = ["🌬️ **Live Sri Lanka Air Quality Telemetry (Open-Meteo CAMS)**\n"]
            for r in matched_aqi:
                lines.append(
                    f"📍 **{r.area}** ({r.district} District, {r.province} Province)\n"
                    f"• **US AQI:** **{r.aqi}** — **{r.category}**\n"
                    f"• **Pollutants:** PM2.5: `{r.pm2_5} µg/m³` | PM10: `{r.pm10} µg/m³` | NO₂: `{r.nitrogen_dioxide} µg/m³` | O₃: `{r.ozone} µg/m³` | CO: `{r.carbon_monoxide} µg/m³`\n"
                    f"• **Health Guidance:** {r.health_recommendation}\n"
                )
            lines.append(
                "📢 *Observed smoke, open waste burning, or industrial emissions here? Open **Air Quality** → **Report Air Issue** to file a geo-tagged environmental complaint.*"
            )
            return "\n".join(lines)

        if summary:
            sample_list = "\n".join(f"• {item}" for item in summary["sample_top"])
            return (
                f"🌬️ **Sri Lanka Islandwide Live Air Quality ({summary['total_cities']} Cities Monitored)**\n\n"
                f"• **Islandwide Average AQI:** **{summary['avg_aqi']}**\n"
                f"• **Cleanest Air Right Now:** {summary['best']}\n"
                f"• **Highest AQI Right Now:** {summary['highest']}\n\n"
                f"**Live Readings in Key Cities:**\n{sample_list}\n\n"
                "💡 *Ask me about any specific Sri Lankan city (e.g., \"What is the AQI in Kandy?\", \"Air quality in Jaffna or Galle\") or open the **Air Quality** screen to pick any location and file an environmental complaint.*"
            )

    # 3. Waste Management / Collection Schedules / Recycling
    if any(
        w in msg
        for w in (
            "waste", "garbage", "trash", "bin", "recycling", "recycle",
            "collection", "schedule", "pickup", "dumping", "compost",
        )
    ):
        schedules = ctx.get("schedules", [])
        sched_lines = ""
        if schedules:
            items = "\n".join(
                f"• **{s['area']}:** {s['day']} ({s['time']}) — *{s['waste_types']}*"
                for s in schedules[:5]
            )
            sched_lines = f"\n\n📅 **Active Municipal Collection Schedules:**\n{items}"

        return (
            "♻️ **Smart City Waste Management & Collection**\n\n"
            "• **Waste Separation Guide:**\n"
            "  - **Green Bin (Biodegradable):** Food scraps, garden waste, organic matter\n"
            "  - **Blue Bin (Recyclables):** Clean paper, cardboard, PET plastic bottles, metal cans, glass\n"
            "  - **Red/Hazardous:** E-waste, batteries, medical sharps, CFL bulbs (do not mix with general trash)\n"
            "• **Report a Waste Issue:** Open **Waste Management** → **New Report** to report missed garbage pickups, overflowing public bins, or illegal roadside dumping with GPS/town location."
            f"{sched_lines}"
        )

    # 4. Energy & Water Services
    if any(
        w in msg
        for w in (
            "water", "leak", "leakage", "pipe", "burst", "pressure", "drainage",
            "sewage", "energy", "power", "electricity", "outage", "blackout",
            "transformer", "streetlight", "lamp", "ceb", "nwsdb",
        )
    ):
        return (
            "⚡💧 **Energy & Water Utility Services**\n\n"
            "• **Water Supply & Leakage:**\n"
            "  - Report burst mains, treated water pipe leaks, low water pressure, or blocked storm drains via **Energy & Water** → **New Report**.\n"
            "  - View active leak locations on the interactive **Water Leakage Map**.\n"
            "• **Power Grid & Streetlights:**\n"
            "  - Report localized power outages, sparking transformers, fallen lines, or broken streetlights.\n"
            "  - ⚠️ **Emergency Safety:** Never approach fallen power cables. Mark the report severity as **Critical** for immediate utility dispatch."
        )

    # 5. Traffic & Road Infrastructure
    if any(
        w in msg
        for w in (
            "traffic", "road", "pothole", "signal", "accident", "congestion",
            "junction", "highway", "pavement", "bridge", "parking", "lane",
        )
    ):
        return (
            "🚦 **Traffic Control & Road Infrastructure**\n\n"
            "• **Report Road & Signal Hazards:**\n"
            "  - Open **Traffic Management** → **New Report** to report potholes, road surface collapse, malfunctioning traffic lights, or blocked lanes.\n"
            "  - Pin the exact junction or street address using the **Sri Lanka Town & Address Locator**.\n"
            "• **Live Incident Map:**\n"
            "  - View active road hazards and congestion hotspots on the **Traffic Incident Map** before commuting."
        )

    # 6. Public Safety, Alerts & Departments
    if any(
        w in msg
        for w in (
            "safety", "alert", "hazard", "emergency", "department", "contact",
            "hotline", "police", "fire", "ambulance", "complaint", "disaster",
        )
    ):
        alerts = ctx.get("safety_alerts", [])
        depts = ctx.get("departments", [])
        alert_text = ""
        if alerts:
            alert_items = "\n".join(
                f"• **[{a['severity']}] {a['title']} ({a['area']}):** {a['description']}"
                for a in alerts[:3]
            )
            alert_text = f"\n\n🚨 **Active Public Safety Alerts:**\n{alert_items}"

        dept_text = ""
        if depts:
            dept_items = "\n".join(
                f"• **{d['name']}:** {d['phone']} ({d['email']})"
                for d in depts[:4]
            )
            dept_text = f"\n\n🏛️ **Municipal Department Contacts:**\n{dept_items}"

        return (
            "🛡️ **Public Safety & Municipal Emergency Services**\n\n"
            "• **Report Public Safety Hazards:** Open **Public Safety** → **New Report** to report fallen trees, exposed wiring, unsafe structures, or public hazards.\n"
            "• **Sri Lanka Emergency Hotlines:** Police Emergency `119` | Suwa Seriya Ambulance `1990` | Fire & Rescue `110` | Disaster Management `117` | Gov Info `1919`."
            f"{alert_text}{dept_text}"
        )

    # 7. City name mentioned without specific domain -> give city overview + AQI if available
    if matched_aqi:
        r = matched_aqi[0]
        return (
            f"🏙️ **Smart City Services for {r.area} ({r.district} District)**\n\n"
            f"• **Live Air Quality:** US AQI **{r.aqi}** ({r.category}) — PM2.5 `{r.pm2_5} µg/m³`, PM10 `{r.pm10} µg/m³`\n"
            f"• **Health Guidance:** {r.health_recommendation}\n"
            f"• **Report an Issue in {r.area}:** You can submit geo-tagged reports for Waste, Energy & Water, Traffic, Public Safety, or Air Quality in **{r.area}** directly from your dashboard."
        )

    return (
        "🏙️ **Smart City AI Assistant**\n\n"
        "I can help you with any Smart City service across Sri Lanka:\n"
        "• **Ask about Live Air Quality:** e.g., *\"What is the AQI in Colombo, Kandy, or Galle?\"*\n"
        "• **Track Your Reports:** e.g., *\"Show my active reports\"*\n"
        "• **Waste & Recycling:** e.g., *\"What is the waste collection schedule?\"*\n"
        "• **Utilities & Roads:** e.g., *\"How do I report a water pipe leak or pothole?\"*\n"
        "• **Safety & Contacts:** e.g., *\"Show active safety alerts and department contacts\"*"
    )


def generate_assistant_reply(
    message: str,
    history: list,
    db: Session | None = None,
    user_id: int | None = None,
) -> str:
    # 1. Enforce strict Smart City domain guardrail first
    is_allowed, is_greeting = _is_smart_city_query(message, history)
    if not is_allowed:
        return _off_topic_refusal_reply()

    # 2. Gather live Smart City context from the database & telemetry services
    live_ctx = _gather_live_context(db, user_id, message)

    if not settings.GEMINI_API_KEY or genai is None or types is None:
        return _smart_city_local_reply(message, live_ctx, is_greeting=is_greeting)

    client = genai.Client(
        api_key=settings.GEMINI_API_KEY,
        http_options=types.HttpOptions(timeout=25000),
    )
    try:
        conversation = []

        for chat_message in history[-10:]:
            conversation.append(
                types.Content(
                    role=(
                        "model"
                        if chat_message.role == "assistant"
                        else "user"
                    ),
                    parts=[types.Part(text=chat_message.content)],
                )
            )

        conversation.append(
            types.Content(
                role="user",
                parts=[types.Part(text=message)],
            )
        )

        context_block = _format_context_for_llm(live_ctx)

        system_prompt = (
            "You are the official Smart City AI Assistant for the Sri Lanka Smart City Platform.\n"
            "STRICT DOMAIN RULE (CRITICAL):\n"
            "- You MUST ONLY answer questions related to Smart City domains: Waste Management, Garbage Collection Schedules, Recycling, "
            "Energy & Power Outages, Streetlights, Water Supply & Pipe Leakages, Traffic Management & Road Damage/Potholes, "
            "Public Safety & Emergency Alerts, Sri Lanka Live Air Quality (AQI & pollutants across Sri Lankan cities), "
            "Citizen Issue Reporting & Status Tracking, and Municipal Departments.\n"
            "- If the user asks about ANY unrelated topic (e.g., general coding/programming, recipes, sports, movies, celebrities, math homework, crypto, general world trivia, or creative writing), "
            "politely refuse and explain that you only answer Smart City–related questions.\n\n"
            "RESPONSE STYLE:\n"
            "- Use the LIVE PLATFORM DATA below to give accurate, specific answers (cite exact AQI numbers, pollutant levels, report IDs, statuses, schedules, or department contacts when relevant).\n"
            "- Keep answers clear, structured with bullet points, and concise.\n\n"
            f"=== LIVE SMART CITY PLATFORM DATA ===\n{context_block}\n====================================="
        )

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=conversation,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.3,
            ),
        )

        if not response.text:
            return _smart_city_local_reply(message, live_ctx, is_greeting=is_greeting)

        return response.text.strip()

    except Exception:
        return _smart_city_local_reply(message, live_ctx, is_greeting=is_greeting)

    finally:
        client.close()
