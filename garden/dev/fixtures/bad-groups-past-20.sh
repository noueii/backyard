# expect: more than 20 seeds: every seed needs a group
. "$FIXTURES/good-seeds.sh"
for i in $(seq 1 20); do n=extra-$i; mkdir -p seeds/$n/docs seeds/$n/memory; printf -- '---\nname: %s\nwhen: "Extra %s."\nautonomy: stop-and-record\n---\nx\n' $n $i > seeds/$n/SEED.md; printf '# Docs\n' > seeds/$n/docs/INDEX.md; printf '# Memory\n' > seeds/$n/MEMORY.md; printf '# Runs\n' > seeds/$n/memory/runs.md; printf -- '- %s: Extra %s.\n' $n $i >> seeds/INDEX.md; done
