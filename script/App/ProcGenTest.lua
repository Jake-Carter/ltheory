-- Fixed-seed procedural ship mesh smoke test (Shape finalize, mesh validate, optional BSP).

local kDefaultSeed = 5444776163124604250ULL
local kDefaultFrames = 120

Config.render.vsync = false

local ShipType = require('Game.ShipType')

local ProcGenTest = Application()

function ProcGenTest:getTitle ()
  return 'ProcGen Test'
end

function ProcGenTest:onInit ()
  if self.maxFrames == nil then
    self.maxFrames = (Config.run and Config.run.maxFrames) or kDefaultFrames
  end

  local seed = (Config.run and Config.run.procGenSeed)
    or Config.gen.seedGlobal
    or kDefaultSeed

  printf('ProcGenTest: seed=%s shipRes=%d skipMeshAO=%s',
    seed, Config.gen.shipRes, tostring(Config.gen.skipMeshAO))

  local buildBSP = (Config.run and Config.run.procGenBuildBSP)
    or Config.gen.buildShipBSP

  local prevBuildBSP = Config.gen.buildShipBSP
  Config.gen.buildShipBSP = buildBSP

  local shipType = ShipType(seed, Gen.Ship.ShipFighter, Config.gen.playerShipSize)
  Config.gen.buildShipBSP = prevBuildBSP

  local mesh = shipType.mesh
  local err = mesh:validate()
  if err ~= Error.None then
    error(format('ProcGenTest: mesh validate failed (0x%x)', err))
  end

  local vc = mesh:getVertexCount()
  local ic = mesh:getIndexCount()
  local radius = mesh:getRadius()
  local center = mesh:getCenter()

  printf('ProcGenTest: mesh ok — %d verts, %d indices, radius=%.3f center=(%.2f, %.2f, %.2f)',
    vc, ic, radius, center.x, center.y, center.z)

  if buildBSP then
    if shipType.bsp then
      printf('ProcGenTest: BSP ok (buildShipBSP=true)')
      if #shipType.sockets[MountType.Turret] == 0 and #shipType.sockets[MountType.Thruster] == 0 then
        error('ProcGenTest: BSP built but FindMountPoint returned no sockets')
      end
    else
      error('ProcGenTest: buildShipBSP requested but BSP.Create returned nil')
    end
  else
    printf('ProcGenTest: BSP skipped (set Config.run.procGenBuildBSP=true to test)')
  end

  local nTurret = #shipType.sockets[MountType.Turret]
  local nThruster = #shipType.sockets[MountType.Thruster]
  printf('ProcGenTest: sockets turret=%d thruster=%d', nTurret, nThruster)

  self.shipType = shipType
end

function ProcGenTest:onExit ()
  printf('ProcGenTest: passed (%d frames)', self.frameCount or 0)
end

return ProcGenTest
