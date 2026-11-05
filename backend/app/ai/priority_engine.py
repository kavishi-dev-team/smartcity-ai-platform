HIGH_PRIORITY_KEYWORDS = [
    "emergency",
    "life threatening",
    "fire",
    "accident",
    "danger",
    "electric shock",
    "major flood",
    "collapsed",
]

MEDIUM_PRIORITY_KEYWORDS = [
    "damaged road",
    "water leak",
    "broken street light",
    "blocked drain",
    "garbage",
    "waste collection",
]


def calculate_priority(title: str, description: str) -> dict:
    text = f"{title} {description}".lower()

    high_matches = [
        keyword for keyword in HIGH_PRIORITY_KEYWORDS
        if keyword in text
    ]

    medium_matches = [
        keyword for keyword in MEDIUM_PRIORITY_KEYWORDS
        if keyword in text
    ]

    if high_matches:
        priority = "high"
    elif medium_matches:
        priority = "medium"
    else:
        priority = "low"

    return {
        "priority": priority,
        "matched_keywords": high_matches or medium_matches,
    }
