VERSION 5.00
Begin VB.Form frmProcMan 
   Caption         =   "Process Manager"
   ClientHeight    =   4140
   ClientLeft      =   60
   ClientTop       =   -240
   ClientWidth     =   8610
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   204
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "frmProcMan.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   4140
   ScaleWidth      =   8610
   StartUpPosition =   2  'CenterScreen
   Begin VB.Frame fraProcessManager 
      Caption         =   "Itty Bitty Process Manager v."
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   204
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3975
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   8415
      Begin VB.CommandButton cmdProcManRefresh 
         Caption         =   "Re&fresh"
         Height          =   495
         Left            =   1440
         TabIndex        =   7
         Top             =   3360
         Width           =   1215
      End
      Begin VB.CommandButton cmdProcManBack 
         Cancel          =   -1  'True
         Caption         =   "E&xit"
         Height          =   495
         Left            =   4440
         TabIndex        =   6
         Top             =   3360
         Width           =   1215
      End
      Begin VB.CommandButton cmdProcManRun 
         Caption         =   "&Run..."
         Height          =   495
         Left            =   2760
         TabIndex        =   5
         Top             =   3360
         Width           =   1215
      End
      Begin VB.CommandButton cmdProcManKill 
         Caption         =   "&Kill process"
         Height          =   495
         Left            =   120
         TabIndex        =   4
         Top             =   3360
         Width           =   1215
      End
      Begin VB.ListBox lstProcessManager 
         Height          =   1185
         IntegralHeight  =   0   'False
         Left            =   120
         MultiSelect     =   2  'Extended
         TabIndex        =   3
         Top             =   600
         Width           =   8175
      End
      Begin VB.CheckBox chkProcManShowDLLs 
         Caption         =   "Show &DLLs"
         Height          =   255
         Left            =   3480
         TabIndex        =   2
         Top             =   330
         Width           =   1935
      End
      Begin VB.ListBox lstProcManDLLs 
         Height          =   1140
         IntegralHeight  =   0   'False
         Left            =   120
         TabIndex        =   1
         Top             =   2040
         Visible         =   0   'False
         Width           =   8175
      End
      Begin VB.Label lblConfigInfo 
         AutoSize        =   -1  'True
         Caption         =   "Loaded DLL libraries by selected process:"
         Height          =   195
         Index           =   9
         Left            =   240
         TabIndex        =   10
         Top             =   1800
         Width           =   2955
      End
      Begin VB.Image imgProcManCopy 
         Height          =   240
         Left            =   2520
         Picture         =   "frmProcMan.frx":1CFA
         ToolTipText     =   "Copy process list to clipboard"
         Top             =   330
         Width           =   240
      End
      Begin VB.Label lblProcManDblClick 
         Caption         =   "Double-click a file to view its properties."
         Height          =   390
         Left            =   5760
         TabIndex        =   9
         Top             =   3330
         Width           =   2295
      End
      Begin VB.Label lblConfigInfo 
         AutoSize        =   -1  'True
         Caption         =   "Running processes:"
         Height          =   195
         Index           =   8
         Left            =   240
         TabIndex        =   8
         Top             =   360
         Width           =   1410
      End
      Begin VB.Image imgProcManSave 
         Height          =   240
         Left            =   3000
         Picture         =   "frmProcMan.frx":1E44
         ToolTipText     =   "Save process list to file.."
         Top             =   330
         Width           =   240
      End
   End
   Begin VB.Menu mnuProcMan 
      Caption         =   "ProcessManager Popup Menu"
      Visible         =   0   'False
      Begin VB.Menu mnuProcManKill 
         Caption         =   "Kill process(es)"
      End
      Begin VB.Menu mnuProcManStr1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuProcManCopy 
         Caption         =   "Copy list to clipboard"
      End
      Begin VB.Menu mnuProcManSave 
         Caption         =   "Save list to disk..."
      End
      Begin VB.Menu mnuProcManStr2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuProcManProps 
         Caption         =   "File properties"
      End
   End
