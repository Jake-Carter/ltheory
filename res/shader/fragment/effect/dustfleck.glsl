#include fragment
#include color
#include math
#include dustlighting

#autovar samplerCube envMap
#autovar samplerCube irMap
#autovar vec3 starDir
#autovar vec3 starColor

uniform vec2 size;
uniform float starIntensity;
uniform float nebulaGIIntensity;
uniform float nebulaChromaVariance;
uniform float scatterIntensity;

varying float wrapDist;

void main() {
  float dist = length(pos - eye);
  float alpha = exp(-pow2(2.0 * uv.x));
  alpha *= 0.1;
  alpha *= 1.0 - exp(-8.0 * uv.y);
  alpha *= 1.0 - exp(-8.0 * (1.0 - uv.y));
  alpha *= 1.0 - pow4(1.0 - uv.y);
  alpha *= exp(-4.0 * max(0.0, dist / 1024.0 - 0.8));
  alpha *= 1.0 - exp(-16.0 * max(0.0, dist / 1024.0 - 0.1));
  vec3 c = shadeDustFleck(
    eye, pos, starDir, starColor, envMap, irMap,
    starIntensity, nebulaGIIntensity, nebulaChromaVariance, scatterIntensity, 1.0 - uv.y);
  gl_FragColor = vec4(c * alpha, 1.0);
  FRAGMENT_CORRECT_DEPTH;
}
