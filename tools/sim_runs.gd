extends SceneTree
## Plays runs headless and prints where each ended: the measuring tool for
## the rebuild (docs/REBUILD_SPEC.md). A measurement, not a gate.
##
##   bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd -- --seeds 20 --buy cheapest
##
## --buy picks how the run spends its Cash, as a stand-in for a player:
##   none      never buys (the default)
##   cheapest  buys the cheapest level it can afford, as soon as it can
##   even      buys whichever open row has the fewest levels, when it can
##   attack    only Damage and Attack Speed, cheapest first
##   core      Damage, Attack Speed, Health, Health Regen and Defense
##             Absolute, cheapest first; in a career its Workshop does the same
##   grow      core in the run; in a career its Workshop also opens the Cash and
##             Coins groups and buys Coins / Kill Bonus and Coins / Wave with the rest
##   health    60% of the Cash earned goes to Health, the rest to the cheapest
##             other core row; in a career its Workshop buys as core does
##   survival  Health only while the Number is under half the run's best, the
##             rest to the cheapest of Damage, Attack Speed and Defense
##             Absolute; in a career its Workshop buys as core does
## --cap-minutes stops a run that is still alive (default 90).
## --divider-share N scales how many Dividers come (1 is Guesses.DIVIDER's,
## 0 none) and --divider-speed N sets their speed as a share of a basic
## enemy's, and --divider-health N its health in basic enemies', for trying
## the Divider's tuning without changing the game; --divider-divisor N fixes
## its divisor at every wave, and --divider-refill N the seconds a bite takes
## to come back (D134; 0, the game's, is Regen straight back).
## --tank-intro N brings the first tank on wave N (D144; 0 for none, as The
## Tower's mix alone). --lock off plays without Locks (D133); --lock-from N sets their first wave,
## --lock-every A:B their beat (every A waves, then every B from their full
## wave, which --lock-full N sets) and --lock-health N their health in basic
## enemies'. --overfill N sets how much
## of Lifesteal works past Health (0 a ceiling, 1 none), and --curve
## adds the Number at the end of every fifth wave to each run's line.
## --peak-drift N and --kill-share N try other numbers for how the Number
## grows (D111): regen's share past the run's best, and a clean kill's share
## of its Attack.
## --gains adds where the Number's gains came from: each source's share of
## all it gained, and after the slash its share of the new highs, the gains
## that lifted the Number past its best so far rather than refilling it.
##
## --workshop open plays each run with every Workshop group open at its
## first levels, --workshop max with every row at its last level too, and
## --workshop N with every row at level N (or its last, if lower): how far
## Tier 1 goes for a player who has bought that much.
##
## --workshop-unlock N, with --workshop, opens only the groups that cost N
## Coins or less to unlock (15000: every group up to Orbs).
##
## --workshop-coins N builds each run's Workshop by spending N Coins from a
## fresh one, as --workshop-plan says (core, turtle, blender, tank or spread; see
## WORKSHOP_PLANS): groups open in The Tower's order, up to --workshop-unlock
## (1.5M by default: everything below Super Crit, the Wall, Enemy Level Skip
## and Rend Armor), then the rest buys the plan's rows, cheapest for its weight
## first. Each run also prints what took the Number, by enemy kind.
##
## --until-wave N ends a career once a run reaches wave N, saying which run
## and after how many hours of game time; in single runs it ends each run there.
## --tier N plays each run in Tier N (1 to 3, D107): its enemies' health and
## attack, its Coins bonus and its spawns, from TowerData.tier.
## --career-seed N plays another career: run R is seed N × 1000 + R (0, the
## default, is run R on seed R, as before).
## Experiments that are not the game's rules (BattleSim's measuring options):
## --packages N opens Recovery Packages with its rows at level N in every run;
## --packages-to-best makes a package refill only to the run's best; and
## --sure-divider FROM:EVERY:DIVISOR lands a Divider nothing can stop, every
## EVERY waves from wave FROM.
## --careers N plays N runs in a row from a fresh Workshop instead, spending
## the Coins between runs: it opens the cheapest group it can, otherwise buys
## the open Workshop row with the fewest levels, until nothing is affordable.
## Each run buys with --buy (use even). Each row printed is one run.
## --cards ID:LEVEL,ID:LEVEL plays every run with those Cards equipped at
## those levels (D146; ids from data/cards/cards.json, built ones only), and
## --card-sweep LEVEL plays the seeds once with no card, then once with each
## built card alone at LEVEL, and prints each one's median wave, Cash and
## Coins beside the no-card line: what a card is worth to that build. Both
## work with --buy, --workshop and the other run options, and --cards with
## --careers too, where the cards come in only once a run has reached wave 20
## and opened Cards, as in the game (never with --legacy-progression). Both also take the
## card test series' candidates (Cards.CANDIDATES, docs/CARDS.md), which the
## game never draws: name them in --cards, or add --with-candidates to a sweep.
## --sweep-cards ID,ID, with --card-sweep, sweeps only those cards (built or
## candidate), plus the candidates if --with-candidates is given too. --cards
## takes each card once, and no more than the game's slots.
## --berserker-scale N multiplies Berserker's share in every run that has it
## (1, The Tower's, is the default): a Tier 1 Number absorbs only a few hundred
## damage in a run, so at The Tower's shares the card does nothing (docs/CARDS.md).
## --legacy-progression omits D126's wave rewards for a before/after career
## comparison; normal careers receive the same one-time rewards as the UI.

