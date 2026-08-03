#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
#define MY_HIGHP_OR_MEDIUMP highp
#else
#define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;
extern MY_HIGHP_OR_MEDIUMP vec2 frozen;

number frozen_noise(vec2 position) {
    return fract(sin(dot(position, vec2(41.371, 289.913))) * 48271.753);
}

number frozen_crystal_edge(vec2 uv, vec2 scale, number offset) {
    vec2 cell = fract(uv * scale + offset) - 0.5;
    number diagonal = abs(cell.x + cell.y * 0.72);
    number cross = abs(cell.x - cell.y * 0.72);
    number edge = min(diagonal, cross);
    return 1.0 - smoothstep(0.018, 0.075, edge);
}

vec4 effect(vec4 colour, Image tex_image, vec2 texture_coords, vec2 screen_coords) {
    vec4 base = Texel(tex_image, texture_coords) * colour;
    vec2 uv = (((texture_coords * image_details) - texture_details.xy * texture_details.ba) / texture_details.ba);
    vec2 centered = uv - vec2(0.5);
    centered.x *= texture_details.b / max(texture_details.a, 0.001);
    number grain = frozen_noise(floor(uv * vec2(58.0, 79.0)));
    number large_grain = frozen_noise(floor(uv * vec2(14.0, 19.0)) + 73.0);
    number veins = sin(uv.x * 39.0 + sin(uv.y * 22.0 + time * 0.35) * 3.2);
    number frost = smoothstep(0.31, 0.91, grain * 0.68 + abs(veins) * 0.46 + large_grain * 0.22);
    number crystal = max(
        frozen_crystal_edge(uv, vec2(9.0, 13.0), 0.0),
        frozen_crystal_edge(uv + vec2(0.17, 0.31), vec2(17.0, 11.0), 4.0)
    );
    number edge = smoothstep(0.17, 0.72, length(centered));
    number moving_band = 1.0 - smoothstep(0.015, 0.14, abs(uv.x - uv.y * 0.62 - 0.58 + sin(time * 0.55) * 0.32));
    number sparkle = max(0.0, sin((uv.x - uv.y) * 62.0 - time * 2.3) - 0.64) * 0.78;
    number glaze = clamp(0.22 + frost * 0.31 + edge * 0.22 + crystal * 0.34 + moving_band * 0.28, 0.0, 0.82) * base.a;
    vec3 ice = vec3(0.72941, 0.96863, 0.94510);
    vec3 glass = 1.0 - (1.0 - base.rgb) * (1.0 - ice * (0.34 + frost * 0.31));
    vec3 result = mix(base.rgb, glass, glaze);
    result = mix(result, vec3(1.0), (crystal * 0.29 + moving_band * 0.31 + sparkle * 0.42) * base.a);
    number renderer_keepalive = dissolve + burn_colour_1.a + burn_colour_2.a + frozen.x + frozen.y;
    if (renderer_keepalive < -9999.0) {
        result += burn_colour_1.rgb + burn_colour_2.rgb;
    }
    if (shadow) {
        return vec4(vec3(0.0), base.a * 0.30);
    }
    return vec4(result, base.a);
}

extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    if (hovering <= 0.0) {
        return transform_projection * vertex_position;
    }

    float mid_dist = length(vertex_position.xy - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy) / screen_scale;
    float scale = 0.2 * (-0.03 - 0.3 * max(0.0, 0.3 - mid_dist))
        * hovering * (length(mouse_offset) * length(mouse_offset)) / (2.0 - mid_dist);
    return transform_projection * vertex_position + vec4(0.0, 0.0, 0.0, scale);
}
#endif
