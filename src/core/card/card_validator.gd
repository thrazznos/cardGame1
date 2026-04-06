extends RefCounted
class_name CardValidator

func validate_catalog(payload: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var seen_card_ids: Dictionary = {}
	var seen_aliases: Dictionary = {}
	var cards: Array = payload.get("cards", [])
	if cards.is_empty():
		errors.append("ERR_CARD_CATALOG_EMPTY")
		return errors

	for entry in cards:
		if not (entry is Dictionary):
			errors.append("ERR_CARD_ENTRY_INVALID")
			continue
		var card: Dictionary = entry
		var card_id: String = str(card.get("card_id", "")).strip_edges()
		if card_id == "":
			errors.append("ERR_CARD_ID_MISSING")
			continue
		if seen_card_ids.has(card_id):
			errors.append("ERR_CARD_ID_DUPLICATE:%s" % card_id)
			continue
		seen_card_ids[card_id] = true

		if str(card.get("display_name", "")).strip_edges() == "":
			errors.append("ERR_CARD_DISPLAY_NAME_MISSING:%s" % card_id)
		if str(card.get("role_marker", "")).strip_edges() == "":
			errors.append("ERR_CARD_ROLE_MARKER_MISSING:%s" % card_id)
		if str(card.get("palette", "")).strip_edges() == "":
			errors.append("ERR_CARD_PALETTE_MISSING:%s" % card_id)
		var effects: Array = card.get("effects", [])
		if effects.is_empty():
			errors.append("ERR_CARD_EFFECTS_MISSING:%s" % card_id)

		var aliases: Array = card.get("aliases", [])
		for alias in aliases:
			var alias_id: String = str(alias).strip_edges()
			if alias_id == "":
				continue
			if seen_card_ids.has(alias_id) or seen_aliases.has(alias_id):
				errors.append("ERR_CARD_ALIAS_DUPLICATE:%s" % alias_id)
				continue
			seen_aliases[alias_id] = card_id

	return errors
