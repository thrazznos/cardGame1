extends RefCounted
class_name FloorController

## Floor traversal state machine.
## Manages navigation through a FloorGraph, gem stack persistence between rooms,
## and the combat-slice lifecycle for each room.

const FLOOR_GRAPH_SCRIPT := preload("res://src/core/map/floor_graph.gd")

const STATE_FLOOR_START := "floor_start"
const STATE_ROOM_SELECT := "room_select"
const STATE_ROOM_ENTER := "room_enter"
const STATE_COMBAT := "combat"
const STATE_ROOM_CLEAR := "room_clear"
const STATE_BOSS_GATE := "boss_gate"
const STATE_FLOOR_COMPLETE := "floor_complete"

var state: String = STATE_FLOOR_START
var graph: Variant = null
var current_node: int = -1
var floor_index: int = 1
var rooms_cleared: int = 0
var event_stream: Array[Dictionary] = []
var active_constraint: String = ""

## Conduit objective state
var conduit_pattern: Array = []
var conduit_progress: int = 0
var conduit_matched: bool = false

## Circuit objective state
var circuit_sequence: Array = []
var circuit_progress: int = 0
var circuit_penalties: int = 0

## Seal objective state
var seal_nodes: Array = []
var seals_broken: int = 0

## GSM state saved between rooms
var gsm_floor_state: Dictionary = {}

func start_floor(rng: Variant, p_floor_index: int = 1, p_constraint: String = "") -> Dictionary:
	floor_index = p_floor_index
	active_constraint = p_constraint
	graph = FLOOR_GRAPH_SCRIPT.new()
	var gen_result: Dictionary = graph.generate(rng, floor_index)
	if not gen_result.get("ok", false):
		return gen_result

	current_node = graph.start_node
	rooms_cleared = 0
	state = STATE_ROOM_SELECT
	event_stream = []
	gsm_floor_state = {}

	# Generate conduit pattern if constraint is active
	conduit_pattern = []
	conduit_progress = 0
	conduit_matched = false
	circuit_sequence = []
	circuit_progress = 0
	circuit_penalties = 0
	seal_nodes = []
	seals_broken = 0

	if active_constraint == "conduit":
		conduit_pattern = _generate_conduit_pattern(rng)
	elif active_constraint == "circuit":
		circuit_sequence = _generate_circuit_sequence(rng)
	elif active_constraint == "seal":
		seal_nodes = _generate_seal_nodes(rng)

	graph.mark_cleared(current_node)
	_record_event("floor_start", {
		"floor_index": floor_index,
		"shape": str(gen_result.get("shape", "")),
		"node_count": int(gen_result.get("node_count", 0)),
	})

	return {
		"ok": true,
		"floor_index": floor_index,
		"current_node": current_node,
		"legal_moves": graph.get_legal_moves(current_node),
	}

func select_room(node_id: int) -> Dictionary:
	if state != STATE_ROOM_SELECT:
		return {"ok": false, "reason": "ERR_WRONG_STATE", "state": state}

	var legal: Array = _get_uncleared_legal_moves()
	if not legal.has(node_id):
		return {"ok": false, "reason": "ERR_ILLEGAL_MOVE", "node_id": node_id, "legal": legal}

	var node: Dictionary = graph.get_node(node_id)
	current_node = node_id
	state = STATE_ROOM_ENTER

	_record_event("room_selected", {
		"node_id": node_id,
		"node_type": str(node.get("node_type", "")),
		"gem_affinity": str(node.get("gem_affinity", "")),
	})

	return {
		"ok": true,
		"node_id": node_id,
		"node_type": str(node.get("node_type", "")),
		"gem_affinity": str(node.get("gem_affinity", "")),
	}

