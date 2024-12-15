using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SimplePostProcessing : MonoBehaviour
{
    [SerializeField]
    public Material postProcessingMaterial;
    private void OnRenderImage(RenderTexture src, RenderTexture dst) {
        Graphics.Blit(src, dst, postProcessingMaterial);
    }

    private void OnEnable() {
        Camera cam = GetComponent<Camera>();
        if (cam != null) {
            cam.depthTextureMode |= DepthTextureMode.Depth | DepthTextureMode.MotionVectors | DepthTextureMode.DepthNormals;
        }
    }
}