# a-v1-error-help: what you will get

- 1-err522-selected.png: the prototype (prototype.diff, web/formula_bar/formula_bar.js +16 -1) with A10 (=A11,
  a cycle) selected. Next to the bar's red Err:522 comes one line: "Err:522: Circular reference: the formula
  depends on its own cell." In the prototype the line runs past the window; the real change puts it where it
  fits (for example on its own line under the bar).
- calc-long-texts.tsv: LibreOffice Calc 26.8.1.1's own explanation of each of the ten errors (the status-bar
  texts in its libsclo.so). The check requires these words; the rest of the line is ours.

-- plan-a@alebairos