End
Attribute VB_Name = "frmProcMan"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'v1.00 - original release, later added copy to clipboard button
'v1.01 - added label for dlls, keyboard shortcuts
'v1.01.1 - fixed crash bug in form_resize, added version number to frame
'v1.02 - added PID numbers to process list
'v1.03 - fixed killing multiple processes (it works now.. typos suck)
'        also added PauseProcess to the killing subs :D (excludes self)
'        added right-click menu to listboxes
'        fixed a crash bug with the CompanyName property of RAdmin.exe
'v1.04 - processes that fail to be killed are now resumed again
'--
'v1.05 - dll list is updated when browsing process list with keyboard

Private Type PROCESSENTRY32
    dwSize As Long
    cntUsage As Long
    th32ProcessID As Long
    th32DefaultHeapID As Long
    th32ModuleID As Long
    cntThreads As Long
    th32ParentProcessID As Long
    pcPriClassBase As Long
    dwFlags As Long
    szExeFile As String * 260
End Type

Private Type MODULEENTRY32
    dwSize As Long
    th32ModuleID As Long
    th32ProcessID As Long
    GlblcntUsage As Long
    ProccntUsage As Long
    modBaseAddr As Long
    modBaseSize As Long
    hModule As Long
    szModule As String * 256
    szExePath As String * 260
End Type

Private Type THREADENTRY32
    dwSize As Long
    dwRefCount As Long
    th32ThreadID As Long
    th32ProcessID As Long
    dwBasePriority As Long
    dwCurrentPriority As Long
    dwFlags As Long
End Type


Private Declare Function CreateToolhelp32Snapshot Lib "kernel32.dll" (ByVal lFlags As Long, ByVal lProcessID As Long) As Long
Private Declare Function Process32First Lib "kernel32.dll" (ByVal hSnapshot As Long, uProcess As PROCESSENTRY32) As Long
Private Declare Function Process32Next Lib "kernel32.dll" (ByVal hSnapshot As Long, uProcess As PROCESSENTRY32) As Long
Private Declare Function Module32First Lib "kernel32.dll" (ByVal hSnapshot As Long, uProcess As MODULEENTRY32) As Long
Private Declare Function Module32Next Lib "kernel32.dll" (ByVal hSnapshot As Long, uProcess As MODULEENTRY32) As Long
Private Declare Function Thread32First Lib "kernel32.dll" (ByVal hSnapshot As Long, uThread As THREADENTRY32) As Long
Private Declare Function Thread32Next Lib "kernel32.dll" (ByVal hSnapshot As Long, ByRef ThreadEntry As THREADENTRY32) As Long
Private Declare Function TerminateProcess Lib "kernel32.dll" (ByVal hProcess As Long, ByVal uExitCode As Long) As Long
Private Declare Function CloseHandle Lib "kernel32.dll" (ByVal hObject As Long) As Long
Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteW" (ByVal hWnd As Long, ByVal lpOperation As Long, ByVal lpFile As Long, ByVal lpParameters As Long, ByVal lpDirectory As Long, ByVal nShowCmd As Long) As Long
Private Declare Function SHRunDialog Lib "shell32.dll" Alias "#61" (ByVal hOwner As Long, ByVal Unknown1 As Long, ByVal Unknown2 As Long, ByVal szTitle As String, ByVal szPrompt As String, ByVal uFlags As Long) As Long
Private Declare Sub ReleaseCapture Lib "user32.dll" ()

Private Const TH32CS_SNAPPROCESS = &H2
Private Const TH32CS_SNAPMODULE = &H8
Private Const TH32CS_SNAPTHREAD = &H4
Private Const PROCESS_TERMINATE = &H1
Private Const PROCESS_QUERY_INFORMATION = 1024
Private Const PROCESS_QUERY_LIMITED_INFORMATION = &H1000
Private Const PROCESS_VM_READ = 16
Private Const THREAD_SUSPEND_RESUME = &H2

