local world
local hands = {
  colliders = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
  touching = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}
}
local framerate = 1 / 72 -- fixed framerate is recommended for physics updates
local collisionCallbacks = {}

local keys = {
  colliders = {},
  offsets = {}
}

local fingertipsize = 0.006
local keysStartPos = vec3(-0.15, 1.7, -0.35) -- vec3(0.1,1.5,-0.35)
local bKeyShape = vec3(0.01, 0.01, 0.07)
local wKeyShape = vec3(0.03, 0.01, 0.115)

local octaves = 1

local channelCounter = 0
local channelNames = {'1', '2', '3'}
local channels = {}
local scene = {}

local mode = true --also true - allowed to play, false - to move stuff around

local wasPressed = false
local wasReleased = false

local startTime = lovr.timer.getTime()

local drag = {
  active = false,
}

function contains(tb, key)
  for _, en in ipairs(tb) do
    if en == key then return 1 end
  end
  return 0
end

function checkMode()
  if hands.colliders[1] ~= nil and lovr.timer.getTime() - startTime > 5.0 then
    local x1, y1, z1 = hands.colliders[6]:getPosition()
    local x2, y2, z2 = hands.colliders[9]:getPosition()

    if math.abs(x2-x1)+math.abs(y2-y1)+math.abs(z2-z1) < 0.033 then
      mode = not mode
      print("Mode.."..tostring(mode))
    end
  end
end

function alternateMotion()
  if wasPressed then
    for idx, coll in ipairs(keys.colliders) do
      local offset = vec3(coll:getPosition()) - vec3(hands.colliders[6]:getPosition())
      local halfSize = 0.5--wKeyShape.x
      local x, y, z = offset:unpack()
      if math.abs(x) < halfSize and math.abs(y) < halfSize and math.abs(z) < halfSize then
        drag.active = true
        keys.offsets[idx]:set(offset)
      end
    end
  end

  if drag.active then
    for idx, coll in ipairs(keys.colliders) do
      local x, y, z = (keys.offsets[idx] + vec3(hands.colliders[6]:getPosition())):unpack()
      coll:setPosition(x, y, z)
    end
    if wasReleased then
      drag.active = false
    end
  end
end

