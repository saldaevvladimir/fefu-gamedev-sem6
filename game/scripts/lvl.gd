extends Node2D

@onready var tile_map = $TileMap
@onready var player = $Player

const WORLD_WIDTH = 30  # in cells
const WORLD_HEIGHT = 20 # in cells

const CELL_SIZE = 3     # 4x4 tiles in 1 cell
const TILE_SIZE = 64    # in pixels

# tileset id
var source_id = 1

# atlases for specific tiles
var wall_atlas = Vector2i(8, 7)
var wall_t_atlas = Vector2i(2, 0)
var wall_r_atlas = Vector2i(0, 1)
var wall_b_atlas = Vector2i(4, 4)
var wall_l_atlas = Vector2i(5, 1)
var wall_ibr_atlas = Vector2i(5, 4)
var wall_ibl_atlas = Vector2i(0, 4)
var wall_otl_atlas = Vector2i(0, 5)
var wall_otr_atlas = Vector2i(5, 5)

var ground_atlas = Vector2i(9, 7)


func _ready() -> void:
	generate_world()
	
func generate_world():
	var maze = generate_maze(WORLD_WIDTH, WORLD_HEIGHT)
	var start_pos = get_random_boundary_cell(maze)
	var longest_path = find_longest_path(maze, start_pos)
	var exit_pos = longest_path[-1]
	
	generate_map(maze)
	player.position = Vector2(
		TILE_SIZE * (start_pos[0] * CELL_SIZE + CELL_SIZE / 2),
		TILE_SIZE * (start_pos[1] * CELL_SIZE + CELL_SIZE / 2)
	)
	print(start_pos)
	
	print_maze(maze)
	print_path(maze, longest_path)
	
	
func generate_map(maze):
	var w = maze[0].size()
	var h = maze.size()
	
	for x in range(w):
		for y in range(h):
			var offset_x = x * CELL_SIZE
			var offset_y = y * CELL_SIZE
			
			for i in range(CELL_SIZE):
				for j in range(CELL_SIZE):
					var atlas = ground_atlas if maze[y][x] else wall_atlas
					tile_map.set_cell(0, Vector2(offset_x + i, offset_y + j), source_id, atlas)
	
	
func print_path(maze, path):
	print("\nСамый длинный путь:")
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			if not maze[y][x]:
				row += "▓"
			else:
				row += '*' if [x, y] in path else ' '
		print(row)
		
func print_maze(maze):
	print("\nЛабиринт:")
	for y in range(maze.size()):
		var row = ""
		for x in range(maze[y].size()):
			row += "▓" if not maze[y][x] else " "
		print(row)
		
func get_random_boundary_cell(maze: Array) -> Array:
	var h: int = maze.size()
	if h == 0:
		return []
	var w: int = maze[0].size()
	var boundary_cells: Array = []
	# Проверяем верхнюю и нижнюю границы (y=1 и y=h-2)
	for x in range(1, w - 1):
		# Верхняя граница (y=1)
		if maze[1][x]:
			boundary_cells.append([x, 1])
		# Нижняя граница (y=h-2)
		if h >= 4 and maze[h - 2][x]:
			boundary_cells.append([x, h - 2])
	# Проверяем левую и правую границы (x=1 и x=w-2)
	for y in range(1, h - 1):
		# Левая граница (x=1)
		if maze[y][1]:
			boundary_cells.append([1, y])
		# Правая граница (x=w-2)
		if w >= 4 and maze[y][w - 2]:
			boundary_cells.append([w - 2, y])
	# Удаляем дубликаты
	var unique_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell not in unique_boundary_cells:
			unique_boundary_cells.append(cell)
	boundary_cells = unique_boundary_cells
	# Если нет граничных клеток, возвращаем пустой массив
	if boundary_cells.is_empty():
		return []
	# Выбираем случайную клетку из списка граничных клеток
	var random_index = randi() % boundary_cells.size()
	return boundary_cells[random_index]
		
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
		var wall_x = x + (nx - x) / 2
		var wall_y = y + (ny - y) / 2
		maze[wall_y][wall_x] = true
		recursive_backtracker(maze, visited, nx, ny, w, h)
		neighbors = get_unvisited_neighbors(visited, x, y, w, h)
		
func find_longest_path(maze: Array, start_pos: Array) -> Array:
	var w: int = maze[0].size()
	var h: int = maze.size()
	# Проверяем, что начальная точка является проходимой
	var start_x = start_pos[0]
	var start_y = start_pos[1]
	if not maze[start_y][start_x]:
		return []  # Начальная точка — стена, возвращаем пустой путь
	# Находим все граничные клетки
	var boundary_cells: Array = []
	# Верхняя и нижняя границы (y=1 и y=h-2)
	for x in range(1, w - 1, 2):  # Предполагаем, что проходимые клетки на нечётных позициях
		if maze[1][x]:
			boundary_cells.append([x, 1])
		if h >= 4 and maze[h - 2][x]:
			boundary_cells.append([x, h - 2])
	# Левая и правая границы (x=1 и x=w-2)
	for y in range(1, h - 1, 2):
		if maze[y][1]:
			boundary_cells.append([1, y])
		if w >= 4 and maze[y][w - 2]:
			boundary_cells.append([w - 2, y])
	# Удалим дубликаты
	var unique_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell not in unique_boundary_cells:
			unique_boundary_cells.append(cell)
	boundary_cells = unique_boundary_cells
	# Если начальная точка является граничной, удаляем её из списка граничных клеток
	var filtered_boundary_cells: Array = []
	for cell in boundary_cells:
		if cell != start_pos:
			filtered_boundary_cells.append(cell)
	boundary_cells = filtered_boundary_cells
	# Если нет граничных клеток (кроме, возможно, начальной), возвращаем пустой путь
	if boundary_cells.size() == 0:
		return []
	# Инициализируем максимальную длину пути и сам путь
	var longest_path: Array = []
	var max_length: int = 0
	# Перебираем все граничные клетки (кроме начальной) и ищем путь от start_pos до них
	for end_pos in boundary_cells:
		var path = find_path(maze, start_pos, end_pos)
		if path.size() > max_length:
			max_length = path.size()
			longest_path = path
	return longest_path

	
func find_path(maze: Array, start_pos: Array, end_pos: Array) -> Array:
	var w: int = maze[0].size()
	var h: int = maze.size()
	var visited: Array = []
	for y in range(h):
		visited.append([])
		for x in range(w):
			visited[y].append(false)
	var current_path: Array = []
	var path = dfs(maze, visited, start_pos[0], start_pos[1], end_pos[0], end_pos[1], current_path)
	return path
	
func dfs(maze: Array, visited: Array, x: int, y: int, end_x: int, end_y: int, current_path: Array) -> Array:
	if x == end_x and y == end_y:
		var result_path = current_path.duplicate()
		result_path.append([x, y])
		return result_path
	visited[y][x] = true
	current_path.append([x, y])
	# Проверяем соседей (вверх, вниз, влево, вправо)
	var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]
	for dir in directions:
		var nx = x + dir[0]
		var ny = y + dir[1]
		if nx >= 0 and nx < maze[0].size() and ny >= 0 and ny < maze.size():
			if maze[ny][nx] and not visited[ny][nx]:
				var result_path = dfs(maze, visited, nx, ny, end_x, end_y, current_path)
				if result_path.size() > 0:
					return result_path
	current_path.pop_back()
	visited[y][x] = false
	return []
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
