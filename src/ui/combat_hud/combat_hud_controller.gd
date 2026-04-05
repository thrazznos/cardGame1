extends Control
class_name CombatHudController

var runner: Variant

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	if has_node("VBox/Buttons/Pass"):
		$VBox/Buttons/Pass.pressed.connect(_on_pass)
	if has_node("VBox/Buttons/Restart"):
		$VBox/Buttons/Restart.pressed.connect(_on_restart)
	_connect_hand_buttons()

func _connect_hand_buttons() -> void:
	if not has_node("VBox/HandButtons"):
		return
	for child in $VBox/HandButtons.get_children():
		if child is Button:
			child.pressed.connect(_on_hand_card_pressed.bind(child))

func refresh(vm: Dictionary) -> void:
	if has_node("VBox/Title"):
		$VBox/Title.text = "Dungeon Steward - Combat Prototype"
	if has_node("VBox/Status"):
		$VBox/Status.text = "Turn %d | Phase: %s | Result: %s" % [int(vm.get("turn", 0)), str(vm.get("phase", "-")), str(vm.get("combat_result", "in_progress"))]
	if has_node("VBox/PlayerStats"):
		$VBox/PlayerStats.text = "Player HP: %d  Block: %d  Energy: %d" % [int(vm.get("player_hp", 0)), int(vm.get("player_block", 0)), int(vm.get("energy", 0))]
	if has_node("VBox/EnemyStats"):
		$VBox/EnemyStats.text = "Enemy HP: %d  Block: %d  Intent: %d" % [int(vm.get("enemy_hp", 0)), int(vm.get("enemy_block", 0)), int(vm.get("enemy_intent_damage", 0))]
	if has_node("VBox/Hand"):
		var hand: Array = vm.get("hand", [])
		$VBox/Hand.text = "Hand: %s" % [", ".join(hand)]
	if has_node("VBox/EventLog"):
		$VBox/EventLog.text = "Last: %s" % [str(vm.get("last_event_text", "-"))]
	if has_node("VBox/Hint"):
		$VBox/Hint.text = "Click a card button to play. Strike/Defend cost 1 Energy."
	_refresh_hand_buttons(vm)

func _refresh_hand_buttons(vm: Dictionary) -> void:
	if not has_node("VBox/HandButtons"):
		return
	var hand: Array = vm.get("hand", [])
	var energy: int = int(vm.get("energy", 0))
	var active: bool = str(vm.get("combat_result", "in_progress")) == "in_progress"
	var buttons := $VBox/HandButtons.get_children()
	for i in range(buttons.size()):
		var b = buttons[i]
		if not (b is Button):
			continue
		if i < hand.size():
			var card_id: String = str(hand[i])
			b.text = "Play %s" % [card_id]
			b.set_meta("card_id", card_id)
			b.disabled = (not active) or energy <= 0
		else:
			b.text = "(empty)"
			b.set_meta("card_id", "")
			b.disabled = true

func _on_hand_card_pressed(button: Button) -> void:
	if runner == null:
		return
	var card_id: String = str(button.get_meta("card_id", ""))
	if card_id == "":
		return
	runner.player_play_card(card_id)

func _on_pass() -> void:
	if runner == null:
		return
	runner.player_pass()

func _on_restart() -> void:
	if runner == null:
		return
	runner.reset_battle(13371337)
