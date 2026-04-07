extends Control
class_name MapHudController

## Renders a FloorGraph as a navigable node graph.
## Handles room selection (select-then-commit) and displays gem stack state.

const PANEL_BG := Color("#171b24")
const PANEL_BORDER := Color("#4b5876")
const TEXT_PRIMARY := Color("#f3f6fb")
const TEXT_MUTED := Color("#d0d8e4")
const TEXT_ACCENT := Color("#7ec6ff")
const TEXT_GOOD := Color("#8be28b")
const NODE_RUBY := Color("#c94040")
const NODE_SAPPHIRE := Color("#4080c9")
const NODE_NEUTRAL := Color("#808890")
const NODE_CLEARED := Color("#3a3f48")
const NODE_CURRENT := Color("#ffd36a")
const NODE_SELECTABLE := Color("#b9985a")
const EDGE_DEFAULT := Color("#4b5876")
const EDGE_LEGAL := Color("#7ec6ff")
const NODE_RADIUS := 28.0
const NODE_SELECTED_RADIUS := 34.0

var floor_vm: Dictionary = {}
var gem_stack: Array = []
var gem_stack_cap: int = 6
var selected_node: int = -1
var runner: Variant = null

## 2D positions for each node (computed from graph topology)
var node_positions: Dictionary = {}

func bind_runner(p_runner: Variant) -> void:
	runner = p_runner

func refresh(vm: Dictionary, p_gem_stack: Array = [], p_gem_cap: int = 6) -> void:
	floor_vm = vm
	gem_stack = p_gem_stack
	gem_stack_cap = p_gem_cap
	selected_node = -1
	_compute_node_positions()
	queue_redraw()
	_update_info_panel()

func _compute_node_positions() -> void:
	node_positions = {}
	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var center := size / 2.0
	var radius: float = min(size.x, size.y) * 0.32

	if nodes.is_empty():
		return

	# Layout nodes in a circle with start at top, exit at bottom
	var node_count: int = nodes.size()
	for i in range(node_count):
		var angle: float = -PI / 2.0 + (2.0 * PI * float(i) / float(node_count))
		node_positions[i] = center + Vector2(cos(angle), sin(angle)) * radius

	# Override: start node at top, exit node at bottom
	var start_id: int = int(floor_vm.get("start_node", 0))
	var exit_id: int = int(floor_vm.get("exit_node", -1))
	if node_positions.has(start_id):
		node_positions[start_id] = center + Vector2(0, -radius)
	if node_positions.has(exit_id) and exit_id >= 0:
		node_positions[exit_id] = center + Vector2(0, radius)

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), PANEL_BG)

	var graph: Dictionary = floor_vm.get("graph", {})
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var current: int = int(floor_vm.get("current_node", -1))
	var legal_moves: Array = floor_vm.get("legal_moves", [])

	# Draw edges
	for edge in edges:
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if not node_positions.has(a) or not node_positions.has(b):
			continue
		var pos_a: Vector2 = node_positions[a]
		var pos_b: Vector2 = node_positions[b]
		var edge_color: Color = EDGE_DEFAULT
		if (a == current and legal_moves.has(b)) or (b == current and legal_moves.has(a)):
			edge_color = EDGE_LEGAL
		draw_line(pos_a, pos_b, edge_color, 2.0)

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
		var is_selected: bool = node_id == selected_node

		# Node color
		var fill_color: Color = NODE_NEUTRAL
		if cleared:
			fill_color = NODE_CLEARED
		elif is_current:
			fill_color = NODE_CURRENT
		elif affinity == "Ruby":
			fill_color = NODE_RUBY
		elif affinity == "Sapphire":
			fill_color = NODE_SAPPHIRE

		var draw_radius: float = NODE_SELECTED_RADIUS if is_selected else NODE_RADIUS

		# Selection ring
		if is_legal and not cleared:
			draw_circle(pos, draw_radius + 4.0, NODE_SELECTABLE)
		if is_selected:
			draw_circle(pos, draw_radius + 6.0, TEXT_ACCENT)

		# Node circle
		draw_circle(pos, draw_radius, fill_color)

		# Node type label
		var type_char: String = _type_char(node_type)
		_draw_centered_text(pos, type_char, 16)

		# Affinity label below node
		if not cleared and affinity != "neutral" and affinity != "":
			_draw_centered_text(pos + Vector2(0, draw_radius + 14), affinity[0], 12)

		# Gem gate cost indicator
		var gem_gate: Variant = node.get("gem_gate", null)
		if gem_gate is Dictionary and not cleared:
			var gate_gem: String = str(gem_gate.get("gem", ""))[0] if str(gem_gate.get("gem", "")) != "" else "?"
			var gate_cost: int = int(gem_gate.get("cost", 0))
			var gate_text: String = "%d%s" % [gate_cost, gate_gem]
			_draw_centered_text(pos + Vector2(0, -(draw_radius + 14)), gate_text, 11)

	# Gem stack display (bottom-left)
	_draw_gem_stack()

	# Floor info (top-left)
	_draw_floor_info()

