extends Control
class_name CombatHudController

const PANEL_BG := Color("#171b24")
const PANEL_BG_SOFT := Color("#202838")
const PANEL_BORDER := Color("#4b5876")
const TEXT_PRIMARY := Color("#f3f6fb")
const TEXT_MUTED := Color("#d0d8e4")
const TEXT_ACCENT := Color("#7ec6ff")
const TEXT_GOOD := Color("#8be28b")
const TEXT_WARN := Color("#ffd36a")
const TEXT_BAD := Color("#ff8b8b")
const BAR_BG := Color("#0f131b")
const HEALTH_FILL := Color("#5bd36d")
const ENEMY_FILL := Color("#ff7a7a")
const ENERGY_FILL := Color("#72b9ff")
const STRIKE_BG := Color("#4a2327")
const STRIKE_BORDER := Color("#ff8b8b")
const DEFEND_BG := Color("#1f3550")
const DEFEND_BORDER := Color("#7ec6ff")
const OTHER_BG := Color("#4d3b1f")
const OTHER_BORDER := Color("#ffd36a")
const ALT_STRIKE_BG := Color("#2f2146")
const ALT_STRIKE_BORDER := Color("#d6a4ff")
const ALT_DEFEND_BG := Color("#15384a")
const ALT_DEFEND_BORDER := Color("#8de2ff")
const ALT_OTHER_BG := Color("#27412a")
const ALT_OTHER_BORDER := Color("#9af2a9")
const PLAYER_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/player_cat_steward_bust_128.png"
const ENEMY_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/enemy_badger_warden_068.png"
const CREST_PATH := "res://src/ui/combat_hud/assets/banner_crest_steward_064.png"
const REWARD_SEAL_PATH := "res://src/ui/combat_hud/assets/reward_wax_seal_centered_112.png"
const MISSING_ART_TINT := Color(0.78, 0.82, 0.90, 0.55)

var runner: Variant
var previous_vm: Dictionary = {}
var fx_tweens: Dictionary = {}
var next_encounter_transition_pending: bool = false
var card_style_variant: String = "classic"

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	_apply_readability_theme()
	_apply_generated_art()
	if has_node("Margin/VBox/Buttons/Pass"):
		$Margin/VBox/Buttons/Pass.pressed.connect(_on_pass)
	if has_node("Margin/VBox/Buttons/Restart"):
		$Margin/VBox/Buttons/Restart.pressed.connect(_on_restart)
	_connect_hand_buttons()
	_connect_reward_buttons()

func _connect_hand_buttons() -> void:
	if not has_node("Margin/VBox/HandPanel/HandVBox/HandButtons"):
		return
	for child in $Margin/VBox/HandPanel/HandVBox/HandButtons.get_children():
		if child is Button:
			child.pressed.connect(_on_hand_card_pressed.bind(child))

func _connect_reward_buttons() -> void:
	if not has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices"):
		return
	for child in $RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices.get_children():
		if child is Button:
			child.pressed.connect(_on_reward_pressed.bind(child))
	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue"):
		$RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue.pressed.connect(_on_reward_continue)

func _apply_generated_art() -> void:
	_apply_texture("Margin/VBox/Banner/BannerRow/BannerCrest", CREST_PATH, Vector2(40, 40), true)
	_apply_texture("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerPortrait", PLAYER_PORTRAIT_PATH, Vector2(96, 96), false)
	_apply_texture("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyPortrait", ENEMY_PORTRAIT_PATH, Vector2(88, 88), true)
	_apply_texture("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal", REWARD_SEAL_PATH, Vector2(96, 96), false)

func _apply_texture(path: String, resource_path: String, size: Vector2, pixel_art: bool = false) -> void:
	var node = get_node_or_null(path)
	if not (node is TextureRect):
		return
	var texture := _load_texture(resource_path)
	node.custom_minimum_size = size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR
	if texture == null:
		node.texture = null
		node.visible = true
		node.modulate = MISSING_ART_TINT
		node.tooltip_text = "Missing art asset: %s" % resource_path
		return
	node.texture = texture
	node.visible = true
	node.modulate = Color(1, 1, 1, 1)
	node.tooltip_text = ""

