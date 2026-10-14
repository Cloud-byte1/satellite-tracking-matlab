# Modeling Assumptions and Two-Body Derivation

## Units and constants

The model uses kilometres and seconds consistently:

- Earth gravitational parameter: `mu = 398600.4418 km^3/s^2`
- Earth equatorial radius: `R_E = 6378.137 km`
- Initial altitude: `h = 500 km`
- Initial geocentric radius: `r_0 = R_E + h = 6878.137 km`

The numerical value of `mu` already combines Newton's gravitational constant and
Earth's mass: `mu = G M_E`. Mixing metres with this kilometre-based value produces
errors of several orders of magnitude.

## Reference frame

States are Cartesian in an ideal Earth-centered inertial frame. Earth is fixed at
the origin for the two-body calculation. The six-state vector is

```text
y = [x, y, z, vx, vy, vz]^T.
```

The Day 1 circular orbit is equatorial, begins on the positive x-axis, and travels
in the positive y-direction. This is a convenient initial orientation, not a claim
that a particular real satellite follows this orbit.

## Newtonian two-body derivation

Newton's law of universal gravitation gives the force on satellite mass `m`:

```text
F = -(G M_E m / r^3) r_vector.
```

Using `F = m a`, cancelling the satellite mass, and defining `mu = G M_E` gives

```text
r_vector_double_dot = -(mu / r^3) r_vector.
```

The satellite mass therefore does not appear in the ideal two-body acceleration.
In Cartesian components, the second-order vector equation becomes six coupled
first-order equations required by `ode45`:

```text
x_dot  = vx                 vx_dot = -mu*x/r^3
y_dot  = vy                 vy_dot = -mu*y/r^3
z_dot  = vz                 vz_dot = -mu*z/r^3
r = sqrt(x^2 + y^2 + z^2)
```

For a circular orbit, gravity supplies the centripetal acceleration:

```text
mu/r^2 = v_c^2/r
v_c = sqrt(mu/r)
T = 2*pi*sqrt(r^3/mu)
specific energy = v^2/2 - mu/r = -mu/(2r)
```

The last period relation is Kepler's third law for a circular orbit.

## Numerical method

MATLAB `ode45` is an adaptive explicit Runge-Kutta (Dormand-Prince) solver suited
to this smooth, non-stiff initial-value problem. The production run uses relative
tolerance `1e-11`, absolute tolerance `1e-12`, and a maximum internal step of
`T/200`. Requested output samples do not by themselves force the solver's internal
step size; the adaptive solver chooses internal steps to control local error.

## Day 1 force-model assumptions

Included:

- Spherical point-mass Earth gravity
- Constant Earth gravitational parameter
- Numerically propagated Cartesian state

Excluded until later project stages:

- Earth oblateness and higher harmonics, including J2
- Atmospheric drag
- Solar radiation pressure
- Third-body gravity
- Earth rotation and Earth-fixed coordinate conversion
- Maneuvers and attitude dynamics
- Relativistic acceleration corrections
- Measurement noise and orbit determination

Under these ideal assumptions, specific orbital energy and angular momentum are
constants. Their numerical drift is therefore useful for verifying the integrator.

## Modern-physics connection

Day 1 uses Newtonian gravity because it predicts low-Earth-orbit motion accurately
enough for the initial numerical foundation. Later timing calculations distinguish
coordinate and proper time. Special relativity makes a moving satellite clock run
slower, while the weaker gravitational potential at orbital altitude makes it run
faster relative to a clock on Earth's surface. Those effects are timing corrections;
they are not included in the Day 1 Newtonian trajectory model.

