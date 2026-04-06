extends SceneTree

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const CARD_INSTANCE_SCRIPT := preload("res://src/core/card/card_instance.gd")

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	var catalog = CARD_CATALOG_SCRIPT.new()
	var helper = CARD_INSTANCE_SCRIPT.new()
	var normalized: Dictionary = helper.from_value("strike_01", catalog)

	node.call("reset_battle", 1337)
	var dls: Variant = node.get("dls")
	var hand_internal_uses_dictionaries: bool = dls.hand.size() > 0 and dls.hand[0] is Dictionary
	var draw_internal_uses_dictionaries: bool = dls.draw_pile.size() > 0 and dls.draw_pile[0] is Dictionary

	dls.hand = [normalized]
	node.call("refresh_hud")
	var vm: Dictionary = node.call("get_view_model")

	var payload: Dictionary = {
		"normalized_instance_id": str(normalized.get("instance_id", "")),
		"normalized_card_id": str(normalized.get("card_id", "")),
		"hand_internal_uses_dictionaries": hand_internal_uses_dictionaries,
		"draw_internal_uses_dictionaries": draw_internal_uses_dictionaries,
		"view_hand_first": str(vm.get("hand", [""])[0]),
	}
	print("CARD_INSTANCE_PROBE=" + JSON.stringify(payload))

	node.queue_free()
	await process_frame
	quit()
