{------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterPas.pas, released 2000-04-17.
The Original Code is based on the mwPasSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Martin Waldenburg.
Portions created by Martin Waldenburg are Copyright (C) 1998 Martin Waldenburg.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynHighlighterPas.pas,v 1.30 2005/01/28 16:53:24 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net


@abstract(Provides a AutoAssembler syntax highlighter for SynEdit)


}

{$IFNDEF QSYNHIGHLIGHTERPAS}
unit SynHighlighterAA;
{$ENDIF}

{$I SynEdit.inc}

interface

uses
{$IFDEF SYN_CLX}
  QGraphics,
  QSynEditTypes,
  QSynEditHighlighter,
{$ELSE}
  Windows,
  Graphics,
  SynEditTypes,
  SynEditHighlighter,
{$ENDIF}
  SysUtils,
  Classes,
  assemblerunit;

type
  TtkTokenKind = (tkAsm, tkComment, tkIdentifier, tkKey, tkNull, tkNumber,
    tkSpace, tkString, tkSymbol, tkUnknown, tkFloat, tkHex, tkDirec, tkChar,
    tkRegister);

  TRangeState = (rsANil, rsAnsi, rsAnsiAsm, rsAsm, rsBor, rsBorAsm, rsProperty,
    rsExports, rsDirective, rsDirectiveAsm, rsUnKnown);

  TProcTableProc = procedure of object;

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function: TtkTokenKind of object;

  TAutoAssemblerVersion = (dvAutoAssembler1, dvAutoAssembler2, dvAutoAssembler3, dvAutoAssembler4, dvAutoAssembler5,
    dvAutoAssembler6, dvAutoAssembler7, dvAutoAssembler8, dvAutoAssembler2005);

const
  LastAutoAssemblerVersion = dvAutoAssembler2005;

type
  TSynAASyn = class(TSynCustomHighlighter)
  private
    fAsmStart: Boolean;
    fRange: TRangeState;
    fLine: PChar;
    fLineNumber: Integer;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fStringLen: Integer;
    fToIdent: PChar;
    fIdentFuncTable: array[0..222] of TIdentFuncTableFunc;
    fTokenPos: Integer;
    FTokenID: TtkTokenKind;
    fStringAttri: TSynHighlighterAttributes;
    fCharAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fFloatAttri: TSynHighlighterAttributes;
    fHexAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fAsmAttri: TSynHighlighterAttributes;
    fCommentAttri: TSynHighlighterAttributes;
    fDirecAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fRegisterAttri: TSynHighlighterAttributes;
    fAutoAssemblerVersion: TAutoAssemblerVersion;
    fPackageSource: Boolean;
    function KeyHash(ToHash: PChar): Integer;
    function KeyComp(const aKey: string): Boolean;
    function Func9: TtkTokenKind; //ah
    function Func10: TtkTokenKind; //bh
    function Func11: TtkTokenKind; //ch
    function Func12: TtkTokenKind; //dh
    function Func13: TtkTokenKind; //di / al
    function Func14: TtkTokenKind; //bl
    function Func15: TtkTokenKind; //cl
    function Func16: TtkTokenKind; //dl
    function Func18: TtkTokenKind; //edi  / bp
    function Func23: TtkTokenKind; //ebp
    function Func25: TtkTokenKind; //ax / 25
    function Func26: TtkTokenKind; //bx
    function Func27: TtkTokenKind; //cx
    function Func28: TtkTokenKind; //dx / si
    function Func30: TtkTokenKind; //eax / eip
    function Func31: TtkTokenKind; //ebx
    function Func32: TtkTokenKind; //ecx
    function Func33: TtkTokenKind; //edx / esi
    function Func35: TtkTokenKind; //sp
    function Func39: TtkTokenKind; //enable
    function Func40: TtkTokenKind; //esp
    function Func43: TtkTokenKind; //alloc /define
    function Func52: TtkTokenKind; //dealloc / disable
    function Func54: TtkTokenKind; //kalloc
    function Func55: TtkTokenKind; //aobscan
    function Func59: TtkTokenKind; //readmem    
    function Func68: TtkTokenKind; //include
    function Func82: TtkTokenKind; //assert
    function Func92: TtkTokenKind; //globalalloc
    function Func101: TtkTokenKind; //fullaccess/loadbinary
    function Func108: TtkTokenKind; //CreateThread
    function Func117: TtkTokenKind; //loadlibrary
    function Func187: TtkTokenKind; //registersymbol
    function Func222: TtkTokenKind; //unregistersymbol

    function AltFunc: TtkTokenKind;
    procedure InitIdent;
    function getfirsttoken(s: string): string;
    function IdentKind(MayBe: PChar): TtkTokenKind;
    procedure MakeMethodTables;
    procedure AddressOpProc;
    procedure AsciiCharProc;
    procedure AnsiProc;
    procedure BorProc;
    procedure BraceOpenProc;
    procedure ColonOrGreaterProc;
    procedure CRProc;
    procedure IdentProc;
    procedure IntegerProc;
    procedure LFProc;
    procedure LowerProc;
    procedure NullProc;
    procedure NumberProc;
    procedure PointProc;
    procedure RoundOpenProc;
    procedure SemicolonProc;
    procedure SlashProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure SymbolProc;
    procedure UnknownProc;
    procedure SetAutoAssemblerVersion(const Value: TAutoAssemblerVersion);
    procedure SetPackageSource(const Value: Boolean);
  protected
    function GetIdentChars: TSynIdentChars; override;
    function GetSampleSource: string; override;
    function IsFilterStored: boolean; override;
  public
    class function GetCapabilities: TSynHighlighterCapabilities; override;
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetRange: Pointer; override;
    function GetToken: string; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    procedure Next; override;
    procedure ResetRange; override;
    procedure SetLine(NewValue: string; LineNumber:Integer); override;
    procedure SetRange(Value: Pointer); override;
    property IdentChars;
  published
    property AsmAttri: TSynHighlighterAttributes read fAsmAttri write fAsmAttri;
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property DirectiveAttri: TSynHighlighterAttributes read fDirecAttri
      write fDirecAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property RegisterAttri: TSynHighlighterAttributes read fRegisterAttri write fRegisterAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property FloatAttri: TSynHighlighterAttributes read fFloatAttri
      write fFloatAttri;
    property HexAttri: TSynHighlighterAttributes read fHexAttri
      write fHexAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property CharAttri: TSynHighlighterAttributes read fCharAttri
      write fCharAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
    property AutoAssemblerVersion: TAutoAssemblerVersion read fAutoAssemblerVersion write SetAutoAssemblerVersion
      default LastAutoAssemblerVersion;
    property PackageSource: Boolean read fPackageSource write SetPackageSource default True;
  end;

