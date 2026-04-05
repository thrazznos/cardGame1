extends SceneTree

const MISSING_ART_PATH := "res://tools/imagegen/output/does_not_exist/missing_texture.png"
const TARGET_PATH := "Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerPortrait"

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	hud.call("_apply_texture", TARGET_PATH, MISSING_ART_PATH, Vector2(96, 96), false)

	var portrait_node: Node = hud.get_node(TARGET_PATH)
	var payload: Dictionary = {
		"visible": false,
		"has_texture": false,
		"tooltip": "",
	}
	if portrait_node is TextureRect:
		var portrait: TextureRect = portrait_node
		payload["visible"] = portrait.visible
		payload["has_texture"] = portrait.texture != null
		payload["tooltip"] = portrait.tooltip_text

	print("ART_FALLBACK_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
