extends Node

const FLOOR_TILE_ID = 1
const WALL_TILE_ID = 0

var width = 20
var height = 20
var maze = []
var tile_size = 64
var cell_size = 3 * tile_size
var tile_map


func _on_ready() -> void:
	tile_map = $TileMap
	generate_maze()
	project_maze_on_map()
	spawn_chests()
	create_exit()
	spawn_player()
	spawn_skeletons()

func generate_maze():
	maze = []
	for x in range(width):
		maze.append([])
		for y in range(height):
			maze[x].append(1)  # 1 - стена, 0 - пол

	recursive_division(0, 0, width, height)

func recursive_division(x, y, w, h):
	if w < 2 or h < 2:
		return

	var dir = randi() % 2  # 0 - горизонтально, 1 - вертикально
	var pos = randi() % (w if dir == 0 else h)

	if dir == 0:
		for i in range(h):
			maze[x + pos][y + i] = 0  # пол
		recursive_division(x, y, pos, h)
		recursive_division(x + pos + 1, y, w - pos - 1, h)
	else:
		for i in range(w):
			maze[x + i][y + pos] = 0  # пол
		recursive_division(x, y, w, pos)
		recursive_division(x, y + pos + 1, w, h - pos - 1)

func project_maze_on_map():
	for x in range(width):
		for y in range(height):
			if maze[x][y] == 1:
				tile_map.set_cell(0, Vector2i(x, y), WALL_TILE_ID)  # стена
			else:
				tile_map.set_cell(0, Vector2i(x, y), FLOOR_TILE_ID)  # пол

func spawn_chests():
	var chests = []
	for x in range(0, width, 10):
		for y in range(0, height, 10):
			var chest_type = randi() % 2
			if chest_type == 0:
				# 2 обычных сундука
				for meme in range(2):
					var chest_x = x + randi() % 10
					var chest_y = y + randi() % 10
					if tile_map.get_cell(0, Vector2i(chest_x, chest_y)) == FLOOR_TILE_ID:
						# Сундук на полу
						var chest = load("res://game/scenes/Chest.tscn").instance()
						chest.position = Vector2(chest_x * tile_size, chest_y * tile_size)
						add_child(chest)
						chests.append(chest)
			else:
				# 1 обычный и 1 особый сундук
				var chest_x = x + randi() % 10
				var chest_y = y + randi() % 10
				if tile_map.get_cell(0, Vector2i(chest_x, chest_y)) == FLOOR_TILE_ID:
					# Сундук на полу
					var chest = load("res://game/scenes/Chest.tscn").instance()
					chest.position = Vector2(chest_x * tile_size, chest_y * tile_size)
					add_child(chest)
					chests.append(chest)
				var special_chest_x = x + randi() % 10
				var special_chest_y = y + randi() % 10
				if tile_map.get_cell(0, Vector2i(special_chest_x, special_chest_y)) == FLOOR_TILE_ID:
					# Особый сундук на полу
					var special_chest = load("res://game/scenes/SpecialChest.tscn").instance()
					special_chest.position = Vector2(special_chest_x * tile_size, special_chest_y * tile_size)
					add_child(special_chest)
					chests.append(special_chest)
	return chests

func create_exit():
	var exit_x = randi() % width
	var exit_y = 0
	tile_map.set_cell(0, Vector2i(exit_x, exit_y), FLOOR_TILE_ID)  # создаем дыру в стене
	return Vector2(exit_x * tile_size, exit_y * tile_size)

func spawn_player():
	var exit_position = create_exit()
	var player_position = get_farthest_position_from_exit(exit_position)
	var player = load("res://game/scenes/Player.tscn").instance()
	player.position = player_position
	add_child(player)

func get_farthest_position_from_exit(exit_position):
	var farthest_position = Vector2()
	var max_distance = 0
	for x in range(width):
		for y in range(height):
			if tile_map.get_cell(0, Vector2i(x, y)) == FLOOR_TILE_ID:
				var distance = (Vector2(x * tile_size, y * tile_size) - exit_position).length()
				if distance > max_distance:
					max_distance = distance
					farthest_position = Vector2(x * tile_size, y * tile_size)
	return farthest_position

func spawn_skeletons():
	var chests = spawn_chests()
	var skeleton_count = int(chests.size() * 1.5)
	for meme in range(skeleton_count):
		var skeleton_x = randi() % width
		var skeleton_y = randi() % height
		if tile_map.get_cell(0, Vector2i(skeleton_x, skeleton_y)) == FLOOR_TILE_ID:
			var skeleton = load("res://game/scenes/Skeleton.tscn").instance()
			skeleton.position = Vector2(skeleton_x * tile_size, skeleton_y * tile_size)
			add_child(skeleton)
