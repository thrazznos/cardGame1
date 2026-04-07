extends SceneTree

const RUNNER_SCRIPT := preload("res://src/bootstrap/combat_slice_runner.gd")

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var runner: Node = node
	var results: Array = []

	# Test encounter 1 (steady profile)
	results.append(_capture_encounter_profile(runner, 1))

	# Win encounter 1 via auto-finish, pick reward, advance to encounter 2 (burst)
	_auto_win_and_advance(runner)
	results.append(_capture_encounter_profile(runner, 2))

	# Win encounter 2, advance to encounter 3 (escalating)
	_auto_win_and_advance(runner)
	results.append(_capture_encounter_profile(runner, 3))

	# Win encounter 3, advance to encounter 4 (attrition)
	_auto_win_and_advance(runner)
	results.append(_capture_encounter_profile(runner, 4))

	# Verify all 4 profiles are distinct
	var profile_ids: Array = []
	var all_distinct: bool = true
	for r in results:
		var pid: String = str(r.get("profile_id", ""))
		if profile_ids.has(pid):
			all_distinct = false
		profile_ids.append(pid)

	var payload: Dictionary = {
		"encounters": results,
		"profile_ids": profile_ids,
		"all_profiles_distinct": all_distinct,
		"encounter_count": results.size(),
	}

	print("PRESSURE_PROFILE_PROBE=" + JSON.stringify(payload))
	node.queue_free()
	await process_frame
	quit()


func _capture_encounter_profile(runner: Node, expected_index: int) -> Dictionary:
	var vm: Dictionary = runner.call("get_view_model")
	var intent: Dictionary = vm.get("enemy_intent", {})
	return {
		"encounter_index": int(vm.get("encounter_index", -1)),
		"expected_index": expected_index,
		"index_match": int(vm.get("encounter_index", -1)) == expected_index,
		"profile_id": str(vm.get("pressure_profile_id", "")),
		"profile_name": str(vm.get("pressure_profile_name", "")),
		"enemy_max_hp": int(vm.get("enemy_max_hp", 0)),
		"intent_type": str(intent.get("intent_type", "")),
		"intent_damage": int(intent.get("damage", 0)),
		"telegraph_text": str(intent.get("telegraph_text", "")),
		"has_telegraph": str(intent.get("telegraph_text", "")) != "",
		"encounter_title": str(vm.get("encounter_title", "")),
	}


func _auto_win_and_advance(runner: Node) -> void:
	# Use the runner's built-in auto-finish which handles all card types
	runner.call("_auto_finish_combat", 20)

	# Pick reward and advance
	var vm: Dictionary = runner.call("get_view_model")
	var reward_offer: Array = vm.get("reward_offer", [])
	if not reward_offer.is_empty():
		runner.call("choose_reward_by_index", 0)
	runner.call("start_next_encounter")