## --uncached-buys uses the original per-tick purchase checks for parity measurements.
## --json-out PATH also writes unrounded per-run measurements for balance comparisons.
## It never writes a player save; no output file is written after invalid options.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const Progression = preload("res://src/tower/progression.gd")
const Cards = preload("res://src/tower/cards.gd")

const STRATEGIES := ["none", "cheapest", "even", "attack", "core", "grow", "health", "survival"]
## With --buy health, this share of the Cash earned goes to Health.
const HEALTH_SHARE := 0.6
## With --buy survival, the rows bought when the Number isn't low.
const SURVIVAL_ROWS := ["damage", "attack_speed", "defense_absolute"]
## The rows a focused player buys, with --buy core: in the run, and in a
## career's Workshop (where it opens only the Defense group for them).
const CORE_ROWS := ["damage", "attack_speed", "health", "health_regen", "defense_absolute"]
## With --buy grow, a career's Workshop also opens the Cash and Coins groups and buys
## these with the core rows, cheapest first: a focused player who invests in
## income, as The Tower's players do. In the run it buys as core does.
const GROW_ROWS := ["coins_per_kill", "coins_per_wave"]
## Ways a player might spend a Workshop budget, for --workshop-coins: the
## groups to open (in The Tower's order, only while each costs at most half
## what's left), and each row's weight when choosing the next level to buy.
## "turtle" is The Tower's Tier 1 meta from its wiki's beginner guide (Defense
## Absolute first, Thorns for damage, Defense % after); "blender" its Tier 2
## pivot (Health, Lifesteal, Knockback, Orbs); "blender_thorns" that with
## Thorns bought too, as the wiki's Tier 2 "Blender Thorns" build has it (the
## plain blender opens Thorns but buys none, and stays as the balance
## baseline measured it); "blender_orbs" that with every orb bought first
## (max_first: one 120K orb never comes up cheapest beside hundreds of cheaper
## levels, but a blender player buys them all); "blender_orbline" that with
## Range also bought first to the orbs' circle (range_m, 60 m: where the orbs
## sit while Range is 60 m or less), as The Tower's blender sets its Range lab
## to the orbs, so enemies Knockback holds at the Range's edge sit on the
## orbs; "spread" everything evenly.
const WORKSHOP_PLANS := {
	"core": {"groups": ["defense"], "rows": {"damage": 1, "attack_speed": 1, "health": 1, "health_regen": 1, "defense_absolute": 1}},
	"turtle": {"groups": ["cash", "defense", "thorns"], "rows": {"defense_absolute": 3, "thorns": 2, "defense_percent": 1, "health": 1,
		"health_regen": 1, "damage": 1, "attack_speed": 1, "cash_per_wave": 1}},
	"blender": {"groups": ["defense", "thorns", "lifesteal", "knockback", "orbs"], "rows": {"damage": 1, "attack_speed": 1, "health": 2,
		"health_regen": 1, "defense_absolute": 1, "lifesteal": 1, "knockback_chance": 1, "knockback_force": 1, "orbs": 1, "orb_speed": 1}},
	"blender_thorns": {"groups": ["defense", "thorns", "lifesteal", "knockback", "orbs"], "rows": {"damage": 1, "attack_speed": 1, "health": 2,
		"health_regen": 1, "defense_absolute": 1, "lifesteal": 1, "knockback_chance": 1, "knockback_force": 1, "orbs": 1, "orb_speed": 1, "thorns": 2}},
	"blender_orbs": {"groups": ["defense", "thorns", "lifesteal", "knockback", "orbs"], "max_first": ["orbs"],
		"rows": {"damage": 1, "attack_speed": 1, "health": 2, "health_regen": 1, "defense_absolute": 1, "lifesteal": 1, "knockback_chance": 1,
		"knockback_force": 1, "orb_speed": 1, "thorns": 2}},
	"blender_orbline": {"groups": ["range", "defense", "thorns", "lifesteal", "knockback", "orbs"], "range_m": 60.0, "max_first": ["orbs"],
		"rows": {"damage": 1, "attack_speed": 1, "health": 2, "health_regen": 1, "defense_absolute": 1, "lifesteal": 1, "knockback_chance": 1,
		"knockback_force": 1, "orb_speed": 1, "thorns": 2}},
	"spread": {"groups": [], "rows": {}},
	# Never opens Defense Absolute: Health and Regen with a little killing, the
	# build Berserker (damage from damage absorbed) is meant for.
	"tank": {"groups": [], "rows": {"damage": 1, "attack_speed": 1, "health": 2, "health_regen": 2}},
}
## --berserker-scale, read once in _init.
var _berserker_scale := 1.0
var _measurements: Array[Dictionary] = []
var _export_measurements := false
var _cache_buys := true


