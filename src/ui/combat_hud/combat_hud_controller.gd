extends Control
class_name CombatHudController

const PANEL_BG := Color("#171b24")
const PANEL_BG_SOFT := Color("#202838")
const PANEL_BORDER := Color("#4b5876")
const HAND_PANEL_BG := Color("#101722")
const HAND_PANEL_BORDER := Color("#b9985a")
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
const HAND_CARD_SIZE := Vector2(448, 640)
const REWARD_CARD_SIZE := Vector2(336, 480)
const HAND_ART_FACE_SIZE := Vector2(376, 220)
const REWARD_ART_FACE_SIZE := Vector2(276, 166)
const HAND_ROLE_FACE_SIZE := Vector2(48, 48)
const REWARD_ROLE_FACE_SIZE := Vector2(40, 40)
const HAND_HOVER_SCALE := 1.5
const REWARD_HOVER_SCALE := 1.22
const CARD_BODY_CLASSIC := Color("#eadfc7")
const CARD_BODY_ALT := Color("#ddd0b7")
const CARD_BODY_DISABLED := Color("#938b7e")
const CARD_TEXT_DARK := Color("#2c2218")
const CARD_TEXT_MUTED_DARK := Color("#6d5d49")
const CARD_TITLE_RAIL_CLASSIC := Color("#33261a")
const CARD_TITLE_RAIL_ALT := Color("#273137")
const CARD_TITLE_TEXT := Color("#f7efe2")
const CARD_FRAME_BG := Color("#d8cab0")
const CARD_FRAME_BORDER := Color("#5a4733")
const CARD_FOOTER_GOOD := Color("#6d7f4d")
const CARD_FOOTER_WARN := Color("#9a7241")
const CARD_FOOTER_NEUTRAL := Color("#b59d6f")
const PLAYER_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/player_cat_steward_bust_128.png"
const ENEMY_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/enemy_badger_warden_068.png"
const CREST_PATH := "res://src/ui/combat_hud/assets/banner_crest_steward_064.png"
const REWARD_SEAL_PATH := "res://assets/generated/ui/reward/reward_seal_steward_polish.png"
const CARD_ART_STRIKE_PATH := "res://assets/generated/cards/card_strike_cat_duelist_md.png"
const CARD_ART_DEFEND_PATH := "res://assets/generated/cards/card_defend_badger_bulwark_md.png"
const CARD_ART_UTILITY_PATH := "res://assets/generated/cards/card_scheme_seep_goblin_md.png"
const CARD_ART_RUBY_PATH := "res://assets/generated/cards/card_ember_jab_ruby_md.png"
const CARD_ART_SAPPHIRE_PATH := "res://assets/generated/cards/card_ward_polish_sapphire_md.png"
const CARD_ART_FOCUS_PATH := "res://assets/generated/cards/card_vault_focus_seal_polish_md.png"
const CARD_ART_PLACEHOLDER_PATH := "res://assets/generated/cards/placeholders/card_placeholder_steward_warrant_md.png"
const GEM_RUBY_ICON_PATH := "res://assets/generated/gems/obj_gem_ruby_token_md.png"
const GEM_SAPPHIRE_ICON_PATH := "res://assets/generated/gems/obj_gem_sapphire_token_md.png"
const ROLE_ICON_ATTACK_PATH := "res://assets/generated/ui/icons/ui_icon_attack_sm.png"
const ROLE_ICON_DEFEND_PATH := "res://assets/generated/ui/icons/ui_icon_defend_sm.png"
const ROLE_ICON_UTILITY_PATH := "res://assets/generated/ui/icons/ui_icon_utility_sm.png"
const FOCUS_ICON_PATH := "res://assets/generated/ui/icons/ui_icon_focus_sm.png"
const LOCK_ICON_PATH := "res://assets/generated/ui/icons/ui_icon_locked_sm.png"
const BUTTON_ART_SIZE := Vector2(56, 56)
const BUTTON_ROLE_ICON_SIZE := Vector2(20, 20)
const STATUS_ICON_SIZE := Vector2(24, 24)
const STATUS_GEM_SIZE := Vector2(28, 28)
const GEM_REJECT_REASONS := [
	"ERR_FOCUS_REQUIRED",
	"ERR_STACK_EMPTY",
	"ERR_STACK_TOP_MISMATCH",
	"ERR_STACK_TARGET_MISMATCH",
	"ERR_SELECTOR_INVALID",
]
const MISSING_ART_TINT := Color(0.78, 0.82, 0.90, 0.55)
const CARD_PRESENTER_SCRIPT := preload("res://src/core/card/card_presenter.gd")

var runner: Variant
var card_presenter: Variant
var previous_vm: Dictionary = {}
var fx_tweens: Dictionary = {}
var next_encounter_transition_pending: bool = false
var card_style_variant: String = "classic"

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	card_presenter = CARD_PRESENTER_SCRIPT.new()
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
			child.mouse_entered.connect(_on_card_hover_entered.bind(child))
			child.mouse_exited.connect(_on_card_hover_exited.bind(child))
			child.focus_entered.connect(_on_card_hover_entered.bind(child))
			child.focus_exited.connect(_on_card_hover_exited.bind(child))

func _connect_reward_buttons() -> void:
	if not has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices"):
		return
	for child in $RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices.get_children():
		if child is Button:
			child.pressed.connect(_on_reward_pressed.bind(child))
			child.mouse_entered.connect(_on_card_hover_entered.bind(child))
			child.mouse_exited.connect(_on_card_hover_exited.bind(child))
			child.focus_entered.connect(_on_card_hover_entered.bind(child))
			child.focus_exited.connect(_on_card_hover_exited.bind(child))
	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue"):
		$RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue.pressed.connect(_on_reward_continue)

