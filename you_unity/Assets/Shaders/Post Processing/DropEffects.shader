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
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);

            int _BlurSteps;
            float _BlurRadius;
            float _Blur;
            float _BlurFlicker;

            v2f_img vert(appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            float3 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(uv));
            }

            float3 blur(float2 uv, float amount)
            {
                float3 total = 0;

                for (int i = -_BlurSteps; i <= _BlurSteps; i++)
                {
                    float offset = (float)i / _BlurSteps;
                    offset *= amount;
                    total += getScreenCol(uv + float2(offset * _BlurRadius, 0));
                }

                return total / (_BlurSteps * 2 + 1);
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float blurAmount = saturate(_Blur + sin(_Time.y * 100) * _BlurFlicker * _Blur) * _BlurRadius;
                return float4(blur(i.uv, blurAmount), 0);
            }
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Noise.cginc"

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

            v2f_img vert(appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            float3 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(uv));
            }

            float3 blur(float2 uv, float amount)
            {
                float3 total = 0;

                for (int i = -_BlurSteps; i <= _BlurSteps; i++)
                {
                    float offset = (float)i / _BlurSteps;
                    offset *= amount;
                    total += getScreenCol(uv + float2(0, offset * _BlurRadius));
                }

                return total / (_BlurSteps * 2 + 1);
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                float2 uv = i.uv;

                // Offset
                float angle = gnoise(uv * _Scale + _Time * _TimeSpeed + _Strength) * UNITY_PI * 2;
                float2 offset = float2(cos(angle), sin(angle));

                float borderX = max(uv.x, 1 - uv.x);
                float borderY = max(uv.y, 1 - uv.y);
                float border = smoothstep(1, _BorderStrength, max(borderY, borderX));

                // Apply offset
                uv += offset * _Multiplier * _Strength * border;

                float blurAmount = saturate(_Blur + sin(_Time.y * 100) * _BlurFlicker * _Blur) * _BlurRadius;
                return float4(blur(uv, blurAmount), 0);
            }
            ENDCG
        }
    }
}