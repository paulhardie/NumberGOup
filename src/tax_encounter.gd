class_name TaxEncounter
extends RefCounted

## A wave's members (D057). Each carries its share of the wave's HP and Hit and
## walks in as part of a column: `arrive` is when it reaches the Number, in
## seconds from the wave's start. Damage strikes the front standing member, and
## any beyond what that member has left is lost, as it always was past a
## wave's last HP. A member that reaches the Number lands its share of the Hit
## once and passes (D037, per member).
const STANDING := 0
const KILLED := 1
const LANDED := 2

var tier_id: int = 1
var wave: int = 1
var max_liability := ScientificNumber.new()
## What is still standing: the HP of members neither beaten nor passed.
## Setting it spreads the new total over the standing members, front first,
## so a caller that thinks of the wave as one HP pool still reads true.
var remaining_liability: ScientificNumber:
	get:
		return _remaining
	set(value):
		_set_standing_total(value)
var _remaining := ScientificNumber.new()
## HP that walked past with members that landed, which was never cleared.
var passed_liability := ScientificNumber.new()
var collection := ScientificNumber.new()
var reward: int = 0
var is_boss: bool = false
## Each is {max, hp, share, arrive, state}, front first. `share` is the part of
## the wave's HP and Hit the member carries.
var members: Array = []

func _init(
	encounter_tier: int = 1,
	encounter_wave: int = 1,
	liability: ScientificNumber = null,
	collection_amount: ScientificNumber = null,
	reward_amount: int = 0,
	boss: bool = false,
	arrivals: Array = []
) -> void:
	tier_id = encounter_tier
	wave = encounter_wave
	max_liability = liability.copy() if liability != null else ScientificNumber.new()
	collection = collection_amount.copy() if collection_amount != null else ScientificNumber.new()
	reward = reward_amount
	is_boss = boss
	# One member arriving at the end of the clock is the wave as it was before
	# groups, which is also how an older save's active wave comes back.
	var times: Array = arrivals if not arrivals.is_empty() else [TaxBalanceProfile.WAVE_INTERVAL_SECONDS]
	var share := 1.0 / float(times.size())
	for arrive in times:
		var hp := max_liability.multiply_scalar(share)
		members.append({"max": hp, "hp": hp.copy(), "share": share, "arrive": float(arrive), "state": STANDING})
	_sum_remaining()

func apply_compliance(amount: ScientificNumber, multiplier: float = 1.0) -> ScientificNumber:
	if is_cleared() or amount.is_zero() or multiplier <= 0.0:
		return ScientificNumber.new()
	var index := front_index()
	var member: Dictionary = members[index]
	var requested := amount.multiply_scalar(multiplier)
	var applied: ScientificNumber = requested if requested.compare_to(member.hp) < 0 else member.hp.copy()
	member.hp = member.hp.subtract(applied)
	if member.hp.is_zero():
		member.state = KILLED
	_sum_remaining()
	return applied

## The standing member nearest the Number, or -1 when none stands.
func front_index() -> int:
	for index in range(members.size()):
		if int(members[index].state) == STANDING:
			return index
	return -1

## The front member if its arrival time has come, or -1. Members arrive in
## order, so no standing member behind the front can be due before it.
func due_index(elapsed: float) -> int:
	var index := front_index()
	if index >= 0 and float(members[index].arrive) <= elapsed:
		return index
	return -1

## The member reaches the Number: its HP leaves the wave uncleared.
func land(index: int) -> void:
	var member: Dictionary = members[index]
	if int(member.state) != STANDING:
		return
	passed_liability = passed_liability.add(member.hp)
	member.state = LANDED
	_sum_remaining()

## HP not cleared: what stands plus what walked past.
func uncleared() -> ScientificNumber:
	return _remaining.add(passed_liability)

## Takes the state of `old`, the same wave on an older balance profile, member
## for member: each keeps its share of its HP and whether it was beaten or has
## landed, so a resumed run never lands a member twice. False when the groups
## do not match, for the caller to fall back to the cleared share.
func carry_from(old) -> bool:
	if old == null or old.members.size() != members.size() or members.is_empty():
		return false
	passed_liability = ScientificNumber.new()
	for index in range(members.size()):
		var was: Dictionary = old.members[index]
		var member: Dictionary = members[index]
		member.hp = member.max.multiply_scalar(_ratio(was.hp, was.max))
		member.state = int(was.state)
		if int(member.state) == KILLED:
			member.hp = ScientificNumber.new()
		elif int(member.state) == LANDED:
			passed_liability = passed_liability.add(member.hp)
	_sum_remaining()
	return true

