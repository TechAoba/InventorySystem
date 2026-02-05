## BaseItem 仅存储物品的基本属性
class_name ItemBase extends Resource

## 物品唯一标识
@export var item_id: String = ""
## 物品显示名称
@export var name: String
## 物品材质
@export var texture: Texture2D
## 物品类型
@export var item_type: ItemType = ItemType.NONE
## 物品描述
@export var description: String = "无描述"
## 物品在背包中的属性
@export var in_backpack_attr: InBackpackAttr


func _init() -> void:
	in_backpack_attr = InBackpackAttr.new()


## 物品类型
enum ItemType {
	NONE,			# 无类型
	WEAPON,			# 武器
	CONSUMABLE,		# 消耗品
	MATERIAL,		# 材料
}

func get_item_info() -> String:
	return "%s - %s" % [name, description]

func rotate() -> int:
	return in_backpack_attr.rotate()
	
## 通过texture的size动态计算物品的占格子数 [br]
## [b]强制要求物品尺寸能被格子size整除[/b]
var dimentions: Vector2i:
	get():
		var item_size := Vector2i(texture.get_width(), texture.get_height())
		return in_backpack_attr.get_dimention_in_backpack(item_size)
	
