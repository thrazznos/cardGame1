extends Control
class_name CombatStageController

## Visual combat stage: arena with character portraits, hand fan overlay,
## gem stack icons, and compact event feed.
## Same refresh(vm) contract as the old CombatHudController.

## Colors and layout constants are sourced from UITheme (src/ui/theme.gd).

var _player_portrait_tex: Texture2D
var _enemy_portrait_tex: Texture2D
var _crest_tex: Texture2D
var _reward_seal_tex: Texture2D
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

const REWARD_CARD_WIDTH: float = 308.0
const REWARD_CARD_HEIGHT: float = 418.0
const REWARD_CARD_GAP: float = 24.0
const REWARD_CARD_Y: float = 188.0
const REWARD_CARD_HOVER_LIFT: float = 14.0

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_player_portrait_tex = _try_load_first([
		"res://assets/generated/stage/player_cat_steward_polish_bust.png",
		"res://src/ui/combat_hud/assets/player_cat_steward_bust_128.png",
	])
	_enemy_portrait_tex = _try_load_first([
		"res://assets/generated/stage/enemy_badger_warden_polish_bust.png",
		"res://src/ui/combat_hud/assets/enemy_badger_warden_068.png",
	])
	_crest_tex = _try_load("res://src/ui/combat_hud/assets/banner_crest_steward_064.png")
	_reward_seal_tex = _try_load_first([
		"res://assets/generated/ui/reward/reward_seal_steward_polish.png",
		"res://src/ui/combat_hud/assets/reward_wax_seal_centered_112.png",
	])
	_gem_ruby_tex = _try_load("res://assets/generated/gems/obj_gem_ruby_token_md.png")
	_gem_sapphire_tex = _try_load("res://assets/generated/gems/obj_gem_sapphire_token_md.png")
	_art_strike = _try_load("res://assets/generated/cards/card_strike_cat_duelist_md.png")
	_art_defend = _try_load("res://assets/generated/cards/card_defend_badger_bulwark_md.png")
	_art_utility = _try_load_first([
		"res://assets/generated/cards/card_scheme_seep_goblin_polish_md.png",
		"res://assets/generated/cards/card_scheme_seep_goblin_md.png",
	])
	_art_ruby = _try_load("res://assets/generated/cards/card_ember_jab_ruby_md.png")
	_art_sapphire = _try_load("res://assets/generated/cards/card_ward_polish_sapphire_md.png")
	_art_focus = _try_load_first([
		"res://assets/generated/cards/card_vault_focus_seal_polish_md.png",
		"res://assets/generated/cards/card_vault_focus_seal_md.png",
	])
	_art_placeholder = _try_load("res://assets/generated/cards/placeholders/card_placeholder_steward_warrant_md.png")

