#version 330 core

// --- attributes & varyings ---
in  vec3 position;
out vec3 vPos;          // passed to fragment shader

// --- uniforms ---
uniform float depth;
uniform mat4  view;

void main()
{
    gl_Position = vec4(position, 1.0);

    vec3 texcoords = vec3(position.xy, depth * 2.0 - 1.0);
    vec4 world     = view * vec4(texcoords, 1.0);

    vPos = world.xyz / world.w;  // perspective divide
}
