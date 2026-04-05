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
	# Sprint 001 scaffold: validate/commit pipeline to be implemented.
	if resolve_lock:
		return {"ok": false, "reason": "ERR_RESOLVE_LOCKED"}
	return {"ok": true, "intent": intent}

func submit_pass() -> Dictionary:
	if resolve_lock:
		return {"ok": false, "reason": "ERR_RESOLVE_LOCKED"}
	return {"ok": true}

func transition_to(next_phase: String) -> void:
	phase = next_phase
	phase_index += 1
