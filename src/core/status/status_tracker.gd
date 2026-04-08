extends RefCounted
class_name StatusTracker

## Tracks active status effects for a single entity (player or enemy).
## Handles applying, stacking, ticking, and expiring statuses.

const STATUS_REGISTRY_SCRIPT := preload("res://src/core/status/status_registry.gd")

var _active: Dictionary = {}
var _registry: Variant = null

func _init() -> void:
	_registry = STATUS_REGISTRY_SCRIPT.new()

func apply(effect_id: String, stacks: int = 1, duration: int = -1) -> Dictionary:
	if not _registry.has_effect(effect_id):
		return {"ok": false, "reason": "ERR_UNKNOWN_STATUS", "effect_id": effect_id}

	var max_stacks: int = _registry.get_max_stacks(effect_id)
	var resolved_duration: int = duration if duration > 0 else _registry.get_default_duration(effect_id)

	if _active.has(effect_id):
		var existing: Dictionary = _active[effect_id]
		var old_stacks: int = int(existing.get("stacks", 0))
		var new_stacks: int = min(old_stacks + stacks, max_stacks)
		var stack_behavior: String = str(_registry.get_effect(effect_id).get("stack_behavior", "additive"))
		if stack_behavior == "duration_refresh":
			existing["duration"] = resolved_duration
			existing["stacks"] = max(1, new_stacks)
		else:
			existing["stacks"] = new_stacks
		_active[effect_id] = existing
		return {
			"ok": true,
			"operation": "stack",
			"effect_id": effect_id,
			"stacks": int(existing.get("stacks", 0)),
			"duration": int(existing.get("duration", 0)),
		}

	_active[effect_id] = {
		"effect_id": effect_id,
		"stacks": min(stacks, max_stacks),
		"duration": resolved_duration,
	}
	return {
		"ok": true,
		"operation": "apply",
		"effect_id": effect_id,
		"stacks": min(stacks, max_stacks),
		"duration": resolved_duration,
	}

func has_status(effect_id: String) -> bool:
	return _active.has(effect_id)

func get_stacks(effect_id: String) -> int:
	if not _active.has(effect_id):
		return 0
	return int(_active[effect_id].get("stacks", 0))

func get_duration(effect_id: String) -> int:
	if not _active.has(effect_id):
		return 0
	return int(_active[effect_id].get("duration", 0))

func tick_turn_start() -> Array[Dictionary]:
	## Process all turn-start status ticks (e.g., poison damage).
	## Returns an array of tick result events.
	var results: Array[Dictionary] = []
	var to_remove: Array = []

	for effect_id in _active:
		var timing: String = _registry.get_tick_timing(effect_id)
		if timing != "turn_start":
			continue

		var entry: Dictionary = _active[effect_id]
		var stacks: int = int(entry.get("stacks", 0))
		var params: Dictionary = _registry.get_tick_params(effect_id)
		var formula: String = str(_registry.get_effect(effect_id).get("tick_formula", ""))

		var tick_result: Dictionary = {
			"effect_id": effect_id,
			"stacks": stacks,
			"formula": formula,
		}

		match formula:
			"damage_per_stack":
				var dmg_per: int = int(params.get("damage_per_stack", 1))
				tick_result["damage"] = stacks * dmg_per
				# Poison loses 1 stack per tick
				entry["stacks"] = max(0, stacks - 1)
				if int(entry.get("stacks", 0)) <= 0:
					to_remove.append(effect_id)

		_active[effect_id] = entry
		results.append(tick_result)

	for eid in to_remove:
		_active.erase(eid)

	return results

func tick_turn_end() -> void:
	## Decrement duration for duration-based effects at turn end.
	var to_remove: Array = []
	for effect_id in _active:
		var duration_type: String = _registry.get_duration_type(effect_id)
		if duration_type != "turns":
			continue
		var entry: Dictionary = _active[effect_id]
		entry["duration"] = max(0, int(entry.get("duration", 0)) - 1)
		if int(entry.get("duration", 0)) <= 0:
			to_remove.append(effect_id)
		else:
			_active[effect_id] = entry

	for eid in to_remove:
		_active.erase(eid)

func get_damage_dealt_multiplier() -> float:
	## Returns the combined multiplier for outgoing damage (strength/weakness).
	var mult: float = 1.0
	for effect_id in _active:
		var timing: String = _registry.get_tick_timing(effect_id)
		if timing != "on_deal_damage":
			continue
		var params: Dictionary = _registry.get_tick_params(effect_id)
		mult *= float(params.get("multiplier", 1.0))
	return mult

func get_damage_taken_multiplier() -> float:
	## Returns the combined multiplier for incoming damage (vulnerability).
	var mult: float = 1.0
	for effect_id in _active:
		var timing: String = _registry.get_tick_timing(effect_id)
		if timing != "on_take_damage":
			continue
		var params: Dictionary = _registry.get_tick_params(effect_id)
		mult *= float(params.get("multiplier", 1.0))
	return mult

func clear_all() -> void:
	_active = {}

func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect_id in _active:
		var entry: Dictionary = _active[effect_id].duplicate(true)
		entry["display_name"] = _registry.get_display_name(effect_id)
		entry["is_debuff"] = _registry.is_debuff(effect_id)
		result.append(entry)
	return result

func restore(statuses: Array) -> void:
	_active = {}
	for entry in statuses:
		if entry is Dictionary:
			var eid: String = str(entry.get("effect_id", ""))
			if eid != "":
				_active[eid] = entry.duplicate(true)
