const float tau = 6.28318530718;
const float m = 0.1;

uniform float n;
uniform float p;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec2 pos = textureCoords * 2.0 - 1.0;
	float angle = atan(pos.y, pos.x);
	// float r = (1.0 - cos(n * angle)) / 2.0;
	float tauOverN = tau / n;
	float r =
		pow(
			(cos(n * angle) + 1.0) / 2.0, // Basic flower,
			// exponentiated with fattening factor:
			pow(
				// which is a number which is 1 in the centre of a petal's angle and 0 off to the sides,
				abs(
					mod(angle + 0.5 * tauOverN, tauOverN) / tauOverN - 0.5
				),
				// exponentiated by a fatness factor,
				p *
					// which gets multiplied by a factor that reduces the effective fatness factor when there are less petals, since less petals -> more space per petal -> fatter petals -> fatness depending on n. This *tries* to cancel that out
					n * m / (n * m + 1.0)
			)
		)
	;
	if (length(pos) <= r) {
		return colour;
	}
	return vec4(0.0);
}
