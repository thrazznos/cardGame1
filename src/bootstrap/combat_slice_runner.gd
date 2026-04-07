extends Control
class_name CombatSliceRunner

const FIXTURE_PATH := "res://tests/determinism/fixtures/seed_smoke_001.json"
const TSRE_SCRIPT := preload("res://src/core/tsre/tsre.gd")
const ACTION_QUEUE_SCRIPT := preload("res://src/core/tsre/action_queue.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const ERP_SCRIPT := preload("res://src/core/erp/erp.gd")
const DLS_SCRIPT := preload("res://src/core/dls/deck_lifecycle.gd")
const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")
const REWARD_DRAFT_SCRIPT := preload("res://src/core/reward/reward_draft.gd")
const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")
const CARD_PRESENTER_SCRIPT := preload("res://src/core/card/card_presenter.gd")
const CARD_INSTANCE_SCRIPT := preload("res://src/core/card/card_instance.gd")

const PRESSURE_PROFILES_PATH := "res://data/encounters/pressure_profiles_v1.json"
const PLAYER_MAX_HP := 40
const DEFAULT_ENEMY_MAX_HP := 24
const HAND_SIZE_TARGET := 5
const TURN_ENERGY := 3

const FIXTURE_STARTER_RUN_DECK := [
	"strike_01", "strike_02", "defend_01", "strike_03", "defend_02",
	"strike_04", "defend_03", "strike_05", "defend_04", "strike_06"
]

var tsre: Variant
var queue: Variant
var rng: Variant
var erp: Variant
var dls: Variant
var gsm: Variant
var reward_draft: Variant
var card_catalog: Variant
var card_presenter: Variant
var card_instance: Variant
var hud: Variant

var event_stream: Array[Dictionary] = []
var effect_resolve_draw_annotations: Dictionary = {}
var pressure_profiles: Dictionary = {}
var encounter_sequence: Array = []

var player_hp: int = PLAYER_MAX_HP
var player_block: int = 0
var enemy_max_hp: int = DEFAULT_ENEMY_MAX_HP
var enemy_hp: int = DEFAULT_ENEMY_MAX_HP
var enemy_block: int = 0
var energy: int = TURN_ENERGY
var enemy_intent: Dictionary = {}
var combat_result: String = "in_progress"
var active_profile: Dictionary = {}
var cycle_step: int = 0
var floor_runner: Variant = null
var use_external_gsm: bool = false
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
	gsm = GSM_SCRIPT.new()
	card_catalog = CARD_CATALOG_SCRIPT.new()
	card_presenter = CARD_PRESENTER_SCRIPT.new()
	card_instance = CARD_INSTANCE_SCRIPT.new()
	reward_draft = REWARD_DRAFT_SCRIPT.new()
	reward_draft.set_card_catalog(card_catalog)
	_load_pressure_profiles()
	hud = $CombatHud
	hud.bind_runner(self)
	# Don't auto-start if we're a child of a floor runner
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.has_method("on_combat_complete"):
		floor_runner = parent_node
		use_external_gsm = false  # Will be set true when floor launches combat
	else:
		reset_battle(13371337)

func reset_battle(seed_root: int = 13371337) -> void:
	rng.bootstrap(seed_root)
	event_stream.clear()
	effect_resolve_draw_annotations.clear()
	if not use_external_gsm:
		gsm = GSM_SCRIPT.new()

	tsre.phase = tsre.PHASE_TURN_START
	tsre.turn_index = 1
	tsre.phase_index = 0
	tsre.resolve_lock = false

	active_profile = _profile_for_encounter(encounter_index)
	cycle_step = 0
	enemy_max_hp = int(active_profile.get("enemy_hp_base", DEFAULT_ENEMY_MAX_HP))
	player_hp = PLAYER_MAX_HP
	player_block = 0
	enemy_hp = enemy_max_hp
	enemy_block = 0
	energy = TURN_ENERGY
	combat_result = "in_progress"
	last_event_text = "Battle ready"
	last_reject_reason = ""
	last_resolved_queue_item = {}
	run_master_deck = card_catalog.starter_run_deck()
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
	enemy_intent = _roll_enemy_intent()
	_record_event("encounter_start", {
		"encounter_index": encounter_index,
		"turn": tsre.turn_index,
		"profile_id": str(active_profile.get("profile_id", "steady")),
	})
	refresh_hud()

func _bootstrap_demo_state() -> void:
	dls.draw_pile = _card_instance_array(run_master_deck, _encounter_runtime_scope("draw"))
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
		"enemy_max_hp": enemy_max_hp,
		"enemy_block": enemy_block,
		"energy": energy,
		"turn_energy_max": TURN_ENERGY,
		"enemy_intent_damage": int(enemy_intent.get("damage", 0)),
		"enemy_intent": enemy_intent.duplicate(true),
		"pressure_profile_id": str(active_profile.get("profile_id", "steady")),
		"pressure_profile_name": str(active_profile.get("display_name", "Steady Pressure")),
		"hand": _zone_instance_ids(dls.hand),
		"hand_card_ids": _zone_card_ids(dls.hand),
		"hand_play_reasons": _zone_play_reasons(dls.hand),
		"zones": {
			"draw": dls.draw_pile.size(),
			"discard": dls.discard_pile.size(),
			"exhaust": dls.exhaust_pile.size(),
			"limbo": dls.limbo.size(),
		},
		"focus": gsm.focus_snapshot(),
		"gem_stack": gsm.stack_snapshot(),
		"gem_stack_top": _gem_stack_top_window(3),
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

func player_play_card(instance_id: String) -> Dictionary:
	var play_gate_reason: String = _get_play_gate_reason()
	if play_gate_reason != "":
		return _reject_play(instance_id, {"ok": false, "reason": play_gate_reason})

	var source_instance_id: String = instance_id
	var selected_card: Variant = _hand_card_entry(source_instance_id)
	if selected_card == null:
		return _reject_play(source_instance_id, {"ok": false, "reason": "ERR_CARD_NOT_IN_HAND", "card_id": instance_id})
	var resolved_card_id: String = _card_instance_card_id(selected_card)
	if resolved_card_id == "" or card_catalog == null or not card_catalog.has_card(resolved_card_id):
		return _reject_play(source_instance_id, {
			"ok": false,
			"reason": "ERR_CARD_DEFINITION_NOT_FOUND",
			"instance_id": source_instance_id,
			"card_id": resolved_card_id,
		})
	var card_reject_reason: String = _card_play_reject_reason(selected_card)
	if card_reject_reason != "":
		return _reject_play(source_instance_id, {
			"ok": false,
			"reason": card_reject_reason,
			"instance_id": source_instance_id,
			"card_id": resolved_card_id,
		})
	var play_cost: int = _card_play_cost(selected_card)

	var submit: Dictionary = tsre.submit_play_intent({
		"card_id": resolved_card_id,
		"source_instance_id": source_instance_id,
	})
	if not submit.get("ok", false):
		return _reject_play(source_instance_id, submit)

	var committed: Dictionary = dls.commit_play(source_instance_id)
	if not committed.get("ok", false):
		return _reject_play(source_instance_id, committed)
	var committed_card: Variant = committed.get("card", selected_card)
	resolved_card_id = _card_instance_card_id(committed_card)

	_clear_reject()
	energy -= play_cost
	queue.enqueue({
		"turn_index": tsre.turn_index,
		"phase_index": tsre.phase_index,
		"timing_window_priority": _card_timing_window_priority(committed_card),
		"speed_class_priority": _card_speed_class_priority(committed_card),
		"source_instance_id": source_instance_id,
		"card_id": resolved_card_id,
		"effect": _card_to_effect(committed_card)
	})
	tsre.resolve_lock = true
	_resolve_queue_once()
	tsre.resolve_lock = false
	_record_event("play_commit", {
		"card_id": source_instance_id,
		"energy_after": energy,
	})
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
	var intent_type: String = str(enemy_intent.get("intent_type", "attack"))
	var incoming: int = int(enemy_intent.get("damage", 0))
	var blocked: int = min(player_block, incoming)
	player_block -= blocked
	var hp_loss: int = max(0, incoming - blocked)
	player_hp = max(0, player_hp - hp_loss)

	var event_payload: Dictionary = {
		"intent_type": intent_type,
		"incoming": incoming,
		"blocked": blocked,
		"hp_loss": hp_loss,
		"player_hp_after": player_hp,
	}

	var block_gain: int = int(enemy_intent.get("block_gain", 0))
	if block_gain > 0:
		enemy_block += block_gain
		event_payload["enemy_block_gain"] = block_gain

	var energy_drain_amount: int = int(enemy_intent.get("energy_drain", 0))
	if energy_drain_amount > 0:
		event_payload["energy_drain"] = energy_drain_amount

	var discard_count: int = int(enemy_intent.get("discard_count", 0))
	if discard_count > 0:
		var discarded: Array = _force_discard_random(discard_count)
		event_payload["force_discarded"] = discarded

	_record_event("enemy_attack", event_payload)

func _force_discard_random(count: int) -> Array:
	var discarded: Array = []
	for _i in range(count):
		if dls.hand.is_empty():
			break
		var draw: Dictionary = rng.draw_next("encounter.targeting")
		var idx: int = int(draw.get("value", 0)) % dls.hand.size()
		var card: Dictionary = dls.hand.pop_at(idx)
		dls.discard_pile.append(card)
		discarded.append(_card_instance_id(card))
	return discarded

func _start_next_turn() -> void:
	tsre.transition_to(tsre.PHASE_TURN_END)
	tsre.turn_index += 1
	tsre.transition_to(tsre.PHASE_TURN_START)
	player_block = 0
	energy = TURN_ENERGY
	var energy_drain_amount: int = int(enemy_intent.get("energy_drain", 0))
	if energy_drain_amount > 0:
		energy = max(0, energy - energy_drain_amount)
	while dls.hand.size() < HAND_SIZE_TARGET:
		var drawn = dls.draw_one()
		if drawn == null:
			break
	enemy_intent = _roll_enemy_intent()
	var turn_start_payload: Dictionary = {
		"turn": tsre.turn_index,
		"enemy_intent_damage": int(enemy_intent.get("damage", 0)),
		"enemy_intent_type": str(enemy_intent.get("intent_type", "attack")),
	}
	if energy_drain_amount > 0:
		turn_start_payload["energy_drained"] = energy_drain_amount
		turn_start_payload["energy_after_drain"] = energy
	_record_event("turn_start", turn_start_payload)

func _roll_enemy_intent() -> Dictionary:
	var script_mode: String = str(active_profile.get("script_mode", "fixed_cycle"))
	match script_mode:
		"fixed_cycle":
			return _roll_fixed_cycle_intent()
		"state_reactive":
			return _roll_escalating_intent()
		"weighted_policy":
			return _roll_weighted_intent()
		_:
			return _roll_fixed_cycle_intent()

func _roll_fixed_cycle_intent() -> Dictionary:
	var cycle: Array = active_profile.get("cycle", [])
	if cycle.is_empty():
		return _fallback_intent()
	var step: Dictionary = cycle[cycle_step % cycle.size()]
	cycle_step += 1
	var damage: int = _roll_damage_in_range(
		int(step.get("damage_min", 5)),
		int(step.get("damage_max", 8))
	)
	damage += _enrage_bonus()
	var intent: Dictionary = {
		"intent_type": str(step.get("intent_type", "attack")),
		"damage": damage,
		"telegraph_text": _format_telegraph(step, damage),
	}
	if step.has("block_gain"):
		intent["block_gain"] = int(step.get("block_gain", 0))
	return intent

func _roll_escalating_intent() -> Dictionary:
	var base_min: int = int(active_profile.get("base_damage_min", 3))
	var base_max: int = int(active_profile.get("base_damage_max", 4))
	var per_turn: int = int(active_profile.get("escalation_per_turn", 1))
	var cap: int = int(active_profile.get("escalation_cap", 8))
	var escalation: int = min((tsre.turn_index - 1) * per_turn, cap)
	var damage: int = _roll_damage_in_range(base_min + escalation, base_max + escalation)
	damage += _enrage_bonus()
	var cycle: Array = active_profile.get("cycle", [])
	var step: Dictionary = cycle[0] if not cycle.is_empty() else {}
	return {
		"intent_type": "attack",
		"damage": damage,
		"telegraph_text": _format_telegraph(step, damage),
	}

func _roll_weighted_intent() -> Dictionary:
	var weights: Dictionary = active_profile.get("intent_weights", {})
	var cycle: Array = active_profile.get("cycle", [])
	if weights.is_empty() or cycle.is_empty():
		return _fallback_intent()

	var candidates: Array = []
	var cumulative: Array = []
	var total: int = 0
	for step in cycle:
		var intent_type: String = str(step.get("intent_type", "attack"))
		var w: int = int(weights.get(intent_type, 0))
		if w <= 0:
			continue
		total += w
		candidates.append(step)
		cumulative.append(total)

	if total <= 0 or candidates.is_empty():
		return _fallback_intent()

	var draw: Dictionary = rng.draw_next("encounter.intent")
	var roll: int = int(draw.get("value", 0)) % total
	var selected: Dictionary = candidates[0]
	for i in range(cumulative.size()):
		if roll < int(cumulative[i]):
			selected = candidates[i]
			break

	var damage: int = _roll_damage_in_range(
		int(selected.get("damage_min", 3)),
		int(selected.get("damage_max", 5))
	)
	damage += _enrage_bonus()
	var intent: Dictionary = {
		"intent_type": str(selected.get("intent_type", "attack")),
		"damage": damage,
		"telegraph_text": _format_telegraph(selected, damage),
	}
	if selected.has("energy_drain"):
		intent["energy_drain"] = int(selected.get("energy_drain", 0))
	if selected.has("discard_count"):
		intent["discard_count"] = int(selected.get("discard_count", 0))
	return intent

func _roll_damage_in_range(dmg_min: int, dmg_max: int) -> int:
	if dmg_min >= dmg_max:
		return dmg_min
	var draw: Dictionary = rng.draw_next("encounter.intent")
	var spread: int = dmg_max - dmg_min + 1
	return dmg_min + int(draw.get("value", 0)) % spread

func _enrage_bonus() -> int:
	var enrage_start: int = int(active_profile.get("enrage_start_turn", 12))
	var enrage_step: int = int(active_profile.get("enrage_damage_step", 1))
	if tsre.turn_index < enrage_start:
		return 0
	return (tsre.turn_index - enrage_start + 1) * enrage_step

func _fallback_intent() -> Dictionary:
	var draw: Dictionary = rng.draw_next("encounter.intent")
	return {
		"intent_type": "attack",
		"damage": 5 + int(draw.get("value", 0)) % 4,
		"telegraph_text": "Attack",
	}

func _format_telegraph(step: Dictionary, damage: int) -> String:
	var template: String = str(step.get("telegraph_text", "Attack for {dmg}"))
	template = template.replace("{dmg}", str(damage))
	template = template.replace("{block}", str(int(step.get("block_gain", 0))))
	template = template.replace("{drain}", str(int(step.get("energy_drain", 0))))
	template = template.replace("{discard}", str(int(step.get("discard_count", 0))))
	return template

func _encounter_title() -> String:
	var seq: Dictionary = _sequence_for_encounter(encounter_index)
	var title: String = str(seq.get("title", ""))
	if title != "":
		return "Encounter %d • %s" % [encounter_index, title]
	return "Encounter %d • %s" % [encounter_index, str(active_profile.get("display_name", "Unknown"))]

func _encounter_intent_style() -> String:
	return str(active_profile.get("display_name", "Steady Pressure"))

func _encounter_intro_flavor() -> String:
	var seq: Dictionary = _sequence_for_encounter(encounter_index)
	var flavor: String = str(seq.get("flavor", ""))
	if flavor != "":
		return flavor
	return "The dungeon stirs with a harsher tempo."

func _resolve_queue_once() -> void:
	if not queue.has_items():
		return
	var item: Dictionary = queue.dequeue()
	last_resolved_queue_item = item.duplicate(true)
	var effect_payload: Variant = item.get("effect", {})
	var effect_list: Array = []
	var is_multi_effect: bool = effect_payload is Array
	if is_multi_effect:
		effect_list = (effect_payload as Array)
	elif effect_payload is Dictionary:
		effect_list = [effect_payload]
	else:
		effect_list = [{"type": "draw_n", "amount": 0}]

	for effect_entry in effect_list:
		if not (effect_entry is Dictionary):
			continue
		var effect: Dictionary = effect_entry
		var result: Dictionary = erp.resolve_effect(effect, {"gsm": gsm})
		var drawn_cards: Array = _apply_effect_result(result)
		var event_item: Dictionary = item.duplicate(true)
		event_item.erase("card_id")
		if is_multi_effect:
			_record_event("effect_resolve", {"item": event_item, "effect": effect, "result": result})
		else:
			_record_event("effect_resolve", {"item": event_item, "result": result})
		if not drawn_cards.is_empty():
			effect_resolve_draw_annotations[event_stream.size() - 1] = drawn_cards.duplicate(true)

	dls.finalize_play(str(item.get("source_instance_id", "")))

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
				drawn_cards.append(_card_instance_id(drawn))
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
		if floor_runner != null:
			floor_runner.on_combat_complete(combat_result)

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
	var reward_live_card: Dictionary = _live_runtime_card(card_id, _encounter_runtime_scope("reward"), reward_commit_count)
	reward_commit_count += 1
	reward_state = "applied"
	run_master_deck.append(card_id)
	dls.discard_pile.append(reward_live_card)
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
	# If running under a floor controller, hand control back to it
	if floor_runner != null:
		floor_runner.on_combat_complete(combat_result)
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
	active_profile = _profile_for_encounter(encounter_index)
	cycle_step = 0
	enemy_max_hp = int(active_profile.get("enemy_hp_base", DEFAULT_ENEMY_MAX_HP))
	player_hp = PLAYER_MAX_HP
	player_block = 0
	enemy_hp = enemy_max_hp
	enemy_block = 0
	energy = TURN_ENERGY
	_bootstrap_demo_state()
	enemy_intent = _roll_enemy_intent()
	_record_event("encounter_start", {
		"encounter_index": encounter_index,
		"turn": tsre.turn_index,
		"reward_card_id": reward_selected_card_id,
		"profile_id": str(active_profile.get("profile_id", "steady")),
	})
	refresh_hud()

func run_fixture(path: String) -> Dictionary:
	var fixture: Dictionary = _read_json(path)
	if fixture.is_empty():
		return {"ok": false, "reason": "ERR_FIXTURE_READ_FAILED", "path": path}

	reset_battle(int(fixture.get("seed_root", 0)))
	# Keep fixture baselines stable even as live starter deck evolves.
	run_master_deck = FIXTURE_STARTER_RUN_DECK.duplicate(true)
	_bootstrap_demo_state()

	var inputs: Array = fixture.get("inputs", [])
	for step in inputs:
		if combat_result != "in_progress":
			break
		_apply_step(step)

	_auto_finish_combat(int(fixture.get("auto_finish_max_turns", 12)))

	var post_combat_inputs: Array = fixture.get("post_combat_inputs", [])
	for step in post_combat_inputs:
		_apply_step(step)

	var final_state: Dictionary = {
		"phase": tsre.phase,
		"turn_index": tsre.turn_index,
		"hand": _zone_instance_ids(dls.hand),
		"discard": _zone_instance_ids(dls.discard_pile),
		"exhaust": _zone_instance_ids(dls.exhaust_pile),
		"limbo": _zone_instance_ids(dls.limbo),
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
		"hand": _zone_instance_ids(dls.hand),
		"hand_card_ids": _zone_card_ids(dls.hand),
		"discard": _zone_instance_ids(dls.discard_pile),
		"discard_card_ids": _zone_card_ids(dls.discard_pile),
	}

func _apply_step(step: Dictionary) -> void:
	var action: String = str(step.get("action", ""))
	match action:
		"set_hand":
			var cards: Array = step.get("cards", [])
			dls.hand = []
			for card in cards:
				dls.hand.append(_card_instance_value(card))
			if bool(step.get("clear_other_zones", false)):
				dls.draw_pile = []
				dls.discard_pile = []
				dls.exhaust_pile = []
				dls.limbo = []
			refresh_hud()
		"set_energy":
			energy = int(step.get("energy", energy))
			refresh_hud()
		"play":
			var play_token: String = str(step.get("instance_id", step.get("card_id", "")))
			player_play_card(play_token)
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

func _card_to_effect(card_value: Variant) -> Variant:
	var card_id: String = _card_instance_card_id(card_value)
	if card_catalog != null and card_catalog.has_card(card_id):
		return card_catalog.effects_for(card_id)
	return {"type": "invalid_card_definition", "card_id": card_id}

func _card_play_cost(card_value: Variant) -> int:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return 1
	return int(card_catalog.base_cost(card_id))

func _card_timing_window_priority(card_value: Variant) -> int:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return 1
	return int(card_catalog.timing_window_priority(card_id))

func _card_speed_class_priority(card_value: Variant) -> int:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return 1
	return int(card_catalog.speed_class_priority(card_id))

func _auto_finish_combat(max_turns: int) -> void:
	while combat_result == "in_progress" and tsre.turn_index <= max_turns:
		while combat_result == "in_progress" and energy > 0:
			var playable_card: String = _first_playable_card()
			if playable_card != "":
				player_play_card(playable_card)
				continue
			break
		if combat_result == "in_progress":
			player_pass()

func _first_playable_card() -> String:
	# Prefer attacks to end fights, then defends, then anything else.
	for c in dls.hand:
		var cid: String = _card_instance_card_id(c)
		if _card_play_reject_reason(c) == "" and _card_palette_tag(cid) == "attack":
			return _card_instance_id(c)
	for c in dls.hand:
		var cid: String = _card_instance_card_id(c)
		if _card_play_reject_reason(c) == "" and _card_palette_tag(cid) == "defend":
			return _card_instance_id(c)
	for c in dls.hand:
		if _card_play_reject_reason(c) == "":
			return _card_instance_id(c)
	return ""

func _card_palette_tag(card_id: String) -> String:
	if card_catalog == null or not card_catalog.has_card(card_id):
		return ""
	return str(card_catalog.palette_key(card_id))

func _first_card_by_resolved_id(target_card_id: String) -> String:
	for c in dls.hand:
		var instance_id: String = _card_instance_id(c)
		if _card_instance_card_id(c) == target_card_id:
			return instance_id
	return ""

func _hand_card_entry(instance_id: String) -> Variant:
	for c in dls.hand:
		if _card_instance_id(c) == instance_id:
			return c
	return null

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

func _zone_play_reasons(zone: Array) -> Array:
	var reasons: Array = []
	for card_value in zone:
		reasons.append(_card_play_reject_reason(card_value))
	return reasons

func _card_play_reject_reason(card_value: Variant) -> String:
	var global_reason: String = _get_play_gate_reason()
	if global_reason != "":
		return global_reason
	var play_condition_reason: String = _card_play_condition_reason(card_value)
	if play_condition_reason != "":
		return play_condition_reason
	var target_reason: String = _card_target_reason(card_value)
	if target_reason != "":
		return target_reason
	var play_cost: int = _card_play_cost(card_value)
	if energy < play_cost:
		return "ERR_NOT_ENOUGH_ENERGY"
	return ""

func _card_play_condition_reason(card_value: Variant) -> String:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return ""
	for condition_variant in card_catalog.play_conditions(card_id):
		if not (condition_variant is Dictionary):
			continue
		var condition: Dictionary = condition_variant
		var condition_id: String = str(condition.get("condition_id", "")).strip_edges()
		match condition_id:
			"focus_at_least":
				if gsm == null:
					return "ERR_FOCUS_REQUIRED"
				var required_focus: int = max(1, int(condition.get("amount", 1)))
				if int(gsm.focus_snapshot()) < required_focus:
					return "ERR_FOCUS_REQUIRED"
			_:
				pass
	return ""

func _card_target_reason(card_value: Variant) -> String:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "" or card_catalog == null or not card_catalog.has_card(card_id):
		return ""
	match card_catalog.target_mode(card_id):
		"single_enemy":
			if combat_result != "in_progress" or enemy_hp <= 0:
				return "ERR_NO_VALID_TARGETS"
	return ""

func _reject_play(source_instance_id: String, result: Dictionary) -> Dictionary:
	var payload: Dictionary = result.duplicate(true)
	if not payload.has("card_id"):
		payload["card_id"] = source_instance_id
	_remember_reject(str(payload.get("reason", "")))
	_record_event("play_reject", payload)
	refresh_hud()
	return payload

func _remember_reject(reason: String) -> void:
	last_reject_reason = reason

func _clear_reject() -> void:
	last_reject_reason = ""

func _present_reward_checkpoint() -> void:
	reward_checkpoint_count += 1
	reward_checkpoint_id = "combat_clear_%d" % tsre.turn_index
	var draft: Dictionary = reward_draft.build_card_offer(rng, _live_reward_context_for_checkpoint(reward_checkpoint_id), [])
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

func _live_reward_context_for_checkpoint(checkpoint_id: String) -> Dictionary:
	var reward_pool_tag: String = "base_reward"
	var active_unlock_key: String = "base_set"
	if reward_checkpoint_count >= 2 and _run_contains_unlock_key("gsm_set", 4) and _reward_pool_has_entries("gsm_reward", 3):
		reward_pool_tag = "gsm_reward"
		active_unlock_key = "gsm_set"
	return _reward_context(checkpoint_id, reward_pool_tag, active_unlock_key)

func _run_contains_unlock_key(target_unlock_key: String, minimum_count: int = 1) -> bool:
	if minimum_count <= 0:
		return true
	var match_count: int = 0
	for card_id_variant in run_master_deck:
		if _unlock_key_for_card(str(card_id_variant)) != target_unlock_key:
			continue
		match_count += 1
		if match_count >= minimum_count:
			return true
	return false

func _reward_pool_has_entries(reward_pool_tag: String, minimum_entries: int = 3) -> bool:
	if card_catalog == null:
		return false
	return card_catalog.reward_pool_entries(reward_pool_tag).size() >= minimum_entries

func _unlock_key_for_card(card_id: String) -> String:
	if card_catalog == null or not card_catalog.has_card(card_id):
		return "base_set"
	var card: Dictionary = card_catalog.get_card(card_id)
	var unlock_key: String = str(card.get("unlock_key", "base_set")).strip_edges()
	if unlock_key == "":
		return "base_set"
	return unlock_key

func _reward_context(checkpoint_id: String, reward_pool_tag: String, active_unlock_key: String) -> Dictionary:
	return {
		"checkpoint_id": checkpoint_id,
		"reward_pool_tag": reward_pool_tag,
		"active_unlock_key": active_unlock_key,
	}

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
	if card_presenter != null:
		return card_presenter.display_name(card_id)
	return card_id

func _event_card_label_from_ids(card_id: String, instance_id: String = "") -> String:
	var resolved_card_id: String = card_id.strip_edges()
	if card_instance != null and resolved_card_id != "":
		resolved_card_id = card_instance.card_id_of(resolved_card_id, card_catalog)
	var display_name: String = _display_name_for_card(resolved_card_id)
	var debug_instance_id: String = instance_id.strip_edges()
	if display_name == "":
		return debug_instance_id if debug_instance_id != "" else resolved_card_id
	if debug_instance_id != "" and debug_instance_id != resolved_card_id and debug_instance_id != display_name:
		return "%s [%s]" % [display_name, debug_instance_id]
	return display_name

func _reason_text(reason_code: String) -> String:
	match reason_code:
		"ERR_RESOLVE_LOCKED":
			return "Effects are resolving right now"
		"ERR_NOT_ENOUGH_ENERGY":
			return "you need 1 more energy"
		"ERR_COMBAT_COMPLETE":
			return "combat is already over"
		"ERR_NO_VALID_TARGETS":
			return "no valid target is available"
		"ERR_CARD_NOT_IN_HAND":
			return "that card is no longer in hand"
		"ERR_PHASE_DISALLOWS_INPUT":
			return "you cannot act during this phase"
		"ERR_REWARD_NOT_AVAILABLE":
			return "no reward is available right now"
		"ERR_REWARD_ALREADY_CLAIMED":
			return "this checkpoint reward was already claimed"
		"ERR_INVALID_REWARD_SELECTION":
			return "that reward choice is not valid"
		"ERR_FOCUS_REQUIRED":
			return "this advanced gem action requires FOCUS"
		"ERR_STACK_EMPTY":
			return "the gem stack is empty"
		"ERR_STACK_TOP_MISMATCH":
			return "top gem does not match this card"
		"ERR_STACK_TARGET_MISMATCH":
			return "targeted gem does not match this card"
		"ERR_SELECTOR_INVALID":
			return "that gem selector is out of range"
		_:
			return reason_code if reason_code != "" else "action unavailable"

func _reward_offer_display_text(card_ids: Array) -> String:
	var names: Array = []
	for card_id_variant in card_ids:
		names.append(_display_name_for_card(str(card_id_variant)))
	return ", ".join(names)

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
				_event_card_label_from_ids(str(payload.get("card_id", "-")), str(payload.get("card_id", "-"))),
				int(payload.get("energy_after", 0)),
			]
		"effect_resolve":
			var item: Dictionary = payload.get("item", {})
			var result: Dictionary = payload.get("result", {})
			var effect: Dictionary = payload.get("effect", item.get("effect", {}))
			var effect_type: String = str(effect.get("type", ""))
			var source_instance_id: String = str(item.get("source_instance_id", "-"))
			var source_label: String = _event_card_label_from_ids(str(item.get("card_id", source_instance_id)), source_instance_id)
			var base_line := "#%d Resolve %s via timing %d -> speed %d -> seq %d." % [
				order_index,
				source_label,
				int(item.get("timing_window_priority", 0)),
				int(item.get("speed_class_priority", 0)),
				int(item.get("enqueue_sequence_id", 0)),
			]
			if effect_type.begins_with("gem_"):
				if not bool(result.get("ok", false)):
					return "%s Gem op failed: %s." % [base_line, str(result.get("reason", "ERR_GEM_UNKNOWN"))]
				var stack_after: Array = result.get("stack_after", [])
				var stack_text: String = "(empty)"
				if not stack_after.is_empty():
					var stack_words: Array = []
					for gem in stack_after:
						stack_words.append(str(gem))
					stack_text = " -> ".join(stack_words)
				match effect_type:
					"gem_produce":
						return "%s Produced %s x%d. Stack: %s." % [
							base_line,
							str(result.get("gem", "?")),
							int(result.get("count", 1)),
							stack_text,
						]
					"gem_consume_top":
						return "%s Consumed %s from top. Stack: %s." % [
							base_line,
							str(result.get("gem", "?")),
							stack_text,
						]
					"gem_gain_focus":
						return "%s Gained FOCUS +%d (now %d)." % [
							base_line,
							int(result.get("gained", 0)),
							int(result.get("focus_after", 0)),
						]
					"gem_consume_top_offset":
						return "%s Consumed %s at offset %d. FOCUS now %d. Stack: %s." % [
							base_line,
							str(result.get("gem", "?")),
							int(result.get("offset", 0)),
							int(result.get("focus_after", 0)),
							stack_text,
						]
					_:
						return "%s Gem operation complete." % base_line
			var drawn_cards: Array = effect_resolve_draw_annotations.get(order_index, [])
			if not drawn_cards.is_empty():
				return "%s Drew: %s." % [base_line, ", ".join(drawn_cards)]
			return base_line
		"enemy_attack":
			var intent_type: String = str(payload.get("intent_type", "attack"))
			var base_attack_text: String = "#%d Enemy %s for %d (%d blocked, %d HP lost)." % [
				order_index,
				intent_type,
				int(payload.get("incoming", 0)),
				int(payload.get("blocked", 0)),
				int(payload.get("hp_loss", 0)),
			]
			var extras: Array = []
			if payload.has("enemy_block_gain"):
				extras.append("+%d block" % int(payload.get("enemy_block_gain", 0)))
			if payload.has("energy_drain"):
				extras.append("-%d energy next turn" % int(payload.get("energy_drain", 0)))
			if payload.has("force_discarded"):
				var discarded: Array = payload.get("force_discarded", [])
				if not discarded.is_empty():
					extras.append("discarded %s" % ", ".join(discarded))
			if extras.is_empty():
				return base_attack_text
			return "%s Also: %s." % [base_attack_text, "; ".join(extras)]
		"pass":
			return "#%d Passed turn." % order_index
		"play_reject":
			return "#%d Can't play %s: %s." % [
				order_index,
				_event_card_label_from_ids(str(payload.get("card_id", "-")), str(payload.get("instance_id", payload.get("card_id", "")))),
				_reason_text(str(payload.get("reason", ""))),
			]
		"turn_start":
			var turn_intent_type: String = str(payload.get("enemy_intent_type", "attack"))
			var turn_line: String = "#%d Turn %d. Enemy intent: %s (%d dmg)." % [
				order_index,
				int(payload.get("turn", 0)),
				turn_intent_type,
				int(payload.get("enemy_intent_damage", 0)),
			]
			if payload.has("energy_drained"):
				turn_line += " Energy drained -%d (now %d)." % [
					int(payload.get("energy_drained", 0)),
					int(payload.get("energy_after_drain", 0)),
				]
			return turn_line
		"combat_end":
			return "#%d Combat ended: %s." % [
				order_index,
				str(payload.get("result", "-")),
			]
		"reward_offer":
			return "#%d Reward checkpoint opened: %s." % [
				order_index,
				_reward_offer_display_text(payload.get("offer_card_ids", [])),
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

func _card_instance_value(value: Variant) -> Dictionary:
	if card_instance == null:
		return {"instance_id": str(value), "card_id": str(value)}
	return card_instance.from_value(value, card_catalog)

func _card_instance_id(value: Variant) -> String:
	if card_instance == null:
		return str(value)
	return card_instance.instance_id_of(value)

func _card_instance_card_id(value: Variant) -> String:
	if value == null:
		return ""
	if card_instance == null:
		return str(value)
	return card_instance.card_id_of(value, card_catalog)

func _encounter_runtime_scope(zone_name: String) -> String:
	return "enc_%02d_%s" % [encounter_index, zone_name]

func _mint_runtime_instance_id(card_value: Variant, runtime_scope: String, runtime_index: int) -> String:
	var card_id: String = _card_instance_card_id(card_value)
	if card_id == "":
		card_id = _card_instance_id(card_value)
	return "%s_%02d_%s" % [runtime_scope, runtime_index, card_id]

func _live_runtime_card(value: Variant, runtime_scope: String, runtime_index: int) -> Dictionary:
	if card_instance == null:
		return _card_instance_value(value)
	return card_instance.live_runtime_card(
		value,
		card_catalog,
		_mint_runtime_instance_id(value, runtime_scope, runtime_index)
	)

func _zone_instance_ids(zone: Array) -> Array:
	var ids: Array = []
	for entry in zone:
		ids.append(_card_instance_id(entry))
	return ids

func _zone_card_ids(zone: Array) -> Array:
	var ids: Array = []
	for entry in zone:
		ids.append(_card_instance_card_id(entry))
	return ids

func _card_instance_array(values: Array, runtime_scope: String = "") -> Array:
	var cards: Array = []
	var resolved_runtime_scope: String = runtime_scope
	if resolved_runtime_scope == "":
		resolved_runtime_scope = _encounter_runtime_scope("draw")
	for i in range(values.size()):
		cards.append(_live_runtime_card(values[i], resolved_runtime_scope, i))
	return cards

func _gem_stack_top_window(limit: int) -> Array:
	if gsm == null:
		return []
	return gsm.peek_n(limit)

func _load_pressure_profiles() -> void:
	var payload: Dictionary = _read_json(PRESSURE_PROFILES_PATH)
	pressure_profiles = {}
	encounter_sequence = []
	for profile in payload.get("profiles", []):
		if not (profile is Dictionary):
			continue
		var pid: String = str(profile.get("profile_id", "")).strip_edges()
		if pid != "":
			pressure_profiles[pid] = profile
	for seq_entry in payload.get("encounter_sequence", []):
		if seq_entry is Dictionary:
			encounter_sequence.append(seq_entry)

func _profile_for_encounter(enc_index: int) -> Dictionary:
	var seq: Dictionary = _sequence_for_encounter(enc_index)
	var pid: String = str(seq.get("profile_id", "")).strip_edges()
	if pid != "" and pressure_profiles.has(pid):
		return pressure_profiles[pid]
	# Cycle through available profiles for encounters beyond the sequence
	var profile_ids: Array = pressure_profiles.keys()
	if profile_ids.is_empty():
		return {"profile_id": "steady", "display_name": "Steady Pressure", "script_mode": "fixed_cycle", "enemy_hp_base": DEFAULT_ENEMY_MAX_HP, "cycle": [{"intent_type": "attack", "damage_min": 5, "damage_max": 8, "telegraph_text": "Attack for {dmg}"}], "enrage_start_turn": 12, "enrage_damage_step": 1}
	profile_ids.sort()
	return pressure_profiles[profile_ids[(enc_index - 1) % profile_ids.size()]]

func _sequence_for_encounter(enc_index: int) -> Dictionary:
	for seq_entry in encounter_sequence:
		if int(seq_entry.get("encounter_index", -1)) == enc_index:
			return seq_entry
	return {}

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