func _apply_generated_art() -> void:
	_apply_texture("Margin/VBox/Banner/BannerRow/BannerCrest", CREST_PATH, Vector2(36, 36), true)
	_apply_texture("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerPortrait", PLAYER_PORTRAIT_PATH, Vector2(80, 80), false)
	_apply_texture("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyPortrait", ENEMY_PORTRAIT_PATH, Vector2(72, 72), true)
	_apply_texture("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal", REWARD_SEAL_PATH, Vector2(96, 96), false)

func _apply_texture(path: String, resource_path: String, size: Vector2, pixel_art: bool = false) -> void:
	var node = get_node_or_null(path)
	if not (node is TextureRect):
		return
	_apply_texture_rect(node, resource_path, size, pixel_art)

func _apply_texture_rect(node: TextureRect, resource_path: String, size: Vector2, pixel_art: bool = false, show_missing: bool = true) -> void:
	var texture := TextureLoader.try_load(resource_path)
	node.custom_minimum_size = size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR
	if texture == null:
		node.texture = null
		node.visible = show_missing
		node.modulate = MISSING_ART_TINT
		node.tooltip_text = "Missing art asset: %s" % resource_path if show_missing else ""
		return
	node.texture = texture
	node.visible = true
	node.modulate = Color(1, 1, 1, 1)
	node.tooltip_text = ""

func _clear_texture_rect(node: TextureRect, size: Vector2, visible: bool = false) -> void:
	node.custom_minimum_size = size
	node.texture = null
	node.visible = visible
	node.modulate = Color(1, 1, 1, 1)
	node.tooltip_text = ""

func _is_reward_button(button: Button) -> bool:
	return str(button.name).begins_with("Reward")

