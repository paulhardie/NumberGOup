class_name RuleModifierPipeline
extends RefCounted

## One ordered path for future Laws, Violations, challenges, perks and battle
## conditions. Supported stages intentionally have unambiguous semantics.
static func apply(base: ScientificNumber, target: String, modifiers: Array) -> ScientificNumber:
	var result := base.copy()
	for modifier in modifiers:
		if _matches(modifier, target, "flat"):
			result = result.add(ScientificNumber.from_dict(modifier.get("amount", {})))
	for modifier in modifiers:
		if _matches(modifier, target, "flat_reduce"):
			result = result.subtract(ScientificNumber.from_dict(modifier.get("amount", {})))
	var additive := 0.0
	for modifier in modifiers:
		if _matches(modifier, target, "additive"):
			additive += float(modifier.get("value", 0.0))
	result = result.multiply_scalar(maxf(0.0, 1.0 + additive))
	for modifier in modifiers:
		if _matches(modifier, target, "multiplicative"):
			result = result.multiply_scalar(maxf(0.0, float(modifier.get("value", 1.0))))
	for modifier in modifiers:
		if _matches(modifier, target, "cap_max"):
			var maximum := ScientificNumber.from_dict(modifier.get("amount", {}))
			if result.compare_to(maximum) > 0:
				result = maximum
	for modifier in modifiers:
		if _matches(modifier, target, "cap_min"):
			var minimum := ScientificNumber.from_dict(modifier.get("amount", {}))
			if result.compare_to(minimum) < 0:
				result = minimum
	return result

static func _matches(modifier: Variant, target: String, stage: String) -> bool:
	return modifier is Dictionary and str(modifier.get("target", "")) == target and str(modifier.get("stage", "")) == stage

