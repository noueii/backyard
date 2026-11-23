#!/usr/bin/env python3
"""Every memory write goes through this script: it scans the text, keeps the promotion gate, and fails loudly at
a full budget (no truncation). Budgets and formats are check/validate.py's (spec/SPEC.md §6-7).

Usage (paths relative to the garden root, or absolute inside it):
  write.py add <file> "<line>" [--top]          add a list line to a memory file (MEMORY.md: see the gate below)
      MEMORY.md needs one of:
        --owner                                 the owner stated this fact directly
        --lesson <lessons file>:<line number>   a lesson seen in at least 2 runs; it moves out of the lessons file
  write.py seen <lessons file> <line number> <run slug>   record that another run saw a lesson
  write.py append <topic file>                  append the text on stdin to a topic file (memory/<topic>.md)
  write.py scan                                 scan the text on stdin only
  write.py check <file>                         check a whole memory file (after compaction by hand)
Exit: 0 written (a "compaction due" note at 80 % of a budget), 1 refused (the reason is printed: say it in your
report, and never write around it), 2 usage.
"""
import os
import re
import sys
import unicodedata

ROOT = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "check"))
try:
    import validate as V  # noqa: E402  (the one table of formats and budgets)
except ImportError as e:  # PyYAML missing: validate.py says so
    sys.exit(f"write.py needs check/validate.py and PyYAML: {e}")

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


def fail(msg):
    print(f"write.py: REFUSED: {msg}")
    sys.exit(1)


def usage():
    print(__doc__.strip())
    sys.exit(2)


def scan(text):
    """The first reason this text must not become memory, or None."""
    for ch in text:
        if ch in "\n\t":
            continue
        cat = unicodedata.category(ch)
        if cat in ("Cc", "Cf", "Co", "Cs", "Cn") or ch in "   ":
            return f"invisible or control character U+{ord(ch):04X} ({unicodedata.name(ch, cat)})"
    for pat in SECRET:
        if re.search(pat, text, re.I):
            return "it looks like a secret or token: never store one; say where it lives instead"
    for pat in INSTRUCTION:
        m = re.search(pat, text, re.I | re.M)
        if m:
            return (f"instruction-like text ({m.group(0).strip()!r}): memory holds facts, not instructions; "
                    "a rule goes to docs through rsi, and untrusted text stays out unless verified")
    return None


def resolve(path):
    p = os.path.realpath(path if os.path.isabs(path) else os.path.join(ROOT, path))
    if not p.startswith(ROOT + os.sep):
        fail(f"{path} is outside the garden ({ROOT})")
    rel = os.path.relpath(p, ROOT)
    kind = V.memory_kind(rel)
    if kind is None:
        fail(f"{rel} is not a memory file (MEMORY.md, memory/*.md, seeds/<x>/MEMORY.md, seeds/<x>/memory/*.md)")
    return p, rel, kind


def load(p, kind):
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            return f.read().splitlines()
    header, intro = V.MEMORY_FILES[kind][:2]
    return ([header, ""] + ([intro] if intro else [])) if header else []


def budget_gate(rel, kind, lines):
    """Fail at 100 %; print a note from 80 %."""
    max_lines = V.MEMORY_FILES[kind][2]
    if len(lines) > max_lines:
        fail(f"BUDGET FULL: {rel} would have {len(lines)} lines (budget {max_lines}). Nothing was written. "
             "Compact or remove lines first (skills/rsi/retro.md, Compaction), then write again.")
    if len(lines) >= V.COMPACT_AT * max_lines:
        print(f"write.py: compaction due: {rel} is at {len(lines)}/{max_lines} lines ({100 * len(lines) // max_lines} %)")


def save(p, lines):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def first_list_line(lines):
    return next((i for i, l in enumerate(lines) if l.startswith("- ")), len(lines))


def seen_runs(line):
    m = V.LESSON_SEEN.search(line)
    return [] if not m else [x.strip() for x in m.group(0).split(":", 1)[1].split(",")]


def lesson_at(spec):
    path, _, n = spec.rpartition(":")
    if not path or not n.isdigit():
        fail(f"--lesson is <lessons file>:<line number>, not {spec!r}")
    p, rel, kind = resolve(path)
    if kind != "lessons":
        fail(f"{rel} is not a lessons file")
    lines = load(p, kind)
    i = int(n) - 1
    if not (0 <= i < len(lines)) or not lines[i].startswith("- "):
        fail(f"{rel}:{n} is not a lesson line")
    return p, lines, i


