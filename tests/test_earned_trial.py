"""The earned-Coins criteria (D162) are code, so they are tested: each has to fail at
its boundary, and one whose runs weren't played must not read as a pass."""
import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location('earned_trial', TOOLS / 'earned_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)

PREFIX = trial.name(0.5, 1.0)
TIER_COINS = {'tier1': 100.0, 'tier2': 180.0, 'tier3': 260.0}


def result(coins=100.0, cash=1000.0, seconds=600.0, count=6, interest=0.0, case='run'):
    return {'runs': [{'case': case, 'seed': index + 1, 'run': 0, 'coins': coins, 'cash': cash, 'game_seconds': seconds,
                      'gained_from': {'kill_cash': cash * (1.0 - interest), 'wave_cash': 0.0, 'interest': cash * interest}}
                     for index in range(count)]}


def one(cell):
    """What a control reads in a cell, and what a configuration that changes nothing reads."""
    if cell in TIER_COINS:
        return result(coins=TIER_COINS[cell], count=2)
    if cell.startswith('career_'):
        return result(coins=200.0 if cell == 'career_grow' else 100.0, count=50, case='career')
    if cell.startswith('fresh_'):
        return result(coins=10.0, cash=100.0, count=20)
    return result()


def passing():
    out = {}
    for cell in trial.cells():
        out[f'ctrl.{cell}'] = one(cell)
        out[f'{PREFIX}.{cell}'] = one(cell)
    return out


class EarnedCriteriaTests(unittest.TestCase):
    def verdicts(self, results):
        return {number: found['pass'] for number, found in trial.evaluate(results, PREFIX).items()}

    def test_the_passing_set_passes_every_criterion(self):
        self.assertEqual(self.verdicts(passing()), {number: True for number in range(1, 8)})

    def test_a_criterion_without_its_runs_is_not_run(self):
        results = passing()
        del results[f'{PREFIX}.off_1000000_turtle']
        out = trial.evaluate(results, PREFIX)
        self.assertNotIn(2, out)
        self.assertNotIn(3, out)
        self.assertNotIn(7, out)
        self.assertIn(1, out)
        _, overall = trial.render(((0.5, 1.0),), results)
        self.assertEqual(overall[PREFIX], 'NOT COMPLETE')

    def test_the_pace_stays_within_a_quarter(self):
        results = passing()
        results[f'{PREFIX}.buy_10000_core'] = result(coins=126.0)
        self.assertFalse(self.verdicts(results)[1])
        results[f'{PREFIX}.buy_10000_core'] = result(coins=75.0)
        self.assertTrue(self.verdicts(results)[1], 'a quarter down is still within it')
        results[f'{PREFIX}.buy_10000_core'] = result(coins=74.0)
        self.assertFalse(self.verdicts(results)[1])

    def test_a_hair_outside_a_limit_fails_rounding_never_rescues_it(self):
        results = passing()
        results[f'{PREFIX}.buy_10000_core'] = result(coins=125.049)
        self.assertFalse(self.verdicts(results)[1], '25.049% over is outside 25%, however it is displayed')
        results = passing()
        results[f'{PREFIX}.off_100000_core'] = result(coins=110.04)
        self.assertFalse(self.verdicts(results)[2], '10.04% off is outside 10%')
        results = passing()
        results[f'{PREFIX}.off_10000_turtle'] = result(seconds=857.2)
        self.assertFalse(self.verdicts(results)[3], 'a rate of 0.6999 is under 0.70')
        results = passing()
        results[f'{PREFIX}.tier2'] = result(coins=180.0 * 1.1501, count=2)
        self.assertFalse(self.verdicts(results)[4], '15.01% off the control\'s tier ratio is outside 15%')
        results = passing()
        results[f'{PREFIX}.buy_10000_core']['runs'][0]['coins'] = 150.01
        self.assertFalse(self.verdicts(results)[7], 'a run a hair over 1.5 times its control')

    def test_spenders_and_hoarders_are_paid_by_the_same_measure(self):
        results = passing()
        results[f'{PREFIX}.off_100000_core'] = result(coins=115.0)
        self.assertFalse(self.verdicts(results)[2], '15% more Coins per Number earned off than buying')
        results[f'{PREFIX}.off_100000_core'] = result(coins=109.0)
        self.assertTrue(self.verdicts(results)[2])

    def test_run_upgrades_off_is_neither_a_handicap_nor_dominant(self):
        results = passing()
        results[f'{PREFIX}.off_10000_turtle'] = result(seconds=870.0)
        self.assertFalse(self.verdicts(results)[3], 'a rate of 0.69 of buying')
        results[f'{PREFIX}.off_10000_turtle'] = result(seconds=800.0)
        self.assertTrue(self.verdicts(results)[3])
        results[f'{PREFIX}.off_10000_turtle'] = result(seconds=400.0)
        self.assertFalse(self.verdicts(results)[3], 'a rate of 1.5 of buying')

    def test_the_tier_ratio_must_hold(self):
        results = passing()
        results[f'{PREFIX}.tier2'] = result(coins=216.0, count=2)
        self.assertFalse(self.verdicts(results)[4], 'tier 2 over tier 1 is 20% off the control\'s')
        results[f'{PREFIX}.tier2'] = result(coins=198.0, count=2)
        self.assertTrue(self.verdicts(results)[4], '10% off is within it')

    def test_the_coin_rows_must_still_matter(self):
        results = passing()
        results[f'{PREFIX}.career_grow'] = result(coins=120.0, count=50, case='career')
        self.assertFalse(self.verdicts(results)[5])
        results[f'{PREFIX}.career_grow'] = result(coins=125.0, count=50, case='career')
        self.assertTrue(self.verdicts(results)[5], 'exactly 1.25 passes')

    def test_the_early_game_holds(self):
        results = passing()
        results[f'{PREFIX}.fresh_none'] = result(coins=3.0, cash=100.0, count=20)
        self.assertFalse(self.verdicts(results)[6], 'less than half of 10')
        results[f'{PREFIX}.fresh_none'] = result(coins=0.0, cash=100.0, count=20)
        self.assertFalse(self.verdicts(results)[6], 'none is zero')
        results[f'{PREFIX}.fresh_none'] = result(coins=14.0, cash=100.0, count=20)
        self.assertTrue(self.verdicts(results)[6])
        results[f'ctrl.fresh_none'] = result(coins=4.0, cash=100.0, count=20)
        results[f'{PREFIX}.fresh_none'] = result(coins=6.0, cash=100.0, count=20)
        self.assertTrue(self.verdicts(results)[6], 'a small control allows 2 Coins')
        results[f'{PREFIX}.fresh_none'] = result(coins=6.01, cash=100.0, count=20)
        self.assertFalse(self.verdicts(results)[6])

    def test_no_run_may_run_away_from_its_own_control(self):
        results = passing()
        runs = results[f'{PREFIX}.buy_10000_core']['runs']
        runs[0]['coins'] = 151.0
        self.assertFalse(self.verdicts(results)[7], 'a run 51% over its same-seed control')
        runs[0]['coins'] = 149.0
        self.assertTrue(self.verdicts(results)[7])
        results = passing()
        results['ctrl.fresh_none'] = result(coins=4.0, cash=100.0, count=20)
        results[f'{PREFIX}.fresh_none'] = result(coins=6.0, cash=100.0, count=20)
        self.assertTrue(self.verdicts(results)[7], 'a small control allows 2 Coins')
        results[f'{PREFIX}.fresh_none']['runs'][3]['coins'] = 6.5
        self.assertFalse(self.verdicts(results)[7])

    def test_interest_stays_a_minor_part_of_the_income(self):
        results = passing()
        results[f'{PREFIX}.buy_100000_core'] = result(interest=0.3)
        self.assertFalse(self.verdicts(results)[7])
        results[f'{PREFIX}.buy_100000_core'] = result(interest=0.2)
        self.assertTrue(self.verdicts(results)[7])

    def test_a_run_without_its_control_is_an_error_not_a_pass(self):
        results = passing()
        results[f'{PREFIX}.buy_10000_core']['runs'][0]['seed'] = 99
        with self.assertRaises(ValueError):
            trial.evaluate(results, PREFIX)

    def test_another_configuration_is_exploratory(self):
        results = passing()
        _, overall = trial.render(((0.3, 1.0),), {k.replace(PREFIX, trial.name(0.3, 1.0)): v for k, v in results.items()})
        self.assertEqual(overall[trial.name(0.3, 1.0)], 'EXPLORATORY')

    def test_the_declared_grid_is_all_six_and_all_pass_a_complete_set(self):
        self.assertEqual(len(trial.GRID), 6)
        _, overall = trial.render(((0.5, 1.0),), passing())
        self.assertEqual(overall[PREFIX], 'PASS')

    def test_the_post_hoc_reading_uses_equal_horizons_and_never_changes_a_verdict(self):
        results = passing()
        for cell, coins_each in (('career_core', 100.0), ('career_grow', 40.0)):
            for who in ('ctrl', PREFIX):
                runs = [{'case': 'career', 'seed': i + 1, 'run': i + 1, 'coins': coins_each if i < 50 else 1000.0, 'cash': 100.0,
                         'game_seconds': 600.0} for i in range(trial.CAREER_RUNS[cell.split('_')[1]])]
                results[f'{who}.{cell}'] = {'runs': runs}
        extra = trial.post_hoc(results, PREFIX)
        self.assertEqual(extra['horizon'], 50)
        self.assertAlmostEqual(extra['grow_over_core_median'], 0.4, msg='the 20 later grow runs are left out, so the median is 40 over 100')
        self.assertAlmostEqual(extra['grow_over_core_total'], 0.4)
        self.assertAlmostEqual(extra['worst_run_over_limit']['core'], 100.0 / 150.0)
        self.assertTrue(set(trial.evaluate(results, PREFIX)) <= set(range(1, 8)), 'it is reported beside the criteria, never one of them')
        del results[f'{PREFIX}.career_grow']
        self.assertIsNone(trial.post_hoc(results, PREFIX), 'without its runs it reads nothing, not a number')

    def test_an_exploratory_configuration_is_added_never_in_place_of_the_grid(self):
        self.assertEqual(trial.chosen(None), trial.GRID)
        self.assertEqual(trial.chosen([(0.3, 1.0)]), trial.GRID + ((0.3, 1.0),))
        self.assertEqual(trial.chosen([(0.5, 1.0)]), trial.GRID, 'a declared configuration asked for again is not doubled')

    def test_the_calibration_and_the_plan_are_the_declared_ones(self):
        self.assertAlmostEqual(trial.scale(1.0), 420.5 / 3950.5)
        self.assertAlmostEqual(trial.scale(0.8) * 3950.5 ** 0.8, 420.5, places=6)
        runs = trial.plan()
        self.assertEqual(len(runs), 20 * (1 + len(trial.GRID)))
        control = runs['ctrl.buy_100000_core']
        self.assertNotIn('earned-share', control)
        self.assertEqual(control['seeds'], 6)
        self.assertEqual(control['reserve'], 0.5)
        self.assertEqual(control['number-cash'], 'true')
        self.assertEqual(runs['ctrl.buy_1000000_turtle']['seeds'], 4)
        self.assertEqual(runs['ctrl.off_1000000_turtle']['upgrades-off'], 'true')
        self.assertEqual(runs['ctrl.fresh_even']['seeds'], 20)
        self.assertEqual((runs['ctrl.career_core']['careers'], runs['ctrl.career_grow']['careers']), (50, 70), "the harness's career horizons")
        self.assertEqual(runs['ctrl.tier3']['tier'], 3)
        chosen = runs[f'{trial.name(0.25, 0.8)}.buy_100000_core']
        self.assertEqual((chosen['earned-share'], chosen['earned-power'], float(chosen['earned-scale'])), (0.25, 0.8, trial.scale(0.8)))


if __name__ == '__main__':
    unittest.main()
