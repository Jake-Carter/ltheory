local Generator = require('Gen.Generator')

local function generateNebulaIFS (rng, res, starDir)
  Profiler.Begin('Nebula.Generate.IFS')
  local self = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/nebula')
  local ss = ShaderState.Create(shader)

  local starR, starG, starB
  do -- Nebula color
    local h = rng:getUniform()
    local s = rng:getUniformRange(0.2, 0.8)
    local l = rng:getUniformRange(0.2, 0.8)
    local color = Color.FromHSL(h, s, l)
    starR, starG, starB = color.r, color.g, color.b
    ss:setFloat3('color', starR, starG, starB)
  end

  local roughness = 0.65 + 0.05 * rng:getSign() * rng:getUniform()^2
  ss:setFloat('roughness', roughness)

  local seed = rng:getUniformRange(1, 1000)
  ss:setFloat('seed', seed)

  local lutR = Gen.ColorLUT(rng, 5, 0.30, 0.6)
  local lutG = Gen.ColorLUT(rng, 5, 0.30, 0.6)
  local lutB = Gen.ColorLUT(rng, 5, 0.30, 0.6)
  ss:setTex1D('lutR', lutR)
  ss:setTex1D('lutG', lutG)
  ss:setTex1D('lutB', lutB)

  self:generate(ss)
  self:genMipmap()
  self:setMagFilter(TexFilter.Linear)
  self:setMinFilter(TexFilter.LinearMipLinear)

  ss:free()
  lutR:free()
  lutG:free()
  lutB:free()
  Profiler.End()
  return self, starR, starG, starB
end

Generator.Add('Nebula', 1.0, generateNebulaIFS)