func _load_texture(resource_path: String) -> Texture2D:
	if ResourceLoader.exists(resource_path):
		var imported := load(resource_path)
		if imported is Texture2D:
			return imported
	if not FileAccess.file_exists(resource_path):
		return null
	var image := Image.load_from_file(resource_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _apply_readability_theme() -> void:
	for path in [
		"Margin/VBox/Banner",
		"Margin/VBox/StatsRow/PlayerPanel",
		"Margin/VBox/StatsRow/EnemyPanel",
		"Margin/VBox/StatsRow/ZonesPanel",
		"Margin/VBox/QueuePanel",
		"Margin/VBox/ReasonPanel",
		"Margin/VBox/HandPanel",
		"Margin/VBox/EventPanel",
		"RewardOverlay/Center/RewardPanel",
		"TransitionToastLayer/ToastStrip/ToastPanel",
	]:
		var node = get_node_or_null(path)
		if node is PanelContainer:
			_apply_panel_style(node)

	_apply_label_style("Margin/VBox/Banner/BannerRow/Title", 36, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/Banner/BannerRow/Status", 26, TEXT_ACCENT)
	_apply_label_style("Margin/VBox/Banner/BannerRow/ResolveLock", 24, TEXT_GOOD)
	_apply_label_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerStats", 26, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyStats", 26, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/StatsRow/ZonesPanel/Zones", 22, TEXT_MUTED)
	_apply_label_style("Margin/VBox/QueuePanel/Queue", 22, TEXT_MUTED)
	_apply_label_style("Margin/VBox/ReasonPanel/Hint", 22, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/HandPanel/HandVBox/Hand", 26, TEXT_ACCENT)
	_apply_label_style("Margin/VBox/EventPanel/EventLog", 22, TEXT_MUTED)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardTitle", 30, TEXT_PRIMARY)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSubtitle", 22, TEXT_MUTED)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardState", 22, TEXT_PRIMARY)
	_apply_label_style("TransitionToastLayer/ToastStrip/ToastPanel/ToastLabel", 28, TEXT_ACCENT)

	_apply_progress_bar_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerHpBar", HEALTH_FILL)
	_apply_progress_bar_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/EnergyBar", ENERGY_FILL)
	_apply_progress_bar_style("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyHpBar", ENEMY_FILL)

	if has_node("Margin/VBox/Buttons/Pass"):
		_apply_neutral_button_style($Margin/VBox/Buttons/Pass, 22, 60)
	if has_node("Margin/VBox/Buttons/Restart"):
		_apply_neutral_button_style($Margin/VBox/Buttons/Restart, 22, 60)
	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue"):
		_apply_neutral_button_style($RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue, 22, 60)

func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

func _build_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

func _apply_neutral_button_style(button: Button, font_size: int, min_height: int) -> void:
	button.add_theme_stylebox_override("normal", _build_button_style(PANEL_BG_SOFT, PANEL_BORDER))
	button.add_theme_stylebox_override("hover", _build_button_style(PANEL_BG_SOFT, TEXT_ACCENT))
	button.add_theme_stylebox_override("pressed", _build_button_style(PANEL_BG_SOFT, TEXT_GOOD))
	button.add_theme_stylebox_override("disabled", _build_button_style(Color("#171b24"), Color("#2d3444")))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, min_height)

func _apply_card_button_style(button: Button, card_id: String, disabled: bool) -> void:
	var palette: Dictionary = _card_palette(card_id)
	var bg_color: Color = palette.get("bg", OTHER_BG)
	var border_color: Color = palette.get("border", OTHER_BORDER)

	button.add_theme_stylebox_override("normal", _build_button_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", _build_button_style(bg_color, TEXT_PRIMARY))
	button.add_theme_stylebox_override("pressed", _build_button_style(bg_color, TEXT_GOOD))
	button.add_theme_stylebox_override("disabled", _build_button_style(Color("#171b24"), Color("#2d3444")))
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 104)
	button.disabled = disabled

func _card_palette(card_id: String) -> Dictionary:
	if card_style_variant == "alt":
		if card_id.begins_with("strike"):
			return {"bg": ALT_STRIKE_BG, "border": ALT_STRIKE_BORDER}
		if card_id.begins_with("defend"):
			return {"bg": ALT_DEFEND_BG, "border": ALT_DEFEND_BORDER}
		return {"bg": ALT_OTHER_BG, "border": ALT_OTHER_BORDER}

	if card_id.begins_with("strike"):
		return {"bg": STRIKE_BG, "border": STRIKE_BORDER}
	if card_id.begins_with("defend"):
		return {"bg": DEFEND_BG, "border": DEFEND_BORDER}
	return {"bg": OTHER_BG, "border": OTHER_BORDER}

func _apply_progress_bar_style(path: String, fill_color: Color) -> void:
	var node = get_node_or_null(path)
	if not (node is ProgressBar):
		return
	var background := StyleBoxFlat.new()
	background.bg_color = BAR_BG
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_right = 6
	background.corner_radius_bottom_left = 6
	background.content_margin_left = 2
	background.content_margin_top = 2
	background.content_margin_right = 2
	background.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 5
	fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_right = 5
	fill.corner_radius_bottom_left = 5
	node.add_theme_stylebox_override("background", background)
	node.add_theme_stylebox_override("fill", fill)
	node.show_percentage = false

func _apply_label_style(path: String, font_size: int, color: Color) -> void:
	var node = get_node_or_null(path)
	if node is Label:
		node.add_theme_font_size_override("font_size", font_size)
		node.add_theme_color_override("font_color", color)

func refresh(vm: Dictionary) -> void:
	var previous: Dictionary = previous_vm
	_set_label("Margin/VBox/Banner/BannerRow/Title", "Dungeon Steward")
	_set_label("Margin/VBox/Banner/BannerRow/Status", _status_text(vm))
	_refresh_resolve_lock(vm)
	_set_label("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerStats", _player_stats_text(vm))
	_set_label("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyStats", _enemy_stats_text(vm))
	_set_label("Margin/VBox/StatsRow/ZonesPanel/Zones", _zones_text(vm))
	_set_label("Margin/VBox/QueuePanel/Queue", _queue_text(vm))
	_set_label("Margin/VBox/ReasonPanel/Hint", _hint_text(vm))
	_set_label("Margin/VBox/HandPanel/HandVBox/Hand", _hand_text(vm))
	_set_label("Margin/VBox/EventPanel/EventLog", _event_log_text(vm))
	_refresh_bars(vm)
	_refresh_pass_button(vm)
	_refresh_hand_buttons(vm)
	_refresh_reward_overlay(vm)
	_play_ui_juice(vm, previous)
	previous_vm = vm.duplicate(true)

func _set_label(path: String, text_value: String) -> void:
	var node = get_node_or_null(path)
	if node is Label:
		node.text = text_value

func _restart_fx_tween(key: String) -> Tween:
	var existing: Variant = fx_tweens.get(key, null)
	if existing is Tween:
		var existing_tween: Tween = existing
		if is_instance_valid(existing_tween):
			existing_tween.kill()
	var tween: Tween = create_tween()
	fx_tweens[key] = tween
	return tween

func _flash_canvas_item(node: Node, flash_color: Color, key: String, in_duration: float = 0.06, out_duration: float = 0.16) -> void:
	if not (node is CanvasItem):
		return
	var item: CanvasItem = node
	item.modulate = Color(1, 1, 1, 1)
	var tween: Tween = _restart_fx_tween(key)
	tween.tween_property(item, "modulate", flash_color, in_duration)
	tween.tween_property(item, "modulate", Color(1, 1, 1, 1), out_duration)

func _pulse_control(node: Node, scale_peak: float, key: String, in_duration: float = 0.05, out_duration: float = 0.08) -> void:
	if not (node is Control):
		return
	var control: Control = node
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	var tween: Tween = _restart_fx_tween(key)
	tween.tween_property(control, "scale", Vector2(scale_peak, scale_peak), in_duration)
	tween.tween_property(control, "scale", Vector2.ONE, out_duration)

func _play_ui_juice(vm: Dictionary, previous: Dictionary) -> void:
	if previous.is_empty():
		return

	var previous_player_hp: int = int(previous.get("player_hp", vm.get("player_hp", 0)))
	var previous_enemy_hp: int = int(previous.get("enemy_hp", vm.get("enemy_hp", 0)))
	var current_player_hp: int = int(vm.get("player_hp", 0))
	var current_enemy_hp: int = int(vm.get("enemy_hp", 0))
	if current_player_hp < previous_player_hp:
		_play_damage_flash(
			"Margin/VBox/StatsRow/PlayerPanel",
			"Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerPortrait",
			"Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerHpBar"
		)
	if current_enemy_hp < previous_enemy_hp:
		_play_damage_flash(
			"Margin/VBox/StatsRow/EnemyPanel",
			"Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyPortrait",
			"Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyHpBar"
		)

	var previous_reward_state: String = str(previous.get("reward_state", "none"))
	var reward_state: String = str(vm.get("reward_state", "none"))
	if previous_reward_state != reward_state:
		if reward_state == "presented":
			_play_reward_reveal()
		elif reward_state == "applied":
			_play_reward_claim(str(vm.get("reward_selected_card_id", "")))

	var previous_encounter_index: int = int(previous.get("encounter_index", 1))
	var encounter_index: int = int(vm.get("encounter_index", 1))
	if encounter_index != previous_encounter_index:
		_play_encounter_toast(
			encounter_index,
			str(vm.get("encounter_title", "Encounter %d" % encounter_index)),
			str(vm.get("encounter_intent_style", "")),
			str(vm.get("encounter_intro_flavor", ""))
		)

func _play_damage_flash(panel_path: String, portrait_path: String, bar_path: String) -> void:
	_flash_canvas_item(get_node_or_null(panel_path), Color(1.0, 0.78, 0.78, 1.0), "damage_panel:%s" % panel_path)
	_flash_canvas_item(get_node_or_null(portrait_path), Color(1.0, 0.70, 0.70, 1.0), "damage_portrait:%s" % portrait_path)
	_flash_canvas_item(get_node_or_null(bar_path), Color(1.0, 0.82, 0.82, 1.0), "damage_bar:%s" % bar_path, 0.05, 0.18)

func _play_reward_reveal() -> void:
	var overlay_node: Node = get_node_or_null("RewardOverlay")
	if overlay_node is Control:
		var overlay: Control = overlay_node
		overlay.visible = true

	var scrim_node: Node = get_node_or_null("RewardOverlay/Scrim")
	if scrim_node is CanvasItem:
		var scrim: CanvasItem = scrim_node
		scrim.modulate = Color(1, 1, 1, 0)
		var scrim_tween: Tween = _restart_fx_tween("reward_reveal_scrim")
		scrim_tween.tween_property(scrim, "modulate", Color(1, 1, 1, 1), 0.12)

	var panel_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel")
	if panel_node is CanvasItem:
		var panel: CanvasItem = panel_node
		panel.modulate = Color(1, 1, 1, 0)
		var panel_tween: Tween = _restart_fx_tween("reward_reveal_panel")
		panel_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.18)

	var seal_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal")
	if seal_node is CanvasItem:
		var seal: CanvasItem = seal_node
		seal.modulate = Color(1, 1, 1, 0)
		var seal_tween: Tween = _restart_fx_tween("reward_reveal_seal")
		seal_tween.tween_interval(0.05)
		seal_tween.tween_property(seal, "modulate", Color(1, 1, 1, 1), 0.18)
	if seal_node is Control:
		var seal_control: Control = seal_node
		seal_control.pivot_offset = seal_control.size * 0.5
		seal_control.scale = Vector2(0.9, 0.9)
		var seal_scale_tween: Tween = _restart_fx_tween("reward_reveal_seal_scale")
		seal_scale_tween.tween_interval(0.05)
		seal_scale_tween.tween_property(seal_control, "scale", Vector2.ONE, 0.18)

	var buttons: Array = []
	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices"):
		buttons = $RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices.get_children()
	for i in range(buttons.size()):
		var button_node: Node = buttons[i]
		if not (button_node is Button):
			continue
		var button: Button = button_node
		if not button.visible:
			continue
		button.modulate = Color(1, 1, 1, 0)
		var button_tween: Tween = _restart_fx_tween("reward_reveal_button_%d" % i)
		button_tween.tween_interval(0.08 + float(i) * 0.04)
		button_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.14)

