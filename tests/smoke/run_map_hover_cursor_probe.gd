extends SceneTree

const MAP_HUD_SCRIPT := preload("res://src/ui/map_hud/map_hud_controller.gd")

func _vm() -> Dictionary:
	return {
		"graph": {
			"nodes": [
				{"node_id": 0, "node_type": "start", "gem_affinity": "neutral", "cleared": true},
				{"node_id": 1, "node_type": "combat", "gem_affinity": "Ruby", "cleared": false},
			],
			"edges": [[0, 1]],
		},
		"current_node": 0,
		"start_node": 0,
		"exit_node": 1,
		"legal_moves": [1],
		"objective_text": "Clear the next room.",
	}

func _init() -> void:
	var hud: Control = MAP_HUD_SCRIPT.new()
	hud.size = Vector2(1280, 720)
	root.add_child(hud)
	await process_frame

	hud.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hud.set("_hovered_node_id", 1)
	hud.refresh(_vm(), ["Ruby"], 6)
	await process_frame

	var payload: Dictionary = {
		"refresh_hovered_node": int(hud.get("_hovered_node_id")),
		"refresh_cursor": int(hud.mouse_default_cursor_shape),
	}

	hud.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hud.set("_hovered_node_id", 1)
	hud.show_event("Room cleared")
	await process_frame
	payload["show_event_hovered_node"] = int(hud.get("_hovered_node_id"))
	payload["show_event_cursor"] = int(hud.mouse_default_cursor_shape)

	hud.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hud.set("_hovered_node_id", 1)
	hud.dismiss_event()
	await process_frame
	payload["dismiss_hovered_node"] = int(hud.get("_hovered_node_id"))
	payload["dismiss_cursor"] = int(hud.mouse_default_cursor_shape)

	print("MAP_HOVER_CURSOR_PROBE=" + JSON.stringify(payload))
	hud.queue_free()
	await process_frame
	quit()
