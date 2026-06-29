local NebulaExport = {}
local GenUtil = require('Gen.GenUtil')

local function seedPathLabel (seed)
  local s = tostring(seed)
  if s:find('[eE]') then
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 4294967296 end
    return format('seed_%08x', h)
  end
  return s:gsub('[^%w_-]', '_')
end

local function pathJoin (a, b)
  if a:sub(-1) == '/' or a:sub(-1) == '\\' then
    return a .. b
  end
  return a .. '/' .. b
end

local function ensureDir (path)
  path = path:gsub('\\', '/'):gsub('/$', '')
  if path == '' then return end
  local acc = nil
  for part in path:gmatch('[^/]+') do
    if part == '.' then
      acc = acc or '.'
    elseif acc == nil then
      acc = part
    else
      acc = acc .. '/' .. part
    end
    if part ~= '.' and part ~= '..' and not File.IsDir(acc) then
      Directory.Create(acc)
    end
  end
end

local function skyboxParams (overrides, nebula)
  overrides = overrides or {}
  local sky = overrides.nebulaSkyIntensity
  if not sky and nebula and nebula.skyIntensity then sky = nebula.skyIntensity end
  if not sky then sky = GenUtil.pickScalar(Config.gen.nebulaSkyIntensity, nil, 0.18) end

  local star = overrides.centralStarIntensity
  if not star and nebula and nebula.starIntensity then star = nebula.starIntensity end
  if not star then star = GenUtil.pickScalar(Config.gen.centralStarIntensity, nil, 0.5) end

  return {
    intensity           = sky,
    starIntensity       = star,
    nebulaStarTint      = overrides.nebulaStarTint or Config.gen.nebulaStarTint or 0.4,
    nebulaStarHighlight = overrides.nebulaStarHighlight or Config.gen.nebulaStarHighlight or 0.6,
    nebulaStarRange     = overrides.nebulaStarRange or Config.gen.nebulaStarRange or 1.0,
    nebulaChromaVariance = overrides.nebulaChromaVariance or Config.gen.nebulaChromaVariance or 0.2,
    nebulaAccentStrength = overrides.nebulaAccentStrength or Config.gen.nebulaAccentStrength or 0.4,
    nebulaAccentShadow   = overrides.nebulaAccentShadow or Config.gen.nebulaAccentShadow or 0.35,
    nebulaAccentRim      = overrides.nebulaAccentRim or Config.gen.nebulaAccentRim or 0.25,
    nebulaGradeContrast  = overrides.nebulaGradeContrast or Config.gen.nebulaGradeContrast or 0.45,
    nebulaGradeSaturation = overrides.nebulaGradeSaturation or Config.gen.nebulaGradeSaturation or 0.35,
    nebulaHighlightSaturation = overrides.nebulaHighlightSaturation or Config.gen.nebulaHighlightSaturation or 0.5,
  }
end

local function sweepLabel (overrides)
  if not overrides then return nil end
  local parts = {}
  for k, v in pairs(overrides) do
    insert(parts, format('%s_%g', k, v))
  end
  table.sort(parts)
  return #parts > 0 and join(parts, '_') or nil
end

