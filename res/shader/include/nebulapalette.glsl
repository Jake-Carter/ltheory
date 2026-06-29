#ifndef include_nebulapalette
#define include_nebulapalette

#include color
#include gamma
#include centralstar

/* Remap baked density into a visible range (shadow lift + shoulder). */
float nebulaDensityShape (float d) {
  d = max(d, 0.0);
  return min(1.0, 1.0 - exp(-3.5 * d));
}

float nebulaDensity (vec3 baked) {
  return nebulaDensityShape(lum(max(linear(baked), vec3(0.0))));
}

/* Star-anchored palette: baked density structure × star color × accent variance. */
vec3 nebulaStarPalette (vec3 baked, vec3 starColor, float chromaVariance) {
  vec3 n = max(linear(baked), vec3(0.0));
  float density = nebulaDensityShape(lum(n));
  vec3 star = linear(starColor);
  float d = max(density, 1e-4);
  vec3 variance = clamp(n / max(lum(n), 1e-4), 0.75, 1.25);
  variance = mix(vec3(1.0), variance, chromaVariance);
  return star * density * variance;
}

/* Saturation and brightness lift (nebulaStarTint). */
vec3 enrichNebulaPalette (vec3 c, float density, float amount) {
  if (amount <= 1e-4) return c;
  vec3 hsl = toHSL(c);
  hsl.y = mix(hsl.y, min(1.0, hsl.y + amount * (0.18 + 0.55 * density)), amount);
  hsl.z = mix(hsl.z, min(1.0, hsl.z + amount * (0.06 + density * 0.38)), amount * 0.9);
  return toRGB(hsl);
}

vec3 nebulaStarScatterHighlight (
    vec3 baked, vec3 starColor, float scatter, float intensity)
{
  return linear(starColor) * nebulaDensity(baked) * scatter * intensity;
}

/* Faint star-tinted haze in all gas regions. */
vec3 nebulaAmbientHaze (vec3 baked, vec3 starColor, float amount) {
  float density = nebulaDensity(baked);
  return linear(starColor) * amount * pow(density, 0.65);
}

#endif
