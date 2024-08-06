float3 palette( in float t, in float3 a, in float3 b, in float3 c, in float3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float3 rainbow( in float t)
{
    return palette(t, 0.5, 0.5, 1, float3(0, 0.33, 0.66));
}

float3 gammaCorrect( in float3 col)
{
    return pow(saturate(col), 2.2);
}

// https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
float3 hueShift( float3 color, float hueAdjust ){
    hueAdjust *= UNITY_PI * 2;

    const float3  kRGBToYPrime = float3 (0.299, 0.587, 0.114);
    const float3  kRGBToI      = float3 (0.596, -0.275, -0.321);
    const float3  kRGBToQ      = float3 (0.212, -0.523, 0.311);

    const float3  kYIQToR     = float3 (1.0, 0.956, 0.621);
    const float3  kYIQToG     = float3 (1.0, -0.272, -0.647);
    const float3  kYIQToB     = float3 (1.0, -1.107, 1.704);

    float   YPrime  = dot (color, kRGBToYPrime);
    float   I       = dot (color, kRGBToI);
    float   Q       = dot (color, kRGBToQ);
    float   hue     = atan2 (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    float3    yIQ   = float3 (YPrime, I, Q);

    return float3( dot (yIQ, kYIQToR), dot (yIQ, kYIQToG), dot (yIQ, kYIQToB) );

}