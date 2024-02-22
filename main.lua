-- TODO: Go throguh the code and replace all magic numbers with parameters
-- TODO: Replace thickness * tapering mode of tapering with a ramp-up period where thickness is controlled by tapering *instead of* multiplied with its progress

local vec2 = require("lib.mathsies").vec2

local generateVine = require("generate-vine")

local tau = math.pi * 2

local dummyTexture, leafShader, flowerShader

local vines

local function sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	end
	return 0
end

function love.load()
	dummyTexture = love.graphics.newImage(love.image.newImageData(1, 1))
	leafShader = love.graphics.newShader("shaders/leaf.glsl")
	flowerShader = love.graphics.newShader("shaders/flower.glsl")

	vines = {}
	for _=1, 30 do
		vines[#vines + 1] = generateVine({
			startPosition = vec2(
				love.math.random() * 2 - 0.5,
				love.math.random() * 2 - 0.5
			) * vec2(love.graphics.getDimensions()),
			startVelocity = vec2.fromAngle(love.math.random() * tau) * 40,
			startAcceleration = vec2(),
			minimumSpeed = 20,
			maximumSpeed = 25,
			timeStep = 0.125,
			timeLimit = 40 + love.math.random() * 10,
			initialAcceleration = 3,
			colour = {0.4, 0.6, 0.2},
			flowerColour = {0.9, 0.3, 0.6},
			flowerCentreColour = {1, 1, 1},
			newAccelTimerLengthBase = 3,
			newAccelTimerLengthVariation = 1,
			maxAcceleration = 7,
			startThickness = 3,
			minimumThickness = 3, -- Ignoring tapering
			maximumThickness = 5,
			leafProbabilityPerTime = 0.25,
			flowerProbabilityPerTime = 0.1,
			taperTime = 1,
			newThicknessChangeTimerLengthBase = 3,
			newThicknessChangeTimerLengthVariation = 1,
			maxThicknessChangeMagnitude = 0.3,
			minimumFlowerRadius = 10,
			maximumFlowerRadius = 14,
			minimumFlowerCentreRadius = 2,
			maximumFlowerCentreRadius = 3,
			minimumFlowerN = 4,
			maximumFlowerN = 7
			-- add branching
		})
	end
end

function love.draw()
	for _, vine in ipairs(vines) do
		for i, vertex in ipairs(vine.vertices) do
			if i + 1 <= #vine.vertices then
				local nextVertex = vine.vertices[i + 1]
				love.graphics.setColor(vertex.colour)
				love.graphics.setLineWidth(vertex.thickness)
				love.graphics.line(
					vertex.position.x,
					vertex.position.y,
					nextVertex.position.x,
					nextVertex.position.y
				)
			end
		end
		for i, vertex in ipairs(vine.vertices) do
			for _, leaf in ipairs(vertex.leaves) do
				local normal
				-- Specially handle leaves on ends
				if i == 1 then
					local nextVertex = vine.vertices[i + 1]
					normal = vec2.rotate(vec2.normalise(nextVertex.position - vertex.position), sign(leaf.relativeAngle) * (math.abs(leaf.relativeAngle) + tau / 8))
				elseif i == #vine.vertices then
					local previousVertex = vine.vertices[i - 1]
					normal = vec2.rotate(vec2.normalise(vertex.position - previousVertex.position), sign(leaf.relativeAngle) * (math.abs(leaf.relativeAngle) - tau / 8))
				else
					local nextVertex = vine.vertices[i + 1]
					normal = vec2.rotate(vec2.normalise(nextVertex.position - vertex.position), leaf.relativeAngle)
				end
				local leafOrigin = vertex.position + normal * vertex.thickness / 2
				love.graphics.setShader(leafShader)
				leafShader:send("fatness", leaf.fatness)
				love.graphics.draw(dummyTexture, leafOrigin.x, leafOrigin.y, vec2.toAngle(normal) - tau / 8, leaf.scale)
			end
		end
		for _, vertex in ipairs(vine.vertices) do
			for _, flower in ipairs(vertex.flowers) do
				love.graphics.setShader(flowerShader)
				love.graphics.setColor(flower.colour)
				flowerShader:send("n", flower.n)
				love.graphics.draw(dummyTexture, vertex.position.x, vertex.position.y, flower.angle, flower.radius * 2, flower.radius * 2, 0.5, 0.5)
				love.graphics.setShader()
				love.graphics.setColor(flower.centreColour)
				love.graphics.circle("fill", vertex.position.x, vertex.position.y, flower.centreRadius)
			end
		end
		love.graphics.setShader()
	end
end
