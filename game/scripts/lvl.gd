extends Node2D

@onready var tile_map = $TileMap
@onready var player = $Player/Player
const finish = preload("res://game/scenes/door.tscn")
const Peak = preload("res://game/scenes/objects/Peaks.tscn")
const Skeleton = preload("res://game/scenes/mobs/Skeleton.tscn")
const SimpleChest = preload("res://game/scenes/objects/Chest1.tscn")
const WORLD_WIDTH = 10  # in cells
const WORLD_HEIGHT = 10 # in cells
const CELL_SIZE = 3     # CELL_SIZExCELL_SIZE tiles in 1 cell
const TILE_SIZE = 64    # in pixels
const TRAPS_RATE = 0.02
const MOB_RATE = 0.3
const SIMPLE_CHEST_RATE = 0.01

# tileset id
var source_id = 1

# atlases for specific tiles
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

func _ready() -> void:
	generate_world()

func set_map_size(width, height):
	map_width = width
	map_height = height
	
func set_maze(new_maze):
	maze = new_maze

func generate_world():
	set_maze(generate_maze(WORLD_WIDTH, WORLD_HEIGHT))
	var start_pos = get_random_boundary_cell()
	var longest_path = find_longest_path(start_pos)
	var exit_pos = longest_path[-1]
	print(exit_pos)

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
	add_child(door)

	print_maze()
	print_path(longest_path)

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
	#place_traps()
	#place_mobs()
	#place_chests()

func get_wall_atlas(x, y, i, j):
	# Check if the current tile is on the edge of the cell
	if i == 0:
		if j == 0:
			# Top-left corner
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
			# Bottom-left corner
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
			# Left edge
			if x > 0 and maze[y][x - 1]:
				return wall_l_atlas
			else:
				return wall_atlas
	elif i == CELL_SIZE - 1:
		if j == 0:
			# Top-right corner
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
			# Bottom-right corner
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
			# Right edge
			if x < map_width - 1 and maze[y][x + 1]:
				return wall_r_atlas
			else:
				return wall_atlas
	else:
		if j == 0:
			# Top edge
			if y > 0 and maze[y - 1][x]:
				return wall_t_atlas
			else:
				return wall_atlas
		elif j == CELL_SIZE - 1:
			# Bottom edge
			if y < map_height - 1 and maze[y + 1][x]:
				return wall_b_atlas
			else:
				return wall_atlas
		else:
			# Inner tile
			return wall_atlas

func place_chests():
	var w = maze[0].size()
	var h = maze.size()
	print("Placing chests in a maze of size: ", w, "x", h)
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and is_next_to_wall(x, y):
				var rand_val = randf()
				if rand_val < SIMPLE_CHEST_RATE:
					place_chest(x, y, SimpleChest)

func place_chest(x, y, chest_type):
	var cell_x = x * CELL_SIZE
	var cell_y = y * CELL_SIZE
	var pos_x = randi() % CELL_SIZE
	var pos_y = randi() % CELL_SIZE
	var chest = chest_type.instantiate()
	chest.position = Vector2(
		(cell_x + pos_x + 0.5) * TILE_SIZE,
		(cell_y + pos_y + 0.5) * TILE_SIZE
	)
	chest.scale = Vector2(1, 1)
	add_child(chest)
	print("Added chest at position: ", chest.position)

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

func place_traps():
	var w = maze[0].size()
	var h = maze.size()
	print("Placing traps in a maze of size: ", w, "x", h)
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and randf() < TRAPS_RATE:
				print("Potential trap at: ", x, y)
				if has_opposite_wall_neighbors(x, y) and not is_too_close_to_player(x, y):
					place_traps_in_line(x, y)

func place_mobs():
	var w = maze[0].size()
	var h = maze.size()
	print("Placing mobs in a maze of size: ", w, "x", h)
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if maze[y][x] and randf() < MOB_RATE and not is_too_close_to_player(x, y):
				place_mob(x, y)

func place_mob(x, y):
	var cell_x = x * CELL_SIZE
	var cell_y = y * CELL_SIZE
	var pos_x = randi() % CELL_SIZE
	var pos_y = randi() % CELL_SIZE
	var mob = Skeleton.instantiate()
	mob.position = Vector2(
		(cell_x + pos_x + 0.5) * TILE_SIZE,
		(cell_y + pos_y + 0.5) * TILE_SIZE
	)
	mob.scale = Vector2(1, 1)
	add_child(mob)
	print("Added mob at position: ", mob.position)

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
	var result = has_left_and_right_walls or has_top_and_bottom_walls
	print("Checking opposite wall neighbors at: ", x, y, "Result: ", result)
	return result