def cmd_add(args):
    if len(args) < 2:
        usage()
    path, line, flags = args[0], args[1], args[2:]
    top = "--top" in flags
    owner = "--owner" in flags
    lesson = flags[flags.index("--lesson") + 1] if "--lesson" in flags and flags.index("--lesson") + 1 < len(flags) else None
    p, rel, kind = resolve(path)
    if kind == "topic":
        fail("topic files take prose: use append")
    if "\n" in line:
        fail("one line at a time")
    reason = scan(re.sub(r"^- \d{4}-\d{2}-\d{2}( \d{2}:\d{2})? (\| )?", "", line))
    if reason:
        fail(reason)
    if kind == "memory":
        if not owner and not lesson:
            fail("the promotion gate: a new lesson goes to memory/lessons.md first (with · seen: <run>), and into "
                 "MEMORY.md only once 2 runs saw it (--lesson <file>:<n>) or the owner stated it (--owner)")
        if lesson:
            lp, llines, li = lesson_at(lesson)
            runs = set(seen_runs(llines[li]))
            if len(runs) < 2 and not owner:
                fail(f"the promotion gate: {lesson} was seen in {len(runs)} run(s); it needs 2, or the owner's word")
    problem = V.line_problem(kind, line)
    if problem:
        fail(problem)
    max_len = V.MEMORY_FILES[kind][3]
    if max_len and len(line) > max_len:
        fail(f"{len(line)} characters (budget {max_len}): shorten it, and put the detail in a topic file")
    lines = load(p, kind)
    if kind in ("runs", "unrouted", "rejected", "archive", "lessons") or not top:
        lines.append(line)
    else:
        lines.insert(first_list_line(lines), line)
    budget_gate(rel, kind, lines)
    save(p, lines)
    if kind == "memory" and lesson:
        del llines[li]
        save(lp, llines)
        print(f"write.py: promoted; removed the lesson from {os.path.relpath(lp, ROOT)}")
    print(f"write.py: added to {rel}")


def cmd_seen(args):
    if len(args) != 3 or not V.NAME_RE.match(args[2]):
        usage()
    p, lines, i = lesson_at(f"{args[0]}:{args[1]}")
    runs = seen_runs(lines[i])
    if args[2] not in runs:
        runs.append(args[2])
    lines[i] = V.LESSON_SEEN.sub("", lines[i]) + " · seen: " + ", ".join(runs)
    save(p, lines)
    rel = os.path.relpath(p, ROOT)
    if len(runs) >= 2:
        print(f"write.py: seen in {len(runs)} runs: promote it with add <MEMORY.md> \"<line>\" --lesson {rel}:{args[1]}")
    else:
        print(f"write.py: seen in {len(runs)} run")


def cmd_append(args):
    if len(args) != 1:
        usage()
    p, rel, kind = resolve(args[0])
    if kind != "topic":
        fail(f"{rel} is not a topic file: use add")
    text = sys.stdin.read()
    reason = scan(text)
    if reason:
        fail(reason)
    lines = load(p, kind) + text.rstrip("\n").splitlines()
    budget_gate(rel, kind, lines)
    save(p, lines)
    print(f"write.py: appended {len(text.splitlines())} line(s) to {rel}")


def cmd_check(args):
    if len(args) != 1:
        usage()
    p, rel, kind = resolve(args[0])
    with open(p, encoding="utf-8") as f:
        text = f.read()
    reason = scan(text)
    problems = V.file_problems(kind, text)
    for i, problem in problems:
        print(f"{rel}{f':{i}' if i else ''}: {problem}")
    if reason:
        fail(f"{rel}: {reason}")
    if problems:
        sys.exit(1)
    budget_gate(rel, kind, text.splitlines())
    print(f"write.py: {rel} ok")


def main(argv):
    if len(argv) < 2:
        usage()
    cmd, args = argv[1], argv[2:]
    if cmd == "scan":
        reason = scan(sys.stdin.read())
        if reason:
            fail(reason)
        print("write.py: clean")
    elif cmd in ("add", "seen", "append", "check"):
        globals()[f"cmd_{cmd}"](args)
    else:
        usage()


if __name__ == "__main__":
    main(sys.argv)
