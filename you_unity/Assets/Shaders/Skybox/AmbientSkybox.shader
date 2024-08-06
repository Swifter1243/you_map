// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "You/AmbientSkybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Twist ("Twist", Float) = 1
        _Size ("Size", Float) = 700
        _Opacity ("Opacity", Range(0, 1)) = 1
        _Evolve ("Evolve", Range(0, 1)) = 0
        _LightBrightness ("Light Brightness", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZWrite Off

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
                float4 vertex : SV_POSITION;
                float3 pos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float _Twist;
            float _Size;
            float _Opacity;
            float _Evolve;
            float _LightBrightness;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 pos = i.pos / _Size;
                float2 vec = i.pos.xy;
                float angle = atan2(vec.y, vec.x);

                float f = 1 - length(i.pos.xy) / _Size;
                float twist = f * _Twist * sin(_Time.y * 0.1) + 10 - pos.z * 5;
                float strength = 1 - length(pos.xy);
                angle += gnoise(float2(length(pos.xy) * 20 * strength, sin(angle))) * 0.1 * pow(strength, 3);
                angle += sin(angle * 6)  * pow(strength, 3) * _Evolve;
                float a = sin(angle * 2 + cos(_Time.y * 0.1) + twist);
                a -= pos.z;

                float t = f + a + _Time.y * 0.1;
                float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));

                
                float t2 = pow(saturate(f), 2);
                float3 col = lerp(col1, 1, t2);

                col *= pow(saturate(f), 4) - a * 0.3;

                col *= lerp(col, 1, 0.3);

                col *= 0.3 + _Evolve * 0.3;

                // Light
                col = lerp(col, 0.9, pow(smoothstep(0.9, 1, f), 6));
                float3 darkenedCol = lerp(col, 0.1, pow(smoothstep(0.1, 1, f), 6));
                col = lerp(darkenedCol, col, _LightBrightness);
                col = lerp(col * 0.7, col, _LightBrightness);

                // Galaxy
                float g = gnoise((pos + a) * 6 * float3(1, 0.3, 1)) * 0.2;
                float3 galaxy = palette(g + a + f + 0.6 + _Evolve * 0.3, float3(0.448, -0.542, 1.028), 0.5, float3(0.8, 0.8, 0.5), float3(0, 0.2, 0.5)) * gnoise(pos);
                galaxy = pow(galaxy, 3);
                col += (galaxy + 0.8) * 0.1 * gnoise(pos * 3 * float3(1 - a, 0.28, a));

                col += palette(pos.y + gnoise(pos.x), 0.5, 0.5, 1, float3(0.00, 0.10, 0.2)) * 0.1 * _Evolve;

                float opacity = f - 1;
                opacity = smoothstep(_Opacity, 1, opacity);
                col *= lerp(1, opacity * 7, pow(1 - _Opacity, 0.6));


                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
