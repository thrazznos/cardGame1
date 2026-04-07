extends SceneTree

const FLOOR_GRAPH_SCRIPT := preload("res://src/core/map/floor_graph.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")

func _init() -> void:
	var rng = RSGC_SCRIPT.new()
	rng.bootstrap(55667788)

	var results: Array = []

	# Generate each polyhedra type
	for floor_idx in [1, 2, 5]:
		var graph = FLOOR_GRAPH_SCRIPT.new()
		var gen: Dictionary = graph.generate(rng, floor_idx)
		var node_count: int = graph.nodes.size()
		var edge_count: int = graph.edges.size()

		# Check connectivity: each node should have 2-3 neighbors
		var min_neighbors: int = 99
		var max_neighbors: int = 0
		var affinities: Dictionary = {}
		for node in graph.nodes:
			var n_id: int = int(node.get("node_id", 0))
			var neighbor_count: int = graph.get_neighbors(n_id).size()
			min_neighbors = min(min_neighbors, neighbor_count)
			max_neighbors = max(max_neighbors, neighbor_count)
			var aff: String = str(node.get("gem_affinity", ""))
			affinities[aff] = int(affinities.get(aff, 0)) + 1

		# Check start and exit
		var start: Dictionary = graph.get_node(graph.start_node)
		var exit: Dictionary = graph.get_node(graph.exit_node)

		results.append({
			"floor_index": floor_idx,
			"shape": str(gen.get("shape", "")),
			"node_count": node_count,
			"edge_count": edge_count,
			"min_neighbors": min_neighbors,
			"max_neighbors": max_neighbors,
			"affinities": affinities,
			"start_type": str(start.get("node_type", "")),
			"exit_type": str(exit.get("node_type", "")),
			"start_is_neutral": str(start.get("gem_affinity", "")) == "neutral",
			"exit_is_neutral": str(exit.get("gem_affinity", "")) == "neutral",
		})

	# Determinism check: same seed should produce same graph
	var rng2 = RSGC_SCRIPT.new()
	rng2.bootstrap(55667788)
	var graph_a = FLOOR_GRAPH_SCRIPT.new()
	graph_a.generate(rng2, 1)
	var rng3 = RSGC_SCRIPT.new()
	rng3.bootstrap(55667788)
	var graph_b = FLOOR_GRAPH_SCRIPT.new()
	graph_b.generate(rng3, 1)

	var deterministic: bool = JSON.stringify(graph_a.snapshot()) == JSON.stringify(graph_b.snapshot())

	var payload: Dictionary = {
		"results": results,
		"deterministic": deterministic,
	}

	print("FLOOR_GRAPH_PROBE=" + JSON.stringify(payload))
	quit()
