"""The top-down battle's criteria (D167) are code, so they are tested: each has
to fail at its boundary, and one whose runs weren't played must not read as a pass."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('topdown_trial', TOOLS / 'topdown_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)


def cell(wave=30, count=6, seconds=600.0, stop='death', top=False):
    return {'runs': [{'case': 'run', 'seed': i + 1, 'run': 0, 'wave': wave, 'game_seconds': seconds, 'stop': stop, 'coins': 100.0,
                      'start': {'tuning': {'top_down': True} if top else {}},
                      'damage_by': {'shot': 90.0, 'orb': 10.0}, 'lost_to': {'basic': 5.0, 'ranged': 15.0}} for i in range(count)]}


def career(wave_30=40, runs=50):
    return {'runs': [{'case': 'career', 'seed': i, 'run': i, 'wave': 30 if i >= wave_30 else 12, 'game_seconds': 600.0, 'stop': 'death',
                      'coins': 50.0, 'damage_by': {}, 'lost_to': {}} for i in range(1, runs + 1)]}


def passing():
    out = {}
    for way in trial.WAYS:
        out[f'{way}.fresh_none'] = cell(wave=4, count=20, seconds=120.0)
        for budget in trial.BUDGETS:
            for plan in trial.PLANS:
                out[f'{way}.buy_{budget}_{plan}'] = cell(wave=30 if budget == 10000 else 50)
        for policy, runs in trial.CAREERS.items():
            out[f'{way}.career_{policy}'] = career(runs=runs)
    return out


class TopDownCriteriaTests(unittest.TestCase):
    def verdicts(self, results):
        return {number: found['pass'] for number, found in trial.evaluate(results).items()}

    def test_the_passing_set_passes_every_criterion(self):
        self.assertEqual(self.verdicts(passing()), {1: True, 2: True, 3: True})
        self.assertEqual(trial.render(passing())[1], 'PASS')

    def test_a_criterion_without_its_runs_is_not_run(self):
        results = passing()
        del results['round.buy_100000_blender']
        self.assertEqual(set(trial.evaluate(results)), {1, 3})
        self.assertEqual(trial.render(results)[1], 'NOT COMPLETE')

    def test_the_first_minutes_end_by_wave_5_inside_180_seconds(self):
        results = passing()
        results['top.fresh_none'] = cell(wave=6, count=20, seconds=120.0)
        self.assertFalse(self.verdicts(results)[1], 'wave 6 is too late')
        results['top.fresh_none'] = cell(wave=5, count=20, seconds=180.5)
        self.assertFalse(self.verdicts(results)[1], 'and so is 180.5 s')
        results['top.fresh_none'] = cell(wave=5, count=20, seconds=180.0, stop='time_cap')
        self.assertFalse(self.verdicts(results)[1], 'a tower that never died is not a death')
        results['top.fresh_none'] = cell(wave=5, count=20, seconds=180.0)
        self.assertTrue(self.verdicts(results)[1])

    def test_workshop_cells_stay_within_a_fifth(self):
        results = passing()
        results['top.buy_10000_turtle'] = cell(wave=37)
        self.assertFalse(self.verdicts(results)[2], '37 against 30 is over 20%')
        results['top.buy_10000_turtle'] = cell(wave=36)
        self.assertTrue(self.verdicts(results)[2], '36 against 30 is exactly 20%')
        results['top.buy_10000_turtle'] = cell(wave=23)
        self.assertFalse(self.verdicts(results)[2], 'and 23 is under')

    def test_careers_stay_within_a_quarter_and_never_against_never_passes(self):
        results = passing()
        results['top.career_core'] = career(wave_30=51)
        self.assertFalse(self.verdicts(results)[3], 'run 51 against 40 is over 25%')
        results['top.career_core'] = career(wave_30=50)
        self.assertTrue(self.verdicts(results)[3], 'run 50 is exactly 25%')
        results['top.career_core'] = career(wave_30=99)
        self.assertFalse(self.verdicts(results)[3], 'never against run 40 fails')
        results['round.career_core'] = career(wave_30=99)
        self.assertTrue(self.verdicts(results)[3], 'never against never passes')

    def test_the_plan_plays_both_ways_on_the_same_cells(self):
        runs = trial.plan()
        self.assertEqual(len(runs), 2 * (1 + len(trial.BUDGETS) * len(trial.PLANS) + len(trial.CAREERS)))
        self.assertNotIn('top-down', runs['round.career_core'])
        self.assertEqual(runs['top.career_core']['top-down'], 'true')
        self.assertEqual({k: v for k, v in runs['top.buy_100000_turtle'].items() if k != 'top-down'}, runs['round.buy_100000_turtle'])
        self.assertEqual(runs['round.career_grow']['careers'], 70)

    def test_a_run_that_played_the_other_battle_is_an_error(self):
        results = {'top.buy_10000_core': cell(top=True), 'round.buy_10000_core': cell()}
        trial.check_ways(results)
        results['top.buy_10000_core'] = cell()
        with self.assertRaises(ValueError):
            trial.check_ways(results)
        results = {'round.buy_10000_core': cell(top=True)}
        with self.assertRaises(ValueError):
            trial.check_ways(results)

    def test_the_report_is_shares_beside_the_criteria(self):
        report = trial.reported(passing())
        self.assertEqual(report['buy_10000_core']['top']['damage_by'], {'shot': 0.9, 'orb': 0.1})
        self.assertEqual(set(trial.evaluate(passing())), {1, 2, 3}, 'never a criterion itself')


if __name__ == '__main__':
    unittest.main()
