from difflib import SequenceMatcher


def calculate_similarity(text1: str, text2: str) -> float:
    text1 = text1.lower().strip()
    text2 = text2.lower().strip()

    return round(
        SequenceMatcher(None, text1, text2).ratio(),
        2,
    )


def detect_duplicate(
    new_title: str,
    new_description: str,
    existing_issues: list,
    threshold: float = 0.75,
) -> dict:

    new_text = f"{new_title} {new_description}"

    duplicates = []

    for issue in existing_issues:
        existing_text = f"{issue.title} {issue.description}"

        similarity = calculate_similarity(
            new_text,
            existing_text,
        )

        if similarity >= threshold:
            duplicates.append({
                "issue_id": issue.id,
                "title": issue.title,
                "similarity": similarity,
            })

    return {
        "is_duplicate": len(duplicates) > 0,
        "duplicates": duplicates,
    }