function getChannel()
  channelCounter = channelCounter + 1
  if channelCounter > 100 then channelCounter = 1 end
  return channels[(channelCounter % (#channels)) + 1]
end

function setupChannels()
  -- Setup Thread(s) to signal play
  for _, channelName in ipairs(channelNames) do
    local channel = lovr.thread.getChannel(channelName)
    local thread = lovr.thread.newThread('play.lua')
    thread:start(channelName)
    table.insert(channels, channel)
  end
end

function scene.load()
  setupChannels()
  -- Setup complete  
  world = lovr.physics.newWorld(0, -2, 0, false)
    -- ground plane
  local box = world:newBoxCollider(vec3(0, 0, 0), vec3(20, 0.1, 20))
    -- just one lonely piano key

  local pianoKey = 48
  for octave = 0, octaves do
    local newPos = 0
    for key = 1, 5 do
      newPos = keysStartPos + vec3(wKeyShape.x, 0.0, 0.0):mul(key) + vec3(0.01, 0.005, -0.0125)
      if key > 2 then
        newPos = keysStartPos + vec3(wKeyShape.x, 0.0, 0.0):mul(key+1) + vec3(0.01, 0.005, -0.0125)
      end
      local pianokeyCollider = world:newBoxCollider(newPos, bKeyShape)
      pianokeyCollider:setKinematic(true)
      pianokeyCollider:setUserData(pianoKey)
      table.insert(keys.colliders, pianokeyCollider)
      table.insert(keys.offsets, lovr.math.newVec3())
      pianoKey = pianoKey + 1
    end
    for key = 1, 7 do
      newPos = keysStartPos + vec3(wKeyShape.x, 0.0, 0.0):mul(key) + vec3(0.001, 0.0, 0.0)
      local pianokeyCollider = world:newBoxCollider(newPos, wKeyShape)
      pianokeyCollider:setKinematic(true)
      pianokeyCollider:setUserData(pianoKey)
      table.insert(keys.colliders, pianokeyCollider)
      table.insert(keys.offsets, lovr.math.newVec3())
      pianoKey = pianoKey + 1
    end
    keysStartPos = newPos
  end

  --create colliders for all finger tips
  local count = 1
  for count = 1, 10 do
    hands.colliders[count] = world:newSphereCollider(0,2,0, fingertipsize)
    hands.colliders[count]:setLinearDamping(0.2)
    hands.colliders[count]:setAngularDamping(0.3)
    hands.colliders[count]:setMass(0.1)
    hands.colliders[count]:setUserData(count)
    registerCollisionCallback(hands.colliders[count], 
      function (collider, world)
        -- store keys that were last touched by the fingers
        -- local colliderId = collider:getUserData()
        if mode and (hands.touching[count] == nil or (lovr.timer.getTime() - hands.touching[count]) > 0.5) then
          if collider:getUserData() and collider:getUserData() > 10 then   
            print("Pressing...  "..collider:getUserData())
            getChannel():push(collider:getUserData())
            hands.touching[count] = lovr.timer.getTime()
          end
        end
        -- Push note of the touching key to channel below
        -- if keys.bindings[collider] ~= nil then
        --   print("Pressing...  "..collider:getUserData())
        -- end
      end)
  end
end

function scene.update(dt)
    -- override collision resolver to notify all colliders that have registered their callbacks
  world:update(framerate, function(world) 
    world:computeOverlaps()
    for shapeA, shapeB in world:overlaps() do
      local areColliding = world:collide(shapeA, shapeB)
      if areColliding then
        cbA = collisionCallbacks[shapeA]
        if cbA then cbA(shapeB:getCollider(), world) end
        cbB = collisionCallbacks[shapeB]
        if cbB then cbB(shapeA:getCollider(), world) end
      end
    end
  end)

  -- hand updates - location, orientation, solidify on trigger button, grab on grip button
  -- finger tip updates - location
  local count = 1
  for _, hand in ipairs({'left', 'right'}) do
    for idx, joint in ipairs(lovr.headset.getSkeleton(hand) or {}) do
      if joint ~= nil and idx == 6 or idx == 11 or idx == 16 or idx == 21 or idx == 26 then
        local rw = mat4(unpack(joint))
        local vr = mat4(hands.colliders[count]:getPose())
        local angle, ax,ay,az = quat(rw):mul(quat(vr):conjugate()):unpack()
        angle = ((angle + math.pi) % (2 * math.pi) - math.pi) -- for minimal motion wrap to (-pi, +pi) range
        hands.colliders[count]:applyTorque(vec3(ax, ay, az):mul(angle * dt * 1))
        hands.colliders[count]:applyForce((vec3(rw:mul(0,0,0)) - vec3(vr:mul(0,0,0))):mul(dt * 2000))
        count = count + 1
      end
    end
  end

  checkMode()
  if not mode then
    local x1, y1, z1 = hands.colliders[6]:getPosition() -- right index tip
    local x2, y2, z2 = hands.colliders[7]:getPosition() -- right thumb tip

    -- if lovr.headset.wasPressed('left','trigger') then
    if math.abs(x2-x1)+math.abs(y2-y1)+math.abs(z2-z1) < 0.033 then
      if not wasPressed then
        wasPressed = true
        print("wasPressed")
      end
      wasReleased = false
    else
      if wasPressed then
        wasReleased = true
      end
      wasPressed = false
    end
    alternateMotion() -- only change positions when changing location of the piano
  end
end

-- Touching keys to set again in collision resolver
-- Maybe not needed, can use the previous values to check for 'pressed' and 'up' events
-- for _, key in ipairs(hands.touching) do
--   key = nil
-- end

function scene.draw()
  for i, collider in ipairs(hands.colliders) do
    local alpha = hands.touching[i] and 1 or 0.8
    lovr.graphics.setColor(0.1, 0.3, 0.7)
    if not mode then
      lovr.graphics.setColor(0.1, 0.3, 0.3)
    end
    drawCollider(collider, 'sphere')
  end
  
  lovr.math.setRandomSeed(0)
  for i, collider in ipairs(keys.colliders) do
    local shade = 0.2 + 0.6 + lovr.math.random()
    lovr.graphics.setColor(shade, shade, shade)
    drawCollider(collider, 'box')
  end
end

function drawCollider(collider, shapetype)
  local pose = mat4(collider:getPose())
  local shape = collider:getShapes()[1]
  -- print(shape)
  if shape then
    if shapetype == 'box' then
      local size = vec3(shape:getDimensions())
      pose:scale(size)
      lovr.graphics.box('line', pose)
    end
    if shapetype == 'sphere' then
      -- lovr.graphics.sphere(vec3(pose):unpack(), fingertipsize)
      -- print("Sphere -- "..shape:getRadius())
      -- print(vec3(pose))
      -- lovr.graphics.points(vec3(pose):unpack())
      local x, y, z = vec3(pose):unpack()
      lovr.graphics.sphere(x,y,z, shape:getRadius())
    end
  end
  lovr.graphics.setShader()
end


function registerCollisionCallback(collider, callback)
  collisionCallbacks = collisionCallbacks or {}
  for _, shape in ipairs(collider:getShapes()) do
    collisionCallbacks[shape] = callback
  end
  -- to be called with arguments callback(otherCollider, world) from update function
end

return scene