func _play_reward_claim(selected_card_id: String) -> void:
	var state_label_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardState")
	_flash_canvas_item(state_label_node, Color(0.78, 1.0, 0.78, 1.0), "reward_claim_state")

	var seal_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal")
	_flash_canvas_item(seal_node, Color(1.0, 0.94, 0.80, 1.0), "reward_claim_seal")
	_pulse_control(seal_node, 1.06, "reward_claim_seal_pulse", 0.06, 0.12)

	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices"):
		for child in $RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices.get_children():
			if not (child is Button):
				continue
			var reward_button: Button = child
			if str(reward_button.get_meta("reward_card_id", "")) != selected_card_id:
				continue
			_flash_canvas_item(reward_button, Color(0.86, 1.0, 0.86, 1.0), "reward_claim_button_flash")
			_pulse_control(reward_button, 1.03, "reward_claim_button_pulse", 0.06, 0.12)

	var continue_button_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue")
	if continue_button_node is Button:
		var continue_button: Button = continue_button_node
		continue_button.modulate = Color(1, 1, 1, 0)
		var continue_tween: Tween = _restart_fx_tween("reward_continue_reveal")
		continue_tween.tween_interval(0.08)
		continue_tween.tween_property(continue_button, "modulate", Color(1, 1, 1, 1), 0.16)

