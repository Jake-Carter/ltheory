#ifndef include_skybox_compose
#define include_skybox_compose

#include nebulapalette

const float kNebulaAmbientHaze = 0.12;

vec3 composeSkybox (
    vec3 dir,
    vec3 nebula,
    samplerCube envMap,
    vec3 starDir,
    vec3 starColor,
    vec3 accentColor,
    float intensity,
    float starIntensity,
    float nebulaStarTint,
    float nebulaStarHighlight,
    float nebulaStarRange,
    float nebulaChromaVariance,
    float accentStrength,
    float accentShadow,
    float accentRim,
    float gradeContrast,
    float gradeSaturation,
    float highlightSaturation,
    float edgeHighlight,
    float edgeOcclude,
    float edgeScale,
    float heatGlow,
    float heatSaturation,
    float heatStarBias,
    float heatHue,
    float heatVariation)
{
  float rawD = lum(max(linear(nebula), vec3(0.0)));
  float density = gradeNebulaDensity(rawD, gradeContrast);
  float scatter = nebulaStarAngularWeight(dir, starDir, nebulaStarRange, 1.5);
  float accentSide = nebulaSoftBand(1.0 - scatter, 0.15, 0.95) * accentStrength;

  vec3 c = nebulaDualPalette(
    nebula, starColor, accentColor, density, nebulaChromaVariance, accentStrength);
  c += nebulaAccentVeil(
    accentColor, density, kNebulaAmbientHaze + accentShadow * 0.55, accentSide);
  c += nebulaFilamentRim(accentColor, density, accentRim);

  c = gradeNebulaPalette(
    c, density, accentColor, nebulaStarTint, gradeSaturation, highlightSaturation);
  vec3 edgeHi;
  float edgeOcc;
  nebulaStructureEdges(
    envMap, dir, density, starColor, accentColor,
    edgeHighlight, edgeOcclude, edgeScale, edgeHi, edgeOcc);
  c += edgeHi;
  c *= 1.0 - edgeOcc;
  c = max(c, vec3(0.0));
  c *= intensity;
  c += nebulaStarScatterHighlight(nebula, starColor, scatter, nebulaStarHighlight) * intensity;
  c += nebulaIonizedEdgeGlow(
    envMap, dir, nebula, density, starDir, starColor, accentColor,
    heatGlow, heatSaturation, heatStarBias, heatHue, edgeScale, heatVariation);
  c += centralStarGlow(dir, starDir, starColor) * starIntensity;
  return nebulaSanitizeColor(c);
}

#endif
