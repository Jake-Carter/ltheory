Config.app = 'InputTest'

Config.run = {
  maxFrames = nil, -- auto-exit after N frames; override via CLI: lt64.exe AppName --frames 60
  minimalAttach = false, -- true: two-box FFI attach only (no ship proc-gen)
  singleAsteroid = false, -- true: one asteroid in system, no compound attach
  skipAttach = false,   -- skip final asteroid attach in full/system mode
  procGenSeed = nil,    -- fixed seed for ProcGenTest (nil = use kDefaultSeed in app)
  procGenBuildBSP = false, -- ProcGenTest only; attempt BSP.Create when true
  ltheorySeed = nil,    -- fixed seed for LTheory gate (nil = random)
}

Config.debug = {
  metrics         = true,
  window          = true, -- Debug window visible by default at launch?
  windowSection   = nil,  -- Set to the name of a debug window section to
                          -- collapse all others by default
  timeAccelFactor = 10,
}

Config.debug.physics = {
  drawWireframes         = false,
  drawBoundingBoxesLocal = false,
  drawBoundingBoxesworld = false,
}

local goodSeeds = {
  14589938814258111262ULL,
  15297218883250103974ULL,
  1842258441393851360ULL,
  1305797465843153519ULL,
  5421862249219039751ULL,
  638780708004697442ULL,
}

Config.gen = {
  buildShipBSP = true,  -- ProcGenTest validates BSP_Create on fixed-seed ship meshes
  skipMeshAO   = false, -- mesh AO in Shape:finalize (ProcGenTest validates this path)
  seedGlobal = nil, -- Set to force deterministic global RNG
  seedSystem = nil, -- Set to force deterministic system generation

  origin     = Vec3f(0, 0, 0), -- Set far from zero to test engine precision
  nFields    = 20,
  nFieldSize = function (rng) return 200 * (rng:getExp() + 1.0) end,
  nStations  = 1,
  nNPCs      = 0,
  nNPCsNew   = 0,
  nPlanets   = 1,
  beltFieldCount = 500, -- asteroids in standalone belt (original LTheory default)
  nBeltSize  = function (rng) return 10 end, -- ore-bearing asteroids in belt field; also per-planet ring in SystemBasic
  nThrusters = 1,
  nTurrets   = 2,

  nDustFlecks = 1024,
  nDustClouds = 1024,
  nStars      = function (rng) return 5000 * (1.0 + 0.5 * rng:getExp()) end,

  shipRes     = 8,
  nebulaRes   = 1024,

  scalePlanet = 2000,
  playerShipSize = 4,
}

Config.game = {
  boostCost = 10,
  rateOfFire = 10,

  autoTarget             = false,
  pulseDamage            = 5,
  pulseSize              = 64,
  pulseSpeed             = 6e2,
  pulseRange             = 1000,
  pulseSpread            = 0.01,

  shipBuildTime          = 10,
  shipEnergy             = 100,
  shipEnergyRecharge     = 10,
  shipHealth             = 100,
  shipHealthRegen        = 2,
  stationScale           = 20,

  playerDamageResistance = 1.0,

  enemies                = 1,
  friendlies             = 1,
  aiShipCount            = 5, -- ships per spawnAI call (historically 100 in full game)
  squadSizeEnemy         = 8,
  squadSizeFriendly      = 8,
  spawnDistance          = 2000,
  friendlySpawnCount     = 10,
  timeScaleShipEditor    = 0.0,
  invertPitch            = false,

  aiUsesBoost            = true,
  aiFire                 = function (dt, rng) return rng:getExp() ^ 2 < dt end,

  dockRange              = 50,
}

Config.render = {
  fullscreen = false,
  vsync      = true,
}

Config.ui = {
  showTrackers     = true,
  defaultControl   = 'Ship',
  controlBarHeight = 48
}

Config.ui.color = {
  accent            = Color(1.00, 0.00, 0.30, 1.0),
  focused           = Color(1.00, 0.00, 0.30, 1.0),
  active            = Color(0.70, 0.00, 0.21, 1.0),
  background        = Color(0.15, 0.15, 0.15, 1.0),
  border            = Color(0.12, 0.12, 0.12, 1.0),
  fill              = Color(0.60, 0.60, 0.60, 1.0),
  textNormal        = Color(0.75, 0.75, 0.75, 1.0),
  textNormalFocused = Color(0.00, 0.00, 0.00, 1.0),
  textTitle         = Color(0.60, 0.60, 0.60, 1.0),
  debugRect         = Color(0.50, 1.00, 0.50, 0.05),
  selection         = Color(1.00, 0.50, 0.10, 1.0),
  control           = Color(0.20, 0.60, 1.00, 0.3),
  controlFocused    = Color(0.20, 1.00, 0.20, 0.4),
  controlActive     = Color(0.14, 0.70, 0.14, 0.4),
}

Config.ui.font = setmetatable({
  normalFamily = 'Share',
  titleFamily  = 'Exo2Bold',
  monoFamily   = 'NovaMono',
  normalSize   = 14,
  titleSize    = 10,
  hudSize      = 16,
}, {
  __index = function (self, key)
    if key == 'normal' then
      local font = Cache.Font(self.normalFamily, self.normalSize)
      rawset(self, key, font)
      return font
    elseif key == 'title' then
      local font = Cache.Font(self.titleFamily, self.titleSize)
      rawset(self, key, font)
      return font
    elseif key == 'mono' then
      local font = Cache.Font(self.monoFamily, self.hudSize)
      rawset(self, key, font)
      return font
    end
  end,
})
