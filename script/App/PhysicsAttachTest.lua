-- Minimal RigidBody_Attach smoke test: one ship, one asteroid, N physics steps.
-- Reproduces the compound-attach path used by PhysicsTest and LTheory escorts.

local kSeed = 1234ULL
local kDefaultFrames = 60

Config.render.vsync = false

local Entities = requireAll('Game.Entities')

local PhysicsAttachTest = Application()

function PhysicsAttachTest:getTitle ()
  return 'Physics Attach Test'
end

function PhysicsAttachTest:onInit ()
  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or kDefaultFrames
  end

  if Config.run and Config.run.minimalAttach then
    self.physics = Physics.Create():managed()
    self.parent = RigidBody.CreateBox():managed()
    self.child = RigidBody.CreateBox():managed()
    self.physics:addRigidBody(self.parent)
    if not (Config.run and Config.run.skipAttach) then
      self.parent:attach(self.child, Vec3f(2, 0, 0), Quat.Identity())
      printf('PhysicsAttachTest: minimal attach ok (maxFrames=%d)', self.maxFrames)
    else
      printf('PhysicsAttachTest: minimal no-attach ok (maxFrames=%d)', self.maxFrames)
    end
    return
  end

  if Config.run and Config.run.singleAsteroid then
    local seed = Config.gen.seedGlobal or kSeed
    self.system = Entities.System(seed)
    self.asteroid = Entities.Asteroid(1234, 5)
    self.asteroid:setPos(Config.gen.origin)
    self.system:addChild(self.asteroid)
    printf('PhysicsAttachTest: single asteroid ok (maxFrames=%d)', self.maxFrames)
    return
  end

  local seed = Config.gen.seedGlobal or kSeed
  self.system = Entities.System(seed)

  self.ship = self.system:spawnShip()
  self.ship:setPos(Config.gen.origin)
  self.ship:setFriction(0)
  self.ship:setSleepThreshold(0, 0)

  self.asteroid = Entities.Asteroid(1234, 5)
  self.asteroid:setPos(Vec3f(10, 0, 0))
  self.system:addChild(self.asteroid)
  self.system:removeChild(self.asteroid)
  if not (Config.run and Config.run.skipAttach) then
    self.ship:attach(self.asteroid, Vec3f(10, 0, 0), Quat.Identity())
  end

  printf('PhysicsAttachTest: attach ok (maxFrames=%d)', self.maxFrames)
end

function PhysicsAttachTest:onUpdate (dt)
  if self.physics then
    self.physics:update(dt)
  else
    self.system:update(dt)
  end
end

function PhysicsAttachTest:onDraw ()
end

function PhysicsAttachTest:onExit ()
  printf('PhysicsAttachTest: passed (%d frames)', self.frameCount or 0)
end

return PhysicsAttachTest
