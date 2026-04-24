# claude-daily-log

> Automated daily activity journal for Obsidian, powered by a scheduled headless [Claude Code](https://claude.com/claude-code) session.

Every evening, a fresh Claude session reads your Claude Code transcripts and today's git commits across your projects, distills them into a short Markdown entry, and appends it to a single file in your Obsidian vault. No server, no database, no extension — just `claude --print` plus the OS scheduler.

## What it writes

A new dated heading appended to one file in your vault, e.g.:

```markdown
## 2026-04-24
- Finished phase 1 of the Coff UI workflow and merged it ([[Coff Workflow To Do]])
- Opened branch for phase 2a (editing nodes) and started scaffolding ([[Coff Workflow To Do]])
- Drafted marketing-automation plan files ([[Marketing automation agent]])
- Built claude-daily-log — scheduled Obsidian log generator with tool-allowlist sandbox
- Commits: coff-ui `a4f3d2b feat: node editor` · claude-daily-log `730c8bc fix: scan all repos`
```

The entry is composed from:
- **Claude Code transcripts** (the JSONL files under `~/.claude/projects/*`) — captures decisions and intent
- **`git log --since=midnight`** across directories you list — captures what actually shipped
- **`[[wikilinks]]`** to hub notes that already exist in your vault (never invented)

Transcripts are **distilled, never copied verbatim**.

## Why

"What did I work on today?" is surprisingly hard to answer from memory. Commit messages miss the decisions. Chat history has the decisions but is a firehose. This tool does the distillation automatically, once a day, with zero effort after setup.

## How it works

```
┌──────────────────────────────────────┐
│ OS scheduler fires at your chosen    │
│ time (Task Scheduler / launchd)      │
└─────────────────┬────────────────────┘
                  ▼
┌──────────────────────────────────────┐
│ scripts/run.{ps1,sh}                 │
│  • reads config.json                 │
│  • builds --add-dir flags            │
│  • pipes prompt.md to `claude --print`│
└─────────────────┬────────────────────┘
                  ▼
┌──────────────────────────────────────┐
│ Headless Claude Code session         │
│  • scans today's transcripts         │
│  • runs git log across repos         │
│  • composes the entry                │
│  • appends to the daily log file     │
└──────────────────────────────────────┘
```

The "brain" is [`prompt.md`](prompt.md) — a plain-English instruction set. Change the prompt, change the behavior. No build step.

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI on `PATH` (verify with `claude --version`)
- An Obsidian vault — any directory with Markdown files; Obsidian itself does not need to be running
- Windows 10/11 **or** macOS (Linux should work, but install scripts aren't provided)
- On macOS, `python3` on `PATH` (used by `run.sh` to parse JSON; ships with recent macOS / Xcode CLT)

## Quickstart

```bash
git clone https://github.com/<you>/claude-daily-log.git
cd claude-daily-log
cp config.example.json config.json
# open config.json and fill in vault_path, daily_log_file, project_dirs
```

Install the scheduler:

**Windows** (PowerShell, as your normal user — no admin needed):

```powershell
./install/install-windows.ps1                 # default 18:03 local time
./install/install-windows.ps1 -Time 19:07     # pick your own time
```

**macOS** (Terminal):

```bash
./install/install-macos.sh                    # default 18:03 local time
./install/install-macos.sh 19:07              # pick your own time
```

Verify by running once manually:

```powershell
./scripts/run.ps1       # Windows
```

```bash
./scripts/run.sh        # macOS
```

A new heading for today should appear at the end of your daily log file.

## Configuration

`config.json` (gitignored — your local paths stay local):

| Field | Type | Description |
|---|---|---|
| `vault_path` | string | Absolute path to your Obsidian vault |
| `daily_log_file` | string | Filename inside the vault, e.g. `DailyLog.md` |
| `transcript_root` | string | Root of Claude Code transcripts. Default: `~/.claude/projects` |
| `project_dirs` | string[] | Directories containing git repos to scan for today's commits |
| `language` | `"tr"` \| `"en"` | Output language for bullet text |
| `date_format` | string | Heading format, e.g. `YYYY-MM-DD` or `DD.MM.YYYY` |
| `hub_hint` | string (optional) | Free-form note telling Claude which wikilinks to prefer |

## Security model

The scheduled session is **sandboxed with explicit allow/deny lists** — it is *not* run with blanket permission bypass:

- **`--permission-mode acceptEdits`** — auto-approves file edits only; Bash commands still require explicit allowlist entries
- **`--add-dir <path>`** — grants read/write access to the vault, transcript root, and listed project dirs only
- **[`.claude/settings.json`](.claude/settings.json)** — explicit `allow` list for exactly the tools the task needs (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git log:*)`, `Bash(git -C:*)`, `Bash(date:*)`, …)
- **Explicit `deny` list** for anything risky (`git push`, `git commit`, `git add`, `git reset`, `rm`, `mv`, `WebFetch`, `WebSearch`)

If the prompt drifts and tries to `git push` or delete files, the session fails closed.

## Customizing

Almost everything is driven by `prompt.md`. To change what gets logged, how it's formatted, or which sources are consulted, edit that file — no code changes needed. Common tweaks live in `config.json` (language, date format, paths, project list).

## Uninstall

```powershell
# Windows
Unregister-ScheduledTask -TaskName 'ClaudeDailyLog' -Confirm:$false
```

```bash
# macOS
launchctl unload ~/Library/LaunchAgents/com.claude.dailylog.plist
rm ~/Library/LaunchAgents/com.claude.dailylog.plist
```

## Troubleshooting

- **Nothing was appended.** Run `scripts/run.*` manually and read the output — it prints `Logged N bullets for <date>.` on success, or a clear error otherwise.
- **`claude not found`.** The scheduled session inherits the user's `PATH`. On Windows this comes from the logged-in user profile; on macOS it comes from whatever login shell resolves under launchd. If `claude` is in a non-standard location, symlink it into `/usr/local/bin` (macOS) or set a full path in `scripts/run.ps1`.
- **Permission denied writing to vault.** Make sure `vault_path` in `config.json` exists and matches the `--add-dir` flag the wrapper builds.
- **Entry keeps getting written for the wrong day.** The job runs at the scheduled local time; headings use the local date at run time. If you work past midnight, schedule before midnight.

## License

MIT
