class_name Heuristics

static func scoreBAF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [rect.area() - item.in_backpack_attr.width * item.in_backpack_attr.height, 
			min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreBSSF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height), max(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreBLSF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [max(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height), min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreWAF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [-(rect.area() - item.in_backpack_attr.width * item.in_backpack_attr.height), -min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreWSSF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [-min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height), -max(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreWLSF(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [-max(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height), -min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]

static func scoreBL(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	return [rect.y + item.in_backpack_attr.height, rect.x]

static func common_interval_length(a_start: int, a_end: int, b_start: int, b_end: int) -> int:
	if a_end <= b_start or b_end <= a_start:
		return 0
	return min(a_end, b_end) - max(a_start, b_start)

static func scoreCP(rect: FreeRectangle, item: ItemBase, packer) -> Array:
	var perim = 0
	# 边界接触
	if rect.x == 0 or rect.x + item.in_backpack_attr.width == packer.bin_width:
		perim += item.in_backpack_attr.height
	if rect.y == 0 or rect.y + item.in_backpack_attr.height == packer.bin_height:
		perim += item.in_backpack_attr.width

	# 与其他已放置物品接触
	for itm in packer.items:
		# 左右接触
		if itm.x == rect.x + rect.width or itm.x + itm.width == rect.x:
			perim += common_interval_length(itm.y, itm.y + itm.height, rect.y, rect.y + item.in_backpack_attr.height)
		# 上下接触
		if itm.y == rect.y + rect.height or itm.y + itm.height == rect.y:
			perim += common_interval_length(itm.x, itm.x + itm.width, rect.x, rect.x + item.in_backpack_attr.width)

	return [-perim, min(rect.width - item.in_backpack_attr.width, rect.height - item.in_backpack_attr.height)]