local function jsonEscape (s)
  return (s:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local function jsonValue (v)
  local t = type(v)
  if t == 'number' then
    return format('%.17g', v)
  elseif t == 'boolean' then
    return v and 'true' or 'false'
  elseif t == 'string' then
    return format('"%s"', jsonEscape(v))
  elseif t == 'table' then
    local isArray = #v > 0
    local parts = {}
    if isArray then
      for i = 1, #v do insert(parts, jsonValue(v[i])) end
      return '[' .. join(parts, ',') .. ']'
    end
    for k, val in pairs(v) do
      insert(parts, format('"%s":%s', jsonEscape(tostring(k)), jsonValue(val)))
    end
    table.sort(parts)
    return '{' .. join(parts, ',') .. '}'
  end
  return 'null'
end

function NebulaExport.exportMetadata (outPath, meta)
  local dir = outPath:match('^(.*)[/\\][^/\\]+$')
  if dir then ensureDir(dir) end
  local f = File.Create(outPath)
  if f == nil then
    error(format('NebulaExport: failed to create <%s>', outPath))
  end
  f:writeStr(jsonValue(meta))
  f:close()
end

function NebulaExport.exportCubemapFaces (cubemap, pathPrefix)
  local dir = pathPrefix:match('^(.*)[/\\][^/\\]+$')
  if dir then ensureDir(dir) end
  cubemap:save(pathPrefix)
end

function NebulaExport.exportEquirect (cubemap, outPath, w, h)
  w = w or 2048
  h = h or math.floor(w / 2)
  local dir = outPath:match('^(.*)[/\\][^/\\]+$')
  if dir then ensureDir(dir) end

  local tex = Tex2D.Create(w, h, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/equirect')

  RenderState.PushAllDefaults()
  tex:push()
  Draw.Clear(0, 0, 0, 1)
  shader:start()
  Shader.SetTexCube('src', cubemap)
  Draw.Rect(0, 0, w, h)
  Draw.Flush()
  shader:stop()
  tex:pop()
  RenderState.PopAll()

  tex:save(outPath)
  tex:free()
  return outPath
end

function NebulaExport.exportBaked (envMap, outDir, name)
  local prefix = pathJoin(outDir, name .. '_baked')
  NebulaExport.exportCubemapFaces(envMap, prefix)
  local equi = pathJoin(outDir, name .. '_baked_equirect.png')
  NebulaExport.exportEquirect(envMap, equi)
  return prefix, equi
end

function NebulaExport.renderComposedCubemap (nebula, overrides)
  local p = skyboxParams(overrides, nebula)
  local res = (Config.run and Config.run.nebulaExportRes) or 512
  local tex = TexCube.Create(res, TexFormat.RGBA16F)
  local shader = Cache.Shader('ui', 'gen/skybox_compose')
  local ss = ShaderState.Create(shader)

  ss:setTexCube('envMap', nebula.envMap)
  ss:setFloat3('starDir', nebula.starDir.x, nebula.starDir.y, nebula.starDir.z)
  ss:setFloat3('starColor', nebula.starColor.x, nebula.starColor.y, nebula.starColor.z)
  ss:setFloat3('accentColor', nebula.accentColor.x, nebula.accentColor.y, nebula.accentColor.z)
  ss:setFloat('intensity', p.intensity)
  ss:setFloat('starIntensity', p.starIntensity)
  ss:setFloat('nebulaStarTint', p.nebulaStarTint)
  ss:setFloat('nebulaStarHighlight', p.nebulaStarHighlight)
  ss:setFloat('nebulaStarRange', p.nebulaStarRange)
  ss:setFloat('nebulaChromaVariance', p.nebulaChromaVariance)
  ss:setFloat('nebulaAccentStrength', p.nebulaAccentStrength)
  ss:setFloat('nebulaAccentShadow', p.nebulaAccentShadow)
  ss:setFloat('nebulaAccentRim', p.nebulaAccentRim)
  ss:setFloat('nebulaGradeContrast', p.nebulaGradeContrast)
  ss:setFloat('nebulaGradeSaturation', p.nebulaGradeSaturation)
  ss:setFloat('nebulaHighlightSaturation', p.nebulaHighlightSaturation)

  tex:generate(ss)
  ss:free()
  return tex
end

function NebulaExport.exportComposed (nebula, outDir, name, overrides)
  local composed = NebulaExport.renderComposedCubemap(nebula, overrides):managed()
  local label = sweepLabel(overrides)
  local suffix = label and ('_' .. label) or ''
  local prefix = pathJoin(outDir, name .. '_composed' .. suffix)
  NebulaExport.exportCubemapFaces(composed, prefix)
  local equi = pathJoin(outDir, name .. '_composed' .. suffix .. '_equirect.png')
  NebulaExport.exportEquirect(composed, equi)
  return prefix, equi, composed
end

function NebulaExport.exportNebula (nebula, seed, outDir, options)
  options = options or {}
  ensureDir(outDir)

  local name = options.name or seedPathLabel(seed)
  local overrides = options.overrides

  printf('NebulaExport: seed=%s outDir=%s', seed, outDir)

  local bakedPrefix, bakedEqui = NebulaExport.exportBaked(nebula.envMap, outDir, name)
  printf('NebulaExport: baked faces <%s_*.png>', bakedPrefix)
  printf('NebulaExport: baked equirect <%s>', bakedEqui)

  local composedPrefix, composedEqui = NebulaExport.exportComposed(nebula, outDir, name, overrides)
  printf('NebulaExport: composed faces <%s_*.png>', composedPrefix)
  printf('NebulaExport: composed equirect <%s>', composedEqui)

  local p = skyboxParams(overrides, nebula)
  local meta = {
    seed = tostring(seed),
    nebulaRes = nebula.envMap:getSize(),
    exportRes = (Config.run and Config.run.nebulaExportRes) or 512,
    starDir = {
      nebula.starDir.x,
      nebula.starDir.y,
      nebula.starDir.z,
    },
    starColor = {
      nebula.starColor.x,
      nebula.starColor.y,
      nebula.starColor.z,
    },
    accentColor = {
      nebula.accentColor.x,
      nebula.accentColor.y,
      nebula.accentColor.z,
    },
    nebulaSkyIntensity = p.intensity,
    centralStarIntensity = p.starIntensity,
    nebulaStarTint = p.nebulaStarTint,
    nebulaStarHighlight = p.nebulaStarHighlight,
    nebulaStarRange = p.nebulaStarRange,
    nebulaChromaVariance = p.nebulaChromaVariance,
    nebulaAccentStrength = p.nebulaAccentStrength,
    nebulaAccentShadow = p.nebulaAccentShadow,
    nebulaAccentRim = p.nebulaAccentRim,
    nebulaGradeContrast = p.nebulaGradeContrast,
    nebulaGradeSaturation = p.nebulaGradeSaturation,
    nebulaHighlightSaturation = p.nebulaHighlightSaturation,
    overrides = overrides,
  }
  local metaPath = pathJoin(outDir, 'meta.json')
  if overrides then
    local label = sweepLabel(overrides)
    if label then metaPath = pathJoin(outDir, 'meta_' .. label .. '.json') end
  end
  NebulaExport.exportMetadata(metaPath, meta)
  printf('NebulaExport: metadata <%s>', metaPath)

  return {
    bakedPrefix = bakedPrefix,
    bakedEquirect = bakedEqui,
    composedPrefix = composedPrefix,
    composedEquirect = composedEqui,
    metaPath = metaPath,
  }
end

function NebulaExport.exportSweep (nebula, seed, outDir, sweep)
  local name = seedPathLabel(seed)
  local results = {}
  for i, overrides in ipairs(sweep) do
    results[i] = NebulaExport.exportNebula(nebula, seed, outDir, {
      name = name,
      overrides = overrides,
    })
  end
  return results
end

NebulaExport.seedPathLabel = seedPathLabel

return NebulaExport
