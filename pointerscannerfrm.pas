unit pointerscannerfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, syncobjs,syncobjs2, Menus, math,
  frmRescanPointerUnit, pointervaluelist, rescanhelper, 
  virtualmemory, symbolhandler,mainunit,disassembler,cefuncproc,newkernelhandler,
  valuefinder, PointerscanresultReader;


const staticscanner_done=wm_user+1;
const rescan_done=wm_user+2;
const open_scanner=wm_user+3;

type
  TfrmPointerscanner = class;
  TRescanWorker=class(TThread)
  private
    procedure flushresults;
    function isMatchToValue(p: pointer): boolean;
  public
    filename: string;
    tempfile: tfilestream;
    tempbuffer: TMemoryStream;

    PointerAddressToFind: dword;
    forvalue: boolean;
    valuetype: TVariableType;
    valuescandword: dword;
    valuescansingle: single;
    valuescandouble: double;
    valuescansinglemax: single;
    valuescandoublemax: double;


    //---
    Pointerscanresults: TPointerscanresultReader;

    startentry: uint64;
    EntriesToCheck: uint64;

    rescanhelper: TRescanhelper;

    evaluated: uint64;
    procedure execute; override;
    destructor destroy; override;
  end;


  Trescanpointers=class(tthread)
  private
    procedure closeOldFile;
  public
    ownerform: TFrmPointerScanner;
    progressbar: tprogressbar;
    filename: string;
    overwrite: boolean;
    address: dword;
    forvalue: boolean;
    valuetype: TVariableType;
    valuescandword: dword;
    valuescansingle: single;
    valuescandouble: double;
    valuescansinglemax: single;
    valuescandoublemax: double;

    procedure execute; override;
  end;



  toffsetlist = array of dword;

  TStaticscanner = class;

  TReverseScanWorker = class (tthread)
  private
    offsetlist: array of dword;
    results: tmemorystream;
    resultsfile: tfilestream;


    procedure flushresults;
    procedure rscan(valuetofind:dword; level: integer);
    procedure StorePath(level: integer; staticdata: PStaticData);

  public
    ownerform: TFrmPointerscanner;
    valuetofind: dword;
    maxlevel: integer;
    structsize: integer;
//    startaddress: dword;
    startlevel: integer;
    alligned: boolean;
    staticonly: boolean;

    isdone: boolean;
    startworking: tevent;
    stop: boolean;

    staticscanner: TStaticscanner;
    tempresults: array of dword;


    //info:
    currentaddress: pointer;
    currentlevel: integer;
    LookingForMin: dword;
    LookingForMax: dword;
    lastaddress: dword;
    
    filename: string;

    haserror: boolean;
    errorstring: string;

    procedure execute; override;
    constructor create(suspended: boolean);
    destructor destroy; override;
  end;


  TStaticscanner = class(TThread)
  private
    updateline: integer; //not used for addentry

    memoryregion: array of tmemoryregion;

    reversescanners: array of treversescanworker;

    function ismatchtovalue(p: pointer): boolean;  //checks if the pointer points to a value matching the user's input
    procedure reversescan;

  public
    //reverse
    firstaddress: pointer;
    currentaddress: pointer;
    lastaddress: pointer;

    lookingformin: dword;
    lookingformax: dword;

    reverseScanCS: TCriticalSection;
        
    //reverse^

    ownerform: TfrmPointerscanner;
    
    reverse: boolean;
    automatic: boolean;
    automaticaddress: dword;

    start: dword;
    stop: dword;
    progressbar: TProgressbar;
    sz,sz0: integer;
    maxlevel: integer;
    unalligned: boolean;
    codescan: boolean;


    fast: boolean;
    psychotic: boolean;
    writableonly: boolean;
    unallignedbase: boolean;

    useheapdata: boolean;
    useOnlyHeapData: boolean;

    findValueInsteadOfAddress: boolean;
    valuetype: TVariableType;
    valuescandword: dword;
    valuescansingle: single;
    valuescandouble: double;
    valuescansinglemax: single;
    valuescandoublemax: double;


    mustEndWithSpecificOffset: boolean;
    mustendwithoffsetlist: array of dword;
    onlyOneStaticInPath: boolean;


    threadcount: integer;
    scannerpriority: TThreadPriority;

    filename: string; //the final filename
    phase: integer;
    currentpos: ^Dword;

    starttime: dword;

    isdone: boolean;

    staticonly: boolean; //for reverse

    pointersfound: uint64;

    hasError: boolean;
    errorString: string;

    procedure execute; override;
    destructor destroy; override;
  end;

  Tfrmpointerscanner = class(TForm)
    ProgressBar1: TProgressBar;
    Panel1: TPanel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    New1: TMenuItem;
    N2: TMenuItem;
    Open1: TMenuItem;
    Pointerscanner1: TMenuItem;
    Method3Fastspeedandaveragememoryusage1: TMenuItem;
    N1: TMenuItem;
    Rescanmemory1: TMenuItem;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    Timer2: TTimer;
    pgcPScandata: TPageControl;
    tsPSReverse: TTabSheet;
    tvRSThreads: TTreeView;
    Panel2: TPanel;
    Label5: TLabel;
    lblRSTotalStaticPaths: TLabel;
    Panel3: TPanel;
    btnStopScan: TButton;
    Label6: TLabel;
    ListView1: TListView;
    PopupMenu1: TPopupMenu;
    Resyncmodulelist1: TMenuItem;
    cbType: TComboBox;
    procedure Method3Fastspeedandaveragememoryusage1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Rescanmemory1Click(Sender: TObject);
    procedure btnStopScanClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure New1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure Resyncmodulelist1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure cbTypeChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    start:tdatetime;

    rescan: trescanpointers;
    cewindowhandle: thandle;
    pointerlisthandler: TReversePointerListHandler;   //handled by the form for easy reuse

    procedure m_staticscanner_done(var message: tmessage); message staticscanner_done;
    procedure rescandone(var message: tmessage); message rescan_done;
    procedure openscanner(var message: tmessage); message open_scanner;
    procedure doneui;
    procedure resyncloadedmodulelist;
    procedure OpenPointerfile(filename: string);
  public
    { Public declarations }
    Staticscanner:TStaticScanner;

    Pointerscanresults: TPointerscanresultReader;
        {
    OpenedPointerfile: record
      filename: string;
      pointerfile: Tfilestream;
      modulelist: Tstringlist;
      offsetlength: integer;
      StartPosition: integer;
      SizeOfEntry: integer;
      TotalPointers: uint64;
    end;

    tempoffset: array of dword; //used by ondata
    }

  end;

{$ifdef benchmarkps}
var
  totalpathsevaluated: uint64;

  starttime: dword;
  startcount: uint64;
{$endif}
           


implementation

{$R *.dfm}

uses PointerscannerSettingsFrm, frmMemoryAllocHandlerUnit;