func _play_encounter_toast(encounter_index: int, encounter_title: String, encounter_intent_style: String, encounter_intro_flavor: String) -> void:
	var layer_node: Node = get_node_or_null("TransitionToastLayer")
	if layer_node is Control:
		var layer: Control = layer_node
		layer.visible = true

	var label_node: Node = get_node_or_null("TransitionToastLayer/ToastStrip/ToastPanel/ToastLabel")
	if label_node is Label:
		var label: Label = label_node
		var title: String = encounter_title if encounter_title != "" else "Encounter %d Begins" % encounter_index
		var lines: Array = ["%s Begins" % title]
		if encounter_intent_style != "":
			lines.append(encounter_intent_style)
		if encounter_intro_flavor != "":
			lines.append(encounter_intro_flavor)
		lines.append("Press Enter to continue")
		label.text = _join_lines(lines)

	var panel_node: Node = get_node_or_null("TransitionToastLayer/ToastStrip/ToastPanel")
	if panel_node is CanvasItem:
		var panel: CanvasItem = panel_node
		panel.modulate = Color(1, 1, 1, 0)
		var toast_tween: Tween = _restart_fx_tween("encounter_toast")
		toast_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.12)
	_pulse_control(panel_node, 1.02, "encounter_toast_pulse", 0.08, 0.12)

