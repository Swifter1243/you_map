Shader "You/SaberBlade"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata_base v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                const float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewVector = worldPos - _WorldSpaceCameraPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_SETUP_INSTANCE_ID(i);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                
                float d = dot(-i.normal, normalize(i.viewVector));
                return float4(d * Color * 4, d);
            }
            ENDCG
        }
    }
}
