////////////////////////////////////////////
// Created 7/6/2025}
//
// TODO:
// 1) K_MACPTR, K_CIOUT, and a few other routines
//    need to be refactored or they won't compile
//    when you try to invoke them.
//
// 2) Determine which (if any) of the commented
//    out procedure declarations should be added
//    back or deleted after offering alternative
//    hand written routines.
//
// 3) Finish writing tests for all the routines in
//    this file.
//
////////////////////////////////////////////
{Unit to interface with Commander X16 Kernal assembly routines}
{$ORG $0801}
//{$BOOTLOADER X16}
{$BOOTLOADER $0C, $08, $0A, $00, $9E, 'COD_5A', $00, $00, $00}
{$STRING NULL_TERMINATED}
//Set RAM for Commander X16
{$SET_STATE_RAM '0000-0001:SFR'} //Zero page

// These can be uncommented to use different 
// sections of the Zero Page if you don't care
// about trashing the memory there
//
{$SET_STATE_RAM '0080-00FF:SFR'} //ZERO PAGE SAFE USAGE COMMENT OUT TO USE ALL ZERO PAGE (1)
//{$SET_DATA_ADDR '0080-00DE:SFR'} // USE BASIC ZERO PAGE SPACE (2)
//{$SET_DATA_ADDR '0080-00A8:SFR'} // USE BASIC/MATH LIBRARY ZERO PAGE SPACE (3)

{$SET_STATE_RAM '0100-01FF:SFR'} //Stack
{$SET_DATA_ADDR '0022-007F'}     //Free For User: ALWAYS AVAILABLE 
//{$SET_DATA_ADDR '0022-00FF'}     //Free For User: UNCOMMENT TO USE ALL ZERO PAGE (1)
//{$SET_DATA_ADDR '00A9-00FF'}     //Free For User: UNCOMMENT IF USING (2)
//{$SET_DATA_ADDR '00DF-00FF'}     //Free For User: UNCOMMENT IF USING (3)

unit CX16Kernal;
interface

// Types for multi-byte return Kernal subroutines
type RetAXY = [3]byte;
type RetXY  = word;

