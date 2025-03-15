shader_type canvas_item;
uniform float skew = 0.0;
uniform float skew_center = 0.5;

void vertex() {
    float distance_factor = (UV.y - skew_center);

    VERTEX.x += distance_factor * skew;
}