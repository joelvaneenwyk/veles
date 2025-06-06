#version 330 core

// --- samplers & uniforms ---
uniform sampler3D tex_intensity;   // texture unit 0
uniform sampler3D tex_pos;         // texture unit 1
uniform float     gain;
uniform float     power;
uniform bool      palette;

// --- varyings ---
in  vec3 vPos;          // comes from vertex shader
out vec4 fragColor;     // single output needs no location

// --- palette helpers ---
vec3 get_color_a(float loc)
{
    return (loc < 0.5)
         ? vec3(1.0, 1.0, loc * 2.0)
         : vec3(1.0 - ((loc * 2.0) - 1.0), 1.0, 1.0);
}

vec3 get_color_b(float loc)
{
    if      (loc < 0.25) { float i = loc * 4.0;       return vec3(1.0,        i, 0.0); }
    else if (loc < 0.50) { float i = loc * 4.0 - 1.0; return vec3(1.0, 1.0,   i);     }
    else if (loc < 0.75) { float i = loc * 4.0 - 2.0; return vec3(1.0 - i, 1.0, 1.0); }
    else                 { float i = loc * 4.0 - 3.0; return vec3(0.0, 1.0 - i, 1.0); }
}

void main()
{
    vec3 texcoord = vPos + vec3(0.5);
    bool inBounds = all(lessThanEqual(texcoord, vec3(1.0))) &&
                    all(greaterThanEqual(texcoord, vec3(0.0)));

    float intensity = texture(tex_intensity, texcoord).r;
    float fpos      = texture(tex_pos,       texcoord).r;
    vec3  fcolor    = palette ? get_color_b(fpos) : get_color_a(fpos);

    intensity = clamp(pow(intensity, power) * pow(gain, 1.5), 0.0, 1.0);
    fragColor = inBounds ? vec4(fcolor, intensity) : vec4(0.0);
}
