# expect: 31 files (budget 30)
. "$FIXTURES/good-seeds.sh"
for i in $(seq 1 30); do mem memory/pending/2026-11-23-pending-lesson-number-$i.md lesson "task-$i" "task-$i" "Lesson $i."; done
