Shader "You/BuildupPanel"
{
    Properties
    {
        _Progress ("Progress", Float) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
        _Angle ("Angle", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        ZWrite Off
        ZTest Off

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
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Progress;
            float _Opacity;
            float _Angle;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = (i.uv - 0.5) * 2;
                float dist = 1 - saturate(length(uv));

                // Gay
                float3 col = rainbow(dist * 1 + _Time.y * 0.2 + uv.y * 0.5) * 5;

                // Noise
                col *= 0.1 + gnoise(gnoise(uv * 3 + _Time.y * 0.5)) * 0.9;

                // Falloff
                col *= dist;

                // Waves
                col *= 1 - pow(1 - (cos(pow(dist, 0.4) * 10 + _Progress * 5)), 0.1);
                col *= smoothstep(0.6, 1.6, cos(pow(dist, 0.4) * 10 + _Progress * 5));
                col *= 6;

                // Opacity
                col *= _Opacity;

                // Wave Funnyness
                float rawAngle = atan2(uv.y, uv.x);
                float angle = (rawAngle + UNITY_PI) / UNITY_PI / 2;

                float destAngle = _Angle % 1;

                float wrap = min(min(abs(destAngle - angle), abs(destAngle - angle + 1)), abs(destAngle - angle - 1));
                col *= lerp(pow(wrap, 0.7) - 0.2, 1, pow(_Opacity - 0.1, 60));

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);
                return float4(col, Luminance(col) * 4);
            }
            ENDCG
        }
    }
}
