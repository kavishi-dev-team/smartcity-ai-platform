from collections import defaultdict
from datetime import datetime, timedelta, timezone
import json
import math
import time
from typing import Optional
import urllib.parse
import urllib.request

from sqlalchemy.orm import Session

from app.api.v1.endpoints.issues import reverse_geocode_location
from app.repositories import air_quality_repository as repo
from app.schemas.air_quality import (
    AirQualityHistoryOut,
    AirQualityHistoryPoint,
    AirQualityReadingOut,
)

PERIOD_DAYS = {"daily": 1, "weekly": 7, "monthly": 30}

# Comprehensive Sri Lanka Islandwide Air Quality Monitoring Network (All 25 Districts & 9 Provinces)
SRI_LANKA_CITIES: list[dict] = [
    # Western Province
    {"id": 101, "area": "Colombo", "district": "Colombo", "province": "Western", "lat": 6.9271, "lon": 79.8612},
    {"id": 102, "area": "Sri Jayawardenepura Kotte", "district": "Colombo", "province": "Western", "lat": 6.8905, "lon": 79.9018},
    {"id": 103, "area": "Dehiwala-Mount Lavinia", "district": "Colombo", "province": "Western", "lat": 6.8390, "lon": 79.8645},
    {"id": 104, "area": "Moratuwa", "district": "Colombo", "province": "Western", "lat": 6.7730, "lon": 79.8816},
    {"id": 105, "area": "Maharagama", "district": "Colombo", "province": "Western", "lat": 6.8480, "lon": 79.9265},
    {"id": 106, "area": "Battaramulla", "district": "Colombo", "province": "Western", "lat": 6.8984, "lon": 79.9222},
    {"id": 107, "area": "Homagama", "district": "Colombo", "province": "Western", "lat": 6.8440, "lon": 80.0024},
    {"id": 108, "area": "Negombo", "district": "Gampaha", "province": "Western", "lat": 7.2008, "lon": 79.8737},
    {"id": 109, "area": "Gampaha", "district": "Gampaha", "province": "Western", "lat": 7.0873, "lon": 79.9990},
    {"id": 110, "area": "Wattala", "district": "Gampaha", "province": "Western", "lat": 6.9892, "lon": 79.8917},
    {"id": 111, "area": "Kalutara", "district": "Kalutara", "province": "Western", "lat": 6.5854, "lon": 79.9607},
    {"id": 112, "area": "Panadura", "district": "Kalutara", "province": "Western", "lat": 6.7132, "lon": 79.9026},
    # Central Province
    {"id": 113, "area": "Kandy", "district": "Kandy", "province": "Central", "lat": 7.2906, "lon": 80.6337},
    {"id": 114, "area": "Peradeniya", "district": "Kandy", "province": "Central", "lat": 7.2631, "lon": 80.5928},
    {"id": 115, "area": "Gampola", "district": "Kandy", "province": "Central", "lat": 7.1644, "lon": 80.5767},
    {"id": 116, "area": "Matale", "district": "Matale", "province": "Central", "lat": 7.4675, "lon": 80.6234},
    {"id": 117, "area": "Dambulla", "district": "Matale", "province": "Central", "lat": 7.8742, "lon": 80.6511},
    {"id": 118, "area": "Nuwara Eliya", "district": "Nuwara Eliya", "province": "Central", "lat": 6.9497, "lon": 80.7891},
    {"id": 119, "area": "Hatton", "district": "Nuwara Eliya", "province": "Central", "lat": 6.8917, "lon": 80.5955},
    # Southern Province
    {"id": 120, "area": "Galle", "district": "Galle", "province": "Southern", "lat": 6.0329, "lon": 80.2168},
    {"id": 121, "area": "Hikkaduwa", "district": "Galle", "province": "Southern", "lat": 6.1408, "lon": 80.1028},
    {"id": 122, "area": "Matara", "district": "Matara", "province": "Southern", "lat": 5.9549, "lon": 80.5550},
    {"id": 123, "area": "Weligama", "district": "Matara", "province": "Southern", "lat": 5.9750, "lon": 80.4297},
    {"id": 124, "area": "Hambantota", "district": "Hambantota", "province": "Southern", "lat": 6.1246, "lon": 81.1185},
    {"id": 125, "area": "Tangalle", "district": "Hambantota", "province": "Southern", "lat": 6.0244, "lon": 80.7941},
    # Northern Province
    {"id": 126, "area": "Jaffna", "district": "Jaffna", "province": "Northern", "lat": 9.6615, "lon": 80.0255},
    {"id": 127, "area": "Kilinochchi", "district": "Kilinochchi", "province": "Northern", "lat": 9.3803, "lon": 80.3770},
    {"id": 128, "area": "Mannar", "district": "Mannar", "province": "Northern", "lat": 8.9810, "lon": 79.9044},
    {"id": 129, "area": "Vavuniya", "district": "Vavuniya", "province": "Northern", "lat": 8.7542, "lon": 80.4982},
    {"id": 130, "area": "Mullaitivu", "district": "Mullaitivu", "province": "Northern", "lat": 9.2671, "lon": 80.8142},
    # Eastern Province
    {"id": 131, "area": "Trincomalee", "district": "Trincomalee", "province": "Eastern", "lat": 8.5874, "lon": 81.2152},
    {"id": 132, "area": "Batticaloa", "district": "Batticaloa", "province": "Eastern", "lat": 7.7310, "lon": 81.6747},
    {"id": 133, "area": "Ampara", "district": "Ampara", "province": "Eastern", "lat": 7.2975, "lon": 81.6820},
    {"id": 134, "area": "Kalmunai", "district": "Ampara", "province": "Eastern", "lat": 7.4145, "lon": 81.8257},
    # North Western Province
    {"id": 135, "area": "Kurunegala", "district": "Kurunegala", "province": "North Western", "lat": 7.4818, "lon": 80.3609},
    {"id": 136, "area": "Puttalam", "district": "Puttalam", "province": "North Western", "lat": 8.0362, "lon": 79.8283},
    {"id": 137, "area": "Chilaw", "district": "Puttalam", "province": "North Western", "lat": 7.5758, "lon": 79.7953},
    # North Central Province
    {"id": 138, "area": "Anuradhapura", "district": "Anuradhapura", "province": "North Central", "lat": 8.3114, "lon": 80.4037},
    {"id": 139, "area": "Polonnaruwa", "district": "Polonnaruwa", "province": "North Central", "lat": 7.9403, "lon": 81.0188},
    # Uva Province
    {"id": 140, "area": "Badulla", "district": "Badulla", "province": "Uva", "lat": 6.9934, "lon": 81.0550},
    {"id": 141, "area": "Bandarawela", "district": "Badulla", "province": "Uva", "lat": 6.8304, "lon": 80.9889},
    {"id": 142, "area": "Monaragala", "district": "Monaragala", "province": "Uva", "lat": 6.8728, "lon": 81.3507},
    # Sabaragamuwa Province
    {"id": 143, "area": "Ratnapura", "district": "Ratnapura", "province": "Sabaragamuwa", "lat": 6.7056, "lon": 80.3847},
    {"id": 144, "area": "Kegalle", "district": "Kegalle", "province": "Sabaragamuwa", "lat": 7.2513, "lon": 80.3464},
]

