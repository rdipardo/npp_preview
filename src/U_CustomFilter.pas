unit U_CustomFilter;

{$ifdef FPC}{$mode delphiunicode}{$endif}

////////////////////////////////////////////////////////////////////////////////////////////////////
interface
uses
  Classes, Windows, SysUtils;

type
{$ifdef FPC}
  TFileName = UnicodeString;
{$endif}

  {--- 2013-01-26 Martijn: TFilterData contains all the information needed for the filter to do its
                            job (in a different thread, so the filter processing becomes thread-safe). ---}
  TFilterData = record
    Name: {$ifdef FPC} Ansistring {$else} string {$endif};
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
    procedure DoSynchronize;
  public
    constructor Create(const Data: TFilterData); reintroduce;
    destructor  Destroy; override;
    procedure Execute; override;
    function StripBom(const Text: string): string;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////
implementation

uses
  process, Pipes,
{$ifndef FPC}
  IOUtils
{$else}
  ProcessUnicode
{$endif},
  Debug,
  F_PreviewHTML;

{ TCustomFilterThread }

{ ------------------------------------------------------------------------------------------------ }
constructor TCustomFilterThread.Create(const Data: TFilterData);
begin
  FData := Data;
  Self.OnTerminate := Data.OnTerminate;
  inherited Create(False);
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
  hIniFile, hOutFile: THandle;
  sIniFile, sOutFile: THandleStream;
//  i: Integer;
begin
//ODS('Data.FilterInfo.Count = "%d"', [FData.FilterInfo.Count]);
//for i := 0 to FData.FilterInfo.Count - 1 do begin
//  ODS('Data.FilterInfo[%d] = "%s"', [i, FData.FilterInfo.Strings[i]]);
//end;
  try
    Command := {$ifdef FPC}UTF8ToString{$endif}(FData.FilterInfo.Values['Command']);
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
        OutFile := {$ifndef FPC}TPath.GetTempFileName{$else}UTF8toString(GetTempFileName){$endif}
      else
        OutFile := '';
    end else begin // ContentInput = citFile
      Input := nil;
      if FData.Modified or (OutputMethod = cotInputFile) then begin
        TempFile := {$ifndef FPC}TPath.GetTempFileName{$else}UTF8toString(GetTempFileName){$endif};
        // rename the TempFile so it has the proper extension
        InFile := ChangeFileExt(TempFile, ExtractFileExt(FData.DocFile));
        if not RenameFile(TempFile, InFile) then
          InFile := TempFile;
        // Save the contents to the input file
        SS := TStringStream.Create(FData.Contents, FData.Encoding, False);
        try
          hIniFile := FileCreate(InFile);
          if (hIniFile <> THandle(-1)) then begin
            sIniFile := THandleStream.Create(hIniFile);
            SS.SaveToStream(sIniFile);
            FileClose(sIniFile.Handle);
            sIniFile.Free;
          end;
        finally
          SS.Free;
        end;
      end else begin
        // Use the original file as input file
        InFile := FData.DocFile;
      end;
      case OutputMethod of
        cotInputFile:   OutFile := InFile;
        cotOutputFile:  OutFile := {$ifndef FPC}TPath.GetTempFileName{$else}UTF8toString(GetTempFileName){$endif};
      end;
    end;

    if Terminated then
      Exit;

    if InFile = '' then
      WorkingDir := ExtractFilePath(FData.DocFile)
    else
      WorkingDir := ExtractFilePath(InFile);

    // Perform replacements in the command string
    Command := {$ifdef FPC}UnicodeStringReplace{$else}StringReplace{$endif}(Command, '%1', InFile, [rfReplaceAll]);
    Command := {$ifdef FPC}UnicodeStringReplace{$else}StringReplace{$endif}(Command, '%2', OutFile, [rfReplaceAll]);
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
          HTML := StripBom(Output.{$ifdef FPC}UnicodeDataString{$else}DataString{$endif});
          if Length(HTML) = 0 then
            HTML := '<pre style="color: darkred">' +
                {$ifdef FPC}UnicodeStringReplace{$else}StringReplace{$endif}(
                  Error.{$ifdef FPC}UnicodeDataString{$else}DataString{$endif},
                  '<', '&lt;', [rfReplaceAll]) +
                '</pre>';
        end;
        cotInputFile, cotOutputFile: begin
          SS := TStringStream.Create('', FData.Encoding, False);
          try
            hOutFile := FileOpen(OutFile, fmOpenReadWrite or fmShareExclusive);
            if (hOutFile <> THandle(-1)) then begin
              sOutFile := THandleStream.Create(hOutFile);
              SS.LoadFromStream(sOutFile);
              FileClose(sOutFile.Handle);
              sOutFile.Free;
            end;
            HTML := StripBom(SS.{$ifdef FPC}UnicodeDataString{$else}DataString{$endif});
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
      ContentStream.Text := HTML;
      Synchronize(DoSynchronize);
    end;

ODS('Cleaning up...');
    frmHTMLPreview.sbrIE.Panels[0].Text := 'Done';
    // Delete the temporary files
    if (InFile <> '') and not WideSameText(FData.DocFile, OutFile) then
      DeleteFile(OutFile);
    if (InFile <> '') and not WideSameText(InFile, FData.DocFile) then
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

function TCustomFilterThread.StripBom(const Text: string): string;
const
  BOM: TBytes = [ $EF, $BF, $BD ];
begin
  Result := {$ifdef FPC}UnicodeStringReplace{$else}StringReplace{$endif}(Text, FData.Encoding.GetString(BOM), '', [rfReplaceAll]);
end;

procedure TCustomFilterThread.DoSynchronize;
begin
ODS('Synchronizing HTML of length %d in thread ID [%x]', [Length(ContentStream.Text), GetCurrentThreadID]);
  if not frmHTMLPreview.UpdatePreview(FData.BufferID) then
    frmHTMLPreview.DisplayPreview(FData.BufferID);
end;

end.