func _set_control_rect(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom

func _ensure_face_panel(button: Button, node_name: String) -> Panel:
	var existing := button.get_node_or_null(node_name)
	if existing is Panel:
		return existing
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(panel)
	return panel

func _ensure_face_label(button: Button, node_name: String, wrap: bool = false, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var existing := button.get_node_or_null(node_name)
	if existing is Label:
		var label_existing: Label = existing
		label_existing.horizontal_alignment = alignment
		label_existing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label_existing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
		return label_existing
	var label := Label.new()
	label.name = node_name
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	button.add_child(label)
	return label

func _ensure_card_face(button: Button, is_reward: bool) -> void:
	_ensure_face_panel(button, "Chrome")
	_ensure_face_panel(button, "ArtFrame")
	_ensure_face_panel(button, "TitleRail")
	_ensure_face_panel(button, "FooterStrip")
	_ensure_face_label(button, "HotkeyBadge", false, HORIZONTAL_ALIGNMENT_LEFT)
	_ensure_face_label(button, "CostBadge", false, HORIZONTAL_ALIGNMENT_RIGHT)
	_ensure_face_label(button, "NameLabel", false, HORIZONTAL_ALIGNMENT_LEFT)
	_ensure_face_label(button, "PayoffLabel", true, HORIZONTAL_ALIGNMENT_LEFT)
	_ensure_face_label(button, "RulesLabel", true, HORIZONTAL_ALIGNMENT_LEFT)
	_ensure_face_label(button, "FooterLabel", false, HORIZONTAL_ALIGNMENT_LEFT)
	_apply_card_face_layout(button, is_reward)

	var order: Array[String] = [
		"Chrome",
		"ArtFrame",
		"TitleRail",
		"FooterStrip",
		"HotkeyBadge",
		"CostBadge",
		"ArtThumb",
		"RoleIcon",
		"NameLabel",
		"PayoffLabel",
		"RulesLabel",
		"FooterLabel",
	]
	for index in range(order.size()):
		var child := button.get_node_or_null(order[index])
		if child != null:
			button.move_child(child, index)

func _apply_card_face_layout(button: Button, is_reward: bool) -> void:
	var chrome := button.get_node_or_null("Chrome")
	var art_frame := button.get_node_or_null("ArtFrame")
	var title_rail := button.get_node_or_null("TitleRail")
	var footer_strip := button.get_node_or_null("FooterStrip")
	var hotkey_badge := button.get_node_or_null("HotkeyBadge")
	var cost_badge := button.get_node_or_null("CostBadge")
	var art_thumb := button.get_node_or_null("ArtThumb")
	var role_icon := button.get_node_or_null("RoleIcon")
	var name_label := button.get_node_or_null("NameLabel")
	var payoff_label := button.get_node_or_null("PayoffLabel")
	var rules_label := button.get_node_or_null("RulesLabel")
	var footer_label := button.get_node_or_null("FooterLabel")

	if is_reward:
		if chrome is Control:
			_set_control_rect(chrome, 12.0, 12.0, 324.0, 456.0)
		if art_frame is Control:
			_set_control_rect(art_frame, 22.0, 42.0, 314.0, 224.0)
		if title_rail is Control:
			_set_control_rect(title_rail, 22.0, 236.0, 314.0, 280.0)
		if footer_strip is Control:
			_set_control_rect(footer_strip, 20.0, 446.0, 316.0, 470.0)
		if hotkey_badge is Control:
			_set_control_rect(hotkey_badge, 30.0, 14.0, 100.0, 40.0)
		if cost_badge is Control:
			_set_control_rect(cost_badge, 230.0, 14.0, 308.0, 42.0)
		if art_thumb is Control:
			_set_control_rect(art_thumb, 30.0, 50.0, 306.0, 216.0)
		if role_icon is Control:
			_set_control_rect(role_icon, 28.0, 238.0, 68.0, 278.0)
		if name_label is Control:
			_set_control_rect(name_label, 78.0, 242.0, 308.0, 274.0)
		if payoff_label is Control:
			_set_control_rect(payoff_label, 30.0, 296.0, 306.0, 332.0)
		if rules_label is Control:
			_set_control_rect(rules_label, 30.0, 344.0, 306.0, 432.0)
		if footer_label is Control:
			_set_control_rect(footer_label, 30.0, 446.0, 306.0, 470.0)
	else:
		if chrome is Control:
			_set_control_rect(chrome, 12.0, 12.0, 436.0, 628.0)
		if art_frame is Control:
			_set_control_rect(art_frame, 24.0, 40.0, 424.0, 272.0)
		if title_rail is Control:
			_set_control_rect(title_rail, 24.0, 286.0, 424.0, 338.0)
		if footer_strip is Control:
			_set_control_rect(footer_strip, 20.0, 606.0, 428.0, 634.0)
		if hotkey_badge is Control:
			_set_control_rect(hotkey_badge, 30.0, 16.0, 102.0, 44.0)
		if cost_badge is Control:
			_set_control_rect(cost_badge, 320.0, 16.0, 424.0, 44.0)
		if art_thumb is Control:
			_set_control_rect(art_thumb, 30.0, 50.0, 406.0, 270.0)
		if role_icon is Control:
			_set_control_rect(role_icon, 28.0, 290.0, 76.0, 338.0)
		if name_label is Control:
			_set_control_rect(name_label, 88.0, 294.0, 422.0, 334.0)
		if payoff_label is Control:
			_set_control_rect(payoff_label, 28.0, 360.0, 422.0, 408.0)
		if rules_label is Control:
			_set_control_rect(rules_label, 28.0, 424.0, 422.0, 592.0)
		if footer_label is Control:
			_set_control_rect(footer_label, 28.0, 606.0, 422.0, 632.0)

func _apply_readability_theme() -> void:
	for path in [
		"Margin/VBox/Banner",
		"Margin/VBox/StatsRow/PlayerPanel",
		"Margin/VBox/StatsRow/EnemyPanel",
		"Margin/VBox/StatsRow/ZonesPanel",
		"Margin/VBox/StatsRow/GeneratedStatusPanel",
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

	var hand_panel_node := get_node_or_null("Margin/VBox/HandPanel")
	if hand_panel_node is PanelContainer:
		_apply_hand_panel_style(hand_panel_node)

	_apply_label_style("Margin/VBox/Banner/BannerRow/Title", 28, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/Banner/BannerRow/Status", 20, TEXT_ACCENT)
	_apply_label_style("Margin/VBox/Banner/BannerRow/ResolveLock", 18, TEXT_GOOD)
	_apply_label_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerStats", 20, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyStats", 20, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/StatsRow/ZonesPanel/Zones", 16, TEXT_MUTED)
	_apply_label_style("Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusLabel", 16, TEXT_ACCENT)
	_apply_label_style("Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/FocusValue", 20, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/QueuePanel/Queue", 16, TEXT_MUTED)
	_apply_label_style("Margin/VBox/ReasonPanel/Hint", 16, TEXT_PRIMARY)
	_apply_label_style("Margin/VBox/HandPanel/HandVBox/Hand", 24, TEXT_ACCENT)
	_apply_label_style("Margin/VBox/EventPanel/EventLog", 16, TEXT_MUTED)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardTitle", 30, TEXT_PRIMARY)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSubtitle", 22, TEXT_MUTED)
	_apply_label_style("RewardOverlay/Center/RewardPanel/RewardVBox/RewardState", 22, TEXT_PRIMARY)
	_apply_label_style("TransitionToastLayer/ToastStrip/ToastPanel/ToastLabel", 28, TEXT_ACCENT)

	_apply_progress_bar_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerHpBar", HEALTH_FILL)
	_apply_progress_bar_style("Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/EnergyBar", ENERGY_FILL)
	_apply_progress_bar_style("Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyHpBar", ENEMY_FILL)

	if has_node("Margin/VBox/Buttons/Pass"):
		_apply_neutral_button_style($Margin/VBox/Buttons/Pass, 20, 48)
	if has_node("Margin/VBox/Buttons/Restart"):
		_apply_neutral_button_style($Margin/VBox/Buttons/Restart, 20, 48)
	if has_node("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue"):
		_apply_neutral_button_style($RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue, 20, 48)

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

func _apply_hand_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = HAND_PANEL_BG
	style.border_color = HAND_PANEL_BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 14
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
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

func _build_card_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
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

func _card_body_color(disabled: bool) -> Color:
	if disabled:
		return CARD_BODY_DISABLED
	return CARD_BODY_ALT if card_style_variant == "alt" else CARD_BODY_CLASSIC

func _apply_card_button_style(button: Button, card_id: String, disabled: bool, card_size: Vector2 = HAND_CARD_SIZE) -> void:
	var palette: Dictionary = _card_palette(card_id)
	var border_color: Color = palette.get("accent", OTHER_BORDER)
	var body_color: Color = _card_body_color(disabled)
	var hover_border: Color = Color(1, 1, 1, 0.95)
	var pressed_border: Color = TEXT_GOOD if not disabled else border_color.darkened(0.2)
	var disabled_border: Color = border_color.darkened(0.35)

	button.add_theme_stylebox_override("normal", _build_card_button_style(body_color, border_color))
	button.add_theme_stylebox_override("hover", _build_card_button_style(body_color.lightened(0.03), hover_border))
	button.add_theme_stylebox_override("pressed", _build_card_button_style(body_color.darkened(0.04), pressed_border))
	button.add_theme_stylebox_override("disabled", _build_card_button_style(CARD_BODY_DISABLED, disabled_border))
	button.add_theme_font_size_override("font_size", 1)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = 0
	button.custom_minimum_size = card_size
	button.disabled = disabled

func _card_palette(card_id: String) -> Dictionary:
	var palette_key: String = "utility"
	if card_presenter != null:
		palette_key = card_presenter.palette_key(card_id)

	if card_style_variant == "alt":
		match palette_key:
			"attack":
				return {"accent": ALT_STRIKE_BORDER}
			"defend":
				return {"accent": ALT_DEFEND_BORDER}
			_:
				return {"accent": ALT_OTHER_BORDER}

	match palette_key:
		"attack":
			return {"accent": STRIKE_BORDER}
		"defend":
			return {"accent": DEFEND_BORDER}
		_:
			return {"accent": OTHER_BORDER}

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

func _card_catalog_ref() -> Variant:
	if card_presenter != null and card_presenter.card_catalog != null:
		return card_presenter.card_catalog
	return null

func _build_face_panel_style(bg_color: Color, border_color: Color, border_width: int = 1, corner_radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style

func _apply_face_panel_override(button: Button, node_name: String, bg_color: Color, border_color: Color, border_width: int = 1, corner_radius: int = 8) -> void:
	var node := button.get_node_or_null(node_name)
	if node is Panel:
		(node as Panel).add_theme_stylebox_override("panel", _build_face_panel_style(bg_color, border_color, border_width, corner_radius))

func _apply_face_label_override(button: Button, node_name: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> void:
	var node := button.get_node_or_null(node_name)
	if node is Label:
		var label: Label = node
		label.horizontal_alignment = alignment
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)

func _card_face_target(button: Button) -> Node:
	var chrome := button.get_node_or_null("Chrome")
	if chrome is Node:
		return chrome
	return button

func _face_footer_background(footer_text: String, disabled: bool) -> Color:
	if disabled:
		return CARD_FOOTER_WARN
	var normalized: String = footer_text.to_lower().strip_edges()
	if normalized == "" or normalized == "playable" or normalized == "add to deck" or normalized == "chosen":
		return CARD_FOOTER_GOOD
	if normalized.begins_with("needs") or normalized.find("locked") != -1 or normalized.find("not enough") != -1 or normalized.find("reward open") != -1:
		return CARD_FOOTER_WARN
	return CARD_FOOTER_NEUTRAL

func _set_face_text(button: Button, node_name: String, text_value: String, visible: bool = true) -> void:
	var node := button.get_node_or_null(node_name)
	if node is Label:
		var label: Label = node
		label.text = text_value
		label.visible = visible and text_value != ""

func _set_face_visibility(button: Button, node_name: String, visible: bool) -> void:
	var node := button.get_node_or_null(node_name)
	if node is CanvasItem:
		(node as CanvasItem).visible = visible

func _card_cost_badge_text(card_id: String) -> String:
	if card_id == "":
		return ""
	var card_catalog: Variant = _card_catalog_ref()
	if card_catalog == null:
		return "1◎"
	return "%d◎" % int(card_catalog.base_cost(card_id))

func _normalize_card_effects(card_id: String) -> Array:
	var card_catalog: Variant = _card_catalog_ref()
	if card_catalog == null:
		return []
	var effect_payload: Variant = card_catalog.effects_for(card_id)
	if effect_payload is Array:
		return (effect_payload as Array).duplicate(true)
	if effect_payload is Dictionary:
		return [effect_payload.duplicate(true)]
	return []

func _effect_payoff_text(effect: Dictionary) -> String:
	var effect_type: String = str(effect.get("type", "")).strip_edges()
	match effect_type:
		"deal_damage":
			return "%d DMG" % int(effect.get("amount", 0))
		"gain_block":
			return "%d BLK" % int(effect.get("amount", 0))
		"draw_n":
			return "Draw %d" % int(effect.get("amount", 0))
		"gem_produce":
			return "Produce %s" % str(effect.get("gem", "Gem"))
		"gem_gain_focus":
			return "+%d FOCUS" % int(effect.get("amount", 0))
		"gem_consume_top":
			return "Consume %s" % str(effect.get("gem", "Gem"))
		"gem_consume_top_offset":
			return "Offset %s" % str(effect.get("gem", "Gem"))
		_:
			return ""

func _card_payoff_text(card_id: String) -> String:
	var tokens: Array = []
	for effect_variant in _normalize_card_effects(card_id):
		if not (effect_variant is Dictionary):
			continue
		var token: String = _effect_payoff_text(effect_variant)
		if token == "":
			continue
		tokens.append(token)
		if tokens.size() >= 2:
			break
	if tokens.is_empty():
		var card_catalog: Variant = _card_catalog_ref()
		if card_catalog != null:
			return str(card_catalog.hand_rules_text(card_id))
	return "  •  ".join(tokens)

func _clean_face_rules_text(text_value: String) -> String:
	var cleaned: String = text_value.strip_edges()
	for prefix in [
		"Attack card:",
		"Attack upgrade:",
		"Defense card:",
		"Defense upgrade:",
		"Utility card:",
		"Advanced gem action:",
		"Gem action:",
	]:
		if cleaned.begins_with(prefix):
			cleaned = cleaned.trim_prefix(prefix).strip_edges()
	return cleaned.capitalize()

func _truncate_text(text_value: String, max_length: int) -> String:
	var trimmed: String = text_value.strip_edges()
	if trimmed.length() <= max_length:
		return trimmed
	return "%s…" % trimmed.substr(0, max_length - 1).strip_edges()

func _card_face_rules_text(card_id: String, is_reward: bool) -> String:
	if card_id == "":
		return ""
	var card_catalog: Variant = _card_catalog_ref()
	if card_catalog == null:
		return ""
	var base_text: String = str(card_catalog.tooltip_text(card_id))
	if is_reward and base_text == "":
		base_text = str(card_catalog.reward_rules_text(card_id))
	return _truncate_text(_clean_face_rules_text(base_text), 64 if is_reward else 48)

func _hand_footer_text(play_reason: String, reward_open: bool) -> String:
	if reward_open:
		return "Reward open"
	match play_reason:
		"":
			return "Playable"
		"ERR_FOCUS_REQUIRED":
			return "Needs FOCUS"
		"ERR_DISCARD_REQUIRED":
			return "Need discard"
		"ERR_STACK_EMPTY":
			return "Stack empty"
		"ERR_STACK_TOP_MISMATCH":
			return "Needs top gem"
		"ERR_STACK_TARGET_MISMATCH":
			return "Wrong target gem"
		"ERR_SELECTOR_INVALID":
			return "Selection invalid"
		"ERR_NOT_ENOUGH_ENERGY":
			return "Not enough energy"
		"ERR_RESOLVE_LOCKED":
			return "Resolve locked"
		"ERR_PHASE_DISALLOWS_INPUT":
			return "Wrong phase"
		_:
			return _truncate_text(_reason_text(play_reason), 24)

func _reward_footer_text(card_id: String, reward_state: String, reward_selected_card_id: String) -> String:
	if reward_state == "presented":
		return "Add to deck"
	if reward_selected_card_id != "" and reward_selected_card_id == card_id:
		return "Chosen"
	return "Reward secured"

func _apply_card_face_style(button: Button, card_id: String, footer_text: String, disabled: bool, is_reward: bool) -> void:
	var palette: Dictionary = _card_palette(card_id)
	var accent: Color = palette.get("accent", OTHER_BORDER)
	var chrome_border: Color = accent.lightened(0.18)
	var title_bg: Color = CARD_TITLE_RAIL_ALT if card_style_variant == "alt" else CARD_TITLE_RAIL_CLASSIC
	var footer_bg: Color = _face_footer_background(footer_text, disabled)
	var body_text_color: Color = CARD_TEXT_MUTED_DARK if disabled else CARD_TEXT_DARK
	var payoff_color: Color = accent if not disabled else CARD_TEXT_MUTED_DARK
	var badge_color: Color = CARD_TEXT_MUTED_DARK if disabled else CARD_TEXT_DARK
	var footer_text_color: Color = CARD_TITLE_TEXT if not disabled else CARD_TEXT_DARK
	var title_text_color: Color = CARD_TITLE_TEXT if not disabled else Color(0.82, 0.78, 0.72, 1.0)

	_apply_face_panel_override(button, "Chrome", Color(1, 1, 1, 0.10), chrome_border, 1, 10)
	_apply_face_panel_override(button, "ArtFrame", CARD_FRAME_BG, CARD_FRAME_BORDER, 1, 8)
	_apply_face_panel_override(button, "TitleRail", title_bg, accent, 1, 7)
	_apply_face_panel_override(button, "FooterStrip", footer_bg, accent, 1, 7)
	_apply_face_label_override(button, "HotkeyBadge", 20 if not is_reward else 18, badge_color, HORIZONTAL_ALIGNMENT_LEFT, false)
	_apply_face_label_override(button, "CostBadge", 20 if not is_reward else 19, badge_color, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_apply_face_label_override(button, "NameLabel", 28 if not is_reward else 24, title_text_color, HORIZONTAL_ALIGNMENT_LEFT, false)
	_apply_face_label_override(button, "PayoffLabel", 22 if not is_reward else 21, payoff_color, HORIZONTAL_ALIGNMENT_LEFT, true)
	_apply_face_label_override(button, "RulesLabel", 17 if not is_reward else 16, body_text_color, HORIZONTAL_ALIGNMENT_LEFT, true)
	_apply_face_label_override(button, "FooterLabel", 15 if not is_reward else 15, footer_text_color, HORIZONTAL_ALIGNMENT_LEFT, false)

func _refresh_card_face(button: Button, card_id: String, slot_index: int, footer_text: String, disabled: bool) -> void:
	var is_reward: bool = _is_reward_button(button)
	_ensure_card_face(button, is_reward)
	_apply_card_face_style(button, card_id, footer_text, disabled, is_reward)
	var is_empty: bool = card_id == ""
	for panel_name in ["Chrome", "ArtFrame", "TitleRail", "FooterStrip"]:
		_set_face_visibility(button, panel_name, not is_empty)
	_set_face_text(button, "HotkeyBadge", str(slot_index + 1) if not is_empty else "", not is_empty)
	_set_face_text(button, "CostBadge", _card_cost_badge_text(card_id), not is_empty)
	_set_face_text(button, "NameLabel", _card_display_name(card_id), not is_empty)
	_set_face_text(button, "PayoffLabel", _card_payoff_text(card_id), not is_empty)
	_set_face_text(button, "RulesLabel", _card_face_rules_text(card_id, is_reward), not is_empty)
	_set_face_text(button, "FooterLabel", footer_text if not is_empty else "", not is_empty)

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
	_refresh_generated_status_strip(vm)
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

func _button_has_card_content(button: Button) -> bool:
	var card_id: String = str(button.get_meta("card_id", button.get_meta("reward_card_id", ""))).strip_edges()
	return card_id != ""

func _hover_scale_for_button(button: Button) -> float:
	return REWARD_HOVER_SCALE if _is_reward_button(button) else HAND_HOVER_SCALE

func _set_card_hover_state(button: Button, hovered: bool, instant: bool = false) -> void:
	if button == null or not is_instance_valid(button):
		return
	var target_scale: Vector2 = Vector2.ONE
	if hovered and _button_has_card_content(button):
		var scale_value: float = _hover_scale_for_button(button)
		target_scale = Vector2(scale_value, scale_value)
	button.pivot_offset = Vector2(button.size.x * 0.5, button.size.y)
	if target_scale != Vector2.ONE:
		button.z_index = 50
	if instant:
		button.scale = target_scale
		if target_scale == Vector2.ONE:
			button.z_index = 0
		return
	var tween: Tween = _restart_fx_tween("card_hover:%s" % str(button.get_path()))
	tween.tween_property(button, "scale", target_scale, 0.12 if hovered else 0.10)
	if target_scale == Vector2.ONE:
		tween.tween_callback(Callable(self, "_reset_card_hover_draw_order").bind(button))

func _reset_card_hover_draw_order(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.scale.is_equal_approx(Vector2.ONE):
		button.z_index = 0

func _on_card_hover_entered(button: Button) -> void:
	_set_card_hover_state(button, true)

func _on_card_hover_exited(button: Button) -> void:
	_set_card_hover_state(button, false)

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
			_flash_canvas_item(_card_face_target(reward_button), Color(0.86, 1.0, 0.86, 1.0), "reward_claim_button_flash")
			_pulse_control(_card_face_target(reward_button), 1.03, "reward_claim_button_pulse", 0.06, 0.12)

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
		label.text = _join_lines(lines)

	var panel_node: Node = get_node_or_null("TransitionToastLayer/ToastStrip/ToastPanel")
	if panel_node is CanvasItem:
		var panel: CanvasItem = panel_node
		panel.modulate = Color(1, 1, 1, 0)
		var toast_tween: Tween = _restart_fx_tween("encounter_toast")
		toast_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.12)
	var auto_hide_tween: Tween = _restart_fx_tween("encounter_toast_auto_hide")
	auto_hide_tween.tween_interval(0.8)
	auto_hide_tween.tween_callback(Callable(self, "_hide_transition_toast"))
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

func _refresh_generated_status_strip(vm: Dictionary) -> void:
	var top_window: Array = vm.get("gem_stack_top", [])
	var gem_paths: Array[String] = [
		"Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop1",
		"Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop2",
		"Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop3",
	]
	for i in range(gem_paths.size()):
		var gem_node := get_node_or_null(gem_paths[i])
		if not (gem_node is TextureRect):
			continue
		if i < top_window.size():
			var gem_name: String = str(top_window[i])
			_apply_texture_rect(gem_node, _gem_icon_path(gem_name), STATUS_GEM_SIZE, true, true)
			gem_node.tooltip_text = "Top gem %d: %s" % [i + 1, gem_name]
		else:
			_clear_texture_rect(gem_node, STATUS_GEM_SIZE, false)

	var focus_icon_node := get_node_or_null("Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/FocusIcon")
	if focus_icon_node is TextureRect:
		_apply_texture_rect(focus_icon_node, FOCUS_ICON_PATH, STATUS_ICON_SIZE, true, true)
		focus_icon_node.tooltip_text = "FOCUS"

	var focus_value_node := get_node_or_null("Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/FocusValue")
	if focus_value_node is Label:
		focus_value_node.text = str(int(vm.get("focus", 0)))
		focus_value_node.add_theme_color_override("font_color", TEXT_PRIMARY if int(vm.get("focus", 0)) > 0 else TEXT_MUTED)

	var lock_icon_node := get_node_or_null("Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/LockIcon")
	if lock_icon_node is TextureRect:
		if _should_show_lock_icon(vm):
			_apply_texture_rect(lock_icon_node, LOCK_ICON_PATH, STATUS_ICON_SIZE, true, true)
			lock_icon_node.tooltip_text = _lock_icon_tooltip(vm)
		else:
			_clear_texture_rect(lock_icon_node, STATUS_ICON_SIZE, false)

func _should_show_lock_icon(vm: Dictionary) -> bool:
	if bool(vm.get("resolve_lock", false)):
		return true
	if str(vm.get("play_gate_reason", "")) != "":
		return true
	return GEM_REJECT_REASONS.has(str(vm.get("last_reject_reason", "")))

func _lock_icon_tooltip(vm: Dictionary) -> String:
	if bool(vm.get("resolve_lock", false)):
		return _reason_text("ERR_RESOLVE_LOCKED")
	var play_gate_reason: String = str(vm.get("play_gate_reason", ""))
	if play_gate_reason != "":
		return _reason_text(play_gate_reason)
	var last_reject_reason: String = str(vm.get("last_reject_reason", ""))
	if last_reject_reason != "":
		return _reason_text(last_reject_reason)
	return "Action currently unavailable."

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
	var profile_name: String = str(vm.get("pressure_profile_name", "Steady Pressure"))
	var intent: Dictionary = vm.get("enemy_intent", {})
	var telegraph: String = str(intent.get("telegraph_text", "Attack for %d" % int(vm.get("enemy_intent_damage", 0))))
	return "ENEMY  HP %d/%d  •  Block %d\nIntent: %s\nPattern: %s" % [
		int(vm.get("enemy_hp", 0)),
		int(vm.get("enemy_max_hp", 0)),
		int(vm.get("enemy_block", 0)),
		telegraph,
		profile_name,
	]

func _zones_text(vm: Dictionary) -> String:
	var zones: Dictionary = vm.get("zones", {})
	var lines: Array = [
		"ZONES",
		"Draw %d" % int(zones.get("draw", 0)),
		"Discard %d" % int(zones.get("discard", 0)),
		"Exhaust %d" % int(zones.get("exhaust", 0)),
		"FOCUS %d" % int(vm.get("focus", 0)),
	]
	if int(zones.get("limbo", 0)) > 0:
		lines.append("Limbo %d" % int(zones.get("limbo", 0)))

	var top_window: Array = vm.get("gem_stack_top", [])
	if top_window.is_empty():
		lines.append("Gem Top (empty)")
	else:
		var gems: Array = []
		for gem in top_window:
			gems.append(str(gem))
		lines.append("Gem Top %s" % " -> ".join(gems))
	return _join_lines(lines)

func _queue_item_source_text(item: Dictionary) -> String:
	var source_instance_id: String = str(item.get("source_instance_id", "")).strip_edges()
	var card_id: String = str(item.get("card_id", source_instance_id)).strip_edges()
	if card_presenter != null and card_id != "":
		var display_name: String = card_presenter.display_name(card_id)
		if source_instance_id != "" and source_instance_id != card_id and source_instance_id != display_name:
			return "%s [%s]" % [display_name, source_instance_id]
		if display_name != "":
			return display_name
	return source_instance_id if source_instance_id != "" else card_id

func _queue_text(vm: Dictionary) -> String:
	var queue_preview: Array = vm.get("queue_preview", [])
	if not queue_preview.is_empty():
		var item: Dictionary = queue_preview[0]
		return "NEXT RESOLVE\n%s\nComparator: timing %d -> speed %d -> seq %d" % [
			_queue_item_source_text(item),
			int(item.get("timing_window_priority", 0)),
			int(item.get("speed_class_priority", 0)),
			int(item.get("enqueue_sequence_id", 0)),
		]

	var last_item: Dictionary = vm.get("last_resolved_queue_item", {})
	if not last_item.is_empty():
		return "LAST RESOLVE\n%s\nComparator: timing %d -> speed %d -> seq %d" % [
			_queue_item_source_text(last_item),
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
		mappings.append("%d=%s" % [i + 1, _card_display_name(_hand_presented_card_id(vm, i))])
	if mappings.is_empty():
		mappings.append("1-5=(empty)")
	mappings.append("Enter=End Turn")
	return "HAND • %d cards • Style: %s (V toggle)\nHotkeys: %s" % [hand.size(), _card_style_label(), " • ".join(mappings)]

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
	var reward_open: bool = str(vm.get("reward_state", "none")) in ["presented", "applied"]
	var buttons := $Margin/VBox/HandPanel/HandVBox/HandButtons.get_children()
	for i in range(buttons.size()):
		var b = buttons[i]
		if not (b is Button):
			continue
		if i < hand.size():
			var instance_id: String = _hand_instance_id(vm, i)
			var card_id: String = _hand_presented_card_id(vm, i)
			var play_reason: String = _hand_play_reason(vm, i)
			var disabled: bool = reward_open or play_reason != ""
			b.text = _card_button_text(card_id)
			b.set_meta("card_id", card_id)
			b.set_meta("instance_id", instance_id)
			b.set_meta("play_reason", play_reason)
			b.tooltip_text = _card_tooltip(card_id)
			if play_reason != "":
				b.tooltip_text += "\nUnavailable: %s" % _reason_text(play_reason)
			_apply_card_button_style(b, card_id, disabled, HAND_CARD_SIZE)
			_refresh_card_button_visuals(b, card_id)
			_refresh_card_face(b, card_id, i, _hand_footer_text(play_reason, reward_open), disabled)
		else:
			b.text = "(empty)"
			b.set_meta("card_id", "")
			b.set_meta("instance_id", "")
			b.set_meta("play_reason", "")
			b.tooltip_text = ""
			_apply_card_button_style(b, "", true, HAND_CARD_SIZE)
			_refresh_card_button_visuals(b, "")
			_refresh_card_face(b, "", i, "", true)
			_set_card_hover_state(b, false, true)

func _hand_presented_card_id(vm: Dictionary, hand_index: int) -> String:
	var hand_card_ids: Array = vm.get("hand_card_ids", [])
	if hand_index >= 0 and hand_index < hand_card_ids.size():
		var card_id: String = str(hand_card_ids[hand_index])
		if card_id != "":
			return card_id
	var hand: Array = vm.get("hand", [])
	if hand_index >= 0 and hand_index < hand.size():
		return str(hand[hand_index])
	return ""

func _hand_instance_id(vm: Dictionary, hand_index: int) -> String:
	var hand: Array = vm.get("hand", [])
	if hand_index >= 0 and hand_index < hand.size():
		return str(hand[hand_index])
	var hand_card_ids: Array = vm.get("hand_card_ids", [])
	if hand_index >= 0 and hand_index < hand_card_ids.size():
		return str(hand_card_ids[hand_index])
	return ""

func _hand_play_reason(vm: Dictionary, hand_index: int) -> String:
	var hand_play_reasons: Array = vm.get("hand_play_reasons", [])
	if hand_index >= 0 and hand_index < hand_play_reasons.size():
		return str(hand_play_reasons[hand_index])
	var play_gate_reason: String = str(vm.get("play_gate_reason", ""))
	return play_gate_reason

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
			var disabled: bool = reward_state != "presented"
			b.visible = true
			b.text = _reward_card_button_text(card_id)
			b.set_meta("reward_card_id", card_id)
			b.tooltip_text = _reward_card_tooltip(card_id)
			_apply_card_button_style(b, card_id, disabled, REWARD_CARD_SIZE)
			_refresh_card_button_visuals(b, card_id)
			_refresh_card_face(b, card_id, i, _reward_footer_text(card_id, reward_state, str(vm.get("reward_selected_card_id", ""))), disabled)
		else:
			b.visible = false
			_refresh_card_button_visuals(b, "")
			_refresh_card_face(b, "", i, "", true)
			_set_card_hover_state(b, false, true)

	var continue_button = get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue")
	if continue_button is Button:
		continue_button.text = "Start Next Encounter"
		continue_button.visible = reward_state == "applied"
		continue_button.disabled = reward_state != "applied"

func _card_button_text(card_id: String) -> String:
	if card_presenter != null:
		return card_presenter.card_button_text(card_id)
	return card_id

func _card_tooltip(card_id: String) -> String:
	if card_presenter != null:
		return card_presenter.card_tooltip(card_id)
	return card_id

func _reward_card_button_text(card_id: String) -> String:
	if card_presenter != null:
		return card_presenter.reward_card_button_text(card_id)
	return card_id

func _reward_card_tooltip(card_id: String) -> String:
	return "%s\nReward effect: permanently add this card to your run deck." % _card_tooltip(card_id)

func _refresh_card_button_visuals(button: Button, card_id: String) -> void:
	var is_reward: bool = _is_reward_button(button)
	_ensure_card_face(button, is_reward)
	var art_size: Vector2 = REWARD_ART_FACE_SIZE if is_reward else HAND_ART_FACE_SIZE
	var role_size: Vector2 = REWARD_ROLE_FACE_SIZE if is_reward else HAND_ROLE_FACE_SIZE
	var art_node := button.get_node_or_null("ArtThumb")
	if art_node is TextureRect:
		if card_id == "":
			_clear_texture_rect(art_node, art_size, false)
		else:
			_apply_texture_rect(art_node, _card_art_path(card_id), art_size, false, true)
			art_node.tooltip_text = _card_display_name(card_id)

	var role_icon_node := button.get_node_or_null("RoleIcon")
	if role_icon_node is TextureRect:
		if card_id == "":
			_clear_texture_rect(role_icon_node, role_size, false)
		else:
			_apply_texture_rect(role_icon_node, _role_icon_path(card_id), role_size, true, true)
			role_icon_node.tooltip_text = _card_role_marker(card_id)

func _card_art_path(card_id: String) -> String:
	var canonical_card_id: String = _canonical_card_id(card_id)
	match canonical_card_id:
		"strike", "strike_plus", "strike_precise", "quick_slash":
			return CARD_ART_STRIKE_PATH
		"defend", "defend_plus", "defend_hold", "heavy_guard":
			return CARD_ART_DEFEND_PATH
		"scheme_flow", "steady_hand":
			return CARD_ART_UTILITY_PATH
		"gem_produce_ruby", "gem_hybrid_ruby_strike", "gem_consume_top_ruby", "gem_offset_consume_ruby":
			return CARD_ART_RUBY_PATH
		"gem_produce_sapphire", "gem_hybrid_sapphire_guard", "gem_hybrid_sapphire_burst", "gem_consume_top_sapphire", "gem_offset_consume_sapphire":
			return CARD_ART_SAPPHIRE_PATH
		"gem_focus", "gem_hybrid_focus_guard":
			return CARD_ART_FOCUS_PATH
		"":
			return ""
		_:
			return CARD_ART_PLACEHOLDER_PATH

func _role_icon_path(card_id: String) -> String:
	if card_id == "":
		return ""
	match _card_palette_key(card_id):
		"attack":
			return ROLE_ICON_ATTACK_PATH
		"defend":
			return ROLE_ICON_DEFEND_PATH
		_:
			return ROLE_ICON_UTILITY_PATH

func _gem_icon_path(gem_name: String) -> String:
	match str(gem_name).strip_edges():
		"Ruby":
			return GEM_RUBY_ICON_PATH
		"Sapphire":
			return GEM_SAPPHIRE_ICON_PATH
		_:
			return ""

func _card_palette_key(card_id: String) -> String:
	if card_presenter != null:
		return str(card_presenter.palette_key(card_id))
	return "utility"

func _canonical_card_id(card_id: String) -> String:
	if card_id == "":
		return ""
	if card_presenter != null and card_presenter.card_catalog != null and card_presenter.card_catalog.has_method("resolved_card_id"):
		var resolved: String = str(card_presenter.card_catalog.resolved_card_id(card_id))
		if resolved != "":
			return resolved
	return card_id

func _card_role_marker(card_id: String) -> String:
	if card_presenter != null:
		return card_presenter.role_marker(card_id)
	return "[UTL]"

func _card_display_name(card_id: String) -> String:
	if card_presenter != null:
		return card_presenter.display_name(card_id)
	return card_id.capitalize()

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
			return "Effects are still resolving."
		"ERR_NOT_ENOUGH_ENERGY":
			return "You do not have enough energy to play this card."
		"ERR_COMBAT_COMPLETE":
			return "Combat is over. Restart to play again."
		"ERR_NO_VALID_TARGETS":
			return "No living target matches this card right now."
		"ERR_CARD_NOT_IN_HAND":
			return "That card is no longer in hand."
		"ERR_PHASE_DISALLOWS_INPUT":
			return "You can only act during your turn."
		"ERR_REWARD_NOT_AVAILABLE":
			return "No reward is available right now."
		"ERR_REWARD_ALREADY_CLAIMED":
			return "This checkpoint reward was already claimed."
		"ERR_INVALID_REWARD_SELECTION":
			return "That reward choice is not valid."
		"ERR_FOCUS_REQUIRED":
			return "This card needs FOCUS before it can resolve."
		"ERR_DISCARD_REQUIRED":
			return "This card needs more discard setup first."
		"ERR_STACK_EMPTY":
			return "This card needs a gem on the stack first."
		"ERR_STACK_TOP_MISMATCH":
			return "The top gem does not match this card."
		"ERR_STACK_TARGET_MISMATCH":
			return "The selected gem does not match this card."
		"ERR_SELECTOR_INVALID":
			return "The selected gem position is out of range."
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
	var instance_id: String = _hand_instance_id(previous_vm, hand_index)
	if instance_id == "":
		return true
	if _hand_play_reason(previous_vm, hand_index) != "":
		return true
	runner.player_play_card(instance_id)
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
	if button.disabled:
		return
	var instance_id: String = str(button.get_meta("instance_id", button.get_meta("card_id", "")))
	if instance_id == "":
		return
	_pulse_control(_card_face_target(button), 1.03, "hand_press:%s" % str(button.get_path()), 0.04, 0.08)
	runner.player_play_card(instance_id)

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
	_pulse_control(_card_face_target(button), 1.03, "reward_press:%s" % str(button.get_path()), 0.04, 0.08)
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
