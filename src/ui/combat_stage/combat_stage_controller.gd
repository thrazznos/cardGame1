extends Control
class_name CombatStageController

## Visual combat stage: arena with character portraits, hand fan overlay,
## gem stack icons, and compact event feed.
## Same refresh(vm) contract as the old CombatHudController.

const PANEL_BG := Color("#1a1520")
const PANEL_BORDER := Color("#4b3860")
const ARENA_BG := Color("#0e0a14")
const TEXT_PRIMARY := Color("#fffdf5")
const TEXT_MUTED := Color("#a0a8b8")
const TEXT_ACCENT := Color("#60d0ff")
const TEXT_GOOD := Color("#70e870")
const TEXT_WARN := Color("#ffd36a")
const TEXT_BAD := Color("#ff6666")
const HP_PLAYER := Color("#50c860")
const HP_ENEMY := Color("#e05050")
const ENERGY_COLOR := Color("#60a0e0")
const BLOCK_COLOR := Color("#60d0ff")
const CARD_BG := Color("#eadfc7")
const CARD_BG_DISABLED := Color("#707070")
const CARD_BORDER := Color("#5a4733")
const CARD_TEXT := Color("#2c2218")
const CARD_WIDTH := 160.0
const CARD_HEIGHT := 220.0
const CARD_OVERLAP := 100.0
const CARD_HOVER_LIFT := 40.0
const CARD_HOVER_SCALE := 1.25

const PLAYER_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/player_cat_steward_bust_128.png"
const ENEMY_PORTRAIT_PATH := "res://src/ui/combat_hud/assets/enemy_badger_warden_068.png"
const GEM_RUBY_PATH := "res://assets/generated/gems/obj_gem_ruby_token_md.png"
const GEM_SAPPHIRE_PATH := "res://assets/generated/gems/obj_gem_sapphire_token_md.png"

