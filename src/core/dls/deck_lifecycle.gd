extends RefCounted
class_name DeckLifecycle

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var limbo: Array = []

func draw_one() -> Variant:
	if draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card = draw_pile.pop_back()
	hand.append(card)
	return card

func commit_play(card_id: String) -> Dictionary:
	for i in range(hand.size()):
		if str(hand[i]) == card_id:
			var card = hand.pop_at(i)
			limbo.append(card)
			return {"ok": true, "card": card}
	return {"ok": false, "reason": "ERR_CARD_NOT_IN_HAND"}

func finalize_play(card_id: String, destination: String = "discard") -> void:
	for i in range(limbo.size()):
		if str(limbo[i]) == card_id:
			var card = limbo.pop_at(i)
			if destination == "exhaust":
				exhaust_pile.append(card)
			else:
				discard_pile.append(card)
			return

func _reshuffle_discard_into_draw() -> void:
	draw_pile = discard_pile.duplicate(true)
	discard_pile.clear()
