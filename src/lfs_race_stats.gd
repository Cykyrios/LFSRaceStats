extends MarginContainer


var insim := InSim.new()

var connections: Array[Connection] = []
var players: Array[Player] = []
var drivers: Array[Driver] = []

var relative_times := RelativeTimes.new()
var current_time := 0.0

@onready var map: Map = %Map as Map
@onready var connections_vbox := %ConnectionsVBox
@onready var players_vbox := %PlayersVBox


func _ready() -> void:
	add_child(insim)
	connect_signals()
	initialize_insim()

	add_child(relative_times)
	var timer := Timer.new()
	var _discard := timer.timeout.connect(relative_times.sort_drivers_by_position)
	add_child(timer)
	timer.start(1)
	_discard = relative_times.drivers_sorted.connect(func() -> void:
		var panels := players_vbox.get_children()
		for panel in panels:
			players_vbox.remove_child(panel)
		for driver in relative_times.times:
			var plid := driver.plid
			for panel in panels:
				var label := panel.get_child(0) as RichTextLabel
				if label.get_meta("plid", 0) == plid:
					players_vbox.add_child(panel)
					var player := get_player_from_plid(plid)
					label.text = "%s (PLID %d, UCID %d) - node %d" % \
							[LFSText.lfs_colors_to_bbcode(player.nickname),
							player.plid, player.ucid, relative_times.nodes[driver.last_updated_index]]
					break
		for i in relative_times.times.size():
			var idx := relative_times.times.size() - 1 - i
			if idx == 0:
				return
			var driver := relative_times.times[idx]
			var driver_in_front := relative_times.times[idx - 1]
			var lap_difference := driver_in_front.lap - driver.lap
			if (
				driver_in_front.last_updated_index == relative_times.nodes.size() - 1
				or driver.last_updated_index > driver_in_front.last_updated_index
				and driver.last_updated_index != relative_times.nodes.size() - 1
			):
				lap_difference -= 1
			var difference := driver.times[driver.last_updated_index] \
					- driver_in_front.times[driver.last_updated_index]
			var label := players_vbox.get_child(idx).get_child(0) as RichTextLabel
			label.text += ": %s" % ["%s%sL" % ["+" if lap_difference >= 0 else "", lap_difference] \
					if lap_difference != 0 else "%s%s" % ["+" if difference >= 0 else "",
					GISUtils.get_time_string_from_seconds(difference)]])


func connect_signals() -> void:
	var _discard := insim.isp_cnl_received.connect(_on_cnl_received)
	_discard = insim.isp_cpr_received.connect(_on_cpr_received)
	_discard = insim.isp_crs_received.connect(_on_crs_received)
	_discard = insim.isp_csc_received.connect(_on_csc_received)
	_discard = insim.isp_fin_received.connect(_on_fin_received)
	_discard = insim.isp_flg_received.connect(_on_flg_received)
	_discard = insim.isp_lap_received.connect(_on_lap_received)
	_discard = insim.isp_mci_received.connect(_on_mci_received)
	_discard = insim.isp_mso_received.connect(_on_mso_received)
	_discard = insim.isp_ncn_received.connect(_on_ncn_received)
	_discard = insim.isp_npl_received.connect(_on_npl_received)
	_discard = insim.isp_pit_received.connect(_on_pit_received)
	_discard = insim.isp_pla_received.connect(_on_pla_received)
	_discard = insim.isp_pll_received.connect(_on_pll_received)
	_discard = insim.isp_plp_received.connect(_on_plp_received)
	_discard = insim.isp_psf_received.connect(_on_psf_received)
	_discard = insim.isp_pen_received.connect(_on_pen_received)
	_discard = insim.isp_reo_received.connect(_on_reo_received)
	_discard = insim.isp_res_received.connect(_on_res_received)
	_discard = insim.isp_rst_received.connect(_on_rst_received)
	_discard = insim.isp_slc_received.connect(_on_slc_received)
	_discard = insim.isp_spx_received.connect(_on_spx_received)
	_discard = insim.isp_sta_received.connect(_on_sta_received)
	_discard = insim.isp_toc_received.connect(_on_toc_received)
	_discard = insim.small_rtp_received.connect(_on_small_rtp_received)
	_discard = insim.small_vta_received.connect(_on_small_vta_received)
	_discard = insim.tiny_ren_received.connect(_on_tiny_ren_received)
	_discard = insim.packet_received.connect(_on_packet_received)
	_discard = insim.connected.connect(_on_insim_connected)