var runner: Variant = null
var vm: Dictionary = {}
var previous_vm: Dictionary = {}
var hovered_card_index: int = -1
var player_portrait_tex: Texture2D = null
var enemy_portrait_tex: Texture2D = null
var gem_ruby_tex: Texture2D = null
var gem_sapphire_tex: Texture2D = null

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	player_portrait_tex = _load_tex(PLAYER_PORTRAIT_PATH)
	enemy_portrait_tex = _load_tex(ENEMY_PORTRAIT_PATH)
	gem_ruby_tex = _load_tex(GEM_RUBY_PATH)
	gem_sapphire_tex = _load_tex(GEM_SAPPHIRE_PATH)

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
	draw_rect(Rect2(0, 0, w, arena_h), ARENA_BG)
	draw_rect(Rect2(0, arena_h, w, h - arena_h), PANEL_BG)

	# Arena divider line
	draw_line(Vector2(0, arena_h), Vector2(w, arena_h), PANEL_BORDER, 2.0)

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
	if player_portrait_tex != null:
		draw_texture_rect(player_portrait_tex, Rect2(Vector2(player_x - 64, center_y - 64), portrait_size), false)

	var player_hp: int = int(vm.get("player_hp", 0))
	var player_max: int = int(vm.get("player_max_hp", 40))
	var player_block: int = int(vm.get("player_block", 0))
	_draw_hp_bar(Vector2(player_x - 64, center_y + 72), 128.0, player_hp, player_max, HP_PLAYER)
	draw_string(font, Vector2(player_x - 64, center_y + 100), "HP %d/%d" % [player_hp, player_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, TEXT_PRIMARY)
	if player_block > 0:
		draw_string(font, Vector2(player_x - 64, center_y + 120), "Block %d" % player_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, BLOCK_COLOR)

	# Enemy (right side)
	var enemy_x: float = w * 0.8
	if enemy_portrait_tex != null:
		draw_texture_rect(enemy_portrait_tex, Rect2(Vector2(enemy_x - 64, center_y - 64), portrait_size), false)

	var enemy_hp: int = int(vm.get("enemy_hp", 0))
	var enemy_max: int = int(vm.get("enemy_max_hp", 24))
	var enemy_block: int = int(vm.get("enemy_block", 0))
	_draw_hp_bar(Vector2(enemy_x - 64, center_y + 72), 128.0, enemy_hp, enemy_max, HP_ENEMY)
	draw_string(font, Vector2(enemy_x - 64, center_y + 100), "HP %d/%d" % [enemy_hp, enemy_max], HORIZONTAL_ALIGNMENT_LEFT, 128, 18, TEXT_PRIMARY)
	if enemy_block > 0:
		draw_string(font, Vector2(enemy_x - 64, center_y + 120), "Block %d" % enemy_block, HORIZONTAL_ALIGNMENT_LEFT, 128, 16, BLOCK_COLOR)

	# Enemy intent (centered between portraits)
	var intent: Dictionary = vm.get("enemy_intent", {})
	var telegraph: String = str(intent.get("telegraph_text", ""))
	if telegraph == "":
		telegraph = "Intent: %d dmg" % int(vm.get("enemy_intent_damage", 0))
	var intent_x: float = w * 0.5
	var intent_y: float = center_y - 20
	draw_string(font, Vector2(intent_x - 150, intent_y), telegraph, HORIZONTAL_ALIGNMENT_CENTER, 300, 24, TEXT_WARN)

	# Profile name below intent
	var profile: String = str(vm.get("pressure_profile_name", ""))
	if profile != "":
		draw_string(font, Vector2(intent_x - 100, intent_y + 30), profile, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, TEXT_MUTED)

	# Encounter title at top of arena
	var title: String = str(vm.get("encounter_title", ""))
	if title != "":
		draw_string(font, Vector2(20, 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TEXT_PRIMARY)

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
		draw_string(font, Vector2(w * 0.5 - 60, hand_y + 80), "Hand empty", HORIZONTAL_ALIGNMENT_CENTER, 120, 20, TEXT_MUTED)
		return

	# Calculate card positions for fan layout
	var total_width: float = CARD_WIDTH + float(card_count - 1) * CARD_OVERLAP
	var start_x: float = (w - total_width) / 2.0
	var base_y: float = hand_y + 20.0

	for i in range(card_count):
		var card_x: float = start_x + float(i) * CARD_OVERLAP
		var card_y: float = base_y
		var is_hovered: bool = i == hovered_card_index
		var card_id: String = str(hand_card_ids[i]) if i < hand_card_ids.size() else ""
		var instance_id: String = str(hand[i]) if i < hand.size() else ""
		var reject_reason: String = str(hand_play_reasons[i]) if i < hand_play_reasons.size() else ""
		var playable: bool = reject_reason == ""

		if is_hovered:
			card_y -= CARD_HOVER_LIFT

		_draw_card(Vector2(card_x, card_y), card_id, instance_id, playable, is_hovered)

	# Energy counter
	var energy_text: String = "Energy %d/%d" % [energy, max_energy]
	draw_string(font, Vector2(w - 180, hand_y + CARD_HEIGHT + 30), energy_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ENERGY_COLOR)

	# Phase / combat result
	var phase: String = str(vm.get("ui_phase_text", ""))
	var result: String = str(vm.get("combat_result", "in_progress"))
	var phase_text: String = phase
	var phase_color: Color = TEXT_MUTED
	if result == "player_win":
		phase_text = "VICTORY"
		phase_color = TEXT_GOOD
	elif result == "player_lose":
		phase_text = "DEFEAT"
		phase_color = TEXT_BAD
	draw_string(font, Vector2(20, hand_y + CARD_HEIGHT + 30), phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, phase_color)

	# Pass button hint
	if result == "in_progress":
		draw_string(font, Vector2(20, hand_y + CARD_HEIGHT + 56), "SPACE = Pass Turn  |  R = Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEXT_MUTED)

func _draw_card(pos: Vector2, card_id: String, instance_id: String, playable: bool, hovered: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	var bg: Color = CARD_BG if playable else CARD_BG_DISABLED
	var card_w: float = CARD_WIDTH
	var card_h: float = CARD_HEIGHT

	if hovered:
		card_w *= CARD_HOVER_SCALE
		card_h *= CARD_HOVER_SCALE

	# Card body
	draw_rect(Rect2(pos, Vector2(card_w, card_h)), bg)
	draw_rect(Rect2(pos, Vector2(card_w, card_h)), CARD_BORDER, false, 2.0)

	# Card name
	var display_name: String = card_id
	if runner != null and runner.has_method("_display_name_for_card"):
		display_name = str(runner.call("_display_name_for_card", card_id))
	elif card_id != "":
		display_name = card_id.replace("_", " ").capitalize()
	draw_string(font, pos + Vector2(8, 24), display_name, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 16), 16, CARD_TEXT)

	# Card rules text
	var rules: String = ""
	if runner != null and runner.card_catalog != null and runner.card_catalog.has_card(card_id):
		rules = str(runner.card_catalog.hand_rules_text(card_id))
	if rules != "":
		draw_string(font, pos + Vector2(8, 48), rules, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 16), 13, CARD_TEXT)

	# Playability indicator
	if not playable:
		draw_string(font, pos + Vector2(8, card_h - 12), "locked", HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 16), 12, TEXT_BAD)

func _draw_status_bar(w: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var turn: int = int(vm.get("turn", 0))
	var zones: Dictionary = vm.get("zones", {})
	var status: String = "Turn %d  |  Draw %d  |  Discard %d" % [
		turn,
		int(zones.get("draw", 0)),
		int(zones.get("discard", 0)),
	]
	draw_string(font, Vector2(w - 320, 30), status, HORIZONTAL_ALIGNMENT_RIGHT, 300, 16, TEXT_MUTED)

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
		var tex: Texture2D = gem_ruby_tex if gem == "Ruby" else gem_sapphire_tex
		var x: float = start_x + float(i) * 40.0
		# Slot outline
		draw_rect(Rect2(Vector2(x - 2, y - 2), slot_size), PANEL_BORDER, false, 1.5)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(x, y), icon_size), false)

	# Focus indicator
	var font: Font = ThemeDB.fallback_font
	if focus > 0:
		var focus_x: float = start_x + float(display_gems.size()) * 40.0 + 20.0
		draw_string(font, Vector2(focus_x, y + 22), "FOCUS %d" % focus, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEXT_ACCENT)