func _init() -> void:
	var options := _options()
	_export_measurements = options.has("json-out")
	_cache_buys = not options.has("uncached-buys")
	var seeds := int(options.get("seeds", "10"))
	var cap_seconds := float(options.get("cap-minutes", "90")) * 60.0
	var strategy: String = options.get("buy", "none")
	if strategy not in STRATEGIES:
		printerr("--buy must be one of %s" % ", ".join(STRATEGIES))
		quit(1)
		return
	_berserker_scale = float(options.get("berserker-scale", "1"))
	if _berserker_scale <= 0.0:
		printerr("--berserker-scale takes a number above 0")
		quit(1)
		return
	var loadout := _card_effects(String(options.get("cards", "")))
	if loadout.is_empty():
		quit(1)
		return
	if options.has("careers"):
		if options.has("card-sweep"):
			printerr("--card-sweep plays single runs, not --careers")
			quit(1)
			return
		if not _career(int(options.careers), strategy, cap_seconds, options, loadout):
			quit(1)
			return
		quit(0 if _write_measurements(options) else 1)
		return
	var workshop: String = options.get("workshop", "")
	if workshop not in ["", "open", "max"] and not workshop.is_valid_int():
		printerr("--workshop must be open, max or a level")
		quit(1)
		return
	var levels := {}
	var groups: Array = BattleSim.START_GROUPS
	if options.has("workshop-coins"):
		var plan: String = options.get("workshop-plan", "core")
		if plan not in WORKSHOP_PLANS:
			printerr("--workshop-plan must be one of %s" % ", ".join(WORKSHOP_PLANS.keys()))
			quit(1)
			return
		var built := _budget_workshop(float(options["workshop-coins"]), plan, float(options.get("workshop-unlock", "1500000")))
		levels = built.levels
		groups = built.open_groups
		print("Workshop from %s Coins, %s: %s" % [options["workshop-coins"], plan, _levels_text(levels)])
	elif workshop != "":
		groups = TowerData.groups().map(func(entry): return String(entry.id))
		if options.has("workshop-unlock"):
			groups = TowerData.groups().filter(func(entry): return float(entry.unlock_coins) <= float(options["workshop-unlock"])).map(func(entry): return String(entry.id))
		if workshop != "open":
			for id in TowerData.rows():
				if TowerData.group(id) in groups:
					levels[id] = TowerData.max_level(id) if workshop == "max" else mini(int(workshop), TowerData.max_level(id))
	if (options.has("sweep-cards") or options.has("with-candidates")) and not options.has("card-sweep"):
		printerr("--sweep-cards and --with-candidates go with --card-sweep LEVEL")
		quit(1)
		return
	if options.has("card-sweep"):
		var level := int(options["card-sweep"])
		if level < 1 or level > Cards.max_level():
			printerr("--card-sweep takes a level from 1 to %d" % Cards.max_level())
			quit(1)
			return
		var measured := _card_sweep(level, seeds, levels, groups, strategy, cap_seconds, options)
		quit(0 if measured and _write_measurements(options) else 1)
		return
	var waves: Array[int] = []
	print("buying: %s%s%s" % [strategy, ", Workshop " + workshop if workshop != "" else "", ", Cards " + options.cards if options.has("cards") else ""])
	print("seed  wave  game time  kills  cash earned  coins  peak Number  ÷ came/landed  ÷ took  killed by  levels bought")
	for index in range(seeds):
		var sim := BattleSim.new(index + 1, levels, groups, int(options.get("tier", "1")), loadout.stat, loadout.rule)
		if not _tune(sim, options):
			quit(1)
			return
		var last_wave := int(options.get("until-wave", "0"))
		while sim.alive and sim.time < cap_seconds and (last_wave <= 0 or sim.wave < last_wave):
			_spend(sim, strategy)
			sim.step()
		waves.append(sim.wave)
		_record_run(sim, "run", 0, cap_seconds)
		print("%4d  %4d  %9s  %5d  %11.0f  %5.0f  %11.1f  %13s  %5.0f%%  %-9s  %s" % [index + 1, sim.wave, _clock(sim.time), sim.kills, sim.cash_earned, sim.coins,
			sim.peak_number, "%d/%d" % [sim.dividers_spawned, sim.dividers_landed], _divider_share_of_loss(sim),
			sim.killed_by if not sim.alive else "(alive)", _bought(sim)] + _curve(sim, options) + _gains(sim, options) + _losses(sim, options))
	waves.sort()
	print("median wave %d, range %d to %d" % [waves[waves.size() / 2], waves[0], waves[-1]])
	quit(0 if _write_measurements(options) else 1)


