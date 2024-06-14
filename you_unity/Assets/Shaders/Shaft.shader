Shader "You/Shaft"
{
    Properties
    {
        _Progress ("Progress", Range(0,1)) = 0
        _Test ("Test", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZWrite Off
        // ZTest Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Noise.cginc"
            #include "Colors.cginc"
            #include "Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 center : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord0.xy;
                o.vertex.x += (o.uv.y - 0.5) * 1000;

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.center = float3(v.texcoord0.zw, v.texcoord1.x);
                return o;
            }

            float _Progress;
            float _Test;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldCenter = mul(unity_ObjectToWorld, float3(0,0,0));

                // Falloff
                float dist = (1 - abs(i.uv.x - 0.5) * 2);
                float3 col = dist;

                // Noise coloration
                float noise = gnoise(i.center.zx * 0.03);
                col *= noise;

                // Dip level
                float y = (noise - 0.5) * 6 + i.worldPos.y * 0.005;
                col *= saturate(y);
                
                // Coloration
                float t = i.center.x * 0.0003;
                // float3 f = palette(t + pow(dist, 0.2) * 2, 0.5, 0.5, float3(1,1,0.5), float3(0.8, 0.9, 0.3));
                // f = lerp(f, 1, 0.3);
                float3 f = pow(1 - abs((i.worldPos.x * 0.3 + i.worldPos.y) * 0.0001 - (_Progress - 0.5) * 0.1), 5) * 2 * rainbow(t);
                col *= f * saturate(y * 0.3) * 0.6;
                col *= lerp(1, gnoise(i.uv * 3), 0.3);

                // Speckles
                float3 sPos = i.worldPos * 0.01;
                sPos.y *= 0.9;
                sPos.y += _Time.y * noise * 0.4;
                col += col * pow(gnoise(sPos), 4) * 6;

                // Fade out
                col *= pow(saturate((3000 - i.worldPos.y) * 0.001), 6);
                col *= 1;
                // col *= 1 - pow(1 - dist, 4);
                col *= dist;

                // Variation
                noise = gnoise(gnoise(i.worldPos.xy * 0.001 + _Progress + i.worldPos.z * 0.02) + 5 + _Progress * _Test);
                col += f * (1 - pow(1 - dist, 3));

                col *= pow(noise, 3) + 0.1;
                col *= 1 - pow(abs(_Progress - 0.5) * 2, 1);
                col *= 0.4;

                // Travel mask
                float targetDest = (_Progress - 0.5) * 4;
                col *= pow(1 - abs((i.worldPos.x) * 0.002 - targetDest), 1);
                
                return float4(gammaCorrect(col), 0);
            }
            ENDCG
        }
    }
}
