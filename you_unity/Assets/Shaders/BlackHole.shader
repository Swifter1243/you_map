Shader "You/BlackHole"
{
    Properties
    {
        _Strength ("Strength", Float) = 1
        _FresnelPower ("Fresnel Power", Float) = 6
        _CoreThreshold ("Core Threshold", Range(0.5, 1)) = 0.9
        _Pulse ("Pulse", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        // ZTest Off

        GrabPass { "_GrabTexture1" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 screenUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD2;
                float3 normal : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Strength;
            float _FresnelPower;
            float _CoreThreshold;
            float _Pulse;
            
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture1);

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenUV = ComputeGrabScreenPos(o.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewVector = normalize(worldPos - _WorldSpaceCameraPos);
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));
                return o;
            }

            float2 worldToScreen(float3 pos) {
                float4 v = ComputeGrabScreenPos(UnityObjectToClipPos(pos));
                return v.xy / v.w;
            }

            float4 getGrabPassCol(float2 uv) {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture1, uv);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Screen to black hole center
                float2 centerUV = worldToScreen(float3(0,0,0));
                float2 screenUV = (i.screenUV) / i.screenUV.w;
                float2 toCenter = centerUV - screenUV;

                // Fresnel
                float d = dot(i.viewVector, i.normal);
                float fresnel = saturate(pow(1 - (-saturate(-d) * 0.5 + 0.5) * 2, _FresnelPower));

                // Distort
                float pulse = sin(_Time.y) * _Pulse;
                screenUV += toCenter * _Strength * fresnel * (1 + pulse * 0.5);
                float4 col = getGrabPassCol(screenUV);

                // Core
                if (d < -_CoreThreshold + pulse * 0.01) {
                    return 0;
                }

                return col;
            }
            ENDCG
        }
    }
}
