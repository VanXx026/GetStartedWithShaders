#ifndef TOON_OPAQUE_COMMON
#define TOON_OPAQUE_COMMON

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

half _AlphaCutoff;

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
    half4 albedo = tex2D(_MainTex, i.uv) * _Color;

    // ambient
    half3 ambient = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));

    // diffuse
    float nDotL = dot(i.worldNormalDir, i.worldLightDir) * 0.5 + 0.5;
    half2 diffGradient = tex2D(_GradientMap, float2(nDotL, 0.5)).rg;
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

#ifdef IS_ALPHA_TEST
    clip(albedo.a - _AlphaCutoff);
#endif

#ifdef IS_TRANSPARENT
    return half4(col.rgb, albedo.a);
#else
    return half4(col.rgb, 1.0);
#endif
}
#endif
