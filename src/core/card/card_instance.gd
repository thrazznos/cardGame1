extends RefCounted
class_name CardInstance

func from_value(value: Variant, card_catalog: Variant) -> Dictionary:
	if value is Dictionary:
		var existing: Dictionary = value
		var instance_id: String = str(existing.get("instance_id", "")).strip_edges()
		var card_id: String = str(existing.get("card_id", "")).strip_edges()
		if instance_id != "" and card_id != "":
			return existing.duplicate(true)
		if instance_id == "":
			instance_id = card_id
		if card_id == "" and card_catalog != null and card_catalog.has_card(instance_id):
			card_id = card_catalog.resolved_card_id(instance_id)
		return {
			"instance_id": instance_id,
			"card_id": card_id,
		}

	var raw_value: String = str(value).strip_edges()
	var resolved_card_id: String = raw_value
	if card_catalog != null and card_catalog.has_card(raw_value):
		resolved_card_id = card_catalog.resolved_card_id(raw_value)
	return {
		"instance_id": raw_value,
		"card_id": resolved_card_id,
	}

func instance_id_of(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("instance_id", "")).strip_edges()
	return str(value).strip_edges()

func card_id_of(value: Variant, card_catalog: Variant) -> String:
	if value is Dictionary:
		var existing: Dictionary = value
		var explicit_card_id: String = str(existing.get("card_id", "")).strip_edges()
		if explicit_card_id != "":
			return explicit_card_id
		var instance_id: String = instance_id_of(value)
		if card_catalog != null and card_catalog.has_card(instance_id):
			return card_catalog.resolved_card_id(instance_id)
		return instance_id
	var raw_value: String = str(value).strip_edges()
	if card_catalog != null and card_catalog.has_card(raw_value):
		return card_catalog.resolved_card_id(raw_value)
	return raw_value

func to_debug_string(value: Variant) -> String:
	if value is Dictionary:
		var card: Dictionary = value
		return "%s<%s>" % [str(card.get("instance_id", "")), str(card.get("card_id", ""))]
	return str(value)
