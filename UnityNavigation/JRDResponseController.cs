// JRDResponseController.cs
// Handles mouse-based angle selection on a circular interface.

using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.EventSystems;

public class JRDResponseController : MonoBehaviour, IPointerClickHandler
{
    public RectTransform wheelTransform;        // 外圆（响应区域）
    public RectTransform innerMaskTransform;    // 内圆（遮挡区域）
    public RectTransform responseBar;           // 红色 bar，表示角度
    public RectTransform feedbackBar;           // 蓝色 bar，表示正确方向
    public TextMeshProUGUI centerText;          // 中间文本（“按空格键提交” 或 feedback）

    private float currentAngle = -1f;
    private bool submitted = false;

    public System.Action<float> onSubmit;        // 提交后的回调

    public float CurrentAngle => currentAngle;
    public bool Submitted => submitted;

    private float OuterRadiusLocal => wheelTransform.rect.width / 2f;
    private float InnerRadiusLocal => innerMaskTransform.rect.width / 2f;
    private float outerRadius => OuterRadiusLocal * wheelTransform.lossyScale.x;
    private float innerRadius => InnerRadiusLocal * innerMaskTransform.lossyScale.x;


    public void OnPointerClick(PointerEventData eventData)
    {
        Vector2 screenPos = eventData.position;
        Vector2 center = RectTransformUtility.WorldToScreenPoint(null, wheelTransform.position);
        Vector2 dir = screenPos - center;
        float distance = dir.magnitude;

        if (distance < innerRadius || distance > outerRadius)
            return; // 无效点击

        float angle = Mathf.Atan2(dir.x, dir.y) * Mathf.Rad2Deg;
        if (angle < 0f) angle += 360f;
        currentAngle = angle;

        UpdateResponseBar();
    }

    void SetBarPositionAndRotation(RectTransform bar, float angle)
    {
        float rad = angle * Mathf.Deg2Rad;
        float barRadius = (OuterRadiusLocal + InnerRadiusLocal) / 2f;

        // 计算位置
        float x = barRadius * Mathf.Sin(rad);
        float y = barRadius * Mathf.Cos(rad);
        bar.localPosition = new Vector2(x, y);

        // 旋转：bar 默认是朝上（0°），需要旋转到该角度
        bar.localRotation = Quaternion.Euler(0f, 0f, -angle);
    }

    void UpdateResponseBar()
    {
        responseBar.gameObject.SetActive(true);
        SetBarPositionAndRotation(responseBar, currentAngle);
    }

    // 开始判断的指导语
    public void ResetResponse(string promptText = "请开始判断")
    {
        currentAngle = -1f;
        submitted = false;
        responseBar.gameObject.SetActive(false);
        feedbackBar.gameObject.SetActive(false);
        centerText.text = $"{promptText}\n按空格键提交";
    }

    public void Submit(float correctAngle)
    {
        if (currentAngle < 0f) return;

        submitted = true;

        // 显示反馈
        feedbackBar.gameObject.SetActive(true);
        SetBarPositionAndRotation(feedbackBar, correctAngle);

        float delta = - Mathf.DeltaAngle(currentAngle, correctAngle);
        centerText.text = $"Difference: {delta:F2} °";

        // 回调
        onSubmit?.Invoke(currentAngle);
    }
}