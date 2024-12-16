Shader "You/Ribbon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgePercent ("Edge Percent", Range(0, 0.5)) = 0.1
        _UVScale ("UV Scale", Float) = 1
        _RepeatTime ("Repeat Time", Float) = 0.7
        _InflexPoint ("Inflex Point", Float) = 0
        _NearFadeOutPoint ("Near Fade Out Point", Float) = 0
        _FarFadeOutPoint ("Far Fade Out Point", Float) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
        [Toggle(DISSOLVE_BORDER)] _DissolveBorder ("Dissolve Border", Int) = 0
        _Movement ("Movement", Range(0,1)) = 1
        _MovementOffset ("Movement Offset", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DISSOLVE_BORDER

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Colors.cginc"
            #include "Assets/CGIncludes/Noise.cginc"

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
                float3 objPos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _EdgePercent;
            float _UVScale;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _RepeatTime;
            float _InflexPoint;
            float _NearFadeOutPoint;
            float _FarFadeOutPoint;
            float _Opacity;
            float _Movement;
            float _MovementOffset;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                worldVertex.y += sin(worldVertex.z / 30 + _Time.y) * 10;
                worldVertex.xy *= pow((_InflexPoint - worldVertex.z) / _InflexPoint, 1);
                worldVertex.z += _MovementOffset * _Movement;
                v.vertex = mul(unity_WorldToObject, worldVertex);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.objPos = v.vertex;
                o.worldPos = worldVertex;
                return o;
            }

            float softenEdge(float x, float b)
            {
                return 1 - pow(2 * abs(0.5 - x), b);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.worldPos.z -= _MovementOffset * _Movement;

                float2 uv = i.uv;
                uv.x *= _UVScale;
                uv.x = (uv.x + i.objPos.z * 0.3) % 1;

                float t = (cos(_Time.y * UNITY_PI * _RepeatTime * 2) * 0.5 + 0.5) * 0.1 + _Time.y * _RepeatTime;
                float y = abs(uv.y - 0.5) + t;
                y += cos(i.objPos.z * 30);
                uv.y = y;

                float f = Luminance(tex2D(_MainTex, uv).xyz);

                float distToEdge = min(i.uv.y, 1 - i.uv.y);

                if (
                    distToEdge < _EdgePercent
                ) {
                    float mix = distToEdge / _EdgePercent;
                    mix = pow(mix, 3);
                    f += lerp(1, Luminance(tex2D(_MainTex, float2(uv.x, 0.5))) * 9, mix);
                }

                float3 col = lerp(rainbow(i.objPos.z * 20), 1, 0.2);
                col = lerp(col, palette(i.objPos.x * 10, 0.5, 0.5, 1, float3(0, 0.1, 0.2)), 0.4);
                col *= f;

                float4 output = float4(col, f * 0.5);
                output *= pow(saturate((i.worldPos.z - _NearFadeOutPoint) / 1000), 40);
                output *= pow(saturate((_FarFadeOutPoint - i.worldPos.z) / 700), 40);
                // output = pow((i.worldPos.z * 0.001 - _FadeOutPoint), 3);

                float outlinePoint = lerp(_InflexPoint, 0, _Opacity);
                float outlineDist = (i.worldPos.z + gnoise3D(i.worldPos * 0.1) * 20) - outlinePoint;
                float dissolveFac = 1 - pow(_Opacity, 30);
                clip(outlineDist);
                if (outlineDist < 0) return lerp(output, 0, dissolveFac);

                #if DISSOLVE_BORDER
                if (outlineDist < dissolveFac * 6)
                {
                    return (1 - pow(1 - _Opacity, 40)) * 10;
                }
                #endif

                output *= _Opacity;

                return float4(output);
            }
            ENDCG
        }
    }
}
