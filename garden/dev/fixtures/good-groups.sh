# expect: ok
# Past 20 seeds, with groups: seeds/INDEX.md under ## headings, each with its one plain line.
. "$FIXTURES/good-seeds.sh"
sed -i 's/^access: read-only$/access: read-only\ngroup: code/' seeds/reviewer/SEED.md
sed -i 's/^calls: \[reviewer\]$/calls: [reviewer]\ngroup: code/' seeds/task-manager/SEED.md
{ printf '# Seeds\n\n## code\nSeeds that change or review code.\n'; grep '^- ' seeds/INDEX.md; printf '\n## chores\nHousekeeping seeds.\n'; } > seeds/INDEX.new
for i in $(seq 1 20); do
  n=chore-$i; mkdir -p seeds/$n/docs seeds/$n/memory
  printf -- '---\nname: %s\nwhen: "Chore %s."\ngroup: chores\nautonomy: decide-and-record\n---\nDo chore %s.\n' $n $i $i > seeds/$n/SEED.md
  printf '# Docs\n' > seeds/$n/docs/INDEX.md; printf '# Memory\n' > seeds/$n/memory/INDEX.md
  printf -- '- %s: Chore %s.\n' $n $i >> seeds/INDEX.new
done
mv seeds/INDEX.new seeds/INDEX.md
