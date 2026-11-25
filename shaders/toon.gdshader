shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float shine = 0.35;
uniform float rim = 0.14;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_mix = 0.0;
uniform float tex_scale = 0.25;

varying vec3 wpos;
varying vec3 wnor;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnor = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = albedo.rgb;
	if (tex_mix > 0.0) {
		vec3 n = abs(wnor);
		n /= (n.x + n.y + n.z + 0.0001);
		vec3 t = texture(tex, wpos.zy * tex_scale).rgb * n.x + texture(tex, wpos.xz * tex_scale).rgb * n.y + texture(tex, wpos.xy * tex_scale).rgb * n.z;
		c *= mix(vec3(1.0), t * 1.35, tex_mix);
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	float r = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	EMISSION = c * r * rim;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.05, 0.1, ndl) * 0.62 + smoothstep(0.5, 0.6, ndl) * 0.38;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band * 0.62;
	vec3 h = normalize(LIGHT + VIEW);
	float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 40.0);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * step(0.5, spec) * shine * 0.5;
}
