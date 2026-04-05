extends Control
class_name CombatHudController

var runner: Variant

func bind_runner(runtime_runner: Variant) -> void:
	runner = runtime_runner

func _ready() -> void:
	if has_node("VBox/Buttons/PlayStrike"):
		$VBox/Buttons/PlayStrike.pressed.connect(_on_play_strike)
	if has_node("VBox/Buttons/PlayDefend"):
		$VBox/Buttons/PlayDefend.pressed.connect(_on_play_defend)
	if has_node("VBox/Buttons/Pass"):
		$VBox/Buttons/Pass.pressed.connect(_on_pass)
	if has_node("VBox/Buttons/Restart"):
		$VBox/Buttons/Restart.pressed.connect(_on_restart)

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
	if has_node("VBox/Hint"):
		$VBox/Hint.text = "Strike/Defend cost 1 Energy. Pass ends player turn."

func _on_play_strike() -> void:
	if runner == null:
		return
	runner.player_play_card("strike_01")

func _on_play_defend() -> void:
	if runner == null:
		return
	runner.player_play_card("defend_01")

func _on_pass() -> void:
	if runner == null:
		return
	runner.player_pass()

func _on_restart() -> void:
	if runner == null:
		return
	runner.reset_battle(13371337)
