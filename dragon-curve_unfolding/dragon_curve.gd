## An implementation of the Dragon Curve.
##
## Here, the Dragon Curve is built from a previous iteration (starting with one line segment)
## by rotating it around its last point, similar to folding up a piece of paper.



extends ColorRect
class_name DragonCurve



## The number of expansion steps after which the animation stops.
const max_steps: int = 16


## The color to draw the curve with.
@export var foreground_color: Color = Color("#ABC7E4")

## The current thickness of the line segments (shrinks with each step).
var line_thickness: float = 16.0

## The points defining the line segments of the current step.
var current_points: Array[Vector2]

## The scale of the current step.
var current_scale: float = 1.0

## The zoom center point of the current step.
var current_zoom_center: Vector2

## The points defining the line segments of the next step.
var target_points: Array[Vector2]

## The scale of the next step.
var target_scale: float = 1.0

## The zoom center point of the next step.
var target_zoom_center: Vector2

## How many times the rotation has been performed.
var num_steps: int = 0

## The animation timer.
var step_animation_timer: Timer



func _ready() -> void:

	# define the initial line segment relative to the screen size
	var x_margin: float = get_viewport_rect().size.x * 0.35
	var y_offset: float = get_viewport_rect().size.y * 0.15
	var initial_points: Array[Vector2] = [
		Vector2(x_margin, get_viewport_rect().size.y / 2.0 + y_offset),
		Vector2(get_viewport_rect().size.x - x_margin, get_viewport_rect().size.y / 2.0 + y_offset)
	]

	# initially, both the current and target points are the initial points
	current_points = initial_points.duplicate()
	target_points = initial_points.duplicate()

	current_zoom_center = (current_points[0] + current_points[-1]) * 0.5
	target_zoom_center = (target_points[0] + target_points[-1]) * 0.5

 	# set up the animation timer
	step_animation_timer = Timer.new()
	step_animation_timer.wait_time = 3.5
	step_animation_timer.timeout.connect(_do_dragon_curve_step)
	add_child(step_animation_timer)

	# do one initial expansion step to start the process
	_do_dragon_curve_step()
	step_animation_timer.start()



func _draw() -> void:

	var percentage: float = 1.0 - step_animation_timer.time_left / step_animation_timer.wait_time
	percentage = _easing_function(percentage)

	# the rotation pivot is the last of the old points, so it's the middle point of the new ones
	var pivot = current_points[len(current_points) / 2]

	# get the current angle based on the animation timer
	var angle: float = lerpf(0, TAU / 4, percentage)

	# get the current scale based on the animation timer
	var scale_factor: float = lerpf(current_scale, target_scale, percentage)
	scale = Vector2.ONE * scale_factor

	# get the current zoom center based on the animation timer
	var moving_zoom_center: Vector2 = lerp(current_zoom_center, target_zoom_center, percentage)

	# interpolate between the current and target points
	# based on the animation timer
	var moving_points: Array[Vector2] = []
	for i in range(len(current_points)):
		if i < len(current_points) / 2:  # the first half of points stays still
			moving_points.append(current_points[i])
		else:
			var point: Vector2 = _rotate_point_around(current_points[i], pivot, angle)
			moving_points.append(point)

	# draw a polyline with the interpolated points
	draw_polyline(moving_points, foreground_color, line_thickness, true)

	# shift the position to be centered on the zoom center point
	position = -moving_zoom_center * scale.x + size / 2



func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if not step_animation_timer:
		return

	# we have to tell godot to redraw each frame
	# because we're not changing properties like scale,
	# so as far as Godot knows there's nothing to redraw
	queue_redraw()



## Runs when the step timer runs out.
##
func _do_dragon_curve_step() -> void:

	# end the animation if enough steps were taken
	if num_steps >= max_steps:
		step_animation_timer.stop()
		return

	# make the target points/scale/zoom center the new current ones
	current_points = target_points.duplicate()
	current_scale = target_scale
	current_zoom_center = target_zoom_center

	# and calculate the new target points
	_split_points()

	num_steps += 1



## Performs one iteration in the Dragon Curve process,
## creating new target points.
##
func _split_points() -> void:

	var other_points: Array[Vector2] = current_points.duplicate()
	other_points.reverse()
	var pivot: Vector2 = other_points[0]

	for i in range(1, len(other_points)):
		var p: Vector2 = other_points[i]
		current_points.append(p)
		target_points.append(_rotate_point_around(p, pivot, TAU / 4))

	line_thickness *= 1.1892
	target_scale *= 0.707
	target_zoom_center = (target_points[0] + target_points[-1]) * 0.5



## An easing function.
## Input and output should be between 0 and 1.
##
func _easing_function(x: float) -> float:

	return 0.5 * sin(PI * (x - 0.5)) + 0.5



## Rotates one point around another and returns the new point.
##
func _rotate_point_around(p: Vector2, pivot: Vector2, angle: float) -> Vector2:

	var diff: Vector2 = p - pivot
	diff = diff.rotated(angle)

	return pivot + diff
