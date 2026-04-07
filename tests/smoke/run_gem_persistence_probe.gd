extends SceneTree

const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")
const FLOOR_CONTROLLER_SCRIPT := preload("res://src/core/map/floor_controller.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")

func _init() -> void:
	var rng = RSGC_SCRIPT.new()
	rng.bootstrap(99001122)
	var gsm = GSM_SCRIPT.new()
	var fc = FLOOR_CONTROLLER_SCRIPT.new()

	# Start a floor
	var start_result: Dictionary = fc.start_floor(rng, 1)
	var start_ok: bool = bool(start_result.get("ok", false))

	# Test stack cap
	var cap_before: int = gsm.stack_cap()
	for _i in range(8):
		gsm.produce("Ruby", 1)
	var stack_after_overfill: Array = gsm.stack_snapshot()
	var capped_correctly: bool = stack_after_overfill.size() <= 6

	# Test save/restore
	gsm.reset_stack()
	gsm.produce("Ruby", 2)
	gsm.produce("Sapphire", 1)
	var saved: Dictionary = gsm.save_state()
	gsm.reset_stack()
	var stack_after_reset: Array = gsm.stack_snapshot()
	gsm.restore_state(saved)
	var stack_after_restore: Array = gsm.stack_snapshot()
	var restore_correct: bool = stack_after_restore.size() == 3

	# Test affinity gem grant
	gsm.reset_stack()
	var grant_ruby: Dictionary = gsm.grant_affinity_gem("Ruby")
	var grant_sapphire: Dictionary = gsm.grant_affinity_gem("Sapphire")
	var stack_after_grants: Array = gsm.stack_snapshot()

	# Test slot loss
	var reduce_result: Dictionary = gsm.reduce_cap(1)
	var cap_after_loss: int = gsm.stack_cap()

	# Test floor traversal with gem persistence
	gsm = GSM_SCRIPT.new()
	rng = RSGC_SCRIPT.new()
	rng.bootstrap(99001122)
	fc = FLOOR_CONTROLLER_SCRIPT.new()
	fc.start_floor(rng, 1)

	var legal_moves: Array = fc.get_view_model().get("legal_moves", [])
	var traversal_ok: bool = not legal_moves.is_empty()

	# Select first legal room
	var room_stacks: Array = []
	if not legal_moves.is_empty():
		fc.select_room(legal_moves[0])
		var enter: Dictionary = fc.enter_room(gsm)
		room_stacks.append({
			"node_id": legal_moves[0],
			"action": str(enter.get("action", "")),
			"stack": gsm.stack_snapshot(),
		})
		# Simulate combat complete
		gsm.produce("Ruby", 1)  # simulate producing a gem in combat
		fc.complete_combat(gsm, "player_win")
		room_stacks.append({
			"after_combat_stack": gsm.stack_snapshot(),
		})

		# Enter second room — stack should persist
		var moves2: Array = fc.get_view_model().get("legal_moves", [])
		if not moves2.is_empty():
			fc.select_room(moves2[0])
			var enter2: Dictionary = fc.enter_room(gsm)
			room_stacks.append({
				"node_id": moves2[0],
				"action": str(enter2.get("action", "")),
				"stack_on_entry": gsm.stack_snapshot(),
				"persistence_ok": gsm.stack_snapshot().size() > 0,
			})

	var payload: Dictionary = {
		"start_ok": start_ok,
		"cap_before": cap_before,
		"capped_correctly": capped_correctly,
		"stack_after_overfill_size": stack_after_overfill.size(),
		"restore_correct": restore_correct,
		"stack_after_reset_size": stack_after_reset.size(),
		"stack_after_restore": stack_after_restore,
		"grant_ruby_ok": bool(grant_ruby.get("ok", false)),
		"grant_sapphire_ok": bool(grant_sapphire.get("ok", false)),
		"stack_after_grants": stack_after_grants,
		"cap_after_loss": cap_after_loss,
		"traversal_ok": traversal_ok,
		"room_stacks": room_stacks,
	}

	print("GEM_PERSISTENCE_PROBE=" + JSON.stringify(payload))
	quit()
