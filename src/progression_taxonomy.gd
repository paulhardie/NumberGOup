class_name ProgressionTaxonomy
extends RefCounted

## Shared vocabulary for progression layers and the permanent Workshop.
const RESEARCH := "research"
const WORKSHOP := "workshop"
const MODULE := "module"
const PROTOCOL := "protocol"
const ROUTINE := "routine"
const BREAKTHROUGH := "breakthrough"
const KNOWLEDGE := "knowledge"
const LAW := "law"
const VIOLATION := "violation"

const ATTACK := "attack"
const DEFENSE := "defense"
const UTILITY := "utility"
const ULTIMATES := "ultimates"

const WORKSHOP_CATEGORIES := [ATTACK, DEFENSE, UTILITY, ULTIMATES]
const RESEARCH_FOCUS_CATEGORIES := [ATTACK, DEFENSE, UTILITY]
const CATEGORY_NAMES := {
	ATTACK: "ATTACK",
	DEFENSE: "DEFENSE",
	UTILITY: "UTILITY",
	ULTIMATES: "ULTIMATES",
}
const CATEGORY_DESCRIPTIONS := {
	ATTACK: "Beat waves before they Hit. Buy Attack when the ring is not closing before the timer runs out.",
	DEFENSE: "Survive the Hits. Buy Defense when Hits drain your Number.",
	UTILITY: "Get more from every run. Buy Utility when permanent progress feels slow.",
	ULTIMATES: "Rare, powerful and earned. Milestones unlock abilities that fire automatically.",
}
const LEGACY_CATEGORY_MAP := {
	"output": ATTACK,
	"speed": ATTACK,
	"chance": ATTACK,
	"logic": UTILITY,
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

static func category_description(category: String) -> String:
	return str(CATEGORY_DESCRIPTIONS.get(category, ""))

static func migrate_legacy_category(value: String, fallback: String = ATTACK) -> String:
	if WORKSHOP_CATEGORIES.has(value):
		return value
	return str(LEGACY_CATEGORY_MAP.get(value, fallback))
