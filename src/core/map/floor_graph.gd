extends RefCounted
class_name FloorGraph

## Generates and holds a gem-attuned floor graph from polyhedra projections.
## Deterministic from seed. Nodes have gem affinity, type, and adjacency.

const GEM_AFFINITIES := ["Ruby", "Sapphire", "neutral"]
const NODE_TYPES := ["combat", "combat", "combat", "event", "rest", "boss"]

## Polyhedra edge definitions (0-indexed node pairs).
## Connectivity target: 2-3 edges per node.
const TETRAHEDRON_EDGES := [
	[0, 1], [0, 2], [0, 3],
	[1, 2], [1, 3], [2, 3],
]
const TETRAHEDRON_NODE_COUNT := 4

## Octahedron: 6 vertices, 12 edges in full form.
## Pruned to 8 edges for 2-3 connectivity target.
const OCTAHEDRON_EDGES := [
	[0, 1], [0, 2],
	[1, 3],
	[2, 3], [2, 4],
	[3, 5],
	[4, 5],
	[0, 5],
]
const OCTAHEDRON_NODE_COUNT := 6

## Cube: 8 vertices, 12 edges. Each node has exactly 3 neighbors.
const CUBE_EDGES := [
	[0, 1], [0, 3], [0, 4],
	[1, 2], [1, 5],
	[2, 3], [2, 6],
	[3, 7],
	[4, 5], [4, 7],
	[5, 6],
	[6, 7],
]
const CUBE_NODE_COUNT := 8

var nodes: Array[Dictionary] = []
var edges: Array[Array] = []
var adjacency: Dictionary = {}
var start_node: int = 0
var exit_node: int = -1
var floor_index: int = 1

func generate(rng: Variant, p_floor_index: int = 1) -> Dictionary:
	floor_index = p_floor_index
	var shape: String = _shape_for_floor(p_floor_index)
	var base_edges: Array = _base_edges(shape)
	var node_count: int = _base_node_count(shape)

	# Build nodes with gem affinities and types
	nodes = []
	for i in range(node_count):
		var affinity_draw: Dictionary = rng.draw_next("map.generation")
		var affinity_idx: int = int(affinity_draw.get("value", 0)) % GEM_AFFINITIES.size()
		nodes.append({
			"node_id": i,
			"gem_affinity": GEM_AFFINITIES[affinity_idx],
			"node_type": _assign_node_type(i, node_count, rng),
			"cleared": false,
			"is_start": i == 0,
			"is_exit": false,
		})

	# Mark exit node (last node)
	exit_node = node_count - 1
	nodes[exit_node]["node_type"] = "boss"
	nodes[exit_node]["is_exit"] = true
	nodes[exit_node]["gem_affinity"] = "neutral"

	# Start node is non-combat junction
	start_node = 0
	nodes[start_node]["node_type"] = "start"
	nodes[start_node]["gem_affinity"] = "neutral"

	# Copy base edges
	edges = []
	for edge in base_edges:
		edges.append([int(edge[0]), int(edge[1])])

	# Apply random modification
	_apply_random_modification(rng, node_count)

	# Assign gem gates to premium nodes
	_assign_gem_gates(rng)

	# Build adjacency map
	_rebuild_adjacency()

	return {
		"ok": true,
		"shape": shape,
		"node_count": nodes.size(),
		"edge_count": edges.size(),
		"start_node": start_node,
		"exit_node": exit_node,
	}

func get_node(node_id: int) -> Dictionary:
	if node_id < 0 or node_id >= nodes.size():
		return {}
	return nodes[node_id].duplicate(true)

func get_neighbors(node_id: int) -> Array:
	if not adjacency.has(node_id):
		return []
	var neighbor_ids: Array = adjacency[node_id]
	neighbor_ids.sort()
	return neighbor_ids

func get_legal_moves(node_id: int) -> Array:
	var neighbors: Array = get_neighbors(node_id)
	var legal: Array = []
	for n_id in neighbors:
		if n_id >= 0 and n_id < nodes.size():
			# Boss gate: only accessible if no uncompleted seal/mandatory nodes
			# (For MVP, always accessible)
			legal.append(n_id)
	return legal

func mark_cleared(node_id: int) -> void:
	if node_id >= 0 and node_id < nodes.size():
		nodes[node_id]["cleared"] = true

func snapshot() -> Dictionary:
	return {
		"nodes": nodes.duplicate(true),
		"edges": edges.duplicate(true),
		"start_node": start_node,
		"exit_node": exit_node,
		"floor_index": floor_index,
	}

func get_view_model() -> Dictionary:
	var node_views: Array = []
	for node in nodes:
		node_views.append(node.duplicate(true))
	var edge_views: Array = []
	for edge in edges:
		edge_views.append([int(edge[0]), int(edge[1])])
	return {
		"nodes": node_views,
		"edges": edge_views,
		"start_node": start_node,
		"exit_node": exit_node,
		"floor_index": floor_index,
	}

func _shape_for_floor(f_index: int) -> String:
	if f_index <= 1:
		return "tetrahedron"
	if f_index <= 3:
		return "octahedron"
	return "cube"

func _base_edges(shape: String) -> Array:
	match shape:
		"tetrahedron":
			return TETRAHEDRON_EDGES.duplicate(true)
		"octahedron":
			return OCTAHEDRON_EDGES.duplicate(true)
		"cube":
			return CUBE_EDGES.duplicate(true)
		_:
			return TETRAHEDRON_EDGES.duplicate(true)

