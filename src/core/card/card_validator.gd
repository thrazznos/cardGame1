extends RefCounted
class_name CardValidator

const VALID_SPEED_CLASSES := {
	"fast": true,
	"normal": true,
	"slow": true,
}
const VALID_COST_TYPES := {
	"energy": true,
	"mana": true,
	"other": true,
}
const VALID_TIMING_WINDOWS := {
	"pre": true,
	"main": true,
	"post": true,
}
const VALID_TARGET_MODES := {
	"self": true,
	"single_enemy": true,
	"none": true,
}
const VALID_INVALID_TARGET_POLICIES := {
	"fizzle": true,
	"retarget_if_possible": true,
	"retarget_random_deterministic": true,
}
const VALID_ZONE_ON_PLAY := {
	"discard": true,
	"exhaust": true,
	"retain": true,
	"temp": true,
}

func validate_catalog(payload: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var seen_card_ids: Dictionary = {}
	var seen_aliases: Dictionary = {}
	var cards: Array = payload.get("cards", [])
	if cards.is_empty():
		errors.append("ERR_CARD_CATALOG_EMPTY")
		return errors

	for entry in cards:
		if not (entry is Dictionary):
			errors.append("ERR_CARD_ENTRY_INVALID")
			continue
		var card: Dictionary = entry
		var card_id: String = str(card.get("card_id", "")).strip_edges()
		if card_id == "":
			errors.append("ERR_CARD_ID_MISSING")
			continue
		if seen_card_ids.has(card_id):
			errors.append("ERR_CARD_ID_DUPLICATE:%s" % card_id)
			continue
		seen_card_ids[card_id] = true

		if str(card.get("display_name", "")).strip_edges() == "":
			errors.append("ERR_CARD_DISPLAY_NAME_MISSING:%s" % card_id)
		if str(card.get("role_marker", "")).strip_edges() == "":
			errors.append("ERR_CARD_ROLE_MARKER_MISSING:%s" % card_id)
		if str(card.get("palette", "")).strip_edges() == "":
			errors.append("ERR_CARD_PALETTE_MISSING:%s" % card_id)
		if not card.has("base_cost"):
			errors.append("ERR_CARD_BASE_COST_MISSING:%s" % card_id)
		elif int(card.get("base_cost", -1)) < 0:
			errors.append("ERR_CARD_BASE_COST_INVALID:%s" % card_id)
		var cost_type: String = str(card.get("cost_type", "")).strip_edges()
		if cost_type == "":
			errors.append("ERR_CARD_COST_TYPE_MISSING:%s" % card_id)
		elif not VALID_COST_TYPES.has(cost_type):
			errors.append("ERR_CARD_COST_TYPE_INVALID:%s" % card_id)
		var speed_class: String = str(card.get("speed_class", "")).strip_edges()
		if speed_class == "":
			errors.append("ERR_CARD_SPEED_CLASS_MISSING:%s" % card_id)
		elif not VALID_SPEED_CLASSES.has(speed_class):
			errors.append("ERR_CARD_SPEED_CLASS_INVALID:%s" % card_id)
		var timing_window: String = str(card.get("timing_window", "")).strip_edges()
		if timing_window == "":
			errors.append("ERR_CARD_TIMING_WINDOW_MISSING:%s" % card_id)
		elif not VALID_TIMING_WINDOWS.has(timing_window):
			errors.append("ERR_CARD_TIMING_WINDOW_INVALID:%s" % card_id)
		var zone_on_play: String = str(card.get("zone_on_play", "")).strip_edges()
		if zone_on_play == "":
			errors.append("ERR_CARD_ZONE_ON_PLAY_MISSING:%s" % card_id)
		elif not VALID_ZONE_ON_PLAY.has(zone_on_play):
			errors.append("ERR_CARD_ZONE_ON_PLAY_INVALID:%s" % card_id)
		var target_mode: String = str(card.get("target_mode", "")).strip_edges()
		if target_mode == "":
			errors.append("ERR_CARD_TARGET_MODE_MISSING:%s" % card_id)
		elif not VALID_TARGET_MODES.has(target_mode):
			errors.append("ERR_CARD_TARGET_MODE_INVALID:%s" % card_id)
		if not card.has("max_targets"):
			errors.append("ERR_CARD_MAX_TARGETS_MISSING:%s" % card_id)
		elif int(card.get("max_targets", -1)) < 0:
			errors.append("ERR_CARD_MAX_TARGETS_INVALID:%s" % card_id)
		elif target_mode != "none" and int(card.get("max_targets", 0)) < 1:
			errors.append("ERR_CARD_MAX_TARGETS_INVALID:%s" % card_id)
		var invalid_target_policy: String = str(card.get("invalid_target_policy", "")).strip_edges()
		if invalid_target_policy == "":
			errors.append("ERR_CARD_INVALID_TARGET_POLICY_MISSING:%s" % card_id)
		elif not VALID_INVALID_TARGET_POLICIES.has(invalid_target_policy):
			errors.append("ERR_CARD_INVALID_TARGET_POLICY_INVALID:%s" % card_id)
		var play_conditions: Variant = card.get("play_conditions", [])
		if not (play_conditions is Array):
			errors.append("ERR_CARD_PLAY_CONDITIONS_INVALID:%s" % card_id)
		else:
			for condition_variant in play_conditions:
				if not (condition_variant is Dictionary):
					errors.append("ERR_CARD_PLAY_CONDITIONS_INVALID:%s" % card_id)
					break
				if str((condition_variant as Dictionary).get("condition_id", "")).strip_edges() == "":
					errors.append("ERR_CARD_PLAY_CONDITIONS_INVALID:%s" % card_id)
					break
		var combo_tags: Variant = card.get("combo_tags", [])
		if not (combo_tags is Array):
			errors.append("ERR_CARD_COMBO_TAGS_INVALID:%s" % card_id)
		var chain_flags: Variant = card.get("chain_flags", [])
		if not (chain_flags is Array):
			errors.append("ERR_CARD_CHAIN_FLAGS_INVALID:%s" % card_id)
		var weight_modifiers: Variant = card.get("weight_modifiers", [])
		if not (weight_modifiers is Array):
			errors.append("ERR_CARD_WEIGHT_MODIFIERS_INVALID:%s" % card_id)
		else:
			for modifier_variant in weight_modifiers:
				if not (modifier_variant is Dictionary):
					errors.append("ERR_CARD_WEIGHT_MODIFIERS_INVALID:%s" % card_id)
					break
				var modifier: Dictionary = modifier_variant
				if str(modifier.get("modifier_id", "")).strip_edges() == "":
					errors.append("ERR_CARD_WEIGHT_MODIFIERS_INVALID:%s" % card_id)
					break
				if str(modifier.get("type", "")).strip_edges() == "":
					errors.append("ERR_CARD_WEIGHT_MODIFIERS_INVALID:%s" % card_id)
					break
				if not modifier.has("value"):
					errors.append("ERR_CARD_WEIGHT_MODIFIERS_INVALID:%s" % card_id)
					break
		var effects: Array = card.get("effects", [])
		if effects.is_empty():
			errors.append("ERR_CARD_EFFECTS_MISSING:%s" % card_id)
		else:
			for effect_variant in effects:
				if not (effect_variant is Dictionary):
					errors.append("ERR_CARD_EFFECT_ENTRY_INVALID:%s" % card_id)
					break
				var effect: Dictionary = effect_variant
				var legacy_type: String = str(effect.get("type", "")).strip_edges()
				if legacy_type != "":
					continue
				var effect_id: String = str(effect.get("effect_id", "")).strip_edges()
				if effect_id == "":
					errors.append("ERR_CARD_EFFECT_ENTRY_INVALID:%s" % card_id)
					break
				if not (effect.get("params", {}) is Dictionary):
					errors.append("ERR_CARD_EFFECT_PARAMS_INVALID:%s" % card_id)
					break

		var aliases: Array = card.get("aliases", [])
		for alias in aliases:
			var alias_id: String = str(alias).strip_edges()
			if alias_id == "":
				continue
			if seen_card_ids.has(alias_id) or seen_aliases.has(alias_id):
				errors.append("ERR_CARD_ALIAS_DUPLICATE:%s" % alias_id)
				continue
			seen_aliases[alias_id] = card_id

	return errors
