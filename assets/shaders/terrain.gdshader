/* The two-texture shared working OK up to Feb 2024
*/
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex_1_albedo: hint_albedo;
// Ambient occlusion, roughness, metalness
uniform sampler2D tex_1_ao: hint_black;
uniform sampler2D tex_1_normal : hint_normal;
uniform sampler2D tex_2_albedo: hint_albedo;
uniform sampler2D tex_2_normal : hint_normal;
uniform sampler2D tex_3_albedo: hint_albedo;
uniform sampler2D tex_3_normal : hint_normal;
uniform float blend_smoothness : hint_range(0.01, 1.0, 0.01) = 0.12;
uniform float threshold : hint_range(0.1, 1.0, 0.01) = 0.88;
uniform float normal_mult : hint_range(0.1, 1.0, 0.01) = 0.77;
uniform float scale_texture1 : hint_range(0.25, 1024.0, 0.125) = 16.0;
uniform float scale_texture2 : hint_range(0.25, 1025.0, 0.125) = 16.0;
uniform float scale_texture3 : hint_range(0.25, 1025.0, 0.125) = 16.0;
uniform bool additive_mix = false;
uniform bool use_red_vertex_color = true;
uniform bool use_ao_occlusion = false;
uniform bool use_world_direction = false;
uniform vec3 world_direction = vec3(0.0, 1.0, 0.0);

void fragment(){
	// sample all the textures
	vec4 albedo1 = texture(tex_1_albedo, UV*scale_texture1);
	vec4 albedo2 = texture(tex_2_albedo, UV*scale_texture2);
	vec4 albedo3 = texture(tex_3_albedo, UV*scale_texture3);
	//vec3 normal1 = texture(tex_1_normal, UV*scale_texture1).rgb;  
	vec3 normal1 = texture(tex_1_normal, UV*scale_texture1).rgb * vec3(1.0, -1.0, 1.0) - vec3(0.0, -1.0, 0.0);  // correcting the inverted normal?
	vec3 normal2 = texture(tex_2_normal, UV*scale_texture2).rgb;
	vec3 normal3 = texture(tex_3_normal, UV*scale_texture3).rgb;
	float ao = texture(tex_1_ao, UV).r;
	float mix_factor1 = 0.0;
	float addends = 0.0;
	if(use_red_vertex_color){
		mix_factor1 += COLOR.r;
		addends += 1.0;
	}
	if(use_world_direction){
		// textures are from 0 to 1, but we want the normals to be able to go negative.
		vec3 unpacked_normal = (normal1 * 2.0 - vec3(1.0))*normal_mult;
		unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));
		// Binormal and tangent vectors are what allows us to transform the
		// 2D normalmaps into something that can interact with 3D space
		vec3 world_tangent = (CAMERA_MATRIX * vec4(TANGENT, 0.0)).xyz;
		vec3 world_binormal = (CAMERA_MATRIX * vec4(BINORMAL, 0.0)).xyz;
		vec3 world_normal = (CAMERA_MATRIX * vec4(NORMAL, 0.0)).xyz;
		// Normal mixing taken directly from Godot's spatial shader (drivers/gles3/shaders/spatial.glsl)
		vec3 normalmap_normal = normalize(unpacked_normal.y * world_tangent + unpacked_normal.x * world_binormal + world_normal * unpacked_normal.z);
		
		// the more the world-space normal is aligned to the given vector,
		// the more we want to show the second texture.
		mix_factor1 += clamp(
				dot(normalmap_normal, world_direction)
				,0.0,1.0);
		addends += 1.0;
	}
	if(use_ao_occlusion){
		mix_factor1 += 1.0 - ao;
		addends += 1.0;
	}
	
	// If we don't use additive mix, we do an average of the components.
	if(!additive_mix){
		mix_factor1 /= addends;
	}


	mix_factor1 = smoothstep(0.0, blend_smoothness, mix_factor1 - threshold);

	NORMALMAP = mix(normal1, normal2, mix_factor1);
	
	
	
	ALBEDO = clamp(mix(albedo1, albedo2, mix_factor1).rgb, vec3(0.0), vec3(1.0));
}

