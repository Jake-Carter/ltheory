#include fragment
#include deferred
#include gamma
#include color
#include fog
#include centralstar

#autovar samplerCube envMap
#autovar vec3 starDir

uniform float intensity;
uniform float starIntensity;

void main() {
  vec3 V = normalize(vertPos);
  vec3 c = textureCube(envMap, V).xyz * intensity;
  c += centralStarGlow(V, starDir, starColor) * starIntensity;

  gl_FragDepth = 1.0;

  setAlbedo(linear(c.xyz));
  setAlpha(1.0);
  setDepth();
  setNormal(-normalize(vertPos));
  setRoughness(0);
  setMaterial(Material_NoShade);
}
