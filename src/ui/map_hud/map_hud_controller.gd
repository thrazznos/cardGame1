extends Control
class_name MapHudController

## Renders a FloorGraph as a navigable node graph.
## Single-click on a legal adjacent room to enter it.

const PANEL_BG := Color("#1a1520")
const PANEL_BORDER := Color("#4b3860")
const ARENA_BG := Color("#0e0a14")
const TEXT_PRIMARY := Color("#fffdf5")
const TEXT_MUTED := Color("#a0a8b8")
const TEXT_ACCENT := Color("#60d0ff")
const TEXT_GOOD := Color("#70e870")
const TEXT_WARN := Color("#ffcc44")
const NODE_RUBY := Color("#e04040")
const NODE_SAPPHIRE := Color("#3090e0")
const NODE_NEUTRAL := Color("#707880")
const NODE_CLEARED := Color("#383040")
const NODE_CURRENT := Color("#f0c030")
const NODE_LEGAL_RING := Color("#e0b840")
const EDGE_DEFAULT := Color("#403848")
const EDGE_LEGAL := Color("#60d0ff")
const EDGE_HOVER := Color("#f5d98a")
const NODE_HOVER_RING := Color("#fff1c2")
const TOOLTIP_BG := Color(0.09, 0.08, 0.13, 0.92)
const TOOLTIP_BORDER := Color(0.55, 0.46, 0.30, 0.96)
const NODE_RADIUS := 72.0

var _gem_ruby_tex: Texture2D
var _gem_sapphire_tex: Texture2D

var floor_vm: Dictionary = {}
var gem_stack: Array = []
var gem_stack_cap: int = 6
var runner: Variant = null
var node_positions: Dictionary = {}
var _busy: bool = false
var _event_text: String = ""
var _showing_event: bool = false
var _hovered_node_id: int = -1

func _ready() -> void:
	_gem_ruby_tex = _try_load("res://assets/generated/gems/obj_gem_ruby_token_md.png")
	_gem_sapphire_tex = _try_load("res://assets/generated/gems/obj_gem_sapphire_token_md.png")