//----------------------- scanner info --------------------------
//----------------------- staticscanner -------------------------




procedure TFrmpointerscanner.doneui;
begin
  progressbar1.position:=0;

  pgcPScandata.Visible:=false;
  open1.Enabled:=true;
  new1.enabled:=true;
  rescanmemory1.Enabled:=true;

  if staticscanner<>nil then
    OpenPointerfile(staticscanner.filename);

  if rescan<>nil then
  begin
    OpenPointerfile(rescan.filename);
    freeandnil(rescan);
  end;
end;

procedure Tfrmpointerscanner.m_staticscanner_done(var message: tmessage);
var x: tfilestream;
    result: tfilestream;
    i: integer;
    temp: dword;
    tempstring: string;
begin
{$ifdef benchmarkps}
  showmessage(format('Evaluated: %d Time: %d  (%d / s)',[totalpathsevaluated-startcount, ((gettickcount-starttime) div 1000), trunc(((totalpathsevaluated-startcount)/((gettickcount-starttime) / 1000))) ]));
{$endif}

  if staticscanner=nil then exit;

{$ifndef injectedpscan}
  if staticscanner.useHeapData then
    frmMemoryAllocHandler.displaythread.Resume; //continue adding new entries
{$endif}


  //update the treeview
  if message.WParam<>0 then
  begin
    messagedlg('Error during scan: '+pchar(message.LParam), mtError, [mbok] ,0);


  end;


  doneui;



end;







procedure TReverseScanWorker.flushresults;
begin
  resultsfile.WriteBuffer(results.Memory^,results.Position);
  results.Seek(0,sofrombeginning);
 // results.Clear;
end;

constructor TReverseScanWorker.create(suspended:boolean);
begin
  results:=tmemorystream.Create;
  results.SetSize(16*1024*1024);

  startworking:=tevent.create(nil,false,false,'');
  isdone:=true;

  inherited create(suspended);
end;

destructor TReverseScanWorker.destroy;
begin
  results.free;
  if resultsfile<>nil then
    freeandnil(resultsfile);

  startworking.free;
end;

procedure TReverseScanWorker.execute;
var wr: twaitresult;
i: integer;
begin
  try
    try
      resultsfile:= tfilestream.Create(filename,fmcreate);
      resultsfile.free;
      resultsfile:= tfilestream.Create(filename,fmOpenWrite or fmShareDenyNone);

      while not terminated do
      begin
        wr:=startworking.WaitFor(infinite);
        if stop then exit;

        if wr=wrSignaled then
        begin
          try
            rscan(valuetofind,startlevel);
          finally
            isdone:=true;  //set isdone to true
          end;
        end;
      end;

    except
      on e: exception do
      begin
        haserror:=true;
        errorstring:='ReverseScanWorker:'+e.message;

        //tell all siblings they should terminate
        staticscanner.reverseScanCS.Enter;
        for i:=0 to length(staticscanner.reversescanners)-1 do
          staticscanner.reversescanners[i].Terminate;

        staticscanner.reverseScanCS.leave;
        terminate;
      end;
    end;
  finally
    isdone:=true;
  end;

end;


var fcount:uint64=0;
var scount:uint64=0;

procedure TReverseScanWorker.StorePath(level: integer; staticdata: PStaticData);
{Store the current path to memory and flush if needed}
var i: integer;
    x: dword;

    foundstatic: boolean;
    mi: tmoduleinfo;
begin
  inc(fcount); //increme
  if (staticdata=nil) then exit; //don't store it

  inc(scount);

  //fill in the offset list
  inc(staticscanner.pointersfound);

  //for i:=0 to level do
  //  offsetlist[level-i]:=tempresults[i];

  results.WriteBuffer(staticdata.moduleindex, sizeof(staticdata.moduleindex));
  results.WriteBuffer(staticdata.offset,sizeof(staticdata.offset));
  i:=level+1; //store many offsets are actually used (since all are saved)
  results.WriteBuffer(i,sizeof(i));
  results.WriteBuffer(tempresults[0], maxlevel*sizeof(tempresults[0]) );

  if results.position>15*1024*1024 then //bigger than 15mb
    flushresults;

end;

procedure TReverseScanWorker.rscan(valuetofind:dword; level: integer);
{
scan through the memory for a address that points in the region of address, if found, recursive call till level maxlevel
}
var p: ^byte;
    pd: ^dword absolute p;
    maxaddress: dword;
    AddressMinusMaxStructSize: dword;
    found: boolean;
    i,j,k: integer;
    createdworker: boolean;

    mi: tmoduleinfo;
    mbi: _MEMORY_BASIC_INFORMATION;

    ExactOffset: boolean;
{$ifndef injectedpscan}
    mae: TMemoryAllocEvent;
{$endif}

  originalStartvalue: dword;
  startvalue: dword;
  stopvalue: dword;
  plist: PPointerlist;

  nostatic: TStaticData;
  DontGoDeeper: boolean;
begin
  {$ifdef benchmarkps}
  inc(totalpathsevaluated);
  {$endif}     

  currentlevel:=level;
  if (level>=maxlevel) then 
    exit;

  if self.staticscanner.Terminated then
    exit;


 {
  p:=vm.GetBuffer;  }

  exactOffset:=staticscanner.mustEndWithSpecificOffset and (length(staticscanner.mustendwithoffsetlist)-1>=level);

  if exactOffset then
  begin
    startvalue:=valuetofind-staticscanner.mustendwithoffsetlist[level];
    stopvalue:=startvalue;
  end
  else
  begin
    startvalue:=valuetofind-structsize;
    stopvalue:=valuetofind;

    if staticscanner.useheapdata then
    begin
      mae:=frmMemoryAllocHandler.FindAddress(@frmMemoryAllocHandler.HeapBaselevel, valuetofind);
      if mae<>nil then
      begin
        exactoffset:=true;
        startvalue:=mae.BaseAddress;
        stopvalue:=startvalue;
      end
      else //not static and not in heap
       if staticscanner.useOnlyHeapData then
         exit;
    end;
  end;
 {
  maxaddress:=dword(p)+vm.GetBufferSize;   }
  lastaddress:=maxaddress;

  LookingForMin:=startvalue;
  LookingForMax:=stopvalue;


  found:=false;
  dontGoDeeper:=false;
  while stopvalue>=startvalue do
  begin
    plist:=ownerform.pointerlisthandler.findPointerValue(startvalue, stopvalue);
    if plist<>nil then
    begin
      found:=true;
      for j:=0 to plist.pos-1 do
      begin

        tempresults[level]:=valuetofind-stopvalue; //store the offset
        if (plist.list[j].staticdata=nil) then
        begin
          if (not dontGoDeeper) then
          begin
            //check if whe should go deeper into these results (not if max level has been reached)

            if (level+1) >= maxlevel then
            begin
              if (not staticonly) then //store this results entry
              begin
                nostatic.moduleindex:=$FFFFFFFF;
                nostatic.offset:=plist.list[j].address;
                StorePath(level,@nostatic);
              end;
            end
            else
            begin
              //not at max level, so scan for it
              //scan for this address
              //either spawn of a new thread that can do this, or do it myself

              createdworker:=false;
              staticscanner.reverseScanCS.Enter;

              //scan the worker thread array for a idle one, if found use it
              for i:=0 to length(staticscanner.reversescanners)-1 do
              begin
                if staticscanner.reversescanners[i].isdone then
                begin
                  staticscanner.reversescanners[i].isdone:=false;
                  staticscanner.reversescanners[i].maxlevel:=maxlevel;
                  staticscanner.reversescanners[i].valuetofind:=plist.list[j].address;

                  for k:=0 to maxlevel-1 do
                    staticscanner.reversescanners[i].tempresults[k]:=tempresults[k]; //copy results

                  staticscanner.reversescanners[i].startlevel:=level+1;
                  staticscanner.reversescanners[i].structsize:=structsize;
                  staticscanner.reversescanners[i].startworking.SetEvent;
                  createdworker:=true;
                  break;
                end;
              end;

              staticscanner.reverseScanCS.Leave;


              if not createdworker then
              begin
                //I'll have to do it myself
                rscan(plist.list[j].address,level+1);
              end;
            end;
          end;
        end
        else
        begin
          //found a static one
          StorePath(level, plist.list[j].staticdata);

          if staticscanner.onlyOneStaticInPath then DontGoDeeper:=true;
        end;
      end;

      if not staticscanner.unalligned then
        stopvalue:=stopvalue-4
      else
        stopvalue:=stopvalue-1;
        
    end else
    begin
     { if (not found) and (not staticonly) then
      begin
        //nothing was found, let's just say this is the final level and store it...

        if level>0 then
        begin
          nostatic.moduleindex:=$FFFFFFFF;
          nostatic.offset:=startvalue;
          StorePath(level-1);
        end;

      end;}
      exit;
    end;

  end;
