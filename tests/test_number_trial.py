"""The trial's pass criteria are code, so they are tested: a criterion has to
fail at its boundary, and one whose runs weren't played must not read as a pass."""
import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location('number_trial', Path(__file__).resolve().parents[1] / 'tools/number_trial.py')
trial = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trial)

BASELINE = {'fresh': {'none': 3, 'even': 6, 'core': 3}, 'career_first_31': 47, 'turtle_100k_peak': 2820.0}
CELLS = [(budget, build) for budget in trial.BUDGETS for build in trial.BUILDS]


def result(waves, case='run', peak=100.0, thefts=None, taken=None, back=None, runs=None):
    rows = []
    for index, wave in enumerate(waves):
        row = {'case': case, 'seed': index + 1, 'run': runs[index] if runs else 0, 'wave': wave, 'peak_number': peak}
        if thefts is not None:
            row.update({'thefts': thefts, 'thief_taken': taken, 'thief_recovered': back})
        rows.append(row)
    return {'runs': rows}


def build_results(costs=None, ledger=None):
    """Every build-phase run, each at wave 30 unless `costs` moves it: how many
    waves the candidate has over each variant, per (kind, budget, build)."""
    costs = costs or {}
    ledger = ledger or {}
    out = {}
    for budget, build in CELLS:
        taken, back = ledger.get((budget, build), (100.0, 40.0 if budget == 10000 else 95.0))
        out[f'on_{budget}_{build}'] = result([30] * 4, thefts=5, taken=taken, back=back)
        for kind in ('nopower', 'norecovery', 'nodividers'):
            out[f'{kind}_{budget}_{build}'] = result([30 + costs.get((kind, budget, build), 0)] * 4)
    return out


