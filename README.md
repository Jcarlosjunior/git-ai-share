# git-ai-share

`git ai-share` counts the commits in a git history that carry an AI coding tool's signature. It reads each commit's author, committer and `Co-authored-by` trailers, and matches them against the signatures that Claude Code, GitHub Copilot, Cursor, Aider, Devin and Jules write.

This is the output for [modelcontextprotocol/python-sdk](https://github.com/modelcontextprotocol/python-sdk) since January 2025, run on 3 November 2026:

```
$ git ai-share --since=2025-01-01
Tool              Commits   Share  Lines changed   Share
Claude                 26    3.0%           8439    1.9%
Copilot                 4    0.5%            165    0.0%
----------------------------------------------------------
Any AI                 30    3.4%           8604    1.9%
No AI signature       845   96.6%         432655   98.1%
Total                 875                 441259
```

The tool is one bash script. It needs git and awk, nothing else.

## Install

Put the script anywhere on your `PATH`. Git then runs it as `git ai-share`:

```sh
curl -fsSL -o ~/.local/bin/git-ai-share https://raw.githubusercontent.com/Jcarlosjunior/git-ai-share/main/git-ai-share
chmod +x ~/.local/bin/git-ai-share
```

Requires git 2.22 or newer. It works on Linux, macOS and Git Bash on Windows.

## Usage

```sh
git ai-share                       # share per tool, whole history
git ai-share --by month            # trend over time
git ai-share --by author           # who uses AI tools, and how much
git ai-share --csv > ai-share.csv  # for a spreadsheet or dashboard
git ai-share v2.0..HEAD -- src/    # any git log range, options and paths
```

Merge commits are skipped unless you pass `--include-merges`. A commit with signatures from two tools counts once in "Any AI" and once for each tool.

## Signatures

`git ai-share --tools` prints the signatures in use. The built-in ones:

| Tool | Matched on |
| --- | --- |
| Claude | `noreply@anthropic.com` (the Claude Code trailer), `claude[bot]` |
| Copilot | `Copilot@users.noreply.github.com` (Copilot and Copilot Autofix), `copilot-swe-agent[bot]` |
| Cursor | `cursoragent@cursor.com` |
| Aider | `noreply@aider.chat`, author names ending in `(aider)` |
| Devin | `devin-ai-integration[bot]` |
| Jules | `google-labs-jules[bot]` |

Add a tool, or replace a built-in one, with git config. The value is `Name=regex`, an extended regular expression matched against the lowercased `name <email>`:

```sh
git config --add aishare.tool 'Codex=codex@openai\.com'
git config --global --add aishare.tool 'Internal bot=^release-bot <'
```

If a tool you use leaves a signature that is missing here, please open an issue or a pull request with an example commit.

## What the numbers mean

This tool counts attribution, not authorship. Keep three limits in mind:

- **It is a lower bound.** Many tools add no trailer by default, and people often remove trailers. A commit without a signature is not proof that no AI was used.
- **Lines changed are per commit.** A commit with a Claude trailer counts all of its added and deleted lines, including the parts a person wrote.
- **Squash merges keep trailers, rebases may not.** GitHub copies `Co-authored-by` trailers into squash commits. Other workflows can drop them.

Use it to see trends within one team or repository over time. It is not a measure of productivity or code quality, and comparing people by it says little.

## Tests

```sh
bash tests/run.sh
```

## License

MIT
