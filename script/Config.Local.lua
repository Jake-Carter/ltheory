Config.debug.instantJobs = true
Config.debug.jobSpeed = 10000

Config.debug.window = true
Config.debug.metrics = true
Config.ui.showTrackers = false

Config.render.vsync = false
-- Config.run.ltheorySeed = 17713639446270978484
-- Config.run.ltheorySeed = 10531126295213924902
Config.run.ltheorySeed = 2

-- Config.gen.nBeltSize = function (rng) return 10000 end
Config.gen.scalePlanet = 5e3
-- Config.gen.nNPCs = 10
Config.gen.nFields = 1
Config.gen.nPlanets = 0
Config.gen.nTurrets = 1
Config.gen.nThrusters = 2
Config.gen.nStations = 2
Config.gen.dustCloudSize = 256
Config.gen.dustCloudOpacity = 1.0
Config.gen.nDustClouds = 0
Config.gen.nDustFlecks = 512
Config.gen.dustScatterIntensity = 3.0

-- Config.gen.starfieldIntensity = 0.3
-- Config.gen.starfieldBrightness = 0.2
-- Config.gen.nebulaSkyIntensity = 0.5
-- Config.gen.centralStarIntensity = 0.5
-- Config.gen.nebulaGIIntensity = 0.1
-- ConfigReload.gen.nebulaStarTint = 1.0
-- Config.gen.nebulaStarHighlight = 1.0
-- Config.gen.nebulaStarRange = 1.0

if false then
  Config.jit.loom = true
  Config.jit.profile = false
  Config.jit.verbose = false
end
