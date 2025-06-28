extends Node2D

@onready var tile_map = $TileMap
@onready var player = $Player/Player
@onready var loader = $CanvasLayer2/Loader

const finish = preload("res://game/scenes/door.tscn")
const Peak = preload("res://game/scenes/objects/Peaks.tscn")
const Skeleton = preload("res://game/scenes/mobs/Skeleton.tscn")
const SimpleChest = preload("res://game/scenes/objects/Chest1.tscn")

const WORLD_WIDTH = 100
const WORLD_HEIGHT = 100
const CELL_SIZE = 3
const TILE_SIZE = 64
const TRAPS_RATE = 0.2
const MOB_RATE = 0.4
const SIMPLE_CHEST_RATE = 0.15
const SPAWN_RANGE = 10 * TILE_SIZE
const DESPAWN_RANGE = 11 * TILE_SIZE

var source_id = 1
var ground_atlas = Vector2i(9, 7)
var wall_atlas = Vector2i(8, 7)
var wall_t_atlas = Vector2i(4, 4)
var wall_r_atlas = Vector2i(0, 1)
var wall_b_atlas = Vector2i(2, 0)
var wall_l_atlas = Vector2i(5, 1)
var wall_obr_atlas = Vector2i(4, 0)
var wall_obl_atlas = Vector2i(3, 0)
var wall_ibr_atlas = Vector2i(5, 4)
var wall_ibl_atlas = Vector2i(0, 4)
var wall_itl_atlas = Vector2i(0, 0)
var wall_itr_atlas = Vector2i(5, 0)
var wall_otl_atlas = Vector2i(0, 5)
var wall_otr_atlas = Vector2i(5, 5)

var maze = [[]]
var map_width = -1
var map_height = -1
var chest_positions = []
var trap_positions = []
var mob_positions = []
var active_chests = {}
var active_traps = {}
var active_mobs = {}

func _ready() -> void:
	loader.visible = true

	generate_world_async()

func generate_world_async():
	set_maze(generate_maze(WORLD_WIDTH, WORLD_HEIGHT))
	var start_pos = get_random_boundary_cell()
	var longest_path = find_longest_path(start_pos)
	var exit_pos = longest_path[-1]
	generate_map()
	player.position = Vector2(
		TILE_SIZE * (start_pos[0] * CELL_SIZE + CELL_SIZE / 2),
		TILE_SIZE * (start_pos[1] * CELL_SIZE + CELL_SIZE / 2)
	)
	player.z_index = 1
	var door_position = Vector2(
		TILE_SIZE * (exit_pos[0] * CELL_SIZE + CELL_SIZE / 2),
		TILE_SIZE * (exit_pos[1] * CELL_SIZE + CELL_SIZE / 2)
	)
	var door = finish.instantiate()
	door.position = door_position
	door.z_index = 1
	add_child(door)

	print_path(longest_path)

	await get_tree().create_timer(0.1).timeout

	loader.visible = false

func set_map_size(width, height):
	map_width = width
	map_height = height

func set_maze(new_maze):
	maze = new_maze

func generate_map():
	var w = map_width
	var h = map_height
	for x in range(w):
		for y in range(h):
			var offset_x = x * CELL_SIZE
			var offset_y = y * CELL_SIZE
			for i in range(CELL_SIZE):
				for j in range(CELL_SIZE):
					var atlas = ground_atlas if maze[y][x] else get_wall_atlas(x, y, i, j)
					tile_map.set_cell(0, Vector2(offset_x + i, offset_y + j), source_id, atlas)
	place_traps()
	place_mobs()
	place_chests()