Private Const LB_SETTABSTOPS = &H192
Private Const WM_NCLBUTTONDOWN = &HA1
Private Const HTCAPTION = 2

Private lstProcessManagerHasFocus As Boolean


Public Sub RefreshProcessList(objList As ListBox)
    Dim hSnap&, uPE32 As PROCESSENTRY32, i&
    Dim sExeFile$, hProcess&

    hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    
    uPE32.dwSize = Len(uPE32)
    If Process32First(hSnap, uPE32) = 0 Then
        CloseHandle hSnap
        Exit Sub
    End If
    
    objList.Clear
    Do
        sExeFile = TrimNull(uPE32.szExeFile)
        objList.AddItem uPE32.th32ProcessID & vbTab & sExeFile
    Loop Until Process32Next(hSnap, uPE32) = 0
    CloseHandle hSnap
End Sub

Public Sub RefreshProcessListNT(objList As ListBox)
        Dim lNumProcesses As Long, i As Long
        Dim sProcessName As String
        Dim Process() As MY_PROC_ENTRY
        
        lNumProcesses = GetProcesses_Zw(Process)
        
        If lNumProcesses Then
        
            For i = 0 To UBound(Process)
        
                sProcessName = Process(i).Path
                
                If Len(Process(i).Path) = 0 Then
                    If Not ((StrComp(Process(i).Name, "System Idle Process", 1) = 0 And Process(i).PID = 0) _
                        Or (StrComp(Process(i).Name, "System", 1) = 0 And Process(i).PID = 4) _
                        Or (StrComp(Process(i).Name, "Memory Compression", 1) = 0)) Then
                          sProcessName = Process(i).Name '& " (cannot get Process Path)"
                    End If
                End If
                
                If Len(sProcessName) <> 0 Then
                    'objList.AddItem Process(i).PID & vbTab & Process(i).SessionID & vbTab & sProcessName
                    objList.AddItem Process(i).PID & vbTab & sProcessName
                End If
            Next
        End If
End Sub

Public Sub RefreshDLLList(lPID&, objList As ListBox)
    Dim hSnap&, uME32 As MODULEENTRY32
    Dim sDllFile$
    objList.Clear
    If lPID = 0 Then Exit Sub
    
    hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, lPID)
    uME32.dwSize = Len(uME32)
    If Module32First(hSnap, uME32) = 0 Then
        CloseHandle hSnap
        Exit Sub
    End If
    
    Do
        sDllFile = TrimNull(uME32.szExePath)
        objList.AddItem sDllFile
    Loop Until Module32Next(hSnap, uME32) = 0
    CloseHandle hSnap
End Sub

