#ifndef include_skybox_compose
#define include_skybox_compose

#include nebulapalette

const float kNebulaAmbientHaze = 0.12;

vec3 composeSkybox (
    vec3 dir,
    vec3 nebula,
    vec3 starDir,
    vec3 starColor,
    float intensity,
    float starIntensity,
    float nebulaStarTint,
    float nebulaStarHighlight,
    float nebulaStarRange,
    float nebulaChromaVariance)
{
  float density = nebulaDensity(nebula);
  float scatter = nebulaStarAngularWeight(dir, starDir, nebulaStarRange, 1.5);
  vec3 c = nebulaStarPalette(nebula, starColor, nebulaChromaVariance);
  c += nebulaAmbientHaze(nebula, starColor, kNebulaAmbientHaze);
  c = enrichNebulaPalette(c, density, nebulaStarTint);
  c *= intensity;
  c += nebulaStarScatterHighlight(nebula, starColor, scatter, nebulaStarHighlight) * intensity;
  c += centralStarGlow(dir, starDir, starColor) * starIntensity;
  return c;
}

#endif