func get_wall_atlas(x, y, i, j):
	if i == 0:
		if j == 0:
			if y > 0 and x > 0 and maze[y - 1][x] and maze[y][x - 1]:
				return wall_otl_atlas
			elif y > 0 and maze[y - 1][x]:
				return wall_t_atlas
			elif x > 0 and maze[y][x - 1]:
				return wall_l_atlas
			elif x > 0 and y > 0 and maze[y - 1][x - 1]:
				return wall_ibr_atlas
			else:
				return wall_atlas
		elif j == CELL_SIZE - 1:
			if y < map_height - 1 and x > 0 and maze[y + 1][x] and maze[y][x - 1]:
				return wall_obl_atlas
			elif y < map_height - 1 and maze[y + 1][x]:
				return wall_b_atlas
			elif x > 0 and maze[y][x - 1]:
				return wall_l_atlas
			elif x > 0 and y < map_height - 1 and maze[y + 1][x - 1]:
				return wall_itr_atlas
			else:
				return wall_atlas
		else:
			if x > 0 and maze[y][x - 1]:
				return wall_l_atlas
			else:
				return wall_atlas
	elif i == CELL_SIZE - 1:
		if j == 0:
			if y > 0 and x < map_width - 1 and maze[y - 1][x] and maze[y][x + 1]:
				return wall_otr_atlas
			elif y > 0 and maze[y - 1][x]:
				return wall_t_atlas
			elif x < map_width - 1 and maze[y][x + 1]:
				return wall_r_atlas
			elif y > 0 and x < map_width - 1 and maze[y - 1][x + 1]:
				return wall_ibl_atlas
			else:
				return wall_atlas
		elif j == CELL_SIZE - 1:
			if y < map_height - 1 and x < map_width - 1 and maze[y + 1][x] and maze[y][x + 1]:
				return wall_obr_atlas
			elif y < map_height - 1 and maze[y + 1][x]:
				return wall_b_atlas
			elif x < map_width - 1 and maze[y][x + 1]:
				return wall_r_atlas
			elif y < map_height - 1 and x < map_height - 1 and maze[y + 1][x + 1]:
				return wall_itl_atlas
			else:
				return wall_atlas
		else:
			if x < map_width - 1 and maze[y][x + 1]:
				return wall_r_atlas
			else:
				return wall_atlas
	else:
		if j == 0:
			if y > 0 and maze[y - 1][x]:
				return wall_t_atlas
			else:
				return wall_atlas
		elif j == CELL_SIZE - 1:
			if y < map_height - 1 and maze[y + 1][x]:
				return wall_b_atlas
			else:
				return wall_atlas
		else:
			return wall_atlas

func place_chests():
	var w = maze[0].size()
	var h = maze.size()
	chest_positions = []
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and is_next_to_wall(x, y):
				var rand_val = randf()
				if rand_val < SIMPLE_CHEST_RATE:
					var cell_x = x * CELL_SIZE
					var cell_y = y * CELL_SIZE
					var pos_x = randi() % CELL_SIZE
					var pos_y = randi() % CELL_SIZE
					var chest_pos = Vector2(
						(cell_x + pos_x + 0.5) * TILE_SIZE,
						(cell_y + pos_y + 0.5) * TILE_SIZE
					)
					chest_positions.append(chest_pos)

func place_traps():
	var w = maze[0].size()
	var h = maze.size()
	trap_positions = []
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and randf() < TRAPS_RATE:
				if has_opposite_wall_neighbors(x, y) and not is_too_close_to_player(x, y):
					var cell_x = x * CELL_SIZE
					var cell_y = y * CELL_SIZE
					var has_left_and_right_walls = (x > 0 and not maze[y][x - 1]) and (x < w - 1 and not maze[y][x + 1])
					var has_top_and_bottom_walls = (y > 0 and not maze[y - 1][x]) and (y < h - 1 and not maze[y + 1][x])
					if has_left_and_right_walls:
						for i in range(CELL_SIZE):
							var trap_x = x * CELL_SIZE + i
							var trap_pos = Vector2(
								(trap_x + 0.5) * TILE_SIZE,
								(y * CELL_SIZE + CELL_SIZE / 2 + 0.5) * TILE_SIZE
							)
							trap_positions.append(trap_pos)
					elif has_top_and_bottom_walls:
						for i in range(CELL_SIZE):
							var trap_y = y * CELL_SIZE + i
							var trap_pos = Vector2(
								(x * CELL_SIZE + CELL_SIZE / 2 + 0.5) * TILE_SIZE,
								(trap_y + 0.5) * TILE_SIZE
							)
							trap_positions.append(trap_pos)