func _hide_transition_toast() -> void:
	var layer_node: Node = get_node_or_null("TransitionToastLayer")
	if layer_node is Control:
		var layer: Control = layer_node
		layer.visible = false
	var panel_node: Node = get_node_or_null("TransitionToastLayer/ToastStrip/ToastPanel")
	if panel_node is CanvasItem:
		var panel: CanvasItem = panel_node
		panel.modulate = Color(1, 1, 1, 1)
	if panel_node is Control:
		var panel_control: Control = panel_node
		panel_control.scale = Vector2.ONE

func _is_transition_toast_visible() -> bool:
	var layer_node: Node = get_node_or_null("TransitionToastLayer")
	if layer_node is Control:
		return (layer_node as Control).visible
	return false

func _play_next_encounter_transition() -> void:
	var scrim_node: Node = get_node_or_null("RewardOverlay/Scrim")
	if scrim_node is CanvasItem:
		var scrim: CanvasItem = scrim_node
		var scrim_tween: Tween = _restart_fx_tween("next_encounter_scrim")
		scrim_tween.tween_property(scrim, "modulate", Color(1, 1, 1, 0), 0.12)

	var panel_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel")
	if panel_node is CanvasItem:
		var panel: CanvasItem = panel_node
		var panel_tween: Tween = _restart_fx_tween("next_encounter_panel")
		panel_tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.12)

	var commit_tween: Tween = _restart_fx_tween("next_encounter_commit")
	commit_tween.tween_interval(0.12)
	commit_tween.tween_callback(Callable(self, "_commit_next_encounter"))

func _commit_next_encounter() -> void:
	next_encounter_transition_pending = false
	if runner == null:
		return
	runner.start_next_encounter()

func _refresh_bars(vm: Dictionary) -> void:
	var player_hp_bar = get_node_or_null("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerHpBar")
	if player_hp_bar is ProgressBar:
		player_hp_bar.max_value = float(vm.get("player_max_hp", 1))
		player_hp_bar.value = float(vm.get("player_hp", 0))
	var energy_bar = get_node_or_null("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/EnergyBar")
	if energy_bar is ProgressBar:
		energy_bar.max_value = float(vm.get("turn_energy_max", 1))
		energy_bar.value = float(vm.get("energy", 0))
	var enemy_hp_bar = get_node_or_null("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyHpBar")
	if enemy_hp_bar is ProgressBar:
		enemy_hp_bar.max_value = float(vm.get("enemy_max_hp", 1))
		enemy_hp_bar.value = float(vm.get("enemy_hp", 0))

func _refresh_resolve_lock(vm: Dictionary) -> void:
	var node = get_node_or_null("Margin/VBox/Banner/BannerRow/ResolveLock")
	if not (node is Label):
		return
	if bool(vm.get("resolve_lock", false)):
		node.text = "LOCKED: Resolving"
		node.add_theme_color_override("font_color", TEXT_WARN)
	elif str(vm.get("combat_result", "in_progress")) == "player_win":
		node.text = "VICTORY"
		node.add_theme_color_override("font_color", TEXT_GOOD)
	elif str(vm.get("combat_result", "in_progress")) == "player_lose":
		node.text = "DEFEAT"
		node.add_theme_color_override("font_color", TEXT_BAD)
	else:
		node.text = "INPUT READY"
		node.add_theme_color_override("font_color", TEXT_GOOD)

func _status_text(vm: Dictionary) -> String:
	var encounter_title: String = str(vm.get("encounter_title", "Encounter %d" % int(vm.get("encounter_index", 1))))
	return "%s • Turn %d • %s • %s" % [
		encounter_title,
		int(vm.get("turn", 0)),
		str(vm.get("ui_phase_text", "Player Turn")),
		_combat_result_text(str(vm.get("combat_result", "in_progress"))),
	]

func _player_stats_text(vm: Dictionary) -> String:
	return "PLAYER  HP %d/%d  •  Block %d  •  Energy %d/%d" % [
		int(vm.get("player_hp", 0)),
		int(vm.get("player_max_hp", 0)),
		int(vm.get("player_block", 0)),
		int(vm.get("energy", 0)),
		int(vm.get("turn_energy_max", 0)),
	]

