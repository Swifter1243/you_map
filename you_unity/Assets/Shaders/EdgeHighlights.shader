Shader "Unlit/EdgeHighlights"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Blur ("Blur", Range(0, 1)) = 0
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
            #include "Noise.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);

            float _Blur;
            int _BlurSteps;
            float _BlurRadius;

            v2f vert (appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
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

                float2 fixedUv = UnityStereoTransformScreenSpaceTex(i.uv);
                float2 uv = fixedUv;
                uv += gnoise(uv * float2(0, 30)) * 0.03;
                uv.x = (uv.x + 0.5);
                uv.x = clamp(uv.x, 0, 0.5);

                float edgeDist = abs(fixedUv.x - 0.5) * 2;

                float3 blurcol = blur(uv);
                float noise = gnoise(float2(uv.y * 20, 0));
                blurcol *= noise;
                // blurcol *= pow(edgeDist, 1.6);
                // blurcol += max(0, blurcol * 10 * pow(edgeDist, 30));
                blurcol *= 0.02;
                blurcol += max(0, blurcol * 10 * pow(noise, 6) * pow(edgeDist, 15));
                // blurcol *= 0.5;

                // blurcol *= 60;

                return float4(getScreenCol(fixedUv) + blurcol, 0);
            }
            ENDCG
        }
    }
}
