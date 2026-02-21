## BaseItem 仅存储物品的基本属性
class_name ItemBase extends Resource

## 物品唯一标识
@export var item_id: String = ""
## 物品显示名称
@export var name: String
## 物品类型
@export var item_type: ItemType = ItemType.NONE
## 物品描述
@export var description: String = "无描述"
## 物品在背包中的属性
@export var in_backpack_attr: InBackpackAttr = null
## 物品材质
@export var texture: Texture2D:
	set(new_texture):
		texture = new_texture
		if new_texture != null and in_backpack_attr == null:
			in_backpack_attr = InBackpackAttr.new(texture.get_width(), texture.get_height())
		else:
			in_backpack_attr.ori_width_pixel = texture.get_width()
			in_backpack_attr.ori_height_pixel = texture.get_height()



## 物品类型
enum ItemType {
	WEAPON 		= 0,	# 武器
	CONSUMABLE 	= 1,	# 消耗品
	MATERIAL	= 2,	# 材料
	NONE		= 3,	# 无类型
}


## 自定义排序函数 [br]
## 1. 物品类型优先级 eg: 武器 > 消耗品 [br]
## 2. 物品面积降序 [br]
## 3. 物品的item_id => 同类型物品放置在一起
static func sort_func(item1: ItemBase, item2: ItemBase) -> bool:
	if item1.item_type != item2.item_type:
		return item1.item_type < item2.item_type
	if item1.in_backpack_attr.area != item2.in_backpack_attr.area:
		return item1.in_backpack_attr.area > item2.in_backpack_attr.area
	return item1.item_id < item2.item_id


func get_item_info() -> String:
	return "%s - %s" % [name, description]

func rotate() -> int:
	return in_backpack_attr.rotate()
	
## 通过texture的size动态计算物品的占格子数 [br]
## [b]强制要求物品尺寸能被格子size整除[/b]
var dimentions: Vector2i:
	get():
		var item_size := Vector2i(texture.get_width(), texture.get_height())
		return in_backpack_attr.get_dimention_in_backpack()


## for Debug
func position_in_backpack() -> String:
	return "item_name: %s, position: (%d, %d), rotate_degree: %d" \
	% [item_id, in_backpack_attr.x, in_backpack_attr.y, in_backpack_attr.rotate_degree]
