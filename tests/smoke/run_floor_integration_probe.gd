extends SceneTree

## Full integration test: launch floor scene, navigate map, fight combat, return to map.

func _init() -> void:
	var scene: PackedScene = load("res://scenes/floor/floor_run.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame
	await process_frame

	var floor_runner: Node = node
	var results: Array = []

	# Check floor started
	var fvm: Dictionary = floor_runner.call("get_floor_view_model")
	results.append({
		"step": "floor_start",
		"floor_index": int(fvm.get("floor_index", 0)),
		"state": str(fvm.get("state", "")),
		"current_node": int(fvm.get("current_node", -1)),
		"legal_moves_count": fvm.get("legal_moves", []).size(),
		"gem_stack": fvm.get("gem_stack", []),
		"gem_stack_cap": int(fvm.get("gem_stack_cap", 0)),
	})

	# Navigate to first legal room
	var legal: Array = fvm.get("legal_moves", [])
	if not legal.is_empty():
		floor_runner.call("map_commit_room", int(legal[0]))
		await process_frame

		# Check if we're in combat or auto-completed
		fvm = floor_runner.call("get_floor_view_model")
		var combat_runner: Node = floor_runner.get_node_or_null("CombatSlice")

		results.append({
			"step": "after_first_room",
			"state": str(fvm.get("state", "")),
			"combat_visible": combat_runner.visible if combat_runner != null else false,
			"map_visible": floor_runner.get_node_or_null("MapHud").visible if floor_runner.get_node_or_null("MapHud") != null else false,
		})

		# If in combat, auto-finish it
		if combat_runner != null and combat_runner.visible:
			combat_runner.call("_auto_finish_combat", 20)
			await process_frame

			var cvm: Dictionary = combat_runner.call("get_view_model")
			results.append({
				"step": "combat_finished",
				"combat_result": str(cvm.get("combat_result", "")),
				"reward_state": str(cvm.get("reward_state", "")),
			})

			# Pick reward and continue (this should callback to floor_runner)
			var reward_offer: Array = cvm.get("reward_offer", [])
			if not reward_offer.is_empty():
				combat_runner.call("choose_reward_by_index", 0)
			combat_runner.call("start_next_encounter")
			await process_frame

			# Should be back on map
			fvm = floor_runner.call("get_floor_view_model")
			results.append({
				"step": "back_on_map",
				"state": str(fvm.get("state", "")),
				"rooms_cleared": int(fvm.get("rooms_cleared", 0)),
				"gem_stack": fvm.get("gem_stack", []),
				"map_visible": floor_runner.get_node_or_null("MapHud").visible if floor_runner.get_node_or_null("MapHud") != null else false,
				"combat_visible": combat_runner.visible if combat_runner != null else false,
			})

	var payload: Dictionary = {
		"step_count": results.size(),
		"results": results,
	}
	print("FLOOR_INTEGRATION_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
