extends Control
class_name CombatHudController

var tsre: Variant

func bind_runtime(runtime_tsre: Variant) -> void:
	tsre = runtime_tsre

func on_play_pressed(intent: Dictionary) -> Dictionary:
	if tsre == null:
		return {"ok": false, "reason": "ERR_TSRE_NOT_BOUND"}
	return tsre.submit_play_intent(intent)

func on_pass_pressed() -> Dictionary:
	if tsre == null:
		return {"ok": false, "reason": "ERR_TSRE_NOT_BOUND"}
	return tsre.submit_pass()
