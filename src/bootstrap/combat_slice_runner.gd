extends Control
class_name CombatSliceRunner

const FIXTURE_PATH := "res://tests/determinism/fixtures/seed_smoke_001.json"
const TSRE_SCRIPT := preload("res://src/core/tsre/tsre.gd")
const ACTION_QUEUE_SCRIPT := preload("res://src/core/tsre/action_queue.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const ERP_SCRIPT := preload("res://src/core/erp/erp.gd")
const DLS_SCRIPT := preload("res://src/core/dls/deck_lifecycle.gd")
const REWARD_DRAFT_SCRIPT := preload("res://src/core/reward/reward_draft.gd")

const PLAYER_MAX_HP := 40
const ENEMY_MAX_HP := 24
const HAND_SIZE_TARGET := 5
const TURN_ENERGY := 3
const STARTER_RUN_DECK := [
	"strike_01", "strike_02", "defend_01", "strike_03", "defend_02",
	"strike_04", "defend_03", "strike_05", "defend_04", "strike_06"
]

var tsre: Variant
var queue: Variant
var rng: Variant
var erp: Variant
var dls: Variant
var reward_draft: Variant
var hud: Variant

var event_stream: Array[Dictionary] = []
var effect_resolve_draw_annotations: Dictionary = {}

var player_hp: int = PLAYER_MAX_HP
var player_block: int = 0
var enemy_hp: int = ENEMY_MAX_HP
var enemy_block: int = 0
var energy: int = TURN_ENERGY
var enemy_intent_damage: int = 6
var combat_result: String = "in_progress"
var last_event_text: String = "Battle ready"
var last_reject_reason: String = ""
var last_resolved_queue_item: Dictionary = {}
var run_master_deck: Array = []
var reward_state: String = "none"
var reward_checkpoint_id: String = ""
var reward_draft_instance_id: String = ""
var reward_offer: Array[Dictionary] = []
var reward_selected_card_id: String = ""
var reward_summary_text: String = ""
var reward_checkpoint_count: int = 0
var reward_commit_count: int = 0
var encounter_index: int = 1

func _ready() -> void:
	tsre = TSRE_SCRIPT.new()
	queue = ACTION_QUEUE_SCRIPT.new()
	rng = RSGC_SCRIPT.new()
	erp = ERP_SCRIPT.new()
	dls = DLS_SCRIPT.new()
	reward_draft = REWARD_DRAFT_SCRIPT.new()
	hud = $CombatHud
	hud.bind_runner(self)
	reset_battle(13371337)

func reset_battle(seed_root: int = 13371337) -> void:
	rng.bootstrap(seed_root)
	event_stream.clear()
	effect_resolve_draw_annotations.clear()

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
	last_event_text = "Battle ready"
	last_reject_reason = ""
	last_resolved_queue_item = {}
	run_master_deck = STARTER_RUN_DECK.duplicate(true)
	reward_state = "none"
	reward_checkpoint_id = ""
	reward_draft_instance_id = ""
	reward_offer = []
	reward_selected_card_id = ""
	reward_summary_text = ""
	reward_checkpoint_count = 0
	reward_commit_count = 0
	encounter_index = 1

	_bootstrap_demo_state()
	enemy_intent_damage = _roll_enemy_intent_damage()
	_record_event("encounter_start", {"encounter_index": encounter_index, "turn": tsre.turn_index})
	refresh_hud()

func _bootstrap_demo_state() -> void:
	dls.draw_pile = run_master_deck.duplicate(true)
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
		"ui_phase_text": tsre.get_ui_phase_label(),
		"resolve_lock": tsre.resolve_lock,
		"player_hp": player_hp,
		"player_max_hp": PLAYER_MAX_HP,
		"player_block": player_block,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": ENEMY_MAX_HP,
		"enemy_block": enemy_block,
		"energy": energy,
		"turn_energy_max": TURN_ENERGY,
		"enemy_intent_damage": enemy_intent_damage,
		"hand": dls.hand.duplicate(true),
		"zones": {
			"draw": dls.draw_pile.size(),
			"discard": dls.discard_pile.size(),
			"exhaust": dls.exhaust_pile.size(),
			"limbo": dls.limbo.size(),
		},
		"queue_preview": queue.snapshot(),
		"last_resolved_queue_item": last_resolved_queue_item.duplicate(true),
		"play_gate_reason": _get_play_gate_reason(),
		"pass_gate_reason": _get_pass_gate_reason(),
		"last_reject_reason": last_reject_reason,
		"recent_events": _get_recent_event_lines(4),
		"reward_state": reward_state,
		"reward_checkpoint_id": reward_checkpoint_id,
		"reward_draft_instance_id": reward_draft_instance_id,
		"reward_offer": reward_offer.duplicate(true),
		"reward_selected_card_id": reward_selected_card_id,
		"reward_summary_text": reward_summary_text,
		"reward_checkpoint_count": reward_checkpoint_count,
		"reward_commit_count": reward_commit_count,
		"run_master_deck_size": run_master_deck.size(),
		"encounter_index": encounter_index,
		"encounter_title": _encounter_title(),
		"encounter_intent_style": _encounter_intent_style(),
		"encounter_intro_flavor": _encounter_intro_flavor(),
		"combat_result": combat_result,
		"last_event_text": last_event_text,
	}