func _enemy_stats_text(vm: Dictionary) -> String:
	var intent_style: String = str(vm.get("encounter_intent_style", "Steady pressure"))
	return "ENEMY  HP %d/%d  •  Block %d  •  Intent %d dmg\nPattern: %s" % [
		int(vm.get("enemy_hp", 0)),
		int(vm.get("enemy_max_hp", 0)),
		int(vm.get("enemy_block", 0)),
		int(vm.get("enemy_intent_damage", 0)),
		intent_style,
	]

func _zones_text(vm: Dictionary) -> String:
	var zones: Dictionary = vm.get("zones", {})
	var lines: Array = [
		"ZONES",
		"Draw %d" % int(zones.get("draw", 0)),
		"Discard %d" % int(zones.get("discard", 0)),
		"Exhaust %d" % int(zones.get("exhaust", 0)),
	]
	if int(zones.get("limbo", 0)) > 0:
		lines.append("Limbo %d" % int(zones.get("limbo", 0)))
	return _join_lines(lines)

func _queue_text(vm: Dictionary) -> String:
	var queue_preview: Array = vm.get("queue_preview", [])
	if not queue_preview.is_empty():
		var item: Dictionary = queue_preview[0]
		return "NEXT RESOLVE\n%s\nComparator: timing %d -> speed %d -> seq %d" % [
			str(item.get("source_instance_id", "-")),
			int(item.get("timing_window_priority", 0)),
			int(item.get("speed_class_priority", 0)),
			int(item.get("enqueue_sequence_id", 0)),
		]

	var last_item: Dictionary = vm.get("last_resolved_queue_item", {})
	if not last_item.is_empty():
		return "LAST RESOLVE\n%s\nComparator: timing %d -> speed %d -> seq %d" % [
			str(last_item.get("source_instance_id", "-")),
			int(last_item.get("timing_window_priority", 0)),
			int(last_item.get("speed_class_priority", 0)),
			int(last_item.get("enqueue_sequence_id", 0)),
		]

	return "LAST RESOLVE\nNo queued effects yet."

func _hint_text(vm: Dictionary) -> String:
	var reward_state: String = str(vm.get("reward_state", "none"))
	if reward_state == "presented":
		return "Victory. Choose 1 of 3 cards to add to your deck."
	if reward_state == "applied" or reward_state == "closed":
		return str(vm.get("reward_summary_text", "Reward claimed."))

	var last_reject_reason: String = str(vm.get("last_reject_reason", ""))
	if last_reject_reason != "":
		return "Why unavailable: %s" % _reason_text(last_reject_reason)

	var play_gate_reason: String = str(vm.get("play_gate_reason", ""))
	if play_gate_reason != "":
		return "Cards unavailable: %s" % _reason_text(play_gate_reason)

	var pass_gate_reason: String = str(vm.get("pass_gate_reason", ""))
	if pass_gate_reason != "":
		return "Pass unavailable: %s" % _reason_text(pass_gate_reason)

	return "Red cards attack. Blue cards defend. Gold cards are utility."

func _hand_text(vm: Dictionary) -> String:
	var hand: Array = vm.get("hand", [])
	var mappings: Array = []
	for i in range(min(hand.size(), 5)):
		mappings.append("%d=%s" % [i + 1, _card_display_name(str(hand[i]))])
	if mappings.is_empty():
		mappings.append("1-5=(empty)")
	mappings.append("Enter=End Turn")
	return "HAND • %d cards\nHotkeys: %s\nStyle: %s (V toggle)" % [hand.size(), " • ".join(mappings), _card_style_label()]

func _event_log_text(vm: Dictionary) -> String:
	var lines: Array = vm.get("recent_events", [])
	return "RECENT EVENTS\n%s" % _join_lines(lines)

func _join_lines(lines: Array) -> String:
	var rendered: String = ""
	for i in range(lines.size()):
		rendered += str(lines[i])
		if i < lines.size() - 1:
			rendered += "\n"
	return rendered

func _refresh_pass_button(vm: Dictionary) -> void:
	var node = get_node_or_null("Margin/VBox/Buttons/Pass")
	if not (node is Button):
		return
	var reason: String = str(vm.get("pass_gate_reason", ""))
	node.disabled = reason != ""
	if reason == "":
		node.tooltip_text = "End the turn."
	else:
		node.tooltip_text = _reason_text(reason)

func _refresh_hand_buttons(vm: Dictionary) -> void:
	if not has_node("Margin/VBox/HandPanel/HandVBox/HandButtons"):
		return
	var hand: Array = vm.get("hand", [])
	var play_gate_reason: String = str(vm.get("play_gate_reason", ""))
	var reward_open: bool = str(vm.get("reward_state", "none")) in ["presented", "applied"]
	var buttons := $Margin/VBox/HandPanel/HandVBox/HandButtons.get_children()
	for i in range(buttons.size()):
		var b = buttons[i]
		if not (b is Button):
			continue
		if i < hand.size():
			var card_id: String = str(hand[i])
			b.text = _card_button_text(card_id)
			b.set_meta("card_id", card_id)
			b.tooltip_text = _card_tooltip(card_id)
			if play_gate_reason != "":
				b.tooltip_text += "\nUnavailable: %s" % _reason_text(play_gate_reason)
			_apply_card_button_style(b, card_id, reward_open or play_gate_reason != "")
		else:
			b.text = "(empty)"
			b.set_meta("card_id", "")
			b.tooltip_text = ""
			_apply_card_button_style(b, "", true)

