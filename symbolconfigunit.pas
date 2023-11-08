unit symbolconfigunit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,symbolhandler, ComCtrls, ExtCtrls, Menus;

type
  TfrmSymbolhandler = class(TForm)
    Panel1: TPanel;
    Label3: TLabel;
    edtSymbolname: TEdit;
    Label2: TLabel;
    edtAddress: TEdit;
    Button1: TButton;
    Panel2: TPanel;
    Label1: TLabel;
    ListView1: TListView;
    PopupMenu1: TPopupMenu;
    Delete1: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
  private
    { Private declarations }
    procedure SymUpdate(var message:TMessage); message wm_user+1;

  public
    { Public declarations }
    procedure refreshlist;
  end;

var
  frmSymbolhandler: TfrmSymbolhandler;

implementation

{$R *.dfm}

procedure SymbolUpdate;
begin
  if frmsymbolhandler<>nil then
    postmessage(frmsymbolhandler.handle,wm_user+1,0,0);  //in case of multithreading
end;

procedure TfrmSymbolhandler.SymUpdate(var message: tmessage);
begin
  refreshlist;
end;


procedure TfrmSymbolhandler.refreshlist;
var sl: tstringlist;
    i: integer;
    li: tlistitem;
    extradata: ^TUDSEnum;

begin
  listview1.Items.Clear;
  sl:=tstringlist.create;
  try
    symhandler.EnumerateUserdefinedSymbols(sl);

    for i:=0 to sl.Count-1 do
    begin
      li:=listview1.Items.Add;
      li.Caption:=sl[i];
      extradata:=pointer(sl.objects[i]);
      li.SubItems.Add(extradata^.addressstring);
      if extradata^.allocsize>0 then
        li.SubItems.Add(inttohex(dword(extradata^.allocsize),8));

      freemem(extradata);
    end;
  finally
    sl.free;
  end;
end;

procedure TfrmSymbolhandler.FormShow(Sender: TObject);
begin
  refreshlist;
end;

procedure TfrmSymbolhandler.Button1Click(Sender: TObject);
var symbolname:string;
    address: dword;
    li: tlistitem;
begin
  symbolname:=edtsymbolname.Text;
  symhandler.AddUserdefinedSymbol(edtaddress.Text,symbolname);

  li:=listview1.Items.Add;
  li.Caption:=symbolname;
  li.SubItems.Add(edtaddress.Text);

  edtSymbolname.SetFocus;
  edtSymbolname.SelectAll;
end;

procedure TfrmSymbolhandler.ListView1Click(Sender: TObject);
var li: tlistitem;
begin
  if listview1.ItemIndex<>-1 then
  begin
    li:=listview1.Items[listview1.itemindex];

    edtSymbolname.Text:=li.Caption;
    edtAddress.text:=li.SubItems[0];
  end;
end;

procedure TfrmSymbolhandler.FormCreate(Sender: TObject);
begin
  symhandler.RegisterUserdefinedSymbolCallback(@symbolupdate);
end;

procedure TfrmSymbolhandler.Delete1Click(Sender: TObject);
begin
  if listview1.ItemIndex<>-1 then
  begin
    if messagedlg('Are you sure you want to remove this symbol from the list?',mtconfirmation,[mbyes,mbno],0)=mryes then
    begin
      symhandler.DeleteUserdefinedSymbol(listview1.Items[listview1.ItemIndex].Caption);
      listview1.Items[listview1.ItemIndex].Delete;
    end;
  end;
end;

end.
