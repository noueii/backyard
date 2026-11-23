# expect: lists ghost, but seeds/ghost/SEED.md does not exist
. "$FIXTURES/good-seeds.sh"
printf -- '- ghost: Haunting.\n' >> seeds/INDEX.md