func _refresh_reward_overlay(vm: Dictionary) -> void:
	var overlay = get_node_or_null("RewardOverlay")
	if not (overlay is Control):
		return
	var reward_state: String = str(vm.get("reward_state", "none"))
	var show_overlay: bool = reward_state in ["presented", "applied"]
	overlay.visible = show_overlay
	if not show_overlay:
		return

	var reward_title: String = "Victory Reward" if reward_state == "presented" else "Checkpoint Complete"
	var reward_subtitle: String = "Choose 1 card to permanently add to this run's deck." if reward_state == "presented" else "Reward secured for next encounter."
	var reward_state_text: String = "Role tags: [ATK] damage, [DEF] block, [UTL] utility. Hotkeys: 1-3 pick reward." if reward_state == "presented" else "%s\nHotkey: Enter starts next encounter." % str(vm.get("reward_summary_text", "Reward applied."))
	_set_label("RewardOverlay/Center/RewardPanel/RewardVBox/RewardTitle", reward_title)
	_set_label("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSubtitle", reward_subtitle)
	_set_label("RewardOverlay/Center/RewardPanel/RewardVBox/RewardState", reward_state_text)

	var rewards: Array = vm.get("reward_offer", [])
	var buttons := $RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices.get_children()
	for i in range(buttons.size()):
		var b = buttons[i]
		if not (b is Button):
			continue
		if i < rewards.size():
			var reward: Dictionary = rewards[i]
			var card_id: String = str(reward.get("card_id", ""))
			b.visible = true
			b.text = _reward_card_button_text(card_id)
			b.set_meta("reward_card_id", card_id)
			b.tooltip_text = _reward_card_tooltip(card_id)
			_apply_card_button_style(b, card_id, reward_state != "presented")
		else:
			b.visible = false

	var continue_button = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue")
	if continue_button is Button:
		continue_button.text = "Start Next Encounter"
		continue_button.visible = reward_state == "applied"
		continue_button.disabled = reward_state != "applied"

func _card_button_text(card_id: String) -> String:
	var marker: String = _card_role_marker(card_id)
	if card_id.begins_with("strike"):
		return "%s Strike\nAttack • 6 dmg • Cost 1" % marker
	if card_id.begins_with("defend"):
		return "%s Defend\nDefense • 5 block • Cost 1" % marker
	return "%s %s\nUtility • Draw 1 • Cost 1" % [marker, _card_display_name(card_id)]

func _card_tooltip(card_id: String) -> String:
	var marker: String = _card_role_marker(card_id)
	if card_id.begins_with("strike"):
		return "%s Attack card: deal 6 damage." % marker
	if card_id.begins_with("defend"):
		return "%s Defense card: gain 5 block." % marker
	return "%s Utility card: draw 1 card." % marker

func _reward_card_button_text(card_id: String) -> String:
	var marker: String = _card_role_marker(card_id)
	if card_id.begins_with("strike"):
		return "%s Strike\nAdd to deck • Deal 6 dmg • Cost 1" % marker
	if card_id.begins_with("defend"):
		return "%s Defend\nAdd to deck • Gain 5 block • Cost 1" % marker
	return "%s %s\nAdd to deck • Draw 1 • Cost 1" % [marker, _card_display_name(card_id)]

func _reward_card_tooltip(card_id: String) -> String:
	return "%s\nReward effect: permanently add this card to your run deck." % _card_tooltip(card_id)

func _card_role_marker(card_id: String) -> String:
	if card_id.begins_with("strike"):
		return "[ATK]"
	if card_id.begins_with("defend"):
		return "[DEF]"
	return "[UTL]"

func _card_display_name(card_id: String) -> String:
	if card_id.begins_with("strike"):
		return "Strike"
	if card_id.begins_with("defend"):
		return "Defend"
	var words: PackedStringArray = PackedStringArray()
	for part in card_id.split("_"):
		if part == "":
			continue
		words.append(part.capitalize())
	var rendered: String = " ".join(words)
	if rendered == "":
		return card_id
	return rendered

func _card_style_label() -> String:
	return "Classic" if card_style_variant == "classic" else "Alt"

func _toggle_card_style_variant() -> void:
	card_style_variant = "alt" if card_style_variant == "classic" else "classic"
	if previous_vm.is_empty():
		return
	refresh(previous_vm)