## The effects of Cards given as "id:level,id:level", split by domain:
## {stat, rule}; empty, having said why, if a card isn't built or a level
## isn't 1 to 7.
func _card_effects(spec: String) -> Dictionary:
	var effects := []
	var seen: Array[String] = []
	if spec.split(",", false).size() > Cards.max_slots():
		printerr("--cards takes at most %d cards, the game's slots" % Cards.max_slots())
		return {}
	for part in spec.split(",", false):
		var pieces := part.split(":")
		var id := pieces[0].strip_edges()
		var level := int(pieces[1]) if pieces.size() > 1 else 1
		if not (Cards.built(id) or Cards.candidate(id)) or id in seen or level < 1 or level > Cards.max_level():
			printerr("--cards takes built or candidate cards, once each, at levels 1 to %d: %s (built: %s; candidates: %s)" % [Cards.max_level(), part,
				", ".join(Cards.built_ids()), ", ".join(Cards.CANDIDATES.keys())])
			return {}
		seen.append(id)
		for effect in Cards.effects_at(id, level):
			if id == "berserker":
				effect.value = float(effect.value) * _berserker_scale
			effects.append(effect)
	return {"stat": effects.filter(func(effect): return effect.domain == "stat"), "rule": effects.filter(func(effect): return effect.domain == "rule")}


## --card-sweep: the seeds with no card, then with each built card alone at
## `level`, as one line each of medians.
func _card_sweep(level: int, seeds: int, levels: Dictionary, groups: Array, strategy: String, cap_seconds: float, options: Dictionary) -> bool:
	print("card sweep at level %d, %d seeds, buying %s%s" % [level, seeds, strategy, ", Workshop " + options.workshop if options.has("workshop") else ""])
	print("card                     value   median wave   range      median Cash   median Coins")
	var cases: Array = [""]
	cases.append_array(Cards.built_ids())
	if options.has("sweep-cards"):
		cases = [""]
		cases.append_array(String(options["sweep-cards"]).split(",", false))
	if options.has("with-candidates"):
		cases.append_array(Cards.CANDIDATES.keys().filter(func(id): return id not in cases))
	var base_coins := 0.0
	for id in cases:
		var loadout := _card_effects("" if id == "" else "%s:%d" % [id, level])
		if loadout.is_empty():
			return false
		var waves: Array[int] = []
		var cash: Array[float] = []
		var coins: Array[float] = []
		for index in range(seeds):
			var sim := BattleSim.new(index + 1, levels, groups, int(options.get("tier", "1")), loadout.stat, loadout.rule)
			if not _tune(sim, options):
				return false
			var last_wave := int(options.get("until-wave", "0"))
			while sim.alive and sim.time < cap_seconds and (last_wave <= 0 or sim.wave < last_wave):
				_spend(sim, strategy)
				sim.step()
			waves.append(sim.wave)
			_record_run(sim, "no_card" if id == "" else id, 0, cap_seconds)
			cash.append(sim.cash_earned)
			coins.append(sim.coins)
		waves.sort()
		cash.sort()
		coins.sort()
		var median_coins := coins[coins.size() / 2]
		if id == "":
			base_coins = median_coins
		var shown := "(no card)" if id == "" else String(Cards.definition(id).name) + (" *" if Cards.candidate(id) else "")
		var value := "" if id == "" else preload("res://src/ui/cards_screen.gd").describe(id, level)
		print("%-24s %6s   %11d   %3d–%-4d   %11.0f   %12.0f%s" % [shown, value, waves[waves.size() / 2], waves[0], waves[-1], cash[cash.size() / 2], median_coins,
			"  (%+.0f%%)" % (100.0 * (median_coins / base_coins - 1.0)) if id != "" and base_coins > 0.0 else ""])
	return true


