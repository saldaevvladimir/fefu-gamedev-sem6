extends Node2D

@export var noise_height_text: NoiseTexture2D
const WORLD_WIDTH = 20
const WORLD_HEIGHT = 20

func _ready() -> void:
	generate_world()

func generate_world():
	var maze = generate_maze(WORLD_WIDTH, WORLD_HEIGHT)
	print_maze(maze)

func print_maze(maze):
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			row += "▓" if not maze[y][x] else " "
		print(row)

func generate_maze(width: int, height: int) -> Array:
	# Округляем размеры до ближайшего нечетного числа
	var w: int = width + (1 if width % 2 == 0 else 0)
	var h: int = height + (1 if height % 2 == 0 else 0)

	# Инициализируем массив, заполненный стенами (false)
	var maze: Array = []
	for y in range(h):
		maze.append([])
		for x in range(w):
			maze[y].append(false)

	# Создаем массив посещенных клеток
	var visited: Array = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)

	# Начинаем с случайной клетки (нечетной, чтобы избежать границ)
	var start_x: int = 1
	var start_y: int = 1
	recursive_backtracker(maze, visited, start_x, start_y, w, h)

	# Устанавливаем границы лабиринта как стены
	for x in range(w):
		maze[0][x] = false
		maze[h - 1][x] = false

	for y in range(h):
		maze[y][0] = false
		maze[y][w - 1] = false

	return maze

func get_unvisited_neighbors(visited: Array, x: int, y: int, w: int, h: int) -> Array:
	var neighbors: Array = []
	# Проверяем соседей (вверх, вниз, влево, вправо)
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
		# Удаляем стену между текущей клеткой и соседом
		maze[(y + ny) / 2][(x + nx) / 2] = true
		recursive_backtracker(maze, visited, nx, ny, w, h)
		neighbors = get_unvisited_neighbors(visited, x, y, w, h)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
