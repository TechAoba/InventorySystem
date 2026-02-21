class_name BinManagerMutiple

var bin_width: int
var bin_height: int
var items: Array = []
## 多箱模型，当物品无法在当前所有箱子中放置，则创建新箱子
var bins: Array = []
var bin_algo: String
var pack_algo: String
var heuristic: String
var split_heuristic: String
var rotation: bool
var rectangle_merge: bool
var sorting: bool
var sorting_heuristic: String

var bin_select_func_: Callable


func _init(
	p_bin_width: int = 10,
	p_bin_height: int = 6,
	p_bin_algo: String = "bin_best_fit",
	p_pack_algo: String = "maximal_rectangle",
	p_heuristic: String = "best_area",
	p_split_heuristic: String = "default",
	p_rotation: bool = true,
	p_rectangle_merge: bool = true,
	p_wastemap: bool = true,
	p_sorting: bool = true,
	p_sorting_heuristic: String = "DESCA"
):
	bin_width = p_bin_width
	bin_height = p_bin_height
	bin_algo = p_bin_algo
	pack_algo = p_pack_algo
	heuristic = p_heuristic
	split_heuristic = p_split_heuristic
	rotation = p_rotation
	rectangle_merge = p_rectangle_merge
	sorting = p_sorting
	sorting_heuristic = p_sorting_heuristic
	
	match bin_algo:
		"bin_first_fit": bin_select_func_ = bin_first_fit_
		"bin_best_fit": bin_select_func_ = bin_best_fit_
		_: push_error("Unknown bin selection algorithm: %s" % bin_algo); return
		
	var default_bin = bin_factory_()
	bins.append(default_bin)

	
func add_items(items_to_add: Array[ItemBase]) -> void:
	for itm in items_to_add:
		items.append(itm)
	if sorting:
		items_sort_()


func items_sort_():
	var key_func: Callable
	
	match sorting_heuristic:
		"ASCA": 		key_func = func(i): return i.width * i.height		# 面积从小到大
		"DESCA":		key_func = func(i): return -(i.width * i.height)	# 面积从大到小
		"ASCSS":		key_func = func(i): return min(i.width, i.height)	# 根据最短边长度从小到大
		"DESCSS":		key_func = func(i): return -min(i.width, i.height)	# 根据最短边长度从大到小
		"ASCLS":		key_func = func(i): return max(i.width, i.height)	# 根据最长边长度从小到大
		"DESCLS": 		key_func = func(i): return -max(i.width, i.height)	# 根据最长边长度从大到小
		"ASCPERIM":   	key_func = func(i): return (i.width + i.height)		# 根据周长从小到大
		"DESCPERIM":  	key_func = func(i): return (i.width + i.height)		# 根据周长从大到小
		"ASCDIFF":    	key_func = func(i): return abs(i.width - i.height)	# 根据边长差值从小到大
		"DESCDIFF":   	key_func = func(i): return -abs(i.width - i.height)	# 根据边长差值从大到小
		"ASCRATIO":   	key_func = func(i): return float(i.width) / i.height if i.height > 0 else INF
		"DESCRATIO":  	key_func = func(i): return -float(i.width) / i.height if i.height > 0 else -INF
		_: 
			key_func = func(i): return -(i.width * i.height)  # default DESCA 面积从大到小

	# 自定义排序
	items.sort_custom(func(a, b): return key_func.call(a) < key_func.call(b))


func bin_factory_():
	if pack_algo == "maximal_rectangle":
		return MaximalRectanglePacker.new(bin_width, bin_height, rotation, heuristic)
	else:
		push_error("Unsupported packing algorithm: %s" % pack_algo)
		return null
		

func bin_first_fit_(item: ItemBase) -> void:
	for binn in bins:
		if binn.insert(item):
			return
	# 若未放入，新建bin
	var new_bin = bin_factory_()
	new_bin.insert(item)
	bins.append(new_bin)
	
	
func bin_best_fit_(item: ItemBase) -> bool:
	# 检查 item 是否理论上能放入单个bin
	var fits_normally = (item.in_backpack_attr.width <= bin_width and item.in_backpack_attr.height <= bin_height)
	var fits_rotated = rotation and (item.in_backpack_attr.height <= bin_width and item.in_backpack_attr.width <= bin_height)
	if not (fits_normally or fits_normally):
		push_error("Item too large for bin: %dx%d vs %dx%d" % [item.in_backpack_attr.width, item.in_backpack_attr.height, bin_width, bin_height])
		return false
	
	var candidates: Array = []	# [score, bin]
	
	for binn in bins:
		var result = binn.find_best_score_(item)
		var score = result[0]
		if score != null:
			candidates.append([score, binn])
	
	if not candidates.is_empty():
		candidates.sort_custom(func(a, b): return a[0] < b[0])
		var best_bin = candidates[0][1]
		return best_bin.insert(item)
	
	# 否则新建bin
	var new_bin = bin_factory_()
	new_bin.insert(item)
	bins.append(new_bin)
	return true
	

func execute() -> void:
	for item in items:
		bin_select_func_.call(item)
		
