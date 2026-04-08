extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

func _init() -> void:
	var catalog = CARD_CATALOG_SCRIPT.new()
	var strike_alias: Dictionary = catalog.get_card("strike_01")
	var strike_plus: Dictionary = catalog.get_card("strike_plus")
	var strike_effects: Array = strike_alias.get("effects", [])
	var strike_effect_entry: Dictionary = strike_effects[0] if not strike_effects.is_empty() else {}
	var strike_precise: Dictionary = catalog.get_card("strike_precise")
	var strike_precise_effects: Array = strike_precise.get("effects", [])
	var strike_precise_effect_ids: Array = []
	for effect_variant in strike_precise_effects:
		if effect_variant is Dictionary:
			strike_precise_effect_ids.append(str((effect_variant as Dictionary).get("effect_id", "")))
	var payload: Dictionary = {
		"validation_errors": catalog.validation_errors(),
		"starter_deck_size": catalog.starter_run_deck().size(),
		"alias_display_name": str(strike_alias.get("display_name", "")),
		"alias_resolved_id": catalog.resolved_card_id("strike_01"),
		"reward_variant_name": str(strike_plus.get("display_name", "")),
		"has_effects": not strike_plus.get("effects", []).is_empty(),
		"strike_authored_effect_id": str(strike_effect_entry.get("effect_id", "")),
		"strike_authored_effect_params": strike_effect_entry.get("params", {}).duplicate(true) if strike_effect_entry.get("params", {}) is Dictionary else {},
		"strike_normalized_effect": catalog.effects_for("strike"),
		"strike_precise_authored_effect_ids": strike_precise_effect_ids,
		"strike_precise_normalized_effects": catalog.effects_for("strike_precise"),
	}
	print("CARD_CATALOG_PROBE=" + JSON.stringify(payload))
	quit()
