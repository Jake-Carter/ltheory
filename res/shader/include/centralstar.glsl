/* Central star bloom for skybox rendering (angular distance from starDir). */
vec3 centralStarGlow (vec3 dir, vec3 towardStar, vec3 color) {
  /* Dots between normalized directions may still be > 1 due to fp precision. */
  float d = max(0.0, 1.0 - dot(dir, towardStar));
  float dd = 0.0;
  dd += 8.0 * exp(-sqrt(4096.0 * d));
  dd += 4.0 * exp(-sqrt(sqrt(1024.0 * d)));
  return dd * color;
}
