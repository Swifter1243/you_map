Shader "You/ReflectiveNote"
{
    Properties
    {
        _Color ("Note Color", Color) = (1,1,1)
        _Blur ("Blur", Range(0, 1)) = 0
        _BlurSteps ("Blur Steps", Int) = 10
        _FadeDistance ("Fade Distance", float) = 15
        [ToggleUI] _Arrow ("Arrow", Int) = 0
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
            #pragma multi_compile_instancing

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
                float3 pos : TEXCOORD0;
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
            UNITY_INSTANCING_BUFFER_END(Props)

            float _Blur;
            int _BlurSteps;
            float _FadeDistance;
            bool _Arrow;

            v2f vert (appdata v)
            {
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                // worldspace position
                o.pos = mul(unity_ObjectToWorld, v.vertex);

                // position to camera
                o.viewVector = o.pos - _WorldSpaceCameraPos;

                // Normal
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));

                // Local position
                o.localPos = v.vertex;

                return o;
            }

            float3 getSkyColor(float3 viewVector) {
                // return 0;
                return float4(DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, viewVector, 0), unity_SpecCube0_HDR), 0);
            }

            float3 rotateX(float angle, float3 vec) {
                return float3(
                vec[0] * cos(angle) - vec[1] * sin(angle),
                vec[0] * sin(angle) + vec[1] * cos(angle),
                vec[2]
                );
            }

            float3 rotateY(float angle, float3 vec) {
                return float3(
                vec[0] * cos(angle) + vec[2] * sin(angle),
                vec[1],
                -vec[0] * sin(angle) + vec[2] * cos(angle)
                );
            }

            float3 rotateZ(float angle, float3 vec) {
                return float3(
                vec[0],
                vec[1] * cos(angle) - vec[2] * sin(angle),
                vec[1] * sin(angle) + vec[2] * cos(angle)
                );
            }

            float3 blurredSkybox(float3 viewVector) {
                float3 total = 0;

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

                        offset *= _Blur;

                        float3 newVec = rotateY(offset.y, rotateX(offset.x, viewVector));

                        kernelSize++;
                        total += getSkyColor(newVec);
                    }
                }

                return total / kernelSize;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float clipVal = Cutout - (-i.localPos.y) - 0.5;
                clip(clipVal);

                if (clipVal < 0.02) {
                    return float4(1, 1, 1, 20);
                }

                float3 worldRefl = reflect(i.viewVector, i.normal);
                // float3 a = reflect(-i.viewVector, i.normal);

                float3 col = blurredSkybox(worldRefl);
                col += blurredSkybox(-worldRefl);

                float lum = Luminance(col);
                col = Color * lum * 15;
                // col = lerp(1, Color, 0.7) * lum * 2;

                col += getSkyColor(worldRefl);
                col += getSkyColor(-worldRefl);

                col *= saturate(1 - (i.pos.z / _FadeDistance));

                // col = Luminance(pow(col, 2)) * ogColor;

                float alpha = Luminance(col);
                if (_Arrow) {
                    col += blurredSkybox(i.viewVector);
                    alpha *= 10;
                    col *= 69;
                }

                // float3 darkenedColor = pow(col, 3);
                // darkenedColor = lerp(darkenedColor, Luminance(darkenedColor), 0.8);

                // col *= _HighBound;
                
                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
