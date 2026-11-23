# expect: 51 files (budget 50)
# committed/ past its budget (and INDEX.md with it).
. "$FIXTURES/good-seeds.sh"
for i in $(seq 1 50); do
  mem memory/committed/2026-11-23-owner-fact-number-$i.md fact "owner: \"fact $i\"" - "Fact $i."
  idx memory 2026-11-23-owner-fact-number-$i.md "fact $i matters"
done