func initialize_insim() -> void:
	var init_data := InSimInitializationData.new()
	init_data.i_name = "GIS Race Stats"
	init_data.flags |= InSim.InitFlag.ISF_LOCAL | InSim.InitFlag.ISF_MCI
	init_data.interval = 100
	insim.initialize("127.0.0.1", 29999, init_data)


#region Connections, Players, Drivers
func get_connection_from_driver(driver: Driver) -> Connection:
	var username := driver.username
	for connection in connections:
		if connection.username == username:
			return connection
	return null


func get_connection_from_plid(plid: int) -> Connection:
	var player := get_player_from_plid(plid)
	if not player:
		return null
	return get_connection_from_ucid(player.ucid)


func get_connection_from_ucid(ucid: int) -> Connection:
	for connection in connections:
		if connection.ucid == ucid:
			return connection
	return null


func get_connection_from_username(username: String) -> Connection:
	for connection in connections:
		if connection.username == username:
			return connection
	return null


func get_driver_from_plid(plid: int) -> Driver:
	return _get_driver_from_connection(get_connection_from_plid(plid))


func get_driver_from_ucid(ucid: int) -> Driver:
	return _get_driver_from_connection(get_connection_from_ucid(ucid))


func get_driver_from_username(username: String) -> Driver:
	for driver in drivers:
		if driver.username == username:
			return driver
	return null


func get_player_from_driver(driver: Driver) -> Player:
	var connection := get_connection_from_driver(driver)
	if not connection:
		return null
	return get_player_from_ucid(connection.ucid)


func get_player_from_plid(plid: int) -> Player:
	for player in players:
		if player.plid == plid:
			return player
	return null


func get_player_from_ucid(ucid: int) -> Player:
	var connection := get_connection_from_ucid(ucid)
	if not connection:
		return null
	return get_player_from_plid(connection.plid)


func get_player_from_username(username: String) -> Player:
	var connection := get_connection_from_username(username)
	if not connection:
		return null
	return get_player_from_ucid(connection.ucid)


func _get_driver_from_connection(connection: Connection) -> Driver:
	if not connection:
		return null
	var username := connection.username
	for driver in drivers:
		if driver.username == username:
			return driver
	return null
#endregion

#region InSim callbacks
func _on_insim_connected() -> void:
	await get_tree().create_timer(1).timeout
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NCN))
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NPL))
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_RES))
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_RST))


func _on_cnl_received(packet: InSimCNLPacket) -> void:
	var connection := get_connection_from_ucid(packet.ucid)
	if not connection:
		push_error("Could not find connection with UCID %d" % [packet.ucid])
		return
	Logger.log_message("%s (%s, UCID %d) left." % [LFSText.strip_colors(connection.nickname),
			connection.username, connection.ucid])
	for panel: PanelContainer in connections_vbox.get_children():
		var label := panel.get_child(0) as RichTextLabel
		if label.get_meta("ucid", -1) == connection.ucid:
			panel.queue_free()
			break
	connections.erase(connection)


func _on_cpr_received(packet: InSimCPRPacket) -> void:
	var connection := get_connection_from_ucid(packet.ucid)
	if not connection:
		push_error("Could not find connection with UCID %d" % [packet.ucid])
		return
	var ucid := connection.ucid
	var old_name := connection.nickname
	var new_name := packet.player_name
	var new_plate := packet.plate
	Logger.log_message("%s (UCID %d) renamed to %s (plate %s)." % [LFSText.strip_colors(old_name),
			ucid, LFSText.strip_colors(new_name), new_plate])
	connection.nickname = new_name
	for panel: PanelContainer in connections_vbox.get_children():
		var label := panel.get_child(0) as RichTextLabel
		if label.get_meta("ucid") == ucid:
			label.text = "%s (%s, UCID %d)" % [LFSText.lfs_colors_to_bbcode(connection.nickname),
				LFSText.lfs_colors_to_bbcode(connection.username), connection.ucid]
			break
	var player := get_player_from_ucid(ucid)
	if not player:
		push_error("Could not find player from UCID %d" % [connection.ucid])
		return
	player.nickname = new_name
	player.plate = new_plate
	for panel: PanelContainer in players_vbox.get_children():
		var label := panel.get_child(0) as RichTextLabel
		if label.get_meta("plid") == player.plid:
			label.text = "%s (PLID %d, UCID %d)" % [LFSText.lfs_colors_to_bbcode(player.nickname),
				player.plid, player.ucid]
		break


