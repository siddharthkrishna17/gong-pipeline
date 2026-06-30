# Gong Pipeline Intelligence Dashboard

## What This Is
A Claude Code-native pipeline hygiene tool for Gong's sales team.
Claude Code is the intelligence layer — there is no separate build pipeline.

When asked to run the pipeline, Claude reads the deal data, scores every deal,
generates SPRY/Josh Braun-style re-engagement emails, and produces a polished
single-page HTML dashboard for both sales managers and AEs.

## How to Run
In Claude Code, say: "run pipeline hygiene"

Claude will:
1. Read deals from data/deals.csv
2. Score every deal using the v2 scoring matrix
3. Flag deals into health categories
4. Write a draft re-engagement email per flagged deal
5. Generate output/dashboard.html (the full product)
6. Write output/flagged_deals.json (structured data)
7. Send Slack digest if SLACK_WEBHOOK_URL is set in .env

## Company Context
Framed as Gong's internal weekly pipeline review tool.

- **Product being sold**: Gong Revenue Intelligence Platform
- **AEs**: Sarah Chen, Marcus Webb, James O'Brien, Priya Nair
- **Prospects**: B2B companies across various industries
- **Deal size**: $25K–$250K ARR
- **Stages**: Prospecting → Discovery → Demo → Proposal → Negotiation

## Data Source
`data/deals.csv` — source of truth. NEVER overwrite or regenerate.

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
A Prospecting deal closing in 2 weeks scores near 0 on this factor.

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

## Email Framework (SPRY / Josh Braun)
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

## Dashboard Design (output/dashboard.html)
Single-page HTML/CSS/JS app. Must look like a real SaaS product — not a report.

### Manager View
- Header: Gong logo + "Weekly Pipeline Review — [date]"
- Summary bar: total deals, flagged count, total ARR at risk, avg health score
- AE Leaderboard: each AE's deal count, flagged count, ARR at risk
- Deal Risk Table: all deals sorted by ARR desc, color-coded by health
- Top 3 "Act Today" deals highlighted prominently

### AE View
- Filtered to show only that AE's deals
- Each flagged deal shown as a card
- Card expands to show: deal context, health score breakdown, draft email (copyable)

