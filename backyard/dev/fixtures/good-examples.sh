# expect: ok
# new-seed's examples, installed as seeds (with stand-in planner and coder seeds), are a valid backyard.
set -e
lines=""
for n in task-manager reviewer planner coder; do
  mkdir -p "seeds/$n/docs" "seeds/$n/memory"
  if [ -d "backyard/skills/backyard-new-seed/examples/$n" ]; then cp backyard/skills/backyard-new-seed/examples/$n/* "seeds/$n/"
  else printf -- '---\nname: %s\nwhen: "Stand-in %s for the fixture."\nautonomy: stop-and-record\n---\nStand-in.\n' $n $n > "seeds/$n/SEED.md"; fi
  printf '# Docs\n' > "seeds/$n/docs/INDEX.md"; printf '# Memory\n' > "seeds/$n/memory/INDEX.md"
  lines="$lines- $n: $(sed -n 's/^when: "\(.*\)"$/\1/p' "seeds/$n/SEED.md")
"
done
printf '# Seeds\n\n%s' "$lines" > seeds/INDEX.md
