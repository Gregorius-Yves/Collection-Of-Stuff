#!/bin/bash
# Verify every instruction in the code segment fits the 4-byte-slot contract.
# Usage: ./check.sh yukari.asm
set -e
asm="$1"; bin=/tmp/_chk.bin; lst=/tmp/_chk.lst
nasm -f bin "$asm" -o "$bin" -l "$lst"

# find header_size (start of shuffled core) and payload (end of shuffled core).
# only the shuffled core must obey the 4-byte-slot contract; the tail is normal code.
read hs end < <(python3 -c "
import re
L=open('$lst').read().splitlines()
def off(name):
    for i,l in enumerate(L):
        if re.search(r'\b'+name+r':',l):
            for l2 in L[i:]:
                m=re.match(r'\s*\d+\s+([0-9A-F]{8})\s',l2)
                if m: return int(m.group(1),16)
    return None
hs=off('header_size'); pl=off('payload')
import os
end = pl if pl is not None else os.path.getsize('$bin')
print(hs, end)
")
code=$((end - hs))
echo "header_size=0x$(printf %x $hs)  code_size=$code  bound_should_be=$((code/4))"
[ $((code % 16)) -ne 0 ] && echo "!! code_size not a multiple of 16" && exit 1

# disassemble the code region and record every instruction start + length
objdump -D -b binary -m i386:x86-64 -M intel "$bin" \
  --start-address=$hs --stop-address=$end 2>/dev/null \
| awk '/^\s+[0-9a-f]+:/{
    a=strtonum("0x" substr($1,1,length($1)-1)); n=0;
    for(i=2;i<=NF;i++){ if($i ~ /^[0-9a-f][0-9a-f]$/) n++; else break }
    print a, n
  }' > /tmp/_ins.txt

python3 - "$hs" "$end" <<'EOF'
import sys
hs,end=int(sys.argv[1]),int(sys.argv[2])
starts={}; bad=[]
for line in open('/tmp/_ins.txt'):
    a,n=map(int,line.split()); starts[a-hs]=n
    if n>4: bad.append((a-hs,n))
# every multiple of 4 in [0,code) must be an instruction start
code=end-hs
missing=[o for o in range(0,code,4) if o not in starts]
ok=True
if bad:
    ok=False
    print("!! instructions longer than 4 bytes (they straddle slots):")
    for o,n in bad: print(f"     code+{o} ({n} bytes)")
if missing:
    ok=False
    print("!! these 4-byte slot boundaries are NOT instruction starts (something straddles them):")
    for o in missing: print(f"     code+{o}")
print("OK: every 4-byte slot is a clean instruction boundary" if ok else "FAILED")
EOF