# Running the experiment: Cursor agents on this host

This run builds the spreadsheet engine in [sheet-exp-b](https://github.com/alebairos/sheet-exp-b), whose `SPEC.md` is the only spec, through this cooknship host. A baseline builds the same spec without cooknship in [sheet-base-d](https://github.com/alebairos/sheet-base-d). At the end a hidden suite of 600 LibreOffice cases scores both.

## The sessions

Run six Cursor cloud agents (Cursor CLI with pstack), one per row, all at once.

| Id (`--as`) | Roles | Tiers | Does |
|---|---|---|---|
| `gm-1@alebairos` | Gm | Top | intake the human asks for; `poke` after a merged landing; shows the human what waits on them |
| `plan-1@alebairos` | Planner | Top | writes plans and their checks |
| `gate-1@alebairos` | GateReviewer | Top | certifies plans (needs the product's toolchain) |
| `impl-1@alebairos` | Implementer | Any | builds work items |
| `impl-2@alebairos` | Implementer | Any | builds work items |
| `rev-1@alebairos` | DoReviewer | Top | reviews built work items |

- Add implementers (`impl-3@alebairos`, …) once the board shows `available.implement` above 2 for a while. Never give a session two of Planner, GateReviewer and DoReviewer.
- The roles are spread across sessions on purpose. A session never reviews its own work: `land` voids that review.

## Setting up each session

Each session uses its own clones and environment. It never shares a working tree.

```bash
curl -fsSL https://github.com/alebairos/cooknship-machine-releases/releases/download/v0.1.30/install.sh | sh
git clone https://github.com/alebairos/sheet-exp-host host && git clone https://github.com/alebairos/sheet-exp-b exp-b
cd host
export COOKNSHIP_AS=<the id from the table>
export COOKNSHIP_SESSION=<this harness session's id>
export COOKNSHIP_PRODUCT=exp-b
```

## The prompt for each agent

> You are `<id>`, a cooknship operator with the roles `<roles>`, working in this clone of sheet-exp-host. Read `AGENTS.md` and follow it exactly. Loop: `cooknship next --as $COOKNSHIP_AS --roles <roles> --tiers <tiers> --product exp-b`, do the task it hands you with the skill its hint names, and report it with `cooknship submit … --usage '<your model and tokens>'`. After every step print the `status` and `next` lines verbatim. When `next` says Stop, wait a few minutes and ask again; stop after 3 days. Never send a decision for the human: show it to them. Never read sheet-base-d or anything outside these two repos and SPEC.md.

## The human (the HITL)

- The HITL answers in plain words in a chat with their own Claude Code session (not one of the six). That session shows each waiting decision from `cooknship decide --list` with its options and the page link. It sends the HITL's answer as they gave it, with `cooknship decide --as alebairos --answer <Name:id> --option <key> --text '<their words>'`, and adds nothing of its own. This deliberately departs from rule 4 of the generated AGENTS.md: the HITL chose it, and it is logged as a finding of the run.
- Its `--text` ends with the log line `min=<minutes> page-only=<y|n> ease=<1-5>`, which the HITL gives with the answer or the session asks for.
- Nothing is done by hand outside the machine; anything that is gets logged as a finding.
- Day 1: ask `gm-1` to park "make it feel fast" exactly as worded.
- Day 2: ask `gm-1` to file the defect "ROUND(2.5) shows 2".
- Auto-merge is on for exp-b (`cooknship automerge off --product exp-b` turns it off). WIP is 8.

## The baseline (sheet-base-d)

One Cursor cloud agent (Cursor CLI with pstack), started at the same time as the six above, with the same model, a 3-day limit, and helpers of its own if it wants:

> Build what `SPEC.md` in this repo specifies, in this repo, committing to `main`. `./test.sh` must run the whole suite from a clean clone. Read nothing outside this repo. Stop when you judge the spec done, or after 3 days.

## The end

The run stops when every intent here has a verdict, or after 3 days. The hidden suite then runs against both engines, and the ledger's replay becomes the explainer page.