procedure aa_AddExtraCommand(command:pchar);
procedure aa_RemoveExtraCommand(command:pchar);
function isExtraCommand(token:string): boolean;


implementation

uses
{$IFDEF SYN_CLX}
  QSynEditStrConst;
{$ELSE}
  SynEditStrConst;
{$ENDIF}

var
  Identifiers: array[#0..#255] of ByteBool;
  mHashTable: array[#0..#255] of Integer;

  extraCommands: Tstringlist;

procedure aa_AddExtraCommand(command:pchar);
begin
  if extraCommands=nil then
  begin
    extraCommands:=tstringlist.create;
    extraCommands.Duplicates:=dupIgnore;
    extracommands.CaseSensitive:=false;
  end;

  extraCommands.Add(command);
end;

procedure aa_RemoveExtraCommand(command:pchar);
begin
  if extracommands<>nil then
  begin
    extracommands.Delete(extracommands.IndexOf(command));
    if extracommands.Count=0 then
      freeandnil(extracommands);
  end;
end;

function isExtraCommand(token: string): boolean;
begin
  result:=false;
  if extracommands<>nil then
    result:=extracommands.IndexOf(token)<>-1;
end;


procedure MakeIdentTable;
var
  I, J: Char;
begin
  for I := #0 to #255 do
  begin
    Case I of
      '_', '0'..'9', 'a'..'z', 'A'..'Z': Identifiers[I] := True;
    else Identifiers[I] := False;
    end;
    J := UpCase(I);
    Case I of
      'a'..'z', 'A'..'Z', '_': mHashTable[I] := Ord(J) - 64;
    else mHashTable[Char(I)] := 0;
    end;
  end;
end;

procedure TSynAASyn.InitIdent;
var
  I: Integer;
  pF: PIdentFuncTableFunc;
begin
  pF := PIdentFuncTableFunc(@fIdentFuncTable);
  for I := Low(fIdentFuncTable) to High(fIdentFuncTable) do begin
    pF^ := AltFunc;
    Inc(pF);
  end;
  fIdentFuncTable[9] := Func9;
  fIdentFuncTable[10] := Func10;
  fIdentFuncTable[11] := Func11;
  fIdentFuncTable[12] := Func12;
  fIdentFuncTable[13] := Func13;
  fIdentFuncTable[14] := Func14;
  fIdentFuncTable[15] := Func15;
  fIdentFuncTable[16] := Func16;
  fIdentFuncTable[18] := Func18;
  fIdentFuncTable[23] := Func23;
  fIdentFuncTable[25] := Func25;
  fIdentFuncTable[26] := Func26;
  fIdentFuncTable[27] := Func27;
  fIdentFuncTable[28] := Func28;
  fIdentFuncTable[30] := Func30;
  fIdentFuncTable[31] := Func31;
  fIdentFuncTable[32] := Func32;
  fIdentFuncTable[33] := Func33;
  fIdentFuncTable[35] := Func35;
  fIdentFuncTable[39] := Func39;
  fIdentFuncTable[40] := Func40;
  fIdentFuncTable[43] := Func43;
  fIdentFuncTable[52] := Func52;
  fIdentFuncTable[54] := Func54;
  fIdentFuncTable[55] := Func55;  
  fIdentFuncTable[59] := Func59;
  fIdentFuncTable[68] := Func68;
  fIdentFuncTable[82] := Func82;  
  fIdentFuncTable[92] := Func92;
  fIdentFuncTable[101] := Func101;
  fIdentFuncTable[108] := Func108;
  fIdentFuncTable[117] := Func117;
  fIdentFuncTable[187] := Func187;
  fIdentFuncTable[222] := Func222;
end;

function TSynAASyn.KeyHash(ToHash: PChar): Integer;
begin
  Result := 0;
  while ToHash^ in ['a'..'z', 'A'..'Z'] do
  begin
    inc(Result, mHashTable[ToHash^]);
    inc(ToHash);
  end;
  if ToHash^ in ['_', '0'..'9'] then inc(ToHash);
  fStringLen := ToHash - fToIdent;
end; { KeyHash }

function TSynAASyn.KeyComp(const aKey: string): Boolean;
var
  I: Integer;
  Temp: PChar;
begin
  Temp := fToIdent;
  if Length(aKey) = fStringLen then
  begin
    Result := True;
    for i := 1 to fStringLen do
    begin
      if mHashTable[Temp^] <> mHashTable[aKey[i]] then
      begin
        Result := False;
        break;
      end;
      inc(Temp);
    end;
  end else Result := False;
end; { KeyComp }

function TSynAASyn.Func9: TtkTokenKind;
begin
  if KeyComp('ah') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func10: TtkTokenKind;
begin
  if KeyComp('bh') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func11: TtkTokenKind;
begin
  if KeyComp('ch') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func12: TtkTokenKind;
begin
  if KeyComp('dh') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func13: TtkTokenKind;
begin
  if KeyComp('di') then Result := tkRegister else
    if KeyComp('al') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func14: TtkTokenKind;
begin
  if KeyComp('bl') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func15: TtkTokenKind;
begin
  if KeyComp('cl') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func16: TtkTokenKind;
begin
  if KeyComp('dl') then Result := tkRegister else
    Result := tkIdentifier;
end;


function TSynAASyn.Func18: TtkTokenKind;
begin
  if KeyComp('edi') then Result := tkRegister else
    if KeyComp('bp') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func23: TtkTokenKind;
begin
  if KeyComp('ebp') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func25: TtkTokenKind;
begin
  if KeyComp('ax') then Result := tkRegister else
    if KeyComp('ip') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func26: TtkTokenKind;
begin
  if KeyComp('bx') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func27: TtkTokenKind;
begin
  if KeyComp('cx') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func28: TtkTokenKind;
begin
  if KeyComp('dx') then Result := tkRegister else
    if KeyComp('si') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func30: TtkTokenKind;
begin
  if KeyComp('eax') then Result := tkRegister else
    if KeyComp('eip') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func31: TtkTokenKind;
begin
  if KeyComp('ebx') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func32: TtkTokenKind;
begin
  if KeyComp('Label') then Result := tkKey else
    if KeyComp('ecx') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func33: TtkTokenKind;
begin
  if KeyComp('edx') then Result := tkRegister else
    if KeyComp('esi') then Result := tkRegister else
      Result := tkIdentifier;
end;

function TSynAASyn.Func35: TtkTokenKind;
begin
  if KeyComp('bp') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func39: TtkTokenKind; //enable
begin
  if KeyComp('enable') then Result := tkspace else
    Result := tkIdentifier;
end;

function TSynAASyn.Func40: TtkTokenKind; //enable
begin
  if KeyComp('esp') then Result := tkRegister else
    Result := tkIdentifier;
end;

function TSynAASyn.Func43: TtkTokenKind; //alloc /define
begin
  if KeyComp('alloc') then Result := tkKey else
    if KeyComp('define') then Result := tkKey else
      Result := tkIdentifier;
end;

function TSynAASyn.Func52: TtkTokenKind; //dealloc
begin
  if KeyComp('dealloc') then Result := tkKey else
    if KeyComp('disable') then Result := tkspace else
    Result := tkIdentifier;
end;

function TSynAASyn.Func54: TtkTokenKind; //kalloc
begin
  if KeyComp('kalloc') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func55: TtkTokenKind; //aobscan
begin
  if KeyComp('aobscan') then Result := tkKey else
    Result := tkIdentifier;
end;


function TSynAASyn.Func59: TtkTokenKind; //readmem
begin
  if KeyComp('readmem') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func68: TtkTokenKind; //include
begin
  if KeyComp('include') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func82: TtkTokenKind; //include
begin
  if KeyComp('assert') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func92: TtkTokenKind; //globalalloc
begin
  if KeyComp('globalalloc') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func101: TtkTokenKind;
begin
  if KeyComp('LoadBinary') then Result := tkKey else
    if KeyComp('fullaccess') then Result := tkKey else
      Result := tkIdentifier;
end;

function TSynAASyn.Func108: TtkTokenKind; //CreateThread
begin
  if KeyComp('createthread') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func117: TtkTokenKind; //loadlibrary
begin
  if KeyComp('loadlibrary') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func187: TtkTokenKind; //registersymbol
begin
  if KeyComp('registersymbol') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.Func222: TtkTokenKind; //unregistersymbol
begin
  if KeyComp('unregistersymbol') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynAASyn.AltFunc: TtkTokenKind;
begin
  Result := tkIdentifier
end;

function TSynAASyn.getfirsttoken(s: string): string;
var i: integer;
begin
  result:=s;
  for i:=1 to length(s) do
  begin
    if (s[i]='(') or (s[i]=' ') or (s[i]=#9) or (s[i]=',') or (s[i]=#10) or (s[i]=#13) then
    begin
      result:=copy(s,1,i-1);
      exit;
    end;
  end;
end;

function TSynAASyn.IdentKind(MayBe: PChar): TtkTokenKind;
var
  HashKey: Integer;
begin
  fToIdent := MayBe;
  HashKey := KeyHash(MayBe);
  if HashKey < 223 then Result := fIdentFuncTable[HashKey] else
    Result := tkIdentifier;

    
  if (result=tkIdentifier) then
  begin
    if GetOpcodesIndex(getfirsttoken(maybe))<>-1 then
      result:=tkKey
    else
    if isExtraCommand(getfirsttoken(maybe)) then
      result:=tkKey;
  end;


end;

procedure TSynAASyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    case I of
      #0: fProcTable[I] := NullProc;
      #10: fProcTable[I] := LFProc;
      #13: fProcTable[I] := CRProc;
      #1..#9, #11, #12, #14..#32:
        fProcTable[I] := SpaceProc;
      '#': fProcTable[I] := IntegerProc;
      #39: fProcTable[I] := StringProc;
      '0'..'9': fProcTable[I] := NumberProc;
      'A'..'Z', 'a'..'z', '_':
        fProcTable[I] := IdentProc;
      '{': fProcTable[I] := BraceOpenProc;
      '}', '!', '"', '%', '&', '('..'/', ':'..'@', '['..'^', '`', '~':
        begin
          case I of
            '(': fProcTable[I] := RoundOpenProc;
            '.': fProcTable[I] := PointProc;
            ';': fProcTable[I] := SemicolonProc;
            '/': fProcTable[I] := SlashProc;
            ':', '>': fProcTable[I] := ColonOrGreaterProc;
            '<': fProcTable[I] := LowerProc;
            '@': fProcTable[I] := AddressOpProc;
          else
            fProcTable[I] := SymbolProc;
          end;
        end;
    else
      fProcTable[I] := UnknownProc;
    end;
end;

constructor TSynAASyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fAutoAssemblerVersion := LastAutoAssemblerVersion;
  fPackageSource := True;

  fAsmAttri := TSynHighlighterAttributes.Create(SYNS_AttrAssembler);
  AddAttribute(fAsmAttri);
  fCommentAttri := TSynHighlighterAttributes.Create(SYNS_AttrComment);
  fCommentAttri.Style:= [fsItalic];
  fCommentAttri.Foreground:=clBlue;

  AddAttribute(fCommentAttri);
  fDirecAttri := TSynHighlighterAttributes.Create(SYNS_AttrPreprocessor);
  fDirecAttri.Style:= [fsItalic];
  AddAttribute(fDirecAttri);
  fIdentifierAttri := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier);
  AddAttribute(fIdentifierAttri);
  fKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord);
  fKeyAttri.Style:= [fsBold];

  fRegisterAttri := TSynHighlighterAttributes.Create('Register');
  fRegisterAttri.Style:= [fsBold];
  fRegisterAttri.Foreground:=$0080f0;

  AddAttribute(fKeyAttri);
  fNumberAttri := TSynHighlighterAttributes.Create(SYNS_AttrNumber);
  fNumberAttri.Foreground:=clGreen;

  AddAttribute(fNumberAttri);
  fFloatAttri := TSynHighlighterAttributes.Create(SYNS_AttrFloat);
  fFloatAttri.Foreground:=clGreen;
  AddAttribute(fFloatAttri);

  fHexAttri := TSynHighlighterAttributes.Create(SYNS_AttrHexadecimal);
  fHexAttri.Foreground:=clGreen;
  AddAttribute(fHexAttri);

  fSpaceAttri := TSynHighlighterAttributes.Create(SYNS_AttrSpace);
  fSpaceAttri.Foreground:=clNavy;
  AddAttribute(fSpaceAttri);

  fStringAttri := TSynHighlighterAttributes.Create(SYNS_AttrString);
  fStringAttri.Foreground:=clRed;

  AddAttribute(fStringAttri);
  fCharAttri := TSynHighlighterAttributes.Create(SYNS_AttrCharacter);
//  fCharAttri.Foreground:=clRed;
  AddAttribute(fCharAttri);
  fSymbolAttri := TSynHighlighterAttributes.Create(SYNS_AttrSymbol);
  AddAttribute(fSymbolAttri);
  SetAttributesOnChange(DefHighlightChange);

  InitIdent;
  MakeMethodTables;
  fRange := rsUnknown;
  fAsmStart := False;
  fDefaultFilter := SYNS_FilterPascal;
end; { Create }

procedure TSynAASyn.SetLine(NewValue: string; LineNumber:Integer);
begin
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end; { SetLine }

procedure TSynAASyn.AddressOpProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] = '@' then inc(Run);
end;