Public Sub SaveProcessList(objProcess As ListBox, objDLL As ListBox, Optional bDoDLLs As Boolean = False)
    Dim sFileName$, i&, sProcess$, sModule$, ff%
    'Save process list to file.., Text files, All files
    sFileName = CmnDlgSaveFile(Translate(166), Translate(167) & " (*.txt)|*.txt|" & Translate(168) & " (*.*)|*.*", "processlist.txt")
    If sFileName = vbNullString Then Exit Sub
    
    On Error Resume Next
    ff = FreeFile()
    Open sFileName For Output As #ff
        'Process list saved on [*DateTime*]
        Print #ff, Replace$(Translate(169), "[*DateTime*]", Format(time, "Long Time") & ", " & Format(Date, "Short Date"))
        'Platform
        Print #ff, Translate(185) & ": " & sWinVersion & vbCrLf
        '[full path to filename]
        '[file version]
        '[company name]
        Print #ff, "[pid]" & vbTab & Translate(186) & vbTab & vbTab & Translate(187) & vbTab & Translate(188)
        For i = 0 To objProcess.ListCount - 1
            sProcess = objProcess.List(i)
            Print #ff, sProcess & vbTab & vbTab & _
                      GetFilePropVersion(Mid$(sProcess, InStr(sProcess, vbTab) + 1)) & vbTab & _
                      GetFilePropCompany(Mid$(sProcess, InStr(sProcess, vbTab) + 1))
        Next i
       
        If bDoDLLs Then
            Dim arList() As String, J&, lPID&       'Full image. DLLs of ALL processes.
            
            For i = 0 To objProcess.ListCount - 1
                sProcess = objProcess.List(i)
                lPID = CLng(Left$(sProcess, InStr(sProcess, vbTab) - 1))
                sProcess = Mid$(sProcess, InStr(sProcess, vbTab) + 1)
                GetDLLList lPID, arList()
                'DLLs loaded by process
                Print #ff, vbCrLf & vbCrLf & Translate(189) & " [" & lPID & "] " & sProcess & ":" & vbCrLf
                '[full path to filename]
                '[file version]
                '[company name]
                Print #ff, Translate(186) & vbTab & vbTab & Translate(187) & vbTab & Translate(188)
                If IsArrDimmed(arList) Then
                    For J = 0 To UBound(arList)
                        sModule = arList(J)
                        Print #ff, sModule & vbTab & vbTab & GetFilePropVersion(sModule) & vbTab & GetFilePropCompany(sModule)
                    Next
                End If
                Print #ff, vbNullString
                DoEvents
            Next
        End If

    Close #ff
    
    ShellExecute 0&, StrPtr("open"), StrPtr(sFileName), 0&, 0&, 1&
End Sub

Public Sub CopyProcessList(objProcess As ListBox, objDLL As ListBox, Optional bDoDLLs As Boolean = False)
    Dim i&, sList$, sProcess$, sModule$
    
    On Error Resume Next
    'Process list saved on [*DateTime*]
    'Platform
    '[full path to filename]
    '[file version]
    '[company name]
    sList = Replace$(Translate(169), "[*DateTime*]", Format(time, "Long Time") & ", " & Format(Date, "Short Date")) & vbCrLf & _
            Translate(185) & ": " & sWinVersion & vbCrLf & vbCrLf & _
            "[pid]" & vbTab & Translate(186) & vbTab & vbTab & Translate(187) & vbTab & Translate(188) & vbCrLf
    For i = 0 To objProcess.ListCount - 1
        sProcess = objProcess.List(i)
        sList = sList & sProcess & vbTab & vbTab & _
                GetFilePropVersion(Mid$(sProcess, InStr(sProcess, vbTab) + 1)) & vbTab & _
                GetFilePropCompany(Mid$(sProcess, InStr(sProcess, vbTab) + 1)) & vbCrLf
    Next i
    
    If bDoDLLs Then
        sProcess = objProcess.List(objProcess.ListIndex)
        sProcess = Mid$(sProcess, InStr(sProcess, vbTab) + 1)
        'DLLs loaded by process
        '[full path to filename]
        '[file version]
        '[company name]
        sList = sList & vbCrLf & vbCrLf & Translate(189) & " " & sProcess & ":" & vbCrLf & vbCrLf & _
                Translate(186) & vbTab & vbTab & Translate(187) & vbTab & Translate(188) & vbCrLf
        For i = 0 To objDLL.ListCount - 1
            sModule = objDLL.List(i)
            sList = sList & sModule & vbTab & vbTab & GetFilePropVersion(sModule) & vbTab & GetFilePropCompany(sModule) & vbCrLf
        Next i
    End If
    
    Clipboard.Clear
    Clipboard.SetText sList
    If bDoDLLs Then
        'The process list and dll list have been copied to your clipboard.
        MsgBoxW Translate(1650), vbInformation
    Else
        'The process list has been copied to your clipboard.
        MsgBoxW Translate(1651), vbInformation
    End If
