#!/usr/bin/env python3
"""build-vault-bundles.py: packs your vault's markdown notes into about 25 bundle files, so a
Google Apps Script (scripts/vault-docs.gs) can turn each bundle into a native Google Doc. Gemini's
Drive search reads Google Docs but not raw .md files, and 25 big Docs search better than
thousands of small ones. Run by scripts/mirror-vault-to-drive.sh after each mirror.

Usage: build-vault-bundles.py VAULT_DIR OUT_DIR [EXCLUDED_TOP_FOLDER ...]

- One bundle per folder (vault/<top>/<sub>), split into parts above LIMIT characters.
- Every note is wrapped in "=== FILE: <path> | MODIFIED: <date> ===" ... "=== END FILE: <path> ===",
  so an assistant can say which note it used.
- "00 START HERE" maps every bundle (folders, note counts, dates, top tags), lists open tasks
  ("- [ ] ...") and recent changes, and holds your key notes and latest daily notes in full.
  Key notes: set POS_BUNDLE_KEY_NOTES in config.sh to vault-relative paths separated by ";",
  for example "Tasks.md;Projects/Index.md".
- Output is deterministic (dates come from the notes, not the clock), so a bundle is rewritten
  only when its notes change. Bundles no longer produced are removed. The vault is never written.
Python 3.9 compatible (the macOS system python).
"""
import collections
import os
import re
import sys
import time

LIMIT = 500000            # characters per bundle; a Google Doc holds about 1 million
KEY_NOTES = [p.strip() for p in os.environ.get("POS_BUNDLE_KEY_NOTES", "").split(";") if p.strip()]
RECENT_DAYS = 14
TASK_DAYS = 30
LATEST_DAILY = 7
MAX_TASKS = 300
MAX_RECENT = 100
MIN_NOTES = 20
START = "00 START HERE"
DAILY = re.compile(r"^\d{4}-\d{2}-\d{2}\.md$")
MONTH = re.compile(r"^\d{4}-\d{2}$")
TASK = re.compile(r"^\s*(?:[-*]|\d+\.)\s+\[ \]\s+(.+?)\s*$")
TAG = re.compile(r"(?<![\w#/&])#([A-Za-z][\w/-]{1,40})")
FM_TAGS = re.compile(r"^tags:\s*(.*)$", re.M)


def fmt(ts):
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(ts))


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def is_archive(group):
    return group == "Archive" or group.startswith("Archive - ")


def group_of(rel):
    parts = rel.split("/")
    if len(parts) == 1:
        return "Vault root"
    if len(parts) == 2:
        return parts[0]
    return parts[0] + " - " + parts[1]


def folder_label(group):
    return "(top level)" if group == "Vault root" else group.replace(" - ", "/", 1)


def tags_of(text):
    found = set(TAG.findall(text))
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end > 0:
            m = FM_TAGS.search(text[3:end])
            if m:
                raw = m.group(1).strip().strip("[]")
                found.update(t.strip().strip("'\"#") for t in raw.split(",") if t.strip())
                if not raw:
                    block = text[3:end][m.end():]
                    for line in block.splitlines():
                        line = line.strip()
                        if not line.startswith("- "):
                            break
                        found.add(line[2:].strip().strip("'\"#"))
    return {t for t in found if t}


def collect(vault, excluded):
    notes = []
    for dirpath, dirnames, filenames in os.walk(vault):
        rel_dir = os.path.relpath(dirpath, vault)
        top = rel_dir == "."
        dirnames[:] = sorted(d for d in dirnames
                             if not d.startswith(".") and d != "_to_delete" and ".bak-" not in d
                             and not (top and d in excluded))
        for name in sorted(filenames):
            if not name.endswith(".md") or ".bak-" in name:
                continue
            path = os.path.join(dirpath, name)
            try:
                st = os.stat(path)
            except OSError:
                continue
            if st.st_size == 0:
                continue
            rel = name if top else rel_dir.replace(os.sep, "/") + "/" + name
            notes.append({"rel": rel, "mtime": st.st_mtime, "text": read(path)})
    return notes


def section(note):
    text = note["text"].rstrip("\n")
    if len(text) > LIMIT - 2000:
        text = text[:LIMIT - 2000] + "\n\n[... note truncated here: too long for one Doc ...]"
    return "\n\n=== FILE: %s | MODIFIED: %s ===\n\n%s\n\n=== END FILE: %s ===\n" % (
        note["rel"], fmt(note["mtime"]), text, note["rel"])


def build_bundles(notes):
    by_group = collections.OrderedDict()
    for note in sorted(notes, key=lambda n: n["rel"]):
        by_group.setdefault(group_of(note["rel"]), []).append(note)
    bundles, meta, where = {}, [], {}
    for group in sorted(by_group, key=lambda g: (is_archive(g), g)):
        items = by_group[group]
        if MONTH.match(group.split(" - ")[-1]):
            items = sorted(items, key=lambda n: n["rel"], reverse=True)
        parts, current, current_items = [], "", []
        for note in items:
            sec = section(note)
            if current and len(current) + len(sec) > LIMIT:
                parts.append((current, current_items))
                current, current_items = "", []
            current += sec
            current_items.append(note)
        if current:
            parts.append((current, current_items))
        for i, (body, its) in enumerate(parts, 1):
            name = group if len(parts) == 1 else "%s (part %d of %d)" % (group, i, len(parts))
            latest = max(n["mtime"] for n in its)
            tags = collections.Counter(t for n in its for t in tags_of(n["text"]))
            old = (" Old material kept for reference: newer versions of these notes may exist "
                   "in the other bundles.") if is_archive(group) else ""
            header = ("# [Vault] %s\n\n%d notes from the vault folder %s, latest change %s.%s\n"
                      "Each note starts with \"=== FILE: <path> | MODIFIED: <date> ===\" and ends with "
                      "\"=== END FILE: <path> ===\".\n") % (name, len(its), folder_label(group), fmt(latest), old)
            bundles[name] = header + body
            for n in its:
                where[n["rel"]] = name
            meta.append({"name": name, "group": group, "count": len(its), "latest": latest,
                         "first": its[0]["rel"], "last": its[-1]["rel"],
                         "tags": [t for t, _ in sorted(tags.items(), key=lambda kv: (-kv[1], kv[0]))[:8]]})
    return bundles, meta, where


