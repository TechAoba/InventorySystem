class_name BackpackItem extends Sprite2D

var data: ItemBase = null
var is_picked: bool = false
var grid_position: Vector2

var size: Vector2:
	get():
		return Vector2(data.dimentions.x, data.dimentions.y) * Global.GridSize

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


# global_position为物体中心点，锚点anchor_point为物体左上角
func set_init_position(anchor_pos: Vector2) -> void:
	rotation_degrees = data.in_backpack_attr.rotate_degree
	global_position = anchor_pos + size / 2


func get_picked_up(grid_position: Vector2) -> void:
	self.grid_position = grid_position
	add_to_group("held_item")
	is_picked = true
	z_index = 10


## 放置物品 [br]
## mousePos: 鼠标绝对坐标
func get_placed(mousePos: Vector2, slot_idx: int) -> void:
	data.in_backpack_attr.slot_idx = slot_idx
	data.in_backpack_attr.is_placed = true
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
	var half_block := Global.GridSize / 2
	var around_anchor: Vector2i = (relative_pos - size / 2 + Vector2(half_block, half_block)) as Vector2i
	relative_pos = around_anchor / Global.GridSize * Global.GridSize
	global_position = relative_pos + size / 2 + grid_position


func _input(event: InputEvent) -> void:
	if event is InputEventKey and Input.is_action_just_pressed("tab"):
		if is_picked:
			do_rotation()


func do_rotation() -> void:
	var rotate_digree: int = data.rotate()
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotate_digree, 0.1)
	
	# 限制角度范围在[0, 360)
	tween.finished.connect(func():
		rotation_degrees = rotate_digree % 360
	)
