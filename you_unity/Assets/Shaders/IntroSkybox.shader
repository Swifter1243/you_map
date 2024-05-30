// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/IntroSkybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("Size", Float) = 1
        _ID ("ID", Int) = 0
        _Zoom ("Zoom", Range(0, 1)) = 0
        _Flutter ("Flutter", Range(0, 1)) = 1
        _Light ("Light", Range(0, 1)) = 0
        _Hue ("Hue", Range(0, 1)) = 0
        _Opacity ("Opacity", Range(0, 1)) = 0
        _RingCompress ("Ring Compress", Range(0, 1)) = 0
        _AngleOffset ("Angle Offset", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Colors.cginc"
            #include "Noise.cginc"
            #include "Easings.cginc"

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
                float3 pos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Size;
            uint _ID;
            float _Zoom;
            float _Flutter;
            float _Light;
            float _Hue;
            float _Opacity;
            float _RingCompress;
            float _AngleOffset;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 pos = i.pos / _Size;
                float2 vec = i.pos.xy;
                float rawAngle = atan2(vec.y, vec.x);

                _Zoom = _Zoom % 1;

                // _Zoom = easeInOutExpo(_Zoom);

                // Normalize
                float angle = (rawAngle + UNITY_PI) / UNITY_PI / 2;

                float destAngle = _ID * 0.22 + hashwithoutsine11(_ID) * 0.3 * _Light;
                destAngle += _AngleOffset;
                destAngle = (destAngle + pos.z * 0.4) % 1;

                float wrap = min(min(abs(destAngle - angle), abs(destAngle - angle + 1)), abs(destAngle - angle - 1));
                float thinness = 1 + -pow(pos.z, 60) * 0.4 * (1 - _Hue);
                float3 col = pow(saturate(1 - wrap * thinness), 20);
                col *= 1 - pow(1 - _Zoom, 60);
                col = lerp(col, 0.1, pow(_Light, 4));
                // _Zoom = lerp(_Zoom, 0.5, _Light);
                // _ID = lerp(_ID, 1, _Light);

                float a = atan2(abs(vec.y), vec.x);
                col += gnoise((a - destAngle) * 20) * 0.01 * (1 - _Light);

                col += saturate((1 - abs(0.5 - _Zoom) * 2)) * 0.1 * saturate(1 - wrap * 10) * (1 - _Light);

                float z = lerp(0.4, 1.4, _Zoom);

                {
                    float ring = pow(saturate(1 - abs(pos.z - z)), 8);
                    col *= ring;
                    col *= saturate(pos.z);
                }

                {
                    float ringZoomInfluence = 0.3 + pow(_Light, 0.3) * 0.7;
                    z = lerp(z, 0.9 + _RingCompress * 0.03, ringZoomInfluence);
                    float ring = pow(saturate(1 - abs(pos.z - z)), 8);
                    col = lerp(col, 0.1, lerp(0, z, _Light)) * ring * lerp(1, 3, _Light);
                }


                col *= palette(pos.z + 0.3 * _Hue, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col *= 2 * pos.z * (1 + sin(_Time.y * 60) * 0.1 * _Flutter);

                float f = 1 - length(pos.xy);
                {
                    float twist = f * 3 * sin(_Time.y * 0.1) + 10 - pos.z * 5;
                    float a = sin(rawAngle * 2 + cos(_Time.y * 0.1) + twist);
                    a -= pos.z;

                    float t = f + a + _Time.y * 0.1;
                    float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    float3 col2 = palette(t + 0 + 1, 0.5, 0.5, 1, float3(0.30, 0, 0.20));

                    float3 col3 = lerp(col1, col2, a);
                    
                    float t2 = pow(saturate(f), 2);
                    col3 = lerp(col1, 1, t2);

                    col3 *= pow(saturate(f), 4) - a * 0.1;

                    col3 *= lerp(col3, 1, 0.3);

                    col3 *= 0.2;
                    
                    col3 += pow(abs(f), 50) * 0.9;

                    col3 = lerp(col3, 1, pow(abs(f), 30));

                    col += col3 * _Light;
                }


                col *= lerp(length(pos.xy), 1, _Opacity);

                // Swirls
                float dist = sin(length(pos.xy) * 5 + _Time.y * 1 + rawAngle * 3);
                float pattern = cos(rawAngle * 5 + dist *2) + cos(rawAngle * 4);
                pattern = pattern * 0.5 + 0.5;
                // pattern *= pos.z * 2;
                pattern *= saturate(1 - pos.z * 1.1);
                pattern *= saturate(pos.z * 0.6 + 0.3);
                // col = pattern;
                float3 swirlcol = palette(dist, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                col += pattern * 0.7 * lerp(col, 1, 0.8) * pow(_Light, 2) * swirlcol;
                // col = pattern;

                // col = dist;

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