var
  // Variable aliases for registers
  r0:  word absolute $02;
  r1:  word absolute $04;
  r2:  word absolute $06;
  r3:  word absolute $08;
  r4:  word absolute $0A;
  r5:  word absolute $0C;
  r6:  word absolute $0E;
  r7:  word absolute $10;
  r8:  word absolute $12;
  r9:  word absolute $14;
  r10: word absolute $16;
  r11: word absolute $18;
  r12: word absolute $1A;
  r13: word absolute $1C;
  r14: word absolute $1E;
  r15: word absolute $20;
  
  // TODO: REMOVE THESE
  // Used for multi-byte return Kernal subroutines
  K_RetAXY: RetAXY;
  K_RetXY:  RetXY;
  
  CmdBuffer: [128]char;
  
  // Screen/Print Functions 
  procedure GoToScreenXY(x: byte registerX; y: byte registerY);
  procedure ClearScreen;
  procedure PrintStr(StrPtr: word);
  
  // I/O Functions
  procedure LoadFileFromSD(FileStrtPtr: word; FileNamePtr: word): boolean;
  procedure LoadFileFromFDskDrv(FileStrtPtr: word; FileNamePtr: word): boolean;
  
  // String Helper Functions
  procedure StringLenNT(StrPtr: word): byte;
  
  // DOS Functions
  procedure DOS_Scratch(FileStrPtr: word absolute $04);
  procedure DOS_ExecComm(StrPtr: word absolute $02);
  
  // KERNAL HELPER FUNCTIONS
  procedure SetHighBankRAM(Bank: byte registerA);   // Open to renaming these
  procedure ActiveHighBankRAM: byte;
  procedure SetHighBankROM(Bank: byte registerA);
  procedure ActiveHighBankROM: byte;
  
  // COMMODORE/X16 IEEE/PERIPHERAL BUS KERNAL ROUTINES
  procedure K_ACPTR: byte;
  procedure K_MACPTR(NBytes: byte registerA; AddrLo: byte registerX; AddrHi: byte registerY; CF: boolean): boolean;
  procedure K_CIOUT(b: byte registerA);
  procedure K_MCIOUT(NBytes: byte registerA; AddrLo: byte registerX; AddrHi: byte registerY; CF: boolean): boolean;
  procedure K_SETTMO(TimeoutFlag: byte registerA);
  procedure K_UNLSN;
  procedure K_SECOND(SecAddr: byte registerA);
  procedure K_LISTEN(DeviceNum: byte registerA);
  procedure K_TALK(Dev: byte registerA);
  procedure K_TKSA(SecAddr: byte registerA);
  procedure K_UNTLK;
  
  // COMMODORE/X16 IO KERNAL ROUTINES
  //procedure K_SETMSG(CntrlCode: byte registerA);
  //procedure K_READST: byte;
  procedure K_SETLFS(LFN: byte registerA; DevNum: byte registerX; Comm: byte registerY);
  procedure K_SETNAM(FNLen: byte registerA; FNAddrLo: byte registerX; FNAddrHi: byte registerY);
  procedure K_OPEN;
  procedure K_CLOSE(LF: byte registerA);
  procedure K_CHKIN(LF: byte registerX): byte;
  procedure K_CHKOUT(LF: byte registerX): byte;
  procedure K_CLRCHN;
  procedure K_CHRIN: char;
  procedure K_CHROUT(Chr: char registerA);
  procedure K_LOAD(LV: byte registerA; AddrStrtLo: byte registerX; AddrStrtHi: byte registerY): RetXY;
  procedure K_SAVE(ZPOffset: byte registerA; AddrEndLo: byte registerX; AddrEndHi: byte registerY): boolean;
  procedure K_CLALL;
  
  // COMMODORE/X16 SYS KERNAL ROUTINES
  //procedure K_IOINIT;
  //procedure K_RESTOR;
  //procedure K_VECTOR(CF: boolean registerA; VectAddrLo: byte registerX; VectAddrHi: byte registerY);
  
  // COMMODORE/X16 MEM KERNAL ROUTINES
  //procedure K_RAMTAS;
  //procedure K_MEMTOP(CF: boolean registerA; MTOPAddrLo: byte registerX; MTOPAddrHi: byte registerY);
  //procedure K_MEMBOT(CF: boolean registerA; MBOTAddrLo: byte registerX; MBOTAddrHi: byte registerY);
  
  // COMMODORE/X16 EDITOR KERNAL ROUTINES
  procedure K_CINT;
  procedure K_SCREEN: word;
  procedure K_PLOT_Set(PosRow: byte registerX; PosCol: byte registerY);
  procedure K_PLOT_Get: word; 
  
  // COMMODORE/X16 KBD ROUTINES
  procedure K_SCNKEY;
  procedure K_STOP: boolean;
  procedure K_GETIN: byte;
  
  // COMMODORE/X16 TIME ROUTINES
  //procedure K_SETTIM(MSB: byte registerA; MDB: byte registerX; LSB: byte registerY);
  //procedure K_RDTIM;
  
implementation

///////////////////////////////////////////////////////////
// Screen/Print Functions 
///////////////////////////////////////////////////////////

// Alias for K_PLOT_set(X,Y)
// 
// Params:
// -------
//
// PosRow: Row to set screen cursor position to
// PosCol: Col to set screen cursor position to
// 
// Returns:
// --------
//
// None
//
procedure GoToScreenXY(x: byte registerX; y: byte registerY);
begin
  asm 
    clc 
    jsr $FFF0 
  end; 
end;

// Uses inline assembly for kernal routine
// calls
// 
// Returns:
// --------
//
// None
//
procedure ClearScreen;
var
  sw, sh, i, j: byte;
begin
  // Get screen width and height
  // and go to screen coords (0,0)
  asm 
    jsr $FFED    ; K_SCREEN
    dex
    stx sw 
    dey
    sty sh      
    ldx #0 
    ldy #0 
    clc 
    jsr $FFF0    ; K_PLOT
  end;
  
  // Fill screen with ' ' chars
  for i:=0 to sh do
    for j:=0 to sw do
      asm 
        lda #32
        jsr $FFD2 ; K_CHROUT
      end; 
    end; 
  end; 
  
end;  

