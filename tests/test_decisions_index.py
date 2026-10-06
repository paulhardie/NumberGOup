"""The decision index (tools/decisions_index.py) is what lets a session find a
decision without reading DECISIONS.md, and what stops two branches taking the
same ID, so both are tested: IDs are unique and in order, every record has a
status, and the committed index is current."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('decisions_index', ROOT / 'tools/decisions_index.py')
index = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(index)

SAMPLE = '''# Decisions

## D001 — First
- **Status:** Accepted (2026-01-01), then replaced by [D002](#d002--second).

## D002 — Second | with a bar
- **Status:** Accepted: the owner's words.
- Detail.

## D004 — Third
*Superseded in part by D002.*
- **Status:** Accepted.

## D005 — No status line of its own
- Detail.

## D006 — Next record's status must not leak backwards
- **Status:** Accepted.

## D007 — Wording the real records use
- **Status:** Accepted (2026-09-26). Its second point is superseded the same day by [D006](#d006--x): the Number is the tower, and D001 stands.
- Its rule that ranks are uncapped is superseded by [D005](#d005--x) and its name by D004 (2026-09-23).
'''


class DecisionIndexTests(unittest.TestCase):
    def test_ids_are_unique_and_in_order(self):
        ids = [entry[0] for entry in index.parse()]
        self.assertEqual(len(ids), len(set(ids)), 'two decisions share an ID: renumber one (python3 tools/decisions_index.py --next)')
        self.assertEqual(ids, sorted(ids), 'decisions are out of order in DECISIONS.md')

    def test_every_decision_has_a_status(self):
        missing = [entry[0] for entry in index.parse() if not entry[2]]
        self.assertEqual(missing, [], 'records without a "- **Status:**" line near the top')

    def test_the_committed_index_is_current(self):
        self.assertEqual((ROOT / 'docs/DECISIONS_INDEX.md').read_text(), index.render(index.parse()),
                         'docs/DECISIONS_INDEX.md is out of date: run python3 tools/decisions_index.py')

    def test_parsing_status_supersession_and_the_next_id(self):
        found = index.parse(SAMPLE)
        self.assertEqual([entry[0] for entry in found], ['D001', 'D002', 'D004', 'D005', 'D006', 'D007'])
        self.assertEqual(found[0][2], 'Accepted')
        self.assertEqual(found[0][3], 'D002')
        self.assertEqual(found[1][2], 'Accepted')
        self.assertEqual(found[2][3], 'D002 (in part)')
        self.assertEqual(index.next_id(found), 'D008')
        self.assertEqual(found[3][2], '', 'a record without a status must not borrow the next one\'s')
        self.assertEqual(found[5][2:], ('Accepted', 'D006 D005 D004'), 'the wording D079 and D015 use, and not a decision merely mentioned after a colon')
        self.assertIn('Second / with a bar', index.render(found), 'a pipe in a title would break the table')


if __name__ == '__main__':
    unittest.main()
