using UnityEngine;
using UnityEngine.AI;
using UnityEngine.UI;

public class PlayerController : MonoBehaviour
{
    public float speed = 10f;
    public float mouseSensitivity = 1.5f;
    public Transform cameraTransform;
    public bool canMove = true;  // 默认允许移动
    public bool canLook = true;  // 默认允许鼠标转头

    public CharacterController controller;
    public float yaw = 0f;  // 水平角度

    public RectTransform minimapPanel;
    public RectTransform minimapArrow;
    public Vector2 worldSize = new Vector2(200, 200);

    // 平衡正北方向
    public void SetInitialYaw(float newYaw)
    {
        yaw = newYaw;
        transform.eulerAngles = new Vector3(0f, yaw, 0f);
    }

    void Start()
    {
        controller = GetComponent<CharacterController>();
        Cursor.lockState = CursorLockMode.Locked;  // 锁定鼠标光标
    }

    void Update()
    {
        // ---- 1. 鼠标转头 ----
        if (canLook)
        {
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
            yaw += mouseX;
            transform.eulerAngles = new Vector3(0f, yaw, 0f);
        }

        // ---- 2. 仅在允许移动时执行位移检查与移动 ----
        if (canMove)
        {
            float moveX = Input.GetAxis("Horizontal");
            float moveZ = Input.GetAxis("Vertical");
            Vector3 move = transform.right * moveX + transform.forward * moveZ;
            Vector3 intendedMove = move * speed * Time.deltaTime;
            Vector3 nextPosition = transform.position + intendedMove;

            // 检查是否在 NavMesh 上
            NavMeshHit hit;
            Vector3 flatSamplePos = new Vector3(nextPosition.x, 0, nextPosition.z);
            bool onNavMesh = NavMesh.SamplePosition(flatSamplePos, out hit, 0.2f, NavMesh.AllAreas);

            if (onNavMesh)
            {
                controller.Move(intendedMove);
            }
        }

        // ---- 3. MiniMap 玩家箭头更新 ----
        UpdateMiniMapArrow();
    }

    void UpdateMiniMapArrow()
    {
        Vector3 pos = transform.position;

        // 归一化世界坐标 → [0, 1]
        float normX = (pos.x + worldSize.x / 2f) / worldSize.x;
        float normY = (pos.z + worldSize.y / 2f) / worldSize.y;

        // UI 面板尺寸
        float panelW = minimapPanel.rect.width;
        float panelH = minimapPanel.rect.height;

        // 直接映射，无需翻转 Y
        float uiX = normX * panelW;
        float uiY = (1f - normY) * panelH;

        // 
        minimapArrow.anchoredPosition = new Vector2(uiX, -uiY); // Y轴反向映射为负号

        float angle = transform.eulerAngles.y;
        minimapArrow.localRotation = Quaternion.Euler(0, 0, -angle);
    }
    
}