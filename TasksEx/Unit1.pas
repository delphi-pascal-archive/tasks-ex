unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    btRunTask1: TButton;
    btRunTask2: TButton;
    btRunTask3: TButton;
    btRunTask4: TButton;
    ProgressBar: TProgressBar;
    Label1: TLabel;
    Memo: TMemo;
    btStopTask1: TButton;
    btStopTask2: TButton;
    btStopTask3: TButton;
    btStopLastTask: TButton;
    btStopAllTasks: TButton;
    btClearMemo: TButton;
    procedure btRunTask1Click(Sender: TObject);
    procedure btRunTask2Click(Sender: TObject);
    procedure btRunTask3Click(Sender: TObject);
    procedure btRunTask4Click(Sender: TObject);
    procedure btStopTask1Click(Sender: TObject);
    procedure btStopTask2Click(Sender: TObject);
    procedure btStopTask3Click(Sender: TObject);
    procedure btStopLastTaskClick(Sender: TObject);
    procedure btStopAllTasksClick(Sender: TObject);
    procedure btClearMemoClick(Sender: TObject);
  private
    { Private declarations }
    // �������������� ���������� ����� ��� �� ���������
    Task1, Task2, Task3: Cardinal;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  TasksEx, AsyncCalls;

{$R *.dfm}

procedure TForm1.btClearMemoClick(Sender: TObject);
begin
  Memo.Clear;
end;

