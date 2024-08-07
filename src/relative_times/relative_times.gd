class_name RelativeTimes
extends Node


signal reinitialization_requested

const MAX_CARS_IN_RACE := 40
const PTH_STEP := 1

var nodes: Array[int] = []
var times: Array[DriverTimes] = []


func clear_times() -> void:
	times.clear()


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
	for player in players:
		var driver_times := DriverTimes.new(player.plid, nodes.size())
		times.append(driver_times)


func remove_driver(plid: int) -> void:
	for i in times.size():
		if times[i].plid == plid:
			times.remove_at(i)
			return


func sort_drivers_by_position() -> Array[DriverTimes]:
	var sorted_drivers: Array[DriverTimes] = times.duplicate() as Array[DriverTimes]
	sorted_drivers.sort_custom(func(a: DriverTimes, b: DriverTimes) -> bool:
		return a.position < b.position)
	return sorted_drivers


func sort_drivers_by_proximity(reference_plid: int) -> Array[DriverTimes]:
	var reference_driver: DriverTimes = null
	for driver in times:
		if driver.plid == reference_plid:
			reference_driver = driver
			break
	var drivers_in_front: Array[DriverTimes] = []
	var drivers_behind: Array[DriverTimes] = []
	var half_count := nodes.size() / 2.0
	var reference_idx := reference_driver.last_updated_index
	for driver in times:
		if driver == reference_driver:
			continue
		var idx := driver.last_updated_index
		var difference := idx - reference_idx
		var abs_difference := absi(difference)
		var behind := true if (difference < 0 and abs_difference < half_count
		or difference > 0 and abs_difference > half_count) else false
		if behind:
			drivers_behind.append(driver)
		else:
			drivers_in_front.append(driver)
	drivers_behind.sort_custom(func(a: DriverTimes, b: DriverTimes) -> bool:
		var difference_a := a.last_updated_index - reference_driver.last_updated_index
		var difference_b := b.last_updated_index - reference_driver.last_updated_index
		if difference_a > 0:
			difference_a -= nodes.size()
		if difference_b > 0:
			difference_b -= nodes.size()
		return difference_a > difference_b
	)
	drivers_in_front.sort_custom(func(a: DriverTimes, b: DriverTimes) -> bool:
		var difference_a := a.last_updated_index - reference_driver.last_updated_index
		var difference_b := b.last_updated_index - reference_driver.last_updated_index
		if difference_a < 0:
			difference_a += nodes.size()
		if difference_b < 0:
			difference_b += nodes.size()
		return difference_a > difference_b
	)
	var sorted_drivers: Array[DriverTimes] = []
	sorted_drivers.append_array(drivers_in_front)
	sorted_drivers.append(reference_driver)
	sorted_drivers.append_array(drivers_behind)
	return sorted_drivers


func update_position(plid: int, position: int) -> void:
	for driver in times:
		if driver.plid == plid:
			driver.position = position
			for d in times:
				if d.position == position and d.plid != plid:
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


class DriverTimes extends RefCounted:
	var plid := 0
	var position := 0
	var lap := 0
	var times: Array[float] = []
	var last_updated_index := -1

	func _init(driver_plid: int, size: int) -> void:
		plid = driver_plid
		times.clear()
		var _discard := times.resize(size)

	func clear() -> void:
		plid = 0
		var size := times.size()
		times.clear()
		var _discard := times.resize(size)
