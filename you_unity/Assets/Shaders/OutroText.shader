Shader "You/OutroText"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PlaneDistance ("Plane Distance", Float) = 20
        _PlaneOffset ("Plane Offset", Float) = 0
        _Whiteness ("Whiteness", Range(0,1)) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend One OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/CGIncludes/Noise.cginc"
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
                float3 worldPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _PlaneDistance;
            float _PlaneOffset;
            float _Whiteness;
            float _Opacity;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                _PlaneDistance += _PlaneOffset;
                float3 textCol = tex2D(_MainTex, i.uv).xyz;
                if (textCol.x < 0.9) textCol = 0;

                float3 toText = i.worldPos - _WorldSpaceCameraPos;
                // col = gnoise((toText * 2 + _WorldSpaceCameraPos).xy);

                float planeDist = _PlaneDistance - i.worldPos.z;
                float3 planeIntersect = i.worldPos + normalize(toText) * planeDist;
                float n = gnoise3D(float3(planeIntersect.xy / 30, _Time.y * 4));

                float2 starScroll = float2(planeIntersect.x, planeIntersect.y + sin(_Time.y + planeIntersect.y * 0.1));
                float3 col = textCol - (1 - saturate(pow(gnoise(starScroll), 60))) * 0.9;
                col *= rainbow(n);

                // col *= cos(length(planeIntersect.xy));

                // col = planeDist;

                col = lerp(col, textCol, pow(_Whiteness, 2));

                col *= _Opacity;

                return float4(col, Luminance(col));
            }
            ENDCG
        }
    }
}