// Print string implementation
// 
// Params:
// -------
//
// StrPtr: Pointer to the NULL terminated string
//
// Returns:
// --------
//
// None
//
procedure PrintStr(StrPtr: word absolute $02);
begin 
  asm
    ldy #0
  loop:
    lda (r0),y
    beq endr
    jsr $FFD2
    iny  
    bne loop 
  endr:
  end;
end;

///////////////////////////////////////////////////////////
// I/O Routines
///////////////////////////////////////////////////////////

// NOTE: not sure if I should expose this one or not
//
// Does the work for loading files from SD or Disk Drive so
// we don't duplicate code
//
// Params:
// -------
//
// FileStrtPtr: Where to load file to in RAM
// FileNamePtr: Where the file name string is located in RAM/ROM
// LFN:         Logical File Number
//
// Returns:
// --------
//
// ResB:        Boolean value that contains true if the file loaded,
//              false if it failed to load.
//
procedure LoadFile(FileStrtPtr: word; FileNamePtr: word; LFN: byte): boolean;
const
  Load:         byte = 0;
var
  FileNameLen:  byte;
  ResB:         boolean;
begin 
  FileNameLen := StringLenNT(FileNamePtr);
  
  // Setup call to K_LOAD
  K_SETLFS(1, LFN, 0);
  K_SETNAM(FileNameLen, FileNamePtr.low, FileNamePtr.high);
  
  K_Load(Load, FileStrtPtr.low, FileStrtPtr.high);
  
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

// Intended to replace ' LOAD "...",8,1 '
//
// Params:
// -------
//
// FileStrtPtr: Where to load file to in RAM
// FileNamePtr: Where the file name string is located in RAM/ROM
//
// Returns:
// --------
//
// ResB:        Boolean value that contains true if the file loaded,
//              false if it failed to load.
//
procedure LoadFileFromSD(FileStrtPtr: word; FileNamePtr: word): boolean;
const
  LFN:          byte = 8;
var
  ResB:         boolean;
begin 
  ResB := LoadFile(FileStrtPtr, FileNamePtr, LFN);
end;

// Intended to replace ' LOAD "...",9,1 ', aka Load File From Disk Drive
//
// Params:
// -------
//
// FileStrtPtr: Where to load file to in RAM
// FileNamePtr: Where the file name string is located in RAM/ROM
//
// Returns:
// --------
//
// ResB:        Boolean value that contains true if the file loaded,
//              false if it failed to load.
//
procedure LoadFileFromFDskDrv(FileStrtPtr: word; FileNamePtr: word): boolean;
const
  LFN:          byte = 9;
var
  ResB:         boolean;
begin 
  ResB := LoadFile(FileStrtPtr, FileNamePtr, LFN);
end;

///////////////////////////////////////////////////////////
// String helper functions
/////////////////////////////////////////////////////////// 

// Finds the length of NULL terminated string or 255 if no
// NULL character found.
// 
// Params:
// -------
//
// StrPtr: Pointer to the NULL terminated string
//
// Returns:
// --------
//
// byte:   Length of string. Defaults to 255 if no NULL char found.
//
procedure StringLenNT(StrPtr: word): byte;
const
  r0Addr: byte = $02;
begin
  r0.low  := StrPtr.low;
  r0.high := StrPtr.high;
  
  asm
    ldy #0
    ldx #0
  loop:
    lda (r0Addr),y
    beq setsum
    iny 
    inx 
    bne loop
  setsum:
    txa
  end;
end;

///////////////////////////////////////////////////////////
// DOS Functions
///////////////////////////////////////////////////////////

// Copies command and parameters to CmdBuffer
//
// Params:
// -------
//
// r0: Pointer to null terminated command string
// r1: Pointer to null terminated parameter string
//
// Returns:
// --------
//
// None.
//
procedure CopyToCmdBuffer(CmdPtr1: word absolute $02; CmdPtr2: word absolute $04);
begin
  asm 
    ldy #0
    ldx #0
  loop:
    lda (r0),y
    beq copy_nxt
    sta CmdBuffer,x
    inx 
    iny 
    jmp loop
  copy_nxt:
    ldy #0
  loop_2:
    lda (r1),y
    beq endr
    sta CmdBuffer,x        
    inx 
    iny 
    jmp loop_2
  endr: 
    sta CmdBuffer,x
  end;
