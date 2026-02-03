class_name ItemGrid extends GridContainer

const SLOT_SIZE: int = GlobalVariable.GridSize
#@export var inventory_slot_scene: PackedScene
@onready var inventory_slot_scene: PackedScene = load(&"res://scenes/inventory_slot.tscn");
@export var dimentions: Vector2i = Vector2i(5, 8)
var slot_data: Array[Node] = []

func _ready() -> void:
	create_slots()
	init_slot_data()

func create_slots() -> void:
	self.columns = dimentions.x
	for y in dimentions.y:
		for x in dimentions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			add_child(inventory_slot)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var held_item: InventoryItem = get_tree().get_first_node_in_group("held_item")
			# 当前鼠标未持有物体，检查点击位置物体，若存在则pickup，并在背包的格子中删除物体
			if !held_item:
				var slot_index = get_slot_index_from_coords(get_global_mouse_position())
				var item: InventoryItem = slot_data[slot_index]
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
						held_item.get_placed(get_global_mouse_position())
						remove_item_from_slot_data(items[0])
						add_item_to_slot_data(index, held_item)
						items[0].get_picked_up(global_position)
					return
				held_item.get_placed(get_global_mouse_position())
				add_item_to_slot_data(index, held_item)


func remove_item_from_slot_data(item: Node) -> void:
	for i in slot_data.size():
		if slot_data[i] == item:
			slot_data[i] = null

func add_item_to_slot_data(index: int, item: Node) -> void:
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_data[index + x + y * columns] = item

func items_in_area(index: int, item_dimentions: Vector2i) -> Array:
	var items: Dictionary = {}
	for y in item_dimentions.y:
		for x in item_dimentions.x:
			var slot_index = index + x + y * columns
			var item = slot_data[slot_index]
			if !item:
				continue
			if !items.has(item):
				items[item] = true
	return items.keys() if items.size() else []

func init_slot_data() -> void:
	slot_data.resize(dimentions.x * dimentions.y)
	slot_data.fill(null)
	

func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimentions.x * dimentions.y || index < 0:
		return -1
	return index


func get_coords_from_slot_index(index: int) -> Vector2i:
	var row = index / columns
	var column = index % columns
	return Vector2i(global_position) + Vector2i(column * SLOT_SIZE, row * SLOT_SIZE)


func attempt_to_add_item_data(item: Node) -> bool:
	var slot_index: int = 0
	while slot_index < slot_data.size():
		if item_fits(slot_index, item.data.dimentions):
			break
		slot_index += 1
	if slot_index >= slot_data.size():
		return false
		
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_data[slot_index + x + y * columns] = item
	
	item.set_init_position(get_coords_from_slot_index(slot_index))
	return true

## 检查物品能否放置在特定位置 [br]
## index: 物品左上角的编号。rect： 物品的尺寸 Vector2i
func item_fits(index: int, rect: Vector2i) -> bool:
	if !is_in_border(index, rect):
		return false
	for y in rect.y:
		for x in rect.x:
			var curr_index = index + x + y * columns
			if slot_data[curr_index] != null:
				return false
	return true

## 检查物品是否超过背包边界 [br]
## index： 物品左上角编号。rect： 物品尺寸 Vector2i
func is_in_border(index: int, rect: Vector2i) -> bool:
	var start_x = index % columns
	var start_y = index / columns
	if start_x + rect.x > dimentions.x or start_y + rect.y > dimentions.y:
		return false
	return true
