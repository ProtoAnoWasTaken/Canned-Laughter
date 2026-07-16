#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
#define MY_HIGHP_OR_MEDIUMP highp
#else
#define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;
extern MY_HIGHP_OR_MEDIUMP vec2 glitter;

number rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453);
}

number sparkle_mask(vec2 uv, number time, number density, number size, number speed) {
    vec2 grid = floor(uv * vec2(42.0, 56.0));
    vec2 cell = fract(uv * vec2(42.0, 56.0)) - 0.5;
    number seed = rand(grid);
    number pulse = 0.5 + 0.5 * sin(time * speed + seed * 6.28318);
    number shape = 1.0 - smoothstep(size * 0.35, size, length(cell));
    return step(density, seed) * shape * pulse;
}

vec4 alpha_fade_layer(vec4 base, float threshold, float divisor) {
    if (base.a < threshold) base.a = base.a / max(divisor, 0.001);
    return base;
}

vec4 glitter_field_layer(vec4 base, vec2 uv, float time_value, float phase, float speed, float amount, vec3 glitter_color, vec3 soft_color) {
    vec2 centered = uv - vec2(0.5);
    centered.x *= texture_details.b / max(texture_details.a, 0.001);
    float low = min(base.r, min(base.g, base.b));
    float high = max(base.r, max(base.g, base.b));
    float contrast = high - low;
    float dist = length(centered);
    float t = time_value * speed + phase * 6.28318;
    float vignette = smoothstep(0.24, 0.82, dist);
    float pulse = 0.5 + 0.5 * sin(t * 1.25 + dist * 9.0);
    float strength = clamp(0.12 + 0.80 * vignette + 0.18 * pulse * vignette, 0.0, 0.92) * amount;
    vec3 darkened = min(mix(base.rgb, soft_color, 0.42), glitter_color * (0.56 + 0.34 * contrast));
    base.rgb = mix(base.rgb, darkened, strength);
    vec2 grid = vec2(38.0, 54.0);
    vec2 cell = floor(uv * grid);
    float seed = rand(cell);
    float seed2 = rand(cell + 17.0);
    float seed3 = rand(cell + 43.0);
    vec2 pos = fract(uv * grid) - 0.5 - (vec2(seed2, seed3) * 0.58 - 0.29);
    float shape = 1.0 - smoothstep(0.018, mix(0.10, 0.20, rand(cell + 91.0)), length(pos));
    float life = 0.5 + 0.5 * sin(t * mix(3.2, 11.4, seed2) + seed * 6.28318);
    float fleck = step(0.915, seed) * shape * smoothstep(mix(0.52, 0.86, seed3), 1.0, life);
    float diagonal = max(0.0, cos((uv.x + uv.y) * 95.0 + t * 2.4) - 0.94) * 8.0;
    float sparkle = clamp(fleck + diagonal * smoothstep(0.48, 0.86, dist), 0.0, 1.0);
    base.rgb = mix(base.rgb, vec3(1.0), 0.48 * sparkle * amount);
    return base;
}

float vanilla_field(vec2 uv, float t, float shimmer_scale, float wave_scale) {
    vec2 centered = uv - vec2(0.5);
    float aspect = max(texture_details.b / max(texture_details.a, 1.0), 0.01);
    centered.x *= aspect;
    vec2 grid = floor(uv * texture_details.ba) / max(texture_details.ba, vec2(1.0));
    vec2 p = (grid - 0.5) * shimmer_scale;
    float field = sin(length(p + 12.0 * vec2(sin(t / 1.7), cos(t / 1.3))) / max(wave_scale, 0.001));
    field += cos(dot(centered, vec2(0.8, -0.6)) * shimmer_scale + t * 1.7);
    field += sin((uv.x + uv.y) * wave_scale + t * 2.1);
    return 0.5 + 0.5 * sin(field);
}

vec4 dissolve_mask_layer(vec4 base, vec2 uv, float time_value, float dissolve_amount, float softness, float threshold) {
    if (dissolve_amount <= 0.001) return base;
    float field = vanilla_field(uv, time_value * 10.0 + 2003.0, 48.0, 24.0);
    float edge = smoothstep(threshold - max(softness, 0.001), threshold + max(softness, 0.001), field);
    float mask = smoothstep(dissolve_amount - max(softness, 0.001), dissolve_amount + max(softness, 0.001), edge);
    base.a *= mask;
    return base;
}

vec2 layer_uv_transform(vec2 source_uv, vec2 offset, vec2 scale, number rotation_degrees) {
    vec2 centered = source_uv - vec2(0.5);
    number radians_value = radians(rotation_degrees);
    mat2 rotation = mat2(cos(radians_value), -sin(radians_value), sin(radians_value), cos(radians_value));
    return rotation * (centered * scale) + vec2(0.5) + offset;
}

vec2 layer_texture_coords(vec2 layer_uv) {
    return (texture_details.xy * texture_details.ba + layer_uv * texture_details.ba) / image_details;
}

