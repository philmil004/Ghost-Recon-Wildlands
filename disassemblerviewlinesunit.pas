unit disassemblerviewlinesunit;

interface

uses windows,sysutils, classes,ComCtrls, graphics, cefuncproc, disassembler,
     debugger, kerneldebugger, symbolhandler, plugin;

type TDisassemblerLine=class
  private
    fbitmap: tbitmap;
    fCanvas: TCanvas;
    fHeaders: THeaderSections;
    top: integer;
    height: integer; //height of the line
    fInstructionCenter: integer; //y position of the center of the disassembled line (so no header)
    isselected: boolean;

    faddress: dword;
    fdescription: string;
    fdisassembled: string;

    fisJump: boolean;
    fJumpsTo: dword;


    addressstring: string;
    bytestring: string;
    opcodestring: string;
    specialstring: string;
    referencedbylineheight: integer;
    boldheight: integer;
    textheight: integer;
    function truncatestring(s: string; maxwidth: integer): string;
    function buildReferencedByString: string;
  public
    property address: dword read faddress;
    property instructionCenter: integer read fInstructionCenter;
    function isJumpOrCall(var addressitjumpsto: dword): boolean;
    function getHeight: integer;
    function getTop: integer;
    property description:string read fdescription;
    property disassembled:string read fdisassembled;
    procedure renderLine(var address: dword; linestart: integer; selected: boolean=false; focused: boolean=false);
    procedure drawJumplineTo(yposition: integer; offset: integer; showendtriangle: boolean=true);
    procedure handledisassemblerplugins(addressStringPointer: pointer; bytestringpointer: pointer; opcodestringpointer: pointer; specialstringpointer: pointer; textcolor: PColor);
    constructor create(bitmap: TBitmap; headersections: THeaderSections);
end;

implementation

uses MemoryBrowserFormUnit, dissectcodeunit, dissectCodeThread;

procedure TDisassemblerLine.drawJumplineTo(yposition: integer; offset: integer; showendtriangle: boolean=true);
var
  oldpenstyle: Tpenstyle;
  oldpencolor, oldbrushcolor: TColor;
begin
  oldpenstyle:=fCanvas.Pen.Style;
  oldpencolor:=fCanvas.Pen.color;
  oldbrushcolor:=fCanvas.Brush.color;

  fCanvas.Pen.Color:=clBlack;
  fCanvas.Pen.Style:=psDot;


  fCanvas.PenPos:=point(fHeaders.items[2].Left,instructioncenter);
  fCanvas.LineTo(fHeaders.items[2].Left-offset,instructioncenter);
  fCanvas.LineTo(fHeaders.items[2].Left-offset,yposition);
  fCanvas.LineTo(fHeaders.items[2].Left,yposition);

  fCanvas.Pen.Style:=oldpenstyle;
  if showendtriangle then
  begin
    fCanvas.Brush.Style:=bsSolid; //should be the default, but in case something fucked with it (not in the planning, never intended, so even if someone did do it, I'll undo it)
    fCanvas.Brush.Color:=clblack;
    fCanvas.Polygon([point(fheaders.items[2].Left-4,yposition-4),point(fheaders.items[2].Left,yposition),point(fheaders.items[2].Left-4,yposition+4)]);
  end;
  fCanvas.Brush.Color:=oldbrushcolor;
  fCanvas.Pen.Color:=oldpencolor;

end;

function TDisassemblerLine.isJumpOrCall(var addressitjumpsto: dword): boolean;
begin
  result:=fisJump;
  if result then
    addressitjumpsto:=fJumpsTo;
end;

function TDisassemblerLine.truncatestring(s: string; maxwidth: integer): string;
var dotsize: integer;
begin
  if fCanvas.TextWidth(s)>maxwidth then
  begin
    dotsize:=fCanvas.TextWidth('...');
    maxwidth:=maxwidth-dotsize;
    if maxwidth<=0 then
    begin
      result:=''; //it's too small for '...'
      exit;
    end;

    while fCanvas.TextWidth(s)>maxwidth do
      s:=copy(s,1,length(s)-1);

    result:=s+'...';
  end else result:=s; //it fits
end;


function TdisassemblerLine.buildReferencedByString: string;
var addresses: tdissectarray;
    i: integer;
