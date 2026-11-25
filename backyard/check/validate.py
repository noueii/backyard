#!/usr/bin/env python3
"""Structural checks for a backyard (backyard/docs/SPEC.md, seeds format 2.0). Deterministic; no AI.

Usage: python3 backyard/check/validate.py <backyard root>
Prints one line per problem (ERROR or WARN), "needs installed: <skill>" for each installed: skill, and exits 1 on
any ERROR. Needs python3 and PyYAML.
"""
import datetime
import os
import re
import sys
import unicodedata

try:
    import yaml
except ImportError:
    sys.exit("validate.py needs PyYAML: pip install pyyaml")

FORMAT_MAJOR = 2
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SKILL_KEYS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
SEED_KEYS = {"name", "when", "group", "skills", "calls", "access", "autonomy"}
ACCESS = {"read-only", "edit", "full"}
AUTONOMY = {"decide-and-record", "stop-and-record"}
MANDATORY = ("backyard-memory",)
# The framework lives in backyard/ (backyard/docs/decisions/0002-framework-folder.md). Its skills are exactly these,
# prefixed so they don't clash with other installed skills in tools that list nested ones (0004); the owner's own
# shared skills live in skills/ at the root, and never take the prefix.
FRAMEWORK = "backyard"
PREFIX = "backyard-"
FRAMEWORK_SKILLS = ("backyard-memory", "backyard-escalate", "backyard-handoff", "backyard-sync", "backyard-new-seed")
# Skill names backyard no longer ships, and where they went (backyard/docs/MIGRATING.md).
RETIRED_SKILLS = {"rsi": "merged into backyard-memory", "memory": "renamed backyard-memory",
                  "escalate": "renamed backyard-escalate", "handoff": "renamed backyard-handoff",
                  "sync": "renamed backyard-sync", "new-seed": "renamed backyard-new-seed"}
# Where a SKILL.md may be: the router, and one per skill folder (0004). Nowhere else, in any casing.
SKILL_MD_AT = re.compile(r"^(SKILL\.md|(backyard/skills|skills|seeds/[^/]+/skills)/[^/]+/SKILL\.md)$")
# What a backyard skill's description says first: it runs through the router, not on its own.
THROUGH_BACKYARD = "Part of the backyard skill"
FRAMEWORK_DIRS = ("skills", "docs", "check", "dev")
# Backyard-owned paths outside backyard/, each needed at the root (0002): the router, CI and the union merge.
ROOT_OWNED = ("SKILL.md", "backyard/", ".github/workflows/backyard.yml", ".gitattributes")
UPSTREAM_PATHS = "backyard/docs/upstream-paths.txt"
# Where the framework's files sat before 2.0.0: any of them at the root means a half-done move.
OLD_LAYOUT = ("spec/SPEC.md", "spec/upstream-paths.txt", "spec/MIGRATING.md", "check/validate.py",
              "check/pre-commit.sh", "guide/tutorial.md", "guide/reference.md", "dev/AGENTS.md",
              "dev/check-upstream.sh", "dev/test-validate.sh", "dev/test-scripts.sh", "dev/decisions/README.md")
# Names that only the owner's content uses: never inside backyard/ (new-seed's examples excepted for SEED.md).
USER_NAMES = ("MEMORY.md", "SEED.md", "INDEX.md")
EXAMPLES = "backyard/skills/backyard-new-seed/examples/"
REJECTED_INTRO = "Proposals the owner declined. Read before proposing a change; never re-propose one without new evidence."
REJECTED_LINE = re.compile(r"^- \d{4}-\d{2}-\d{2} \| [^|]+ \| [^|]+$")
DOC_LINE = re.compile(r"^- \[([^\]/]+\.md)\]\(([^)]+)\): read when .+\.$")
SEED_LINE = re.compile(r"^- ([a-z0-9-]+): (.+)$")
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
TEXT_EXT = {".md", ".sh", ".py", ".txt", ".yaml", ".yml", ".json"}


class Report:
    def __init__(self):
        self.errors, self.warns, self.installed = [], [], set()

    def err(self, path, msg):
        self.errors.append(f"ERROR {path}: {msg}")

    def warn(self, path, msg):
        self.warns.append(f"WARN  {path}: {msg}")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def words(text):
    return len(text.split())


def frontmatter(path, rep, rel):
    """(dict, body) or (None, text) after reporting the problem."""
    text = read(path)
    if not text.startswith("---\n"):
        rep.err(rel, "no YAML frontmatter (the file must start with ---)")
        return None, text
    end = text.find("\n---\n", 4)
    if end < 0:
        rep.err(rel, "frontmatter is not closed with ---")
        return None, text
    try:
        data = yaml.safe_load(text[4:end]) or {}
    except (yaml.YAMLError, ValueError) as e:
        rep.err(rel, f"frontmatter is not valid YAML: {str(e).splitlines()[0]}")
        return None, text
    if not isinstance(data, dict):
        rep.err(rel, "frontmatter is not a mapping")
        return None, text
    return data, text[end + 5:]


