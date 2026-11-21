# Intent `a-v1-start-docs`

## 1. Outcome

> A new user can't find how to start the browser UI, and part of the tests never run. Observed: README.md documents only ./test.sh and ./engine; the UI's start (python3 web/io/serve.py, then /io/index.html) is only in web/io/README.md, and web/grid/README.md points to a demo with no engine; the grid's Node tests (tests/web/grid) are not run by ./test.sh (G31, G32; prior S1, T1). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Standard · State: accepted · 2 work items · 2 bullets

## 2. What you will see

README.md gets a 'Use it in the browser' section: run `python3 web/io/serve.py` (or add a port), open http://127.0.0.1:8000/io/index.html, and you have the spreadsheet: open a .json or .csv, edit in the grid or the formula bar, save; Ctrl+C stops it. web/grid/README.md points to the same start and says its own page is a grid-only demo. ./test.sh now runs the grid, formula bar and open/save Node tests (78 tests instead of 75), and goes red when any of them fails. Nothing in the product's behaviour changes.

- [a-v1-start-docs/README.md](https://github.com/alebairos/sheet-exp-host/blob/8f20dd7c9039cdff63d429df15a3b5dabb9dc739/a-v1-start-docs/README.md)
- [a-v1-start-docs/today.txt](https://github.com/alebairos/sheet-exp-host/blob/8f20dd7c9039cdff63d429df15a3b5dabb9dc739/a-v1-start-docs/today.txt)
- [a-v1-start-docs/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/8f20dd7c9039cdff63d429df15a3b5dabb9dc739/a-v1-start-docs/prototype.diff)

## 3. Approach

Cause, as read and run on main (f101426). (1) README.md documents only ./test.sh and ./engine; the real UI start (python3 web/io/serve.py, then http://127.0.0.1:8000/io/index.html) is only in web/io/README.md, and web/grid/README.md says to serve the repo and open /web/grid/, a grid-only demo where formulas stay text. (2) tests/web has no __init__.py, so unittest discovery (scripts/test) never enters it: not only the grid's Node tests but also the formula bar's and open/save's wrappers, which exist, have never run in ./test.sh (75 tests, no tests.web lines). (3) Run by hand, grid 7/7 and formula bar 6/6 pass, but open/save fails 1 of 9: its page test (one Delete is one compute) went stale twice unnoticed, when a-r2 added the formula bar import and when big-sheets made the grid a scroll box.
Fix, as in the evidence prototype (about 20 lines outside tests). WI 1 (docs): README.md gains a short 'Use it in the browser' section (the command, the port option, the URL, what the page does, Ctrl+C to stop, a link to web/io/README.md); web/grid/README.md sends readers to that start and says its index.html is a demo with no engine. WI 2 (tests): tests/web/__init__.py and tests/web/grid/__init__.py, tests/web/grid/test_grid.py (the formula bar's wrapper, pointed at grid.test.mjs), and the open/save page test's fixture brought up to the page as shipped: rewrite the formula bar import as it already does the grid's, and give its fake element the DOM the grid's mount now uses (classList, style, createElement, replaceChildren). Its assertions are not touched. test.sh and scripts/test need no change. If overlapping intents land first and break a web Node test, WI 2 brings its fixture up to date the same way, never by weakening an assertion.

Beliefs:
- ran: on main both checks fail (b1: README has no start command; b2: no tests.web suite runs); ./test.sh runs 75 tests with no web suites; by hand grid 7/7, formula bar 6/6, open/save 8/9 with ERR_MODULE_NOT_FOUND formula_bar.js. Settled by a_v1_sd_b1_start.sh and a_v1_sd_b2_node.sh (evidence today.txt).
- ran: on the prototype both checks pass, ./test.sh runs 78 tests, all OK, and a failing test planted in each of grid, formula bar and open/save turns ./test.sh red. b1 also passes with port 8000 taken. Settled by b1, b2 and the land test.
- ran: the open/save page test is not vacuous after the fixture fix: each Delete still makes exactly one compute. Settled by b2 (the suite must run and pass).
- human: out_of_scope 'changing the tests' content' is read as 'not changing what the tests assert'. The open/save fixture must change or registering it makes ./test.sh red; registering only the grid would leave b2's 'web parts' unmet. Settled by SpecAccept: if you read it otherwise, reject and say so.
- code: the Node wrappers skip without Node.js, as the formula bar and open/save ones already do; the land workflow has Node (a-r2 needs it), and b2 refuses to pass without Node. Settled by b2 on the land runner.
- memory: overlapping intents (big-sheets, cell-edit, grid-keys, keep-work, sheet-tabs, entry-display, error-help, csv-text, engine-failure, typing-kept) change grid.js or index.html and may break a Node test that today nobody runs. Settled by the land test once this lands; until then, by WI 2 re-running the suites on the main it builds on.
- No computed values here, so no LibreOffice reference applies; the =A1*3 -> 6 in b1 only proves the engine is behind the page.

Learned from RECORD.md and the overlapping pages: S1/T1 lost a point only for the missing UI start; a-i9 and a-i10 both said 'park an intent to register the Node tests' and nobody did, and a-i10's review saw './test.sh green (10 tests)', the skeleton's count, which nobody questioned. The record's lesson that parts tested apart failed together (S12/S14, a-r2) shows here too: the open/save page test broke when a-r2 and big-sheets changed the page, because it never ran. b1 follows README.md from a clean copy, as a user would, not a part in isolation, and the judge check is on the product as shipped. a-r2 noted the browser test needs Chrome and Node in land; this keeps that.

- **Reuses:** web/io/serve.py and its [port] argument as they are; the formula bar's unittest wrapper for Node tests (copied for the grid); scripts/test's unittest discovery, unchanged.
- **Removes:** web/grid/README.md's instruction to use the engine-less demo as the way to run the UI; the silent skipping of every web Node test.
- **Rejected:** Registering only the grid's tests: the formula bar and open/save suites would keep never running, and b2 names the web parts. Running node --test from scripts/test or test.sh: two runners to keep in step, and the existing wrappers already fit unittest. Deleting or skipping the stale open/save page test: it guards a real past defect (a-i11 attempt 1, computes per keypress). Moving the UI start into ./engine: a behaviour change, outside this scope.

## 4. Work items

### `wi-a-v1-start-docs-1`: Say how to start the browser UI

README.md tells a new user the command and URL that open the spreadsheet in the browser, and web/grid/README.md points there instead of to its engine-less demo, so a new user can find the app.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-sd-b1` | b1 | `tests/web/checks/a_v1_sd_b1_start.sh` | red | — |
| `ac-sd-judge` | b1 | `judge:Usefulness only (not Calc fidelity): starting from a fresh clone of the product as shipped and reading only the top-level README.md, can an ordinary user start the spreadsheet, open the page it names in their browser, type a few numbers and a formula such as =A1*2 and see it computed, save their work, and stop the server again, without reading any other file or guessing? Answer yes or no with what you tried.` | judged | — |

### `wi-a-v1-start-docs-2`: Run the web tests in ./test.sh

Registers the grid, formula bar and open/save Node tests with ./test.sh (and brings the stale open/save page test's fixture up to the page as shipped), so a broken web part turns the suite red instead of going unnoticed.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-sd-b2` | b2 | `tests/web/checks/a_v1_sd_b2_node.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | README.md tells a new user how to start the browser UI and which URL to open, and following it from a clean clone shows the app page | no landed check |
| not yet | b2 | ./test.sh runs the web parts' Node tests and fails when one fails | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the tests' content
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:README.md`, `exp-a:web/grid/README.md`, `exp-a:test.sh`, `exp-a:tests/web/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-start-docs-1` | — |
| Reviewed `wi-a-v1-start-docs-1` | — |
| Implemented `wi-a-v1-start-docs-2` | — |
| Reviewed `wi-a-v1-start-docs-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 9 h 34 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
