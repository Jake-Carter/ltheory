#include fragment
#include gamma
#include texcube
#include skybox_compose

uniform float intensity;
uniform float starIntensity;
uniform float nebulaStarTint;
uniform float nebulaStarHighlight;
uniform float nebulaStarRange;
uniform float nebulaChromaVariance;
uniform float nebulaAccentStrength;
uniform float nebulaAccentShadow;
uniform float nebulaAccentRim;
uniform float nebulaGradeContrast;
uniform float nebulaGradeSaturation;
uniform float nebulaHighlightSaturation;

void main() {
  vec3 dir = cubeMapDir(uv);
  vec3 nebula = textureCube(envMap, dir).xyz;
  vec3 c = composeSkybox(
    dir, nebula, starDir, starColor, accentColor,
    intensity, starIntensity,
    nebulaStarTint, nebulaStarHighlight, nebulaStarRange, nebulaChromaVariance,
    nebulaAccentStrength, nebulaAccentShadow, nebulaAccentRim,
    nebulaGradeContrast, nebulaGradeSaturation, nebulaHighlightSaturation);
  gl_FragColor = vec4(c, 1.0);
}
