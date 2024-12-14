Shader "You/SaberGuide"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1)
        _VirtualOffset ("Virtual Offset", Vector) = (0,0,0,0)
        _GuideWidth ("Guide Width", Float) = 1
        _GuideOpacity ("Guide Opacity", Range(0,1)) = 1
        _GuideFade ("Guide Fade", Float) = 0.1
        _GuideTaper ("Guide Taper", Float) = 0.3
        _GuideTaperStart ("Guide Taper Start", Float) = 0.4
        _Alpha ("Alpha", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent+1"
        }
        Cull Off
        Blend One OneMinusSrcColor

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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _Color;
            float4 _MainTex_ST;
            float3 _VirtualOffset;
            float _GuideWidth;
            float _GuideOpacity;
            float _GuideFade;
            float _GuideTaper;
            float _GuideTaperStart;
            float _Alpha;

            float3 cubicSpline(in float3 p0, in float3 p1, in float3 p2, in float t)
            {
                float3 c0 = lerp(p0, p1, t);
                float3 c1 = lerp(p1, p2, t);
                return lerp(c0, c1, t);
            }
            
            float3 quadracticSpline(in float3 p0, in float3 p1, in float3 p2, in float3 p3, in float t)
            {
                float3 c0 = cubicSpline(p0, p1, p2, t);
                float3 c1 = cubicSpline(p1, p2, p3, t);
                return lerp(c0, c1, t);
            }

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 saberCenter = mul(unity_ObjectToWorld, float4(0, 0, 0, v.vertex.w));
                float3 saberForward = mul(unity_ObjectToWorld, float4(0, 0, 1, v.vertex.w)) - saberCenter;
                
                float3 p0 = saberCenter + saberForward;
                float3 p1 = saberCenter + saberForward * 2;
                float3 p2 = saberCenter + saberForward + _VirtualOffset;
                float3 p3 = saberCenter + _VirtualOffset;

                float t = v.vertex.z;
                float3 p = quadracticSpline(p0, p1, p2, p3, t);
                float3 pAhead = quadracticSpline(p0, p1, p2, p3, t + 1e-3);
                
                float3 forward = normalize(pAhead - p);
                float3 up = p - _WorldSpaceCameraPos;
                float3 right = normalize(cross(up, forward));

                float taperAmount = smoothstep(0, _GuideTaperStart, t);
                float taper = lerp(_GuideTaper, 1, taperAmount);
                float3 worldPos = v.vertex.x * right * _GuideWidth * taper + p;
                float3 localPos = mul(unity_WorldToObject, float4(worldPos, v.vertex.w));

                o.vertex = UnityObjectToClipPos(localPos);

                float2 transformedUV = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = float3(transformedUV, t);
                
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float fade = smoothstep(0, _GuideFade, 1 - i.uv.z);
                float v = fade * _GuideOpacity;

                float4 col = tex2D(_MainTex, i.uv) * v * _Color;
                col.a *= _Alpha;
                return col;
            }
            ENDCG
        }
    }
}