end;


//--------------------------STATICSCANNER------------------
function TStaticScanner.ismatchtovalue(p: pointer): boolean;
begin
  case valuetype of
    vtDword: result:=pdword(p)^=valuescandword;
    vtSingle: result:=(psingle(p)^>=valuescansingle) and (psingle(p)^<valuescansinglemax);
    vtDouble: result:=(pdouble(p)^>=valuescandouble) and (pdouble(p)^<valuescandoublemax);
  end;
end;

procedure TStaticScanner.reversescan;
{
Do a reverse pointer scan
}
var p: ^byte;
    pd: ^dword absolute p;
    maxaddress: dword;
    automaticAddressMinusMaxStructSize: dword;

    results: array of dword;
    i,j: integer;
    alldone: boolean;
    {$ifdef injectedpscan}
    mbi: _MEMORY_BASIC_INFORMATION;
    {$endif}

    exactoffset: boolean;
{$ifndef injectedpscan}
    mae: TMemoryAllocEvent;
{$endif}

  startvalue: dword;
  stopvalue: dword;

  plist: PPointerList;

  currentaddress: integer;
  createdWorker: boolean;

  valuefinder: TValueFinder;
begin
  //scan the buffer
  fcount:=0; //debug counter to 0
  scount:=0;
  alldone:=false;

  if maxlevel>0 then
  begin
    setlength(results,maxlevel);

    //initialize the first reverse scan worker
    //that one will spawn of all his other siblings if needed

    if Self.findValueInsteadOfAddress then
    begin
      //scan the memory for the value
      ValueFinder:=TValueFinder.create(start,stop);
      ValueFinder.alligned:=not unalligned;
      ValueFinder.valuetype:=valuetype;
      ValueFinder.valuescandword:=valuescandword;
      ValueFinder.valuescansingle:=valuescansingle;
      ValueFinder.valuescandouble:=valuescandouble;
      ValueFinder.valuescansinglemax:=valuescansinglemax;
      ValueFinder.valuescandoublemax:=valuescandoublemax;

      currentaddress:=dword(ValueFinder.FindValue(start));
      while currentaddress>0 do
      begin
        //if found, find a idle thread and tell it to look for this address starting from level 0 (like normal)
        createdWorker:=false;
        while not createdworker do
        begin
          reversescancs.Enter;
          try
            for i:=0 to length(reversescanners)-1 do
              if reversescanners[i].isdone then
              begin
                reversescanners[i].isdone:=false;
                reversescanners[i].maxlevel:=maxlevel;

                reversescanners[i].valuetofind:=currentaddress;
                reversescanners[i].structsize:=sz;
                reversescanners[i].startlevel:=0;
                reversescanners[i].startworking.SetEvent;
                reversescancs.Leave;
                createdworker:=true;
                break;
              end;
          finally
            reversescancs.Leave;
          end;
          
          if not createdworker then
            sleep(500) //note: change this to an event based wait
          else
          begin //next
            if unalligned then
              currentaddress:=dword(ValueFinder.FindValue(currentaddress+1))
            else
              currentaddress:=dword(ValueFinder.FindValue(currentaddress+4));
          end;
        end;

      end;

      //done with the value finder, wait till all threads are done
      valuefinder.free;
    end
    else
    begin
      //initialize the first thread (it'll spawn all other threads)
      reversescanners[0].isdone:=false;
      reversescanners[0].maxlevel:=maxlevel;

      reversescanners[0].valuetofind:=self.automaticaddress;
      reversescanners[0].structsize:=sz;
      reversescanners[0].startlevel:=0;
      reversescanners[0].startworking.SetEvent;
    end;

    //wait till all threads are in isdone state
    while (not alldone) do
    begin
      sleep(500);
      alldone:=true;

      //no need for a CS here since it's only a read, and even when a new thread is being made, the creator also has the isdone boolean to false
      for i:=0 to length(reversescanners)-1 do
      begin
        if reversescanners[i].haserror then
        begin
          haserror:=true;
          errorstring:=reversescanners[i].errorstring;

          for j:=0 to length(reversescanners)-1 do reversescanners[j].terminate; //even though the reversescanner already should have done this, let's do it myself as well

          alldone:=true; 
          break;
        end;

        if not reversescanners[i].isdone then
        begin
          alldone:=false;
          break;
        end;
      end;
    end;
  end;

  isdone:=true;


  //all threads are done
  for i:=0 to length(reversescanners)-1 do
  begin
    reversescanners[i].stop:=true;
    reversescanners[i].startworking.SetEvent;  //run it in case it was waiting
    reversescanners[i].WaitFor; //wait till this thread has terminated because the main thread has terminated
    if not haserror then
      reversescanners[i].flushresults;  //write unsaved results to disk
    reversescanners[i].Free;
    reversescanners[i]:=nil;
  end;

  setlength(reversescanners,0);

  if haserror then
    postmessage(ownerform.Handle,staticscanner_done,1,dword(pchar(errorstring)))
  else
    postmessage(ownerform.Handle,staticscanner_done,0,maxlevel);
  terminate;
