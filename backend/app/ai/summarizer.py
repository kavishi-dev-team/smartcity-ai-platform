import re


def summarize_issue(
    title: str,
    description: str,
    max_sentences: int = 2,
) -> dict:
    text = re.sub(r"\s+", " ", description).strip()

    sentences = re.split(r"(?<=[.!?])\s+", text)

    summary = " ".join(sentences[:max_sentences])

    if not summary:
        summary = title.strip()

    return {
        "title": title,
        "summary": summary,
        "original_length": len(description),
        "summary_length": len(summary),
    }
