#!/usr/bin/env python3
"""Every memory write goes through this script: it scans the text, keeps the promotion gate, keeps INDEX.md equal to
committed/, and fails loudly at a full budget (no truncation). The layout and budgets are garden/check/validate.py's
(garden/docs/SPEC.md §6-7). A memory folder is memory/ (shared) or seeds/<name>/memory/ (one seed's).

Usage (paths relative to the garden root, or absolute inside it; a body is read from stdin):
  write.py new <memory folder> <description> --type <t> --source "<where from>" [--date YYYY-MM-DD]
               (--owner --when "<condition>" [--top] | --seen <task>)
      Writes <date>-<description>.md (description: short kebab-case words, grepable), type fact | decision |
      preference | lesson. --owner: the owner stated it; source starts with owner: "<their words>"; it goes
      straight to committed/ with an INDEX.md line "read when <condition>". --seen <task>: anything else; it goes
      to pending/, seen by that task.
  write.py seen <pending file> <task>        another task saw a pending memory; at 2 tasks a retro is due
  write.py promote <pending file> --when "<condition>" [--top]   seen by 2 tasks: move it to committed/ and index it
  write.py remove <committed or pending file>   delete it (and its INDEX.md line); git history keeps it
  write.py reject "- YYYY-MM-DD | <proposal> | <reason>"   record a declined proposal in memory/rejected.md
  write.py scan | check <memory folder>     scan stdin only | check a folder (after hand edits) and its budgets
Exit: 0 written (maybe with "compaction due" or "retro due"), 1 refused (say why in your report; never write
around it), 2 usage.
"""
import datetime
import os
import re
import sys

ROOT = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "garden", "check"))
sys.dont_write_bytecode = True  # no __pycache__ in the live clone
try:
    import validate as V  # noqa: E402  (the one table of formats and budgets)
except ImportError as e:  # PyYAML missing: validate.py says so
    sys.exit(f"write.py needs garden/check/validate.py and PyYAML: {e}")

B = V.MEMORY_BUDGETS


def fail(msg):
    print(f"write.py: REFUSED: {msg}")
    sys.exit(1)


def usage():
    sys.exit(print(__doc__.strip()) or 2)

def must_be_clean(*texts):
    reason = next((r for r in map(V.scan, texts) if r), None)
    if reason:
        fail(reason)


def inside(path):
    p = os.path.realpath(path if os.path.isabs(path) else os.path.join(ROOT, path))
    if not p.startswith(ROOT + os.sep):
        fail(f"{path} is outside the garden ({ROOT})")
    return p, os.path.relpath(p, ROOT).replace(os.sep, "/")


def memory_dir(path):
    p, rel = inside(path)
    rel = rel.rstrip("/")
    if rel != "memory" and not re.match(r"^seeds/[a-z0-9]+(-[a-z0-9]+)*/memory$", rel):
        fail(f"{rel} is not a memory folder (memory or seeds/<name>/memory)")
    if rel != "memory" and not os.path.isdir(os.path.dirname(p)):
        fail(f"{os.path.dirname(rel)} is not a seed")
    return rel


def memory_file(path, parts):
    _, rel = inside(path)
    place = V.memory_place(rel)
    if not place or place[1] not in parts:
        fail(f"{rel} is not a file in {' or '.join(p + '/' for p in parts)} of a memory folder")
    if not os.path.isfile(os.path.join(ROOT, rel)):
        fail(f"{rel} does not exist")
    return place


def flag(args, name, needed=False):
    if name in args:
        i = args.index(name)
        if i + 1 >= len(args) or args[i + 1].startswith("--"):
            fail(f"{name} needs a value")
        return args[i + 1]
    if needed:
        fail(f"{name} is required")
    return None


