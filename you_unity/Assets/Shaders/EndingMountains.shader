Shader "You/EndingMountains"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightPos ("Light Position", Vector) = (0,0,0,0)
        _LightSpread ("Light Spread", Float) = 200
        _LightBrightness ("Light Brightness", Range(0,1)) = 1
        _LightColor ("Light Color", Color) = (0,0,0)
        _AmbientColor ("Ambient Color", Color) = (0,0,0)
        _AmbientBrightness ("Ambient Brightness", Range(0,1)) = 1
        _ShadowHarshness ("Shadow Harshness", Float) = 1
        _FogDistance ("Fog Distance", Float) = 1
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 normal : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _LightPos;
            float _LightSpread;
            float3 _LightColor;
            float _LightBrightness;
            float _ShadowHarshness;
            float3 _AmbientColor;
            float _AmbientBrightness;
            float _FogDistance;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                _LightSpread += sin(_Time.y) * 30;

                float3 toLight = _LightPos - i.worldPos;
                float d = pow(dot(i.normal, normalize(toLight)) * 0.5 + 0.5, _ShadowHarshness);
                float3 col = _LightColor * d;
                col *= saturate(pow(1 - length(toLight) / _LightSpread, 3) * _LightBrightness);

                // col = d;

                col += saturate(dot(i.normal, normalize(float3(0,-1,0.7)))) * _AmbientColor * _AmbientBrightness;

                float rockColor = frac(gnoise(gnoise(i.worldPos.xz * 0.08 * float2(0.02,1))) * 6);
                rockColor += hash(i.worldPos.xz).x;
                col *= lerp(rockColor, 1, 0.5);

                float dist = length(i.worldPos - _WorldSpaceCameraPos) / _FogDistance;
                col *= saturate(1 - dist); 
                
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
