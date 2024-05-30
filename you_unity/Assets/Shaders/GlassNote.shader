Shader "Unlit/GlassNote"
{
    Properties
    {
        _Color ("Note Color", Color) = (1,1,1)
        _RefractiveIndex ("Refractive Index", Float) = 1
        _RGBSplit ("RGB Split", Float) = 0.01
        [ToggleUI] _Arrow ("Arrow", Int) = 0
        _Cutout ("Cutout", Range(0,1)) = 1
        _ColorMix ("Color Mix", Range(0,1)) = 1
        _DistortionAmount ("Distortion Amount", Float) = 1
        _FadeDistance ("Fade Distance", Float) = 40
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        // Blend One One
        // ZWrite Off

        // #if UNITY_EDITOR 
        GrabPass { "_GlassNoteGrab" }
        // #endif

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 pos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 localPos : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float4 screenUV : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_INSTANCING_BUFFER_END(Props)

            float _RefractiveIndex;
            float _RGBSplit;
            bool _Arrow;
            float _ColorMix;
            float _DistortionAmount;
            float _FadeDistance;

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GlassNoteGrab);

            v2f vert (appdata v)
            {
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

                // local position
                o.localPos = v.vertex;

                // worldspace position
                o.pos = mul(unity_ObjectToWorld, v.vertex);

                // position to camera
                o.viewVector = normalize(o.pos - _WorldSpaceCameraPos);

                // Normal
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL));

                // UV
                o.uv =  WorldSpaceViewDir(v.vertex);

                // screenUV
                o.screenUV = ComputeGrabScreenPos(o.vertex);

                return o;
            }

            float3 rotate3D(inout half3 p, half x, half y, half z)
            {
                half cx, sx;
                half cy, sy;
                half cz, sz;
                sincos(x, sx, cx);
                sincos(y, sy, cy);
                sincos(z, sz, cz);
                return mul(p, half3x3(cy*cz, -cy*sz, sy, cx*sz+cz*sx*sy, cx*cz-sx*sy*sz, -cy*sx, sx*sz-cx*cz*sy, cz*sx+cx*sy*sz, cx*cy));
            }

            float3 getSkyColor(float3 viewVector) {
                return float4(DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, viewVector, 0), unity_SpecCube0_HDR), 0);
            }

            float4 getGrabPassCol(v2f i) {
                float2 uv = i.uv;
                float4 screenUV = (i.screenUV) / i.screenUV.w;
                // screenUV.xy += uv.xy*uv.xy*0.05;
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GlassNoteGrab, uv);
            }

            float4 getGrabPassUV(v2f i) {
                return i.screenUV / i.screenUV.w;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_SETUP_INSTANCE_ID(i);
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                // return float4(i.uv, 0, 0);

                // return tex2D(_GlassNoteGrab, UnityStereoScreenSpaceUVAdjust(i.uv, _GlassNoteGrab_ST));

                float noise = (gnoise3D(i.localPos * 2) * 0.5 + 0.25) * 2;
                float c = Cutout - noise;

                clip(c);

                float fog = saturate(1 - length((i.pos) / _FadeDistance));
                float4 screenUV = getGrabPassUV(i);
                float4 rawScreenCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GlassNoteGrab, screenUV);
                // screenUV.xy += i.uv.xy*i.uv.xy*0.05;

                if (c < 0.02) {
                    return lerp(float4(1,1,1,20), rawScreenCol, saturate(length((i.pos) / 8)));
                }

                if (_Arrow) {
                    return lerp(rawScreenCol, float4(Color, 2), fog);
                }

                float noiseAngle = noise *= UNITY_PI;
                float2 noiseVec = float2(cos(noiseAngle), sin(noiseAngle)) * _DistortionAmount;
                float3 distortedNormal = rotate3D(i.normal, noiseVec.x, noiseVec.y, 0);

                float3 refraction = refract(i.viewVector, distortedNormal, _RefractiveIndex);
                float3 reflection = reflect(i.viewVector, distortedNormal);

                screenUV.xy += noiseVec * 0.2;
                float4 screenCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GlassNoteGrab, screenUV);

                float3 col = saturate(getSkyColor(refraction));

                if (refraction.x == 0 && refraction.y == 0 && refraction.z == 0) {
                    col = 0;
                }

                col *= 3;
                // col = clamp(col, 0, 1);

                // col = Luminance(col) * _Color;

                float3 reflectionCol = float3(
                getSkyColor(lerp(reflection, i.normal, _RGBSplit)).x,
                getSkyColor(lerp(reflection, i.normal, -_RGBSplit)).y,
                getSkyColor(reflection).z
                );

                // float3 reflectionCol = saturate(getSkyColor(reflection));
                reflectionCol *= 10;

                // reflectionCol = clamp(reflectionCol, 0, 1);
                col += reflectionCol;

                col += screenCol.xyz * 0.8;

                col = lerp(col, Luminance(col) * Color, _ColorMix);

                // col = normalize(col) * Luminance(col);

                // col *= 20;

                // col = clamp(col, 0, 0.2);

                // col *= 4;

                float alpha = Luminance(col);

                // col = pow(col, 0.7);

                // return rawScreenCol;

                float4 finalCol = float4(col, alpha * 3);
                return lerp(rawScreenCol, finalCol, fog);
            }
            ENDCG
        }
    }
}
