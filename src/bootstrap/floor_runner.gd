extends Control
class_name FloorRunner

## Orchestrates the floor loop: map navigation -> combat -> map navigation.
## Wraps the existing CombatSliceRunner for combat rooms.

const FLOOR_CONTROLLER_SCRIPT := preload("res://src/core/map/floor_controller.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")

var floor_controller: Variant
var rng: Variant
var gsm: Variant
var combat_runner: Variant
var map_hud: Variant
var floor_index: int = 1
var run_seed: int = 42424242

func _ready() -> void:
	rng = RSGC_SCRIPT.new()
	rng.bootstrap(run_seed)
	gsm = GSM_SCRIPT.new()
	floor_controller = FLOOR_CONTROLLER_SCRIPT.new()

	map_hud = get_node_or_null("MapHud")
	combat_runner = get_node_or_null("CombatSlice")

	if map_hud != null:
		map_hud.bind_runner(self)

	_start_floor()

func _start_floor() -> void:
	var result: Dictionary = floor_controller.start_floor(rng, floor_index)
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
			# MVP: auto-complete events
			floor_controller.complete_non_combat(gsm)
			_after_room_clear()
		"rest":
			# MVP: auto-complete rest (could heal later)
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
	combat_runner.gsm = gsm
	combat_runner.encounter_index = profile_index
	combat_runner.reset_battle(rng.draw_next("map.combat_seed").get("value", 0))

	_show_combat()

func on_combat_complete(combat_result: String) -> void:
	## Called by combat runner when combat ends and reward is handled.
	# Sync GSM back from combat (it may have been modified)
	if combat_runner != null and combat_runner.gsm != null:
		gsm = combat_runner.gsm
	var result: Dictionary = floor_controller.complete_combat(gsm, combat_result)
	if not result.get("ok", false):
		return
	if combat_result == "player_lose":
		# TODO: run over screen
		_show_map()
		return
	_after_room_clear()

func _after_room_clear() -> void:
	var fc_state: String = floor_controller.state
	if fc_state == "floor_complete":
		_on_floor_complete()
	else:
		_show_map()

func _on_floor_complete() -> void:
	floor_index += 1
	# TODO: show floor clear screen, constraint draft, then start next floor
	_start_floor()

func get_floor_view_model() -> Dictionary:
	var fc_vm: Dictionary = floor_controller.get_view_model() if floor_controller != null else {}
	fc_vm["gem_stack"] = gsm.stack_snapshot() if gsm != null else []
	fc_vm["gem_stack_cap"] = gsm.stack_cap() if gsm != null else 6
	return fc_vm
