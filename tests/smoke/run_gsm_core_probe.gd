extends SceneTree

const GSM_SCRIPT := preload("res://src/core/gsm/gem_stack_machine.gd")

func _init() -> void:
	var gsm = GSM_SCRIPT.new()

	gsm.produce("Ruby", 1)
	gsm.produce("Sapphire", 1)
	var peek_top_before_consume: String = gsm.peek_top()
	var peek_two_before_consume: Array = gsm.peek_n(2)

	var consume_top_result: Dictionary = gsm.consume_top("Sapphire")
	var consume_top_reject: Dictionary = gsm.consume_top("Sapphire")

	gsm.produce("Sapphire", 1)
	var peek_three_after_consume: Array = gsm.peek_n(3)
	var advanced_no_focus: Dictionary = gsm.consume_from_top_offset(1, "Sapphire")

	gsm.gain_focus(1)
	var advanced_with_focus: Dictionary = gsm.consume_from_top_offset(1, "Ruby")

	var payload: Dictionary = {
		"consume_top_ok": bool(consume_top_result.get("ok", false)),
		"consume_top_gem": str(consume_top_result.get("gem", "")),
		"consume_top_reject_reason": str(consume_top_reject.get("reason", "")),
		"peek_top_before_consume": peek_top_before_consume,
		"peek_two_before_consume": peek_two_before_consume,
		"peek_three_after_consume": peek_three_after_consume,
		"advanced_without_focus_reason": str(advanced_no_focus.get("reason", "")),
		"advanced_with_focus_ok": bool(advanced_with_focus.get("ok", false)),
		"advanced_with_focus_gem": str(advanced_with_focus.get("gem", "")),
		"final_stack": gsm.stack_snapshot(),
	}

	print("GSM_CORE_PROBE=" + JSON.stringify(payload))
	quit()