func place_mobs():
	var w = maze[0].size()
	var h = maze.size()
	mob_positions = []
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and randf() < MOB_RATE and not is_too_close_to_player(x, y):
				var cell_x = x * CELL_SIZE
				var cell_y = y * CELL_SIZE
				var pos_x = randi() % CELL_SIZE
				var pos_y = randi() % CELL_SIZE
				var mob_pos = Vector2(
					(cell_x + pos_x + 0.5) * TILE_SIZE,
					(cell_y + pos_y + 0.5) * TILE_SIZE
				)
				mob_positions.append(mob_pos)

func is_next_to_wall(x, y):
	var w = maze[0].size()
	var h = maze.size()
	var has_wall_neighbors = false
	if x > 0 and not maze[y][x - 1]:
		has_wall_neighbors = true
	if x < w - 1 and not maze[y][x + 1]:
		has_wall_neighbors = true
	if y > 0 and not maze[y - 1][x]:
		has_wall_neighbors = true
	if y < h - 1 and not maze[y + 1][x]:
		has_wall_neighbors = true
	return has_wall_neighbors

func is_too_close_to_player(x, y):
	var player_cell_x = int(player.position.x / (TILE_SIZE * CELL_SIZE))
	var player_cell_y = int(player.position.y / (TILE_SIZE * CELL_SIZE))
	var distance = sqrt((x - player_cell_x) ** 2 + (y - player_cell_y) ** 2)
	return distance < 2

func has_opposite_wall_neighbors(x, y):
	var w = maze[0].size()
	var h = maze.size()
	var has_left_and_right_walls = (x > 0 and not maze[y][x - 1]) and (x < w - 1 and not maze[y][x + 1])
	var has_top_and_bottom_walls = (y > 0 and not maze[y - 1][x]) and (y < h - 1 and not maze[y + 1][x])
	return has_left_and_right_walls or has_top_and_bottom_walls

func spawn_object_at_position(position: Vector2, object_type: String) -> Node2D:
	var object: Node2D
	match object_type:
		"chest":
			object = SimpleChest.instantiate()
			object.add_to_group("chest")
			if object.has_signal("opened"):
				object.connect("opened", Callable(self, "_on_chest_opened"))
		"trap":
			object = Peak.instantiate()
			object.scale = Vector2(4, 4)
			object.add_to_group("trap")
		"mob":
			object = Skeleton.instantiate()
			object.add_to_group("mob")
			if object.has_signal("died"):
				object.connect("died", Callable(self, "_on_mob_died"))
	object.position = position
	add_child(object)
	match object_type:
		"chest":
			active_chests[position] = object
		"trap":
			active_traps[position] = object
		"mob":
			active_mobs[position] = object
	return object

func despawn_object(object: Node2D, position: Vector2, object_type: String):
	if not is_instance_valid(object):
		return
	match object_type:
		"chest":
			if active_chests.has(position):
				active_chests.erase(position)
			if not object.is_interactive():
				object.queue_free()
			else:
				chest_positions.append(position)
		"trap":
			if active_traps.has(position):
				active_traps.erase(position)
			trap_positions.append(position)
		"mob":
			if active_mobs.has(position):
				active_mobs.erase(position)
			if object.is_alive():
				mob_positions.append(object.position)
	object.queue_free()

