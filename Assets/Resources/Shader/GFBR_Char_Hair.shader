Shader "Unlit/GFBR_Char_hair"
{
    Properties
    {
        _hairMap ("_hairMap", 2D) = "white" { }
        _hairMask ("_hairMask", 2D) = "white" { }

        _anisoBias ("Aniso Bias", Range(-1, 1)) = 0.5
        _anisoNoiseIntensity ("Aniso Noise Intensity", Range(0, 1)) = 0.5
        
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Range(0, 0.03)) = 0.01
        _OutlineWidthFadeDistance ("Outline Width Fade Distance", Range(0.0, 1.0)) = 0.5
        _SpecularIntencity ("Specular Intencity", Range(0, 10)) = 0.5
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        [Toggle(_EnableOutline)]_EnableOutline ("Enable Outline", Float) = 0


        _DiffuseRampPower ("Diffuse Ramp Power", Range(0, 10)) = 1
        _RimPower ("Rim Power", Range(0, 100)) = 3
        _RimStrength ("Rim Strength", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangentOS : TANGENT;
                float4 normalOS : NORMAL;
            };

            uniform float4 _WorldSpaceLightPos0;
            half4 _SpecularColor;

            half _SpecularIntencity;
            half _anisoBias;
            half _anisoNoiseIntensity;
            half _RimPower;
            half _RimStrength;
            half _DiffuseRampPower;

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangentWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };

            TEXTURE2D(_hairMap);  SAMPLER(sampler_hairMap);
            TEXTURE2D(_hairMask);  SAMPLER(sampler_hairMask);


            

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS).xyz;
                output.uv = input.uv;
                

                VertexNormalInputs vertexnormal = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = vertexnormal.normalWS;
                output.tangentWS = vertexnormal.tangentWS;


                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                //数据准备
                half4 baseColor = SAMPLE_TEXTURE2D(_hairMap, sampler_hairMap, input.uv);
                half3 normalWS = normalize(input.normalWS);
                half3 tangentWS = normalize(input.tangentWS);
                half3 lightDirWS = normalize(_WorldSpaceLightPos0.xyz);
                half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                half3 HDirWS = normalize(lightDirWS + viewDirWS);

                //资源采样
                half4 mask = SAMPLE_TEXTURE2D(_hairMask, sampler_hairMask, input.uv);//采样mask
                half anisoNoise = ((mask.x * 2) - 1) * _anisoNoiseIntensity;//偏移方向映射到-1到1之间
                half ao = mask.z;
                half3 T_shift = normalize(normalWS * (anisoNoise + _anisoBias) + tangentWS);//切线方向的偏移
                half TdotH = (dot(T_shift, HDirWS));
                half NdotL_Raw = saturate(dot(normalWS, lightDirWS));
                half halflambert = max((dot(normalWS, lightDirWS) * 0.5) + 0.5, 0.5);
                //kajiya-kay高光模型
                half4 specular = pow(sqrt((1 - TdotH * TdotH)),40)*baseColor*NdotL_Raw *_SpecularIntencity*_SpecularColor;
                // return specular;

                //漫反射
                half diffuseRamp = pow(mask.y, _DiffuseRampPower);
                half4 diffuse = baseColor *diffuseRamp  * ao;
                // return diffuse ;

                
                half4 finalColor = diffuse + specular;

                //rimlight，边缘光，可加可不加，官方没加，自己尝试了下
                half ndotl = saturate(dot(normalWS, viewDirWS));
                ndotl = saturate(pow(ndotl, _RimPower));
                half3 rimColor = ndotl * baseColor * _RimStrength;
                // return float4(rimColor,1);

                // finalColor.rgb += rimColor;

                
                return finalColor;
            }
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

            half _OutlineWidthFadeDistance;
            half _OutlineWidth;
            half4 _OutlineColor;



            

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
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float4 positionCS : SV_POSITION;
                float3 smoothNormal : TEXCOORD7;
            };

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
                    half outline_scale = lerp(1, input.color.a, view_fade) * 1 ;
                    // half outline_scale =input.color.a * cameraScale ;

                    
                    float3x3 tbn = float3x3(VertexNormalInputs.tangentWS, VertexNormalInputs.bitangentWS, VertexNormalInputs.normalWS);
                    positionWS += VertexNormalInputs.normalWS * _OutlineWidth * 0.1 * outline_scale;
                #endif

                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = VertexNormalInputs.normalWS;
                output.positionWS = positionWS;
                output.smoothNormal = input.smoothNormal;
                output.uv0 = input.uv0;
                return output;
            }

            half4 frag(VertexOutput input) : SV_Target
            {


                half3 OutlineColor;
                
                OutlineColor = _OutlineColor;


                

                half4 finalColor = float4(OutlineColor, 1);
                
                
                // 返回采样结果
                return finalColor;
            }

            ENDHLSL
        }
    }
}
