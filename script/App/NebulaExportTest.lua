local Nebula = require('Game.Entities.Nebula')
local NebulaExport = require('Gen.NebulaExport')

local kDefaultSeed = 16527831391977940936ULL

local NebulaExportTest = Application()

function NebulaExportTest:getTitle ()
  return 'Nebula Export Test'
end

function NebulaExportTest:onInit ()
  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or 1
  end

  Config.render.vsync = false

  local seed = (Config.run and Config.run.nebulaExportSeed)
    or (Config.run and Config.run.ltheorySeed)
    or kDefaultSeed

  local seedLabel = NebulaExport.seedPathLabel(seed)

  local rng = RNG.Create(seed):managed()
  local starAngle = rng:getDir2()
  local starDir = Vec3f(starAngle.x, 0, starAngle.y)

  local nebula = Nebula(seed, starDir)
  nebula:forceLoad()

  local baseDir = (Config.run and Config.run.nebulaExportDir) or './export/nebula/'
  if baseDir:sub(-1) ~= '/' and baseDir:sub(-1) ~= '\\' then baseDir = baseDir .. '/' end
  local outDir = baseDir .. seedLabel .. '/'

  local sweep = Config.run and Config.run.nebulaExportSweep
  if sweep and #sweep > 0 then
    printf('NebulaExportTest: exporting base + %d sweep variants', #sweep)
    NebulaExport.exportNebula(nebula, seed, outDir, { name = seedLabel })
    NebulaExport.exportSweep(nebula, seed, outDir, sweep)
  else
    NebulaExport.exportNebula(nebula, seed, outDir, { name = seedLabel })
  end

  self.exportDir = outDir
end

function NebulaExportTest:onExit ()
  printf('NebulaExportTest: passed — output in <%s>', self.exportDir or '?')
end

return NebulaExportTest
