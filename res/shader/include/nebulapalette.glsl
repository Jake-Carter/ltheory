#ifndef include_nebulapalette
#define include_nebulapalette

#include color
#include gamma
#include centralstar
#include noise

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

/* --- Spatial edge detail (compose-time, cubemap samples) ----------------- */

float nebulaCubemapDensity (samplerCube map, vec3 dir, float lod) {
  vec3 baked = max(linear(textureCubeLod(map, dir, lod).xyz), vec3(0.0));
  return nebulaDensityShape(lum(baked));
}

float nebulaSpatialEdgeAt (samplerCube map, vec3 dir, float eps) {
  vec3 up = abs(dir.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 t1 = normalize(cross(up, dir));
  vec3 t2 = cross(dir, t1);
  float d0 = nebulaCubemapDensity(map, dir, 0.0);
  float d1 = nebulaCubemapDensity(map, normalize(dir + eps * t1), 0.0);
  float d2 = nebulaCubemapDensity(map, normalize(dir + eps * t2), 0.0);
  float g = length(vec2(d1 - d0, d2 - d0));
  return g / (g + 0.065);
}

float nebulaSpatialEdge (samplerCube map, vec3 dir, float scale) {
  return nebulaSpatialEdgeAt(map, dir, 0.0035 * max(scale, 0.25));
}

/* Pillar-scale silhouette from blurred-vs-sharp density (macro backlighting). */
float nebulaMacroSilhouette (samplerCube map, vec3 dir) {
  float sharp = nebulaCubemapDensity(map, dir, 0.0);
  float blur = nebulaCubemapDensity(map, dir, 3.0);
  return nebulaSoftBand(abs(sharp - blur), 0.025, 0.28);
}

float nebulaUnsharpDetail (samplerCube map, vec3 dir) {
  return nebulaCubemapDensity(map, dir, 0.0) - nebulaCubemapDensity(map, dir, 1.75);
}

/* Star-facing ionization front — bright where density rises toward the star. */
float nebulaBacklitEdgeBoost (
    vec3 dir, vec3 starDir, samplerCube map, float eps)
{
  vec3 up = abs(dir.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 t1 = normalize(cross(up, dir));
  vec3 t2 = cross(dir, t1);
  float d0 = nebulaCubemapDensity(map, dir, 0.0);
  float d1 = nebulaCubemapDensity(map, normalize(dir + eps * t1), 0.0);
  float d2 = nebulaCubemapDensity(map, normalize(dir + eps * t2), 0.0);
  vec3 grad = t1 * (d1 - d0) + t2 * (d2 - d0);
  float gLen = length(grad);
  if (gLen < 1e-5) return 0.55;
  vec3 starTan = starDir - dir * dot(starDir, dir);
  float sl = length(starTan);
  if (sl < 1e-5) return 0.55;
  float facing = dot(grad / gLen, starTan / sl);
  return mix(0.42, 1.0, nebulaSoftBand(facing, -0.12, 0.52));
}

/* Combined fine + macro edge strength for rim effects. */
float nebulaCombinedEdge (
    samplerCube envMap, vec3 dir, float edgeScale, out float heatT)
{
  float fineE = nebulaSpatialEdgeAt(envMap, dir, 0.0035 * max(edgeScale, 0.25));
  float macroE = nebulaSpatialEdgeAt(envMap, dir, 0.014 * max(edgeScale, 0.25));
  float silhouette = nebulaMacroSilhouette(envMap, dir);

  float detail = max(nebulaUnsharpDetail(envMap, dir), 0.0);
  float fineWisp = fineE * nebulaSoftBand(detail, -0.02, 0.14);

  float edge = max(macroE, silhouette);
  edge = max(edge, fineWisp * 0.38);
  heatT = saturate(max(edge, macroE * 0.65 + silhouette * 0.85));
  return edge;
}

/* Fine filament rims (highlight) and cavity lanes (occlude) from gradient + unsharp. */
vec3 nebulaStructureEdges (
    samplerCube envMap, vec3 dir, float density,
    vec3 starColor, vec3 accentColor,
    float edgeHighlight, float edgeOcclude, float edgeScale)
{
  if (edgeHighlight <= 1e-5 && edgeOcclude <= 1e-5) return vec3(0.0);

  float spatial = nebulaSpatialEdge(envMap, dir, edgeScale);
  float detail = nebulaUnsharpDetail(envMap, dir);
  float edge = spatial * (0.6 + 0.4 * nebulaSoftBand(detail, -0.04, 0.12));

  float hiBand = nebulaSoftBand(density, 0.14, 0.66);
  float shadowBand = nebulaSoftBand(1.0 - density, 0.06, 0.55);

  vec3 highlight = linear(accentColor) * edgeHighlight * edge * hiBand
    * (0.55 + max(detail, 0.0) * 5.0);
  vec3 occlude = linear(starColor) * edgeOcclude * edge * shadowBand * 0.4;
  return highlight - occlude;
}

/* Warm HII emission chroma — star hue with optional shift toward magenta/red. */
vec3 nebulaHeatEmission (
    vec3 starColor, vec3 accentColor, float heatSaturation, float heatHue)
{
  vec3 star = max(linear(starColor), vec3(0.0));
  vec3 hsl = toHSL(star);
  hsl.x = fract(hsl.x + heatHue);
  hsl.y = mix(hsl.y, min(1.0, hsl.y + heatSaturation * 0.55 + 0.15), heatSaturation);
  hsl.z = mix(hsl.z, min(1.0, hsl.z + heatSaturation * 0.12), heatSaturation * 0.85);
  vec3 heat = toRGB(hsl);
  heat = mix(heat, linear(accentColor), heatSaturation * 0.15);
  return oversaturate(max(heat, vec3(0.0)), heatSaturation * 0.45);
}

/* white-hot core → orange → crimson (Mystic Mountain-style backlighting). */
vec3 nebulaHeatColorRamp (
    float t, vec3 starColor, vec3 accentColor,
    float heatSaturation, float heatHue)
{
  t = saturate(t);
  vec3 core = vec3(1.0, 0.97, 0.86);
  vec3 hot  = vec3(1.0, 0.58, 0.14);
  vec3 warm = vec3(0.90, 0.20, 0.06);
  vec3 deep = vec3(0.48, 0.05, 0.03);
  vec3 c = t > 0.70 ? mix(hot, core, (t - 0.70) / 0.30)
        : t > 0.36 ? mix(warm, hot, (t - 0.36) / 0.34)
        : mix(deep, warm, t / 0.36);
  vec3 starTint = nebulaHeatEmission(starColor, accentColor, heatSaturation * 0.3, heatHue);
  c = mix(c, c * (starTint / max(lum(starTint), 1e-4)), heatSaturation * 0.35);
  return oversaturate(max(c, vec3(0.0)), heatSaturation * 0.4);
}

/* Patchy macro/meso/fine breakup + sparse hot flares near the star. */
void nebulaHeatSpatialVariation (
    vec3 dir, vec3 baked, vec3 starDir, float scatter, float variation,
    out float intensityMult, out float heatTBias, out float hotspot)
{
  intensityMult = 1.0;
  heatTBias = 0.0;
  hotspot = 0.0;
  if (variation <= 1e-5) return;

  vec3 n = max(linear(baked), vec3(0.0));
  float l = max(lum(n), 1e-4);
  float seed = l * 13.7 + n.g * 5.3 + n.b * 2.1;
  vec3 p = dir * 5.0 + seed;

  float macro = fSmoothNoise(p, 4, 2.05);
  float meso = frCellNoise(p * 1.8 + 0.31, seed + 7.0, 4, 2.15);
  float fine = fSmoothNoise(p * 11.0, 3, 2.3);

  /* Large quiet vs active regions — not every edge glows equally. */
  float patch = mix(0.12, 1.0, nebulaSoftBand(macro, 0.16, 0.80));
  float breakup = mix(0.38, 1.0, meso);
  float sparkle = mix(0.68, 1.48, fine);
  intensityMult = mix(1.0, patch * breakup * sparkle, variation);

  /* Sparse ionized flares — tips/ridges that "catch fire" near the star. */
  float cell = frCellNoise(dir * 8.5 + starDir * 1.5, seed + 23.0, 5, 2.0);
  hotspot = variation * nebulaSoftBand(cell, 0.66, 0.93) * scatter * scatter;

  /* Local color temperature: meso highs run hotter (whiter), lows deeper crimson. */
  heatTBias = variation * (meso - 0.5) * 0.62;
}

/* Ionized edge glow — macro backlit pillars + fine wisps, emissive at compose. */
vec3 nebulaIonizedEdgeGlow (
    samplerCube envMap, vec3 dir, vec3 baked, float density,
    vec3 starDir, vec3 starColor, vec3 accentColor,
    float heatIntensity, float heatSaturation, float heatStarBias, float heatHue,
    float edgeScale, float heatVariation)
{
  if (heatIntensity <= 1e-5) return vec3(0.0);

  float heatT;
  float edgeStrength = nebulaCombinedEdge(envMap, dir, edgeScale, heatT);

  float ionFront = nebulaSoftBand(density, 0.10, 0.84)
    * nebulaSoftBand(1.0 - density, 0.02, 0.68);
  float backlit = nebulaBacklitEdgeBoost(
    dir, starDir, envMap, 0.014 * max(edgeScale, 0.25));
  float scatter = nebulaStarAngularWeight(dir, starDir, heatStarBias, 1.2);

  float intensityMult, heatTBias, hotspot;
  nebulaHeatSpatialVariation(
    dir, baked, starDir, scatter, heatVariation,
    intensityMult, heatTBias, hotspot);

  float mask = edgeStrength * ionFront * backlit * mix(0.48, 1.0, scatter);
  mask *= intensityMult;

  heatT = saturate(heatT * (0.55 + mask * 1.8) + heatTBias + hotspot * 0.42);

  float localSat = heatSaturation * mix(0.75, 1.35, intensityMult);
  vec3 heat = nebulaHeatColorRamp(
    heatT, starColor, accentColor, localSat, heatHue);

  vec3 emissive = heat * mask * heatIntensity;
  emissive += vec3(1.0, 0.94, 0.80) * hotspot * mask * heatIntensity * 0.62;
  return emissive;
}

#endif
