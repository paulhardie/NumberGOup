class_name ProgressionTaxonomy
extends RefCounted

## This is the shared vocabulary for every progression layer. Keeping it separate
## from a build track (MORE / FASTER / SMARTER) prevents future systems from
## turning the main screen into an unstructured list of currencies and upgrades.
const RESEARCH := "research"
const WORKSHOP := "workshop"
const MODULE := "module"
const PROTOCOL := "protocol"
const ROUTINE := "routine"
const BREAKTHROUGH := "breakthrough"
const KNOWLEDGE := "knowledge"
const LAW := "law"
const VIOLATION := "violation"

## The four Workshop categories (D013). Each answers one failure the player can
## read off the run screen, which is why every row belongs to exactly one.
const ATTACK := "attack"
const DEFENSE := "defense"
const UTILITY := "utility"
const ULTIMATE := "ultimate"

const WORKSHOP_CATEGORIES := [ATTACK, DEFENSE, UTILITY, ULTIMATE]
const CATEGORY_NAMES := {
	ATTACK: "ATTACK",
	DEFENSE: "DEFENSE",
	UTILITY: "UTILITY",
	ULTIMATE: "ULTIMATE"
}
const CATEGORY_PURPOSES := {
	ATTACK: "Beat waves before they hit.",
	DEFENSE: "Survive the hits you can't beat.",
	UTILITY: "Get more from every run.",
	ULTIMATE: "Rare, powerful, earned."
}
## The line that lets a player map a failure to a shelf without a wiki.
const CATEGORY_BUY_WHEN := {
	ATTACK: "Buy when the ring isn't closing before the timer runs out.",
	DEFENSE: "Buy when a wave outlasts its timer and the hits drain your Number.",
	UTILITY: "Buy when you survive comfortably but progress between runs feels slow.",
	ULTIMATE: "Earned by reaching waves 10, 25, 50 and 100."
}

## Retired by D013. Kept for migration only, so a pre-V5 save's bay-shaped
## Research Focus and open tab land on the category that inherited that bay's
## upgrades. Output, Speed and Chance were all production, so all three become
## Attack; Logic was "spend and choose better", which is Utility.
const CATEGORY_FOR_LEGACY_BAY := {
	"output": ATTACK,
	"speed": ATTACK,
	"chance": ATTACK,
	"logic": UTILITY
}

const PLAYABLE_ORDER := [WORKSHOP, MODULE, PROTOCOL, ROUTINE]
const FUTURE_ORDER := [BREAKTHROUGH, KNOWLEDGE, LAW, VIOLATION]

const NAMES := {
	RESEARCH: "RESEARCH",
	WORKSHOP: "WORKSHOP",
	MODULE: "MODULES",
	PROTOCOL: "PROTOCOLS",
	ROUTINE: "ROUTINES",
	BREAKTHROUGH: "BREAKTHROUGHS",
	KNOWLEDGE: "KNOWLEDGE",
	LAW: "LAWS",
	VIOLATION: "VIOLATIONS"
}

const DESCRIPTIONS := {
	RESEARCH: "Choose a direction for the machine.",
	WORKSHOP: "Assemble the early machine that makes Number go up.",
	MODULE: "Direct improvements to Number production.",
	PROTOCOL: "Simple rules that change how modules interact.",
	ROUTINE: "Automation that removes mastered repetition.",
	BREAKTHROUGH: "A rare discovery that changes the machine itself.",
	KNOWLEDGE: "Permanent understanding retained beyond a reset.",
	LAW: "A fundamental rule of the Number universe.",
	VIOLATION: "A controlled exception to a Law."
}

static func display_name(progression_type: String) -> String:
	return str(NAMES.get(progression_type, progression_type.to_upper()))

static func description(progression_type: String) -> String:
	return str(DESCRIPTIONS.get(progression_type, ""))

static func is_future_layer(progression_type: String) -> bool:
	return FUTURE_ORDER.has(progression_type)

static func category_name(category: String) -> String:
	return str(CATEGORY_NAMES.get(category, category.to_upper()))

static func category_purpose(category: String) -> String:
	return str(CATEGORY_PURPOSES.get(category, ""))

static func category_buy_when(category: String) -> String:
	return str(CATEGORY_BUY_WHEN.get(category, ""))

## Idempotent: a value that is already a category passes through, a retired bay
## maps to its heir, and anything else (including "") returns "".
static func category_for_legacy_bay(bay: String) -> String:
	if WORKSHOP_CATEGORIES.has(bay):
		return bay
	return str(CATEGORY_FOR_LEGACY_BAY.get(bay, ""))
