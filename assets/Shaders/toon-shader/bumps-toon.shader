// Toon shader with normal map, depth map, occlusion map and
// anisotropy maps. It has to be separated because assigning
// values to the normal map may cause geometry to break.
// If all your models are well made, you can use this one
// in place of the base toon shader, though they might be
// less efficient, so unless you're using them there is
// little reason to not use the base toon shader instead.
shader_type spatial;



uniform vec4 albedo : hint_color = vec4(1.0);
uniform sampler2D texture_albedo : hint_albedo;

// Diffuse curve. This is, in my opinion, what defines a toon shader. A
// photo-realistic shader should have a linear curve starting at 0 and
// finishing at 1, and a toon shader should start at 0 and get to 1 almost
// instantaneously. The length of this transition is its smoothing, working
// the same way as the specular and rim light smoothing uniforms. Another
// common curve is to make it a staircase, which would result in multiple
// shading bands. Check the video for a more detailed explanation.
uniform sampler2D diffuse_curve : hint_white;

// Specular light uniforms. Set specular to zero to turn off the effect.
// The texture map uses the red channel for the specular value, green for amount
// and blue for smoothness.
uniform float specular : hint_range(0,1) = 0.5;
uniform float specular_amount : hint_range(0,1) = 0.5;
uniform float specular_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_specular : hint_white;

// Rim light uniforms. Set rim to zero to turn off the effect.
// The texture map uses the red channel for the rim value, green for rim amount
// and blue for smoothness.
uniform float rim : hint_range(0,1) = 0.5;
uniform float rim_amount : hint_range(0,1) = 0.2;
uniform float rim_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_rim : hint_white;

// Roughness and metallic here are only for reflection purposes if you are
// using SS reflections or want the sky reflected on your material. In most
// cases you don't want to change those, but you can try them. The surface
// texture maps the red channel to roughness and the green channel to metallic.
uniform float metallic : hint_range(0,1) = 0.0;
uniform float roughness : hint_range(0,1) = 1.0;
uniform sampler2D texture_surface : hint_white;

// Emission from base code.
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
uniform sampler2D texture_emission : hint_black_albedo;

// Normal map from base code.
uniform float normal_scale : hint_range(-16,16) = 1.0;
uniform sampler2D texture_normal : hint_normal;

// Depth map from base code.
uniform float depth_scale = 0.0;
uniform int depth_min_layers = 8;
uniform int depth_max_layers = 32;
uniform bool flip_tangent = false;
uniform bool flip_binormal = false;
uniform sampler2D texture_depth : hint_black;

// Ambient occlusion from base code.
uniform float ao_light_affect: hint_range(0,1) = 0.0;
uniform sampler2D ao_map : hint_white;

// Anisotropy from base code.
uniform float anisotropy_ratio: hint_range(-1,1) = 0.0;
uniform vec3 anisotropy_direction = vec3(0.0, -1.0, 0.0);
uniform float aniso_map_dir_ratio: hint_range(0,1) = 0.0;
uniform sampler2D anisotropy_flowmap : hint_aniso;

// UV scale and offset from base code.
uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);



// Vertex function to deal with UV scale and offset, straight out of base code.
void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}



