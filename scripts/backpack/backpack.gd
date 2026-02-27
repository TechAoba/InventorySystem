class_name Backpack extends Panel

@onready var item_grid: ItemGrid = %ItemGrid
@onready var highlight_box: ColorRect = %HighlightBox
@export var items: Array[ItemBase] = []

const SAVE_PATH = "user://backpack_save.tres"
const backpackItemScene_: PackedScene = preload("res://scenes/backpack_item.tscn")

## 物品实例数组
var backpackItems_: Array[BackpackItem] = []
var data_: BackpackData
## 背包整理器
var packer_: BinManager = null

## 选择物品高亮 相关配置
const SelectRectColor := Color(1, 1, 1, 0.3)
var highlight_pos_ := Vector2(0, 0)
var highlight_size_ := Vector2(0, 0)


func _ready() -> void:
	data_ = BackpackData.new()
	# 背包格子数量
	var backpack_size: Vector2i = data_.get_backpack_size()
	item_grid.init_slot_data(backpack_size)
	load_()
	# 物品高亮
	highlight_box.color = SelectRectColor
	highlight_box.z_index = 20
	set_highlight_box()		# 设置为初始值


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
	
	# 4. 将物品放置背包
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


func set_highlight_box(pos: Vector2 = highlight_pos_, size: Vector2 = highlight_size_) -> void:
	highlight_box.position = pos
	highlight_box.size = size


## 获取 方向键 触发的方向
func get_keyboard_direction_() -> Vector2i:
	if Input.is_action_just_pressed("left"):
		return Vector2i(-1, 0)
	elif Input.is_action_just_pressed("up"):
		return Vector2i(0, -1)
	elif Input.is_action_just_pressed("right"):
		return Vector2i(1, 0)
	elif Input.is_action_just_pressed("down"):
		return Vector2i(0, 1)
	return Vector2i(0, 0)


func _input(event: InputEvent) -> void:
	# --- 键盘事件 ---
	if event is InputEventKey:
		if event is InputEventKey and Input.is_action_just_pressed("tab"):
			if Global.something_pickup:
				var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
				held_item.do_rotation(self)
		# 按下 R 键触发整理背包 & 没有物品被点击拾起
		if Input.is_action_just_pressed("pack"):
			if !Global.something_pickup:
				pack_backpack_()
		# 按下 P 键触发拾取物品
		elif Input.is_action_just_pressed("pickup"):
			pickup_item_()
		elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("up") \
		or Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down"):
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			var direction: Vector2i = get_keyboard_direction_()
			var highlight_pos_size := item_grid.get_highlight_box_by_keyboard(highlight_pos_, highlight_size_, direction)
			highlight_pos_ = highlight_pos_size[0]
			highlight_size_ = highlight_pos_size[1]
			set_highlight_box()
		# 确认键，拾起/放置物品
		elif Input.is_action_just_pressed("confirm"):
			item_grid.confirm_item(highlight_pos_, highlight_size_)
	# --- 鼠标移动事件 ---
	elif event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_highlight_by_mouse()
		

func update_highlight_by_mouse() -> void:
	var highlight_pos_size := item_grid.get_highlight_box_by_pos(get_global_mouse_position())
	highlight_pos_ = highlight_pos_size[0]
	highlight_size_ = highlight_pos_size[1]
	set_highlight_box()


func update_highlight_by_held_item() -> void:
	if Global.something_pickup:
		var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
		highlight_pos_ = held_item.global_position - held_item.xy / 2.0 - item_grid.global_position
		highlight_size_ = held_item.xy
		set_highlight_box()


func update_highlight_by_self_pos() -> void:
	var pos: Vector2 = highlight_pos_ + Vector2(Global.GridSize / 2, Global.GridSize / 2)
	var highlight_pos_size := item_grid.get_highlight_box_by_pos(pos)
	highlight_pos_ = highlight_pos_size[0]
	highlight_size_ = highlight_pos_size[1]
	set_highlight_box()
