extends RefCounted
class_name TSRE

const PHASE_COMBAT_INIT := "CombatInit"
const PHASE_TURN_START := "TurnStart"
const PHASE_PLAYER := "PlayerPhase"
const PHASE_RESOLVE := "ResolvePhase"
const PHASE_ENEMY := "EnemyPhase"
const PHASE_TURN_END := "TurnEnd"
const PHASE_COMBAT_END := "CombatEnd"

var phase: String = PHASE_COMBAT_INIT
var turn_index: int = 0
var phase_index: int = 0
var resolve_lock: bool = false

func submit_play_intent(intent: Dictionary) -> Dictionary:
	var gate: Dictionary = get_input_gate()
	if not gate.get("ok", false):
		return gate
	return {"ok": true, "intent": intent}

func submit_pass() -> Dictionary:
	var gate: Dictionary = get_input_gate()
	if not gate.get("ok", false):
		return gate
	return {"ok": true}

func get_input_gate() -> Dictionary:
	if resolve_lock:
		return {"ok": false, "reason": "ERR_RESOLVE_LOCKED"}
	if phase in [PHASE_ENEMY, PHASE_TURN_END, PHASE_COMBAT_END, PHASE_RESOLVE]:
		return {"ok": false, "reason": "ERR_PHASE_DISALLOWS_INPUT", "phase": phase}
	return {"ok": true}

func get_ui_phase_label() -> String:
	match phase:
		PHASE_ENEMY:
			return "Enemy Turn"
		PHASE_TURN_END:
			return "Turn End"
		PHASE_COMBAT_END:
			return "Combat End"
		PHASE_RESOLVE:
			return "Resolving"
		PHASE_PLAYER, PHASE_TURN_START, PHASE_COMBAT_INIT:
			return "Player Turn"
		_:
			return phase

func transition_to(next_phase: String) -> void:
	phase = next_phase
	phase_index += 1
