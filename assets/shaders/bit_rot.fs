#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define MY_HIGHP_OR_MEDIUMP highp
#else
    #define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP vec2 bit_rot;
extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = (((texture_coords) * image_details) - texture_details.xy * texture_details.ba) / texture_details.ba;

    float band_seed = floor(uv.y * 45.0 + floor(time * 5.0));
    float noise = fract(sin(band_seed * 17.17 + bit_rot.r * 13.0) * 43758.5453);
    float band = step(0.76, noise);
    float hard_band = step(0.94, noise);
    float shift = band * sin(time * 15.0 + band_seed) * (0.006 + 0.006 * hard_band);
    vec2 displaced = texture_coords + vec2(shift, 0.0);

    vec4 tex = Texel(texture, displaced) * colour;

    float split = (0.0035 + 0.0035 * hard_band) * band;
    float red = Texel(texture, displaced + vec2(split, 0.0)).r;
    float blue = Texel(texture, displaced - vec2(split, 0.0)).b;
    tex.r = mix(tex.r, red, 0.65 * band);
    tex.g *= 1.0 - 0.10 * hard_band;
    tex.b = mix(tex.b, blue, 0.65 * band);
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(0.90, 1.04, 1.12), 0.24);
    tex.rgb = mix(
        tex.rgb,
        burn_colour_1.rgb * burn_colour_1.a + burn_colour_2.rgb * burn_colour_2.a,
        dissolve * 0.08
    );
    tex.a *= 1.0 - dissolve;

    if (shadow) {
        return vec4(vec3(0.0), tex.a * 0.3);
    }

    return tex;
}

extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    if (hovering <= 0.0) {
        return transform_projection * vertex_position;
    }

    float mid_dist = length(vertex_position.xy - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy) / screen_scale;
    float scale = 0.2 * (-0.03 - 0.3 * max(0.0, 0.3 - mid_dist))
        * hovering * dot(mouse_offset, mouse_offset) / (2.0 - mid_dist);

    return transform_projection * vertex_position + vec4(0.0, 0.0, 0.0, scale);
}
#endif
