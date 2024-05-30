Shader "Unlit/AmbientFlare"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Steepness ("Steepness", Float) = 3
        _Size ("Size", Float) = 1
        _FlareBrightness ("Flare Brightness", Float) = 0.1
        _CenterBrightness ("Center Brightness", Float) = 0.1
        _Flutter ("Flutter", Float) = 0.1
        _Exaggerate ("Exaggerate", Range(0, 1)) = 0
        _Opacity ("Opacity", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZWrite Off
        ZTest Off
        Cull Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Colors.cginc"
            #include "Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata_full v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;

                // billboard mesh towards camera
                // float3 vpos = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
                // float4 worldCoord = float4(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23, 1);
                // float4 viewPos = mul(UNITY_MATRIX_V, worldCoord) + float4(vpos, 0);
                // float4 outPos = mul(UNITY_MATRIX_P, viewPos);

                // o.pos = outPos;

                return o;
            }

            float _Steepness;
            float _Size;
            float _CenterBrightness;
            float _FlareBrightness;
            float _Flutter;
            float _Exaggerate;
            float _Opacity;
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 col = 1;

                _Size -= _Exaggerate * 0.2;
                _Flutter += _Exaggerate * 0.6;
                _CenterBrightness *= 1 - _Exaggerate * 4;

                float2 uv = (i.uv - 0.5) * 2;
                uv *= _Size;

                // Thinner flare
                float r = pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), _Steepness) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30) * 2;

                // Thicker flare
                // r += pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), _Steepness * 0.1) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30);

                float r2 = pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), _Steepness * 0.1) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30) * 3;
                float a = atan2(abs(uv.y), uv.x);
                float aNoise = gnoise(a * 40);
                r += r2 * (0.8 + aNoise * 0.2);

                r *= 1 + _Exaggerate * 2;
                // Flutter
                r *= 1 + sin(_Time.y * 100.587) * _Flutter;

                float c = pow(saturate(1 - length(uv)), 50) * _CenterBrightness + r * _FlareBrightness;
                float alpha = c;
                col *= alpha;
                col *= 3;
                
                col = saturate(col);
                col *= palette(length(uv * 7), 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));

                float flicker = 1 + sin(_Time.y * 300 * _Exaggerate) * 0.4;
                col += pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), 20) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30) * 3 * _Exaggerate * flicker;
                
                for (int j = 6; j <= 7; j++) {
                    float e = floor(_Exaggerate * j * 3) / j / 3;
                    float len = length(i.uv.xy - 0.5) * e;
                    float g = (a / UNITY_PI) * j;
                    float s = abs((g % 2) - 1) * 0.07;
                    float shape = 1 - abs(len - 0.3 + s + 0.1 * (j - 6));
                    float circDist = pow(shape, 40);
                    // col = len;
                    col += aNoise * circDist * 0.1 * _Exaggerate;
                }

                col *= _Opacity;

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
