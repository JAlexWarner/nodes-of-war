shader_type canvas_item;

//instance uniform int resource_val : int;
//uniform int resource_val = 30;

uniform float line_thickness = 0.01;
uniform float radius = .48;
uniform vec2 origin = vec2(0.5, 0.5);
uniform vec3 color: source_color;

void fragment() {
    COLOR.rgb = color;
    float distance_to_center = distance(UV, origin);
    float not_outside_circle = step(radius - line_thickness * 0.5, distance_to_center);
    float not_inside_circle = step(distance_to_center, radius + line_thickness * 0.5);
    //COLOR.a = not_outside_circle * not_inside_circle;
	COLOR.a = not_inside_circle;
}