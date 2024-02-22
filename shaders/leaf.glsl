uniform float fatness;

float upperBound(float s) {
	return pow(s, 1.0 / (fatness + 1.0));
}

float lowerBound(float s) {
	return pow(s, fatness + 1.0);
}

// Not actually being used for fog

float calculateFogFactor(float dist, float maxDist, float fogFadeLength) { // More fog the further you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return dist < maxDist ? 0.0 : 1.0;
	}
	return clamp((dist - maxDist + fogFadeLength) / fogFadeLength, 0.0, 1.0);
}

float calculateFogFactor2(float dist, float fogFadeLength) { // More fog the closer you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return 1.0; // Immediate fog
	}
	return clamp(1 - dist / fogFadeLength, 0.0, 1.0);
}

float distanceToLine(vec2 lineStart, vec2 lineEnd, vec2 point) {
	vec2 v1 = lineEnd - lineStart;
	vec2 v2 = lineStart - point;
	vec2 v3 = vec2(v1.y, -v1.x);
	return abs(dot(v2, normalize(v3)));
}

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	if (lowerBound(textureCoords.s) <= textureCoords.t && textureCoords.t <= upperBound(textureCoords.s)) {
		float centreDarkening = (
			1.0 - calculateFogFactor2(
				distanceToLine(vec2(0.0), vec2(1.0), textureCoords),
				0.1
			)
			* (
				1.0 - calculateFogFactor(
					length(textureCoords),
					sqrt(2.0), // length(vec2(1.0))
					0.75
				)
			)
		) / 2.0 + 0.5;
		return colour * vec4(vec3(centreDarkening), 1.0);
	}
	return vec4(0.0);
}
