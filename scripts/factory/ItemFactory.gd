extends Node

## 物品ID -> 物品资源路径
@export var item_resources: Dictionary = {
	"axe": "res://resources/items/斧头武器.tres",
	"shield": "res://resources/items/盾武器.tres",
	"medicine": "res://resources/items/药水.tres",
}

# 资源缓存：已加载的物品资源，避免重复load
var _cached_resources: Dictionary = {}

# 根据item_id创建物品实例
func create_item(item_id: String) -> ItemBase:
	# 1. 检查item_id是否存在于映射表
	if not item_resources.has(item_id):
		printerr("[ItemFactory] 不存在物品ID: %s" % [item_id])
		return null
	
	# 2. 从缓存加载资源（无缓存则加载并加入缓存）
	if not _cached_resources.has(item_id):
		var res_path: String = item_resources[item_id]
		var item_res: ItemBase = load(res_path) as ItemBase
		item_res.in_backpack_attr.is_placed = false
		if not item_res:
			printerr("[ItemFactory] 加载物品资源失败: %s" % [res_path])
			return null
		_cached_resources[item_id] = item_res	# 加入缓存，后续直接复用
	
	# 3. 复制资源创建实例（Resource需用duplicate()创建独立实例，避免共享属性）
	var item_instance: ItemBase = _cached_resources[item_id].duplicate(true)
	return item_instance


## Debug使用：获取随机一件物品
func get_radom_item() -> ItemBase:
	var item_id_array = item_resources.keys()
	var random_key = item_id_array.pick_random()
	return create_item(random_key)


## 清空资源缓存（如切换场景时使用）
func clear_cache() -> void:
	_cached_resources.clear()
	print("[ItemFactory] 物品资源缓存已清空")
