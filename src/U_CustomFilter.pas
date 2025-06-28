unit U_CustomFilter;

////////////////////////////////////////////////////////////////////////////////////////////////////
interface
uses
  Classes, Windows, SysUtils;

type
  {--- 2013-01-26 Martijn: TFilterData contains all the information needed for the filter to do its
                            job (in a different thread, so the filter processing becomes thread-safe). ---}
  TFilterData = record
    Name: string;
    DocFile: TFileName;
    BufferID: NativeInt;
    Contents: string;
    Encoding: TEncoding;
    UseBOM: Boolean;
    Modified: Boolean;
    FilterInfo: TStringList; // the contents of the filter
    OnTerminate: TNotifyEvent;
  end;

type
  TCustomFilterThread = class(TThread)
  private
    FData: TFilterData;
    function Run(const Command, WorkingDir: string; const Input, Output, Error: TStream): NativeInt;
  public
    constructor Create(const Data: TFilterData); reintroduce;
    destructor  Destroy; override;
    procedure Execute; override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////
implementation

uses
  IOUtils,
  process, Pipes,
  Debug,
  F_PreviewHTML;

{ TCustomFilterThread }

{ ------------------------------------------------------------------------------------------------ }
constructor TCustomFilterThread.Create(const Data: TFilterData);
begin
  FData := Data;
  Self.OnTerminate := Data.OnTerminate;
  inherited Create;
end {TCustomFilter.Create};

{ ------------------------------------------------------------------------------------------------ }
destructor TCustomFilterThread.Destroy;
begin
  FreeAndNil(FData.FilterInfo);
  inherited;
end {TCustomFilterThread.Destroy};

{ ------------------------------------------------------------------------------------------------ }
procedure TCustomFilterThread.Execute;
type
  TContentInputType = (citStandardInput, citFile);
  TContentOutputType = (cotStandardOutput, cotInputFile, cotOutputFile);
var
  HTML: string;
  Command: string;
  TempFile, InFile, OutFile, WorkingDir: TFileName;
  SS: TStringStream;
  InputMethod: TContentInputType;
  OutputMethod: TContentOutputType;
  Input, Output, Error: TStringStream;
//  i: Integer;
begin
//ODS('Data.FilterInfo.Count = "%d"', [FData.FilterInfo.Count]);
//for i := 0 to FData.FilterInfo.Count - 1 do begin
//  ODS('Data.FilterInfo[%d] = "%s"', [i, FData.FilterInfo.Strings[i]]);
//end;
  try
    Command := FData.FilterInfo.Values['Command'];
//ODS('Command: "%s"', [Command]);
    if Command = '' then begin
      HTML := FData.Contents;
      Exit;
    end;


    // Decide what the input and output methods are
    if Pos('%1', Command) > 0 then begin
      InputMethod := citFile;
    end else begin
      InputMethod := citStandardInput;
    end;
    if Pos('%2', Command) > 0 then begin
      OutputMethod := cotOutputFile;
    end else begin
      OutputMethod := cotStandardOutput;
    end;

    {$MESSAGE HINT 'TODO: allow for explicit overrides in the filter settings — Martijn 2013-01-26'}

    if Terminated then
      Exit;

    {--- Now we figure out what in- and output files we will need ---}
    if InputMethod = citStandardInput then begin
      InFile := '';
      Input := TStringStream.Create(FData.Contents, FData.Encoding, False);
      if OutputMethod = cotInputFile then begin
        OutputMethod := cotStandardOutput;
        {$MESSAGE HINT 'TODO: warn the user that this filter is misconfigured — Martijn 2013-01-26'}
      end;
      if OutputMethod = cotOutputFile then
        OutFile := TPath.GetTempFileName
      else
        OutFile := '';
    end else begin // ContentInput = citFile
      Input := nil;
      if FData.Modified or (OutputMethod = cotInputFile) then begin
        TempFile := TPath.GetTempFileName;
        // rename the TempFile so it has the proper extension
        InFile := ChangeFileExt(TempFile, ExtractFileExt(FData.DocFile));
        if not RenameFile(TempFile, InFile) then
          InFile := TempFile;
        // Save the contents to the input file
        SS := TStringStream.Create(FData.Contents, FData.Encoding, False);
        try
          SS.SaveToFile(InFile);
        finally
          SS.Free;
        end;
      end else begin
        // Use the original file as input file
        InFile := FData.DocFile;
      end;
      case OutputMethod of
        cotInputFile:   OutFile := InFile;
        cotOutputFile:  OutFile := TPath.GetTempFileName;
      end;
    end;

    if Terminated then
      Exit;

    if InFile = '' then
      WorkingDir := ExtractFilePath(FData.DocFile)
    else
      WorkingDir := ExtractFilePath(InFile);

    // Perform replacements in the command string
    Command := StringReplace(Command, '%1', InFile, [rfReplaceAll]);
    Command := StringReplace(Command, '%2', OutFile, [rfReplaceAll]);
    // TODO: also replace environment strings?

    if OutFile = '' then begin
      Output := TStringStream.Create('', FData.Encoding, False);
    end else begin
      Output := nil;
    end;
    Error := TStringStream.Create('', CP_OEMCP);
    try