static func _try_load(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	return null

func bind_runner(p_runner: Variant) -> void:
	runner = p_runner

func _ui_scale() -> float:
	var scale_x: float = size.x / 1600.0 if size.x > 0.0 else 1.0
	var scale_y: float = size.y / 900.0 if size.y > 0.0 else 1.0
	return clampf(min(scale_x, scale_y), 0.72, 1.15)

func _scaled_font(base_size: int) -> int:
	return max(12, int(round(float(base_size) * _ui_scale())))

func refresh(vm: Dictionary, p_gem_stack: Array = [], p_gem_cap: int = 6) -> void:
	floor_vm = vm
	gem_stack = p_gem_stack
	gem_stack_cap = p_gem_cap
	_busy = false
	_hovered_node_id = -1
	mouse_default_cursor_shape = CURSOR_ARROW
	_compute_node_positions()
	queue_redraw()

func _compute_node_positions() -> void:
	node_positions = {}
	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var center := size / 2.0
	var radius: float = min(size.x, size.y) * 0.30

	if nodes.is_empty():
		return

	var node_count: int = nodes.size()
	var start_id: int = int(floor_vm.get("start_node", 0))
	var exit_id: int = int(floor_vm.get("exit_node", -1))

	for i in range(node_count):
		var angle: float = -PI / 2.0 + (2.0 * PI * float(i) / float(node_count))
		node_positions[i] = center + Vector2(cos(angle), sin(angle)) * radius

	if node_positions.has(start_id):
		node_positions[start_id] = center + Vector2(0, -radius)
	if node_positions.has(exit_id) and exit_id >= 0:
		node_positions[exit_id] = center + Vector2(0, radius)

func show_event(event_text: String) -> void:
	_showing_event = true
	_event_text = event_text
	_busy = true
	_hovered_node_id = -1
	mouse_default_cursor_shape = CURSOR_ARROW
	queue_redraw()

func dismiss_event() -> void:
	_showing_event = false
	_event_text = ""
	_busy = false
	_hovered_node_id = -1
	mouse_default_cursor_shape = CURSOR_ARROW
	queue_redraw()

func _draw() -> void:
	var ui_scale: float = _ui_scale()
	draw_rect(Rect2(Vector2.ZERO, size), PANEL_BG)
	draw_circle(size * 0.5, min(size.x, size.y) * 0.28, Color(0.18, 0.20, 0.28, 0.10))
	draw_circle(Vector2(size.x * 0.5, size.y * 0.35), min(size.x, size.y) * 0.18, Color(0.85, 0.70, 0.36, 0.05))

	if _showing_event:
		_draw_event_screen()
		return

	# Frame border
	draw_rect(Rect2(Vector2(8, 8) * ui_scale, size - Vector2(16, 16) * ui_scale), PANEL_BORDER, false, 2.0 * ui_scale)

	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var current: int = int(floor_vm.get("current_node", -1))
	var legal_moves: Array = floor_vm.get("legal_moves", [])
	var font: Font = ThemeDB.fallback_font

	var node_radius: float = NODE_RADIUS * ui_scale

	# Draw edges
	for edge in edges:
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if not node_positions.has(a) or not node_positions.has(b):
			continue
		var is_legal_edge: bool = (a == current and legal_moves.has(b)) or (b == current and legal_moves.has(a))
		var is_hover_edge: bool = _hovered_node_id >= 0 and ((a == current and b == _hovered_node_id) or (b == current and a == _hovered_node_id))
		var edge_color: Color = EDGE_DEFAULT
		var edge_width: float = 1.5 * ui_scale
		if is_legal_edge:
			edge_color = EDGE_LEGAL
			edge_width = 3.0 * ui_scale
		if is_hover_edge:
			edge_color = EDGE_HOVER
			edge_width = 4.0 * ui_scale
		draw_line(node_positions[a], node_positions[b], edge_color, edge_width)

	# Draw nodes
	for node in nodes:
		var node_id: int = int(node.get("node_id", 0))
		if not node_positions.has(node_id):
			continue
		var pos: Vector2 = node_positions[node_id]
		var cleared: bool = bool(node.get("cleared", false))
		var affinity: String = str(node.get("gem_affinity", "neutral"))
		var node_type: String = str(node.get("node_type", "combat"))
		var is_current: bool = node_id == current
		var is_legal: bool = legal_moves.has(node_id)
		var is_hovered: bool = node_id == _hovered_node_id

		# Node fill
		var fill_color: Color = _node_fill(affinity, cleared, is_current)
		if is_hovered and not cleared:
			fill_color = fill_color.lightened(0.08)

		# Legal ring (thick gold border on clickable rooms)
		if is_legal and not cleared:
			draw_circle(pos, node_radius + 8.0 * ui_scale, NODE_LEGAL_RING)
		if is_hovered and not cleared:
			draw_circle(pos, node_radius + 14.0 * ui_scale, NODE_HOVER_RING)

		# Current position ring (bright double ring)
		if is_current:
			draw_circle(pos, node_radius + 12.0 * ui_scale, NODE_CURRENT)
			draw_circle(pos, node_radius + 6.0 * ui_scale, PANEL_BG)

		# Node body
		draw_circle(pos, node_radius, fill_color)

		# Room type label inside node
		var type_label: String = _type_label(node_type)
		var label_color: Color = TEXT_PRIMARY if not cleared else TEXT_MUTED
		_draw_text_centered(pos + Vector2(0, -10.0 * ui_scale), type_label, _scaled_font(22), label_color)

		# Affinity label below type
		if not cleared:
			var aff_label: String = affinity if affinity != "neutral" else "---"
			_draw_text_centered(pos + Vector2(0, 18.0 * ui_scale), aff_label, _scaled_font(18), TEXT_MUTED)

		# Cleared overlay
		if cleared and not is_current:
			_draw_text_centered(pos, "DONE", _scaled_font(20), TEXT_MUTED)

		# Gem gate cost above node
		var gem_gate: Variant = node.get("gem_gate", null)
		if gem_gate is Dictionary and not cleared:
			var gate_gem: String = str(gem_gate.get("gem", ""))
			var gate_cost: int = int(gem_gate.get("cost", 0))
			_draw_text_centered(pos + Vector2(0, -(node_radius + 22.0 * ui_scale)), "%d %s needed" % [gate_cost, gate_gem], _scaled_font(18), TEXT_WARN)

	# HUD elements
	_draw_gem_stack_bar()
	_draw_floor_banner()
	_draw_objective_banner()
	_draw_instructions()
	_draw_hover_panel()

func _node_fill(affinity: String, cleared: bool, is_current: bool) -> Color:
	if cleared and not is_current:
		return NODE_CLEARED
	if is_current:
		return NODE_CURRENT.darkened(0.4)
	match affinity:
		"Ruby":
			return NODE_RUBY
		"Sapphire":
			return NODE_SAPPHIRE
		_:
			return NODE_NEUTRAL

func _draw_text_centered(pos: Vector2, text: String, font_size: int, color: Color = TEXT_PRIMARY) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

func _draw_gem_stack_bar() -> void:
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = _ui_scale()
	var y: float = size.y - 80.0 * ui_scale
	var icon_size := Vector2(36, 36) * ui_scale

	# Label
	draw_string(font, Vector2(24.0 * ui_scale, y - 4.0 * ui_scale), "Gem Stack [%d/%d]" % [gem_stack.size(), gem_stack_cap], HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(20), TEXT_ACCENT)

	# Gem icon slots
	for i in range(gem_stack_cap):
		var slot_x: float = 24.0 * ui_scale + float(i) * 44.0 * ui_scale
		var slot_y: float = y + 20.0 * ui_scale
		# Slot outline
		draw_rect(Rect2(Vector2(slot_x - 2.0 * ui_scale, slot_y - 2.0 * ui_scale), Vector2(40, 40) * ui_scale), PANEL_BORDER, false, 1.5 * ui_scale)
		# Gem icon or empty
		if i < gem_stack.size():
			var gem: String = str(gem_stack[i])
			var tex: Texture2D = _gem_ruby_tex if gem == "Ruby" else _gem_sapphire_tex
			if tex != null:
				draw_texture_rect(tex, Rect2(Vector2(slot_x, slot_y), icon_size), false)
		else:
			draw_rect(Rect2(Vector2(slot_x, slot_y), icon_size), Color("#1a1520"))

func _draw_floor_banner() -> void:
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = _ui_scale()
	var floor_idx: int = int(floor_vm.get("floor_index", 1))
	var rooms: int = int(floor_vm.get("rooms_cleared", 0))
	var info: String = "FLOOR %d  |  Rooms cleared: %d" % [floor_idx, rooms]
	draw_string(font, Vector2(24.0 * ui_scale, 40.0 * ui_scale), info, HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(24), TEXT_PRIMARY)

func _draw_objective_banner() -> void:
	var constraint: String = str(floor_vm.get("active_constraint", ""))
	if constraint == "":
		return
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = _ui_scale()
	var origin := Vector2(size.x - 400.0 * ui_scale, 40.0 * ui_scale)

	match constraint:
		"conduit":
			var pattern: Array = floor_vm.get("conduit_pattern", [])
			var progress: int = int(floor_vm.get("conduit_progress", 0))
			var matched: bool = bool(floor_vm.get("conduit_matched", false))
			if pattern.is_empty():
				return
			if matched:
				draw_string(font, origin, "CONDUIT MATCHED!", HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(24), TEXT_GOOD)
				return
			var label: String = "Conduit: "
			for i in range(pattern.size()):
				var gem_char: String = str(pattern[i])[0]
				if i < progress:
					label += "[%s] " % gem_char
				elif i == progress:
					label += ">%s< " % gem_char
				else:
					label += " %s  " % gem_char
			draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(22), TEXT_ACCENT)

		"circuit":
			var seq: Array = floor_vm.get("circuit_sequence", [])
			var progress: int = int(floor_vm.get("circuit_progress", 0))
			var penalties: int = int(floor_vm.get("circuit_penalties", 0))
			if seq.is_empty():
				return
			if progress >= seq.size():
				draw_string(font, origin, "CIRCUIT COMPLETE!", HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(24), TEXT_GOOD)
				return
			var label: String = "Circuit: "
			for i in range(seq.size()):
				var gem_char: String = str(seq[i])[0]
				if i < progress:
					label += "[%s] " % gem_char
				elif i == progress:
					label += ">%s< " % gem_char
				else:
					label += " %s  " % gem_char
			if penalties > 0:
				label += " (%d wrong)" % penalties
			draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(22), TEXT_WARN)

		"seal":
			var broken: int = int(floor_vm.get("seals_broken", 0))
			var total: int = int(floor_vm.get("seals_total", 0))
			var locked: bool = bool(floor_vm.get("boss_locked", false))
			var label: String = "Seals: %d/%d broken" % [broken, total]
			if locked:
				label += " (BOSS LOCKED)"
			var color: Color = TEXT_GOOD if not locked else TEXT_WARN
			draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(22), color)

