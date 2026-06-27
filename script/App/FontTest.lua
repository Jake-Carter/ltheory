-- Font loading and UI text draw smoke test (metrics, Cache.Font, DrawEx paths).

local kDefaultFrames = 120

Config.render.vsync = false

local FontTest = Application()

function FontTest:getTitle ()
  return 'Font Test'
end

function FontTest:onInit ()
  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or kDefaultFrames
  end

  self.samples = {
    { family = Config.ui.font.normalFamily, size = Config.ui.font.normalSize,
      text = 'Cache.Font normal (Share @ 14)' },
    { family = Config.ui.font.titleFamily, size = Config.ui.font.titleSize,
      text = 'Cache.Font title (Share @ 10)' },
    { family = Config.ui.font.monoFamily, size = Config.ui.font.hudSize,
      text = 'HUD mono path (Share @ 16)' },
  }

  for i = 1, #self.samples do
    local s = self.samples[i]
    s.font = Cache.Font(s.family, s.size)
    printf('FontTest: loaded <%s> @ %d', s.family, s.size)
  end

  printf('FontTest: maxFrames=%d', self.maxFrames)
end

function FontTest:onDraw ()
  BlendMode.PushAlpha()
  Draw.Color(0.12, 0.12, 0.14, 1.0)
  Draw.Rect(0, 0, self.resX, self.resY)

  local y = 24
  for i = 1, #self.samples do
    local s = self.samples[i]
    s.font:draw(s.text, 16, y, 1, 1, 1, 1)
    y = y + s.font:getLineHeight() + 12
  end

  UI.DrawEx.TextAlpha(
    Config.ui.font.normalFamily,
    'DrawEx.TextAlpha',
    18,
    16, y, self.resX - 32, 32,
    0.4, 0.9, 1.0, 1.0,
    0, 0.5)
  y = y + 36

  UI.DrawEx.TextAdditive(
    Config.ui.font.monoFamily,
    'DrawEx.TextAdditive (HUD dock prompt style)',
    Config.ui.font.hudSize,
    16, y, self.resX - 32, 32,
    1, 1, 1, 1,
    0, 0.5)
  BlendMode.Pop()
end

function FontTest:onExit ()
  printf('FontTest: passed (%d frames)', self.frameCount or 0)
end

return FontTest
