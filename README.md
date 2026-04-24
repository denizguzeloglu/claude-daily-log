# claude-daily-log

**Your Obsidian daily log, ghostwritten by Claude Code — automatically, every evening.**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS-lightgrey.svg)
![Status](https://img.shields.io/badge/status-beta-orange.svg)

---

You code all day. You talk through decisions with Claude Code. You ship commits. Then you try to remember what you actually did — and the answer lives in three places: your memory (fuzzy), your commit log (no "why"), and dozens of Claude Code chat transcripts (firehose).

**`claude-daily-log` reads all three, distills them into a short dated entry, and appends it to a single file in your Obsidian vault. Every day. Automatically.**

No server. No database. No extension. Just `claude --print` plus the OS scheduler you already have.

---

## What you get

Every evening at your configured time, a new heading like this lands in your daily log file:

```markdown
## 2026-04-24
- Finished phase 1 of the Coff UI workflow and merged it ([[Coff Workflow To Do]])
- Opened a branch for phase 2a (editing nodes) and started scaffolding ([[Coff Workflow To Do]])
- Drafted marketing-automation plan files ([[Marketing automation agent]])
- Built claude-daily-log — scheduled Obsidian log generator with a sandboxed tool allowlist
- Commits: coff-ui `a4f3d2b feat: node editor` · claude-daily-log `730c8bc fix: scan all repos`
```

No firehose, no boilerplate — just the decisions that mattered, cross-linked to the hub notes you already keep in Obsidian.

When a new project shows up in your work on two different days, `claude-daily-log` also drops an empty hub stub in your vault — e.g. `Party Room.md`, ready for you to flesh out manually — so your graph stays tidy instead of fragmenting into wikilinks that point nowhere.

---

## Why

Keeping a journal is free. Keeping one consistently is not. The usual failure modes:

- **End-of-day writing is friction.** You forget, or skip it, or let it pile up.
- **Commit messages are not a journal.** They describe *what*, not *why*, and miss every non-code decision.
- **Chat history is not a journal either.** Too much signal, too much noise, no rollup.

`claude-daily-log` removes the friction. The LLM that already has all the context writes the entry. You don't have to remember to journal — you just review it the next morning.

---

## Features

- 🕕 **Zero-touch** — runs on Task Scheduler (Windows) or launchd (macOS), appends to your vault file in the background
- 🧠 **Distilled, not copied** — Claude paraphrases into themes; transcript content is never pasted verbatim
- 🔗 **Knowledge-graph aware** — auto-links to hub notes that already exist in your vault, and creates empty stubs for new recurring projects
- 🖥️ **Cross-platform** — first-class installers for Windows and macOS
- 📝 **Prompt-driven** — all behavior lives in [`prompt.md`](prompt.md). Change the prompt, change the tool. No build step
- 🔒 **Sandboxed by default** — explicit tool allow/deny lists, not blanket permission bypass. The agent can't `git push`, `rm`, or reach the web
- 🏠 **Fully local** — no server, no database, no cloud. Your transcripts and vault never leave your machine
- 🌍 **Multilingual** — English and Turkish bullet output built in; any language you can describe in `prompt.md` works

---

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
│  • builds --add-dir sandbox flags    │
│  • pipes prompt.md to `claude --print`│
└─────────────────┬────────────────────┘
                  ▼
┌──────────────────────────────────────┐
│ Headless Claude Code session         │
│  • scans today's transcripts         │
│  • runs git log across your repos    │
│  • composes the entry                │
│  • creates new hub stubs if needed   │
│  • appends to the daily log file     │
└──────────────────────────────────────┘
```

The "brain" is [`prompt.md`](prompt.md) — a plain-English instruction set. Fork it, edit it, iterate on behavior without touching code.

---

## Quickstart

Get running in under two minutes.

```bash
git clone https://github.com/denizguzeloglu/claude-daily-log.git
cd claude-daily-log
cp config.example.json config.json
# open config.json, set vault_path, daily_log_file, and project_dirs
```

Install the scheduler:

**Windows** (PowerShell, as your normal user — no admin required):

```powershell
./install/install-windows.ps1                 # default 18:03 local time
./install/install-windows.ps1 -Time 19:07     # custom time
```

**macOS** (Terminal):

```bash
./install/install-macos.sh                    # default 18:03 local time
./install/install-macos.sh 19:07              # custom time
```

Verify by running once manually:

```powershell
./scripts/run.ps1     # Windows
```
```bash
./scripts/run.sh      # macOS
```

A new heading for today should appear at the end of your daily log file.

---

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI on `PATH` (verify with `claude --version`)
- An Obsidian vault — any directory containing Markdown files. Obsidian itself doesn't need to be running
- Windows 10/11 **or** macOS (Linux should work but installers aren't shipped — PRs welcome)
- On macOS, `python3` on `PATH` (used by `run.sh` to parse JSON; ships with recent macOS / Xcode CLT)

---

## Configuration

All user-specific settings live in `config.json` (copied from `config.example.json`, gitignored so your paths never leak):

| Field | Type | Description |
|---|---|---|
| `vault_path` | string | Absolute path to your Obsidian vault |
| `daily_log_file` | string | Filename of the log inside the vault, e.g. `DailyLog.md` |
| `transcript_root` | string | Root of Claude Code transcripts. Default: `~/.claude/projects` |
| `project_dirs` | string[] | Directories containing git repos to scan for today's commits |
| `language` | `"tr"` \| `"en"` | Output language for bullets |
| `date_format` | string | Heading format, e.g. `YYYY-MM-DD` or `DD.MM.YYYY` |
| `hub_hint` | string (optional) | Free-form note telling Claude which wikilinks to prefer |

To change **what** gets logged or **how** it's formatted, edit `prompt.md` — no code changes required. The prompt is readable English Markdown.

---

## Security model

The scheduled session is **sandboxed with explicit allow and deny lists** — it is *not* run with blanket permission bypass:

- `--permission-mode acceptEdits` — auto-approves file edits only; Bash commands still require explicit allowlist entries
- `--add-dir <path>` — grants read/write access to the vault, transcript root, and listed project dirs, and nothing else
- [`.claude/settings.json`](.claude/settings.json) — explicit `allow` list for exactly the tools the task needs (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git log:*)`, `Bash(git -C:*)`, `Bash(date:*)`, …)
- Explicit `deny` list for anything risky (`git push`, `git commit`, `git add`, `git reset`, `rm`, `mv`, `WebFetch`, `WebSearch`)

