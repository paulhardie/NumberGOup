"""Reporting contracts: broken measurements must not look like good balance."""
import copy
import importlib.util
from pathlib import Path
import tempfile
import subprocess
import re
import json
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('balance_report', Path(__file__).resolve().parents[1] / 'tools/balance_report.py')
balance = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(balance)


def snapshot(suite='quick'):
    scenarios = []
    for spec in balance.scenarios(suite):
        options = spec['options']
        cases = ['career'] if 'careers' in options else ['no_card', 'health', 'coins'] if 'card-sweep' in options else ['run']
        rows = []
        for case in cases:
            for index in range(1, options.get('careers', options.get('seeds')) + 1):
                rows.append({'case': case, 'seed': index, 'run': index if case == 'career' else 0,
                             'wave': 3, 'game_seconds': 80.0, 'kills': 2, 'coins': 10.0, 'cash': 20.0,
                             'peak_number': 10.0, 'stop': 'death', 'killed_by': 'basic', 'reached': {},
                             'start': {}, 'dividers_spawned': 0, 'dividers_landed': 0,
                             'lost_to': {'basic': 10.0}, 'damage_by': {'shot': 8.0}, 'permanent_rewards': 0.0})
        measurement = {'schema': 1, 'engine': 'test', 'data_signature': 'test', 'built_cards': ['health', 'coins'], 'runs': rows}
        scenarios.append(dict(spec, measurement=measurement))
    return {'schema': 1, 'suite': suite, 'provenance': {'commit': 'test', 'dirty': False, 'source_sha256': 'test'}, 'scenarios': scenarios}


