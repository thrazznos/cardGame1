extends SceneTree

const OVERLAY_SCENE := preload("res://scenes/ui/deck_inspection_overlay.tscn")

func _button_texts(container: Node) -> Array:
	var texts: Array = []
	for child in container.get_children():
		if child is Button:
			texts.append((child as Button).text)
	return texts

func _init() -> void:
	var overlay: Control = OVERLAY_SCENE.instantiate()
	root.add_child(overlay)
	await process_frame

	var controller = overlay
	var snapshot := {
		"context": "combat",
		"title": "Combat Deck",
		"read_only": true,
		"total_count": 3,
		"active_filter": "all",
		"sections": [
			{"id": "draw", "label": "Draw", "count": 1},
			{"id": "hand", "label": "Hand", "count": 1},
			{"id": "discard", "label": "Discard", "count": 1},
		],
		"cards": [
			{
				"card_id": "strike",
				"card_instance_id": "strike_01",
				"display_name": "Strike",
				"cost": 1,
				"role_label": "[ATK]",
				"rules_text": "Attack • 6 dmg • Cost 1",
				"zone": "draw",
				"zone_label": "Draw",
				"art_path": "",
				"sort_key": [0, 0, "strike", "strike_01"],
				"flags": {},
			},
			{
				"card_id": "scheme_flow",
				"card_instance_id": "runtime_scheme_alpha",
				"display_name": "Scheme",
				"cost": 1,
				"role_label": "[UTL]",
				"rules_text": "Utility • Draw 1 • Cost 1",
				"zone": "hand",
				"zone_label": "Hand",
				"art_path": "",
				"sort_key": [1, 0, "scheme_flow", "runtime_scheme_alpha"],
				"flags": {},
			},
			{
				"card_id": "strike_plus",
				"card_instance_id": "strike_plus",
				"display_name": "Strike+",
				"cost": 1,
				"role_label": "[ATK]",
				"rules_text": "Attack • 9 dmg • Cost 1",
				"zone": "discard",
				"zone_label": "Discard",
				"art_path": "",
				"sort_key": [2, 0, "strike_plus", "strike_plus"],
				"flags": {},
			},
		],
	}

	var initially_visible: bool = overlay.visible
	controller.open_with_snapshot(snapshot)
	await process_frame

	var title_label: Label = overlay.get_node("Center/Panel/VBox/HeaderRow/Title")
	var count_label: Label = overlay.get_node("Center/Panel/VBox/HeaderRow/CountLabel")
	var filter_row: HBoxContainer = overlay.get_node("Center/Panel/VBox/FilterRow")
	var card_grid: GridContainer = overlay.get_node("Center/Panel/VBox/BodyRow/CardScroll/CardGrid")
	var detail_title: Label = overlay.get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailTitle")
	var detail_meta: Label = overlay.get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailMeta")
	var detail_rules: Label = overlay.get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailRules")

	var after_open_visible: bool = overlay.visible
	var filter_texts: Array = _button_texts(filter_row)
	var visible_card_count_after_open: int = card_grid.get_child_count()
	var detail_title_after_open: String = detail_title.text
	var detail_meta_after_open: String = detail_meta.text
	var detail_rules_after_open: String = detail_rules.text
	var count_after_open: String = count_label.text

	controller.set_active_filter("discard")
	await process_frame
	var visible_card_count_after_discard: int = card_grid.get_child_count()
	var detail_title_after_discard: String = detail_title.text
	var count_after_discard: String = count_label.text

	controller.close_overlay()
	await process_frame
	var after_close_visible: bool = overlay.visible

	var payload := {
		"initially_visible": initially_visible,
		"after_open_visible": after_open_visible,
		"title_text": title_label.text,
		"count_after_open": count_after_open,
		"filter_texts": filter_texts,
		"visible_card_count_after_open": visible_card_count_after_open,
		"detail_title_after_open": detail_title_after_open,
		"detail_meta_after_open": detail_meta_after_open,
		"detail_rules_after_open": detail_rules_after_open,
		"visible_card_count_after_discard": visible_card_count_after_discard,
		"detail_title_after_discard": detail_title_after_discard,
		"count_after_discard": count_after_discard,
		"after_close_visible": after_close_visible,
	}
	print("DECK_INSPECTION_OVERLAY_PROBE=" + JSON.stringify(payload))
	quit()
