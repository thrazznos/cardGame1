extends SceneTree

const CSR_SCRIPT := preload("res://src/bootstrap/combat_slice_runner.gd")

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var runner: Node = node

	# Advance to encounter 4 (attrition profile)
	for _i in range(3):
		_auto_win_and_advance(runner)

	var vm: Dictionary = runner.call("get_view_model")
	var profile_id: String = str(vm.get("pressure_profile_id", ""))
	var is_attrition: bool = profile_id == "attrition"

	# Play through several turns recording energy drain and discard events
	var turn_records: Array = []
	var max_test_turns: int = 8
	var turn: int = 0

	while str(vm.get("combat_result", "")) == "in_progress" and turn < max_test_turns:
		turn += 1
		var intent: Dictionary = vm.get("enemy_intent", {})
		var intent_type: String = str(intent.get("intent_type", ""))
		var energy_before_pass: int = int(vm.get("energy", 0))
		var hand_size_before_pass: int = vm.get("hand", []).size()

		# Pass immediately to see enemy action effects
		runner.call("player_pass")
		vm = runner.call("get_view_model")

		var energy_after: int = int(vm.get("energy", 0))
		var hand_size_after: int = vm.get("hand", []).size()

		turn_records.append({
			"turn": turn,
			"intent_type": intent_type,
			"energy_before": energy_before_pass,
			"energy_after": energy_after,
			"hand_before": hand_size_before_pass,
			"hand_after": hand_size_after,
		})

	# Check that we saw at least one non-attack intent
	var saw_drain: bool = false
	var saw_discard: bool = false
	for record in turn_records:
		if str(record.get("intent_type", "")) == "drain_energy":
			saw_drain = true
		if str(record.get("intent_type", "")) == "force_discard":
			saw_discard = true

	var payload: Dictionary = {
		"profile_id": profile_id,
		"is_attrition": is_attrition,
		"turns_played": turn,
		"turn_records": turn_records,
		"saw_drain_intent": saw_drain,
		"saw_discard_intent": saw_discard,
		"saw_any_special": saw_drain or saw_discard,
	}

	print("ATTRITION_MECHANICS_PROBE=" + JSON.stringify(payload))
	node.queue_free()
	await process_frame
	quit()


func _auto_win_and_advance(runner: Node) -> void:
	runner.call("_auto_finish_combat", 20)
	var vm: Dictionary = runner.call("get_view_model")
	var reward_offer: Array = vm.get("reward_offer", [])
	if not reward_offer.is_empty():
		runner.call("choose_reward_by_index", 0)
	runner.call("start_next_encounter")