func _draw_instructions() -> void:
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = _ui_scale()
	var legal: Array = floor_vm.get("legal_moves", [])
	var state: String = str(floor_vm.get("state", ""))
	var text: String = ""
	if state == FloorController.STATE_ROOM_SELECT:
		if legal.is_empty():
			text = "No rooms available. Floor complete?"
		else:
			text = "Hover a room for details, then click a highlighted room to enter it."
	elif state == FloorController.STATE_COMBAT:
		text = "Fighting..."
	elif state == FloorController.STATE_FLOOR_COMPLETE:
		text = "Floor complete!"
	if text != "":
		draw_string(font, Vector2(24.0 * ui_scale, size.y - 20.0 * ui_scale), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _scaled_font(20), TEXT_MUTED)

func _draw_hover_panel() -> void:
	if _hovered_node_id < 0:
		return
	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var node: Dictionary = {}
	for entry in nodes:
		if entry is Dictionary and int(entry.get("node_id", -1)) == _hovered_node_id:
			node = entry
			break
	if node.is_empty():
		return
	var title: String = _type_label(str(node.get("node_type", "room")))
	var affinity: String = str(node.get("gem_affinity", "neutral"))
	var legal_moves: Array = floor_vm.get("legal_moves", [])
	var is_legal: bool = legal_moves.has(_hovered_node_id)
	var lines: Array = []
	lines.append("Affinity: %s" % affinity.capitalize())
	var gem_gate: Variant = node.get("gem_gate", null)
	if gem_gate is Dictionary:
		var gate_gem: String = str(gem_gate.get("gem", ""))
		var gate_cost: int = int(gem_gate.get("cost", 0))
		lines.append("Gate: %d %s on top" % [gate_cost, gate_gem])
		if not _can_afford_gate(gate_gem, gate_cost):
			lines.append("Locked until you can pay it")
	elif bool(node.get("is_exit", false)) and bool(floor_vm.get("boss_locked", false)):
		lines.append("Boss gate still locked")
	elif is_legal:
		lines.append("Click to enter")
	var panel_size := Vector2(260, 34 + float(lines.size()) * 20.0)
	var panel_pos := Vector2(size.x - panel_size.x - 24.0, size.y - panel_size.y - 96.0)
	draw_rect(Rect2(panel_pos, panel_size), TOOLTIP_BG)
	draw_rect(Rect2(panel_pos, panel_size), TOOLTIP_BORDER, false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, panel_pos + Vector2(14, 22), title, HORIZONTAL_ALIGNMENT_LEFT, int(panel_size.x - 28.0), 18, TEXT_PRIMARY)
	for i in range(lines.size()):
		draw_string(font, panel_pos + Vector2(14, 44 + float(i) * 18.0), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, int(panel_size.x - 28.0), 16, TEXT_MUTED if i < 2 else TEXT_WARN)

