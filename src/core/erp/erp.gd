extends RefCounted
class_name ERP

func resolve_effect(effect: Dictionary, state: Dictionary) -> Dictionary:
	# Sprint 001 subset only. Detailed handlers to be expanded per GDD.
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"deal_damage":
			return {"ok": true, "delta": {"hp_delta": -int(effect.get("amount", 0))}}
		"gain_block":
			return {"ok": true, "delta": {"block_delta": int(effect.get("amount", 0))}}
		"draw_n":
			return {"ok": true, "delta": {"draw_n": int(effect.get("amount", 1))}}
		_:
			return {"ok": false, "reason": "ERR_UNSUPPORTED_EFFECT_TYPE", "effect_type": effect_type}
