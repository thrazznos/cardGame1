extends SceneTree

const STATUS_TRACKER_SCRIPT := preload("res://src/core/status/status_tracker.gd")

func _init() -> void:
	var tracker = STATUS_TRACKER_SCRIPT.new()

	# Apply poison
	var apply_poison: Dictionary = tracker.apply("poison", 3)
	var has_poison: bool = tracker.has_status("poison")
	var poison_stacks: int = tracker.get_stacks("poison")

	# Apply strength
	var apply_strength: Dictionary = tracker.apply("strength", 1, 2)
	var has_strength: bool = tracker.has_status("strength")

	# Apply vulnerability
	tracker.apply("vulnerability", 1, 2)

	# Check multipliers
	var deal_mult: float = tracker.get_damage_dealt_multiplier()
	var take_mult: float = tracker.get_damage_taken_multiplier()

	# Tick turn start (poison should deal damage)
	var tick_results: Array = tracker.tick_turn_start()
	var poison_after_tick: int = tracker.get_stacks("poison")

	# Tick turn end (strength/vulnerability should decrement)
	tracker.tick_turn_end()
	var strength_duration: int = tracker.get_duration("strength")

	# Tick again to expire
	tracker.tick_turn_end()
	var strength_expired: bool = not tracker.has_status("strength")

	# Snapshot
	var snap: Array = tracker.snapshot()

	var payload: Dictionary = {
		"apply_poison_ok": bool(apply_poison.get("ok", false)),
		"has_poison": has_poison,
		"poison_stacks": poison_stacks,
		"apply_strength_ok": bool(apply_strength.get("ok", false)),
		"has_strength_initially": has_strength,
		"deal_multiplier": deal_mult,
		"take_multiplier": take_mult,
		"tick_results_count": tick_results.size(),
		"tick_poison_damage": int(tick_results[0].get("damage", 0)) if not tick_results.is_empty() else 0,
		"poison_stacks_after_tick": poison_after_tick,
		"strength_duration_after_1_tick": strength_duration,
		"strength_expired_after_2_ticks": strength_expired,
		"snapshot_size": snap.size(),
	}

	print("STATUS_EFFECT_PROBE=" + JSON.stringify(payload))
	quit()
