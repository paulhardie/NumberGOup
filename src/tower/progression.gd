extends RefCounted
## Permanent progression beside the Workshop: records, claimed wave rewards,
## Gems, unlocks and research. One atomic save owns both domains.

const Workshop = preload("res://src/tower/workshop.gd")
const RealClock = preload("res://src/tower/real_clock.gd")
const Research = preload("res://src/tower/research.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
## Known free-track rewards from TOWER_RULES.md. Unknown later rewards wait
## for their source rather than extrapolating an economy.
static var MILESTONES: Array = TowerData.progression().milestones
## The Tower v29's free daily claim (developer notes, 25 August 2026).
static var DAILY_GEMS: int = int(TowerData.progression().daily_gems)

var workshop: Workshop
var gems := 0
## Tier id as text → {reached, cleared}. Reaching and clearing are distinct.
var records: Dictionary = {}
var claimed: Array[String] = []
var last_daily_day := -1
var clock := RealClock.new()
var research := Research.new()
## Newer or unreadable data is never overwritten by this older build.
var writable := true
var notice := ""


func _init(permanent: Workshop = null) -> void:
	workshop = permanent if permanent != null else Workshop.new()


func observe(tier: int, reached: int, cleared: int = 0) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	if not writable or tier < 1 or tier > TowerData.tier_count() or reached < 0 or cleared < 0:
		return rewards
	var key := str(tier)
	var best: Dictionary = records.get(key, {"reached": 0, "cleared": 0})
	best.reached = maxi(int(best.reached), reached)
	best.cleared = maxi(int(best.cleared), mini(cleared, reached))
	records[key] = best
	for row in MILESTONES:
		var id := "%d:%d" % [int(row.tier), int(row.wave)]
		if int(row.wave) == 100 and cleared < 100: continue
		if gems > 9007199254740991 - int(row.gems): continue
		if int(row.tier) == tier and reached >= int(row.wave) and id not in claimed:
			claimed.append(id)
			workshop.add_coins(float(row.coins))
			gems += int(row.gems)
			rewards.append(row.duplicate())
	return rewards


func best_wave(tier: int, cleared := false) -> int:
	return int(records.get(str(tier), {}).get("cleared" if cleared else "reached", 0))


func unlocked(feature: String) -> bool:
	match feature:
		"workshop": return workshop.runs > 0
		"cards": return best_wave(1) >= 20
		"labs": return best_wave(1) >= 30
	return false


func tier_open(tier: int) -> bool:
	return tier == 1 or (tier > 1 and tier <= TowerData.tier_count() and best_wave(tier - 1, true) >= 100)


func claim_daily(now: float = Time.get_unix_time_from_system()) -> bool:
	if not writable or workshop.runs == 0 or not is_finite(now) or now < 0.0 or now > RealClock.LAST_SUPPORTED_UTC or gems > 9007199254740991 - DAILY_GEMS:
		return false
	var day := floori(now / 86400.0)
	if day <= last_daily_day:
		return false
	last_daily_day = day
	gems += DAILY_GEMS
	return true


func spend_gems(amount: int) -> bool:
	if not writable or amount < 0 or amount > gems:
		return false
	gems -= amount
	return true


func advance_time(now: float = Time.get_unix_time_from_system()) -> Array[String]:
	if not writable:
		return []
	return research.advance(clock.advance(now))


func run_effects(domain: String = "stat") -> Array:
	return research.effects().filter(func(effect): return effect.get("domain", "stat") == domain)


func start_research(id: String, cost: float, seconds: float, effects: Array, now: float = Time.get_unix_time_from_system()) -> bool:
	if not writable or not unlocked("labs"):
		return false
	advance_time(now)
	return research.start(id, cost, seconds, effects, workshop)


func to_dict() -> Dictionary:
	return {"gems": gems, "records": records.duplicate(true), "claimed": claimed.duplicate(),
		"last_daily_day": last_daily_day, "clock": clock.last_utc, "research": research.to_dict()}


func restore(data: Dictionary) -> void:
	gems = _count(data.get("gems", 0))
	last_daily_day = maxi(-1, _count(data.get("last_daily_day", -1), -1))
	records.clear()
	claimed.clear()
	if data.get("records") is Dictionary:
		for key in data.records:
			var record = data.records[key]
			if key is String and key.is_valid_int() and int(key) >= 1 and int(key) <= TowerData.tier_count() and record is Dictionary:
				var reached := _count(record.get("reached", 0))
				records[key] = {"reached": reached, "cleared": mini(reached, _count(record.get("cleared", 0)))}
	if data.get("claimed") is Array:
		for id in data.claimed:
			if id is String and id not in claimed:
				claimed.append(id)
	clock.restore(data.get("clock", -1.0))
	if data.get("research") is Dictionary:
		research.restore(data.research)


static func _count(value, fallback := 0) -> int:
	if (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 9007199254740991.0:
		return int(value)
	return fallback
