shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

// Espectador 2D dibujado en el propio shader: cabeza, cuerpo y brazos que se levantan.
uniform float cheer = 0.5;
varying vec3 shirt;
varying vec4 cd;
varying float inst;

void vertex() {
	shirt = COLOR.rgb;
	cd = INSTANCE_CUSTOM;
	inst = float(INSTANCE_ID);
	float bob = abs(sin(TIME * (4.0 + cd.x * 4.0) + cd.y * 6.28)) * 0.12 * cheer;
	VERTEX.y += bob;
}

float sd_circle(vec2 p, vec2 c, float r) {
	return length(p - c) - r;
}

float sd_seg(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float sd_box(vec2 p, vec2 c, vec2 hb, float r) {
	vec2 q = abs(p - c) - hb + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = vec2(UV.x, 1.0 - UV.y); // y hacia arriba, 0 = pies
	vec3 skin = mix(vec3(0.95, 0.77, 0.56), vec3(0.36, 0.21, 0.1), cd.z);
	vec3 hair = mix(vec3(0.09, 0.06, 0.04), vec3(0.86, 0.66, 0.26), cd.w);
	float wave = 0.5 + 0.5 * sin(TIME * (5.0 + cd.x * 3.0) + cd.y * 6.28);
	float up = clamp(cheer * 1.2 * (0.35 + 0.65 * wave), 0.0, 1.0);

	float d_head = sd_circle(p, vec2(0.5, 0.72), 0.17);
	float d_body = sd_box(p, vec2(0.5, 0.35), vec2(0.2, 0.26), 0.08);
	vec2 hand = vec2(0.0, mix(0.2, 0.92, up));
	float d_arm_l = sd_seg(p, vec2(0.31, 0.5), vec2(0.2, hand.y), 0.05);
	float d_arm_r = sd_seg(p, vec2(0.69, 0.5), vec2(0.8, hand.y), 0.05);
	float d_arm = min(d_arm_l, d_arm_r);
	float d_all = min(min(d_head, d_body), d_arm);

	float ol = 0.035;
	if (d_all > ol) {
		discard;
	}
	vec3 col = vec3(0.11, 0.07, 0.03);
	if (d_all <= 0.0) {
		if (d_head <= 0.0 && d_head <= d_body) {
			col = skin;
			if (p.y > 0.73 || (p.y > 0.66 && abs(p.x - 0.5) > 0.12)) {
				col = hair;
			}
			if (p.y < 0.7 && p.y > 0.66 && abs(abs(p.x - 0.5) - 0.07) < 0.025) {
				col = vec3(0.1, 0.06, 0.03);
			}
		} else if (d_body <= 0.0) {
			col = shirt;
			if (p.y > 0.5) {
				col = shirt * 1.08;
			}
		} else {
			col = skin;
		}
	}
	ALBEDO = col;
}
