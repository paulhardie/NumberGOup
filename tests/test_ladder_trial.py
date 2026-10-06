"""The earned digit ladder's criteria (D163) are code, so they are tested: each has to
fail at its boundary, and one whose runs weren't played must not read as a pass."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('ladder_trial', TOOLS / 'ladder_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)


def cell(earned=2000.0, peak=100.0, count=6):
    return {'runs': [{'case': 'run', 'seed': i + 1, 'run': 0, 'cash': earned, 'peak_number': peak, 'coins': 100.0} for i in range(count)]}


def career(arrivals=None, coins=100.0, wave_30=40, runs=50, scale=1.0):
    """A career whose digits arrive on the given runs, earning `coins` a run: each run's
    Number earned and peak are set so both ladders reach the same digits on the same runs."""
    arrivals = arrivals if arrivals is not None else {10.0: 1, 100.0: 5, 1000.0: 30}
    out, level = [], 1.0
    for index in range(1, runs + 1):
        digits = [d for d, at in arrivals.items() if at == index]
        level = max([level] + digits)
        out.append({'case': 'career', 'seed': index, 'run': index, 'coins': coins, 'cash': level, 'peak_number': level,
                    'wave': 30 if index >= wave_30 else 10, 'digits': digits,
                    'digits_paid': sum(trial.DIGITS[d] * scale for d in digits)})
    return {'runs': out}


def passing(scale=1.0):
    out = {}
    for b in trial.BUDGETS:
        for p in trial.PLANS:
            out[f'cell.buy_{b}_{p}'] = cell(earned={10000: 2000.0, 100000: 5000.0, 1000000: 20000.0}[b])
    for prefix in ('ctrl', trial.name(scale)):
        for policy in trial.CAREERS:
            out[f'{prefix}.career_{policy}'] = career(scale=1.0 if prefix == 'ctrl' else scale)
    return out


class LadderCriteriaTests(unittest.TestCase):
    def verdicts(self, results, scale=1.0):
        return {n: found['pass'] for n, found in trial.evaluate(results, scale).items()}

    def test_the_passing_set_passes_every_criterion(self):
        self.assertEqual(self.verdicts(passing()), {n: True for n in range(1, 6)})

    def test_without_careers_only_reachability_is_read(self):
        results = passing()
        del results['x1.career_grow']
        self.assertEqual(set(trial.evaluate(results, 1.0)), {1})
        _, overall = trial.render((1.0,), results)
        self.assertEqual(overall['x1'], 'NOT COMPLETE')

    def test_the_control_is_read_by_its_peak(self):
        results = passing()
        self.assertFalse(self.verdicts(results, None)[1], 'peaks of 100 reach no digit 1,000')

    def test_reachable_with_a_long_goal_left(self):
        results = passing()
        results['cell.buy_10000_turtle'] = cell(earned=999.0)
        self.assertFalse(self.verdicts(results)[1])
        results = passing()
        results['cell.buy_1000000_core'] = cell(earned=9999.0)
        self.assertFalse(self.verdicts(results)[1])
        results = passing()
        results['cell.buy_100000_core']['runs'][0]['cash'] = 1000000.0
        self.assertFalse(self.verdicts(results)[1], 'a run reaching the last digit leaves no long goal')

    def test_the_first_digits_come_early(self):
        results = passing()
        results['x1.career_core'] = career({10.0: 1, 100.0: 11, 1000.0: 30})
        self.assertFalse(self.verdicts(results)[2], 'digit 100 on run 11 is late')
        results['x1.career_core'] = career({10.0: 1, 100.0: 10})
        self.assertFalse(self.verdicts(results)[2], 'and 1,000 must come within the 50')
        results['x1.career_core'] = career({10.0: 1, 100.0: 10, 1000.0: 50})
        self.assertTrue(self.verdicts(results)[2])

    def test_the_share_is_real_but_minor(self):
        results = passing()
        results['x1.career_core'] = career(coins=2.0)
        self.assertFalse(self.verdicts(results)[3], '310 of 410 Coins is far over a fifth')
        results['x1.career_core'] = career(coins=300.0)
        self.assertFalse(self.verdicts(results)[3], '310 of 15,310 is under 3%')

    def test_no_digit_may_dominate_its_run(self):
        results = passing()
        results['x1.career_grow']['runs'][4]['coins'] = 16.0
        self.assertFalse(self.verdicts(results)[4], 'digit 100 pays 50 for a 16-Coin run: over 3 times')
        results['x1.career_grow']['runs'][4]['coins'] = 16.7
        self.assertTrue(self.verdicts(results)[4], '50 for 16.7 is under 3 times')
        results = passing(0.5)
        results['x0.5.career_grow']['runs'][4]['coins'] = 8.0
        self.assertFalse(self.verdicts(results, 0.5)[4], 'at half, digit 100 pays 25: over 3 times 8')
        results['x0.5.career_grow']['runs'][4]['coins'] = 9.0
        self.assertTrue(self.verdicts(results, 0.5)[4])
        results['x0.5.career_grow']['runs'][0]['coins'] = 0.5
        self.assertTrue(self.verdicts(results, 0.5)[4], 'the first digit, 10, is exempt')

    def test_the_early_game_is_not_rushed(self):
        results = passing()
        results['x1.career_core'] = career(wave_30=31)
        self.assertFalse(self.verdicts(results)[5], 'run 31 is earlier than 0.8 of the control\'s 40')
        results['x1.career_core'] = career(wave_30=32)
        self.assertTrue(self.verdicts(results)[5])
        results['x1.career_core'] = career(wave_30=99)
        self.assertTrue(self.verdicts(results)[5], 'never reaching it is not rushing it')

    def test_recorded_digits_must_match_the_reading(self):
        results = passing()
        results['x1.career_core']['runs'][4]['digits'] = []
        with self.assertRaises(ValueError):
            trial.evaluate(results, 1.0)

    def test_the_plan_is_the_declared_one(self):
        runs = trial.plan()
        self.assertEqual(len(runs), 6 + 2 * 3)
        self.assertNotIn('ladder', runs['ctrl.career_core'])
        self.assertEqual((runs['x0.5.career_grow']['ladder'], runs['x0.5.career_grow']['ladder-scale']), ('earned', 0.5))
        self.assertEqual({runs[f'ctrl.career_{p}']['careers'] for p in trial.CAREERS}, {50}, 'equal horizons')
        self.assertEqual(runs['cell.buy_1000000_turtle']['seeds'], 4)
        _, overall = trial.render((0.7,), passing(0.7))
        self.assertEqual(overall['x0.7'], 'EXPLORATORY')


if __name__ == '__main__':
    unittest.main()
