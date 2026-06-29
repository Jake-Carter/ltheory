#ifndef include_skybox_compose
#define include_skybox_compose

#include centralstar

vec3 composeSkybox (
    vec3 dir,
    vec3 nebula,
    vec3 starDir,
    vec3 starColor,
    float intensity,
    float starIntensity,
    float nebulaStarTint,
    float nebulaStarHighlight,
    float nebulaStarRange)
{
  vec3 c = harmonizeNebulaWithStar(nebula, dir, starDir, starColor, nebulaStarTint, nebulaStarRange);
  c *= intensity;
  c += nebulaStarIllumination(dir, starDir, starColor, nebula, nebulaStarHighlight, nebulaStarRange) * intensity;
  c += centralStarGlow(dir, starDir, starColor) * starIntensity;
  return c;
}

#endif