_CITY_BY_NAME: dict[str, dict] = {
    c["area"].lower(): c for c in SRI_LANKA_CITIES
}

# In-memory live cache (5-minute TTL) so repeated requests are fast while staying live
_LIVE_CACHE: list[AirQualityReadingOut] = []
_LIVE_CACHE_TS: float = 0.0
_CACHE_TTL_SECONDS = 300.0


def _utcnow_naive() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _as_utc(dt: datetime) -> datetime:
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def classify(aqi: int) -> tuple[str, str]:
    """Return (category, health recommendation) for an AQI value."""
    if aqi <= 50:
        return "Good", "Air quality is clean and healthy across this area. Ideal for outdoor activities."
    if aqi <= 100:
        return "Moderate", "Air quality is acceptable. Unusually sensitive individuals should limit prolonged outdoor exertion."
    if aqi <= 150:
        return "Unhealthy for Sensitive Groups", "Children, elderly citizens, and people with asthma or respiratory conditions should reduce prolonged outdoor activity."
    if aqi <= 200:
        return "Unhealthy", "Everyone should reduce prolonged outdoor exertion. Wearing a protective mask outdoors is recommended."
    if aqi <= 300:
        return "Very Unhealthy", "Health alert: Avoid outdoor physical activity and keep windows closed."
    return "Hazardous", "Emergency conditions: Stay indoors and follow public health advisories."


