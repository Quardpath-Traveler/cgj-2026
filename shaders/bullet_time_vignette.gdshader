shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float radius : hint_range(0.0, 1.0) = 0.32;
uniform float softness : hint_range(0.0, 1.0) = 0.45;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// 屏幕中心 -> 角落的距离，用屏幕宽高归一化（圆而非椭圆）
	vec2 centered = UV - vec2(0.5);
	centered.x *= 1.0;
	centered.y *= 1.0;
	float dist = length(centered);

	// 中心完全无影响（vignette=1），向外渐变到完全暗化（vignette=0）
	float vignette = 1.0 - smoothstep(radius, radius + softness, dist);

	// 强度可控
	float a = (1.0 - vignette) * intensity;
	COLOR = vec4(vignette_color.rgb, vignette_color.a * a);
}