procedure TSynAASyn.AsciiCharProc;
begin
  fTokenID := tkChar;
  Inc(Run);
  while FLine[Run] in ['0'..'9', '$', 'A'..'F', 'a'..'f'] do
    Inc(Run);
end;

procedure TSynAASyn.BorProc;
begin
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    begin
      if fRange in [rsDirective, rsDirectiveAsm] then
        fTokenID := tkDirec
      else
        fTokenID := tkComment;
      repeat
        if fLine[Run] = '}' then
        begin
          Inc(Run);
          if fRange in [rsBorAsm, rsDirectiveAsm] then
            fRange := rsAsm
          else
            fRange := rsUnKnown;
          break;
        end;
        Inc(Run);
      until fLine[Run] in [#0, #10, #13];
    end;
  end;
end;

procedure TSynAASyn.BraceOpenProc;
begin
 { if (fLine[Run + 1] = '$') then
  begin
    if fRange = rsAsm then
      fRange := rsDirectiveAsm
    else
      fRange := rsDirective;
  end
  else
  begin  }
    if fRange = rsAsm then
      fRange := rsBorAsm
    else
      fRange := rsBor;
  //end;
  BorProc;
end;

procedure TSynAASyn.ColonOrGreaterProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] = '=' then inc(Run);
end;

