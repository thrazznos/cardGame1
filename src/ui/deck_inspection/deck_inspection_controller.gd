extends Control
class_name DeckInspectionController

var snapshot: Dictionary = {}
var active_filter: String = "all"
var selected_card: Dictionary = {}

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var close_button := get_node_or_null("Center/Panel/VBox/HeaderRow/CloseButton")
	if close_button is Button and not close_button.pressed.is_connected(close_overlay):
		close_button.pressed.connect(close_overlay)

func open_with_snapshot(p_snapshot: Dictionary) -> void:
	snapshot = p_snapshot.duplicate(true)
	active_filter = str(snapshot.get("active_filter", "all"))
	visible = true
	_render_header()
	_render_filters()
	_render_cards()

func close_overlay() -> void:
	visible = false
	selected_card = {}
	_clear_children(_filter_row())
	_clear_children(_card_grid())
	_set_detail({})

func set_active_filter(filter_id: String) -> void:
	active_filter = str(filter_id).strip_edges()
	if active_filter == "":
		active_filter = "all"
	_render_filters()
	_render_cards()

func _render_header() -> void:
	_title_label().text = str(snapshot.get("title", "Deck Inspection"))
	_context_badge().text = str(snapshot.get("context", ""))

func _render_filters() -> void:
	var row := _filter_row()
	_clear_children(row)
	for section_variant in snapshot.get("sections", []):
		if not (section_variant is Dictionary):
			continue
		var section: Dictionary = section_variant
		var button := Button.new()
		button.text = "%s (%d)" % [str(section.get("label", "Section")), int(section.get("count", 0))]
		button.toggle_mode = true
		var section_id: String = str(section.get("id", ""))
		button.button_pressed = section_id == active_filter
		button.pressed.connect(_on_filter_pressed.bind(section_id))
		row.add_child(button)

func _render_cards() -> void:
	var cards: Array = _visible_cards()
	var grid := _card_grid()
	_clear_children(grid)
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 88)
		button.text = "%s %s\n%s" % [
			str(card.get("role_label", "")),
			str(card.get("display_name", "Unknown")),
			str(card.get("zone_label", "")),
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_card_pressed.bind(card.duplicate(true)))
		grid.add_child(button)
	if cards.is_empty():
		selected_card = {}
		_count_label().text = "0 cards"
		_set_detail({})
		return
	if selected_card.is_empty() or not _cards_include_instance(cards, str(selected_card.get("card_instance_id", ""))):
		selected_card = (cards[0] as Dictionary).duplicate(true)
	_count_label().text = _count_text(cards.size())
	_set_detail(selected_card)

func _visible_cards() -> Array:
	var cards: Array = []
	for card_variant in snapshot.get("cards", []):
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		if active_filter != "all" and str(card.get("zone", "")) != active_filter:
			continue
		cards.append(card.duplicate(true))
	return cards

func _set_detail(card: Dictionary) -> void:
	var title := _detail_title()
	var meta := _detail_meta()
	var rules := _detail_rules()
	if card.is_empty():
		title.text = ""
		meta.text = ""
		rules.text = ""
		return
	title.text = str(card.get("display_name", "Unknown"))
	meta.text = "%s  Cost %d  %s" % [
		str(card.get("role_label", "")),
		int(card.get("cost", 0)),
		str(card.get("zone_label", "")),
	]
	rules.text = str(card.get("rules_text", ""))

func _on_filter_pressed(filter_id: String) -> void:
	set_active_filter(filter_id)

func _on_card_pressed(card: Dictionary) -> void:
	selected_card = card.duplicate(true)
	_set_detail(selected_card)

func _cards_include_instance(cards: Array, instance_id: String) -> bool:
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		if str((card_variant as Dictionary).get("card_instance_id", "")) == instance_id:
			return true
	return false

func _count_text(count: int) -> String:
	return "%d card" % count if count == 1 else "%d cards" % count

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _title_label() -> Label:
	return get_node("Center/Panel/VBox/HeaderRow/Title") as Label

func _context_badge() -> Label:
	return get_node("Center/Panel/VBox/HeaderRow/ContextBadge") as Label

func _count_label() -> Label:
	return get_node("Center/Panel/VBox/HeaderRow/CountLabel") as Label

func _filter_row() -> HBoxContainer:
	return get_node("Center/Panel/VBox/FilterRow") as HBoxContainer

func _card_grid() -> GridContainer:
	return get_node("Center/Panel/VBox/BodyRow/CardScroll/CardGrid") as GridContainer

func _detail_title() -> Label:
	return get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailTitle") as Label

func _detail_meta() -> Label:
	return get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailMeta") as Label

func _detail_rules() -> Label:
	return get_node("Center/Panel/VBox/BodyRow/DetailPanel/DetailVBox/DetailRules") as Label