end;

procedure DOS_CD(StrPtr: word absolute $02);
begin 

end;

procedure DOS_MD(StrPtr: word absolute $02);
begin 

end;

procedure DOS_RD(StrPtr: word absolute $02);
begin 

end;

procedure DOS_Dir;
var 
  cmd: char = '$';
begin 
  
end;

// Deletes file
//
// Params:
// -------
//
// FileStrPtr: Pointer to string with file name
//
// Returns:
// --------
//
// None.
//
procedure DOS_Scratch(FileStrPtr: word);
var 
  CmdStrt: [3]char = 'S:';
begin 
  CopyToCmdBuffer(@CmdStrt, FileStrPtr);
  DOS_ExecComm(@CmdBuffer);
end;

// Executes CBM-DOS command
//
// Params:
// -------
//
// StrPtr (r0): Pointer to string with command
//
// Returns:
// --------
//
// None.
//
procedure DOS_ExecComm(StrPtr: word absolute $02);
begin 
  asm
    ldy #0 
	  lda (r0),y
    bne start 
    rts       
  start:
  end;
  
  K_CHKIN(15); 
  K_LISTEN(8);
  K_SECOND($6F);
  
  asm
    ldy #0 
  loop:
    lda (r0),Y           
    beq endr  
    jsr $FFA8            
    iny                   
    jmp loop        
  endr:
  end;
  
  K_UNLSN;
  K_CLRCHN;
end;


///////////////////////////////////////////////////////////
// KERNAL HELPER FUNCTIONS
///////////////////////////////////////////////////////////

// Sets the High RAM Bank
//
// Params:
// -------
//
// registerA: Bank to set active
//
// Returns:
// --------
//
// None.
//
procedure SetHighBankRAM(Bank: byte registerA);
begin
  asm 
    sta $00  
  end; 
end; 

// Gets the High RAM Bank
//
// Returns:
// --------
//
// registerA: Active bank
//
procedure ActiveHighBankRAM: byte;
begin
  asm 
    lda $00  
  end; 
end; 

// Sets the High ROM Bank
//
// Params:
// -------
//
// registerA: Bank to set active
//
// Returns:
// --------
//
// None.
//
procedure SetHighBankROM(Bank: byte registerA);
begin
  asm 
    sta $01  
  end; 
end; 

// Gets the High ROM Bank
//
// Returns:
// --------
//
// registerA: Active bank
//
procedure ActiveHighBankROM: byte;
begin
  asm 
    lda $01  
  end; 
end;

///////////////////////////////////////////////////////////
// COMMODORE/X16 IEEE/PERIPHERAL BUS KERNAL ROUTINES
///////////////////////////////////////////////////////////

// Calls ACPTR from assembly
//
// Returns:
// --------
//
// registerA: byte from the bus
//
procedure K_ACPTR: byte;
begin
  asm 
    jsr $FFA5 
  end; 
end;

// Calls MACPTR from assembly.
//
// Params:
// -------
//
// NBytes: Number of bytes to write
// AddrLo: Low byte of address to write to
// AddrHi: High byte of address to write to
// CF:     Boolean to store carry flag alias 
//
// Returns:
// --------
//
// CF:      Returns carry flag
// K_RetXY: The combined result of X/Y
// 
procedure K_MACPTR(NBytes: byte registerA; 
                   AddrLo: byte registerX; 
                   AddrHi: byte registerY;
                   CF: boolean): boolean;
begin
  asm 
    jsr $FF44
    bcs setTrue
  setFalse:
    lda #0
    sta CF
    beq endr
  setTrue:
    lda #1
    sta CF
  endr:
    stx K_RetXY
    sty K_RetXY+1     
  end; 

  exit(CF); 
end; 

// Calls CIOUT from assembly
//
// Params:
// -------
//
// b:     byte CIOUT should write
//
// Returns:
// --------
//
// None.
//
procedure K_CIOUT(b: byte registerA);
begin
  asm 
    jsr $FFA8
  end; 
end; 

