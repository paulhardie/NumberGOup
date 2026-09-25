extends SceneTree

## Writes the live permanent-upgrade catalogues to data/workshop/current.json
## and a readable summary to data/workshop/current.md. It reads GameState,
## LabResearch and CardCollection directly, so the export can never drift from
## the game: rerun it after any catalogue change.
##
## Run: bash run_godot.sh --headless --path . -s res://tools/export_workshop.gd
const JSON_PATH := "res://data/workshop/current.json"
const MD_PATH := "res://data/workshop/current.md"
const SAMPLE_RANKS := [1, 10, 25, 50, 100, 1000, 5000]

func _init() -> void:
	var state := GameState.new()
	var workshop: Array = []
	var totals := {}
	for definition in state.definitions:
		if definition.progression_type == ProgressionTaxonomy.KNOWLEDGE:
			continue
		workshop.append(_workshop_row(state, definition))
		var category: String = definition.workshop_category
		totals[category] = int(totals.get(category, 0)) + int(workshop[-1].coins_to_max)
	var labs: Array = []
	for lab in state.lab_research.definitions:
		labs.append(_lab_row(state, lab))
	var cards: Array = []
	for card in state.card_collection.definitions:
		cards.append({
			"id": card.id,
			"name": card.title,
			"description": card.description,
			"rarity": card.rarity,
			"max_level": CardCollection.MAX_LEVEL,
			"effects_per_level": card.effects,
		})
	var data := {
		"generated_by": "tools/export_workshop.gd",
		"balance_profile": state.balance_profile.PROFILE_ID,
		"note": "Generated from the live catalogue. Edit the game, not this file.",
		"workshop_coins_to_max_by_category": totals,
		"workshop": workshop,
		"labs": labs,
		"cards": cards,
		"card_pull_cost_gems": CardCollection.PULL_COST_GEMS,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/workshop"))
	var file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ", false) + "\n")
	file = FileAccess.open(MD_PATH, FileAccess.WRITE)
	file.store_string(_markdown(data))
	print("WROTE ", ProjectSettings.globalize_path(JSON_PATH), " and current.md: ", workshop.size(), " Workshop rows, ", labs.size(), " Lab lines, ", cards.size(), " cards")
	quit(0)

func _workshop_row(state: GameState, definition: UpgradeDefinition) -> Dictionary:
	var ranks: Array = []
	var cumulative := 0
	for rank in range(1, definition.max_rank + 1):
		var cost := state.get_workshop_coin_cost_at(definition, rank - 1)
		cumulative += cost
		# Long rows keep every level to 300, then every 50th and the last, so
		# the export stays readable at 6,000 levels.
		if rank <= 300 or rank % 50 == 0 or rank == definition.max_rank:
			var shown := state.stat_display(definition, rank)
			ranks.append({"rank": rank, "cost": cost, "coins_to_here": cumulative, "value": snappedf(float(shown.value), 0.000001)})
	var at_zero := state.stat_display(definition, 0)
	var at_max := state.stat_display(definition, definition.max_rank)
	var group := state.get_group(definition.group)
	return {
		"id": definition.id,
		"name": definition.title,
		"description": definition.description,
		"category": definition.workshop_category,
		"unlock": definition.group,
		"unlock_coins": int(ceil(float(group.get("unlock_coins", 0.0)))),
		"max_rank": definition.max_rank,
		"unit": at_max.unit,
		"value_at_rank_0": snappedf(float(at_zero.value), 0.000001),
		"value_at_max": snappedf(float(at_max.value), 0.000001),
		"first_rank_coins": ranks[0].cost,
		"last_rank_coins": ranks[-1].cost,
		"coins_to_max": cumulative,
		"first_run_upgrade_cash": definition.cash_price_at(0),
		"ranks": ranks,
	}

func _lab_row(state: GameState, lab) -> Dictionary:
	var ranks: Array = []
	var coins := 0
	var seconds := 0.0
	for rank in range(1, lab.max_rank + 1):
		var cost: int = state.lab_research.cost_at(lab, rank - 1)
		var duration: float = state.lab_research.duration_at(lab, rank - 1, 0)
		coins += cost
		seconds += duration
		ranks.append({"rank": rank, "cost": cost, "seconds": snappedf(duration, 0.1), "coins_to_here": coins, "seconds_to_here": snappedf(seconds, 0.1)})
	return {
		"id": lab.id,
		"name": lab.title,
		"description": lab.description,
		"category": lab.category,
		"max_rank": lab.max_rank,
		"effects_per_rank": lab.effects,
		"coins_to_max": coins,
		"days_to_max_without_lab_speed": snappedf(seconds / 86400.0, 0.01),
		"ranks": ranks,
	}

## Percent rows are stored as fractions; the summary reads them as players do.
func _shown(value: float, unit: String) -> String:
	match unit:
		"percent":
			return str(snappedf(value * 100.0, 0.01)) + "%"
		"multiplier":
			return "×" + str(snappedf(value, 0.0001))
		"per_second":
			return (str(snappedf(value, 0.0001)) if value < 1000.0 else ScientificNumber.from_float(value).format_value()) + "/s"
		"metres":
			return str(snappedf(value, 0.01)) + " m"
		"per_metre":
			return "+" + str(snappedf(value * 100.0, 0.01)) + "%/m"
		"seconds":
			return str(snappedf(value, 0.01)) + " s"
		"rpm":
			return str(snappedf(value, 0.01)) + " rpm"
		"count":
			return str(int(value))
	return ScientificNumber.from_float(value).format_value()

func _markdown(data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# Workshop, Labs and Cards: current catalogue")
	lines.append("")
	lines.append("Generated by `tools/export_workshop.gd` from the live game (" + str(data.balance_profile) + "). Edit the game, not this file; the full per-rank tables are in `current.json`.")
	lines.append("")
	lines.append("## Workshop")
	lines.append("")
	lines.append("The Tower's rows, levels and prices (D068), from `data/workshop/upgrades.json`.")
	lines.append("")
	lines.append("| Category | Row | Id | Unlock (Coins) | Levels | At 0 | At max | First level | Last level | Coins to max | First run Upgrade |")
	lines.append("| --- | --- | --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: |")
	for row in data.workshop:
		lines.append("| %s | %s | `%s` | %s (%d) | %d | %s | %s | %d | %d | %d | $%s |" % [
			row.category, row.name, row.id, row.unlock, row.unlock_coins, row.max_rank,
			_shown(row.value_at_rank_0, row.unit), _shown(row.value_at_max, row.unit), row.first_rank_coins, row.last_rank_coins, row.coins_to_max,
			str(row.first_run_upgrade_cash)])
	lines.append("")
	for category in data.workshop_coins_to_max_by_category:
		lines.append("- **" + category.capitalize() + "** costs " + str(data.workshop_coins_to_max_by_category[category]) + " Coins to max.")
	lines.append("")
	lines.append("### Value and Coins to reach sample levels")
	lines.append("")
	lines.append("| Row | Level 1 | Level 10 | Level 25 | Level 50 | Level 100 | Level 1,000 | Level 5,000 |")
	lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
	for row in data.workshop:
		var cells: Array[String] = []
		for sample in SAMPLE_RANKS:
			if sample > int(row.max_rank):
				cells.append("—")
			else:
				var entry: Dictionary = {}
				for candidate in row.ranks:
					if int(candidate.rank) == sample:
						entry = candidate
						break
				cells.append(_shown(entry.value, row.unit) + " · " + str(entry.coins_to_here) + " C")
		lines.append("| " + str(row.name) + " | " + " | ".join(cells) + " |")
	lines.append("")
	lines.append("## Labs")
	lines.append("")
	lines.append("| Line | Ranks | Per rank | Coins to max | Days to max (no Lab Speed) |")
	lines.append("| --- | ---: | --- | ---: | ---: |")
	for lab in data.labs:
		lines.append("| %s | %d | %s | %d | %s |" % [lab.name, lab.max_rank, str(lab.effects_per_rank) if not (lab.effects_per_rank as Dictionary).is_empty() else "research speed", lab.coins_to_max, str(lab.days_to_max_without_lab_speed)])
	lines.append("")
	lines.append("## Cards")
	lines.append("")
	lines.append("A pull costs " + str(data.card_pull_cost_gems) + " Gems; cards level to " + str(CardCollection.MAX_LEVEL) + " through duplicate pulls.")
	lines.append("")
	lines.append("| Card | Rarity | Per level |")
	lines.append("| --- | --- | --- |")
	for card in data.cards:
		lines.append("| %s | %s | %s |" % [card.name, card.rarity, str(card.effects_per_level)])
	lines.append("")
	return "\n".join(lines)