func _career(runs: int, strategy: String, cap_seconds: float, options: Dictionary, loadout: Dictionary) -> bool:
	var workshop := Workshop.new()
	var progression := Progression.new(workshop)
	var hours := 0.0
	print("career, buying %s in each run, %d-minute cap%s" % [strategy, int(cap_seconds / 60.0), ", Cards " + options.cards if options.has("cards") else ""])
	print("run  wave  game time  hours  coins earned  coins left  peak Number  start Number  last wave's Number  ÷ came/landed  killed by  Workshop")
	var until := int(options.get("until-wave", "0"))
	var seed_base := int(options.get("career-seed", "0")) * 1000
	for run in range(runs):
		# Cards open at wave 20 (D146): the career plays without them until then.
		var carded := progression.unlocked("cards")
		var sim := BattleSim.new(seed_base + run + 1, workshop.levels, workshop.open_groups, int(options.get("tier", "1")),
			loadout.stat if carded else [], loadout.rule if carded else [])
		if not _tune(sim, options):
			return false
		var start_number := sim.health
		while sim.alive and sim.time < cap_seconds:
			_spend(sim, strategy)
			sim.step()
		_record_run(sim, "career", run + 1, cap_seconds)
		workshop.add_coins(sim.coins)
		var before_rewards := workshop.coins
		workshop.finish_run(sim.wave, sim.peak_number)
		# Same one-time rewards as the screens; the switch measures D125's
		# earlier progression without altering any battle rules.
		if not options.has("legacy-progression"):
			progression.observe(sim.tier, sim.wave, sim.wave if sim.killed_by == "data_limit" else sim.wave - 1)
		if _export_measurements:
			_measurements[-1]["permanent_rewards"] = workshop.coins - before_rewards
		hours += sim.time / 3600.0
		_spend_workshop(workshop, strategy)
		# The Number as the wave it ended on began (at death it reads 0).
		var entering: float = float(sim.wave_log[-1].health) if not sim.wave_log.is_empty() else start_number
		print("%3d  %4d  %9s  %5.1f  %12.0f  %10.0f  %11.0f  %12.0f  %18.0f  %13s  %-9s  %s" % [run + 1, sim.wave, _clock(sim.time), hours, sim.coins, workshop.coins,
			sim.peak_number, start_number, entering, "%d/%d" % [sim.dividers_spawned, sim.dividers_landed], sim.killed_by if not sim.alive else "(alive)", _workshop_summary(workshop)] + _curve(sim, options) + _gains(sim, options))
		if until > 0 and sim.wave >= until:
			print("reached wave %d on run %d, after %.1f hours of game time" % [until, run + 1, hours])
			return true

	return true


func _spend_workshop(workshop: Workshop, strategy: String) -> void:
	if strategy in ["core", "grow", "health", "survival"]:
		# The Coins group opens only after Cash, in The Tower's order.
		var groups := ["defense", "cash", "coins"] if strategy == "grow" else ["defense"]
		var rows: Array = CORE_ROWS + GROW_ROWS if strategy == "grow" else CORE_ROWS
		while true:
			var closed := groups.filter(func(group): return not workshop.is_group_open(group))
			if not closed.is_empty():
				if not workshop.open_group(closed[0]):
					return
				continue
			var cheapest := ""
			for id in rows:
				if workshop.level(id) < TowerData.max_level(id) and (cheapest == "" or workshop.price(id) < workshop.price(cheapest)):
					cheapest = id
			if cheapest == "" or not workshop.buy(cheapest):
				return
	while true:
		var cheapest_group := ""
		for category in ["attack", "defense", "utility"]:
			var group := workshop.next_group(category)
			if group != "" and workshop.can_open(group) and (cheapest_group == "" or TowerData.group_price(group) < TowerData.group_price(cheapest_group)):
				cheapest_group = group
		if cheapest_group != "":
			workshop.open_group(cheapest_group)
			continue
		var fewest := ""
		for id in TowerData.rows():
			if workshop.is_group_open(TowerData.group(id)) and workshop.level(id) < TowerData.max_level(id):
				if fewest == "" or workshop.level(id) < workshop.level(fewest):
					fewest = id
		if fewest == "" or not workshop.buy(fewest):
			return