void fragment() {
	vec2 base_uv = UV;
	
	// Depth from base code, with deep parallax enabled. Slightly modified so that
	// black are deeps and white are peaks, as well as turning depth flip into bools.
	// It is very intense on the GPU, so keep depth scale at zero to turn this off.
	if (depth_scale != 0.0) {
		vec2 depth_flip = vec2(flip_tangent ? -1.0 : 1.0, flip_binormal ? -1.0 : 1.0);
		vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*depth_flip.x,-BINORMAL*depth_flip.y,NORMAL));
		float num_layers = mix(float(depth_max_layers),float(depth_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		float current_layer_depth = 0.0;
		vec2 P = view_dir.xy * depth_scale;
		vec2 delta = P / num_layers;
		vec2  ofs = base_uv;
		float depth = 1.0 - textureLod(texture_depth, ofs,0.0).r;
		float current_depth = 0.0;
		while(current_depth < depth) {
			ofs -= delta;
			depth = 1.0 - textureLod(texture_depth, ofs,0.0).r;
			current_depth += layer_depth;
		}
		vec2 prev_ofs = ofs + delta;
		float after_depth  = depth - current_depth;
		float before_depth = 1.0 - textureLod(texture_depth, prev_ofs, 0.0).r - current_depth + layer_depth;
		float weight = after_depth / (after_depth - before_depth);
		ofs = mix(ofs,prev_ofs,weight);
		base_uv=ofs;
	}
	
	ALBEDO = albedo.rgb * texture(texture_albedo, base_uv).rgb;
	ROUGHNESS = roughness * texture(texture_surface, base_uv).r;
	METALLIC = metallic * texture(texture_surface, base_uv).g;
	
	// Normal map, straight out of base code.
	NORMALMAP = texture(texture_normal, base_uv).rgb;
	NORMALMAP_DEPTH = normal_scale;
	
	// Ambient occlusion, straight out of base code on the red channel.
	AO = texture(ao_map, base_uv).r;
	AO_LIGHT_AFFECT = ao_light_affect;
	
	// Emission, straight out of base code with additive mode.
	EMISSION = (emission.rgb + texture(texture_emission, base_uv).rgb) * emission_energy;
}



const float PI = 3.14159265358979323846;

void light() {
	// Let's start by incorporating specular and rim textures. Pay attention to
	// the channels and what each value does.
	float spec_value = specular * texture(texture_specular, UV).r;
	float spec_gloss = pow(2.0, 8.0 * (1.0 - specular_amount * texture(texture_specular, UV).g));
	float spec_smooth = specular_smoothness * texture(texture_specular, UV).b;
	float rim_value = rim * texture(texture_rim, UV).r;
	float rim_width = rim_amount * texture(texture_rim, UV).g;
	float rim_smooth = rim_smoothness * texture(texture_rim, UV).b;
	
	// Diffuse part. We take the dot product between light and normal, multiply it by attenuation
	// and apply it to the diffuse curve. This means the diffuse curve gets to do the dot product
	// smoothing, set multiple light bands each with its own tone and smoothing, etc etc. I reccomend
	// using the gradient tool to make a curve, since it gives you control of each point's position
	// and color with precision. The curve tool works too, it gives you control of different
	// interpolation methods but you have less control over each point's exact position and value.
	vec3 litness = texture(diffuse_curve, vec2(dot(LIGHT, NORMAL), 0.0)).r * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * litness;
	
	// Specular part. We use the Blinn-Phong specular calculations with a smoothstep
	// function to toonify. Mess with the specular uniforms to see what each one does.
	// It also deals with anisotropy. If you want to remove anisotropy calculations,
	// remove flowchart, aniso_dir, aniso and replace spec by dot(NORMAL, half).
	vec3 half = normalize(VIEW + LIGHT);
	vec3 flowchart = (texture(anisotropy_flowmap, UV).rgb * 2.0 - 1.0);
	vec3 aniso_dir = mix(normalize(anisotropy_direction), flowchart, aniso_map_dir_ratio);
	float aniso = max(0, sin(dot(normalize(NORMAL + aniso_dir), half) * PI));
	float spec = mix(dot(NORMAL, half), aniso, anisotropy_ratio * texture(anisotropy_flowmap, UV).a);
	float spec_intensity = pow(spec, spec_gloss * spec_gloss);
	spec_intensity = smoothstep(0.05, 0.05 + spec_smooth, spec_intensity);
	SPECULAR_LIGHT += LIGHT_COLOR * spec_value * spec_intensity * litness;
	
	// Rim part. We use the view and normal vectors only to find out if we're looking
	// at a pixel from the edge of the object or not. We add the final value to specular
	// light values so that Godot treats it as specular.
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_width), dot(LIGHT, NORMAL));
	float rim_intensity = smoothstep(rim_threshold - rim_smooth/2.0, rim_threshold + rim_smooth/2.0, rim_dot);
	SPECULAR_LIGHT += LIGHT_COLOR * rim_value * rim_intensity * litness;
}


