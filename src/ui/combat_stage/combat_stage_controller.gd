extends Control
class_name CombatStageController

## Visual combat stage: arena with character portraits, hand fan overlay,
## gem stack icons, and compact event feed.
## Same refresh(vm) contract as the old CombatHudController.

## Colors and layout constants are sourced from UITheme (src/ui/theme.gd).

var _player_portrait_tex: Texture2D
var _enemy_portrait_tex: Texture2D
var _gem_ruby_tex: Texture2D
var _gem_sapphire_tex: Texture2D
var _art_strike: Texture2D
var _art_defend: Texture2D
var _art_utility: Texture2D
var _art_ruby: Texture2D
var _art_sapphire: Texture2D
var _art_focus: Texture2D
var _art_placeholder: Texture2D

var runner: Variant = null
var vm: Dictionary = {}
var previous_vm: Dictionary = {}
var hovered_card_index: int = -1

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_player_portrait_tex = _try_load("res://src/ui/combat_hud/assets/player_cat_steward_bust_128.png")
	_enemy_portrait_tex = _try_load("res://src/ui/combat_hud/assets/enemy_badger_warden_068.png")
	_gem_ruby_tex = _try_load("res://assets/generated/gems/obj_gem_ruby_token_md.png")
	_gem_sapphire_tex = _try_load("res://assets/generated/gems/obj_gem_sapphire_token_md.png")
	_art_strike = _try_load("res://assets/generated/cards/card_strike_cat_duelist_md.png")
	_art_defend = _try_load("res://assets/generated/cards/card_defend_badger_bulwark_md.png")
	_art_utility = _try_load("res://assets/generated/cards/card_scheme_seep_goblin_md.png")
	_art_ruby = _try_load("res://assets/generated/cards/card_ember_jab_ruby_md.png")
	_art_sapphire = _try_load("res://assets/generated/cards/card_ward_polish_sapphire_md.png")
	_art_focus = _try_load("res://assets/generated/cards/card_vault_focus_seal_md.png")
	_art_placeholder = _try_load("res://assets/generated/cards/placeholders/card_placeholder_steward_warrant_md.png")

static func _try_load(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	return null

func refresh(new_vm: Dictionary) -> void:
	previous_vm = vm.duplicate(true)
	vm = new_vm.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var arena_h: float = h * 0.55
	var hand_y: float = arena_h

	# Arena background
	draw_rect(Rect2(0, 0, w, arena_h), UITheme.ARENA_BG)
	draw_rect(Rect2(0, arena_h, w, h - arena_h), UITheme.PANEL_BG)

	# Arena divider line
	draw_line(Vector2(0, arena_h), Vector2(w, arena_h), UITheme.PANEL_BORDER, 2.0)

	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))
	if reward_state == CombatSliceRunner.REWARD_PRESENTED or reward_state == CombatSliceRunner.REWARD_APPLIED:
		_draw_reward_overlay(w, h)
	else:
		_draw_arena(w, arena_h)
		_draw_hand(w, h, hand_y)
		_draw_status_bar(w)
		_draw_gem_stack_icons(w, h)
		_draw_event_feed(w, arena_h)

