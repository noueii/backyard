#!/usr/bin/env python3
"""Structural checks for a garden (spec/SPEC.md, seeds format 1.0). Deterministic; no AI.

Usage: python3 check/validate.py <garden root>
Prints one line per problem (ERROR or WARN), "needs installed: <skill>" for each installed: skill, and exits 1 on
any ERROR. Needs python3 and PyYAML.
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    sys.exit("validate.py needs PyYAML: pip install pyyaml")

FORMAT_MAJOR = 1
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SKILL_KEYS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
SEED_KEYS = {"name", "when", "group", "skills", "calls", "access", "autonomy"}
ACCESS = {"read-only", "edit", "full"}
AUTONOMY = {"decide-and-record", "stop-and-record"}
MANDATORY = ("memory", "rsi")
OUTCOMES = {"done", "escalated", "stopped", "decided", "passed", "failed"}
MEMORY_INTRO = "One line per fact, most valuable first: tools may load only the start. Longer notes go in memory/<topic>.md."
LESSONS_INTRO = "Not memory yet: a lesson moves to MEMORY.md once 2 runs saw it, or the owner states it."
REJECTED_INTRO = "rsi proposals the owner declined. rsi reads this before proposing again."
LESSON_SEEN = re.compile(r" · seen: [a-z0-9-]+(, [a-z0-9-]+)*$")
REJECTED_LINE = re.compile(r"^- \d{4}-\d{2}-\d{2} \| [^|]+ \| [^|]+$")
MEMORY_LINE = re.compile(r"^- \d{4}-\d{2}-\d{2} \S.*$")
DOC_LINE = re.compile(r"^- \[([^\]/]+\.md)\]\(([^)]+)\): read when .+\.$")
SEED_LINE = re.compile(r"^- ([a-z0-9-]+): (.+)$")
RUN_HEAD = re.compile(r"^- \d{4}-\d{2}-\d{2} \d{2}:\d{2}$")
TAGS = re.compile(r"^(-|[a-z]+=\S+( [a-z]+=\S+)*)$")
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
    except yaml.YAMLError as e:
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
                rep.err(os.path.join(reld, x), "a .git folder below the root (no clone, worktree or copy inside a garden)")
                dirs.remove(x)
            elif x.lower() == "skill.md":
                rep.err(os.path.join(reld, x), "a folder named SKILL.md")
        for n in names:
            rel = os.path.normpath(os.path.join(reld, n))
            if rel == ".git":
                continue
            if n == ".git" and reld != ".":
                rep.err(rel, "a .git file below the root (a worktree or submodule inside the garden)")
            if n.lower() == "skill.md" and rel != "SKILL.md":
                rep.err(rel, "SKILL.md is only allowed at the root, in any casing: use ENTRY.md")
            files.append(rel)
    return files


def require(root, rel, rep):
    if not os.path.isfile(os.path.join(root, rel)):
        rep.err(rel, "required file is missing")
        return False
    return True


def subdirs(path):
    return sorted(x for x in os.listdir(path) if os.path.isdir(os.path.join(path, x))) if os.path.isdir(path) else []


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
    if d.get("name") != "garden":
        rep.err("SKILL.md", f"name must be garden, not {d.get('name')!r}")
    check_description("SKILL.md", d, rep)
    meta = d.get("metadata") if isinstance(d.get("metadata"), dict) else {}
    fmt = str(meta.get("seeds-format", ""))
    if not re.match(r"^\d+\.\d+$", fmt):
        rep.err("SKILL.md", "metadata.seeds-format is missing (\"1.0\")")
    elif int(fmt.split(".")[0]) != FORMAT_MAJOR:
        rep.err("SKILL.md", f"seeds-format {fmt}: this validator knows major {FORMAT_MAJOR}")
    if words(body) > 600:
        rep.err("SKILL.md", f"body is {words(body)} words (budget 600)")


def check_skill_dir(root, reld, rep):
    """A skills/<s>/ folder: ENTRY.md, frontmatter, budgets. Returns True if it is a usable skill."""
    name = os.path.basename(reld)
    entry = os.path.join(reld, "ENTRY.md")
    if not NAME_RE.match(name) or len(name) > 64:
        rep.err(reld, "skill folder names are lowercase letters, digits and single hyphens")
    if not require(root, entry, rep):
        return False
    d, body = frontmatter(os.path.join(root, entry), rep, entry)
    if d is None:
        return True
    if d.get("name") != name:
        rep.err(entry, f"name {d.get('name')!r} must equal the folder name {name!r}")
    meta = d.get("metadata") if isinstance(d.get("metadata"), dict) else {}
    vendored = "source" in meta
    if vendored and "commit" not in meta:
        rep.err(entry, "a vendored skill (metadata.source) needs metadata.commit")
    check_description(entry, d, rep, need_use_when=not vendored)
    if words(body) > 800:
        rep.err(entry, f"body is {words(body)} words (budget 800)")
    for d2, _, names in os.walk(os.path.join(root, reld)):
        for n in names:
            p = os.path.join(d2, n)
            rel = os.path.relpath(p, root)
            if n == "ENTRY.md" or os.path.splitext(n)[1] not in TEXT_EXT:
                continue
            with open(p, encoding="utf-8", errors="replace") as f:
                lines = sum(1 for _ in f)
            if lines > 300:
                rep.err(rel, f"{lines} lines (a supporting file's budget is 300)")
    return True


def any_disable(root, files, rep):
    for rel in files:
        if os.path.basename(rel) in ("SKILL.md", "ENTRY.md", "SEED.md"):
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
# One table for the validator and skills/memory/write.py. kind: (header, intro or None, max lines, max line length).
# Compaction is due at 80 % of a budget; at 100 % write.py refuses the write and the validator fails the file.
MEMORY_FILES = {
    "memory": ("# Memory", MEMORY_INTRO, 60, 400),
    "lessons": ("# Lessons", LESSONS_INTRO, 100, 400),
    "runs": ("# Runs", None, 200, 400),
    "unrouted": ("# Unrouted", None, 200, 400),
    "rejected": ("# Rejected", REJECTED_INTRO, 100, 400),
    "archive": ("# Archive", None, 300, 400),
    "topic": (None, None, 300, None),
}
COMPACT_AT = 0.8
SPECIAL = {"runs.md": "runs", "unrouted.md": "unrouted", "archive.md": "archive", "lessons.md": "lessons",
           "rejected.md": "rejected"}


def memory_kind(rel):
    """The kind of a memory file from its path relative to the root, or None if it is not a memory file."""
    parts = rel.replace(os.sep, "/").split("/")
    if parts[:1] == ["seeds"] and len(parts) >= 3:
        parts = parts[2:]
    elif parts[:1] == ["seeds"]:
        return None
    if parts == ["MEMORY.md"]:
        return "memory"
    if len(parts) == 2 and parts[0] == "memory" and parts[1].endswith(".md"):
        if parts[1] == "rejected.md" and rel.startswith("seeds"):
            return None
        return SPECIAL.get(parts[1], "topic")
    return None


def line_problem(kind, line):
    """What is wrong with one list line of a memory file of this kind, or None."""
    if kind in ("memory", "lessons"):
        if not MEMORY_LINE.match(line):
            return "not a memory line: - YYYY-MM-DD <fact> [· from: <seed>]"
        if kind == "lessons" and not LESSON_SEEN.search(line):
            return "a lesson ends with · seen: <run>[, <run>]"
    elif kind == "rejected":
        if not REJECTED_LINE.match(line):
            return "not a rejected line: - YYYY-MM-DD | <proposal> | <reason>"
    elif kind in ("runs", "unrouted"):
        parts = line.split(" | ")
        if len(parts) == 4 and line.endswith(" |"):
            parts[3] = parts[3][:-2]
            parts.append("")
        if len(parts) != 5:
            return "not a run line: - <date> <time> | <task> | <outcome> | <tags> | <note>"
        head, task, outcome, tags, note = parts
        if not RUN_HEAD.match(head):
            return "starts with - YYYY-MM-DD HH:MM"
        if not NAME_RE.match(task):
            return f"task slug {task!r}: lowercase letters, digits and hyphens"
        if kind == "unrouted":
            if outcome != "one-off":
                return "an unrouted line's outcome is one-off"
        elif task == "retro":
            if not re.match(r"^\d+ runs?$", outcome):
                return "a retro line's third field is <n> runs"
        elif outcome not in OUTCOMES:
            return f"outcome {outcome!r}: one of {', '.join(sorted(OUTCOMES))}"
        if not TAGS.match(tags):
            return "tags are key=value pairs separated by spaces, or -"
        if len(note) > 140:
            return f"the note is {len(note)} characters (budget 140)"
    return None


def file_problems(kind, text):
    """[(line number or None, problem)] for a whole memory file of this kind."""
    header, intro, max_lines, max_len = MEMORY_FILES[kind]
    lines = text.splitlines()
    out = []
    if header and (not lines or lines[0] != header):
        out.append((1, f'the first line must be "{header}"'))
    if len(lines) > max_lines:
        out.append((None, f"{len(lines)} lines (budget {max_lines})"))
    if not header:
        return out
    for i, line in enumerate(lines[1:], 2):
        if not line.strip() or line == intro:
            continue
        if max_len and len(line) > max_len:
            out.append((i, f"{len(line)} characters (budget {max_len})"))
        if kind != "archive":
            p = line_problem(kind, line)
            if p:
                out.append((i, p))
    return out


def check_memory_file(root, rel, kind, rep):
    for i, problem in file_problems(kind, read(os.path.join(root, rel))):
        rep.err(f"{rel}:{i}" if i else rel, problem)


def check_memory(root, reld, rep, runs=False, unrouted=False):
    """reld is "" for the root or seeds/<name>."""
    mem = os.path.join(reld, "MEMORY.md")
    mdir = os.path.join(reld, "memory")
    if not require(root, mem, rep):
        return
    check_memory_file(root, mem, "memory", rep)
    present = set(x for x in os.listdir(os.path.join(root, mdir)) if x.endswith(".md")) \
        if os.path.isdir(os.path.join(root, mdir)) else set()
    if os.path.isdir(os.path.join(root, mdir)):
        for x in subdirs(os.path.join(root, mdir)):
            rep.err(os.path.join(mdir, x), "memory folders are flat: no subfolders")
    linking = read(os.path.join(root, mem))
    if "lessons.md" in present:
        linking += read(os.path.join(root, mdir, "lessons.md"))
    named = set(re.findall(r"memory/([A-Za-z0-9._-]+\.md)", linking))
    for x in sorted(named - present - set(SPECIAL)):
        rep.err(mem, f"names memory/{x}, which does not exist")
    for x in sorted(present):
        rel = os.path.join(mdir, x)
        kind = memory_kind(rel)
        if kind is None:
            rep.err(rel, "rejected.md lives in the root memory/ only")
            continue
        if kind == "topic" and x not in named:
            rep.err(rel, "a topic file not linked from MEMORY.md or memory/lessons.md")
        check_memory_file(root, rel, kind, rep)
    if runs:
        require(root, os.path.join(mdir, "runs.md"), rep)


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
        elif s not in shared and s not in bundled:
            rep.err(seed_md, f"skill {s} resolves to neither skills/{s}/ENTRY.md nor {reld}/skills/{s}/ENTRY.md")
    names = req + opt
    if len(set(names)) != len(names):
        rep.err(seed_md, "a skill is listed twice")
    calls = d.get("calls") or []
    if not isinstance(calls, list) or not all(isinstance(x, str) for x in calls):
        rep.err(seed_md, "calls is a list of seed names")
        calls = []
    if calls and "handoff" not in names:
        rep.err(seed_md, "calls needs handoff in skills")
    if name in calls:
        rep.err(seed_md, "a seed can't call itself")
    access = d.get("access", "full")
    if access not in ACCESS:
        rep.err(seed_md, f"access {access!r}: one of read-only, edit, full")
    has_esc = "escalate" in names
    autonomy = d.get("autonomy")
    if has_esc and autonomy is not None:
        rep.err(seed_md, "autonomy is only set when escalate is not in skills")
    if not has_esc and autonomy not in AUTONOMY:
        rep.err(seed_md, "without escalate, autonomy is decide-and-record or stop-and-record")
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
    check_memory(root, reld, rep, runs=True)
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
        rep.warn(rel, f"{len(seeds)} seeds: rsi's sprawl check should propose merging or retiring some")


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
                rep.err(rel, f"link {target} leaves the garden")
            elif not os.path.exists(p):
                rep.err(rel, f"link {target} does not resolve")


# ---------------------------------------------------------------- main
def validate(root):
    rep = Report()
    files = walk(root, rep)
    check_router(root, rep)
    shared = set()
    for s in subdirs(os.path.join(root, "skills")):
        if check_skill_dir(root, os.path.join("skills", s), rep):
            shared.add(s)
    for s in MANDATORY:
        if s not in shared:
            rep.err(f"skills/{s}", "a mandatory shared skill is missing")
    any_disable(root, files, rep)
    check_docs(root, "docs", rep)
    check_memory(root, "", rep)
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