begin
  result:='';
  setlength(addresses,0);

  if (frmDissectCode<>nil) and (frmDissectCode.dissectcode<>nil) and (frmDissectCode.dissectcode.done) then
  begin
    if frmDissectCode.dissectcode.CheckAddress(address, addresses) then
    begin
      for i:=0 to length(addresses)-1 do
      begin
        case addresses[i].jumptype of
          jtUnconditional:
            result:=result+' '+inttohex(addresses[i].address,8)+'(Un)';

          jtConditional:
            result:=result+' '+inttohex(addresses[i].address,8)+'(Con)';

          jtCall:
            result:=result+' '+inttohex(addresses[i].address,8)+'(Call)';
        end;
      end;
    end;
  end;
end;

procedure TDisassemblerLine.renderLine(var address: dword; linestart: integer; selected: boolean=false; focused: boolean=false);
var isbp: boolean;
    baseofsymbol: dword;
    symbolname: string;
    refferencedby: string;
    refferencedbylinecount: integer;
    refferencedbyheight: integer;
    refferencedbystrings: array of string;
    i,j: integer;

    paddressstring: pchar;
    pbytestring: pchar;
    popcodestring: pchar;
    pspecialstring: pchar;

    textcolor: TColor;
begin
  top:=linestart;
  faddress:=address;

  fisJump:=cefuncproc.isjumporcall(faddress, fJumpsTo);


  height:=0;
  baseofsymbol:=0;
  symbolname:=symhandler.getNameFromAddress(address,symhandler.showsymbols,symhandler.showmodules,@baseofsymbol);

  if (baseofsymbol>0) and (faddress=baseofsymbol) then
  begin
    if textheight=-1 then
      textheight:=fcanvas.TextHeight(symbolname);

    height:=height+textheight+1+10;
  end;

  refferencedbylinecount:=0;
  if (frmDissectCode<>nil) and (frmDissectCode.dissectcode<>nil) and (frmDissectCode.dissectcode.done) then
  begin
    refferencedby:=buildReferencedByString;
    if refferencedby<>'' then
    begin
      fcanvas.Font.Style:=[fsBold, fsItalic];
      if referencedbylineheight=-1 then
        referencedbylineheight:=fcanvas.textheight('xxx');

      refferencedbylinecount:=1+(fcanvas.TextWidth(refferencedby) div (fbitmap.width - 10 ));

      setlength(refferencedbystrings, refferencedbylinecount);

      j:=1;
      i:=0;
      refferencedbyheight:=0;
      while (j<=length(refferencedby)) do
      begin
        refferencedbystrings[i]:='';
        while (fcanvas.TextWidth(refferencedbystrings[i])<(fbitmap.width-10)) and (j<=length(refferencedby)) do
        begin
          refferencedbystrings[i]:=refferencedbystrings[i]+refferencedby[j];
          inc(j);
        end;

        refferencedbyheight:=refferencedbyheight+referencedbylineheight;

        inc(i);
      end;

      height:=height+refferencedbyheight;
      fcanvas.Font.Style:=[];
    end;
  end;

  fdisassembled:=disassemble(address,fdescription);


  if boldheight=-1 then
  begin
    fcanvas.Font.Style:=[fsbold];
    boldheight:=fcanvas.TextHeight(fdisassembled)+1;
    fcanvas.Font.Style:=[];
  end;

  height:=height+boldheight+1;


  isbp:=((kdebugger.isactive) and (kdebugger.isExecutableBreakpoint(faddress))) or
        ((debuggerthread<>nil) and (debuggerthread.userisdebugging) and (debuggerthread.isBreakpoint(faddress)));
  
  if selected then
  begin
    if not isbp then
    begin
      //default
      if not focused then
      begin
        fcanvas.Brush.Color:=clGradientActiveCaption;
        fcanvas.Font.Color:=clHighlightText;
      end
      else
      begin
        fcanvas.Brush.Color:=clHighlight;
        fcanvas.Font.Color:=clHighlightText;
      end;
    end
    else
    begin
      //it's a breakpoint
      fCanvas.Brush.Color:=clGreen;
      fCanvas.font.Color:=clWhite;
    end;
    fcanvas.Refresh;



  end
  else
  begin
    //not selected
    if isbp then
    begin
      fCanvas.Brush.Color:=clRed;
      fCanvas.font.Color:=clBlack;
      fcanvas.Refresh
    end else
    begin
      fcanvas.Brush.Color:=clBtnFace;
      fcanvas.Font.Color:=clWindowText;
      fcanvas.Refresh
    end;
  end;
  fcanvas.FillRect(rect(0,top,fbitmap.width,top+height));

  if (baseofsymbol>0) and (faddress=baseofsymbol) then
  begin
    fcanvas.Font.Style:=[fsbold];
    fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart+5,symbolname);
    linestart:=linestart+fcanvas.TextHeight(symbolname)+1+10;
    fcanvas.Font.Style:=[];
  end;

  if (refferencedbylinecount>0) then
  begin
    fcanvas.Font.Style:=[fsBold,fsItalic];
    for i:=0 to refferencedbylinecount-1 do
    begin
      fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart,refferencedbystrings[i]);
      linestart:=linestart+fcanvas.TextHeight(refferencedbystrings[i]);
    end;
    fcanvas.Font.Style:=[];

  end;


  splitDisassembledString(fdisassembled, true, addressstring, bytestring, opcodestring, specialstring, @MemoryBrowser.lastdebugcontext);
  if symhandler.showmodules then
    addressString:=symbolname
  else
    addressString:=truncatestring(addressString, fHeaders.Items[0].Width-2);

  bytestring:=truncatestring(bytestring, fHeaders.Items[1].Width-2);
  opcodestring:=truncatestring(opcodestring, fHeaders.Items[2].Width-2);
  specialstring:=truncatestring(specialstring, fHeaders.Items[3].Width-2);

  if MemoryBrowser.lastdebugcontext.EIP=faddress then
    addressString:='>>'+addressString;


  //set pointers to strings
  paddressstring:=@addressstring[1];
  pbytestring:=@bytestring[1];
  popcodestring:=@opcodestring[1];
  pspecialstring:=@specialstring[1];


  textcolor:=fcanvas.Font.Color;
  handledisassemblerplugins(@paddressString, @pbytestring, @popcodestring, @pspecialstring, @textcolor);
  fcanvas.font.color:=textcolor;


  fcanvas.TextRect(rect(fHeaders.Items[0].Left, linestart, fHeaders.Items[0].Right, linestart+height), fHeaders.Items[0].Left+1,linestart, paddressString);
  fcanvas.TextRect(rect(fHeaders.Items[1].Left, linestart, fHeaders.Items[1].Right, linestart+height),fHeaders.Items[1].Left+1,linestart, pbytestring);
  fcanvas.TextRect(rect(fHeaders.Items[2].Left, linestart, fHeaders.Items[2].Right, linestart+height),fHeaders.Items[2].Left+1,linestart, popcodestring);
  fcanvas.TextRect(rect(fHeaders.Items[3].Left, linestart, fHeaders.Items[3].Right, linestart+height),fHeaders.Items[3].Left+1,linestart, pspecialstring);

  fInstructionCenter:=linestart+(fcanvas.TextHeight(opcodestring) div 2);

  if focused then
      fcanvas.DrawFocusRect(rect(0,top,fbitmap.width,top+height));

  if selected then //restore
  begin
    fcanvas.Brush.Color:=clBtnFace;
    fcanvas.Font.Color:=clWindowText;
    fcanvas.Refresh;
  end;
end;

procedure TDisassemblerLine.handledisassemblerplugins(addressStringPointer: pointer; bytestringpointer: pointer; opcodestringpointer: pointer; specialstringpointer: pointer; textcolor: PColor);
begin
  pluginhandler.handledisassemblerplugins(faddress, addressStringPointer, bytestringpointer, opcodestringpointer, specialstringpointer, textcolor);
end;

function TDisassemblerLine.getHeight: integer;
begin
  result:=height;
end;

function TDisassemblerLine.getTop: integer;
begin
  result:=top;
end;

constructor TDisassemblerLine.create(bitmap: TBitmap; headersections: THeaderSections);
begin
  fCanvas:=bitmap.canvas;
  fBitmap:=bitmap;
  fheaders:=headersections;
  boldheight:=-1; //bypass for memory leak
  textheight:=-1;
  referencedbylineheight:=-1;

  height:=fCanvas.TextHeight('X');
end;

end.