static func _try_load(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	return null

static func _try_load_first(paths: Array) -> Texture2D:
	for raw_path in paths:
		var path: String = str(raw_path)
		var tex: Texture2D = _try_load(path)
		if tex != null:
			return tex
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
	draw_circle(Vector2(w * 0.22, arena_h * 0.40), arena_h * 0.40, UITheme.ARENA_SPOTLIGHT_PLAYER)
	draw_circle(Vector2(w * 0.78, arena_h * 0.38), arena_h * 0.36, UITheme.ARENA_SPOTLIGHT_ENEMY)
	draw_circle(Vector2(w * 0.50, arena_h * 0.28), arena_h * 0.24, UITheme.ARENA_SPOTLIGHT_CENTER)
	draw_rect(Rect2(0, arena_h, w, h - arena_h), UITheme.PANEL_BG)
	draw_rect(Rect2(0, arena_h, w, h - arena_h), Color(1, 1, 1, 0.02))

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
	var portrait_size := Vector2(160, 160)

	# Player (left side)
	var player_x: float = w * 0.2
	_draw_portrait_mount(Vector2(player_x, center_y), portrait_size, _player_portrait_tex, UITheme.CARD_BORDER_ATTACK)

	var player_hp: int = int(vm.get("player_hp", 0))
	var player_max: int = int(vm.get("player_max_hp", 40))
	var player_block: int = int(vm.get("player_block", 0))
	_draw_hp_bar(Vector2(player_x - 64, center_y + 72), 128.0, player_hp, player_max, UITheme.HP_PLAYER)
	draw_string(font, Vector2(player_x - 64, center_y + 100), "HP %d/%d" % [player_hp, player_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, UITheme.TEXT_PRIMARY)
	if player_block > 0:
		draw_string(font, Vector2(player_x - 64, center_y + 120), "Block %d" % player_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, UITheme.BLOCK_COLOR)

	# Enemy (right side)
	var enemy_x: float = w * 0.8
	_draw_portrait_mount(Vector2(enemy_x, center_y), portrait_size, _enemy_portrait_tex, UITheme.CARD_BORDER_DEFEND)

	var enemy_hp: int = int(vm.get("enemy_hp", 0))
	var enemy_max: int = int(vm.get("enemy_max_hp", 24))
	var enemy_block: int = int(vm.get("enemy_block", 0))
	_draw_hp_bar(Vector2(enemy_x - 64, center_y + 72), 128.0, enemy_hp, enemy_max, UITheme.HP_ENEMY)
	draw_string(font, Vector2(enemy_x - 64, center_y + 100), "HP %d/%d" % [enemy_hp, enemy_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, UITheme.TEXT_PRIMARY)
	if enemy_block > 0:
		draw_string(font, Vector2(enemy_x - 64, center_y + 120), "Block %d" % enemy_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, UITheme.BLOCK_COLOR)

	# Player statuses below HP
	var player_statuses: Array = vm.get("player_statuses", [])
	_draw_status_strip(Vector2(player_x - 64, center_y + 138), player_statuses, font)

	# Enemy statuses below HP
	var enemy_statuses_arr: Array = vm.get("enemy_statuses", [])
	_draw_status_strip(Vector2(enemy_x - 64, center_y + 138), enemy_statuses_arr, font)

	# Enemy intent (centered between portraits)
	var intent: Dictionary = vm.get("enemy_intent", {})
	var telegraph: String = str(intent.get("telegraph_text", ""))
	if telegraph == "":
		telegraph = "Intent: %d dmg" % int(vm.get("enemy_intent_damage", 0))
	var intent_x: float = w * 0.5
	var intent_y: float = center_y - 20
	_draw_intent_banner(Vector2(intent_x, intent_y - 8), telegraph, font)
	draw_line(Vector2(intent_x + 170, intent_y + 2), Vector2(enemy_x - 92, center_y - 6), Color(UITheme.TEXT_WARN.r, UITheme.TEXT_WARN.g, UITheme.TEXT_WARN.b, 0.38), 2.0)

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
	draw_rect(Rect2(pos, Vector2(bar_width, bar_h)), UITheme.PANEL_BG)
	if maximum > 0:
		var fill_w: float = bar_width * clampf(float(current) / float(maximum), 0.0, 1.0)
		draw_rect(Rect2(pos, Vector2(fill_w, bar_h)), fill_color)

func _draw_portrait_mount(center: Vector2, portrait_size: Vector2, tex: Texture2D, accent_color: Color) -> void:
	var halo_radius: float = max(portrait_size.x, portrait_size.y) * 0.72
	draw_circle(center + Vector2(0, 6), halo_radius, Color(0, 0, 0, 0.20))
	draw_circle(center, halo_radius, Color(accent_color.r, accent_color.g, accent_color.b, 0.14))
	draw_circle(center, halo_radius - 10.0, Color(0.08, 0.07, 0.11, 0.88))
	draw_circle(center, halo_radius - 16.0, accent_color)
	draw_circle(center, halo_radius - 20.0, UITheme.PANEL_BG)
	if tex != null:
		draw_texture_rect(tex, Rect2(center - portrait_size * 0.5, portrait_size), false)

func _draw_intent_banner(center: Vector2, telegraph: String, font: Font) -> void:
	var box_size := Vector2(340, 42)
	var box_pos := center - box_size * 0.5
	draw_rect(Rect2(box_pos, box_size), Color(0.10, 0.08, 0.12, 0.86))
	draw_rect(Rect2(box_pos, box_size), UITheme.TEXT_WARN, false, 2.0)
	if _crest_tex != null:
		draw_texture_rect(_crest_tex, Rect2(box_pos + Vector2(10, 5), Vector2(32, 32)), false)
	draw_string(font, box_pos + Vector2(52, 28), telegraph, HORIZONTAL_ALIGNMENT_LEFT, int(box_size.x - 64), 22, UITheme.TEXT_WARN)

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

	var hovered_payload: Dictionary = {}
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
			hovered_payload = {
				"pos": Vector2(card_x, card_y),
				"card_id": card_id,
				"instance_id": instance_id,
				"playable": playable,
				"reject_reason": reject_reason,
			}
			continue

		_draw_card(Vector2(card_x, card_y), card_id, instance_id, playable, false, reject_reason)

	if not hovered_payload.is_empty():
		_draw_card(
			hovered_payload.get("pos", Vector2.ZERO),
			str(hovered_payload.get("card_id", "")),
			str(hovered_payload.get("instance_id", "")),
			bool(hovered_payload.get("playable", false)),
			true,
			str(hovered_payload.get("reject_reason", ""))
		)

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

func _draw_card(pos: Vector2, card_id: String, instance_id: String, playable: bool, hovered: bool, reject_reason: String = "") -> void:
	var font: Font = ThemeDB.fallback_font
	var card_w: float = UITheme.CARD_WIDTH
	var card_h: float = UITheme.CARD_HEIGHT
	var draw_pos: Vector2 = pos

	if hovered:
		card_w *= UITheme.CARD_HOVER_SCALE
		card_h *= UITheme.CARD_HOVER_SCALE
		draw_pos.x -= (card_w - UITheme.CARD_WIDTH) * 0.5
		draw_pos.y -= (card_h - UITheme.CARD_HEIGHT)

	var body_color: Color = UITheme.CARD_BODY if playable else UITheme.CARD_BODY_DISABLED
	var border_color: Color = _card_border_color(card_id)
	if hovered:
		border_color = border_color.lightened(0.18)
	var title_h: float = card_h * 0.1
	var art_h: float = card_h * 0.35
	var footer_h: float = card_h * 0.1
	var cost_size: float = card_w * 0.14
	var padding: float = card_w * 0.05
	var inner_w: float = card_w - padding * 2
	var shadow_offset := Vector2(12, 14 if hovered else 10)

	# Card shadow and hover glow
	draw_rect(Rect2(draw_pos + shadow_offset, Vector2(card_w, card_h)), UITheme.CARD_SHADOW)
	if hovered:
		draw_rect(Rect2(draw_pos + Vector2(-6, -8), Vector2(card_w + 12, card_h + 14)), UITheme.CARD_HOVER_GLOW)

	# Card outer border
	draw_rect(Rect2(draw_pos, Vector2(card_w, card_h)), border_color)
	# Card body inset
	draw_rect(Rect2(draw_pos + Vector2(3, 3), Vector2(card_w - 6, card_h - 6)), body_color)
	if hovered:
		draw_rect(Rect2(draw_pos + Vector2(8, 8), Vector2(card_w - 16, card_h * 0.18)), Color(1, 1, 1, 0.05))

	# Title bar
	var title_rect := Rect2(draw_pos + Vector2(3, 3), Vector2(card_w - 6, title_h))
	draw_rect(title_rect, UITheme.CARD_TITLE_BG)
	var display_name: String = _resolve_display_name(card_id)
	draw_string(font, draw_pos + Vector2(padding + cost_size + 8, title_h * 0.7), display_name, HORIZONTAL_ALIGNMENT_LEFT, int(inner_w - cost_size - 8), int(title_h * 0.55), UITheme.CARD_TITLE_TEXT)

	# Cost badge (top-left circle)
	var cost_center := draw_pos + Vector2(padding + cost_size * 0.5, 3 + title_h * 0.5)
	var cost: int = _resolve_cost(card_id)
	draw_circle(cost_center, cost_size * 0.5, UITheme.CARD_COST_BG)
	draw_string(font, cost_center + Vector2(-6, 6), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 12, int(cost_size * 0.6), UITheme.CARD_COST_TEXT)

	# Art area
	var art_rect := Rect2(draw_pos + Vector2(padding, 3 + title_h + 4), Vector2(inner_w, art_h))
	draw_rect(art_rect, UITheme.CARD_ART_BG)
	var art_tex: Texture2D = _resolve_card_art(card_id)
	if art_tex != null:
		draw_texture_rect(art_tex, art_rect, false)
	if hovered:
		draw_rect(Rect2(art_rect.position, Vector2(art_rect.size.x, art_rect.size.y * 0.28)), Color(1, 1, 1, 0.08))

	# Role marker badge
	var role: String = _resolve_role(card_id)
	if role != "":
		var role_y: float = art_rect.position.y + art_h + 6
		draw_rect(Rect2(Vector2(draw_pos.x + padding, role_y), Vector2(min(110.0, inner_w * 0.45), 20)), Color(0.17, 0.14, 0.19, 0.88))
		draw_string(font, draw_pos + Vector2(padding + 8, role_y + 14), role, HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), int(card_h * 0.04), UITheme.CARD_TEXT_MUTED)

	# Rules text area
	var rules_y: float = draw_pos.y + 3 + title_h + art_h + 24
	var rules: String = _resolve_rules(card_id)
	if rules != "":
		var line_h: float = card_h * 0.05
		var rules_font_size: int = int(card_h * 0.045)
		var lines: Array = rules.split(" • ")
		for li in range(lines.size()):
			draw_string(font, Vector2(draw_pos.x + padding, rules_y + float(li) * (line_h + 4)), str(lines[li]).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), rules_font_size, UITheme.CARD_TEXT)

	# Footer — locked state / legality hint
	if not playable:
		var lock_y: float = draw_pos.y + card_h - footer_h
		draw_rect(Rect2(Vector2(draw_pos.x + 3, lock_y), Vector2(card_w - 6, footer_h - 3)), UITheme.CARD_FOOTER_LOCKED)
		var footer_text: String = "LOCKED"
		if hovered and reject_reason != "":
			footer_text = _readable_reject_reason(reject_reason)
		draw_string(font, Vector2(draw_pos.x + padding, lock_y + footer_h * 0.6), footer_text, HORIZONTAL_ALIGNMENT_LEFT, int(inner_w), int(footer_h * 0.42), UITheme.TEXT_BAD)

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

func _readable_reject_reason(reason: String) -> String:
	match reason:
		"ERR_NOT_ENOUGH_ENERGY":
			return "Need more energy"
		"ERR_FOCUS_REQUIRED":
			return "Need FOCUS"
		"ERR_DISCARD_REQUIRED":
			return "Need discard"
		"ERR_SELF_TARGET_REQUIRED":
			return "Target yourself"
		"ERR_ENEMY_TARGET_REQUIRED":
			return "Need enemy target"
		"ERR_CARD_NOT_IN_HAND":
			return "Not in hand"
		_:
			return reason.replace("ERR_", "").replace("_", " ").capitalize()

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

func _draw_status_strip(pos: Vector2, statuses: Array, font: Font) -> void:
	if statuses.is_empty():
		return
	var x_offset: float = 0.0
	for status in statuses:
		if not (status is Dictionary):
			continue
		var name: String = str(status.get("display_name", str(status.get("effect_id", "?"))))
		var stacks: int = int(status.get("stacks", 0))
		var duration: int = int(status.get("duration", 0))
		var is_debuff: bool = bool(status.get("is_debuff", false))
		var color: Color = UITheme.TEXT_BAD if is_debuff else UITheme.TEXT_GOOD
		var bg: Color = Color(0.14, 0.12, 0.18, 0.90) if is_debuff else Color(0.12, 0.15, 0.13, 0.90)
		var label: String = "%s %d" % [name, stacks] if stacks > 1 else name
		if duration > 0:
			label += " (%dt)" % duration
		var pill_width: float = max(62.0, min(132.0, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 18.0))
		draw_rect(Rect2(pos + Vector2(x_offset, -12), Vector2(pill_width, 18)), bg)
		draw_rect(Rect2(pos + Vector2(x_offset, -12), Vector2(pill_width, 18)), Color(color.r, color.g, color.b, 0.55), false, 1.0)
		draw_string(font, pos + Vector2(x_offset + 8, 1), label, HORIZONTAL_ALIGNMENT_LEFT, int(pill_width - 10.0), 13, color)
		x_offset += pill_width + 8.0

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

func _event_feed_panel_rect(w: float, arena_h: float) -> Rect2:
	var panel_size := Vector2(356, 148)
	var panel_pos := Vector2(w - panel_size.x - 18.0, arena_h - panel_size.y - 18.0)
	return Rect2(panel_pos, panel_size)

func _event_feed_entries(limit: int = 3) -> Array:
	var events: Array = vm.get("recent_events", [])
	var entries: Array = []
	for i in range(min(events.size(), limit)):
		var raw_line: String = str(events[events.size() - 1 - i])
		var split: Dictionary = _event_feed_split(raw_line)
		var is_primary: bool = i == 0
		var body: String = _event_feed_truncate(str(split.get("body", raw_line)), 72 if is_primary else 64)
		entries.append({
			"badge": str(split.get("badge", "")),
			"text": body,
			"tone": _event_feed_tone(body),
			"is_primary": is_primary,
		})
	return entries

func _event_feed_split(raw_line: String) -> Dictionary:
	var trimmed: String = raw_line.strip_edges()
	if trimmed.begins_with("#"):
		var split_index: int = trimmed.find(" ")
		if split_index > 0:
			return {
				"badge": trimmed.substr(0, split_index),
				"body": trimmed.substr(split_index + 1).strip_edges(),
			}
	return {
		"badge": "",
		"body": trimmed,
	}

func _event_feed_truncate(text_value: String, max_length: int) -> String:
	var trimmed: String = text_value.strip_edges()
	if trimmed.length() <= max_length:
		return trimmed
	return "%s…" % trimmed.substr(0, max_length - 1).strip_edges()

func _event_feed_tone(text_value: String) -> String:
	var lowered: String = text_value.to_lower()
	if lowered.find("can't play") != -1 or lowered.find("failed") != -1 or lowered.find("no living target") != -1 or lowered.find("needs ") != -1 or lowered.find("rejected") != -1 or lowered.find("not available") != -1 or lowered.find("invalid reward") != -1:
		return "bad"
	if lowered.find("reward checkpoint opened") != -1 or lowered.find("reward claimed") != -1 or lowered.find("player_win") != -1 or lowered.find("claimed") != -1:
		return "good"
	if lowered.find("enemy") != -1 or lowered.find("passed turn") != -1:
		return "warn"
	return "neutral"

func _event_feed_text_color(tone: String, is_primary: bool) -> Color:
	match tone:
		"bad":
			return UITheme.TEXT_BAD if is_primary else Color(UITheme.TEXT_BAD.r, UITheme.TEXT_BAD.g, UITheme.TEXT_BAD.b, 0.92)
		"good":
			return UITheme.TEXT_GOOD if is_primary else Color(UITheme.TEXT_GOOD.r, UITheme.TEXT_GOOD.g, UITheme.TEXT_GOOD.b, 0.90)
		"warn":
			return UITheme.TEXT_WARN if is_primary else Color(UITheme.TEXT_WARN.r, UITheme.TEXT_WARN.g, UITheme.TEXT_WARN.b, 0.90)
		_:
			return UITheme.TEXT_PRIMARY if is_primary else UITheme.TEXT_MUTED

func _event_feed_row_bg(tone: String, is_primary: bool) -> Color:
	var base_color: Color = _event_feed_text_color(tone, true)
	var alpha: float = 0.14 if is_primary else 0.08
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func _event_feed_badge_bg(tone: String, is_primary: bool) -> Color:
	var base_color: Color = _event_feed_text_color(tone, true)
	var alpha: float = 0.26 if is_primary else 0.18
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func _event_feed_entry_at(entries: Array, index: int) -> Dictionary:
	if index < 0 or index >= entries.size() or not (entries[index] is Dictionary):
		return {}
	return entries[index]

func _debug_event_feed_snapshot() -> Dictionary:
	var panel_rect: Rect2 = _event_feed_panel_rect(size.x, size.y * 0.55)
	var entries: Array = _event_feed_entries()
	var latest: Dictionary = _event_feed_entry_at(entries, 0)
	var reward_entry: Dictionary = _event_feed_entry_at(entries, 1)
	var resolve_entry: Dictionary = _event_feed_entry_at(entries, 2)
	return {
		"panel_width": int(panel_rect.size.x),
		"panel_height": int(panel_rect.size.y),
		"row_count": entries.size(),
		"latest_badge": str(latest.get("badge", "")),
		"latest_text": str(latest.get("text", "")),
		"latest_text_length": str(latest.get("text", "")).length(),
		"latest_tone": str(latest.get("tone", "")),
		"latest_is_primary": bool(latest.get("is_primary", false)),
		"reward_badge": str(reward_entry.get("badge", "")),
		"reward_text": str(reward_entry.get("text", "")),
		"reward_text_length": str(reward_entry.get("text", "")).length(),
		"reward_tone": str(reward_entry.get("tone", "")),
		"reward_is_primary": bool(reward_entry.get("is_primary", false)),
		"resolve_text": str(resolve_entry.get("text", "")),
		"resolve_tone": str(resolve_entry.get("tone", "")),
	}

func _draw_event_feed(w: float, arena_h: float) -> void:
	var entries: Array = _event_feed_entries()
	if entries.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var panel_rect: Rect2 = _event_feed_panel_rect(w, arena_h)
	var panel_pos: Vector2 = panel_rect.position
	var panel_size: Vector2 = panel_rect.size
	draw_rect(panel_rect, UITheme.FEED_PANEL_BG)
	draw_rect(panel_rect, UITheme.FEED_PANEL_BORDER, false, 2.0)
	draw_rect(Rect2(panel_pos + Vector2(10, 30), Vector2(panel_size.x - 20, panel_size.y - 40)), Color(1, 1, 1, 0.02))
	draw_string(font, panel_pos + Vector2(12, 22), "Recent", HORIZONTAL_ALIGNMENT_LEFT, 120, 17, UITheme.TEXT_ACCENT)
	draw_string(font, panel_pos + Vector2(panel_size.x - 74, 22), "Latest", HORIZONTAL_ALIGNMENT_RIGHT, 62, 14, UITheme.TEXT_MUTED)
	var line_y: float = panel_pos.y + 52.0
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var is_primary: bool = bool(entry.get("is_primary", false))
		var tone: String = str(entry.get("tone", "neutral"))
		var row_height: float = 32.0 if is_primary else 24.0
		var row_rect := Rect2(Vector2(panel_pos.x + 10.0, line_y - 18.0), Vector2(panel_size.x - 20.0, row_height))
		var row_bg: Color = _event_feed_row_bg(tone, is_primary)
		var line_color: Color = _event_feed_text_color(tone, is_primary)
		draw_rect(row_rect, row_bg)
		draw_rect(row_rect, Color(line_color.r, line_color.g, line_color.b, 0.18 if is_primary else 0.10), false, 1.0)
		var text_x: float = row_rect.position.x + 10.0
		var badge: String = str(entry.get("badge", ""))
		if badge != "":
			var badge_rect := Rect2(Vector2(row_rect.position.x + 8.0, row_rect.position.y + (6.0 if is_primary else 4.0)), Vector2(34.0, 18.0 if not is_primary else 20.0))
			draw_rect(badge_rect, _event_feed_badge_bg(tone, is_primary))
			draw_rect(badge_rect, Color(line_color.r, line_color.g, line_color.b, 0.28), false, 1.0)
			draw_string(font, badge_rect.position + Vector2(5, 14 if not is_primary else 15), badge, HORIZONTAL_ALIGNMENT_LEFT, 26, 13 if not is_primary else 14, UITheme.TEXT_PRIMARY)
			text_x = badge_rect.position.x + badge_rect.size.x + 10.0
		draw_string(font, Vector2(text_x, line_y), str(entry.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, int(panel_rect.end.x - text_x - 12.0), 16 if is_primary else 14, line_color)
		line_y += row_height + (6.0 if is_primary else 4.0)

func _draw_reward_overlay(w: float, h: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))

	# Scrim + framed panel
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0, 0, 0, 0.78))
	var panel_rect := Rect2(Vector2(w * 0.08, 26), Vector2(w * 0.84, h - 52))
	draw_rect(panel_rect, UITheme.CARD_REWARD_PANEL_BG)
	draw_rect(panel_rect, UITheme.CARD_REWARD_PANEL_BORDER, false, 2.0)
	if _reward_seal_tex != null:
		draw_circle(Vector2(w * 0.5, 76), 58.0, Color(0.86, 0.74, 0.34, 0.12))
		draw_texture_rect(_reward_seal_tex, Rect2(Vector2(w * 0.5 - 56, 20), Vector2(112, 112)), false)

	# Title
	var title: String = "VICTORY — Choose a Reward"
	if reward_state == CombatSliceRunner.REWARD_APPLIED:
		title = "Card Added to Deck"
	draw_string(font, Vector2(w * 0.5 - 220, 86), title, HORIZONTAL_ALIGNMENT_CENTER, 440, 28, UITheme.TEXT_GOOD)

	# Subtitle
	var summary: String = str(vm.get("reward_summary_text", ""))
	if summary == "" and reward_state == CombatSliceRunner.REWARD_PRESENTED:
		summary = "Hover a card for a closer look, then click to draft it."
	if summary != "":
		draw_string(font, Vector2(w * 0.5 - 260, 116), summary, HORIZONTAL_ALIGNMENT_CENTER, 520, 18, UITheme.TEXT_MUTED)

	# Reward cards
	var offers: Array = vm.get("reward_offer", [])
	var selected: String = str(vm.get("reward_selected_card_id", ""))
	var reward_layout: Dictionary = _reward_card_layout(offers.size())
	var card_w: float = float(reward_layout.get("card_w", REWARD_CARD_WIDTH))
	var card_h: float = float(reward_layout.get("card_h", REWARD_CARD_HEIGHT))
	var gap: float = float(reward_layout.get("gap", REWARD_CARD_GAP))
	var start_x: float = float(reward_layout.get("start_x", 0.0))
	var card_y: float = float(reward_layout.get("card_y", REWARD_CARD_Y))

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
		elif is_hovered:
			border = border.lightened(0.16)
		var body: Color = UITheme.CARD_BODY if is_pickable else UITheme.CARD_BODY_DISABLED
		var pos := Vector2(x, card_y)
		if is_hovered and is_pickable:
			pos.y -= REWARD_CARD_HOVER_LIFT

		# Shadow + border
		draw_rect(Rect2(pos + Vector2(10, 12), Vector2(card_w, card_h)), UITheme.CARD_SHADOW)
		if is_hovered:
			draw_rect(Rect2(pos + Vector2(-6, -6), Vector2(card_w + 12, card_h + 12)), UITheme.CARD_HOVER_GLOW)
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
		if is_hovered:
			draw_rect(Rect2(art_rect.position, Vector2(art_rect.size.x, art_rect.size.y * 0.26)), Color(1, 1, 1, 0.07))

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

