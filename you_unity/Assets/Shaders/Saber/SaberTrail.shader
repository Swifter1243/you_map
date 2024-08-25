Shader "You/SaberTrail"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1)
        _Mask ("Mask", 2D) = "white"
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

            sampler2D _Mask;
            float4 _Mask_ST;

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

                float n = voronoi(float2(i.uv.x * 2, 1 - pow(saturate(1 - i.uv.y), 10) * 2 + _Time.y * 0.4));
                float3 n2 = simplex(float3(i.uv.xy * 5, _Time.y * 0.3) + n * 1.3);

                float brightness = 1;
                brightness *= smoothstep(0, 0.1, i.uv.x);
                brightness *= smoothstep(1, 0.9, i.uv.x);

                float t = i.uv.y * 1 + n * 0.6 - _Time.y * 0.1 + n2 * 0.1;
                t *= 3 + n * 0.001;
                float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col1 *= brightness;

                float lumcol1 = Luminance(col1);
                float3 col2 = Luminance(col1) * Color;
                col2 = lerp(col2, lumcol1, 0.3);
                col2 *= 5;

                float coloration = smoothstep(0.4, 0, i.uv.y);
                float3 col = lerp(col1, col2, coloration);

                //col *= 3;

                float2 maskUV = i.uv + n * 0.03 + n2 * 0.115;

                col *= tex2D(_Mask, TRANSFORM_TEX(maskUV, _Mask));

                //col *= 1.2;
                col = pow(col, 2);
                col = saturate(col) * 0.5;

                return float4(col, Luminance(col) * 0.4);
            }
            ENDCG
        }
    }
}