end;

procedure TStaticScanner.execute;
var
    i,j,k: integer;
    x,opcode:string;

    t:dword;
    hexcount,hexstart: integer;
    isstruct: boolean;
    isstatic: boolean;
    found: boolean;

    mbi: _MEMORY_BASIC_INFORMATION;

    tn,tempnode: ttreenode;
    lastnode: ttreenode;
    oldshowsymbols: boolean;
    oldshowmodules: boolean;


    bitcount: integer;

    scanregions: tmemoryregions;
    currentregion: integer;
    maxpos: dword;
    dw: byte;

    result: tfilestream;
    temp: dword;
    tempstring: string;
begin
  if terminated then exit;
  try

    if ownerform.pointerlisthandler=nil then
    begin
      phase:=1;
      progressbar.Position:=0;
      try
        ownerform.pointerlisthandler:=TReversePointerListHandler.Create(start,stop,not unalligned,progressbar);
      except
        postmessage(ownerform.Handle,staticscanner_done,1,dword(pchar('Failure copying target process memory'))); //I can just priovide this string as it's static in the .code section
        terminate;
        exit;
      end;
    end; 


    phase:=2;
    progressbar.Position:=0;
  
    currentpos:=pointer(start);





    i:=0;

    if reverse then  //always true since 5.6
    begin
      maxlevel:=maxlevel-1; //for reversescan
      reverseScanCS:=tcriticalsection.Create;
      try
        setlength(reversescanners,threadcount);
        for i:=0 to threadcount-1 do
        begin
          reversescanners[i]:=TReverseScanWorker.Create(true);
          reversescanners[i].ownerform:=ownerform;
          reversescanners[i].Priority:=scannerpriority;
          reversescanners[i].staticscanner:=self;
          setlength(reversescanners[i].tempresults,maxlevel);
          setlength(reversescanners[i].offsetlist,maxlevel);
          reversescanners[i].staticonly:=staticonly;
          reversescanners[i].alligned:=not self.unalligned;
          reversescanners[i].filename:=self.filename+'.'+inttostr(i);

          reversescanners[i].Resume;
        end;

        //create the headerfile
        result:=TfileStream.create(filename,fmcreate or fmShareDenyWrite);

        //save header (modulelist, and levelsize)
        ownerform.pointerlisthandler.saveModuleListToResults(result);

        //levelsize
        result.Write(maxlevel,sizeof(maxlevel)); //write max level (maxlevel is provided in the message (it could change depending on the settings)

        //pointerstores
        temp:=length(reversescanners);
        result.Write(temp,sizeof(temp));
        for i:=0 to length(reversescanners)-1 do
        begin
          tempstring:=ExtractFileName(reversescanners[i].filename);
          temp:=length(tempstring);
          result.Write(temp,sizeof(temp));
          result.Write(tempstring[1],temp);
        end;

        result.Free;


        reversescan;
      finally
        freeandnil(reverseScanCS);
      end;

    end;


  except
    on e: exception do
    begin
      haserror:=true;
      errorstring:='StaticScanner:'+e.message;
      postmessage(ownerform.Handle,staticscanner_done,1,dword(pchar(errorstring))); //I can just priovide this string as it's static in the .code section
      terminate;
    end;
  end;

  terminate;

  {
  if (vm<>nil) and (not reuse) then
    freeandnil(vm);   }
    
end;


destructor TStaticscanner.destroy;
begin
  terminate;
  waitfor;

  //clean up other stuff
  inherited destroy;
end;

//---------------------------------main--------------------------

procedure Tfrmpointerscanner.Method3Fastspeedandaveragememoryusage1Click(
  Sender: TObject);
var
  i: integer;
  floataccuracy: integer;
  floatsettings: TFormatSettings;
begin
  GetLocaleFormatSettings(GetThreadLocale, FloatSettings);
  
  start:=now;
  if frmpointerscannersettings=nil then
    frmpointerscannersettings:=tfrmpointerscannersettings.create(nil);

  if frmpointerscannersettings.Visible then exit; //already open, so no need to make again

  {
  if vm<>nil then
    frmpointerscannersettings.cbreuse.Caption:='Reuse memory copy from previous scan';}

  if frmpointerscannersettings.Showmodal=mrok then
  begin
    new1.click;

    if not savedialog1.Execute then exit;
        

    pgcPScandata.Visible:=false;
    open1.Enabled:=false;
    new1.enabled:=false;
    rescanmemory1.Enabled:=false;

    cbType.Visible:=false;
    listview1.Visible:=false;


    timer2.Enabled:=true;

    //initialize array's




    //default scan
    staticscanner:=TStaticscanner.Create(true);

    try
      staticscanner.ownerform:=self;
      staticscanner.filename:=savedialog1.FileName;
      staticscanner.reverse:=true; //since 5.6 this is always true

      staticscanner.start:=frmpointerscannersettings.start;
      staticscanner.stop:=frmpointerscannersettings.Stop;

      staticscanner.unalligned:=not frmpointerscannersettings.CbAlligned.checked;
      pgcPScandata.ActivePage:=tsPSReverse;
      tvRSThreads.Items.Clear;


      staticscanner.codescan:=frmpointerscannersettings.codescan;
      staticscanner.staticonly:=frmpointerscannersettings.cbStaticOnly.checked;

      staticscanner.automatic:=true;

      staticscanner.automaticaddress:=frmpointerscannersettings.automaticaddress;
      staticscanner.sz:=frmpointerscannersettings.structsize;
      staticscanner.sz0:=frmpointerscannersettings.level0structsize;
      staticscanner.maxlevel:=frmpointerscannersettings.maxlevel;

      staticscanner.progressbar:=progressbar1;
      staticscanner.threadcount:=frmpointerscannersettings.threadcount;
      staticscanner.scannerpriority:=frmpointerscannersettings.scannerpriority;

      staticscanner.mustEndWithSpecificOffset:=frmpointerscannersettings.cbMustEndWithSpecificOffset.checked;
      if staticscanner.mustEndWithSpecificOffset then
      begin
        setlength(staticscanner.mustendwithoffsetlist, frmpointerscannersettings.offsetlist.count);
        for i:=0 to frmpointerscannersettings.offsetlist.count-1 do
          staticscanner.mustendwithoffsetlist[i]:=TOffsetEntry(frmpointerscannersettings.offsetlist[i]).offset;
      end;

      staticscanner.onlyOneStaticInPath:=frmpointerscannersettings.cbOnlyOneStatic.checked;