func _draw_centered_text(pos: Vector2, text: String, font_size: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, TEXT_PRIMARY)

func _draw_gem_stack() -> void:
	var origin := Vector2(20, size.y - 40)
	var font: Font = ThemeDB.fallback_font
	var stack_text: String = "Stack [%d/%d]: " % [gem_stack.size(), gem_stack_cap]
	if gem_stack.is_empty():
		stack_text += "(empty)"
	else:
		var gems: Array = []
		for gem in gem_stack:
			gems.append(str(gem)[0])
		stack_text += " ".join(gems)
	draw_string(font, origin, stack_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_ACCENT)

func _draw_floor_info() -> void:
	var font: Font = ThemeDB.fallback_font
	var floor_idx: int = int(floor_vm.get("floor_index", 1))
	var rooms_cleared: int = int(floor_vm.get("rooms_cleared", 0))
	var state: String = str(floor_vm.get("state", ""))
	var info: String = "Floor %d • Rooms cleared: %d • %s" % [floor_idx, rooms_cleared, state]
	draw_string(font, Vector2(20, 28), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_MUTED)

func _update_info_panel() -> void:
	# Update any child labels if they exist
	var info_label: Node = get_node_or_null("InfoLabel")
	if info_label is Label:
		if selected_node >= 0:
			var graph: Dictionary = floor_vm.get("graph", {})
			var nodes: Array = graph.get("nodes", [])
			if selected_node < nodes.size():
				var node: Dictionary = nodes[selected_node]
				(info_label as Label).text = "%s • %s • %s" % [
					str(node.get("node_type", "")),
					str(node.get("gem_affinity", "")),
					"Cleared" if bool(node.get("cleared", false)) else "Available",
				]
		else:
			(info_label as Label).text = "Select a room to enter"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var clicked_node: int = _node_at_position(mb.position)
			if clicked_node >= 0:
				_handle_node_click(clicked_node)

func _handle_node_click(node_id: int) -> void:
	var legal_moves: Array = floor_vm.get("legal_moves", [])
	if not legal_moves.has(node_id):
		return

	if selected_node == node_id:
		# Second click = commit
		if runner != null:
			runner.call("map_commit_room", node_id)
		selected_node = -1
	else:
		# First click = select
		selected_node = node_id
		queue_redraw()
		_update_info_panel()

func _node_at_position(pos: Vector2) -> int:
	for node_id in node_positions:
		var node_pos: Vector2 = node_positions[node_id]
		if pos.distance_to(node_pos) <= NODE_RADIUS + 8.0:
			return int(node_id)
	return -1

func _type_char(node_type: String) -> String:
	match node_type:
		"combat":
			return "!"
		"boss":
			return "B"
		"event":
			return "?"
		"rest":
			return "R"
		"start":
			return "S"
		_:
			return "."
