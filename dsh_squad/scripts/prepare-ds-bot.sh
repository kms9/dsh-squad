#!/bin/sh
# Builds the patched ds-bot the squad's tests and the experiment runner load: the copy of
# dsh-bot/ds-bot that dsh-bot/UPSTREAM pins (dsh-bot/ds-bot itself stays untouched), plus
# dsh_squad/patches/ds-bot/*.patch.
#
#   dsh_squad/scripts/prepare-ds-bot.sh [--test]
#
# Output: dsh_squad/.build/ds-bot (gitignored), a git repo whose first commit is the upstream
# copy, so `git diff` there shows exactly what the patches change. --test runs ds-bot's unit
# tests on the result against dev/harness of dsh-bot/ds-bot.
set -eu
SQUAD="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(dirname "$SQUAD")"
SRC="$REPO/dsh-bot/ds-bot"
OUT="$SQUAD/.build/ds-bot"
UPSTREAM="$(awk 'NR == 1 { print $2 }' "$REPO/dsh-bot/UPSTREAM")"

# --stamp prints what a build from the current copy and patches would be made of.
if [ "${1:-}" = --stamp ]; then
  printf '%s %s\n' "$UPSTREAM" "$(cat "$SQUAD"/patches/ds-bot/*.patch | sha256sum | cut -d' ' -f1)"
  exit 0
fi
rm -rf "$OUT"
mkdir -p "$OUT"
# The installs (node_modules) are not copied: they stay where they are and are linked below.
(cd "$SRC" && tar --exclude=./node_modules --exclude=./dev/harness/node_modules -cf - .) | tar -x -C "$OUT"
cd "$OUT"
git init -q
git add -A
git -c user.name=prepare -c user.email=prepare@localhost commit -qm "ds-bot at $UPSTREAM"
for patch in "$SQUAD"/patches/ds-bot/*.patch; do
  git apply --whitespace=nowarn "$patch"
  echo "applied $(basename "$patch")"
done
# Build tools and the test harness come from dsh-bot/ds-bot's own installs.
[ -d "$SRC/node_modules" ] && ln -sfn "$SRC/node_modules" node_modules
printf 'node_modules\n' >> .git/info/exclude
git diff --stat
# What this build is made of, so a later run knows when the copy or a patch moved.
printf '.squad-build\n' >> .git/info/exclude
"$SQUAD/scripts/prepare-ds-bot.sh" --stamp > .squad-build
if [ "${1:-}" = --test ]; then
  DSH_HARNESS="$SRC/dev/harness" node --import ./test/harness-resolve.mjs --test "test/*.test.js"
fi