func enter_room(gsm: Variant) -> Dictionary:
	if state != STATE_ROOM_ENTER:
		return {"ok": false, "reason": "ERR_WRONG_STATE", "state": state}

	var node: Dictionary = graph.get_node(current_node)
	var node_type: String = str(node.get("node_type", ""))
	var gem_affinity: String = str(node.get("gem_affinity", ""))

	# Restore GSM state from previous room (persistence)
	if not gsm_floor_state.is_empty():
		gsm.restore_state(gsm_floor_state)

	# Check gem gate
	var gem_gate: Variant = node.get("gem_gate", null)
	var gate_result: Dictionary = {}
	if gem_gate is Dictionary:
		var gate_gem: String = str(gem_gate.get("gem", ""))
		var gate_cost: int = int(gem_gate.get("cost", 0))
		gate_result = _try_pay_gate(gsm, gate_gem, gate_cost)

	# Grant affinity gem
	var gem_grant: Dictionary = {}
	if gem_affinity != "" and gem_affinity != "neutral":
		gem_grant = gsm.grant_affinity_gem(gem_affinity)

	# Track objective progress
	_check_conduit_progress(node)
	_check_circuit_progress(node)
	_check_seal_progress(node, gsm)

	_record_event("room_entered", {
		"node_id": current_node,
		"node_type": node_type,
		"gem_affinity": gem_affinity,
		"gem_grant": gem_grant,
		"gem_gate": gate_result,
		"stack_on_entry": gsm.stack_snapshot(),
	})

	if node_type == "combat" or node_type == "boss":
		state = STATE_COMBAT
		return {
			"ok": true,
			"action": "start_combat",
			"node_id": current_node,
			"gem_affinity": gem_affinity,
			"gem_grant": gem_grant,
		}
	elif node_type == "event":
		# Events are non-combat — auto-clear for MVP
		state = STATE_ROOM_CLEAR
		return {
			"ok": true,
			"action": "event",
			"node_id": current_node,
			"gem_affinity": gem_affinity,
			"gem_grant": gem_grant,
		}
	elif node_type == "rest":
		state = STATE_ROOM_CLEAR
		return {
			"ok": true,
			"action": "rest",
			"node_id": current_node,
			"gem_affinity": gem_affinity,
			"gem_grant": gem_grant,
		}
	else:
		# Start node or unknown — skip to room select
		state = STATE_ROOM_CLEAR
		return {
			"ok": true,
			"action": "pass_through",
			"node_id": current_node,
		}

func complete_combat(gsm: Variant, combat_result: String) -> Dictionary:
	if state != STATE_COMBAT:
		return {"ok": false, "reason": "ERR_WRONG_STATE", "state": state}

	# Save GSM state for persistence to next room
	gsm_floor_state = gsm.save_state()

	graph.mark_cleared(current_node)
	rooms_cleared += 1

	var node: Dictionary = graph.get_node(current_node)
	var is_boss: bool = bool(node.get("is_exit", false))

	_record_event("room_cleared", {
		"node_id": current_node,
		"combat_result": combat_result,
		"rooms_cleared": rooms_cleared,
		"stack_on_exit": gsm.stack_snapshot(),
		"is_boss": is_boss,
	})

	if is_boss:
		state = STATE_FLOOR_COMPLETE
		return {
			"ok": true,
			"action": "floor_complete",
			"combat_result": combat_result,
			"rooms_cleared": rooms_cleared,
		}

	state = STATE_ROOM_SELECT
	return {
		"ok": true,
		"action": "continue",
		"combat_result": combat_result,
		"legal_moves": _get_uncleared_legal_moves(),
	}

func complete_non_combat(gsm: Variant) -> Dictionary:
	if state != STATE_ROOM_CLEAR:
		return {"ok": false, "reason": "ERR_WRONG_STATE", "state": state}

	gsm_floor_state = gsm.save_state()
	graph.mark_cleared(current_node)
	rooms_cleared += 1

	var node: Dictionary = graph.get_node(current_node)
	var is_boss: bool = bool(node.get("is_exit", false))

	_record_event("room_cleared", {
		"node_id": current_node,
		"rooms_cleared": rooms_cleared,
		"is_boss": is_boss,
	})

	if is_boss:
		state = STATE_FLOOR_COMPLETE
		return {"ok": true, "action": "floor_complete", "rooms_cleared": rooms_cleared}

	state = STATE_ROOM_SELECT
	return {
		"ok": true,
		"action": "continue",
		"legal_moves": _get_uncleared_legal_moves(),
	}

