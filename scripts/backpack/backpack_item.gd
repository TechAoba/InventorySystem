class_name BackpackItem extends Control

@onready var item_control: Control = %ItemControl
@onready var color_rect: ColorRect = %ColorRect
@onready var count_label: Label = %CountLabel
@onready var texture_rect: TextureRect = %TextureRect


var data: ItemBase = null
var is_picked: bool = false
var grid_position: Vector2

const BgColor := Color("#121214CC")

var xy: Vector2:
	get():
		return Vector2(data.dimentions.x, data.dimentions.y) * Global.GridSize

var anchor_point: Vector2:
	get():
		return global_position - xy / 2


func _ready() -> void:
	color_rect.color = BgColor
	color_rect.z_index = -1
	z_index = 1
	if data:
		texture_rect.texture = data.texture
		color_rect.size = data.texture.get_size()
		color_rect.position = -data.in_backpack_attr.get_ori_dimention_in_backpack() * Global.GridSize as Vector2 / 2
		# 渲染物品数量
		count_label.visible = data.is_stackable()


func _process(delta: float) -> void:
	if is_picked:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			var pos := get_global_mouse_position()
			set_pos(pos)
	if data:
		count_label.text = str(data.in_backpack_attr.stack_count)

# global_position为物体中心点，锚点anchor_point为物体左上角
func set_init_position(anchor_pos: Vector2) -> void:
	item_control.rotation_degrees = data.in_backpack_attr.rotate_degree
	global_position = anchor_pos + xy / 2


func get_picked_up(grid_position: Vector2) -> void:
	self.grid_position = grid_position
	data.in_backpack_attr.is_placed = false
	add_to_group("held_item")
	is_picked = true
	z_index = 10
	Global.something_pickup = true
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		var pos := get_global_mouse_position()
		set_pos(pos)


## 放置物品 [br]
## mousePos: 鼠标绝对坐标
func get_placed(mousePos: Vector2, slot_idx: int) -> void:
	data.in_backpack_attr.slot_idx = slot_idx
	data.in_backpack_attr.is_placed = true
	is_picked = false
	z_index = 1
	set_pos(mousePos)
	remove_from_group("held_item")
	Global.something_pickup = false


## 设置物品位置，包含吸附功能 [br]
## mousePos: 鼠标绝对坐标
func set_pos(mousePos: Vector2) -> void:
	#var grid_position: Vector2 = item_grid.g_position
	var relative_pos: Vector2 = mousePos - grid_position
	# 四舍五入
	var half_block := Global.GridSize / 2
	var around_anchor: Vector2i = (relative_pos - xy / 2 + Vector2(half_block, half_block)) as Vector2i
	relative_pos = around_anchor / Global.GridSize * Global.GridSize
	global_position = relative_pos + xy / 2 + grid_position


func do_rotation(node = null) -> void:
	var last_anchor_point := anchor_point
	var rotate_degree: int = data.rotate()
	var tween = create_tween()
	tween.tween_property(item_control, "rotation_degrees", rotate_degree, 0.05)
	
	# 限制角度范围在[0, 360)
	tween.finished.connect(func():
		item_control.rotation_degrees = rotate_degree % 360
		# 键盘旋转，需确保旋转后以左上角点对齐
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			var target_pos: Vector2 = last_anchor_point + xy / 2
			set_pos(target_pos)
		# 旋转后，更新高亮矩形
		if node != null:
			node.update_highlight_by_held_item()
	)


func do_move(target_position: Vector2 = Vector2i(0, 0), rotate_degree: int = 0) -> void:
	# 移动动画
	target_position += xy / 2
	var move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_position, 0.05)
	
	# 旋转动画
	var rotate_tween = create_tween()
	rotate_tween.tween_property(item_control, "rotation_degrees", rotate_degree, 0.05)
	