End Sub

Private Sub SetListBoxColumns(objListBox As ListBox)
    Dim lTabStop&(1)
    On Error GoTo 0:
    lTabStop(0) = 70
    lTabStop(1) = 0
    SendMessage objListBox.hWnd, LB_SETTABSTOPS, UBound(lTabStop), lTabStop(0)
End Sub

Private Sub chkProcManShowDLLs_Click()
    lstProcManDLLs.Visible = CBool(chkProcManShowDLLs.value)
    On Error Resume Next
    'lstProcessManager.ListIndex = 0
    lstProcessManager_MouseUp 1, 0, 0, 0
    lstProcessManager.SetFocus
    Form_Resize
End Sub

Private Sub cmdProcManBack_Click()
    Unload Me
End Sub

Private Sub cmdProcManKill_Click()
    Dim sMsg$, i&, s$, HasSelectedProcess As Boolean
    sMsg = Translate(179) & vbCrLf
    'sMsg = "Are you sure you want to close the selected processes?" & vbCrLf
    For i = 0 To lstProcessManager.ListCount - 1
        If lstProcessManager.Selected(i) Then
            sMsg = Replace$(sMsg, "[]", vbCrLf & Mid$(lstProcessManager.List(i), InStr(lstProcessManager.List(i), vbTab) + 1))
            HasSelectedProcess = True
        End If
    Next i
    'sMsg = sMsg & vbCrLf & "Any unsaved data in it will be lost."
    If HasSelectedProcess Then
        sMsg = sMsg & vbCrLf & Translate(180)
        If MsgBoxW(sMsg, vbExclamation + vbYesNo) = vbNo Then Exit Sub
    Else
        MsgBoxW Translate(184), vbExclamation
        Exit Sub
    End If
    
    'SetCurrentProcessPrivileges "SeDebugPrivilege"
    
    'pause selected processes
    For i = 0 To lstProcessManager.ListCount - 1
        If lstProcessManager.Selected(i) Then
            s = lstProcessManager.List(i)
            s = Left$(s, InStr(s, vbTab) - 1)
            PauseProcess CLng(s)
        End If
    Next i
    For i = 0 To lstProcessManager.ListCount - 1
        If lstProcessManager.Selected(i) Then
            s = lstProcessManager.List(i)
            s = Left$(s, InStr(s, vbTab) - 1)
            If bIsWinNT Then
                KillProcessNT CLng(s)
            Else
                KillProcess CLng(s)
            End If
        End If
    Next i
    Sleep 1000
    'resume any processes still alive
    For i = 0 To lstProcessManager.ListCount - 1
        If lstProcessManager.Selected(i) Then
            s = lstProcessManager.List(i)
            s = Left$(s, InStr(s, vbTab) - 1)
            ResumeProcess CLng(s)
        End If
    Next i
    
    cmdProcManRefresh_Click
End Sub

Private Sub cmdProcManRefresh_Click()
    lstProcessManager.Clear
    If Not bIsWinNT Then
        RefreshProcessList lstProcessManager
    Else
        RefreshProcessListNT lstProcessManager
        lstProcessManager.ListIndex = 0
        If lstProcManDLLs.Visible Then
            Dim s$
            s = lstProcessManager.List(lstProcessManager.ListIndex)
            s = Left(s, InStr(s, vbTab) - 1)
            If Not bIsWinNT Then
                RefreshDLLList CLng(s), lstProcManDLLs
            Else
                RefreshDLLListNT CLng(s), lstProcManDLLs
            End If
        End If
    End If
    'Running processes:
    lblConfigInfo(8).Caption = Translate(171) & " (" & lstProcessManager.ListCount & ")"
    'Loaded DLL libraries by selected process:
    lblConfigInfo(9).Caption = Translate(178) & " (" & lstProcManDLLs.ListCount & ")"
End Sub