def strip_code(text):
    text = re.sub(r"^(```|~~~).*?^\1[^\n]*$", "", text, flags=re.S | re.M)
    return re.sub(r"`[^`\n]*`", "", text)


def check_description(rel, d, rep, need_use_when=True):
    desc = d.get("description")
    if not isinstance(desc, str) or not desc.strip():
        rep.err(rel, "description is missing")
        return
    if len(desc) > 1024:
        rep.err(rel, f"description is {len(desc)} characters (budget 1024)")
    if "use when" not in desc.lower():
        (rep.err if need_use_when else rep.warn)(rel, 'description does not contain "Use when"')


# ---------------------------------------------------------------- layout
def walk(root, rep):
    """All files below root (relative paths), checking SKILL.md and nested .git on the way."""
    files = []
    for d, dirs, names in os.walk(root):
        reld = os.path.relpath(d, root)
        if reld == ".":
            dirs[:] = [x for x in dirs if x != ".git"]
        for x in list(dirs):
            if x == ".git":
                rep.err(os.path.join(reld, x), "a .git folder below the root (no clone, worktree or copy inside a backyard)")
                dirs.remove(x)
            elif x.lower() == "skill.md":
                rep.err(os.path.join(reld, x), "a folder named SKILL.md")
        for n in names:
            rel = os.path.normpath(os.path.join(reld, n))
            if rel == ".git":
                continue
            if n == ".git" and reld != ".":
                rep.err(rel, "a .git file below the root (a worktree or submodule inside the backyard)")
            if n.lower() == "skill.md" and not SKILL_MD_AT.match(rel.replace(os.sep, "/")):
                rep.err(rel, "a SKILL.md is allowed only at the root and as a skill's own file (backyard/skills/<s>/, "
                        "skills/<s>/, seeds/<x>/skills/<s>/), always in that casing")
            files.append(rel)
    return files


def require(root, rel, rep):
    if not os.path.isfile(os.path.join(root, rel)):
        rep.err(rel, "required file is missing")
        return False
    return True


def subdirs(path):
    return sorted(x for x in os.listdir(path) if os.path.isdir(os.path.join(path, x))) if os.path.isdir(path) else []


# ---------------------------------------------------------------- separation of backyard/ and the owner's content
def check_separation(root, files, rep):
    """The framework is SKILL.md, backyard/ and ROOT_OWNED; the owner's content is never inside backyard/."""
    g = os.path.join(root, FRAMEWORK)
    if not os.path.isdir(g):
        rep.err(FRAMEWORK, "the framework folder backyard/ is missing")
    for rel in OLD_LAYOUT:
        if os.path.exists(os.path.join(root, rel)):
            rep.err(rel, "a backyard-owned file outside backyard/ (the old layout: backyard/docs/MIGRATING.md)")
    for x in sorted(os.listdir(g)) if os.path.isdir(g) else []:
        if x not in FRAMEWORK_DIRS:
            rep.err(os.path.join(FRAMEWORK, x), f"backyard/ holds only {', '.join(FRAMEWORK_DIRS)}: "
                    "your own content goes outside backyard/ (docs/, seeds/, skills/, memory/)")
    for x in subdirs(os.path.join(g, "skills")):
        if x in RETIRED_SKILLS:
            rep.err(os.path.join(FRAMEWORK, "skills", x), f"backyard's {x} skill is {RETIRED_SKILLS[x]}: "
                    "this folder is left over (backyard/docs/MIGRATING.md)")
        elif x not in FRAMEWORK_SKILLS:
            rep.err(os.path.join(FRAMEWORK, "skills", x),
                    f"not one of backyard's skills: your own shared skills go in skills/{x}/")
    for rel in files:
        r = rel.replace(os.sep, "/")
        if not r.startswith(FRAMEWORK + "/"):
            continue
        parts = r.split("/")
        if "seeds" in parts[:-1] or (parts[-1] in USER_NAMES and not (parts[-1] == "SEED.md" and r.startswith(EXAMPLES))):
            rep.err(rel, "your own content (seeds, docs indexes, memory) never goes inside backyard/")
    if not require(root, UPSTREAM_PATHS, rep):
        return
    listed = [x.strip() for x in read(os.path.join(root, UPSTREAM_PATHS)).splitlines()
              if x.strip() and not x.startswith("#")]
    for x in listed:
        if x not in ROOT_OWNED:
            rep.err(UPSTREAM_PATHS, f"{x}: backyard owns only {', '.join(ROOT_OWNED)}")
    for x in ("SKILL.md", "backyard/"):
        if x not in listed:
            rep.err(UPSTREAM_PATHS, f"{x} is missing")