ODS('Command="%s"; WorkingDir="%s"; InFile="%s"; OutFile="%s"', [Command, WorkingDir, InFile, OutFile]);

      // Run the command and keep track of the new process
      Run(Command, WorkingDir, Input, Output, Error);

      if Terminated then
        Exit;

      case OutputMethod of
        cotStandardOutput: begin
          // read the output from the process's standard output stream
          HTML := TStringStream(Output).DataString;
          if Length(HTML) = 0 then
            HTML := '<pre style="color: darkred">' + StringReplace(Error.DataString, '<', '&lt;', [rfReplaceAll]) + '</pre>';
        end;
        cotInputFile, cotOutputFile: begin
          SS := TStringStream.Create('', FData.Encoding, False);
          try
            SS.LoadFromFile(OutFile);
            HTML := SS.DataString;
          finally
            SS.Free;
          end;
        end;
      end;
    finally
      FreeAndNil(Input);
      FreeAndNil(Output);
      FreeAndNil(Error);
    end;
  finally
    {--- When finished, we need to populate the webbrowser component, but this needs to happen in
          the main thread. ---}
    if not Terminated then begin
ODS('About to synchronize HTML of length %d in thread ID [%x]', [Length(HTML), GetCurrentThreadID]);
      Synchronize(procedure
                  begin
ODS('Synchronizing HTML of length %d in thread ID [%x]', [Length(HTML), GetCurrentThreadID]);
                    ContentStream.Text := HTML;
                    frmHTMLPreview.DisplayPreview(FData.BufferID);
                  end);
    end;

ODS('Cleaning up...');
    // Delete the temporary files
    if (InFile <> '') and not SameFileName(FData.DocFile, OutFile) then
      DeleteFile(OutFile);
    if (InFile <> '') and not SameFileName(InFile, FData.DocFile) then
      DeleteFile(InFile);
  end;
end {TCustomFilter.Execute};

{ ------------------------------------------------------------------------------------------------ }
function TCustomFilterThread.Run(const Command, WorkingDir: string; const Input, Output, Error: TStream): NativeInt;
const
  READ_BYTES = 2048;
  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  {$POINTERMATH ON}
  function CacheStream(Input: TInputPipeStream; Cache: TMemoryStream; var BytesRead: LongInt): LongInt;
  var
    CacheMem: PByte;
  begin
    if Input.NumBytesAvailable > 0 then begin
      // make sure we have room
      Cache.SetSize(BytesRead + READ_BYTES);

      // try reading it
      CacheMem := Cache.Memory;
      Inc(CacheMem, BytesRead);
      Result := Input.Read(CacheMem^, READ_BYTES);
      if Result > 0 then begin
        Inc(BytesRead, Result);
      end;
    end else begin
      Result := 0;
    end;
  end{CacheStream};
  {$POINTERMATH OFF}
  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
var
  OMS, EMS: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead, ErrBytesRead: LongInt;
begin
  // We cannot use poWaitOnExit here since we don't
  // know the size of the output. On Linux the size of the
  // output pipe is 2 kB. If the output data is more, we
  // need to read the data. This isn't possible since we are
  // waiting. So we get a deadlock here.
  //
  // A temp Memorystream is used to buffer the output

  BytesRead := 0;
  OMS := TMemoryStream.Create;
  ErrBytesRead := 0;
  EMS := TMemoryStream.Create;
  try
    P := TProcess.Create(nil);
    try
      P.CurrentDirectory := WorkingDir;
      P.CommandLine := Command;
      P.Options := P.Options + [poUsePipes];
      P.StartupOptions := [suoUseShowWindow];
      P.ShowWindow := swoHIDE;

      P.Execute;
      if P.Running and Assigned(Input) then
        P.Input.CopyFrom(Input, Input.Size);

      while P.Running do begin
        n := CacheStream(P.Output, OMS, BytesRead);
        Inc(n, CacheStream(P.Stderr, EMS, ErrBytesRead));
        if n <= 0 then begin
          // no data, wait 100 ms
          Sleep(100);
        end;

        if Self.Terminated then begin
          P.Terminate(-1);
          Exit(-1);
        end;

      end;
      // read last part
      repeat
        n := CacheStream(P.Output, OMS, BytesRead);
        Inc(n, CacheStream(P.Stderr, EMS, ErrBytesRead));
      until n <= 0;

      Result := P.ExitStatus;

      OMS.SetSize(BytesRead);
      EMS.SetSize(ErrBytesRead);
    finally
      P.Free;
    end;

    if Assigned(Output) then
      Output.CopyFrom(OMS, 0);

    if Assigned(Error) then
      Error.CopyFrom(EMS, 0);
  finally
    OMS.Free;
    EMS.Free;
  end;
end {TCustomFilterThread.Run};

end.
