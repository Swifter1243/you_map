Shader "You/Template"
{
    Properties
    {
        // Define properties to change in the inspector

        // This parameter will be registered with name "_Parameter" and will be a "Float" (decimal number)
        // It will display as "Some Parameter" in the inspector
        _Parameter ("Some Parameter", Float) = 3 // Default value of 3
    }
    SubShader
    {
        // This object will be opaque.
        // Other rendertypes and render queues can be set to render transparent geometry.
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            // Starting the shader program
            // Allows us to define the vertex and fragment shaders
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Imports unity's functions for potential use in the shader
            #include "UnityCG.cginc"

            // Data being passed into the vertex shader
            struct appdata
            {
                float4 vertex : POSITION; // This is where the vertex is in OBJECT SPACE
                float2 uv : TEXCOORD0; // This is the UV data from the mesh

                UNITY_VERTEX_INPUT_INSTANCE_ID // Unity macro to make the shader work in 1.29 and 1.3X
            };

            // Data being passed into the fragment (pixel) shader
            struct v2f
            {
                // "SV_POSITION" is a keyword used by the fragment shader to determine information about where to render the vertex.
                // To be honest I am not fully sure about this works myself, but I know that it's required to properly render the shape.
                float4 vertex : SV_POSITION;

                // The "TEXCOORD<N>" keywords are basically any data you'd like to pass into the fragment shader from the vertex shader.
                // In this case, we're passing data about the UV.
                float2 uv : TEXCOORD0;


                UNITY_VERTEX_OUTPUT_STEREO // Unity macro to make the shader work in 1.29 and 1.3X
            };

            // Define the parameter from the inspector we defined earlier.
            float _Parameter;
            
            v2f vert (appdata v)
            {
                // Unity macros to make the shader work in 1.29 and 1.3X
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // Assign UV data
                o.uv = v.uv;

                // Convert vertex position from object space to clip space and assign
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Return the output vertex data.
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // The fragment shader needs a 4 number RGBA output.
                // The UV data is only 2 numbers, so we can use it to fill the R and G channels, and set the others to 0.
                // HLSL knows that "i.uv" is 2 numbers, so it will use it to automatically spread the numbers out.
                // But for example, float4(i.uv.x, i.uv.y, 0, 0) is the same thing.

                return float4(i.uv, 0, 0); // (R, G, B, A)
            }
            ENDCG
        }
    }
}