## Returns the current state string (e.g. STATE_FLOOR_COMPLETE).
func get_state() -> String:
	return state

## Returns the data dictionary for the current node, or an empty dictionary
## if no graph or node is active.
func get_current_node_data() -> Dictionary:
	if graph == null or current_node < 0:
		return {}
	return graph.get_node(current_node)

## Returns the number of rooms cleared on this floor.
func get_rooms_cleared() -> int:
	return rooms_cleared

func get_view_model() -> Dictionary:
	var graph_vm: Dictionary = graph.get_view_model() if graph != null else {}
	return {
		"state": state,
		"floor_index": floor_index,
		"current_node": current_node,
		"rooms_cleared": rooms_cleared,
		"legal_moves": _get_uncleared_legal_moves(),
		"graph": graph_vm,
		"active_constraint": active_constraint,
		"conduit_pattern": conduit_pattern.duplicate(true),
		"conduit_progress": conduit_progress,
		"conduit_matched": conduit_matched,
		"circuit_sequence": circuit_sequence.duplicate(true),
		"circuit_progress": circuit_progress,
		"circuit_penalties": circuit_penalties,
		"seal_nodes": seal_nodes.duplicate(true),
		"seals_broken": seals_broken,
		"seals_total": seal_nodes.size(),
		"boss_locked": is_boss_locked(),
	}

func _get_uncleared_legal_moves() -> Array:
	if graph == null:
		return []
	var neighbors: Array = graph.get_legal_moves(current_node)
	var uncleared: Array = []
	for n_id in neighbors:
		var node: Dictionary = graph.get_node(n_id)
		if not bool(node.get("cleared", false)):
			uncleared.append(n_id)
	# Boss node — accessible unless seals are active and unbroken
	if not uncleared.has(graph.exit_node) and neighbors.has(graph.exit_node):
		var exit_node: Dictionary = graph.get_node(graph.exit_node)
		if not bool(exit_node.get("cleared", false)) and not is_boss_locked():
			uncleared.append(graph.exit_node)
	return uncleared

func _generate_conduit_pattern(rng: Variant) -> Array:
	var gems := ["Ruby", "Sapphire"]
	var pattern: Array = []
	var length: int = 3 + (floor_index - 1)  # 3 on floor 1, grows with depth
	length = min(length, 5)  # Cap at 5
	for _i in range(length):
		var draw: Dictionary = rng.draw_next("map.conduit")
		pattern.append(gems[int(draw.get("value", 0)) % gems.size()])
	return pattern

func _check_conduit_progress(node: Dictionary) -> void:
	if active_constraint != "conduit" or conduit_pattern.is_empty():
		return
	if conduit_matched:
		return
	var affinity: String = str(node.get("gem_affinity", ""))
	if affinity == "neutral" or affinity == "":
		return
	if conduit_progress < conduit_pattern.size() and affinity == conduit_pattern[conduit_progress]:
		conduit_progress += 1
		if conduit_progress >= conduit_pattern.size():
			conduit_matched = true
			_record_event("conduit_matched", {
				"pattern": conduit_pattern,
				"progress": conduit_progress,
			})

func _generate_circuit_sequence(rng: Variant) -> Array:
	var gems := ["Ruby", "Sapphire"]
	var seq: Array = []
	var length: int = 3 + min(floor_index - 1, 2)
	for _i in range(length):
		var draw: Dictionary = rng.draw_next("map.circuit")
		seq.append(gems[int(draw.get("value", 0)) % gems.size()])
	return seq

