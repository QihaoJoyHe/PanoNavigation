// ExpController, for spatial learning phase in Unity3D.
// Guided exploration, 6rounds of navigation, 9 targets each.
// horizontal FOV = 60, vDist = 60cm
//
// By Qihao He, June 2025

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Linq;

public class ExpController : MonoBehaviour
{
    // 路口信息结构
    [System.Serializable]
    public class IntersectionInfo
    {
        public string name;
        public Vector2 position;   // x,z 坐标
        public int blockID;        // Block0, Block22.5, Block45
        public int index;          // 唯一编号，用于被试内识别和配对
        public Sprite iconSprite;  // 图形图标 (被试内固定，外部打乱)
    }

    public int roundCount = 6;                        // 总轮次，暂定为6 (需要调整请在inpector中修改)
    public int maxRounds = 8;                         // 最大轮次，如果选择题测试不合格
    public List<IntersectionInfo> allIntersections;   // 所有路口
    public List<IntersectionInfo> roundTargets;       // 抽取的9个目标
    public GameObject player;                         // 玩家物体
    public float targetRadius = 2f;                   // 判定到达目标的范围

    [Header("UI 组件")]
    public TextMeshProUGUI goalNameText;              // MiniMap下方显示目标名
    public GameObject instructionPanel;               // 文本提示面板
    public TextMeshProUGUI instructionText;           // 提示内容文本
    public GameObject RestPanel;                      // 休息阶段面板
    public TextMeshProUGUI restText;                  // 休息提示文本
    public TextMeshProUGUI continueText;              // 休息提示文本

    [Header("被试信息 UI")]
    public GameObject participantInfoPanel;
    public TMP_InputField inputID;
    public TMP_InputField inputName;
    public TMP_InputField inputAge;
    public TMP_Dropdown dropdownGender;
    public TMP_Dropdown dropdownHandedness;
    public Button startButton;

    [Header("图钉管理")]
    public List<Image> minimapPins;                   // MiniMap 图钉（和 allIntersections 顺序一致）
    public Color defaultColor = new Color(0.6f, 0.9f, 0.9f);   // 浅蓝绿色
    public Color targetColor = Color.red;

    [Header("生成路口位置")]
    public Transform locationsParent;                  // 拖入 Locations
    public GameObject pinTemplate;                     // 拖入你的 PinTemplate
    public RectTransform minimapPanel;                 // 拖入 MiniMapDisplay
    public Transform pinContainer;                     // 拖入 PinContainer 作为图钉父物体
    public Vector2 worldSize = new Vector2(200, 200);  // 地图大小

    [Header("JRD控制")]
    public JRDResponseController jrdController;    // Inspector 拖入 JRD Canvas
    public GameObject jrdBlackScreen;              // 背景+指导语UI
    public GameObject jrdFixation;                 // 注视点
    public GameObject jrdBlank;                    // JRD 空屏
    public GameObject passiveCanvas;               // 被动环视
    public TextMeshProUGUI interInstructionText;   // 提示内容文本

    [Header("Intra-JRD 相机")]
    public Camera jrdCamera;               // 拖入一个额外相机
    public GameObject jrdCameraCanvas;     // 该相机用的 UI（比如圆环），用于开关显示
    public float intraViewFOV = 35.16f;       // 换算 horizontal FOV = 60

    [Header("图标素材")]
    public List<Sprite> availableIcons; // 拖入icon素材

    [Header("图标展示 UI")]
    public Image goalIconImage;     // 顶部导航时的icon

    [Header("JRD 图标 UI")]
    public Image jrdFromIcon;
    public Image jrdToIcon;

    void AssignIconSpritesToTargets()
    {
        List<Sprite> shuffled = new List<Sprite>(availableIcons);
        shuffled.Shuffle(); // 扩展方法 List<T>.Shuffle()

        for (int i = 0; i < roundTargets.Count; i++)
        {
            roundTargets[i].iconSprite = shuffled[i];
        }
    }

    private int currentRound = 1;                  // 当前轮次（1~6）
    private int trialInRound = 0;                  // 当前轮内的目标编号（0~8）
    private int correctInCurrentRound = 0;         // 当前轮次正确的选择题数量
    private bool isNavigating = false;
    private float currentNorthYaw = 0f;            // 当前正北方向的 yaw 角度

    // 选择题
    [Header("选择题 UI")]
    public GameObject choicePanel; 
    public List<Button> optionButtons;    // inspector中拖入这4个按钮
    private bool identificationFinished = false;

    private ParticipantInfo participant;


