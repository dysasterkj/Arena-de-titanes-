shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform float cheer = 1.0;
uniform int mode = 0;
uniform float side = 1.0;
varying vec3 col;

void vertex() {
	col = COLOR.rgb;
	float id = float(INSTANCE_ID);
	float bob = abs(sin(TIME * (3.0 + mod(id, 5.0) * 0.45) + id)) * 0.16 * cheer;
	if (mode == 1) {
		vec3 v = VERTEX;
		v.y += 0.25;
		float ang = mix(0.3, 2.65, clamp(cheer, 0.0, 1.0)) + sin(TIME * (5.0 + mod(id, 4.0)) + id) * 0.55 * cheer;
		ang *= side;
		float c = cos(ang);
		float s = sin(ang);
		VERTEX = vec3(v.x * c - v.y * s, v.x * s + v.y * c, v.z);
		NORMAL = vec3(NORMAL.x * c - NORMAL.y * s, NORMAL.x * s + NORMAL.y * c, NORMAL.z);
	}
	VERTEX.y += bob;
}

void fragment() {
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
