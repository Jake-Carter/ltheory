#include fragment
#include gamma
#include math
#include noise
#include color
#include dustlighting

#autovar samplerCube envMap
#autovar samplerCube irMap
#autovar vec3 starDir
#autovar vec3 starColor
#autovar vec3 accentColor

uniform sampler2D texDust;
uniform float opacity;
uniform float alphaPower;
uniform float fadeWidth;
uniform float starIntensity;
uniform float nebulaGIIntensity;
uniform float nebulaChromaVariance;
uniform float nebulaAccentStrength;
uniform float nebulaAccentShadow;
uniform float scatterIntensity;

varying float wrapDist;

void main() {
  vec3 scatter = shadeDustCloudScatter(
    eye, pos, starDir, starColor, accentColor, envMap, irMap,
    starIntensity, nebulaGIIntensity, nebulaChromaVariance,
    nebulaAccentStrength, nebulaAccentShadow, scatterIntensity);
  float a = texture2D(texDust, 0.5 + 0.5 * uv).x;
  a *= smoothstep(0.0, fadeWidth, wrapDist);
  a *= 1.0 - smoothstep(1.0 - fadeWidth, 1.0, wrapDist);
  a *= opacity;
  a = saturate(a);
  a = pow(a, alphaPower);
  gl_FragColor = vec4(scatter * a, 1.0);
  FRAGMENT_CORRECT_DEPTH;
}
