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

func draw_one() -> Variant:
	if draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card: Dictionary = _normalize_card(draw_pile.pop_back())
	hand.append(card)
	return card

func commit_play(card_id: String) -> Dictionary:
	for i in range(hand.size()):
		if _instance_id_of(hand[i]) == card_id:
			var card: Dictionary = _normalize_card(hand.pop_at(i))
			limbo.append(card)
			return {"ok": true, "card": card}
	return {"ok": false, "reason": "ERR_CARD_NOT_IN_HAND"}

func finalize_play(card_id: String, destination: String = "discard") -> void:
	for i in range(limbo.size()):
		if _instance_id_of(limbo[i]) == card_id:
			var card: Dictionary = _normalize_card(limbo.pop_at(i))
			if destination == "exhaust":
				exhaust_pile.append(card)
			else:
				discard_pile.append(card)
			return

func _reshuffle_discard_into_draw() -> void:
	draw_pile = discard_pile.duplicate(true)
	discard_pile.clear()

func _normalize_card(value: Variant) -> Dictionary:
	return card_instance.from_value(value, card_catalog)

func _instance_id_of(value: Variant) -> String:
	return card_instance.instance_id_of(value)
