#ifndef TOON_OUTLINE_COMMON
#define TOON_OUTLINE_COMMON
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
#endif
