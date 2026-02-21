## 记录空闲矩形
class_name FreeRectangle

var width: int
var height: int
var x: int
var y: int


func _init(w: int, h: int, x: int, y: int):
	self.width = w
	self.height = h
	self.x = x
	self.y = y
	

func area() -> int:
	return width * height


func rect() -> Rect2i:
	return Rect2i(x, y, width, height)
	

func contains(other: FreeRectangle) -> bool:
	var r1 = rect()
	var r2 = other.rect()
	return r1.encloses(r2)
