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
   - Use `Glob` with pattern `**/.git` (or recurse with `ls`) under each project dir to find repos, up to depth 3.
   - For each repo path `R`, run: `git -C "R" log --since="today 00:00" --all --pretty=format:"%h %s" --author="<email>"`. Always use the `-C` form so you never need to `cd`.
   - Collect non-empty results keyed by repo name (basename of `R`).

6. **Discover hub notes.** List `.md` files at the root of `vault_path`. Their basenames (without `.md`) are candidate wikilink targets. Use `hub_hint` in config as a tiebreaker.

7. **Detect new project hubs.** For each distinct project or named topic you identify in today's work (proper nouns only — named projects, products, initiatives; NOT generic activities like "debugging", "refactoring", "meetings"):
   - If a hub file already exists at `{vault_path}/{Topic}.md`, use that wikilink in the entry as normal — skip this sub-step.
   - If no hub file exists: scan the last 14 `## ...` date headings in the daily log file. Count how many distinct date headings contain this topic's name (case-insensitive, partial match on the bare name without brackets).
   - If `prior_days >= 1` (so today + at least 1 prior day = 2+ distinct days), create a new hub stub at `{vault_path}/{Topic}.md` using the template below. Use the topic name exactly as you would in a wikilink (preserve user-facing casing, e.g. `Party Room.md`, not `party-room.md`).
   - Never overwrite an existing file. If the target path already exists (even with different casing on case-insensitive filesystems), skip creation and just use the wikilink.
   - After creation, reference it with a wikilink in today's entry.

   **Hub stub template** (write verbatim, substituting `{Topic}` and `{today_iso}` — ISO date `YYYY-MM-DD` regardless of `config.date_format`):

   ```markdown
   ---
   type: project-hub
   created: {today_iso}
   tags: [project, auto-hub]
   ---

   # {Topic}

   > _Auto-generated stub — fill in scope, status, and links manually._

   ## Scope

   (empty)

   ## Status

   - First seen in daily log: {today_iso}

   ## Related

   (empty)
   ```

   Do not attempt to fill `Scope` or `Related` from transcripts — leave them empty. The stub exists to be a wikilink target and a manual writing prompt for the user.

8. **Compose the entry.**

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

9. **Append.** Open the daily log file. Ensure it ends with a blank line. Append the composed entry, then a trailing newline.

10. **Report.** Print one line to stdout: `Logged N bullets for <date>.` where N is the bullet count. If any new hub stubs were created, add a second line: `Created hub stubs: <Topic>, <Topic>`.

## Constraints

- Modify only the daily log file, with one exception: you MAY create new hub stub files at the vault root when — and only when — step 7's criteria are met. Never modify, overwrite, or delete any existing file in the vault other than the daily log.
- Do not commit, push, or run any git write operation.
- Do not open a browser, call external APIs, or contact any MCP server.
- If `config.json` is missing, malformed, or `vault_path` / daily log file does not exist: print a clear error to stderr and exit non-zero. Do not attempt to create them.
- Transcripts can be very large. Read line-by-line (JSONL), do not load whole files into memory when avoidable.
- Keep the run under 5 minutes. If transcript volume is too large, prioritize the 3 most recently modified sessions.
- **Do NOT create auxiliary script files** (`.py`, `.sh`, `.js`, etc.) to process data. You already have `Read`, `Glob`, `Grep` as first-class tools — use them directly. Writing a helper script and then being unable to delete it leaves trash in the project dir.
