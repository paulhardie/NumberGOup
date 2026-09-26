extends RefCounted
## Permanent progress, The Tower's way: Coins kept between runs, Workshop
## levels bought with them, and groups of rows opened a group at a time in The
## Tower's order. Every run starts from here. The rules for spending Coins live
## here; src/tower/save.gd writes it to disk.

const TowerData = preload("res://src/tower/tower_data.gd")

## Groups whose mechanics the battle has. The rest (Super Crit, Death Defy)
## show but can't be opened yet.
const BUILT_GROUPS := ["attack_start", "range", "multishot", "rapid_fire", "bounce_shot",
	"defense_start", "defense", "thorns", "lifesteal", "knockback", "orbs",
	"cash", "coins", "free_upgrades", "interest"]

var coins := 0.0
## Row id → Workshop level. Rows not listed are at level 0.
var levels: Dictionary = {}
## Every group opened, the free starting ones included.
var open_groups: Array = []
var best_wave := 0
var runs := 0


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
	return group == next_group(category) and group in BUILT_GROUPS and coins >= TowerData.group_price(group)


func open_group(group: String) -> bool:
	if not can_open(group):
		return false
	coins -= TowerData.group_price(group)
	open_groups.append(group)
	return true


func price(id: String) -> float:
	return TowerData.coin_price(id, level(id))


func can_buy(id: String) -> bool:
	return is_group_open(TowerData.group(id)) and level(id) < TowerData.max_level(id) and coins >= price(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	coins -= price(id)
	levels[id] = level(id) + 1
	return true


## Coins a run has earned, kept as they come in, so quitting mid-run loses
## none of them.
func add_coins(amount: float) -> void:
	if amount > 0.0:
		coins += amount


func finish_run(wave: int) -> void:
	runs += 1
	best_wave = maxi(best_wave, wave)


func to_dict() -> Dictionary:
	return {"coins": coins, "levels": levels.duplicate(), "open_groups": open_groups.duplicate(), "best_wave": best_wave, "runs": runs}


## Takes saved data into this fresh Workshop, keeping only what still makes
## sense: rows and groups this version knows, whole levels within each row's
## range, and counts that are real, non-negative numbers.
func restore(data: Dictionary) -> void:
	coins = _amount(data.get("coins"))
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
	runs = int(_amount(data.get("runs")))


static func _amount(value) -> float:
	if (value is float or value is int) and is_finite(float(value)):
		return maxf(0.0, float(value))
	return 0.0
