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

/* Split-tone density remap — toe + shoulder for filament/haze separation. */
float gradeNebulaDensity (float raw, float contrast) {
  float d = nebulaDensityShape(max(raw, 0.0));
  if (contrast <= 1e-4) return d;
  float toe = pow(d, 0.82);
  float shoulder = 1.0 - pow(max(1.0 - d, 0.0), 1.0 + contrast * 0.55);
  return mix(d, mix(toe, shoulder, 0.55), contrast);
}

/* Rotate star hue in HSL (0.5 = complement, 0.33 = split-complement). */
vec3 nebulaAccentFromStar (vec3 starColor, float hueOffset) {
  vec3 hsl = toHSL(max(linear(starColor), vec3(0.0)));
  hsl.x = fract(hsl.x + hueOffset);
  return max(toRGB(hsl), vec3(0.0));
}

vec3 nebulaStructuralVariance (
    vec3 n, float chromaVariance, float accentStrength)
{
  float l = max(lum(n), 1e-4);
  float spread = mix(0.25, 0.40, accentStrength);
  vec3 variance = clamp(n / l, 1.0 - spread, 1.0 + spread);
  return mix(vec3(1.0), variance, chromaVariance);
}

/* Star-anchored palette: baked density × star color × accent variance. */
vec3 nebulaStarPalette (vec3 baked, vec3 starColor, float chromaVariance) {
  vec3 n = max(linear(baked), vec3(0.0));
  float density = nebulaDensityShape(lum(n));
  vec3 star = linear(starColor);
  vec3 variance = nebulaStructuralVariance(n, chromaVariance, 0.0);
  return star * density * variance;
}

/* Dual palette: star in filaments, accent in haze/shadow lanes. */
vec3 nebulaDualPalette (
    vec3 baked, vec3 starColor, vec3 accentColor,
    float density, float chromaVariance, float accentStrength)
{
  vec3 n = max(linear(baked), vec3(0.0));
  vec3 star = linear(starColor);
  vec3 accent = linear(accentColor);
  vec3 variance = nebulaStructuralVariance(n, chromaVariance, accentStrength);
  float accentMix = accentStrength * pow(1.0 - density, 1.35);
  vec3 hue = mix(star, accent, accentMix);
  return hue * density * variance;
}

/* Saturation and brightness lift (nebulaStarTint). */
vec3 enrichNebulaPalette (vec3 c, float density, float amount) {
  if (amount <= 1e-4) return c;
  vec3 hsl = toHSL(c);
  hsl.y = mix(hsl.y, min(1.0, hsl.y + amount * (0.18 + 0.55 * density)), amount);
  hsl.z = mix(hsl.z, min(1.0, hsl.z + amount * (0.06 + density * 0.38)), amount * 0.9);
  return toRGB(hsl);
}

/* Split-tone grading: shadow accent hue, highlight saturation. */
vec3 gradeNebulaPalette (
    vec3 c, float density, vec3 accentColor,
    float tintAmount, float gradeSaturation, float highlightSaturation)
{
  vec3 graded = enrichNebulaPalette(c, density, tintAmount);

  if (gradeSaturation > 1e-4) {
    vec3 hsl = toHSL(max(graded, vec3(0.0)));
    hsl.y = mix(hsl.y, min(1.0, hsl.y + gradeSaturation * 0.35), gradeSaturation);
    graded = toRGB(hsl);
  }

  if (highlightSaturation > 1e-4) {
    float hi = pow(density, 1.4);
    graded = mix(graded, oversaturate(max(graded, vec3(0.0)), highlightSaturation * 0.65), hi);
    vec3 hsl = toHSL(max(graded, vec3(0.0)));
    hsl.z = mix(hsl.z, min(1.0, hsl.z + highlightSaturation * 0.22 * hi), highlightSaturation * 0.85);
    graded = toRGB(hsl);
  }

  float shadow = pow(1.0 - density, 1.5);
  if (shadow > 1e-4) {
    vec3 accent = linear(accentColor);
    vec3 gradedChroma = graded / max(lum(graded), 1e-4);
    vec3 accChroma = accent / max(lum(accent), 1e-4);
    vec3 target = normalize(mix(gradedChroma, accChroma, shadow * 0.45) + 1e-4);
    graded = mix(graded, target * lum(graded), shadow * 0.35);
  }

  return graded;
}

vec3 nebulaStarScatterHighlight (
    vec3 baked, vec3 starColor, float scatter, float intensity)
{
  return linear(starColor) * nebulaDensity(baked) * scatter * intensity;
}

/* Accent-tinted haze in gas regions (shadow-weighted). */
vec3 nebulaAmbientHazeAccent (
    vec3 baked, vec3 accentColor, float amount, float shadowWeight)
{
  float density = nebulaDensity(baked);
  float shadow = pow(1.0 - density, 1.2) * shadowWeight;
  return linear(accentColor) * amount * (0.35 * pow(density, 0.65) + shadow);
}

/* Faint star-tinted haze in all gas regions. */
vec3 nebulaAmbientHaze (vec3 baked, vec3 starColor, float amount) {
  float density = nebulaDensity(baked);
  return linear(starColor) * amount * pow(density, 0.65);
}

/* Shadow lanes — low-density accent fill. */
vec3 nebulaShadowAccent (vec3 baked, vec3 accentColor, float amount) {
  float density = nebulaDensity(baked);
  return linear(accentColor) * amount * pow(1.0 - density, 1.8);
}

/* Split-complement rim on high-density filaments. */
vec3 nebulaFilamentRim (
    vec3 baked, vec3 accentColor, float density, float amount)
{
  float rim = amount * pow(density, 0.65) * pow(max(1.0 - density, 0.0), 2.5);
  return linear(accentColor) * rim * 0.85;
}

#endif
