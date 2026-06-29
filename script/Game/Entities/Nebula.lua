local Nebula = class(function (self, seed, starDir)
  self.seed = seed
  self.starDir = starDir
  self.starColor = Vec3f(1.0, 0.85, 0.65)
  self.accentColor = Vec3f(0.55, 0.75, 1.0)
end)

local function nebulaLightingScalars (self)
  local sky = self.skyIntensity
  local star = self.starIntensity
  if not sky or not star then
    local GenUtil = require('Gen.GenUtil')
    local rng = RNG.Create(self.seed + 0x51A7EULL):managed()
    if not sky then
      sky = GenUtil.pickScalar(Config.gen.nebulaSkyIntensity, rng, 0.18)
      self.skyIntensity = sky
    end
    if not star then
      star = GenUtil.pickScalar(Config.gen.centralStarIntensity, rng, 0.5)
      self.starIntensity = star
    end
  end
  return sky, star
end

local function nebulaComposeUniforms ()
  Shader.SetFloat('nebulaAccentStrength', Config.gen.nebulaAccentStrength or 0.4)
  Shader.SetFloat('nebulaAccentShadow', Config.gen.nebulaAccentShadow or 0.35)
  Shader.SetFloat('nebulaAccentRim', Config.gen.nebulaAccentRim or 0.25)
  Shader.SetFloat('nebulaGradeContrast', Config.gen.nebulaGradeContrast or 0.45)
  Shader.SetFloat('nebulaGradeSaturation', Config.gen.nebulaGradeSaturation or 0.35)
  Shader.SetFloat('nebulaHighlightSaturation', Config.gen.nebulaHighlightSaturation or 0.5)
end

function Nebula:forceLoad ()
  if self.envMap then return end
  local rng = RNG.Create(self.seed + 0xC0104FULL):managed()
  local gen = Gen.Generator.Get('Nebula', rng)
  local envMap, sr, sg, sb = gen(rng, Config.gen.nebulaRes, self.starDir)
  self.envMap = envMap:managed()
  if sr then
    self.starColor = Vec3f(sr, sg, sb)
    local star = Color(sr, sg, sb)
    local hueOffset = Config.gen.nebulaAccentHueOffset or 0.5
    local NebulaPalette = require('Gen.NebulaPalette')
    local accent = NebulaPalette.pickAccentColor(rng, star, hueOffset)
    self.accentColor = accent:toVec3()
  end
  self.irMap = self.envMap:genIRMap(256):managed()
  self.stars = Gen.Starfield(rng, Config.gen.nStars(rng)):managed()
  nebulaLightingScalars(self)
end

function Nebula:render (state)
  self:forceLoad()
  if state.mode == BlendMode.Disabled then
    RenderState.PushDepthWritable(false)
    local shader = Cache.Shader('farplane', 'skybox')
    CullFace.Push(CullFace.None)
    shader:start()
    local sky, star = nebulaLightingScalars(self)
    Shader.SetFloat('intensity', sky)
    Shader.SetFloat('starIntensity', star)
    Shader.SetFloat('nebulaStarTint', Config.gen.nebulaStarTint or 0.4)
    Shader.SetFloat('nebulaStarHighlight', Config.gen.nebulaStarHighlight or 0.6)
    Shader.SetFloat('nebulaStarRange', Config.gen.nebulaStarRange or 1.0)
    Shader.SetFloat('nebulaChromaVariance', Config.gen.nebulaChromaVariance or 0.2)
    nebulaComposeUniforms()
    Draw.Box3(Box3f(-1, -1, -1, 1, 1, 1))
    shader:stop()
    CullFace.Pop()
    RenderState.PopDepthWritable()
  elseif state.mode == BlendMode.Additive then
    local shader = Cache.Shader('farplane', 'starbg')
    shader:start()
    Shader.SetTexCube('irMap', self.irMap)
    Shader.SetTexCube('envMap', self.envMap)
    Shader.SetFloat('intensity', Config.gen.starfieldIntensity or 1.0)
    self.stars:draw()
    shader:stop()
  end
end

return Nebula
