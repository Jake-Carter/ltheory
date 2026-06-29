local Dust = class(function (self, seed)
  self.seed = seed or 0
end)

function Dust:forceLoad ()
  if self.clouds then return end

  local nClouds = Config.gen.nDustClouds or 0
  local nFlecks = Config.gen.nDustFlecks or 0
  local cloudDist = Config.gen.dustCloudDistance or 1024
  local fleckDist = Config.gen.dustFleckDistance or 1024
  self.cloudSize = Config.gen.dustCloudSize or 96

  local rng = RNG.Create(self.seed + 0xD05700ULL):managed()

  if nClouds > 0 then
    local mesh = Mesh.Create():managed()
    for i = 1, nClouds do
      local p = rng:getVec3(-cloudDist, cloudDist)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1, -1, -1)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1,  1, -1)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1,  1,  1)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1, -1,  1)
      local i0 = 4 * (i - 1)
      mesh:addQuad(i0, i0 + 3, i0 + 2, i0 + 1)
    end
    self.clouds = mesh
  end

  if nFlecks > 0 then
    local mesh = Mesh.Create():managed()
    for i = 1, nFlecks do
      local p = rng:getVec3(-fleckDist, fleckDist)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1, -1, 0)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1,  1, 0)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1,  1, 1)
      mesh:addVertex(p.x, p.y, p.z, 0, 0, 1, -1, 1)
      local i0 = 4 * (i - 1)
      mesh:addQuad(i0, i0 + 3, i0 + 2, i0 + 1)
    end
    self.flecks = mesh
  end
end

local mIdentity = Matrix.Identity()
local texDust

local function dustLightingUniforms ()
  Shader.SetFloat('starIntensity', Config.gen.centralStarIntensity or 1.0)
  local sky = Config.gen.nebulaSkyIntensity or 1.0
  Shader.SetFloat('nebulaGIIntensity', (Config.gen.nebulaGIIntensity or 0.05) * sky)
  Shader.SetFloat('nebulaChromaVariance', Config.gen.nebulaChromaVariance or 0.2)
  Shader.SetFloat('scatterIntensity', Config.gen.dustScatterIntensity or 1.5)
end

function Dust:render (state)
  self:forceLoad()
  if state.mode == BlendMode.Alpha then
    if not self.clouds then return end
    Profiler.Begin('DustClouds.RenderAlpha')
    if not texDust then
      texDust = Tex2D.Create(128, 128, TexFormat.R8)
      local shader = Cache.Shader('identity', 'effect/dustcloudtex')
      texDust:push()
      shader:start()
      Draw.Rect(-1, -1, 2, 2)
      shader:stop()
      texDust:pop()
      texDust:genMipmap()
      texDust:setMagFilter(TexFilter.Linear)
      texDust:setMinFilter(TexFilter.LinearMipLinear)
      texDust:setWrapMode(TexWrapMode.Clamp)
    end

    local cam = Camera.get()
    local shader = Cache.Shader('billboard/wrapped', 'effect/dustcloud')
    local up = cam.rot:getUp()
    local size = self.cloudSize
    shader:start()
    dustLightingUniforms()
    Shader.SetFloat3('axis', up.x, up.y, up.z)
    Shader.SetFloat2('size', size, size)
    Shader.SetMatrix('mWorld', mIdentity)
    Shader.SetTex2D('texDust', texDust)
    Shader.SetFloat('opacity', Config.gen.dustCloudOpacity or 0.5)
    Shader.SetFloat('alphaPower', Config.gen.dustCloudAlphaPower or 1.25)
    Shader.SetFloat('fadeWidth', Config.gen.dustCloudFadeWidth or 0.35)
    -- Additive blend only for the draw: emissive scatter, not alpha occlusion.
    BlendMode.PushAdditive()
    self.clouds:draw()
    BlendMode.Pop()
    shader:stop()
    Profiler.End()
  elseif state.mode == BlendMode.Additive then
    if not self.flecks then return end
    Profiler.Begin('DustFlecks.RenderAdditive')
    local vel = state.velocity
    if vel then
      local vl = vel:length()
      if vl > 1e-6 then
        local vn = vel:normalize()
        local shader = Cache.Shader('billboard/wrapped', 'effect/dustfleck')
        shader:start()
        dustLightingUniforms()
        Shader.SetMatrix('mWorld', mIdentity)
        Shader.SetFloat2('size', 2.0, 0.1 * min(1000.0, vl))
        Shader.SetFloat3('axis', vn.x, vn.y, vn.z)
        self.flecks:draw()
        shader:stop()
      end
    end
    Profiler.End()
  end
end

return Dust
