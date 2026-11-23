# expect: (budget 1024)
. "$FIXTURES/good-seeds.sh"
python3 -c "import re;p='SKILL.md';s=open(p).read();open(p,'w').write(s.replace('Use when starting', 'x'*1100+' Use when starting',1))"
