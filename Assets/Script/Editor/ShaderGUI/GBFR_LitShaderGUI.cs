using System;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal.ShaderGUI;
using UnityEngine;

namespace IrelansTA.Rendering.Editor
{
    public class GBFR_LitGUI : LitShaderGUI
    {

        // collect properties from the material properties
        private MaterialProperty m_mixMap;
        private MaterialProperty m_rampMap;

        private MaterialProperty m_outlineColor;
        private MaterialProperty m_outlineSize;
        private MaterialProperty m_enableOutLine;
        private MaterialProperty m_outlineNoiseMap;
        private MaterialProperty m_outlineWidthFadeDistance;

        private MaterialProperty m_outlineNoiseContrast;

        private MaterialProperty m_outlineNoiseCutOff;

        private MaterialProperty m_outlineNoiseScale;




        private MaterialProperty m_rimlightPower;
        private MaterialProperty m_rimlightStrength;

        private MaterialProperty m_specularRampWidth;
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            m_outlineColor = FindProperty("_OutlineColor1", properties, false);
            m_outlineSize = FindProperty("_OutlineWidth", properties, false);
            m_enableOutLine = FindProperty("_EnableOutline", properties, false);
            m_outlineWidthFadeDistance = FindProperty("_OutlineWidthFadeDistance", properties, false);
            m_mixMap = FindProperty("_MixMap", properties, false);
            m_rampMap = FindProperty("_RampMap", properties, false);
            m_outlineNoiseMap = FindProperty("_OutlineNoiseMap", properties, false);

            m_rimlightPower = FindProperty("_RimlightPower", properties, false);
            m_rimlightStrength = FindProperty("_RimlightStrength", properties, false);
            m_specularRampWidth = FindProperty("_SpecularRampWidth", properties, false);
            m_outlineNoiseScale = FindProperty("_OutlineNoiseScale", properties, false);
            m_outlineNoiseCutOff = FindProperty("_OutlineNoiseCutOff", properties, false);
            m_outlineNoiseContrast = FindProperty("_OutlineNoiseContrast", properties, false);
        }

        // material changed check
        public override void ValidateMaterial(Material material)
        {
            base.ValidateMaterial(material);
            if (m_enableOutLine != null)
            {
                if (m_enableOutLine.floatValue == 1)
                {
                    material.EnableKeyword("_EnableOutline");
                }
                else
                {
                    material.DisableKeyword("_EnableOutline");
                }
            }
        }

        // material main surface options
        public override void DrawSurfaceOptions(Material material)
        {


            base.DrawSurfaceOptions(material);
        }

        // material main surface inputs
        public override void DrawSurfaceInputs(Material material)
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("RampMap"), m_rampMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("MixMap"), m_mixMap);
            base.DrawSurfaceInputs(material);

            // DrawTileOffset(materialEditor, baseMapProp);
        }

        // material main advanced options
        public override void DrawAdvancedOptions(Material material)
        {
            materialEditor.ShaderProperty(m_enableOutLine, "开启描边");

            if (material.HasProperty("_EnableOutline") && m_enableOutLine.floatValue == 1)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("NoiseMap"), m_outlineNoiseMap);

                materialEditor.ShaderProperty(m_enableOutLine, "EnableOutLine");
                materialEditor.ShaderProperty(m_outlineColor, "OutLineColor");
                materialEditor.ShaderProperty(m_outlineSize, "OutLineSize");
                materialEditor.ShaderProperty(m_outlineWidthFadeDistance, "OutLineWidthFadeDistance");
                materialEditor.ShaderProperty(m_outlineNoiseScale, "OutLineNoiseScale");
                materialEditor.ShaderProperty(m_outlineNoiseCutOff, "OutLineNoiseCutOff");
                materialEditor.ShaderProperty(m_outlineNoiseContrast, "OutLineNoiseContrast");
            }

            materialEditor.ShaderProperty(m_rimlightPower, "RimlightPower");
            materialEditor.ShaderProperty(m_rimlightStrength, "RimlightStrength");
            materialEditor.ShaderProperty(m_specularRampWidth, "SpecularRampWidth");
            base.DrawAdvancedOptions(material);
        }


    }
}
