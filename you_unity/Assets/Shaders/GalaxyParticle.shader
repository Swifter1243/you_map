Shader "You/GalaxyParticle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("Opacity", Range(0, 1)) = 1
        _MaskRef ("Mask Reference", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend One OneMinusSrcColor
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
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pos : TEXCOORD1;
                float3 center: TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Opacity;

            float _Size;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord0.xy;
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                o.center = float3(v.texcoord0.zw, v.texcoord1.x);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 pos = i.pos / _Size;

                float3 viewVec = normalize(_WorldSpaceCameraPos - i.center);
                float3 col = rainbow(viewVec.x * 0.7) * 0.3;
                col = lerp(col, 1, 0.05);

                float tex = (hashwithoutsine11(i.center.x / _Size) < 0.5) * 0.5;
                float2 uv = float2(i.uv.x * 0.5 + tex, i.uv.y);

                float c = tex2D(_MainTex, uv);
                c += saturate(pow(saturate(1 - length(1 - (i.uv * 2))), 50)) * 10;
                c *= _Opacity;
                float alpha = c;
                col *= alpha;
                col *= 3;

                // col = tex;

                // if (i.uv.x < 0.5) return 1;

                // col = tex;

                // float offset = 0.2;
                // float full = offset + 1;

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
