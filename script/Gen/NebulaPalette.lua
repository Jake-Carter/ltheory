local NebulaPalette = {}

function NebulaPalette.pickStarColor (rng)
  local kelvin = Math.Lerp(3200, 11000, rng:getUniform())
  return Color.FromTemperature(kelvin, 2.0)
end

local function rgbToHSL (r, g, b)
  local M = math.max(r, g, b)
  local m = math.min(r, g, b)
  local l = (M + m) * 0.5
  if M == m then return 0, 0, l end
  local d = M - m
  local s = l > 0.5 and d / (2 - M - m) or d / (M + m)
  local h
  if M == r then h = (g - b) / d + (g < b and 6 or 0)
  elseif M == g then h = (b - r) / d + 2
  else h = (r - g) / d + 4 end
  return h / 6, s, l
end

function NebulaPalette.pickAccentColor (rng, starColor, hueOffset)
  hueOffset = hueOffset or 0.5
  local h, s, l = rgbToHSL(starColor.r, starColor.g, starColor.b)
  local jitter = (rng:getUniform() - 0.5) * (30.0 / 360.0)
  h = (h + hueOffset + jitter) % 1.0
  s = math.min(1.0, s * 1.12 + 0.10)
  return Color.FromHSL(h, s, l)
end

function NebulaPalette.emissionColor (rng, starColor, variance)
  variance = variance or 0.18
  local kelvin = Math.Lerp(3200, 11000, rng:getUniform())
  local accent = Color.FromTemperature(kelvin, 2.5):toVec3()
  local base = starColor:toVec3()
  local C = base:lerp(accent, variance):normalize():scale(1.0 + rng:getExp())
  return C
end

return NebulaPalette
