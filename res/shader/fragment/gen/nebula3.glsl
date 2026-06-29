#include fragment
#include color
#include math
#include noise
#include texcube

uniform float seed;

float bgDensity(vec3 p) {
  return 0.5 + 0.5 * fSmoothNoise(p * 4 + seed, 8, 2.0);
}

vec4 generate(vec3 dir) {
  vec3 c = vec3(0.0);
  float dense = bgDensity(dir);
  /* Central star is applied at runtime in skybox.glsl. */

  float d1 = 2.0 * frCellNoise(dir, seed + 1.0, 4, 2.0) - 1.0;
  float d2 = 2.0 * frCellNoise(dir, seed + 2.0, 4, 2.0) - 1.0;
  float d3 = 2.0 * frCellNoise(dir, seed + 3.0, 4, 2.0) - 1.0;
  dir += 0.1 * vec3(d1, d2, d3);
  float k = frCellNoise(dir, seed, 8, 2.0);
  float k2 = frCellNoise(2.0 * dir, seed + 4.0, 8, 2.0);
  k = sqrt(k * k2);
  vec3 c2 = 2.32 * pow4(1.0 / vec3(1.5, 1.2, 1.0));
  c += k * exp(-(k * c2));
  float kd = abs((k - k2) - 0.05);
  c *= 2.0 - exp(-4.0 * kd * c2);

  return vec4(c, avg(c));
}

void main() {
  vec3 dir = cubeMapDir(uv);
  gl_FragColor = generate(dir);
}
