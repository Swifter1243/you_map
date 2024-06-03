Shader "Decline/GlowingWisp"
{
    Properties
    {
        _ColorScale ("Color Scale", Float) = 1
        _Brightness ("Brightness", Float) = 1
        _TimeScale ("Time Scale", float) = 1
        _Flutter ("Flutter", float) = 0
        _FocalAmount ("Focal Amount", float) = 1
        _Opacity ("Opacity", Range(0,1)) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend One One
        ZWrite Off
        ZTest [_ZTest]

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
                float4 screenUV : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenUV = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float _ColorScale;
            float _Brightness;
            float _TimeScale;
            float _Flutter;
            float _FocalAmount;
            float _Opacity;

            fixed4 frag (v2f i) : SV_Target
            {
                //Scaled pixel coordinates
                float2 p = i.uv;
                p.y += _Time.y * _TimeScale * 0.1;
            
                //Pick a color using the turbulent coordinates
                float v = sin((p.x - p.y) * 0.2) * 0.3 + 0.5;
                v = pow(v, 4);
                v *= _Brightness;

                float vignette = saturate(1 - length(i.uv * 2 - 1));
                vignette *= pow(vignette, 4);
                v *= vignette;

                // v = saturate(v);

                v += pow(vignette, 4) * _Brightness * _FocalAmount;

                v = max(0, v);

                v *= saturate(lerp(1, hashwithoutsine11(_Time.y * 20), _Flutter));

                // return 0.3;

                float t = length(i.uv) / _ColorScale;
                float3 col = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));

                col *= _Opacity;

                float2 screenUV = (i.screenUV) / i.screenUV.w;
                float depth = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraDepthTexture, screenUV);
                float depth01 = Linear01Depth(depth);
                // return depth01;
                col *= depth01 > 0.5;

                return float4(v * col, 0);
            }
            ENDCG
        }
    }
}
