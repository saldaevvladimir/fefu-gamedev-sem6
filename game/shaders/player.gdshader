shader_type canvas_item;

uniform float hit_opacity = 0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR.rgb= texture(TEXTURE, UV).rgb * (1.0 - hit_opacity) + vec3(1, 1, 1) * hit_opacity;
	COLOR.a = texture(TEXTURE, UV).a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