static func _ratio(part: ScientificNumber, whole: ScientificNumber) -> float:
	if whole.is_zero():
		return 0.0
	return clampf(part.mantissa / whole.mantissa * pow(10.0, part.exponent - whole.exponent), 0.0, 1.0)

func landed_count() -> int:
	return members.filter(func(member): return int(member.state) == LANDED).size()

func standing_count() -> int:
	return members.filter(func(member): return int(member.state) == STANDING).size()

## True when nothing of the wave stands, whether beaten or passed.
func is_cleared() -> bool:
	return remaining_liability.is_zero()

## True when every member was beaten and none reached the Number.
func is_beaten() -> bool:
	return is_cleared() and landed_count() == 0

## Takes a share of the wave off front first, for a run resumed on a newer
## balance profile that keeps the share of the wave it had cleared.
func set_remaining(target: ScientificNumber) -> void:
	_set_standing_total(target)

func _set_standing_total(target: ScientificNumber) -> void:
	if target.compare_to(_remaining) > 0:
		# More than stands: share the total evenly over the standing members.
		var standing := members.filter(func(member): return int(member.state) == STANDING)
		for member in standing:
			var even := target.multiply_scalar(1.0 / float(standing.size()))
			member.hp = even if even.compare_to(member.max) < 0 else member.max.copy()
		_sum_remaining()
		return
	var to_clear := _remaining.subtract(target)
	for member in members:
		if to_clear.is_zero():
			break
		if int(member.state) != STANDING:
			continue
		var taken: ScientificNumber = to_clear if to_clear.compare_to(member.hp) < 0 else member.hp.copy()
		member.hp = member.hp.subtract(taken)
		to_clear = to_clear.subtract(taken)
		if member.hp.is_zero():
			member.state = KILLED
	_sum_remaining()

func _sum_remaining() -> void:
	var total := ScientificNumber.new()
	for member in members:
		if int(member.state) == STANDING:
			total = total.add(member.hp)
	_remaining = total

func to_dict() -> Dictionary:
	var saved_members: Array = []
	for member in members:
		saved_members.append({
			"max": member.max.to_dict(),
			"hp": member.hp.to_dict(),
			"share": member.share,
			"arrive": member.arrive,
			"state": member.state,
		})
	return {
		"tier_id": tier_id,
		"wave": wave,
		"max_liability": max_liability.to_dict(),
		"remaining_liability": remaining_liability.to_dict(),
		"passed_liability": passed_liability.to_dict(),
		"collection": collection.to_dict(),
		"reward": reward,
		"is_boss": is_boss,
		"members": saved_members,
	}

static func from_dict(data: Dictionary) -> TaxEncounter:
	var encounter = (load("res://src/tax_encounter.gd") as GDScript).new(
		int(data.get("tier_id", 1)),
		int(data.get("wave", 1)),
		ScientificNumber.from_dict(data.get("max_liability", {})),
		ScientificNumber.from_dict(data.get("collection", {})),
		int(data.get("reward", 0)),
		bool(data.get("is_boss", false))
	)
	var saved_members: Variant = data.get("members", null)
	if saved_members is Array and not saved_members.is_empty():
		encounter.members = []
		for saved in saved_members:
			if not (saved is Dictionary and saved.get("hp") is Dictionary and saved.get("max") is Dictionary):
				continue
			encounter.members.append({
				"max": ScientificNumber.from_dict(saved.get("max", {})),
				"hp": ScientificNumber.from_dict(saved.get("hp", {})),
				"share": clampf(float(saved.get("share", 1.0)), 0.0, 1.0),
				"arrive": clampf(float(saved.get("arrive", TaxBalanceProfile.WAVE_INTERVAL_SECONDS)), 0.0, TaxBalanceProfile.WAVE_INTERVAL_SECONDS),
				"state": clampi(int(saved.get("state", STANDING)), STANDING, LANDED),
			})
		encounter.passed_liability = ScientificNumber.from_dict(data.get("passed_liability", {}))
		encounter._sum_remaining()
	# No member that parsed: never a beaten wave for free. It comes back as one
	# member with what the wave had left, as a pre-group save does.
	if encounter.members.is_empty():
		encounter = (load("res://src/tax_encounter.gd") as GDScript).new(
			encounter.tier_id, encounter.wave, encounter.max_liability, encounter.collection, encounter.reward, encounter.is_boss
		)
		encounter.set_remaining(ScientificNumber.from_dict(data.get("remaining_liability", data.get("max_liability", {}))))
	elif not (saved_members is Array and not saved_members.is_empty()):
		# A wave saved before groups (V9 and older) is one member with what it
		# had left.
		encounter.set_remaining(ScientificNumber.from_dict(data.get("remaining_liability", data.get("max_liability", {}))))
	return encounter