func check_and_spawn_objects():
	var player_pos = player.position
	var to_spawn_chests = []
	for pos in chest_positions:
		var distance = player_pos.distance_to(pos)
		if distance <= SPAWN_RANGE:
			to_spawn_chests.append(pos)
	for pos in to_spawn_chests:
		chest_positions.erase(pos)
		var chest = spawn_object_at_position(pos, "chest")
	var to_spawn_traps = []
	for pos in trap_positions:
		var distance = player_pos.distance_to(pos)
		if distance <= SPAWN_RANGE:
			to_spawn_traps.append(pos)
	for pos in to_spawn_traps:
		trap_positions.erase(pos)
		var trap = spawn_object_at_position(pos, "trap")
	var to_spawn_mobs = []
	for pos in mob_positions:
		var distance = player_pos.distance_to(pos)
		if distance <= SPAWN_RANGE:
			to_spawn_mobs.append(pos)
	for pos in to_spawn_mobs:
		mob_positions.erase(pos)
		var mob = spawn_object_at_position(pos, "mob")

func check_and_despawn_objects():
	var player_pos = player.position
	var to_despawn_chests = []
	for pos in active_chests.keys():
		var distance = player_pos.distance_to(pos)
		if distance > DESPAWN_RANGE:
			to_despawn_chests.append(pos)
	for pos in to_despawn_chests:
		var chest = active_chests[pos]
		if is_instance_valid(chest):
			despawn_object(chest, pos, "chest")
	var to_despawn_traps = []
	for pos in active_traps.keys():
		var distance = player_pos.distance_to(pos)
		if distance > DESPAWN_RANGE:
			to_despawn_traps.append(pos)
	for pos in to_despawn_traps:
		var trap = active_traps[pos]
		if is_instance_valid(trap):
			despawn_object(trap, pos, "trap")
	var to_despawn_mobs = []
	for pos in active_mobs.keys():
		var distance = player_pos.distance_to(pos)
		if distance > DESPAWN_RANGE:
			to_despawn_mobs.append(pos)
	for pos in to_despawn_mobs:
		var mob = active_mobs[pos]
		if is_instance_valid(mob):
			despawn_object(mob, mob.position, "mob")

func _on_chest_opened(chest):
	if not is_instance_valid(chest):
		return
	var pos = chest.position
	if active_chests.has(pos):
		active_chests.erase(pos)
	chest.queue_free()

func _on_mob_died(mob):
	if not is_instance_valid(mob):
		return
	var pos = mob.position
	if active_mobs.has(pos):
		active_mobs.erase(pos)
	mob.queue_free()

func _process(delta: float) -> void:
	check_and_spawn_objects()
	check_and_despawn_objects()

func print_path(path):
	print()
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			if not maze[y][x]:
				row += "▓"
			else:
				row += '*' if [x, y] in path else ' '
		print(row)

func print_maze():
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			row += "▓" if not maze[y][x] else " "
		print(row)

func get_random_boundary_cell() -> Array:
	var h: int = maze.size()
	if h == 0:
		return []
	var w: int = maze[0].size()
	var boundary_cells: Array = []
	for x in range(1, w - 1):
		if maze[1][x]:
			boundary_cells.append([x, 1])
		if h >= 4 and maze[h - 2][x]:
			boundary_cells.append([x, h - 2])
	for y in range(1, h - 1):
		if maze[y][1]:
			boundary_cells.append([1, y])
		if w >= 4 and maze[y][w - 2]:
			boundary_cells.append([w - 2, y])
	var unique_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell not in unique_boundary_cells:
			unique_boundary_cells.append(cell)
	boundary_cells = unique_boundary_cells
	if boundary_cells.is_empty():
		return []
	var random_index = randi() % boundary_cells.size()
	return boundary_cells[random_index]

