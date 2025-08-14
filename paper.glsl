
// === Tweakables (ShaderToy-safe) ===
#define PAPER_COLOR        vec3(0.95, 0.92, 0.85)
#define PAPER_NOISE_AMT    0.05
#define FIBER_AMP          0.02

#define LIGHT_DIR          vec3(-0.5, 0.5, 1.0)
#define DEBOSS_SCALE       0.08
#define TEXT_DEBOSS        0.05

#define VIGNETTE_X         0.5
#define VIGNETTE_Y         0.12
#define VIGNETTE_BOOST     1.0

#define GRAIN_STRENGTH     0.03
#define DESATURATE_AMT     0.6

#define WARP_X_FREQ        3.0
#define WARP_X_STRENGTH    0.003
#define WARP_Y_FREQ        6.0
#define WARP_Y_STRENGTH    0.00007

// === Utilities ===
vec3  saturate(vec3 a){ return clamp(a, 0.0, 1.0); }
float rand(vec2 co){ return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453); }
float luminance(vec3 c){ return dot(c, vec3(0.299,0.587,0.114)); }
vec3  desaturate(vec3 c, float factor){ float l = luminance(c); return mix(c, vec3(l), factor); }

// === Paper ===
float paperHeight(vec2 uv){
    float n = rand(uv * 300.0);
    float fiber = sin(uv.y * 800.0 + n * 10.0) * FIBER_AMP;
    return n * PAPER_NOISE_AMT + fiber;
}
vec3 paperColor(){ return PAPER_COLOR; }

// === Deboss ===
float deboss(vec2 uv){
    float h   = paperHeight(uv);
    float hdx = paperHeight(uv + vec2(1.0/80.0, 0.0)) - h;
    float hdy = paperHeight(uv + vec2(0.0, 1.0/40.0)) - h;
    vec3 normal  = normalize(vec3(-hdx, -hdy, 1.0));
    vec3 lightDn = normalize(LIGHT_DIR);
    return dot(normal, lightDn) * DEBOSS_SCALE;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord.xy / iResolution.y;
    uv = uv * 2.0 - 1.0;

    // Warp
    uv.x += cos(uv.y * (uv.x + 1.0) * WARP_X_FREQ) * WARP_X_STRENGTH;
    uv.y += cos(uv.x * WARP_Y_FREQ) * WARP_Y_STRENGTH;

    // Paper base + lighting
    vec3 col = paperColor() + paperHeight(uv);
    col += deboss(uv);

    // Vignette
    vec2 uvV = uv - 1.0; // separate var so we don't affect later math
    float vignetteAmt = VIGNETTE_BOOST * (1.0 - dot(uvV * VIGNETTE_X, uvV * VIGNETTE_Y));
    col *= vignetteAmt;

    // Grain
    col += (rand(uv) - 0.5) * GRAIN_STRENGTH;
    col = saturate(col);

    // Text from iChannel0 (RGBA: color + mask)
    vec4 textPixel = texture(iChannel0, fragCoord.xy / iResolution.xy);
    float mask = textPixel.a;
    vec3 textColor = textPixel.rgb;

    // Pencil-style text
    vec3 pencilText = desaturate(textColor, DESATURATE_AMT);

    // Paper depression under text
    col -= mask * TEXT_DEBOSS;

    // Blend text multiplicatively to keep texture
    col = mix(col, col * pencilText, mask);

    fragColor = vec4(saturate(col), 1.0);
}

