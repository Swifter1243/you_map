Shader "You/SaberGuide"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1)
        _VirtualOffset ("Virtual Offset", Vector) = (0,0,0,0)
        _EyePosition ("Eye Position", Vector) = (0,0,0)
        _GuideWidth ("Guide Width", Float) = 1
        _GuideOpacity ("Guide Opacity", Range(0,1)) = 1
        _GuideFade ("Guide Fade", Float) = 0.1
        _GuideTaper ("Guide Taper", Float) = 0.3
        _GuideTaperStart ("Guide Taper Start", Float) = 0.4
        _GuideSteepness ("Guide Steepness", Float) = 1
        _Alpha ("Alpha", Float) = 1
        _AlphaTaper ("Alpha Taper", Float) = 0.2
        _VertexWiggle ("Vertex Wiggle", Float) = 0.2
        _TextureWiggle ("Texture Wiggle", Float) = 0.1
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
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _VirtualOffset;
            float3 _EyePosition;
            float _GuideWidth;
            float _GuideOpacity;
            float _GuideFade;
            float _GuideTaper;
            float _GuideTaperStart;
            float _GuideSteepness;
            float _Alpha;
            float _AlphaTaper;
            float _VertexWiggle;
            float _TextureWiggle;

            float3 cubicBezier(in float3 p0, in float3 p1, in float3 p2, in float t)
            {
                float3 c0 = lerp(p0, p1, t);
                float3 c1 = lerp(p1, p2, t);
                return lerp(c0, c1, t);
            }

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 saberCenter = mul(unity_ObjectToWorld, float4(0, 0, 0, v.vertex.w));
                float3 saberForward = mul(unity_ObjectToWorld, float4(0, 0, 1, v.vertex.w)) - saberCenter;
                
                float3 p0 = saberCenter;
                float3 p1 = saberCenter - saberForward * _GuideSteepness;
                float3 p2 = saberCenter + _VirtualOffset;

                float t = v.vertex.z;
                float3 p = cubicBezier(p0, p1, p2, t);
                float3 pAhead = cubicBezier(p0, p1, p2, t + 1e-3);
                
                float3 forward = normalize(pAhead - p);
                float3 up = p - _EyePosition;
                float3 right = normalize(cross(up, forward));

                float taperAmount = smoothstep(0, _GuideTaperStart, t);
                float taper = lerp(_GuideTaper, 1, taperAmount);
                float wiggle = sin(_Time.y * 2 + length(p) * 4) * t;
                
                float3 worldPos = (v.vertex.x + wiggle * _VertexWiggle) * right * _GuideWidth * taper + p;
                float3 localPos = mul(unity_WorldToObject, float4(worldPos, v.vertex.w));

                o.vertex = UnityObjectToClipPos(localPos);

                float2 transformedUV = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = float4(transformedUV, t, wiggle);
                
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_SETUP_INSTANCE_ID(i);
                fixed4 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float t = i.uv.z;
                float wiggle = i.uv.w;
                float fade = smoothstep(0, _GuideFade, 1 - t);
                float v = fade * _GuideOpacity;

                float alpha = smoothstep(0, _AlphaTaper, 1 - t) * _Alpha;

                float2 uv = i.uv;
                uv.x += wiggle * _TextureWiggle;

                float4 col = tex2D(_MainTex, uv);
                col = pow(col, 2);
                col *= Color;
                col.a *= Luminance(col.rgb) * alpha;
                col *= v;
                return col;
            }
            ENDCG
        }
    }
}