extends RefCounted
class_name ActionQueue

var _items: Array[Dictionary] = []
var _sequence: int = 0

func enqueue(item: Dictionary) -> Dictionary:
	_sequence += 1
	item["enqueue_sequence_id"] = _sequence
	_items.append(item)
	_items.sort_custom(func(a, b): return _sort_items(a, b))
	return item

func dequeue() -> Dictionary:
	if _items.is_empty():
		return {}
	return _items.pop_front()

func has_items() -> bool:
	return not _items.is_empty()

func snapshot() -> Array[Dictionary]:
	return _items.duplicate(true)

func _sort_items(a: Dictionary, b: Dictionary) -> bool:
	var a_key := [a.get("turn_index", 0), a.get("phase_index", 0), a.get("timing_window_priority", 0), a.get("speed_class_priority", 0), a.get("enqueue_sequence_id", 0), a.get("source_instance_id", "")]
	var b_key := [b.get("turn_index", 0), b.get("phase_index", 0), b.get("timing_window_priority", 0), b.get("speed_class_priority", 0), b.get("enqueue_sequence_id", 0), b.get("source_instance_id", "")]
	return a_key < b_key
