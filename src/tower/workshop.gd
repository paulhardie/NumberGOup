extends RefCounted
## Permanent progress, The Tower's way: Coins kept between runs, Workshop
## levels bought with them, and groups of rows opened a group at a time in The
## Tower's order. Every run starts from here. The rules for spending Coins live
## here; src/tower/save.gd writes it to disk.

const TowerData = preload("res://src/tower/tower_data.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const RunConfig = preload("res://src/tower/run_config.gd")

## Compensation preserves small awards beside a very large balance. The
## display/API remains a float; the remainder survives saving and spending.
var _coins := 0.0
var _coin_remainder := 0.0
var coins: float:
	get: return _coins
	set(value):
		_coins = value
		_coin_remainder = 0.0
## Row id → Workshop level. Rows not listed are at level 0.
var levels: Dictionary = {}
## Every group opened, the free starting ones included.
var open_groups: Array = []
var best_wave := 0
## The highest the Number has stood in any run (D081).
var best_number := 0.0
var runs := 0
## Coins the first run's end just gave (FIRST_RUN_GIFT), for Home to announce
## once; not saved, so a game closed before Home shows it keeps the Coins
## and skips the popup.
var gift_waiting := 0.0
## Coins the latest finish_run gave as the gift, for the log: 0 after any
## other run's end.
var gift_given := 0.0

## The Tower's welcome (the owner, 30 September 2026; D125): when a new
## player's first run ends, a popup shows them the Workshop and gives them
## Coins to start it: The Tower's 50, ours 57 (D137). Saves already past
## their first run never get it.
const FIRST_RUN_GIFT := 57.0


func _init() -> void:
	for group in TowerData.groups():
		if int(group.unlock_coins) == 0:
			open_groups.append(String(group.id))


func level(id: String) -> int:
	return int(levels.get(id, 0))


func is_group_open(group: String) -> bool:
	return group in open_groups


## The next group a category opens, in The Tower's order, or "" when all are.
func next_group(category: String) -> String:
	for group in TowerData.groups():
		if String(group.workshop_category) == category and not is_group_open(String(group.id)):
			return String(group.id)
	return ""


func can_open(group: String) -> bool:
	var category := TowerData.group_category(group)
	return group == next_group(category) and can_spend_coins(TowerData.group_price(group))


func open_group(group: String) -> bool:
	if not can_open(group):
		return false
	if not spend_coins(TowerData.group_price(group)):
		return false
	open_groups.append(group)
	return true


func price(id: String) -> float:
	return TowerData.coin_price(id, level(id))


## What a buy of `count` levels of `id` gets and costs; 0 is Max, as many as
## the Coins cover (TowerData.plan_buy).
func plan(id: String, count: int = 1) -> Dictionary:
	return TowerData.plan_buy(TowerData.upgrade(id)["coin_prices"], level(id), TowerData.max_level(id) - level(id), count, coins)


func can_buy(id: String, count: int = 1) -> bool:
	var buying := plan(id, count)
	return is_group_open(TowerData.group(id)) and int(buying.levels) > 0 and can_spend_coins(float(buying.cost))


## Buys `count` levels of `id` (0: Max) with Coins; false, and nothing
## changes, if it can't.
func buy(id: String, count: int = 1) -> bool:
	if not can_buy(id, count):
		return false
	var buying := plan(id, count)
	if not spend_coins(float(buying.cost)):
		return false
	levels[id] = level(id) + int(buying.levels)
	return true


## Coins a run has earned, kept as they come in, so quitting mid-run loses
## none of them.
func add_coins(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_change_coins(amount)


func spend_coins(amount: float) -> bool:
	if not can_spend_coins(amount):
		return false
	_change_coins(-amount)
	return true


func can_spend_coins(amount: float) -> bool:
	return is_finite(amount) and amount >= 0.0 and amount <= _coins and (amount < _coins or _coin_remainder >= 0.0)


func _change_coins(amount: float) -> void:
	# TwoSum keeps the rounding error even when spending the whole high part.
	var total := _coins + amount
	if not is_finite(total):
		return
	var rounded := total - _coins
	var error := (_coins - (total - rounded)) + (amount - rounded)
	var low := _coin_remainder + error
	var high := total + low
	_coin_remainder = low - (high - total)
	_coins = high


## The digit ladder keyed on the Number earned (D163, THE_NUMBER.md 17): measuring
## options, off in the game and never saved. With `ladder_on_earned` a digit pays
## the first time the best Number a run has earned (`best_earned`, held in memory
## only) reaches it, instead of the best peak, and `ladder_scale` multiplies what it
## pays. The record, `best_number`, stays the true peak either way.
var ladder_on_earned := false
var ladder_scale := 1.0
var best_earned := 0.0


## Counts a run as it ends: its wave and its peak Number against the bests.
## The first run's end also gives FIRST_RUN_GIFT.
## A peak that takes the best Number past a milestone for the first time pays
## that milestone's Coins (D107), or with the ladder keyed on the Number earned
## (D163, measuring only) the run's `earned` does; the milestones reached are returned, as
## {number, coins}, for the run's end to show and the log to keep.
func finish_run(wave: int, peak_number: float = 0.0, earned: float = 0.0) -> Array[Dictionary]:
	gift_given = 0.0
	if runs == 0:
		add_coins(FIRST_RUN_GIFT)
		gift_given = FIRST_RUN_GIFT
		gift_waiting = FIRST_RUN_GIFT
	runs += 1
	best_wave = maxi(best_wave, wave)
	var reached: Array[Dictionary] = []
	if ladder_on_earned:
		if is_finite(earned):
			for milestone in Guesses.MILESTONES:
				if best_earned < float(milestone.number) and earned >= float(milestone.number):
					var paid: Dictionary = milestone.duplicate()
					paid.coins = float(milestone.coins) * ladder_scale
					reached.append(paid)
					add_coins(float(paid.coins))
			best_earned = maxf(best_earned, earned)
		if is_finite(peak_number):
			best_number = maxf(best_number, peak_number)
		return reached
	if is_finite(peak_number):
		for milestone in Guesses.MILESTONES:
			if best_number < float(milestone.number) and peak_number >= float(milestone.number):
				reached.append(milestone.duplicate())
				add_coins(float(milestone.coins))
		best_number = maxf(best_number, peak_number)
	return reached


## The next milestone the best Number hasn't reached, or empty past the last.
func next_milestone() -> Dictionary:
	for milestone in Guesses.MILESTONES:
		if best_number < float(milestone.number):
			return milestone
	return {}


func to_dict() -> Dictionary:
	return {"coins": coins, "coin_remainder": _coin_remainder, "coin_parts": RunConfig.pack({"coins": coins, "remainder": _coin_remainder}), "levels": levels.duplicate(), "open_groups": open_groups.duplicate(), "best_wave": best_wave, "best_number": best_number, "runs": runs}


## Takes saved data into this fresh Workshop, keeping only what still makes
## sense: rows and groups this version knows, whole levels within each row's
## range, and counts that are real, non-negative numbers.
func restore(data: Dictionary) -> void:
	coins = _amount(data.get("coins"))
	var remainder = data.get("coin_remainder", 0.0)
	if (remainder is float or remainder is int) and is_finite(float(remainder)) and absf(float(remainder)) <= maxf(1e-9, absf(coins) * 1e-15):
		_coin_remainder = float(remainder)
	var parts = RunConfig.unpack(data.get("coin_parts"))
	if parts is Dictionary and RunConfig.number(parts.get("coins")) and float(parts.coins) >= 0.0 and RunConfig.number(parts.get("remainder")) \
			and absf(float(parts.remainder)) <= maxf(1e-9, absf(float(parts.coins)) * 1e-15):
		_coins = float(parts.coins)
		_coin_remainder = float(parts.remainder)
	var saved_levels = data.get("levels")
	if saved_levels is Dictionary:
		var known := TowerData.rows()
		for id in saved_levels:
			if String(id) in known:
				levels[String(id)] = clampi(int(_amount(saved_levels[id])), 0, TowerData.max_level(String(id)))
	var saved_groups = data.get("open_groups")
	if saved_groups is Array:
		for group in saved_groups:
			if group is String and TowerData.has_group(group) and not is_group_open(group):
				open_groups.append(group)
	best_wave = int(_amount(data.get("best_wave")))
	# Saves from before D081 have none, and start from 0.
	best_number = _amount(data.get("best_number"))
	runs = int(_amount(data.get("runs")))


static func _amount(value) -> float:
	if (value is float or value is int) and is_finite(float(value)):
		return maxf(0.0, float(value))
	return 0.0
