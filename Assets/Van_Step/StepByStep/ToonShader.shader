Shader "Custom/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _ShadowColor ("Shadow Color", Color) = (0.4, 0.4, 0.4, 1.0)
        _ShadowThreshold ("Shadow Threshold", Range(-1.0, 1.0)) = 0.0
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularThreshold ("Specular Threshold", Range(0.0, 1.0)) = 0.5
        _SpecularPower ("Specular Power", Float) = 20.0
        
        _OutlineColor ("Outline Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _OutlineWidth ("Outline Width", Range(0.0, 3.0)) = 1.0
        _OutlineNormalOffset ("Outline Normal Offset", Range(-1.0, 1.0)) = -0.5
        
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
            
            float4 _LightColor0; // 似乎还需要一个include才能用？还是pragma来着，忘记了，哦不需要

            float4 _ShadowColor;
            half _ShadowThreshold;
            float4 _SpecularColor;
            half _SpecularThreshold;
            half _SpecularPower;
            
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
//                o.uv = i.uv;
                o.uv = TRANSFORM_TEX(i.uv, _MainTex); // 如果需要用到Tilling和Offset需要用这个宏，而且需要额外声明float4 _MainTex_ST;
                o.worldNormalDir = normalize(UnityObjectToWorldNormal(i.normal));
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
                o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // 得拿到最基本的贴图颜色，也就是基本色或者说反射率albedo，角色反射的光也就反映的是基本颜色
                // Van_Wrong: half3 albedo = tex2D(_MainTex, i.uv) * _LightColor0;
                half3 albedo = tex2D(_MainTex, i.uv) * _Color;
                
                // ambient
                // 拿到天空盒的数据，通过世界空间下的法线去计算颜色
                half3 ambient = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));
                
                // diffuse
                // 拿到世界坐标下的光照方向以及法线方向，计算出NDotL，然后通过二分阴影阈值去计算，还需要阴影颜色和光照颜色
                float nDotL = dot(i.worldNormalDir, i.worldLightDir);
                half3 diffuse = nDotL > _ShadowThreshold ? 1.0 : _ShadowColor;

                // specular
                // 拿到世界坐标下的视线方向以及光照方向计算出半程向量，
                float3 halfDir = normalize(i.worldViewDir + i.worldLightDir);
                float nDotH = dot(i.worldNormalDir, halfDir);
                nDotH = pow(max(nDotH, 1e-5), _SpecularPower);
                half3 specular = nDotH > _SpecularThreshold ? _SpecularColor : 0.0;

                // combine all
                // Van_Wrong: half3 col = ambient + albedo.rgb * diffuse;
                half3 col = ambient * albedo + (diffuse + specular) * albedo * _LightColor0;

                return half4(specular.rgb, 1.0);
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
                // 在视图控件偏移法线，让顶点朝法线方向向外扩散
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
