class_name RelativeTimes
extends Node


signal reinitialization_requested

const PTH_STEP := 1
const HIDDEN_CLASS_NAME := "hidden"

var nodes: Array[int] = []
var times: Array[RelativeTimesDriver] = []
var proximity_threshold := 0.5
var car_classes: Array[CarClass] = []

var relative_cars := 7
var hidden_class_cars_displayed := true

var insim_buttons: InSimRelativeTimes = null


func add_driver(player: Player) -> void:
	var driver_times := RelativeTimesDriver.new(player.plid, player.nickname,
			player.car, nodes.size())
	times.append(driver_times)


func clear_insim_buttons() -> void:
	insim_buttons.clear_buttons()


func clear_times() -> void:
	times.clear()


func create_insim_buttons(insim_instance: InSim) -> void:
	insim_buttons = InSimRelativeTimes.new(insim_instance)


func initialize(packet: InSimRSTPacket, players: Array[Player]) -> void:
	print("Nodes in track: %d" % [packet.num_nodes])
	print("Finish line: %d" % [packet.finish])
	print("Split 1: %d" % [packet.split1])
	print("Split 2: %d" % [packet.split2])
	print("Split 3: %d" % [packet.split3])
	times.clear()
	var total_nodes := packet.num_nodes
	if total_nodes == 0:
		print("PTH file invalid or not found. Relative times are disabled.")
		return
	var sectors := 1
	var splits: Array[int] = [packet.finish, packet.split1, packet.split2, packet.split3]
	for i in 3:
		if splits[i + 1] > 0 and splits[i + 1] <= total_nodes:
			sectors += 1
	nodes.clear()
	var _discard := nodes.resize(total_nodes)
	var idx := 0
	for i in sectors:
		var first_node := splits[i]
		var last_node := splits[0] if i == sectors - 1 else splits[i + 1]
		if last_node < first_node:
			last_node += total_nodes
		var possible_nodes := last_node - first_node
		var step := possible_nodes / floorf(possible_nodes as float / PTH_STEP)
		var candidate_node := first_node + step
		while candidate_node < last_node or is_equal_approx(candidate_node, last_node):
			nodes[idx] = roundi(candidate_node if candidate_node <= total_nodes \
					else candidate_node - total_nodes)
			idx += 1
			candidate_node += step
	_discard = nodes.resize(idx)
	print("RelativeTimes kept %d nodes from %d total." % [nodes.size(), total_nodes])
	if packet.num_players != players.size():
		push_error("RelativeTimes encountered a mismatch in player count.")
		reinitialization_requested.emit()
		return
	reinitialize(players)


func reinitialize(players: Array[Player]) -> void:
	times.clear()
	for player in players:
		add_driver(player)


func remove_driver(plid: int) -> void:
	for i in times.size():
		if times[i].plid == plid:
			times[i].clear()
			times.remove_at(i)
			return


func show_insim_buttons() -> void:
	insim_buttons.show_buttons(0)


func sort_drivers_by_position() -> Array[RelativeTimesDriver]:
	var sorted_drivers: Array[RelativeTimesDriver] = times.duplicate() as Array[RelativeTimesDriver]
	sorted_drivers.sort_custom(func(a: RelativeTimesDriver, b: RelativeTimesDriver) -> bool:
		return a.lfs_position < b.lfs_position)
	return sorted_drivers


func sort_drivers_by_proximity(reference_plid: int) -> Array[RelativeTimesDriver]:
	var reference_driver: RelativeTimesDriver = null
	for driver in times:
		if driver.plid == reference_plid:
			reference_driver = driver
			break
	var drivers_in_front: Array[RelativeTimesDriver] = []
	var drivers_behind: Array[RelativeTimesDriver] = []
	var threshold := nodes.size() * proximity_threshold
	var reference_idx := reference_driver.last_updated_index
	for driver in times:
		if driver == reference_driver:
			continue
		var idx := driver.last_updated_index
		var difference := idx - reference_idx
		var abs_difference := absi(difference)
		var behind := true if (difference < 0 and abs_difference < threshold
				or difference > 0 and abs_difference > nodes.size() - threshold) else false
		if behind:
			drivers_behind.append(driver)
		else:
			drivers_in_front.append(driver)
	drivers_behind.sort_custom(func(a: RelativeTimesDriver, b: RelativeTimesDriver) -> bool:
		var difference_a := a.last_updated_index - reference_driver.last_updated_index
		var difference_b := b.last_updated_index - reference_driver.last_updated_index
		if difference_a > 0:
			difference_a -= nodes.size()
		if difference_b > 0:
			difference_b -= nodes.size()
		return difference_a > difference_b
	)
	drivers_in_front.sort_custom(func(a: RelativeTimesDriver, b: RelativeTimesDriver) -> bool:
		var difference_a := a.last_updated_index - reference_driver.last_updated_index
		var difference_b := b.last_updated_index - reference_driver.last_updated_index
		if difference_a < 0:
			difference_a += nodes.size()
		if difference_b < 0:
			difference_b += nodes.size()
		return difference_a > difference_b
	)
	var sorted_drivers: Array[RelativeTimesDriver] = []
	sorted_drivers.append_array(drivers_in_front)
	sorted_drivers.append(reference_driver)
	sorted_drivers.append_array(drivers_behind)
	return sorted_drivers


