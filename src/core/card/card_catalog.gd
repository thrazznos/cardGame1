extends RefCounted
class_name CardCatalog

const CATALOG_PATH := "res://data/cards/catalog_v1.json"
const STARTER_DECK_PATH := "res://data/decks/starter_run_v1.json"
const VALIDATOR_SCRIPT := preload("res://src/core/card/card_validator.gd")

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
	var effects: Array = card.get("effects", [])
	if effects.is_empty():
		return {"type": "draw_n", "amount": 1}
	if effects.size() == 1:
		return effects[0].duplicate(true)
	return effects.duplicate(true)

func starter_run_deck() -> Array:
	_ensure_loaded()
	return _starter_run_deck.duplicate(true)

func reward_pool_entries(checkpoint_id: String) -> Array:
	_ensure_loaded()
	var pool_tag: String = "gsm_reward" if checkpoint_id.begins_with("gsm_") else "base_reward"
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

func value_proxy(card_id: String) -> float:
	var card: Dictionary = get_card(card_id)
	var effects: Array = card.get("effects", [])
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
