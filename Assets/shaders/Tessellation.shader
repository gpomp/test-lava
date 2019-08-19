Shader "Unlit/Tessellation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TessMap ("Tessellation Map", 2D) = "black" {}
        _NoiseMap ("Noise Map", 2D) = "black" {}
        _Uniform ("Uniform Tessellation", Range(1, 64)) = 1
        _Displacement ("Displacement", Range(0, 1.0)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM

            #pragma vertex TessellationVertexProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma geometry geomProgram
            #pragma fragment FragmentProgram

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            /* struct ControlPoint
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };   */
            
            struct TessellationFactors 
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            sampler2D _TessMap;
            sampler2D _NoiseMap;
            float _Uniform;
            float _Displacement;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f TessellationVertexProgram(appdata v)
            {
                v2f p;
                p.vertex = v.vertex;
                p.uv = v.uv;
                return p;
            }

            TessellationFactors PatchConstantFunction(InputPatch<v2f, 3> patch) 
            {
                float p0factor = tex2Dlod(_TessMap, float4(patch[0].uv.x, patch[0].uv.y, 0, 0)).r;
                float p1factor = tex2Dlod(_TessMap, float4(patch[1].uv.x, patch[1].uv.y, 0, 0)).r;
                float p2factor = tex2Dlod(_TessMap, float4(patch[2].uv.x, patch[2].uv.y, 0, 0)).r;
                float factor = (p0factor + p1factor + p2factor);
                TessellationFactors f;
                f.edge[0] = factor > 0.0 ? _Uniform : 1.0;
                f.edge[1] = factor > 0.0 ? _Uniform : 1.0;
                f.edge[2] = factor > 0.0 ? _Uniform : 1.0;
                f.inside = factor > 0.0 ? _Uniform : 1.0;
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("PatchConstantFunction")]
            v2f HullProgram(InputPatch<v2f, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            /* v2f VertexProgram (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            } */

            [UNITY_domain("tri")]
            v2f DomainProgram(TessellationFactors factors, 
                    OutputPatch<v2f, 3> patch,
                    float3 barycentricCoordinates : SV_DomainLocation) 
            {
                v2f data;

                data.vertex = patch[0].vertex * barycentricCoordinates.x + 
                    patch[1].vertex * barycentricCoordinates.y +
                    patch[2].vertex * barycentricCoordinates.z;
                data.uv = patch[0].uv * barycentricCoordinates.x +
                    patch[1].uv * barycentricCoordinates.y +
                    patch[2].uv * barycentricCoordinates.z;

                return data;
            }
 
            [maxvertexcount(6)]
            void geomProgram(triangle v2f patch[3], inout TriangleStream<v2f> stream)
            {
                v2f GS;

                float2 midUv = (patch[0].uv + patch[1].uv + patch[2].uv) / 3;
                float4 nb = tex2Dlod(_NoiseMap, float4(patch[0].uv, 0, 0));
                
                float d = tex2Dlod(_TessMap, float4(midUv, 0, 0)).r * ceil(nb.z - 0.3);
                float n = floor((nb.x + nb.y) * 30) / 30;
                float l = lerp(n - 0.3, n, _Displacement);
                float3 disp = lerp(float3(0, 0, 0), float3(0, -5, 0), _Displacement * smoothstep(0.0, 0.1, d) * l);
                GS.vertex = UnityObjectToClipPos(patch[0].vertex.xyz + disp);
                GS.uv = TRANSFORM_TEX(patch[0].uv, _MainTex);
                stream.Append(GS); 
                GS.vertex = UnityObjectToClipPos(patch[1].vertex.xyz + disp);
                GS.uv = TRANSFORM_TEX(patch[1].uv, _MainTex);
                stream.Append(GS); 
                GS.vertex = UnityObjectToClipPos(patch[2].vertex.xyz + disp);
                GS.uv = TRANSFORM_TEX(patch[2].uv, _MainTex);
                stream.Append(GS);
                stream.RestartStrip();
            }


            fixed4 FragmentProgram (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