func _base_node_count(shape: String) -> int:
	match shape:
		"tetrahedron":
			return TETRAHEDRON_NODE_COUNT
		"octahedron":
			return OCTAHEDRON_NODE_COUNT
		"cube":
			return CUBE_NODE_COUNT
		_:
			return TETRAHEDRON_NODE_COUNT

func _assign_node_type(node_idx: int, total_nodes: int, rng_ref: Variant) -> String:
	# First node = start, last = boss, rest = weighted draw
	if node_idx == 0:
		return "start"
	if node_idx == total_nodes - 1:
		return "boss"
	var type_draw: Dictionary = rng_ref.draw_next("map.generation")
	var combat_types := ["combat", "combat", "combat", "event", "rest"]
	var type_idx: int = int(type_draw.get("value", 0)) % combat_types.size()
	return combat_types[type_idx]

func _assign_gem_gates(rng_ref: Variant) -> void:
	## Assign gem gate costs to ~1-2 premium nodes per floor.
	## Gates are always optional (free path to boss must exist).
	var gatable: Array = []
	for node in nodes:
		var ntype: String = str(node.get("node_type", ""))
		if ntype == "combat" or ntype == "event":
			gatable.append(int(node.get("node_id", -1)))

	if gatable.is_empty():
		return

	# Gate 1-2 nodes
	var gate_draw: Dictionary = rng_ref.draw_next("map.generation")
	var gate_count: int = 1 + int(gate_draw.get("value", 0)) % 2
	gate_count = min(gate_count, gatable.size())

	for _i in range(gate_count):
		if gatable.is_empty():
			break
		var idx_draw: Dictionary = rng_ref.draw_next("map.generation")
		var idx: int = int(idx_draw.get("value", 0)) % gatable.size()
		var target_id: int = gatable[idx]
		gatable.remove_at(idx)

		# Determine gate cost: 1-2 gems of the node's affinity
		var target_node: Dictionary = nodes[target_id]
		var affinity: String = str(target_node.get("gem_affinity", "neutral"))
		if affinity == "neutral":
			affinity = "Ruby"  # Default gate gem
		var cost_draw: Dictionary = rng_ref.draw_next("map.generation")
		var cost: int = 1 + int(cost_draw.get("value", 0)) % 2

		nodes[target_id]["gem_gate"] = {
			"gem": affinity,
			"cost": cost,
		}

func _apply_random_modification(rng_ref: Variant, node_count: int) -> void:
	var mod_draw: Dictionary = rng_ref.draw_next("map.generation")
	var mod_type: int = int(mod_draw.get("value", 0)) % 3
	match mod_type:
		0:
			# Add a shortcut edge between two non-adjacent nodes
			_add_shortcut_edge(rng_ref, node_count)
		1:
			# Add a new node connected to two existing nodes
			_add_extra_node(rng_ref, node_count)
		2:
			# No modification this floor
			pass

func _add_shortcut_edge(rng_ref: Variant, node_count: int) -> void:
	if node_count < 4:
		return
	# Try up to 5 times to find a non-adjacent pair
	for _attempt in range(5):
		var draw_a: Dictionary = rng_ref.draw_next("map.generation")
		var draw_b: Dictionary = rng_ref.draw_next("map.generation")
		var a: int = int(draw_a.get("value", 0)) % node_count
		var b: int = int(draw_b.get("value", 0)) % node_count
		if a == b:
			continue
		if _has_edge(a, b):
			continue
		edges.append([min(a, b), max(a, b)])
		return

func _add_extra_node(rng_ref: Variant, node_count: int) -> void:
	var new_id: int = nodes.size()
	var affinity_draw: Dictionary = rng_ref.draw_next("map.generation")
	var affinity_idx: int = int(affinity_draw.get("value", 0)) % GEM_AFFINITIES.size()
	nodes.append({
		"node_id": new_id,
		"gem_affinity": GEM_AFFINITIES[affinity_idx],
		"node_type": "combat",
		"cleared": false,
		"is_start": false,
		"is_exit": false,
	})
	# Connect to two random existing non-start, non-exit nodes
	var candidates: Array = []
	for i in range(1, node_count - 1):
		candidates.append(i)
	if candidates.size() < 2:
		# Not enough candidates, connect to start and a random node
		edges.append([0, new_id])
		if node_count > 1:
			edges.append([1, new_id])
		return
	var draw_a: Dictionary = rng_ref.draw_next("map.generation")
	var idx_a: int = int(draw_a.get("value", 0)) % candidates.size()
	var target_a: int = candidates[idx_a]
	candidates.remove_at(idx_a)
	var draw_b: Dictionary = rng_ref.draw_next("map.generation")
	var idx_b: int = int(draw_b.get("value", 0)) % candidates.size()
	var target_b: int = candidates[idx_b]
	edges.append([min(target_a, new_id), max(target_a, new_id)])
	edges.append([min(target_b, new_id), max(target_b, new_id)])

func _has_edge(a: int, b: int) -> bool:
	var lo: int = min(a, b)
	var hi: int = max(a, b)
	for edge in edges:
		if int(edge[0]) == lo and int(edge[1]) == hi:
			return true
	return false

func _rebuild_adjacency() -> void:
	adjacency = {}
	for node in nodes:
		adjacency[int(node.get("node_id", 0))] = []
	for edge in edges:
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if not adjacency.has(a):
			adjacency[a] = []
		if not adjacency.has(b):
			adjacency[b] = []
		if not (adjacency[a] as Array).has(b):
			(adjacency[a] as Array).append(b)
		if not (adjacency[b] as Array).has(a):
			(adjacency[b] as Array).append(a)