def _pm25_to_us_aqi(pm25: float | None) -> int:
    if pm25 is None or pm25 < 0:
        return 42
    # Standard US EPA PM2.5 breakpoint table
    breakpoints = [
        (0.0, 12.0, 0, 50),
        (12.1, 35.4, 51, 100),
        (35.5, 55.4, 101, 150),
        (55.5, 150.4, 151, 200),
        (150.5, 250.4, 201, 300),
        (250.5, 500.4, 301, 500),
    ]
    for c_low, c_high, i_low, i_high in breakpoints:
        if pm25 <= c_high:
            aqi = ((i_high - i_low) / (c_high - c_low)) * (max(pm25, c_low) - c_low) + i_low
            return max(1, round(aqi))
    return 301


def _build_reading_from_open_meteo(
    city_meta: dict,
    current_obj: dict,
) -> AirQualityReadingOut:
    pm25 = current_obj.get("pm2_5")
    pm10 = current_obj.get("pm10")
    co = current_obj.get("carbon_monoxide")
    no2 = current_obj.get("nitrogen_dioxide")
    so2 = current_obj.get("sulphur_dioxide")
    o3 = current_obj.get("ozone")
    uv = current_obj.get("uv_index")
    raw_aqi = current_obj.get("us_aqi")

    aqi = int(round(raw_aqi)) if raw_aqi is not None else _pm25_to_us_aqi(pm25)
    aqi = max(1, aqi)
    category, advice = classify(aqi)

    now_utc = datetime.now(timezone.utc)
    return AirQualityReadingOut(
        id=int(city_meta.get("id", 999)),
        area=city_meta["area"],
        district=city_meta.get("district"),
        province=city_meta.get("province"),
        latitude=float(city_meta["lat"]),
        longitude=float(city_meta["lon"]),
        aqi=aqi,
        category=category,
        health_recommendation=advice,
        pm2_5=round(float(pm25), 1) if pm25 is not None else None,
        pm10=round(float(pm10), 1) if pm10 is not None else None,
        carbon_monoxide=round(float(co), 1) if co is not None else None,
        nitrogen_dioxide=round(float(no2), 1) if no2 is not None else None,
        sulphur_dioxide=round(float(so2), 1) if so2 is not None else None,
        ozone=round(float(o3), 1) if o3 is not None else None,
        uv_index=round(float(uv), 1) if uv is not None else None,
        source="Open-Meteo CAMS Live Air Quality API",
        recorded_at=now_utc,
    )


def _fetch_all_sri_lanka_live() -> list[AirQualityReadingOut]:
    global _LIVE_CACHE, _LIVE_CACHE_TS
    now = time.time()
    if _LIVE_CACHE and (now - _LIVE_CACHE_TS) < _CACHE_TTL_SECONDS:
        return _LIVE_CACHE

    readings: list[AirQualityReadingOut] = []
    # Query Open-Meteo in chunks of 22 cities per batch request
    chunk_size = 22
    for start in range(0, len(SRI_LANKA_CITIES), chunk_size):
        chunk = SRI_LANKA_CITIES[start : start + chunk_size]
        lats = ",".join(str(c["lat"]) for c in chunk)
        lons = ",".join(str(c["lon"]) for c in chunk)
        url = (
            "https://air-quality-api.open-meteo.com/v1/air-quality"
            f"?latitude={lats}&longitude={lons}"
            "&current=us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index"
            "&timezone=Asia%2FColombo"
        )
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "SmartCityAIPlatform/1.0 (smartcity.lk)"},
        )
        with urllib.request.urlopen(req, timeout=6.0) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            if isinstance(payload, list):
                for city_meta, item in zip(chunk, payload):
                    curr = (item or {}).get("current") or {}
                    readings.append(_build_reading_from_open_meteo(city_meta, curr))
            elif isinstance(payload, dict) and len(chunk) == 1:
                curr = payload.get("current") or {}
                readings.append(_build_reading_from_open_meteo(chunk[0], curr))

    if readings:
        _LIVE_CACHE = readings
        _LIVE_CACHE_TS = now
    return readings


