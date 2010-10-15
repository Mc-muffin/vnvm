function clamp(v, m, M)
{
	if (v < m) return m;
	if (v > M) return M
	return v;
}

function between(v, m, M)
{
	return (v >= m) && (v < M);
}

function pointInRect(point, rect)
{
	return (
		between(point.x, rect.x, rect.x + rect.w) &&
		between(point.y, rect.y, rect.y + rect.h)
	);
}

function interpolate(from, to, stepf)
{
	stepf = clamp(stepf, 0.0, 1.0);
	return (to - from) * stepf + from;
}

/**
 * Returns an integer value between min and max, excluding max.
 */
function rand_between(min, max)
{
	return min + (rand() % (max - min));
}

/**
 * Returns a float value between 0.0 and 1.0
 */
function rand_float()
{
	return rand() / RAND_MAX.tofloat();
}