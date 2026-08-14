## A small deterministic timing model shared by the tea vat and pearl cooker.
## The scene owns inventory; this object only owns the active batch and its
## golden/late/spoiled collection windows, which keeps the rule independently
## testable and prevents render frame rate from changing the result.
extends RefCounted
class_name PrepBatch

const STATE_EMPTY := "empty"
const STATE_BREWING := "brewing"
const STATE_GOLDEN := "golden"
const STATE_LATE := "late"
const STATE_SPOILED := "spoiled"

var kind := ""
var brew_seconds := 8.0
var golden_seconds := 4.0
var late_seconds := 6.0
var batch_size := 4
var item_id := ""
var elapsed := 0.0
var active := false


func _init(batch_kind := "tea", duration := 8.0, golden_window := 4.0,
		late_window := 6.0, servings := 4) -> void:
	kind = batch_kind
	brew_seconds = maxf(0.1, duration)
	golden_seconds = maxf(0.1, golden_window)
	late_seconds = maxf(0.1, late_window)
	batch_size = maxi(1, servings)


func start(target_id := "") -> bool:
	if active:
		return false
	item_id = target_id
	elapsed = 0.0
	active = true
	return true


func advance(delta: float) -> void:
	if active:
		elapsed += maxf(0.0, delta)


func state() -> String:
	if not active:
		return STATE_EMPTY
	if elapsed < brew_seconds:
		return STATE_BREWING
	if elapsed < brew_seconds + golden_seconds:
		return STATE_GOLDEN
	if elapsed < brew_seconds + golden_seconds + late_seconds:
		return STATE_LATE
	return STATE_SPOILED


func collect_quality() -> int:
	match state():
		STATE_GOLDEN:
			return 2
		STATE_LATE:
			return 1
		STATE_SPOILED:
			return 0
	return -1


func collect() -> Dictionary:
	var quality := collect_quality()
	if quality < 0:
		return {}
	var result := {
		"kind": kind, "item_id": item_id, "quality": quality,
		"servings": batch_size, "elapsed": elapsed,
	}
	active = false
	item_id = ""
	elapsed = 0.0
	return result


func progress() -> float:
	if not active:
		return 0.0
	var total := brew_seconds + golden_seconds + late_seconds
	return clampf(elapsed / total, 0.0, 1.0)


func seconds_to_ready() -> int:
	return ceili(maxf(0.0, brew_seconds - elapsed))


func window_seconds_left() -> int:
	match state():
		STATE_GOLDEN:
			return ceili(brew_seconds + golden_seconds - elapsed)
		STATE_LATE:
			return ceili(brew_seconds + golden_seconds + late_seconds - elapsed)
	return 0
