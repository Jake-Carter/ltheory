#include fragment
#include math

uniform samplerCube src;

vec3 equirectDir (vec2 uv) {
  float theta = uv.x * TAU - PI;
  float phi = (0.5 - uv.y) * PI;
  float cp = cos(phi);
  return normalize(vec3(cp * cos(theta), sin(phi), cp * sin(theta)));
}

void main() {
  vec3 dir = equirectDir(uv);
  gl_FragColor = vec4(textureCube(src, dir).xyz, 1.0);
}