func refresh_hud() -> void:
	if hud != null:
		hud.refresh(get_view_model())

func player_play_card(card_id: String) -> Dictionary:
	var play_gate_reason: String = _get_play_gate_reason()
	if play_gate_reason != "":
		_remember_reject(play_gate_reason)
		refresh_hud()
		return {"ok": false, "reason": play_gate_reason}

	var resolved_card_id: String = card_id
	if not _hand_has_exact(card_id):
		var prefix_match: String = _first_card_by_prefix(card_id.split("_")[0])
		if prefix_match != "":
			resolved_card_id = prefix_match

	var submit: Dictionary = tsre.submit_play_intent({"card_id": resolved_card_id})
	if not submit.get("ok", false):
		_remember_reject(str(submit.get("reason", "")))
		refresh_hud()
		return submit

	var committed: Dictionary = dls.commit_play(resolved_card_id)
	if not committed.get("ok", false):
		_remember_reject(str(committed.get("reason", "")))
		refresh_hud()
		return committed

	_clear_reject()
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
	var pass_gate_reason: String = _get_pass_gate_reason()
	if pass_gate_reason != "":
		_remember_reject(pass_gate_reason)
		refresh_hud()
		return {"ok": false, "reason": pass_gate_reason}
	var pass_result: Dictionary = tsre.submit_pass()
	if not pass_result.get("ok", false):
		_remember_reject(str(pass_result.get("reason", "")))
		refresh_hud()
		return pass_result

	_clear_reject()
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

func _encounter_title() -> String:
	match encounter_index:
		1:
			return "Encounter 1 • Ambush Patrol"
		2:
			return "Encounter 2 • Warden Counterpush"
		_:
			return "Encounter %d • Escalation" % encounter_index

func _encounter_intent_style() -> String:
	match encounter_index:
		1:
			return "Steady pressure"
		2:
			return "Aggressive opener"
		_:
			return "Escalating pattern"

func _encounter_intro_flavor() -> String:
	match encounter_index:
		1:
			return "Scout whistles echo through the corridor."
		2:
			return "Heavy boots thunder as the warden rushes in."
		_:
			return "The dungeon stirs with a harsher tempo."

func _resolve_queue_once() -> void:
	if not queue.has_items():
		return
	var item: Dictionary = queue.dequeue()
	last_resolved_queue_item = item.duplicate(true)
	var effect: Dictionary = item.get("effect", {})
	var result: Dictionary = erp.resolve_effect(effect, {})
	var drawn_cards: Array = _apply_effect_result(result)
	dls.finalize_play(str(item.get("source_instance_id", "")), "discard")
	_record_event("effect_resolve", {"item": item, "result": result})
	if not drawn_cards.is_empty():
		effect_resolve_draw_annotations[event_stream.size() - 1] = drawn_cards.duplicate(true)

func _apply_effect_result(result: Dictionary) -> Array:
	var drawn_cards: Array = []
	if not result.get("ok", false):
		return drawn_cards
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
			var drawn: Variant = dls.draw_one()
			if drawn != null:
				drawn_cards.append(str(drawn))
	return drawn_cards

func _check_combat_end() -> void:
	if combat_result != "in_progress":
		return
	if enemy_hp <= 0:
		combat_result = "player_win"
		tsre.transition_to(tsre.PHASE_COMBAT_END)
		_record_event("combat_end", {"result": combat_result, "turn": tsre.turn_index})
		_present_reward_checkpoint()
	elif player_hp <= 0:
		combat_result = "player_lose"
		tsre.transition_to(tsre.PHASE_COMBAT_END)
		_record_event("combat_end", {"result": combat_result, "turn": tsre.turn_index})

func choose_reward_by_index(offer_index: int) -> Dictionary:
	if offer_index < 0 or offer_index >= reward_offer.size():
		_remember_reject("ERR_INVALID_REWARD_SELECTION")
		refresh_hud()
		return {"ok": false, "reason": "ERR_INVALID_REWARD_SELECTION", "offer_index": offer_index}
	var reward: Dictionary = reward_offer[offer_index]
	return choose_reward(str(reward.get("card_id", "")))

