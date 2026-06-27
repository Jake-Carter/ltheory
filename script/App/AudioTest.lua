-- SDL3 audio smoke test: MP3/WAV decode, 2D/3D playback, programmatic mix verification.

local kDefaultFrames = 90
local kMinMixPeak2D    = 1e-4
local kMinMixPeak3DNear = 1e-5
local kMinMixPeak3DFar  = 1e-6

local AudioTest = Application()

local function fail (msg)
  error('AudioTest: ' .. msg, 2)
end

function AudioTest:getTitle ()
  return 'Audio Test'
end

function AudioTest:onInit ()
  Config.render.vsync = false

  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or kDefaultFrames
  end

  Audio.Init()
  -- distanceScale = min distance (full volume inside); rolloff = falloff beyond it
  Audio.Set3DSettings(0, 50, 1)

  self.listener = Vec3f(0, 0, 0)
  self.phase = 'pending'
  self.wait = 0
  self.peakMax = 0
  self.results = {}
  self.active = nil
  self.playPos0 = 0
end

function AudioTest:_setListener ()
  Audio.SetListenerPos(self.listener, Vec3f(0, 0, 0), Vec3f(0, 0, -1), Vec3f(0, 1, 0))
end

function AudioTest:_tickAudio ()
  self:_setListener()
  Audio.Update()
  self.peakMax = max(self.peakMax, Audio.GetLastMixPeak())
end

function AudioTest:_finishPhase (name, minPeak)
  if self.peakMax < minPeak then
    fail(format('%s mix peak too low (%.2e < %.2e, playing=%d)',
      name, self.peakMax, minPeak, Audio.GetPlayingCount()))
  end
  printf('AudioTest: %s ok (peak=%.4f, playing=%d)', name, self.peakMax, Audio.GetPlayingCount())
  insert(self.results, name)
  self.peakMax = 0
  self.wait = 0
end

function AudioTest:_startDecodeCheck ()
  local blaster = Sound.Load('blaster', false, false)
  local wav = Sound.Load('thybidding', false, false)

  local dBlaster = blaster:getDuration()
  local dWav = wav:getDuration()
  if dBlaster <= 0 then fail(format('blaster duration %.3f', dBlaster)) end
  if dWav <= 0 then fail(format('thybidding duration %.3f', dWav)) end

  printf('AudioTest: decode ok — blaster=%.2fs (mp3), thybidding=%.2fs (wav)', dBlaster, dWav)
  insert(self.results, 'decode')

  self.blaster = blaster:managed()
  self.wav = wav:managed()
end

function AudioTest:_start2D ()
  self.active = self.blaster
  self.active:setVolume(0.8)
  self.active:rewind()
  self.active:play()
  self.playPos0 = self.active:getPlayPos()
  self.phase = '2d'
  self.wait = 8
end

function AudioTest:_start3DNear ()
  if self.active then self.active:pause() end
  self.active = Sound.Load('blaster', false, true):managed()
  self.active:setVolume(0.8)
  self.active:set3DPos(self.listener, Vec3f(0, 0, 0))
  self.active:play()
  self.phase = '3d_near'
  self.wait = 8
end

function AudioTest:_start3DFar ()
  if self.active then self.active:pause() end
  self.active = Sound.Load('blaster', false, true):managed()
  self.active:setVolume(0.8)
  self.active:set3DPos(Vec3f(120, 0, 0), Vec3f(0, 0, 0))
  self.active:play()
  self.phase = '3d_far'
  self.wait = 8
end

function AudioTest:onUpdate (dt)
  if self.phase == 'pending' then
    self:_startDecodeCheck()
    self:_start2D()
    return
  end

  self:_tickAudio()

  if self.phase == '2d' then
    self.wait = self.wait - 1
    if self.wait <= 0 then
      if self.active:getPlayPos() <= self.playPos0 then
        fail(format('2D play position did not advance (%.4f)', self.active:getPlayPos()))
      end
      self:_finishPhase('2D', kMinMixPeak2D)
      self:_start3DNear()
    end
    return
  end

  if self.phase == '3d_near' then
    self.wait = self.wait - 1
    if self.wait <= 0 then
      self:_finishPhase('3D_near', kMinMixPeak3DNear)
      self:_start3DFar()
    end
    return
  end

  if self.phase == '3d_far' then
    self.wait = self.wait - 1
    if self.wait <= 0 then
      self:_finishPhase('3D_far', kMinMixPeak3DFar)
      if self.active then self.active:pause() end
      self.active = nil
      self.phase = 'done'
      printf('AudioTest: all checks passed (%s)', join(self.results, ', '))
    end
  end
end

function AudioTest:onDraw ()
  Draw.Clear(0.08, 0.08, 0.1, 1)
end

function AudioTest:onExit ()
  self.active = nil
  self.blaster = nil
  self.wav = nil
  collectgarbage('collect')
  Audio.Free()
  if self.phase ~= 'done' then
    fail(format('incomplete at phase %s (%s)', self.phase, join(self.results, ', ')))
  end
  printf('AudioTest: passed (%d frames)', self.frameCount or 0)
end

return AudioTest
