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
extern MY_HIGHP_OR_MEDIUMP vec2 celestial;

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

float hsl_hue(float s, float t, float h) {
    float hs = mod(h, 1.0) * 6.0;
    if (hs < 1.0) return (t - s) * hs + s;
    if (hs < 3.0) return t;
    if (hs < 4.0) return (t - s) * (4.0 - hs) + s;
    return s;
}

vec4 hsl_to_rgb(vec4 c) {
    if (c.y < 0.0001) return vec4(vec3(c.z), c.a);
    float t = (c.z < 0.5) ? c.y * c.z + c.z : -c.y * c.z + (c.y + c.z);
    float s = 2.0 * c.z - t;
    return vec4(hsl_hue(s, t, c.x + 0.33333), hsl_hue(s, t, c.x), hsl_hue(s, t, c.x - 0.33333), c.w);
}

vec4 rgb_to_hsl(vec4 c) {
    float low = min(c.r, min(c.g, c.b));
    float high = max(c.r, max(c.g, c.b));
    float delta = high - low;
    float sum_value = high + low;
    vec4 hsl = vec4(0.0, 0.0, 0.5 * sum_value, c.a);
    if (delta == 0.0) return hsl;
    hsl.y = (hsl.z < 0.5) ? delta / sum_value : delta / (2.0 - sum_value);
    if (high == c.r) hsl.x = (c.g - c.b) / delta;
    else if (high == c.g) hsl.x = (c.b - c.r) / delta + 2.0;
    else hsl.x = (c.r - c.g) / delta + 4.0;
    hsl.x = mod(hsl.x / 6.0, 1.0);
    return hsl;
}

vec4 hsl_adjust_layer(vec4 base, float hue_offset, float saturation_add, float saturation_scale, float lightness_add, float lightness_scale) {
    vec4 hsl = rgb_to_hsl(base);
    hsl.x = hsl.x + hue_offset;
    hsl.y = clamp(hsl.y * saturation_scale + saturation_add, 0.0, 1.0);
    hsl.z = clamp(hsl.z * lightness_scale + lightness_add, 0.0, 1.0);
    return hsl_to_rgb(hsl);
}

vec4 played_field_layer(vec4 base, float saturation_scale, float lightness_scale, float alpha_amount) {
    vec4 hsl = rgb_to_hsl(base);
    hsl.y *= saturation_scale;
    hsl.z *= lightness_scale;
    vec4 out_color = hsl_to_rgb(hsl);
    out_color.a *= alpha_amount;
    return out_color;
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

vec4 celestial_wave_wash(vec4 base, vec2 uv, float time_value, float base_alpha) {
    vec2 centered = uv - vec2(0.5);
    float aspect = max(texture_details.b / max(texture_details.a, 0.001), 0.01);
    centered.x *= aspect;

    float diagonal_a = dot(centered, vec2(0.72, 0.58));
    float diagonal_b = dot(centered, vec2(-0.35, 0.94));
    float wave_a = 0.5 + 0.5 * sin(diagonal_a * 24.0 - time_value * 5.40);
    float wave_b = 0.5 + 0.5 * sin(diagonal_b * 17.0 + time_value * 3.85 + sin(uv.y * 10.0 + time_value * 1.7));
    float wave = smoothstep(0.48, 1.0, wave_a * 0.68 + wave_b * 0.32);
    float ribbon = pow(wave, 1.65);

    vec3 blue = vec3(0.03, 0.26, 0.92);
    vec3 violet = vec3(0.66, 0.22, 1.00);
    vec3 wash = mix(blue, violet, smoothstep(0.15, 0.95, wave_b));
    float alpha = (0.16 + 0.46 * ribbon) * base_alpha;

    base = blend_over(base, vec4(wash, alpha), 3);
    base.rgb += wash * (0.10 + ribbon * 0.22) * base_alpha;
    base.rgb += vec3(0.60, 0.78, 1.00) * pow(wave_a, 12.0) * 0.18 * base_alpha;
    base.rgb = clamp(base.rgb, 0.0, 1.0);
    return base;
}

number twinkle_mask(vec2 uv, number time_value) {
    vec2 grid = vec2(22.0, 32.0);
    vec2 cell_id = floor(uv * grid);
    vec2 cell = fract(uv * grid) - 0.5;
    number seed = rand(cell_id + vec2(19.17, 3.91));
    number seed2 = rand(cell_id + vec2(71.43, 41.28));
    vec2 offset = vec2(rand(cell_id + 11.0), rand(cell_id + 29.0)) * 0.64 - 0.32;
    number dist = length(cell - offset);
    number radius = mix(0.09, 0.22, rand(cell_id + 53.0));
    number core = 1.0 - smoothstep(radius * 0.12, radius * 0.42, dist);
    number cross = max(
        1.0 - smoothstep(0.0, radius, abs(cell.x - offset.x)),
        1.0 - smoothstep(0.0, radius, abs(cell.y - offset.y))
    ) * (1.0 - smoothstep(radius * 0.2, radius * 1.8, dist));
    number blink = 0.5 + 0.5 * sin(time_value * mix(5.0, 13.5, seed2) + seed * 6.28318);
    number gate = step(0.82, seed);
    return gate * max(core, cross * 0.55) * smoothstep(0.48, 1.0, blink);
}

vec4 effect(vec4 colour, Image tex_image, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(tex_image, texture_coords) * colour;
    vec2 uv = (((texture_coords) * (image_details)) - texture_details.xy * texture_details.ba) / texture_details.ba;
    number base_alpha = tex.a;
    vec4 result = vec4(0.0);
    vec4 layer_0 = texture_layer(tex_image, uv, vec2(0.00000, 0.00000), vec2(1.00000, 1.00000), 0.00000, 1.00000);
    result = blend_over(result, layer_0, 0);
    result = hsl_adjust_layer(result, 0.00000, -0.50000, 1.00000, 0.00000, 1.00000);
    vec4 layer_2 = vec4(vec3(0.12000, 0.43000, 0.98000), 0.52000 * base_alpha);
    layer_2.a *= base_alpha;
    result = blend_over(result, layer_2, 2);
    vec4 layer_3 = vec4(mix(vec3(0.08000, 0.34000, 0.95000), vec3(0.62000, 0.21000, 1.00000), smoothstep(0.5 - 0.85000, 0.5 + 0.85000, dot(uv - vec2(0.50000, 0.50000), vec2(0.81915, 0.57358)) / max(10.00000, 0.001) + 0.5)), 0.46000);
    layer_3.a *= base_alpha;
    result = blend_over(result, layer_3, 3);
    result = played_field_layer(result, 0.92000, 1.02000, 0.90000);
    result = celestial_wave_wash(result, uv, time, base_alpha);
    vec4 layer_5 = vec4(vec3(1.00000, 1.00000, 1.00000), 1.12000 * sparkle_mask(uv, time, 0.95500, 0.28000, 4.00000));
    layer_5.a *= base_alpha;
    result = blend_over(result, layer_5, 0);
    vec4 twinkle_layer = vec4(vec3(1.00000), 1.70 * twinkle_mask(uv, time));
    twinkle_layer.a *= base_alpha;
    result = blend_over(result, twinkle_layer, 3);
    float edition_keepalive = dissolve + burn_colour_1.a + burn_colour_2.a + celestial.x + celestial.y;
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