Private Sub cmdProcManRun_Click()
    If Not bIsWinNT Then
        SHRunDialog Me.hWnd, 0, 0, Translate(181), Translate(182), 0
        'SHRunDialog Me.hWnd, 0, 0, "Run", "Type the name of a program, folder, document or Internet resource, and Windows will open it for you.", 0
    Else
        SHRunDialog Me.hWnd, 0, 0, StrConv(Translate(181), vbUnicode), StrConv(Translate(182), vbUnicode), 0
        'SHRunDialog Me.hWnd, 0, 0, StrConv("Run", vbUnicode), StrConv("Type the name of a program, folder, document or Internet resource, and Windows will open it for you.", vbUnicode), 0
    End If
    Sleep 1000
    cmdProcManRefresh_Click
End Sub

Private Sub Form_Load()
    ReloadLanguage
    Me.Height = 7215
    'Process Manager
    Me.Caption = Translate(170)
    cmdProcManRefresh_Click
    'Itty Bitty Process Manager - v
    fraProcessManager.Caption = Translate(160) & ProcManVer 'App.Major & "." & Format(App.Minor, "00") & "." & App.Revision
    SetListBoxColumns lstProcessManager
    AddHorizontalScrollBarToResults lstProcessManager
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button = 1 Then
        ReleaseCapture
        SendMessage Me.hWnd, WM_NCLBUTTONDOWN, HTCAPTION, 0
    End If
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    If Me.WindowState = vbMinimized Then Exit Sub
    fraProcessManager.Width = Me.ScaleWidth - 240
    lstProcessManager.Width = Me.ScaleWidth - 480
    lstProcManDLLs.Width = Me.ScaleWidth - 480
    chkProcManShowDLLs.Left = Me.ScaleWidth - 2200
    imgProcManSave.Left = Me.ScaleWidth - 2700
    imgProcManCopy.Left = Me.ScaleWidth - 3100

    fraProcessManager.Height = Me.ScaleHeight - 125
    If chkProcManShowDLLs.value = 0 Then
        lstProcessManager.Height = Me.ScaleHeight - 1470
    Else
        lstProcessManager.Height = (Me.ScaleHeight - 1470) / 2 - 120
        lblConfigInfo(9).Top = (Me.ScaleHeight - 1470) / 2 + 480
        lstProcManDLLs.Top = (Me.ScaleHeight - 1470) / 2 + 720
        lstProcManDLLs.Height = Me.ScaleHeight - 1590 - (Me.ScaleHeight - 1470) / 2
    End If
    cmdProcManKill.Top = Me.ScaleHeight - 720
    cmdProcManRefresh.Top = Me.ScaleHeight - 720
    cmdProcManRun.Top = Me.ScaleHeight - 720
    cmdProcManBack.Top = Me.ScaleHeight - 720
    lblProcManDblClick.Top = Me.ScaleHeight - 720
End Sub

Private Sub fraProcessManager_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ReleaseCapture
    SendMessage Me.hWnd, WM_NCLBUTTONDOWN, HTCAPTION, 0
End Sub

Private Sub imgProcManCopy_Click()
    imgProcManCopy.BorderStyle = 1
    DoEvents
    If chkProcManShowDLLs.value = 1 Then
        CopyProcessList lstProcessManager, lstProcManDLLs, True
    Else
        CopyProcessList lstProcessManager, lstProcManDLLs, False
    End If
    imgProcManCopy.BorderStyle = 0
End Sub

Private Sub imgProcManSave_Click()
    imgProcManSave.BorderStyle = 1
    DoEvents
    If chkProcManShowDLLs.value = 1 Then
        SaveProcessList lstProcessManager, lstProcManDLLs, True
    Else
        SaveProcessList lstProcessManager, lstProcManDLLs, False
    End If
    imgProcManSave.BorderStyle = 0
End Sub

