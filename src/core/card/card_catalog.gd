extends RefCounted
class_name CardCatalog

const CATALOG_PATH := "res://data/cards/catalog_v1.json"
const STARTER_DECK_PATH := "res://data/decks/starter_run_v1.json"
const VALIDATOR_SCRIPT := preload("res://src/core/card/card_validator.gd")
const TIMING_WINDOW_PRIORITIES := {
	"pre": 0,
	"main": 1,
	"post": 2,
}
const SPEED_CLASS_PRIORITIES := {
	"fast": 0,
	"normal": 1,
	"slow": 2,
}
const VALID_COST_TYPES := {
	"energy": true,
	"mana": true,
	"other": true,
}
const VALID_TARGET_MODES := {
	"self": true,
	"single_enemy": true,
	"none": true,
}
const VALID_INVALID_TARGET_POLICIES := {
	"fizzle": true,
	"retarget_if_possible": true,
	"retarget_random_deterministic": true,
}
const VALID_ZONE_ON_PLAY := ["discard", "exhaust", "retain", "temp"]

static var _loaded: bool = false
static var _cards_by_id: Dictionary = {}
static var _cards_in_order: Array = []
static var _alias_to_card_id: Dictionary = {}
static var _starter_run_deck: Array = []
static var _validation_errors: Array = []

func _init() -> void:
	_ensure_loaded()

func validation_errors() -> Array:
	_ensure_loaded()
	return _validation_errors.duplicate(true)

func has_card(card_id: String) -> bool:
	return _resolve_card_id(card_id) != ""

func resolved_card_id(card_id: String) -> String:
	return _resolve_card_id(card_id)

func get_card(card_id: String) -> Dictionary:
	_ensure_loaded()
	var resolved_id: String = _resolve_card_id(card_id)
	if resolved_id == "":
		return {}
	return _duplicate_card(_cards_by_id.get(resolved_id, {}))

func effects_for(card_id: String) -> Variant:
	var card: Dictionary = get_card(card_id)
	var effects: Array = _normalized_effects(card)
	if effects.is_empty():
		return {"type": "draw_n", "amount": 1}
	if effects.size() == 1:
		return effects[0].duplicate(true)
	return effects.duplicate(true)

func starter_run_deck() -> Array:
	_ensure_loaded()
	return _starter_run_deck.duplicate(true)

func base_cost(card_id: String) -> int:
	var card: Dictionary = get_card(card_id)
	return max(0, int(card.get("base_cost", 1)))

func cost_type(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("cost_type", "energy")).strip_edges()
	if not VALID_COST_TYPES.has(authored):
		return "energy"
	return authored

func target_mode(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("target_mode", "self")).strip_edges()
	if not VALID_TARGET_MODES.has(authored):
		return "self"
	return authored

func max_targets(card_id: String) -> int:
	return max(0, int(get_card(card_id).get("max_targets", 1)))

func invalid_target_policy(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("invalid_target_policy", "fizzle")).strip_edges()
	if not VALID_INVALID_TARGET_POLICIES.has(authored):
		return "fizzle"
	return authored

func play_conditions(card_id: String) -> Array:
	return _dictionary_array(get_card(card_id).get("play_conditions", []))

func combo_tags(card_id: String) -> Array:
	return _string_array(get_card(card_id).get("combo_tags", []))

func chain_flags(card_id: String) -> Array:
	return _string_array(get_card(card_id).get("chain_flags", []))

func weight_modifiers(card_id: String) -> Array:
	return _dictionary_array(get_card(card_id).get("weight_modifiers", []))

func timing_window(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("timing_window", "main")).strip_edges()
	if not TIMING_WINDOW_PRIORITIES.has(authored):
		return "main"
	return authored

func timing_window_priority(card_id: String) -> int:
	return int(TIMING_WINDOW_PRIORITIES.get(timing_window(card_id), 1))

func speed_class(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("speed_class", "normal")).strip_edges()
	if not SPEED_CLASS_PRIORITIES.has(authored):
		return "normal"
	return authored

func speed_class_priority(card_id: String) -> int:
	return int(SPEED_CLASS_PRIORITIES.get(speed_class(card_id), 1))

func zone_on_play(card_id: String) -> String:
	var authored: String = str(get_card(card_id).get("zone_on_play", "discard")).strip_edges()
	if VALID_ZONE_ON_PLAY.find(authored) == -1:
		return "discard"
	return authored

func reward_pool_entries(reward_pool_tag: String) -> Array:
	_ensure_loaded()
	var pool_tag: String = str(reward_pool_tag).strip_edges()
	if pool_tag == "":
		pool_tag = "base_reward"
	var entries: Array = []
	for card in _cards_in_order:
		var tags: Array = card.get("pool_tags", [])
		if not tags.has(pool_tag):
			continue
		entries.append({
			"card_id": str(card.get("card_id", "")),
			"rarity": str(card.get("rarity", "common")),
			"unlock_key": str(card.get("unlock_key", "base_set")),
			"weight_base": float(card.get("weight_base", 1.0)),
			"weight_modifiers": _dictionary_array(card.get("weight_modifiers", [])),
			"reward_order": int(card.get("reward_order", 999)),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("reward_order", 999)) < int(b.get("reward_order", 999)))
	for entry in entries:
		entry.erase("reward_order")
	return entries