{$ifndef injectedpscan}
      staticscanner.useHeapData:=frmpointerscannersettings.cbUseHeapData.Checked;
      staticscanner.useOnlyHeapData:=frmpointerscannersettings.cbHeapOnly.checked;


      if staticscanner.useHeapData then
        frmMemoryAllocHandler.displaythread.Suspend; //stop adding entries to the list
{$endif}        

      //check if the user choose to scan for addresses or for values
      staticscanner.findValueInsteadOfAddress:=frmpointerscannersettings.rbFindValue.checked;
      if staticscanner.findValueInsteadOfAddress then
      begin
        //if values, check what type of value
        floataccuracy:=pos(FloatSettings.DecimalSeparator,frmpointerscannersettings.edtAddress.Text);
        if floataccuracy>0 then
          floataccuracy:=length(frmpointerscannersettings.edtAddress.Text)-floataccuracy;

        case frmpointerscannersettings.cbValueType.ItemIndex of
          0:
          begin
            staticscanner.valuetype:=vtDword;
            val(frmpointerscannersettings.edtAddress.Text, staticscanner.valuescandword, i);
            if i>0 then raise exception.Create(frmpointerscannersettings.edtAddress.Text+' is not a valid 4 byte value');
          end;

          1:
          begin
            staticscanner.valuetype:=vtSingle;
            val(frmpointerscannersettings.edtAddress.Text, staticscanner.valuescansingle, i);
            if i>0 then raise exception.Create(frmpointerscannersettings.edtAddress.Text+' is not a valid floating point value');
            staticscanner.valuescansingleMax:=staticscanner.valuescansingle+(1/(power(10,floataccuracy)));
          end;

          2:
          begin
            staticscanner.valuetype:=vtDouble;
            val(frmpointerscannersettings.edtAddress.Text, staticscanner.valuescandouble, i);
            if i>0 then raise exception.Create(frmpointerscannersettings.edtAddress.Text+' is not a valid double value');
            staticscanner.valuescandoubleMax:=staticscanner.valuescandouble+(1/(power(10,floataccuracy)));            
          end;
        end;
      end;


      progressbar1.Max:=staticscanner.stop-staticscanner.start;


      open1.Enabled:=false;
      staticscanner.starttime:=gettickcount;
      staticscanner.Resume;


      pgcPScandata.Visible:=true;

      Method3Fastspeedandaveragememoryusage1.Enabled:=false;
    except
      on e: exception do
      begin
        staticscanner.Free;
        staticscanner:=nil;
        raise e;
      end;
    end;

  end;
end;

procedure Tfrmpointerscanner.Timer2Timer(Sender: TObject);
var i,j,l: integer;
    s: string;
    a: string;
    smallestaddress: dword;
    todo: dword;
    done: dword;
    donetime,todotime: integer;
    oneaddresstime: double;
    _h,_m,_s: integer;
    tn,tn2: TTreenode;
begin
  if listview1.Visible then
    listview1.repaint;

  if pointerlisthandler<>nil then
    label6.caption:='Address specifiers found in the whole process:'+inttostr(pointerlisthandler.count);

  if staticscanner<>nil then
  try
    if staticscanner.isdone then
    begin
      if tvRSThreads.Items.Count>0 then
        tvRSThreads.Items.Clear;

      exit;
    end;

    if staticscanner.reverse then
    begin
      lblRSTotalStaticPaths.caption:=format('Pointer paths found: %d',[scount]);

{$ifdef benchmarkps}
      if (starttime=0) and (totalpathsevaluated<>0) then
      begin
        startcount:=totalpathsevaluated;  //get the count from this point on
        starttime:=gettickcount;
      end;

      label5.caption:=format('Threads: Evaluated: %d Time: %d  (%d / s)',[totalpathsevaluated-startcount, ((gettickcount-starttime) div 1000), trunc(((totalpathsevaluated-startcount)/((gettickcount-starttime) / 1000))) ]);
      label5.Width:=label5.Canvas.TextWidth(label5.caption);
{$endif}    

      //{$ifdef injectedpscan
      //lblRSCurrentAddress.Caption:=format('Currently at address %p (going till %p)',[staticscanner.currentaddress, staticscanner.lastaddress]);
     // {$else
      //if vm<>nil then
  //    lblRSCurrentAddress.Caption:=format('Currently at address %0.8x (going till %0.8x)',[vm.PointerToAddress(staticscanner.currentaddress), vm.PointerToAddress(staticscanner.lastaddress)]);
      //{$endif

      {

      label2.Caption:=inttostr(scount)+' of '+inttostr(fcount);
      label6.caption:='Looking for :'+inttohex(staticscanner.lookingformin,8)+'-'+inttohex(staticscanner.lookingformax,8);;
     
      if staticscanner.phase=2 then
      begin
        //calculate time left
        todo:=dword(staticscanner.lastaddress)-dword(staticscanner.currentaddress);
        done:=dword(staticscanner.currentaddress)-dword(staticscanner.firstaddress);
      end;

      }
      if tvRSThreads.Items.Count<length(staticscanner.reversescanners) then
      begin
        //add them

        for i:=0 to length(staticscanner.reversescanners)-1 do
        begin
          tn:=tvRSThreads.Items.Add(nil,'Thread '+inttostr(i+1));
          tvRSThreads.Items.AddChild(tn,'Current Level:0');
          tvRSThreads.Items.AddChild(tn,'Looking for :0-0');
        end;
      end;

      tn:=tvRSThreads.Items.GetFirstNode;
      i:=0;
      while tn<>nil do
      begin
        if staticscanner.reversescanners[i].isdone then
        begin
          tn.Text:='Thread '+inttostr(i+1)+' (Sleeping)';
          tn2:=tn.getFirstChild;
          tn2.text:='Sleeping';
          tn2:=tn2.getNextSibling;
          tn2.text:='Sleeping';
        end
        else
        begin
          tn.text:='Thread '+inttostr(i+1)+' (Active)';
          tn2:=tn.getFirstChild;

          begin
            s:='';
            for j:=0 to staticscanner.reversescanners[i].currentlevel-1 do
              s:=s+' '+inttohex(staticscanner.reversescanners[i].tempresults[j],8);


            tn2.text:='Current Level:'+inttostr(staticscanner.reversescanners[i].currentlevel)+' ('+s+')';
            tn2:=tn2.getNextSibling;
            tn2.text:='Looking for :'+inttohex(staticscanner.reversescanners[i].lookingformin,8)+'-'+inttohex(staticscanner.reversescanners[i].lookingformax,8);;
          end;
        end;

        tn:=tn.getNextSibling;
        inc(i);
      end;
    end
    else
    begin

    end;


  except

  end;
end;

procedure Tfrmpointerscanner.OpenPointerfile(filename: string);
var
  modulelistlength: dword;
  i,j: integer;
  x: dword;
  temppchar: pchar;
  temppcharmaxlength: integer;

  col_baseaddress:TListColumn;
  col_pointsto: TListColumn;
  col_offsets: Array of TListColumn;
  tempmodulelist: tstringlist;
