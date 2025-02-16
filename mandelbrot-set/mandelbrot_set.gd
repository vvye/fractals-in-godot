## An implementation of a Mandelbrot set visualization.
## It can be dragged around and zoomed into, but is limited to the GPU's float precision.
##
## Use the mouse wheel to zoom in and out, or hold the right mouse button to zoom in smoothly.
##
## The main calculations are done in a shader; this script just handles panning and zooming.



extends ColorRect



# The minimum zoom level.
const min_zoom: float = 0.5

# The maximum zoom level.
const max_zoom: float = INF


# The shader material.
@onready var shader_material = material as ShaderMaterial


# The coordinate represented by the center of the screen.
var center: Vector2 = Vector2.ZERO

# The distance between the center and the edges of the screen at default zoom.
var margin: Vector2 = Vector2(2.5, 1.5)

# The current zoom level.
var zoom: float = 1.0

## How much the scale grows with each zoom step using the mouse wheel.
const fast_zoom_factor: float = 1.1

## How much the scale grows with each zoom step using the mouse button.
const slow_zoom_factor: float = 1.025

## Whether the view si currently being dragged.
var dragging: bool = false



func _ready() -> void:

	# initialize shader parameters
	_zoom(0)
	shader_material.set_shader_parameter("center", center)
	shader_material.set_shader_parameter("palette", $GradientSprite.texture)



func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if Input.is_action_just_pressed("wheel_up"):
		_zoom(fast_zoom_factor)

	if Input.is_action_just_pressed("wheel_down"):
		_zoom(1.0 / fast_zoom_factor)

	if Input.is_action_just_pressed("left_click"):
		dragging = true

	if Input.is_action_just_released("left_click"):
		dragging = false

	if Input.is_action_pressed("right_click"):
		_zoom(slow_zoom_factor)



func _input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:

		if not dragging:
			return

		# handle dragging
		# (convert the mouse distance to "math coordinates"
		# and move the center point by that amount)
		var distance: Vector2 = event.relative
		distance.x = distance.x * 2 * margin.x / (get_viewport().size.x * zoom)
		distance.y = distance.y * 2 * margin.y / (get_viewport().size.y * zoom)
		center -= distance
		shader_material.set_shader_parameter("center", center)



## Zooms in or out.
##
func _zoom(factor: float = fast_zoom_factor) -> void:

	# preserve current mouse cursor position
	# (it might change after zooming because the mouse cursor might end up
	# on a different point in the image)
	var old_mouse_pos = _math_coords(get_local_mouse_position())

	# change the zoom and update the shader parameter
	zoom *= factor
	zoom = clampf(zoom, min_zoom, max_zoom)
	shader_material.set_shader_parameter("zoom", zoom)

	# determine where the mouse cursor ended up after zooming
	# and move the image so that the mouse cursor is on the same point as before
	var new_mouse_pos = _math_coords(get_local_mouse_position())
	var diff = new_mouse_pos - old_mouse_pos
	center -= diff
	shader_material.set_shader_parameter("center", center)



## Converts a vector describing screen coordinates (pixels from 0 to screen width / height)
## to a point in the Mandelbrot set's coordinate system,
## depending on the current center point and zoom.
##
func _math_coords(pos: Vector2) -> Vector2:

	var new_x: float = lerp(center.x - margin.x / zoom, center.x + margin.x / zoom, pos.x / get_viewport().size.x)
	var new_y: float = lerp(center.y - margin.y / zoom, center.y + margin.y / zoom, pos.y / get_viewport().size.y)

	return Vector2(new_x, new_y)
