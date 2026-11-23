# expect: (budget 500)
. "$FIXTURES/good-seeds.sh"
python3 -c "open('seeds/reviewer/SEED.md','a').write(' word'*501)"
