extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const CARD_INSTANCE_SCRIPT := preload("res://src/core/card/card_instance.gd")

func _first_matching_line(lines: Array, needle: String) -> String:
	for line in lines:
		var rendered: String = str(line)
		if rendered.find(needle) >= 0:
			return rendered
	return ""

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame
	var hud: Node = node.get_node("CombatHud")

	var catalog = CARD_CATALOG_SCRIPT.new()
	var helper = CARD_INSTANCE_SCRIPT.new()
	var normalized: Dictionary = helper.from_value("strike_01", catalog)

	node.call("reset_battle", 1337)
	var dls: Variant = node.get("dls")
	var hand_internal_uses_dictionaries: bool = dls.hand.size() > 0 and dls.hand[0] is Dictionary
	var draw_internal_uses_dictionaries: bool = dls.draw_pile.size() > 0 and dls.draw_pile[0] is Dictionary

	dls.hand = [normalized]
	node.call("refresh_hud")
	var normalized_vm: Dictionary = node.call("get_view_model")

	var runtime_instance: Dictionary = {
		"instance_id": "combat_runtime_strike_alpha",
		"card_id": "strike",
	}
	dls.hand = [runtime_instance]
	dls.draw_pile = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	node.call("refresh_hud")
	var runtime_vm_before: Dictionary = node.call("get_view_model")
	var enemy_hp_before: int = int(node.get("enemy_hp"))
	var play_result: Dictionary = node.call("player_play_card", str(runtime_instance.get("instance_id", "")))
	var runtime_vm_after: Dictionary = node.call("get_view_model")
	var enemy_hp_after: int = int(node.get("enemy_hp"))
	var last_resolved: Dictionary = node.get("last_resolved_queue_item")
	var resolved_effect: Dictionary = {}
	var resolved_effect_value: Variant = last_resolved.get("effect", {})
	if resolved_effect_value is Dictionary:
		resolved_effect = (resolved_effect_value as Dictionary).duplicate(true)
	var discard_top: Dictionary = {}
	if dls.discard_pile.size() > 0 and dls.discard_pile[0] is Dictionary:
		discard_top = (dls.discard_pile[0] as Dictionary).duplicate(true)

	dls.hand = [runtime_instance.duplicate(true)]
	dls.draw_pile = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	node.call("refresh_hud")
	var authored_id_play_result: Dictionary = node.call("player_play_card", "strike")

	node.call("reset_battle", 1337)
	dls = node.get("dls")
	var invalid_runtime_instance: Dictionary = {
		"instance_id": "combat_runtime_missing_beta",
		"card_id": "missing_card",
	}
	dls.hand = [invalid_runtime_instance]
	dls.draw_pile = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	node.call("refresh_hud")
	var invalid_runtime_play_result: Dictionary = node.call("player_play_card", str(invalid_runtime_instance.get("instance_id", "")))

	node.call("reset_battle", 1337)
	dls = node.get("dls")
	var runtime_reward_copy: Dictionary = {
		"instance_id": "combat_reward_strike_plus_alpha",
		"card_id": "strike_plus",
	}
	dls.hand = [runtime_reward_copy]
	dls.draw_pile = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	node.call("refresh_hud")
	var runtime_reward_copy_vm: Dictionary = node.call("get_view_model")
	var hand_label_text: String = ""
	var hand_button_text: String = ""
	var hand_button_tooltip: String = ""
	var hand_button_card_meta: String = ""
	var hand_button_instance_meta: String = ""
	var hand_button_role_tooltip: String = ""
	var hand_button_art_tooltip: String = ""
	var hand_label_node = hud.get_node_or_null("Margin/VBox/HandPanel/HandVBox/Hand")
	if hand_label_node is Label:
		hand_label_text = hand_label_node.text
	var hand_buttons_node = hud.get_node_or_null("Margin/VBox/HandPanel/HandVBox/HandButtons")
	if hand_buttons_node != null and hand_buttons_node.get_child_count() > 0:
		var first_button = hand_buttons_node.get_child(0)
		if first_button is Button:
			hand_button_text = first_button.text
			hand_button_tooltip = first_button.tooltip_text
			hand_button_card_meta = str(first_button.get_meta("card_id", ""))
			hand_button_instance_meta = str(first_button.get_meta("instance_id", ""))
			var role_icon = first_button.get_node_or_null("RoleIcon")
			if role_icon is TextureRect:
				hand_button_role_tooltip = role_icon.tooltip_text
			var art_thumb = first_button.get_node_or_null("ArtThumb")
			if art_thumb is TextureRect:
				hand_button_art_tooltip = art_thumb.tooltip_text

	node.call("reset_battle", 1337)
	var bootstrap_cards: Array = node.call("_card_instance_array", ["strike_01", "strike_plus", "strike_plus"])
	var bootstrap_alias: Dictionary = {}
	var bootstrap_reward_instance_ids: Array = []
	var bootstrap_reward_card_ids: Array = []
	for i in range(bootstrap_cards.size()):
		if not (bootstrap_cards[i] is Dictionary):
			continue
		var bootstrap_card: Dictionary = (bootstrap_cards[i] as Dictionary).duplicate(true)
		if i == 0:
			bootstrap_alias = bootstrap_card
			continue
		bootstrap_reward_instance_ids.append(str(bootstrap_card.get("instance_id", "")))
		bootstrap_reward_card_ids.append(str(bootstrap_card.get("card_id", "")))
	var bootstrap_cards_repeat: Array = node.call("_card_instance_array", ["strike_01", "strike_plus", "strike_plus"])
	var bootstrap_reward_instance_ids_repeat: Array = []
	for i in range(1, bootstrap_cards_repeat.size()):
		if bootstrap_cards_repeat[i] is Dictionary:
			bootstrap_reward_instance_ids_repeat.append(str((bootstrap_cards_repeat[i] as Dictionary).get("instance_id", "")))

	node.call("reset_battle", 1337)
	dls = node.get("dls")
	node.set("reward_state", "presented")
	node.set("reward_checkpoint_id", "combat_clear_1")
	node.set("reward_draft_instance_id", "combat_clear_1_draft_0")
	var reward_offer_cards: Array[Dictionary] = []
	reward_offer_cards.append({"card_id": "strike_plus"})
	node.set("reward_offer", reward_offer_cards)
	var reward_pick_result: Dictionary = node.call("choose_reward", "strike_plus")
	var reward_discard_top: Dictionary = {}
	if dls.discard_pile.size() > 0 and dls.discard_pile[0] is Dictionary:
		reward_discard_top = (dls.discard_pile[0] as Dictionary).duplicate(true)

	var alias_dict_input: Dictionary = {
		"instance_id": " strike_01 ",
		"card_id": " strike_01 ",
	}
	var alias_dict_normalized: Dictionary = helper.from_value(alias_dict_input, catalog)
	var inferred_dict_input: Dictionary = {
		"instance_id": " strike_02 ",
		"card_id": "",
	}
	var inferred_dict_normalized: Dictionary = helper.from_value(inferred_dict_input, catalog)

	var payload: Dictionary = {
		"normalized_instance_id": str(normalized.get("instance_id", "")),
		"normalized_card_id": str(normalized.get("card_id", "")),
		"alias_dict_instance_id": str(alias_dict_normalized.get("instance_id", "")),
		"alias_dict_card_id": str(alias_dict_normalized.get("card_id", "")),
		"alias_dict_card_id_of": helper.card_id_of(alias_dict_input, catalog),
		"inferred_dict_instance_id": str(inferred_dict_normalized.get("instance_id", "")),
		"inferred_dict_card_id": str(inferred_dict_normalized.get("card_id", "")),
		"hand_internal_uses_dictionaries": hand_internal_uses_dictionaries,
		"draw_internal_uses_dictionaries": draw_internal_uses_dictionaries,
		"view_hand_first": str(normalized_vm.get("hand", [""])[0]),
		"runtime_view_hand_before_play": runtime_vm_before.get("hand", []).duplicate(true),
		"runtime_view_hand_after_play": runtime_vm_after.get("hand", []).duplicate(true),
		"play_ok": bool(play_result.get("ok", false)),
		"enemy_hp_before": enemy_hp_before,
		"enemy_hp_after": enemy_hp_after,
		"last_resolved_source_instance_id": str(last_resolved.get("source_instance_id", "")),
		"last_resolved_card_id": str(last_resolved.get("card_id", "")),
		"last_resolved_effect_type": str(resolved_effect.get("type", "")),
		"last_resolved_effect_amount": int(resolved_effect.get("amount", 0)),
		"discard_top_instance_id": str(discard_top.get("instance_id", "")),
		"discard_top_card_id": str(discard_top.get("card_id", "")),
		"play_by_authored_id_ok": bool(authored_id_play_result.get("ok", false)),
		"play_by_authored_id_reason": str(authored_id_play_result.get("reason", "")),
		"invalid_runtime_play_ok": bool(invalid_runtime_play_result.get("ok", false)),
		"invalid_runtime_play_reason": str(invalid_runtime_play_result.get("reason", "")),
		"reward_copy_view_hand": runtime_reward_copy_vm.get("hand", []).duplicate(true),
		"reward_copy_view_hand_card_ids": runtime_reward_copy_vm.get("hand_card_ids", []).duplicate(true),
		"reward_copy_hand_hotkey_text": hand_label_text,
		"reward_copy_button_text": hand_button_text,
		"reward_copy_button_tooltip": hand_button_tooltip,
		"reward_copy_button_card_id_meta": hand_button_card_meta,
		"reward_copy_button_instance_id_meta": hand_button_instance_meta,
		"reward_copy_button_role_tooltip": hand_button_role_tooltip,
		"reward_copy_button_art_tooltip": hand_button_art_tooltip,
		"bootstrap_alias_instance_id": str(bootstrap_alias.get("instance_id", "")),
		"bootstrap_alias_card_id": str(bootstrap_alias.get("card_id", "")),
		"bootstrap_reward_instance_ids": bootstrap_reward_instance_ids.duplicate(true),
		"bootstrap_reward_card_ids": bootstrap_reward_card_ids.duplicate(true),
		"bootstrap_reward_instance_ids_repeat": bootstrap_reward_instance_ids_repeat.duplicate(true),
		"reward_pick_ok": bool(reward_pick_result.get("ok", false)),
		"reward_discard_instance_id": str(reward_discard_top.get("instance_id", "")),
		"reward_discard_card_id": str(reward_discard_top.get("card_id", "")),
		"effect_resolve_line": _first_matching_line(runtime_vm_after.get("recent_events", []), "Resolve"),
	}
	print("CARD_INSTANCE_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
