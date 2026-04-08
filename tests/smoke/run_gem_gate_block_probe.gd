extends SceneTree

const FLOOR_CONTROLLER_SCRIPT := preload("res://src/core/map/floor_controller.gd")
const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")

func _init() -> void:
	var setup: Dictionary = _find_start_gate_setup()
	if not setup.get("ok", false):
		print("GEM_GATE_BLOCK_PROBE=" + JSON.stringify({"ok": false, "reason": "ERR_NO_START_GATE_FOUND"}))
		quit()
		return

	var fc: Variant = setup.get("floor_controller")
	var gsm: Variant = GSM_SCRIPT.new()
	var gated_node_id: int = int(setup.get("gated_node_id", -1))
	var legal_moves_before: Array = fc.get_view_model().get("legal_moves", [])
	var select_result: Dictionary = fc.select_room(gated_node_id)
	var enter_result: Dictionary = {}
	if bool(select_result.get("ok", false)):
		enter_result = fc.enter_room(gsm)

	var payload: Dictionary = {
		"ok": true,
		"seed": int(setup.get("seed", 0)),
		"gated_node_id": gated_node_id,
		"gate_gem": str(setup.get("gate_gem", "")),
		"gate_cost": int(setup.get("gate_cost", 0)),
		"legal_moves_before": legal_moves_before,
		"select_ok": bool(select_result.get("ok", false)),
		"select_reason": str(select_result.get("reason", "")),
		"enter_ok": bool(enter_result.get("ok", false)),
		"enter_reason": str(enter_result.get("reason", "")),
		"enter_action": str(enter_result.get("action", "")),
		"state_after_attempt": str(fc.get_state()),
		"stack_after_attempt": gsm.stack_snapshot(),
		"cap_after_attempt": int(gsm.stack_cap()),
		"event_kinds": _event_kinds(fc.event_stream if fc != null else []),
	}
	print("GEM_GATE_BLOCK_PROBE=" + JSON.stringify(payload))
	quit()

func _find_start_gate_setup() -> Dictionary:
	for seed in range(1, 400):
		var rng = RSGC_SCRIPT.new()
		rng.bootstrap(seed)
		var fc = FLOOR_CONTROLLER_SCRIPT.new()
		var start_result: Dictionary = fc.start_floor(rng, 1)
		if not bool(start_result.get("ok", false)):
			continue
		var vm: Dictionary = fc.get_view_model()
		var graph_vm: Dictionary = vm.get("graph", {})
		var nodes: Array = graph_vm.get("nodes", [])
		var edges: Array = graph_vm.get("edges", [])
		var current_node: int = int(vm.get("current_node", 0))
		for node_id in _neighbors_from_edges(edges, current_node):
			var node: Dictionary = _node_by_id(nodes, int(node_id))
			var gate: Variant = node.get("gem_gate", null)
			if gate is Dictionary and int(gate.get("cost", 0)) > 0:
				return {
					"ok": true,
					"seed": seed,
					"floor_controller": fc,
					"gated_node_id": int(node_id),
					"gate_gem": str(gate.get("gem", "")),
					"gate_cost": int(gate.get("cost", 0)),
				}
	return {"ok": false}

func _node_by_id(nodes: Array, node_id: int) -> Dictionary:
	for node in nodes:
		if node is Dictionary and int(node.get("node_id", -1)) == node_id:
			return node.duplicate(true)
	return {}

func _neighbors_from_edges(edges: Array, node_id: int) -> Array:
	var neighbors: Array = []
	for edge in edges:
		if not (edge is Array) or edge.size() < 2:
			continue
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if a == node_id and not neighbors.has(b):
			neighbors.append(b)
		elif b == node_id and not neighbors.has(a):
			neighbors.append(a)
	neighbors.sort()
	return neighbors

func _event_kinds(events: Array) -> Array:
	var kinds: Array = []
	for event in events:
		if event is Dictionary:
			kinds.append(str(event.get("kind", "")))
	return kinds