### Design Aesthetic
- Clean, modern, data-dense but readable
- Color system: red (#EF4444) = Critical, orange (#F97316) = Warning,
  yellow (#EAB308) = Watch, green (#22C55E) = Healthy, grey = no action needed
- Font: system-ui / Inter
- No external dependencies — fully self-contained HTML file

## Output Rules
- All output goes to /output/ — never anywhere else
- Always overwrite existing files in /output/
- Dashboard is the primary artifact: output/dashboard.html
- Structured data: output/flagged_deals.json

## Slack (Optional)
- Webhook URL in .env as SLACK_WEBHOOK_URL
- Skip gracefully with a console note if not set
- Setup deferred — will configure before going live
- When active: Block Kit format, Critical deals individually, Warning/Watch as rollup

## Hard Rules
- NEVER overwrite data/deals.csv
- NEVER hardcode the Slack webhook URL
- NEVER say "hope this finds you well" or "circling back" in any email
- Emails must pass the SPRY test: could this be sent to someone else? If yes, rewrite it
- Dashboard must work by opening the HTML file directly in a browser — no server needed

---

## Current Build State (as of 2026-06-29)

### File Locations
ALL files now live on D: drive — C: drive was full and has been abandoned.
**Working directory for all future Claude Code sessions: `D:\Deal quality and Pipeline hygiene\`**

- Source data: `D:\Deal quality and Pipeline hygiene\deals.csv`
- Enriched data: `D:\Deal quality and Pipeline hygiene\data\deals.json` (30 deals with extended fields)
- Dashboard: `D:\Deal quality and Pipeline hygiene\output\dashboard.html`
- Flagged deals: `D:\Deal quality and Pipeline hygiene\output\flagged_deals.json`
- Vercel config: `D:\Deal quality and Pipeline hygiene\vercel.json`

### Dataset: 30 Deals
deals.csv has been expanded from 20 to 30 deals and all blank context fields have been
filled in with realistic fabricated data. Every deal now has a named champion, economic
buyer, documented pain point with metrics, decision criteria, and a next step.

AE distribution: Sarah Chen (8), Marcus Webb (8), James O'Brien (7), Priya Nair (7)
Total pipeline ARR: $3.08M
Flagged deals: ~19 (4 Critical, 10 Warning, 5 Watch)
ARR at risk: ~$2.09M
Avg health score: 74

New deals added: D021–D030 (Initech Global, Wernham Hogg, Weyland-Yutani, Rekall Inc,
Soylent Corp Expansion, Monsters Inc, Buy n Large, Omni Consumer Products,
Frobozz Magic, InGen Corporation)

### Design Decisions Made
- Visual style: Donezo-inspired — 20px border-radius on all cards, real drop shadows
  (0 2px 12px rgba(0,0,0,.06)), hover lift (translateY -2px), more whitespace
- Background: #ECEEF3 (cooler grey)
- Featured stat card: first card in .stat-row gets dark Gong purple gradient
  (linear-gradient 140deg #16102A → #2D1B69 → #4C1D95)
- AE leaderboard top accent: gradient bars (not solid)
- Filter buttons: full pill shape (border-radius 20px) with purple glow when active
- Dashboard layout: top header toggle (Manager/AE view) — NOT a sidebar
- Gong colors preserved: purple #7C3AED/#2D1B69, health colors unchanged

### Critical Technical Fix
In the view-switching JS function sv(), always use `element.style.display = 'block'`
NOT `element.style.display = ''` — setting '' removes the inline style and lets the
CSS `#ae-view{display:none}` rule snap back in, causing the AE view to appear blank.

### Email Approach
All 19 flagged deal emails have been rewritten with specific context:
- Champion name used in opener
- Actual pain metric referenced (e.g. "31% below quota", "8hrs/week manual reporting")
- Cost of inaction tied to documented pain
- CTA matches the deal's specific stall point
- No forbidden phrases used

### Full Rebuild Complete (2026-06-29)
dashboard.html is the complete v2 product:
- Static Manager View: summary bar + AE leaderboard + Act Today (3 cards) + 30-row ARR-sorted table
- JS-driven AE View: 19 flagged deal cards, DEALS[] data array, buildCard() string concat
  (no nested template literals), data-ae attributes for filter buttons (handles "James O'Brien"
  apostrophe safely), data-subj/data-body on copy buttons, esc() helper for XSS-safe rendering
- Clipboard copy with execCommand() fallback for local file:// access

### AE Filter Button Pattern
Uses data-ae HTML attribute to avoid JS apostrophe escaping:
  <button class="af" data-ae="James O'Brien" onclick="fa(this)">
  function fa(el) { activeAE = el.getAttribute("data-ae"); ... }

### Vercel Deployment
- vercel.json at project root sets outputDirectory:"output" and rewrites / → /dashboard.html
- Scope: siddharthkrishna17-5772s-projects
- Live URL: https://gong-pipeline.vercel.app
- GitHub: https://github.com/siddharthkrishna17/gong-pipeline
- To redeploy after updates:
    cd "D:\Deal quality and Pipeline hygiene"
    git add . && git commit -m "message" && git push
    vercel --prod --scope siddharthkrishna17-5772s-projects
- No build step. Vercel serves output/dashboard.html as a static site.

---

## V3 Plan (fully confirmed 2026-06-30, NOT YET BUILT)

All decisions confirmed by user. Build as a single full rewrite of dashboard.html.

### Confirmed Feature List

1. **Dark mode** — system preference default (`prefers-color-scheme`), sun/moon toggle in header, persisted in localStorage
2. **Slide-up modal** — click any deal row, Act Today card, or AE leaderboard card → slide-up modal. Close via X or backdrop click.
3. **Score breakdown bars** — inside modal: 4 horizontal bars (Activity 35%, MEDDPICC 30%, Stage-Close 20%, Velocity 15%) with X/max labels
4. **Sortable table columns** — click any header to sort asc/desc, arrow indicators shown
5. **Clickable AE leaderboard cards** — click card → switches to AE view filtered to that rep
6. **Clickable Act Today cards** — opens slide-up modal for that deal
7. **Search/filter bar** — live search on manager deal table only (by deal name, AE, account)
8. **Pipeline forecast stat** — 5th summary card: weighted ARR by stage win probability
9. **Pipeline funnel chart** — horizontal bars between AE leaderboard and Act Today section

### Modal Design (confirmed 2026-06-30)
Clean sections with dividers:
- Header: deal name, health badge, AE name, ARR
- Section "DEAL CONTEXT": Champion, Econ Buyer, Budget, Pain, Next Step, flag reason
- Section "SCORE BREAKDOWN": 4 bars with X/max labels, total score shown
- Section "SUGGESTED EMAIL": subject (purple), body, Copy Email button
- Full-width dividers between each section

### Funnel Chart (confirmed 2026-06-30)
- Position: between AE leaderboard and Act Today
- Horizontal bars per stage, Gong purple gradient fill
- Each bar labelled with deal count + ARR total for that stage

### Dark Mode (confirmed 2026-06-30)
Full contrast dark — NOT soft grey:
- Background: #0F0F13
- Card background: #1A1A24
- Card border: #2A2A38
- Text primary: #F0F0F5
- Text muted: #8888A8
- Purple accent: #6D28D9 (unchanged)
- Health colors: unchanged
- Implementation: `body.dark` class toggle, all dark styles scoped to `body.dark`

### Search Scope (confirmed 2026-06-30)
Manager table only. AE view is unaffected by the search bar.

### Stage Win Probabilities (for forecast stat)
- Prospecting: 10%
- Discovery: 20%
- Demo: 35%
- Proposal: 55%
- Negotiation: 80%

### Data Note for V3
- `deals.json` on D: only has D001–D020 (20 deals)
- D021–D030 live only in the JS `DEALS` array inside dashboard.html
- V3 must have all 30 deals in the JS array so modals work for every table row
- Healthy deals not currently in DEALS array — add with: id, deal, ae, stage, arr, days, score, health, champ, eb, budget, pain, nextstep, flag (empty string for healthy deals)

### Build Notes
- Single full rewrite pass (~25–30K tokens)
- No nested template literals — use string concatenation in buildCard()
- sv() must use `element.style.display = 'block'` not `''`
- Modal: slide-up overlay with backdrop, closeable via X or backdrop click
- No external dependencies — fully self-contained HTML

### Continuation Prompt
Paste into a new session to resume:

> Read CLAUDE.md first (C:\Users\Aditya PC\Documents\Deal quality and Pipeline hygiene\CLAUDE.md). Then read D:\Deal quality and Pipeline hygiene\output\dashboard.html in full. C: drive is full — all output goes to D:. Build v3 exactly as specified in the "V3 Plan" section of CLAUDE.md in a single rewrite pass. Output to D:\Deal quality and Pipeline hygiene\output\dashboard.html.
