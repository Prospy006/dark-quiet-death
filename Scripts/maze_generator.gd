extends Node2D

@export var seed             : int            = 12345
@export var width            : int            = 21
@export var height           : int            = 21
@export var port_tile_id     : int            = 1
@export var port_chance      : float          = 0.05
@export var maze_tiles       : TileSet

# ID Exports
@export var id_plusjoint      : int = 16
@export var id_tjoint_lb      : int = 4
@export var id_tjoint_lt      : int = 5
@export var id_tjoint_tr      : int = 6
@export var id_tjoint_tl      : int = 7
@export var id_vertical_rep   : int = 8
@export var id_horizontal_rep : int = 9
@export var id_corner_tr      : int = 10
@export var id_corner_br      : int = 11
@export var id_corner_bl      : int = 12
@export var id_corner_tl      : int = 13

const TILE_FLOOR = 0

var grid : Array                 = []
var rng  : RandomNumberGenerator = RandomNumberGenerator.new()

@onready var floor_map := $FloorLayer
@onready var wall_map  := $WallLayer
@onready var port_map  := $PortLayer

func _ready() -> void:
	rng.seed = seed
	if not maze_tiles:
		push_error("TileSet not assigned in Inspector.")
		return

	floor_map.tile_set = maze_tiles
	wall_map.tile_set  = maze_tiles
	port_map.tile_set  = maze_tiles

	_generate_maze()
	_draw_tiles()
	_stamp_ports()

func _generate_maze() -> void:
	_init_grid()
	_carve_passages(Vector2i(0, 0))

func _init_grid() -> void:
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append([true, true, true, true])
		grid.append(row)

func _carve_passages(cell: Vector2i) -> void:
	var directions = [
		Vector2i( 0, -1),
		Vector2i( 1,  0),
		Vector2i( 0,  1),
		Vector2i(-1,  0),
	]
	var indices = [0, 1, 2, 3]
	indices.shuffle()
	for idx in indices:
		var nxt = cell + directions[idx]
		if nxt.x >= 0 and nxt.x < width and nxt.y >= 0 and nxt.y < height:
			if _is_unvisited(nxt):
				grid[cell.y][cell.x][idx] = false
				grid[nxt.y][nxt.x][(idx + 2) % 4] = false
				_carve_passages(nxt)

func _is_unvisited(cell: Vector2i) -> bool:
	for wall in grid[cell.y][cell.x]:
		if wall == false:
			return false
	return true

func _draw_tiles() -> void:
	floor_map.clear()
	wall_map.clear()

	for y in range(height):
		for x in range(width):
			var pos   = Vector2i(x, y)
			var walls = grid[y][x]

			floor_map.set_cell(pos, TILE_FLOOR)
			wall_map.set_cell(pos, _tile_id_for_cell(walls))

func _tile_id_for_cell(walls: Array) -> int:
	var closed = walls.count(true)
	match closed:
		4:
			return id_plusjoint
		3:
			var idx = walls.find(false)
			match idx:
				0:
					return id_tjoint_lb
				1:
					return id_tjoint_lt
				2:
					return id_tjoint_tr
				3:
					return id_tjoint_tl
		2:
			if walls[0] and walls[2]:
				return id_vertical_rep
			if walls[1] and walls[3]:
				return id_horizontal_rep
			if walls[0] and walls[1]:
				return id_corner_tr
			if walls[1] and walls[2]:
				return id_corner_br
			if walls[2] and walls[3]:
				return id_corner_bl
			if walls[3] and walls[0]:
				return id_corner_tl
		1:
			if walls[0] or walls[2]:
				return id_vertical_rep
			else:
				return id_horizontal_rep
	return id_vertical_rep  # fallback

func _stamp_ports() -> void:
	port_map.clear()
	for y in range(height):
		for x in range(width):
			if grid[y][x].count(true) == 3 and rng.randi_range(0, 99) < int(port_chance * 100):
				port_map.set_cell(Vector2i(x, y), port_tile_id)
