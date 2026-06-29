#include fragment
#include color
#include deferred
#include gamma
#include math
#include starlighting

#autovar samplerCube irMap
#autovar vec3 eye
#autovar vec3 starDir
#autovar vec3 starColor

varying vec3 worldOrigin;
varying vec3 worldDir;

uniform float starIntensity;
uniform float nebulaGIIntensity;
uniform vec3 lightColor;
uniform vec3 lightPos;

uniform sampler2D texNormalMat;
uniform sampler2D texDepth;

float roughnessToLOD (float r) {
  return 8.0 * (pow(2.0, r) - 1.0);
}

void main () {
  vec4 normalMat = texture2D(texNormalMat, uv);
  float depth = texture2D(texDepth, uv).x;
  vec3 N = decodeNormal(normalMat.xy);
  float rough = normalMat.z;
  float mat = normalMat.w;
  vec3 pos = worldOrigin + depth * normalize(worldDir);
  vec3 V = normalize(pos - eye);
  vec3 R = normalize(reflect(V, N));

  vec3 light = vec3(0.0);

  if (mat == Material_Diffuse) {
    light += linear(textureCubeLod(irMap, N, 8.0).xyz) * nebulaGIIntensity;
    light += starIrradiance(N, starDir, starColor, starIntensity);
  }

  else if (mat == Material_Metal) {
    float facing = saturate(dot(N, starDir));
    float reflWeight = facing * facing;
    vec3 envDiff = linear(textureCubeLod(irMap, N, 8.0).xyz);
    #ifdef HIGHQ
      vec3 envRefl = linear(textureCubeLod(irMap, R, roughnessToLOD(rough)).xyz);
    #else
      vec3 envRefl = linear(textureCube(envMap, R).xyz);
    #endif
    light += mix(envDiff, envRefl, reflWeight) * nebulaGIIntensity;
    light += starReflectance(R, N, starDir, starColor, starIntensity, facing);
  }

  else if (mat == Material_NoShade) {
    light += vec3(1.0);
  }

  gl_FragData[0] = vec4(light, 1.0);
}
