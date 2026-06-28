local Entities = requireAll('Game.Entities')
local DebugControl = require('Game.Controls.DebugControl')

local LTheory = Application()
local rng = RNG.FromTime()

local function fail (msg)
  error('LTheory: ' .. msg, 2)
end

function LTheory:generate ()
  local fixedSeed = (Config.run and Config.run.ltheorySeed) or Config.gen.seedGlobal
  if fixedSeed then
    self.seed = fixedSeed
  else
    self.seed = rng:get64()
  end
  if false then
    -- self.seed = 7035008865122330386ULL
    -- self.seed = 15054808765102574876ULL
    -- self.seed = 1777258448479734603ULL
    -- self.seed = 5023726954312599969ULL
  end
  printf('Seed: %s', self.seed)

  if self.system then self.system:delete() end
  self.system = Entities.System(self.seed)

  local ship
  do -- Player Ship
    ship = self.system:spawnShip()
    ship:setPos(Config.gen.origin)
    ship:setFriction(0)
    ship:setSleepThreshold(0, 0)
    ship:setOwner(self.player)
    self.system:addChild(ship)
    self.player:setControlling(ship)

    -- player escorts
    local ships = {}
    for i = 1, Config.game.friendlies do
      local escort = self.system:spawnShip()
      local offset = rng:getSphere():scale(100)
      escort:setPos(ship:getPos() + offset)
      escort:setOwner(self.player)
      escort:pushAction(Actions.Escort(ship, offset))
      insert(ships, escort)
    end

    for i = 1, #ships do
      local j = rng:getInt(1, #ships)
      if i ~= j then
        -- ships[i]:pushAction(Actions.Attack(ships[j]))
      end
    end
  end

  for i = 1, Config.gen.nStations do
    self.system:spawnStation()
  end

  for i = 1, Config.game.enemies do
    self.system:spawnAI(Config.game.aiShipCount or 100)
  end

  for i = 1, Config.gen.nPlanets do
    self.system:spawnPlanet()
  end

  local beltCount = Config.gen.beltFieldCount or 0
  if beltCount > 0 then
    self.system:spawnAsteroidField(beltCount, Config.gen.nBeltSize(self.system.rng))
  end

  self.playerShip = ship
end

function LTheory:validateGate ()
  if not self.system then fail('no system after generate') end

  local ship = self.player:getControlling()
  if not ship then fail('player has no controlling ship') end
  if ship ~= self.playerShip then fail('controlling ship mismatch') end

  local nPlayers = #self.system.players
  local expectedPlayers = Config.game.enemies
  if nPlayers ~= expectedPlayers then
    fail(format('expected %d AI players, got %d', expectedPlayers, nPlayers))
  end

  printf('LTheory: gate ok — ship=%s stations=%d planets=%d belt=%d ore=%d friendlies=%d enemies=%d AI=%d',
    ship:getName() or 'ship',
    Config.gen.nStations,
    Config.gen.nPlanets,
    Config.gen.beltFieldCount or 0,
    Config.gen.nBeltSize(self.system.rng),
    Config.game.friendlies,
    Config.game.enemies,
    nPlayers)
end

function LTheory:onInit ()
  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or nil
  end
  self.gateMode = self.maxFrames ~= nil and self.maxFrames > 0

  Config.render.vsync = false

  self.player = Entities.Player()
  self:generate()
  if self.gateMode then self:validateGate() end

  DebugControl.ltheory = self
  self.gameView = GUI.GameView(self.player)
  self.canvas = UI.Canvas()
  self.canvas
    :add(self.gameView
      :add(Controls.MasterControl(self.gameView, self.player)))
end

function LTheory:onInput ()
  self.canvas:input()
end

function LTheory:onUpdate (dt)
  self.player:getRoot():update(dt)
  self.canvas:update(dt)
end

function LTheory:onDraw ()
  self.canvas:draw(self.resX, self.resY)
end

function LTheory:onExit ()
  if self.gateMode then
    local ship = self.player and self.player:getControlling()
    if not ship then fail('gate exit: no controlling ship') end
    printf('LTheory: passed (%d frames)', self.frameCount or 0)
  end
end

return LTheory
