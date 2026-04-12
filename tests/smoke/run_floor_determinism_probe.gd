extends SceneTree

## Determinism probe: run the same floor twice with the same seed,
## verify gem stack state and combat results match exactly.

func _init() -> void:
	var run_a: Dictionary = await _run_floor(55667788)
	var run_b: Dictionary = await _run_floor(55667788)

	var deterministic: bool = true
	var mismatches: Array = []

	# Compare each room's gem stack and combat result
	var rooms_a: Array = run_a.get("rooms", [])
	var rooms_b: Array = run_b.get("rooms", [])
	if rooms_a.size() != rooms_b.size():
		deterministic = false
		mismatches.append("room_count: %d vs %d" % [rooms_a.size(), rooms_b.size()])
	else:
		for i in range(rooms_a.size()):
			var ra: Dictionary = rooms_a[i]
			var rb: Dictionary = rooms_b[i]
			if str(ra.get("stack_on_entry")) != str(rb.get("stack_on_entry")):
				deterministic = false
				mismatches.append("room_%d stack_on_entry" % i)
			if str(ra.get("stack_on_exit")) != str(rb.get("stack_on_exit")):
				deterministic = false
				mismatches.append("room_%d stack_on_exit" % i)
			if str(ra.get("combat_result")) != str(rb.get("combat_result")):
				deterministic = false
				mismatches.append("room_%d combat_result" % i)

	# Compare final state hash
	if str(run_a.get("final_hash")) != str(run_b.get("final_hash")):
		deterministic = false
		mismatches.append("final_hash")

	var payload: Dictionary = {
		"deterministic": deterministic,
		"mismatches": mismatches,
		"rooms_traversed": rooms_a.size(),
		"run_a_rooms": rooms_a,
		"run_b_final_hash": str(run_b.get("final_hash", "")),
		"run_a_final_hash": str(run_a.get("final_hash", "")),
	}
	print("FLOOR_DETERMINISM_PROBE=" + JSON.stringify(payload))
	quit()


func _run_floor(seed_root: int) -> Dictionary:
	var scene: PackedScene = load("res://scenes/floor/floor_run.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)

	# Wait for _ready
	await process_frame
	await process_frame

	var runner: Node = node
	var rooms: Array = []

	# Get the floor view model
	var fvm: Dictionary = runner.call("get_floor_view_model")
	var max_rooms: int = 4

	for _room_iter in range(max_rooms):
		fvm = runner.call("get_floor_view_model")
		var state: String = str(fvm.get("state", ""))
		if state != "room_select":
			break

		var legal: Array = fvm.get("legal_moves", [])
		if legal.is_empty():
			break

		var stack_before: Array = fvm.get("gem_stack", [])

		# Select first legal room
		runner.call("map_commit_room", int(legal[0]))
		await process_frame

		# Check if we're in combat
		fvm = runner.call("get_floor_view_model")
		var combat_runner: Node = runner.get_node_or_null("CombatStage")
		var combat_result: String = "skipped"

		if combat_runner != null and combat_runner.visible:
			# Auto-finish combat
			combat_runner.call("_auto_finish_combat", 15)
			await process_frame

			var cvm: Dictionary = combat_runner.call("get_view_model")
			combat_result = str(cvm.get("combat_result", ""))

			# Pick reward if available
			var reward_offer: Array = cvm.get("reward_offer", [])
			if not reward_offer.is_empty():
				combat_runner.call("choose_reward_by_index", 0)
			combat_runner.call("start_next_encounter")
			await process_frame

		fvm = runner.call("get_floor_view_model")
		var stack_after: Array = fvm.get("gem_stack", [])

		rooms.append({
			"room_index": _room_iter,
			"stack_on_entry": stack_before.duplicate(true),
			"stack_on_exit": stack_after.duplicate(true),
			"combat_result": combat_result,
		})

	# Final hash of full state
	fvm = runner.call("get_floor_view_model")
	var final_hash: String = str(hash(JSON.stringify(fvm)))

	node.queue_free()
	await process_frame

	return {
		"rooms": rooms,
		"final_hash": final_hash,
	}