procedure TForm1.btRunTask1Click(Sender: TObject);

  procedure EnumFiles(const AFolder: String; AFiles: TStringList);
  var
    SR: TSearchRec;
    S: String;
  begin
    if FindFirst(AFolder + '*.*', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          S := AFolder + SR.Name;
          if DirectoryExists(S) then
            EnumFiles(S + '\', AFiles)
          else
            AFiles.Add(S);
        end;
        // ���������, �� ����� �� ������������ ������ "������"
        CheckAbort;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

var
  Str: TStringList;
begin
  // �.�. ������ �� ������ ����� ��������� � ������ ������,
  // ������������ ����� ������ �������� �� ��� �� ������,
  // ���� ��� Button1Click ��� �� ����������.
  // ����� ����� �� ���������, �� ��������� ������.
  btRunTask1.Enabled := False;
  // �������� ����� � Button4, �.�. ��� ��������� � Memo, ������ �� ������ � ������� ������
  btRunTask4.Enabled := False;
  // ������� ������ ��������� ������
  btStopTask1.Enabled := True;
  try
    Str := TStringList.Create;
    try
      Memo.Lines.Add('������ 1: ��������');
      Task1 := EnterWorkerThread;
      try
        // ��� ����� ���� ����������� ��� �� ��������� ������
        // ���� ����������� EnumFiles, ������������ ����� ��������� ������ �������.
        EnumFiles('C:\', Str);
      finally
        Task1 := 0;
        LeaveWorkerThread;
        Memo.Lines.Add('������ 1: �����������');
      end;
      // ������� ��������� ������ � Memo. ��� ������ �������� ������ �� ������� (� ��� ���������� ����������)
      Memo.Lines.Add('������ 1: ������� ' + IntToStr(Str.Count) + ' ������');
    finally
      FreeAndNil(Str);
    end;
  finally
    btRunTask1.Enabled := True;
    btRunTask4.Enabled := True;
    btStopTask1.Enabled := False;
  end;
end;

procedure TForm1.btRunTask2Click(Sender: TObject);
var
  X: Integer;
begin
  Memo.Lines.Add('������ 2: ��������');
  Task2 := EnterWorkerThread;
  try
    for X := 1 to 10 do
    begin
      Sleep(500);
      CheckAbort;
    end;
  finally
    Task2 := 0;
    LeaveWorkerThread;
    Memo.Lines.Add('������ 2: �����������');
  end;
end;

procedure TForm1.btRunTask3Click(Sender: TObject);
var
  X: Integer;
begin
  Memo.Lines.Add('������ 3: ��������');
  Task3 := EnterWorkerThread;
  try
    for X := 0 to 99 do
    begin
      Sleep(100); // ���-�� ������
      // ������� ����� �������� ������� ����������� ������
      EnterMainThread;
      try
        ProgressBar.StepIt; // ��� ������������ � VCL �� ������ ���� � ������� ������
      finally
        LeaveMainThread;
      end;
      Sleep(100); // ��� ���-�� ������
      CheckAbort;
    end;
  finally
    Task3 := 0;
    LeaveWorkerThread;
    Memo.Lines.Add('������ 3: �����������');
  end;
end;

procedure TForm1.btRunTask4Click(Sender: TObject);
begin
  Memo.Clear;
  Memo.Lines.Add('Before try1 TID = ' + IntToStr(GetCurrentThreadId));
  try
    Memo.Lines.Add('Inside try1 TID = ' + IntToStr(GetCurrentThreadId));
    Memo.Lines.Add('Before EnterWorkerThread TID = ' + IntToStr(GetCurrentThreadId));
    EnterWorkerThread;
    // ��� ����������� �� ��������� ������, ������� ��������� � Memo �����������
    // �� ��� �������� ������� ��� ��� ����� � ���, � ��� ����� ������� ������ ���-�� �����������
    Memo.Lines.Add('After EnterWorkerThread TID = ' + IntToStr(GetCurrentThreadId));
    try
      Memo.Lines.Add('Inside try2 TID = ' + IntToStr(GetCurrentThreadId));
      Memo.Lines.Add('Before EnterMainThread TID = ' + IntToStr(GetCurrentThreadId));
      EnterMainThread;
      Memo.Lines.Add('After EnterMainThread TID = ' + IntToStr(GetCurrentThreadId));
      try
        Memo.Lines.Add('Inside try3 TID = ' + IntToStr(GetCurrentThreadId));
        if Application.MessageBox('��������� ����������?', 'Q', MB_YESNO) = mrYes then
          raise Exception.Create('�������� ����������.');
      finally
        Memo.Lines.Add('Before LeaveMainThread TID = ' + IntToStr(GetCurrentThreadId));
        LeaveMainThread;
        Memo.Lines.Add('After LeaveMainThread TID = ' + IntToStr(GetCurrentThreadId));
      end;
      Memo.Lines.Add('After try3/finally3 TID = ' + IntToStr(GetCurrentThreadId));
    finally
      Memo.Lines.Add('Before LeaveWorkerThread TID = ' + IntToStr(GetCurrentThreadId));
      LeaveWorkerThread;
      Memo.Lines.Add('After LeaveWorkerThread TID = ' + IntToStr(GetCurrentThreadId));
    end;
    Memo.Lines.Add('After try2/finally2 TID = ' + IntToStr(GetCurrentThreadId));
  finally
    Memo.Lines.Add('Inside finally1 TID = ' + IntToStr(GetCurrentThreadId));
  end;
  Memo.Lines.Add('After try1/finally1 TID = ' + IntToStr(GetCurrentThreadId));
end;

procedure TForm1.btStopAllTasksClick(Sender: TObject);
begin
  AbortAllWorkerThreads;
end;

procedure TForm1.btStopLastTaskClick(Sender: TObject);
begin
  AbortLastWorkerThread;
end;

procedure TForm1.btStopTask1Click(Sender: TObject);
begin
  if Task1 <> 0 then
  begin
    Memo.Lines.Add('������ 1: ������� ���������');
    AbortWorkerThread(Task1);
    Task1 := 0;
  end;
  btStopTask1.Enabled := False;
end;

procedure TForm1.btStopTask2Click(Sender: TObject);
begin
  if Task2 <> 0 then
  begin
    Memo.Lines.Add('������ 2: ������� ���������');
    AbortWorkerThread(Task2);
    Task2 := 0;
  end;
end;

procedure TForm1.btStopTask3Click(Sender: TObject);
begin
  if Task3 <> 0 then
  begin
    Memo.Lines.Add('������ 3: ������� ���������');
    AbortWorkerThread(Task3);
    Task3 := 0;
  end;
end;

end.
