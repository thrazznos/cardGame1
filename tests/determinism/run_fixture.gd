extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var report: Dictionary = node.call("run_fixture", "res://tests/determinism/fixtures/seed_smoke_001.json")
	print("DETERMINISM_REPORT=" + JSON.stringify(report))
	quit()