func _draw_arena(w: float, arena_h: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var center_y: float = arena_h * 0.45
	var portrait_size := Vector2(128, 128)

	# Player (left side)
	var player_x: float = w * 0.2
	if _player_portrait_tex != null:
		draw_texture_rect(_player_portrait_tex, Rect2(Vector2(player_x - 64, center_y - 64), portrait_size), false)

	var player_hp: int = int(vm.get("player_hp", 0))
	var player_max: int = int(vm.get("player_max_hp", 40))
	var player_block: int = int(vm.get("player_block", 0))
	_draw_hp_bar(Vector2(player_x - 64, center_y + 72), 128.0, player_hp, player_max, UITheme.HP_PLAYER)
	draw_string(font, Vector2(player_x - 64, center_y + 100), "HP %d/%d" % [player_hp, player_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, UITheme.TEXT_PRIMARY)
	if player_block > 0:
		draw_string(font, Vector2(player_x - 64, center_y + 120), "Block %d" % player_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, UITheme.BLOCK_COLOR)

	# Enemy (right side)
	var enemy_x: float = w * 0.8
	if _enemy_portrait_tex != null:
		draw_texture_rect(_enemy_portrait_tex, Rect2(Vector2(enemy_x - 64, center_y - 64), portrait_size), false)

	var enemy_hp: int = int(vm.get("enemy_hp", 0))
	var enemy_max: int = int(vm.get("enemy_max_hp", 24))
	var enemy_block: int = int(vm.get("enemy_block", 0))
	_draw_hp_bar(Vector2(enemy_x - 64, center_y + 72), 128.0, enemy_hp, enemy_max, UITheme.HP_ENEMY)
	draw_string(font, Vector2(enemy_x - 64, center_y + 100), "HP %d/%d" % [enemy_hp, enemy_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, UITheme.TEXT_PRIMARY)
	if enemy_block > 0:
		draw_string(font, Vector2(enemy_x - 64, center_y + 120), "Block %d" % enemy_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, UITheme.BLOCK_COLOR)

	# Enemy intent (centered between portraits)
	var intent: Dictionary = vm.get("enemy_intent", {})
	var telegraph: String = str(intent.get("telegraph_text", ""))
	if telegraph == "":
		telegraph = "Intent: %d dmg" % int(vm.get("enemy_intent_damage", 0))
	var intent_x: float = w * 0.5
	var intent_y: float = center_y - 20
	draw_string(font, Vector2(intent_x - 150, intent_y), telegraph, HORIZONTAL_ALIGNMENT_CENTER, 300, 24, UITheme.TEXT_WARN)

	# Profile name below intent
	var profile: String = str(vm.get("pressure_profile_name", ""))
	if profile != "":
		draw_string(font, Vector2(intent_x - 100, intent_y + 30), profile, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, UITheme.TEXT_MUTED)

	# Encounter title at top of arena
	var title: String = str(vm.get("encounter_title", ""))
	if title != "":
		draw_string(font, Vector2(20, 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UITheme.TEXT_PRIMARY)

func _draw_hp_bar(pos: Vector2, bar_width: float, current: int, maximum: int, fill_color: Color) -> void:
	var bar_h: float = 12.0
	draw_rect(Rect2(pos, Vector2(bar_width, bar_h)), Color("#1a1520"))
	if maximum > 0:
		var fill_w: float = bar_width * clampf(float(current) / float(maximum), 0.0, 1.0)
		draw_rect(Rect2(pos, Vector2(fill_w, bar_h)), fill_color)

func _draw_hand(w: float, h: float, hand_y: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var hand: Array = vm.get("hand", [])
	var hand_card_ids: Array = vm.get("hand_card_ids", [])
	var hand_play_reasons: Array = vm.get("hand_play_reasons", [])
	var energy: int = int(vm.get("energy", 0))
	var max_energy: int = int(vm.get("turn_energy_max", 3))
	var card_count: int = hand.size()

	if card_count == 0:
		draw_string(font, Vector2(w * 0.5 - 60, hand_y + 80), "Hand empty", HORIZONTAL_ALIGNMENT_CENTER, 120, 20, UITheme.TEXT_MUTED)
		return

	# Calculate card positions for fan layout — cards overlap, centered
	var total_width: float = UITheme.CARD_WIDTH + float(card_count - 1) * UITheme.CARD_OVERLAP
	var start_x: float = (w - total_width) / 2.0
	var base_y: float = hand_y + 16.0

	for i in range(card_count):
		var card_x: float = start_x + float(i) * UITheme.CARD_OVERLAP
		var card_y: float = base_y
		var is_hovered: bool = i == hovered_card_index
		var card_id: String = str(hand_card_ids[i]) if i < hand_card_ids.size() else ""
		var instance_id: String = str(hand[i]) if i < hand.size() else ""
		var reject_reason: String = str(hand_play_reasons[i]) if i < hand_play_reasons.size() else ""
		var playable: bool = reject_reason == ""

		if is_hovered:
			card_y -= UITheme.CARD_HOVER_LIFT

		_draw_card(Vector2(card_x, card_y), card_id, instance_id, playable, is_hovered)

	# Energy counter
	var energy_text: String = "Energy %d/%d" % [energy, max_energy]
	draw_string(font, Vector2(w - 180, hand_y + UITheme.CARD_HEIGHT + 30), energy_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UITheme.ENERGY_COLOR)

	# Phase / combat result
	var phase: String = str(vm.get("ui_phase_text", ""))
	var result: String = str(vm.get("combat_result", CombatSliceRunner.RESULT_IN_PROGRESS))
	var phase_text: String = phase
	var phase_color: Color = UITheme.TEXT_MUTED
	if result == CombatSliceRunner.RESULT_PLAYER_WIN:
		phase_text = "VICTORY"
		phase_color = UITheme.TEXT_GOOD
	elif result == CombatSliceRunner.RESULT_PLAYER_LOSE:
		phase_text = "DEFEAT"
		phase_color = UITheme.TEXT_BAD
	draw_string(font, Vector2(20, hand_y + UITheme.CARD_HEIGHT + 30), phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, phase_color)

	# Pass button hint
	if result == CombatSliceRunner.RESULT_IN_PROGRESS:
		draw_string(font, Vector2(20, hand_y + UITheme.CARD_HEIGHT + 56), "SPACE = Pass Turn  |  R = Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UITheme.TEXT_MUTED)

func _draw_card(pos: Vector2, card_id: String, instance_id: String, playable: bool, hovered: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	var card_w: float = UITheme.CARD_WIDTH
	var card_h: float = UITheme.CARD_HEIGHT

	if hovered:
		card_w *= UITheme.CARD_HOVER_SCALE
		card_h *= UITheme.CARD_HOVER_SCALE

	var body_color: Color = UITheme.CARD_BODY if playable else UITheme.CARD_BODY_DISABLED
	var border_color: Color = _card_border_color(card_id)
	var title_h: float = card_h * 0.1
	var art_h: float = card_h * 0.35
	var rules_h: float = card_h * 0.35
	var footer_h: float = card_h * 0.1
	var cost_size: float = card_w * 0.14
	var padding: float = card_w * 0.05
	var inner_w: float = card_w - padding * 2

	# Card outer border
	draw_rect(Rect2(pos, Vector2(card_w, card_h)), border_color)
	# Card body inset
	draw_rect(Rect2(pos + Vector2(3, 3), Vector2(card_w - 6, card_h - 6)), body_color)

	# Title bar
	var title_rect := Rect2(pos + Vector2(3, 3), Vector2(card_w - 6, title_h))
	draw_rect(title_rect, UITheme.CARD_TITLE_BG)
	var display_name: String = _resolve_display_name(card_id)
	draw_string(font, pos + Vector2(padding + cost_size + 8, title_h * 0.7), display_name, HORIZONTAL_ALIGNMENT_LEFT, int(inner_w - cost_size - 8), int(title_h * 0.55), UITheme.CARD_TITLE_TEXT)

	# Cost badge (top-left circle)
	var cost_center := pos + Vector2(padding + cost_size * 0.5, 3 + title_h * 0.5)
	var cost: int = _resolve_cost(card_id)
	draw_circle(cost_center, cost_size * 0.5, UITheme.CARD_COST_BG)
	draw_string(font, cost_center + Vector2(-6, 6), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 12, int(cost_size * 0.6), UITheme.CARD_COST_TEXT)

	# Art area
	var art_rect := Rect2(pos + Vector2(padding, 3 + title_h + 4), Vector2(inner_w, art_h))
	draw_rect(art_rect, UITheme.CARD_ART_BG)
	# Load and draw card art thumbnail
	var art_tex: Texture2D = _resolve_card_art(card_id)
	if art_tex != null:
		draw_texture_rect(art_tex, art_rect, false)

	# Role marker badge
	var role: String = _resolve_role(card_id)
	if role != "":
		var role_y: float = art_rect.position.y + art_h + 6
		draw_string(font, pos + Vector2(padding, role_y + 14), role, HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), int(card_h * 0.04), UITheme.CARD_TEXT_MUTED)

	# Rules text area
	var rules_y: float = pos.y + 3 + title_h + art_h + 24
	var rules: String = _resolve_rules(card_id)
	if rules != "":
		# Wrap text manually by drawing multiple lines
		var line_h: float = card_h * 0.05
		var rules_font_size: int = int(card_h * 0.045)
		var lines: Array = rules.split(" \u2022 ")
		for li in range(lines.size()):
			draw_string(font, Vector2(pos.x + padding, rules_y + float(li) * (line_h + 4)), str(lines[li]).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), rules_font_size, UITheme.CARD_TEXT)

	# Footer — tooltip or locked state
	if not playable:
		var lock_y: float = pos.y + card_h - footer_h
		draw_rect(Rect2(Vector2(pos.x + 3, lock_y), Vector2(card_w - 6, footer_h - 3)), Color("#402020"))
		draw_string(font, Vector2(pos.x + padding, lock_y + footer_h * 0.6), "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), int(footer_h * 0.5), UITheme.TEXT_BAD)

func _resolve_display_name(card_id: String) -> String:
	if runner != null and runner.has_method("_display_name_for_card"):
		return str(runner.call("_display_name_for_card", card_id))
	return card_id.replace("_", " ").capitalize() if card_id != "" else "?"

func _resolve_cost(card_id: String) -> int:
	if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
		return int(runner.card_catalog.base_cost(card_id))
	return 1

func _resolve_rules(card_id: String) -> String:
	if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
		return str(runner.card_catalog.hand_rules_text(card_id))
	return ""

func _resolve_role(card_id: String) -> String:
	if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
		return str(runner.card_catalog.role_marker(card_id))
	return ""

func _resolve_card_art(card_id: String) -> Texture2D:
	var resolved: String = card_id
	if runner != null and runner.card_catalog != null:
		var r: String = str(runner.card_catalog.resolved_card_id(card_id))
		if r != "":
			resolved = r
	match resolved:
		"strike", "strike_plus", "strike_precise", "quick_slash":
			return _art_strike
		"defend", "defend_plus", "defend_hold", "heavy_guard":
			return _art_defend
		"scheme_flow", "steady_hand":
			return _art_utility
		"gem_produce_ruby", "gem_hybrid_ruby_strike", "gem_consume_top_ruby", "gem_offset_consume_ruby":
			return _art_ruby
		"gem_produce_sapphire", "gem_hybrid_sapphire_guard", "gem_hybrid_sapphire_burst", "gem_consume_top_sapphire", "gem_offset_consume_sapphire":
			return _art_sapphire
		"gem_focus", "gem_hybrid_focus_guard":
			return _art_focus
		_:
			return _art_placeholder

func _card_border_color(card_id: String) -> Color:
	var palette: String = "utility"
	if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
		palette = str(runner.card_catalog.palette_key(card_id))
	match palette:
		"attack":
			return UITheme.CARD_BORDER_ATTACK
		"defend":
			return UITheme.CARD_BORDER_DEFEND
		_:
			return UITheme.CARD_BORDER_UTILITY

func _draw_status_bar(w: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var turn: int = int(vm.get("turn", 0))
	var zones: Dictionary = vm.get("zones", {})
	var status: String = "Turn %d  |  Draw %d  |  Discard %d" % [
		turn,
		int(zones.get("draw", 0)),
		int(zones.get("discard", 0)),
	]
	draw_string(font, Vector2(w - 320, 30), status, HORIZONTAL_ALIGNMENT_RIGHT, 300, 16, UITheme.TEXT_MUTED)

func _draw_gem_stack_icons(w: float, h: float) -> void:
	var gem_stack: Array = vm.get("gem_stack", [])
	var gem_top: Array = vm.get("gem_stack_top", [])
	var focus: int = int(vm.get("focus", 0))
	var icon_size := Vector2(32, 32)
	var slot_size := Vector2(36, 36)
	var start_x: float = 20.0
	var y: float = h - 50.0

	# Draw gem icons for stack top
	var display_gems: Array = gem_top if not gem_top.is_empty() else gem_stack
	for i in range(display_gems.size()):
		var gem: String = str(display_gems[i])
		var tex: Texture2D = _gem_ruby_tex if gem == "Ruby" else _gem_sapphire_tex
		var x: float = start_x + float(i) * 40.0
		# Slot outline
		draw_rect(Rect2(Vector2(x - 2, y - 2), slot_size), UITheme.PANEL_BORDER, false, 1.5)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(x, y), icon_size), false)

	# Focus indicator
	var font: Font = ThemeDB.fallback_font
	if focus > 0:
		var focus_x: float = start_x + float(display_gems.size()) * 40.0 + 20.0
		draw_string(font, Vector2(focus_x, y + 22), "FOCUS %d" % focus, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UITheme.TEXT_ACCENT)

func _draw_event_feed(w: float, arena_h: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var events: Array = vm.get("recent_events", [])
	var x: float = w - 320.0
	var y: float = arena_h - 20.0
	for i in range(events.size()):
		var line: String = str(events[events.size() - 1 - i])
		if line.length() > 50:
			line = line.substr(0, 47) + "..."
		draw_string(font, Vector2(x, y - float(i) * 18.0), line, HORIZONTAL_ALIGNMENT_LEFT, 300, 13, UITheme.TEXT_MUTED)

func _draw_reward_overlay(w: float, h: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))

	# Scrim
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0, 0, 0, 0.75))

	# Title
	var title: String = "VICTORY — Choose a Reward"
	if reward_state == CombatSliceRunner.REWARD_APPLIED:
		title = "Card Added to Deck"
	draw_string(font, Vector2(w * 0.5 - 200, 60), title, HORIZONTAL_ALIGNMENT_CENTER, 400, 28, UITheme.TEXT_GOOD)

	# Subtitle
	var summary: String = str(vm.get("reward_summary_text", ""))
	if summary != "":
		draw_string(font, Vector2(w * 0.5 - 250, 100), summary, HORIZONTAL_ALIGNMENT_CENTER, 500, 18, UITheme.TEXT_MUTED)

	# Reward cards
	var offers: Array = vm.get("reward_offer", [])
	var selected: String = str(vm.get("reward_selected_card_id", ""))
	var card_w: float = 280.0
	var card_h: float = 380.0
	var gap: float = 30.0
	var total_w: float = float(offers.size()) * card_w + float(max(0, offers.size() - 1)) * gap
	var start_x: float = (w - total_w) / 2.0
	var card_y: float = 130.0

	for i in range(offers.size()):
		var offer: Dictionary = offers[i] if offers[i] is Dictionary else {}
		var card_id: String = str(offer.get("card_id", ""))
		var x: float = start_x + float(i) * (card_w + gap)
		var is_selected: bool = card_id == selected and selected != ""
		var is_pickable: bool = reward_state == CombatSliceRunner.REWARD_PRESENTED

		# Check hover
		var is_hovered: bool = false
		if _reward_hover_index == i:
			is_hovered = true

		# Card rendering
		var border: Color = _card_border_color(card_id)
		if is_selected:
			border = UITheme.TEXT_GOOD
		var body: Color = UITheme.CARD_BODY if is_pickable else UITheme.CARD_BODY_DISABLED
		var pos := Vector2(x, card_y)
		if is_hovered and is_pickable:
			pos.y -= 10.0

		# Border
		draw_rect(Rect2(pos, Vector2(card_w, card_h)), border)
		draw_rect(Rect2(pos + Vector2(3, 3), Vector2(card_w - 6, card_h - 6)), body)

		# Title bar
		var title_h: float = card_h * 0.1
		draw_rect(Rect2(pos + Vector2(3, 3), Vector2(card_w - 6, title_h)), UITheme.CARD_TITLE_BG)
		var name: String = _resolve_display_name(card_id)
		draw_string(font, pos + Vector2(12, title_h * 0.7), name, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24), int(title_h * 0.55), UITheme.CARD_TITLE_TEXT)

		# Cost badge
		var cost: int = _resolve_cost(card_id)
		draw_circle(pos + Vector2(card_w - 28, 3 + title_h * 0.5), 16.0, UITheme.CARD_COST_BG)
		draw_string(font, pos + Vector2(card_w - 34, 3 + title_h * 0.5 + 6), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 12, 14, UITheme.CARD_COST_TEXT)

		# Art area
		var art_rect := Rect2(pos + Vector2(12, title_h + 8), Vector2(card_w - 24, card_h * 0.35))
		var art_tex: Texture2D = _resolve_card_art(card_id)
		if art_tex != null:
			draw_texture_rect(art_tex, art_rect, false)
		else:
			draw_rect(art_rect, UITheme.CARD_ART_BG)

		# Rules text
		var rules: String = ""
		if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
			rules = str(runner.card_catalog.reward_rules_text(card_id))
		if rules != "":
			var rules_y: float = pos.y + title_h + card_h * 0.35 + 24
			var lines: Array = rules.split(" \u2022 ")
			for li in range(lines.size()):
				draw_string(font, Vector2(pos.x + 12, rules_y + float(li) * 22.0), str(lines[li]).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24), 15, UITheme.CARD_TEXT)

		# Selected badge
		if is_selected:
			draw_string(font, pos + Vector2(12, card_h - 20), "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24), 16, UITheme.TEXT_GOOD)

	# Continue prompt
	if reward_state == CombatSliceRunner.REWARD_APPLIED:
		draw_string(font, Vector2(w * 0.5 - 150, card_y + card_h + 50), "Press SPACE to continue", HORIZONTAL_ALIGNMENT_CENTER, 300, 20, UITheme.TEXT_ACCENT)

var _reward_hover_index: int = -1

func _gui_input(event: InputEvent) -> void:
	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))
	var in_reward: bool = reward_state == CombatSliceRunner.REWARD_PRESENTED or reward_state == CombatSliceRunner.REWARD_APPLIED

	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if in_reward:
			var new_rh: int = _reward_card_at_position(mm.position)
			if new_rh != _reward_hover_index:
				_reward_hover_index = new_rh
				queue_redraw()
		else:
			var new_hover: int = _card_at_position(mm.position)
			if new_hover != hovered_card_index:
				hovered_card_index = new_hover
				queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if in_reward and reward_state == CombatSliceRunner.REWARD_PRESENTED:
				var reward_idx: int = _reward_card_at_position(mb.position)
				if reward_idx >= 0 and runner != null:
					runner.choose_reward_by_index(reward_idx)
			elif not in_reward:
				var card_idx: int = _card_at_position(mb.position)
				if card_idx >= 0:
					_play_card_at_index(card_idx)