def start_here(notes, meta, where):
    live = [n for n in notes if not is_archive(group_of(n["rel"]))]
    latest = max(n["mtime"] for n in notes)
    out = ["# [Vault] 00 START HERE\n",
           "Overview of the notes vault, latest change %s. Read this first: it maps every "
           "[Vault] Doc, lists open tasks and recent changes, and holds the key notes in full. "
           "To answer a question, open the bundle the map points to, and name the note you used "
           "from its \"=== FILE: <path> ===\" line.\n" % fmt(latest),
           "\n## 1. Bundle map\n",
           "| Doc | Folder | Notes | Latest change | First and last note | Common tags |",
           "|---|---|---|---|---|---|"]
    for m in meta:
        out.append("| [Vault] %s | %s | %d | %s | %s ... %s | %s |" % (
            m["name"], folder_label(m["group"]), m["count"], fmt(m["latest"])[:10],
            m["first"], m["last"], ", ".join("#" + t for t in m["tags"]) or "-"))
    if any(is_archive(m["group"]) for m in meta):
        out.append("\nArchive bundles hold older material; prefer the other bundles when both have a note.")

    by_rel = {n["rel"]: n for n in notes}
    key = [by_rel[k] for k in KEY_NOTES if k in by_rel]
    task_sources = key + [n for n in live if n["mtime"] >= latest - TASK_DAYS * 86400 and n["rel"] not in KEY_NOTES]
    tasks, seen = [], set()
    for n in task_sources:
        for line in n["text"].splitlines():
            m = TASK.match(line)
            if m and m.group(1) not in seen:
                seen.add(m.group(1))
                tasks.append("- [%s] %s" % (n["rel"], m.group(1)))
    out.append("\n## 2. Open tasks (%d)\n" % len(tasks))
    if key:
        out.append("From %s and every note changed in the %d days before the latest change.\n"
                   % (", ".join(n["rel"] for n in key), TASK_DAYS))
    else:
        out.append("From every note changed in the %d days before the latest change.\n" % TASK_DAYS)
    out.extend(tasks[:MAX_TASKS] or ["(none)"])
    if len(tasks) > MAX_TASKS:
        out.append("... and %d more in the bundles." % (len(tasks) - MAX_TASKS))

    recent = sorted((n for n in live if n["mtime"] >= latest - RECENT_DAYS * 86400),
                    key=lambda n: n["mtime"], reverse=True)
    out.append("\n## 3. Changed in the last %d days (%d notes)\n" % (RECENT_DAYS, len(recent)))
    out.extend("- %s (%s, in [Vault] %s)" % (n["rel"], fmt(n["mtime"]), where[n["rel"]])
               for n in recent[:MAX_RECENT])

    out.append("\n## 4. Key notes in full\n")
    daily = sorted((n for n in live if DAILY.match(n["rel"].split("/")[-1])),
                   key=lambda n: n["rel"].split("/")[-1], reverse=True)[:LATEST_DAILY]
    if not key and not daily:
        out.append("(none yet: set POS_BUNDLE_KEY_NOTES in config.sh, or keep daily notes named YYYY-MM-DD.md)")
    head = "\n".join(out)
    body = ""
    for n in key + [d for d in daily if d not in key]:
        sec = section(n)
        if len(head) + len(body) + len(sec) > LIMIT:
            body += "\n\n[... further key notes left out to stay under the Doc size limit ...]\n"
            break
        body += sec
    return head + body


def safe(name):
    return re.sub(r"[/:\\]", "-", name) + ".md"


def write_bundles(out_dir, bundles):
    os.makedirs(out_dir, exist_ok=True)
    wanted = {safe(name): text for name, text in bundles.items()}
    changed = 0
    for filename, text in sorted(wanted.items()):
        path = os.path.join(out_dir, filename)
        try:
            current = read(path)
        except OSError:
            current = None
        if current != text:
            tmp = path + ".tmp"
            with open(tmp, "w", encoding="utf-8") as fh:
                fh.write(text)
            os.replace(tmp, path)
            changed += 1
    removed = 0
    if len(wanted) >= 2:
        for filename in os.listdir(out_dir):
            if filename.endswith(".md") and filename not in wanted:
                os.remove(os.path.join(out_dir, filename))
                removed += 1
    return len(wanted), changed, removed


def main(argv):
    if len(argv) < 3:
        print("Usage: build-vault-bundles.py VAULT_DIR OUT_DIR [EXCLUDED_TOP_FOLDER ...]")
        return 2
    vault, out_dir, excluded = argv[1], argv[2], set(argv[3:])
    notes = collect(vault, excluded)
    if len(notes) < MIN_NOTES:
        print("FAIL | only %d notes found in %s; bundles left untouched" % (len(notes), vault))
        return 1
    bundles, meta, where = build_bundles(notes)
    bundles[START] = start_here(notes, meta, where)
    biggest = max(len(t) for t in bundles.values())
    total, changed, removed = write_bundles(out_dir, bundles)
    print("OK | %d notes -> %d bundles (%d changed, %d removed, largest %d chars)"
          % (len(notes), total, changed, removed, biggest))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
