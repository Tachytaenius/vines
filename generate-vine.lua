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
	local position = vec2.clone(parameters.startPosition)
	local velocity = vec2.clone(parameters.startVelocity)
	local acceleration = vec2.clone(parameters.startAcceleration)
	local thickness = parameters.startThickness
	local thicknessChange = 0 -- Don't care value, gets changed immediately,
	local thicknessChangeTimer = 0 -- because this is zero
	local time = 0
	local newAccelTimer = parameters.newAccelTimerLengthBase + love.math.random() * parameters.newAccelTimerLengthVariation
	local vertices = {}

	while time < parameters.timeLimit do
		-- Alter thickness
		thicknessChangeTimer = thicknessChangeTimer - parameters.timeStep
		if thicknessChangeTimer <= 0 then
			thicknessChangeTimer = parameters.newThicknessChangeTimerLengthBase + love.math.random() * parameters.newThicknessChangeTimerLengthVariation
			thicknessChange = (love.math.random() * 2 - 1) * parameters.maxThicknessChangeMagnitude
		end
		thickness = math.max(parameters.minimumThickness, math.min(parameters.maximumThickness, thickness + thicknessChange * parameters.timeStep))

		-- Get tapering effect, which affects effective thickness
		local tapering = math.min(
			1 - calculateFogFactor2(time, parameters.taperTime),
			1 - calculateFogFactor(time, parameters.timeLimit, parameters.taperTime)
		)
		local effectiveThickness = thickness * tapering

		-- Make leaves
		local function newLeaf(side)
			local ret = {
				relativeAngle = tau / 4 * side,
				fatness = 3.5,
				scale = ((effectiveThickness - parameters.minimumThickness) / parameters.maximumThickness + 1) * 10 -- TEMP magic numbers
			}
			return ret
		end
		local leaves = {}
		if love.math.random() < getProbabilityTime(parameters.leafProbabilityPerTime * tapering, parameters.timeStep) then
			leaves[#leaves + 1] = newLeaf(1)
		end
		if love.math.random() < getProbabilityTime(parameters.leafProbabilityPerTime * tapering, parameters.timeStep) then
			leaves[#leaves + 1] = newLeaf(-1)
		end

		-- Make flowers
		local flowers = {}
		if love.math.random() < getProbabilityTime(parameters.flowerProbabilityPerTime * tapering, parameters.timeStep) then
			flowers[#flowers + 1] = {
				radius = parameters.minimumFlowerRadius + love.math.random() * (parameters.maximumFlowerRadius - parameters.minimumFlowerRadius),
				centreRadius = parameters.minimumFlowerCentreRadius + love.math.random() * (parameters.maximumFlowerCentreRadius - parameters.minimumFlowerCentreRadius),
				angle = love.math.random() * tau,
				colour = shallowClone(parameters.flowerColour),
				centreColour = shallowClone(parameters.flowerCentreColour),
				n = love.math.random(parameters.minimumFlowerN, parameters.maximumFlowerN)
			}
		end

		-- Lay down next point
		vertices[#vertices + 1] = {
			thickness = effectiveThickness,
			position = vec2.clone(position),
			colour = shallowClone(parameters.colour),
			leaves = leaves,
			flowers = flowers
		}

		-- Control acceleration
		newAccelTimer = newAccelTimer - parameters.timeStep
		if newAccelTimer <= 0 then
			newAccelTimer = parameters.newAccelTimerLengthBase + love.math.random() * parameters.newAccelTimerLengthVariation
			acceleration = randCircle(parameters.maxAcceleration)
		end

		-- Control velocity
		if velocity == vec2() and acceleration == vec2() then
			-- Since the vine won't be moving, give it a random push
			velocity = vec2.fromAngle(love.math.random() * tau) * parameters.startAcceleration * parameters.timeStep
		end
		if #velocity < parameters.minimumSpeed then
			velocity = normaliseOrZero(velocity) * parameters.minimumSpeed
		end
		if #velocity > parameters.maximumSpeed then
			velocity = vec2.normalise(velocity) * parameters.maximumSpeed
		end
		velocity = velocity + acceleration * parameters.timeStep

		-- Step forwards
		position = position + velocity * parameters.timeStep
		time = time + parameters.timeStep
	end

	return {
		vertices = vertices
	}
end

return generateVine
