# DealPulse — Pipeline Intelligence

## What This Is
A Claude Code-native pipeline hygiene tool for Gong's sales team, branded as **DealPulse**.
Claude Code is the intelligence layer — there is no separate build pipeline.

When asked to run the pipeline, Claude reads the deal data, scores every deal,
generates Josh Braun-style re-engagement emails, and produces a polished
single-page HTML dashboard for both sales managers and AEs.

## How to Run
In Claude Code, say: "run pipeline hygiene"

Claude will:
1. Read deals from deals.csv (root of C: project folder)
2. Score every deal using the v2 scoring matrix
3. Flag deals into health categories
4. Write a draft re-engagement email per flagged deal
5. Generate output/dashboard.html (the full product)
6. Write output/flagged_deals.json (structured data)
7. Send Slack digest if SLACK_WEBHOOK_URL is set in .env

## Slack On-Demand
Claude can send Slack any time on request — no need to run the full pipeline.
- Say "send Slack digest" → runs send-slack.ps1 (full Block Kit pipeline digest)
- Say "send a Slack message saying X" → Claude constructs a custom payload and fires it directly
- Both require SLACK_WEBHOOK_URL set in .env

## Data Input Flow
To update the dashboard with new deal data:
1. Edit `C:\Users\Aditya PC\Documents\Deal quality and Pipeline hygiene\deals.csv`
   - Same column headers, just update/add rows
2. Say "run pipeline hygiene" in Claude Code
3. Claude rescores everything and rebuilds dashboard.html + flagged_deals.json
4. Run `git push` → Vercel auto-deploys → live dashboard updates

Key CSV fields that drive scoring:
- `stage`, `close_date`, `last_activity_date` — health score (recency + velocity + stage fit)
- `champion`, `economic_buyer`, `budget_confirmed`, `decision_criteria`, `next_step`, `pain_identified` — MEDDPICC score
- `notes` — email drafts (the more specific the pain, the better the email)

## Company Context
Framed as Gong's internal weekly pipeline review tool.

- **Product being sold**: Gong Revenue Intelligence Platform
- **AEs**: Sarah Chen, Marcus Webb, James O'Brien, Priya Nair
- **Prospects**: B2B companies across various industries
- **Deal size**: $25K–$250K ARR
- **Stages**: Prospecting → Discovery → Demo → Proposal → Negotiation

## Data Source
`C:\Users\Aditya PC\Documents\Deal quality and Pipeline hygiene\deals.csv` — source of truth. NEVER overwrite or regenerate.

Fields (original):
deal_id, deal_name, account_name, ae_name, stage, arr,
close_date, last_activity_date, champion, economic_buyer,
budget_confirmed, decision_criteria, next_step, pain_identified, notes

Fields (extended — added for v2):
stage_entered_date, meeting_count, last_activity_type, competitor_mentioned

## Scoring Matrix v2 (0–100)

### 1. Activity Recency (35% weight)
- 0 days since activity = 100 pts
- 30+ days = 0 pts
- Linear between 0–30 days

### 2. Deal Quality / MEDDPICC (30% weight)
- Champion present: 20 pts
- Economic Buyer present: 15 pts
- Pain Identified (real, documented): 20 pts
- Budget Confirmed: 20 pts
- Decision Criteria documented: 15 pts
- Next Step defined: 10 pts
- Total: 0–100 scaled to 30%

### 3. Stage-Adjusted Close Date (20% weight)
Expected minimum days until close by stage:
- Prospecting: 90+ days
- Discovery: 60+ days
- Demo: 45+ days
- Proposal: 30+ days
- Negotiation: 14+ days
Score reflects how well-aligned the close date is to the current stage.

### 4. Stage Velocity (15% weight)
Days stuck in current stage vs. expected average:
- Prospecting avg: 14 days
- Discovery avg: 21 days
- Demo avg: 14 days
- Proposal avg: 21 days
- Negotiation avg: 14 days
Deals exceeding 2x the average for their stage lose points here.