// Calls MCIOUT from assembly. 
// 
// Params:
// -------
//
// NBytes: Number of bytes to write
// AddrLo: Low byte of address to write to
// AddrHi: High byte of address to write to
// CF:     true indicates MCIOUT should advance memory
//         pointer, false indicates not too. 
// 
// Returns:
// --------
//
// CF:      Returns carry flag
// K_RetXY: Contains the # of bytes written in the global variable
//
procedure K_MCIOUT(NBytes: byte registerA; 
                   AddrLo: byte registerX; 
                   AddrHi: byte registerY;
                   CF: boolean): boolean;
begin
  if CF then
    asm 
      sec	 
    end; 
  else
    asm 
      clc 
    end; 
  end;
  
  asm 
    jsr $FEB1
    bcs setTrue
  setFalse:
    lda #0
    sta CF
    beq endr
  setTrue:
    lda #1
    sta CF
  endr:
    stx K_RetXY
    sty K_RetXY+1
  end; 
  
  exit(CF);  
end; 

// Calls SETTMO from assembly.
//
// Params:
// -------
//
// TimeoutFlag: bit 7 set to 0 or 1
//
// Returns:
// --------
//
// None.
//
procedure K_SETTMO(TimeoutFlag: byte registerA);
begin
  asm 
    jsr $FFA2 
  end; 
end; 

// Calls LISTEN from assembly.
//
// Params:
// -------
//
// Dev:    the device number
//
// Returns:
// --------
//
// None.
//
procedure K_LISTEN(Dev: byte registerA);
begin
  asm 
    jsr $FFB1
  end; 
end; 

// Calls UNLSN from assembly.
//
// Returns:
// --------
//
// None.
//
procedure K_UNLSN;
begin
  asm 
    jsr $FFAE
  end; 
end; 

// Calls SECOND from assembly.
//
// Params:
// -------
//
// SecAddr: the secondary address
//
// Returns:
// --------
//
// None.
//
procedure K_SECOND(SecAddr: byte registerA);
begin
  asm 
    jsr $FF93
  end; 
end; 

// Calls TALK from assembly.
//
// Params:
// -------
//
// Dev:    the device number
//
// Returns:
// --------
//
// None.
//
procedure K_TALK(Dev: byte registerA);
begin
  asm 
    jsr $FFB4
  end; 
end;

// Calls TKSA from assembly.
//
// Params:
// -------
//
// SecAddr: the secondary address
//
// Returns:
// --------
//
// None.
//
procedure K_TKSA(SecAddr: byte registerA);
begin
  asm 
    jsr $FF96
  end; 
end; 

// Calls UNTLK from assembly.
//
// Returns:
// --------
//
// None.
//
procedure K_UNTLK;
begin
  asm 
    jsr $FFAB
  end; 
end;

///////////////////////////////////////////////////////////
// COMMODORE/X16 IO KERNAL ROUTINES
/////////////////////////////////////////////////////////// 

// Calls SETMSG from assembly.
//
// Params:
// -------
//
// CntrlCode: value to set what error/control msgs printed
//            by the KERNAL
//
// Returns:
// --------
//
// None.
//
procedure K_SETMSG(CntrlCode: byte registerA);
begin
  asm 
    jsr $FF90 
  end; 
end; 

// Calls READST from assembly.
//
// Returns:
// --------
//
// registerA: Status word
//
procedure K_READST: byte;
begin
  asm 
    jsr $FFB7
  end; 
end; 

// Calls SETLFS from assembly. 
// 
// Params:
// -------
//
// LFN:     Logical File Number
// DevNum:  Device Number
// Comm:    Command
// 
// Returns:
// --------
//
// None.
//
procedure K_SETLFS(LFN: byte registerA; DevNum: byte registerX; Comm: byte registerY);
begin
  asm 
    jsr $FFBA
  end; 
end; 

// Calls SETNAM from assembly. 
// 
// Params:
// -------
//
// FNLen:   File Name Length
// FNAddrLo: Low byte of address of file name
// FNAddrHi: High byte of address of file name
// 
// Returns:
// --------
//
// None.
//
procedure K_SETNAM(FNLen: byte registerA; FNAddrLo: byte registerX; FNAddrHi: byte registerY);
begin
  asm 
    jsr $FFBD
  end; 
end; 

// Calls OPEN from assembly
//
// Returns:
// --------
//
// None.
//
procedure K_OPEN;
begin
  asm 
    jsr $FFC0
  end; 
