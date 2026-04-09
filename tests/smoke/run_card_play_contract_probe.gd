extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const PROBE_CARD_ID := "probe_contract_anchor"
const PROBE_INSTANCE_ID := "probe_contract_anchor_runtime"
const STACK_PROBE_CARD_ID := "probe_stack_top_anchor"
const STACK_PROBE_INSTANCE_ID := "probe_stack_top_anchor_runtime"
const STACK_PROBE_DRAW_INSTANCE_ID := "probe_draw_strike_runtime"
const DISCARD_PROBE_CARD_ID := "probe_discard_ready_anchor"
const DISCARD_PROBE_INSTANCE_ID := "probe_discard_ready_anchor_runtime"
const RETAIN_PROBE_CARD_ID := "probe_retain_anchor"
const RETAIN_PROBE_INSTANCE_ID := "probe_retain_anchor_runtime"
const TEMP_PROBE_CARD_ID := "probe_temp_anchor"
const TEMP_PROBE_INSTANCE_ID := "probe_temp_anchor_runtime"

func _set_probe_state(node: Node, hand_cards: Array, energy_value: int, draw_cards: Array = [], stack_gems: Array = [], discard_cards: Array = []) -> Variant:
	var dls: Variant = node.get("dls")
	dls.hand = []
	for hand_card in hand_cards:
		if hand_card is Dictionary:
			dls.hand.append((hand_card as Dictionary).duplicate(true))
		else:
			dls.hand.append(hand_card)
	dls.draw_pile = []
	for draw_card in draw_cards:
		if draw_card is Dictionary:
			dls.draw_pile.append((draw_card as Dictionary).duplicate(true))
		else:
			dls.draw_pile.append(draw_card)
	dls.discard_pile = []
	for discard_card in discard_cards:
		if discard_card is Dictionary:
			dls.discard_pile.append((discard_card as Dictionary).duplicate(true))
		else:
			dls.discard_pile.append(discard_card)
	dls.exhaust_pile = []
	dls.limbo = []
	var gsm: Variant = node.get("gsm")
	if gsm != null:
		gsm.reset_stack()
		for gem in stack_gems:
			gsm.produce(str(gem), 1)
	node.set("energy", energy_value)
	node.call("refresh_hud")
	return dls

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var catalog = CARD_CATALOG_SCRIPT.new()
	var probe_card: Dictionary = {
		"instance_id": PROBE_INSTANCE_ID,
		"card_id": PROBE_CARD_ID,
	}
	var stack_probe_card: Dictionary = {
		"instance_id": STACK_PROBE_INSTANCE_ID,
		"card_id": STACK_PROBE_CARD_ID,
	}
	var draw_probe_card: Dictionary = {
		"instance_id": STACK_PROBE_DRAW_INSTANCE_ID,
		"card_id": "strike",
	}
	var discard_probe_card: Dictionary = {
		"instance_id": DISCARD_PROBE_INSTANCE_ID,
		"card_id": DISCARD_PROBE_CARD_ID,
	}
	var retain_probe_card: Dictionary = {
		"instance_id": RETAIN_PROBE_INSTANCE_ID,
		"card_id": RETAIN_PROBE_CARD_ID,
	}
	var temp_probe_card: Dictionary = {
		"instance_id": TEMP_PROBE_INSTANCE_ID,
		"card_id": TEMP_PROBE_CARD_ID,
	}

	node.call("reset_battle", 20260406)
	var dls: Variant = _set_probe_state(node, [probe_card], 1)
	var low_energy_result: Dictionary = node.call("player_play_card", PROBE_INSTANCE_ID)
	var low_energy_vm: Dictionary = node.call("get_view_model")

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [probe_card], 3)
	var enemy_hp_before: int = int(node.get("enemy_hp"))
	var play_result: Dictionary = node.call("player_play_card", PROBE_INSTANCE_ID)
	var vm_after: Dictionary = node.call("get_view_model")
	var enemy_hp_after: int = int(node.get("enemy_hp"))
	var energy_after_play: int = int(node.get("energy"))
	var last_resolved: Dictionary = node.get("last_resolved_queue_item")
	var exhaust_top: Dictionary = {}
	if dls.exhaust_pile.size() > 0 and dls.exhaust_pile[0] is Dictionary:
		exhaust_top = (dls.exhaust_pile[0] as Dictionary).duplicate(true)

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [stack_probe_card], 1)
	var stack_empty_result: Dictionary = node.call("player_play_card", STACK_PROBE_INSTANCE_ID)
	var stack_empty_vm: Dictionary = node.call("get_view_model")

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [stack_probe_card], 1, [], ["Sapphire"])
	var stack_mismatch_result: Dictionary = node.call("player_play_card", STACK_PROBE_INSTANCE_ID)

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [probe_card], 3)
	node.set("enemy_hp", 0)
	var no_target_attack_result: Dictionary = node.call("player_play_card", PROBE_INSTANCE_ID)

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [stack_probe_card], 1, [draw_probe_card], ["Ruby"])
	node.set("enemy_hp", 0)
	var targetless_play_result: Dictionary = node.call("player_play_card", STACK_PROBE_INSTANCE_ID)
	var targetless_vm_after: Dictionary = node.call("get_view_model")
	var targetless_last_resolved: Dictionary = node.get("last_resolved_queue_item")
	var targetless_resolved_effect: Dictionary = {}
	var targetless_resolved_effect_value: Variant = targetless_last_resolved.get("effect", {})
	if targetless_resolved_effect_value is Dictionary:
		targetless_resolved_effect = (targetless_resolved_effect_value as Dictionary).duplicate(true)

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [discard_probe_card], 1, [], [], ["strike_01"])
	var discard_gate_result: Dictionary = node.call("player_play_card", DISCARD_PROBE_INSTANCE_ID)
	var discard_gate_vm: Dictionary = node.call("get_view_model")

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [discard_probe_card], 1, [], [], ["strike_01", "defend_01"])
	var discard_ready_block_before: int = int(node.get("player_block"))
	var discard_ready_result: Dictionary = node.call("player_play_card", DISCARD_PROBE_INSTANCE_ID)
	var discard_ready_block_after: int = int(node.get("player_block"))
	var discard_ready_vm: Dictionary = node.call("get_view_model")
	var discard_ready_last_resolved: Dictionary = node.get("last_resolved_queue_item")

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [retain_probe_card], 1)
	var retain_ready_block_before: int = int(node.get("player_block"))
	var retain_ready_result: Dictionary = node.call("player_play_card", RETAIN_PROBE_INSTANCE_ID)
	var retain_ready_block_after: int = int(node.get("player_block"))
	var retain_ready_vm: Dictionary = node.call("get_view_model")

	node.call("reset_battle", 20260406)
	dls = _set_probe_state(node, [temp_probe_card], 1)
	var temp_ready_result: Dictionary = node.call("player_play_card", TEMP_PROBE_INSTANCE_ID)
	var temp_ready_vm: Dictionary = node.call("get_view_model")
	var temp_exhaust_top: Dictionary = {}
	if dls.exhaust_pile.size() > 0 and dls.exhaust_pile[0] is Dictionary:
		temp_exhaust_top = (dls.exhaust_pile[0] as Dictionary).duplicate(true)

	var payload: Dictionary = {
		"catalog_base_cost": catalog.base_cost(PROBE_CARD_ID),
		"catalog_cost_type": catalog.cost_type(PROBE_CARD_ID),
		"catalog_target_mode": catalog.target_mode(PROBE_CARD_ID),
		"catalog_max_targets": catalog.max_targets(PROBE_CARD_ID),
		"catalog_invalid_target_policy": catalog.invalid_target_policy(PROBE_CARD_ID),
		"catalog_play_conditions": catalog.play_conditions(PROBE_CARD_ID),
		"catalog_combo_tags": catalog.combo_tags(PROBE_CARD_ID),
		"catalog_chain_flags": catalog.chain_flags(PROBE_CARD_ID),
		"catalog_weight_modifiers": catalog.weight_modifiers(PROBE_CARD_ID),
		"catalog_speed_class": catalog.speed_class(PROBE_CARD_ID),
		"catalog_timing_window": catalog.timing_window(PROBE_CARD_ID),
		"catalog_zone_on_play": catalog.zone_on_play(PROBE_CARD_ID),
		"normalized_effect": catalog.effects_for(PROBE_CARD_ID),
		"retain_probe_zone_on_play": catalog.zone_on_play(RETAIN_PROBE_CARD_ID),
		"temp_probe_zone_on_play": catalog.zone_on_play(TEMP_PROBE_CARD_ID),
		"stack_probe_target_mode": catalog.target_mode(STACK_PROBE_CARD_ID),
		"stack_probe_max_targets": catalog.max_targets(STACK_PROBE_CARD_ID),
		"stack_probe_invalid_target_policy": catalog.invalid_target_policy(STACK_PROBE_CARD_ID),
		"stack_probe_play_conditions": catalog.play_conditions(STACK_PROBE_CARD_ID),
		"discard_probe_play_conditions": catalog.play_conditions(DISCARD_PROBE_CARD_ID),
		"low_energy_ok": bool(low_energy_result.get("ok", false)),
		"low_energy_reason": str(low_energy_result.get("reason", "")),
		"low_energy_hand_after": low_energy_vm.get("hand", []).duplicate(true),
		"low_energy_discard": int((low_energy_vm.get("zones", {}) as Dictionary).get("discard", 0)),
		"low_energy_exhaust": int((low_energy_vm.get("zones", {}) as Dictionary).get("exhaust", 0)),
		"play_ok": bool(play_result.get("ok", false)),
		"energy_after_play": energy_after_play,
		"enemy_hp_before": enemy_hp_before,
		"enemy_hp_after": enemy_hp_after,
		"last_resolved_card_id": str(last_resolved.get("card_id", "")),
		"last_resolved_timing_priority": int(last_resolved.get("timing_window_priority", -1)),
		"last_resolved_speed_priority": int(last_resolved.get("speed_class_priority", -1)),
		"discard_after_play": int((vm_after.get("zones", {}) as Dictionary).get("discard", 0)),
		"exhaust_after_play": int((vm_after.get("zones", {}) as Dictionary).get("exhaust", 0)),
		"hand_after_play": vm_after.get("hand", []).duplicate(true),
		"exhaust_top_instance_id": str(exhaust_top.get("instance_id", "")),
		"exhaust_top_card_id": str(exhaust_top.get("card_id", "")),
		"stack_empty_ok": bool(stack_empty_result.get("ok", false)),
		"stack_empty_reason": str(stack_empty_result.get("reason", "")),
		"stack_empty_hand_after": stack_empty_vm.get("hand", []).duplicate(true),
		"stack_mismatch_ok": bool(stack_mismatch_result.get("ok", false)),
		"stack_mismatch_reason": str(stack_mismatch_result.get("reason", "")),
		"discard_gate_ok": bool(discard_gate_result.get("ok", false)),
		"discard_gate_reason": str(discard_gate_result.get("reason", "")),
		"discard_gate_hand_after": discard_gate_vm.get("hand", []).duplicate(true),
		"discard_ready_ok": bool(discard_ready_result.get("ok", false)),
		"discard_ready_energy_after": int(discard_ready_vm.get("energy", node.get("energy"))),
		"discard_ready_block_gain": discard_ready_block_after - discard_ready_block_before,
		"discard_ready_hand_after": discard_ready_vm.get("hand", []).duplicate(true),
		"discard_ready_last_resolved_card_id": str(discard_ready_last_resolved.get("card_id", "")),
		"retain_ready_ok": bool(retain_ready_result.get("ok", false)),
		"retain_ready_energy_after": int(retain_ready_vm.get("energy", 0)),
		"retain_ready_block_gain": retain_ready_block_after - retain_ready_block_before,
		"retain_ready_hand_after": retain_ready_vm.get("hand", []).duplicate(true),
		"retain_ready_discard_after": int((retain_ready_vm.get("zones", {}) as Dictionary).get("discard", 0)),
		"retain_ready_exhaust_after": int((retain_ready_vm.get("zones", {}) as Dictionary).get("exhaust", 0)),
		"temp_ready_ok": bool(temp_ready_result.get("ok", false)),
		"temp_ready_energy_after": int(temp_ready_vm.get("energy", 0)),
		"temp_ready_hand_after": temp_ready_vm.get("hand", []).duplicate(true),
		"temp_ready_exhaust_after": int((temp_ready_vm.get("zones", {}) as Dictionary).get("exhaust", 0)),
		"temp_ready_exhaust_top_instance_id": str(temp_exhaust_top.get("instance_id", "")),
		"temp_ready_exhaust_top_card_id": str(temp_exhaust_top.get("card_id", "")),
		"no_target_attack_ok": bool(no_target_attack_result.get("ok", false)),
		"no_target_attack_reason": str(no_target_attack_result.get("reason", "")),
		"targetless_play_ok": bool(targetless_play_result.get("ok", false)),
		"targetless_energy_after": int(node.get("energy")),
		"targetless_hand_after": targetless_vm_after.get("hand", []).duplicate(true),
		"targetless_last_resolved_card_id": str(targetless_last_resolved.get("card_id", "")),
		"targetless_last_resolved_effect_type": str(targetless_resolved_effect.get("type", "")),
		"targetless_last_resolved_effect_amount": int(targetless_resolved_effect.get("amount", 0)),
	}
	print("CARD_PLAY_CONTRACT_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
