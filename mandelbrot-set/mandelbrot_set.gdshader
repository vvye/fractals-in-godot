// A Mandelbrot set renderer.


shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;

// How many iterations to perform for each point before aborting.
const int max_steps = 5000;

// The distance between the center and the edges of the screen at default zoom.
const vec2 margin = vec2(2.5, 1.5);

// The palette to take the colors from.
uniform sampler2D palette;

// The coordinate represented by the center of the screen.
uniform vec2 center;

// The current zoom level.
uniform float zoom = 1.0;



// Calculates how many steps it takes for a point to escape to infitity
// (i.e. escape the circle with radius 2 around the origin)
// under the Mandelbrot map.
// If this returns max_steps, the point is considered to not escape to infinity,
// and thus be in the Mandelbrot set.

int mandelbrot_steps(float x, float y) {
	float orig_x = x;
	float orig_y = y;
	int i = 0;
	while (i++ < max_steps) {
		float x_squared = x * x;
		float y_squared = y * y;
		if (x_squared + y_squared > 4.0) {
			break;
		}
		float new_x = x_squared - y_squared + orig_x;
		y = (x + x) * y + orig_y;
		x = new_x;
	}
	return i;
}



void fragment() {
	
	float x = mix(center.x - margin.x / zoom, center.x + margin.x / zoom, SCREEN_UV.x);
	float y = mix(center.y - margin.y / zoom, center.y + margin.y / zoom, SCREEN_UV.y);
	int num_steps = mandelbrot_steps(x, y);
	if (num_steps >= max_steps - 1) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// I think this is wrong? I should be dividing num_steps by max_steps
		// and using that to lerp the position in the palette,
		// but for some reason this looks better, so hm
		float val = float(num_steps) / float(textureSize(palette, 0).x);
		COLOR = texture(palette, vec2(val, 0));
	}
	
}
