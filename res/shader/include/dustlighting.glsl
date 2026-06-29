#ifndef include_dustlighting
#define include_dustlighting

#include nebulapalette

/* Forward-scatter lobe (Mie-ish) toward the central star. */
float dustForwardScatter (float cosTheta, float sharpness) {
  float g = mix(0.55, 0.82, sharpness);
  float denom = 1.0 + g * g - 2.0 * g * cosTheta;
  return (1.0 - g * g) / (4.0 * 3.14159265 * pow(max(denom, 1e-4), 1.5));
}

/* Blend Mie forward scatter with a uniform lobe so dust brightness does not
 * spike when the camera faces the central star. anisotropy: 0 = uniform. */
float dustScatterPhase (float cosTheta, float anisotropy) {
  float forward = dustForwardScatter(cosTheta, 0.45);
  const float isotropic = 0.11;
  return mix(isotropic, forward, anisotropy);
}

vec3 nebulaPaletteSample (
    vec3 dir, samplerCube map,
    vec3 starColor, vec3 accentColor,
    float chromaVariance, float accentStrength, float accentShadow, float lod)
{
  vec3 baked = textureCubeLod(map, dir, lod).xyz;
  float density = nebulaDensity(baked);
  vec3 c = nebulaDualPalette(
    baked, starColor, accentColor, density, chromaVariance, accentStrength);
  c += nebulaAccentVeil(accentColor, density, 0.12 + accentShadow * 0.35, accentStrength);
  return c;
}

/* Emissive scatter — lit by star + skybox palette, adds light instead of blocking it. */
vec3 shadeDustCloudScatter (
    vec3 eye, vec3 pos, vec3 starDir, vec3 starColor, vec3 accentColor,
    samplerCube envMap, samplerCube irMap,
    float starIntensity, float nebulaGIIntensity, float chromaVariance,
    float accentStrength, float accentShadow,
    float scatterIntensity)
{
  vec3 V = pos - eye;
  vec3 Vn = normalize(V);
  vec3 star = linear(starColor);
  vec3 baked = textureCubeLod(envMap, Vn, 2.0).xyz;
  float density = nebulaDensity(baked);
  float gas = 0.3 + 0.7 * density;

  vec3 scatter = nebulaPaletteSample(
    Vn, envMap, starColor, accentColor, chromaVariance, accentStrength, accentShadow, 2.5)
    * nebulaGIIntensity * 1.4 * gas;
  scatter += linear(textureCubeLod(irMap, Vn, 4.0).xyz) * nebulaGIIntensity * 0.55 * gas;

  float phase = dustScatterPhase(dot(Vn, starDir), 0.12);
  scatter += star * starIntensity * phase * 1.1 * gas;

  scatter = mix(scatter, scatter * vec3(1.06, 0.96, 0.86), 0.35);
  return scatter * scatterIntensity;
}

vec3 shadeDustFleck (
    vec3 eye, vec3 pos, vec3 starDir, vec3 starColor, vec3 accentColor,
    samplerCube envMap, samplerCube irMap,
    float starIntensity, float nebulaGIIntensity, float chromaVariance,
    float accentStrength, float accentShadow,
    float scatterIntensity, float streakT)
{
  vec3 Vn = normalize(pos - eye);
  vec3 star = linear(starColor);
  float cosTheta = dot(Vn, starDir);
  float phase = dustScatterPhase(cosTheta, 0.25);

  vec3 scatter = star * starIntensity * (phase * 1.2 + 0.04);
  scatter += star * streakT * starIntensity * 0.25 * saturate(cosTheta * 0.5 + 0.5);
  scatter += nebulaPaletteSample(
    Vn, envMap, starColor, accentColor, chromaVariance, accentStrength, accentShadow, 3.0)
    * nebulaGIIntensity * 0.35;
  scatter += linear(textureCubeLod(irMap, Vn, 4.0).xyz) * nebulaGIIntensity * 0.25;
  scatter = mix(scatter, scatter * vec3(1.04, 0.95, 0.88), 0.3);
  return scatter * scatterIntensity;
}

#endif
