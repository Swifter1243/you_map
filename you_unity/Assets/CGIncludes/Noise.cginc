float hashwithoutsine11(float p)
{
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float2 hash( float2 p )
{
    //p = mod(p, 4.0); // tile
    p = float2(dot(p,float2(127.1,311.7)),
    dot(p,float2(269.5,183.3)));
    return frac(sin(p)*18.5453);
}

float hash(float3 p3)
{
    p3  = frac(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// return distance, and cell id
float2 voronoi( in float2 x )
{
    float2 n = floor( x );
    float2 f = frac( x );

    float3 m = 8;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        float2  g = float2( float(i), float(j) );
        float2  o = hash( n + g );
        float2  r = g - f + o;
        // float2  r = g - f + (0.5+0.5*sin(_Time.y+6.2831*o));
        float d = dot( r, r );
        if( d<m.x )
        m = float3( d, o );
    }

    return float2( sqrt(m.x), m.y+m.z );
}

float3 voronoi( in float3 x )
{
    float3 p = floor( x );
    float3 f = frac( x );

	float id = 0.0;
    float2 res = 100;
    for( int k=-1; k<=1; k++ )
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        float3 b = float3( float(i), float(j), float(k) );
        float3 r = float3( b ) - f + hash( p + b );
        float d = dot( r, r );

        if( d < res.x )
        {
			id = dot( p+b, float3(1.0,57.0,113.0 ) );
            res = float2( d, res.x );
        }
        else if( d < res.y )
        {
            res.y = d;
        }
    }

    return float3( sqrt( res ), abs(id) );
}

float2 grad( float2 z )  // replace this anything that returns a random vector
{
    // 2D to 1D  (feel free to replace by some other)
    int n = z.x+z.y*11111;

    // Hugo Elias hash (feel free to replace by another one)
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;

    return float2(cos(float(n)),sin(float(n)));
}

float gnoise( in float2 p )
{
    float2 i = float2(floor( p ));
    float2 f =       frac( p );

    float2 u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead

    return lerp( lerp( dot( grad( i+float2(0,0) ), f-float2(0.0,0.0) ),
    dot( grad( i+float2(1,0) ), f-float2(1.0,0.0) ), u.x),
    lerp( dot( grad( i+float2(0,1) ), f-float2(0.0,1.0) ),
    dot( grad( i+float2(1,1) ), f-float2(1.0,1.0) ), u.x), u.y) + 0.5;
}

float gnoise3D( in float3 x )
{
    // grid
    float3 p = floor(x);
    float3 w = frac(x);

    // quintic interpolant
    float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);


    // gradients
    float3 ga = hash( p+float3(0.0,0.0,0.0) );
    float3 gb = hash( p+float3(1.0,0.0,0.0) );
    float3 gc = hash( p+float3(0.0,1.0,0.0) );
    float3 gd = hash( p+float3(1.0,1.0,0.0) );
    float3 ge = hash( p+float3(0.0,0.0,1.0) );
    float3 gf = hash( p+float3(1.0,0.0,1.0) );
    float3 gg = hash( p+float3(0.0,1.0,1.0) );
    float3 gh = hash( p+float3(1.0,1.0,1.0) );

    // projections
    float va = dot( ga, w-float3(0.0,0.0,0.0) );
    float vb = dot( gb, w-float3(1.0,0.0,0.0) );
    float vc = dot( gc, w-float3(0.0,1.0,0.0) );
    float vd = dot( gd, w-float3(1.0,1.0,0.0) );
    float ve = dot( ge, w-float3(0.0,0.0,1.0) );
    float vf = dot( gf, w-float3(1.0,0.0,1.0) );
    float vg = dot( gg, w-float3(0.0,1.0,1.0) );
    float vh = dot( gh, w-float3(1.0,1.0,1.0) );

    // interpolation
    return va +
    u.x*(vb-va) +
    u.y*(vc-va) +
    u.z*(ve-va) +
    u.x*u.y*(va-vb-vc+vd) +
    u.y*u.z*(va-vc-ve+vg) +
    u.z*u.x*(va-vb-ve+vf) +
    u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
}

// https://www.shadertoy.com/view/3sd3Rs
float hash( uint n )
{   // integer hash copied from Hugo Elias
    n = (n<<13U)^n;
    n = n*(n*n*15731U+789221U)+1376312589U;
    return float(n&0x0fffffffU)/float(0x0fffffff);
}

float noise1d( float x )
{
    // setup
    float i = floor(x);
    float f = frac(x);
    float s = sign(frac(x/2.0)-0.5);

    // use some hash to create a random value k in [0..1] from i
    float k = hash(uint(i));
    //float k = 0.5+0.5*sin(i);
    // float k = frac(i*.1731);

    // quartic polynomial
    return s*f*(f-1.0)*((16.0*k-4.0)*f*(f-1.0)-1.0);
}

// https://www.shadertoy.com/view/XsX3zB
float3 random3(float3 c) {
    float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
static float F3 = 0.3333333;
static float G3 = 0.1666667;

/* 3d simplex noise */
float simplex(float3 p) {
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

    /* calculate s and x */
    float3 s = floor(p + dot(p, F3));
    float3 x = p - s + dot(s, G3);

    /* calculate i1 and i2 */
    float3 e = step(0, x - x.yzx);
    float3 i1 = e*(1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy*(1.0 - e);

    /* x1, x2, x3 */
    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0*G3;
    float3 x3 = x - 1.0 + 3.0*G3;

    /* 2. find four surflets and store them in d */
    float4 w, d;

    /* calculate surflet weights */
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
    w = max(0.6 - w, 0.0);

    /* calculate surflet components */
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    /* multiply d by w^4 */
    w *= w;
    w *= w;
    d *= w;

    /* 3. return the sum of the four surflets */
    return dot(d, 52) * 0.5 + 0.5;
}
