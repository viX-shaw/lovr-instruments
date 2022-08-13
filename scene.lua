

local world
local hands = {
  colliders = {},
  touching = {}
}
local framerate = 1 / 72 -- fixed framerate is recommended for physics updates
local collisionCallbacks = {}

function lovr.load()
  world = lovr.physics.newWorld(0, -2, 0, false)
    -- ground plane
  local box = world:newBoxCollider(vec3(0, 0, 0), vec3(20, 0.1, 20))
    -- just one lonely piano key
  local pianokeyCollider = world:newBoxCollider(vec3(0,1.7,-0.8), vec3(0.02, 0.01, 0.04))
  pianokeyCollider:setKinematic(true)
  
  --create colliders for all finger tips
  local count = 1
  for _, hand in ipairs({'left', 'right'}) do
    for idx, joint in ipairs(lovr.headset.getSkeleton(hand) or {}) do
      if idx == 6 or idx == 11 or idx == 16 or idx == 21 or idx == 26 then
        -- hands.colliders[count] = world:newSphereCollider(0,2,0, 0.015)
        table.insert(hands.colliders, world:newSphereCollider(0,2,0, 0.015))
        table.insert(hands.touching, nil)

        hands.colliders[count]:setLinearDamping(0.2)
        hands.colliders[count]:setAngularDamping(0.3)
        hands.colliders[count]:setMass(0.1)
        registerCollisionCallback(hands.colliders[count], 
          function (collider, world)
            -- store keys that were last touched by the fingers
            hands.touching[count] = collider
            -- Push note of the touching key to channel below
          end)
          count = count + 1
      end
    end
  end

  print("Elements count in Hands Colliders  "..#hands.colliders)
  print("Elements count in Hands Touching  "..#hands.touching)
end

function lovr.update(dt)
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
      if idx == 6 or idx == 11 or idx == 16 or idx == 21 or idx == 26 then
        local rw = mat4(joint)
        local vr = mat4(hands.colliders[count]:getPose())
        local angle, ax,ay,az = quat(rw):mul(quat(vr):conjugate()):unpack()
        angle = ((angle + math.pi) % (2 * math.pi) - math.pi) -- for minimal motion wrap to (-pi, +pi) range
        hands.colliders[count]:applyTorque(vec3(ax, ay, az):mul(angle * dt * 1))
        hands.colliders[count]:applyForce((vec3(rw:mul(0,0,0)) - vec3(vr:mul(0,0,0))):mul(dt * 2000))
        count = count + 1
      end
    end
  end

  -- Touching keys to set again in collision resolver
  -- Maybe not needed, can use the previous values to check for 'pressed' and 'up' events
  -- for _, key in ipairs(hands.touching) do
  --   key = nil
  -- end