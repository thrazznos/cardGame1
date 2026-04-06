extends SceneTree

func _has_texture(node: Node) -> bool:
	return node is TextureRect and (node as TextureRect).texture != null

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", 424242)
	var dls: Variant = node.get("dls")
	var gsm: Variant = node.get("gsm")
	dls.hand = [
		"strike_01",
		"gem_produce_ruby_a",
		"scheme_flow",
	]
	gsm.produce("Ruby", 1)
	gsm.produce("Sapphire", 1)
	gsm.gain_focus(1)
	node.set("reward_state", "presented")
	var reward_offer: Array = node.get("reward_offer")
	reward_offer.clear()
	reward_offer.append({"card_id": "strike_plus"})
	reward_offer.append({"card_id": "gem_focus"})
	reward_offer.append({"card_id": "defend_plus"})
	node.set("reward_offer", reward_offer)
	node.set("last_reject_reason", "ERR_FOCUS_REQUIRED")
	node.call("refresh_hud")
	await process_frame

	var hand_button: Node = node.get_node_or_null("CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	var reward_button: Node = node.get_node_or_null("CombatHud/RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1")
	var gem_top_1: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop1")
	var gem_top_2: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop2")
	var focus_icon: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/FocusIcon")
	var focus_value: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/FocusValue")
	var lock_icon: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/LockIcon")
	var zones_label: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/ZonesPanel/Zones")

	var payload: Dictionary = {
		"hand_art_has_texture": _has_texture(hand_button.get_node_or_null("ArtThumb") if hand_button != null else null),
		"hand_role_icon_has_texture": _has_texture(hand_button.get_node_or_null("RoleIcon") if hand_button != null else null),
		"reward_art_has_texture": _has_texture(reward_button.get_node_or_null("ArtThumb") if reward_button != null else null),
		"reward_role_icon_has_texture": _has_texture(reward_button.get_node_or_null("RoleIcon") if reward_button != null else null),
		"gem_top_1_has_texture": _has_texture(gem_top_1),
		"gem_top_2_has_texture": _has_texture(gem_top_2),
		"focus_icon_has_texture": _has_texture(focus_icon),
		"focus_value_text": (focus_value as Label).text if focus_value is Label else "",
		"lock_icon_has_texture": _has_texture(lock_icon),
		"lock_icon_visible": (lock_icon as TextureRect).visible if lock_icon is TextureRect else false,
		"zones_text": (zones_label as Label).text if zones_label is Label else "",
	}

	print("GAMEPLAY_ART_VISIBILITY_PROBE=" + JSON.stringify(payload))
	node.queue_free()
	await process_frame
	quit()
