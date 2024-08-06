Shader "You/Accretion"
{
    Properties
    {
        _Vibration ("Vibration", Range(0,1)) = 1
        _Flutter ("Flutter", Range(0,1)) = 1
        _ClipRadius ("Clip Radius", Range(0, 0.5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        // ZWrite Off
        // ZTest Always

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Colors.cginc"
            #include "Assets/CGIncludes/Noise.cginc"

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
                float3 objPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Vibration;
            float _Flutter;
            float _ClipRadius;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.objPos = v.vertex;
                return o;
            }

            const static float3 sunDirection = normalize(float3(1.,0.2,-0.2));

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
                float2 vec = i.objPos.xy;

                float rawAngle = atan2(vec.y, vec.x);
                float angle = (rawAngle + UNITY_PI) / UNITY_PI / 2;

                vec += gnoise(rotate(vec, _Time.y * 0.02) * 400) * 0.008;

                float3 col = 0.5;
                float a = atan2(abs(vec.y), vec.x);
                float dist = length(vec);
                // dist += sin(dist + _Time.y) * 0.01 + cos(dist + _Time.y * 0.3) * 0.04;

                float n = gnoise(dist * 60 + cos(rawAngle + _Time.y * 200) * 0.3 * _Vibration);
                col += n * 0.2;
                float flutter = hashwithoutsine11(_Time.y) * _Flutter;
                col += pow(n, 4) * (1 + flutter);

                col *= pow(dist, 4);
                col *= 1 - dist;

                col *= pow(1 - length(vec * 2), 2);
                col *= 1 - length(vec * 2);

                col *= 1000;

                col *= saturate(pow(dist * 5.3, 30));

                float3 rb = rainbow(dist * 3 + 0.5 + sin(rawAngle * 3) * 0.1);

                col *= rb;

                col = saturate(col);

                float lum = Luminance(col);

                float c = pow(1 - abs(angle - 0.5), 20);
                c *= pow(1 - dist, 10) * 30;

                // float clipVal = lum - 0.001 - c * 0.2;

                // clip(clipVal);

                clip(dist - _ClipRadius);

                // col = c;
                // lum = 1;

                // col = lum;
                

                return float4(col, lum * 7);
            }
            ENDCG
        }
    }
}
