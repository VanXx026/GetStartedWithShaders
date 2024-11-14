Shader "Custom/ToonTransparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _GradientMap ("Gradient Map", 2D) = "white" {}
        
        // 1. 最基本的二分阴影方法
        // _ShadowThreshold ("Shadow Threshold", Range(-1.0, 1.0)) = 0.0
        // _ShadowColor ("Shadow Color", Color) = (0.6, 0.6, 0.6, 1.0)
        // 2. 通过贴图控制（罪恶装备做法）
        _ShadowColor1stTex ("1st Shadow Color Tex", 2D) = "white" {} // 指定第一层阴影的颜色
        _ShadowColor1st ("1st Shadow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShadowColor2ndTex ("2nd Shadow Color Tex", 2D) = "white" {} // 指定第二层阴影的颜色
        _ShadowColor2nd ("2nd Shadow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        // 1. 高光通过阈值控制 2. 改为使用GradientMap控制
        // _SpecularThreshold ("Specular ThreShold", Range(0.0, 1.0)) = 0.5
        _SpecularPower ("Specular Power", Range(0.0, 100.0)) = 1
        [HDR] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        _OutlineWidth ("Outline Width", Range(0.0, 3.0)) = 1.0
        _OutlineColor ("Outline Color", Color) = (0.2, 0.2, 0.2, 1.0)
        
        _CutOff ("Cut Off", Range(0.0, 1.0)) = 0.5
        
        _RimLightMask ("RimLight Mask", 2D) = "white" {}
        [HDR] _RimLightColor ("RimLight Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _RimLightPower ("RimLight Power", Float) = 20.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }

        Pass
        {
            ZWrite On
            ColorMask 0    
        }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"

            #define IS_TRANSPARENT
            #include "ToonShadingCommon.cginc"
            ENDCG
        }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"

            #define IS_TRANSPARENT
            #include "ToonOutlineCommon.cginc"
            ENDCG
        }
    }
}
