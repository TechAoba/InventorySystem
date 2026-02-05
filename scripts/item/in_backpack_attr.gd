## 描述物品在背包中的属性，如旋转角度、数量等
class_name InBackpackAttr
extends Resource

## 物品左上角所在slot index
@export var slot_idx: int
## 物品是否已放置在背包中
@export var is_placed: bool = false
## 物品的旋转角度
@export var rotate_degree: int
## 物品堆叠数量
@export var stack_count: int

func _init(stack_count_: int = 1, slot_idx_: int = 0) -> void:
	slot_idx = slot_idx_
	is_placed = false
	rotate_degree = 0
	stack_count = stack_count_

# 旋转90度，避免物体反向旋转，特殊360值返回
func rotate() -> int:
	rotate_degree = (rotate_degree + 90) % 360
	return 360 if rotate_degree == 0 else rotate_degree


func get_dimention_in_backpack(item_size: Vector2i) -> Vector2i:
	var width: int = item_size.x
	var height: int = item_size.y
	var slot_size: int = Global.GridSize
	assert(width % slot_size == 0 and height % slot_size == 0)
	width /= slot_size
	height /= slot_size
	if rotate_degree % 180 == 90:
		var temp := width
		width = height
		height = temp
	return Vector2i(width, height)
