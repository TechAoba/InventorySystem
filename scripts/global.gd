extends Node

@onready var item_grid: ItemGrid = %ItemGrid

# 背包格子像素
const GridSize: int = 32
# 背包格子解锁上限
const max_backpack_level: int = 4
# 每一等级背包格子数量
const backpack_level_size: Array[Vector2i] = [
	Vector2i(10, 6),
	Vector2i(11, 7),
	Vector2i(12, 8),
	Vector2i(15, 8),
]
# 背包每一级价格
const backpack_upgrade_price: Array[int] = [0, 24000, 40000, 73000]
# 最大堆叠数 TODO 最大堆叠数和具体物品绑定
const max_item_stack: int = 50


## 通过背包等级获取背包的尺寸
func get_backpack_size(level: int) -> Vector2i:
	assert(level >= 0 and level < max_backpack_level)
	return backpack_level_size[level]
