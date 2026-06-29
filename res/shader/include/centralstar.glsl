#include math
#include color

/* Central star bloom for skybox rendering (angular distance from starDir). */
vec3 centralStarGlow (vec3 dir, vec3 towardStar, vec3 color) {
  /* Dots between normalized directions may still be > 1 due to fp precision. */
  float d = max(0.0, 1.0 - dot(dir, towardStar));
  float dd = 0.0;
  dd += 8.0 * exp(-sqrt(4096.0 * d));
  dd += 4.0 * exp(-sqrt(sqrt(1024.0 * d)));
  return dd * color;
}

/*
 * Angular weight for star/nebula coupling.
 * range = 1.0 => full skybox (uniform weight).
 * range < 1.0 => tighter toward starDir; range > 1.0 stays full sky.
 */
float nebulaStarAngularWeight (vec3 dir, vec3 towardStar, float range, float power) {
  float r = max(0.01, range);
  float facing = saturate(dot(dir, towardStar));
  float tight = pow(facing, max(0.35, power / r)) * (0.25 + 0.75 * facing);
  float coverage = saturate(r);
  return mix(tight, 1.0, coverage);
}

/* Broad star-lit emission on nebula gas (wider falloff than centralStarGlow). */
vec3 nebulaStarIllumination (
    vec3 dir, vec3 towardStar, vec3 starColor, vec3 nebula, float intensity, float range)
{
  float scatter = nebulaStarAngularWeight(dir, towardStar, range, 1.5);
  /* Multiply into nebula color so edges follow gas density, not a hard lum mask. */
  vec3 n = max(linear(nebula), vec3(0.0));
  return linear(starColor) * scatter * n * intensity;
}

/* Pull nebula chroma toward the star near starDir for color harmony. */
vec3 harmonizeNebulaWithStar (
    vec3 nebula, vec3 dir, vec3 towardStar, vec3 starColor, float amount, float range)
{
  float w = amount * nebulaStarAngularWeight(dir, towardStar, range, 1.25);
  vec3 n = linear(nebula);
  vec3 tint = linear(starColor);
  float tl = max(1e-4, avg(tint));
  vec3 harmonized = n * (tint / tl);
  return mix(n, harmonized, saturate(w));
}