func _can_afford_gate(gate_gem: String, gate_cost: int) -> bool:
	if gate_cost <= 0 or gate_gem == "":
		return true
	if gem_stack.size() < gate_cost:
		return false
	var start_index: int = gem_stack.size() - gate_cost
	for i in range(start_index, gem_stack.size()):
		if str(gem_stack[i]) != gate_gem:
			return false
	return true

func _gui_input(event: InputEvent) -> void:
	if _showing_event:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_dismiss_event_and_continue()
		return
	if _busy:
		return
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		var hovered_node: int = _node_at_position(mm.position)
		if hovered_node != _hovered_node_id:
			_hovered_node_id = hovered_node
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if hovered_node >= 0 and floor_vm.get("legal_moves", []).has(hovered_node) else CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var clicked_node: int = _node_at_position(mb.position)
			if clicked_node >= 0:
				_handle_node_click(clicked_node)

func _unhandled_input(event: InputEvent) -> void:
	if _showing_event and event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and key.keycode == KEY_SPACE:
			_dismiss_event_and_continue()

func _dismiss_event_and_continue() -> void:
	dismiss_event()
	if runner != null:
		runner.call("map_event_dismissed")

func _handle_node_click(node_id: int) -> void:
	var legal_moves: Array = floor_vm.get("legal_moves", [])
	if not legal_moves.has(node_id):
		return
	# Single click = commit immediately
	_busy = true
	if runner != null:
		runner.call("map_commit_room", node_id)