procedure TSynAASyn.CRProc;
begin
  fTokenID := tkSpace;
  inc(Run);
  if fLine[Run] = #10 then
    Inc(Run);
end; { CRProc }


procedure TSynAASyn.IdentProc;
begin
  fTokenID := IdentKind((fLine + Run));
  inc(Run, fStringLen);
  while Identifiers[fLine[Run]] do
    Inc(Run);
end; { IdentProc }


procedure TSynAASyn.IntegerProc;
begin
  inc(Run);
  fTokenID := tkHex;
  while FLine[Run] in ['0'..'9', 'A'..'F', 'a'..'f'] do
    Inc(Run);
end; { IntegerProc }


procedure TSynAASyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end; { LFProc }


procedure TSynAASyn.LowerProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] in ['=', '>'] then
    Inc(Run);
end; { LowerProc }


procedure TSynAASyn.NullProc;
begin
  fTokenID := tkNull;
end; { NullProc }

procedure TSynAASyn.NumberProc;
begin
 { Inc(Run);
  fTokenID := tkNumber;
  while FLine[Run] in ['0'..'9', '.', 'e', 'E', '-', '+'] do
  begin
    case FLine[Run] of
      '.':
        if FLine[Run + 1] = '.' then
          Break
        else
          fTokenID := tkFloat;
      'e', 'E': fTokenID := tkFloat;
      '-', '+':
        begin
          if fTokenID <> tkFloat then // arithmetic
            Break;
          if not (FLine[Run - 1] in ['e', 'E']) then
            Break; //float, but it ends here
        end;
    end;
    Inc(Run);
  end;   }
    fTokenID := IdentKind((fLine + Run));

  if fTokenID=tkIdentifier then
  begin
    inc(Run);
    fTokenID := tkNumber;
    while FLine[Run] in ['0'..'9', '.', 'a'..'f' , 'A'..'F'] do
    begin
      {case FLine[Run] of
        '.':
          if FLine[Run + 1] = '.' then break;
      end;   }
      inc(Run);
    end;

    if ((FLine[Run]>'G') and (FLine[Run]<='Z')) or ((FLine[Run]>='g') and (FLine[Run]<='z')) then
      fTokenID:=tkIdentifier;
  end
  else
  begin
    inc(Run, fStringLen);
    while Identifiers[fLine[Run]] do inc(Run);
  end;