Private Sub lstProcessManager_Click()
    If lstProcManDLLs.Visible = False Then Exit Sub
    Dim s$
    If lstProcessManager.ListIndex = -1 Then lstProcessManager.ListIndex = 0: lstProcessManager.Selected(0) = True
    s = lstProcessManager.List(lstProcessManager.ListIndex)
    s = Left$(s, InStr(s, vbTab) - 1)
    If Not bIsWinNT Then
        RefreshDLLList CLng(s), lstProcManDLLs
    Else
        RefreshDLLListNT CLng(s), lstProcManDLLs
    End If
    lblConfigInfo(9).Caption = Translate(178) & " (" & lstProcManDLLs.ListCount & ")"
    'lblConfigInfo(9).Caption = "Loaded DLL libraries by selected process: (" & lstProcManDLLs.ListCount & ")"
End Sub

Private Sub lstProcessManager_DblClick()
    Dim s$
    If lstProcessManager.ListIndex = -1 Then
        If lstProcessManager.ListCount <> 0 Then s = lstProcessManager.List(0) Else Exit Sub
    Else
        s = lstProcessManager.List(lstProcessManager.ListIndex)
    End If
    s = Mid$(s, InStr(s, vbTab) + 1)
    ShowFileProperties s, Me.hWnd
End Sub

Private Sub lstProcManDLLs_DblClick()
    Dim s$
    If lstProcManDLLs.ListIndex = -1 Then
        If lstProcManDLLs.ListCount <> 0 Then s = lstProcManDLLs.List(0) Else Exit Sub
    Else
        s = lstProcManDLLs.List(lstProcManDLLs.ListIndex)
    End If
    s = Mid$(s, InStr(s, vbTab) + 1)
    ShowFileProperties s, Me.hWnd
End Sub

Private Sub lstProcManDLLs_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = 13 Then lstProcManDLLs_DblClick
End Sub

Private Sub lstProcessManager_KeyDown(KeyCode As Integer, Shift As Integer)
    Select Case KeyCode
        Case 13: lstProcessManager_DblClick
        Case 33, 34, 35, 36, 37, 38, 40: lstProcessManager_MouseUp 1, 0, 0, 0
    End Select
End Sub

Private Sub lstProcessManager_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button = 1 Then
        If lstProcManDLLs.Visible = False Then Exit Sub
        Dim s$
        s = lstProcessManager.List(lstProcessManager.ListIndex)
        s = Left(s, InStr(s, vbTab) - 1)
        If Not bIsWinNT Then
            RefreshDLLList CLng(s), lstProcManDLLs
        Else
            RefreshDLLListNT CLng(s), lstProcManDLLs
        End If
        'Loaded DLL libraries by selected process:
        lblConfigInfo(9).Caption = Translate(178) & " (" & lstProcManDLLs.ListCount & ")"
    ElseIf Button = 2 Then
        PopupMenu mnuProcMan, , , , mnuProcManProps
    End If
End Sub

Private Sub lstProcManDLLs_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button = 2 Then
        mnuProcManKill.Enabled = False
        PopupMenu mnuProcMan, , , , mnuProcManProps
        mnuProcManKill.Enabled = True
    End If
End Sub

Private Sub mnuProcManCopy_Click()
    imgProcManCopy_Click
End Sub

Private Sub mnuProcManKill_Click()
    cmdProcManKill_Click
End Sub

Private Sub lstProcessManager_LostFocus()
    lstProcessManagerHasFocus = False
End Sub
Private Sub lstProcessManager_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Not lstProcessManagerHasFocus Then
        lstProcessManagerHasFocus = True
        'lstProcessManager.SetFocus
    End If
End Sub

Private Sub mnuProcManProps_Click()
    If lstProcessManagerHasFocus Then
        lstProcessManager_DblClick
    Else
        lstProcManDLLs_DblClick
    End If
End Sub

Private Sub mnuProcManSave_Click()
    imgProcManSave_Click
End Sub