vec4 texture_layer(Image tex_image, vec2 source_uv, vec2 offset, vec2 scale, number rotation_degrees, number opacity) {
    vec2 layer_uv = layer_uv_transform(source_uv, offset, scale, rotation_degrees);
    vec4 sampled = Texel(tex_image, layer_texture_coords(layer_uv));
    return vec4(sampled.rgb, sampled.a * opacity);
}

vec3 blend_rgb(vec3 base, vec3 layer, int mode) {
    if (mode == 1) return min(base + layer, vec3(1.0));
    if (mode == 2) return base * layer;
    if (mode == 3) return 1.0 - (1.0 - base) * (1.0 - layer);
    if (mode == 4) return mix(2.0 * base * layer, 1.0 - 2.0 * (1.0 - base) * (1.0 - layer), step(0.5, base));
    if (mode == 5) return max(base - layer, vec3(0.0));
    if (mode == 6) return mix(2.0 * base * layer + base * base * (1.0 - 2.0 * layer), sqrt(max(base, vec3(0.0))) * (2.0 * layer - 1.0) + 2.0 * base * (1.0 - layer), step(0.5, layer));
    if (mode == 7) return max(base, layer);
    if (mode == 8) return min(base, layer);
    if (mode == 9) return abs(base - layer);
    if (mode == 10) {
        float low = min(base.r, min(base.g, base.b));
        float high = max(base.r, max(base.g, base.b));
        float delta = min(high, max(0.5, 1.0 - low));
        float lift = max(layer.r, max(layer.g, layer.b));
        return clamp(vec3(
            base.r - delta + delta * lift * 0.3,
            base.g - delta + delta * lift * 0.3,
            base.b + delta * lift * 1.9
        ), 0.0, 1.0);
    }
    if (mode == 11) {
        float low = min(base.r, min(base.g, base.b));
        float high = max(base.r, max(base.g, base.b));
        float delta = high - low;
        return clamp(base + delta * layer, 0.0, 1.0);
    }
    if (mode == 12) {
        float low = min(base.r, min(base.g, base.b));
        float high = max(base.r, max(base.g, base.b));
        float delta = high - low;
        return clamp(base - delta * layer, 0.0, 1.0);
    }
    return layer;
}

vec4 blend_over(vec4 base, vec4 layer, int mode) {
    float raw_alpha = layer.a;
    layer.a = clamp(layer.a, 0.0, 1.0);
    vec3 rgb = mix(base.rgb, blend_rgb(base.rgb, layer.rgb, mode), layer.a);
    if (mode == 10) {
        float foil_alpha = min(base.a, 0.3 * base.a + 0.9 * min(0.5, max(raw_alpha, 0.0) * 0.1));
        return vec4(rgb, foil_alpha);
    }
    return vec4(rgb, max(base.a, layer.a));
}

vec4 effect(vec4 colour, Image tex_image, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(tex_image, texture_coords) * colour;
    vec2 uv = (((texture_coords) * (image_details)) - texture_details.xy * texture_details.ba) / texture_details.ba;
    number base_alpha = tex.a;
    vec4 result = vec4(0.0);
    vec4 layer_0 = texture_layer(tex_image, uv, vec2(0.00000, 0.00000), vec2(1.00000, 1.00000), 0.00000, 1.00000);
    result = blend_over(result, layer_0, 0);
    result = alpha_fade_layer(result, 0.70000, 3.00000);
    result = dissolve_mask_layer(result, uv, time, 0.00000, 0.12000, 0.50000);
    result = glitter_field_layer(result, uv, time, 0.0, 1.00000, 1.50000, vec3(1.00000, 0.52941, 0.96863), vec3(1.00000, 0.72157, 0.98039));
    vec4 layer_4 = vec4(vec3(1.00000, 0.36078, 0.95686), 0.30000);
    layer_4.a *= base_alpha;
    result = blend_over(result, layer_4, 4);
    vec4 layer_5 = vec4(vec3(1.00000, 1.00000, 1.00000), 0.85000 * sparkle_mask(uv, time, 0.96500, 0.45000, 4.00000));
    layer_5.a *= base_alpha;
    result = blend_over(result, layer_5, 3);
    float edition_keepalive = dissolve + burn_colour_1.a + burn_colour_2.a + glitter.x + glitter.y;
    if (edition_keepalive < -9999.0) result += vec4(burn_colour_1.rgb + burn_colour_2.rgb, edition_keepalive);
    if (shadow) result = vec4(vec3(0.0), result.a * 0.3);
    return result;
}

extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    if (hovering <= 0.0) return transform_projection * vertex_position;
    float mid_dist = length(vertex_position.xy - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy) / screen_scale;
    float scale = 0.2 * (-0.03 - 0.3 * max(0.0, 0.3 - mid_dist)) * hovering * (length(mouse_offset) * length(mouse_offset)) / (2.0 - mid_dist);
    return transform_projection * vertex_position + vec4(0.0, 0.0, 0.0, scale);
}
#endif