func _unhandled_input(event: InputEvent) -> void:
	if runner == null:
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			_handle_pass_or_continue()
		KEY_R:
			runner.reset_battle(13371337)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			var idx: int = int(key.keycode) - int(KEY_1)
			_play_card_at_index(idx)

func _handle_pass_or_continue() -> void:
	var result: String = str(vm.get("combat_result", CombatSliceRunner.RESULT_IN_PROGRESS))
	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))
	if result != CombatSliceRunner.RESULT_IN_PROGRESS:
		if reward_state == CombatSliceRunner.REWARD_PRESENTED:
			# Auto-pick first reward
			runner.choose_reward_by_index(0)
		elif reward_state == CombatSliceRunner.REWARD_APPLIED or reward_state == CombatSliceRunner.REWARD_CLOSED:
			runner.start_next_encounter()
		return
	runner.player_pass()

func _play_card_at_index(idx: int) -> void:
	if runner == null:
		return
	var hand: Array = vm.get("hand", [])
	if idx < 0 or idx >= hand.size():
		return
	var instance_id: String = str(hand[idx])
	runner.player_play_card(instance_id)

func _card_at_position(pos: Vector2) -> int:
	var hand: Array = vm.get("hand", [])
	var card_count: int = hand.size()
	if card_count == 0:
		return -1
	var w: float = size.x
	var arena_h: float = size.y * 0.55
	var hand_y: float = arena_h + 20.0
	var total_width: float = UITheme.CARD_WIDTH + float(card_count - 1) * UITheme.CARD_OVERLAP
	var start_x: float = (w - total_width) / 2.0

	# Check from rightmost card (topmost in draw order) to leftmost
	for i in range(card_count - 1, -1, -1):
		var card_x: float = start_x + float(i) * UITheme.CARD_OVERLAP
		var card_y: float = hand_y + 20.0
		if i == hovered_card_index:
			card_y -= UITheme.CARD_HOVER_LIFT
		var rect := Rect2(Vector2(card_x, card_y), Vector2(UITheme.CARD_WIDTH, UITheme.CARD_HEIGHT))
		if rect.has_point(pos):
			return i
	return -1

func _reward_card_at_position(pos: Vector2) -> int:
	var offers: Array = vm.get("reward_offer", [])
	if offers.is_empty():
		return -1
	var w: float = size.x
	var card_w: float = 280.0
	var card_h: float = 380.0
	var gap: float = 30.0
	var total_w: float = float(offers.size()) * card_w + float(max(0, offers.size() - 1)) * gap
	var start_x: float = (w - total_w) / 2.0
	var card_y: float = 130.0
	for i in range(offers.size() - 1, -1, -1):
		var x: float = start_x + float(i) * (card_w + gap)
		var rect := Rect2(Vector2(x, card_y), Vector2(card_w, card_h))
		if rect.has_point(pos):
			return i
	return -1

