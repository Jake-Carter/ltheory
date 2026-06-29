#include fragment
#include color
#include gamma
#include math
#include noise
#include texcube

uniform vec3 color;
uniform float seed;

vec4 generate(vec3 dir) {
  float d1 = 2.0 * frCellNoise(dir, seed + 1.0, 4, 2.0) - 1.0;
  float d2 = 2.0 * frCellNoise(dir, seed + 2.0, 4, 2.0) - 1.0;
  float d3 = 2.0 * frCellNoise(dir, seed + 3.0, 4, 2.0) - 1.0;
  dir += 0.1 * vec3(d1, d2, d3);
  float k = frCellNoise(dir, seed, 8, 2.0);
  float k2 = frCellNoise(2.0 * dir, seed + 4.0, 8, 2.0);
  k = sqrt(k * k2);
  float absScale = 2.32 * pow4(1.0 / max(0.35, lum(linear(color))));
  float density = k * exp(-k * absScale);
  float kd = abs((k - k2) - 0.05);
  density *= 2.0 - exp(-5.5 * kd * absScale);
  density = min(1.0, 1.0 - exp(-3.0 * density));

  return vec4(vec3(density), density);
}

void main() {
  vec3 dir = cubeMapDir(uv);
  gl_FragColor = generate(dir);
}