func _check_circuit_progress(node: Dictionary) -> void:
	if active_constraint != "circuit" or circuit_sequence.is_empty():
		return
	if circuit_progress >= circuit_sequence.size():
		return
	var affinity: String = str(node.get("gem_affinity", ""))
	if affinity == "neutral" or affinity == "":
		return
	if affinity == circuit_sequence[circuit_progress]:
		circuit_progress += 1
		_record_event("circuit_advance", {"progress": circuit_progress, "total": circuit_sequence.size(), "gem": affinity})
		if circuit_progress >= circuit_sequence.size():
			_record_event("circuit_complete", {"sequence": circuit_sequence})
	else:
		circuit_penalties += 1
		_record_event("circuit_wrong", {"expected": circuit_sequence[circuit_progress], "got": affinity, "penalties": circuit_penalties})

func _generate_seal_nodes(rng: Variant) -> Array:
	var seals: Array = []
	var candidates: Array = []
	for node in graph.nodes:
		var ntype: String = str(node.get("node_type", ""))
		if ntype == "combat" or ntype == "event":
			candidates.append(int(node.get("node_id", -1)))
	var seal_count: int = min(3, candidates.size())
	for _i in range(seal_count):
		if candidates.is_empty():
			break
		var draw: Dictionary = rng.draw_next("map.seal")
		var idx: int = int(draw.get("value", 0)) % candidates.size()
		var target: int = candidates[idx]
		candidates.remove_at(idx)
		seals.append(target)
		# Mark the node as a seal node
		if target >= 0 and target < graph.nodes.size():
			graph.nodes[target]["is_seal"] = true
	return seals

func _check_seal_progress(node: Dictionary, gsm: Variant) -> void:
	if active_constraint != "seal":
		return
	var node_id: int = int(node.get("node_id", -1))
	if not seal_nodes.has(node_id):
		return
	if bool(node.get("seal_broken", false)):
		return
	# Break the seal — costs 1 gem of the room's affinity
	var affinity: String = str(node.get("gem_affinity", "neutral"))
	if affinity != "neutral" and affinity != "" and gsm != null:
		gsm.consume_top(affinity)
	seals_broken += 1
	if node_id >= 0 and node_id < graph.nodes.size():
		graph.nodes[node_id]["seal_broken"] = true
	_record_event("seal_broken", {"node_id": node_id, "seals_broken": seals_broken, "total": seal_nodes.size()})

func is_boss_locked() -> bool:
	if active_constraint != "seal":
		return false
	return seals_broken < seal_nodes.size()

func _try_pay_gate(gsm: Variant, gate_gem: String, gate_cost: int) -> Dictionary:
	if gate_cost <= 0 or gate_gem == "":
		return {"ok": true, "paid": true, "cost": 0}

	# Try to consume gems from the stack
	var consumed: int = 0
	for _i in range(gate_cost):
		var result: Dictionary = gsm.consume_top(gate_gem)
		if bool(result.get("ok", false)):
			consumed += 1
		else:
			break

	if consumed >= gate_cost:
		_record_event("gem_gate_paid", {
			"gem": gate_gem,
			"cost": gate_cost,
			"consumed": consumed,
		})
		return {"ok": true, "paid": true, "cost": gate_cost, "consumed": consumed}

	# Couldn't afford — trigger gem slot loss
	var slot_loss: Dictionary = gsm.reduce_cap(1)
	_record_event("gem_slot_lost", {
		"gem": gate_gem,
		"cost": gate_cost,
		"consumed": consumed,
		"shortfall": gate_cost - consumed,
		"cap_after": int(slot_loss.get("cap_after", 0)),
	})
	return {
		"ok": true,
		"paid": false,
		"slot_lost": true,
		"cost": gate_cost,
		"consumed": consumed,
		"cap_after": int(slot_loss.get("cap_after", 0)),
	}

func _record_event(kind: String, payload: Dictionary) -> void:
	event_stream.append({
		"order_index": event_stream.size(),
		"kind": kind,
		"payload": payload,
	})
