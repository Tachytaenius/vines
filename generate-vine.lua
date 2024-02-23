local vec2 = require("lib.mathsies").vec2

local tau = math.pi * 2

local function normaliseOrZero(v)
	return v == vec2() and vec2() or vec2.normalise(v)
end

local function shallowClone(t)
	local ret = {}
	for k, v in pairs(t) do
		ret[k] = v
	end
	return ret
end

local function randCircle(r)
	return vec2.fromAngle(love.math.random() * tau) * math.sqrt(love.math.random()) * r
end

-- Original purpose was fog, can be anything applicable

-- More fog the further you are
local function calculateFogFactor(dist, maxDist, fogFadeLength)
	if fogFadeLength == 0 then -- Avoid dividing by zero
		return dist < maxDist and 0 or 1
	end
	return math.max(0, math.min(1, (dist - maxDist + fogFadeLength) / fogFadeLength))
end

-- More fog the closer you are
local function calculateFogFactor2(dist, fogFadeLength)
	if fogFadeLength == 0 then -- Avoid dividing by zero
		return 1 -- Immediate fog
	end
	return math.max(0, math.min(1, 1 - dist / fogFadeLength))
end

local function getProbabilityTime(chancePerTime, time)
	return 1 - (1 - chancePerTime) ^ time
end

local function generateVine(parameters)
	local vine = {
		position = vec2.clone(parameters.startPosition),
		velocity = vec2.clone(parameters.startVelocity),
		acceleration = vec2.clone(parameters.startAcceleration),
		thickness = parameters.startThickness,
		thicknessChange = 0, -- Don't care value, gets changed immediately,
		thicknessChangeTimer = 0, -- because this is zero
		time = 0,
		newAccelTimer = parameters.newAccelTimerLengthBase + love.math.random() * parameters.newAccelTimerLengthVariation,
		vertices = {}
	}
	for k, v in pairs(parameters) do
		assert(not vine[k])
		vine[k] = v
	end

	function vine.step(vine, dt)
		-- Alter thickness
		vine.thicknessChangeTimer = vine.thicknessChangeTimer - dt
		if vine.thicknessChangeTimer <= 0 then
			vine.thicknessChangeTimer = vine.newThicknessChangeTimerLengthBase + love.math.random() * vine.newThicknessChangeTimerLengthVariation
			vine.thicknessChange = (love.math.random() * 2 - 1) * vine.maxThicknessChangeMagnitude
		end
		vine.thickness = math.max(vine.minimumThickness, math.min(vine.maximumThickness, vine.thickness + vine.thicknessChange * dt))

		-- Get tapering effect, which affects effective thickness
		-- local tapering = math.min(
		-- 	1 - calculateFogFactor2(vine.time, vine.taperTime),
		-- 	1 - calculateFogFactor(vine.time, vine.timeLimit, vine.taperTime)
		-- )
		local tapering = 1
		local effectiveThickness = vine.thickness * tapering

		-- Make leaves
		local function newLeaf(side)
			local ret = {
				relativeAngle = tau / 4 * side,
				fatness = 3.5,
				scale = ((effectiveThickness - vine.minimumThickness) / vine.maximumThickness + 1) * 10 -- TEMP magic numbers
			}
			return ret
		end
		local leaves = {}
		if love.math.random() < getProbabilityTime(vine.leafProbabilityPerTime * tapering, dt) then
			leaves[#leaves + 1] = newLeaf(1)
		end
		if love.math.random() < getProbabilityTime(vine.leafProbabilityPerTime * tapering, dt) then
			leaves[#leaves + 1] = newLeaf(-1)
		end

		-- Make flowers
		local flowers = {}
		if love.math.random() < getProbabilityTime(vine.flowerProbabilityPerTime * tapering, dt) then
			flowers[#flowers + 1] = {
				radius = vine.minimumFlowerRadius + love.math.random() * (vine.maximumFlowerRadius - vine.minimumFlowerRadius),
				centreRadius = vine.minimumFlowerCentreRadius + love.math.random() * (vine.maximumFlowerCentreRadius - vine.minimumFlowerCentreRadius),
				angle = love.math.random() * tau,
				colour = shallowClone(vine.flowerColour),
				centreColour = shallowClone(vine.flowerCentreColour),
				n = love.math.random(vine.minimumFlowerN, vine.maximumFlowerN),
				p = love.math.random(vine.minimumFlowerP, vine.maximumFlowerP)
			}
		end

		-- Lay down next point
		vine.vertices[#vine.vertices + 1] = {
			thickness = effectiveThickness,
			position = vec2.clone(vine.position),
			colour = shallowClone(vine.colour),
			leaves = leaves,
			flowers = flowers
		}

		-- Control acceleration
		vine.newAccelTimer = vine.newAccelTimer - dt
		if vine.newAccelTimer <= 0 then
			vine.newAccelTimer = vine.newAccelTimerLengthBase + love.math.random() * vine.newAccelTimerLengthVariation
			vine.acceleration = randCircle(vine.maxAcceleration)
		end

		-- Control velocity
		if vine.velocity == vec2() and vine.acceleration == vec2() then
			-- Since the vine won't be moving, give it a random push
			vine.velocity = vec2.fromAngle(love.math.random() * tau) * vine.startAcceleration * dt
		end
		if #vine.velocity < vine.minimumSpeed then
			vine.velocity = normaliseOrZero(vine.velocity) * vine.minimumSpeed
		end
		if #vine.velocity > vine.maximumSpeed then
			vine.velocity = vec2.normalise(vine.velocity) * vine.maximumSpeed
		end
		vine.velocity = vine.velocity + vine.acceleration * dt

		-- Step forwards
		vine.position = vine.position + vine.velocity * dt
		vine.time = vine.time + dt
	end

	return vine
end

return generateVine
