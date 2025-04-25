Shader "Irelans/GFBR_Char_Body"
{
    Properties
    {
        
        _RampMap ("Ramp Map", 2D) = "white" { }
        _SpecularRampWidth ("Specular Ramp Width", Range(0, 1)) = 0.5
        _OutlineNoiseMap ("Outline Noise Map", 2D) = "white" { }
        _OutlineNoiseContrast ("Outline Noise Contrast", Range(0, 1)) = 0.5
        _OutlineNoiseCutOff ("Outline Noise Cutoff", Range(0, 1)) = 0.5
        _OutlineNoiseScale ("Outline Noise Scale", float) =1 

        _MixMap ("Mask Texture", 2D) = "white" { }
        _OutlineColor1 ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Range(0, 0.03)) = 0.01
        _OutlineWidthFadeDistance ("Outline Width Fade Distance", Range(0.0, 1.0)) = 0.5

        _RimlightPower ("Rimlight Power", float) = 1
        _RimlightStrength ("Rimlight Intencity", float) = 1
        [Toggle]_EnableOutline ("Enable Outline", Float) = 0

        // Specular vs Metallic workflow
        _WorkflowMode ("WorkflowMode", Float) = 1.0

        [MainTexture] _BaseMap ("Albedo", 2D) = "white" { }
        [MainColor] _BaseColor ("Color", Color) = (1, 1, 1, 1)
        
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0
        
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap ("Metallic", 2D) = "white" { }
        
        _SpecColor ("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecGlossMap ("Specular", 2D) = "white" { }
        
        [ToggleOff] _SpecularHighlights ("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections ("Environment Reflections", Float) = 1.0
        
        _BumpScale ("Scale", Float) = 1.0
        _BumpMap ("Normal Map", 2D) = "bump" { }
        
        _Parallax ("Scale", Range(0.005, 0.08)) = 0.005
        _ParallaxMap ("Height Map", 2D) = "black" { }
        
        _OcclusionStrength ("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap ("Occlusion", 2D) = "white" { }
        
        [HDR] _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" { }
        
        _DetailMask ("Detail Mask", 2D) = "white" { }
        _DetailAlbedoMapScale ("Scale", Range(0.0, 2.0)) = 1.0
        _DetailAlbedoMap ("Detail Albedo x2", 2D) = "linearGrey" { }
        _DetailNormalMapScale ("Scale", Range(0.0, 2.0)) = 1.0
        [Normal] _DetailNormalMap ("Normal Map", 2D) = "bump" { }
        
        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector] _ClearCoatMask ("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness ("_ClearCoatSmoothness", Float) = 0.0
        
        // Blending state
        _Surface ("__surface", Float) = 0.0
        _Blend ("__blend", Float) = 0.0
        _Cull ("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip ("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha ("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha ("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _BlendModePreserveSpecular ("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask ("__alphaToMask", Float) = 0.0
        
        [ToggleUI] _ReceiveShadows ("Receive Shadows", Float) = 1.0
        // Editmode props
        _QueueOffset ("Queue offset", Float) = 0.0
        
        // ObsoleteProperties
        [HideInInspector] _MainTex ("BaseMap", 2D) = "white" { }
        [HideInInspector] _Color ("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale ("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness ("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections ("EnvironmentReflections", Float) = 0.0
        
        [HideInInspector][NoScaleOffset]unity_Lightmaps ("unity_Lightmaps", 2DArray) = "" { }
        [HideInInspector][NoScaleOffset]unity_LightmapsInd ("unity_LightmapsInd", 2DArray) = "" { }
        [HideInInspector][NoScaleOffset]unity_ShadowMasks ("unity_ShadowMasks", 2DArray) = "" { }
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // -------------------------------------
            // Render State Commands
            Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Resources/Shader/Library/CharacterLitInput.hlsl"
            #include "Assets/Resources/Shader/Library/CharacterLitForward.hlsl"
            ENDHLSL
        }

        Pass // 外描边颜色 Pass

        {
            Tags { "RenderType" = "Opaque" "LightMode" = "SRPDefaultUnlit" }
            Cull Front
            ZWrite On
            // ZTest Always
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _EnableOutline
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Assets/Resources/Shader/Library/CharacterLitInput.hlsl"

            


            
            

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv0 : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 color : COLOR;
                float3 smoothNormal : TEXCOORD7;
            };

            struct VertexOutput
            {
                float2 uv0 : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float3 smoothNormal : TEXCOORD3;
                float3 normalOS:TEXCOORD4;
                float4 positionOS:TEXCOORD5;
            };
            // 根据法线的 三个轴  ， 生成遮罩
            float3 NormalMask(float3 wNormal)
            {
                float3 tempNormal = pow(abs(wNormal), 2);
                float3 mask = tempNormal / (tempNormal.x + tempNormal.y + tempNormal.z);
                return mask;
            }
            float4 TriPlanar(float3 maskValue, float3 worldPos, float3 worldPivot, Texture2D Tex, SamplerState Sampler, float tiling)
            {
                float3 tempPos = ((worldPos - worldPivot) * tiling).xyz;
                //  xy 平面的像素正常显示 但是  其他轴对应平面的值不正确，所以 乘以 maskValue.z，屏蔽掉其它轴面的值。
                float4 colorZ = SAMPLE_TEXTURE2D(Tex, Sampler, tempPos.xy) * maskValue.z;
                float4 colorY = SAMPLE_TEXTURE2D(Tex, Sampler, tempPos.xz) * maskValue.y;
                float4 colorX = SAMPLE_TEXTURE2D(Tex, Sampler, tempPos.yz) * maskValue.x;
                //  三个轴面的正确结果相加  ，  归一化
                return normalize(colorX + colorY + colorZ);
            }
 
            half CheapContrast(float x, float contrast)
            {
                contrast = lerp((0 - contrast), (1 + contrast), x);
                return saturate(contrast);
            }
            VertexOutput vert(appdata input)
            {
                VertexOutput output = (VertexOutput)0;
                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs VertexNormalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3 positionWS = vertexPositionInput.positionWS;
                
                #if _EnableOutline
                    // CameraFade
                    float3 front = (float3(0.0, 1.0, 0.00));
                    half3 V = GetWorldSpaceNormalizeViewDir(positionWS);
                    V = TransformWorldToObject(V);
                    half view_fade = saturate(dot(V, front));

                    half cameradistance = distance(GetCameraPositionWS(), positionWS);

                    half camerafade = 1 - smoothstep(0, 1, 1 - (cameradistance - 0) / max(_OutlineWidthFadeDistance, 0.001));
                    
                    half cameraScale = lerp(1, 3, camerafade);
                    


                    half outline_scale = lerp(1, input.color.x, view_fade) * 1 ;
                    // half outline_scale =input.color.a * cameraScale ;

                    
                    float3x3 tbn = float3x3(VertexNormalInputs.tangentWS, VertexNormalInputs.bitangentWS, VertexNormalInputs.normalWS);
                    positionWS += VertexNormalInputs.normalWS * _OutlineWidth * 0.1 * input.color.x;
                #endif

                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = VertexNormalInputs.normalWS;
                output.positionWS = positionWS;
                output.smoothNormal = input.smoothNormal;
                output.uv0 = input.uv0;
                output.normalOS = input.normalOS;
                output.positionOS = input.positionOS;
                return output;
            }

            half4 frag(VertexOutput input) : SV_Target
            {
                // 采样 _ShadowRampMap 的逻辑
                // float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);

                // float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv0);
                // float RampSampler = lightMap.a * 256;

                half3 OutlineColor;
                
                OutlineColor = _OutlineColor1;


                //模型空间三面投UV采样noise
                float3 maskValue = NormalMask(input.normalOS);

                half3 worldPivot = float3(0, 0, 0);
                half3 worldPos = input.positionWS;
                worldPos = input.positionOS;
                float outlineNoise = TriPlanar(maskValue, worldPos, worldPivot, _OutlineNoiseMap, sampler_OutlineNoiseMap, _OutlineNoiseScale).x;
                clip(outlineNoise - _OutlineNoiseCutOff);

                
                // return float4(OutlineColor,1);
                //纠正调色
                half4 finalColor = float4(OutlineColor, 1);
                
                
                // 返回采样结果
                return finalColor;
            }

            ENDHLSL
        }
    }
    CustomEditor "IrelansTA.Rendering.Editor.GBFR_LitGUI"
}
