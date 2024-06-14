// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "You/DropSkybox"
{
    Properties
    {
        _Twist ("Twist", Float) = 1
        _Size ("Size", Float) = 700
        _TimeOffset ("Time Offset", Float) = 0
        _TimeSpeed ("Time Speed", Float) = 1
        _Flicker ("Flicker", Range(0,1)) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
        _Alpha ("Alpha", Range(0,1)) = 1
        _Mirrors ("Mirrors", Int) = 5
        _HueShift ("Hue Shift", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend One OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Colors.cginc"
            #include "Noise.cginc"

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

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.pos = v.vertex;
                return o;
            }

            float _Twist;
            float _Size;
            float _TimeOffset;
            float _TimeSpeed;
            float _Flicker;
            float _Opacity;
            float _Alpha;
            int _Mirrors;
            float _HueShift;

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _TimeSpeed + _TimeOffset;

                float3 pos = i.pos / _Size;
                float2 vec = i.pos.xy;
                float angle = atan2(vec.y, vec.x);

                float3 col = 0;

                {                
                    float f = 1 - length(i.pos.xy) / _Size * 2;
                    float twist = f * _Twist * sin(time * 0.2 + pos.z * 2) - pos.z;
                    float a = sin(angle * _Mirrors * 4 + cos(time) + twist * 5);
                    a -= pos.z;
                    a += gnoise(float2(pos.z * 200, a)) * 0.2;

                    float t = f + a + time * 0.8;
                    // cos(time * 0.1 + pos.z)
                    float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    float3 col2 = palette(t + cos(time * 0.3 + pos.z), 0.5, 0.5, 1, float3(0.1, 0.33, 3.66));

                    col += lerp(col1, col2, cos(time * 5 + pos.z) * 0.2 + f);
                    
                    float t2 = pow(saturate(f), 1);
                    col = lerp(col, 1, t2);

                    // col *= sin(pos.z + time) * 0.5 + 0.5;
                    
                    col *= pow(saturate(f), 2) - a * 0.3;
                    col *= lerp(col, 1, 0.2);
                    col *= saturate(f + 2);
                }

                {                
                    float f = 1 - length(i.pos.xy) / _Size * 2;
                    float twist = f * _Twist * sin(time * 0.2 + pos.z * 2) - pos.z;
                    float a = sin(angle * _Mirrors + cos(time) + twist);
                    a -= pos.z;
                    a += gnoise(pos.z * 4) * 1;

                    float t = f + a + time * 0.8;
                    // cos(time * 0.1 + pos.z)
                    float3 col1 = palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    float3 col2 = palette(t + cos(time * 0.3 + pos.z), 0.5, 0.5, 1, float3(0.1, 0.33, 0.66));

                    col += lerp(col1, col2, cos(time * 5 + pos.z) * 0.2 + f);
                    
                    float t2 = pow(saturate(f), 1);
                    col = lerp(col, 1, t2);

                    // col *= sin(pos.z + time) * 0.5 + 0.5;
                    
                    col *= pow(saturate(f), 2) - a * 0.3;
                    col *= lerp(col, 1, 0.2);
                    col *= saturate(f + 2);

                    col += col1 * sin((pos.z + time * 0.3) * 6) * 0.3;
                    col += col2 * cos((pos.z + time * 0.3) * 6) * 0.3;
                }

                col *= saturate((i.pos.z - 300) / 300);

                // Outside Swirls
                {
                    // col = 0;
                    float dist = sin(length(pos.xy) * 5 + _Time.y * 1 + angle * 3);
                    float pattern = cos(angle * 5 + dist *2) + cos(angle * 4);
                    pattern = pattern * 0.5 + 0.5;
                    // pattern *= pos.z * 2;
                    pattern *= saturate(1 - pos.z * 0.4);
                    pattern *= saturate(pos.z * 0.6 + 0.3);
                    // col = pattern;
                    float3 swirlcol = palette(dist, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
                    col += pattern * 0.7 * lerp(col, 1, 0.8) * swirlcol;
                }

                float hue = (_HueShift + length(vec) / _Size) % 1;
                col = hueShift(col, hue);

                float middleBrightnessMask = smoothstep(0, 0.6, length(pos.xy));
                col *= middleBrightnessMask;

                col *= _Opacity;

                // Gamma Correct
                col = saturate(col);
                col = pow(col, 2.2);

                // Alpha
                float alpha = Luminance(col) * _Alpha;
                alpha *= (sin(_Time.y * 100) * 0.5 + 0.5) * _Flicker;
                alpha += col * (cos(hue * UNITY_PI * 2) * 0.5 + 0.5);

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