begin
  new1.Click;

  Pointerscanresults:=TPointerscanresultReader.create(filename);

  listview1.Items.BeginUpdate;
  listview1.Columns.BeginUpdate;  
  listview1.Items.Count:=0;
  listview1.Columns.Clear;

  col_baseaddress:=listview1.Columns.Add;
  col_baseaddress.Caption:='Base Address';
  col_baseaddress.Width:=150;
  col_baseaddress.MinWidth:=20;

  setlength(col_offsets, Pointerscanresults.offsetCount);
  for i:=0 to Pointerscanresults.offsetCount-1 do
  begin
    col_offsets[i]:=listview1.Columns.Add;
    col_offsets[i].Caption:='Offset '+inttostr(i);
    col_offsets[i].Width:=80;
    col_offsets[i].MinWidth:=10;
  end;

  col_pointsto:=listview1.Columns.Add;
  col_pointsto.Caption:='Points to:';
  col_pointsto.Width:=80;
  col_pointsto.MinWidth:=10;
  col_pointsto.AutoSize:=true;


  listview1.Items.Count:=Pointerscanresults.count;

  panel1.Caption:='pointercount:'+inttostr(Pointerscanresults.count);

  if (listview1.Items.Count=0) and (Pointerscanresults.count>100000000) then
  begin
    listview1.Items.Count:=100000000;
    showmessage('Due to OS restrictions only the first 100000000 entries will be displayed. Rescan will still work with all results');
  end;

  listview1.Align:=alClient;
  listview1.Visible:=true;

  listview1.Columns.EndUpdate;
  listview1.Items.EndUpdate;

  cbtype.top:=0;
  cbtype.height:=panel1.ClientHeight;
  cbtype.Visible:=true;

  Rescanmemory1.Enabled:=true;
  new1.Enabled:=true;

  caption:='Pointer scan : '+extractfilename(filename);
end;

procedure Tfrmpointerscanner.Open1Click(Sender: TObject);
begin
  if opendialog1.Execute then
    OpenPointerfile(Opendialog1.filename);
end;

function TRescanWorker.isMatchToValue(p:pointer): boolean;
begin
  case valuetype of
    vtDword: result:=pdword(p)^=valuescandword;
    vtSingle: result:=(psingle(p)^>=valuescansingle) and (psingle(p)^<valuescansinglemax);
    vtDouble: result:=(pdouble(p)^>=valuescandouble) and (pdouble(p)^<valuescandoublemax);
  end;
end;

procedure TRescanWorker.flushresults;
begin
  tempfile.WriteBuffer(tempbuffer.Memory^,tempbuffer.Position);
  tempbuffer.Seek(0,sofrombeginning);
end;

destructor TRescanworker.destroy;
begin
  if Pointerscanresults<>nil then
    Pointerscanresults.Free;
end;

procedure TRescanWorker.execute;
var



    currentEntry: integer;
    i,j: integer;

    address,address2: dword;
    pa: PPointerAddress;
    x: dword;
    valid: boolean;

    tempvalue: pointer;
    value: pointer;
    valuesize: integer;

    p: ppointerscanresult;
begin
  tempfile:=nil;
  tempbuffer:=nil;

  if forvalue and (valuetype=vtDouble) then valuesize:=8 else valuesize:=4;

  getmem(tempvalue,valuesize);

  try
    tempfile:=tfilestream.Create(self.filename, fmCreate);
    tempbuffer:=TMemoryStream.Create;
    tempbuffer.SetSize(16*1024*1024);

    evaluated:=0;
    currentEntry:=self.startentry;

    while evaluated < self.EntriesToCheck do
    begin
      p:=Pointerscanresults.getPointer(currentEntry);
      if p<>nil then
      begin
        valid:=true;
        if p.modulenr=-1 then
          address:=p.moduleoffset
        else
          address:=Pointerscanresults.getModuleBase(p.modulenr)+p.moduleoffset;

        if address>0 then
        begin                    
          for i:=p.offsetcount-1 downto 0 do
          begin
            pa:=rescanhelper.findPointer(address);
            if pa=nil then
            begin
              if readprocessmemory(processhandle, pointer(address), @address2, 4, x) then
                pa:=rescanhelper.AddPointer(address, address2)
              else
                pa:=rescanhelper.AddPointer(address, 0);
            end;

            if pa.value>0 then
              address:=pa.value+p.offsets[i]
            else
            begin
              valid:=false;
              break; //invalid pointer
            end;
          end;

          if valid then
          begin
            if forvalue then
            begin
              //evaluate the address (address must be accessible)
              if rescanhelper.ispointer(address) then
              begin
                value:=rescanhelper.findAddress(address);
                if value=nil then
                begin
                  //value is not yet stored, fetch it and add it to the list
                  if ReadProcessMemory(processhandle,pointer(address),tempvalue,valuesize,x) then
                    value:=rescanhelper.AddAddress(address, tempvalue, valuesize)
                  else
                    valid:=false; //unreadable even though ispointer returned true....
                end;


                if (value=nil) or (not isMatchToValue(value)) then
                  valid:=false; //invalid value
              end else valid:=false; //unreadable address
            end
            else
            begin
              //check if the address matches
              if address<>PointerAddressToFind then
                valid:=false;
            end;
          end;

          if valid then
          begin
            //checks passed, it's valid
            tempbuffer.Write(p^,Pointerscanresults.entrySize);
            if tempbuffer.Position>16*1024*1024 then flushresults;
          end;



        end; //else not a valid module
      end;

      inc(evaluated);
      inc(currentEntry);
    end;

    flushresults;
  finally
    freemem(tempvalue);
    
    if tempfile<>nil then
      freeandnil(tempfile);

    if tempbuffer<>nil then
      freeandnil(tempbuffer);

  end;
end;

procedure TRescanpointers.closeOldFile;
begin
  ownerform.New1Click(ownerform.new1);
end;

procedure TRescanpointers.execute;
var offsetsize: dword;
    offsetlist: array of dword;
    tempbuf: array [0..7] of byte;

    tempstring: string;

    i,j: integer;
    mi: TModuleInfo;

    stringlength: dword;
    ssize: dword;
    s: pchar;
    offset: dword;
    pointermatch: boolean;
    //---------------------

    TotalPointersToEvaluate: UINT64;
    PointersEvaluated: UINT64;

    rescanworkercount: integer;
    rescanworkers: array of TRescanWorker;
    blocksize: uint64;

    threadhandles: array of Thandle;
    result,x: tfilestream;

    modulecount: dword;
    rescanhelper: TRescanHelper;
    temp: dword;
