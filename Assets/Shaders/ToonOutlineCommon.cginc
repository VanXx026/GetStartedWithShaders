#ifndef TOON_OUTLINE_COMMON
#define TOON_OUTLINE_COMMON

sampler2D _MainTex;
float4 _MainTex_ST;
half4 _Color;
float _CutOff;

float _OutlineWidth;
half4 _OutlineColor;

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
};

v2f vert(a2v v)
{
    v2f o;

    float3 viewPos = UnityObjectToViewPos(v.vertex);
    float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
    viewNormal.z = -0.5; // Van_Confuse
    viewPos = viewPos + normalize(viewNormal) * _OutlineWidth * 0.002;
    o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1.0));
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    half4 albedo = tex2D(_MainTex, i.uv) * _Color;

#ifdef IS_ALPHATEST
    clip(albedo.a - _CutOff);
#endif
    
    half3 col = albedo * _OutlineColor.rgb;

#ifdef IS_TRANSPARENT
    return half4(col, albedo.a);
#else
    return half4(col, 1.0);
#endif
}

#endif