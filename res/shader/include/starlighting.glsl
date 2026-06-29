#ifndef include_starlighting
#define include_starlighting

#include centralstar
#include color

/* Diffuse + tight core from the central star. */
vec3 starIrradiance(vec3 N, vec3 towardStar, vec3 color, float intensity) {
  float nl = max(0.0, dot(N, towardStar));
  vec3 lit = linear(color) * intensity;
  vec3 diff = lit * nl * 3.0;
  vec3 core = centralStarGlow(N, towardStar, lit) * 0.35;
  return diff + core;
}

/* Star light on reflective surfaces (diffuse facing + specular lobe). */
vec3 starReflectance(vec3 R, vec3 N, vec3 towardStar, vec3 color, float intensity, float facing) {
  vec3 lit = linear(color) * intensity;
  vec3 diff = lit * facing * 1.5;
  vec3 spec = centralStarGlow(R, towardStar, lit) * 0.6 * facing * facing;
  return diff + spec;
}

#endif
