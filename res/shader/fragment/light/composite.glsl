#include fragment
#include deferred
#include gamma

uniform sampler2D texAlbedo;
uniform sampler2D texDepth;
uniform sampler2D texLighting;

void main () {
  vec3 albedo = texture2D(texAlbedo, uv).xyz;
  vec3 light = texture2D(texLighting, uv).xyz;
  gl_FragData[0] = vec4(albedo * light, 1.0);
}