## A fresh Workshop with `coins` spent as `plan` says (WORKSHOP_PLANS), opening
## no group that costs more than `unlock_cap` to unlock.
func _budget_workshop(coins: float, plan: String, unlock_cap: float) -> Workshop:
	var workshop := Workshop.new()
	workshop.coins = coins
	var wanted: Array = WORKSHOP_PLANS[plan].groups
	var weights: Dictionary = WORKSHOP_PLANS[plan].rows
	# A group opens only after those before it in its tab, as in The Tower.
	var opening := true
	while opening:
		opening = false
		for category in ["attack", "defense", "utility"]:
			var next := workshop.next_group(category)
			if next == "" or TowerData.group_price(next) > unlock_cap or TowerData.group_price(next) > workshop.coins * 0.5:
				continue
			var needed := plan == "spread"
			for group in wanted:
				if TowerData.group_category(group) == category and not workshop.is_group_open(group):
					needed = true
			if needed and workshop.open_group(next):
				opening = true
	# A plan with max_first buys those rows to their last level before
	# anything else; one with range_m buys Range first, to the first level
	# reaching it, and no further (its weights leave Range out).
	for id in WORKSHOP_PLANS[plan].get("max_first", []):
		while workshop.is_group_open(TowerData.group(id)) and workshop.level(id) < TowerData.max_level(id) and workshop.buy(id):
			pass
	var range_m := float(WORKSHOP_PLANS[plan].get("range_m", 0.0))
	while range_m > 0.0 and workshop.is_group_open(TowerData.group("range")) and TowerData.value("range", workshop.level("range")) < range_m:
		if not workshop.buy("range"):
			break
	while true:
		var best := ""
		var best_cost := INF
		for id in TowerData.rows():
			var weight := float(weights.get(id, 1.0 if plan == "spread" else 0.0))
			if weight <= 0.0 or not workshop.is_group_open(TowerData.group(id)) or workshop.level(id) >= TowerData.max_level(id):
				continue
			if workshop.price(id) / weight < best_cost:
				best = id
				best_cost = workshop.price(id) / weight
		if best == "" or not workshop.buy(best):
			break
	return workshop


func _levels_text(levels: Dictionary) -> String:
	var parts: Array[String] = []
	for id in levels:
		if int(levels[id]) > 0:
			parts.append("%s %d" % [id, int(levels[id])])
	return ", ".join(parts)


