class_name InventoryItem extends Sprite2D

var data: ItemData = null
var is_picked: bool = false
var grid_position: Vector2

## 物品放置的偏移值
var place_offset: Vector2:
	get():
		return -Vector2(data.dimentions.x, data.dimentions.y) * GlobalVariable.GridSize / 2
var size: Vector2:
	get():
		return Vector2(data.dimentions.x, data.dimentions.y) * GlobalVariable.GridSize

var anchor_point: Vector2:
	get():
		return global_position - size / 2

func _ready() -> void:
	if data:
		texture = data.texture

func _process(delta: float) -> void:
	if is_picked:
		var pos := get_global_mouse_position()
		set_pos(pos)

func set_init_position(pos: Vector2) -> void:
	global_position = pos + size / 2
	
func get_picked_up(grid_position: Vector2) -> void:
	self.grid_position = grid_position
	add_to_group("held_item")
	is_picked = true
	z_index = 10

## 放置物品 [br]
## mousePos: 鼠标绝对坐标
func get_placed(mousePos: Vector2) -> void:
	is_picked = false
	z_index = 0
	set_pos(mousePos)
	remove_from_group("held_item")

## 设置物品位置，包含吸附功能 [br]
## mousePos: 鼠标绝对坐标
func set_pos(mousePos: Vector2) -> void:
	#var grid_position: Vector2 = item_grid.g_position
	var relative_pos: Vector2 = mousePos - grid_position
	# 四舍五入
	var half_block := GlobalVariable.GridSize / 2
	relative_pos = ((relative_pos as Vector2i) + (place_offset as Vector2i) + Vector2i(half_block, half_block)) / GlobalVariable.GridSize * GlobalVariable.GridSize
	global_position = relative_pos + size / 2 + grid_position
	anchor_point = relative_pos + grid_position

#func get_index() -> int:
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("tab"):
		if is_picked:
			do_rotation()

func do_rotation() -> void:
	data.is_rotated = !data.is_rotated
	data.dimentions = Vector2i(data.dimentions.y, data.dimentions.x)
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 90 if data.is_rotated else 0, 0.1)