func display_name(card_id: String) -> String:
	return str(get_card(card_id).get("display_name", card_id))

func role_marker(card_id: String) -> String:
	return str(get_card(card_id).get("role_marker", "[UTL]"))

func palette_key(card_id: String) -> String:
	return str(get_card(card_id).get("palette", "utility"))

func hand_rules_text(card_id: String) -> String:
	return str(get_card(card_id).get("hand_rules_text", "Draw 1 • Cost 1"))

func tooltip_text(card_id: String) -> String:
	return str(get_card(card_id).get("tooltip_text", "Utility card: draw 1 card."))

func reward_rules_text(card_id: String) -> String:
	var card: Dictionary = get_card(card_id)
	return str(card.get("reward_rules_text", card.get("hand_rules_text", "Add to deck • Draw 1 • Cost 1")))

func sim_metadata(card_id: String) -> Dictionary:
	var card: Dictionary = get_card(card_id)
	var metadata: Variant = card.get("sim_metadata", {})
	if metadata is Dictionary:
		return (metadata as Dictionary).duplicate(true)
	return {}

func value_proxy(card_id: String) -> float:
	var metadata: Dictionary = sim_metadata(card_id)
	if metadata.has("value_proxy"):
		return float(metadata.get("value_proxy", 0.0))
	var card: Dictionary = get_card(card_id)
	var effects: Array = _normalized_effects(card)
	var total: float = 0.0
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant
		var effect_type: String = str(effect.get("type", ""))
		match effect_type:
			"deal_damage":
				total += float(effect.get("amount", 0))
			"gain_block":
				total += float(effect.get("amount", 0))
			"draw_n":
				total += float(effect.get("amount", 0))
			"gem_produce":
				total += float(effect.get("count", 1))
			"gem_gain_focus":
				total += float(effect.get("amount", 1))
			"gem_consume_top":
				total += 1.0
			"gem_consume_top_offset":
				total += 1.0
			_:
				pass
	return total

static func _normalized_effects(card: Dictionary) -> Array:
	var normalized: Array = []
	for effect_variant in card.get("effects", []):
		var effect: Dictionary = _normalized_effect(effect_variant)
		if effect.is_empty():
			continue
		normalized.append(effect)
	return normalized

static func _normalized_effect(effect_variant: Variant) -> Dictionary:
	if not (effect_variant is Dictionary):
		return {}
	var effect: Dictionary = (effect_variant as Dictionary).duplicate(true)
	var legacy_type: String = str(effect.get("type", "")).strip_edges()
	if legacy_type != "":
		return effect
	var effect_id: String = str(effect.get("effect_id", "")).strip_edges()
	if effect_id == "":
		return {}
	var normalized: Dictionary = {}
	var params: Variant = effect.get("params", {})
	if params is Dictionary:
		normalized = (params as Dictionary).duplicate(true)
	normalized["type"] = effect_id
	return normalized

static func _string_array(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for entry in value:
		result.append(str(entry).strip_edges())
	return result

static func _dictionary_array(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for entry in value:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result

static func _ensure_loaded() -> void:
	if _loaded:
		return

	_cards_by_id = {}
	_cards_in_order = []
	_alias_to_card_id = {}
	_starter_run_deck = []
	_validation_errors = []

	var payload: Dictionary = _read_json(CATALOG_PATH)
	var validator = VALIDATOR_SCRIPT.new()
	_validation_errors = validator.validate_catalog(payload)
	for error in _validation_errors:
		push_error(str(error))

	var cards: Array = payload.get("cards", [])
	for entry in cards:
		if not (entry is Dictionary):
			continue
		var card: Dictionary = entry.duplicate(true)
		var card_id: String = str(card.get("card_id", "")).strip_edges()
		if card_id == "":
			continue
		_cards_by_id[card_id] = card
		_cards_in_order.append(card)
		var aliases: Array = card.get("aliases", [])
		for alias in aliases:
			var alias_id: String = str(alias).strip_edges()
			if alias_id == "":
				continue
			_alias_to_card_id[alias_id] = card_id

	var starter_payload: Dictionary = _read_json(STARTER_DECK_PATH)
	for card_id_variant in starter_payload.get("cards", []):
		_starter_run_deck.append(str(card_id_variant))

	_loaded = true

static func _resolve_card_id(card_id: String) -> String:
	_ensure_loaded()
	if _cards_by_id.has(card_id):
		return card_id
	return str(_alias_to_card_id.get(card_id, ""))

static func _duplicate_card(value: Variant) -> Dictionary:
	if value is Dictionary:
		var card: Dictionary = value
		return card.duplicate(true)
	return {}

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}
