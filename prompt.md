# Daily Log Task

You are running as a scheduled headless job. Your single responsibility is to append today's activity summary to the user's Obsidian daily log.

## Steps

1. **Load config.** Read `config.json` in the current working directory. Required fields: `vault_path`, `daily_log_file`, `transcript_root`, `project_dirs`, `language`, `date_format`. Optional: `hub_hint`.

2. **Determine today's date.** Use the system clock (`date` / `Get-Date`). Format according to `config.date_format`.

3. **Skip if already logged.** Read the daily log file. If a heading for today's date already exists, print `Already logged for <date>.` and exit without writing.

4. **Scan today's transcripts.**
   - Expand `~` in `transcript_root` if present.
   - Recursively find `.jsonl` files whose mtime falls on today's local date.
   - For each file, extract only entries where `type == "user"` AND `message.role == "user"` AND `message.content` is plain text (skip tool results, skip system reminders). These are the user's actual prompts.
   - Also scan your own assistant messages for high-level decisions you announced (e.g. "I'll take approach X because Y") — these capture the "why" behind the work.
   - **Do NOT copy verbatim.** Distill across all sessions into themes.

5. **Scan git activity.** Get the user's git email once: `git config --global user.email`. Then for each path in `project_dirs`:
   - Recursively find `.git` directories up to depth 3.
   - For each repo, run: `git log --since="today 00:00" --all --pretty=format:"%h %s" --author="<email>"`.
   - Collect non-empty results keyed by repo name (basename of the repo dir).

6. **Discover hub notes.** List `.md` files at the root of `vault_path`. Their basenames (without `.md`) are candidate wikilink targets. Use `hub_hint` in config as a tiebreaker. Never invent a hub name that doesn't exist as a file.

7. **Compose the entry.**

   ```
   ## {today in date_format}
   - <topic bullet>, optionally with [[hub note]]
   - <another topic>
   - Commitler: <repo> `hash msg`, `hash msg` · <repo> `hash msg`
   ```

   Rules:
   - 5–10 bullets max. Merge related items into one bullet.
   - Bullet text in `config.language` (`tr` = Turkish, `en` = English).
   - Wikilinks only to hubs that exist. Skip the wikilink if no good match.
   - The commits line is singular: one bullet starting with `Commitler:` (tr) or `Commits:` (en), listing repo → commits. Omit entirely if no commits.
   - If no transcripts AND no commits today: write a single bullet `- dinlendi` (tr) / `- day off` (en).

8. **Append.** Open the daily log file. Ensure it ends with a blank line. Append the composed entry, then a trailing newline.

9. **Report.** Print one line to stdout: `Logged N bullets for <date>.` where N is the bullet count.

## Constraints

- Modify ONLY the daily log file. Do not create or touch any other file in the vault.
- Do not commit, push, or run any git write operation.
- Do not open a browser, call external APIs, or contact any MCP server.
- If `config.json` is missing, malformed, or `vault_path` / daily log file does not exist: print a clear error to stderr and exit non-zero. Do not attempt to create them.
- Transcripts can be very large. Read line-by-line (JSONL), do not load whole files into memory when avoidable.
- Keep the run under 5 minutes. If transcript volume is too large, prioritize the 3 most recently modified sessions.