func generate_maze(width: int, height: int) -> Array:
	var w: int = width + (1 if width % 2 == 0 else 0)
	var h: int = height + (1 if height % 2 == 0 else 0)
	set_map_size(w, h)
	var maze: Array = []
	for y in range(h):
		maze.append([])
		for x in range(w):
			maze[y].append(false)
	var visited: Array = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)

	var start_x = randi() % (w - 2) + 1
	var start_y = randi() % (h - 2) + 1
	start_x = 1
	start_y = 1
	visited[start_y][start_x] = true
	maze[start_y][start_x] = true

	var walls = []
	if start_x > 1 and not visited[start_y][start_x - 2]:
		walls.append([start_x - 1, start_y, start_x - 2, start_y])
	if start_x < w - 2 and not visited[start_y][start_x + 2]:
		walls.append([start_x + 1, start_y, start_x + 2, start_y])
	if start_y > 1 and not visited[start_y - 2][start_x]:
		walls.append([start_x, start_y - 1, start_x, start_y - 2])
	if start_y < h - 2 and not visited[start_y + 2][start_x]:
		walls.append([start_x, start_y + 1, start_x, start_y + 2])

	while walls.size() > 0:
		var wall_index = randi() % walls.size()
		var wall = walls[wall_index]
		var x = wall[0]
		var y = wall[1]
		var nx = wall[2]
		var ny = wall[3]

		if not visited[ny][nx]:
			maze[y][x] = true
			visited[ny][nx] = true
			maze[ny][nx] = true

			if nx > 1 and not visited[ny][nx - 2]:
				walls.append([nx - 1, ny, nx - 2, ny])
			if nx < w - 2 and not visited[ny][nx + 2]:
				walls.append([nx + 1, ny, nx + 2, ny])
			if ny > 1 and not visited[ny - 2][nx]:
				walls.append([nx, ny - 1, nx, ny - 2])
			if ny < h - 2 and not visited[ny + 2][nx]:
				walls.append([nx, ny + 1, nx, ny + 2])
		walls.remove_at(wall_index)

	for x in range(w):
		maze[0][x] = false
		maze[h - 1][x] = false
	for y in range(h):
		maze[y][0] = false
		maze[y][w - 1] = false

	return maze

func find_longest_path(start_pos: Array) -> Array:
	var w: int = maze[0].size()
	var h: int = maze.size()
	var start_x = start_pos[0]
	var start_y = start_pos[1]
	if not maze[start_y][start_x]:
		return []
	var boundary_cells: Array = []
	for x in range(1, w - 1, 2):
		if maze[1][x]:
			boundary_cells.append([x, 1])
		if h >= 4 and maze[h - 2][x]:
			boundary_cells.append([x, h - 2])
	for y in range(1, h - 1, 2):
		if maze[y][1]:
			boundary_cells.append([1, y])
		if w >= 4 and maze[y][w - 2]:
			boundary_cells.append([w - 2, y])
	var unique_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell not in unique_boundary_cells:
			unique_boundary_cells.append(cell)
	boundary_cells = unique_boundary_cells
	var filtered_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell != start_pos:
			filtered_boundary_cells.append(cell)
	boundary_cells = filtered_boundary_cells
	if boundary_cells.size() == 0:
		return []
	var longest_path: Array = []
	var max_length: int = 0
	for end_pos in boundary_cells:
		var path = find_path(start_pos, end_pos)
		if path.size() > max_length:
			max_length = path.size()
			longest_path = path
	return longest_path

func find_path(start_pos: Array, end_pos: Array) -> Array:
	var w: int = maze[0].size()
	var h: int = maze.size()
	var visited: Array = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)
	var stack: Array = []
	var current_path: Array = []
	stack.append([start_pos, current_path])
	while stack.size() > 0:
		var current = stack.pop_back()
		var pos = current[0]
		current_path = current[1]
		var x: int = pos[0]
		var y: int = pos[1]
		if x == end_pos[0] and y == end_pos[1]:
			current_path.append([x, y])
			return current_path
		if not visited[y][x]:
			visited[y][x] = true
			current_path.append([x, y])
			var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]
			for dir in directions:
				var nx = x + dir[0]
				var ny = y + dir[1]
				if nx >= 0 and nx < w and ny >= 0 and ny < h:
					if maze[ny][nx] and not visited[ny][nx]:
						stack.append([[nx, ny], current_path.duplicate()])
	return []
