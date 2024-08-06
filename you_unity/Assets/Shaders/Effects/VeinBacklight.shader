Shader "You/VeinBacklight"
{
    Properties
    {
        _Progress ("Progress", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha

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

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float _Progress;

            fixed4 frag (v2f i) : SV_Target
            {
                _Progress = lerp(0.126, 1, _Progress);

                float2 uv = (i.uv - 0.5) * 2;
                float a = atan2(uv.y, uv.x) + _Time.y * 0.1;

                float dist = 1 - length(uv);
                dist -= 1 - _Progress;
                a += dist;
                dist += sin(a * 10) * 0.03; 
                dist = pow(saturate(dist), 4);
                dist *= 0.5;

                float3 col = dist;

                col *= lerp(rainbow(dist * 1.5 + _Time.y * 0.3), 1, 0.6);

                return float4(col, Luminance(col));
            }
            ENDCG
        }
    }
}