# ---------------------------------------------------------------- router and skills
def check_router(root, rep):
    if not os.path.isfile(os.path.join(root, "SKILL.md")):
        rep.err("SKILL.md", "the router is missing")
        return
    d, body = frontmatter(os.path.join(root, "SKILL.md"), rep, "SKILL.md")
    if d is None:
        return
    extra = set(d) - SKILL_KEYS
    if extra:
        rep.err("SKILL.md", f"keys outside the Agent Skills fields: {', '.join(sorted(extra))}")
    if d.get("name") != "backyard":
        rep.err("SKILL.md", f"name must be backyard, not {d.get('name')!r}")
    check_description("SKILL.md", d, rep)
    meta = d.get("metadata") if isinstance(d.get("metadata"), dict) else {}
    fmt = str(meta.get("seeds-format", ""))
    if not re.match(r"^\d+\.\d+$", fmt):
        rep.err("SKILL.md", "metadata.seeds-format is missing (\"2.0\")")
    elif int(fmt.split(".")[0]) != FORMAT_MAJOR:
        rep.err("SKILL.md", f"seeds-format {fmt}: this validator knows major {FORMAT_MAJOR}")
    if words(body) > 600:
        rep.err("SKILL.md", f"body is {words(body)} words (budget 600)")


def check_skill_dir(root, reld, rep):
    """A backyard/skills/<s>/, skills/<s>/ or seeds/<x>/skills/<s>/ folder: SKILL.md, frontmatter, budgets.
    Returns True if it is a usable skill."""
    name = os.path.basename(reld)
    entry = os.path.join(reld, "SKILL.md")
    backyard_own = reld.replace(os.sep, "/").startswith(FRAMEWORK + "/")
    if not NAME_RE.match(name) or len(name) > 64:
        rep.err(reld, "skill folder names are lowercase letters, digits and single hyphens")
    if not backyard_own and (name == FRAMEWORK or name.startswith(PREFIX)):
        rep.err(reld, f"backyard and {PREFIX}* are backyard's own names: name your skill without them")
    if os.path.exists(os.path.join(root, reld, "ENTRY.md")):
        rep.err(os.path.join(reld, "ENTRY.md"), "a skill's file is SKILL.md since backyard 3.0.0: rename it "
                "(backyard/docs/MIGRATING.md)")
    if not require(root, entry, rep):
        return False
    d, body = frontmatter(os.path.join(root, entry), rep, entry)
    if d is None:
        return True
    if d.get("name") != name:
        rep.err(entry, f"name {d.get('name')!r} must equal the folder name {name!r}")
    extra = set(d) - SKILL_KEYS
    if extra:
        (rep.err if backyard_own else rep.warn)(
            entry, f"keys outside the Agent Skills fields: {', '.join(sorted(map(str, extra)))}")
    meta = d.get("metadata") if isinstance(d.get("metadata"), dict) else {}
    vendored = "source" in meta
    if vendored and "commit" not in meta:
        rep.err(entry, "a vendored skill (metadata.source) needs metadata.commit")
    check_description(entry, d, rep, need_use_when=not vendored)
    if backyard_own and not str(d.get("description", "")).startswith(THROUGH_BACKYARD):
        rep.err(entry, f'a backyard skill\'s description starts with "{THROUGH_BACKYARD}": tools that list nested '
                "skills (opencode) must see it is used through the router, not on its own")
    if words(body) > 800:
        rep.err(entry, f"body is {words(body)} words (budget 800)")
    for d2, _, names in os.walk(os.path.join(root, reld)):
        for n in names:
            p = os.path.join(d2, n)
            rel = os.path.relpath(p, root)
            if n == "SKILL.md" or os.path.splitext(n)[1] not in TEXT_EXT:
                continue
            with open(p, encoding="utf-8", errors="replace") as f:
                lines = sum(1 for _ in f)
            if lines > 300:
                rep.err(rel, f"{lines} lines (a supporting file's budget is 300)")
    return True


def any_disable(root, files, rep):
    for rel in files:
        if os.path.basename(rel) in ("SKILL.md", "SEED.md"):
            text = read(os.path.join(root, rel))
            if text.startswith("---\n") and re.search(r"^disable-model-invocation\s*:", text.split("\n---\n", 1)[0], re.M):
                rep.err(rel, "disable-model-invocation is never allowed")


# ---------------------------------------------------------------- docs
def check_docs(root, reld, rep):
    path = os.path.join(root, reld)
    index = os.path.join(reld, "INDEX.md")
    if not os.path.isdir(path):
        rep.err(reld, "the docs folder is missing (it holds at least INDEX.md)")
        return
    for x in subdirs(path):
        rep.err(os.path.join(reld, x), "docs folders are flat: no subfolders")
    if not require(root, index, rep):
        return
    lines = read(os.path.join(root, index)).splitlines()
    if not lines or lines[0] != "# Docs":
        rep.err(index, 'the first line must be "# Docs"')
    listed = []
    for i, line in enumerate(lines[1:], 2):
        if not line.strip():
            continue
        m = DOC_LINE.match(line)
        if not m or m.group(1) != m.group(2):
            rep.err(f"{index}:{i}", "not an index line: - [<file>](<file>): read when <condition>.")
            continue
        if len(line) > 160:
            rep.err(f"{index}:{i}", f"{len(line)} characters (budget 160)")
        listed.append(m.group(1))
    if len(listed) > 40:
        rep.err(index, f"{len(listed)} entries (budget 40)")
    docs = sorted(x for x in os.listdir(path) if x.endswith(".md") and x != "INDEX.md")
    for x in sorted(set(listed)):
        if listed.count(x) > 1:
            rep.err(index, f"{x} is listed more than once")
        if x not in docs:
            rep.err(index, f"lists {x}, which does not exist")
    for x in docs:
        if x not in listed:
            rep.err(os.path.join(reld, x), "not listed in INDEX.md")
        n = words(read(os.path.join(path, x)))
        if n > 1500:
            rep.err(os.path.join(reld, x), f"{n} words (budget 1500)")