class BalanceReportingTests(unittest.TestCase):
    def test_same_results_have_no_movement_but_known_failures_are_visible(self):
        data = snapshot('full')
        text, changed = balance.render(data, copy.deepcopy(data))
        self.assertFalse(changed)
        self.assertIn('FAIL:** D149 level-7 health [known failure; still fails]', text)
        self.assertIn('FAIL:** D149 level-7 coins', text)

    def test_paired_change_is_visible_even_when_median_is_unchanged(self):
        before = snapshot()
        after = copy.deepcopy(before)
        after['scenarios'][0]['measurement']['runs'][0]['wave'] = 4
        text, changed = balance.render(after, before)
        self.assertTrue(changed)
        self.assertIn('1 changed, 0 added, 0 removed', text)
        self.assertIn('run / 1 / 0 | +1', text)

    def test_censored_runs_are_not_deaths_or_card_floor_failures(self):
        data = snapshot('full')
        for scenario in data['scenarios']:
            if scenario['id'].startswith('cards_'):
                for row in scenario['measurement']['runs']:
                    if row['case'] == 'health':
                        row.update(stop='time_cap', game_seconds=10800, killed_by='')
        text, _ = balance.render(data)
        self.assertIn('INCONCLUSIVE:** D149 level-7 health', text)
        self.assertNotIn('FAIL:** D149 level-7 health', text)

    def test_card_passes_on_one_build_and_coins_uses_income(self):
        data = snapshot('full')
        early = next(s for s in data['scenarios'] if s['id'] == 'cards_early')
        for row in early['measurement']['runs']:
            if row['case'] == 'health':
                row['wave'] += 1
            if row['case'] == 'coins':
                row['coins'] += 5
        text, _ = balance.render(data)
        self.assertIn('MEETS:** D149 level-7 health', text)
        self.assertIn('MEETS:** D149 level-7 coins', text)

    def test_quick_does_not_claim_to_measure_card_floor(self):
        text, _ = balance.render(snapshot())
        self.assertIn('NOT MEASURED:** D149 card floor', text)

    def test_bad_values_duplicate_missing_and_unclassified_rows_fail(self):
        for mutation in ('nan', 'negative', 'duplicate', 'missing', 'stop', 'milestone', 'fraction', 'cap'):
            data = snapshot()
            rows = data['scenarios'][0]['measurement']['runs']
            if mutation == 'nan': rows[0]['coins'] = float('nan')
            if mutation == 'negative': rows[0]['coins'] = -1
            if mutation == 'duplicate': rows.append(copy.deepcopy(rows[0]))
            if mutation == 'missing': rows.pop()
            if mutation == 'stop': rows[0]['stop'] = 'unknown'
            if mutation == 'milestone': rows[0]['wave'] = 20
            if mutation == 'fraction': rows[0]['wave'] = 3.5
            if mutation == 'cap': rows[0]['stop'] = 'time_cap'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                balance.validate_snapshot(data)

    def test_new_and_removed_cards_are_reported(self):
        before = snapshot('full')
        after = copy.deepcopy(before)
        for scenario in after['scenarios']:
            if scenario['id'].startswith('cards_'):
                measurement = scenario['measurement']
                measurement['built_cards'].remove('health')
                measurement['built_cards'].append('new_card')
                for row in measurement['runs']:
                    if row['case'] == 'health': row['case'] = 'new_card'
        text, changed = balance.render(after, before)
        self.assertTrue(changed)
        self.assertIn('10 added, 10 removed', text)

    def test_mismatched_suite_or_configuration_cannot_compare(self):
        with self.assertRaises(ValueError): balance.render(snapshot(), snapshot('full'))
        data = snapshot()
        data['scenarios'][0]['options']['buy'] = 'core'
        with self.assertRaises(ValueError): balance.render(data, snapshot())

    def test_career_reach_time_includes_prior_runs_and_not_end_of_current_run(self):
        data = snapshot()
        rows = next(s for s in data['scenarios'] if s['id'] == 'career_core')['measurement']['runs']
        rows[1].update(wave=10, game_seconds=400.0, reached={'10': 315.0})
        text, _ = balance.render(data)
        self.assertIn('Reach wave 10: no baseline → run 2, 0.110 game hours', text)

    def test_shuffled_career_rows_keep_chronological_milestone_time(self):
        data = snapshot()
        rows = next(s for s in data['scenarios'] if s['id'] == 'career_core')['measurement']['runs']
        rows[1].update(wave=10, game_seconds=400.0, reached={'10': 315.0})
        expected, _ = balance.render(data)
        rows.reverse()
        actual, _ = balance.render(data)
        self.assertIn('Reach wave 10: no baseline → run 2, 0.110 game hours', actual)
        self.assertEqual([line for line in expected.splitlines() if 'Reach wave' in line],
                         [line for line in actual.splitlines() if 'Reach wave' in line])

    def test_strict_mode_fails_movement_default_reports_and_baseline_stays_unchanged(self):
        with tempfile.TemporaryDirectory() as folder:
            baseline = Path(folder) / 'base.json'
            balance.write_json(baseline, snapshot())
            original = baseline.read_bytes()
            current = snapshot()
            current['scenarios'][0]['measurement']['runs'][0]['coins'] += 1
            args = ['tool', 'compare', '--baseline', str(baseline), '--output', str(Path(folder) / 'current.json'), '--report', str(Path(folder) / 'report.md')]
            with patch.object(balance, 'capture', return_value=current), patch('sys.argv', args), patch('builtins.print'):
                self.assertEqual(balance.main(), 0)
            with patch.object(balance, 'capture', return_value=current), patch('sys.argv', args + ['--fail-on-change']), patch('builtins.print'):
                self.assertEqual(balance.main(), 1)
            self.assertEqual(baseline.read_bytes(), original)

    def test_record_requires_explicit_replacement_and_bad_baseline_does_not_capture(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'baseline.json'
            path.write_text('{}')
            with patch.object(balance, 'capture') as capture, patch('sys.argv', ['tool', 'record', '--baseline', str(path)]), patch('builtins.print'):
                self.assertEqual(balance.main(), 2)
                capture.assert_not_called()
            with patch.object(balance, 'capture') as capture, patch('sys.argv', ['tool', 'compare', '--baseline', str(path)]), patch('builtins.print'):
                self.assertEqual(balance.main(), 2)
                capture.assert_not_called()

    def test_runtime_errors_reject_even_zero_exit_and_leave_no_baseline(self):
        process = type('Result', (), {'returncode': 0, 'stdout': 'PASS\nSCRIPT ERROR: broken'})()
        with patch.object(balance.subprocess, 'run', return_value=process):
            with self.assertRaisesRegex(ValueError, 'SCRIPT ERROR'):
                balance.capture('quick')

    def test_cached_and_original_purchases_have_identical_runtime_measurements(self):
        root = Path(__file__).resolve().parents[1]
        cases = [
            ['--seeds', '1', '--buy', 'core', '--workshop', '12', '--cards', 'free_upgrades:7', '--until-wave', '12'],
            ['--seeds', '1', '--buy', 'health', '--cap-minutes', '2'],
            ['--seeds', '1', '--buy', 'survival', '--cap-minutes', '2'],
        ]
        with tempfile.TemporaryDirectory(prefix='ngu-buy-parity-') as folder:
            for index, options in enumerate(cases):
                measurements, outputs = [], []
                for uncached in (False, True):
                    output = Path(folder) / f'{index}-{uncached}.json'
                    command = ['bash', str(root / 'run_godot.sh'), '--headless', '--path', str(root),
                               '-s', 'res://tools/sim_runs.gd', '--'] + options + ['--json-out', str(output)]
                    if uncached:
                        command.append('--uncached-buys')
                    process = subprocess.run(command, cwd=root, text=True, capture_output=True, timeout=120)
                    self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
                    self.assertIsNone(re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', process.stdout + process.stderr, re.MULTILINE))
                    measurements.append(json.loads(output.read_text())['runs'])
                    outputs.append(process.stdout)
                self.assertEqual(measurements[0], measurements[1])
                self.assertEqual(outputs[0], outputs[1])

    def test_median_and_zero_comparison(self):
        self.assertEqual(balance.upper_median([1, 2, 3, 4]), 3)
        self.assertFalse(balance.different(1.0, 1.0 + 1e-12))
        self.assertTrue(balance.different(0.0, 1.0))


if __name__ == '__main__':
    unittest.main()