func _hand_card_rect(card_index: int, card_count: int) -> Rect2:
	var total_width: float = UITheme.CARD_WIDTH + float(card_count - 1) * UITheme.CARD_OVERLAP
	var start_x: float = (size.x - total_width) / 2.0
	var card_x: float = start_x + float(card_index) * UITheme.CARD_OVERLAP
	var card_y: float = size.y * 0.55 + 16.0
	var card_w: float = UITheme.CARD_WIDTH
	var card_h: float = UITheme.CARD_HEIGHT
	if card_index == hovered_card_index:
		card_y -= UITheme.CARD_HOVER_LIFT
		card_w *= UITheme.CARD_HOVER_SCALE
		card_h *= UITheme.CARD_HOVER_SCALE
		card_x -= (card_w - UITheme.CARD_WIDTH) * 0.5
		card_y -= (card_h - UITheme.CARD_HEIGHT)
	return Rect2(Vector2(card_x, card_y), Vector2(card_w, card_h))

func _card_at_position(pos: Vector2) -> int:
	var hand: Array = vm.get("hand", [])
	var card_count: int = hand.size()
	if card_count == 0:
		return -1

	if hovered_card_index >= 0 and hovered_card_index < card_count:
		var hovered_rect := _hand_card_rect(hovered_card_index, card_count)
		if hovered_rect.has_point(pos):
			return hovered_card_index

	# Check remaining cards from rightmost to leftmost, matching normal draw order.
	for i in range(card_count - 1, -1, -1):
		if i == hovered_card_index:
			continue
		var rect := _hand_card_rect(i, card_count)
		if rect.has_point(pos):
			return i
	return -1