func update_car_classes(categories: Array[CarClass]) -> void:
	car_classes = categories.duplicate()


func update_position(plid: int, position: int) -> void:
	for driver in times:
		if driver.plid == plid:
			driver.lfs_position = position
			for d in times:
				if d.lfs_position == position and d.plid != plid:
					update_position(d.plid, position + 1)
					break
			return


func update_time(plid: int, position: int, lap: int, node: int, time: float) -> void:
	var idx := nodes.find(node)
	if idx < 0:
		return
	for driver in times:
		if driver.plid == plid:
			update_position(plid, position)
			driver.lap = lap
			driver.times[idx] = time
			driver.last_updated_index = idx
			return
	push_warning("RelativeTimes could not update time for PLID %d: not found." % [plid])
	reinitialization_requested.emit()


func update_gaps_between_cars() -> void:
	if times.is_empty():
		return
	#var panels := players_vbox.get_children()
	#for panel in panels:
		#players_vbox.remove_child(panel)
	#for driver in times:
		#var plid := driver.plid
		#for panel in panels:
			#var label := panel.get_child(0) as RichTextLabel
			#if label.get_meta("plid", 0) == plid:
				#players_vbox.add_child(panel)
				#var player := get_player_from_plid(plid)
				#label.text = "%s (PLID %d, UCID %d) - node %d" % \
						#[LFSText.lfs_colors_to_bbcode(player.nickname),
						#player.plid, player.ucid, nodes[driver.last_updated_index]]
				#break
	for i in times.size():
		var idx := times.size() - 1 - i
		if idx == 0:
			return
		var driver := times[idx]
		var driver_in_front := times[idx - 1]
		var lap_difference := driver_in_front.lap - driver.lap
		if (
			driver_in_front.last_updated_index == nodes.size() - 1
			or driver.last_updated_index > driver_in_front.last_updated_index
			and driver.last_updated_index != nodes.size() - 1
		):
			lap_difference -= 1
		var difference := driver.times[driver.last_updated_index] \
				- driver_in_front.times[driver.last_updated_index]
		#var label := players_vbox.get_child(idx).get_child(0) as RichTextLabel
		#label.text += ": %s" % ["%+dL" % [lap_difference] if lap_difference != 0 else \
				#"%s" % [GISUtils.get_time_string_from_seconds(difference, 1, true, true)]]


