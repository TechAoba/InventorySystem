## ItemWeapon 记录武器物品的基础属性
class_name ItemWeapon
extends ItemBase

# 武器专属属性
@export var damage: int = 10					# 伤害
@export var mag_capacity: int = 6			# 弹夹容量
@export var fire_rate: float = 0.8			# 射速（秒/发）
@export var weapon_model: PackedScene		# 武器3D/2D模型（拾取后世界显示/人物持有的预制体）
@export var fire_sound: AudioStream 			# 开火音效


func get_item_info() -> String:
	return "%s | 伤害：%d | 弹匣：%d | 射速：%f" % [name, damage, mag_capacity, fire_rate]


# 武器专属方法（示例：开火逻辑，可在人物持有时调用）
func fire() -> void:
	print("%s 开火！伤害：%d" % [name, damage])
