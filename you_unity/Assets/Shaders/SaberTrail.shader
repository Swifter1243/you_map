Shader "You/SaberTrail"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcColor
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Colors.cginc"
            #include "Noise.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            v2f vert (appdata_base v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float n = voronoi(float2(i.uv.x * 3, i.uv.y - _Time.y));
                float brightness = pow(1 - i.uv.y + n * 0.2, 4);
                brightness *= 1 - i.uv.x;
                brightness = lerp(brightness, brightness * gnoise(i.uv * float2(10, 1)), 0.6);
                
                float t = i.uv.y * 2 + n * 0.2 - _Time.y * 0.4 + i.uv.x;
                float3 col = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col *= brightness * 3;
                return float4(col, brightness);
            }
            ENDCG
        }
    }
}
