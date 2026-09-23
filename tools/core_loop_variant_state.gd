extends GameState

## Simulator-only alternative to D012. While a wave has HP, this share of
## produced damage banks as Number and the rest damages the wave. The same
## output is never counted twice; the shipped GameState remains unchanged.
var bank_while_uncleared_share := 0.0
var bank_taps_only := false
var _applying_tap := false

func tap() -> SimulationEvent:
	_applying_tap = true
	var event: SimulationEvent = super.tap()
	_applying_tap = false
	return event

func _add_number(amount: ScientificNumber) -> void:
	if bank_while_uncleared_share <= 0.0 or (bank_taps_only and not _applying_tap) or not in_run or active_encounter == null or active_encounter.is_cleared():
		super._add_number(amount)
		return
	lifetime_generated = lifetime_generated.add(amount)
	var direct_bank := amount.multiply_scalar(clampf(bank_while_uncleared_share, 0.0, 1.0))
	var into_wave: ScientificNumber = active_encounter.apply_compliance(amount.subtract(direct_bank))
	var banked: ScientificNumber = direct_bank.add(amount.subtract(direct_bank).subtract(into_wave))
	# Existing Siphon is unchanged in the experiment; its extra Number is an
	# upgrade effect, not part of the conserved output split being compared.
	var siphon := minf(_effect_sum("siphon_share"), balance_profile.SIPHON_CEILING)
	if siphon > 0.0 and not into_wave.is_zero():
		banked = banked.add(into_wave.multiply_scalar(siphon))
	number = number.add(banked)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()
	if number.compare_to(run_peak_number) > 0:
		run_peak_number = number.copy()
