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