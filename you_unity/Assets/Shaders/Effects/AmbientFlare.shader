Shader "You/AmbientFlare"
{
    Properties
    {
        _Steepness ("Steepness", Float) = 3
        _Size ("Size", Float) = 1
        _FlareBrightness ("Flare Brightness", Float) = 0.1
        _FlareOpacity ("Flare Opacity", Range(0,1)) = 1
        _CenterBrightness ("Center Brightness", Float) = 0.1
        _Flutter ("Flutter", Float) = 0.1
        _Exaggerate ("Exaggerate", Range(0, 1)) = 0
        _Opacity ("Opacity", Range(0, 1)) = 1
        _DepthClip ("Depth Clip", Range(0,1)) = 0
        _LightBrightness ("Light Brightness", Range(0,1)) = 1
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 midUV : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            v2f vert (appdata_full v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;

                float4 midClipPos = UnityObjectToClipPos(float3(0,0,0));
                // float4 midClipPos = UnityObjectToClipPos(v.vertex);
                o.midUV = ComputeGrabScreenPos(midClipPos);

                return o;
            }

            float _Steepness;
            float _Size;
            float _CenterBrightness;
            float _FlareBrightness;
            float _FlareOpacity;
            float _Flutter;
            float _Exaggerate;
            float _Opacity;
            float _DepthClip;
            float _LightBrightness;

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthTexture);

            #ifdef UNITY_STEREO_INSTANCING_ENABLED
                #define SAMPLE_TEXTURE(tex, uv) UNITY_SAMPLE_TEX2DARRAY(tex, float3((uv).xy, 0))
            #else
                #define SAMPLE_TEXTURE(tex, uv) tex2D(tex, uv)
            #endif
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.midUV.xy / i.midUV.w;
                float depth = SAMPLE_TEXTURE(_CameraDepthTexture, screenUV);
                float depth01 = Linear01Depth(depth);
                clip(depth01 - _DepthClip);

                float3 col = 1;

                _Size -= _Exaggerate * 0.2;
                _Flutter += _Exaggerate * 0.6;
                _CenterBrightness *= 1 - _Exaggerate * 4;

                float2 uv = (i.uv - 0.5) * 2;
                uv *= _Size;

                // Thinner flare
                float r = pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), _Steepness) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30) * 2;

                // Thicker flare
                float r2 = pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), _Steepness * 0.1) * (1. - abs(uv.y) * 0.1) - length(uv) * 0.3), 30) * 3;
                float a = atan2(abs(uv.y), uv.x);
                float aNoise = gnoise(a * 40);
                r += r2 * (0.8 + aNoise * 0.2);

                r *= 1 + _Exaggerate * 2;
                
                // Flutter
                const float flutterRate = sin(_Time.y * 100.587);
                r *= 1 + flutterRate * _Flutter;
                
                float c = pow(saturate(1 - length(uv)), 50) * _CenterBrightness + r * _FlareBrightness * _FlareOpacity;
                float alpha = c;
                col *= alpha;
                col *= 3;
                
                col = saturate(col);
                float3 coloring = palette(length(uv * 7), 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col *= coloring;

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

                // Light
                float lightFlutter = 1 + flutterRate * _Flutter * 2;
                float light = smoothstep(0.1 * _FlareOpacity, 0, length(uv));
                float aNoise2 = gnoise(a * 3);
                col += pow(light, 20) * lightFlutter * _LightBrightness * _FlareOpacity;
                float3 lightFlare = palette(length(uv * 70), 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col += aNoise2 * light * _LightBrightness * lerp(lightFlare, 1, 0.8) * 0.5 * smoothstep(0.5, 1, _FlareOpacity);

                col *= _Opacity;
                col = saturate(col);
                col = pow(col, 2.2); // Gamma Correct
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
