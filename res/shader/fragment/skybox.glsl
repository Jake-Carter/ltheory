#include fragment
#include deferred
#include gamma
#include color
#include fog
#include skybox_compose

#autovar samplerCube envMap
#autovar vec3 starDir
#autovar vec3 starColor
#autovar vec3 accentColor

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
uniform float nebulaEdgeHighlight;
uniform float nebulaEdgeOcclude;
uniform float nebulaEdgeScale;
uniform float nebulaHeatGlow;
uniform float nebulaHeatSaturation;
uniform float nebulaHeatStarBias;
uniform float nebulaHeatHue;
uniform float nebulaHeatVariation;

void main() {
  vec3 V = normalize(vertPos);
  vec3 nebula = textureCube(envMap, V).xyz;
  vec3 c = composeSkybox(
    V, nebula, envMap, starDir, starColor, accentColor,
    intensity, starIntensity,
    nebulaStarTint, nebulaStarHighlight, nebulaStarRange, nebulaChromaVariance,
    nebulaAccentStrength, nebulaAccentShadow, nebulaAccentRim,
    nebulaGradeContrast, nebulaGradeSaturation, nebulaHighlightSaturation,
    nebulaEdgeHighlight, nebulaEdgeOcclude, nebulaEdgeScale,
    nebulaHeatGlow, nebulaHeatSaturation, nebulaHeatStarBias, nebulaHeatHue,
    nebulaHeatVariation);

  gl_FragDepth = 1.0;

  setAlbedo(linear(c.xyz));
  setAlpha(1.0);
  setDepth();
  setNormal(-normalize(vertPos));
  setRoughness(0);
  setMaterial(Material_NoShade);
}
