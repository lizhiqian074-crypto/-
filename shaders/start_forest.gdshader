shader_type canvas_item;
// A local, resolution-independent forest backdrop: no downloaded artwork needed.
float hill(vec2 p, float h, float frequency, float seed) {
	return smoothstep(h - 0.012, h + 0.018, p.y + sin(p.x * frequency + seed) * 0.075 + sin(p.x * frequency * 2.1 + seed) * 0.021);
}
void fragment() {
	vec2 p = UV;
	vec3 color = mix(vec3(0.025,0.052,0.042), vec3(0.18,0.24,0.15), p.y * 0.65);
	float glow = exp(-length((p - vec2(0.68,0.22)) * vec2(1.0,1.1)) * 3.8);
	color += vec3(0.34,0.25,0.12) * glow;
	color = mix(color,vec3(0.105,0.17,0.13),hill(p,0.59,5.2,0.1)*0.8);
	color = mix(color,vec3(0.075,0.12,0.09),hill(p,0.71,7.1,2.0));
	color = mix(color,vec3(0.025,0.071,0.053),hill(p,0.91,5.0,3.0));
	// Tall silhouettes around the edges leave room for the original logo.
	float cell = floor(p.x * 24.0);
	float x = abs(fract(p.x * 24.0) - 0.5);
	float height = 0.10 + fract(sin(cell * 71.32) * 871.6) * 0.43;
	float trunk = (1.0-smoothstep(0.035,0.065,x)) * smoothstep(height,height+0.06,p.y);
	float canopy = (1.0-smoothstep(0.03,0.48,x)) * smoothstep(height-0.18,height,p.y) * (1.0-smoothstep(height+0.10,height+0.19,p.y));
	float edge = smoothstep(0.23,0.49,abs(p.x-0.5));
	color = mix(color,vec3(0.022,0.053,0.039),clamp((trunk+canopy)*edge,0.0,0.85));
	float fog = sin(p.x*5.0+TIME*0.05)*sin(p.y*7.0-TIME*0.04)*0.5+0.5;
	color += vec3(0.04,0.052,0.035)*fog*smoothstep(0.5,0.9,p.y)*0.35;
	color *= 1.0-smoothstep(0.2,0.83,length((p-0.5)*vec2(1.1,1.0)))*0.45;
	COLOR = vec4(color,1.0);
}
