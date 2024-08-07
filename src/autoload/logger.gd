extends Node


const FLUSH_INTERVAL := 1.0

var file: FileAccess = null
var file_open := false

var flush_timer := Timer.new()


func _ready() -> void:
	create_log_file()
	flush_timer.one_shot = true
	var _discard := flush_timer.timeout.connect(_on_flush_timer_timeout)
	add_child(flush_timer)


func _exit_tree() -> void:
	close_log_file()


func create_log_file() -> void:
	file = FileAccess.open("user://%s.log" % [get_date_time_string()], FileAccess.WRITE)
	if file:
		file_open = true


func close_log_file() -> void:
	file_open = false
	file = null


func flush_log_file() -> void:
	if not file_open:
		return
	file.flush()


func get_date_time_string() -> String:
	return Time.get_datetime_string_from_system(true, true)


func log_error(packet: InSimPacket, message: String) -> void:
	log_message("Error: %s - %s" % [InSim.Packet.keys()[packet.type], message])


func log_message(message: String) -> void:
	if not file_open:
		return
	file.store_line("%s - %s" % [get_date_time_string(), message])
	if flush_timer.is_stopped():
		flush_timer.start(FLUSH_INTERVAL)


func log_packet(packet: InSimPacket) -> void:
	if not file_open:
		return
	var packet_string := packet.to_string()
	file.store_line("%s - %s" % [get_date_time_string(), packet_string])
	if flush_timer.is_stopped():
		flush_timer.start(FLUSH_INTERVAL)


func log_warning(packet: InSimPacket, message: String) -> void:
	log_message("Warning: %s - %s" % [InSim.Packet.keys()[packet.type], message])


func _on_flush_timer_timeout() -> void:
	flush_log_file()
