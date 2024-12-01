Shader "Custom/ToonShaderAlphaTest"
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
        
        _AlphaCutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        
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

            #define IS_ALPHA_TEST
            #include "UnityCG.cginc"
            #include "ToonOpaqueCommon.cginc"
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

            #define IS_ALPHA_TEST
            #include "UnityCG.cginc"
            #include "ToonOutlineCommon.cginc"
            ENDCG
        }
    }
}
