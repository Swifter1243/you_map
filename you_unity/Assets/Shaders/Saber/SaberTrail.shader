Shader "You/SaberTrail"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcColor
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

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
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)
            
            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_SETUP_INSTANCE_ID(i);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                
                float n = voronoi(float2(i.uv.x * 3, 1 - pow(saturate(1 - i.uv.y), 10) * 2 - _Time.y));
                float brightness = pow(1 - i.uv.y + n * 0.6, 10);
                brightness *= 1 - i.uv.x;
                brightness = lerp(brightness, brightness * gnoise(i.uv * float2(10, 1)), 0.6);
                brightness *=  1 - pow(1 - i.uv.x + n * 0.05, 6);
                
                float t = i.uv.y * 2 + n * 0.2 - _Time.y + i.uv.x * 0.4;
                float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col1 *= brightness;

                const float3 col2 = Luminance(col1) * Color;

                float coloration = pow(1 - i.uv.y, 2);
                float3 col = lerp(col1, col2, coloration);
                
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
