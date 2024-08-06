Shader "You/CircleOutline"
{
    Properties
    {
        _Progress ("Progress", Range(0,1)) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
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

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Colors.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float _Progress;
            float _Opacity;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 objPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.objPos = v.vertex;
                return o;
            }

            const static float3 sunDirection = normalize(float3(1.,0.2,-0.2));

            fixed4 frag (v2f i) : SV_Target
            {
                float angle = lerp(-1.4, 4.8, _Progress);

                float3 curSunDirection = normalize(sunDirection + float3(0.,cos(angle), sin(angle))).yxz;
                float3 normal = normalize(i.objPos);
                float d = dot(normal, curSunDirection);

                float fresnel = saturate(1 - dot(normal, float3(0,0,-1)));

                // d = pow(d, 3);
                float3 col = rainbow((1.6 - d + _Progress * 0.8) * 0.5) * pow(-d, 3) * pow(fresnel, 3);
                // col = pow(fresnel, 8);
                // col = 1;
                // col = pow(-d, 3);

                col *= 6;
                col *= 1 - pow(abs(_Progress - 0.5) * 2, 5);

                col *= _Opacity;

                col = gammaCorrect(col);
                float alpha = Luminance(col) * 6;
                // alpha = 0;

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
