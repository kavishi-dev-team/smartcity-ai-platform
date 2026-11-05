import re


CATEGORY_KEYWORDS = {
    "Roads": [
        "road", "pothole", "street", "pavement",
        "road damage", "broken road", "traffic light",
    ],
    "Waste Management": [
        "garbage", "waste", "rubbish", "dump",
        "trash", "bin", "collection",
    ],
    "Water": [
        "water", "leak", "pipe", "drainage",
        "flood", "sewage", "blocked drain",
    ],
    "Electricity": [
        "electricity", "power", "street light",
        "lamp", "blackout", "electric pole",
    ],
    "Public Safety": [
        "accident", "crime", "unsafe", "danger",
        "emergency", "fire", "theft",
    ],
}


def classify_issue(title: str, description: str) -> dict:
    text = f"{title} {description}".lower()
    text = re.sub(r"\s+", " ", text).strip()

    scores = {}

    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(
            1 for keyword in keywords
            if keyword in text
        )
        scores[category] = score

    best_category = max(scores, key=scores.get)
    best_score = scores[best_category]

    if best_score == 0:
        return {
            "category": "Other",
            "confidence": 0.0,
        }

    total_matches = sum(scores.values())
    confidence = best_score / total_matches

    return {
        "category": best_category,
        "confidence": round(confidence, 2),
    }
