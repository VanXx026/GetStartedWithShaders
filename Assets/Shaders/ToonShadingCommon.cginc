#ifndef TOON_SHADING_COMMON
#define TOON_SHADING_COMMON

sampler2D _MainTex;
float4 _MainTex_ST;
half4 _Color;
half _SpecularPower;
half4 _SpecularColor;
half _CutOff;

sampler2D _RimLightMask;
half4 _RimLightColor;
float _RimLightPower;

sampler2D _GradientMap;

sampler2D _ShadowColor1stTex;
half4 _ShadowColor1st;
sampler2D _ShadowColor2ndTex;
half4 _ShadowColor2nd;

float4 _LightColor0; // 必须要叫这个名字

struct a2v
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalDir : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
};

v2f vert(a2v v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normalDir = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    half4 albedo = tex2D(_MainTex, i.uv) * _Color;
    
    half3 normalDir = normalize(i.normalDir);
    half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
    half viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
    half3 halfDir = normalize(viewDir + lightDir);

#ifdef IS_ALPHATEST
    clip(albedo.a - _CutOff);
#endif
    
    // ambient
    // half3 ambient = ShadeSH9(half4(normalDir, 1.0f)); // 如果把1.0f改成0.0f，会变暗，如果改成比1更大的值，会更亮
    half3 ambient = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));

    // diffuse
    half nDotL = dot(normalDir, lightDir);
    half2 diffuseGradient = tex2D(_GradientMap, float2(nDotL * 0.5 + 0.5, 0.5)).rg;
    half3 diffuseAlbedo = lerp(albedo.rgb, tex2D(_ShadowColor1stTex, i.uv) * _ShadowColor1st.rgb, diffuseGradient.x);
    diffuseAlbedo = lerp(diffuseAlbedo, tex2D(_ShadowColor2ndTex, i.uv) * _ShadowColor2nd.rgb, diffuseGradient.y);
    half3 diffuse = diffuseAlbedo;

    // specular
    half nDotH = dot(normalDir, halfDir);
    nDotH = pow(max(nDotH, 1e-5), _SpecularPower);
    half specularGradient = tex2D(_GradientMap, float2(nDotH, 0.5)).b;
    half3 specular = specularGradient * albedo.rgb * _SpecularColor.rgb;

    // RimLight
    half nDotV = dot(normalDir, viewDir);
    half rimLightGradient = tex2D(_GradientMap, float2(pow(max(1.0 - clamp(nDotV, 0.0, 1.0), 1e-5), _RimLightPower), 0.5)).a;
    half rimLightMask = tex2D(_RimLightMask, i.uv);
    half3 rimLight = rimLightGradient * _RimLightColor.rgb * rimLightMask * diffuse;

    // Combine all
    half3 col = ambient * albedo + (diffuse + specular) * _LightColor0.rgb + rimLight;

#ifdef IS_TRANSPARENT
    return half4(col, albedo.a);
#else
    return half4(col, 1.0);
#endif
}

#endif
