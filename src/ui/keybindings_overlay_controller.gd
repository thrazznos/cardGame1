extends Control
class_name KeybindingsOverlayController

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var close_button := get_node_or_null("Center/Panel/VBox/CloseButton")
	if close_button is Button and not close_button.pressed.is_connected(close_overlay):
		close_button.pressed.connect(close_overlay)

func open_overlay() -> void:
	visible = true

func close_overlay() -> void:
	visible = false
