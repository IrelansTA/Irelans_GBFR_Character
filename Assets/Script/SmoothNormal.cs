using System.Collections;

using System.Collections.Generic;

using UnityEngine;

using UnityEditor;



public class SmoothNormals : MonoBehaviour

{



    private Renderer[] allRenderers;



    public struct NormalWeight {

        public Vector3 normal;

        public float weight;

    }



#if UNITY_EDITOR

    void OnValidate()

   {  

        void SmoothNormals(Mesh mesh)

        {

            Dictionary<Vector3, List<NormalWeight>> normalDict = new Dictionary<Vector3, List<NormalWeight>>();

            var triangles = mesh.triangles;

            var vertices = mesh.vertices;

            var normals = mesh.normals;

            var tangents = mesh.tangents;

            var smoothNormals = mesh.normals;



            for (int i = 0; i < triangles.Length - 3; i += 3)

            {

                int[] triangle = new int[] {triangles[i], triangles[i+1], triangles[i+2]};

                for (int j = 0; j < 3; j++)

                {

                    int vertexIndex = triangle[j];

                    Vector3 vertex = vertices[vertexIndex];

                    if (!normalDict.ContainsKey(vertex))

                    {

                        normalDict.Add(vertex, new List<NormalWeight>());

                    }



                    NormalWeight nw;

                    nw.normal = normals[vertexIndex];

                    Vector3 lineA = Vector3.zero;

                    Vector3 lineB = Vector3.zero;

                    if (j == 0)

                    {

                        lineA = vertices[triangle[1]] - vertex;

                        lineB = vertices[triangle[2]] - vertex;

                    }

                    else if (j == 1)

                    {

                        lineA = vertices[triangle[0]] - vertex;

                        lineB = vertices[triangle[2]] - vertex;

                    }

                    else

                    {

                        lineA = vertices[triangle[0]] - vertex;

                        lineB = vertices[triangle[1]] - vertex;

                    }

                    float angle = Mathf.Acos(Mathf.Max(Mathf.Min(Vector3.Dot(lineA, lineB)/(lineA.magnitude  * lineB.magnitude), 1), -1));

                    nw.weight = angle;

                    normalDict[vertex].Add(nw);

                }

            }



            for (int i = 0; i < vertices.Length; i++) {

                Vector3 vertex = vertices[i];

                List<NormalWeight> normalList = normalDict[vertex];



                Vector3 smoothNormal = Vector3.zero;

                float weightSum = 0;

                for (int j = 0; j < normalList.Count; j++)

                {

                    NormalWeight nw = normalList[j];

                    weightSum += nw.weight;

                }



               

                for (int j = 0; j < normalList.Count; j++)

                {

                    NormalWeight nw = normalList[j];

                    smoothNormal += nw.normal * nw.weight/weightSum;

                }

               



                smoothNormal = smoothNormal.normalized;

                smoothNormals[i] = smoothNormal;

               

                var normal = normals[i];

                var tangent = tangents[i];

                var binormal = (Vector3.Cross(normal, tangent) * tangent.w).normalized;

                var tbn = new Matrix4x4(tangent, binormal, normal, Vector3.zero);

                tbn = tbn.transpose;

                smoothNormals[i] = tbn.MultiplyVector(smoothNormals[i]).normalized;

            }

            mesh.SetUVs(7, smoothNormals);

        }



        foreach (var item in GetComponentsInChildren<MeshFilter>())

        {

            SmoothNormals(item.sharedMesh);

        }

        foreach (var item in GetComponentsInChildren<SkinnedMeshRenderer>())

        {

            SmoothNormals(item.sharedMesh);

        }

   }

#endif

}