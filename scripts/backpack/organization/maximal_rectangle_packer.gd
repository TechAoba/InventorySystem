class_name MaximalRectanglePacker

const Heuristics = preload("res://scripts/backpack/organization/heuristics.gd")

var bin_width: int
var bin_height: int
var free_area: int
var rotation: bool = true
## 物品数组
var items: Array[ItemBase] = []
## 空闲矩形数组
var free_rects: Array[FreeRectangle] = []

var score_func_: Callable

func _init(width: int, height: int, rotation: bool = false, heuristic: String = "best_shortside"):
	self.bin_width = width
	self.bin_height = height
	self.free_area = width * height
	self.rotation = rotation
	#print("bin_width: ", bin_width)
	#print("bin_height: ", bin_height)
	#print("algo: ", heuristic)
	match heuristic:
		"best_area": 		score_func_ = Heuristics.scoreBAF
		"best_shortside":  	score_func_ = Heuristics.scoreBSSF
		"best_longside":   	score_func_ = Heuristics.scoreBLSF
		"worst_area":      	score_func_ = Heuristics.scoreWAF
		"worst_shortside": 	score_func_ = Heuristics.scoreWSSF
		"worst_longside":  	score_func_ = Heuristics.scoreWLSF
		"bottom_left":     	score_func_ = Heuristics.scoreBL
		"contact_point":   	score_func_ = Heuristics.scoreCP
		_: push_error("Unknown heuristic: %s" % heuristic); return
		
	clear()


func clear() -> void:
	items.clear()
	free_rects.clear()
	# 整个背包作为空闲矩形
	if bin_width > 0 and bin_height > 0:
		free_rects.append(FreeRectangle.new(bin_width, bin_height, 0, 0))


## 判断物品能否放入空闲块
func item_fits_rect_(item: ItemBase, rect: FreeRectangle, do_rotation: bool = false) -> bool:
	if not do_rotation:
		return item.in_backpack_attr.width <= rect.width and item.in_backpack_attr.height <= rect.height
	else:
		return item.in_backpack_attr.height <= rect.width and item.in_backpack_attr.width <= rect.height
	
	
## 在FreeRect左下角放入item，将split出两个有相交区域的矩形
func split_rectangle_(rect: FreeRectangle, item: ItemBase) -> Array:
	var results: Array = []
	# 如果item宽度比FreeRect小，分出一个右边矩形
	if item.in_backpack_attr.width < rect.width:
		results.append(FreeRectangle.new(
			rect.width - item.in_backpack_attr.width,
			rect.height,
			rect.x + item.in_backpack_attr.width,
			rect.y
		))
	# 如果item高度比FreeRect小，分出一个上边矩形
	if item.in_backpack_attr.height < rect.height:
		results.append(FreeRectangle.new(
			rect.width,
			rect.height - item.in_backpack_attr.height,
			rect.x,
			rect.y + item.in_backpack_attr.height
		))
	return results
	

## 判断两个矩形是否有相交区域
func check_intersection_(free_rect: FreeRectangle, bounds: Rect2i) -> bool:
	var r = free_rect.rect()
	return r.intersects(bounds)


## 获取两个矩形的相交矩形
func find_overlap_(free_rect: FreeRectangle, bounds: Rect2i) -> Rect2i:
	var r = free_rect.rect()
	return r.intersection(bounds)
	
	
func clip_overlap_(rect: FreeRectangle, overlap: Rect2i) -> Array:
	var results := []
	var r: Rect2i = rect.rect()
	
	# 检查非相交的部分
	# Left Side
	if overlap.position.x > r.position.x:
		results.append(FreeRectangle.new(
			overlap.position.x - r.position.x,
			r.size.y,
			r.position.x,
			r.position.y
		))
	# Right side
	if overlap.end.x < r.end.x:
		results.append(FreeRectangle.new(
			r.end.x - overlap.end.x,
			r.size.y,
			overlap.end.x,
			r.position.y
		))
	# Bottom
	if overlap.position.y > r.position.y:
		results.append(FreeRectangle.new(
			r.size.x,
			overlap.position.y - r.position.y,
			r.position.x,
			r.position.y
		))
	# Top
	if overlap.end.y < r.end.y:
		results.append(FreeRectangle.new(
			r.size.x,
			r.end.y - overlap.end.y,
			r.position.x,
			overlap.end.y
		))
	return results
	

