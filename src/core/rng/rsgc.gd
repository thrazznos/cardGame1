extends RefCounted
class_name RSGC

var manifest: Dictionary = {}
var cursors: Dictionary = {}

func bootstrap(run_seed: int, algorithm_version: String = "v1", stream_schema_version: String = "v1") -> void:
	manifest = {
		"seed_root": run_seed,
		"rng_algorithm_version": algorithm_version,
		"rng_stream_schema_version": stream_schema_version,
	}
	cursors = {}

func draw_next(stream_key: String) -> Dictionary:
	var idx: int = int(cursors.get(stream_key, 0))
	var value := _draw_u32_at(stream_key, idx)
	cursors[stream_key] = idx + 1
	return {
		"stream_key": stream_key,
		"draw_index": idx,
		"value": value,
	}

func _draw_u32_at(stream_key: String, draw_index: int) -> int:
	# Deterministic placeholder hash. Replace with finalized algorithm per ADR-0002.
	var seed := int(manifest.get("seed_root", 0))
	var h := hash([seed, stream_key, draw_index])
	return int(abs(h) % 4294967295)
