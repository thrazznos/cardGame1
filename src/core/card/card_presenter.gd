extends RefCounted
class_name CardPresenter

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

var card_catalog: Variant

func _init() -> void:
	card_catalog = CARD_CATALOG_SCRIPT.new()

func display_name(card_id: String) -> String:
	return card_catalog.display_name(card_id)

func role_marker(card_id: String) -> String:
	return card_catalog.role_marker(card_id)

func palette_key(card_id: String) -> String:
	return card_catalog.palette_key(card_id)

func card_button_text(card_id: String) -> String:
	return "%s %s\n%s" % [role_marker(card_id), display_name(card_id), card_catalog.hand_rules_text(card_id)]

func card_tooltip(card_id: String) -> String:
	return "%s %s" % [role_marker(card_id), card_catalog.tooltip_text(card_id)]

func reward_card_button_text(card_id: String) -> String:
	return "%s %s\n%s" % [role_marker(card_id), display_name(card_id), card_catalog.reward_rules_text(card_id)]

func reward_card_tooltip(card_id: String) -> String:
	return "%s\nReward effect: permanently add this card to your run deck." % card_tooltip(card_id)