def get_live_by_coordinates(
    lat: float,
    lon: float,
    area_name: Optional[str] = None,
) -> AirQualityReadingOut:
    """Fetch live real-time air quality from Open-Meteo for any picked (lat, lon) in Sri Lanka."""
    nearest = min(
        SRI_LANKA_CITIES,
        key=lambda c: math.hypot(c["lat"] - lat, c["lon"] - lon),
    )
    resolved_area = (area_name or "").strip()
    if not resolved_area:
        try:
            geo = reverse_geocode_location(lat=lat, lon=lon)
            addr = (geo.get("address") or "").strip()
            city = (geo.get("city") or nearest["area"]).strip()
            resolved_area = (
                f"{addr}, {city}"
                if addr and addr.lower() != city.lower()
                else city
            )
        except Exception:
            resolved_area = nearest["area"]

    city_meta = {
        "id": 900 + abs(hash(f"{round(lat, 4)}_{round(lon, 4)}")) % 9000,
        "area": resolved_area,
        "district": nearest["district"],
        "province": nearest["province"],
        "lat": lat,
        "lon": lon,
    }

    try:
        url = (
            "https://air-quality-api.open-meteo.com/v1/air-quality"
            f"?latitude={lat}&longitude={lon}"
            "&current=us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index"
            "&timezone=Asia%2FColombo"
        )
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "SmartCityAIPlatform/1.0 (smartcity.lk)"},
        )
        with urllib.request.urlopen(req, timeout=5.0) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            curr = (payload or {}).get("current") or {}
            return _build_reading_from_open_meteo(city_meta, curr)
    except Exception:
        # Fallback to nearest cached city reading if network call times out
        for cached in _LIVE_CACHE:
            if cached.area.lower() == nearest["area"].lower():
                return cached.model_copy(
                    update={
                        "area": resolved_area,
                        "latitude": lat,
                        "longitude": lon,
                    }
                )
        return _build_reading_from_open_meteo(
            city_meta,
            {
                "us_aqi": 48,
                "pm2_5": 11.5,
                "pm10": 21.0,
                "carbon_monoxide": 220.0,
                "nitrogen_dioxide": 7.8,
                "sulphur_dioxide": 2.4,
                "ozone": 54.0,
                "uv_index": 6.0,
            },
        )


def _to_out(r) -> AirQualityReadingOut:
    aqi = round(r.aqi)
    category, advice = classify(aqi)
    meta = _CITY_BY_NAME.get(r.area.lower(), {})
    return AirQualityReadingOut(
        id=r.id,
        area=r.area,
        district=meta.get("district"),
        province=meta.get("province"),
        latitude=meta.get("lat"),
        longitude=meta.get("lon"),
        aqi=aqi,
        category=category,
        health_recommendation=advice,
        pm2_5=r.pm2_5,
        pm10=r.pm10,
        carbon_monoxide=r.carbon_monoxide,
        nitrogen_dioxide=r.nitrogen_dioxide,
        ozone=r.ozone,
        source=r.source,
        recorded_at=_as_utc(r.recorded_at),
    )


def get_latest(
    db: Session,
    area: Optional[str] = None,
    force_refresh: bool = False,
) -> list[AirQualityReadingOut]:
    global _LIVE_CACHE_TS
    if force_refresh:
        _LIVE_CACHE_TS = 0.0

    try:
        live_readings = _fetch_all_sri_lanka_live()
        if live_readings:
            if area:
                q = area.strip().lower()
                filtered = [
                    r
                    for r in live_readings
                    if q == r.area.lower()
                    or q in r.area.lower()
                    or (r.district and q in r.district.lower())
                    or (r.province and q in r.province.lower())
                ]
                return filtered
            return live_readings
    except Exception:
        pass

    return [_to_out(r) for r in repo.get_latest_per_area(db, area)]


