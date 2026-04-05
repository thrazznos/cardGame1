extends SceneTree

const DEFAULT_FIXTURE := "res://tests/determinism/fixtures/seed_smoke_001.json"

func _init() -> void:
	var fixture_path := DEFAULT_FIXTURE
	var args: Array = OS.get_cmdline_user_args()
	if args.size() >= 1:
		fixture_path = str(args[0])

	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var report: Dictionary = node.call("run_fixture", fixture_path)
	print("DETERMINISM_REPORT=" + JSON.stringify(report))
	quit()