begin
 
  progressbar.Min:=0;
  progressbar.Max:=100;
  progressbar.Position:=0;
  result:=nil;
  x:=nil;

  rescanhelper:=TRescanHelper.create;

  ownerform.resyncloadedmodulelist;

  //fill the modulelist with baseaddresses
  try


    //the modulelist now holds the baseaddresses (0 if otherwhise)
    TotalPointersToEvaluate:=ownerform.pointerscanresults.count;


    //spawn all threads
    rescanworkercount:=GetCPUCount;
    if HasHyperthreading then rescanworkercount:=(rescanworkercount div 2)+1;

    rescanworkercount:=1;

    blocksize:=TotalPointersToEvaluate div rescanworkercount;


    setlength(rescanworkers, rescanworkercount);
    setlength(threadhandles, rescanworkercount);
    for i:=0 to rescanworkercount-1 do
    begin
      rescanworkers[i]:=TRescanWorker.Create(true);


      rescanworkers[i].Pointerscanresults:=TPointerscanresultReader.create(ownerform.Pointerscanresults.filename);
     { rescanworkers[i].OriginalFilename:=ownerform.pointerscanresults.filename;
      rescanworkers[i].OriginalFileEntrySize:=ownerform.pointerscanresults.sizeOfEntry;
      rescanworkers[i].OriginalFileStartPosition:=ownerform.pointerscanresults.StartPosition;
      rescanworkers[i].offsetlength:=ownerform.OpenedPointerfile.offsetlength;
      rescanworkers[i].modulelist:=ownerform.OpenedPointerfile.modulelist;    }
      rescanworkers[i].PointerAddressToFind:=self.address;
      rescanworkers[i].forvalue:=forvalue;
      rescanworkers[i].valuetype:=valuetype;
      rescanworkers[i].valuescandword:=valuescandword;
      rescanworkers[i].valuescansingle:=valuescansingle;
      rescanworkers[i].valuescandouble:=valuescandouble;
      rescanworkers[i].valuescansinglemax:=valuescansinglemax;
      rescanworkers[i].valuescandoublemax:=valuescandoublemax;

      rescanworkers[i].rescanhelper:=rescanhelper;

      if overwrite then
        rescanworkers[i].filename:=self.filename+'.'+inttostr(i)+'.overwrite'      
      else
        rescanworkers[i].filename:=self.filename+'.'+inttostr(i);

      rescanworkers[i].startEntry:=blocksize*i;
      rescanworkers[i].entriestocheck:=blocksize;
      if i=rescanworkercount-1 then
        rescanworkers[i].entriestocheck:=TotalPointersToEvaluate-rescanworkers[i].startEntry; //to the end

      threadhandles[i]:=rescanworkers[i].Handle;
      rescanworkers[i].Resume;
    end;


    if overwrite then
      result:=TFileStream.Create(filename+'.overwrite',fmCreate)
    else
      result:=TFileStream.Create(filename,fmCreate);

    //write header
    //modulelist
    ownerform.pointerscanresults.saveModulelistToResults(result);

    //offsetlength
    result.Write(ownerform.pointerscanresults.offsetcount, sizeof(dword));

    //pointerstores
    temp:=length(rescanworkers);
    result.Write(temp,sizeof(temp));
    for i:=0 to length(rescanworkers)-1 do
    begin
      tempstring:=ExtractFileName(rescanworkers[i].filename);
      if overwrite then
        tempstring:=copy(tempstring,1,length(tempstring)-10);
        
      temp:=length(tempstring);
      result.Write(temp,sizeof(temp));
      result.Write(tempstring[1],temp);
    end;

    result.Free;

    while WaitForMultipleObjects(rescanworkercount, @threadhandles[0], true, 1000) = WAIT_TIMEOUT do      //wait
    begin
      //query all threads the number of pointers they have evaluated
      PointersEvaluated:=0;
      for i:=0 to rescanworkercount-1 do
        inc(PointersEvaluated,rescanworkers[i].evaluated);

      progressbar.Position:=PointersEvaluated div (TotalPointersToEvaluate div 100);
    end;
    //no timeout, so finished or crashed

    if overwrite then //delete the old ptr file
    begin
      synchronize(closeoldfile);
      DeleteFile(filename);
      RenameFile(filename+'.overwrite',filename);
    end;

    //destroy workers
    for i:=0 to rescanworkercount-1 do
    begin
      rescanworkers[i].WaitFor; //just to be sure
      rescanworkers[i].Free;

      if overwrite then
      begin
        DeleteFile(filename+'.'+inttostr(i));
        RenameFile(filename+'.'+inttostr(i)+'.overwrite', filename+'.'+inttostr(i));
      end;
    end;


    rescanworkercount:=0;
    setlength(rescanworkers,0);


  finally
    progressbar.Position:=0;
    postmessage(ownerform.Handle,rescan_done,0,0);
    if rescanhelper<>nil then
      freeandnil(rescanhelper);
  end;

end;

procedure Tfrmpointerscanner.Rescanmemory1Click(Sender: TObject);
var address: dword;
    saddress: string;
    FloatSettings: TFormatSettings;
    floataccuracy: integer;
    i: integer;
begin

  GetLocaleFormatSettings(GetThreadLocale, FloatSettings);
  saddress:='';

  if rescan<>nil then
    freeandnil(rescan);

  rescan:=trescanpointers.create(true);
  rescan.ownerform:=self;
  rescan.progressbar:=progressbar1;



  try

    with TFrmRescanPointer.Create(self) do
    begin
      try
        if showmodal=mrok then
        begin
          if savedialog1.Execute then
          begin
            if cbDelay.Checked then
            begin
              try
                sleep(strtoint(edtDelay.Text)*1000);
              except

              end;
            end;


            rescan.filename:=savedialog1.filename;

            if uppercase(rescan.filename)=uppercase(pointerscanresults.filename) then
              rescan.overwrite:=true;



            Rescanmemory1.Enabled:=false;
            new1.Enabled:=false;

            if rbFindAddress.Checked then
            begin
              address:=strtoint('$'+edtAddress.Text);

              //rescan the pointerlist

              rescan.address:=address;
              rescan.forvalue:=false;

            end
            else
            begin

              //if values, check what type of value
              floataccuracy:=pos(FloatSettings.DecimalSeparator,edtAddress.Text);
              if floataccuracy>0 then
                floataccuracy:=length(edtAddress.Text)-floataccuracy;

              case cbValueType.ItemIndex of
                0:
                begin
                  rescan.valuetype:=vtDword;
                  val(edtAddress.Text, rescan.valuescandword, i);
                  if i>0 then raise exception.Create(edtAddress.Text+' is not a valid 4 byte value');
                end;

                1:
                begin
                  rescan.valuetype:=vtSingle;
                  val(edtAddress.Text, rescan.valuescansingle, i);
                  if i>0 then raise exception.Create(edtAddress.Text+' is not a valid floating point value');
                  rescan.valuescansingleMax:=rescan.valuescansingle+(1/(power(10,floataccuracy)));
                end;

                2:
                begin
                  rescan.valuetype:=vtDouble;
                  val(edtAddress.Text, rescan.valuescandouble, i);
                  if i>0 then raise exception.Create(edtAddress.Text+' is not a valid double value');
                  rescan.valuescandoubleMax:=rescan.valuescandouble+(1/(power(10,floataccuracy)));
                end;
              end;



              rescan.forvalue:=true;

            end;
            rescan.resume;
          end;
        end;


      finally
        free;
      end;
    end;


  except
    on e: exception do
    begin
      Rescanmemory1.Enabled:=true;
      new1.Enabled:=true;


      freeandnil(rescan);
      raise e;
    end;

  end;


