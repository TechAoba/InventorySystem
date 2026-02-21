## 单箱整理器
class_name BinManager

var bin_width: int
var bin_height: int
var items: Array[ItemBase] = []
var bin
var pack_algo: String
var heuristic: String
var split_heuristic: String
var rotation: bool
var rectangle_merge: bool
var sorting: bool

var placed_items: Array[ItemBase] = []        # 成功放置的 Item
var unplaced_items: Array[ItemBase] = []      # 无法放置的 Item

func _init(
	p_bin_width: int = 10,
	p_bin_height: int = 6,
	p_pack_algo: String = "maximal_rectangle",
	p_heuristic: String = "best_area",
	p_split_heuristic: String = "default",
	p_rotation: bool = true,
	p_rectangle_merge: bool = true,
	p_sorting: bool = true,
):
	bin_width = p_bin_width
	bin_height = p_bin_height
	pack_algo = p_pack_algo
	heuristic = p_heuristic
	split_heuristic = p_split_heuristic
	rotation = p_rotation
	rectangle_merge = p_rectangle_merge
	sorting = p_sorting
	# 初始箱子
	bin = bin_factory_()

	
func add_items(items_to_add: Array[ItemBase]) -> void:
	for itm in items_to_add:
		var t_item: ItemBase = itm    # TODO: .duplicate(true)
		t_item.in_backpack_attr.rotate_degree = 0
		items.append(t_item)
	if sorting:
		items.sort_custom(ItemBase.sort_func)


func clear() -> void:
	items.clear()


func bin_factory_():
	if pack_algo == "maximal_rectangle":
		return MaximalRectanglePacker.new(bin_width, bin_height, rotation, heuristic)
	else:
		push_error("Unsupported packing algorithm: %s" % pack_algo)
		return null
		

func execute() -> void:
	placed_items.clear()
	unplaced_items.clear()
	bin.clear()
	for item in items:
		if not bin.insert(item):
			unplaced_items.append(item)
		else:
			placed_items.append(item)