func update_intervals_to_plid(reference_plid: int) -> void:
	if times.is_empty():
		return
	var sorted_drivers := sort_drivers_by_proximity(reference_plid)
	var target_driver: RelativeTimesDriver = null
	for driver in sorted_drivers:
		if driver.plid == reference_plid:
			target_driver = driver
			break
	var standings := sort_drivers_by_position()
	var class_positions: Array[int] = []
	for category in car_classes:
		class_positions.append(0)
	var position_offset := 0
	var cars_to_remove: Array[RelativeTimesDriver] = []
	for driver in standings:
		driver.car_class = null
		driver.class_position = 0
		var hidden_car := false
		for i in car_classes.size():
			if driver.car in car_classes[i].cars:
				driver.car_class = car_classes[i]
				class_positions[i] += 1
				driver.class_position = class_positions[i]
				if car_classes[i].name == HIDDEN_CLASS_NAME:
					hidden_car = true
					driver.class_position = 0
					position_offset -= 1
					driver.overall_position = 0
					cars_to_remove.append(driver)
				break
		if not hidden_car:
			driver.overall_position = driver.lfs_position + position_offset
	if not hidden_class_cars_displayed:
		for driver in cars_to_remove:
			standings.erase(driver)
			sorted_drivers.erase(driver)
	var total_cars := sorted_drivers.size()
	var half_relative_cars := floori(relative_cars / 2.0)
	var max_cars := half_relative_cars * 2 + 1
	var target_idx := sorted_drivers.find(target_driver)
	var first_idx := target_idx - floori(max_cars / 2.0)
	var last_idx := target_idx + floori(max_cars / 2.0)
	if max_cars >= total_cars:
		first_idx = 0
		last_idx = total_cars - 1
	elif first_idx < 0:
		var offset := -first_idx
		first_idx += offset
		last_idx += offset
	elif last_idx >= total_cars:
		var offset := last_idx - total_cars + 1
		first_idx -= offset
		last_idx -= offset
	var displayed_cars := last_idx - first_idx + 1
	if insim_buttons.buttons_enabled and displayed_cars != insim_buttons.buttons_num_cars:
		insim_buttons.clear_buttons()
		insim_buttons.initialize_buttons(displayed_cars)
		insim_buttons.buttons_num_cars = displayed_cars
	#var panels: Array[PanelContainer] = []
	#panels.assign(players_vbox.get_children())
	#for panel in panels:
		#panel.visible = false
		#players_vbox.remove_child(panel)
	#for i in displayed_cars:
		#var idx := first_idx + i
		#var driver := sorted_drivers[idx]
		#var plid := driver.plid
		#for panel in panels:
			#var label := panel.get_child(0) as RichTextLabel
			#if label.get_meta("plid", 0) == plid:
				#panel.visible = true
				#players_vbox.add_child(panel)
				#var player := get_player_from_plid(plid)
				#label.text = "%-3d\t%-24s" % [driver.position,
						#LFSText.lfs_colors_to_bbcode(player.nickname)]
				#if not insim_buttons.buttons_enabled:
					#break
				#insim_buttons.update_button_text(insim_buttons.first_button_idx + (i + 1) * 4 + 1,
						#"%s%s" % ["^7" if plid == reference_plid else "", str(driver.position)])
				#insim_buttons.update_button_text(insim_buttons.first_button_idx + (i + 1) * 4 + 2,
						#"^%d%s" % [LFSText.ColorCode.DEFAULT if not driver.car_class \
						#else driver.car_class.insim_color, str(driver.class_position)])
				#insim_buttons.update_button_text(insim_buttons.first_button_idx + (i + 1) * 4 + 3, player.nickname)
				#break
	#for panel in panels:
		#if not panel.get_parent():
			#players_vbox.add_child(panel)
	for i in displayed_cars:
		var idx := last_idx - i
		var driver_front: RelativeTimesDriver = null
		var driver_back: RelativeTimesDriver = null
		var lap_difference := 0
		var time_difference := 0.0
		if idx > target_idx:
			driver_front = target_driver
			driver_back = sorted_drivers[idx]
		elif idx < target_idx:
			driver_front = sorted_drivers[idx]
			driver_back = target_driver
		else:
			driver_front = target_driver
			driver_back = target_driver
		var lapping := false
		var position_difference := driver_back.overall_position - driver_front.overall_position
		if (
			absi(idx - target_idx) < absi(position_difference)
			or absi(idx - target_idx) == -absi(position_difference)
		):
			lapping = true
		lap_difference = driver_front.lap - driver_back.lap
		if (
			driver_front.last_updated_index == nodes.size() - 1
			or driver_back.last_updated_index > driver_front.last_updated_index
			and driver_back.last_updated_index != nodes.size() - 1
		):
			lap_difference -= 1
		if lap_difference != 0:
			lapping = true
		time_difference = driver_back.times[driver_back.last_updated_index] \
				- driver_front.times[driver_back.last_updated_index]
		if idx < target_idx:
			lap_difference = -lap_difference
			time_difference = -time_difference
		var interval_string := "%s" % \
				[GISUtils.get_time_string_from_seconds(time_difference, 1, true, true)]
		var lapping_string := "%+dL" % [lap_difference]
		if lapping and lap_difference == 0:
			lapping = false
		#var label := players_vbox.get_child(idx - first_idx).get_child(0) as RichTextLabel
		#label.text += "\t%s" % [interval_string] + (" (%s)" % [lapping_string] if lapping else "")
		if not insim_buttons.buttons_enabled:
			continue
		var driver := sorted_drivers[idx]
		var plid := driver.plid
		var hidden_class := true if driver.car_class \
				and driver.car_class.name == HIDDEN_CLASS_NAME else false
		insim_buttons.update_driver_info(
			displayed_cars - i,
			"%s%s" % ["^7" if plid == reference_plid else "",
					str(driver.overall_position) if not hidden_class else "-"],
			"-" if hidden_class or not driver.car_class else \
					"^%d%s" % [driver.car_class.insim_color, str(driver.class_position)],
			driver.car,
			driver.name,
			insim_buttons.UNKNOWN_INTERVAL_STRING if driver_front == driver_back else
					"^%d%s" % [insim_buttons.interval_color_lapping if lap_difference < 0 \
					else insim_buttons.interval_color_lapped if lap_difference > 0 \
					else insim_buttons.interval_color_front if idx < target_idx \
					else insim_buttons.interval_color_behind, interval_string]
					+ (" (%s)" % [lapping_string] if lapping else "")
		)