func _reason_text(reason_code: String) -> String:
	match reason_code:
		"ERR_RESOLVE_LOCKED":
			return "Effects are resolving right now."
		"ERR_NOT_ENOUGH_ENERGY":
			return "You need 1 energy to play another card."
		"ERR_COMBAT_COMPLETE":
			return "Combat is over. Restart to play again."
		"ERR_CARD_NOT_IN_HAND":
			return "That card is no longer in hand."
		"ERR_PHASE_DISALLOWS_INPUT":
			return "You cannot act during the enemy or end step."
		"ERR_REWARD_NOT_AVAILABLE":
			return "No reward is available right now."
		"ERR_REWARD_ALREADY_CLAIMED":
			return "This checkpoint reward was already claimed."
		"ERR_INVALID_REWARD_SELECTION":
			return "That reward choice is not valid."
		_:
			return "UNMAPPED_REASON(%s)" % reason_code

func _combat_result_text(result: String) -> String:
	match result:
		"player_win":
			return "Victory"
		"player_lose":
			return "Defeat"
		_:
			return "In Progress"

func _unhandled_input(event: InputEvent) -> void:
	if runner == null:
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	if _is_transition_toast_visible():
		if _is_enter_key(key_event):
			_hide_transition_toast()
		var viewport_toast := get_viewport()
		if viewport_toast != null:
			viewport_toast.set_input_as_handled()
		return

	if _is_style_toggle_key(key_event):
		_toggle_card_style_variant()
		var viewport_style := get_viewport()
		if viewport_style != null:
			viewport_style.set_input_as_handled()
		return

	var handled: bool = _handle_reward_hotkey(key_event)
	if not handled:
		handled = _handle_combat_hotkey(key_event)
	if handled:
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _handle_reward_hotkey(key_event: InputEventKey) -> bool:
	var reward_state: String = str(previous_vm.get("reward_state", "none"))
	if reward_state == "presented":
		var reward_offer: Array = previous_vm.get("reward_offer", [])
		var reward_index: int = _key_to_slot_index(key_event)
		if reward_index < 0:
			return false
		if reward_index >= reward_offer.size() or reward_index >= 3:
			return true
		if runner.has_method("choose_reward_by_index"):
			runner.choose_reward_by_index(reward_index)
		return true
	if reward_state in ["applied", "closed"] and _is_enter_key(key_event):
		_on_reward_continue()
		return true
	return false

func _handle_combat_hotkey(key_event: InputEventKey) -> bool:
	var reward_state: String = str(previous_vm.get("reward_state", "none"))
	if reward_state in ["presented", "applied", "closed"]:
		return false
	if _is_enter_key(key_event):
		runner.player_pass()
		return true
	var hand_index: int = _key_to_slot_index(key_event)
	if hand_index < 0:
		return false
	var hand: Array = previous_vm.get("hand", [])
	if hand_index >= hand.size():
		return true
	var card_id: String = str(hand[hand_index])
	if card_id == "":
		return true
	runner.player_play_card(card_id)
	return true

func _key_to_slot_index(key_event: InputEventKey) -> int:
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		KEY_4, KEY_KP_4:
			return 3
		KEY_5, KEY_KP_5:
			return 4
		_:
			return -1

func _is_enter_key(key_event: InputEventKey) -> bool:
	return key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER

func _is_style_toggle_key(key_event: InputEventKey) -> bool:
	return key_event.keycode == KEY_V

func _on_hand_card_pressed(button: Button) -> void:
	if runner == null:
		return
	var card_id: String = str(button.get_meta("card_id", ""))
	if card_id == "":
		return
	_pulse_control(button, 1.03, "hand_press:%s" % str(button.get_path()), 0.04, 0.08)
	runner.player_play_card(card_id)

func _on_pass() -> void:
	if runner == null:
		return
	runner.player_pass()

func _on_restart() -> void:
	if runner == null:
		return
	runner.reset_battle(13371337)

func _on_reward_pressed(button: Button) -> void:
	if runner == null:
		return
	var reward_card_id: String = str(button.get_meta("reward_card_id", ""))
	if reward_card_id == "":
		return
	_pulse_control(button, 1.03, "reward_press:%s" % str(button.get_path()), 0.04, 0.08)
	runner.choose_reward(reward_card_id)

func _on_reward_continue() -> void:
	if runner == null:
		return
	if next_encounter_transition_pending:
		return
	next_encounter_transition_pending = true
	var continue_button_node: Node = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue")
	if continue_button_node is Button:
		var continue_button: Button = continue_button_node
		continue_button.disabled = true
		_pulse_control(continue_button, 1.03, "reward_continue_press", 0.04, 0.08)
	_play_next_encounter_transition()
