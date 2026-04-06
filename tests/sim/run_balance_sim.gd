extends SceneTree

const DEFAULT_INPUT := {
	"simulation_id": "sim_default",
	"seed_root": 13371337,
	"deck_list": [],
	"enemy_profile_id": "default",
	"policy_id": "random_legal",
	"balance_profile_id": "default",
	"max_turns": 12,
}

const POLICY_PATHS := {
	"random_legal": "res://tests/sim/policies/policy_random_legal.gd",
}

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

func _init() -> void:
	var input_payload: Dictionary = _load_input_payload()
	var policy: Variant = _load_policy(str(input_payload.get("policy_id", "random_legal")))

	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", int(input_payload.get("seed_root", 13371337)))
	_apply_deck_if_provided(node, input_payload)
	node.call("refresh_hud")

	_run_simulation(node, policy, int(input_payload.get("max_turns", 12)))

	var report: Dictionary = _build_report(node, input_payload)
	print("BALANCE_SIM_REPORT=" + JSON.stringify(report))
	quit()

func _load_input_payload() -> Dictionary:
	var payload := DEFAULT_INPUT.duplicate(true)
	var args: Array = OS.get_cmdline_user_args()
	if args.is_empty():
		return payload

	var input_path: String = str(args[0])
	if not FileAccess.file_exists(input_path):
		return payload

	var f := FileAccess.open(input_path, FileAccess.READ)
	if f == null:
		return payload

	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return payload

	for key in parsed.keys():
		payload[key] = parsed[key]
	return payload

func _load_policy(policy_id: String) -> Variant:
	var path: String = str(POLICY_PATHS.get(policy_id, POLICY_PATHS["random_legal"]))
	var script: Script = load(path)
	return script.new()

func _apply_deck_if_provided(node: Node, input_payload: Dictionary) -> void:
	var provided: Array = input_payload.get("deck_list", [])
	if provided.is_empty():
		return

	var deck_list: Array = []
	for card in provided:
		deck_list.append(str(card))

	node.set("run_master_deck", deck_list.duplicate(true))
	var dls: Variant = node.get("dls")
	dls.draw_pile = deck_list.duplicate(true)
	dls.hand = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	for _i in range(5):
		var drawn: Variant = dls.draw_one()
		if drawn == null:
			break

func _run_simulation(node: Node, policy: Variant, max_turns: int) -> void:
	var step_count: int = 0
	var step_cap: int = 1000
	while step_count < step_cap:
		var vm: Dictionary = node.call("get_view_model")
		if str(vm.get("combat_result", "in_progress")) != "in_progress":
			break
		if int(vm.get("turn", 1)) > max_turns:
			break

		var action: Dictionary = policy.choose_action(vm)
		var action_type: String = str(action.get("type", "pass"))
		if action_type == "play":
			var card_id: String = str(action.get("card_id", ""))
			var result: Dictionary = node.call("player_play_card", card_id)
			if not result.get("ok", false):
				node.call("player_pass")
		else:
			node.call("player_pass")
		step_count += 1

	if step_count >= step_cap:
		node.set("combat_result", "timeout")

func _build_report(node: Node, input_payload: Dictionary) -> Dictionary:
	var vm: Dictionary = node.call("get_view_model")
	var event_stream: Array = node.get("event_stream")
	var card_catalog = CARD_CATALOG_SCRIPT.new()
	var card_play_counts: Dictionary = {}
	var card_effect_value_proxy: Dictionary = {}
	var mana_spent_total: int = 0

	for event in event_stream:
		var e: Dictionary = event
		if str(e.get("kind", "")) != "play_commit":
			continue
		mana_spent_total += 1
		var payload: Dictionary = e.get("payload", {})
		var card_id: String = str(payload.get("card_id", ""))
		if card_id == "":
			continue
		card_play_counts[card_id] = int(card_play_counts.get(card_id, 0)) + 1
		card_effect_value_proxy[card_id] = float(card_effect_value_proxy.get(card_id, 0.0)) + card_catalog.value_proxy(card_id)

	var canonical: Dictionary = {
		"simulation_id": str(input_payload.get("simulation_id", "sim_default")),
		"seed_root": int(input_payload.get("seed_root", 13371337)),
		"policy_id": str(input_payload.get("policy_id", "random_legal")),
		"enemy_profile_id": str(input_payload.get("enemy_profile_id", "default")),
		"result": str(vm.get("combat_result", "timeout")),
		"turns_completed": int(vm.get("turn", 0)),
		"player_hp_end": int(vm.get("player_hp", 0)),
		"enemy_hp_end": int(vm.get("enemy_hp", 0)),
		"mana_spent_total": mana_spent_total,
		"mana_wasted_total": max(0, int(vm.get("energy", 0))),
		"gems_produced_total": 0,
		"gems_consumed_total": 0,
		"advanced_ops_total": 0,
		"stability_ops_total": 0,
		"focus_gate_rejects": 0,
		"card_play_counts": card_play_counts,
		"card_effect_value_proxy": card_effect_value_proxy,
		"event_count": event_stream.size(),
	}
	canonical["determinism_hash"] = str(hash(JSON.stringify(canonical)))
	return canonical

