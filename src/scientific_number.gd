class_name ScientificNumber
extends RefCounted

## A positive decimal value stored as mantissa × 10^exponent.
## It intentionally has just the operations the economy needs, avoiding float overflow.
var mantissa: float = 0.0
var exponent: int = 0

func _init(value_mantissa: float = 0.0, value_exponent: int = 0) -> void:
	mantissa = value_mantissa
	exponent = value_exponent
	_normalize()

static func from_float(value: float) -> ScientificNumber:
	return ScientificNumber.new(value, 0)

static func from_dict(data: Dictionary) -> ScientificNumber:
	return ScientificNumber.new(float(data.get("mantissa", 0.0)), int(data.get("exponent", 0)))

func to_dict() -> Dictionary:
	return {"mantissa": mantissa, "exponent": exponent}

func copy() -> ScientificNumber:
	return ScientificNumber.new(mantissa, exponent)

func is_zero() -> bool:
	return mantissa <= 0.0

func compare_to(other: ScientificNumber) -> int:
	if is_zero() and other.is_zero():
		return 0
	if is_zero():
		return -1
	if other.is_zero():
		return 1
	if exponent != other.exponent:
		return 1 if exponent > other.exponent else -1
	if is_equal_approx(mantissa, other.mantissa):
		return 0
	return 1 if mantissa > other.mantissa else -1

func add(other: ScientificNumber) -> ScientificNumber:
	if other.is_zero():
		return copy()
	if is_zero():
		return other.copy()
	var largest := copy()
	var smallest := other
	if other.exponent > exponent:
		largest = other.copy()
		smallest = self
	var difference: int = largest.exponent - smallest.exponent
	if difference > 15:
		return largest
	largest.mantissa += smallest.mantissa * pow(10.0, -difference)
	largest._normalize()
	return largest

func subtract(other: ScientificNumber) -> ScientificNumber:
	if compare_to(other) < 0:
		return ScientificNumber.new()
	if other.is_zero():
		return copy()
	var difference: int = exponent - other.exponent
	if difference > 15:
		return copy()
	var result := copy()
	result.mantissa -= other.mantissa * pow(10.0, -difference)
	result._normalize()
	return result

func multiply_scalar(scalar: float) -> ScientificNumber:
	if scalar <= 0.0 or is_zero():
		return ScientificNumber.new()
	var result := ScientificNumber.new(mantissa * scalar, exponent)
	return result

func multiply(other: ScientificNumber) -> ScientificNumber:
	if is_zero() or other.is_zero():
		return ScientificNumber.new()
	return ScientificNumber.new(mantissa * other.mantissa, exponent + other.exponent)

func log10() -> float:
	if is_zero():
		return -INF
	return log(mantissa) / log(10.0) + float(exponent)

## Numbers stay as full grouped digits below this exponent (10^6 = under a million)
## rather than abbreviating to "1K" right away — a short suffix reads as tiny inside
## a screen-filling number display, so the wall of digits is kept for longer.
const FULL_DIGIT_EXPONENT_CEILING := 6

func format_value(decimals: int = 2) -> String:
	if is_zero():
		return "0"
	if exponent < FULL_DIGIT_EXPONENT_CEILING:
		return _group_integer(int(roundi(mantissa * pow(10.0, exponent))))
	var suffixes := ["K", "M", "B", "T", "Qa"]
	var group: int = exponent / 3
	if group <= suffixes.size():
		var scaled: float = mantissa * pow(10.0, exponent % 3)
		return _trim_decimal(scaled, decimals) + suffixes[group - 1]
	return _trim_decimal(mantissa, decimals) + "e" + str(exponent)

func _normalize() -> void:
	if mantissa <= 0.000000000001:
		mantissa = 0.0
		exponent = 0
		return
	while mantissa >= 10.0:
		mantissa /= 10.0
		exponent += 1
	while mantissa > 0.0 and mantissa < 1.0:
		mantissa *= 10.0
		exponent -= 1

static func _trim_decimal(value: float, decimals: int) -> String:
	var raw := ("%." + str(decimals) + "f") % value
	return raw.rstrip("0").rstrip(".")

static func _group_integer(value: int) -> String:
	var raw := str(value)
	var result := ""
	for index in range(raw.length()):
		if index > 0 and (raw.length() - index) % 3 == 0:
			result += ","
		result += raw[index]
	return result