end; 

// Calls CLOSE from assembly
//
// Params:
// -------
//
// LF:    Logical File to close
//
// Returns:
// --------
// 
// None.
// 
procedure K_CLOSE(LF: byte registerA);
begin
  asm 
    jsr $FFC3 
  end; 
end; 

// Calls CHKIN from assembly
//
// Params:
// -------
//
// LF:    Logical File to check
//
// Returns:
// --------
// 
// registerA: Differs depending on Logical File # 
// 
procedure K_CHKIN(LF: byte registerX): byte;
begin
  asm 
    jsr $FFC3
  end; 
end;

// Calls CHKOUT from assembly
//
// Params:
// -------
//
// LF:    Logical File to check
//
// Returns:
// --------
// 
// registerA: Differs depending on Logical File # 
// 
procedure K_CHKOUT(LF: byte registerX): byte;
begin
  asm 
    jsr $FFC9
  end; 
end;

// Calls CLRCHN from assembly
//
// Returns:
// --------
// 
// None.
// 
procedure K_CLRCHN;
begin
  asm 
    jsr $FFCC
  end; 
end; 

// Calls CHRIN from assembly
//
// Returns:
// 
// registerA:   Character returned by CHRIN
// 
procedure K_CHRIN: char;
begin
  asm 
    jsr $FFCF 
  end;
end; 

// Calls CHROUT from assembly
//
// Params:
// -------
//
// char:   Character to output
//
// Returns:
// --------
// 
// None.
// 
procedure K_CHROUT(Chr: char registerA);
begin
  asm 
    jsr $FFD2
  end; 
end; 

// Calls LOAD from assembly. 
// 
// Params:
// -------
//
// LV:         Load or Verify
// AddrStrtLo: Low byte of address of file RAM load
// AddrStrtHi: High byte of address of file RAM load
// 
// Returns:
// --------
//
// RetAddr: Address of highest byte of loaded file
//
procedure K_LOAD(LV: byte registerA; AddrStrtLo: byte registerX; AddrStrtHi: byte registerY): RetXY;
var
RetAddr: RetXY;
begin
  asm 
    jsr $FFD5
    stx RetAddr
    sty RetAddr 
  end; 
end; 

// Calls SAVE from assembly. 
// 
// Params:
// -------
//
// ZPOffset:     Zero page offset where file start pointer is stored
// AddrEndLo:    Low byte of address of end of file
// AddrEndHi:    High byte of address of end of file
// 
// Returns:
// --------
//
// Boolean:      Returns Carry Flag to indicate success or failure
//
procedure K_SAVE(ZPOffset: byte registerA; AddrEndLo: byte registerX; AddrEndHi: byte registerY): boolean;
begin
  asm 
    jsr $FFD8
    bcc retTrue
    lda #0
    bcs endr
  retTrue:
    lda #$FF
  endr:
  end; 
end;

// Calls CLALL from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_CLALL;
begin
  asm 
    jsr $FFE7
  end; 
end; 

///////////////////////////////////////////////////////////
// COMMODORE/X16 SYS KERNAL ROUTINES
///////////////////////////////////////////////////////////

// Calls IOINIT from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_IOINIT;
begin
  asm 
    jsr $FF84 
  end; 
end; 


// Calls RESTOR from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_RESTOR;
begin
  asm 
    jsr $FF8A 
  end; 
end; 

// Calls VECTOR from assembly. 
// 
// Params:
// -------
//
// CF:            If true, sec, else if false, clc
// VectAddrLo:    Low byte of address of vector
// VectAddrHi:    High byte of address of vector
// 
// Returns:
// --------
//
// None.
//
procedure K_VECTOR(CF: boolean registerA; VectAddrLo: byte registerX; VectAddrHi: byte registerY);
begin
  if CF then
    asm 
      sec
    end; 
  else
    asm 
      clc 
    end; 
  end;
  
  asm 
    jsr $FF8D 
  end;    
end; 

///////////////////////////////////////////////////////////
// COMMODORE/X16 MEM KERNAL ROUTINES
///////////////////////////////////////////////////////////

// Calls RAMTAS from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_RAMTAS;
begin
  asm 
    jsr $FF87 
  end; 
