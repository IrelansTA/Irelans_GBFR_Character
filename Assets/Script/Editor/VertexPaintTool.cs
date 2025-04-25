using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public class VertexPaintTool : EditorWindow
{
    [MenuItem("TA工具/顶点色笔刷")]
    static void Init() => GetWindow<VertexPaintTool>("顶点色笔刷");

    private Color brushColor = Color.red;
    private float brushSize = 0.1f;
    private float brushStrength = 1.0f;
    private SkinnedMeshRenderer targetRenderer;
    private Mesh modifiedMesh;

    MeshCollider meshCollider;

    public Mesh rawMesh;
    private bool initialized;
    void initialize()
    {
        Debug.Log("initialize");
        //保留原始网格
        if (targetRenderer != null && rawMesh == null)
        {

            rawMesh = Instantiate(targetRenderer.sharedMesh);
        }
        //创建Collider
        if (targetRenderer != null && targetRenderer.GetComponent<MeshCollider>() == null)
        {
            meshCollider = targetRenderer.gameObject.AddComponent<MeshCollider>();
            meshCollider.sharedMesh = targetRenderer.sharedMesh;
        }
        modifiedMesh = targetRenderer.sharedMesh;


    }
    void OnGUI()
    {
        if (!initialized && targetRenderer != null)
        {
            initialized = true;
            initialize();
        }
        GUILayout.Label("刷顶点色工具", EditorStyles.boldLabel);
        brushColor = EditorGUILayout.ColorField("笔刷颜色", brushColor);
        brushSize = EditorGUILayout.Slider("笔刷尺寸", brushSize, 0.001f, 0.1f);
        brushStrength = EditorGUILayout.Slider("笔刷力度", brushStrength, 0f, 1f);
        if (GUILayout.Button("填充白色"))
        {
            if (targetRenderer != null)
            {
                Mesh mesh = targetRenderer.sharedMesh;
                Color[] colors = new Color[mesh.vertexCount];
                for (int i = 0; i < colors.Length; i++)
                {
                    colors[i] = Color.white;
                }
                mesh.colors = colors;
                SaveMeshChanges();
            }
        }
        if (GUILayout.Button("填充黑色"))
        {
            if (targetRenderer != null)
            {
                Mesh mesh = targetRenderer.sharedMesh;
                Color[] colors = new Color[mesh.vertexCount];
                for (int i = 0; i < colors.Length; i++)
                {
                    colors[i] = Color.black;
                }
                mesh.colors = colors;
                SaveMeshChanges();
            }
        }
        if (GUILayout.Button("重置顶点色"))
        {

            if (targetRenderer != null && rawMesh != null)
            {
                targetRenderer.sharedMesh.colors = rawMesh.colors;
                SaveMeshChanges();
            }
            else
            {
                Debug.LogWarning("No mesh to reset");
            }


        }


        EditorGUILayout.Space();
        targetRenderer = EditorGUILayout.ObjectField(
            "目标Mesh",
            targetRenderer,
            typeof(SkinnedMeshRenderer),
            true) as SkinnedMeshRenderer;

        EditorGUILayout.Space(59);

        GUI.backgroundColor = Color.yellow; // 设置按钮颜色为绿色
        if (GUILayout.Button("保存Mesh"))
        {
            OutputNewMesh();
        }
        GUI.backgroundColor = Color.white; 
        GUI.backgroundColor = Color.green; // 设置按钮颜色为绿色
        if (GUILayout.Button("保存Prefab"))
        {
            ReplacePrefabMesh();
        }
        GUI.backgroundColor = Color.white; // 恢复默认按钮颜色

    }
    private void PaintVertices(RaycastHit hit)
    {
        // // 确保使用独立网格实例
        // if (modifiedMesh == null || modifiedMesh != targetRenderer.sharedMesh)
        // {
        //     modifiedMesh = Instantiate(targetRenderer.sharedMesh);
        //     targetRenderer.sharedMesh = modifiedMesh;
        // }
        modifiedMesh = targetRenderer.sharedMesh;
        Vector3[] vertices = modifiedMesh.vertices;
        Color[] colors = modifiedMesh.colors.Length == vertices.Length ?
            modifiedMesh.colors :
            new Color[vertices.Length];

        Matrix4x4 localToWorld = targetRenderer.transform.localToWorldMatrix;
        Matrix4x4 worldToLocal = targetRenderer.transform.worldToLocalMatrix;

        // 转换碰撞点到模型空间
        Vector3 localHitPoint = worldToLocal.MultiplyPoint3x4(hit.point);

        for (int i = 0; i < vertices.Length; i++)
        {
            Vector3 vertexPos = localToWorld.MultiplyPoint3x4(vertices[i]);
            float distance = Vector3.Distance(vertexPos, hit.point);

            if (distance < brushSize)
            {
                float falloff = 1 - Mathf.Clamp01(distance / brushSize);
                colors[i] = Color.Lerp(
                    colors[i],
                    brushColor,
                    falloff * brushStrength * 0.1f);
            }
        }

        modifiedMesh.colors = colors;
    }
    private void SaveMeshChanges()
    {
        if (modifiedMesh != null)
        {
            // 创建一个新的.asset文件来保存修改后的网格
            string path = AssetDatabase.GetAssetPath(targetRenderer.sharedMesh);

            // 如果.asset文件不存在，则创建
            // if (!AssetDatabase.Contains(modifiedMesh))




            // 更新MeshFilter的mesh引用为新保存的.asset文件
            // targetRenderer.sharedMesh = newMesh;

            // 标记为脏数据并保存
            EditorUtility.SetDirty(modifiedMesh);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("Saved mesh changes to .asset file.");
        }
        else
        {
            Debug.LogWarning("No modified mesh to save.");
        }
    }
    private void OutputNewMesh()
    {
        if (modifiedMesh != null)
        {
            string path = AssetDatabase.GetAssetPath(targetRenderer.sharedMesh);
            string newPath = System.IO.Path.ChangeExtension(path, null) + "_Modified.asset";
            //如果path包含_Modified.asset
            if (path.Contains("_Modified.asset"))
            {
                Debug.Log("已存在文件,直接覆盖");
                newPath = path;

            }

            if (!AssetDatabase.LoadAssetAtPath<Mesh>(newPath))
            {
                Debug.Log($"存储新文件: {newPath}");
                AssetDatabase.CreateAsset(Instantiate(modifiedMesh), newPath);
            }
            var newMesh = AssetDatabase.LoadAssetAtPath<Mesh>(newPath);
            targetRenderer.sharedMesh = newMesh;
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            //获得prefab Instance



        }
    }
    private void ReplacePrefabMesh()
    {
        if (modifiedMesh != null)
        {

            GameObject prefab = PrefabUtility.GetNearestPrefabInstanceRoot(targetRenderer.gameObject);
            Debug.Log("prefab路径: " + prefab);
            if (prefab != null)
            {

                var objectOverrides = PrefabUtility.GetObjectOverrides(prefab);
                Debug.Log("override个数" + objectOverrides.Count);
                foreach (var objectOverride in objectOverrides)
                {

                    string assetPath = PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(objectOverride.instanceObject);
                    Debug.Log("Prefab路径: " + assetPath);

                    PrefabUtility.ApplyObjectOverride(objectOverride.instanceObject, assetPath, InteractionMode.UserAction);
                    Debug.Log("Prefab已覆盖");

                }
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                Debug.Log("Prefab已更新");
            }
            else
            {
                Debug.LogError("没找到prefab");
            }
        }
    }
    private void OnSceneGUI(SceneView sceneView)
    {
        if (targetRenderer == null) return;

        HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
        Event e = Event.current;

        // 获取鼠标位置
        Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
        if (!Physics.Raycast(ray, out RaycastHit hit)) return;


        //如果键盘按了alt
        if (e.alt)
        {
            return;
        }
        if (e.type == EventType.MouseDown && e.button == 0)
        {
            PaintVertices(hit);
            e.Use();
        }
        else if (e.type == EventType.MouseDrag && e.button == 0)
        {
            PaintVertices(hit);
            e.Use();
        }
        else if (e.type == EventType.MouseUp && e.button == 0)
        {

            SaveMeshChanges();
            e.Use();
        }

        // 绘制笔刷指示器
        Handles.color = new Color(brushColor.r, brushColor.g, brushColor.b, 0.2f);
        Handles.DrawSolidDisc(hit.point, hit.normal, brushSize);
        Handles.color = Color.white;
    }
    void OnEnable()
    {
        SceneView.duringSceneGui += OnSceneGUI;


    }
    // void OnEnable() => SceneView.duringSceneGui += OnSceneGUI;
    void OnDisable()
    {
        SceneView.duringSceneGui -= OnSceneGUI;
        //remove the mesh collider
        if (targetRenderer != null)
        {
            MeshCollider meshCollider = targetRenderer.GetComponent<MeshCollider>();
            if (meshCollider != null)
            {
                DestroyImmediate(meshCollider);
            }
        }



    }
}