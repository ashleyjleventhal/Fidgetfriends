#!/usr/bin/env bash
set -euo pipefail

copy_site="$(dirname "$0")/../scripts/copy-published-site.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/dist1/assets" "$tmp/dist2/assets" "$tmp/pages"

printf 'gitdir: worktree\n' > "$tmp/pages/.git"
printf '<script src="assets/app-old.js"></script>\n' > "$tmp/dist1/index.html"
printf 'old bundle\n' > "$tmp/dist1/assets/app-old.js"
touch "$tmp/dist1/stale.html"
printf '<script src="assets/app-new.js"></script>\n' > "$tmp/dist2/index.html"
touch -r "$tmp/dist1/index.html" "$tmp/dist2/index.html"
printf 'new bundle\n' > "$tmp/dist2/assets/app-new.js"

bash "$copy_site" "$tmp/dist1" "$tmp/pages"
test -f "$tmp/pages/stale.html"
bash "$copy_site" "$tmp/dist2" "$tmp/pages"

cmp "$tmp/dist1/assets/app-old.js" "$tmp/pages/assets/app-old.js"
cmp "$tmp/dist2/assets/app-new.js" "$tmp/pages/assets/app-new.js"
cmp "$tmp/dist2/index.html" "$tmp/pages/index.html"
test ! -e "$tmp/pages/stale.html"
test "$(< "$tmp/pages/.git")" = 'gitdir: worktree'
printf 'Publish copy retained both asset versions, updated HTML, and removed stale non-asset files.\n'
