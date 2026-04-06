extends RefCounted
class_name GemStackMachine

var _stack: Array[String] = []
var _focus_charges: int = 0

func stack_snapshot() -> Array:
	return _stack.duplicate(true)

func focus_snapshot() -> int:
	return _focus_charges

func peek_top() -> String:
	if _stack.is_empty():
		return ""
	return _stack[_stack.size() - 1]

func peek_n(count: int) -> Array:
	if count <= 0 or _stack.is_empty():
		return []
	var start: int = max(0, _stack.size() - count)
	return _stack.slice(start, _stack.size())

func gain_focus(amount: int = 1) -> Dictionary:
	var gain: int = max(0, amount)
	_focus_charges += gain
	return {
		"ok": true,
		"focus_before": _focus_charges - gain,
		"focus_after": _focus_charges,
		"gained": gain,
	}

func clear_focus() -> void:
	_focus_charges = 0

func produce(gem: String, count: int = 1) -> Dictionary:
	var normalized: String = _normalize_gem(gem)
	if normalized == "":
		return {"ok": false, "reason": "ERR_GEM_INVALID"}
	if count <= 0:
		return {"ok": false, "reason": "ERR_COUNT_INVALID", "count": count}

	for _i in range(count):
		_stack.append(normalized)
	return {
		"ok": true,
		"operation": "produce",
		"gem": normalized,
		"count": count,
		"stack_after": stack_snapshot(),
	}

func consume_top(expected_gem: String = "") -> Dictionary:
	if _stack.is_empty():
		return {"ok": false, "reason": "ERR_STACK_EMPTY"}

	var normalized_expected: String = _normalize_gem(expected_gem)
	var top_gem: String = _stack[_stack.size() - 1]
	if normalized_expected != "" and top_gem != normalized_expected:
		return {
			"ok": false,
			"reason": "ERR_STACK_TOP_MISMATCH",
			"expected": normalized_expected,
			"actual": top_gem,
		}

	var consumed: String = _stack.pop_back()
	return {
		"ok": true,
		"operation": "consume_top",
		"gem": consumed,
		"stack_after": stack_snapshot(),
	}

func consume_from_top_offset(offset: int, expected_gem: String = "") -> Dictionary:
	if offset < 0:
		return {"ok": false, "reason": "ERR_SELECTOR_INVALID", "offset": offset}
	if _focus_charges <= 0:
		return {
			"ok": false,
			"reason": "ERR_FOCUS_REQUIRED",
			"offset": offset,
			"focus": _focus_charges,
		}
	if offset >= _stack.size():
		return {
			"ok": false,
			"reason": "ERR_SELECTOR_INVALID",
			"offset": offset,
			"stack_size": _stack.size(),
		}

	var index: int = _stack.size() - 1 - offset
	var target: String = _stack[index]
	var normalized_expected: String = _normalize_gem(expected_gem)
	if normalized_expected != "" and target != normalized_expected:
		return {
			"ok": false,
			"reason": "ERR_STACK_TARGET_MISMATCH",
			"expected": normalized_expected,
			"actual": target,
			"offset": offset,
		}

	_focus_charges -= 1
	_stack.remove_at(index)
	return {
		"ok": true,
		"operation": "consume_from_top_offset",
		"gem": target,
		"offset": offset,
		"focus_after": _focus_charges,
		"stack_after": stack_snapshot(),
	}

func _normalize_gem(gem: String) -> String:
	var value: String = str(gem).strip_edges()
	if value == "":
		return ""
	if value == "ruby" or value == "Ruby":
		return "Ruby"
	if value == "sapphire" or value == "Sapphire":
		return "Sapphire"
	return ""