func place_traps_in_line(x, y):
	var w = maze[0].size()
	var h = maze.size()
	var has_left_and_right_walls = (x > 0 and not maze[y][x - 1]) and (x < w - 1 and not maze[y][x + 1])
	var has_top_and_bottom_walls = (y > 0 and not maze[y - 1][x]) and (y < h - 1 and not maze[y + 1][x])
	if has_left_and_right_walls:
		for i in range(CELL_SIZE):
			var trap_x = x * CELL_SIZE + i
			var trap = Peak.instantiate()
			trap.position = Vector2(
				(trap_x + 0.5) * TILE_SIZE,
				(y * CELL_SIZE + CELL_SIZE / 2 + 0.5) * TILE_SIZE
			)
			trap.scale = Vector2(4, 4)
			add_child(trap)
			print("Added trap at horizontal position: ", trap.position)
	elif has_top_and_bottom_walls:
		for i in range(CELL_SIZE):
			var trap_y = y * CELL_SIZE + i
			var trap = Peak.instantiate()
			trap.position = Vector2(
				(x * CELL_SIZE + CELL_SIZE / 2 + 0.5) * TILE_SIZE,
				(trap_y + 0.5) * TILE_SIZE
			)
			trap.scale = Vector2(4, 4)
			add_child(trap)
			print("Added trap at vertical position: ", trap.position)

func print_path(path):
	print("\nСамый длинный путь:")
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			if not maze[y][x]:
				row += "▓"
			else:
				row += '*' if [x, y] in path else ' '
		print(row)

func print_maze():
	print("\nЛабиринт:")
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
	var start_x: int = 1
	var start_y: int = 1
	recursive_backtracker(maze, visited, start_x, start_y, w, h)
	for x in range(w):
		maze[0][x] = false
		maze[h - 1][x] = false
	for y in range(h):
		maze[y][0] = false
		maze[y][w - 1] = false
	return maze

func get_unvisited_neighbors(visited: Array, x: int, y: int, w: int, h: int) -> Array:
	var neighbors: Array = []
	if y > 1 and not visited[y - 2][x]:
		neighbors.append([x, y - 2])
	if y < h - 2 and not visited[y + 2][x]:
		neighbors.append([x, y + 2])
	if x > 1 and not visited[y][x - 2]:
		neighbors.append([x - 2, y])
	if x < w - 2 and not visited[y][x + 2]:
		neighbors.append([x + 2, y])
	return neighbors

func recursive_backtracker(maze: Array, visited: Array, x: int, y: int, w: int, h: int):
	visited[y][x] = true
	maze[y][x] = true
	var neighbors: Array = get_unvisited_neighbors(visited, x, y, w, h)
	while not neighbors.is_empty():
		var neighbor: Array = neighbors[randi() % neighbors.size()]
		var nx: int = neighbor[0]
		var ny: int = neighbor[1]
		var wall_x = x + (nx - x) / 2
		var wall_y = y + (ny - y) / 2
		maze[wall_y][wall_x] = true
		recursive_backtracker(maze, visited, nx, ny, w, h)
		neighbors = get_unvisited_neighbors(visited, x, y, w, h)

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
	var current_path: Array = []
	var path = dfs(visited, start_pos[0], start_pos[1], end_pos[0], end_pos[1], current_path)
	return path

func dfs(visited: Array, x: int, y: int, end_x: int, end_y: int, current_path: Array) -> Array:
	if x == end_x and y == end_y:
		var result_path = current_path.duplicate()
		result_path.append([x, y])
		return result_path
	visited[y][x] = true
	current_path.append([x, y])
	var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]
	for dir in directions:
		var nx = x + dir[0]
		var ny = y + dir[1]
		if nx >= 0 and nx < maze[0].size() and ny >= 0 and ny < maze.size():
			if maze[ny][nx] and not visited[ny][nx]:
				var result_path = dfs(visited, nx, ny, end_x, end_y, current_path)
				if result_path.size() > 0:
					return result_path
	current_path.pop_back()
	visited[y][x] = false
	return []

func _process(delta: float) -> void:
	pass
