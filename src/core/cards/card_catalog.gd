extends RefCounted
class_name CardCatalog

const CATALOG_PATH := "res://data/cards/card_catalog.json"

var _loaded: bool = false
var _cards: Array[Dictionary] = []

func get_card(card_id: String) -> Dictionary:
	_ensure_loaded()
	var best_match: Dictionary = {}
	var best_len: int = -1
	for entry in _cards:
		var prefix: String = str(entry.get("id_prefix", ""))
		if prefix == "":
			continue
		if not card_id.begins_with(prefix):
			continue
		if prefix.length() > best_len:
			best_match = entry
			best_len = prefix.length()
	if best_match.is_empty():
		return {}
	var card: Dictionary = best_match.duplicate(true)
	card["card_id"] = card_id
	return card

func get_effect_payload(card_id: String) -> Variant:
	var card: Dictionary = get_card(card_id)
	if card.is_empty():
		return {}
	var effects: Array = card.get("effects", [])
	if effects.size() == 1 and effects[0] is Dictionary:
		return effects[0]
	return effects.duplicate(true)

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var text: String = FileAccess.get_file_as_string(CATALOG_PATH)
	if text == "":
		push_warning("CardCatalog: missing catalog file at %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("CardCatalog: invalid JSON root in %s" % CATALOG_PATH)
		return
	var cards_variant: Variant = (parsed as Dictionary).get("cards", [])
	if not (cards_variant is Array):
		push_warning("CardCatalog: cards array missing in %s" % CATALOG_PATH)
		return
	for entry in cards_variant:
		if entry is Dictionary:
			_cards.append((entry as Dictionary).duplicate(true))
