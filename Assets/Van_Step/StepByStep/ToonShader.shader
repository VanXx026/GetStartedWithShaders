Shader "Custom/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower ("Specular Power", Float) = 20.0
        
        _OutlineColor ("Outline Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _OutlineWidth ("Outline Width", Range(0.0, 3.0)) = 1.0
        _OutlineNormalOffset ("Outline Normal Offset", Range(-1.0, 1.0)) = -0.5
        
        _GradientMap ("Gradient Map", 2D) = "white" {}
        _ShadowTex1 ("Shadow Texture 1", 2D) = "white" {}
        _ShadowTex1Color ("Shadow Texture 1 Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShadowTex2 ("Shadow Texture 2", 2D) = "white" {}
        _ShadowTex2Color ("Shadow Texture 2 Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        _RimlightColor ("Rimlight Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimlightPower ("Rimlight Power", Float) = 20.0
        _RimlightMask ("Rimlight Mask", 2D) = "white" {}
        
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _SpecularColor;
            half _SpecularPower;

            sampler2D _GradientMap;
            sampler2D _ShadowTex1;
            float4 _ShadowTex1Color;
            sampler2D _ShadowTex2;
            float4 _ShadowTex2Color;

            float4 _RimlightColor;
            half _RimlightPower;
            sampler2D _RimlightMask;

            float4 _LightColor0;
            
            struct a2v
            {
                float3 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormalDir : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldLightDir : TEXCOORD3;
                float3 worldViewDir : TEXCOORD4;
            };

            v2f vert(a2v i)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                o.worldNormalDir = normalize(UnityObjectToWorldNormal(i.normal));
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
                o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half3 albedo = tex2D(_MainTex, i.uv) * _Color;
                
                // ambient
                half3 ambient = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));
                
                // diffuse
                float nDotL = dot(i.worldNormalDir, i.worldLightDir) * 0.5 + 0.5;
                half2 diffGradient= tex2D(_GradientMap, float2(nDotL, 0.5)).rg;
                half3 diffuse = lerp(albedo, tex2D(_ShadowTex1, i.uv) * _ShadowTex1Color, diffGradient.x);
                diffuse = lerp(diffuse, tex2D(_ShadowTex2, i.uv) * _ShadowTex2Color, diffGradient.y);

                // specular
                float3 halfDir = normalize(i.worldViewDir + i.worldLightDir);
                float nDotH = dot(i.worldNormalDir, halfDir);
                nDotH = pow(max(nDotH, 1e-5), _SpecularPower);
                half specGradient = tex2D(_GradientMap, float2(nDotH, 0.5)).b;
                half3 specular = specGradient * _SpecularColor * albedo;

                // rimlight
                half nDotV = dot(i.worldNormalDir, i.worldViewDir);
                half rimGradient = tex2D(_GradientMap, float2(pow(max(1.0 - clamp(nDotV, 0.0, 1.0), 1e-5), _RimlightPower), 0.5)).a;
                float3 rimMask = tex2D(_RimlightMask, i.uv);
                half3 rimlight = rimGradient * rimMask * _RimlightColor * diffuse;
                
                // combine all
                half3 col = ambient * albedo + (diffuse + specular) * _LightColor0 + rimlight;

                return half4(col.rgb, 1.0);
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            
            float4 _LightColor0;

            float _OutlineWidth;
            float4 _OutlineColor;
            float _OutlineNormalOffset;
            
            struct a2v
            {
                float3 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v i)
            {
                v2f o;
                // 在视图空间偏移法线，让顶点朝法线方向向外扩散
                float3 viewPos = UnityObjectToViewPos(i.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, i.normal);
                viewNormal.z = _OutlineNormalOffset;
                viewPos = viewPos + normalize(viewNormal) * _OutlineWidth * 0.002;
                o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1.0));
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 albedo = tex2D(_MainTex, i.uv) * _Color;

                float3 col = albedo * _OutlineColor.rgb;

                return half4(col, 1.0);
            }
            ENDCG
        }
    }
}