If the prompt drifts and tries to push code or delete files, the session fails closed.

---

## Troubleshooting

- **Nothing was appended.** Run `scripts/run.*` manually — it prints `Logged N bullets for <date>.` on success, or a clear error otherwise.
- **`claude` not found by the scheduled task.** The scheduled session inherits the user's `PATH`. If `claude` is in a non-standard location, add its directory to `PATH` in your shell init (macOS) or system environment (Windows), or use a full path in `scripts/run.*`.
- **Permission denied writing to vault.** Make sure `vault_path` in `config.json` exists and matches the `--add-dir` flag the wrapper builds.
- **Entry keeps landing on the wrong day.** The job fires at the scheduled local time; headings use the local date at run time. If you work past midnight, schedule the run before midnight.
- **"Already logged" on every run.** The prompt deliberately skips if today's heading already exists — so manual test runs plus the scheduled run don't double-write. Delete the heading to re-run for the same day.

---

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

---

## Contributing

Issues and PRs welcome. Because behavior is driven by `prompt.md`, many "features" are really prompt tweaks — easy to propose, easy to test. For new platform support (e.g. Linux systemd timers, vanilla cron), see the installers under `install/` as templates.

Run `scripts/run.*` manually to iterate on prompt changes — each run is one `claude --print` invocation and a one-line status report.

---

## License

[MIT](LICENSE) — do what you want, no warranty.
