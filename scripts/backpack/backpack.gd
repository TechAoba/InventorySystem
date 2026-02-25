class_name Backpack extends Panel

@onready var item_grid: ItemGrid = %ItemGrid
@export var items: Array[ItemBase] = []

const SAVE_PATH = "user://backpack_save.tres"
const backpackItemScene_: PackedScene = preload("res://scenes/backpack_item.tscn")

## 物品实例数组
var backpackItems_: Array[BackpackItem] = []
var data_: BackpackData
## 背包整理器
var packer_: BinManager = null


func _ready() -> void:
	data_ = BackpackData.new()
	# 背包格子数量
	var backpack_size: Vector2i = data_.get_backpack_size()
	item_grid.init_slot_data(backpack_size)
	load_()
	

## 保存数据
func save_() -> bool:
	data_.item_datas = self.items
	var save_status := ResourceSaver.save(data_, SAVE_PATH)
	if save_status == OK:
		print("游戏存档保存成功: ", SAVE_PATH)
	else:
		printerr("游戏存档保存失败: ", save_status)
	return save_status == OK


## 加载背包数据
func load_() -> void:
	var raw_data = ResourceLoader.load(SAVE_PATH) as BackpackData
	if not FileAccess.file_exists(SAVE_PATH):
		print("游戏存档不存在： ", SAVE_PATH)
		return
	data_ = ResourceLoader.load(SAVE_PATH).duplicate(true) as BackpackData
	if data_:
		if data_ is BackpackData:
			init_backpack_()
			print("游戏存档加载成功")
		else:
			printerr("游戏存档格式错误！")
	else:
		print("游戏存档加载失败！")


func add_item(item_data: ItemBase) -> void:
	var backpack_item = backpackItemScene_.instantiate() as BackpackItem
	backpack_item.data = item_data
	backpackItems_.append(backpack_item)
	add_child(backpack_item)
	var grid_index: int = item_grid.attempt_to_add_item_data(backpack_item)
	if grid_index < 0:
		printerr("物品放置失败！")


## 初始化背包
func init_backpack_() -> void:
	clear_()		# 清除背包数据
	items = data_.item_datas
	for item in self.items:
		add_item(item)


## 释放物品实例 & 清空背包数据 
func clear_() -> void:
	for backpack_item in backpackItems_:
		backpack_item.queue_free()
	backpackItems_.clear()
	# 清除背包格子
	item_grid.init_slot_data(Global.get_backpack_size(data_.level))
	items.clear()


## 生成物品，添加到背包中
func pickup_item_() -> void:
	var item_data: ItemBase = ItemFactory.get_radom_item()
	var backpack_item = backpackItemScene_.instantiate() as BackpackItem
	backpack_item.data = item_data
	backpackItems_.append(backpack_item)
	add_child(backpack_item)
	var grid_index: int = item_grid.attempt_to_add_item_data(backpack_item)
	if grid_index < 0:
		backpack_item.data.in_backpack_attr.rotate()
		grid_index = item_grid.attempt_to_add_item_data(backpack_item)
		if grid_index < 0:
			printerr("物品放置失败！")
			backpackItems_.pop_back()
			backpack_item.queue_free()
	if grid_index >= 0:
		items.append(item_data)
	

## 升级背包
func upgrade_() -> void:
	if data_.level >= Global.max_backpack_level - 1:
		print("背包已经满级")
		return
	
	# 1. 升级背包
	var old_dimention: Vector2i = Global.get_backpack_size(data_.level)
	data_.level += 1
	var new_dimention: Vector2i = Global.get_backpack_size(data_.level)
	
	# 2. 物品的位置不会发生变化，仅修改物品的slot_idx
	for i in items.size():
		var x: int = items[i].in_backpack_attr.slot_idx % old_dimention.x
		var y: int = items[i].in_backpack_attr.slot_idx / old_dimention.x
		var new_idx: int = y * new_dimention.x + x
		items[i].in_backpack_attr.slot_idx = new_idx
	
	# 3. 更新背包格子的dimentions
	item_grid.init_slot_data(new_dimention)
	
	# 4. 过滤掉free的物品（合并）
	#backpackItems_ = backpackItems_.filter(func(item):
		#return is_instance_valid(item)
	#)
	
	# 5. 将物品放置背包
	for backpack_item in backpackItems_:
		var grid_index: int = item_grid.attempt_to_add_item_data(backpack_item)


func remove_item(rmItem: BackpackItem) -> void:
	for i in range(backpackItems_.size() - 1, -1, -1):
		if backpackItems_[i] == rmItem:
			backpackItems_.remove_at(i)
	for i in range(items.size() - 1, -1, -1):
		if items[i] == rmItem.data:
			items.remove_at(i)


func pack_backpack_() -> void:
	# 根据背包大小判断整理器是否要重新声明
	var backpack_size: Vector2i = data_.get_backpack_size()
	if packer_ == null or packer_.bin_width != backpack_size.x or packer_.bin_height != backpack_size.y:
		packer_ = BinManager.new(backpack_size.x, backpack_size.y)
	packer_.clear()
	
	packer_.add_items(items)
	packer_.execute()
	# 没有不能放置的物品，成功整理
	if len(packer_.unplaced_items) == 0:
		items = packer_.placed_items
		item_grid.move_item_by_packer(backpackItems_)


func _input(event: InputEvent) -> void:
	# 按下 R 键触发整理背包 & 没有物品被点击拾起
	if event is InputEventKey and Input.is_action_just_pressed("pack"):
		if !Global.something_pickup:
			pack_backpack_()
	# 按下 P 键触发拾取物品
	elif event is InputEventKey and Input.is_action_just_pressed("pickup"):
		pickup_item_()
	
