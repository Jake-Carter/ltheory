local function GenerateDensityLUT (rng, iterations, variation, rough)
  local self = Tex1D.Create(256, TexFormat.RGB8)
  self:setMagFilter(TexFilter.Linear);
  self:setMinFilter(TexFilter.Linear);

  local cPoints = List()
    :add(Vec3f(0, 0, 0))
    :add(Vec3f(1, 1, 1))
  local v = variation
  for i = 1, iterations do
    local newPoints = List()
    for j = 1, #cPoints - 1 do
      local p0 = cPoints[j + 0]
      local p1 = cPoints[j + 1]
      local pn = p0:lerp(p1, 0.5)
      local g = pn.x + v * rng:getGaussian()
      g = Math.Clamp(g, 0.0, 1.0)
      pn.x = g
      pn.y = g
      pn.z = g
      newPoints:add(p0)
      newPoints:add(pn)
    end

    newPoints:add(cPoints[#cPoints])
    cPoints = newPoints
    v = v * rough
  end

  local points = List()
  for i = 0, 255 do
    local t = i / 255
    local interp = cPoints:clone()
    while #interp > 1 do
      local newInterp = List()
      for j = 1, #interp - 1 do
        local p0 = interp[j + 0]
        local p1 = interp[j + 1]
        newInterp:add(p0:lerp(p1, t))
      end
      interp = newInterp
    end
    points:add(interp[1])
  end

  do
    local bytes = Bytes.Create(256 * 3 * 4)
    for i = 1, #points do
      local point = points[i]
      bytes:writeF32(point.x)
      bytes:writeF32(point.y)
      bytes:writeF32(point.z)
    end

    self:setDataBytes(bytes, PixelFormat.RGB, DataFormat.Float)
    bytes:free()
  end

  return self
end

return GenerateDensityLUT