end; { NumberProc }

procedure TSynAASyn.PointProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] in ['.', ')'] then
    Inc(Run);
end; { PointProc }

procedure TSynAASyn.AnsiProc;
begin
{  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    fTokenID := tkComment;
    repeat
      if (fLine[Run] = '*') and (fLine[Run + 1] = ')') then begin
        Inc(Run, 2);
        if fRange = rsAnsiAsm then
          fRange := rsAsm
        else
          fRange := rsUnKnown;
        break;
      end;
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end;   }
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    fTokenID := tkComment;
    repeat
      if (fLine[Run] = '*') and (fLine[Run + 1] = '/') then begin
        Inc(Run, 2);
        if fRange = rsAnsiAsm then
          fRange := rsAsm
        else
          fRange := rsUnKnown;
        break;
      end;
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end;  
end;

procedure TSynAASyn.RoundOpenProc;
begin
  Inc(Run);
  case fLine[Run] of
  {  '*':
      begin
        Inc(Run);
        if fRange = rsAsm then
          fRange := rsAnsiAsm
        else
          fRange := rsAnsi;
        fTokenID := tkComment;
        if not (fLine[Run] in [#0, #10, #13]) then
          AnsiProc;
      end; }
    '.':
      begin
        inc(Run);
        fTokenID := tkSymbol;
      end;
  else
    fTokenID := tkSymbol;
  end;
end;

procedure TSynAASyn.SemicolonProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
  if fRange in [rsProperty, rsExports] then
    fRange := rsUnknown;
end;

procedure TSynAASyn.SlashProc;
begin
 { Inc(Run);
  if (fLine[Run] = '/') and (fAutoAssemblerVersion > dvAutoAssembler1) then
  begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end
  else if (fLine[Run] = '*') then
  begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
      
    until fLine[Run] in [#0];
  end else fTokenID := tkSymbol;  }

  Inc(Run);
  if fLine[Run] = '/' then
  begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end
  else
  if fline[run] = '*' then
  begin
      begin
        Inc(Run);
        if fRange = rsAsm then
          fRange := rsAnsiAsm
        else
          fRange := rsAnsi;
        fTokenID := tkComment;
        if not (fLine[Run] in [#0, #10, #13]) then
          AnsiProc;
      end;
  end 
  else fTokenID := tkSymbol;  

end;

procedure TSynAASyn.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  while FLine[Run] in [#1..#9, #11, #12, #14..#32] do inc(Run);
end;

procedure TSynAASyn.StringProc;
begin
  fTokenID := tkString;
  Inc(Run);
  while not (fLine[Run] in [#0, #10, #13]) do begin
    if fLine[Run] = #39 then begin
      Inc(Run);
      if fLine[Run] <> #39 then
        break;
    end;
    Inc(Run);
  end;
end;

procedure TSynAASyn.SymbolProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynAASyn.UnknownProc;
begin
{$IFDEF SYN_MBCSSUPPORT}
  if FLine[Run] in LeadBytes then
    Inc(Run, 2)
  else
{$ENDIF}
  inc(Run);
  fTokenID := tkUnknown;
end;

procedure TSynAASyn.Next;
begin
  fAsmStart := False;
  fTokenPos := Run;
  case fRange of
    rsAnsi, rsAnsiAsm:
      AnsiProc;
    rsBor, rsBorAsm, rsDirective, rsDirectiveAsm:
      BorProc;
  else
    fProcTable[fLine[Run]];
  end;
end;

function TSynAASyn.GetDefaultAttribute(Index: integer):
  TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynAASyn.GetEol: Boolean;
begin
  Result := fTokenID = tkNull;
end;

function TSynAASyn.GetToken: string;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  SetString(Result, (FLine + fTokenPos), Len);
end;

function TSynAASyn.GetTokenID: TtkTokenKind;
begin
  if not fAsmStart and (fRange = rsAsm)
    and not (fTokenId in [tkNull, tkComment, tkDirec, tkSpace])
  then
    Result := tkAsm
  else
    Result := fTokenId;
end;

function TSynAASyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case GetTokenID of
    tkAsm: Result := fAsmAttri;
    tkComment: Result := fCommentAttri;
    tkDirec: Result := fDirecAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkRegister: Result := fRegisterAttri;
    tkNumber: Result := fNumberAttri;
    tkFloat: Result := fFloatAttri;
    tkHex: Result := fHexAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkChar: Result := fCharAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynAASyn.GetTokenKind: integer;
begin
  Result := Ord(GetTokenID);
end;

function TSynAASyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynAASyn.GetRange: Pointer;
begin
  Result := Pointer(fRange);
end;

procedure TSynAASyn.SetRange(Value: Pointer);
begin
  fRange := TRangeState(Value);
end;

procedure TSynAASyn.ResetRange;
begin
  fRange:= rsUnknown;
end;

function TSynAASyn.GetIdentChars: TSynIdentChars;
begin
  Result := TSynValidStringChars;
end;

function TSynAASyn.GetSampleSource: string;
begin
  Result :=  'NYI'#13#10;
end; { GetSampleSource }


class function TSynAASyn.GetLanguageName: string;
begin
  Result := SYNS_LangPascal;
end;

class function TSynAASyn.GetCapabilities: TSynHighlighterCapabilities;
begin
  Result := inherited GetCapabilities + [hcUserSettings];
end;

function TSynAASyn.IsFilterStored: boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterPascal;
end;

procedure TSynAASyn.SetAutoAssemblerVersion(const Value: TAutoAssemblerVersion);
begin
  if fAutoAssemblerVersion <> Value then
  begin
    fAutoAssemblerVersion := Value;
    if (fAutoAssemblerVersion < dvAutoAssembler3) and fPackageSource then
      fPackageSource := False;
    DefHighlightChange( Self );
  end;
end;


procedure TSynAASyn.SetPackageSource(const Value: Boolean);
begin
  if fPackageSource <> Value then
  begin
    fPackageSource := Value;
    if fPackageSource and (fAutoAssemblerVersion < dvAutoAssembler3) then
      fAutoAssemblerVersion := dvAutoAssembler3;
    DefHighlightChange( Self );
  end;
end;


initialization
  MakeIdentTable;
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TSynAASyn);
{$ENDIF}
end.

