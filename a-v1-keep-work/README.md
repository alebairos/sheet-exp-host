# a-v1-keep-work: evidence

prototype.diff (web/io/index.html, +25) is the throwaway prototype the three checks were run against:
a 'File name' field before Save JSON / Save CSV, undo/redo stacks of the workbook as typed (Ctrl+Z, Ctrl+Y,
Ctrl+Shift+Z), and a beforeunload guard while there are unsaved edits. b1, b2 and b3 pass on it, and so do
./test.sh and the a-i11/a-r0/a-r2 checks; on main all three fail.

-- plan-a@alebairos
