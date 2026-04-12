extends Control
class_name FloorRunner

## Orchestrates the floor loop: map navigation -> combat -> map navigation.
## Wraps the existing CombatSliceRunner for combat rooms.

const FLOOR_CONTROLLER_SCRIPT := preload("res://src/core/map/floor_controller.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")

const CONSTRAINT_TYPES := ["conduit", "circuit", "seal"]

var floor_controller: Variant
var rng: Variant
var gsm: Variant
var combat_runner: Variant
var map_hud: Variant
var exit_overlay: Variant
var keybindings_overlay: Variant
var floor_index: int = 1
var run_seed: int = 42424242
var active_constraint: String = ""
var constraint_history: Array = []

func _ready() -> void:
	rng = RSGC_SCRIPT.new()
	rng.bootstrap(run_seed)
	gsm = GSM_SCRIPT.new()
	floor_controller = FLOOR_CONTROLLER_SCRIPT.new()

	map_hud = get_node_or_null("MapHud")
	combat_runner = get_node_or_null("CombatStage")
	exit_overlay = get_node_or_null("ExitOverlay")
	keybindings_overlay = get_node_or_null("KeybindingsOverlay")

	if map_hud != null:
		map_hud.bind_runner(self)

	_start_floor()

func _start_floor() -> void:
	var result: Dictionary = floor_controller.start_floor(rng, floor_index, active_constraint)
	if not result.get("ok", false):
		push_error("Floor start failed: %s" % str(result))
		return

	# Reset GSM for new floor (stack doesn't persist between floors)
	gsm.reset_stack()

	_show_map()

func _show_map() -> void:
	if combat_runner != null:
		(combat_runner as Control).visible = false
	if map_hud != null:
		(map_hud as Control).visible = true
		map_hud.refresh(
			floor_controller.get_view_model(),
			gsm.stack_snapshot(),
			gsm.stack_cap(),
		)

func _show_combat() -> void:
	if map_hud != null:
		(map_hud as Control).visible = false
	if combat_runner != null:
		(combat_runner as Control).visible = true

func map_commit_room(node_id: int) -> void:
	var select_result: Dictionary = floor_controller.select_room(node_id)
	if not select_result.get("ok", false):
		return

	var enter_result: Dictionary = floor_controller.enter_room(gsm)
	if not enter_result.get("ok", false):
		return

	var action: String = str(enter_result.get("action", ""))
	match action:
		"start_combat":
			_launch_combat(enter_result)
		"event":
			if map_hud != null:
				var node: Dictionary = floor_controller.graph.get_node(floor_controller.current_node)
				var affinity: String = str(node.get("gem_affinity", "neutral"))
				map_hud.show_event("A %s-attuned shrine hums with residual energy." % affinity if affinity != "neutral" else "You find a quiet moment to catch your breath.")
			else:
				floor_controller.complete_non_combat(gsm)
				_after_room_clear()
		"rest":
			if map_hud != null:
				map_hud.show_event("A sheltered alcove offers a moment of rest.")
			else:
				floor_controller.complete_non_combat(gsm)
				_after_room_clear()
		"pass_through":
			floor_controller.complete_non_combat(gsm)
			_after_room_clear()

func _launch_combat(enter_result: Dictionary) -> void:
	if combat_runner == null:
		return

	var node: Dictionary = floor_controller.graph.get_node(floor_controller.current_node)
	var node_type: String = str(node.get("node_type", "combat"))

	# Determine encounter profile based on room visit order within floor
	var profile_index: int = floor_controller.rooms_cleared + 1
	if node_type == "boss":
		profile_index = 99

	# Wire the callback so combat hands control back to us
	combat_runner.floor_runner = self
	combat_runner.use_external_gsm = true
	combat_runner.encounter_index = profile_index
	var seed_val: int = int(rng.draw_next("map.combat_seed").get("value", 0))
	combat_runner.reset_battle(seed_val)
	# Inject GSM AFTER reset so it's not overwritten
	combat_runner.gsm = gsm

	_show_combat()
	# Re-refresh after making visible so _draw triggers
	combat_runner.refresh_hud()

func map_event_dismissed() -> void:
	floor_controller.complete_non_combat(gsm)
	_after_room_clear()

