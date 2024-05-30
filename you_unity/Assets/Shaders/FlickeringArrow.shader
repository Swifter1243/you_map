Shader "Unlit/FlickeringArrow"
{
    Properties
    {
        _Color ("Note Color", Color) = (1,1,1)
        _FadeDistance ("Fade Distance", float) = 15
        [ToggleUI] _Flicker ("Flicker", Int) = 0
        _Cutout ("Cutout", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float3 pos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _Color;
            float _FadeDistance;
            int _Flicker;
            float _Cutout;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                // worldspace position
                o.pos = mul(unity_ObjectToWorld, v.vertex);

                // Local position
                o.localPos = v.vertex;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float clipVal = _Cutout - (-i.localPos.y) - 0.5;
                clip(clipVal);

                if (clipVal < 0.02 || !_Flicker) {
                    return float4(1, 1, 1, 20);
                }

                float zDist = saturate(1 - (i.pos.z / _FadeDistance));
                float flicker = sin(_Time.y * 100);
                float3 col = zDist * _Flicker * flicker;
                
                float alpha = Luminance(col);
                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
