extends SceneTree

const HUD_SCRIPT_PATH := "res://src/ui/combat_hud/combat_hud_controller.gd"

func _init() -> void:
	var hud_script: Script = load(HUD_SCRIPT_PATH)
	var constants: Dictionary = hud_script.get_script_constant_map()

	var panel_bg: Color = constants.get("PANEL_BG", Color.BLACK)
	var panel_bg_soft: Color = constants.get("PANEL_BG_SOFT", Color.BLACK)
	var text_primary: Color = constants.get("TEXT_PRIMARY", Color.WHITE)
	var text_muted: Color = constants.get("TEXT_MUTED", Color.WHITE)
	var text_accent: Color = constants.get("TEXT_ACCENT", Color.WHITE)
	var text_warn: Color = constants.get("TEXT_WARN", Color.WHITE)
	var text_good: Color = constants.get("TEXT_GOOD", Color.WHITE)

	var checks: Array[Dictionary] = [
		{"name": "TEXT_PRIMARY_on_PANEL_BG", "fg": text_primary, "bg": panel_bg, "min": 7.0},
		{"name": "TEXT_MUTED_on_PANEL_BG", "fg": text_muted, "bg": panel_bg, "min": 4.5},
		{"name": "TEXT_ACCENT_on_PANEL_BG", "fg": text_accent, "bg": panel_bg, "min": 4.5},
		{"name": "TEXT_WARN_on_PANEL_BG_SOFT", "fg": text_warn, "bg": panel_bg_soft, "min": 3.0},
		{"name": "TEXT_GOOD_on_PANEL_BG_SOFT", "fg": text_good, "bg": panel_bg_soft, "min": 3.0},
	]

	var ratios: Dictionary = {}
	var failures: Array = []
	for check in checks:
		var name: String = str(check.get("name", "unknown"))
		var ratio: float = _contrast_ratio(check.get("fg", Color.WHITE), check.get("bg", Color.BLACK))
		var minimum: float = float(check.get("min", 4.5))
		ratios[name] = snappedf(ratio, 0.01)
		if ratio < minimum:
			failures.append({"name": name, "ratio": ratio, "minimum": minimum})

	var payload: Dictionary = {
		"ok": failures.is_empty(),
		"ratios": ratios,
		"failures": failures,
	}
	print("HUD_CONTRAST_PROBE=" + JSON.stringify(payload))
	quit()

func _contrast_ratio(fg: Color, bg: Color) -> float:
	var l1: float = _relative_luminance(fg)
	var l2: float = _relative_luminance(bg)
	var lighter: float = max(l1, l2)
	var darker: float = min(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	var r: float = _to_linear(color.r)
	var g: float = _to_linear(color.g)
	var b: float = _to_linear(color.b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b

func _to_linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)
