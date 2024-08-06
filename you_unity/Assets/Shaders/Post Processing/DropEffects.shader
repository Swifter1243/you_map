Shader "You/DropEffects"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Distortion)][Space(10)]
        _Strength ("Strength", Range(0, 1)) = 0
        _Multiplier ("Multiplier", Range(0, 0.1)) = 0.01
        _Scale ("Scale", Float) = 4
        _BorderStrength ("Border Strength", Float) = 4
        _TimeSpeed ("Time Speed", Float) = 0.6

        [Header(Blur)][Space(10)]
        _Blur ("Blur", Range(0, 1)) = 0
        _BlurFlicker ("Blur Flicker", Range(0, 1)) = 0
        _BlurSteps ("Blur Steps", Int) = 10
        _BlurRadius ("Blur Radius", Range(0,0.2)) = 0.04
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
            #include "Assets/CGIncludes/Noise.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);

            float _Strength;
            float _Multiplier;
            float _Scale;
            float _BorderStrength;
            float _TimeSpeed;

            float _Blur;
            float _BlurFlicker;
            int _BlurSteps;
            float _BlurRadius;

            v2f vert (appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);

                float3 viewDir = mul(unity_CameraInvProjection, float4(v.texcoord.xy * 2.0 - 1.0, 0, 1)).xyz;
                viewDir.z = -viewDir.z;
                o.viewVector = mul(unity_CameraToWorld, float4(viewDir, 0)).xyz;

                o.uv = v.texcoord;
                return o;
            }

            float3 getScreenCol(float2 uv) {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, uv);
            }

            float3 blur(float2 uv) {
                // if (_Blur == 0) return getScreenCol(uv);

                float3 total = 0;
                
                float aspect = _ScreenParams.y / _ScreenParams.x;

                uint kernelSize = 0;

                for (int x = -_BlurSteps; x <= _BlurSteps; x++) {
                    for (int y = -_BlurSteps; y <= _BlurSteps; y++) {
                        if (x == 0 && y == 0) {
                            continue;
                        }

                        float2 offset = float2(x, y) / _BlurSteps;

                        if (length(offset) > 1) {
                            continue;
                        }

                        offset.x *= aspect;

                        offset *= _Blur;

                        kernelSize++;
                        total += getScreenCol(uv + offset * _BlurRadius);
                    }
                }

                return total / kernelSize;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                _Blur = saturate(_Blur + sin(_Time.y * 100) * _BlurFlicker * _Blur);

                float2 uv = i.uv;

                // Offset
                float angle = gnoise(uv * _Scale + _Time * _TimeSpeed + _Strength) * UNITY_PI * 2;
                float2 offset = float2(cos(angle), sin(angle));

                float borderX = max(uv.x, 1 - uv.x);
                float borderY = max(uv.y, 1 - uv.y);
                float border = smoothstep(1, _BorderStrength, max(borderY, borderX));

                // return border;

                // Apply offset
                float2 screenUV = UnityStereoTransformScreenSpaceTex(uv);
                screenUV += offset * _Multiplier * _Strength * border;
                return float4(blur(screenUV), 0);
            }
            ENDCG
        }
    }
}