func choose_reward(card_id: String) -> Dictionary:
	if reward_state != "presented":
		_remember_reject("ERR_REWARD_NOT_AVAILABLE")
		refresh_hud()
		return {"ok": false, "reason": "ERR_REWARD_NOT_AVAILABLE"}
	if not _reward_offer_has_card(card_id):
		_remember_reject("ERR_INVALID_REWARD_SELECTION")
		refresh_hud()
		return {"ok": false, "reason": "ERR_INVALID_REWARD_SELECTION", "card_id": card_id}

	_clear_reject()
	reward_selected_card_id = card_id
	reward_commit_count += 1
	reward_state = "applied"
	run_master_deck.append(card_id)
	dls.discard_pile.append(card_id)
	reward_summary_text = "Added %s to discard. Deck now %d cards." % [_display_name_for_card(card_id), run_master_deck.size()]
	_record_event("reward_pick", {
		"draft_instance_id": reward_draft_instance_id,
		"checkpoint_id": reward_checkpoint_id,
		"card_id": card_id,
		"run_master_deck_size": run_master_deck.size(),
	})
	refresh_hud()
	return {"ok": true, "card_id": card_id}

func dismiss_reward_checkpoint() -> void:
	if reward_state != "applied":
		return
	reward_state = "closed"
	_record_event("reward_checkpoint_closed", {
		"draft_instance_id": reward_draft_instance_id,
		"checkpoint_id": reward_checkpoint_id,
		"selected_card_id": reward_selected_card_id,
	})
	refresh_hud()

func start_next_encounter() -> void:
	if reward_state != "applied" and reward_state != "closed":
		_remember_reject("ERR_REWARD_NOT_AVAILABLE")
		refresh_hud()
		return
	encounter_index += 1
	combat_result = "in_progress"
	reward_state = "none"
	reward_checkpoint_id = ""
	reward_draft_instance_id = ""
	reward_offer = []
	reward_summary_text = "Using rewarded card in the next encounter."
	last_reject_reason = ""
	last_resolved_queue_item = {}
	tsre.phase = tsre.PHASE_TURN_START
	tsre.turn_index = 1
	tsre.phase_index = 0
	tsre.resolve_lock = false
	player_hp = PLAYER_MAX_HP
	player_block = 0
	enemy_hp = ENEMY_MAX_HP
	enemy_block = 0
	energy = TURN_ENERGY
	_bootstrap_demo_state()
	enemy_intent_damage = _roll_enemy_intent_damage()
	_record_event("encounter_start", {"encounter_index": encounter_index, "turn": tsre.turn_index, "reward_card_id": reward_selected_card_id})
	refresh_hud()

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

	var post_combat_inputs: Array = fixture.get("post_combat_inputs", [])
	for step in post_combat_inputs:
		_apply_step(step)

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
		"run_master_deck": run_master_deck,
		"reward_state": reward_state,
		"reward_checkpoint_id": reward_checkpoint_id,
		"reward_draft_instance_id": reward_draft_instance_id,
		"reward_offer_card_ids": _reward_offer_card_ids(),
		"reward_selected_card_id": reward_selected_card_id,
		"reward_summary_text": reward_summary_text,
		"reward_checkpoint_count": reward_checkpoint_count,
		"reward_commit_count": reward_commit_count,
		"encounter_index": encounter_index,
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
		"reward_state": reward_state,
		"reward_offer_card_ids": _reward_offer_card_ids(),
		"reward_selected_card_id": reward_selected_card_id,
		"reward_checkpoint_count": reward_checkpoint_count,
		"reward_commit_count": reward_commit_count,
		"run_master_deck_size": run_master_deck.size(),
		"encounter_index": encounter_index,
		"encounter_title": _encounter_title(),
		"encounter_intent_style": _encounter_intent_style(),
		"encounter_intro_flavor": _encounter_intro_flavor(),
		"hand": dls.hand,
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
		"pick_reward":
			var pick_result: Dictionary = choose_reward_by_index(int(step.get("offer_index", -1)))
			if not pick_result.get("ok", false):
				_record_event("reward_reject", pick_result)
		"continue_reward":
			start_next_encounter()
		"auto_finish":
			_auto_finish_combat(int(step.get("max_turns", 12)))
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

