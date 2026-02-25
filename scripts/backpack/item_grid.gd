class_name ItemGrid extends GridContainer

const SLOT_SIZE: int = Global.GridSize
const backpackSlotScene_: PackedScene = preload("res://scenes/backpack_slot.tscn")

var dimentions_: Vector2i = Vector2i(10, 6)
var slotDatas_: Array[BackpackItem] = []

func _ready() -> void:
	#init_slot_data()
	pass

func init_slot_data(dim: Vector2i = dimentions_) -> void:
	self.dimentions_ = dim
	slotDatas_.resize(dim.x * dim.y)
	reset_slots_()
	slotDatas_.fill(null)

## 设置格子尺寸
func reset_slots_() -> void:
	self.columns = dimentions_.x
	# 1. 清除背包中所有格子（背包列数发生改变，格子index到行列的映射关系发生变化）
	for child in get_children():
		if child is BackpackSlot:
			child.queue_free()
	# 2. 创建背包格子对象
	for y in dimentions_.y:
		for x in dimentions_.x:
			var backpackSlot_ = backpackSlotScene_.instantiate() as BackpackSlot
			backpackSlot_.row = y
			backpackSlot_.column = x
			add_child(backpackSlot_)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
			# 当前鼠标未持有物体，检查点击位置物体，若存在则pickup，并在背包的格子中删除物体
			if !held_item:
				var slot_index = get_slot_index_from_coords(get_global_mouse_position())
				var item: BackpackItem = slotDatas_[slot_index]
				if !item:
					return
				item.get_picked_up(global_position)
				remove_item_from_slot_data(item)
			# 手上持有物品
			else:
				# 物品超过背包界限，直接返回
				var offset = Vector2(SLOT_SIZE, SLOT_SIZE) / 2
				var index = get_slot_index_from_coords(held_item.anchor_point + offset)
				if !is_in_border(index, held_item.data.dimentions):
					return
				# 物品有重叠部分
				var items = items_in_area(index, held_item.data.dimentions)
				if items.size():
					if items.size() == 1:
						# 物品完全重合 & id相同 & 物品可堆叠
						#print(items.values()[0] == held_item.data.in_backpack_attr.area)
						#print(items.keys()[0].data.item_id == held_item.data.item_id)
						#print(held_item.data.is_stackable())
						if items.values()[0] == held_item.data.in_backpack_attr.area \
						and items.keys()[0].data.item_id == held_item.data.item_id \
						and held_item.data.is_stackable():
							handle_merge(index)
						else:
							held_item.get_placed(get_global_mouse_position(), index)
							remove_item_from_slot_data(items.keys()[0])
							add_item_to_slot_data(index, held_item)
							items.keys()[0].get_picked_up(global_position)
					return
				# 位置可直接放置
				held_item.get_placed(get_global_mouse_position(), index)
				add_item_to_slot_data(index, held_item)


func handle_merge(slot_idx: int) -> void:
	var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
	var item: BackpackItem = slotDatas_[slot_idx]
	# 1. 如果物品可完全叠加到一起
	if held_item.data.in_backpack_attr.stack_count \
		+ item.data.in_backpack_attr.stack_count \
		<= item.data.in_backpack_attr.max_stack_count:
			item.data.in_backpack_attr.stack_count += held_item.data.in_backpack_attr.stack_count
			Global.something_pickup = false
			get_parent().remove_item(held_item)
			held_item.queue_free()
	# 2. 可叠加到上限，手上还剩部分物品
	else:
		held_item.data.in_backpack_attr.stack_count -= \
		held_item.data.in_backpack_attr.max_stack_count - \
		item.data.in_backpack_attr.stack_count
		item.data.in_backpack_attr.stack_count = held_item.data.in_backpack_attr.max_stack_count


func remove_item_from_slot_data(item: Node) -> void:
	for i in slotDatas_.size():
		if slotDatas_[i] == item:
			slotDatas_[i] = null

