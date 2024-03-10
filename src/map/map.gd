class_name Map
extends Node2D


var arrows: Array[MapArrow] = []


func add_arrow(compcar: CompCar) -> void:
	var arrow := MapArrow.new()
	arrow.plid = compcar.player_id
	arrow.last_position = compcar.gis_position
	arrow.last_heading = compcar.gis_heading
	arrow.last_speed = compcar.gis_speed
	arrow.last_direction = compcar.gis_direction
	arrows.append(arrow)
	add_child(arrow)


func clear_arrows() -> void:
	for arrow in arrows:
		arrow.queue_free()
	arrows.clear()


func get_arrow_by_plid(plid: int) -> MapArrow:
	for arrow in arrows:
		if arrow.plid == plid:
			return arrow
	return null


func hide_arrow_by_plid(plid: int) -> void:
	var arrow := get_arrow_by_plid(plid)
	if not arrow:
		return
	arrow.visible = false


func pause() -> void:
	for arrow in arrows:
		arrow.paused = true


func remove_arrow_by_plid(plid: int) -> void:
	var arrow := get_arrow_by_plid(plid)
	if not arrow:
		return
	arrow.queue_free()
	arrows.erase(arrow)


func remove_arrows() -> void:
	for arrow in arrows:
		arrow.queue_free()
	arrows.clear()


func unpause() -> void:
	for arrow in arrows:
		arrow.paused = false
		arrow.last_update_time = Time.get_ticks_msec() / 1000.0


#func update_arrow(plid: int, driver: String, map_position: Vector2, heading: int) -> void:
func update_arrow(compcar: CompCar) -> void:
	var arrow := get_arrow_by_plid(compcar.player_id)
	if not arrow:
		add_arrow(compcar)
		arrow = arrows[-1]
	arrow.update_data(compcar)
	arrow.update()
