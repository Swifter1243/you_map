Shader "You/Implosion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Distance ("Distance", Range(0,1)) = 0
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
            #include "Noise.cginc"
            #include "Colors.cginc"

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

            float _Distance;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 vec = i.pos.xy;
                float rawAngle = atan2(vec.y, vec.x);
                float angle = (rawAngle + UNITY_PI) / UNITY_PI / 2;

                float3 col = 0;
                float a = atan2(abs(vec.y), vec.x);
                col += gnoise((a - angle) * 20);

                _Distance = _Distance * 0.65 + 0.15;
                col *= pow(1 - abs(length(vec) - _Distance + 0.3), 60);
                col *= pow(saturate(1 - length(vec) * 2), 3);

                col *= lerp(palette(a, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2)), 1, 0.1) * 2;

                return float4(col, pow(Luminance(col) * 7, 5));
            }
            ENDCG
        }
    }
}
