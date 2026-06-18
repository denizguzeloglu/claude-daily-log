# Daily Log Task

You are running as a scheduled headless job. Your single responsibility is to write today's activity summary as a **per-day file** inside the user's Obsidian vault (`{vault_path}/{daily_dir}/{ISO date}.md`).

This vault uses one Markdown file per day (not a single growing log). Each file has YAML frontmatter and follows the format described in step 8. Never touch any existing file other than the one for today.

## Steps

1. **Load config.** Read `config.json` in the current working directory. Required fields: `vault_path`, `daily_dir`, `projects_dir`, `transcript_root`, `project_dirs`, `git_author_email`, `language`, `date_format`, `heading_format`. Optional: `hub_hint`.

2. **Determine today's date.** Use the system clock (`date`). Produce three forms:
   - `iso` — ISO `YYYY-MM-DD` (used for the filename and the frontmatter `date:` field). This is `date_format`.
   - `heading` — formatted per `heading_format` (e.g. `DD.MM.YYYY`), used for the `# ` heading inside the file.
   - `hour` — current local hour as an integer (used by the day-off rule in step 8).

3. **Skip if already written.** The daily file path is `{vault_path}/{daily_dir}/{iso}.md`. If that file already exists, print `Already logged for {iso}.` and exit `0` without writing or overwriting anything.

4. **Scan today's transcripts.**
   - Expand `~` in `transcript_root` if present.
   - Recursively find `.jsonl` files whose mtime falls on today's local date.
   - For each file, extract only entries where `type == "user"` AND `message.role == "user"` AND `message.content` is plain text (skip tool results, skip system reminders). These are the user's actual prompts.
   - Also scan your own assistant messages for high-level decisions you announced (e.g. "I'll take approach X because Y") — these capture the "why" behind the work.
   - **Do NOT copy verbatim.** Distill across all sessions into themes.

5. **Scan git activity.** Determine the author email: use `config.git_author_email` if non-empty; otherwise fall back to `git config --global user.email`; if still empty, run the log without an `--author` filter. Then for each path in `project_dirs`:
   - Expand `~`. Use `Glob` with pattern `**/.git` (or recurse with `ls`) under each project dir to find repos, up to depth 3.
   - For each repo path `R`, run: `git -C "R" log --since="today 00:00" --all --pretty=format:"%h %s" --author="<email>"` (omit `--author` if no email was resolved). Always use the `-C` form so you never need to `cd`.
   - Collect non-empty results keyed by repo name (basename of `R`).

6. **Discover hub notes.** Recursively list `.md` files under `{vault_path}/{projects_dir}/` (the PARA-lite projects folder). Their basenames (without `.md`) are candidate wikilink targets. Use `hub_hint` in config as a tiebreaker. Wikilinks resolve by basename in Obsidian, so subfolder paths do not appear in the link text.

7. **Detect new project hubs.** For each distinct project or named topic you identify in today's work (proper nouns only — named projects, products, initiatives; NOT generic activities like "debugging", "refactoring", "meetings"):
   - If a hub file with basename `{Topic}.md` already exists anywhere under `{vault_path}/{projects_dir}/` (use the recursive scan from step 6), use that wikilink in the entry as normal — skip this sub-step.
   - If no hub file exists: list the day files in `{vault_path}/{daily_dir}/` (filenames matching `YYYY-MM-DD.md`), take the most recent 14 by date, and read them. Count how many distinct day files mention this topic's name (case-insensitive, partial match on the bare name without brackets).
   - If `prior_days >= 1` (so today + at least 1 prior day = 2+ distinct days), create a new hub stub at `{vault_path}/{projects_dir}/{Topic}/{Topic}.md` using the template below. Create the `{Topic}` subfolder if it does not exist. Use the topic name exactly as you would in a wikilink (preserve user-facing casing, e.g. `Party Room.md`, not `party-room.md`).
   - Never overwrite an existing file. If a file with the same basename already exists anywhere under `{projects_dir}/` (even with different casing on case-insensitive filesystems), skip creation and just use the wikilink.
   - After creation, reference it with a wikilink in today's entry.

   **Hub stub template** (write verbatim, substituting `{Topic}` and `{iso}`):

   ```markdown
   ---
   type: project-hub
   created: {iso}
   tags: [project, auto-hub]
   ---

   # {Topic}

   > _Auto-generated stub — fill in scope, status, and links manually._

   ## Scope

   (empty)

   ## Status

   - First seen in daily log: {iso}

   ## Related

   (empty)
   ```

   Do not attempt to fill `Scope` or `Related` from transcripts — leave them empty. The stub exists to be a wikilink target and a manual writing prompt for the user.

8. **Compose the day file.** The file content must be exactly this shape (matching the vault's existing daily files):

   ```
   ---
   tags: [type/log, daily]
   date: {iso}
   ---

   # {heading}

   - <topic bullet>, optionally with [[hub note]]
   - <another topic>
   - Commitler: <repo> `hash msg`, `hash msg` · <repo> `hash msg`
   ```

   Rules:
   - 5–10 bullets max. Merge related items into one bullet.
   - Bullet text in `config.language` (`tr` = Turkish, `en` = English).
   - Wikilinks only to hubs that exist (after step 7). Skip the wikilink if no good match.
   - The commits line is a single bullet starting with `Commitler:` (tr) or `Commits:` (en), listing repo → commits. Repos are separated by ` · `, commits within a repo by `, `, each commit as `` `hash msg` ``. Omit the whole bullet if there are no commits today.
   - **Day off:** If there are no transcripts AND no commits today:
     - If `hour >= 17`: write the file with `rest` added to the tags (`tags: [type/log, daily, rest]`) and a single bullet `- dinlendi` (tr) / `- day off` (en).
     - If `hour < 17`: print `Too early to declare a day off (hour={hour}); skipping write — the evening run will log real work.` to stderr and exit `0` without creating the file. (An early-hour catch-up run from a previously missed schedule must not pre-empt today's evening run by stamping a bogus `dinlendi` file.)

9. **Write the file.** Create `{vault_path}/{daily_dir}/{iso}.md` with the composed content. End the file with a trailing newline. Do NOT modify `Yaptiklarim.md`, `_Daily.base`, or any other existing file — the Dataview index and base pick up the new file automatically.

10. **Report.** Print one line to stdout: `Logged N bullets for {iso}.` where N is the bullet count. If any new hub stubs were created, add a second line: `Created hub stubs: <Topic>, <Topic>`.

## Constraints

- Create only today's day file, with one exception: you MAY create new hub stub files under `{projects_dir}/` when — and only when — step 7's criteria are met. Never modify, overwrite, or delete any existing file in the vault.
- Do not commit, push, or run any git write operation.
- Do not open a browser, call external APIs, or contact any MCP server.
- If `config.json` is missing, malformed, or `vault_path` / `daily_dir` does not exist: print a clear error to stderr and exit non-zero. Do not attempt to create them.
- Transcripts can be very large. Read line-by-line (JSONL), do not load whole files into memory when avoidable.
- Keep the run under 5 minutes. If transcript volume is too large, prioritize the 3 most recently modified sessions.
- **Do NOT create auxiliary script files** (`.py`, `.sh`, `.js`, etc.) to process data. You already have `Read`, `Glob`, `Grep` as first-class tools — use them directly. Writing a helper script and then being unable to delete it leaves trash in the project dir.
