Shader "Custom/TessellationSurface"
{
    Properties {
            _MainTex ("Base (RGB)", 2D) = "white" {}
            _TessMap ("Tessellation Map", 2D) = "black" {}
            _Displacement ("Displacement", Range(0, 10.0)) = 0.3
            _Uniform ("Uniform Tessellation", Range(1, 64)) = 1
            _DispTex ("Disp Texture", 2D) = "gray" {}
            _NormalMap ("Normalmap", 2D) = "bump" {}
            _Color ("Color", color) = (1,1,1,0)
            _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)
        }
        SubShader {
            Tags { "RenderType"="Opaque" }
            LOD 300
            
            CGPROGRAM
            #pragma surface surf BlinnPhong vertex:disp tessellate:tessDistance nolightmap
            #pragma target 3.0
            #include "Tessellation.cginc"

            struct appdata {
                float4 vertex : POSITION; 
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            float _Tess;
            sampler2D _TessMap;
            float _Uniform;

            float getMapFactor(float2 p1, float2 p2, float perc) {
                return tex2Dlod(_TessMap, float4(lerp(p1, p2, perc), 0, 0)).r;
            }

            float4 tessDistance (appdata v0, appdata v1, appdata v2) {
                float p0factor = getMapFactor(v0.texcoord, v1.texcoord, 0.0);
                float p1factor = getMapFactor(v0.texcoord, v1.texcoord, 1.0);
                float p2factor = getMapFactor(v0.texcoord, v2.texcoord, 1.0);
                float p01factor = getMapFactor(v0.texcoord, v1.texcoord, 0.5);
                float p02factor = getMapFactor(v0.texcoord, v2.texcoord, 0.5);
                float p12factor = getMapFactor(v1.texcoord, v2.texcoord, 0.5);
                float factor = (p0factor + p1factor + p2factor + p01factor + p02factor + p12factor) / 6.0;               
                return float4(
                    factor > 0.0 ? _Uniform : 1.0,
                    factor > 0.0 ? _Uniform : 1.0,
                    factor > 0.0 ? _Uniform : 1.0,
                    factor > 0.0 ? _Uniform : 1.0
                );
            }

            sampler2D _DispTex;
            float _Displacement;

            void disp (inout appdata v)
            {
                float d = tex2Dlod(_TessMap, float4(v.texcoord, 0, 0)).r * -1 * _Displacement;
                v.vertex.xyz += v.normal * d;
            }

            struct Input {
                float2 uv_MainTex;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            fixed4 _Color;

            void surf (Input IN, inout SurfaceOutput o) {
                half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
                float cLava = tex2D (_TessMap, IN.uv_MainTex).r;
                o.Albedo = lerp(c.rgb, float3(0.8, 0.2, 0.0), smoothstep(0.0, 0.1, cLava));
                o.Specular = 0.2;
                o.Gloss = 1.0;
                o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
            }
            ENDCG
        }
        FallBack "Diffuse"
}
