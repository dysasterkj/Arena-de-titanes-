shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float shine = 0.35;
uniform float rim = 0.3;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_mix = 0.0;
uniform float tex_scale = 0.25;
uniform sampler2D tex2 : source_color, filter_linear_mipmap, repeat_enable;
uniform float detail_mix = 0.0;
uniform float detail_scale = 1.0;
uniform float ground_ao = 1.0;

varying vec3 wpos;
varying vec3 wnor;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnor = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 tri(sampler2D s, vec3 p, vec3 n, float sc) {
	return texture(s, p.zy * sc).rgb * n.x + texture(s, p.xz * sc).rgb * n.y + texture(s, p.xy * sc).rgb * n.z;
}

void fragment() {
	vec3 c = albedo.rgb;
	vec3 n = abs(wnor);
	n /= (n.x + n.y + n.z + 0.0001);
	if (tex_mix > 0.0) {
		c *= mix(vec3(1.0), tri(tex, wpos, n, tex_scale) * 1.35, tex_mix);
	}
	if (detail_mix > 0.0) {
		c *= mix(vec3(1.0), tri(tex2, wpos, n, tex_scale * detail_scale) * 1.4, detail_mix);
	}
	// sombra de contacto cerca del suelo: los pies se ven apoyados
	float ao = mix(0.62, 1.0, clamp(wpos.y * 0.9 + 0.1, 0.0, 1.0));
	c *= mix(1.0, ao, ground_ao);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	float r = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	EMISSION = c * r * rim;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.1, 0.28, ndl) * 0.62 + smoothstep(0.3, 0.85, ndl) * 0.38;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band * 0.5;
	vec3 h = normalize(LIGHT + VIEW);
	float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 40.0);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * smoothstep(0.35, 0.8, spec) * shine * 0.3;
}