class TrialCriteriaTests(unittest.TestCase):
    def test_a_criterion_without_its_runs_is_not_run_not_a_pass(self):
        out = trial.evaluate({}, BASELINE)
        self.assertEqual(out, {})
        text, overall = trial.render(trial.CENTRE, out)
        self.assertIn('C1 NOT RUN', text)
        self.assertEqual(overall, 'NOT COMPLETE')

    def test_the_number_has_to_decide_something_in_every_build_at_both_budgets(self):
        # The candidate is ahead of its variants, so the variants have fewer waves.
        every = {(kind, budget, build): -2 for kind in ('nopower', 'norecovery') for budget, build in CELLS}
        self.assertTrue(trial.evaluate(build_results(every), BASELINE)[1]['pass'])
        short = {**every, ('nopower', 10000, 'core'): -1}
        self.assertFalse(trial.evaluate(build_results(short), BASELINE)[1]['pass'], 'a lever one wave short in one cell')
        one_cell = {**{('nopower', budget, build): -2 for budget, build in CELLS}, ('norecovery', 100000, 'turtle'): -2}
        found = trial.evaluate(build_results(one_cell), BASELINE)[1]
        self.assertFalse(found['pass'], 'recovery that matters in one cell does not pass for all four')
        self.assertIn('a pass', found['detail'], 'though the looser one-build reading would have passed, and the report says so')

    def test_the_problem_is_real_at_10k_and_solved_at_100k_for_both_builds(self):
        good = {('nodividers', 10000, 'core'): 2, ('nodividers', 10000, 'turtle'): 3,
                ('nodividers', 100000, 'core'): 1, ('nodividers', 100000, 'turtle'): 0}
        self.assertTrue(trial.evaluate(build_results(good), BASELINE)[2]['pass'])
        only_core = {**good, ('nodividers', 10000, 'turtle'): 1}
        self.assertFalse(trial.evaluate(build_results(only_core), BASELINE)[2]['pass'])
        never_solved = {**good, ('nodividers', 100000, 'core'): 2}
        self.assertFalse(trial.evaluate(build_results(never_solved), BASELINE)[2]['pass'])

    def test_the_dead_cards_have_to_gain_a_wave_each(self):
        def sweep(gain_health, gain_regen, gain_damage=10):
            rows = result([20] * 10, case='no_card')['runs'] + result([20 + gain_health] * 10, case='health')['runs'] \
                + result([20 + gain_regen] * 10, case='health_regen')['runs'] + result([20 + gain_damage] * 10, case='damage')['runs']
            return {'runs': rows}
        good = {f'cards_{name}': sweep(0, 0) for name, _, _ in trial.CARD_BUILDS}
        good['cards_turtle'] = sweep(1, 1)
        found = trial.evaluate(good, BASELINE)[3]
        self.assertTrue(found['pass'])
        self.assertIn("share of the Damage card's gain", found['detail'])
        self.assertIn("'health': {'early': 0.0, 'turtle': 0.1, 'later': 0.0}", found['detail'], 'the ratio to the Damage card is reported')
        good['cards_turtle'] = sweep(1, 0)
        self.assertFalse(trial.evaluate(good, BASELINE)[3]['pass'])
        good['cards_turtle'] = sweep(0, 0, gain_damage=30)
        self.assertFalse(trial.evaluate(good, BASELINE)[3]['pass'], 'the Damage card is the yardstick, not what passes')

    def test_no_runaway_means_a_career_window_and_a_capped_number(self):
        def run_for(first, peak):
            career = result([40 if run >= first else 20 for run in range(1, 51)], runs=list(range(1, 51)))
            return {'career': career, 'on_100000_turtle': result([80] * 4, peak=peak)}
        self.assertTrue(trial.evaluate(run_for(35, 8460.0), BASELINE)[4]['pass'])
        self.assertFalse(trial.evaluate(run_for(34, 2820.0), BASELINE)[4]['pass'], 'a career that is too fast')
        self.assertFalse(trial.evaluate(run_for(61, 2820.0), BASELINE)[4]['pass'], 'and one that is too slow')
        self.assertFalse(trial.evaluate(run_for(47, 8461.0), BASELINE)[4]['pass'], 'and a Number three times too big')
        never = {'career': result([20] * 50, runs=list(range(1, 51))), 'on_100000_turtle': result([80] * 4)}
        self.assertFalse(trial.evaluate(never, BASELINE)[4]['pass'], 'never reaching wave 31 is not a pass')

    def test_the_early_game_holds_within_one_wave(self):
        def fresh(none, even, core):
            return {'fresh_none': result([none] * 20), 'fresh_even': result([even] * 20), 'fresh_core': result([core] * 20)}
        self.assertTrue(trial.evaluate(fresh(4, 5, 3), BASELINE)[5]['pass'])
        self.assertFalse(trial.evaluate(fresh(5, 6, 3), BASELINE)[5]['pass'])

    def test_the_ledger_has_to_show_a_weak_start_and_a_solved_late_game(self):
        self.assertTrue(trial.evaluate(build_results(), BASELINE)[6]['pass'])
        strong_early = {(10000, 'core'): (100.0, 60.0)}
        self.assertFalse(trial.evaluate(build_results(ledger=strong_early), BASELINE)[6]['pass'], 'recovering most of it at 10K')
        weak_late = {(100000, 'turtle'): (100.0, 80.0)}
        self.assertFalse(trial.evaluate(build_results(ledger=weak_late), BASELINE)[6]['pass'], 'and under 90% at 100K')
        unrobbed = {(10000, 'turtle'): (0.0, 0.0)}
        self.assertFalse(trial.evaluate(build_results(ledger=unrobbed), BASELINE)[6]['pass'], 'a build nothing steals from has no ledger to read')

    def test_the_plan_plays_the_harness_scenarios_with_the_right_stand_ins(self):
        config = dict(trial.CENTRE, r_base=0.25, r_max=1.0)
        plan = trial.build_plan(config)
        self.assertEqual(len(plan), 16)
        self.assertEqual(plan['on_10000_core']['thief-recovery'], 0.25)
        self.assertEqual(plan['on_100000_turtle']['thief-recovery'], 1.0)
        self.assertNotIn('number-power', plan['nopower_10000_core'])
        self.assertEqual(plan['norecovery_100000_core']['thief-recovery'], 0.0)
        self.assertEqual(plan['norecovery_100000_core']['number-power'], config['power'])
        self.assertNotIn('thieves', plan['nodividers_10000_core'])
        self.assertEqual(plan['nodividers_10000_core']['divider-share'], 0)
        for name, spec in plan.items():
            self.assertEqual((spec['seeds'], spec['buy'], spec['cap-minutes']), (4, 'core', 180), name)
        slow = trial.slow_plan(config)
        self.assertEqual(slow['career']['careers'], 50)
        self.assertEqual(slow['fresh_none']['seeds'], 20)
        self.assertEqual(slow['cards_later']['workshop-coins'], 40000)
        self.assertTrue(all(spec['thief-recovery'] == 0.25 for spec in slow.values()))

    def test_an_exploratory_run_is_never_a_pass(self):
        every_criterion = {number: trial.verdict(True, 'ok') for number in range(1, 7)}
        text, overall = trial.render(trial.CENTRE, every_criterion)
        self.assertEqual(overall, 'PASS')
        text, overall = trial.render(dict(trial.CENTRE, extra={'divider-share': '3'}), every_criterion)
        self.assertEqual(overall, 'EXPLORATORY')
        self.assertIn('cannot count as a pass', text)

    def test_extra_options_reach_every_run_but_a_runs_own_win(self):
        config = dict(trial.CENTRE, extra={'divider-share': '3', 'divider-health': '2'})
        plan = trial.build_plan(config)
        self.assertEqual(plan['on_10000_core']['divider-share'], '3')
        self.assertEqual(plan['nodividers_10000_core']['divider-share'], 0, 'the no-Dividers reference stays without them')
        self.assertEqual(plan['norecovery_10000_core']['divider-health'], '2')
        self.assertTrue(all(spec['divider-health'] == '2' for spec in trial.slow_plan(config).values()))

    def test_the_committed_baseline_has_what_the_criteria_are_written_against(self):
        found = trial.committed_baseline()
        self.assertEqual(set(found['fresh']), {'none', 'even', 'core'})
        self.assertGreater(found['career_first_31'], 0)
        self.assertGreater(found['turtle_100k_peak'], 0)


if __name__ == '__main__':
    unittest.main()
