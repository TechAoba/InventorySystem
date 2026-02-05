class_name Backpack extends PanelContainer

@onready var item_grid: ItemGrid = %ItemGrid
@export var items: Array[ItemBase] = []

const SAVE_PATH = "res://backpack_save.tres"
const backpack_item_scene: PackedScene = preload("res://scenes/backpack_item.tscn")

## 物品实例数组
var backpack_items: Array[Node] = []
var save_res: BackpackSaveData
var backpack_level: int = 1


func _ready() -> void:
	save_res = BackpackSaveData.new()
	# 通过背包等级设置格子数量
	var backpack_size: Vector2i = Global.get_backpack_size(backpack_level)
	item_grid.init_slot_data(backpack_size)
	load_()


## 保存数据
func save_() -> bool:
	save_res.grid_level = self.backpack_level
	save_res.item_datas = self.items
	var save_status := ResourceSaver.save(save_res, SAVE_PATH)
	if save_status == OK:
		print("游戏存档保存成功: ", SAVE_PATH)
	else:
		printerr("游戏存档保存失败: ", save_status)
	return save_status == OK


## 加载背包数据
func load_() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("游戏存档不存在： ", SAVE_PATH)
		return
	save_res = ResourceLoader.load(SAVE_PATH).duplicate(true) as BackpackSaveData
	if save_res:
		if save_res is BackpackSaveData:
			init_backpack_()
			print("游戏存档加载成功")
		else:
			printerr("游戏存档格式错误！")
	else:
		print("游戏存档加载失败！")



func add_item(item_data: ItemBase) -> void:
	var backpack_item = backpack_item_scene.instantiate() as BackpackItem
	backpack_item.data = item_data
	backpack_items.append(backpack_item)
	add_child(backpack_item)
	var grid_index: int = item_grid.attempt_to_add_item_data(backpack_item)
	if grid_index < 0:
		printerr("物品放置失败！")


## 初始化背包
func init_backpack_() -> void:
	clear_()		# 清除背包数据
	items = save_res.item_datas
	for item in self.items:
		add_item(item)


## 释放物品实例 & 清空背包数据 
func clear_() -> void:
	for backpack_item in backpack_items:
		backpack_item.queue_free()
	backpack_items.clear()
	# 清除背包格子
	item_grid.slot_datas.fill(null)
	items.clear()


## 生成物品，添加到背包中
func pickup_item_() -> void:
	var item_data: ItemBase = ItemFactory.get_radom_item()
	var backpack_item = backpack_item_scene.instantiate() as BackpackItem
	backpack_item.data = item_data
	backpack_items.append(backpack_item)
	add_child(backpack_item)
	var grid_index: int = item_grid.attempt_to_add_item_data(backpack_item)
	if grid_index < 0:
		printerr("物品放置失败！")
		backpack_items.pop_back()
		backpack_item.queue_free()
	else:
		items.append(item_data)

## 升级背包
#func upgrade_() -> void:
	#if 
