extends SceneTree

## Encounter Variety Report Probe
##
## Runs all 4 encounter profiles to completion, recording per-encounter metrics:
## turns to win/lose, damage taken, cards played, intent type distribution.
## Outputs a comparative summary proving encounters pressure different habits.

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var runner: Node = node
	var encounter_reports: Array = []

	# Run through 4 encounters collecting metrics
	for enc_idx in range(1, 5):
		if enc_idx > 1:
			_auto_win_and_advance(runner)
		var report: Dictionary = _run_encounter_to_completion(runner, enc_idx)
		encounter_reports.append(report)

	# Cross-encounter comparison
	var profile_ids: Array = []
	var turns_list: Array = []
	var damage_taken_list: Array = []
	var intent_distributions: Array = []
	for r in encounter_reports:
		profile_ids.append(str(r.get("profile_id", "")))
		turns_list.append(int(r.get("turns_to_end", 0)))
		damage_taken_list.append(int(r.get("total_damage_taken", 0)))
		intent_distributions.append(r.get("intent_type_counts", {}))

	var all_profiles_unique: bool = true
	for i in range(profile_ids.size()):
		for j in range(i + 1, profile_ids.size()):
			if profile_ids[i] == profile_ids[j]:
				all_profiles_unique = false

	var payload: Dictionary = {
		"encounter_count": encounter_reports.size(),
		"encounter_reports": encounter_reports,
		"profile_ids": profile_ids,
		"all_profiles_unique": all_profiles_unique,
		"turns_range": [turns_list.min(), turns_list.max()],
		"damage_taken_range": [damage_taken_list.min(), damage_taken_list.max()],
		"intent_distributions": intent_distributions,
	}

	print("ENCOUNTER_VARIETY_REPORT=" + JSON.stringify(payload))
	node.queue_free()
	await process_frame
	quit()


func _run_encounter_to_completion(runner: Node, expected_index: int) -> Dictionary:
	var vm: Dictionary = runner.call("get_view_model")
	var profile_id: String = str(vm.get("pressure_profile_id", ""))
	var profile_name: String = str(vm.get("pressure_profile_name", ""))
	var start_hp: int = int(vm.get("player_hp", 0))
	var enemy_max_hp: int = int(vm.get("enemy_max_hp", 0))
	var intent_type_counts: Dictionary = {}
	var cards_played: int = 0
	var turns: int = 0

	while str(vm.get("combat_result", "")) == "in_progress" and turns < 50:
		turns += 1
		# Record this turn's intent type
		var intent: Dictionary = vm.get("enemy_intent", {})
		var intent_type: String = str(intent.get("intent_type", "attack"))
		intent_type_counts[intent_type] = int(intent_type_counts.get(intent_type, 0)) + 1

		# Play cards
		var hand: Array = vm.get("hand", [])
		for card_id in hand:
			if int(vm.get("energy", 0)) <= 0:
				break
			var result: Dictionary = runner.call("player_play_card", str(card_id))
			if bool(result.get("ok", false)):
				cards_played += 1
			vm = runner.call("get_view_model")
			if str(vm.get("combat_result", "")) != "in_progress":
				break

		if str(vm.get("combat_result", "")) == "in_progress":
			runner.call("player_pass")
			vm = runner.call("get_view_model")

	var end_hp: int = int(vm.get("player_hp", 0))
	return {
		"encounter_index": expected_index,
		"profile_id": profile_id,
		"profile_name": profile_name,
		"combat_result": str(vm.get("combat_result", "")),
		"turns_to_end": turns,
		"total_damage_taken": start_hp - end_hp,
		"player_hp_remaining": end_hp,
		"enemy_max_hp": enemy_max_hp,
		"cards_played": cards_played,
		"intent_type_counts": intent_type_counts,
	}


func _auto_win_and_advance(runner: Node) -> void:
	var vm: Dictionary = runner.call("get_view_model")
	# Use built-in auto-finish
	runner.call("_auto_finish_combat", 20)
	vm = runner.call("get_view_model")
	var reward_offer: Array = vm.get("reward_offer", [])
	if not reward_offer.is_empty():
		runner.call("choose_reward_by_index", 0)
	runner.call("start_next_encounter")