def read_text(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def save(p, text):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(text if text.endswith("\n") else text + "\n")


def index_lines(mdir):
    p = os.path.join(ROOT, mdir, "INDEX.md")
    return read_text(p).splitlines() if os.path.exists(p) else [V.INDEX_HEADER, "", V.INDEX_INTRO]


def index_line(name, when):
    when = when.strip().rstrip(".")
    if when.lower().startswith("read when "):
        when = when[10:]
    if not when:
        fail("--when is the condition for opening it: read when <condition>")
    return f"- [{name}](committed/{name}): read when {when}."


def add_to_index(mdir, name, when, top):
    line = index_line(name, when)
    if len(line) > B["index_line"]:
        fail(f"the INDEX.md line is {len(line)} characters (budget {B['index_line']}): shorten --when")
    lines = index_lines(mdir)
    entries = [i for i, l in enumerate(lines) if l.startswith("- ")]
    if len(entries) + 1 > B["index"]:
        full(f"{mdir}/INDEX.md would have {len(entries) + 1} entries (budget {B['index']})")
    lines.insert(entries[0] if top and entries else len(lines), line)
    save(os.path.join(ROOT, mdir, "INDEX.md"), "\n".join(lines))


def full(what):
    fail(f"BUDGET FULL: {what}. Nothing was written. Compact or remove first "
         "(garden/skills/garden-memory/retro.md, Compaction), then write again.")


def count(mdir, part):
    return len(V.memory_files(ROOT, mdir, part))


def room(mdir, part):
    if count(mdir, part) + 1 > B[part]:
        full(f"{mdir}/{part}/ would have {count(mdir, part) + 1} files (budget {B[part]})")


def parsed(p, name):
    fm, body, problem = V.parse_memory(read_text(p))
    if problem:
        fail(f"{name}: {problem}")
    return fm, body


def notes(mdir):
    """The 80 % notes: compaction is due, and so is a retro."""
    for k, (used, budget) in V.memory_usage(ROOT, mdir).items():
        if used >= V.COMPACT_AT * budget:
            print(f"write.py: compaction due (a retro is due): {mdir} {k} at {used}/{budget} "
                  f"({100 * used // budget} %)")


def render(fm, body):
    import yaml
    head = "\n".join(f"{k}: " + yaml.safe_dump(v, default_flow_style=True, allow_unicode=True, width=1000)
                     .removesuffix("\n...\n").strip() for k, v in fm.items())
    return f"---\n{head}\n---\n{body.strip()}\n"


def check_file(part, name, text):
    if V.memory_file_problems(part, name, text):
        fail(f"{name}: " + "; ".join(V.memory_file_problems(part, name, text)))


def cmd_new(args):
    if len(args) < 2:
        usage()
    mdir, desc, rest = memory_dir(args[0]), args[1], args[2:]
    mtype, source = flag(rest, "--type", True), flag(rest, "--source", True)
    date = flag(rest, "--date") or datetime.date.today().isoformat()
    owner, top = "--owner" in rest, "--top" in rest
    when, task = flag(rest, "--when"), flag(rest, "--seen")
    if owner == bool(task):
        fail("one of --owner (the owner stated it) or --seen <task> (anything else: it goes to pending/)")
    if owner and not when:
        fail("--owner needs --when: the condition on its INDEX.md line")
    if owner and not V.OWNER_SOURCE.match(source.strip()):
        fail('with --owner, the source is the owner\'s words: owner: "<what they said>"')
    if task and not V.NAME_RE.match(task):
        fail(f"--seen {task!r}: a task slug (lowercase letters, digits, hyphens)")
    body = sys.stdin.read()
    must_be_clean(desc, source, when or "", body)
    name = f"{date}-{desc}.md"
    if V.name_problem(name):
        fail(V.name_problem(name))
    for part in ("committed", "pending"):
        for x in V.memory_files(ROOT, mdir, part):
            if V.description_of(x) == desc:
                fail(f"{mdir}/{part}/{x} has the same description: if it is the same memory, use seen "
                     "(pending) or leave it (committed); if not, describe it differently")
    part = "committed" if owner else "pending"
    fm = {"type": mtype, "date": datetime.date.fromisoformat(date), "source": source.strip()} | (
        {"seen": [task]} if task else {})
    text = render(fm, body)
    check_file(part, name, text)
    room(mdir, part)
    if owner:
        add_to_index(mdir, name, when, top)
    save(os.path.join(ROOT, mdir, part, name), text)
    print(f"write.py: wrote {mdir}/{part}/{name}" + (" and its INDEX.md line" if owner else ""))
    notes(mdir)


def cmd_seen(args):
    if len(args) != 2 or not V.NAME_RE.match(args[1]):
        usage()
    mdir, _, name = memory_file(args[0], ("pending",))
    p = os.path.join(ROOT, mdir, "pending", name)
    fm, body = parsed(p, name)
    seen = list(fm.get("seen") or [])
    if args[1] not in seen:
        seen.append(args[1])
    fm["seen"] = seen
    save(p, render(fm, body))
    print("write.py: seen by 1 task" if len(set(seen)) < 2 else f"write.py: seen by {len(set(seen))} tasks: a retro "
          f"is due; it promotes this: promote {mdir}/pending/{name} --when \"<condition>\" (garden/skills/garden-memory/retro.md)")


def cmd_promote(args):
    if len(args) < 1:
        usage()
    mdir, _, name = memory_file(args[0], ("pending",))
    when, top = flag(args[1:], "--when", True), "--top" in args[1:]
    must_be_clean(when)
    src = os.path.join(ROOT, mdir, "pending", name)
    fm, _ = parsed(src, name)
    if len(set(fm.get("seen") or [])) < 2:
        fail(f"the promotion gate: {name} was seen by {len(set(fm.get('seen') or []))} task(s); it needs 2 "
             "(or the owner's word: then write it again with new --owner and remove this one)")
    check_file("committed", name, read_text(src))
    room(mdir, "committed")
    add_to_index(mdir, name, when, top)
    os.makedirs(os.path.join(ROOT, mdir, "committed"), exist_ok=True)
    os.replace(src, os.path.join(ROOT, mdir, "committed", name))
    print(f"write.py: promoted {mdir}/pending/{name} to committed/, with its INDEX.md line")
    notes(mdir)


def cmd_remove(args):
    if len(args) != 1:
        usage()
    mdir, part, name = memory_file(args[0], ("committed", "pending"))
    if part == "committed":
        lines = [l for l in index_lines(mdir) if f"](committed/{name})" not in l]
        save(os.path.join(ROOT, mdir, "INDEX.md"), "\n".join(lines))
    os.remove(os.path.join(ROOT, mdir, part, name))
    print(f"write.py: removed {mdir}/{part}/{name}" + (" and its INDEX.md line" if part == "committed" else "")
          + " (git history keeps it)")


def cmd_reject(args):
    if len(args) != 1:
        usage()
    line = args[0]
    if "\n" in line or not V.REJECTED_LINE.match(line):
        fail("a rejected line is - YYYY-MM-DD | <proposal> | <reason, or: no reason given>")
    if len(line) > B["rejected_line"]:
        fail(f"{len(line)} characters (budget {B['rejected_line']})")
    must_be_clean(re.sub(r"^- \d{4}-\d{2}-\d{2} \| ", "", line))
    p = os.path.join(ROOT, "memory", "rejected.md")
    lines = read_text(p).splitlines() if os.path.exists(p) else [V.REJECTED_HEADER, "", V.REJECTED_INTRO]
    lines.append(line)
    if len(lines) > B["rejected"]:
        full(f"memory/rejected.md would have {len(lines)} lines (budget {B['rejected']})")
    save(p, "\n".join(lines))
    print("write.py: added to memory/rejected.md")
    notes("memory")


def cmd_check(args):
    if len(args) != 1:
        usage()
    mdir = memory_dir(args[0])
    problems = V.memory_problems(ROOT, mdir)
    print("\n".join(f"{rel}: {problem}" for rel, problem in problems))
    if problems:
        sys.exit(1)
    for k, (used, budget) in V.memory_usage(ROOT, mdir).items():
        print(f"write.py: {mdir} {k}: {used}/{budget}")
    notes(mdir)
    print(f"write.py: {mdir} ok")


def main(argv):
    if len(argv) < 2:
        usage()
    cmd, args = argv[1], argv[2:]
    if cmd == "scan":
        must_be_clean(sys.stdin.read())
        print("write.py: clean")
    elif cmd in ("new", "seen", "promote", "remove", "reject", "check"):
        globals()[f"cmd_{cmd}"](args)
    else:
        usage()


if __name__ == "__main__":
    main(sys.argv)
