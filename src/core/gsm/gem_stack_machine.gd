extends RefCounted
class_name GemStackMachine

const DEFAULT_STACK_CAP := 6

var _stack: Array[String] = []
var _focus_charges: int = 0
var _stack_cap: int = DEFAULT_STACK_CAP

func stack_snapshot() -> Array:
	return _stack.duplicate(true)

func focus_snapshot() -> int:
	return _focus_charges

func stack_cap() -> int:
	return _stack_cap

func stack_remaining() -> int:
	return max(0, _stack_cap - _stack.size())

func reduce_cap(amount: int = 1) -> Dictionary:
	var before: int = _stack_cap
	_stack_cap = max(1, _stack_cap - max(0, amount))
	# If stack exceeds new cap, trim from bottom
	while _stack.size() > _stack_cap:
		_stack.remove_at(0)
	return {
		"ok": true,
		"cap_before": before,
		"cap_after": _stack_cap,
		"stack_after": stack_snapshot(),
	}

func save_state() -> Dictionary:
	return {
		"stack": _stack.duplicate(true),
		"focus_charges": _focus_charges,
		"stack_cap": _stack_cap,
	}

func restore_state(state: Dictionary) -> void:
	_stack = []
	for gem in state.get("stack", []):
		_stack.append(str(gem))
	_focus_charges = int(state.get("focus_charges", 0))
	_stack_cap = int(state.get("stack_cap", DEFAULT_STACK_CAP))

func reset_stack() -> void:
	_stack = []
	_focus_charges = 0

func grant_affinity_gem(gem: String) -> Dictionary:
	var normalized: String = _normalize_gem(gem)
	if normalized == "":
		return {"ok": false, "reason": "ERR_GEM_INVALID"}
	if _stack.size() >= _stack_cap:
		return {"ok": false, "reason": "ERR_STACK_FULL", "cap": _stack_cap}
	_stack.append(normalized)
	return {
		"ok": true,
		"operation": "affinity_grant",
		"gem": normalized,
		"stack_after": stack_snapshot(),
	}

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

	var produced: int = 0
	for _i in range(count):
		if _stack.size() >= _stack_cap:
			break
		_stack.append(normalized)
		produced += 1
	return {
		"ok": true,
		"operation": "produce",
		"gem": normalized,
		"count": produced,
		"requested": count,
		"capped": produced < count,
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
