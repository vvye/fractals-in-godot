## An implementation of the Dragon Curve.
##
## Here, the Dragon Curve is built from a previous iteration (starting with one line segment)
## by extracting the midpoimt of each line segment, alternating between outwards and inwards,
## changing each one into a right angle.



extends ColorRect
class_name DragonCurve



## The number of expansion steps after which the animation stops.
const max_steps: int = 20


## The color to draw the curve with.
@export var foreground_color: Color = Color("#ABC7E4")


## The current thickness of the line segments (shrinks with each step).
var line_thickness: float = 16.0

## The points defining the line segments of the current step.
## This includes a not-yet-expanded midpoint for each line segment
## to make the animation work.
var current_points: Array[Vector2]

## The points defining the line segments of the next step.
var target_points: Array[Vector2]

## How many times the expansion has been performed.
var num_steps: int = 0

## The animation timer.
var step_animation_timer: Timer



func _ready() -> void:

	# define the initial line segment relative to the screen size
	var x_margin: float = get_viewport_rect().size.x * 0.25
	var y_offset: float = get_viewport_rect().size.y * 0.15
	var initial_points: Array[Vector2] = [
		Vector2(x_margin, get_viewport_rect().size.y / 2.0 + y_offset),
		Vector2(get_viewport_rect().size.x - x_margin, get_viewport_rect().size.y / 2.0 + y_offset)
	]

	# initially, both the current and target points are the initial points
	current_points = initial_points
	target_points = initial_points

	# set up the animation timer
	step_animation_timer = Timer.new()
	step_animation_timer.wait_time = 1.0
	step_animation_timer.timeout.connect(_do_dragon_curve_step)
	add_child(step_animation_timer)

	# do one initial expansion step to start the process
	_do_dragon_curve_step()
	step_animation_timer.start()



func _draw() -> void:

	var percentage: float = 1.0 - step_animation_timer.time_left / step_animation_timer.wait_time
	percentage = _easing_function(percentage)

	# interpolate between the current and target points
	# based on the animation timer
	var moving_points: Array[Vector2] = []
	for i in range(len(current_points)):
		var point: Vector2 = lerp(current_points[i], target_points[i], percentage)
		moving_points.append(point)

	# draw a polyline with the interpolated points
	draw_polyline(moving_points, foreground_color, line_thickness)



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

	# make the target points the new current points, and calculate the new target points
	current_points = target_points
	_split_points()

	num_steps += 1



## Performs one iteration in the Dragon Curve process,
## creating new target points.
##
func _split_points() -> void:

	var new_points: Array[Vector2] = []
	target_points = []

	var rotation_dir = -1

	for i in range(len(current_points) - 1):
		var point: Vector2 = current_points[i]
		var next_point: Vector2 = current_points[i + 1]

		# create the target point by expanding outwards/inwards depending on current direction
		var target_point: Vector2 = point + (
				(next_point - point) / sqrt(2.0)).rotated(TAU / 8 * rotation_dir
		)

		# create a corresponding point that's just the midpoint of the line segment
		# (this will be animated towards the target point)
		var between_point: Vector2 = point + ((next_point - point) / 2.0)

		target_points.append(point)
		target_points.append(target_point)
		new_points.append(point)
		new_points.append(between_point)

		rotation_dir *= -1

	# add the last point outside of the loop#
	# (no need to create a new point for it)
	target_points.append(current_points[-1])
	new_points.append(current_points[-1])

	current_points = new_points

	line_thickness *= 0.9



## An easing function.
## Input and output should be between 0 and 1.
##
func _easing_function(x: float) -> float:

	return 0.5 * sin(PI * (x - 0.5)) + 0.5
