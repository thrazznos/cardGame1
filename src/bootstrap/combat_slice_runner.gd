extends Control
class_name CombatSliceRunner

const FIXTURE_PATH := "res://tests/determinism/fixtures/seed_smoke_001.json"
const TSRE_SCRIPT := preload("res://src/core/tsre/tsre.gd")
const ACTION_QUEUE_SCRIPT := preload("res://src/core/tsre/action_queue.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const ERP_SCRIPT := preload("res://src/core/erp/erp.gd")
const DLS_SCRIPT := preload("res://src/core/dls/deck_lifecycle.gd")

var tsre: Variant
var queue: Variant
var rng: Variant
var erp: Variant
var dls: Variant
var hud: Variant

var event_stream: Array[Dictionary] = []

func _ready() -> void:
	tsre = TSRE_SCRIPT.new()
	queue = ACTION_QUEUE_SCRIPT.new()
	rng = RSGC_SCRIPT.new()
	erp = ERP_SCRIPT.new()
	dls = DLS_SCRIPT.new()
	hud = $CombatHud
	hud.bind_runtime(tsre)

	_bootstrap_demo_state()

func _bootstrap_demo_state() -> void:
	dls.draw_pile = ["strike_01", "defend_01", "strike_02", "defend_02"]
	dls.hand = ["strike_01", "defend_01"]
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []

func run_fixture(path: String) -> Dictionary:
	var fixture: Dictionary = _read_json(path)
	if fixture.is_empty():
		return {"ok": false, "reason": "ERR_FIXTURE_READ_FAILED", "path": path}

	rng.bootstrap(int(fixture.get("seed_root", 0)))
	event_stream.clear()

	var inputs: Array = fixture.get("inputs", [])
	for step in inputs:
		_apply_step(step)

	var final_state: Dictionary = {
		"phase": tsre.phase,
		"turn_index": tsre.turn_index,
		"hand": dls.hand,
		"discard": dls.discard_pile,
		"exhaust": dls.exhaust_pile,
		"limbo": dls.limbo,
		"rng_cursors": rng.cursors,
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
	}

func _apply_step(step: Dictionary) -> void:
	var action: String = str(step.get("action", ""))
	match action:
		"play":
			var card_id: String = str(step.get("card_id", ""))
			var intent: Dictionary = {"card_id": card_id, "target": step.get("target", null)}
			var submit: Dictionary = hud.on_play_pressed(intent)
			if submit.get("ok", false):
				var committed: Dictionary = dls.commit_play(card_id)
				if committed.get("ok", false):
					queue.enqueue({
						"turn_index": int(step.get("turn", 0)),
						"phase_index": tsre.phase_index,
						"timing_window_priority": 1,
						"speed_class_priority": 1,
						"source_instance_id": card_id,
						"effect": _card_to_effect(card_id)
					})
					_resolve_queue_once()
					_record_event("play_commit", {"card_id": card_id})
				else:
					_record_event("play_reject", committed)
			else:
				_record_event("intent_reject", submit)
		"pass":
			var pass_result: Dictionary = hud.on_pass_pressed()
			_record_event("pass", pass_result)
			tsre.transition_to(tsre.PHASE_ENEMY)
			var enemy_rng: Dictionary = rng.draw_next("encounter.intent")
			_record_event("enemy_intent_roll", enemy_rng)
			tsre.transition_to(tsre.PHASE_TURN_END)
			tsre.turn_index += 1
			tsre.transition_to(tsre.PHASE_TURN_START)
			if dls.hand.size() < 5:
				dls.draw_one()
		_:
			_record_event("unknown_action", step)

func _resolve_queue_once() -> void:
	if not queue.has_items():
		return
	var item: Dictionary = queue.dequeue()
	var effect: Dictionary = item.get("effect", {})
	var result: Dictionary = erp.resolve_effect(effect, {})
	dls.finalize_play(str(item.get("source_instance_id", "")), "discard")
	_record_event("effect_resolve", {"item": item, "result": result})

func _card_to_effect(card_id: String) -> Dictionary:
	if card_id.begins_with("strike"):
		return {"type": "deal_damage", "amount": 6}
	if card_id.begins_with("defend"):
		return {"type": "gain_block", "amount": 5}
	return {"type": "draw_n", "amount": 1}

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
