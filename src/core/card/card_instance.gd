extends RefCounted
class_name CardInstance

func from_value(value: Variant, card_catalog: Variant) -> Dictionary:
	if value is Dictionary:
		var existing: Dictionary = value
		var instance_id: String = str(existing.get("instance_id", "")).strip_edges()
		var card_id: String = _canonical_card_id(str(existing.get("card_id", "")).strip_edges(), card_catalog)
		if instance_id == "":
			instance_id = card_id
		if card_id == "" and card_catalog != null and card_catalog.has_card(instance_id):
			card_id = card_catalog.resolved_card_id(instance_id)
		return {
			"instance_id": instance_id,
			"card_id": card_id,
		}

	var raw_value: String = str(value).strip_edges()
	var resolved_card_id: String = _canonical_card_id(raw_value, card_catalog)
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
		var explicit_card_id: String = _canonical_card_id(str(existing.get("card_id", "")).strip_edges(), card_catalog)
		if explicit_card_id != "":
			return explicit_card_id
		var instance_id: String = instance_id_of(value)
		if card_catalog != null and card_catalog.has_card(instance_id):
			return card_catalog.resolved_card_id(instance_id)
		return instance_id
	var raw_value: String = str(value).strip_edges()
	return _canonical_card_id(raw_value, card_catalog)

func _canonical_card_id(raw_card_id: String, card_catalog: Variant) -> String:
	if raw_card_id == "":
		return ""
	if card_catalog != null and card_catalog.has_card(raw_card_id):
		return card_catalog.resolved_card_id(raw_card_id)
	return raw_card_id

func preserves_authored_instance_id(value: Variant, card_catalog: Variant) -> bool:
	var instance_id: String = instance_id_of(value)
	if instance_id == "":
		return false
	var card_id: String = card_id_of(value, card_catalog)
	return card_id != "" and instance_id != card_id

func live_runtime_card(value: Variant, card_catalog: Variant, runtime_instance_id: String) -> Dictionary:
	var normalized: Dictionary = from_value(value, card_catalog)
	if runtime_instance_id == "" or preserves_authored_instance_id(normalized, card_catalog):
		return normalized
	normalized["instance_id"] = runtime_instance_id
	return normalized

func to_debug_string(value: Variant) -> String:
	if value is Dictionary:
		var card: Dictionary = value
		return "%s<%s>" % [str(card.get("instance_id", "")), str(card.get("card_id", ""))]
	return str(value)
