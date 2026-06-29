local Generator = require('Gen.Generator')

local function generateNebula3 (rng, res, starDir)
  Profiler.Begin('Nebula.Generate.3')
  local self = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/nebula3')
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

  ss:setFloat('seed', rng:getUniformRange(1, 1000))

  self:generate(ss)
  self:genMipmap()
  self:setMagFilter(TexFilter.Linear)
  self:setMinFilter(TexFilter.LinearMipLinear)

  ss:free()
  Profiler.End()
  return self, starR, starG, starB
end

Generator.Add('Nebula', 0.35, generateNebula3)
