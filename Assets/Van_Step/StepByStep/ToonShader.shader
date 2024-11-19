Shader "Custom/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _ShadowColor ("Shadow Color", Color) = (0.4, 0.4, 0.4, 1.0)
        _ShadowThreshold ("Shadow Threshold", Range(-1.0, 1.0)) = 0.0
        
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
            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _Color;
            float4 _LightColor0; // 似乎还需要一个include才能用？还是pragma来着，忘记了，哦不需要
            float4 _ShadowColor;
            half _ShadowThreshold;
            
            struct a2v
            {
                float3 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 worldVertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldView : TEXCOORD3;
                float3 worldLightDir : TEXCOORD4;
            };

            v2f vert(a2v i)
            {
                v2f o;
                o.worldVertex = UnityObjectToClipPos(i.vertex);
                o.uv = i.uv;
                // o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.worldView = normalize(UnityWorldSpaceViewDir(o.worldPos));
                o.worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
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
                float nDotL = dot(i.worldNormal, i.worldLightDir);
                half3 diffuse = nDotL > _ShadowThreshold ? 1.0 : _ShadowColor;

                // specular
                // 拿到世界坐标下的视线方向以及光照方向计算出半程向量，

                // combine all
                // Van_Wrong: half3 col = ambient + albedo.rgb * diffuse;
                half3 col = ambient * albedo + diffuse * albedo * _LightColor0;

                return half4(col.rgb, 1.0);
            }
            
            ENDCG
        }
    }
}
