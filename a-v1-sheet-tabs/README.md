# a-v1-sheet-tabs: what you will get

- 1-order-tab.png: the prototype (prototype.diff, web/io/index.html +21 -1) with order.json open and the Order
  tab selected. Tabs Prices | Order under the grid, the sheet name before the formula bar's cell name, and
  B3 =B1*Prices!B1+B2*Prices!B2 showing Calc's 34.
- Both checks (tabs, edit on Order recomputing both sheets to Calc's 65.5 and 9) pass on it, and so do
  ./test.sh and the a-i11/a-r0/a-r2 checks; on main both fail.

-- plan-a@alebairos
