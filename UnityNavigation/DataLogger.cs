using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

public class DataLogger : MonoBehaviour
{
    public static DataLogger Instance;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    // 被试信息结构
    public ParticipantInfo participant;

    // 所有数据结构
    public List<ViewingFrameData> viewingFrames = new();
    public List<ViewingSummary> viewingSummaries = new();
    public List<NavigationFrameData> navigationFrames = new();
    public List<NavigationSummary> navigationSummaries = new();
    public List<ChoiceQuestionData> choiceResponses = new();
    public List<InterTrialData> interTrials = new();
    public List<IntraTrialData> intraTrials = new();

    // ------------ 记录函数 ------------
    public void LogViewingFrame(int round, int trial, string name, string iconName, string block, int binIndex, float enterTime, float duration, Vector2 pos)
    {
        viewingFrames.Add(new ViewingFrameData
        {
            participantID = participant.ID,
            startYaw = participant.StartYaw,
            round = round,
            trialInRound = trial,
            intersectionName = name,
            iconName = iconName,
            block = block,
            binIndex = binIndex,
            enterTime = enterTime,
            duration = duration,
            posX = pos.x,
            posY = pos.y
        });
    }

    public void LogViewingSummary(ViewingSummary data)
    {
        data.participantID = participant.ID;
        data.startYaw = participant.StartYaw;
        viewingSummaries.Add(data);
    }

    public void LogNavigationFrame(int round, int trial, string targetName, string iconName, string block, Vector2 intersectionPos, Vector2 playerPos, float playerYaw)
    {
        navigationFrames.Add(new NavigationFrameData
        {
            participantID = participant.ID,
            startYaw = participant.StartYaw,
            round = round,
            trialInRound = trial,
            targetIntersection = targetName,
            iconName = iconName,
            block = block,
            time = Time.time,
            intersectionX = intersectionPos.x,
            intersectionY = intersectionPos.y,
            playerX = playerPos.x,
            playerY = playerPos.y, 
            playerYaw = playerYaw  // 记录玩家朝向
        });
    }

    public void LogNavigationSummary(NavigationSummary data)
    {
        data.participantID = participant.ID;
        data.startYaw = participant.StartYaw;
        navigationSummaries.Add(data);
    }

    public void LogChoice(ChoiceQuestionData data)
    {
        data.participantID = participant.ID;
        data.startYaw = participant.StartYaw;
        choiceResponses.Add(data);
    }

    public void LogInter(InterTrialData data)
    {
        data.participantID = participant.ID;
        data.startYaw = participant.StartYaw;
        interTrials.Add(data);
    }

    public void LogIntra(IntraTrialData data)
    {
        data.participantID = participant.ID;
        data.startYaw = participant.StartYaw;
        intraTrials.Add(data);
    }

    // ------------ 导出数据 ------------
    public void ExportAll()
    {
        string basePath = Path.Combine(Application.dataPath, "Results", $"P{participant.ID}_{DateTime.Now:yyyyMMdd_HHmmss}");
        Directory.CreateDirectory(basePath);

        ExportCSV(viewingFrames, Path.Combine(basePath, "ViewingFrames.csv"));
        ExportCSV(viewingSummaries, Path.Combine(basePath, "ViewingSummary.csv"));
        ExportCSV(navigationFrames, Path.Combine(basePath, "NavigationFrames.csv"));
        ExportCSV(navigationSummaries, Path.Combine(basePath, "NavigationSummary.csv"));
        ExportCSV(choiceResponses, Path.Combine(basePath, "Choices.csv"));
        ExportCSV(interTrials, Path.Combine(basePath, "InterJRD.csv"));
        ExportCSV(intraTrials, Path.Combine(basePath, "IntraJRD.csv"));
        ExportParticipantInfo(Path.Combine(basePath, "Participant.csv"));
    }

    void ExportParticipantInfo(string path)
    {
        using StreamWriter writer = new StreamWriter(path);
        var fields = typeof(ParticipantInfo).GetFields();

        // 写标题行
        writer.WriteLine(string.Join(",", fields.Select(f => f.Name)));

        // 写数据行
        writer.WriteLine(string.Join(",", fields.Select(f => f.GetValue(participant))));
    }

    void ExportCSV<T>(List<T> list, string path)
    {
        using StreamWriter writer = new StreamWriter(path);
        var fields = typeof(T).GetFields();
        writer.WriteLine(string.Join(",", fields.Select(f => f.Name)));

        foreach (var item in list)
        {
            writer.WriteLine(string.Join(",", fields.Select(f => f.GetValue(item))));
        }
    }

    // ------------ 提取 block 字符串 ------------
    public string ExtractBlockFromName(string name)
    {
        if (name.StartsWith("Cross"))
        {
            string[] parts = name.Substring(5).Split('_');
            if (float.TryParse(parts[0], out float degree))
            {
                return $"Block{degree}";
            }
        }
        return "Unknown";
    }
}

// ------------ 数据结构定义 ------------
[Serializable]
public struct ParticipantInfo
{
    public int ID;
    public string Name;
    public int Age;
    public int Gender;        // 1 = 男, 2 = 女
    public int Handedness;    // 1 = 右, 2 = 左
    public float StartYaw;    // 0/90/180/270，对应 ID % 4 * 90f
}

[Serializable]
public struct ViewingFrameData
{
    public int participantID;
    public float startYaw;
    public int round;
    public int trialInRound;
    public string intersectionName;
    public string iconName;
    public string block;
    public int binIndex;     // 0~719, bin 宽度为0.5°
    public float enterTime;  // Time.time 进入时间
    public float duration;   // 当前bin下停留时间
    public float posX;
    public float posY;      
}

[Serializable]
public struct ViewingSummary
{
    public int participantID;
    public float startYaw;
    public int round;
    public int trialInRound;
    public string intersectionName;
    public string iconName;
    public string block;
    public float duration;
    public float posX;
    public float posY; 
}

[Serializable]
public struct NavigationFrameData
{
    public int participantID;
    public float startYaw;
    public int round;
    public int trialInRound;
    public string targetIntersection;
    public string iconName;
    public string block;
    public float time;
    public float intersectionX;
    public float intersectionY; 
    public float playerX;
    public float playerY; 
    public float playerYaw;
}

[Serializable]
public struct NavigationSummary
{
    public int participantID;
    public float startYaw;
    public int round;
    public int trialInRound;
    public string targetIntersection;
    public string iconName;
    public string block;
    public float duration;
    public float intersectionX;
    public float intersectionY; 
}

[Serializable]
public struct ChoiceQuestionData
{
    public int participantID;
    public float startYaw;
    public int round;
    public int trialInRound;
    public string correctName;
    public string chosenName;
    public string correctBlock;
    public string chosenBlock;
    public bool isCorrect;
    public float RT;
}

[Serializable]
public struct InterTrialData
{
    public int participantID;
    public float startYaw;
    public int trialID;
    public string fromName;
    public string toName;
    public string fromIconName;
    public string toIconName;
    public string fromBlock;
    public string toBlock;
    public float trueAngle;
    public float responseAngle;
    public float deviation;    // 角度偏差
    public float absDeviation; // 绝对值
    public float RT;
    public float fromX;
    public float fromY; 
    public float toX;
    public float toY; 
}

[Serializable]
public struct IntraTrialData
{
    public int participantID;
    public float startYaw;
    public int trialID;
    public string intersectionName;
    public string iconName;
    public string block;
    public float trueAngle;
    public float responseAngle;
    public float deviation;    // 角度偏差
    public float absDeviation; // 绝对值
    public float RT;
    public float posX;
    public float posY; 
}