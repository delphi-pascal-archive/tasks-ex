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
    // Идентификаторы запущенных задач для их остановки
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
        // Проверяем, не нажал ли пользователь кнопку "Отмена"
        CheckAbort;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

var
  Str: TStringList;
begin
  // Т.к. работу мы сейчас будем выполнять в другом потоке,
  // пользователь может нажать повторно на эту же кнопку,
  // пока код Button1Click ещё не выполнился.
  // Чтобы этого не произошло, мы блокируем кнопку.
  btRunTask1.Enabled := False;
  // Отключим также и Button4, т.к. она оперирует с Memo, причём не только в главном потоке
  btRunTask4.Enabled := False;
  // Включим кнопку остановки работы
  btStopTask1.Enabled := True;
  try
    Str := TStringList.Create;
    try
      Memo.Lines.Add('Задача 1: запущена');
      Task1 := EnterWorkerThread;
      try
        // Эта часть кода выполняется уже во вторичном потоке
        // Пока выполняется EnumFiles, пользователь может запускать другие функции.
        EnumFiles('C:\', Str);
      finally
        Task1 := 0;
        LeaveWorkerThread;
        Memo.Lines.Add('Задача 1: остановлена');
      end;
      // Выводим результат поиска в Memo. При отмене операции ничего не выводим (у нас возбуждено исключение)
      Memo.Lines.Add('Задача 1: найдено ' + IntToStr(Str.Count) + ' файлов');
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
  Memo.Lines.Add('Задача 2: запущена');
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
    Memo.Lines.Add('Задача 2: остановлена');
  end;
end;

procedure TForm1.btRunTask3Click(Sender: TObject);
var
  X: Integer;
begin
  Memo.Lines.Add('Задача 3: запущена');
  Task3 := EnterWorkerThread;
  try
    for X := 0 to 99 do
    begin
      Sleep(100); // что-то делаем
      // настало время обновить процент выполненной работы
      EnterMainThread;
      try
        ProgressBar.StepIt; // для оперирования с VCL мы должны быть в главном потоке
      finally
        LeaveMainThread;
      end;
      Sleep(100); // ещё что-то делаем
      CheckAbort;
    end;
  finally
    Task3 := 0;
    LeaveWorkerThread;
    Memo.Lines.Add('Задача 3: остановлена');
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
    // это выполняется во вторичном потоке, поэтому обращение к Memo некорректно
    // но для простого примера это нам сойдёт с рук, а это самый простой способ что-то просмотреть
    Memo.Lines.Add('After EnterWorkerThread TID = ' + IntToStr(GetCurrentThreadId));
    try
      Memo.Lines.Add('Inside try2 TID = ' + IntToStr(GetCurrentThreadId));
      Memo.Lines.Add('Before EnterMainThread TID = ' + IntToStr(GetCurrentThreadId));
      EnterMainThread;
      Memo.Lines.Add('After EnterMainThread TID = ' + IntToStr(GetCurrentThreadId));
      try
        Memo.Lines.Add('Inside try3 TID = ' + IntToStr(GetCurrentThreadId));
        if Application.MessageBox('Возбудить исключение?', 'Q', MB_YESNO) = mrYes then
          raise Exception.Create('Тестовое исключение.');
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
    Memo.Lines.Add('Задача 1: попытка остановки');
    AbortWorkerThread(Task1);
    Task1 := 0;
  end;
  btStopTask1.Enabled := False;
end;

procedure TForm1.btStopTask2Click(Sender: TObject);
begin
  if Task2 <> 0 then
  begin
    Memo.Lines.Add('Задача 2: попытка остановки');
    AbortWorkerThread(Task2);
    Task2 := 0;
  end;
end;

procedure TForm1.btStopTask3Click(Sender: TObject);
begin
  if Task3 <> 0 then
  begin
    Memo.Lines.Add('Задача 3: попытка остановки');
    AbortWorkerThread(Task3);
    Task3 := 0;
  end;
end;

end.
