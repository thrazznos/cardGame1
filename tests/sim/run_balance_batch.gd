extends SceneTree

const POLICY_PATHS := {
	"random_legal": "res://tests/sim/policies/policy_random_legal.gd",
	"greedy_value": "res://tests/sim/policies/policy_greedy_value.gd",
	"sequencing_aware_v1": "res://tests/sim/policies/policy_sequencing_aware_v1.gd",
}

const DAMAGE_PROXY := {
	"strike": 6.0,
	"defend": 5.0,
	"scheme": 0.0,
}

func _init() -> void:
	var scenario_payload: Dictionary = _load_scenario_payload()
	if scenario_payload.is_empty():
		push_error("Scenario payload missing or invalid")
		quit(1)
		return

	var jobs: Array[Dictionary] = _expand_jobs(scenario_payload)
	if jobs.is_empty():
		push_error("Scenario expanded to zero jobs")
		quit(1)
		return

	var artifact_path: String = _artifact_path(str(scenario_payload.get("scenario_id", "scenario")))
	var out := FileAccess.open(artifact_path, FileAccess.WRITE)
	if out == null:
		push_error("Failed to open artifact path: %s" % artifact_path)
		quit(1)
		return

	for job in jobs:
		var report: Dictionary = await _run_single(job)
		out.store_line(JSON.stringify(report))

	out.close()
	print("BALANCE_BATCH_ARTIFACT=" + artifact_path)
	print("BALANCE_BATCH_COUNT=" + str(jobs.size()))
	quit()

func _load_scenario_payload() -> Dictionary:
	var args: Array = OS.get_cmdline_user_args()
	var scenario_path: String = "res://tests/sim/scenarios/baseline_commons_v1.json"
	if not args.is_empty():
		scenario_path = str(args[0])

	if not FileAccess.file_exists(scenario_path):
		return {}

	var f := FileAccess.open(scenario_path, FileAccess.READ)
	if f == null:
		return {}

	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _expand_jobs(scenario_payload: Dictionary) -> Array[Dictionary]:
	var scenario_id: String = str(scenario_payload.get("scenario_id", "scenario"))
	var defaults: Dictionary = scenario_payload.get("defaults", {})
	var seeds: Array = scenario_payload.get("seeds", [])
	var policies: Array = scenario_payload.get("policies", [])
	var decks: Array = scenario_payload.get("decks", [])
	var jobs: Array[Dictionary] = []

	for deck_index in range(decks.size()):
		var deck: Dictionary = decks[deck_index]
		var deck_id: String = str(deck.get("deck_id", "deck_%d" % deck_index))
		var deck_cards: Array = []
		for card in deck.get("cards", []):
			deck_cards.append(str(card))

		for seed in seeds:
			for policy in policies:
				var seed_int: int = int(seed)
				var policy_id: String = str(policy)
				var job: Dictionary = {
					"simulation_id": "%s__%s__%d__%s" % [scenario_id, deck_id, seed_int, policy_id],
					"seed_root": seed_int,
					"deck_list": deck_cards.duplicate(true),
					"enemy_profile_id": str(deck.get("enemy_profile_id", defaults.get("enemy_profile_id", "default"))),
					"policy_id": policy_id,
					"balance_profile_id": str(deck.get("balance_profile_id", defaults.get("balance_profile_id", "default"))),
					"max_turns": int(deck.get("max_turns", defaults.get("max_turns", 12))),
					"scenario_id": scenario_id,
					"deck_id": deck_id,
				}
				jobs.append(job)
	return jobs

func _artifact_path(scenario_id: String) -> String:
	var base_dir: String = ProjectSettings.globalize_path("res://artifacts/balance/raw")
	DirAccess.make_dir_recursive_absolute(base_dir)
	var stamp: int = int(Time.get_unix_time_from_system())
	return base_dir.path_join("%s_%d.jsonl" % [scenario_id, stamp])

func _run_single(input_payload: Dictionary) -> Dictionary:
	var policy_bundle: Dictionary = _load_policy(str(input_payload.get("policy_id", "random_legal")))
	var policy: Variant = policy_bundle.get("instance")
	var runtime_policy_id: String = str(policy_bundle.get("runtime_id", "random_legal"))

	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", int(input_payload.get("seed_root", 13371337)))
	_apply_deck_if_provided(node, input_payload)
	node.call("refresh_hud")

	_run_simulation(node, policy, int(input_payload.get("max_turns", 12)))

	var report: Dictionary = _build_report(node, input_payload, runtime_policy_id)
	node.queue_free()
	await process_frame
	return report

func _load_policy(policy_id: String) -> Dictionary:
	var resolved_policy_id: String = policy_id
	if not POLICY_PATHS.has(resolved_policy_id):
		resolved_policy_id = "random_legal"
	var path: String = str(POLICY_PATHS.get(resolved_policy_id, POLICY_PATHS["random_legal"]))
	var script: Script = load(path)
	var instance: Variant = script.new()
	if instance.has_method("get_policy_id"):
		resolved_policy_id = str(instance.call("get_policy_id"))
	return {
		"instance": instance,
		"runtime_id": resolved_policy_id,
	}

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

func _build_report(node: Node, input_payload: Dictionary, runtime_policy_id: String) -> Dictionary:
	var vm: Dictionary = node.call("get_view_model")
	var event_stream: Array = node.get("event_stream")
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
		card_effect_value_proxy[card_id] = float(card_effect_value_proxy.get(card_id, 0.0)) + _value_proxy_for_card(card_id)

	var canonical: Dictionary = {
		"simulation_id": str(input_payload.get("simulation_id", "sim_default")),
		"scenario_id": str(input_payload.get("scenario_id", "scenario")),
		"deck_id": str(input_payload.get("deck_id", "deck")),
		"seed_root": int(input_payload.get("seed_root", 13371337)),
		"policy_id": str(input_payload.get("policy_id", "random_legal")),
		"policy_runtime_id": runtime_policy_id,
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

func _value_proxy_for_card(card_id: String) -> float:
	if card_id.begins_with("strike"):
		return DAMAGE_PROXY["strike"]
	if card_id.begins_with("defend"):
		return DAMAGE_PROXY["defend"]
	if card_id.begins_with("scheme"):
		return DAMAGE_PROXY["scheme"]
	return 0.0
