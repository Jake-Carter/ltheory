#include fragment
#include gamma
#include texcube
#include skybox_compose

uniform float intensity;
uniform float starIntensity;
uniform float nebulaStarTint;
uniform float nebulaStarHighlight;
uniform float nebulaStarRange;

void main() {
  vec3 dir = cubeMapDir(uv);
  vec3 nebula = textureCube(envMap, dir).xyz;
  vec3 c = composeSkybox(
    dir, nebula, starDir, starColor,
    intensity, starIntensity,
    nebulaStarTint, nebulaStarHighlight, nebulaStarRange);
  gl_FragColor = vec4(c, 1.0);
}
