class_name Map
extends Node2D


var arrows: Array[MapArrow] = []

@onready var track_image: Sprite2D = %TrackImage


func add_arrow(compcar: CompCar) -> void:
	var arrow := MapArrow.new()
	arrow.plid = compcar.player_id
	arrow.last_position = compcar.gis_position
	arrow.last_heading = compcar.gis_heading
	arrow.last_speed = compcar.gis_speed
	arrow.last_direction = compcar.gis_direction
	arrows.append(arrow)
	add_child(arrow)


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


func set_background(track: String) -> void:
	var track_environment := track.left(2)
	if track_environment in ["AS", "AU", "BL", "FE", "KY", "RO", "SO", "WE"]:
		track_image.texture = load("res://src/map/environments/%s.png" % [track_environment])
	else:
		track_image.texture = null


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
