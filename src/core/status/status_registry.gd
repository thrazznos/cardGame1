extends RefCounted
class_name StatusRegistry

## Loads and provides status effect definitions from data files.

const EFFECTS_PATH := "res://data/status_effects/effects_v1.json"

static var _loaded: bool = false
static var _effects_by_id: Dictionary = {}

func _init() -> void:
	_ensure_loaded()

func has_effect(effect_id: String) -> bool:
	_ensure_loaded()
	return _effects_by_id.has(effect_id)

func get_effect(effect_id: String) -> Dictionary:
	_ensure_loaded()
	if not _effects_by_id.has(effect_id):
		return {}
	return _effects_by_id[effect_id].duplicate(true)

func get_display_name(effect_id: String) -> String:
	return str(get_effect(effect_id).get("display_name", effect_id))

func get_max_stacks(effect_id: String) -> int:
	return int(get_effect(effect_id).get("max_stacks", 1))

func get_tick_timing(effect_id: String) -> String:
	return str(get_effect(effect_id).get("tick_timing", ""))

func get_tick_params(effect_id: String) -> Dictionary:
	var params: Variant = get_effect(effect_id).get("tick_params", {})
	if params is Dictionary:
		return (params as Dictionary).duplicate(true)
	return {}

func get_duration_type(effect_id: String) -> String:
	return str(get_effect(effect_id).get("duration_type", "turns"))

func get_default_duration(effect_id: String) -> int:
	return int(get_effect(effect_id).get("default_duration", 1))

func get_tags(effect_id: String) -> Array:
	var tags: Variant = get_effect(effect_id).get("tags", [])
	if tags is Array:
		return tags.duplicate(true)
	return []

func is_debuff(effect_id: String) -> bool:
	return get_tags(effect_id).has("debuff")

func is_buff(effect_id: String) -> bool:
	return get_tags(effect_id).has("buff")

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_effects_by_id = {}
	if not FileAccess.file_exists(EFFECTS_PATH):
		_loaded = true
		return
	var file := FileAccess.open(EFFECTS_PATH, FileAccess.READ)
	if file == null:
		_loaded = true
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_loaded = true
		return
	for entry in (parsed as Dictionary).get("effects", []):
		if not (entry is Dictionary):
			continue
		var effect_id: String = str(entry.get("effect_id", "")).strip_edges()
		if effect_id != "":
			_effects_by_id[effect_id] = entry
	_loaded = true
