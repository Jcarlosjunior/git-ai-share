#!/usr/bin/env bash
# Builds a small repository with known signatures and checks the CSV output.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
tool="$here/../git-ai-share"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$work"
git init -q -b main
git config user.name "Ada Human"
git config user.email "ada@example.com"
git config commit.gpgsign false
git config core.autocrlf false

n=0
# commit <month> <lines> <message...>: adds <lines> lines to a new file.
commit() {
    local month=$1 lines=$2; shift 2
    n=$((n + 1))
    seq "$lines" > "f$n.txt"
    git add "f$n.txt"
    GIT_AUTHOR_DATE="$month-15T12:00:00Z" GIT_COMMITTER_DATE="$month-15T12:00:00Z" \
        git commit -q "$@"
}

commit 2026-01 10 -m "human only"
commit 2026-01 20 -m "with claude" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
commit 2026-02 30 -m "copilot autofix" -m "Co-authored-by: Copilot Autofix powered by AI <175728472+Copilot@users.noreply.github.com>"
commit 2026-02 40 -m "two tools" -m "Co-authored-by: Claude <noreply@anthropic.com>
Co-authored-by: Cursor Agent <cursoragent@cursor.com>"
commit 2026-02 5 -m "pairing with a person" -m "Co-authored-by: Bo Human <bo@example.com>"
GIT_AUTHOR_NAME="Ada Human (aider)" commit 2026-03 15 -m "aider commit"

fail=0
check() {
    local name=$1 expected=$2 actual=$3
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $name"
        diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true
        fail=1
    else
        echo "ok: $name"
    fi
}

check "by tool" 'tool,commits,commit_share,lines_changed,line_share
"Claude",2,0.3333,60,0.5000
"Aider",1,0.1667,15,0.1250
"Copilot",1,0.1667,30,0.2500
"Cursor",1,0.1667,40,0.3333
"Any AI",4,0.6667,105,0.8750
"No AI signature",2,0.3333,15,0.1250
"Total",6,1,120,1' "$("$tool" --csv)"

check "by month" 'month,commits,ai_commits,ai_commit_share,lines_changed,ai_lines_changed,ai_line_share
"2026-01",2,1,0.5000,30,20,0.6667
"2026-02",3,2,0.6667,75,70,0.9333
"2026-03",1,1,1.0000,15,15,1.0000' "$("$tool" --csv --by month)"

check "by author" 'author,commits,ai_commits,ai_commit_share,lines_changed,ai_lines_changed,ai_line_share
"Ada Human",5,3,0.6000,105,90,0.8571
"Ada Human (aider)",1,1,1.0000,15,15,1.0000' "$("$tool" --csv --by author)"

check "git log options pass through" '"Total",3,1,75,1' "$("$tool" --csv --since=2026-02-01 --until=2026-02-28 | tail -n 1)"

git config --add aishare.tool 'Pairing=bo@example\.com'
check "custom signature" '"Pairing",1,0.1667,5,0.0417' "$("$tool" --csv | grep '^"Pairing"')"

exit $fail
