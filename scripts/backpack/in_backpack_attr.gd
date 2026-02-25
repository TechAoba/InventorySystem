## 描述物品在背包中的属性，如旋转角度、数量等
class_name InBackpackAttr
extends Resource

## 物品在箱子中左上角所在坐标
@export var x: int
@export var y: int
@export var slot_idx: int
## 物品的尺寸
@export var ori_width_pixel: int
@export var ori_height_pixel: int
## 物品是否已放置在背包中
@export var is_placed: bool = false
## 物品的旋转角度
@export var rotate_degree: int
## 最大叠加数量
@export var max_stack_count: int = 1
## 物品堆叠数量
@export var stack_count: int = 1

func _init(p_width_pixel: int = 0, p_height_pixel: int = 0,  
		   p_x: int = 0, p_y: int = 0, p_stack_count: int = 1) -> void:
	self.ori_width_pixel = p_width_pixel
	self.ori_height_pixel = p_height_pixel
	self.x = p_x
	self.y = p_y
	self.is_placed = false
	self.rotate_degree = 0
	#self.stack_count = p_stack_count


# 旋转90度，避免物体反向旋转，特殊360值返回
func rotate() -> int:
	rotate_degree = (rotate_degree + 90) % 360
	return 360 if rotate_degree == 0 else rotate_degree


## 反向旋转
func reverse_rotate() -> int:
	rotate_degree = (rotate_degree + 270) % 360
	return rotate_degree


func set_idx(p_idx: int) -> void:
	self.idx = p_idx


func get_dimention_in_backpack() -> Vector2i:
	var slot_size: int = Global.GridSize
	assert(ori_width_pixel % slot_size == 0 and ori_height_pixel % slot_size == 0)
	var width_pixel := ori_width_pixel
	var height_pixel := ori_height_pixel
	width_pixel /= slot_size
	height_pixel /= slot_size
	if rotate_degree % 180 == 90:
		var temp := width_pixel
		width_pixel = height_pixel
		height_pixel = temp
	return Vector2i(width_pixel, height_pixel)


## 返回矩形左下角和右上角点坐标
func get_bounds() -> Rect2i:
	return Rect2i(x, y, width, height)


var width: int:
	get():
		var slot_size: int = Global.GridSize
		var width_pixel := ori_width_pixel
		var height_pixel := ori_height_pixel
		width_pixel /= slot_size
		height_pixel /= slot_size
		if rotate_degree % 180 == 90:
			return height_pixel
		else:
			return width_pixel


var height: int:
	get():
		var slot_size: int = Global.GridSize
		var width_pixel := ori_width_pixel
		var height_pixel := ori_height_pixel
		width_pixel /= slot_size
		height_pixel /= slot_size
		if rotate_degree % 180 == 90:
			return width_pixel
		else:
			return height_pixel


## count of slots
var area: int:
	get():
		var area: int = ori_width_pixel * ori_height_pixel
		return area / (Global.GridSize * Global.GridSize)
