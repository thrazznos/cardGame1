extends RefCounted
class_name DeckInspectionSnapshotBuilder

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const CARD_INSTANCE_SCRIPT := preload("res://src/core/card/card_instance.gd")
const CARD_PRESENTER_SCRIPT := preload("res://src/core/card/card_presenter.gd")

const COMBAT_ZONE_ORDER := {
	"draw": 0,
	"hand": 1,
	"discard": 2,
	"exhaust": 3,
}

const ZONE_LABELS := {
	"draw": "Draw",
	"hand": "Hand",
	"discard": "Discard",
	"exhaust": "Exhaust",
	"deck": "Deck",
}

var card_catalog: Variant
var card_instance: Variant
var card_presenter: Variant

func _init() -> void:
	card_catalog = CARD_CATALOG_SCRIPT.new()
	card_instance = CARD_INSTANCE_SCRIPT.new()
	card_presenter = CARD_PRESENTER_SCRIPT.new()

func build_snapshot(mode: String, payload: Dictionary) -> Dictionary:
	match String(mode).strip_edges():
		"combat_full":
			return _build_combat_snapshot(payload, "all")
		"combat_discard":
			return _build_combat_snapshot(payload, "discard")
		"map_run_deck":
			return _build_map_snapshot(payload)
		_:
			return {
				"context": "unknown",
				"title": "Deck Inspection",
				"read_only": true,
				"total_count": 0,
				"active_filter": "all",
				"sections": [],
				"cards": [],
			}

func _build_combat_snapshot(payload: Dictionary, active_filter: String) -> Dictionary:
	var sections: Array = []
	var all_cards: Array = []
	for zone_id in ["draw", "hand", "discard", "exhaust"]:
		var zone_values: Array = _variant_array(payload.get(zone_id, []))
		sections.append({
			"id": zone_id,
			"label": _zone_label(zone_id),
			"count": zone_values.size(),
		})
		for index in range(zone_values.size()):
			all_cards.append(_normalize_card(zone_values[index], zone_id, index))
	var visible_cards: Array = _filtered_cards(all_cards, active_filter)
	return {
		"context": "combat",
		"title": "Combat Deck",
		"read_only": true,
		"total_count": visible_cards.size(),
		"active_filter": active_filter,
		"sections": sections,
		"cards": visible_cards,
	}

func _build_map_snapshot(payload: Dictionary) -> Dictionary:
	var deck_values: Array = _variant_array(payload.get("deck", []))
	var cards: Array = []
	for index in range(deck_values.size()):
		cards.append(_normalize_card(deck_values[index], "deck", index))
	cards.sort_custom(func(a: Dictionary, b: Dictionary): return _map_card_less(a, b))
	return {
		"context": "map",
		"title": "Run Deck",
		"read_only": true,
		"total_count": cards.size(),
		"active_filter": "all",
		"sections": [
			{
				"id": "deck",
				"label": "Deck",
				"count": cards.size(),
			}
		],
		"cards": cards,
	}

func _normalize_card(value: Variant, zone_id: String, source_index: int) -> Dictionary:
	var normalized: Dictionary = card_instance.from_value(value, card_catalog)
	var card_id: String = str(normalized.get("card_id", "")).strip_edges()
	var instance_id: String = str(normalized.get("instance_id", "")).strip_edges()
	return {
		"card_id": card_id,
		"card_instance_id": instance_id,
		"display_name": card_presenter.display_name(card_id),
		"cost": card_catalog.base_cost(card_id),
		"role_label": card_presenter.role_marker(card_id),
		"rules_text": card_catalog.hand_rules_text(card_id),
		"zone": zone_id,
		"zone_label": _zone_label(zone_id),
		"art_path": "",
		"sort_key": _sort_key(zone_id, source_index, card_id, instance_id),
		"flags": {},
	}

func _sort_key(zone_id: String, source_index: int, card_id: String, instance_id: String) -> Array:
	return [
		int(COMBAT_ZONE_ORDER.get(zone_id, 99)),
		source_index,
		card_id,
		instance_id,
	]

func _filtered_cards(cards: Array, active_filter: String) -> Array:
	if active_filter == "all":
		return cards.duplicate(true)
	var filtered: Array = []
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		if str(card.get("zone", "")) == active_filter:
			filtered.append(card.duplicate(true))
	return filtered

func _map_card_less(a: Dictionary, b: Dictionary) -> bool:
	var a_cost: int = int(a.get("cost", 0))
	var b_cost: int = int(b.get("cost", 0))
	if a_cost != b_cost:
		return a_cost < b_cost
	var a_name: String = str(a.get("display_name", ""))
	var b_name: String = str(b.get("display_name", ""))
	if a_name != b_name:
		return a_name < b_name
	var a_card_id: String = str(a.get("card_id", ""))
	var b_card_id: String = str(b.get("card_id", ""))
	if a_card_id != b_card_id:
		return a_card_id < b_card_id
	return str(a.get("card_instance_id", "")) < str(b.get("card_instance_id", ""))

func _zone_label(zone_id: String) -> String:
	return str(ZONE_LABELS.get(zone_id, zone_id.capitalize()))

func _variant_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []
