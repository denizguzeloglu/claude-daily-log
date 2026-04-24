# claude-daily-log

Cross-platform daily activity logger for Obsidian, powered by Claude Code.

Every day at a scheduled time, a headless Claude Code session:
1. Scans today's Claude Code transcripts under `~/.claude/projects/` for user prompts and key decisions
2. Collects today's git commits across configured project directories
3. Distills everything into a short, wikilink-rich entry and appends it to a single Markdown file in your Obsidian vault

No server, no database, no external service. Just `claude --print` + the OS scheduler.

## Requirements

- [Claude Code](https://claude.com/claude-code) installed and on `PATH` (`claude --version` works)
- An Obsidian vault (a folder with Markdown files — Obsidian itself is not required at run time)
- Windows 10/11 **or** macOS

## Setup

1. Clone this repo somewhere stable:

   ```bash
   git clone https://github.com/<you>/claude-daily-log.git
   cd claude-daily-log
   ```

2. Copy the config template and edit it:

   ```bash
   cp config.example.json config.json
   ```

   Fields:

   | Field | Meaning |
   | --- | --- |
   | `vault_path` | Absolute path to your Obsidian vault |
   | `daily_log_file` | Name of the log file inside the vault (e.g. `DailyLog.md`) |
   | `transcript_root` | Root of Claude Code session transcripts. Default: `~/.claude/projects` |
   | `project_dirs` | List of directories containing git repos to scan for commits |
   | `language` | `tr` or `en` — language of bullet text |
   | `date_format` | Heading format, e.g. `DD.MM.YYYY` or `YYYY-MM-DD` |
   | `hub_hint` | Optional free-form note telling the prompt which wikilinks to prefer |

3. Install the scheduler:

   **Windows** (PowerShell, run as your normal user, not admin):

   ```powershell
   .\install\install-windows.ps1            # default 18:03 local time
   .\install\install-windows.ps1 -Time 19:07
   ```

   **macOS** (Terminal):

   ```bash
   ./install/install-macos.sh               # default 18:03 local time
   ./install/install-macos.sh 19:07
   ```

4. Trigger it once manually to verify:

   ```powershell
   # Windows
   .\scripts\run.ps1
   ```

   ```bash
   # macOS
   ./scripts/run.sh
   ```

   A new heading for today should appear at the bottom of your daily log file.

## How it works

The "brain" is `prompt.md` — a self-contained instruction set Claude Code follows each run. The wrapper scripts just `cat prompt.md | claude --print` with the project directory as CWD so Claude can find `config.json`.

Editing `prompt.md` changes behavior without touching code.

## Uninstall

- **Windows:** `Unregister-ScheduledTask -TaskName 'ClaudeDailyLog' -Confirm:$false`
- **macOS:** `launchctl unload ~/Library/LaunchAgents/com.claude.dailylog.plist && rm ~/Library/LaunchAgents/com.claude.dailylog.plist`

## Notes

- The scheduled task runs whether or not the Claude Code TUI is open. It spawns its own headless session.
- `config.json` is gitignored — it contains your local paths.
- Transcripts are read but never copied verbatim into the log. The prompt instructs Claude to distill.
