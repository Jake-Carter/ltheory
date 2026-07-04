#include filter
#include color
#include math
#include gamma
#include noise
#include bezier

uniform int hdrOut;

const float b = 1.25;
const float k = 2.30;

const float kVignetteStrength = 0.25;
const float kVignetteHardness = 32.0;

#define HDR 0
#define COLOR_GRADING 1
#define DESAT 1
#define VIGNETTE 1

void main() {
  vec4 cc = texture2D(src, uv);
  vec3 c = cc.xyz;
  /* Clamp to >= 0 before any pow()/gamma(). A negative HDR channel (produced by
   * a downstream additive/lighting pass) would make pow(c, ...) return NaN,
   * which renders as isolated black speckles in otherwise bright regions. */
  c = max(c, vec3(0.0));
  c = gamma(c);

  #if VIGNETTE
    /* NOTE : Applying vignette *before* tonemap allows HDR color to leak into
              the vignette, which is a nice touch. */

    /* Vignetting. */ {
      vec2 uvp = vec2(1.0, 1.0) - 2.0 * abs(vec2(0.5, 0.5) - uv);
      c *= 1.0 - kVignetteStrength * exp(-kVignetteHardness * uvp.x);
      c *= 1.0 - kVignetteStrength * exp(-kVignetteHardness * uvp.y);
    }
  #endif
 
  #if HDR
    c /= pow(lum(c), mix(0.25, 0.0, lum(c)));
  #endif

  /* Expmap with contrast correction. */ {
    #if 0
      c = saturate(c);
    #else
      c = 1.0 - exp(-k * pow(c, 1.25 + c));
    #endif
  }

  #if COLOR_GRADING
    /* Bezier grading. Control points are the screen-center (uv = 0.5) values
       of the old screenspace-varying grade; per-channel spread must stay
       uniform across the frame, else channels shape differently top-vs-bottom
       and produce a view-dependent saturation gradient on the skybox. */ {
      c = beziernorm3(c,
        vec3(0.25, 0.25, 0.275),
        vec3(0.40, 0.40, 0.50),
        vec3(0.90, 0.80, 0.60)
      );
    }
  #endif

  #if DESAT
    /* Desaturate as luminance -> 1 for 'more realistic' highlights.
     *
     * This mixes toward luminance-grey directly instead of the old
     * toHSL()/toRGB() round-trip. That round-trip computed HSL saturation as
     * s = (M - m) / (2 - (M + m)); for the near-white, faintly-tinted pixels
     * that dominate a blown-out nebula, (2 - (M + m)) collapses toward zero (and
     * can flip sign under float rounding when a channel sits at ~1.0), yielding
     * an out-of-range saturation that toRGB() turned into negative/black. That
     * produced isolated black speckles scattered through the brightest gas. The
     * luminance mix below has no division and no round-trip, so it is stable. */
    float desatL = lum(c);
    c = mix(c, vec3(desatL), pow4(saturate(desatL)));
  #endif

  #if HDR
    c = mix(c, vec3(lum(c)), lum(c));
  #endif

  /* Color dither & clamp */ {
    c -= (2.0 * noise3(noise(uv * 16.0)) - vec3(1.0)) / 256.0;
    c = min(vec3(1.0), max(vec3(0.0), c));
  }

  gl_FragColor = vec4(c, cc.w);
}
