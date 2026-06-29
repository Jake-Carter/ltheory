Config.debug.instantJobs = true
Config.debug.jobSpeed = 10000

Config.debug.window = true
Config.debug.metrics = true
Config.ui.showTrackers = false

Config.render.vsync = false

-- Config.run.ltheorySeed = 16527831391977940936

-- Config.gen.nBeltSize = function (rng) return 10000 end
Config.gen.scalePlanet = 5e3
-- Config.gen.nNPCs = 10
Config.gen.nFields = 1
Config.gen.nPlanets = 0
Config.gen.nTurrets = 1
Config.gen.nThrusters = 2
Config.gen.nStations = 2
Config.gen.dustCloudSize = 256
Config.gen.dustCloudOpacity = 0.5
Config.gen.nDustClouds = 64

Config.gen.starfieldIntensity = 0.3
Config.gen.starfieldBrightness = 0.2
Config.gen.nebulaSkyIntensity = 0.3
Config.gen.centralStarIntensity = 1.0
Config.gen.nebulaGIIntensity = 0.1

if false then
  Config.jit.loom = true
  Config.jit.profile = false
  Config.jit.verbose = false
end
