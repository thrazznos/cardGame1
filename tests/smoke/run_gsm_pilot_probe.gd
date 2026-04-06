extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var vm: Dictionary = node.call("get_view_model")
	var run_master_deck: Array = node.get("run_master_deck")
	var opening_hand: Array = vm.get("hand", [])
	var gsm_card_count: int = 0
	var opening_hand_gsm_count: int = 0
	var has_advanced_card: bool = false

	for card in run_master_deck:
		var card_id: String = str(card)
		if card_id.begins_with("gem_"):
			gsm_card_count += 1
		if card_id.begins_with("gem_offset_consume_"):
			has_advanced_card = true

	for card in opening_hand:
		if str(card).begins_with("gem_"):
			opening_hand_gsm_count += 1

	var first_button_text: String = ""
	var hand_button_node: Node = node.get_node_or_null("CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	if hand_button_node is Button:
		first_button_text = (hand_button_node as Button).text

	var payload: Dictionary = {
		"deck_size": run_master_deck.size(),
		"gsm_card_count": gsm_card_count,
		"has_focus_card": run_master_deck.has("gem_focus_a"),
		"has_advanced_card": has_advanced_card,
		"opening_hand": opening_hand,
		"opening_hand_gsm_count": opening_hand_gsm_count,
		"first_button_text": first_button_text,
	}
	print("GSM_PILOT_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