func _draw_event_feed(w: float, arena_h: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var events: Array = vm.get("recent_events", [])
	var x: float = w - 320.0
	var y: float = arena_h - 20.0
	for i in range(events.size()):
		var line: String = str(events[events.size() - 1 - i])
		if line.length() > 50:
			line = line.substr(0, 47) + "..."
		draw_string(font, Vector2(x, y - float(i) * 18.0), line, HORIZONTAL_ALIGNMENT_LEFT, 300, 13, TEXT_MUTED)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		var new_hover: int = _card_at_position(mm.position)
		if new_hover != hovered_card_index:
			hovered_card_index = new_hover
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
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
	var result: String = str(vm.get("combat_result", "in_progress"))
	var reward_state: String = str(vm.get("reward_state", "none"))
	if result != "in_progress":
		if reward_state == "presented":
			# Auto-pick first reward
			runner.choose_reward_by_index(0)
		elif reward_state == "applied" or reward_state == "closed":
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
	var total_width: float = CARD_WIDTH + float(card_count - 1) * CARD_OVERLAP
	var start_x: float = (w - total_width) / 2.0

	# Check from rightmost card (topmost in draw order) to leftmost
	for i in range(card_count - 1, -1, -1):
		var card_x: float = start_x + float(i) * CARD_OVERLAP
		var card_y: float = hand_y
		if i == hovered_card_index:
			card_y -= CARD_HOVER_LIFT
		var rect := Rect2(Vector2(card_x, card_y), Vector2(CARD_WIDTH, CARD_HEIGHT))
		if rect.has_point(pos):
			return i
	return -1

func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	return null
