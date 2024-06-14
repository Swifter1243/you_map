Shader "You/BlackHoleBeam"
{
    Properties
    {
        _Size ("Size", Float) = 700
        _Opacity ("Opacity", Range(0, 1)) = 1
        _MaskRef ("Mask Reference", Float) = 2
        _FlickerScalar ("Flicker Scalar", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend One OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            Stencil
            {
                Ref [_MaskRef]
                Comp Greater
                Fail Keep
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

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
                float4 vertex : SV_POSITION;
                float3 pos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Opacity;
            float _FlickerScalar;

            float _Size;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 pos = i.pos / _Size;
                float3 col = rainbow(pos.y + _Time.y * 0.2);
                col = lerp(col, 1, 0.5);

                float d = saturate(1 - length(pos.xy));
                float2 uv = (i.uv - 0.5) * 2;


                float r = pow(saturate(pow(1. - abs(uv.x) * abs(uv.y), 50.) * (1. - abs(uv.y) * 3.) - length(uv) * 0.3), 30);
                // return r;
                r *= 1 + hashwithoutsine11(_Time.y * 20 + pos.z * 20 * _FlickerScalar) * 0.9;

                float c = pow(saturate(1 - length(uv)), 50) * 0.3 + r * 0.1;
                float cutoff = smoothstep(0.02, 0, uv.y);
                c *= cutoff;
                // return cutoff;

                float alpha = c;
                col *= alpha;
                col *= 3;

                // float offset = 0.2;
                // float full = offset + 1;
                float opacity = 1 -  length(pos * 0.3);
                opacity = smoothstep(1 - _Opacity, 1, opacity);
                col *= opacity;

                return float4(col, alpha * 4 * opacity);
            }
            ENDCG
        }
    }
}
