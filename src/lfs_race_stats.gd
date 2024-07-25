extends MarginContainer


var insim := InSim.new()

var connections: Array[Connection] = []
var players: Array[Player] = []
var drivers: Array[DriverData] = []

@onready var map: Map = %Map as Map


func _ready() -> void:
	add_child(insim)
	connect_signals()
	initialize_insim()


func connect_signals() -> void:
	var _discard := insim.isp_fin_received.connect(_on_fin_received)
	_discard = insim.isp_flg_received.connect(_on_flg_received)
	_discard = insim.isp_lap_received.connect(_on_lap_received)
	_discard = insim.isp_mci_received.connect(_on_mci_received)
	_discard = insim.isp_mso_received.connect(_on_mso_received)
	_discard = insim.isp_npl_received.connect(_on_npl_received)
	_discard = insim.isp_pit_received.connect(_on_pit_received)
	_discard = insim.isp_pla_received.connect(_on_pla_received)
	_discard = insim.isp_pll_received.connect(_on_pll_received)
	_discard = insim.isp_plp_received.connect(_on_plp_received)
	_discard = insim.isp_psf_received.connect(_on_psf_received)
	_discard = insim.isp_pen_received.connect(_on_pen_received)
	_discard = insim.isp_res_received.connect(_on_res_received)
	_discard = insim.isp_rst_received.connect(_on_rst_received)
	_discard = insim.isp_slc_received.connect(_on_slc_received)
	_discard = insim.isp_spx_received.connect(_on_spx_received)
	_discard = insim.isp_sta_received.connect(_on_sta_received)
	_discard = insim.isp_toc_received.connect(_on_toc_received)
	_discard = insim.tiny_ren_received.connect(_on_tiny_ren_received)
	_discard = insim.packet_received.connect(_on_packet_received)


func get_connection_from_ucid(ucid: int) -> Connection:
	for connection in connections:
		if connection.ucid == ucid:
			return connection
	return null


func get_player_from_plid(plid: int) -> Player:
	for player in players:
		if player.plid == plid:
			return player
	return null


func initialize_insim() -> void:
	var init_data := InSimInitializationData.new()
	init_data.i_name = "GIS Race Stats"
	init_data.flags |= InSim.InitFlag.ISF_LOCAL | InSim.InitFlag.ISF_MCI
	init_data.interval = 250
	insim.initialize("127.0.0.1", 29999, init_data)


#region InSim callbacks
func _on_fin_received(packet: InSimFINPacket) -> void:
	Logger.log_message("PLID %d finished in %s (%d laps, best lap %s)." % [packet.player_id,
			GISUtils.get_time_string_from_seconds(packet.gis_race_time), packet.laps_done,
			GISUtils.get_time_string_from_seconds(packet.gis_best_lap)])


func _on_flg_received(packet: InSimFLGPacket) -> void:
	var flag_string := ""
	if packet.flag == 1:
		flag_string = "Blue flag %s" % ["given to" if packet.off_on else "cleared for"]
	if packet.flag == 2:
		flag_string = "Yellow flag %s" % ["caused by" if packet.off_on else "cleared for"]
	flag_string += " PLID %d (car behind: PLID %d)." % [packet.player_id, packet.car_behind]
	Logger.log_message(flag_string)


