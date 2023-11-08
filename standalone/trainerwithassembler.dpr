program Trainerwithassembler;

uses
  Forms,
  PatcherUnit in 'PatcherUnit.pas' {frmPatcher},
  settingsunit in 'settingsunit.pas',
  frmMainUnit in 'frmMainUnit.pas' {frmMain},
  MemoryTrainerUnit in 'MemoryTrainerUnit.pas' {frmMemoryTrainer},
  ExtraTrainerComponents in '..\ExtraTrainerComponents.pas',
  Userdefinedformunit in 'Userdefinedformunit.pas' {Userdefinedform},
  HotkeyHandler in '..\HotkeyHandler.pas',
  CEFuncProc in '..\CEFuncProc.pas',
  reinit in '..\reinit.pas',
  Assemblerunit in '..\Assemblerunit.pas',
  NewKernelHandler in '..\NewKernelHandler.pas',
  Filehandler in '..\Filehandler.pas',
  symbolhandler in '..\symbolhandler.pas',
  autoassembler in '..\autoassembler.pas',
  ProcessHandlerUnit in '..\ProcessHandlerUnit.pas',
  simpleaobscanner in '..\simpleaobscanner.pas',
  memscan in '..\memscan.pas';

{$R *.res}

{$R ..\manifest.res} 

begin
  Application.Initialize;
  Application.ShowMainForm:=false;

  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