func on_combat_complete(combat_result: String) -> void:
	## Called by combat runner when combat ends and reward is handled.
	# Sync GSM back from combat (it may have been modified)
	if combat_runner != null and combat_runner.gsm != null:
		gsm = combat_runner.gsm

	# Check if this was a boss kill — extract constraint from reward pick
	var node: Dictionary = floor_controller.graph.get_node(floor_controller.current_node)
	var is_boss: bool = bool(node.get("is_exit", false))
	if is_boss and combat_runner != null:
		var selected_card: String = str(combat_runner.reward_selected_card_id)
		if selected_card != "":
			active_constraint = _constraint_for_card(selected_card)
			constraint_history.append(active_constraint)

	var result: Dictionary = floor_controller.complete_combat(gsm, combat_result)
	if not result.get("ok", false):
		return
	if combat_result == CombatSliceRunner.RESULT_PLAYER_LOSE:
		_show_map()
		return
	_after_room_clear()

func _after_room_clear() -> void:
	var fc_state: String = floor_controller.state
	if fc_state == FloorController.STATE_FLOOR_COMPLETE:
		_on_floor_complete()
	else:
		_show_map()

func _on_floor_complete() -> void:
	floor_index += 1
	# TODO: show floor clear screen, constraint draft, then start next floor
	_start_floor()

func _is_exit_overlay_visible() -> bool:
	return exit_overlay is Control and (exit_overlay as Control).visible

func _is_keybindings_overlay_visible() -> bool:
	return keybindings_overlay is Control and (keybindings_overlay as Control).visible

func _open_exit_overlay() -> void:
	if exit_overlay != null and exit_overlay.has_method("open_overlay"):
		exit_overlay.open_overlay()

func _close_exit_overlay() -> void:
	if exit_overlay != null and exit_overlay.has_method("close_overlay"):
		exit_overlay.close_overlay()

func _toggle_keybindings_overlay() -> void:
	if _is_keybindings_overlay_visible():
		_close_keybindings_overlay()
		return
	_open_keybindings_overlay()

func _open_keybindings_overlay() -> void:
	if keybindings_overlay != null and keybindings_overlay.has_method("open_overlay"):
		keybindings_overlay.open_overlay()

func _close_keybindings_overlay() -> void:
	if keybindings_overlay != null and keybindings_overlay.has_method("close_overlay"):
		keybindings_overlay.close_overlay()

func _close_any_open_window() -> bool:
	if combat_runner != null and combat_runner.has_method("is_deck_inspection_open") and combat_runner.is_deck_inspection_open():
		combat_runner.close_deck_inspection()
		return true
	if _is_keybindings_overlay_visible():
		_close_keybindings_overlay()
		return true
	if _is_exit_overlay_visible():
		_close_exit_overlay()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_F2:
		_toggle_keybindings_overlay()
		var viewport_keys := get_viewport()
		if viewport_keys != null:
			viewport_keys.set_input_as_handled()
		return
	if key.keycode != KEY_ESCAPE:
		return
	if _close_any_open_window():
		var viewport_close := get_viewport()
		if viewport_close != null:
			viewport_close.set_input_as_handled()
		return
	_open_exit_overlay()
	var viewport_open := get_viewport()
	if viewport_open != null:
		viewport_open.set_input_as_handled()

func get_floor_view_model() -> Dictionary:
	var fc_vm: Dictionary = floor_controller.get_view_model() if floor_controller != null else {}
	fc_vm["gem_stack"] = gsm.stack_snapshot() if gsm != null else []
	fc_vm["gem_stack_cap"] = gsm.stack_cap() if gsm != null else 6
	fc_vm["active_constraint"] = active_constraint
	fc_vm["constraint_history"] = constraint_history.duplicate(true)
	return fc_vm

func _constraint_for_card(card_id: String) -> String:
	## Deterministically assign a constraint type based on card_id hash.
	## In a full implementation, this would be authored per card or per reward offer.
	var h: int = hash(card_id)
	return CONSTRAINT_TYPES[abs(h) % CONSTRAINT_TYPES.size()]

func get_constraint_label(constraint: String) -> String:
	match constraint:
		"conduit":
			return "Conduit — match a gem pattern for a pre-boss bonus"
		"circuit":
			return "Circuit — trace the correct color sequence through rooms"
		"seal":
			return "Seal — break gem-locked checkpoints to reach the boss"
		_:
			return ""