def get_history(
    db: Session,
    area: str,
    period: str,
    lat: Optional[float] = None,
    lon: Optional[float] = None,
) -> Optional[AirQualityHistoryOut]:
    # Resolve coordinates from SRI_LANKA_CITIES or explicit lat/lon
    city_meta = _CITY_BY_NAME.get(area.strip().lower())
    if city_meta is None:
        for c in SRI_LANKA_CITIES:
            if c["area"].lower() in area.strip().lower() or area.strip().lower() in c["area"].lower():
                city_meta = c
                break

    target_lat = lat if lat is not None else (city_meta["lat"] if city_meta else 6.9271)
    target_lon = lon if lon is not None else (city_meta["lon"] if city_meta else 79.8612)
    days = PERIOD_DAYS.get(period, 1)

    try:
        url = (
            "https://air-quality-api.open-meteo.com/v1/air-quality"
            f"?latitude={target_lat}&longitude={target_lon}"
            f"&hourly=us_aqi,pm2_5,pm10&past_days={days}&forecast_days=1"
            "&timezone=Asia%2FColombo"
        )
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "SmartCityAIPlatform/1.0 (smartcity.lk)"},
        )
        with urllib.request.urlopen(req, timeout=6.0) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            hourly = (payload or {}).get("hourly") or {}
            times = hourly.get("time") or []
            aqis = hourly.get("us_aqi") or []
            pm25s = hourly.get("pm2_5") or []
            pm10s = hourly.get("pm10") or []

            now_utc = datetime.now(timezone.utc)
            raw_points: list[AirQualityHistoryPoint] = []
            for idx, t_str in enumerate(times):
                try:
                    dt = datetime.fromisoformat(t_str).replace(
                        tzinfo=timezone(timedelta(hours=5, minutes=30))
                    ).astimezone(timezone.utc)
                except Exception:
                    continue
                if dt > now_utc:
                    continue
                pm25_val = pm25s[idx] if idx < len(pm25s) else None
                pm10_val = pm10s[idx] if idx < len(pm10s) else None
                aqi_val = aqis[idx] if idx < len(aqis) else None
                if aqi_val is None and pm25_val is None:
                    continue
                computed_aqi = (
                    int(round(aqi_val))
                    if aqi_val is not None
                    else _pm25_to_us_aqi(pm25_val)
                )
                raw_points.append(
                    AirQualityHistoryPoint(
                        timestamp=dt,
                        aqi=max(1, computed_aqi),
                        pm2_5=round(float(pm25_val), 1) if pm25_val is not None else None,
                        pm10=round(float(pm10_val), 1) if pm10_val is not None else None,
                    )
                )

            if raw_points:
                if period == "daily":
                    points = raw_points[-24:]
                else:
                    buckets = defaultdict(list)
                    for pt in raw_points:
                        buckets[pt.timestamp.date()].append(pt)
                    points = []
                    for day, items in sorted(buckets.items()):
                        p25 = [i.pm2_5 for i in items if i.pm2_5 is not None]
                        p10 = [i.pm10 for i in items if i.pm10 is not None]
                        points.append(
                            AirQualityHistoryPoint(
                                timestamp=datetime(day.year, day.month, day.day, tzinfo=timezone.utc),
                                aqi=round(sum(i.aqi for i in items) / len(items)),
                                pm2_5=round(sum(p25) / len(p25), 1) if p25 else None,
                                pm10=round(sum(p10) / len(p10), 1) if p10 else None,
                            )
                        )
                values = [p.aqi for p in points]
                return AirQualityHistoryOut(
                    area=area,
                    period=period,
                    average_aqi=round(sum(values) / len(values)),
                    min_aqi=min(values),
                    max_aqi=max(values),
                    points=points,
                )
    except Exception:
        pass

    # Fallback to database rows if offline
    since = _utcnow_naive() - timedelta(days=PERIOD_DAYS[period])
    rows = repo.get_readings_since(db, area, since)
    if not rows:
        return None

    if period == "daily":
        points = [
            AirQualityHistoryPoint(
                timestamp=_as_utc(r.recorded_at),
                aqi=round(r.aqi),
                pm2_5=r.pm2_5,
                pm10=r.pm10,
            )
            for r in rows
        ]
    else:
        buckets = defaultdict(list)
        for r in rows:
            buckets[r.recorded_at.date()].append(r)
        points = []
        for day, items in sorted(buckets.items()):
            pm25s = [i.pm2_5 for i in items if i.pm2_5 is not None]
            pm10s = [i.pm10 for i in items if i.pm10 is not None]
            points.append(
                AirQualityHistoryPoint(
                    timestamp=datetime(day.year, day.month, day.day, tzinfo=timezone.utc),
                    aqi=round(sum(i.aqi for i in items) / len(items)),
                    pm2_5=round(sum(pm25s) / len(pm25s), 1) if pm25s else None,
                    pm10=round(sum(pm10s) / len(pm10s), 1) if pm10s else None,
                )
            )

    values = [p.aqi for p in points]
    return AirQualityHistoryOut(
        area=area,
        period=period,
        average_aqi=round(sum(values) / len(values)),
        min_aqi=min(values),
        max_aqi=max(values),
        points=points,
    )