# ---------------------------------------------------------------- memory
# One table for the validator and backyard/skills/backyard-memory/write.py (backyard/docs/SPEC.md §6-7). A memory folder is the
# root's memory/ or seeds/<name>/memory/:
#   INDEX.md     one line per committed file: - [<file>](committed/<file>): read when <condition>.
#   committed/   YYYY-MM-DD-<description>.md: memories the owner stated, or promoted after a 2nd sighting
#   pending/     YYYY-MM-DD-<description>.md: seen once, waiting for a 2nd sighting (never indexed)
#   rejected.md  the root's only: proposals the owner declined
# Compaction is due at 80 % of a budget; at 100 % write.py refuses the write and the validator fails the folder.
MEMORY_BUDGETS = {
    "index": 50,          # INDEX.md entries (one per committed file)
    "index_line": 300,    # characters per INDEX.md line
    "committed": 50,      # files in committed/
    "pending": 30,        # files in pending/
    "file": 1200,         # characters per committed or pending file
    "rejected": 100,      # lines in rejected.md
    "rejected_line": 400,  # characters per rejected.md line
}
COMPACT_AT = 0.8
MEMORY_TYPES = ("fact", "decision", "preference", "lesson")
MEMORY_KEYS = {"type", "date", "source", "seen"}
MEMORY_NAME = re.compile(r"^(\d{4}-\d{2}-\d{2})-([a-z0-9]+(?:-[a-z0-9]+)+)\.md$")
MEMORY_DESC_MAX = 50
INDEX_HEADER = "# Memory"
INDEX_INTRO = ("One line per committed memory, most valuable first: tools may load only the start. "
               "Open a file only when its line fits the task.")
INDEX_LINE = re.compile(r"^- \[([^\]/]+)\]\(([^)]+)\): read when .+\.$")
REJECTED_HEADER = "# Rejected"
# The 1.x memory files (seeds-format 1.0): any of them left means a half-done migration.
OLD_MEMORY = ("runs.md", "lessons.md", "archive.md", "unrouted.md")
OWNER_SOURCE = re.compile(r"^owner\b", re.I)


# Text that is untrusted until verified (tool output, web pages, issue text, called-seed reports) must never
# become memory as instructions, secrets or hidden characters.
INSTRUCTION = [
    r"\b(ignore|disregard|forget|override)\b.{0,40}\b(previous|prior|above|earlier|all|your|these)\b.{0,20}\b(instructions?|rules?|prompts?|guidelines?)\b",
    r"\b(new|updated|real|actual) (system )?(instructions?|rules?)\b",
    r"\bsystem prompt\b", r"</?\s*(system|assistant|user|instructions?)\s*>",
    r"\byou (are|must|should|will) (now|always|never|from now on)\b", r"\bfrom now on\b",
    r"\b(do not|don't|never) (tell|inform|mention|reveal|show)\b.{0,30}\b(owner|user|human)\b",
    r"\b(run|execute|exec)\b.{0,15}\b(this|the following) (command|script|code)\b",
    r"\b(curl|wget)\b[^|]{0,200}\|\s*(ba|z)?sh\b",
    r"^\s*(always|never)\b",
]
SECRET = [
    r"\bgh[pousr]_[A-Za-z0-9]{20,}", r"\bgithub_pat_[A-Za-z0-9_]{20,}", r"\bsk-(ant-)?[A-Za-z0-9_-]{20,}",
    r"\bAKIA[0-9A-Z]{16}\b", r"\bxox[abpors]-[A-Za-z0-9-]{10,}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
    r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}",
    r"\b(api[_-]?key|access[_-]?token|auth[_-]?token|secret|password|passwd)\b\s*[:=]\s*['\"]?[^\s'\"]{8,}",
    r"\bAIza[0-9A-Za-z_-]{30,}", r"://[^/\s:@]+:[^/\s@]+@",
]


def scan(text):
    """The first reason this text must not become memory, or None."""
    for ch in text:
        if ch in "\n\t":
            continue
        cat = unicodedata.category(ch)
        if cat in ("Cc", "Cf", "Co", "Cs", "Cn") or ch in "   ":
            return f"invisible or control character U+{ord(ch):04X} ({unicodedata.name(ch, cat)})"
    for pat in SECRET:
        if re.search(pat, text, re.I):
            return "it looks like a secret or token: never store one; say where it lives instead"
    for pat in INSTRUCTION:
        m = re.search(pat, text, re.I | re.M)
        if m:
            return (f"instruction-like text ({m.group(0).strip()!r}): memory holds facts, not instructions; "
                    "a rule goes to docs through a staged change (backyard/skills/backyard-memory/stage.md), and untrusted "
                    "text stays out unless verified")
    return None