## With --workshop-coins, what took the Number, as each kind's share of all
## it lost: " | lost: basic 40%, ranged 35%, …", then what made the kills, as
## each source's share: " | kills: shot 80%, orb 15%, …".
func _losses(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("workshop-coins"):
		return ""
	var total := 0.0
	for kind in sim.lost_to:
		total += float(sim.lost_to[kind])
	# How long a Lock held the Number (D133), before what took it.
	var held := " | held %.0f%% of the run" % (100.0 * sim.locked_seconds / sim.time) if sim.locked_seconds > 0.0 else ""
	if total <= 0.0:
		return held + " | lost: nothing"
	var kinds := sim.lost_to.keys()
	kinds.sort_custom(func(a, b): return sim.lost_to[a] > sim.lost_to[b])
	return held + " | lost: " + ", ".join(kinds.map(func(kind): return "%s %.0f%%" % [kind, 100.0 * float(sim.lost_to[kind]) / total])) + _kill_sources(sim)


func _kill_sources(sim: BattleSim) -> String:
	if sim.kills <= 0:
		return ""
	var sources := sim.kills_by.keys()
	sources.sort_custom(func(a, b): return sim.kills_by[a] > sim.kills_by[b])
	return " | kills: " + ", ".join(sources.map(func(source): return "%s %.0f%%" % [source, 100.0 * float(sim.kills_by[source]) / sim.kills]))


func _workshop_summary(workshop: Workshop) -> String:
	var opened: Array[String] = []
	for group in workshop.open_groups:
		if TowerData.group_price(group) > 0.0:
			opened.append(group)
	var total := 0
	for id in workshop.levels:
		total += int(workshop.levels[id])
	return "%d levels; opened %s" % [total, ", ".join(opened) if not opened.is_empty() else "nothing"]


func _spend(sim: BattleSim, strategy: String) -> void:
	if strategy == "none":
		return
	if strategy == "health":
		_spend_health_heavy(sim)
		return
	if strategy == "survival":
		_spend_survival(sim)
		return
	# These fixed policies depend only on Cash and upgrade levels. The only
	# automatic level changes happen at wave boundaries (Free Upgrades), so
	# nothing affordable can change between checks with the same Cash/wave.
	# Health-sensitive policies above must still run on every tick.
	if _cache_buys and sim.get_meta("last_spend_cash", NAN) == sim.cash and sim.get_meta("last_spend_wave", -1) == sim.wave and sim.get_meta("last_spend_policy", "") == strategy:
		return
	while true:
		var choice := _choose(sim, strategy)
		if choice == "" or not sim.buy(choice):
			break
	sim.set_meta("last_spend_cash", sim.cash)
	sim.set_meta("last_spend_wave", sim.wave)
	sim.set_meta("last_spend_policy", strategy)


## --buy health: every Cash earned is split into a Health budget and a budget
## for the other core rows, and each is spent only on its own rows, waiting
## for the cheapest as core does.
func _spend_health_heavy(sim: BattleSim) -> void:
	var fresh: float = sim.cash_earned - float(sim.get_meta("split", 0.0))
	sim.set_meta("split", sim.cash_earned)
	var for_health: float = float(sim.get_meta("for_health", 0.0)) + fresh * HEALTH_SHARE
	var for_rest: float = float(sim.get_meta("for_rest", 0.0)) + fresh * (1.0 - HEALTH_SHARE)
	while sim.is_open("health") and not sim.at_max("health") and sim.price("health") <= for_health and sim.can_buy("health"):
		for_health -= sim.price("health")
		sim.buy("health")
	while true:
		var cheapest := _cheapest(sim, CORE_ROWS.filter(func(id): return id != "health"))
		if cheapest == "" or sim.price(cheapest) > for_rest or not sim.can_buy(cheapest):
			break
		for_rest -= sim.price(cheapest)
		sim.buy(cheapest)
	sim.set_meta("for_health", for_health)
	sim.set_meta("for_rest", for_rest)


## --buy survival: Health only while the Number is under half the run's best,
## otherwise the cheapest of Damage, Attack Speed and Defense Absolute.
func _spend_survival(sim: BattleSim) -> void:
	while sim.health < 0.5 * sim.peak_number and sim.can_buy("health"):
		sim.buy("health")
	while true:
		var cheapest := _cheapest(sim, SURVIVAL_ROWS)
		if cheapest == "" or not sim.buy(cheapest):
			return


func _cheapest(sim: BattleSim, ids: Array) -> String:
	var best := ""
	for id in ids:
		if sim.is_open(id) and not sim.at_max(id) and (best == "" or sim.price(id) < sim.price(best)):
			best = id
	return best


## The row the strategy buys next, or "" to wait. It waits for its choice
## rather than buying something else, as a player saving up would.
func _choose(sim: BattleSim, strategy: String) -> String:
	var rows: Array[String] = []
	for id in TowerData.rows():
		var allowed: bool = (strategy != "attack" or id in ["damage", "attack_speed"]) and (strategy not in ["core", "grow"] or id in CORE_ROWS)
		if sim.is_open(id) and not sim.at_max(id) and allowed:
			rows.append(id)
	if rows.is_empty():
		return ""
	var best := rows[0]
	for id in rows:
		var better := sim.price(id) < sim.price(best) if strategy != "even" else int(sim.run_levels.get(id, 0)) < int(sim.run_levels.get(best, 0))
		if better:
			best = id
	return best if sim.can_buy(best) else ""


## With --curve, the Number at the end of every fifth wave, as " | 5:12 10:40 …".
func _curve(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("curve"):
		return ""
	var points: Array[String] = []
	for snapshot in sim.wave_log:
		if int(snapshot.wave) % 5 == 0:
			points.append("%d:%.0f" % [int(snapshot.wave), float(snapshot.health)])
	return "  | " + " ".join(points)


## With --gains, " | gained 312: regen 71%/88% health 29%/12%": each source's
## share of everything gained, then of the new highs.
func _gains(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("gains"):
		return ""
	var total := 0.0
	var highs := 0.0
	for source in sim.gained_from:
		total += float(sim.gained_from[source])
	for source in sim.raised_by:
		highs += float(sim.raised_by[source])
	var parts: Array[String] = []
	for source in ["regen", "health", "lifesteal", "package", "kills"]:
		if sim.gained_from.has(source):
			parts.append("%s %.0f%%/%.0f%%" % [source, 100.0 * float(sim.gained_from[source]) / total,
				100.0 * float(sim.raised_by.get(source, 0.0)) / highs if highs > 0.0 else 0.0])
	return "  | gained %.0f, highs %.0f: %s" % [total, highs, " ".join(parts)]


func _tune(sim: BattleSim, options: Dictionary) -> bool:
	if options.has("peak-drift"):
		sim.peak_drift = float(options["peak-drift"])
	if options.has("packages"):
		if not "recovery_packages" in sim.open_groups:
			sim.open_groups.append("recovery_packages")
		for id in TowerData.group_rows("recovery_packages"):
			sim.levels[id] = mini(int(options["packages"]), TowerData.max_level(id))
	sim.packages_to_best = options.has("packages-to-best")
	if options.has("sure-divider"):
		var parts: PackedStringArray = String(options["sure-divider"]).split(":")
		sim.sure_from = int(parts[0])
		sim.sure_every = int(parts[1])
		sim.sure_divisor = float(parts[2])
	if options.has("kill-share"):
		sim.kill_share = float(options["kill-share"])
	if options.has("divider-share"):
		var scale := float(options["divider-share"])
		sim.divider.rate_first = minf(1.0, float(sim.divider.rate_first) * scale)
		sim.divider.rate_full = minf(1.0, float(sim.divider.rate_full) * scale)
	if options.has("divider-speed"):
		sim.divider.speed = float(options["divider-speed"])
	if options.has("overfill"):
		sim.overfill = float(options.overfill)
	if options.has("divider-divisor"):
		sim.divider.divisor_first = float(options["divider-divisor"])
		sim.divider.divisor_full = float(options["divider-divisor"])
	if options.has("divider-health"):
		sim.divider.health_first = float(options["divider-health"])
		sim.divider.health_full = float(options["divider-health"])
	if options.has("divider-refill"):
		sim.divider.refill_seconds = float(options["divider-refill"])
	if options.has("tank-intro"):
		sim.tank_intro = int(options["tank-intro"])
	if options.get("lock", "") == "off":
		sim.lock.from_wave = 0
	if options.has("lock-from"):
		sim.lock.from_wave = int(options["lock-from"])
	if options.has("lock-full"):
		sim.lock.full_wave = int(options["lock-full"])
	if options.has("lock-every"):
		var beat: PackedStringArray = String(options["lock-every"]).split(":")
		sim.lock.every_first = int(beat[0])
		sim.lock.every_full = int(beat[beat.size() - 1])
	if options.has("lock-health"):
		sim.lock.health = float(options["lock-health"])
	if not sim.configure_tuning(sim.tuning_config()):
		printerr("Unsupported measuring tuning; check positive intervals and finite, bounded values.")
		return false
	return true


## The share of everything the Number lost that Dividers took.
func _divider_share_of_loss(sim: BattleSim) -> float:
	var total := 0.0
	for kind in sim.lost_to:
		total += float(sim.lost_to[kind])
	return 100.0 * float(sim.lost_to.get("divider", 0.0)) / total if total > 0.0 else 0.0


func _bought(sim: BattleSim) -> String:
	var parts: Array[String] = []
	for id in sim.run_levels:
		parts.append("%s %d" % [id, sim.run_levels[id]])
	return ", ".join(parts)


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _options() -> Dictionary:
	var found := {}
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index].begins_with("--"):
			# An option with no value after it, like --curve, is a switch.
			var has_value := index + 1 < args.size() and not args[index + 1].begins_with("--")
			found[args[index].substr(2)] = args[index + 1] if has_value else "true"
	return found


## JSON keeps measurements separate from rounded console text. A stopped run
## is censored, not a death; a career still follows its existing spending policy.
func _record_run(sim: BattleSim, case_id: String, run: int, cap_seconds: float) -> void:
	if not _export_measurements:
		return
	var reached := {}
	for target in [10, 20, 30]:
		if sim.wave >= target:
			# Wave logs describe completed waves. Reaching N is finishing N-1.
			for point in sim.wave_log:
				if int(point.wave) == target - 1:
					reached[str(target)] = float(point.time)
					break
	_measurements.append({"case": case_id, "seed": sim.run_seed, "run": run,
		"wave": sim.wave, "game_seconds": sim.time, "kills": sim.kills,
		"cash": sim.cash_earned, "coins": sim.coins, "peak_number": sim.peak_number,
		"stop": ("time_cap" if sim.time >= cap_seconds else "wave_target") if sim.alive else ("data_limit" if sim.killed_by == "data_limit" else "death"),
		"killed_by": sim.killed_by, "reached": reached,
		"dividers_spawned": sim.dividers_spawned, "dividers_landed": sim.dividers_landed,
		"lost_to": sim.lost_to.duplicate(), "damage_by": sim.damage_by.duplicate(),
		"start": sim.start_config()})


func _write_measurements(options: Dictionary) -> bool:
	if not options.has("json-out"):
		return true
	var path := String(options["json-out"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write measurements: %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify({"schema": 1, "engine": Engine.get_version_info().string,
		"data_signature": TowerData.data_signature(), "built_cards": Cards.built_ids(),
		"options": options, "runs": _measurements}, "\t", true, true) + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		printerr("Could not finish writing measurements: %s (error %d)" % [path, error])
		return false
	return true
