local Generator = require('Gen.Generator')
local NebulaPalette = require('Gen.NebulaPalette')

local function generateNebula3 (rng, res, starDir)
  Profiler.Begin('Nebula.Generate.3')
  local self = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/nebula3')
  local ss = ShaderState.Create(shader)

  local starColor = NebulaPalette.pickStarColor(rng)
  ss:setFloat3('color', starColor.r, starColor.g, starColor.b)
  ss:setFloat('seed', rng:getUniformRange(1, 1000))

  self:generate(ss)
  self:genMipmap()
  self:setMagFilter(TexFilter.Linear)
  self:setMinFilter(TexFilter.LinearMipLinear)

  ss:free()
  Profiler.End()
  return self, starColor.r, starColor.g, starColor.b
end

Generator.Add('Nebula', 0.35, generateNebula3)
