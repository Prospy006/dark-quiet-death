extends Node2D

@export var seed         := 12345
@export var width        := 21
@export var height       := 21
@export var port_tile_id := 3
@export var port_chance  := 0.05

var grid : Array
var rng  : RandomNumberGenerator

@onready var floor_map : TileMapLayer = $FloorLayer
@onready var wall_map  : TileMapLayer = $WallLayer
@onready var port_map  : TileMapLayer = $PortLayer

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed

	_generate_maze()
	_draw_tiles()
	_stamp_ports()

func _generate_maze() -> void:
	_init_grid()
	_carve_passages(Vector2i(0, 0))

func _init_grid() -> void:
	grid = []
	for y in range(height):
		var row := []
		for x in range(width):
			row.append([true, true, true, true])
		grid.append(row)

func _carve_passages(cell: Vector2i) -> void:
	var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var order = [0, 1, 2, 3]
	order.shuffle()
	for idx in order:
		var d = dirs[idx]
		var n = cell + d
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
			if grid[n.y][n.x].count(false) == 0:
				grid[cell.y][cell.x][idx] = false
				grid[n.y][n.x][(idx + 2) % 4] = false
				_carve_passages(n)

func _draw_tiles() -> void:
	floor_map.clear()
	wall_map.clear()

	for y in range(height):
		for x in range(width):
			var pos   = Vector2i(x, y)
			var walls = grid[y][x]

			floor_map.set_cell(pos, 0)

			if walls[0]:
				wall_map.set_cell(pos, 1)
			if walls[1]:
				wall_map.set_cell(pos + Vector2i(1, 0), 2)
			if walls[2]:
				wall_map.set_cell(pos + Vector2i(0, 1), 1)
			if walls[3]:
				wall_map.set_cell(pos, 2)

func _stamp_ports() -> void:
	for y in range(height):
		for x in range(width):
			if grid[y][x].count(true) == 3 and rng.randf() < port_chance:
				port_map.set_cell(Vector2i(x, y), port_tile_id)
