Shader "Unlit/EndingVeins"
{
    Properties
    {
        _Twist ("Twist", Float) = 1
        _Size ("Size", Float) = 700
        _Flicker ("Flicker", Range(0,1)) = 0
        _InflexPoint ("Inflex Point", Float) = 1000
        _InflexZ ("Inflex Z", Float) = 300
        _VeinTwist ("Vein Twist", Float) = 1
        _Opacity ("Opacity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        // ZTest Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Colors.cginc"
            #include "Noise.cginc"

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

            float _Twist;
            float _Size;
            float _Flicker;
            float _InflexPoint;
            float _InflexZ;
            float _VeinTwist;
            float _Opacity;

            float3 rotateY(float angle, float3 vec) {
                return float3(
                vec[0] * cos(angle) + vec[2] * sin(angle),
                vec[1],
                -vec[0] * sin(angle) + vec[2] * cos(angle)
                );
            }

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = mul(unity_ObjectToWorld, v.vertex);

                float f = 1 - o.pos.y / 900;
                v.vertex += gnoise(v.vertex.xy * 60 + _Time.y * 0.1) * 0.001 * f * 2;
                
                float twist = f * _VeinTwist + 60 - o.pos.y * 8 / _Size;
                float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                worldVertex.z += _InflexZ;
                worldVertex.xz *= abs(pow(((_InflexPoint - worldVertex.y) / _InflexPoint) * 0.1, 0.5)) * 0.6;
                worldVertex = float4(rotateY(twist, worldVertex.xyz), worldVertex.w);
                worldVertex.z -= _InflexZ;
                v.vertex = mul(unity_WorldToObject, worldVertex);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 pos = i.pos / _Size;
                float2 vec = i.pos.xz;
                float angle = atan2(vec.y, vec.x);


                float f = 1 - length(i.pos.xy) / _Size;
                float twist = f * _Twist * sin(_Time.y * 0.2) + 10 - pos.z * 5;
                float a = sin(angle * 3 + cos(_Time.y) + twist);
                a -= pos.z;

                float t = f + a + _Time.y;
                float3 col1 = palette(t * 0.1, 0.5, 0.5, 1, float3(0.00, 0.10, 0.20));
                float3 col2 = palette(t + cos(_Time.y * 0.3 + pos.z), 0.5, 0.5, 1, float3(0.1, cos(_Time.y * 0.1 + pos.y), 0.20));

                float3 col = lerp(col1, col2, a);
                
                float t2 = pow(saturate(f), 2);
                col = lerp(col1, 1, t2);

                col *= pow(saturate(f), 2) - a * 0.3;

                col *= lerp(col, 1, 0.3);
                col = pow(col, 3);

                // Flicker
                float centerDist = pow((1 - length(pos - float3(0,0,1))), 3) * 10;
                col += (sin(_Time.y * 100) * 0.5 + 0.5) * _Flicker * centerDist;

                // col = col1;

                col *= 1 - length((i.pos + 3) * 0.001);

                col *= _Opacity;

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);

                return float4(col, Luminance(col) * 30);
            }
            ENDCG
        }
    }
}
