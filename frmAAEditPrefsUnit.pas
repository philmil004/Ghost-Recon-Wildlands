unit frmAAEditPrefsUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, SynEdit;

type
  TfrmAAEditPrefs = class(TForm)
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    cbShowLineNumbers: TCheckBox;
    cbShowGutter: TCheckBox;
    cbSmartTab: TCheckBox;
    FontDialog1: TFontDialog;
    btnFont: TButton;
    cbTabsToSpace: TCheckBox;
    procedure btnFontClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbShowLineNumbersClick(Sender: TObject);
    procedure cbShowGutterClick(Sender: TObject);
    procedure cbSmartTabClick(Sender: TObject);
    procedure cbTabsToSpaceClick(Sender: TObject);
  private
    { Private declarations }
    fSynEdit: TSynEdit;
    oldsettings: record
      font: tfont;
      showlinenumbers: boolean;
      showgutter: boolean;
      options: TSynEditorOptions;
    end;

  public
    { Public declarations }
    function execute(synedit: TSynEdit): boolean;
  end;

var
  frmAAEditPrefs: TfrmAAEditPrefs;

implementation

{$R *.dfm}

function TfrmAAEditPrefs.execute(synedit: TSynEdit): boolean;
begin
  fSynEdit:=synedit;
  FontDialog1.Font.Assign(fSynEdit.Font);

  //save all parameters that could get changed
  oldsettings.font.Assign(fSynEdit.Font);
  oldsettings.showlinenumbers:=fSynEdit.Gutter.ShowLineNumbers;
  oldsettings.showgutter:=fSynEdit.Gutter.Visible;
  oldsettings.options:=fSynEdit.options;

  //setup GUI
  cbShowLineNumbers.Checked:=fSynEdit.Gutter.ShowLineNumbers;
  cbShowGutter.Checked:=fSynEdit.Gutter.Visible;
  cbSmartTab.Checked:=eoSmartTabs in fSynEdit.Options;
  cbTabsToSpace.Checked:=eoTabsToSpaces in fSynEdit.Options;
  btnFont.Caption:=fontdialog1.Font.Name+' '+inttostr(fontdialog1.Font.Size);


  //show form
  result:=showmodal=mrok;

  if not result then //undo all changes
  begin
    fsynedit.font.Assign(oldsettings.font);
    fsynedit.Gutter.ShowLineNumbers:=oldsettings.showlinenumbers;
    fsynedit.Gutter.visible:=oldsettings.showgutter;
    fsynedit.Options:=oldsettings.options;
  end;
  //else leave it and let the caller save to registry, ini, or whatever
end;

procedure TfrmAAEditPrefs.btnFontClick(Sender: TObject);
begin
  if fontdialog1.Execute then
  begin
    fsynedit.font:=fontdialog1.Font;
    btnFont.Caption:=fontdialog1.Font.Name+' '+inttostr(fontdialog1.Font.Size);
  end;
end;

procedure TfrmAAEditPrefs.FormCreate(Sender: TObject);
begin
  oldsettings.font:=tfont.Create;
end;

procedure TfrmAAEditPrefs.FormDestroy(Sender: TObject);
begin
  if oldsettings.font<>nil then oldsettings.font.Free;
end;

procedure TfrmAAEditPrefs.cbShowLineNumbersClick(Sender: TObject);
begin
  fSynEdit.Gutter.ShowLineNumbers:=cbShowLineNumbers.checked;
end;

procedure TfrmAAEditPrefs.cbShowGutterClick(Sender: TObject);
begin
  fSynEdit.Gutter.Visible:=cbShowGutter.Checked;
end;

procedure TfrmAAEditPrefs.cbSmartTabClick(Sender: TObject);
begin
  if cbSmartTab.Checked then
    fSynEdit.Options:=fSynEdit.Options+[eoSmartTabs, eoSmartTabDelete]
  else
    fSynEdit.Options:=fSynEdit.Options-[eoSmartTabs, eoSmartTabDelete];
end;

procedure TfrmAAEditPrefs.cbTabsToSpaceClick(Sender: TObject);
begin
  if cbTabsToSpace.Checked then
    fSynEdit.Options:=fSynEdit.Options+[eoTabsToSpaces]
  else
    fSynEdit.Options:=fSynEdit.Options-[eoTabsToSpaces];

end;

end.


