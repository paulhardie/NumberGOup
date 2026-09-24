class_name TaxEncounter
extends RefCounted

## A wave's members (D057), and any earlier members still at the Number
## (D058). Each wave member carries its share of its wave's HP and Hit and
## walks in as part of a column, reaching the Number at `arrive` seconds into
## the wave's clock. Opening members hit once and leave (D059); later members
## stay and hit again every `interval` seconds until beaten. Members still at
## the Number when the clock runs out carry into the next wave, ahead of its
## column, so a build that cannot beat them is worn down by the pile. Damage
## strikes the front living member, and any beyond its HP is lost.
const STANDING := 0
const KILLED := 1
## A member that landed and passed, as in D057 and the D059 opening. Its HP
## remains uncleared, but it cannot hit again.
const LANDED := 2
const AT_NUMBER := 3

var tier_id: int = 1
var wave: int = 1
## This wave's own HP and Hit in total, not counting members carried in.
var max_liability := ScientificNumber.new()
## What is still alive: every member walking in or at the Number, carried ones
## included. Setting it spreads the new total over the living members, front
## first, so a caller that thinks of the wave as one HP pool still reads true.
var remaining_liability: ScientificNumber:
	get:
		return _remaining
	set(value):
		_set_living_total(value)
var _remaining := ScientificNumber.new()
## How many members are alive, and how many of them are this wave's own, kept
## with `_remaining` so asking is free.
var _alive := 0
var _own_alive := 0
## The soonest any living member can next hit, so a step with nobody due skips
## the scan. -INF means "not known": every recount clears it.
var _next_due := -INF
## 10^-k for k = 0..16, so the recount needs no pow() per member.
const POWERS_BELOW := [1.0, 1e-1, 1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16]
var collection := ScientificNumber.new()
var reward: int = 0
var is_boss: bool = false
## Each is {max, hp, share, arrive, state, wave, wave_hit, next_hit,
## interval, landed, boss, hits}, front first: members carried in, then this
## wave's in arrival order. `share` is the part of its wave's HP and Hit the
## member carries, `wave_hit` its wave's whole Hit, `next_hit` when it next
## hits on this wave's clock, `landed` whether it has reached the Number,
## `boss` whether it is a boss (which may be carried into later waves, D063),
## `hits` how many times it has hit, which heats up its next hit, and `unpaid`
## the share of its passed wave's reward still owed when it is beaten.
var members: Array = []

