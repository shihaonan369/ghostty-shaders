
vec3 saturate(vec3 a){ return clamp(a,0.0,1.0); }
float rand(vec2 co){ return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453); }

// convert RGB to grayscale
float luminance(vec3 c){ return dot(c, vec3(0.299,0.587,0.114)); }
vec3 desaturate(vec3 c, float factor){ float l = luminance(c); return mix(c, vec3(l), factor); }

// Procedural paper texture (height + color)
float paperHeight(vec2 uv){
    float n = rand(uv*300.0);
    float fiber = sin(uv.y*800.0 + n*10.0)*0.02;
    return n*0.05 + fiber;
}
vec3 paperColor(){ return vec3(0.95,0.92,0.85); }

// Compute debossed light based on gradient
float deboss(vec2 uv){
    float h = paperHeight(uv);
    float hdx = paperHeight(uv + vec2(1.0/80.0, 0.0)) - h;
    float hdy = paperHeight(uv + vec2(0.0, 1.0/40.0)) - h;
    vec3 lightDir = normalize(vec3(-0.5,0.5,1.0));
    vec3 normal = normalize(vec3(-hdx,-hdy,1.0));
    return dot(normal, lightDir)*0.08;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord.xy / iResolution.y;
    uv = uv*2.0 - 1.0;
    uv.x += cos(uv.y*(uv.x+1.0)*3.0) * 0.003;
    uv.y += cos(uv.x * 6.0) * 0.00007;

    // base paper with procedural height & deboss
    vec3 col = paperColor() + paperHeight(uv);
    float light = deboss(uv);
    col += light;

    // vignette
    uv -= 1.0;
    float vignetteAmt = 1.0 - dot(uv*0.5, uv*0.12);
    col *= vignetteAmt;

    // grain
    col.rgb += (rand(uv)-0.5)*0.03;
    col.rgb = saturate(col.rgb);

    // text from iChannel0 (RGBA: color + mask)
    vec4 textPixel = texture(iChannel0, fragCoord.xy/iResolution.xy);
    float mask = textPixel.a;
    vec3 textColor = textPixel.rgb;

    // keep paper texture under text, reduce saturation for pencil look
    vec3 pencilText = desaturate(textColor, 0.6);

    // simulate slight deboss on paper under text
    float textDeboss = mask * 0.05; // small depression
    col -= textDeboss;

    // blend pencil text onto paper multiplicatively to preserve texture
    col = mix(col, col * pencilText, mask);

    col = saturate(col);
    fragColor = vec4(col,1.0);
}

