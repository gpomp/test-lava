Shader "Custom/TriangleGeomShader"
{
    Properties
    {  
        _Uniform ("Uniform Tessellation", Range(1, 64)) = 1
        _TessMap ("Tessellation Map", 2D) = "black" {}
        _QuadSize ("Quad Size", Float) = 0.05
    }
    SubShader
    {
        Pass
        {  
            CGPROGRAM
 
            #pragma vertex TessellationVertexProgram
            #pragma hull HSMain
            #pragma domain DSMain
            #pragma fragment PSMain
            #pragma target 5.0
 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct ControlPoint
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
            }; 
            
            struct TessellationFactors 
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            sampler2D _TessMap;
            float _Uniform;
            float  _QuadSize;
           
            ControlPoint TessellationVertexProgram (appdata v)
            {
                ControlPoint p;
                p.vertex = v.vertex;
                p.uv = v.uv;
                return p;
            }
            TessellationFactors PatchConstantFunction(InputPatch<ControlPoint, 3> patch) 
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
 
            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [patchconstantfunc("PatchConstantFunction")]
            [outputcontrolpoints(3)]
           
            ControlPoint HSMain (InputPatch<ControlPoint,3> V, uint ID : SV_OutputControlPointID)
            {
                return V[ID];
            }
 
            [domain("tri")]
            ControlPoint DSMain (TessellationFactors factors, const OutputPatch<ControlPoint,3> P, float3 K : SV_DomainLocation)
            {
                ControlPoint ds;
                ds.vertex =  float4(P[0].vertex.xyz*K.x + P[1].vertex.xyz*K.y + P[2].vertex.xyz*K.z, 1.0);
                return ds;
            }
 
            [maxvertexcount(64)]
            void GSMain( triangle ControlPoint patch[3], inout TriangleStream<ControlPoint> stream )
            {
                ControlPoint GS;
                float3 delta = float3 (_QuadSize, 0.00, 0.00);
                float3 center = float3((patch[0].vertex.xyz + patch[1].vertex.xyz + patch[2].vertex.xyz) / 3);
                GS.uv = float2(0, 0);
                GS.vertex = UnityObjectToClipPos(center + delta.yyy);
                stream.Append(GS);
                GS.vertex = UnityObjectToClipPos(center + delta.yyx);
                stream.Append(GS);
                GS.vertex = UnityObjectToClipPos(center + delta.xyy);
                stream.Append(GS);
                GS.vertex = UnityObjectToClipPos(center + delta.xyy);
                stream.Append(GS);
                GS.vertex = UnityObjectToClipPos(center + delta.xyx);
                stream.Append(GS);
                GS.vertex = UnityObjectToClipPos(center + delta.yyx);
                stream.Append(GS);
                stream.RestartStrip();
            }
           
            float4 PSMain (ControlPoint ps) : SV_Target
            {
                return float4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
 
}