func _on_crs_received(packet: InSimCRSPacket) -> void:
	var plid := packet.plid
	var player := get_player_from_plid(plid)
	Logger.log_message("%s (PLID %d) was reset." % [LFSText.strip_colors(player.nickname), plid])


func _on_csc_received(packet: InSimCSCPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("%s (PLID %d) %s." % [LFSText.strip_colors(player.nickname), player.plid,
			"started" if packet.csc_action == InSim.CSCAction.CSC_START else "stopped"])


func _on_fin_received(packet: InSimFINPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("%s (PLID %d) finished in %s (%d laps, best lap %s)." % \
			[LFSText.strip_colors(player.nickname), player.plid,
			GISUtils.get_time_string_from_seconds(packet.gis_race_time),
			packet.laps_done, GISUtils.get_time_string_from_seconds(packet.gis_best_lap)])


func _on_flg_received(packet: InSimFLGPacket) -> void:
	var flag_color := "Blue" if packet.flag == 1 else "Yellow" if packet.flag == 2 else "Unknown"
	var on_off := "cleared for" if packet.off_on == 0 else "caused by" if packet.flag == 2 \
			else "given to"
	var player := get_player_from_plid(packet.plid)
	var car_behind := get_player_from_plid(packet.car_behind)
	var flag_string := "%s flag %s %s (PLID %d)%s." % [flag_color, on_off,
			LFSText.strip_colors(player.nickname), player.plid, " (car behind: %s (PLID %d))" % \
			[LFSText.strip_colors(car_behind.nickname), car_behind.plid] if packet.flag == 1 \
			and packet.off_on == 1 else ""]
	Logger.log_message(flag_string)
	map.set_flags(packet.plid, -1 if packet.flag != 1 else 1 if packet.off_on else 0,
			 -1 if packet.flag != 2 else 1 if packet.off_on else 0)


func _on_lap_received(packet: InSimLAPPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	if not player:
		return
	player.add_lap(packet)
	Logger.log_message("Lap %d completed by %s (PLID %d): %s" % [packet.laps_done,
			LFSText.strip_colors(player.nickname), player.plid,
			GISUtils.get_time_string_from_seconds(packet.gis_lap_time)])


func _on_mci_received(packet: InSimMCIPacket) -> void:
	var time_request := InSimTinyPacket.new(1, InSim.Tiny.TINY_GTH)
	insim.send_packet(time_request)
	await insim.small_rtp_received
	for compcar in packet.info:
		map.update_arrow(compcar)
		relative_times.update_time(compcar.plid, compcar.position, compcar.lap,
				compcar.node, current_time)


func _on_mso_received(packet: InSimMSOPacket) -> void:
	var message := LFSText.strip_colors(packet.msg)
	if packet.user_type == InSim.MessageUserValue.MSO_USER:
		var connection := get_connection_from_ucid(packet.ucid)
		message = "%s (%s) - %s" % [LFSText.strip_colors(connection.nickname),
				connection.username, message]
	Logger.log_message(message)


func _on_ncn_received(packet: InSimNCNPacket) -> void:
	var connection := get_connection_from_ucid(packet.ucid)
	var new_connection := false
	if not connection:
		new_connection = true
		connection = Connection.new()
		connections.append(connection)
	connection.fill_info(packet)
	if new_connection:
		var panel := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color.hex(0x50505099)
		stylebox.content_margin_top = 4
		stylebox.content_margin_left = 4
		stylebox.content_margin_bottom = 4
		stylebox.content_margin_right = 4
		panel.add_theme_stylebox_override("panel", stylebox)
		var label := RichTextLabel.new()
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.bbcode_enabled = true
		label.fit_content = true
		label.add_theme_color_override("default_color", Color.hex(0xccccccff))
		label.text = "%s (%s, UCID %d)" % [LFSText.lfs_colors_to_bbcode(connection.nickname),
				LFSText.lfs_colors_to_bbcode(connection.username), connection.ucid]
		label.set_meta("ucid", connection.ucid)
		panel.add_child(label)
		connections_vbox.add_child(panel)
		Logger.log_message("New connection: %s (%s, UCID %d)." % \
				[LFSText.strip_colors(connection.nickname), connection.username, connection.ucid])


func _on_npl_received(packet: InSimNPLPacket) -> void:
	var plid := packet.plid
	var player := get_player_from_plid(plid)
	var new_player := false
	if not player:
		new_player = true
		player = Player.new()
		players.append(player)
	player.fill_info(packet)
	var connection := get_connection_from_plid(plid)
	if connection and packet.player_name == connection.nickname:
		connection.plid = plid
	if new_player:
		var panel := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color.hex(0x50505099)
		stylebox.content_margin_top = 4
		stylebox.content_margin_left = 4
		stylebox.content_margin_bottom = 4
		stylebox.content_margin_right = 4
		panel.add_theme_stylebox_override("panel", stylebox)
		var label := RichTextLabel.new()
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.bbcode_enabled = true
		label.fit_content = true
		label.add_theme_color_override("default_color", Color.hex(0xccccccff))
		label.text = "%s (PLID %d, UCID %d)" % [LFSText.lfs_colors_to_bbcode(player.nickname),
				player.plid, player.ucid]
		label.set_meta("plid", player.plid)
		panel.add_child(label)
		players_vbox.add_child(panel)
		Logger.log_message("New player joined: %s (PLID %d, %s)." % \
				[LFSText.strip_colors(player.nickname), player.plid, packet.car_name])

	var map_arrow := map.get_arrow_by_plid(player.plid)
	if not map_arrow:
		var compcar := CompCar.new()
		compcar.plid = player.plid
		map.add_arrow(compcar)
		map_arrow = map.get_arrow_by_plid(player.plid)
	map_arrow.visible = true


func _on_pen_received(packet: InSimPENPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("Penalty for %s (PLID %d): %s (%s)" % [LFSText.strip_colors(player.nickname),
			player.plid, InSim.Penalty.keys()[packet.new_penalty],
			InSim.PenaltyReason.keys()[packet.reason]])


func _on_pit_received(packet: InSimPITPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("%s (PLID %d) made a pit stop: (details to be added)" % \
			[LFSText.strip_colors(player.nickname), player.plid])


func _on_pla_received(packet: InSimPLAPacket) -> void:
	var plid := packet.plid
	var player := get_player_from_plid(plid)
	if not player:
		return
	var lap: LapData = null
	if player.laps.is_empty():
		lap = LapData.new()
	if packet.fact != InSim.PitLane.PITLANE_EXIT and packet.fact != InSim.PitLane.PITLANE_NUM:
		lap.inlap = true
		Logger.log_message("%s (PLID %d) entered the pit lane." % \
				[LFSText.strip_colors(player.nickname), plid])
		map.set_pitlane(plid, true)
	elif packet.fact == InSim.PitLane.PITLANE_EXIT:
		lap.outlap = true
		Logger.log_message("%s (PLID %d) exited the pit lane." % \
				[LFSText.strip_colors(player.nickname), plid])
		map.set_pitlane(plid, false)


func _on_pll_received(packet: InSimPLLPacket) -> void:
	var plid := packet.plid
	var player := get_player_from_plid(plid)
	for panel: PanelContainer in players_vbox.get_children():
		var label := panel.get_child(0) as RichTextLabel
		if label.get_meta("plid", -1) == plid:
			panel.queue_free()
			break
	players.erase(player)
	var connection := get_connection_from_plid(plid)
	if connection:
		connection.plid = -1
	Logger.log_message("%s (PLID %d) spectated or was removed." % \
			[LFSText.strip_colors(player.nickname), plid])
	map.remove_arrow_by_plid(plid)


func _on_plp_received(packet: InSimPLPPacket) -> void:
	var plid := packet.plid
	var player := get_player_from_plid(plid)
	Logger.log_message("%s (PLID %d) pitted." % [LFSText.strip_colors(player.nickname), plid])
	map.clear_flags_for_plid(plid)
	map.hide_arrow_by_plid(plid)


func _on_psf_received(packet: InSimPSFPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("%s (PLID %d) stopped in pits for %s." % \
			[LFSText.strip_colors(player.nickname), player.plid,
			GISUtils.get_time_string_from_seconds(packet.gis_stop_time) \
			+ ("s" if packet.gis_stop_time < 60 else "")])


func _on_reo_received(packet: InSimREOPacket) -> void:
	Logger.log_message("Starting grid:")
	for i in packet.plids.size():
		var id := packet.plids[i]
		if id == 0:
			break
		var player := get_player_from_plid(id)
		Logger.log_message("P%d: %s (PLID %d)" % [i + 1, LFSText.strip_colors(player.nickname), id])


func _on_res_received(packet: InSimRESPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	Logger.log_message("%s (PLID %d, %s) %s." % [LFSText.strip_colors(player.nickname),
			player.plid, packet.car_name,
			"did not finish" if packet.result_num == 255 else "finished P%d (best lap %s)" % \
			[packet.result_num + 1, GISUtils.get_time_string_from_seconds(packet.gis_best_lap)]])


func _on_rst_received(packet: InSimRSTPacket) -> void:
	if packet.req_i == 0:
		Logger.log_message("Session started.")
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NPL))
	map.set_background(packet.track)
	relative_times.initialize(packet, players)


func _on_slc_received(packet: InSimSLCPacket) -> void:
	var connection := get_connection_from_ucid(packet.ucid)
	if not connection:
		return
	connection.selected_car = packet.car_name


func _on_spx_received(packet: InSimSPXPacket) -> void:
	var player := get_player_from_plid(packet.plid)
	if not player:
		return
	player.add_split(packet)
	Logger.log_message("Split %d for %s (PLID %d): %s" % [packet.split,
			LFSText.strip_colors(player.nickname), player.plid,
			GISUtils.get_time_string_from_seconds(packet.gis_split_time)])


func _on_sta_received(packet: InSimSTAPacket) -> void:
	var game_paused := packet.flags & InSim.State.ISS_PAUSED
	if game_paused:
		map.pause()
	else:
		map.unpause()


func _on_toc_received(packet: InSimTOCPacket) -> void:
	var new_connection := get_connection_from_ucid(packet.new_ucid)
	var old_connection := get_connection_from_ucid(packet.old_ucid)
	Logger.log_message("Driver change for PLID %d: %s (UCID %d) took over from %s (UCID %d)." % \
			[packet.plid, LFSText.strip_colors(new_connection.nickname), packet.new_ucid,
			LFSText.strip_colors(old_connection.nickname), packet.old_ucid])


func _on_small_rtp_received(packet: InSimSmallPacket) -> void:
	current_time = packet.value / 100.0


func _on_small_vta_received(packet: InSimSmallPacket) -> void:
	var vote_action := "Nothing"
	match packet.value:
		InSim.Vote.VOTE_END:
			vote_action = "End race"
		InSim.Vote.VOTE_RESTART:
			vote_action = "Restart race"
		InSim.Vote.VOTE_QUALIFY:
			vote_action = "Start qualifying"
	Logger.log_message("Vote completed: %s." % [vote_action])


func _on_tiny_ren_received(_packet: InSimTinyPacket) -> void:
	map.remove_arrows()
	Logger.log_message("Session ended.")


func _on_packet_received(packet: InSimPacket) -> void:
	if (
		packet.type in [
			InSim.Packet.ISP_CCH,
			InSim.Packet.ISP_CIM,
			InSim.Packet.ISP_CNL,
			InSim.Packet.ISP_CPR,
			InSim.Packet.ISP_CRS,
			InSim.Packet.ISP_CSC,
			InSim.Packet.ISP_FIN,
			InSim.Packet.ISP_FLG,
			InSim.Packet.ISP_LAP,
			InSim.Packet.ISP_MCI,
			InSim.Packet.ISP_MSO,
			InSim.Packet.ISP_NCN,
			InSim.Packet.ISP_NPL,
			InSim.Packet.ISP_PEN,
			InSim.Packet.ISP_PIT,
			InSim.Packet.ISP_PLA,
			InSim.Packet.ISP_PLL,
			InSim.Packet.ISP_PSF,
			InSim.Packet.ISP_REO,
			InSim.Packet.ISP_RES,
			InSim.Packet.ISP_RST,
			InSim.Packet.ISP_SPX,
			InSim.Packet.ISP_STA,
			InSim.Packet.ISP_TOC,
			InSim.Packet.ISP_VER,
			InSim.Packet.ISP_VTN,
		] or packet is InSimTinyPacket and (packet as InSimTinyPacket).sub_type in [
			InSim.Tiny.TINY_NONE,
			InSim.Tiny.TINY_AXC,
			InSim.Tiny.TINY_REN,
			InSim.Tiny.TINY_REPLY,
			InSim.Tiny.TINY_VTC,
		] or packet is InSimSmallPacket and (packet as InSimSmallPacket).sub_type in [
			InSim.Small.SMALL_RTP,
			InSim.Small.SMALL_VTA,
		]
	):
		return
	Logger.log_packet(packet)
#endregion