def scan_lines(text):
    """[(line number, reason)] for each line of a memory file that must not be memory."""
    return [(i, r) for i, line in enumerate(text.splitlines(), 1) for r in [scan(line)] if r]


def memory_place(rel):
    """(memory folder, part, file name) for a path relative to the root, or None if it is not memory.
    part is index, committed, pending or rejected."""
    parts = rel.replace(os.sep, "/").split("/")
    if parts[:1] == ["seeds"] and len(parts) >= 3:
        mdir, parts = "/".join(parts[:3]), parts[2:]
        if parts[0] != "memory":
            return None
    elif parts[:1] == ["memory"]:
        mdir = "memory"
    else:
        return None
    rest = parts[1:]
    if rest == ["INDEX.md"]:
        return mdir, "index", "INDEX.md"
    if rest == ["rejected.md"] and mdir == "memory":
        return mdir, "rejected", "rejected.md"
    if len(rest) == 2 and rest[0] in ("committed", "pending"):
        return mdir, rest[0], rest[1]
    return None


def name_problem(name):
    m = MEMORY_NAME.match(name)
    if not m:
        return "a memory file is named YYYY-MM-DD-<short-kebab-description>.md (at least two words)"
    try:
        datetime.date.fromisoformat(m.group(1))
    except ValueError:
        return f"{m.group(1)} is not a date"
    if len(m.group(2)) > MEMORY_DESC_MAX:
        return f"the description is {len(m.group(2))} characters (budget {MEMORY_DESC_MAX}): keep it short and grepable"
    return None


def description_of(name):
    m = MEMORY_NAME.match(name)
    return m.group(2) if m else name


def parse_memory(text):
    """(frontmatter dict or None, body, problem or None) for a committed or pending file."""
    if not text.startswith("---\n"):
        return None, text, "no frontmatter (the file starts with ---: type, date, source)"
    end = text.find("\n---\n", 4)
    if end < 0:
        return None, text, "the frontmatter is not closed with ---"
    try:
        d = yaml.safe_load(text[4:end]) or {}
    except (yaml.YAMLError, ValueError) as e:  # ValueError: a date-like value that is no date (2026-13-40)
        return None, text, f"the frontmatter is not valid YAML: {str(e).splitlines()[0]}"
    if not isinstance(d, dict):
        return None, text, "the frontmatter is not a mapping"
    return d, text[end + 5:], None


def memory_file_problems(part, name, text):
    """[problem] for one committed or pending file: name, frontmatter, the promotion gate, size."""
    out = []
    p = name_problem(name)
    if p:
        out.append(p)
    if len(text) > MEMORY_BUDGETS["file"]:
        out.append(f"{len(text)} characters (budget {MEMORY_BUDGETS['file']}): a memory is a few lines")
    d, body, p = parse_memory(text)
    if p:
        return out + [p]
    extra = set(d) - MEMORY_KEYS
    if extra:
        out.append(f"unknown frontmatter keys: {', '.join(sorted(map(str, extra)))} (allowed: type, date, source, seen)")
    if d.get("type") not in MEMORY_TYPES:
        out.append(f"type {d.get('type')!r}: one of {', '.join(MEMORY_TYPES)}")
    m = MEMORY_NAME.match(name)
    if str(d.get("date", "")) != (m.group(1) if m else None):
        out.append("date is missing or differs from the date in the file name")
    source = d.get("source")
    if not isinstance(source, str) or not source.strip() or "\n" in source.strip():
        out.append("source is missing: one line saying where it came from (owner: \"<their words>\" for the owner)")
        source = ""
    seen = d.get("seen", [])
    if not isinstance(seen, list) or not all(isinstance(x, str) and NAME_RE.match(x) for x in seen):
        out.append("seen is a list of task slugs")
        seen = []
    owner = bool(OWNER_SOURCE.match(source.strip()))
    if part == "pending" and not seen:
        out.append("a pending memory has seen: [<task>], the task that saw it")
    if part == "committed" and not owner and len(set(seen)) < 2:
        out.append("the promotion gate: a committed memory is the owner's (source: owner: ...) "
                   "or was seen by 2 tasks (seen: [a, b])")
    if not body.strip():
        out.append("no body: say the memory and why it holds")
    return out


def index_entries(text):
    """([(line number, file, target)], [(line number, problem)]) for a memory INDEX.md."""
    lines = text.splitlines()
    entries, out = [], []
    if not lines or lines[0] != INDEX_HEADER:
        out.append((1, f'the first line must be "{INDEX_HEADER}"'))
    for i, line in enumerate(lines[1:], 2):
        if not line.strip() or line == INDEX_INTRO:
            continue
        m = INDEX_LINE.match(line)
        if not m:
            out.append((i, "not an index line: - [<file>](committed/<file>): read when <condition>."))
            continue
        if len(line) > MEMORY_BUDGETS["index_line"]:
            out.append((i, f"{len(line)} characters (budget {MEMORY_BUDGETS['index_line']})"))
        f, target = m.groups()
        if target.startswith("pending/"):
            out.append((i, f"{target}: pending memories are never indexed (they are not memory yet)"))
        elif target != f"committed/{f}":
            out.append((i, f"the link is committed/{f}, not {target}"))
        else:
            entries.append((i, f, target))
    if len(entries) > MEMORY_BUDGETS["index"]:
        out.append((None, f"{len(entries)} entries (budget {MEMORY_BUDGETS['index']})"))
    return entries, out