func _reward_card_layout(offer_count: int) -> Dictionary:
	var total_w: float = float(offer_count) * REWARD_CARD_WIDTH + float(max(0, offer_count - 1)) * REWARD_CARD_GAP
	return {
		"card_w": REWARD_CARD_WIDTH,
		"card_h": REWARD_CARD_HEIGHT,
		"gap": REWARD_CARD_GAP,
		"card_y": REWARD_CARD_Y,
		"start_x": (size.x - total_w) / 2.0,
	}

func _reward_card_at_position(pos: Vector2) -> int:
	var offers: Array = vm.get("reward_offer", [])
	if offers.is_empty():
		return -1
	var reward_layout: Dictionary = _reward_card_layout(offers.size())
	var card_w: float = float(reward_layout.get("card_w", REWARD_CARD_WIDTH))
	var card_h: float = float(reward_layout.get("card_h", REWARD_CARD_HEIGHT))
	var gap: float = float(reward_layout.get("gap", REWARD_CARD_GAP))
	var start_x: float = float(reward_layout.get("start_x", 0.0))
	var card_y: float = float(reward_layout.get("card_y", REWARD_CARD_Y))
	var reward_state: String = str(vm.get("reward_state", CombatSliceRunner.REWARD_NONE))
	for i in range(offers.size() - 1, -1, -1):
		var x: float = start_x + float(i) * (card_w + gap)
		var y: float = card_y
		if reward_state == CombatSliceRunner.REWARD_PRESENTED and i == _reward_hover_index:
			y -= REWARD_CARD_HOVER_LIFT
		var rect := Rect2(Vector2(x, y), Vector2(card_w, card_h))
		if rect.has_point(pos):
			return i
	return -1

