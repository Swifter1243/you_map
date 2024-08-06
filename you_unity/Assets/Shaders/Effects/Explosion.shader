Shader "You/Explosion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Distance ("Distance", Range(0,1)) = 0
        _DistLow ("Distance Low", Float) = 0
        _DistHigh ("Distance High", Float) = 1
        _Color1 ("Color 1", Color) = (1,1,1)
        _Color2 ("Color 2", Color) = (1,1,1)
        _Opacity ("Opacity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZTest Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Noise.cginc"
            #include "Assets/CGIncludes/Colors.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Distance;
            float _DistLow;
            float _DistHigh;
            float3 _Color1;
            float3 _Color2;
            float _Opacity;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = v.vertex;
                return o;
            }

            float2 rotate(float2 vec, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return float2(
                    dot(vec, float2(c, -s)),
                    dot(vec, float2(s, c))
                );
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 vec = i.pos.xy;
                vec = rotate(vec, _Distance * 5 * length(vec));
                float rawAngle = atan2(vec.y, vec.x);
                rawAngle += length(vec) * 4;
                float angle = (rawAngle + UNITY_PI) / UNITY_PI / 2;

                float3 col = 0;
                float a = atan2(abs(vec.y), vec.x);
                col += gnoise((a - angle) * 20);

                float dist = lerp(_DistLow, _DistHigh, _Distance);
                col *= pow(1 - abs(length(vec) - dist + 0.3), 60);
                col *= pow(saturate(1 - length(vec) * 2), 3);

                float r = dist * UNITY_PI * 2 + a * 4 + rawAngle * 3 * (1 - _Distance) * dist;
                float dir = gnoise(vec * 4 + float2(cos(r), sin(r)));
                float amt = 5 + dist * 3;
                float n = pow(gnoise(float2(cos(dir) * amt, sin(dir) * amt)), 7);
                col = lerp(col * n, col, 0.2);

                float t = cos(a * 2) * 0.5 + 0.5;
                // float3 col1 = palette(t,
                //     float3(0.821, 0.328, 0.242),
                //     float3(0.659, 0.481, 0.896),
                //     float3(0.612, 0.34, 0.296),
                //     float3(2.82, 3.026, -0.273)
                // );
                float3 col1 = palette(t * 0.3 + 0.5,
                    float3(1.000, 0.500, 0.500),
                    float3(0.500, 0.500, 0.500),
                    float3(0.750, 1.000, 0.667),
                    float3(0.800, 1.000, 0.333)
                );
                float3 col2 = rainbow(t * 0.4);
                // float3 col2 = lerp(_Color1, _Color2, t);

                col *= lerp(lerp(col1, col2, _Distance * 3 - 0.5), 1, (1 - _Distance) * 0.2) * 100;

                float circ = pow(saturate(1 - length(vec)), 10) * 0.5;
                col += circ * saturate(sin(_Distance * UNITY_PI * 2));
                // col = col1;

                // col *= lerp(palette(cos(a * 2) * 0.5 + 0.5,
                //     float3(0.821, 0.328, 0.242),
                //     float3(0.659, 0.481, 0.896),
                //     float3(0.612, 0.34, 0.296),
                //     float3(2.82, 3.026, -0.273)
                // ), 1, 0.2) * 2;

                // col *= lerp(palette(cos(a * 2) * 0.5 + 0.5,
                //     float3(1.000, 0.500, 0.500),
                //     float3(0.500, 0.500, 0.500),
                //     float3(0.750, 1.000, 0.667),
                //     float3(0.800, 1.000, 0.333)
                // ), 1, 0.2) * 2;

                // col = n;

                col *= _Opacity;
                

                return float4(col, Luminance(col) * 2);
            }
            ENDCG
        }
    }
}
