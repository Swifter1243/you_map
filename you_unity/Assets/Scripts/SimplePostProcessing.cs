using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SimplePostProcessing : MonoBehaviour
{
    public Material postProcessingMaterial;

    public bool doPass = false;
    public uint pass = 0;
    private void OnRenderImage(RenderTexture src, RenderTexture dst) {
        Graphics.Blit(src, dst, postProcessingMaterial, doPass ? (int)pass : -1);
    }

    private void OnEnable() {
        Camera cam = GetComponent<Camera>();
        if (cam != null) {
            cam.depthTextureMode |= DepthTextureMode.Depth | DepthTextureMode.MotionVectors | DepthTextureMode.DepthNormals;
        }
    }
}