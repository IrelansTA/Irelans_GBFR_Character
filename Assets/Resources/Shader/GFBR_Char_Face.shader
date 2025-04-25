Shader "Irelans/GFBR_Char_Face"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Range(0,0.03)) = 0.01
        _OutlineWidthFadeDistance("Outline Width Fade Distance", Range(0.0, 100.0)) = 0.5
        [Toggle(_EnableOutline)]_EnableOutline("Enable Outline", Float) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

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
                float4 color : COLOR;
                float4 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS :TEXCOORD3;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };
            half4 _WorldSpaceLightPos0;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.uv = input.uv;
                output.color = input.color;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                //数据准备
                half3 normalWS = normalize(input.normalWS);
                half ndotl  = saturate(dot(normalWS, _WorldSpaceLightPos0.xyz));
                half3 V = GetWorldSpaceNormalizeViewDir(input.positionWS);
                V = normalize(float3(V.x,0,V.z));    //观察方向，这里忽略Y轴
                half3 F = normalize(TransformObjectToWorldNormal(float3(0,0,1)));//前方向
                half3 R = normalize(TransformObjectToWorldNormal(float3(1,0,0)));//右方向
                half VdotF =  pow(saturate(dot(V, F)),1);
                half NdotV = saturate(dot(normalWS, V));
                half VdotR = (dot(V, R));
                half mask_LR = VdotR<0?0:1;
                half VdotR_01 = ((dot(V, R))+1.0f)/2.0f;

                //遮罩图采样
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv);

                //鼻子边缘光
                half left_rim_nose = mask.g>0.005?mask.g:0; // 这里的三目运算是为了去除贴图里的杂志
                left_rim_nose = left_rim_nose*(1-VdotF)*mask_LR;
                half right_rim_nose = mask.a>0.005?mask.a:0;
                right_rim_nose =right_rim_nose*(1-VdotF)* (1-mask_LR);
                half nose_rim =  left_rim_nose + right_rim_nose;

                //脸颊边缘光
                half left_rim_face = mask.b>0.005?mask.b:0;
                left_rim_face = left_rim_face*(1-VdotF)*mask_LR;
                half right_rim_face = mask.r>0.005?mask.r:0;
                right_rim_face =right_rim_face*(1-VdotF)* (1-mask_LR);
                half face_rim = left_rim_face + right_rim_face;
                half final_rim = face_rim + nose_rim;
                
                
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                clip(baseColor.a - 0.5);//透贴

                return baseColor +final_rim*50;

                // return baseColor + mask*10;
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
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

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
                    
                    float3 front = (float3(0.0, 1.0, 0.00));
                    half3 V = GetWorldSpaceNormalizeViewDir(positionWS);
                    V = TransformWorldToObject(V);
                    half view_fade = saturate(dot(V, front));//角度补偿-侧面也能看到被顶点色隐藏的描边
                    half cameradistance = distance(GetCameraPositionWS(), positionWS);
                    half  camerafade = 1 - smoothstep(0, 1, 1 - (cameradistance - 0) / max(_OutlineWidthFadeDistance, 0.001));
                    half cameraScale = lerp(1, 10, camerafade);//远近补偿-描边粗细随着距离变化，这里写死了，可以根据需求调整
                    half outline_scale = lerp(input.color.x, input.color.x, view_fade) * cameraScale ;//合并两个补偿

                    
                    float3x3 tbn = float3x3(VertexNormalInputs.tangentWS, VertexNormalInputs.bitangentWS, VertexNormalInputs.normalWS);
                    positionWS += VertexNormalInputs.normalWS* _OutlineWidth * 0.1 *outline_scale;
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
