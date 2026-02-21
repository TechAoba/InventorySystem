class_name BackpackData
extends Resource

# 背包等级
@export var level: int = 0
# ItemData数组（存储所有背包中的物品数据）
@export var item_datas: Array[ItemBase] = []


func get_backpack_size() -> Vector2i:
	return Global.get_backpack_size(level)
