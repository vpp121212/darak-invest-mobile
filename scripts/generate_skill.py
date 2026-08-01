#!/usr/bin/env python3
"""Generate a SKILL.md + per-chapter files from book_to_skill extraction output.

Usage: python3 scripts/generate_skill.py <workdir> [--output <dir>]
Reads <workdir>/full_text.txt and <workdir>/metadata.json.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

CHAPTER_HEAD = re.compile(
    r"^\s*(?:#+\s+)?(?:chapter|chapitre|kapitel|cap[ií]tulo|capitolo|hoofdstuk|ch\.?)\s*(\d{1,2})",
    re.IGNORECASE,
)
HEADING = re.compile(r"^\s*(?:#{1,6}\s+)?(.*?)\s*$")


def split_chapters(text: str):
    lines = text.splitlines()
    chapters = []
    current_num = None
    current_title = None
    current = []
    for line in lines:
        m = CHAPTER_HEAD.match(line)
        if m:
            if current_num is not None:
                chapters.append((current_num, current_title, current))
            current_num = int(m.group(1))
            current_title = line.strip().lstrip("#").strip()
            current = []
        else:
            current.append(line)
    if current_num is not None:
        chapters.append((current_num, current_title, current))
    return chapters


def summarize(chapter_lines: list[str], max_lines: int = 8) -> str:
    clean = [l.strip() for l in chapter_lines if l.strip() and not l.strip().startswith("=")]
    if not clean:
        return "_No extractable content._"
    scored = []
    for line in clean:
        words = len(line.split())
        has_num = bool(re.search(r"\d", line))
        score = words + (20 if has_num else 0)
        if words < 4 or words > 40:
            score -= 5
        scored.append((score, line))
    scored.sort(key=lambda x: -x[0])
    top = [l for _, l in scored[:max_lines]]
    if not top:
        top = clean[:max_lines]
    return "\n".join("- " + l for l in top)


def slugify(title: str, idx: int) -> str:
    return f"ch{idx:02d}"


def main():
    if len(sys.argv) < 2:
        print("Usage: generate_skill.py <workdir> [--output <dir>]", file=sys.stderr)
        sys.exit(1)
    workdir = Path(sys.argv[1])
    output = Path(sys.argv[sys.argv.index("--output") + 1]) if "--output" in sys.argv else workdir / "skill"

    text = (workdir / "full_text.txt").read_text(encoding="utf-8")
    meta = json.loads((workdir / "metadata.json").read_text(encoding="utf-8"))

    filename = meta.get("filename", "book")
    title = Path(filename).stem.replace("_", " ").replace("-", " ").title()
    chapters = split_chapters(text)
    if not chapters:
        chapters = [(i + 1, f"Section {i + 1}", block) for i, block in enumerate(_fallback_sections(text))]

    output.mkdir(parents=True, exist_ok=True)
    (output / "chapters").mkdir(exist_ok=True)

    chapter_lines = []
    for idx, (num, chap_title, lines) in enumerate(chapters):
        name = slugify(chap_title or f"chapter-{num}", idx + 1)
        body = "\n".join(lines).strip()
        summary = summarize(lines)
        if not body:
            body = summary
        (output / "chapters" / f"{name}.md").write_text(
            f"# {chap_title or f'Chapter {num}'}\n\n{body}\n", encoding="utf-8"
        )
        chapter_lines.append(f"- [{chap_title or f'Chapter {num}'}](chapters/{name}.md)")

    core = [
        "## Core Mental Models",
        "",
        f"The source material spans {len(chapters)} section(s).",
        "- Each section is stored as an on-demand file under `chapters/`.",
        "- Load only the section relevant to the question — do not read everything.",
        "- Answer strictly from the source content; cite the section file when used.",
        "",
        "## Chapter Index",
        "",
    ]
    skill = [
        "---",
        f"name: {title.lower().replace(' ', '-')}",
        f"description: On-demand reference built from \"{title}\". Use for questions about the book's topics, concepts, and sections.",
        "---",
        "",
        *core,
        *chapter_lines,
        "",
        "## Usage",
        "",
        f"- Full text: `full_text.txt` (source extraction).",
        "- Stats: %s words, ~%s tokens, %s chapters detected."
        % (meta.get("words", 0), meta.get("estimated_tokens", 0), meta.get("chapters_detected", 0)),
        "",
    ]
    (output / "SKILL.md").write_text("\n".join(skill), encoding="utf-8")
    (output / "full_text.txt").write_text(text, encoding="utf-8")
    print(f"SKILL.md generated in {output} with {len(chapters)} chapters")


def _fallback_sections(text: str):
    parts = re.split(r"\n\s*\n", text)
    return [p for p in parts if p.strip()]


if __name__ == "__main__":
    main()
