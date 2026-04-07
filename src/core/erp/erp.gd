extends RefCounted
class_name ERP

func resolve_effect(effect: Dictionary, state: Dictionary) -> Dictionary:
	# Sprint 004 extension: include Gem Stack Machine operations while preserving
	# existing deterministic combat subset behavior.
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"deal_damage":
			return {"ok": true, "delta": {"hp_delta": -int(effect.get("amount", 0))}}
		"gain_block":
			return {"ok": true, "delta": {"block_delta": int(effect.get("amount", 0))}}
		"draw_n":
			return {"ok": true, "delta": {"draw_n": int(effect.get("amount", 1))}}
		"gem_produce":
			var gsm: Variant = state.get("gsm", null)
			if gsm == null:
				return {"ok": false, "reason": "ERR_GSM_STATE_MISSING"}
			return gsm.produce(str(effect.get("gem", "")), int(effect.get("count", 1)))
		"gem_consume_top":
			var gsm_top: Variant = state.get("gsm", null)
			if gsm_top == null:
				return {"ok": false, "reason": "ERR_GSM_STATE_MISSING"}
			return gsm_top.consume_top(str(effect.get("gem", "")))
		"gem_gain_focus":
			var gsm_focus: Variant = state.get("gsm", null)
			if gsm_focus == null:
				return {"ok": false, "reason": "ERR_GSM_STATE_MISSING"}
			return gsm_focus.gain_focus(int(effect.get("amount", 1)))
		"gem_consume_top_offset":
			var gsm_offset: Variant = state.get("gsm", null)
			if gsm_offset == null:
				return {"ok": false, "reason": "ERR_GSM_STATE_MISSING"}
			return gsm_offset.consume_from_top_offset(int(effect.get("offset", 0)), str(effect.get("gem", "")))
		"energy_drain":
			return {"ok": true, "delta": {"energy_drain": int(effect.get("amount", 1))}}
		"force_discard":
			return {"ok": true, "delta": {"force_discard": int(effect.get("count", 1))}}
		_:
			return {"ok": false, "reason": "ERR_UNSUPPORTED_EFFECT_TYPE", "effect_type": effect_type}