end;

procedure tfrmpointerscanner.rescandone(var message: tmessage);
{
The rescan is done. rescan.oldpointerlist (the current pointerlist) can be deleted
and the new pointerlist becomes the current pointerlist
}
begin
  doneui;

  if rescan<>nil then
    freeandnil(rescan);
    
  Rescanmemory1.Enabled:=true;
  new1.Enabled:=true;
end;

procedure Tfrmpointerscanner.btnStopScanClick(Sender: TObject);
begin
  if staticscanner<>nil then
  begin
    if not staticscanner.terminated then
    begin
      if messagedlg('Are you sure you want to stop the pointerscan? There is only a one in a billion chance the pointer you need has already been found',mtwarning, [mbyes,mbno],0)<>mryes then exit;
      staticscanner.Terminate;
    end;

    staticscanner.WaitFor;
  end;
end;

procedure Tfrmpointerscanner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Staticscanner<>nil then
  begin
    Staticscanner.Terminate;
    Staticscanner.WaitFor;
    freeandnil(Staticscanner);
  end;

  new1.Click;

  if pointerlisthandler<>nil then
    freeandnil(pointerlisthandler);


  action:=cafree; //on close free itself
end;

procedure Tfrmpointerscanner.openscanner(var message: tmessage);
begin
  if frmpointerscannersettings=nil then
    frmpointerscannersettings:=tfrmpointerscannersettings.create(nil);

  frmpointerscannersettings.edtAddress.text:=inttohex(message.WParam,8);
  Method3Fastspeedandaveragememoryusage1.Click;
end;


procedure Tfrmpointerscanner.New1Click(Sender: TObject);
var i: integer;
begin
  btnStopScan.click;
  if staticscanner<>nil then
    freeandnil(staticscanner);

 
  pgcPScandata.Visible:=false;
  panel1.Caption:='';
  open1.Enabled:=true;
  new1.enabled:=true;
  rescanmemory1.Enabled:=false;

  listview1.Items.BeginUpdate;
  listview1.columns.BeginUpdate;
  listview1.Columns.Clear;
  listview1.Items.Count:=0;

  listview1.Items.EndUpdate;
  listview1.Columns.EndUpdate;

  Method3Fastspeedandaveragememoryusage1.Enabled:=true;

  if Pointerscanresults<>nil then
    freeandnil(Pointerscanresults);
end;



procedure Tfrmpointerscanner.FormCreate(Sender: TObject);
var x:array of integer;
begin
  tsPSReverse.TabVisible:=false;

  {$ifdef injectedpscan}
  caption:='CE Injected Pointerscan';
  {$endif}
  listview1.DoubleBuffered:=true;

  setlength(x,1);
  if loadformposition(self,x) then
    cbtype.itemindex:=x[0];
end;

procedure Tfrmpointerscanner.ListView1Data(Sender: TObject;
  Item: TListItem);
var
  p: PPointerscanResult;
  i: integer;
  s: string;
  check: boolean; 
  doublevalue: double;
  dwordvalue: dword absolute doublevalue; //make sure of the same memory
  floatvalue: single absolute doublevalue;
  x: dword;
  
  {
    offset: dword;
    actualoffsetcount: integer;

    address,address2: dword;




         }
    address: dword;
    
begin
  if Pointerscanresults<>nil then
  begin
    p:=Pointerscanresults.getPointer(item.index, address);
    if p<>nil then //just to be safe
    begin
      if p.modulenr=-1 then
        item.Caption:=inttohex(p.moduleoffset,8)
      else
        item.Caption:=pointerscanresults.getModulename(p.modulenr)+'+'+inttohex(p.moduleoffset,8);

      for i:=p.offsetcount-1 downto 0 do
        item.SubItems.Add(inttohex(p.offsets[i],1));

      for i:=p.offsetcount to Pointerscanresults.offsetCount-1 do
        item.SubItems.Add('');

      if address=0 then
        item.SubItems.Add('-') else
      begin
        s:=inttohex(address,8);
        if cbType.ItemIndex<>-1 then
        begin
          s:=s+' = ';
          if cbType.ItemIndex=2 then
            check:=readprocessmemory(processhandle, pointer(address),@doublevalue,8,x) else
            check:=readprocessmemory(processhandle, pointer(address),@doublevalue,4,x);

          if check then
          begin
            case cbType.ItemIndex of
              0: s:=s+inttostr(dwordvalue);
              1: s:=s+floattostr(floatvalue);
              2: s:=s+floattostr(doublevalue);
            end;
          end else s:=s+'??';
        end;

        item.SubItems.Add(s);

      end;
    end;
  end;
end;

procedure Tfrmpointerscanner.resyncloadedmodulelist;
begin
  pointerscanresults.resyncModulelist;
end;

procedure Tfrmpointerscanner.Resyncmodulelist1Click(Sender: TObject);
begin
  resyncloadedmodulelist;
  listview1.Refresh;
end;

procedure Tfrmpointerscanner.ListView1DblClick(Sender: TObject);
var
  li: tlistitem;
  err: boolean;
  i: integer;
  baseaddress: dword;
  offsets: array of dword;
  t: string;
  c: integer;

  vtype: integer;
begin
  if listview1.ItemIndex<>-1 then
  begin
    err:=false;
    li:=listview1.Items.Item[listview1.ItemIndex];
    t:=li.caption;
    baseaddress:=symhandler.getAddressFromName(t,false,err);
    if err then
      baseAddress:=0;


    try
      setlength(offsets,li.SubItems.Count);
      c:=0;

      for i:=li.SubItems.Count-2 downto 0 do
      begin
        if li.SubItems[i]='' then continue;
        offsets[c]:=strtoint('$'+li.SubItems[i]);
        inc(c);
      end;


      if cbType.ItemIndex=1 then vtype:=3 else
      if cbtype.itemindex=2 then vtype:=4 else
      vtype:=2;

      mainform.addaddress('pointerscan result',baseaddress,offsets,c,true,vtype,0,0,false);
      mainform.memrec[length(mainform.memrec)-1].pointers[length(mainform.memrec[length(mainform.memrec)-1].pointers)-1].Interpretableaddress:=t;
    except

    end;
  end;
end;

procedure Tfrmpointerscanner.cbTypeChange(Sender: TObject);
begin
  listview1.Refresh;
end;

procedure Tfrmpointerscanner.FormDestroy(Sender: TObject);
var x: array of integer;
begin
  setlength(x,1);
  x[0]:=cbtype.itemindex;
  SaveFormPosition(self, x);
end;

end.


