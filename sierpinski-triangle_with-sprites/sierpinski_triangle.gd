## An implementation of the "Sierpinski triangle" fractal with an infinite zoom feature.
## You can zoom in using the mouse wheel, or hold the left mouse button to zoom in smoothly.
##
## This implementation uses Sprite nodes with a pre-rendered image on them
## instead of the _draw function in order to improve performance.


@tool
extends ColorRect
class_name SierpinskiTriangle


## How much the scale grows with each zoom step using the mouse wheel.
const fast_scale_factor: float = 1.1

## How much the scale grows with each zoom step using the mouse button.
const slow_scale_factor: float = 1.0175

## The Sierpinski triangle sprites drawn to the screen.
var sprites: Array[Sprite2D]

## The height of all sprites.
var height: float

## The width of all sprites.
var width: float



func _ready() -> void:

	# initialize the sprite list, width, and height from the initial sprite
	sprites = [$Sprite2D]
	width = $Sprite2D.get_rect().size.x
	height = $Sprite2D.get_rect().size.y

	# do two rounds of splitting upfront
	# (this is enough to make the illusion work)
	_split_all_triangles()
	_split_all_triangles()



## Splits all triangle sprites on screen into smaller triangles.
##
func _split_all_triangles() -> void:

	# halve the global width and height
	width /= 2
	height /= 2

	# loop through all sprites
	# (looping via index because we're manipulating the array in the loop)
	for i in range(len(sprites)):
		var sprite: Sprite2D = sprites[i]

		# scale the sprite down
		sprite.scale /= 2
		var x_offset = width / 2
		var y_offset = height

		# add a copy of the sprite to the bottom left
		var bottom_left_triangle: Sprite2D = sprite.duplicate()
		bottom_left_triangle.position += Vector2(-x_offset, y_offset)
		sprite.add_sibling(bottom_left_triangle)
		sprites.append(bottom_left_triangle)

		# add a copy of the sprite to the bottom left
		var bottom_right_triangle: Sprite2D = sprite.duplicate()
		bottom_right_triangle.position += Vector2(x_offset, y_offset)
		sprite.add_sibling(bottom_right_triangle)
		sprites.append(bottom_right_triangle)



## Removes all sprites that aren't visible on the screen.
##
func _remove_offscreen_sprites() -> void:

	var screen_rect: Rect2 = Rect2(-position / scale, size / scale)

	var new_sprites: Array[Sprite2D] = []
	for sprite in sprites:
		var sprite_rect = Rect2(sprite.position.x - width / 2, sprite.position.y, width, height)
		if screen_rect.intersects(sprite_rect):
			new_sprites.append(sprite)
		else:
			sprite.queue_free()
	sprites = new_sprites



func _process(_delta: float) -> void:

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_zoom(slow_scale_factor)

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# decrease the transparency of the sprites as they grow
	# (this makes the split point less obvious because splitting
	# creates tiny holes that make the shape appear darker)
	for sprite in sprites:
		sprite.self_modulate.a = lerpf(1, 0.75, scale.x - 1)



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
	scale *= factor

	# if the scale exceeds 2, scale it back down and instead scale the sprites up
	if scale.x >= 2.0:
		scale /= 2.0
		width *= 2
		height *= 2
		for i in range(len(sprites)):
			var sprite: Sprite2D = sprites[i]
			var offset: Vector2 = sprite.position - old_mouse_position
			sprite.position += offset
			sprite.scale *= 2.0
		_split_all_triangles()

	# determine where (in image coordinates) the mouse cursor ended up after zooming
	# and move the image so that the mouse cursor is on the same point as before
	# (diff is in image coordinates, position is in actual pixels on the screen, so scale it up)
	var diff = get_local_mouse_position() - old_mouse_position
	position += diff * scale.x

	_remove_offscreen_sprites()
