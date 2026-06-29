#include fragment
#include gamma
#include math
#include noise
#include color

#autovar samplerCube irMap
uniform sampler2D texDust;
uniform float opacity;
uniform float alphaPower;
uniform float fadeWidth;

varying float wrapDist;

void main() {
  vec3 V = pos - eye;
  vec4 bg = textureCubeLod(irMap, V, 2.0);
  vec3 c = mix(vec3(0.2), mix(bg.xyz, 0.75 * sqrt(bg.xyz), 0.25), 0.8);
  float a = texture2D(texDust, 0.5 + 0.5 * uv).x;
  /* Fade by cloud center distance; per-fragment dist would cut large billboards. */
  a *= smoothstep(0.0, fadeWidth, wrapDist);
  a *= 1.0 - smoothstep(1.0 - fadeWidth, 1.0, wrapDist);
  a *= opacity;
  a = saturate(a);
  a = pow(a, alphaPower);
  gl_FragColor = vec4(linear(c), a);
  FRAGMENT_CORRECT_DEPTH;
}
