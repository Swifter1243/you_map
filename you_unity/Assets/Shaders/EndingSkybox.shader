// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/EndingSkybox"
{
    Properties
    {
        _Twist ("Twist", Float) = 1
        _Size ("Size", Float) = 700
        _TimeOffset ("Time Offset", Float) = 0
        _TimeSpeed ("Time Speed", Float) = 1
        _Flicker ("Flicker", Range(0,1)) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
        _Darken ("Darken", Range(0,1)) = 1
        _Alpha ("Alpha", Range(0,1)) = 1
        _Flash ("Flash", Range(0,1)) = 0
        _FadePoint ("Fade Point", Range(0,1)) = 0
        _FadeSlope ("Fade Slope", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        // Blend One OneMinusSrcAlpha
        ZWrite Off
        // ZTest Always

        Pass
        {
            // Stencil
            // {
                //     Ref 1
                //     Comp [_StencilComp]
                //     Pass [_StencilOp] 
                //     ReadMask [_StencilReadMask]
                //     WriteMask [_StencilWriteMask]
            // }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
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
                float3 pos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.pos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float _Twist;
            float _Size;
            float _TimeOffset;
            float _TimeSpeed;
            float _Flicker;
            float _Opacity;
            float _Alpha;
            float _Flash;
            float _Darken;
            float _FadePoint;
            float _FadeSlope;

            float3 capColor(float3 color, float maxValue)
            {
                float3 normalizedColor = normalize(color);
                float3 cappedColor = normalizedColor * min(maxValue, length(color));
                return cappedColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _TimeSpeed + _TimeOffset;

                float3 pos = i.pos / _Size;
                float2 vec = i.pos.xy;
                float angle = atan2(vec.y, vec.x);

                float3 col = 0;
                float3 cola = 0;

                {                
                    float f = 1 - length(i.pos.xy) / _Size * 2;
                    float twist = f * _Twist * (sin(time * 0.2 + pos.z * 2) * 0.5 + 1) - pos.z;
                    float a = sin(angle * 20 + cos(time * 0.1) + twist * 5);
                    a -= pos.z;

                    float t = f + a + time * 0.1;
                    // cos(time * 0.1 + pos.z)
                    float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    float3 col2 = palette(
                    t + cos(time * 0.3 + pos.z), 
                    float3(0.348, -5, 0.528), 
                    float3(-0.472, 0.028, 0.538), 
                    float3(-0.4, 0.2, 1), 
                    float3(-3.052, 0.333, 0.67)
                    );

                    col += capColor(lerp(col1, col2, cos(time * 0.1 + pos.z) * 0.2 + f), 2);
                    
                    float t2 = pow(saturate(f), 1);
                    col = lerp(col, 1, t2);

                    // col *= sin(pos.z + time) * 0.5 + 0.5;
                    
                    col *= pow(saturate(f), 2) - a * 0.3;
                    col *= lerp(col, 1, 0.2);
                    col *= saturate(f + 2);
                }

                float f = 1 - length(i.pos.xy) / _Size * 2;
                float twist = f * _Twist * (sin(time * 0.2 + pos.z * 2) * 0.5 + 1) - pos.z;
                float a = sin(angle * 5 + cos(time * 0.1) + twist);
                a -= pos.z;

                {                

                    float t = f + a + time * 0.1;
                    // cos(time * 0.1 + pos.z)
                    float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    float3 col2 = palette(
                    t * 0.1 + cos(time * 0.1), 
                    float3(0.448, -1.302, 0.528), 
                    float3(-0.32, 0.7, 0.7), 
                    float3(4, 0.2, 0 ), 
                    float3(-3.072, 0.3, 0.667)
                    );

                    col += capColor(lerp(col1, col2, cos(time + pos.z) * 0.1 + f) * 0.8, 1);

                    // col += col2;

                    cola = col1;
                    
                    float t2 = pow(saturate(f), 1);
                    col = lerp(col, 3, t2);

                    // col *= sin(pos.z + time) * 0.5 + 0.5;
                    
                    col *= lerp(pow(saturate(f), 2) - a * 0.7, 1, 0.5);
                    col *= lerp(col, 1, 0.2);
                    col *= saturate(f + 2);

                    // col += col1 * sin((pos.z + time * 0.3) * 6) * 0.1;
                    // col += col2 * cos((pos.z + time * 0.3) * 6) * 0.1;
                }

                col *= lerp(sin(a * 6) + sin(a * 12) * 0.5 + sin(a * 30) + cos(a * 20), 1, 0.99);

                // Sun
                float3 skyColor = palette(i.worldPos.y / 500 + 0.2, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                float skyBrightness = saturate(pos.y * 3 + 1);
                // return skyBrightness;
                col += saturate(1 - (i.worldPos.y + 100) / 500) * skyColor * skyBrightness;
                col = lerp(col, (skyColor * 5 + 1) * skyBrightness, saturate(1 - length(i.worldPos.xy) / 200));
                float sunBrightness = saturate(1 - length(i.worldPos.xy) / 10) * 40;
                sunBrightness += pow(saturate(1 - length(i.worldPos.xy) / 40), 3) * 3;
                col += sunBrightness * skyBrightness;
                // col = skyColor;

                // Fading
                col *= _Opacity * _Darken;
                // col *= saturate((i.pos.z + 700) / 900);
                col *= saturate(pos.z * _FadeSlope + _FadePoint * _FadeSlope);
                col *= 1 + _Flash * 0.7;

                // Ambient color
                float3 viewVec = normalize(_WorldSpaceCameraPos - i.worldPos);
                col += rainbow(viewVec.x * 0.7) * 0.06;

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);

                // Alpha
                float alpha = Luminance(col) * _Alpha;
                alpha = 1 - pow(1 - alpha, 6);

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