    void Start()
    {
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;

        jrdCamera.enabled = false;  // 初始关闭
        jrdCameraCanvas.SetActive(false);  // JRD UI 不显示
        jrdBlackScreen.SetActive(false);  // JRD 黑屏不显示

        participantInfoPanel.SetActive(true);

        // 禁止玩家控制
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null)
        {
            pc.canMove = false;
            pc.canLook = false;
        }
    }

    // 被试info输入完成，按下开始实验
    public void OnStartButtonPressed()
    {
        participant = new ParticipantInfo();

        int.TryParse(inputID.text, out participant.ID);  
        participant.Name = inputName.text;
        int.TryParse(inputAge.text, out participant.Age);

        // Gender: 男=1, 女=2
        participant.Gender = dropdownGender.value + 1;

        // Handedness: 右=1, 左=2
        participant.Handedness = dropdownHandedness.value + 1;


        // 隐藏输入界面
        participantInfoPanel.SetActive(false);

        // 恢复玩家控制 & 鼠标锁定
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null)
        {
            pc.canMove = true;
            pc.canLook = true;
        }

        // 旋转平衡正北
        int rotationIndex = participant.ID % 4;
        float startYaw = rotationIndex * 90f;
        currentNorthYaw = startYaw;
        participant.StartYaw = startYaw; 

        // 设置玩家初始朝向
        pc.SetInitialYaw(startYaw);

        // 旋转 MiniMap（逆时针）
        minimapPanel.localRotation = Quaternion.Euler(0f, 0f, startYaw);

        // 启动实验流程
        InitAllIntersectionsFromScene();      // 把场景中坐标转为列表
        roundTargets = GenerateTargetsForRound();
        AssignIconSpritesToTargets();   // 分配图标（打乱）
        GenerateMinimapPins();                // 在MiniMap上生成图钉
        StartCoroutine(RunLearningPhase());       // 如果跳过学习直接测试，就注释掉这行
        // StartCoroutine(RunTestPhase());           // 临时跳过学习阶段，直接进入测试

        Debug.Log($"ID: {participant.ID}, 姓名: {participant.Name}, 年龄: {participant.Age}, 性别: {(participant.Gender == 1 ? "男" : "女")}, 利手: {(participant.Handedness == 1 ? "右" : "左")}");


        // ----------- data logger 记录被试信息 -----------
        DataLogger.Instance.participant = participant;
    }

    // 初始化路口信息
    void InitAllIntersectionsFromScene()
    {
        allIntersections = new List<IntersectionInfo>();
        int counter = 0;

        foreach (Transform child in locationsParent)
        {
            string objName = child.name;  // 如 "Cross0_2"
            string[] parts = objName.Replace("Cross", "").Split('_');

            int blockID = int.Parse(parts[0]);
            Vector2 pos = new Vector2(child.position.x, child.position.z);

            allIntersections.Add(new IntersectionInfo
            {
                name = objName,
                position = pos,
                blockID = blockID, 
                index = counter++,  
                iconSprite = null   // 留位，稍后根据打乱分配 (下一个函数)
            });
        }
    }

    // 生成target图钉
    void GenerateMinimapPins()
    {
        minimapPins = new List<Image>();

        foreach (var inter in roundTargets)
        {
            GameObject newPin = Instantiate(pinTemplate, pinContainer);
            newPin.SetActive(true);  // 启用图钉

            RectTransform rt = newPin.GetComponent<RectTransform>();

            // 映射到 UI 空间
            float normX = (inter.position.x + worldSize.x / 2f) / worldSize.x;
            float normY = (inter.position.y + worldSize.y / 2f) / worldSize.y;

            float panelW = minimapPanel.rect.width;
            float panelH = minimapPanel.rect.height;

            float uiX = normX * panelW;
            float uiY = panelH - normY * panelH;  

            rt.anchoredPosition = new Vector2(uiX, -uiY);
            rt.localRotation = Quaternion.Euler(0f, 0f, -currentNorthYaw);  // 抵消 minimapPanel 的旋转
            minimapPins.Add(newPin.GetComponent<Image>());
        }
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Learning phase
    IEnumerator RunLearningPhase()
    {
        for (currentRound = 1; currentRound <= maxRounds; currentRound++)
        {
            Debug.Log("开始第" + currentRound + "轮学习, 共" + roundCount + "轮");

            correctInCurrentRound = 0;  // 记录当前轮次正确的选择题数量

            // 每轮都随机一个新顺序（但内容一样）
            List<IntersectionInfo> shuffledTargets = new List<IntersectionInfo>(roundTargets);
            shuffledTargets.Shuffle();  // Shuffle 扩展方法

            for (trialInRound = 0; trialInRound < shuffledTargets.Count; trialInRound++)
            {
                IntersectionInfo target = shuffledTargets[trialInRound];
                yield return StartCoroutine(HandleNavigationTrial(target));
            }

            // 每轮结束后，显示休息提示
            if (currentRound < roundCount)
            {
                Debug.Log("第" + currentRound + "轮学习结束");
                yield return StartCoroutine(ShowRestPanel(
                    $"本轮学习结束\n现在是休息时间\n即将进入第 {currentRound + 1} 轮学习"
                ));
            }
            // 当前轮 == roundCount：检查是否追加一轮
            else if (currentRound == roundCount)
            {
                if (correctInCurrentRound < 8)
                {
                    if (currentRound < maxRounds)  // 还有继续学习的空间
                    {
                        Debug.Log("正确数不足8，追加一轮学习");
                        yield return StartCoroutine(ShowRestPanel(
                            "现在是休息时间\n本轮学习的测试正确数不足8，未达标\n您将进行额外一轮学习"
                        ));
                    }
                    else
                    {
                        Debug.Log("正确数不足8，且已到最大轮数，结束实验");
                        yield return StartCoroutine(ShowRestPanel(
                            "很抱歉，您未能通过学习阶段\n实验结束\n请联系主试"
                        ));

                        // --------- 存储所有学习阶段数据 ---------
                        DataLogger.Instance.ExportAll();
                        Application.Quit();
                        Debug.Log("Application.Quit() 被调用了");
                        yield break;
                    }
                }
                else
                {
                    break;   // 完成，结束学习阶段
                }
            }
            // 当前轮是超出计划的第7、第8轮
            else
            {
                if (correctInCurrentRound >= 8)
                {
                    break; // 达标，结束学习
                }
                else if (currentRound == maxRounds)
                {
                    // 不合格，终止实验
                    Debug.Log("达到最大轮数，仍不合格，结束实验");
                    yield return StartCoroutine(ShowRestPanel(
                        "很抱歉，您未能通过学习阶段\n实验结束\n请联系主试"
                    ));

                    DataLogger.Instance.ExportAll();

                    Application.Quit();
                    Debug.Log("Application.Quit() 被调用了");
                    yield break;
                }
                else
                {
                    yield return StartCoroutine(ShowRestPanel(
                        "本轮学习的测试正确数不足8，未达标\n您将进行额外一轮学习"
                    ));
                }
            }
        }

        Debug.Log("学习阶段全部结束");

        // 休息提示，准备进入测试阶段
        yield return StartCoroutine(ShowRestPanel(
            "恭喜完成学习阶段\n现在是休息时间\n即将进入测试阶段，请先联系主试"
        ));
        
        // 进入testing
        yield return StartCoroutine(RunTestPhase());
    }

    // 休息阶段
    IEnumerator ShowRestPanel(string message)
    {
        Debug.Log("休息");
        // 等待上一轮的 Space 松开，避免直接跳过
        yield return new WaitUntil(() => !Input.GetKey(KeyCode.Space));
        restText.text = message;
        RestPanel.SetActive(true);

        // 等待被试按下空格键
        yield return new WaitUntil(() => Input.GetKeyDown(KeyCode.Space));

        RestPanel.SetActive(false);
    }

    // 导航过程
    IEnumerator HandleNavigationTrial(IntersectionInfo target)
    {
        // 设置导航开始时间
        float navigationStartTime = Time.time;

        Debug.Log("前往: " + target.name);

        // 设置图钉颜色
        UpdateAllPinsColor(defaultColor);
        minimapPins[roundTargets.IndexOf(target)].color = targetColor;

        // 显示目标图标和提示文字 (前三轮学习)
        if (currentRound <= Mathf.FloorToInt(roundCount / 2f))
        {
            goalNameText.text = "请前往：";
            goalNameText.gameObject.SetActive(true); 
            goalIconImage.sprite = target.iconSprite;
            goalIconImage.gameObject.SetActive(true);
        }

        // 等待到达目标（进入半径）; ----------- data logger 记录 navigation frame position 数据 (100ms 记一次 location) -----------
        float lastLogTime = 0f;
        while (Vector2.Distance(new Vector2(player.transform.position.x, player.transform.position.z), target.position) > targetRadius)
        {
            if (Time.time - lastLogTime >= 0.1f)  // 每100ms记录一次
            {
                Vector2 pos = new Vector2(player.transform.position.x, player.transform.position.z);
                string block = DataLogger.Instance.ExtractBlockFromName(target.name);
                DataLogger.Instance.LogNavigationFrame(currentRound, trialInRound, target.name, target.iconSprite?.name ?? "null", block, target.position, pos, player.transform.eulerAngles.y);

                lastLogTime = Time.time;
            }

            yield return null;
        }

        // Snap到中心 & 锁定玩家移动
        player.transform.position = new Vector3(target.position.x, player.transform.position.y, target.position.y);
        player.GetComponent<PlayerController>().canMove = false;

        // ---------- data logger 记录 navigation summary 数据 -----------
        DataLogger.Instance.LogNavigationSummary(new NavigationSummary
        {
            round = currentRound,
            trialInRound = trialInRound,
            targetIntersection = target.name,
            iconName = target.iconSprite?.name ?? "null",
            block = DataLogger.Instance.ExtractBlockFromName(target.name),
            duration = Time.time - navigationStartTime, // 你需要设置 navigationStartTime = Time.time 在开始前
            intersectionX = target.position.x, 
            intersectionY = target.position.y
        });

        // 正北朝向提示
        instructionPanel.SetActive(true);
        instructionText.text = "请先面朝正北方向";
        // 等待玩家将朝向调整到 ±5° 内
        yield return new WaitUntil(() =>
        {
            float yaw = player.transform.eulerAngles.y;
            float delta = Mathf.DeltaAngle(yaw, currentNorthYaw);  // 差值范围：[-180, +180]
            return Mathf.Abs(delta) <= 5f;
        });

        // 自动对齐到正北方向
        Vector3 angles = player.transform.eulerAngles;
        player.transform.eulerAngles = new Vector3(0f, currentNorthYaw, 0f);
        // 更新 yaw 值
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null) pc.yaw = currentNorthYaw;

        instructionPanel.SetActive(false);
        goalNameText.gameObject.SetActive(false);   // 去掉"请前往："

        // 4-6轮学习的选择题测试 (后一半)
        if (currentRound > Mathf.FloorToInt(roundCount / 2f))
        {
            yield return StartCoroutine(HandleChoiceQuestion(target));

            // 显示目标图标
            goalIconImage.sprite = target.iconSprite;
            goalIconImage.gameObject.SetActive(true);
        }

        // 等待玩家环视
        yield return StartCoroutine(HandleViewingTask());

        // 完成环视后，才可以继续移动
        player.GetComponent<PlayerController>().canMove = true;

        // 隐藏目标图标
        goalIconImage.gameObject.SetActive(false);
        
    }

    void UpdateAllPinsColor(Color c)
    {
        foreach (var pin in minimapPins)
        {
            pin.color = c;
        }
    }

    // 抽取9个target路口 (每个block抽3个)
    List<IntersectionInfo> GenerateTargetsForRound()
    {
        var selected = new List<IntersectionInfo>();
        var groupedByBlock = new Dictionary<int, List<IntersectionInfo>>();

        foreach (var inter in allIntersections)
        {
            if (!groupedByBlock.ContainsKey(inter.blockID))
                groupedByBlock[inter.blockID] = new List<IntersectionInfo>();
            groupedByBlock[inter.blockID].Add(inter);
        }

        foreach (var block in groupedByBlock.Keys)
        {
            List<IntersectionInfo> options = groupedByBlock[block];
            options.Shuffle();  // List<T>.Shuffle() 扩展函数
            selected.AddRange(options.GetRange(0, 3));  // 每个 block 抽 3 个
        }

        return selected;
    }

    // 环视任务
    IEnumerator HandleViewingTask()
    {
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null) pc.canLook = false; // 暂时不能转头

        instructionPanel.SetActive(true);
        instructionText.text = "请环视记忆路口内画面对应的方向\n完成学习后按空格继续";
        yield return new WaitForSeconds(2.5f);
        instructionPanel.SetActive(false);

        if (pc != null) pc.canLook = true;  // 开始允许环视
        float viewingStartTime = Time.time;  // 记录环视开始时间

        // 数据记录初始化
        int currentBin = -1;
        float binEnterTime = -1f;
        HashSet<int> visitedFineBins = new();     // 0.5° × 720，用于数据记录
        HashSet<int> visitedCoarseBins = new();   // 20° × 18，用于判断是否环视

        while (true)
        {
            float yaw = player.transform.eulerAngles.y % 360f;
            if (yaw < 0f) yaw += 360f;

            int fineBin = Mathf.FloorToInt(yaw * 2);      // 0~719
            int coarseBin = Mathf.FloorToInt(yaw / 20f);  // 0~17

            if (fineBin != currentBin)  // 切换了bin
            {
                float now = Time.time;

                // 记录上一 bin
                if (currentBin >= 0)
                {
                    // ----------- data logger 记录 viewing frame 数据 -----------
                    DataLogger.Instance.LogViewingFrame(currentRound, trialInRound,
                        roundTargets[trialInRound].name,
                        roundTargets[trialInRound].iconSprite?.name ?? "null",
                        DataLogger.Instance.ExtractBlockFromName(roundTargets[trialInRound].name),
                        currentBin,
                        binEnterTime,
                        now - binEnterTime,
                        new Vector2(player.transform.position.x, player.transform.position.z)
                    );
                }

                currentBin = fineBin;
                binEnterTime = now;

                visitedFineBins.Add(fineBin);
                visitedCoarseBins.Add(coarseBin);
                Debug.Log($"当前访问 coarseBin 数量: {visitedCoarseBins.Count}");
            }

            // 检查是否允许跳出
            if (Input.GetKeyDown(KeyCode.Space))
            {
                if (visitedCoarseBins.Count >= 18)  // 至少环视了一整圈 
                {
                    // 记录最后一个 bin
                    if (currentBin >= 0)
                    {
                        float now = Time.time;
                        DataLogger.Instance.LogViewingFrame(currentRound, trialInRound,
                            roundTargets[trialInRound].name,
                            roundTargets[trialInRound].iconSprite?.name ?? "null",
                            DataLogger.Instance.ExtractBlockFromName(roundTargets[trialInRound].name),
                            currentBin,
                            binEnterTime,
                            now - binEnterTime,
                            new Vector2(player.transform.position.x, player.transform.position.z)
                        );
                    }
                    break;
                }
                else
                {
                    instructionText.text = "请至少完成一圈环视后再继续";
                    instructionPanel.SetActive(true);
                    yield return new WaitForSeconds(2f);
                    instructionPanel.SetActive(false);
                }
            }

            yield return null;
        }

        // ------------- data logger 记录 viewing summary 数据 -------------
        DataLogger.Instance.LogViewingSummary(new ViewingSummary
        {
            round = currentRound,
            trialInRound = trialInRound,
            intersectionName = roundTargets[trialInRound].name,
            iconName = roundTargets[trialInRound].iconSprite?.name ?? "null",
            block = DataLogger.Instance.ExtractBlockFromName(roundTargets[trialInRound].name),
            duration = Time.time - viewingStartTime,  // viewingStartTime 需要在 viewing task 开始处记录
            posX = player.transform.position.x,
            posY = player.transform.position.z
        });
    }

    IEnumerator HandleChoiceQuestion(IntersectionInfo correct)
    {
        // 禁止玩家转头
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null) pc.canLook = false;

        // 显示指导语和选择题
        instructionPanel.SetActive(true);
        choicePanel.SetActive(true);
        instructionText.text = "你位于的路口是：\n(请用鼠标点击对应图标)";

        // 显示选项图标（正确+3个干扰项）
        List<IntersectionInfo> options = new List<IntersectionInfo> { correct };
        Debug.Log($"[识别题] 正确路口：{correct.name} (block {correct.blockID})");

        // 建立 block 分组
        var grouped = new Dictionary<int, List<IntersectionInfo>>();
        foreach (var inter in roundTargets)
        {
            if (!grouped.ContainsKey(inter.blockID))
                grouped[inter.blockID] = new List<IntersectionInfo>();
            grouped[inter.blockID].Add(inter);
        }

        // 从 same block 中再选一个干扰项（排除 correct）
        var sameBlock = grouped[correct.blockID];
        var sameCandidates = new List<IntersectionInfo>(sameBlock);
        sameCandidates.Remove(correct);
        sameCandidates.Shuffle();
        if (sameCandidates.Count > 0)
        {
            var distractor = sameCandidates[0];
            options.Add(distractor);
        }

        // 从其它 block 中各挑一个干扰项
        foreach (var kvp in grouped)
        {
            if (kvp.Key == correct.blockID) continue;

            List<IntersectionInfo> candidates = new List<IntersectionInfo>(kvp.Value);
            candidates.Shuffle();

            if (candidates.Count > 0)
            {
                options.Add(candidates[0]);
            }
        }

        if (options.Count < 4)
        {
            Debug.LogError("选项数不足4个，数据结构出错");
        }

        options.Shuffle();

        Debug.Log("[识别题] 最终选项顺序如下：");
        for (int i = 0; i < options.Count; i++)
        {
            Debug.Log($"Option {i + 1}: {options[i].name} (block {options[i].blockID})");
        }

        // 时间
        float choiceStartTime = Time.time;  // 放在开始等待选择之前

        // 假设你有4个 UI Image + Button，命名为 optionButtons[0~3]
        for (int i = 0; i < 4; i++)
        {
            optionButtons[i].GetComponent<Image>().sprite = options[i].iconSprite;
            int idx = i;
            optionButtons[i].onClick.RemoveAllListeners();
            optionButtons[i].onClick.AddListener(() =>
            {
                // ----------- data logger 记录 identification frame 数据 -----------
                float rt = Time.time - choiceStartTime;

                DataLogger.Instance.LogChoice(new ChoiceQuestionData
                {
                    round = currentRound,
                    trialInRound = trialInRound,
                    correctName = correct.name,
                    chosenName = options[idx].name,
                    correctBlock = DataLogger.Instance.ExtractBlockFromName(correct.name),
                    chosenBlock = DataLogger.Instance.ExtractBlockFromName(options[idx].name),
                    isCorrect = options[idx] == correct,
                    RT = rt
                });

                // 反馈
                StartCoroutine(HandleIdentificationFeedback(options[idx] == correct, correct)); 
            });
            optionButtons[i].gameObject.SetActive(true);

            Debug.Log($"选项 {i} 使用图标：{options[i].iconSprite?.name ?? "null"}");
        }

        // 等待选择完成（用一个标志位）
        identificationFinished = false;
        while (!identificationFinished)
            yield return null;

        foreach (var btn in optionButtons)
            btn.gameObject.SetActive(false);

        // 隐藏选择题和指导语
        choicePanel.SetActive(false);
        instructionPanel.SetActive(false);
    }

    IEnumerator HandleIdentificationFeedback(bool isCorrect, IntersectionInfo correct)
    {
        instructionText.text = isCorrect ? "正确！" : "错误！";
        goalIconImage.sprite = correct.iconSprite;
        goalIconImage.gameObject.SetActive(true);

        if (isCorrect)
            correctInCurrentRound++;   // 正确数量+1

        yield return new WaitForSeconds(2f);

        identificationFinished = true;
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing phase
    void SetupJRDCamera(IntersectionInfo inter, float yaw)
    {
        Vector3 pos = new Vector3(inter.position.x, 1.7f, inter.position.y);  // 适合人眼高度
        jrdCamera.transform.position = pos;
        jrdCamera.transform.rotation = Quaternion.Euler(0f, yaw, 0f);
        jrdCamera.fieldOfView = intraViewFOV;

        // 若相机是世界摄像机，确保只有它启用
        jrdCamera.enabled = true;
    }

    // 路口内测试画面
    float GenerateRandomHeadingExcludingNorth()  // exclude north overlap
    {
        float heading;
        while (true)
        {
            heading = Random.Range(0f, 360f);
            float delta = Mathf.DeltaAngle(currentNorthYaw, heading);
            if (Mathf.Abs(delta) > 45f) break;  // 距离 northYaw 超过 ±45°
        }
        return heading;
    }

    // JRD trials
    List<(IntersectionInfo from, IntersectionInfo to)> GenerateInterJRDTrials()
    {
        List<(IntersectionInfo from, IntersectionInfo to)> trials = new();

        var groupedByBlock = new Dictionary<int, List<IntersectionInfo>>();
        foreach (var inter in roundTargets)  // 从学习阶段的9个中来生成
        {
            if (!groupedByBlock.ContainsKey(inter.blockID))
                groupedByBlock[inter.blockID] = new List<IntersectionInfo>();
            groupedByBlock[inter.blockID].Add(inter);
        }

        foreach (var from in roundTargets)
        {
            var sameBlock = groupedByBlock[from.blockID];
            foreach (var other in sameBlock)
            {
                if (other != from)
                    trials.Add((from, other));
            }

            // 跨 block, 每个block抽两个
            foreach (var kvp in groupedByBlock)
            {
                if (kvp.Key == from.blockID) continue;
                List<IntersectionInfo> others = kvp.Value;
                List<IntersectionInfo> sampled = SampleTwo(others);
                foreach (var other in sampled)
                    trials.Add((from, other));
            }
        }

        trials.Shuffle();  // 打乱顺序
        return trials;
    }

    List<IntersectionInfo> SampleTwo(List<IntersectionInfo> source)
    {
        source = new List<IntersectionInfo>(source);
        source.Shuffle();
        return source.GetRange(0, 2);
    }

    // 测试阶段
    IEnumerator RunTestPhase()
    {
        Debug.Log("进入测试阶段");

        // 关闭主相机和所有学习阶段的UI/玩家控制
        if (player != null) player.SetActive(false);  // 整个玩家物体关闭
        if (minimapPanel != null) minimapPanel.gameObject.SetActive(false); // minimap隐藏
        foreach (var pin in minimapPins)
        {
            if (pin != null) pin.gameObject.SetActive(false);  // 隐藏图钉
        }
        if (goalNameText != null) goalNameText.gameObject.SetActive(false);  // 隐藏目标名

        // 启用 JRD 相机和控制器
        if (jrdCamera != null) jrdCamera.enabled = true;

        var pairs = GenerateInterJRDTrials();

        int trialCount = pairs.Count;
        for (int i = 0; i < trialCount; i++)
        {
            Debug.Log($"开始第 {i + 1} / {trialCount} 个 trial, 路口 {pairs[i].from.index} → {pairs[i].to.index}");
            yield return StartCoroutine(RunSingleTrial(pairs[i].from, pairs[i].to, i));

            // 每完成9个，弹出休息界面（不包括最后一次）
            if ((i + 1) % 9 == 0 && i + 1 < trialCount)
            {
                string msg = $"现在是休息时间\n已完成 {i + 1} / {trialCount} 次测试";
                yield return StartCoroutine(ShowRestPanel(msg));
            }
        }

        Debug.Log("测试阶段完成");
        // --------------------------- DataLogger: 保存所有数据 --------------------------------
        DataLogger.Instance.ExportAll();

        // 显示结束界面，退出程序
        yield return StartCoroutine(ShowEndAndQuit());
    }

    // 一个trial: 路口间 + 路口内
    IEnumerator RunSingleTrial(IntersectionInfo from, IntersectionInfo to, int trialID)
    {
        float interRT = -1f;
        float intraRT = -1f;

        // 打开图标
        jrdFromIcon.sprite = from.iconSprite;
        jrdToIcon.sprite = to.iconSprite;

        // 呈现注视点，1s
        jrdFixation.SetActive(true);
        yield return new WaitForSeconds(1f);
        jrdFixation.SetActive(false);

        // ----------------------------------------------------------------
/*
        // 被动环视 from 路口
        yield return StartCoroutine(PassiveViewing(from, trialID));
        // 空屏 0.5s
        jrdBlank.SetActive(true);
        yield return new WaitForSeconds(0.5f);
        jrdBlank.SetActive(false);
        // 关掉 from icon
        jrdFromIcon.gameObject.SetActive(false);
*/
        // ----------------------------------------------------------------

        // ---- 全局JRD ----
        jrdBlackScreen.SetActive(true);
        jrdCameraCanvas.SetActive(false);
        interInstructionText.text = $"你站在：\n \n面朝正北\n \n目标是：";     // 无环视版本
        // interInstructionText.text = $"你站在当前的路口\n \n面朝正北\n \n目标是：";     // 有环视版本
        yield return new WaitForSeconds(4f);    
        jrdBlackScreen.SetActive(false);

        // 设置圆环中显示的提示语
        jrdController.gameObject.SetActive(true);
        jrdCameraCanvas.SetActive(true);
        jrdController.ResetResponse("请判断目标路口的方位");
        float interResponse = -1f;
        float trueAngle = GetAngleBetween(from.position, to.position, currentNorthYaw);
        yield return StartCoroutine(RunJRDTrial(trueAngle,
            angle => interResponse = angle,
            rt => interRT = rt));
        jrdController.gameObject.SetActive(false);
        jrdCameraCanvas.SetActive(false);

        // 空屏 0.5s
        jrdBlank.SetActive(true);
        yield return new WaitForSeconds(0.5f);
        jrdBlank.SetActive(false);

        // ---- 局部JRD ----
        // 呈现注视点，1s
        jrdFixation.SetActive(true);
        yield return new WaitForSeconds(1f);
        jrdFixation.SetActive(false);
        // 开始局部 JRD
        float heading = GenerateRandomHeadingExcludingNorth();
        SetupJRDCamera(from, heading);
        yield return new WaitForSeconds(4f);
        float relativeHeading = (heading - currentNorthYaw + 360f) % 360f;

        // 设置圆环中心文字为“请判断画面朝向”
        jrdController.gameObject.SetActive(true);
        jrdCameraCanvas.SetActive(true);
        jrdController.ResetResponse("请判断路口内画面朝向");
        float intraResponse = -1f;
        yield return StartCoroutine(RunJRDTrial(relativeHeading,
            angle => intraResponse = angle,
            rt => intraRT = rt));
        jrdController.gameObject.SetActive(false);
        jrdCameraCanvas.SetActive(false);

        Debug.Log($"Trial: {from.index} → {to.index}, inter={interResponse}, intra={intraResponse}, heading={heading}");

        // 整个 trial 结束，呈现空屏,0.5s
        jrdBlank.SetActive(true);
        yield return new WaitForSeconds(0.5f);
        jrdBlank.SetActive(false);

        // ----------- DataLogger: 记录 InterTrial 数据 ------------
        DataLogger.Instance.LogInter(new InterTrialData
        {
            trialID = trialID,  
            fromName = from.name,
            toName = to.name,
            fromBlock = DataLogger.Instance.ExtractBlockFromName(from.name),
            toBlock = DataLogger.Instance.ExtractBlockFromName(to.name),
            fromIconName = from.iconSprite?.name ?? "null",
            toIconName = to.iconSprite?.name ?? "null",
            trueAngle = GetAngleBetween(from.position, to.position, currentNorthYaw),
            responseAngle = interResponse,
            deviation = Mathf.DeltaAngle(interResponse, GetAngleBetween(from.position, to.position, currentNorthYaw)),
            absDeviation = Mathf.Abs(Mathf.DeltaAngle(interResponse, GetAngleBetween(from.position, to.position, currentNorthYaw))),
            RT = interRT,  
            fromX = from.position.x,
            fromY = from.position.y,
            toX = to.position.x,
            toY = to.position.y
        });

        // ----------- DataLogger: 记录 IntraTrial 数据 ------------

        DataLogger.Instance.LogIntra(new IntraTrialData
        {
            trialID = trialID,
            intersectionName = from.name,
            iconName = from.iconSprite?.name ?? "null",
            block = DataLogger.Instance.ExtractBlockFromName(from.name),
            trueAngle = relativeHeading,     // 这里也要考虑northyaw
            responseAngle = intraResponse,
            deviation = Mathf.DeltaAngle(intraResponse, relativeHeading),
            absDeviation = Mathf.Abs(Mathf.DeltaAngle(intraResponse, relativeHeading)),
            RT = intraRT,  
            posX = from.position.x,
            posY = from.position.y
        });

        // --- helper function ---
        float GetAngleBetween(Vector2 from, Vector2 to, float northYaw)
        {
            Vector2 dir = to - from;
            float angle = Mathf.Atan2(dir.x, dir.y) * Mathf.Rad2Deg;
            if (angle < 0) angle += 360f;

            float relative = angle - northYaw;
            if (relative < 0) relative += 360f;

            return relative;
        }
    }

    // rt 在这里记录
    IEnumerator RunJRDTrial(float correctAngle, System.Action<float> storeResponse, System.Action<float> storeRT)
    {
        float startTime = Time.time;
        jrdController.onSubmit = storeResponse;
        jrdController.gameObject.SetActive(true);

        // 等待被试点击 & 空格键提交
        while (!Input.GetKeyDown(KeyCode.Space) || jrdController.CurrentAngle < 0f)
            yield return null;

        float rt = Time.time - startTime;  // 记录RT
        storeRT?.Invoke(rt);               // 传出去

        // 显示偏差反馈
        jrdController.Submit(correctAngle);
        yield return new WaitForSeconds(2f);  // 2s

        jrdController.ResetResponse();
        jrdController.gameObject.SetActive(false);

    }

    // 被动环视部分
    IEnumerator PassiveViewing(IntersectionInfo from, int trialID)
    {
        // 设置相机位置 & 初始角度
        jrdCamera.transform.position = new Vector3(from.position.x, 1.7f, from.position.y);
        jrdCamera.transform.rotation = Quaternion.Euler(0f, currentNorthYaw, 0f);
        jrdCamera.enabled = true;

        // 提示文本“正北”
        jrdBlackScreen.SetActive(false);
        passiveCanvas.gameObject.SetActive(true);
        yield return new WaitForSeconds(1f); // 停留1秒
        passiveCanvas.gameObject.SetActive(false);

        // 被动环视开始
        float duration = 15f;
        float elapsed = 0f;
        float startYaw = currentNorthYaw;

        while (elapsed < duration)
        {
            float t = elapsed / duration;
            float yaw;

            if (trialID % 2 == 0)  // 偶数 trial，顺时针
                yaw = startYaw + 360f * t;
            else                   // 奇数 trial，逆时针
                yaw = startYaw - 360f * t;

            yaw = (yaw + 360f) % 360f;

            jrdCamera.transform.rotation = Quaternion.Euler(0f, yaw, 0f);

            elapsed += Time.deltaTime;
            yield return null;
        }

        // 最后对齐回正北，保险起见
        jrdCamera.transform.rotation = Quaternion.Euler(0f, currentNorthYaw, 0f);
    }

    // 实验结束页面
    IEnumerator ShowEndAndQuit()
    {
        // ------- 计算所有偏差均值, 作为奖励依据 -------
        var interDevs = DataLogger.Instance.interTrials.Select(d => d.absDeviation);
        var intraDevs = DataLogger.Instance.intraTrials.Select(d => d.absDeviation);

        List<float> allDevs = new List<float>();
        allDevs.AddRange(interDevs);
        allDevs.AddRange(intraDevs);

        float avgDeviation = allDevs.Count > 0 ? allDevs.Average() : 0f;

        // 显示结束界面
        RestPanel.SetActive(true);
        restText.text = $"实验结束\n\n您的平均判断偏差为{avgDeviation:F2}°\n感谢您的参与";
        continueText.text = "请联系主试";

        // 按空格退出
        yield return new WaitUntil(() => Input.GetKeyDown(KeyCode.Space));

        Application.Quit();

        Debug.Log("结束页面被调用了");
    }

}