func add_item_to_slot_data(index: int, item: BackpackItem) -> void:
	#print("add to: ", index)
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slotDatas_[index + x + y * columns] = item
	item.data.in_backpack_attr.slot_idx = index

func items_in_area(index: int, item_dimentions: Vector2i) -> Dictionary:
	var items: Dictionary = {}
	for y in item_dimentions.y:
		for x in item_dimentions.x:
			var slot_index = index + x + y * columns
			var item = slotDatas_[slot_index]
			if !item:
				continue
			if !items.has(item):
				items[item] = 1
			else:
				items[item] += 1
	return items


func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	if coords.x < 0 || coords.y < 0:
		return -1
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimentions_.x * dimentions_.y || index < 0:
		return -1
	return index


func get_coords_from_slot_index(index: int) -> Vector2i:
	var row: int = index / columns
	var column: int = index % columns
	return Vector2i(global_position) + Vector2i(column * SLOT_SIZE, row * SLOT_SIZE)


## 尝试将物品放入背包，分为两种情况 [br]
## 1. 物品已经在背包中（读取/扩展背包）。此时直接将物品放在对应位置 [br]
## 2. 物品为新物品（is_placed==false）。for遍历合适的位置，返回放入格子的index中，如不能放入则返回-1
func attempt_to_add_item_data(item: BackpackItem) -> int:
	var slot_index: int = -1
	# 1. 在背包中
	if item.data.in_backpack_attr.is_placed:
		assert(item_fits(item.data.in_backpack_attr.slot_idx, item.data.dimentions))
		slot_index = item.data.in_backpack_attr.slot_idx
	# 2. 不在背包中
	else:
		# 首先尝试不旋转物品
		while slot_index < slotDatas_.size():
			if item_fits(slot_index, item.data.dimentions):
				break
			slot_index += 1
	if slot_index >= slotDatas_.size():
		slot_index = -1
	# 当存在格子放置物品时，真正放置物品
	if slot_index >= 0:
		add_item_to_slot_data(slot_index, item)
		item.data.in_backpack_attr.is_placed = true
		item.data.in_backpack_attr.slot_idx = slot_index
		item.set_init_position(get_coords_from_slot_index(slot_index))
		#var target_position: Vector2 = get_coords_from_slot_index(slot_index)
		#item.do_move(target_position, item.data.in_backpack_attr.rotate_degree)
	return slot_index


## 检查物品能否放置在特定位置 [br]
## index: 物品左上角的编号。rect： 物品的尺寸 Vector2i
func item_fits(index: int, rect: Vector2i, do_rotation: bool = false) -> bool:
	if !is_in_border(index, rect):
		return false
	for y in rect.y:
		for x in rect.x:
			var curr_index = index + x + y * columns
			if slotDatas_[curr_index] != null:
				return false
	return true


## 检查物品是否超过背包边界 [br]
## index： 物品左上角编号。rect： 物品尺寸 Vector2i
func is_in_border(index: int, rect: Vector2i) -> bool:
	if index < 0:
		return false
	var start_x = index % columns
	var start_y = index / columns
	if start_x + rect.x > dimentions_.x or start_y + rect.y > dimentions_.y:
		return false
	return true


## 一键整理背包后，根据物品的坐标。移动物品到正确的位置
func move_item_by_packer(items: Array[BackpackItem]) -> void:
	# 1. 清理 slot 上的 item 引用
	for i in slotDatas_.size():
		slotDatas_[i] = null
	for item in items:
		# 2. 物品根据新放置在 slot 中
		var slot_idx: int = columns * item.data.in_backpack_attr.y + item.data.in_backpack_attr.x
		add_item_to_slot_data(slot_idx, item)
		# 3. 计算物品的绝对位置并移动到对应位置
		var target_position: Vector2 = get_coords_from_slot_index(slot_idx)
		item.do_move(target_position, item.data.in_backpack_attr.rotate_degree)
	
