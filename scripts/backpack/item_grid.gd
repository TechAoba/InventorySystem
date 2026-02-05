class_name ItemGrid extends GridContainer

const SLOT_SIZE: int = Global.GridSize
const backpack_slot_scene: PackedScene = preload("res://scenes/backpack_slot.tscn")
var dimentions: Vector2i = Vector2i(10, 6)
var slot_datas: Array[BackpackItem] = []

func _ready() -> void:
	#init_slot_data()
	pass

func init_slot_data(dim: Vector2i = dimentions) -> void:
	self.dimentions = dim
	slot_datas.resize(dim.x * dim.y)
	reset_slots_()
	slot_datas.fill(null)

## 设置格子尺寸
func reset_slots_() -> void:
	self.columns = dimentions.x
	# 1. 清除背包中所有格子（背包列数发生改变，格子index到行列的映射关系发生变化）
	for child in get_children():
		if child is BackpackSlot:
			child.queue_free()
	# 2. 创建背包格子对象
	for y in dimentions.y:
		for x in dimentions.x:
			var backpack_slot = backpack_slot_scene.instantiate() as BackpackSlot
			backpack_slot.row = y
			backpack_slot.column = x
			add_child(backpack_slot)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var held_item: BackpackItem = get_tree().get_first_node_in_group("held_item")
			# 当前鼠标未持有物体，检查点击位置物体，若存在则pickup，并在背包的格子中删除物体
			if !held_item:
				var slot_index = get_slot_index_from_coords(get_global_mouse_position())
				var item: BackpackItem = slot_datas[slot_index]
				if !item:
					return
				item.get_picked_up(global_position)
				remove_item_from_slot_data(item)
			# 放置物体，放置位置无物体时直接放置；存在一个物体时则替出该物体
			else:
				var offset = Vector2(SLOT_SIZE, SLOT_SIZE) / 2
				var index = get_slot_index_from_coords(held_item.anchor_point + offset)
				if !is_in_border(index, held_item.data.dimentions):
					return
				var items = items_in_area(index, held_item.data.dimentions)
				if items.size():
					if items.size() == 1:
						held_item.get_placed(get_global_mouse_position(), index)
						remove_item_from_slot_data(items[0])
						add_item_to_slot_data(index, held_item)
						items[0].get_picked_up(global_position)
					return
				held_item.get_placed(get_global_mouse_position(), index)
				add_item_to_slot_data(index, held_item)


func remove_item_from_slot_data(item: Node) -> void:
	for i in slot_datas.size():
		if slot_datas[i] == item:
			slot_datas[i] = null

func add_item_to_slot_data(index: int, item: Node) -> void:
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_datas[index + x + y * columns] = item

func items_in_area(index: int, item_dimentions: Vector2i) -> Array:
	var items: Dictionary = {}
	for y in item_dimentions.y:
		for x in item_dimentions.x:
			var slot_index = index + x + y * columns
			var item = slot_datas[slot_index]
			if !item:
				continue
			if !items.has(item):
				items[item] = true
	return items.keys() if items.size() else []


func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	if coords.x < 0 || coords.y < 0:
		return -1
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimentions.x * dimentions.y || index < 0:
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
		while slot_index < slot_datas.size():
			if item_fits(slot_index, item.data.dimentions):
				break
			slot_index += 1
		if slot_index >= slot_datas.size():
			slot_index = -1
	# 当存在格子放置物品时，真正放置物品
	if slot_index >= 0:
		for y in item.data.dimentions.y:
			for x in item.data.dimentions.x:
				slot_datas[slot_index + x + y * columns] = item
		item.data.in_backpack_attr.is_placed = true
		item.data.in_backpack_attr.slot_idx = slot_index
		item.set_init_position(get_coords_from_slot_index(slot_index))
	return slot_index


## 检查物品能否放置在特定位置 [br]
## index: 物品左上角的编号。rect： 物品的尺寸 Vector2i
func item_fits(index: int, rect: Vector2i) -> bool:
	if !is_in_border(index, rect):
		return false
	for y in rect.y:
		for x in rect.x:
			var curr_index = index + x + y * columns
			if slot_datas[curr_index] != null:
				return false
	return true


## 检查物品是否超过背包边界 [br]
## index： 物品左上角编号。rect： 物品尺寸 Vector2i
func is_in_border(index: int, rect: Vector2i) -> bool:
	if index < 0:
		return false
	var start_x = index % columns
	var start_y = index / columns
	if start_x + rect.x > dimentions.x or start_y + rect.y > dimentions.y:
		return false
	return true