func _on_lap_received(packet: InSimLAPPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		return
	player.add_lap(packet)
	Logger.log_message("Lap %d completed by PLID %d: %s" % [packet.laps_done, packet.player_id,
			GISUtils.get_time_string_from_seconds(packet.gis_lap_time)])


func _on_mci_received(packet: InSimMCIPacket) -> void:
	for compcar in packet.info:
		map.update_arrow(compcar)


func _on_mso_received(packet: InSimMSOPacket) -> void:
	var message := LFSText.strip_colors(packet.msg)
	if packet.user_type == InSim.MessageUserValue.MSO_USER:
		message = "PLID %d UCID %d - %s" % [packet.player_id, packet.ucid, message]
	Logger.log_message(message)


func _on_npl_received(packet: InSimNPLPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		player = Player.new()
		players.append(player)
	player.fill_info(packet)
	var map_arrow := map.get_arrow_by_plid(player.plid)
	if map_arrow:
		map_arrow.visible = true


func _on_pen_received(packet: InSimPENPacket) -> void:
	Logger.log_message("Penalty for PLID %d: %s (%s)" % [packet.player_id, packet.new_penalty,
			packet.reason])


func _on_pit_received(packet: InSimPITPacket) -> void:
	Logger.log_message("PLID %d made a pit stop: (details to be added)" % [packet.player_id])


func _on_pla_received(packet: InSimPLAPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		return
	var lap: LapData = null
	if player.laps.is_empty():
		lap = LapData.new()
	if packet.fact != InSim.PitLane.PITLANE_EXIT and packet.fact != InSim.PitLane.PITLANE_NUM:
		Logger.log_message("PLID %d entered the pit lane." % [packet.player_id])
	elif packet.fact == InSim.PitLane.PITLANE_EXIT:
		Logger.log_message("PLID %d exited the pit lane." % [packet.player_id])


func _on_pll_received(packet: InSimPLLPacket) -> void:
	map.remove_arrow_by_plid(packet.player_id)


func _on_plp_received(packet: InSimPLPPacket) -> void:
	map.hide_arrow_by_plid(packet.player_id)


func _on_psf_received(packet: InSimPSFPacket) -> void:
	Logger.log_message("PLID %d stopped in pits for %ss." \
			% [packet.player_id, GISUtils.get_time_string_from_seconds(packet.gis_stop_time)])


func _on_res_received(packet: InSimRESPacket) -> void:
	print(packet.get_dictionary())


func _on_rst_received(packet: InSimRSTPacket) -> void:
	Logger.log_message("Race is starting.")
	print("Nodes in track: %d" % [packet.num_nodes])
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NPL))
	map.set_background(packet.track)
	map.clear_arrows()


func _on_slc_received(packet: InSimSLCPacket) -> void:
	var connection := get_connection_from_ucid(packet.ucid)
	if not connection:
		return
	connection.selected_car = packet.car_name


func _on_spx_received(packet: InSimSPXPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		return
	player.add_split(packet)
	Logger.log_message("Split %d for PLID %d: %s" % [packet.split, packet.player_id,
			GISUtils.get_time_string_from_seconds(packet.gis_split_time)])


func _on_sta_received(packet: InSimSTAPacket) -> void:
	var game_paused := packet.flags & InSim.State.ISS_PAUSED
	if game_paused:
		map.pause()
	else:
		map.unpause()


func _on_toc_received(packet: InSimTOCPacket) -> void:
	Logger.log_message("Driver change for PLID %d: UCID %d took over from UCID %d." \
			% [packet.player_id, packet.new_ucid, packet.old_ucid])


func _on_tiny_ren_received(_packet: InSimTinyPacket) -> void:
	map.remove_arrows()
	Logger.log_message("Race ended.")


func _on_packet_received(packet: InSimPacket) -> void:
	if (
		packet is InSimFINPacket
		or packet is InSimFLGPacket
		or packet is InSimLAPPacket
		or packet is InSimMCIPacket
		or packet is InSimMSOPacket
		or packet is InSimPENPacket
		or packet is InSimPITPacket
		or packet is InSimPLAPacket
		or packet is InSimPSFPacket
		or packet is InSimRESPacket
		or packet is InSimRSTPacket
		or packet is InSimSPXPacket
		or packet is InSimTOCPacket
	):
		return
	if (
		packet is InSimTinyPacket and (packet as InSimTinyPacket).sub_type in [
			InSim.Tiny.TINY_REN,
		]
	):
		return
	Logger.log_packet(packet)
#endregion
