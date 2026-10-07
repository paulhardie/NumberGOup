"""The patrol-line orbs' criterion (D168) is code, so it is tested: it fails at
its boundary, reads NOT RUN without all its runs, and refuses a run that didn't
play the orbs it was meant to."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('orbline_trial', TOOLS / 'orbline_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)


def cell(wave=80, line=False, top=True):
    tuning = dict({'top_down': True} if top else {}, **({'orb_line': True} if line else {}))
    return {'runs': [{'case': 'run', 'seed': i + 1, 'run': 0, 'wave': wave, 'game_seconds': 600.0, 'stop': 'death', 'coins': 100.0,
                      'start': {'tuning': tuning}, 'damage_by': {'shot': 80.0, 'orb': 20.0}, 'lost_to': {}} for i in range(6)]}


def results(line_wave=80, circle_wave=80):
    return {f'{way}.{name}': cell(line_wave if way == 'line' else circle_wave, way == 'line') for way in trial.WAYS for name in trial.cells()}


class OrbLineCriteriaTests(unittest.TestCase):
    def test_every_cell_plays_top_down_and_only_the_line_way_records_the_line(self):
        for name, options in trial.plan().items():
            self.assertEqual(options['top-down'], 'true', name)
            self.assertEqual('orb-line' in options, name.startswith('line.'), name)
            self.assertEqual(options['seeds'], 6, name)

    def test_within_twenty_percent_passes_and_just_past_it_fails(self):
        self.assertTrue(trial.evaluate(results(96, 80))[1]['pass'])
        self.assertTrue(trial.evaluate(results(64, 80))[1]['pass'])
        self.assertFalse(trial.evaluate(results(97, 80))[1]['pass'])
        self.assertFalse(trial.evaluate(results(63, 80))[1]['pass'])

    def test_one_missing_cell_reads_not_run(self):
        partial = results()
        partial.pop(f'line.{next(iter(trial.cells()))}')
        self.assertEqual(trial.evaluate(partial), {})
        self.assertEqual(trial.render(partial)[1], 'NOT RUN')

    def test_a_run_that_played_the_wrong_orbs_is_refused(self):
        wrong = results()
        name = next(iter(trial.cells()))
        wrong[f'line.{name}'] = cell(line=False)
        with self.assertRaises(ValueError):
            trial.check_ways(wrong)
        round_battle = results()
        round_battle[f'circle.{name}'] = cell(top=False)
        with self.assertRaises(ValueError):
            trial.check_ways(round_battle)
        trial.check_ways(results())

    def test_the_orbs_share_is_reported_beside_the_criterion(self):
        text, state = trial.render(results())
        self.assertEqual(state, 'PASS')
        self.assertIn('orb share 0.2', text)


if __name__ == '__main__':
    unittest.main()
