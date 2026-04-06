extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

func _init() -> void:
	var catalog = CARD_CATALOG_SCRIPT.new()
	var strike_alias: Dictionary = catalog.get_card("strike_01")
	var strike_plus: Dictionary = catalog.get_card("strike_plus")
	var payload: Dictionary = {
		"validation_errors": catalog.validation_errors(),
		"starter_deck_size": catalog.starter_run_deck().size(),
		"alias_display_name": str(strike_alias.get("display_name", "")),
		"alias_resolved_id": catalog.resolved_card_id("strike_01"),
		"reward_variant_name": str(strike_plus.get("display_name", "")),
		"has_effects": not strike_plus.get("effects", []).is_empty(),
	}
	print("CARD_CATALOG_PROBE=" + JSON.stringify(payload))
	quit()