end; 

// Calls MEMTOP from assembly. 
// 
// Params:
// -------
//
// CF:         If true, sec, else if false, clc
// MTOPAddrLo: Low byte of address of RAM top
// MTOPAddrHi: High byte of address of RAM top
// 
// Returns:
// --------
//
// K_RetXY:       The combined result of X/Y registers
//
procedure K_MEMTOP(CF: boolean registerA; 
                   MTOPAddrLo: byte registerX; 
                   MTOPAddrHi: byte registerY);
begin
  if CF then
    asm 
      sec
      jsr $FF99
      stx K_RetXY 
      sty K_RetXY+1 
    end; 
  else
    asm 
      clc 
      jsr $FF99  
    end; 
  end; 
end; 
 
// Calls MEMBOT from assembly. 
// 
// Params:
// -------
//
// CF:         If true, sec, else if false, clc
// MBOTAddrLo: Low byte of address of RAM bottom
// MBOTAddrHi: High byte of address of RAM bottom
// 
// Returns:
// --------
//
// K_RetXY:       The combined result of X/Y registers
//
procedure K_MEMBOT(CF: boolean registerA; 
                   MBOTAddrLo: byte registerX; 
                   MBOTAddrHi: byte registerY);
begin
  if CF then
    asm 
      sec
      jsr $FF99
      stx K_RetXY 
      sty K_RetXY+1 
    end; 
  else
    asm 
      clc 
      jsr $FF99  
    end; 
  end; 
end; 

///////////////////////////////////////////////////////////
// COMMODORE/X16 EDITOR KERNAL ROUTINES
///////////////////////////////////////////////////////////

// Calls CINT from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_CINT;
begin
  asm 
    jsr $FF81 
  end; 
end; 

// Calls SCREEN from assembly. 
// 
// Returns:
// --------
//
// RetXY:       The combined result of X/Y registers
//
procedure K_SCREEN: RetXY;
var 
  FmtRC: RetXY;
begin
  asm 
    jsr $FFED
    stx FmtRC 
    sty FmtRC+1 
  end;
  
  exit(FmtRC); 
end;

// Calls PLOT from assembly. 
// 
// Params:
// -------
//
// PosRow: Row to set screen cursor position to
// PosCol: Col to set screen cursor position to
// 
// Returns:
// --------
//
// None
//
procedure K_PLOT_Set(PosRow: byte registerX; PosCol: byte registerY);   
begin
  asm 
    clc 
    jsr $FFF0 
  end; 
end;

procedure K_PLOT_Get: word;   
var
  Ret: RetXY;
begin
  asm 
    sec
    jsr $FFF0
    stx Ret
    sty Ret+1 
  end; 
  exit(Ret);
end;

///////////////////////////////////////////////////////////
// COMMODORE/X16 KBD ROUTINES
///////////////////////////////////////////////////////////

// Calls SCNKEY from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_SCNKEY;
begin
  asm 
    jsr $FF9F 
  end; 
end;

// Calls STOP from assembly. 
//
// Returns:
// --------
//
// boolean: result of zero flag
//
procedure K_STOP: boolean; 
var
  ZF: boolean;
begin
  asm 
    jsr $FFE1
    bne retKND
    lda #0
    beq endr
  retKND:
    lda #$FF
  endr:
    sta ZF
  end; 
end; 

// Calls GETIN from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_GETIN: byte;
begin
  asm 
    jsr $FFE4 
  end; 
end; 

///////////////////////////////////////////////////////////
// COMMODORE/X16 TIME ROUTINES
///////////////////////////////////////////////////////////

// Calls SETTIM from assembly. 
//
// Returns:
// --------
//
// None.
//
procedure K_SETTIM(MSB: byte registerA; MDB: byte registerX; LSB: byte registerY);
begin
  asm 
    jsr $FFDB 
  end; 
end; 

// Calls RDTIM from assembly. 
//
// Returns:
// --------
//
// K_RetAXY: stores the return values in the global variable
//
procedure K_RDTIM;
begin
  asm 
    jsr $FFDB
    sta K_RetAXY
    stx K_RetAXY+1
    sty K_RetAXY+2 
  end; 
end; 

end.
