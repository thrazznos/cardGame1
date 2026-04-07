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

func refresh(vm: Dictionary, p_gem_stack: Array = [], p_gem_cap: int = 6) -> void:
	floor_vm = vm
	gem_stack = p_gem_stack
	gem_stack_cap = p_gem_cap
	_busy = false
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
	queue_redraw()

func dismiss_event() -> void:
	_showing_event = false
	_event_text = ""
	_busy = false
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL_BG)

	if _showing_event:
		_draw_event_screen()
		return

	# Frame border
	draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), PANEL_BORDER, false, 2.0)

	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var current: int = int(floor_vm.get("current_node", -1))
	var legal_moves: Array = floor_vm.get("legal_moves", [])
	var font: Font = ThemeDB.fallback_font

	# Draw edges
	for edge in edges:
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if not node_positions.has(a) or not node_positions.has(b):
			continue
		var is_legal_edge: bool = (a == current and legal_moves.has(b)) or (b == current and legal_moves.has(a))
		var edge_color: Color = EDGE_LEGAL if is_legal_edge else EDGE_DEFAULT
		var edge_width: float = 3.0 if is_legal_edge else 1.5
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

		# Node fill
		var fill_color: Color = _node_fill(affinity, cleared, is_current)

		# Legal ring (thick gold border on clickable rooms)
		if is_legal and not cleared:
			draw_circle(pos, NODE_RADIUS + 8.0, NODE_LEGAL_RING)

		# Current position ring (bright double ring)
		if is_current:
			draw_circle(pos, NODE_RADIUS + 12.0, NODE_CURRENT)
			draw_circle(pos, NODE_RADIUS + 6.0, PANEL_BG)

		# Node body
		draw_circle(pos, NODE_RADIUS, fill_color)

		# Room type label inside node
		var type_label: String = _type_label(node_type)
		var label_color: Color = TEXT_PRIMARY if not cleared else TEXT_MUTED
		_draw_text_centered(pos + Vector2(0, -10), type_label, 22, label_color)

		# Affinity label below type
		if not cleared:
			var aff_label: String = affinity if affinity != "neutral" else "---"
			_draw_text_centered(pos + Vector2(0, 18), aff_label, 18, TEXT_MUTED)

		# Cleared overlay
		if cleared and not is_current:
			_draw_text_centered(pos, "DONE", 20, TEXT_MUTED)

		# Gem gate cost above node
		var gem_gate: Variant = node.get("gem_gate", null)
		if gem_gate is Dictionary and not cleared:
			var gate_gem: String = str(gem_gate.get("gem", ""))
			var gate_cost: int = int(gem_gate.get("cost", 0))
			_draw_text_centered(pos + Vector2(0, -(NODE_RADIUS + 22)), "%d %s needed" % [gate_cost, gate_gem], 18, TEXT_WARN)

	# HUD elements
	_draw_gem_stack_bar()
	_draw_floor_banner()
	_draw_conduit_banner()
	_draw_instructions()

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
	var y: float = size.y - 80.0
	var icon_size := Vector2(36, 36)

	# Label
	draw_string(font, Vector2(24, y - 4), "Gem Stack [%d/%d]" % [gem_stack.size(), gem_stack_cap], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TEXT_ACCENT)

	# Gem icon slots
	for i in range(gem_stack_cap):
		var slot_x: float = 24.0 + float(i) * 44.0
		var slot_y: float = y + 20.0
		# Slot outline
		draw_rect(Rect2(Vector2(slot_x - 2, slot_y - 2), Vector2(40, 40)), PANEL_BORDER, false, 1.5)
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
	var floor_idx: int = int(floor_vm.get("floor_index", 1))
	var rooms: int = int(floor_vm.get("rooms_cleared", 0))
	var info: String = "FLOOR %d  |  Rooms cleared: %d" % [floor_idx, rooms]
	draw_string(font, Vector2(24, 40), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, TEXT_PRIMARY)

func _draw_conduit_banner() -> void:
	var constraint: String = str(floor_vm.get("active_constraint", ""))
	if constraint != "conduit":
		return
	var pattern: Array = floor_vm.get("conduit_pattern", [])
	var progress: int = int(floor_vm.get("conduit_progress", 0))
	var matched: bool = bool(floor_vm.get("conduit_matched", false))
	if pattern.is_empty():
		return

	var font: Font = ThemeDB.fallback_font
	var origin := Vector2(size.x - 400, 40)

	if matched:
		draw_string(font, origin, "CONDUIT MATCHED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, TEXT_GOOD)
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
	draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, TEXT_ACCENT)

func _draw_instructions() -> void:
	var font: Font = ThemeDB.fallback_font
	var legal: Array = floor_vm.get("legal_moves", [])
	var state: String = str(floor_vm.get("state", ""))
	var text: String = ""
	if state == "room_select":
		if legal.is_empty():
			text = "No rooms available. Floor complete?"
		else:
			text = "Click a highlighted room to enter it."
	elif state == "combat":
		text = "Fighting..."
	elif state == "floor_complete":
		text = "Floor complete!"
	if text != "":
		draw_string(font, Vector2(24, size.y - 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TEXT_MUTED)

func _gui_input(event: InputEvent) -> void:
	if _showing_event:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_dismiss_event_and_continue()
		return
	if _busy:
		return
	if event is InputEventMouseButton:
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
	for node_id in node_positions:
		var node_pos: Vector2 = node_positions[node_id]
		if pos.distance_to(node_pos) <= NODE_RADIUS + 12.0:
			return int(node_id)
	return -1

func _draw_event_screen() -> void:
	var font: Font = ThemeDB.fallback_font
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
	draw_rect(Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)), PANEL_BORDER, false, 2.0)

	# Title
	draw_string(font, Vector2(panel_x + 24, panel_y + 40), "EVENT", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48), 28, TEXT_ACCENT)

	# Event text
	if _event_text != "":
		draw_string(font, Vector2(panel_x + 24, panel_y + 90), _event_text, HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48), 20, TEXT_PRIMARY)
	else:
		draw_string(font, Vector2(panel_x + 24, panel_y + 90), "You find a quiet moment to catch your breath.", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48), 20, TEXT_PRIMARY)

	# Continue prompt
	draw_string(font, Vector2(panel_x + 24, panel_y + panel_h - 30), "Click or press SPACE to continue", HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 48), 18, TEXT_MUTED)

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
