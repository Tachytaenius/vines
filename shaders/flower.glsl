uniform float n;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec2 pos = textureCoords * 2.0 - 1.0;
	float angle = atan(pos.y, pos.x);
	float r = (1.0 - cos(n * angle)) / 2.0;
	if (length(pos) <= r) {
		return colour;
	}
	return vec4(0.0);
}
