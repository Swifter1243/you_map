Shader "Unlit/ReflectiveTest"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZWrite Off

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
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                // worldspace position
                float3 pos = mul(unity_ObjectToWorld, v.vertex);

                // position to camera
                o.viewVector = pos - _WorldSpaceCameraPos;

                // Normal
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldRefl = reflect(i.viewVector, i.normal);
                float4 skyData = float4(DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, worldRefl, 0), unity_SpecCube0_HDR), 0);

                float3 col = skyData.xyz;

                float edgeDistX = max(i.uv.x, 1 - i.uv.x);
                float edgeDistY = max(i.uv.y, 1 - i.uv.y);
                float edgeDist = max(edgeDistX, edgeDistY);
                col += pow(edgeDist, 40) * 0.2;

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
