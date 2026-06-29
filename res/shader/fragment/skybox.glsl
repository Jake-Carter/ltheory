#include fragment
#include deferred
#include gamma
#include color
#include fog
#include skybox_compose

#autovar samplerCube envMap
#autovar vec3 starDir

uniform float intensity;
uniform float starIntensity;
uniform float nebulaStarTint;
uniform float nebulaStarHighlight;
uniform float nebulaStarRange;
uniform float nebulaChromaVariance;

void main() {
  vec3 V = normalize(vertPos);
  vec3 nebula = textureCube(envMap, V).xyz;
  vec3 c = composeSkybox(
    V, nebula, starDir, starColor,
    intensity, starIntensity,
    nebulaStarTint, nebulaStarHighlight, nebulaStarRange, nebulaChromaVariance);

  gl_FragDepth = 1.0;

  setAlbedo(linear(c.xyz));
  setAlpha(1.0);
  setDepth();
  setNormal(-normalize(vertPos));
  setRoughness(0);
  setMaterial(Material_NoShade);
}
