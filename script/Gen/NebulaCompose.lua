local GenUtil = require('Gen.GenUtil')

local NebulaCompose = {}

function NebulaCompose.skyboxParams (overrides, nebula)
  overrides = overrides or {}
  local sky = overrides.nebulaSkyIntensity
  if not sky and nebula and nebula.skyIntensity then sky = nebula.skyIntensity end
  if not sky then sky = GenUtil.pickScalar(Config.gen.nebulaSkyIntensity, nil, 0.18) end

  local star = overrides.centralStarIntensity
  if not star and nebula and nebula.starIntensity then star = nebula.starIntensity end
  if not star then star = GenUtil.pickScalar(Config.gen.centralStarIntensity, nil, 0.5) end

  return {
    intensity           = sky,
    starIntensity       = star,
    nebulaStarTint      = overrides.nebulaStarTint or Config.gen.nebulaStarTint or 0.4,
    nebulaStarHighlight = overrides.nebulaStarHighlight or Config.gen.nebulaStarHighlight or 0.6,
    nebulaStarRange     = overrides.nebulaStarRange or Config.gen.nebulaStarRange or 1.0,
    nebulaChromaVariance = overrides.nebulaChromaVariance or Config.gen.nebulaChromaVariance or 0.2,
    nebulaAccentStrength = overrides.nebulaAccentStrength or Config.gen.nebulaAccentStrength or 0.4,
    nebulaAccentShadow   = overrides.nebulaAccentShadow or Config.gen.nebulaAccentShadow or 0.35,
    nebulaAccentRim      = overrides.nebulaAccentRim or Config.gen.nebulaAccentRim or 0.25,
    nebulaEdgeHighlight  = overrides.nebulaEdgeHighlight or Config.gen.nebulaEdgeHighlight or 0.28,
    nebulaEdgeOcclude    = overrides.nebulaEdgeOcclude or Config.gen.nebulaEdgeOcclude or 0.15,
    nebulaEdgeScale      = overrides.nebulaEdgeScale or Config.gen.nebulaEdgeScale or 1.0,
    nebulaHeatGlow       = overrides.nebulaHeatGlow or Config.gen.nebulaHeatGlow or 0.35,
    nebulaHeatSaturation = overrides.nebulaHeatSaturation or Config.gen.nebulaHeatSaturation or 0.65,
    nebulaHeatStarBias   = overrides.nebulaHeatStarBias or Config.gen.nebulaHeatStarBias or 0.55,
    nebulaHeatHue        = overrides.nebulaHeatHue or Config.gen.nebulaHeatHue or 0.02,
    nebulaHeatVariation  = overrides.nebulaHeatVariation or Config.gen.nebulaHeatVariation or 0.70,
    nebulaGradeContrast  = overrides.nebulaGradeContrast or Config.gen.nebulaGradeContrast or 0.45,
    nebulaGradeSaturation = overrides.nebulaGradeSaturation or Config.gen.nebulaGradeSaturation or 0.35,
    nebulaHighlightSaturation = overrides.nebulaHighlightSaturation or Config.gen.nebulaHighlightSaturation or 0.5,
  }
end

local function applyComposeUniforms (ss, nebula, p)
  ss:setTexCube('envMap', nebula.envMap)
  ss:setFloat3('starDir', nebula.starDir.x, nebula.starDir.y, nebula.starDir.z)
  ss:setFloat3('starColor', nebula.starColor.x, nebula.starColor.y, nebula.starColor.z)
  ss:setFloat3('accentColor', nebula.accentColor.x, nebula.accentColor.y, nebula.accentColor.z)
  ss:setFloat('intensity', p.intensity)
  ss:setFloat('starIntensity', p.starIntensity)
  ss:setFloat('nebulaStarTint', p.nebulaStarTint)
  ss:setFloat('nebulaStarHighlight', p.nebulaStarHighlight)
  ss:setFloat('nebulaStarRange', p.nebulaStarRange)
  ss:setFloat('nebulaChromaVariance', p.nebulaChromaVariance)
  ss:setFloat('nebulaAccentStrength', p.nebulaAccentStrength)
  ss:setFloat('nebulaAccentShadow', p.nebulaAccentShadow)
  ss:setFloat('nebulaAccentRim', p.nebulaAccentRim)
  ss:setFloat('nebulaEdgeHighlight', p.nebulaEdgeHighlight)
  ss:setFloat('nebulaEdgeOcclude', p.nebulaEdgeOcclude)
  ss:setFloat('nebulaEdgeScale', p.nebulaEdgeScale)
  ss:setFloat('nebulaHeatGlow', p.nebulaHeatGlow)
  ss:setFloat('nebulaHeatSaturation', p.nebulaHeatSaturation)
  ss:setFloat('nebulaHeatStarBias', p.nebulaHeatStarBias)
  ss:setFloat('nebulaHeatHue', p.nebulaHeatHue)
  ss:setFloat('nebulaHeatVariation', p.nebulaHeatVariation)
  ss:setFloat('nebulaGradeContrast', p.nebulaGradeContrast)
  ss:setFloat('nebulaGradeSaturation', p.nebulaGradeSaturation)
  ss:setFloat('nebulaHighlightSaturation', p.nebulaHighlightSaturation)
end

function NebulaCompose.renderComposedCubemap (nebula, overrides, res)
  local p = NebulaCompose.skyboxParams(overrides, nebula)
  res = res or (Config.run and Config.run.nebulaExportRes) or 512
  local tex = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/skybox_compose')
  local ss = ShaderState.Create(shader)
  applyComposeUniforms(ss, nebula, p)
  tex:generate(ss)
  ss:free()
  return tex
end

return NebulaCompose
