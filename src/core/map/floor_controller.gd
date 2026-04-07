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

## GSM state saved between rooms
var gsm_floor_state: Dictionary = {}

func start_floor(rng: Variant, p_floor_index: int = 1) -> Dictionary:
	floor_index = p_floor_index
	graph = FLOOR_GRAPH_SCRIPT.new()
	var gen_result: Dictionary = graph.generate(rng, floor_index)
	if not gen_result.get("ok", false):
		return gen_result

	current_node = graph.start_node
	rooms_cleared = 0
	state = STATE_ROOM_SELECT
	event_stream = []
	gsm_floor_state = {}

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

	# Grant affinity gem
	var gem_grant: Dictionary = {}
	if gem_affinity != "" and gem_affinity != "neutral":
		gem_grant = gsm.grant_affinity_gem(gem_affinity)

	_record_event("room_entered", {
		"node_id": current_node,
		"node_type": node_type,
		"gem_affinity": gem_affinity,
		"gem_grant": gem_grant,
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

func get_view_model() -> Dictionary:
	var graph_vm: Dictionary = graph.get_view_model() if graph != null else {}
	return {
		"state": state,
		"floor_index": floor_index,
		"current_node": current_node,
		"rooms_cleared": rooms_cleared,
		"legal_moves": _get_uncleared_legal_moves(),
		"graph": graph_vm,
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
	# Boss node is always accessible even if "cleared" logic doesn't apply
	if not uncleared.has(graph.exit_node) and neighbors.has(graph.exit_node):
		var exit_node: Dictionary = graph.get_node(graph.exit_node)
		if not bool(exit_node.get("cleared", false)):
			uncleared.append(graph.exit_node)
	return uncleared

func _record_event(kind: String, payload: Dictionary) -> void:
	event_stream.append({
		"order_index": event_stream.size(),
		"kind": kind,
		"payload": payload,
	})