func _get_play_gate_reason() -> String:
	if combat_result != "in_progress":
		return "ERR_COMBAT_COMPLETE"
	var input_gate: Dictionary = tsre.get_input_gate()
	if not input_gate.get("ok", false):
		return str(input_gate.get("reason", ""))
	if energy <= 0:
		return "ERR_NOT_ENOUGH_ENERGY"
	return ""

func _get_pass_gate_reason() -> String:
	if combat_result != "in_progress":
		return "ERR_COMBAT_COMPLETE"
	var input_gate: Dictionary = tsre.get_input_gate()
	if not input_gate.get("ok", false):
		return str(input_gate.get("reason", ""))
	return ""

func _remember_reject(reason: String) -> void:
	last_reject_reason = reason

func _clear_reject() -> void:
	last_reject_reason = ""

func _present_reward_checkpoint() -> void:
	reward_checkpoint_count += 1
	reward_checkpoint_id = "combat_clear_%d" % tsre.turn_index
	var draft: Dictionary = reward_draft.build_card_offer(rng, reward_checkpoint_id, [])
	reward_draft_instance_id = str(draft.get("draft_instance_id", ""))
	reward_offer = draft.get("offers", []).duplicate(true)
	reward_selected_card_id = ""
	reward_summary_text = "Choose 1 of 3 cards to add to your deck."
	reward_state = "presented"
	_record_event("reward_offer", {
		"checkpoint_id": reward_checkpoint_id,
		"draft_instance_id": reward_draft_instance_id,
		"offer_card_ids": _reward_offer_card_ids(),
	})

func _reward_offer_card_ids() -> Array:
	var ids: Array = []
	for offer in reward_offer:
		ids.append(str(offer.get("card_id", "")))
	return ids

func _reward_offer_has_card(card_id: String) -> bool:
	for offer in reward_offer:
		if str(offer.get("card_id", "")) == card_id:
			return true
	return false

func _display_name_for_card(card_id: String) -> String:
	if card_id.begins_with("strike"):
		return "Strike"
	if card_id.begins_with("defend"):
		return "Defend"
	if card_id.begins_with("scheme"):
		return "Scheme"
	return card_id.capitalize()

func _get_recent_event_lines(limit: int = 4) -> Array:
	var lines: Array = []
	var start: int = max(0, event_stream.size() - limit)
	for i in range(start, event_stream.size()):
		lines.append(_format_event_line(event_stream[i]))
	if lines.is_empty():
		lines.append("Battle ready.")
	return lines

func _format_event_line(event: Dictionary) -> String:
	var order_index: int = int(event.get("order_index", 0))
	var kind: String = str(event.get("kind", "event"))
	var payload: Dictionary = event.get("payload", {})
	match kind:
		"play_commit":
			return "#%d Played %s. Energy %d." % [
				order_index,
				str(payload.get("card_id", "-")),
				int(payload.get("energy_after", 0)),
			]
		"effect_resolve":
			var item: Dictionary = payload.get("item", {})
			var base_line := "#%d Resolve %s via timing %d -> speed %d -> seq %d." % [
				order_index,
				str(item.get("source_instance_id", "-")),
				int(item.get("timing_window_priority", 0)),
				int(item.get("speed_class_priority", 0)),
				int(item.get("enqueue_sequence_id", 0)),
			]
			var drawn_cards: Array = effect_resolve_draw_annotations.get(order_index, [])
			if not drawn_cards.is_empty():
				return "%s Drew: %s." % [base_line, ", ".join(drawn_cards)]
			return base_line
		"enemy_attack":
			return "#%d Enemy hit for %d (%d blocked, %d HP lost)." % [
				order_index,
				int(payload.get("incoming", 0)),
				int(payload.get("blocked", 0)),
				int(payload.get("hp_loss", 0)),
			]
		"pass":
			return "#%d Passed turn." % order_index
		"turn_start":
			return "#%d Turn %d. Enemy intent %d." % [
				order_index,
				int(payload.get("turn", 0)),
				int(payload.get("enemy_intent_damage", 0)),
			]
		"combat_end":
			return "#%d Combat ended: %s." % [
				order_index,
				str(payload.get("result", "-")),
			]
		"reward_offer":
			return "#%d Reward checkpoint opened: %s." % [
				order_index,
				", ".join(payload.get("offer_card_ids", [])),
			]
		"reward_pick":
			return "#%d Reward claimed: %s." % [
				order_index,
				_display_name_for_card(str(payload.get("card_id", "-"))),
			]
		"reward_checkpoint_closed":
			return "#%d Reward panel closed." % order_index
		_:
			return "#%d %s" % [order_index, kind]

func _record_event(kind: String, payload: Dictionary) -> void:
	last_event_text = "%s %s" % [kind, JSON.stringify(payload)]
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
