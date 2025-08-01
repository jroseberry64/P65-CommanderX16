////////////////////////////////////////////
// New program created in 7/6/2025}
////////////////////////////////////////////

// TESTED: 
//
// K_PLOT_Set/Get  
// K_SETLFS
// K_SETNAM
// K_SAVE
// K_LOAD
// K_CHROUT
// StringLenNT
// GoToScreenXY
// ClearScreen
// PrintStr
// DOS_ExecComm
// DOS_Scratch
// K_CHKIN
// K_LISTEN
// K_SECOND
// K_UNLSN
// K_CLRCHN


program NewProgram;
uses CX16Kernal;
var
  IntroStr: ARRAY [] of char = 'CX16KERNAL TST';
  
  Tst1FailStr: ARRAY [] of char = 'TST-KPLOT FAILED';
  Tst2FailStr: ARRAY [] of char = 'TST2-KCHROUT FAILED';
  Tst3FailStr: ARRAY [] of char = 'TST3-KSAVE FAILED';
  Tst4FailStr: ARRAY [] of char = 'TST4-KLOAD FAILED';
  Tst5FailStr: ARRAY [] of char = 'TST5-CMP-LOAD-SAVE-F FAILED';
  Tst6FailStr: ARRAY [] of char = 'TST6-STRINGLENNT FAILED';
  
  AllTestsPassStr: ARRAY [] of char = 'ALL TESTS PASSED';
  
  TstSaveFileName: ARRAY [] of char = 'TST1.BIN';
  
  TstSaveFile: ARRAY [] of char = 'ABCDEFGHIJKLMNOP';
  TstLoadFile: [17]char;
  
  AllTestsPassed: boolean;
  
  i, NumTstsFailed: byte;   

// Test K_CHROUT
procedure TestK_CHROUT: boolean;
begin 
  GoToScreenXY(0,0);
  for i:=0 to IntroStr.length - 1 do
    K_CHROUT(IntroStr[i]);
  end;
  exit(true);
end;

// Tests K_PLOT set and get versions
procedure TestK_PLOT: boolean;
var 
  ResMatch1: boolean;
  ResMatch2: boolean;
  Ret:       RetXY;
begin 
  GoToScreenXY(3, 5);
  Ret := K_PLOT_Get;
  
  ResMatch1 := Ret.low = 3;
  ResMatch2 := Ret.high = 5;
  if ResMatch1 and ResMatch2 then 
    exit(true);
  else 
    exit(false);
  end;
end;

// Tests K_SAVE with a dummy file that
// will be reused in testing K_LOAD. Also
// tests K_SETLFS and K_SETNAM for free.
procedure TestK_SAVE: boolean;
var
  LFN:          byte = 8;
  FileStartPtr: word;
  FileEndPtr:   word;
  FileNamePtr:  word;
  r0Offset:     byte = 2;
  ResB:         boolean;
begin
  // Setup variables to call K_SAVE
  FileStartPtr := @TstSaveFile;
  FileEndPtr   := FileStartPtr + 16;
  FileNamePtr  := @TstSaveFileName;
  
  r0 := FileStartPtr;
  
  // Setup call to K_SAVE
  K_SETLFS(1, LFN, 0);
  K_SETNAM(TstSaveFileName.length, FileNamePtr.low, FileNamePtr.high);
  
  ResB := K_SAVE(r0Offset, FileEndPtr.low, FileEndPtr.high);
  
  exit(ResB);
end; 

// Tests K_LOAD with a dummy file that
// was created during testing K_LOAD. Also
// tests K_SETLFS and K_SETNAM for free.
procedure TestK_LOAD: boolean;
const
  LFN:          byte = 8;
  Load:         byte = 0;
var
  FileStartPtr: word;
  FileNamePtr:  word;
  ResB:         boolean;
begin
  // Setup variables to call K_LOAD
  FileStartPtr := @TstLoadFile;
  FileNamePtr  := @TstSaveFileName;
  
  
  // Setup call to K_LOAD
  K_SETLFS(1, LFN, 0);
  K_SETNAM(TstSaveFileName.length, FileNamePtr.low, FileNamePtr.high);
  
  K_LOAD(Load, FileStartPtr.low, FileStartPtr.high);
  
  asm
    bcc noerror
    lda #0      ; Set ResB false
    bcs endr
  noerror:
    lda #$FF    ; Set ResB true
  endr:
    sta ResB
  end;
end;

// Tests to make sure TstSaveFile = TstLoadFile 
// after TestK_LOAD is called.
procedure TestLoadfEqSavef: boolean;
begin 
  GoToScreenXY(1,0);
  
  for i:=0 to 16 do
    if TstSaveFile[i] <> TstLoadFile[i] then
      exit(false);
    end; 
  end;
  
  exit(true); 
end;

// Tests to make sure StringLenNT actually
// correctly calculates the string length
// (not including NULL character).
procedure TestStringLenNT: boolean;
var 
  Len: byte;
begin 
  Len := StringLenNT(@TstSaveFile);
  
  if Len <> 16 then 
    exit(false);
  end;
  
  // If you're wondering why this isn't in an
  // ELSE block, it's because the compiler will
  // generate an extra RTS if you don't
  exit(true);
end;

procedure TestDOS_ExecComm;
var 
  Cmd: ARRAY [] of char = 'CD:APPS';
begin 
  DOS_ExecComm(@Cmd);
end;

procedure TestDOS_Scratch;
begin 
  DOS_Scratch(@TstSaveFileName);
end;
 
// PROGRAM START 
begin
  // Start by clearing the screen
  ClearScreen;
  
  // Set initial success flag state
  AllTestsPassed := true;
  
  // Set initial number of failed tests
  NumTstsFailed := 0;

  // Changes directory
  TestDOS_ExecComm;
  
  if not TestK_PLOT then 
    GoToScreenXY(NumTstsFailed + 1,0);
    PrintStr(@Tst1FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestK_CHROUT then   
    GoToScreenXY(NumTstsFailed + 1,0);
    PrintStr(@Tst2FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestK_SAVE then
    GoToScreenXY(NumTstsFailed + 1,0);  
    PrintStr(@Tst3FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestK_LOAD then 
    GoToScreenXY(NumTstsFailed + 1,0);
    PrintStr(@Tst4FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestLoadfEqSavef then 
    GoToScreenXY(NumTstsFailed + 1,0);
    PrintStr(@Tst5FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestStringLenNT then 
    GoToScreenXY(NumTstsFailed + 1,0);
    PrintStr(@Tst6FailStr);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  // Delete test file
  TestDOS_Scratch;
  
  if AllTestsPassed then
    GoToScreenXY(1,0);
    PrintStr(@AllTestsPassStr);
  end; 
  
  asm 
    rts 
  end;
end.
