class_name InSimRelativeTimes
extends Node


const MAXIMUM_COLUMNS := 5
const OVERALL_POS_COLUMN := 1
const CLASS_POS_COLUMN := 2
const CAR_COLUMN := 3
const DRIVER_COLUMN := 4
const INTERVAL_COLUMN := 5
const UNKNOWN_INTERVAL_STRING := "---"

var insim: InSim = null

var first_button_idx := 0
var buttons_num_cars := 0

var buttons_enabled := true
var class_position_visible := true:
	set(value):
		class_position_visible = value
		update_fields_per_row()
var car_visible := true:
	set(value):
		car_visible = value
		update_fields_per_row()

var fields_per_row := MAXIMUM_COLUMNS
var margin := 1
var button_height := 4
var overall_pos_width := 3
var class_pos_width := 3
var car_width := 5
var driver_name_width := 12
var interval_width := 7

var interval_color_lapping := LFSText.ColorCode.CYAN
var interval_color_front := LFSText.ColorCode.RED
var interval_color_behind := LFSText.ColorCode.GREEN
var interval_color_lapped := LFSText.ColorCode.MAGENTA


func _init(insim_instance: InSim) -> void:
	insim = insim_instance


func clear_buttons() -> void:
	var packet := InSimBFNPacket.new()
	packet.subtype = InSim.ButtonFunction.BFN_CLEAR
	insim.send_packet(packet)
	buttons_enabled = false


func create_button(
		id: int, left: int, top: int, width: int, height: int, button_style: int, text := ""
) -> InSimBTNPacket:
	var packet := InSimBTNPacket.new()
	packet.req_i = 1
	packet.click_id = first_button_idx + id
	packet.left = left
	packet.top = top
	packet.width = width
	packet.height = height
	packet.button_style = button_style
	packet.text = text
	return packet


func initialize_buttons(num_cars: int) -> void:
	buttons_num_cars = num_cars
	buttons_enabled = true
	var total_width := 2 * margin + overall_pos_width + \
			(class_pos_width if class_position_visible else 0) + (car_width if car_visible else 0) \
			+ driver_name_width + interval_width
	var total_height := (num_cars + 1) * button_height + 2 * margin
	var position_left := InSim.ButtonPosition.X_MIN + 1 + 33
	var position_top := InSim.ButtonPosition.Y_MAX - total_height - 5 + 20
	insim.send_packet(create_button(0, position_left, position_top, total_width, total_height,
			InSim.ButtonStyle.ISB_LIGHT))
	for i in num_cars + 1:
		var id_offset := 0
		var current_x_pos := margin
		insim.send_packet(create_button(
			i * fields_per_row + OVERALL_POS_COLUMN,
			position_left + current_x_pos,
			position_top + margin + i * button_height,
			overall_pos_width,
			button_height,
			InSim.ButtonStyle.ISB_DARK,
			"P" if i == 0 else ""
		))
		current_x_pos += overall_pos_width
		if class_position_visible:
			insim.send_packet(create_button(
				i * fields_per_row + CLASS_POS_COLUMN,
				position_left + current_x_pos,
				position_top + margin + i * button_height,
				class_pos_width,
				button_height,
				InSim.ButtonStyle.ISB_DARK,
				"C" if i == 0 else ""
			))
			current_x_pos += class_pos_width
		else:
			id_offset += 1
		if car_visible:
			insim.send_packet(create_button(
				i * fields_per_row + CAR_COLUMN - id_offset,
				position_left + current_x_pos,
				position_top + margin + i * button_height,
				car_width,
				button_height,
				InSim.ButtonStyle.ISB_DARK,
				"Car" if i == 0 else ""
			))
			current_x_pos += car_width
		else:
			id_offset += 1
		insim.send_packet(create_button(
			i * fields_per_row + DRIVER_COLUMN - id_offset,
			position_left + current_x_pos,
			position_top + margin + i * button_height,
			driver_name_width,
			button_height,
			InSim.ButtonStyle.ISB_DARK,
			"Driver" if i == 0 else ""
		))
		current_x_pos += driver_name_width
		insim.send_packet(create_button(
			i * fields_per_row + INTERVAL_COLUMN - id_offset,
			position_left + current_x_pos,
			position_top + margin + i * button_height,
			interval_width,
			button_height,
			InSim.ButtonStyle.ISB_DARK,
			"Interval" if i == 0 else UNKNOWN_INTERVAL_STRING
		))
		current_x_pos += interval_width


func show_buttons(num_cars: int) -> void:
	buttons_enabled = true
	initialize_buttons(num_cars)


func update_button_text(id: int, text: String) -> void:
	var packet := InSimBTNPacket.new()
	packet.req_i = 1
	packet.click_id = id
	packet.text = text
	insim.send_packet(packet)


func update_driver_info(
	row_idx: int, overall_pos: String, class_pos: String, car_name: String,
	driver_name: String, interval := UNKNOWN_INTERVAL_STRING
) -> void:
	update_button_text(row_idx * fields_per_row + OVERALL_POS_COLUMN, str(overall_pos))
	var offset := 0
	if class_position_visible:
		update_button_text(row_idx * fields_per_row + CLASS_POS_COLUMN, str(class_pos))
	else:
		offset += 1
	if car_visible:
		update_button_text(row_idx * fields_per_row + CAR_COLUMN - offset, car_name)
	else:
		offset += 1
	update_button_text(row_idx * fields_per_row + DRIVER_COLUMN - offset, driver_name)
	update_button_text(row_idx * fields_per_row + INTERVAL_COLUMN - offset, interval)


func update_fields_per_row() -> void:
	fields_per_row = MAXIMUM_COLUMNS
	if not class_position_visible:
		fields_per_row -= 1
	if not car_visible:
		fields_per_row -= 1
