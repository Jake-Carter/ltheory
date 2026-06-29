local NebulaPalette = {}

function NebulaPalette.pickStarColor (rng)
  local kelvin = Math.Lerp(3200, 11000, rng:getUniform())
  return Color.FromTemperature(kelvin, 2.0)
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
