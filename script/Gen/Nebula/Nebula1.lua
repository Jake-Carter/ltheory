local Generator = require('Gen.Generator')
local NebulaPalette = require('Gen.NebulaPalette')

local function generateNebulaIFS (rng, res, starDir)
  Profiler.Begin('Nebula.Generate.IFS')
  local self = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/nebula')
  local ss = ShaderState.Create(shader)

  local starColor = NebulaPalette.pickStarColor(rng)

  local roughness = 0.65 + 0.05 * rng:getSign() * rng:getUniform()^2
  ss:setFloat('roughness', roughness)

  local seed = rng:getUniformRange(1, 1000)
  ss:setFloat('seed', seed)
  ss:setFloat('detailStrength', Config.gen.nebulaBakeDetail or 0.45)

  local lutDensity = Gen.DensityLUT(rng, 5, 0.38, 0.6)
  ss:setTex1D('lutDensity', lutDensity)

  self:generate(ss)
  self:genMipmap()
  self:setMagFilter(TexFilter.Linear)
  self:setMinFilter(TexFilter.LinearMipLinear)

  ss:free()
  lutDensity:free()
  Profiler.End()
  return self, starColor.r, starColor.g, starColor.b
end

Generator.Add('Nebula', 1.0, generateNebulaIFS)
