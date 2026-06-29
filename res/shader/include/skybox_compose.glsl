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

  bool needEdge = edgeHighlight > 1e-5 || edgeOcclude > 1e-5;
  bool needHeat = heatGlow > 1e-5;
  if (needEdge || needHeat) {
    float d0 = nebulaDensityShape(rawD);
    float fineE, macroE, silhouette, detail, backlit, heatT;
    nebulaFetchEdgeData(
      envMap, dir, starDir, edgeScale, d0,
      fineE, macroE, silhouette, detail, backlit, heatT);

    if (needEdge) {
      vec3 edgeHi;
      float edgeOcc;
      nebulaStructureEdgesFromData(
        fineE, detail, density, accentColor,
        edgeHighlight, edgeOcclude, edgeHi, edgeOcc);
      c += edgeHi;
      c *= 1.0 - edgeOcc;
    }
    if (needHeat) {
      float edgeStrength = max(macroE, max(silhouette,
        fineE * nebulaSoftBand(max(detail, 0.0), -0.02, 0.14) * 0.38));
      c += nebulaIonizedEdgeGlowFromData(
        dir, nebula, density, starDir, starColor, accentColor,
        heatGlow, heatSaturation, heatStarBias, heatHue, heatVariation,
        edgeStrength, backlit, heatT);
    }
  }
  c = max(c, vec3(0.0));
  c *= intensity;
  c += nebulaStarScatterHighlight(nebula, starColor, scatter, nebulaStarHighlight) * intensity;
  c += centralStarGlow(dir, starDir, starColor) * starIntensity;
  return nebulaSanitizeColor(c);
}

#endif
