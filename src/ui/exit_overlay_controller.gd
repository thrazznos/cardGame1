extends Control
class_name ExitOverlayController

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var exit_button := get_node_or_null("Center/Panel/VBox/ExitButton")
	if exit_button is Button and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)

func open_overlay() -> void:
	visible = true

func close_overlay() -> void:
	visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()
