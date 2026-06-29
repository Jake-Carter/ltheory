local Nebula = class(function (self, seed, starDir)
  self.seed = seed
  self.starDir = starDir
  self.starColor = Vec3f(1.0, 0.85, 0.65)
end)

function Nebula:forceLoad ()
  if self.envMap then return end
  local rng = RNG.Create(self.seed + 0xC0104FULL):managed()
  local gen = Gen.Generator.Get('Nebula', rng)
  local envMap, sr, sg, sb = gen(rng, Config.gen.nebulaRes, self.starDir)
  self.envMap = envMap:managed()
  if sr then self.starColor = Vec3f(sr, sg, sb) end
  self.irMap = self.envMap:genIRMap(256):managed()
  self.stars = Gen.Starfield(rng, Config.gen.nStars(rng)):managed()
end

function Nebula:render (state)
  self:forceLoad()
  if state.mode == BlendMode.Disabled then
    RenderState.PushDepthWritable(false)
    local shader = Cache.Shader('farplane', 'skybox')
    CullFace.Push(CullFace.None)
    shader:start()
    Shader.SetFloat('intensity', Config.gen.nebulaSkyIntensity or 1.0)
    Shader.SetFloat('starIntensity', Config.gen.centralStarIntensity or 1.0)
    Shader.SetFloat3('starColor', self.starColor.x, self.starColor.y, self.starColor.z)
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