func _node_at_position(pos: Vector2) -> int:
	var ui_scale: float = _ui_scale()
	for node_id in node_positions:
		var node_pos: Vector2 = node_positions[node_id]
		if pos.distance_to(node_pos) <= NODE_RADIUS * ui_scale + 12.0 * ui_scale:
			return int(node_id)
	return -1

func _draw_event_screen() -> void:
	var font: Font = ThemeDB.fallback_font
	var ui_scale: float = _ui_scale()
	var w: float = size.x
	var h: float = size.y

	# Dark background
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), ARENA_BG)

	# Event panel
	var panel_w: float = w * 0.6
	var panel_h: float = h * 0.4
	var panel_x: float = (w - panel_w) / 2.0
	var panel_y: float = (h - panel_h) / 2.0
	draw_rect(Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)), PANEL_BG)
	draw_rect(Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)), PANEL_BORDER, false, 2.0 * ui_scale)

	# Title
	draw_string(font, Vector2(panel_x + 24.0 * ui_scale, panel_y + 40.0 * ui_scale), "EVENT", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48.0 * ui_scale), _scaled_font(28), TEXT_ACCENT)

	# Event text
	if _event_text != "":
		draw_string(font, Vector2(panel_x + 24.0 * ui_scale, panel_y + 90.0 * ui_scale), _event_text, HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48.0 * ui_scale), _scaled_font(20), TEXT_PRIMARY)
	else:
		draw_string(font, Vector2(panel_x + 24.0 * ui_scale, panel_y + 90.0 * ui_scale), "You find a quiet moment to catch your breath.", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48.0 * ui_scale), _scaled_font(20), TEXT_PRIMARY)

	# Continue prompt
	draw_string(font, Vector2(panel_x + 24.0 * ui_scale, panel_y + panel_h - 30.0 * ui_scale), "Click or press SPACE to continue", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48.0 * ui_scale), _scaled_font(18), TEXT_MUTED)

func _type_label(node_type: String) -> String:
	match node_type:
		"combat":
			return "Combat"
		"boss":
			return "BOSS"
		"event":
			return "Event"
		"rest":
			return "Rest"
		"start":
			return "Start"
		_:
			return "Room"
