extends RefCounted
class_name DeckLifecycle

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const CARD_INSTANCE_SCRIPT := preload("res://src/core/card/card_instance.gd")

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var limbo: Array = []
var card_catalog: Variant
var card_instance: Variant

func _init() -> void:
	card_catalog = CARD_CATALOG_SCRIPT.new()
	card_instance = CARD_INSTANCE_SCRIPT.new()

func normalize_zones() -> void:
	draw_pile = _normalize_zone(draw_pile)
	hand = _normalize_zone(hand)
	discard_pile = _normalize_zone(discard_pile)
	exhaust_pile = _normalize_zone(exhaust_pile)
	limbo = _normalize_zone(limbo)

func draw_one() -> Variant:
	normalize_zones()
	if draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card: Dictionary = _normalize_card(draw_pile.pop_back())
	hand.append(card)
	return card

func commit_play(card_id: String) -> Dictionary:
	normalize_zones()
	for i in range(hand.size()):
		if _instance_id_of(hand[i]) == card_id:
			var card: Dictionary = _normalize_card(hand.pop_at(i))
			limbo.append(card)
			return {"ok": true, "card": card}
	return {"ok": false, "reason": "ERR_CARD_NOT_IN_HAND"}

func finalize_play(card_id: String, destination: String = "") -> void:
	normalize_zones()
	for i in range(limbo.size()):
		if _instance_id_of(limbo[i]) == card_id:
			var card: Dictionary = _normalize_card(limbo.pop_at(i))
			var resolved_destination: String = _resolved_destination(card, destination)
			match resolved_destination:
				"exhaust":
					exhaust_pile.append(card)
				"retain":
					hand.append(card)
				_:
					discard_pile.append(card)
			return

func _reshuffle_discard_into_draw() -> void:
	draw_pile = discard_pile.duplicate(true)
	discard_pile.clear()

func _normalize_zone(zone: Array) -> Array:
	var normalized: Array = []
	for value in zone:
		normalized.append(_normalize_card(value))
	return normalized

func _normalize_card(value: Variant) -> Dictionary:
	return card_instance.from_value(value, card_catalog)

func _instance_id_of(value: Variant) -> String:
	return card_instance.instance_id_of(value)

func _resolved_destination(card: Dictionary, requested_destination: String) -> String:
	var destination: String = str(requested_destination).strip_edges()
	if destination == "":
		destination = _authored_zone_on_play(card)
	if destination == "temp":
		return "exhaust"
	if destination == "retain":
		return "retain"
	if destination == "exhaust":
		return "exhaust"
	return "discard"

func _authored_zone_on_play(card: Dictionary) -> String:
	var card_id: String = str(card.get("card_id", "")).strip_edges()
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return "discard"
	return str(card_catalog.zone_on_play(card_id))
