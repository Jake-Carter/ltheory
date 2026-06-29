#ifndef include_skybox_compose
#define include_skybox_compose

#include nebulapalette

const float kNebulaAmbientHaze = 0.12;

vec3 composeSkybox (
    vec3 dir,
    vec3 nebula,
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
    float highlightSaturation)
{
  float rawD = lum(max(linear(nebula), vec3(0.0)));
  float density = gradeNebulaDensity(rawD, gradeContrast);
  float scatter = nebulaStarAngularWeight(dir, starDir, nebulaStarRange, 1.5);
  float accentSide = (1.0 - scatter) * accentStrength;

  vec3 c = nebulaDualPalette(
    nebula, starColor, accentColor, density, nebulaChromaVariance, accentStrength);
  c += nebulaAmbientHazeAccent(
    nebula, accentColor, kNebulaAmbientHaze * (1.0 + accentSide * 0.45), accentShadow);
  c += nebulaShadowAccent(nebula, accentColor, accentShadow * (0.45 + accentSide * 0.55));
  c += nebulaFilamentRim(nebula, accentColor, density, accentRim);

  c = gradeNebulaPalette(
    c, density, accentColor, nebulaStarTint, gradeSaturation, highlightSaturation);
  c *= intensity;
  c += nebulaStarScatterHighlight(nebula, starColor, scatter, nebulaStarHighlight) * intensity;
  c += centralStarGlow(dir, starDir, starColor) * starIntensity;
  return c;
}

#endif
