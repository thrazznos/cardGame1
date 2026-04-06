extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const PROBE_CARD_ID := "probe_contract_anchor"
const PROBE_INSTANCE_ID := "probe_contract_anchor_runtime"

func _set_probe_hand(node: Node, probe_card: Dictionary, energy_value: int) -> Variant:
	var dls: Variant = node.get("dls")
	dls.hand = [probe_card.duplicate(true)]
	dls.draw_pile = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
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

	node.call("reset_battle", 20260406)
	var dls: Variant = _set_probe_hand(node, probe_card, 1)
	var low_energy_result: Dictionary = node.call("player_play_card", PROBE_INSTANCE_ID)
	var low_energy_vm: Dictionary = node.call("get_view_model")

	node.call("reset_battle", 20260406)
	dls = _set_probe_hand(node, probe_card, 3)
	var enemy_hp_before: int = int(node.get("enemy_hp"))
	var play_result: Dictionary = node.call("player_play_card", PROBE_INSTANCE_ID)
	var vm_after: Dictionary = node.call("get_view_model")
	var enemy_hp_after: int = int(node.get("enemy_hp"))
	var last_resolved: Dictionary = node.get("last_resolved_queue_item")
	var exhaust_top: Dictionary = {}
	if dls.exhaust_pile.size() > 0 and dls.exhaust_pile[0] is Dictionary:
		exhaust_top = (dls.exhaust_pile[0] as Dictionary).duplicate(true)

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
		"low_energy_ok": bool(low_energy_result.get("ok", false)),
		"low_energy_reason": str(low_energy_result.get("reason", "")),
		"low_energy_hand_after": low_energy_vm.get("hand", []).duplicate(true),
		"low_energy_discard": int((low_energy_vm.get("zones", {}) as Dictionary).get("discard", 0)),
		"low_energy_exhaust": int((low_energy_vm.get("zones", {}) as Dictionary).get("exhaust", 0)),
		"play_ok": bool(play_result.get("ok", false)),
		"energy_after_play": int(node.get("energy")),
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
	}
	print("CARD_PLAY_CONTRACT_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
