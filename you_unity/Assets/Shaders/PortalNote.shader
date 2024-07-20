Shader "You/PortalNote"
{
    Properties
    {
        _Color ("Note Color", Color) = (1,1,1)
        _Cutout ("Cutout", Range(0,1)) = 1
        [ToggleUI] _Void ("Void", Int) = 0
        _PlaneDistance ("Plane Distance", Float) = 100
        [ToggleUI] _Debris ("Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Noise.cginc"
            #include "Colors.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 localPos : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)

            bool _Void;
            float _PlaneDistance;
            bool _Debris;

            v2f vert (appdata v)
            {
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                // worldspace position
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // position to camera
                o.viewVector = o.worldPos - _WorldSpaceCameraPos;

                // Normal
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));

                // Local position
                o.localPos = v.vertex;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);

                float c = 0;
                if (_Debris) {
                    float3 p = i.localPos + CutPlane.xyz * CutPlane.w;
                    float dist = dot(p, CutPlane.xyz) / length(CutPlane.xyz);

                    float noise = voronoi(i.localPos * 3).y;

                    c = dist - Cutout * 0.5 + noise * 0.2 - 0.1;
                } else {
                    c = Cutout - (-i.localPos.y) - 0.5;
                }

                clip(c);

                if (c < 0.01) {
                    return float4(1, 1, 1, 20);
                }

                if (_Void) return 0;

                float3 toText = i.worldPos - _WorldSpaceCameraPos;
                // col = gnoise((toText * 2 + _WorldSpaceCameraPos).xy);

                float planeDist = _PlaneDistance - i.worldPos.z;
                float3 planeIntersect = i.worldPos + normalize(toText) * planeDist;
                float n = gnoise3D(float3(planeIntersect.xy / 30, _Time.y * 0.2));

                float2 starScroll = float2(planeIntersect.x, planeIntersect.y + sin(_Time.y + planeIntersect.y * 0.1));
                float n2 = saturate(pow(gnoise(starScroll), 60)) * 2;
                float3 planeCol = (n * 0.5 + 0.5) * 3 + n2;
                planeCol *= Luminance(rainbow(n)) * Color;

                float d = dot(normalize(i.viewVector), i.normal) * 0.5 + 0.5;
                d = min(d, 0.3);
                d = saturate(pow(d, 2));

                float hue = atan2(i.localPos.y, i.localPos.x) / UNITY_PI / 2 + 0.5;
                hue += _Time.y;
                float dist = saturate((length(i.viewVector)) / 15);

                float3 closeCol = rainbow(hue) * d * 15 + planeCol * 2.5;
                float3 farCol = planeCol * 100 * d + planeCol * 1.5;
                float3 col = lerp(closeCol, farCol, dist);

                int inside = dot(i.viewVector, i.normal) < 0.2;
                col = lerp(planeCol, col, inside);

                float alpha = max(0, d * 7 + n2 * 0.2) * inside;
                return float4(col, alpha);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

    }
}