def rejected_problems(text):
    lines = text.splitlines()
    out = []
    if not lines or lines[0] != REJECTED_HEADER:
        out.append((1, f'the first line must be "{REJECTED_HEADER}"'))
    if len(lines) > MEMORY_BUDGETS["rejected"]:
        out.append((None, f"{len(lines)} lines (budget {MEMORY_BUDGETS['rejected']})"))
    for i, line in enumerate(lines[1:], 2):
        if not line.strip() or line == REJECTED_INTRO:
            continue
        if len(line) > MEMORY_BUDGETS["rejected_line"]:
            out.append((i, f"{len(line)} characters (budget {MEMORY_BUDGETS['rejected_line']})"))
        if not REJECTED_LINE.match(line):
            out.append((i, "not a rejected line: - YYYY-MM-DD | <proposal> | <reason>"))
    return out


def memory_files(root, mdir, part):
    d = os.path.join(root, mdir, part)
    return sorted(x for x in os.listdir(d) if not x.startswith(".") and os.path.isfile(os.path.join(d, x))) \
        if os.path.isdir(d) else []


def memory_usage(root, mdir):
    """{budget name: (used, budget)} for one memory folder, for the 80 % notes."""
    use = {"committed": len(memory_files(root, mdir, "committed")), "pending": len(memory_files(root, mdir, "pending"))}
    ip = os.path.join(root, mdir, "INDEX.md")
    use["index"] = len(index_entries(read(ip))[0]) if os.path.isfile(ip) else 0
    rp = os.path.join(root, mdir, "rejected.md")
    if os.path.isfile(rp):
        use["rejected"] = len(read(rp).splitlines())
    return {k: (v, MEMORY_BUDGETS[k]) for k, v in use.items()}


def memory_problems(root, mdir):
    """[(path, problem)] for one memory folder (mdir: memory or seeds/<name>/memory)."""
    out = []
    owner_dir = os.path.dirname(mdir)
    old = os.path.join(owner_dir, "MEMORY.md")
    if os.path.exists(os.path.join(root, old)):
        out.append((old, "MEMORY.md is gone since seeds-format 2.0: its lines become files in "
                    f"{mdir}/committed/, listed in {mdir}/INDEX.md (backyard/docs/MIGRATING.md)"))
    path = os.path.join(root, mdir)
    if not os.path.isdir(path):
        return out + [(os.path.join(mdir, "INDEX.md"), "required file is missing")]
    for x in sorted(os.listdir(path)):
        rel = os.path.join(mdir, x)
        if x.startswith("."):
            continue
        if x in OLD_MEMORY:
            out.append((rel, "the 1.x memory layout (seeds-format 1.0): runs.md, lessons.md, archive.md and "
                        "unrouted.md are gone (backyard/docs/MIGRATING.md)"))
        elif os.path.isdir(os.path.join(path, x)):
            if x not in ("committed", "pending"):
                out.append((rel, "memory folders hold only committed/ and pending/"))
        elif x == "rejected.md" and mdir != "memory":
            out.append((rel, "rejected.md lives in the root memory/ only"))
        elif x not in ("INDEX.md", "rejected.md"):
            out.append((rel, f"not part of the memory layout: {mdir}/ holds INDEX.md, committed/ and pending/ "
                        "(and rejected.md at the root)"))
    if not os.path.isfile(os.path.join(path, "INDEX.md")):
        out.append((os.path.join(mdir, "INDEX.md"), "required file is missing"))
        entries = []
    else:
        text = read(os.path.join(path, "INDEX.md"))
        entries, problems = index_entries(text)
        for i, problem in problems + scan_lines(text):
            out.append((f"{mdir}/INDEX.md" + (f":{i}" if i else ""), problem))
    descs = {}
    for part in ("committed", "pending"):
        d = os.path.join(path, part)
        for x in subdirs(d):
            out.append((os.path.join(mdir, part, x), f"{part}/ is flat: no subfolders"))
        names = memory_files(root, mdir, part)
        if len(names) > MEMORY_BUDGETS[part]:
            out.append((os.path.join(mdir, part), f"{len(names)} files (budget {MEMORY_BUDGETS[part]})"))
        for x in names:
            rel = os.path.join(mdir, part, x)
            text = read(os.path.join(d, x))
            for problem in memory_file_problems(part, x, text):
                out.append((rel, problem))
            out += [(f"{rel}:{i}", reason) for i, reason in scan_lines(text)]
            desc = description_of(x)
            if desc in descs:
                out.append((rel, f"the description {desc!r} is also {descs[desc]}: one memory per description"))
            else:
                descs[desc] = rel
    committed = memory_files(root, mdir, "committed")
    listed = [f for _, f, _ in entries]
    for i, f, _ in entries:
        if f not in committed:
            out.append((f"{mdir}/INDEX.md:{i}", f"lists committed/{f}, which does not exist"))
    for f in sorted(set(listed)):
        if listed.count(f) > 1:
            out.append((f"{mdir}/INDEX.md", f"committed/{f} is listed more than once"))
    for f in committed:
        if f not in listed:
            out.append((os.path.join(mdir, "committed", f), "not listed in INDEX.md: every committed memory has one line"))
    rp = os.path.join(path, "rejected.md")
    if mdir == "memory" and os.path.isfile(rp):
        text = read(rp)
        for i, problem in rejected_problems(text) + scan_lines(text):
            out.append((f"{mdir}/rejected.md" + (f":{i}" if i else ""), problem))
    return out