## 两两判断空闲矩阵是否完全包含，如果是则删掉被包含的矩形 O(n^2)
func remove_redundant_() -> void:
	var i := 0
	while i < free_rects.size():
		var j := i + 1
		var removed := false
		while j < free_rects.size():
			if free_rects[j].contains(free_rects[i]):
				free_rects.remove_at(i)
				removed = true
				break
			elif free_rects[i].contains(free_rects[j]):
				free_rects.remove_at(j)
				j -= 1
			j += 1
		if not removed:
			i += 1
			

## 合并空闲块
func prune_overlaps(item_bounds: Rect2i) -> void:
	var new_free_rects: Array[FreeRectangle] = []
	for rect in free_rects:
		if check_intersection_(rect, item_bounds):
			var overlap: Rect2i = find_overlap_(rect, item_bounds)
			var clipped: Array = clip_overlap_(rect, overlap)
			new_free_rects.append_array(clipped)
		else:
			new_free_rects.append(rect)
	free_rects = new_free_rects.duplicate_deep(true)
	remove_redundant_()
	
	
func find_best_score(item: ItemBase) -> Array:
	# [score, rect, rotated]
	var candidates: Array = []
	
	for rect in free_rects:
		if item_fits_rect_(item, rect, false):
			var score = score_func_.call(rect, item, self)
			candidates.append([score, rect, false])
		if rotation and item_fits_rect_(item, rect, true):
			# Temporarily swap to compute score
			item.in_backpack_attr.rotate()
			var score = score_func_.call(rect, item, self)
			candidates.append([score, rect, true])
			# Restore
			item.in_backpack_attr.reverse_rotate()
			
	if candidates.is_empty():
		return [null, null, false]

	# Sort by score (lexicographic comparison works in GDScript for arrays)
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var best = candidates[0]
	return [best[0], best[1], best[2]]
	
	
func insert(item: ItemBase) -> bool:
	var result: Array = find_best_score(item)
	var best_rect = result[1]
	var rotated = result[2]
	
	if best_rect == null:
		return false
	#print("best_rect: (%d, %d), width = %d, height = %d" % [best_rect.x, best_rect.y, best_rect.width, best_rect.height])
	if rotated:
		item.rotate()
	item.in_backpack_attr.y = best_rect.y
	item.in_backpack_attr.x = best_rect.x
	items.append(item)
	free_area -= item.in_backpack_attr.width * item.in_backpack_attr.height
	
	# Remove best_rect and add splits
	free_rects.erase(best_rect)
	
	var splits: Array = split_rectangle_(best_rect, item)
	#print("place item width: %d, height: %d" % [item.in_backpack_attr.width, item.in_backpack_attr.height])
	
	free_rects.append_array(splits)
	#print("after split:")
	#for r in free_rects:
		#print("small chunk: (%d, %d), width = %d, height = %d" % [r.x, r.y, r.width, r.height])
	
	var bounds = item.in_backpack_attr.get_bounds()
	prune_overlaps(bounds)
	#print("after merge:")
	#for r in free_rects:
		#print("small chunk: (%d, %d), width = %d, height = %d" % [r.x, r.y, r.width, r.height])
	
	return true


## 返回箱子状态
func bin_stats() -> Dictionary:
	return {
		"width": bin_width,
		"height": bin_height,
		"area": bin_width * bin_height,
		"efficiency": 1.0 * (bin_width * bin_height - free_area) / (bin_width * bin_height),
		"items": items.duplicate()  # shallow copy
	}
