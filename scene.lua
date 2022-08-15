local world
local hands = {
  colliders = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
  touching = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}
}
local framerate = 1 / 72 -- fixed framerate is recommended for physics updates
local collisionCallbacks = {}

local keys = {
  colliders = {},
}

local fingertipsize = 0.01

local scene = {}

function scene.load()
  -- Setup Thread(s) to signal play
  local channelName = 'thread1'
  channel = lovr.thread.getChannel(channelName)
  thread = lovr.thread.newThread('play.lua')
  thread:start(channelName)
  -- Setup complete  
  world = lovr.physics.newWorld(0, -2, 0, false)
    -- ground plane
  local box = world:newBoxCollider(vec3(0, 0, 0), vec3(20, 0.1, 20))
    -- just one lonely piano key
  local pianokeyCollider = world:newBoxCollider(vec3(0.1,1.5,-0.35), vec3(0.02, 0.01, 0.07))
  pianokeyCollider:setKinematic(true)
  pianokeyCollider:setUserData(52)
  table.insert(keys.colliders, pianokeyCollider)
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
        if hands.touching[count] == nil or (lovr.timer.getTime() - hands.touching[count]) > 1.0 then
          if collider:getUserData() and collider:getUserData() > 10 then   
            print("Pressing...  "..collider:getUserData())
            channel:push(collider:getUserData())
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
      lovr.graphics.box('fill', pose)
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