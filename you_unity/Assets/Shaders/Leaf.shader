Shader "You/Leaf"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Clip ("Alpha clip", Range(0, 1) ) = 0
        _LightPos ("Light Position", Vector) = (0,0,0,0)
        _LightBrightness ("Light Brightness", Float) = 200
        _LightColor ("Light Color", Color) = (0,0,0)
        _StemPos ("Stem Position", Vector) = (0,0,0,0) 
        _AODistance ("Ambient Occlusion Distance", Float) = 0
        _Flutter ("Flutter", Range(0, 1)) = 0
        _PetalCurl ("Petal Curl", Float) = 0
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
                float4 worldPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Clip;
            float3 _LightPos;
            float _LightBrightness;
            float3 _LightColor;
            float _Flutter;
            float _AODistance;
            float3 _StemPos;
            float _PetalCurl;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                float3 toStem = worldPos - _StemPos;
                float stemDist = length(toStem);
                float curl = _PetalCurl + sin(_Time.y * 1.5) * 0.04;
                worldPos.y += stemDist * curl;

                float4 localPos = mul(unity_WorldToObject, worldPos);
                o.vertex = UnityObjectToClipPos(localPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = worldPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 image = tex2D(_MainTex, i.uv);
                clip(image.a - _Clip);

                float3 col = image.xyz;
                col = lerp(col, Luminance(col) * _LightColor, 0.9);
                col *= pow(1 - length(_LightPos - i.worldPos) / _LightBrightness, 3);

                float ao = length(_StemPos - i.worldPos) / _AODistance;
                ao = saturate(ao - 0.1);
                col *= ao;

                float flicker = 1 + sin(_Time.y * 100.587) * _Flutter;
                col *= flicker;
                
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
