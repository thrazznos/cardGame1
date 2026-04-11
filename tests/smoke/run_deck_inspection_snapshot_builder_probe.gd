extends SceneTree

const BUILDER_SCRIPT := preload("res://src/ui/deck_inspection/deck_inspection_snapshot_builder.gd")

func _init() -> void:
	var builder = BUILDER_SCRIPT.new()
	var combat_input := {
		"draw": ["strike_01", "defend_01"],
		"hand": [
			{"instance_id": "runtime_scheme_alpha", "card_id": "scheme_flow"},
		],
		"discard": ["strike_plus"],
		"exhaust": ["defend_plus"],
	}
	var map_input := {
		"deck": ["strike_01", "defend_01", "scheme_flow", "strike_plus"],
	}

	var combat_full = builder.build_snapshot("combat_full", combat_input)
	var combat_discard = builder.build_snapshot("combat_discard", combat_input)
	var map_run_deck = builder.build_snapshot("map_run_deck", map_input)
	var combat_full_repeat = builder.build_snapshot("combat_full", combat_input)

	var payload := {
		"combat_full": combat_full,
		"combat_discard": combat_discard,
		"map_run_deck": map_run_deck,
		"combat_full_repeat": combat_full_repeat,
	}
	print("DECK_INSPECTION_SNAPSHOT_BUILDER_PROBE=" + JSON.stringify(payload))
	quit()