func _init(
	encounter_tier: int = 1,
	encounter_wave: int = 1,
	liability: ScientificNumber = null,
	collection_amount: ScientificNumber = null,
	reward_amount: int = 0,
	boss: bool = false,
	arrivals: Array = [],
	hit_interval: float = TaxBalanceProfile.WAVE_INTERVAL_SECONDS,
	weights: Array = [],
	boss_interval: float = 0.0,
	boss_hit: ScientificNumber = null
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
	# Each member's share of the wave's HP and Hit follows its weight (D065): an
	# ordinary enemy is one, a boss carries many enemies' HP. Without weights
	# the members share evenly and all take the wave's boss flag, as before.
	var total := 0.0
	for index in range(times.size()):
		total += float(weights[index]) if index < weights.size() else 1.0
	for index in range(times.size()):
		var arrive: float = float(times[index])
		var weight: float = float(weights[index]) if index < weights.size() else 1.0
		var share: float = weight / total
		var hp := max_liability.multiply_scalar(share)
		var is_boss_member: bool = boss if weights.is_empty() else weight > 1.0
		var member_hit: ScientificNumber = collection.copy()
		var member_interval := hit_interval
		if is_boss_member and not weights.is_empty():
			if boss_hit != null:
				member_hit = boss_hit.copy()
			if boss_interval > 0.0:
				member_interval = boss_interval
		members.append({
			"max": hp, "hp": hp.copy(), "share": share, "arrive": arrive, "state": STANDING,
			"wave": wave, "wave_hit": member_hit, "next_hit": arrive,
			"interval": member_interval, "landed": false, "boss": is_boss_member, "hits": 0, "unpaid": 0.0,
			"weight": weight, "of": total,
		})
	_sum_remaining()

static func is_alive(member: Dictionary) -> bool:
	var state := int(member.state)
	return state == STANDING or state == AT_NUMBER

func is_own(member: Dictionary) -> bool:
	return int(member.get("wave", wave)) == wave

## Whether the member at `index` is a boss, this wave's or one carried in.
func is_boss_member(index: int) -> bool:
	return index >= 0 and index < members.size() and bool(members[index].get("boss", false))

## The living boss nearest the Number, or -1.
func boss_index() -> int:
	for index in range(members.size()):
		if is_alive(members[index]) and is_boss_member(index):
			return index
	return -1

func apply_compliance(amount: ScientificNumber, multiplier: float = 1.0) -> ScientificNumber:
	if is_cleared() or amount.is_zero() or multiplier <= 0.0:
		return ScientificNumber.new()
	var index := front_index()
	var member: Dictionary = members[index]
	var requested := amount.multiply_scalar(multiplier)
	var applied: ScientificNumber = requested if requested.compare_to(member.hp) < 0 else member.hp.copy()
	_take(member, applied)
	return applied

## Deals `amount` to one member, such as Thorns to the enemy that hit (D064),
## and returns what came off; nothing beyond its HP, and nothing if it is gone.
func damage_member(index: int, amount: ScientificNumber) -> ScientificNumber:
	if index < 0 or index >= members.size() or not is_alive(members[index]) or amount.is_zero():
		return ScientificNumber.new()
	var member: Dictionary = members[index]
	var applied: ScientificNumber = amount if amount.compare_to(member.hp) < 0 else member.hp.copy()
	_take(member, applied)
	return applied

## Takes `applied` off a living member. A hit that leaves it standing moves the
## running total by what came off; a kill recounts, so rounding never builds
## up across a pile (a recount per hit cost 3 ms with a thousand enemies).
func _take(member: Dictionary, applied: ScientificNumber) -> void:
	member.hp = member.hp.subtract(applied)
	if member.hp.is_zero():
		member.state = KILLED
		_sum_remaining()
	else:
		_remaining = _remaining.subtract(applied)

## The living member nearest the Number, or -1 when none lives. Members at the
## Number sit ahead of those still walking, carried ones first.
func front_index() -> int:
	for index in range(members.size()):
		if is_alive(members[index]) and int(members[index].state) == AT_NUMBER:
			return index
	for index in range(members.size()):
		if is_alive(members[index]):
			return index
	return -1

## The living member whose next hit is soonest, if it is due by `elapsed`
## seconds on this wave's clock, or -1.
func due_index(elapsed: float) -> int:
	var due := -1
	for index in range(members.size()):
		var member: Dictionary = members[index]
		if is_alive(member) and float(member.next_hit) <= elapsed and (due < 0 or float(member.next_hit) < float(members[due].next_hit)):
			due = index
	return due

## Every living member due to hit by `elapsed`, soonest first (ties in member
## order, as due_index picks them), from one scan rather than one per hit.
func due_indices(elapsed: float) -> Array:
	var due: Array = []
	if elapsed < _next_due:
		return due
	var soonest := INF
	for index in range(members.size()):
		var member: Dictionary = members[index]
		var state := int(member.state)
		if state == STANDING or state == AT_NUMBER:
			var next_hit := float(member.next_hit)
			if next_hit <= elapsed:
				due.append(index)
			elif next_hit < soonest:
				soonest = next_hit
	# The members due now hit and move on by at least half a second, and
	# hit() lowers this if one comes due sooner.
	_next_due = soonest
	if due.size() > 1:
		due.sort_custom(func(a, b): return float(members[a].next_hit) < float(members[b].next_hit) or (float(members[a].next_hit) == float(members[b].next_hit) and a < b))
	return due

## The member hits: it is at the Number from now on and hits again after its
## interval.
func hit(index: int) -> void:
	var member: Dictionary = members[index]
	if not is_alive(member):
		return
	member.landed = true
	member.hits = int(member.get("hits", 0)) + 1
	# An opening member (interval 0, D059) hits once and leaves, uncleared.
	if float(member.interval) <= 0.0:
		member.state = LANDED
		_sum_remaining()
		return
	member.state = AT_NUMBER
	member.next_hit = float(member.next_hit) + float(member.interval)
	_next_due = minf(_next_due, float(member.next_hit))

## Moves every living member's clock back by `seconds`, when this wave's clock
## wraps (a boss wave) or they carry into the next wave's.
func shift_clock(seconds: float) -> void:
	for member in members:
		member.next_hit = float(member.next_hit) - seconds
	_next_due -= seconds

## The members still alive, for the next wave to carry in.
func living_members() -> Array:
	return members.filter(func(member): return is_alive(member))

## Puts members carried from earlier waves at the front of this one.
func carry_in(carried: Array) -> void:
	if carried.is_empty():
		return
	members = carried + members
	_sum_remaining()

## HP not yet cleared, carried members included, and the HP of opening members
## that hit and left (D059). A member reaching, hitting or leaving the Number
## keeps its HP here, so only damage moves this.
func uncleared() -> ScientificNumber:
	var total := _remaining
	for member in members:
		if int(member.state) == LANDED:
			total = total.add(member.hp)
	return total

## This wave's own HP not cleared: its living members plus any that left
## under the old pass rule.
func own_uncleared() -> ScientificNumber:
	var total := ScientificNumber.new()
	for member in members:
		if is_own(member) and (is_alive(member) or int(member.state) == LANDED):
			total = total.add(member.hp)
	return total

# Plain loops rather than filter(): these run several times a step, and a pile
# can hold hundreds of members.
func own_alive_count() -> int:
	return _own_alive

## How many of this wave's members have reached the Number.
func landed_count() -> int:
	var count := 0
	for member in members:
		if int(member.wave) == wave and bool(member.get("landed", false)):
			count += 1
	return count

func standing_count() -> int:
	return _alive

func at_number_count() -> int:
	var count := 0
	for member in members:
		if int(member.state) == AT_NUMBER:
			count += 1
	return count

## True when nothing lives, this wave's members or carried ones.
func is_cleared() -> bool:
	return _alive == 0

## True when every one of this wave's members is beaten, whether or not it
## reached the Number first (D058): a member at the Number is still a fight.
func is_beaten() -> bool:
	if own_alive_count() > 0:
		return false
	# An opening member that hit and left was never beaten (D059).
	return not members.any(func(member): return is_own(member) and int(member.state) == LANDED)

## Takes the state of `old`, the same wave on an older balance profile, member
## for member: each keeps its share of its HP, its state and its clock, and
## carried members come across as they were, so a resumed run never lands a
## member twice. False when this wave's groups do not match, for the caller to
## fall back to the cleared share.
func carry_from(old) -> bool:
	if old == null:
		return false
	var own_old: Array = old.members.filter(func(member): return int(member.get("wave", old.wave)) == old.wave)
	if own_old.size() != members.size() or members.is_empty():
		return false
	for index in range(members.size()):
		var was: Dictionary = own_old[index]
		var member: Dictionary = members[index]
		member.hp = member.max.multiply_scalar(_ratio(was.hp, was.max))
		member.state = int(was.state)
		member.landed = bool(was.get("landed", false)) or int(was.state) == LANDED
		member.next_hit = float(was.get("next_hit", member.arrive))
		member.hits = int(was.get("hits", 1 if member.landed else 0))
		if int(member.state) == KILLED:
			member.hp = ScientificNumber.new()
	members = old.members.filter(func(member): return int(member.get("wave", old.wave)) != old.wave) + members
	_sum_remaining()
	return true

static func _ratio(part: ScientificNumber, whole: ScientificNumber) -> float:
	if whole.is_zero():
		return 0.0
	return clampf(part.mantissa / whole.mantissa * pow(10.0, part.exponent - whole.exponent), 0.0, 1.0)

## Takes a share of the wave off front first, for a run resumed on a newer
## balance profile that keeps the share of the wave it had cleared.
func set_remaining(target: ScientificNumber) -> void:
	_set_living_total(target)

func _set_living_total(target: ScientificNumber) -> void:
	if target.compare_to(_remaining) > 0:
		# More than lives: share the total evenly over the living members.
		var living := living_members()
		for member in living:
			var even := target.multiply_scalar(1.0 / float(living.size()))
			member.hp = even if even.compare_to(member.max) < 0 else member.max.copy()
		_sum_remaining()
		return
	var to_clear := _remaining.subtract(target)
	while not to_clear.is_zero():
		var index := front_index()
		if index < 0:
			break
		var member: Dictionary = members[index]
		var taken: ScientificNumber = to_clear if to_clear.compare_to(member.hp) < 0 else member.hp.copy()
		member.hp = member.hp.subtract(taken)
		to_clear = to_clear.subtract(taken)
		if member.hp.is_zero():
			member.state = KILLED
	_sum_remaining()

## Recounts what lives and its HP. Summed as plain floats scaled to the
## largest exponent, with one ScientificNumber at the end: adding them one by
## one allocated a number per member.
func _sum_remaining() -> void:
	_next_due = -INF
	var top := -2147483648
	_alive = 0
	_own_alive = 0
	for member in members:
		var state := int(member.state)
		if state == STANDING or state == AT_NUMBER:
			_alive += 1
			if int(member.get("wave", wave)) == wave:
				_own_alive += 1
			var hp: ScientificNumber = member.hp
			if not hp.is_zero() and hp.exponent > top:
				top = hp.exponent
	if _alive == 0 or top == -2147483648:
		_remaining = ScientificNumber.new()
		return
	var sum := 0.0
	for member in members:
		var state := int(member.state)
		if state == STANDING or state == AT_NUMBER:
			var hp: ScientificNumber = member.hp
			var below: int = top - hp.exponent
			# Past sixteen places a member cannot move a float sum.
			if not hp.is_zero() and below < POWERS_BELOW.size():
				sum += hp.mantissa * POWERS_BELOW[below]
	_remaining = ScientificNumber.new(1.0, top).multiply_scalar(sum)

func to_dict() -> Dictionary:
	var saved_members: Array = []
	for member in members:
		saved_members.append({
			"max": member.max.to_dict(),
			"hp": member.hp.to_dict(),
			"share": member.share,
			"arrive": member.arrive,
			"state": member.state,
			"wave": member.wave,
			"wave_hit": member.wave_hit.to_dict(),
			"next_hit": member.next_hit,
			"interval": member.interval,
			"landed": member.landed,
			"boss": member.get("boss", false),
			"hits": member.get("hits", 0),
			"unpaid": member.get("unpaid", 0.0),
			# The share is saved as the two whole numbers it comes from, so it
			# reads back exactly: 1/43 does not survive JSON bit for bit (D065).
			"weight": member.get("weight", 0.0),
			"of": member.get("of", 0.0),
		})
	return {
		"tier_id": tier_id,
		"wave": wave,
		"max_liability": max_liability.to_dict(),
		"remaining_liability": remaining_liability.to_dict(),
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
	var had_members: bool = saved_members is Array and not saved_members.is_empty()
	if had_members:
		encounter.members = []
		for saved in saved_members:
			if not (saved is Dictionary and saved.get("hp") is Dictionary and saved.get("max") is Dictionary):
				continue
			var arrive := clampf(float(saved.get("arrive", TaxBalanceProfile.WAVE_INTERVAL_SECONDS)), 0.0, TaxBalanceProfile.WAVE_INTERVAL_SECONDS)
			var state := clampi(int(saved.get("state", STANDING)), STANDING, AT_NUMBER)
			var wave_hit: Variant = saved.get("wave_hit", null)
			var member_wave := int(saved.get("wave", encounter.wave))
			# A member saved before D058 had no interval: a boss keeps its 15
			# seconds, anything else takes today's.
			var default_interval: float = TaxBalanceProfile.OPENING_HIT_SECONDS if encounter.is_boss and member_wave == encounter.wave else TaxBalanceProfile.DEFAULT_MEMBER_HIT_SECONDS
			var interval := float(saved.get("interval", default_interval))
			# Zero is an opening member that passes (D059); anything else is a
			# real interval, never shorter than half a second.
			if not is_finite(interval) or interval < 0.0:
				interval = default_interval
			elif interval > 0.0:
				interval = maxf(0.5, interval)
			# A damaged clock must neither fire a burst of catch-up hits nor
			# never fire again.
			var next_hit := float(saved.get("next_hit", arrive))
			if not is_finite(next_hit):
				next_hit = arrive
			next_hit = clampf(next_hit, 0.0, TaxBalanceProfile.WAVE_INTERVAL_SECONDS + interval)
			var landed := bool(saved.get("landed", state == LANDED or state == AT_NUMBER))
			# Saved before D063: a boss was always its own wave's, and a member
			# that had landed had hit at least once.
			var weight := float(saved.get("weight", 0.0))
			var of := float(saved.get("of", 0.0))
			var share := weight / of if weight > 0.0 and of >= weight else clampf(float(saved.get("share", 1.0)), 0.0, 1.0)
			encounter.members.append({
				"max": ScientificNumber.from_dict(saved.get("max", {})),
				"hp": ScientificNumber.from_dict(saved.get("hp", {})),
				"share": share,
				"weight": weight if weight > 0.0 and of >= weight else 0.0,
				"of": of if weight > 0.0 and of >= weight else 0.0,
				"arrive": arrive,
				"state": state,
				"wave": member_wave,
				"wave_hit": ScientificNumber.from_dict(wave_hit) if wave_hit is Dictionary else encounter.collection.copy(),
				"next_hit": next_hit,
				"interval": interval,
				"landed": landed,
				"boss": bool(saved.get("boss", encounter.is_boss and member_wave == encounter.wave)),
				# Far past any real run's count, and short of overflowing 1.04^n.
				"hits": clampi(int(saved.get("hits", 1 if landed else 0)), 0, 10000),
				"unpaid": clampf(float(saved.get("unpaid", 0.0)), 0.0, 1.0),
			})
		encounter._sum_remaining()
	# No member that parsed, or a wave saved before groups (V9 and older): one
	# member with what the wave had left, never a beaten wave for free.
	if encounter.members.is_empty() or not had_members:
		encounter = (load("res://src/tax_encounter.gd") as GDScript).new(
			encounter.tier_id, encounter.wave, encounter.max_liability, encounter.collection, encounter.reward, encounter.is_boss
		)
		encounter.set_remaining(ScientificNumber.from_dict(data.get("remaining_liability", data.get("max_liability", {}))))
	return encounter