def check_memory(root, mdir, rep):
    for rel, problem in memory_problems(root, mdir):
        rep.err(rel, problem)


# ---------------------------------------------------------------- seeds
def load_seed(root, name, shared, rep):
    reld = os.path.join("seeds", name)
    seed_md = os.path.join(reld, "SEED.md")
    if not NAME_RE.match(name) or len(name) > 64:
        rep.err(reld, "seed names are lowercase letters, digits and single hyphens")
    if not require(root, seed_md, rep):
        return None
    d, body = frontmatter(os.path.join(root, seed_md), rep, seed_md)
    if d is None:
        return None
    extra = set(d) - SEED_KEYS
    if extra:
        rep.err(seed_md, f"unknown keys: {', '.join(sorted(extra))} (allowed: {', '.join(sorted(SEED_KEYS))})")
    if d.get("name") != name:
        rep.err(seed_md, f"name {d.get('name')!r} must equal the folder name {name!r}")
    when = d.get("when")
    if not isinstance(when, str) or not when.strip():
        rep.err(seed_md, "when is missing")
        when = ""
    elif len(when) > 200 or "\n" in when:
        rep.err(seed_md, "when is one line of at most 200 characters")
    if "group" in d and (not isinstance(d["group"], str) or not NAME_RE.match(d["group"])):
        rep.err(seed_md, "group is a lowercase-hyphen name")
    skills = d.get("skills") or {}
    req, opt = [], []
    if not isinstance(skills, dict) or set(skills) - {"required", "optional"}:
        rep.err(seed_md, "skills has only required and optional lists")
    else:
        for key, out in (("required", req), ("optional", opt)):
            v = skills.get(key) or []
            if not isinstance(v, list) or not all(isinstance(x, str) for x in v):
                rep.err(seed_md, f"skills.{key} is a list of names")
            else:
                out.extend(v)
    bundled = set(subdirs(os.path.join(root, reld, "skills")))
    for s in bundled:
        check_skill_dir(root, os.path.join(reld, "skills", s), rep)
        if s in shared:
            rep.err(os.path.join(reld, "skills", s), f"the bundled skill {s} shadows the shared skill of that name")
    for s in req + opt:
        if s.startswith("installed:"):
            if not NAME_RE.match(s[10:]):
                rep.err(seed_md, f"{s}: installed skill names are lowercase-hyphen names")
            rep.installed.add(s[10:])
        elif s in MANDATORY:
            rep.err(seed_md, f"{s} is mandatory and implicit: don't list it")
        elif s in RETIRED_SKILLS and s not in shared and s not in bundled:
            rep.err(seed_md, f"{s} is {RETIRED_SKILLS[s]}: don't list it")
        elif s not in shared and s not in bundled:
            rep.err(seed_md, f"skill {s} resolves to none of backyard/skills/{s}/SKILL.md, skills/{s}/SKILL.md, "
                    f"{reld}/skills/{s}/SKILL.md")
    names = req + opt
    if len(set(names)) != len(names):
        rep.err(seed_md, "a skill is listed twice")
    calls = d.get("calls") or []
    if not isinstance(calls, list) or not all(isinstance(x, str) for x in calls):
        rep.err(seed_md, "calls is a list of seed names")
        calls = []
    if calls and "backyard-handoff" not in names:
        rep.err(seed_md, "calls needs backyard-handoff in skills")
    if name in calls:
        rep.err(seed_md, "a seed can't call itself")
    access = d.get("access", "full")
    if access not in ACCESS:
        rep.err(seed_md, f"access {access!r}: one of read-only, edit, full")
    has_esc = "backyard-escalate" in names
    autonomy = d.get("autonomy")
    if has_esc and autonomy is not None:
        rep.err(seed_md, "autonomy is only set when backyard-escalate is not in skills")
    if not has_esc and autonomy not in AUTONOMY:
        rep.err(seed_md, "without backyard-escalate, autonomy is decide-and-record or stop-and-record")
    if words(body) > 500:
        rep.err(seed_md, f"body is {words(body)} words (budget 500)")
    wf = os.path.join(reld, "workflow.md")
    if os.path.isfile(os.path.join(root, wf)):
        if "workflow.md" not in body:
            rep.err(seed_md, "workflow.md exists but SEED.md does not link it")
        wtext = read(os.path.join(root, wf))
        if words(wtext) > 800:
            rep.err(wf, f"{words(wtext)} words (budget 800)")
        for target in sorted(set(re.findall(r"`seed:([a-z0-9-]+)`", wtext))):
            if target not in calls:
                rep.err(wf, f"seed:{target} is not in SEED.md's calls")
    check_docs(root, os.path.join(reld, "docs"), rep)
    check_memory(root, os.path.join(reld, "memory"), rep)
    return {"name": name, "when": when, "group": d.get("group"), "calls": calls, "seed_md": seed_md}


