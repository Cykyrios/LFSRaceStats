class_name MapArrow
extends Sprite2D


var arrow := preload("res://src/map/arrow.png")
var paused := false

var plid := 0
var driver := ""

var last_position := Vector3.ZERO
var last_heading := 0.0
var last_speed := 0.0
var last_direction := 0.0
var last_ang_vel := 0.0
var last_update_time := 0.0


func _ready() -> void:
	texture = arrow
	scale = Vector2.ONE * 0.5


func _process(_delta: float) -> void:
	if paused:
		return
	update(Time.get_ticks_msec() / 1000.0 - last_update_time)


func update(extra_time := 0.0) ->  void:
	position = Vector2(last_position.x, -last_position.y) \
			+ extra_time * last_speed * Vector2(0, -1).rotated(-last_direction)
	position /= 4.0
	rotation = -last_heading - extra_time * last_ang_vel


func update_data(compcar: CompCar) -> void:
	last_update_time = Time.get_ticks_msec() / 1000.0
	last_position = compcar.gis_position
	last_heading = compcar.gis_heading
	last_speed = compcar.gis_speed
	last_direction = compcar.gis_direction
	last_ang_vel = compcar.gis_angular_velocity
