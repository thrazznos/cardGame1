extends Control
class_name CombatSliceRunner

const FIXTURE_PATH := "res://tests/determinism/fixtures/seed_smoke_001.json"
const TSRE_SCRIPT := preload("res://src/core/tsre/tsre.gd")
const ACTION_QUEUE_SCRIPT := preload("res://src/core/tsre/action_queue.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const ERP_SCRIPT := preload("res://src/core/erp/erp.gd")
const DLS_SCRIPT := preload("res://src/core/dls/deck_lifecycle.gd")

const PLAYER_MAX_HP := 40
const ENEMY_MAX_HP := 24
const HAND_SIZE_TARGET := 5
const TURN_ENERGY := 3

var tsre: Variant
var queue: Variant
var rng: Variant
var erp: Variant
var dls: Variant
var hud: Variant

var event_stream: Array[Dictionary] = []

var player_hp: int = PLAYER_MAX_HP
var player_block: int = 0
var enemy_hp: int = ENEMY_MAX_HP
var enemy_block: int = 0
var energy: int = TURN_ENERGY
var enemy_intent_damage: int = 6
var combat_result: String = "in_progress"

func _ready() -> void:
	tsre = TSRE_SCRIPT.new()
	queue = ACTION_QUEUE_SCRIPT.new()
	rng = RSGC_SCRIPT.new()
	erp = ERP_SCRIPT.new()
	dls = DLS_SCRIPT.new()
	hud = $CombatHud
	hud.bind_runner(self)
	reset_battle(13371337)

func reset_battle(seed_root: int = 13371337) -> void:
	rng.bootstrap(seed_root)
	event_stream.clear()

	tsre.phase = tsre.PHASE_TURN_START
	tsre.turn_index = 1
	tsre.phase_index = 0
	tsre.resolve_lock = false

	player_hp = PLAYER_MAX_HP
	player_block = 0
	enemy_hp = ENEMY_MAX_HP
	enemy_block = 0
	energy = TURN_ENERGY
	combat_result = "in_progress"

	_bootstrap_demo_state()
	enemy_intent_damage = _roll_enemy_intent_damage()
	refresh_hud()

func _bootstrap_demo_state() -> void:
	dls.draw_pile = [
		"strike_01", "strike_02", "defend_01", "strike_03", "defend_02",
		"strike_04", "defend_03", "strike_05", "defend_04", "strike_06"
	]
	dls.hand = []
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	for _i in range(HAND_SIZE_TARGET):
		dls.draw_one()

func get_view_model() -> Dictionary:
	return {
		"turn": tsre.turn_index,
		"phase": tsre.phase,
		"resolve_lock": tsre.resolve_lock,
		"player_hp": player_hp,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"energy": energy,
		"enemy_intent_damage": enemy_intent_damage,
		"hand": dls.hand.duplicate(true),
		"combat_result": combat_result,
	}

func refresh_hud() -> void:
	if hud != null:
		hud.refresh(get_view_model())

func player_play_card(card_id: String) -> Dictionary:
	if combat_result != "in_progress":
		return {"ok": false, "reason": "ERR_COMBAT_COMPLETE"}
	if energy <= 0:
		return {"ok": false, "reason": "ERR_NOT_ENOUGH_ENERGY"}

	var resolved_card_id: String = card_id
	if not _hand_has_exact(card_id):
		var prefix_match: String = _first_card_by_prefix(card_id.split("_")[0])
		if prefix_match != "":
			resolved_card_id = prefix_match

	var submit: Dictionary = tsre.submit_play_intent({"card_id": resolved_card_id})
	if not submit.get("ok", false):
		return submit

	var committed: Dictionary = dls.commit_play(resolved_card_id)
	if not committed.get("ok", false):
		return committed

	energy -= 1
	queue.enqueue({
		"turn_index": tsre.turn_index,
		"phase_index": tsre.phase_index,
		"timing_window_priority": 1,
		"speed_class_priority": 1,
		"source_instance_id": card_id,
		"effect": _card_to_effect(card_id)
	})
	tsre.resolve_lock = true
	_resolve_queue_once()
	tsre.resolve_lock = false
	_record_event("play_commit", {"card_id": card_id, "energy_after": energy})
	_check_combat_end()
	refresh_hud()
	return {"ok": true}

func player_pass() -> Dictionary:
	if combat_result != "in_progress":
		return {"ok": false, "reason": "ERR_COMBAT_COMPLETE"}
	var pass_result: Dictionary = tsre.submit_pass()
	if not pass_result.get("ok", false):
		return pass_result

	_record_event("pass", {"turn": tsre.turn_index})
	tsre.transition_to(tsre.PHASE_ENEMY)
	_enemy_take_turn()
	_check_combat_end()
	if combat_result == "in_progress":
		_start_next_turn()
	refresh_hud()
	return {"ok": true}

func _enemy_take_turn() -> void:
	var incoming: int = enemy_intent_damage
	var blocked: int = min(player_block, incoming)
	player_block -= blocked
	var hp_loss: int = max(0, incoming - blocked)
	player_hp = max(0, player_hp - hp_loss)
	_record_event("enemy_attack", {
		"incoming": incoming,
		"blocked": blocked,
		"hp_loss": hp_loss,
		"player_hp_after": player_hp,
	})

func _start_next_turn() -> void:
	tsre.transition_to(tsre.PHASE_TURN_END)
	tsre.turn_index += 1
	tsre.transition_to(tsre.PHASE_TURN_START)
	player_block = 0
	energy = TURN_ENERGY
	while dls.hand.size() < HAND_SIZE_TARGET:
		var drawn = dls.draw_one()
		if drawn == null:
			break
	enemy_intent_damage = _roll_enemy_intent_damage()
	_record_event("turn_start", {"turn": tsre.turn_index, "enemy_intent_damage": enemy_intent_damage})

func _roll_enemy_intent_damage() -> int:
	var draw: Dictionary = rng.draw_next("encounter.intent")
	# 5..8 damage deterministic band for prototype readability.
	return 5 + int(draw.get("value", 0)) % 4

func _resolve_queue_once() -> void:
	if not queue.has_items():
		return
	var item: Dictionary = queue.dequeue()
	var effect: Dictionary = item.get("effect", {})
	var result: Dictionary = erp.resolve_effect(effect, {})
	_apply_effect_result(result)
	dls.finalize_play(str(item.get("source_instance_id", "")), "discard")
	_record_event("effect_resolve", {"item": item, "result": result})

func _apply_effect_result(result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	var delta: Dictionary = result.get("delta", {})
	if delta.has("hp_delta"):
		# Negative hp_delta means damage to enemy in this prototype.
		var dmg: int = max(0, -int(delta.get("hp_delta", 0)))
		var blocked: int = min(enemy_block, dmg)
		enemy_block -= blocked
		var hp_loss: int = max(0, dmg - blocked)
		enemy_hp = max(0, enemy_hp - hp_loss)
	if delta.has("block_delta"):
		player_block += int(delta.get("block_delta", 0))
	if delta.has("draw_n"):
		for _i in range(int(delta.get("draw_n", 0))):
			dls.draw_one()

func _check_combat_end() -> void:
	if enemy_hp <= 0:
		combat_result = "player_win"
		tsre.transition_to(tsre.PHASE_COMBAT_END)
		_record_event("combat_end", {"result": combat_result, "turn": tsre.turn_index})
	elif player_hp <= 0:
		combat_result = "player_lose"
		tsre.transition_to(tsre.PHASE_COMBAT_END)
		_record_event("combat_end", {"result": combat_result, "turn": tsre.turn_index})

func run_fixture(path: String) -> Dictionary:
	var fixture: Dictionary = _read_json(path)
	if fixture.is_empty():
		return {"ok": false, "reason": "ERR_FIXTURE_READ_FAILED", "path": path}

	reset_battle(int(fixture.get("seed_root", 0)))

	var inputs: Array = fixture.get("inputs", [])
	for step in inputs:
		if combat_result != "in_progress":
			break
		_apply_step(step)

	_auto_finish_combat(12)

	var final_state: Dictionary = {
		"phase": tsre.phase,
		"turn_index": tsre.turn_index,
		"hand": dls.hand,
		"discard": dls.discard_pile,
		"exhaust": dls.exhaust_pile,
		"limbo": dls.limbo,
		"rng_cursors": rng.cursors,
		"player_hp": player_hp,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_block": enemy_block,
		"energy": energy,
		"combat_result": combat_result,
	}

	var final_state_hash: String = str(hash(JSON.stringify(final_state)))
	var event_sequence_hash: String = str(hash(JSON.stringify(event_stream)))

	return {
		"ok": true,
		"fixture_id": fixture.get("fixture_id", "unknown"),
		"final_state_hash": final_state_hash,
		"event_sequence_hash": event_sequence_hash,
		"rng_cursor_snapshot": rng.cursors,
		"event_count": event_stream.size(),
		"combat_result": combat_result,
		"turns_completed": tsre.turn_index,
	}

func _apply_step(step: Dictionary) -> void:
	var action: String = str(step.get("action", ""))
	match action:
		"play":
			var card_id: String = str(step.get("card_id", ""))
			var result: Dictionary = player_play_card(card_id)
			if not result.get("ok", false):
				_record_event("play_reject", result)
		"pass":
			player_pass()
		_:
			_record_event("unknown_action", step)

func _card_to_effect(card_id: String) -> Dictionary:
	if card_id.begins_with("strike"):
		return {"type": "deal_damage", "amount": 6}
	if card_id.begins_with("defend"):
		return {"type": "gain_block", "amount": 5}
	return {"type": "draw_n", "amount": 1}

func _auto_finish_combat(max_turns: int) -> void:
	while combat_result == "in_progress" and tsre.turn_index <= max_turns:
		while combat_result == "in_progress" and energy > 0:
			var strike_card: String = _first_card_by_prefix("strike")
			if strike_card != "":
				player_play_card(strike_card)
				continue
			var defend_card: String = _first_card_by_prefix("defend")
			if defend_card != "":
				player_play_card(defend_card)
				continue
			break
		if combat_result == "in_progress":
			player_pass()

func _first_card_by_prefix(prefix: String) -> String:
	for c in dls.hand:
		var card_id: String = str(c)
		if card_id.begins_with(prefix):
			return card_id
	return ""

func _hand_has_exact(card_id: String) -> bool:
	for c in dls.hand:
		if str(c) == card_id:
			return true
	return false

func _record_event(kind: String, payload: Dictionary) -> void:
	event_stream.append({
		"order_index": event_stream.size(),
		"kind": kind,
		"payload": payload,
	})

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