def check_seed_index(root, seeds, rep):
    rel = os.path.join("seeds", "INDEX.md")
    if not require(root, rel, rep):
        return
    lines = read(os.path.join(root, rel)).splitlines()
    if not lines or lines[0] != "# Seeds":
        rep.err(rel, 'the first line must be "# Seeds"')
    listed, group, after_heading = {}, None, False
    for i, line in enumerate(lines[1:], 2):
        where = f"{rel}:{i}"
        if not line.strip():
            continue
        if line.startswith("## "):
            group, after_heading = line[3:].strip(), True
            continue
        m = SEED_LINE.match(line)
        if m:
            after_heading = False
            if len(line) > 220:
                rep.err(where, f"{len(line)} characters (budget 220)")
            if m.group(1) in listed:
                rep.err(where, f"{m.group(1)} is listed twice")
            listed[m.group(1)] = (m.group(2), group, where)
        elif after_heading:
            after_heading = False  # the group's one plain line
        else:
            rep.err(where, "not an index line: - <name>: <when>")
    by_name = {s["name"]: s for s in seeds}
    for n, (when, g, where) in listed.items():
        s = by_name.get(n)
        if not s:
            rep.err(where, f"lists {n}, but seeds/{n}/SEED.md does not exist")
            continue
        if when != s["when"]:
            rep.err(where, f"when differs from {s['seed_md']}")
        if s["group"] != g and (s["group"] or g):
            rep.err(where, f"{n} is under group {g!r}, but its SEED.md says {s['group']!r}")
    for n in by_name:
        if n not in listed:
            rep.err(rel, f"seed {n} is not listed")
    if len(seeds) > 20:
        for s in seeds:
            if not s["group"]:
                rep.err(s["seed_md"], "more than 20 seeds: every seed needs a group")
    if len(seeds) > 50:
        rep.warn(rel, f"{len(seeds)} seeds: the retro's sprawl check should propose merging or retiring some")


# ---------------------------------------------------------------- links
def check_links(root, files, rep):
    real_root = os.path.realpath(root)
    for rel in files:
        if not rel.endswith(".md"):
            continue
        text = strip_code(read(os.path.join(root, rel)))
        for target in LINK.findall(text):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                continue
            t = target.split("#", 1)[0]
            if not t:
                continue
            if os.path.isabs(t):
                rep.err(rel, f"link {target}: absolute paths are not allowed")
                continue
            p = os.path.realpath(os.path.join(root, os.path.dirname(rel), t))
            if not (p == real_root or p.startswith(real_root + os.sep)):
                rep.err(rel, f"link {target} leaves the backyard")
            elif not os.path.exists(p):
                rep.err(rel, f"link {target} does not resolve")


# ---------------------------------------------------------------- main
def validate(root):
    rep = Report()
    files = walk(root, rep)
    check_router(root, rep)
    check_separation(root, files, rep)
    shared = set()
    for s in subdirs(os.path.join(root, FRAMEWORK, "skills")):
        if s in FRAMEWORK_SKILLS and check_skill_dir(root, os.path.join(FRAMEWORK, "skills", s), rep):
            shared.add(s)
    for s in MANDATORY:
        if s not in shared:
            rep.err(f"backyard/skills/{s}", "a mandatory shared skill is missing")
    for s in subdirs(os.path.join(root, "skills")):  # the owner's own shared skills
        if check_skill_dir(root, os.path.join("skills", s), rep) and not s.startswith(PREFIX):
            shared.add(s)
    any_disable(root, files, rep)
    check_docs(root, "docs", rep)
    check_memory(root, "memory", rep)
    seeds = []
    for name in subdirs(os.path.join(root, "seeds")):
        s = load_seed(root, name, shared, rep)
        if s:
            seeds.append(s)
    known = {s["name"] for s in seeds}
    for s in seeds:
        for c in s["calls"]:
            if c not in known:
                rep.err(s["seed_md"], f"calls {c}, which is not a seed")
    check_seed_index(root, seeds, rep)
    check_links(root, files, rep)
    return rep


def main(argv):
    if len(argv) != 2 or argv[1].startswith("-"):
        print(__doc__.strip())
        return 2
    root = argv[1]
    if not os.path.isdir(root):
        print(f"not a folder: {root}")
        return 2
    rep = validate(root)
    for line in rep.errors + rep.warns:
        print(line)
    for s in sorted(rep.installed):
        print(f"needs installed: {s}")
    n = len(rep.errors)
    print(f"validate: {'ok' if not n else f'{n} error(s)'}"
          f"{f', {len(rep.warns)} warning(s)' if rep.warns else ''}")
    return 1 if n else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
