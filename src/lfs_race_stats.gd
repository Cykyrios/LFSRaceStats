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
	print(packet.get_dictionary())


func _on_flg_received(packet: InSimFLGPacket) -> void:
	print(packet)


func _on_lap_received(packet: InSimLAPPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		return
	player.add_lap(packet)


func _on_mci_received(packet: InSimMCIPacket) -> void:
	for compcar in packet.info:
		map.update_arrow(compcar)


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
	print(packet)


func _on_pit_received(packet: InSimPITPacket) -> void:
	print(packet)


func _on_pla_received(packet: InSimPLAPacket) -> void:
	var player := get_player_from_plid(packet.player_id)
	if not player:
		return
	var lap: LapData = null
	if player.laps.is_empty():
		lap = LapData.new()
	if packet.fact != InSim.PitLane.PITLANE_EXIT and packet.fact != InSim.PitLane.PITLANE_NUM:
		pass


func _on_pll_received(packet: InSimPLLPacket) -> void:
	map.remove_arrow_by_plid(packet.player_id)


func _on_plp_received(packet: InSimPLPPacket) -> void:
	map.hide_arrow_by_plid(packet.player_id)


func _on_psf_received(packet: InSimPSFPacket) -> void:
	print(packet)


func _on_res_received(packet: InSimRESPacket) -> void:
	print(packet.get_dictionary())


func _on_rst_received(packet: InSimRSTPacket) -> void:
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


func _on_sta_received(packet: InSimSTAPacket) -> void:
	var game_paused := packet.flags & InSim.State.ISS_PAUSED
	if game_paused:
		map.pause()
	else:
		map.unpause()


func _on_toc_received(packet: InSimTOCPacket) -> void:
	print(packet)


func _on_tiny_ren_received(_packet: InSimTinyPacket) -> void:
	map.remove_arrows()


func _on_packet_received(packet: InSimPacket) -> void:
	if packet is InSimMCIPacket:
		return
	print(Time.get_time_string_from_system(), " - ", InSim.Packet.keys()[packet.type], ": ", packet.get_dictionary())
#endregion