### Health Categories
- Critical: score 0–30 (or 30+ days no activity)
- Warning: score 31–55 (or 14–29 days no activity)
- Watch: score 56–70 (or 7–13 days no activity)
- Healthy: score 71–100 (and under 7 days since activity)

## Email Framework (Josh Braun)
Every draft email must follow this exactly:

**Subject**: 2–4 words, lowercase, personal feel — no product pitching
**Opening**: First name only, dash, then something specific to their deal situation
**Body**: Reference the documented pain point, call out cost of inaction, under 70 words total
**CTA**: Chill, low-pressure, conversational — "worth a chat?" / "am I off base?" / "still a priority?"

NEVER write:
- "Hope this email finds you well"
- "Just following up" / "circling back"
- "I understand you're busy"
- "Please don't see this as a sales pitch"
- Any all-caps subject lines

Emails are from the AE to the prospect/champion. Written as suggested drafts
for the sales manager to review and hand to the AE.

## Output Rules
- All output goes to /output/ — never anywhere else
- Always overwrite existing files in /output/
- Dashboard is the primary artifact: output/dashboard.html
- Structured data: output/flagged_deals.json
- Presentation: output/slides.html

## Slack (Live)
- Webhook URL in .env as SLACK_WEBHOOK_URL (never hardcode)
- Script: `D:\Deal quality and Pipeline hygiene\scripts\send-slack.ps1`
- Run: `powershell -ExecutionPolicy Bypass -File scripts\send-slack.ps1`
- Block Kit format with colored attachments:
  - Critical (#EF4444): 2-column fields per deal (name/stage | ARR/days dark)
  - Warning (#F97316): line-by-line rollup
  - Watch (#EAB308): line-by-line rollup
  - Footer (#6D28D9): link to live dashboard
- Use ASCII separators only (`-` and `|`) — the middle dot `·` renders as `?` in Slack

## Hard Rules
- NEVER overwrite deals.csv
- NEVER hardcode the Slack webhook URL
- NEVER say "hope this finds you well" or "circling back" in any email
- Emails must be deal-specific: could this be sent to someone else? If yes, rewrite it
- Dashboard must work by opening the HTML file directly in a browser — no server needed
- C: drive is full (0 bytes free) — ALL output lives on D: drive

---

## Current Build State (as of 2026-06-30)

### File Locations
- Source data: `C:\Users\Aditya PC\Documents\Deal quality and Pipeline hygiene\deals.csv`
  - Note: CSV is in the ROOT project folder, NOT in a data/ subfolder
- Enriched data: `D:\Deal quality and Pipeline hygiene\data\deals.json` (20 deals — D001–D020 only)
- Dashboard: `D:\Deal quality and Pipeline hygiene\output\dashboard.html` (~65K chars)
- Flagged deals: `D:\Deal quality and Pipeline hygiene\output\flagged_deals.json`
- Slides (v2): `D:\Deal quality and Pipeline hygiene\output\slides.html`
- Slack script: `D:\Deal quality and Pipeline hygiene\scripts\send-slack.ps1`
- Env file: `D:\Deal quality and Pipeline hygiene\.env` (in .gitignore — never commit)

### Dataset: 30 Deals
All 30 deals live in the JS `DEALS` array inside dashboard.html.
deals.json on D: only has D001–D020; D021–D030 are JS-only.

AE distribution: Sarah Chen (8), Marcus Webb (8), James O'Brien (7), Priya Nair (7)
Total pipeline ARR: $3.08M
Flagged deals: 19 (4 Critical, 10 Warning, 5 Watch)
ARR at risk: $2.09M | Avg health score: 74 | Weighted forecast: $1.22M

Deals D021–D030: Initech Global, Wernham Hogg, Weyland-Yutani, Rekall Inc,
Soylent Corp Expansion, Monsters Inc, Buy n Large, Omni Consumer Products,
Frobozz Magic, InGen Corporation

Hot streak deals (score >=90, activity <=3 days): Nakatomi Corp, Wayne Enterprises, InGen Corporation

### Deployment
- GitHub: https://github.com/siddharthkrishna17/gong-pipeline
- Vercel: https://gong-pipeline.vercel.app
- Slides: https://gong-pipeline.vercel.app/slides.html
- Auto-deploy: GitHub integration is live — `git push` to main triggers Vercel automatically
- No build step. Vercel serves output/ as a static site.
- vercel.json: outputDirectory:"output", rewrites / → /dashboard.html
- Scope: siddharthkrishna17-5772s-projects

To deploy dashboard: `git add output/dashboard.html && git commit -m "message" && git push`
To deploy slides: `git add output/slides.html && git commit -m "message" && git push`

---

## Slides v2 — DealPulse GTM Cohort Deck

6-slide self-contained HTML presentation. Same design language as dashboard.
Navigation: arrow keys / space / click left-right 20% zones. Progress bar + dot indicators.

### Slide Structure & Confirmed Messaging

| # | Theme | Headline | Key Content |
|---|---|---|---|
| 1 | Dark gradient | DealPulse | Overline: GTM Cohort · Claude Code · Siddharth Krishna / Subline: Built to surface what your CRM was never designed to show / 4 chips |
| 2 | Light (#ECEEF3) | Your pipeline is lying to you. | And the weekly review meeting isn't fixing it / Cards: 4+ hrs · $2.09M ARR · $0 |
| 3 | Dark gradient | Here's what I built. | Every deal scored. Every risk flagged. Every email drafted / URL |
| 4 | Light | Built with Claude Code. | From a spreadsheet to a live intelligence tool / Flow: CSV → Claude Code → Dashboard + Slack |
| 5 | Pure dark (#0F0F13) | The pipeline, scored. | 5 count-up stat cards: 30 · 19 · $2.09M · 74 · $1.22M |
| 6 | Dark gradient | Quote | "Pipeline reviews shouldn't start with a spreadsheet. They should start with answers." / Attribution: DealPulse · GTM Cohort 2026 · Siddharth Krishna / Chips: Claude Code · MEDDPICC Framework · Josh Braun Email Framework · Vercel · GitHub · Slack |

### Slides Design Rules
- Product name is always DealPulse (never "Gong Pipeline Intelligence")
- No SPRY references anywhere in slides
- Logo adapts: dark slides = white/lavender, light slides = dark/purple
- Count-up on slide 5 triggers once on first visit, never repeats
- "Every deal scored." on slide 3 is highlighted in #C4B5FD (lavender)

---

## 5-Minute Demo Script

**[Slide 1 — 0:00]**
Hook: "Sales teams spend 4+ hours every week in pipeline reviews built on gut feel and stale CRM data. The deals that are actually dying — nobody sees them until it's too late. That's the problem I built DealPulse to solve."

**[Slide 2 — 0:25]**
Problem: "There's $2.09M in ARR sitting in deals with broken signals right now. And the fix isn't another 'just checking in' email — that recovers zero dollars."

**[Slide 3 — 0:50]**
Transition: "Here's what I built." → switch to live dashboard at gong-pipeline.vercel.app

**[Dashboard — 1:00]**
- Click 'Deals Flagged' stat card → table filters to 19 flagged deals, rows heat-tint
- Click Cyberdyne Systems (D014, $250K) → show modal: score breakdown, coach tip, email
- Arrow key → next deal (show keyboard nav)
- Switch to AE View → flip a card to show email on back
- Back in Manager View → show Act Today, type 'marcus' in search

**[Slide 4 — 2:50]**
How: "One CSV in. Claude Code scores every deal, flags risk, drafts emails, builds the dashboard. From a spreadsheet to a live intelligence tool."

**[Slide 5 — 3:20]**
Numbers: Watch count-up animate. "$3.08M on paper. $1.22M likely to close. That gap is the entire point of DealPulse."

**[Slide 6 — 4:00]**
Close: Quote + attribution. "The goal wasn't to replace the sales manager. It was to make sure they walk into every review already knowing which deals need them."

Timing: Hook+Problem 0:00–0:50 | Demo transition 0:50–1:00 | Dashboard 1:00–2:50 | How 2:50–3:20 | Numbers 3:20–4:00 | Close 4:00–4:30 | Buffer 4:30–5:00

---

## Full Feature Set (as of 2026-06-30)

### Manager View
- Header: DealPulse logo, "Weekly Pipeline Review — June 30 2026", pulsing Live badge,
  refresh timer ("Updated just now" → counts up), Copy Summary button, view toggles, dark mode toggle
- 5 stat cards (all clickable, all animate count-up on load):
  1. Active Deals → resets table to all 30, sorts by ARR desc
  2. Deals Flagged → filters to 19 flagged deals
  3. ARR at Risk → same filter as Flagged, sorted by ARR desc
  4. Avg Health Score → shows all deals sorted score asc (worst first)
  5. Weighted Forecast → opens stage-breakdown modal ($1.22M calculation)
  - Active stat card gets purple glow ring; click same card again to reset
- AE Leaderboard: 4 cards, each with animated SVG arc ring around avatar
  (ring color = health of avg score: green/amber/orange), click → switches to AE view
- Pipeline Funnel: horizontal bars per stage, animate from 0% on load, shows deal count + ARR
- Act Today: top 3 highest-risk deals, pulse glow animation, click → opens deal modal
- Search bar: live search on deal name, AE, account — highlights matches in yellow
- Deal table: sortable columns (click header), heat tint rows (red/orange/yellow by days dark),
  "★ Hot" badge on top-scoring active deals, hover shows "Open →" hint, click → modal

### AE View
- Filter pills by AE (or All AEs)
- Deal cards in grid layout with flip animation:
  - Front: deal context (champion, EB, budget, pain, last touch, flag reason)
  - Back: suggested re-engagement email + Copy button
  - "See email →" / "← Back to deal" flip hints
- Click AE leaderboard card in Manager view → switches to AE view filtered to that rep

### Deal Modal (slide-up)
- Opens from: table row click, Act Today card click, AE leaderboard card click
- Content: deal name + health badge, AE + ARR + Share button, stage stepper,
  Deal Context (6 fields), flag reason, Coach Tip (purple italic advice),
  Score Breakdown (4 animated bars), animated SVG score ring, Suggested Email + Copy
- Share button: copies deep-link URL (gong-pipeline.vercel.app/#D014) to clipboard
- Keyboard navigation: ← / → arrows to move between deals in current list
- Close: X button, backdrop click, or Esc key

### Keyboard Shortcuts
- `?` — opens shortcut overlay
- `D` — toggles dark mode
- `Esc` — closes modal or shortcut overlay
- `← →` — navigates between deals when modal is open

### Dark Mode
- System preference default (`prefers-color-scheme: dark`)
- Sun/moon toggle in header, persisted in localStorage
- Implementation: `body.dark` class, all dark styles scoped to that selector
- Full contrast dark: bg #0F0F13, cards #1A1A24, borders #2A2A38, text #F0F0F5

### Ambient Background
- Page background temperature shifts based on avg health score of current filtered view:
  - Score >=75: cool blue-grey (#ECEEF3 light / #0F0F13 dark)
  - Score 60–74: warm beige (#F0EDE8 light / #130F0D dark)
  - Score <60: warm rose (#F5EAEA light / #1A0D0D dark)
- Updates live when stat card filters are applied (flagged deals avg ~63 → warm shift)
- 0.7s CSS transition so the shift is visible but not jarring

### Copy Summary (executive summary)
Button in header. Generates 3-sentence pipeline summary from live DEALS data:
- Overall risk level + flagged count + ARR at risk + date
- Worst AE by flagged deal count and ARR exposure
- Top priority deal (highest ARR critical deal) with flag reason
Copies to clipboard, shows toast. Content changes dynamically when filters are active.

### URL Hash Deep-linking
- Opening a deal modal sets `window.location.hash = dealId` (e.g. `#D014`)
- Closing clears the hash via history.pushState
- Loading `gong-pipeline.vercel.app/#D014` opens that deal modal automatically

### Toast Notifications
- Bottom-right toast for: email copied, deal link copied, summary copied
- 2.2s auto-dismiss, dark mode aware

---

## Technical Architecture

### Key JS State Variables
```
sortState    = {col:'arr', dir:'desc'}   // current table sort
currentList  = []                         // deals currently shown in table
modalOpenId  = null                       // ID of open modal deal
statFilter   = null | 'flagged'          // stat card filter
activeStat   = null | 'stat-flagged'...  // which stat card is highlighted
searchQuery  = ''                         // live search string
activeAE     = 'all'                     // AE view filter
```

### Key JS Functions
| Function | Purpose |
|----------|---------|
| `sv(v)` | Switch view — MUST use `display='block'` not `display=''` |
| `openModal(id)` | Open slide-up modal, set hash, animate ring |
| `closeModal()` | Close modal, clear hash, reset modalOpenId |
| `renderTable()` | Re-render deal table, update currentList, call updateAmbient |
| `renderFunnel()` | Render funnel bars starting at 0%, animate via setTimeout |
| `renderAEView()` | Render AE deal cards using buildCard() |
| `buildCard(d)` | Build flip card HTML (front + back) |
| `sortBy(col)` | Toggle sort state and re-render |
| `onSearch(q)` | Update searchQuery and re-render |
| `sortedFiltered()` | Returns DEALS filtered by statFilter + searchQuery, sorted |
| `clickStat(id)` | Handle stat card click: set filter, highlight, scroll to table |
| `highlightStat(id)` | Apply/remove `.stat-active` class on stat cards |
| `openForecastModal()` | Open modal with stage-by-stage forecast breakdown |
| `updateAmbient(list)` | Set --page-bg/--page-bg-dark CSS vars based on avg score |
| `getCoachTip(d)` | Generate context-aware coaching advice for a deal |
| `copySummary()` | Generate + copy 3-sentence exec summary to clipboard |
| `shareModal()` | Copy deep-link URL for current open modal |
| `toggleDark()` | Toggle dark class, persist to localStorage |
| `showToast(msg)` | Show bottom-right toast notification |
| `flipCard(el)` | Toggle .flipped on .flip-wrap for card email flip |
| `openKbd()` / `closeKbd()` | Open/close keyboard shortcut overlay |
| `highlight(text,q)` | Wrap search matches in `<mark>` tags |

### Critical sv() Rule
ALWAYS use `element.style.display = 'block'` NOT `element.style.display = ''`
Setting `''` removes the inline style → CSS `#ae-view{display:none}` snaps back → AE view appears blank.

### AE Colors
```js
AE_COLORS = {
  'Priya Nair':   '#7C3AED',
  'Sarah Chen':   '#2563EB',
  'Marcus Webb':  '#059669',
  "James O'Brien":'#D97706'
}
```

### Stage Win Probabilities (for forecast)
Prospecting 10%, Discovery 20%, Demo 35%, Proposal 55%, Negotiation 80%

### AE Arc Ring Math
SVG circle r=24, circumference=151. Arc fill = round(151 × score/100).
Scores: Priya 89→134, Sarah 73→110, Marcus 70→106, James 63→95.
Ring color = health color of avg score (green/amber/orange). Animated via JS setTimeout in init().

### Ambient Background CSS
Uses CSS custom properties `--page-bg` and `--page-bg-dark` on `:root`.
Body uses `background: var(--page-bg, #ECEEF3)` with 0.7s transition.
`updateAmbient(list)` calculates avg score and sets both properties.
Called by `renderTable()` so it updates on every filter/search change.

### No External Dependencies
Dashboard and slides are fully self-contained HTML. No CDN, no fonts, no scripts.
Must work by opening the file directly in a browser.

---

## Continuation Prompt
Paste into a new session to resume work:

> Read CLAUDE.md first (`C:\Users\Aditya PC\Documents\Deal quality and Pipeline hygiene\CLAUDE.md`).
> The product is called DealPulse. Dashboard is at `D:\Deal quality and Pipeline hygiene\output\dashboard.html`.
> Slides (v2) are at `D:\Deal quality and Pipeline hygiene\output\slides.html`.
> C: drive is full — all output goes to D:. GitHub auto-deploys to Vercel on git push to main.
> Ask me what to build next.
