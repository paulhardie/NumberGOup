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

const WORKSHOP_BAYS := ["output", "speed", "chance", "logic"]
const BAY_NAMES := {"output": "OUTPUT", "speed": "SPEED", "chance": "CHANCE", "logic": "LOGIC"}
const BAY_DESCRIPTIONS := {
	"output": "Make every Number event larger.",
	"speed": "Create Number events more often.",
	"chance": "Improve positive special events.",
	"logic": "Make the machine spend and choose better."
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

static func bay_name(bay: String) -> String:
	return str(BAY_NAMES.get(bay, bay.to_upper()))

static func bay_description(bay: String) -> String:
	return str(BAY_DESCRIPTIONS.get(bay, ""))