/* made using vis shader start, 
textures are good but need to add normals 

shader_type spatial;
render_mode specular_schlick_ggx, async_visible;

uniform sampler2D tex_frg_16;
uniform sampler2D tex_frg_18;
uniform float n_in8p1: hint_range(0.0,1.0) = 0.99900;
uniform float n_in14p1: hint_range(0.0,1.0) = 0.90000;
uniform float brightness: hint_range(0.0,1.0) = 0.2;
uniform float uv_mult: hint_range(0.0,256.0) = 64.0;

void vertex() {
// Output:0

}

void fragment() {
// Input:7
	mat4 n_out7p0 = INV_CAMERA_MATRIX;

// Input:5
	vec3 n_out5p0 = NORMAL;

// TransformVectorMult:9
	vec3 n_out9p0 = (vec4(n_out5p0, 1.0) * n_out7p0).xyz;

// Vector:6
	vec3 n_out6p0 = vec3(0.000000, 1.000000, 0.000000);

// DotProduct:4
	float n_out4p0 = dot(n_out9p0, n_out6p0);

// Texture:16
	vec4 tex_frg_16_read = texture(tex_frg_16, (UV*uv_mult).xy);
	vec3 n_out16p0 = (tex_frg_16_read.rgb)*brightness;
	float n_out16p1 = tex_frg_16_read.a;

// Texture:18
	vec4 tex_frg_18_read = texture(tex_frg_18, (UV*uv_mult).xy);
	vec3 n_out18p0 = tex_frg_18_read.rgb*brightness;
	float n_out18p1 = tex_frg_18_read.a;

// ScalarOp:14

	float n_out14p0 = n_out4p0 - n_in14p1;

// ScalarOp:15
	float n_in15p1 = 1.0/(n_in8p1-n_in14p1); // 4.00000;
	float n_out15p0 = n_out14p0 * n_in15p1;

// VectorScalarMix:12
	vec3 n_out12p0 = mix(n_out18p0, n_out16p0, n_out15p0);

// If:13
	float n_in13p1 = n_in14p1;
	float n_in13p2 = 0.00001;
	vec3 n_out13p0;
	if(abs(n_out4p0 - n_in13p1) < n_in13p2)
	{
		n_out13p0 = n_out12p0;
	}
	else if(n_out4p0 < n_in13p1)
	{
		n_out13p0 = n_out18p0;
	}
	else
	{
		n_out13p0 = n_out12p0;
	}

// If:8

	float n_in8p2 = 0.00001;
	vec3 n_out8p0;
	if(abs(n_out4p0 - n_in8p1) < n_in8p2)
	{
		n_out8p0 = n_out16p0;
	}
	else if(n_out4p0 < n_in8p1)
	{
		n_out8p0 = n_out13p0;
	}
	else
	{
		n_out8p0 = n_out16p0;
	}

// Output:0
	ALBEDO = n_out8p0;

}

void light() {
// Output:0

}/*



/* this one from here:https://www.reddit.com/r/godot/s/dDCTmYgglv
	
	doesn't work too well
	
shader_type spatial;
uniform sampler2D grass_texture : hint_albedo;
uniform sampler2D rock_texture : hint_albedo;
uniform sampler2D sand_texture : hint_albedo;

uniform float min_rock_slope:hint_range(0.0,1.0) = 0.5;
uniform float max_grass_slope:hint_range(0.0,1.0) = 0.9;
uniform float min_rockgrass_height:hint_range(-50,50) = -8.0;
uniform float max_sand_height:hint_range(-50,50) = -6.0;
uniform float UV_mult:hint_range(1.0, 128.0) = 64;

varying float normal_y;
varying float vertex_y;

void vertex(){
	normal_y = NORMAL.y;
	vertex_y = VERTEX.y;
}

void fragment(){
	//Albedo Values
	vec3 grass_albedo = texture(grass_texture,UV*UV_mult).xyz;
	vec3 rock_albedo = texture(rock_texture,UV*UV_mult).xyz;
	vec3 sand_albedo = texture(sand_texture,UV*UV_mult).xyz;
	//Weights
	float rock_grass_weight = normal_y;
	float sand_rockgrass_weight = vertex_y;
	//Calculating Rock/Grass Weight
	rock_grass_weight = max(min_rock_slope, rock_grass_weight);
	rock_grass_weight = min(max_grass_slope, rock_grass_weight);
	rock_grass_weight -= min_rock_slope;
	rock_grass_weight /= max_grass_slope - min_rock_slope;
	//Calculating Sand/RockGrass Weight
	sand_rockgrass_weight = max(min_rockgrass_height, sand_rockgrass_weight);
	sand_rockgrass_weight = min(max_sand_height, sand_rockgrass_weight);
	sand_rockgrass_weight -= min_rockgrass_height;
	sand_rockgrass_weight /= max_sand_height - min_rockgrass_height;
	//Mixing and Assigning Albedo
	vec3 rockgrass_albedo = mix(rock_albedo, grass_albedo, rock_grass_weight);
	ALBEDO = mix(sand_albedo, rockgrass_albedo, sand_rockgrass_weight);
}*/

/* this one from here: https://gitlab.com/arcane_hive/terrain-generator-godot/-/blob/master/shaders/TerrainShader2.shader?ref_type=heads
	doesn't seem to work

shader_type spatial;
uniform float max_grass_height = 2.0;
uniform float min_snow_height = 18.0;
uniform float slope_factor = 8.0;
uniform sampler2D grass_tex : hint_albedo;
uniform vec2 grass_scale;
uniform sampler2D dirt_tex : hint_albedo;
uniform vec2 dirt_scale;
uniform sampler2D snow_tex : hint_albedo;
uniform vec2 snow_scale;
varying float height_val;
varying vec3 normal;
void vertex(){
	height_val = VERTEX.y;
	normal = NORMAL;
}
float get_slope_of_terrain(float height_normal){
	float slope = 1.0-height_normal;
	slope *= slope;
	return (slope*slope_factor);
}
float get_snow_and_grass_mix(float curr_height){
	if (curr_height > min_snow_height){
		return 1.0;
	}
	if (curr_height  < max_grass_height){
		return 0.0;
	}
	float mix_height = (curr_height-max_grass_height) / (min_snow_height-max_grass_height);
	return mix_height;
}
void fragment(){
	vec3 dirt = vec3(texture(dirt_tex, UV*dirt_scale).rgb)*0.35;
	vec3 grass = vec3(texture(grass_tex, UV*grass_scale).rgb)*0.5;
	vec3 snow = vec3(texture(snow_tex, UV*snow_scale).rgb);
	
	float slope = clamp(get_slope_of_terrain(normal.y), 0.0, 1.0);
	float snow_mix = clamp(get_snow_and_grass_mix(height_val), 0.0, 1.0);
	
	vec3 grass_mixin = mix(grass, dirt, slope);
	vec3 dirt_mixin = mix(dirt, snow, snow_mix/slope);
	vec3 snow_mixin = mix(snow, dirt_mixin, slope);
	vec3 mixin = mix(grass_mixin, snow_mixin, snow_mix);
}*/


