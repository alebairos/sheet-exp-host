"""Big sheets in a real browser (a-v1-big-sheets): open a 2001-row, 12-column CSV, scroll to its last cell and
back, move with the arrows and PageDown/PageUp past the visible edge, edit row 2001 and see the formulas reading
it recompute to LibreOffice Calc's values.

big_sheets.mjs drives headless Chrome/Chromium ($CHROME first, then google-chrome or chromium on PATH) over the
DevTools pipe, Node's standard library only, against web/io/serve.py. Skipped only without node or a browser.
"""
import os
import shutil
import subprocess
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
NO_BROWSER = 2


class BigSheetsTest(unittest.TestCase):
    def test_scroll_move_and_edit_row_2001_in_the_browser(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("node is not installed")
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        p = subprocess.run([node, os.path.join(HERE, "big_sheets.mjs")], cwd=ROOT, env=env,
                           capture_output=True, text=True, timeout=300)
        if p.returncode == NO_BROWSER:
            self.skipTest(p.stdout.strip())
        self.assertEqual(p.returncode, 0, (p.stdout + p.stderr).strip()[-2000:])
        self.assertIn("ok", p.stdout)


if __name__ == "__main__":
    unittest.main()
