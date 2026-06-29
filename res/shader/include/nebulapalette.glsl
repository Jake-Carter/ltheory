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

/* Soft band 0→1 across [lo, hi] — avoids hard color borders from pow cliffs. */
float nebulaSoftBand (float x, float lo, float hi) {
  return smoothstep(lo, hi, saturate(x));
}

/* Split-tone density remap — gentler toe/shoulder to reduce banding. */
float gradeNebulaDensity (float raw, float contrast) {
  float d = nebulaDensityShape(max(raw, 0.0));
  if (contrast <= 1e-4) return d;
  float toe = mix(d, pow(d, 0.88), 0.45);
  float shoulder = mix(d, 1.0 - pow(max(1.0 - d, 0.0), 1.0 + contrast * 0.35), 0.45);
  return mix(d, mix(toe, shoulder, 0.5), contrast * 0.85);
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
  float spread = mix(0.18, 0.32, accentStrength);
  vec3 ratio = n / l;
  vec3 soft = mix(vec3(1.0), ratio, 0.65);
  vec3 variance = mix(vec3(1.0), clamp(soft, 1.0 - spread, 1.0 + spread), chromaVariance);
  return variance;
}

/* Star-anchored palette: baked density × star color × accent variance. */
vec3 nebulaStarPalette (vec3 baked, vec3 starColor, float chromaVariance) {
  vec3 n = max(linear(baked), vec3(0.0));
  float density = nebulaDensityShape(lum(n));
  vec3 star = linear(starColor);
  vec3 variance = nebulaStructuralVariance(n, chromaVariance, 0.0);
  return star * density * variance;
}

/* Dual palette: smooth star↔accent blend keyed on graded density. */
vec3 nebulaDualPalette (
    vec3 baked, vec3 starColor, vec3 accentColor,
    float density, float chromaVariance, float accentStrength)
{
  vec3 n = max(linear(baked), vec3(0.0));
  vec3 star = linear(starColor);
  vec3 accent = linear(accentColor);
  vec3 variance = nebulaStructuralVariance(n, chromaVariance, accentStrength);
  float accentMix = accentStrength * nebulaSoftBand(1.0 - density, 0.12, 0.88);
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

/* Split-tone grading — soft shadow hue pull, no hard chroma snap. */
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
    float hi = nebulaSoftBand(density, 0.35, 0.95);
    graded = mix(graded, oversaturate(max(graded, vec3(0.0)), highlightSaturation * 0.55), hi);
    vec3 hsl = toHSL(max(graded, vec3(0.0)));
    hsl.z = mix(hsl.z, min(1.0, hsl.z + highlightSaturation * 0.18 * hi), highlightSaturation * 0.75);
    graded = toRGB(hsl);
  }

  float shadow = nebulaSoftBand(1.0 - density, 0.05, 0.82);
  if (shadow > 1e-4) {
    vec3 accent = linear(accentColor);
    vec3 gradedChroma = graded / max(lum(graded), 1e-4);
    vec3 accChroma = accent / max(lum(accent), 1e-4);
    float pull = shadow * shadow * 0.28;
    vec3 target = normalize(mix(gradedChroma, accChroma, pull) + 1e-4);
    graded = mix(graded, target * lum(graded), pull);
  }

  return graded;
}

vec3 nebulaStarScatterHighlight (
    vec3 baked, vec3 starColor, float scatter, float intensity)
{
  return linear(starColor) * nebulaDensity(baked) * scatter * intensity;
}

/* Unified soft accent veil — one smooth term instead of stacked haze + shadow. */
vec3 nebulaAccentVeil (
    vec3 accentColor, float density, float amount, float angularBias)
{
  float shadowW = nebulaSoftBand(1.0 - density, 0.08, 0.78);
  float midW = nebulaSoftBand(density, 0.05, 0.55) * nebulaSoftBand(1.0 - density, 0.05, 0.65);
  float veil = amount * (0.35 * shadowW + 0.25 * midW) * (0.55 + 0.45 * angularBias);
  return linear(accentColor) * veil;
}

/* Soft filament rim — wide band, not a thin pow spike. */
vec3 nebulaFilamentRim (
    vec3 accentColor, float density, float amount)
{
  float rim = amount * nebulaSoftBand(density, 0.38, 0.92)
    * nebulaSoftBand(1.0 - density, 0.08, 0.62);
  return linear(accentColor) * rim * 0.45;
}

/* Faint star-tinted haze in all gas regions. */
vec3 nebulaAmbientHaze (vec3 baked, vec3 starColor, float amount) {
  float density = nebulaDensity(baked);
  return linear(starColor) * amount * pow(density, 0.65);
}

#endif
