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

program NewProgram;
uses CX16Kernal;
var
  IntroStr: ARRAY [] of char = 'CX16KERNAL TST';
  
  Tst1FailStr: ARRAY [] of char = 'TST-KPLOT FAILED';
  Tst2FailStr: ARRAY [] of char = 'TST2-KCHROUT FAILED';
  Tst3FailStr: ARRAY [] of char = 'TST3-KSAVE FAILED';
  Tst4FailStr: ARRAY [] of char = 'TST4-KLOAD FAILED';
  Tst5FailStr: ARRAY [] of char = 'TST5-CMP-LOAD-SAVE-F FAILED';
  
  AllTestsPassStr: ARRAY [] of char = 'ALL TESTS PASSED';
  
  TstSaveFileName: ARRAY [] of char = 'TST1.BIN';
  
  TstSaveFile: ARRAY [] of byte = (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15);
  TstLoadFile: [16]byte;
  
  AllTestsPassed: boolean;
  
  Ptr: word;
  
  i,j,NumTstsFailed: byte;

// Handy way to test K_PLOT(false,...) for free
procedure GoToXY(x, y: byte);
begin
  K_PLOT_Set(x, y);
end;   
  
// Could use refactoring but works for now
procedure ClearScrX16;
var
  sw, sh: byte;
begin
  // Get screen width and height
  asm 
	  jsr $FFED
    dex
    stx sw 
    dey
    sty sh      
  end; 
  
  GoToXY(0,0);
  
  for i:=0 to sh do
    for j:=0 to sw do
      asm 
        lda #32
        jsr $FFD2 
      end; 
    end; 
  end; 
  
end;     

// Print string implementation
procedure PrintStr(StrPtr: word; StrLen: byte registerX);
const
  r0Addr = $0002;
begin 
  r0 := StrPtr;
  
  asm
    ldy #0
  loop:
    lda (r0Addr),y
    jsr $FFD2
    iny 
    dex 
    bne loop 
  end;
end;  

// Test K_CHROUT
procedure TestK_CHROUT: boolean;
begin 
  GoToXY(0,0);
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
  GoToXY(3, 5);
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
  FileStartPtr:= @TstSaveFile;
  FileEndPtr := FileStartPtr + 15;
  FileNamePtr:= @TstSaveFileName;
  
  r0 := FileStartPtr;
  
  // Setup call to K_SAVE
  K_SETLFS(1, 8, 255);
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
  FileEndPtr:   word;
  FileNamePtr:  word;
  ResB:         boolean;
begin
  // Setup variables to call K_SAVE
  FileStartPtr:= @TstLoadFile;
  FileEndPtr := FileStartPtr + 15;
  FileNamePtr:= @TstSaveFileName;
  
  
  // Setup call to K_SAVE
  K_SETLFS(1, LFN, 255);
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
  for i:=0 to 15 do
    if not TstSaveFile[i] = TstLoadFile[i] then
      exit(false);
    end; 
  end;
  
  exit(true); 
end;
  
begin
  // Start by clearing the screen
  ClearScrX16;
  
  // Set initial success flag state
  AllTestsPassed := true;
  
  // Set initial number of failed tests
  NumTstsFailed := 0;

  if not TestK_PLOT then 
    GoToXY(NumTstsFailed + 1,0);
    Ptr := @Tst1FailStr;
    PrintStr(Ptr, Tst1FailStr.length);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  
  if not TestK_CHROUT then   
    GoToXY(NumTstsFailed + 1,0);
    Ptr := @Tst2FailStr;
    PrintStr(Ptr, Tst2FailStr.length);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestK_SAVE then
    GoToXY(NumTstsFailed + 1,0);  
    Ptr := @Tst3FailStr;
    PrintStr(Ptr, Tst3FailStr.length);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestK_LOAD then 
    GoToXY(NumTstsFailed + 1,0);
    Ptr := @Tst4FailStr;
    PrintStr(Ptr, Tst4FailStr.length);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if not TestLoadfEqSavef then 
    GoToXY(NumTstsFailed + 1,0);
    Ptr := @Tst5FailStr;
    PrintStr(Ptr, Tst5FailStr.length);
    AllTestsPassed := false;
    NumTstsFailed += 1;
  end;
  
  if AllTestsPassed then
    GoToXY(1,0);
    Ptr := @AllTestsPassStr;
    PrintStr(Ptr, AllTestsPassStr.length);
  end; 
  
  asm 
    rts 
  end;
end.
