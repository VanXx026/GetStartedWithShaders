Shader "Custom/Animation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
        
        _ColorGradientMap ("Color Grandient Map", 2D) = "white" {}
        _ColorGradientTiling ("Color Gradient Tiling", Float) = 1.0
        _ColorGradientSpeed ("Color Gradient Speed", Float) = 1.0
        
        _AlphaGradientMap ("Alpha Gradient Map", 2D) = "white" {}
        _AlphaGradientTiling ("Alpha Gradient Tiling", Float) = 1.0
        _AlphaGradientSpeed ("Alpha Gradient Speed", Float) = 1.0
        
        _GridSize ("Grid Size", Range(0.0, 1.0)) = 0.1
        _SpotSize ("Spot Size", Range(0.0, 0.5)) = 0.2
    }
    SubShader
    {
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        
        Pass
        {
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            sampler2D _ColorGradientMap;
            float _ColorGradientTiling;
            float _ColorGradientSpeed;

            sampler2D _AlphaGradientMap;
            float _AlphaGradientTiling;
            float _AlphaGradientSpeed;

            float _GridSize;
            float _SpotSize;
            
            struct a2v
            {
                float3 vertex : POSITION;
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
                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float4 albedo = tex2D(_MainTex, i.uv) * _Color;
                float3 color = albedo.rgb;
                float alpha = albedo.a;

                float disToCenter = length(i.uv - 0.5);
                
                // Color Gradient
                float colorSample = disToCenter * _ColorGradientTiling + _Time.y * _ColorGradientSpeed;
                float4 colorGradient = tex2D(_ColorGradientMap, float2(colorSample, 0.5));
                color *= colorGradient.rgb;

                // Alpha Gradient
                float alphaSample = disToCenter * _AlphaGradientTiling + _Time.y * _AlphaGradientSpeed;
                float alphaGradient = tex2D(_AlphaGradientMap, float2(alphaSample, 0.5));
                alpha *= alphaGradient;

                // spot
                float2 gridPos = fmod(i.uv, _GridSize) / _GridSize;
                float disToGridCenter = length(gridPos - 0.5);
                alpha *= step(disToGridCenter, _SpotSize);

                return half4(color, alpha);
            }
            
            ENDCG
        }

    }
}
