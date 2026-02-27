class_name ItemGrid extends GridContainer

const SLOT_SIZE: int = Global.GridSize
const Grid_Offset = Vector2(SLOT_SIZE, SLOT_SIZE) / 2
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
				get_parent().update_highlight_by_mouse()
			# 手上持有物品
			else:
				place_item(held_item, get_global_mouse_position())


## 放置物品
func place_item(item: BackpackItem, pos: Vector2) -> void:
	# 物品超过背包界限，直接返回
	var index = get_slot_index_from_coords(item.anchor_point + Grid_Offset)
	if !is_in_border(index, item.data.dimentions):
		return
	# 物品有重叠部分
	var items = items_in_area(index, item.data.dimentions)
	if items.size():
		if items.size() == 1:
			# 物品完全重合 & id相同 & 物品可堆叠
			if items.values()[0] == item.data.in_backpack_attr.area \
			and items.keys()[0].data.item_id == item.data.item_id \
			and item.data.is_stackable():
				handle_merge(index)
			# 将拾起的物品放在pos，位置上的物品替换到手上
			else:
				item.get_placed(pos, index)
				remove_item_from_slot_data(items.keys()[0])
				add_item_to_slot_data(index, item)
				items.keys()[0].get_picked_up(global_position)
		return
	# 位置可直接放置
	item.get_placed(pos, index)
	add_item_to_slot_data(index, item)


## 物品合并
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
	if !pixel_in_border(coords):
		return -1
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index >= dimentions_.x * dimentions_.y || index < 0:
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
	

## 通过鼠标的 global_position 计算背包续高亮矩形的 位置 和 尺寸
func get_highlight_box() -> Array:
	var highlight_box: Array = []
	var slot_idx: int = get_slot_index_from_coords(get_global_mouse_position())
	# 1. 未拾取物品
	if !Global.something_pickup:
		# 在空格子上
		if slotDatas_[slot_idx] == null:
			highlight_box.append(get_coords_from_slot_index(slot_idx) as Vector2 - global_position)		# 高亮矩形的左上角位置
			highlight_box.append(Vector2(Global.GridSize, Global.GridSize))								# 高亮矩形的尺寸
		# 在物品上
		else:
			highlight_box.append(slotDatas_[slot_idx].global_position \
			 - (slotDatas_[slot_idx].data.in_backpack_attr.get_size_in_backpack() as Vector2 / 2) \
			 - global_position)																			# 高亮矩形的左上角位置
			highlight_box.append(slotDatas_[slot_idx].data.in_backpack_attr.get_size_in_backpack())		# 高亮矩形的尺寸
	# 2. 已经拾取物品
	else:
		var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
		highlight_box.append(held_item.global_position \
			 - (held_item.data.in_backpack_attr.get_size_in_backpack() as Vector2 / 2) \
			 - global_position)																			# 高亮矩形的左上角位置
		highlight_box.append(held_item.data.in_backpack_attr.get_size_in_backpack())					# 高亮矩形的尺寸
		
	return highlight_box


## 根据当前高亮矩形的位置和尺寸信息 + 方向键 获取新矩形的位置和尺寸
func get_highlight_box_by_keyboard(currentPos: Vector2, currentSize: Vector2, direction: Vector2i) -> Array:
	var highlight_box: Array = []
	# 当前高亮矩形的上下左右边缘
	var top_edge: int = currentPos.y as int
	var bottom_edge: int = currentPos.y + currentSize.y as int
	var left_edge: int = currentPos.x as int
	var right_edge: int = currentPos.x + currentSize.x as int
	
	var next_pos: Vector2
	# 1. 未拾取物品
	if !Global.something_pickup:
		# 在单格子上，简单移动
		if currentSize.x == Global.GridSize and currentSize.y == Global.GridSize:
			next_pos = currentPos + Vector2(direction.x * Global.GridSize, direction.y * Global.GridSize)
		# 在多格子上，确认中心点移动
		else:
			if direction.y == -1:	# up
				next_pos = Vector2((left_edge + right_edge) / 2, top_edge - Global.GridSize / 2)
			elif direction.x == 1:	# right
				next_pos = Vector2(right_edge + Global.GridSize / 2, (top_edge + bottom_edge) / 2)
			elif direction.y == 1:	# down
				next_pos = Vector2((left_edge + right_edge) / 2, bottom_edge + Global.GridSize / 2)
			elif direction.x == -1:	# left
				next_pos = Vector2(left_edge - Global.GridSize / 2, (top_edge + bottom_edge) / 2)
		
		var next_slot_idx: int = get_slot_index_from_coords(next_pos + Grid_Offset)
		# 超过背包边界 返回当前pos和size
		if next_slot_idx < 0:
			return [currentPos, currentSize]
		# 下一个位置为空格子
		if slotDatas_[next_slot_idx] == null:
			highlight_box.append(get_coords_from_slot_index(next_slot_idx) as Vector2 - global_position)		# 高亮矩形的左上角位置
			highlight_box.append(Vector2(Global.GridSize, Global.GridSize))										# 高亮矩形的尺寸
		# 在物品上
		else:
			highlight_box.append(slotDatas_[next_slot_idx].global_position \
			 - (slotDatas_[next_slot_idx].data.in_backpack_attr.get_size_in_backpack() as Vector2 / 2) \
			 - global_position)																					# 高亮矩形的左上角位置
			highlight_box.append(slotDatas_[next_slot_idx].data.in_backpack_attr.get_size_in_backpack())		# 高亮矩形的尺寸
	# 2. 已经拾取物品
	else:
		var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
		var move_offset := Vector2(direction.x * Global.GridSize, direction.y * Global.GridSize)
		next_pos = currentPos + move_offset
		var points := [
			Vector2(next_pos),
			Vector2(next_pos.x + currentSize.x, next_pos.y),
			Vector2(next_pos.x + currentSize.x, next_pos.y + currentSize.y),
			Vector2(next_pos.x, next_pos.y + currentSize.y),
		]
		for point in points:
			if !pixel_in_border(point):
				return [currentPos, currentSize]
		# 高亮矩形的下一个位置
		highlight_box.append(next_pos)
		highlight_box.append(currentSize)
		# 设置物品的位置
		held_item.set_pos(next_pos + self.global_position + held_item.color_rect.size / 2.0)
		
	return highlight_box
	

# 按下 回车 -> 拾起/放置物品
func confirm_item(currentPos: Vector2, currentSize: Vector2) -> void:
	# 1. 未持有物品，拾起
	if !Global.something_pickup:
		var slot_idx: int = get_slot_index_from_coords(currentPos + global_position)
		# 非空格子
		if slotDatas_[slot_idx] != null:
			slotDatas_[slot_idx].get_picked_up(global_position)
			remove_item_from_slot_data(slotDatas_[slot_idx])
	# 2. 持有物品，放置
	else:
		var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
		place_item(held_item, held_item.global_position)
		# 可能有替换拾起物品的情况，更新高亮矩形
		get_parent().update_highlight_by_held_item()


func pixel_in_border(pos: Vector2) -> bool:
	if pos.x < 0 || pos.x > dimentions_.x * Global.GridSize \
	|| pos.y < 0 || pos.y > dimentions_.y * Global.GridSize:
		return false
	return true
