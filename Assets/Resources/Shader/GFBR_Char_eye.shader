Shader "Irelans/GFBR_Char_eye"
{
    Properties
    {
        _pupil ("_pupil", 2D) = "white" { }
        _conj ("_conj", 2D) = "white" { }
        _highlight ("_highlight", 2D) = "white" { }
        _heightMap ("_heightMap", 2D) = "white" { }
        _highLightOffset ("_highLightOffset", Vector) = (0, 0, 0, 0)

        _ScaledByCenter ("_ScaledByCenter", Range(0, 1)) = 1.0
        _IrisDepthScale ("_IrisDepthScale", Range(0, 0.5)) = 1.0

        _uCenterBias ("_uCenterBias", Range(-1, 1)) = 0.0
        _vCenterBias ("_vCenterBias", Range(-1, 1)) = 0.0

        _irisOffset ("_irisOffset", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100
        

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

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
                float4 tangentOS : TANGENT;
            };
            

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
                float3 positionWS : TEXCOORD6;
            };

            cbuffer PerCameraCB
            {
                half4 _highLightOffset;
                half4 _irisOffset;
                half _ScaledByCenter;
                half _IrisDepthScale;
                half _uCenterBias;
                half _vCenterBias;
            };

            TEXTURE2D(_pupil);
            SAMPLER(sampler_pupil);

            TEXTURE2D(_conj);
            SAMPLER(sampler_conj);

            TEXTURE2D(_highlight);
            SAMPLER(sampler_highlight);

            TEXTURE2D(_heightMap);
            SAMPLER(sampler_heightMap);


            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;
                output.color = input.color;
                //Normal
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;;
                output.bitangentWS = normalInputs.bitangentWS;
                //Position
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS).xyz;
                //ViewDir
                output.viewDir = normalize(_WorldSpaceCameraPos - output.positionWS);
                return output;
            }

            float2 BumpOffset(float3 V, float heightRatioInput, float height, float refPlaneHeight, float2 uv, float3x3 tbn)
            {
                
                float3 Local0 = TransformWorldToTangent(V, tbn);
                float2 Local1 = (Local0.rg * ((heightRatioInput * height) + (-1 * refPlaneHeight * heightRatioInput)));
                float2 Local2 = (Local1 + uv);
                return Local2;
            }

            half2 ScaleUVsByCenter(half2 UVs, half u_center_bias, half v_center_bias, float Scale)
            {
                half2 center_bias = half2(0.5 + u_center_bias, 0.5 + v_center_bias);
                return (UVs / Scale + center_bias) - (center_bias / Scale);
            }


            half2 ParallaxMapping(float3 viewDir, half2 uv, half height, half heightScale)
            {
                half2 p = viewDir.xy * (height * heightScale);
                return uv - p;
            }
            half remap(half value, half oldMin, half oldMax, half newMin, half newMax)
            {
                return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
            }
            half4 frag(Varyings input) : SV_Target
            {
                
                // half height = SAMPLE_TEXTURE2D(_heightMap, sampler_heightMap, input.uv);
                //获得观察向量
                half3 viewRay = normalize(input.viewDir);

                

                

                //IrisDepth
                half ScaledByCenter = _ScaledByCenter;
                half IrisDepthScale = _IrisDepthScale;
                half uCenterBias = _uCenterBias;
                half vCenterBias = _vCenterBias;
                half2 scaleUV = half2(ScaledByCenter * 0.5 + 0.5, 0.5);

                half4 height_scaled = SAMPLE_TEXTURE2D(_heightMap, sampler_heightMap, scaleUV);
                half4 height = SAMPLE_TEXTURE2D(_heightMap, sampler_heightMap, input.uv);
                half IrisDepth = max(height - height_scaled, 0) * IrisDepthScale;
                

                //视差UV
                half3x3 tbn = half3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                half3 viewRayTS = TransformWorldToTangentDir(viewRay, tbn, true);
                half2 irisUV = ParallaxMapping(viewRayTS, input.uv, height.x, IrisDepth);
                irisUV = ScaleUVsByCenter(irisUV, uCenterBias, vCenterBias, ScaledByCenter);
                irisUV = irisUV + _irisOffset.xy;

                //贴图采样
                //瞳孔
                half4 pupil = SAMPLE_TEXTURE2D(_pupil, sampler_pupil, irisUV);
                pupil*= pupil.a;
                //眼白
                half4 conj = SAMPLE_TEXTURE2D(_conj, sampler_conj, input.uv) * (1 - pupil.a);
                //高光
                half2 hightlightUV = _highLightOffset.xy + input.uv + _irisOffset.xy;
                half4 highlight = SAMPLE_TEXTURE2D(_highlight, sampler_highlight, hightlightUV);//高光
                highlight *= highlight.a;

                half4 finalColor = conj + pupil + highlight;
                // half4 vertexColor = input.color;
                return finalColor;
            }
            ENDHLSL
        }
    }
}
