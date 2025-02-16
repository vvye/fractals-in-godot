## An implementation of the "Sierpinski triangle" fractal with an infinite zoom feature.
## You can zoom in using the mouse wheel, or hold the left mouse button to zoom in smoothly.



@tool
extends ColorRect
class_name SierpinskiTriangle


## How much the scale grows with each zoom step using the mouse wheel.
const fast_scale_factor: float = 1.1

## How much the scale grows with each zoom step using the mouse button.
const slow_scale_factor: float = 1.025


## The color to draw the triangles with.
@export var foreground_color: Color = Color("#ABC7E4")

## The individual triangles drawn to the screen.
var triangles: Array[Triangle] = []

## The original triangle from which all other triangles descend.
var original_triangle: Triangle


## A basic class for an equilateral triangle with one side parallel to the X axis,
## defined by a top point and a height.
##
## (I could have moved this to its own script file but it's small enough to fit here.)
##
class Triangle:

	## The triangle's top point.
	var top_point: Vector2

	## The triangle's height.
	var height: float

	## The triangle's side length (calculated from the height).
	var side_length: float

	## Initializes the triangle give the top point and the height.
	func _init(_top_point: Vector2, _height: float) -> void:
		top_point = _top_point
		height = _height
		side_length = height / sin(TAU / 6)

	## Returns all three points of the triangle.
	func points() -> Array[Vector2]:
		var left_point = Vector2(top_point.x - side_length / 2, top_point.y + height)
		var right_point = Vector2(top_point.x + side_length / 2, top_point.y + height)
		return [top_point, left_point, right_point]

	## Returns three triangles of half the size, arranged in a Sierpinski pattern
	## (looking like the former triangle with a hole cut out in the middle).
	func split() -> Array[Triangle]:
		var new_height: float = height / 2
		var new_top_point_1: Vector2 = top_point + Vector2(-side_length / 4, height / 2)
		var new_top_point_2: Vector2 = top_point + Vector2(side_length / 4, height / 2)
		return [
			Triangle.new(top_point, new_height),
			Triangle.new(new_top_point_1, new_height),
			Triangle.new(new_top_point_2, new_height)
		]



func _ready() -> void:

	# create the original triangle
	var initial_height: float = 400.0
	var initial_top_point: Vector2 = Vector2(size.x / 2, (size.y - initial_height) / 2)
	original_triangle = Triangle.new(initial_top_point, initial_height)

	# split all triangles until they're a good approximation of the fractal
	triangles = [original_triangle]
	for i in range(8):
		_split_all_triangles()



## Splits all triangles on screen into smaller triangles.
##
func _split_all_triangles() -> void:

	var new_triangles: Array[Triangle] = []
	for triangle in triangles:
		new_triangles.append_array(triangle.split())
	triangles = new_triangles



## Removes all triangles that aren't visible on the screen.
##
## For simplicity, this only checks if a triangle's top point is on screen
## (the individual triangles are so small that it doesn't make a difference).
##
func _remove_offscreen_triangles() -> void:

	var screen_rect: Rect2 = Rect2(-position / scale, size / scale)
	triangles = triangles.filter(func (triangle): return screen_rect.has_point(triangle.top_point))



func _draw() -> void:

	# decrease the transparency of the triangles as they grow
	# (this makes the split point less obvious because splitting
	# creates tiny holes that make the shape appear darker)
	foreground_color.a = lerpf(1, 0.75, scale.x - 1)

	for triangle in triangles:
		draw_primitive(triangle.points(), [foreground_color], [])



func _process(_delta: float) -> void:

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_zoom(slow_scale_factor)

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if Input.is_action_just_pressed("ui_end"):
		_split_all_triangles()
		queue_redraw()



func _input(event):

	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(fast_scale_factor)



## Zooms the view in around the position of the mouse cursor.
##
func _zoom(factor: float) -> void:

	# don't allow zooming in the editor
	if Engine.is_editor_hint():
		return

	# don't do anything if the mouse cursor is off-screen
	if not get_viewport_rect().has_point(get_global_mouse_position()):
		return

	# preserve current mouse cursor position
	# (this is in image coordinates, so it might change after zooming
	# because the mouse cursor might end up on a different point in the image)
	var old_mouse_position = get_local_mouse_position()

	# scale the node up
	# (this is what triggers a redraw; _draw only runs once otherwise)
	scale *= factor

	# if the scale exceeds 2, scale it back down and instead scale the sierpinski triangle up
	if scale.x >= 2.0:
		scale /= 2.0
		if len(triangles):  # no need to do anything when you zoom into a hole leaving no triangles
			var new_triangles: Array[Triangle] = []
			var new_height = triangles[0].height * 2
			for triangle in triangles:
				var offset: Vector2 = triangle.top_point - old_mouse_position
				var new_top_point = triangle.top_point + offset
				new_triangles.append_array(Triangle.new(new_top_point, new_height).split())
			triangles = new_triangles

	# determine where (in image coordinates) the mouse cursor ended up after zooming
	# and move the image so that the mouse cursor is on the same point as before
	# (diff is in image coordinates, position is in actual pixels on the screen, so scale it up)
	var diff = get_local_mouse_position() - old_mouse_position
	position += diff * scale.x

	_remove_offscreen_triangles()
