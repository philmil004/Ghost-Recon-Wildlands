object frameHotkeyConfig: TframeHotkeyConfig
  Left = 0
  Top = 0
  Width = 416
  Height = 414
  TabOrder = 0
  object Panel1: TPanel
    Left = 0
    Top = 50
    Width = 233
    Height = 364
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 233
      Height = 16
      Align = alTop
      Caption = 'Functions'
    end
    object ListBox1: TListBox
      Left = 0
      Top = 16
      Width = 233
      Height = 348
      Align = alClient
      ExtendedSelect = False
      ItemHeight = 16
      Items.Strings = (
        'Popup/Hide cheat engine'
        'Pause the selected process'
        'Toggle the speedhack'
        'Speedhack speed 1'
        'Speedhack speed 2'
        'Speedhack speed 3'
        'Speedhack speed 4'
        'Speedhack speed 5'
        'Speedhack speed +'
        'Speedhack speed -'
        'Change type to Binary'
        'Change type to Byte'
        'Change type to 2 Bytes'
        'Change type to 4 Bytes'
        'Change type to 8 Bytes'
        'Change type to Float'
        'Change type to Double'
        'Change type to Text'
        'Change type to Array of byte'
        'New Scan'
        'New Scan-Exact Value'
        'New Scan-Unknown Initial Value'
        'Next Scan-Exact Value'
        'Next Scan-Increased Value'
        'Next Scan-Decreased Value'
        'Next Scan-Changed Value'
        'Next Scan-Unchanged Value'
        'Next Scan-Same as first scan'
        'Undo last scan'
        'Cancel the current scan'
        'Debug->Run')
      TabOrder = 0
      OnClick = ListBox1Click
    end
  end
  object Panel2: TPanel
    Left = 233
    Top = 50
    Width = 183
    Height = 364
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      183
      364)
    object Label2: TLabel
      Left = 6
      Top = 0
      Width = 43
      Height = 16
      Caption = 'Hotkey'
    end
    object Edit1: TEdit
      Left = 5
      Top = 16
      Width = 172
      Height = 24
      ReadOnly = True
      TabOrder = 0
      OnKeyDown = Edit1KeyDown
    end
    object Button3: TButton
      Left = 128
      Top = 40
      Width = 49
      Height = 17
      Caption = 'Clear'
      TabOrder = 1
      OnClick = Button3Click
    end
    object Panel3: TPanel
      Left = 8
      Top = 64
      Width = 170
      Height = 0
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelOuter = bvNone
      TabOrder = 2
      Visible = False
      DesignSize = (
        170
        0)
      object Label52: TLabel
        Left = 11
        Top = 2
        Width = 41
        Height = 16
        Anchors = [akTop, akRight]
        Caption = 'Speed'
      end
      object Label51: TLabel
        Left = 60
        Top = 2
        Width = 61
        Height = 16
        Anchors = [akTop, akRight]
        Caption = 'Sleeptime'
      end
      object edtSHSpeed: TEdit
        Left = 4
        Top = 18
        Width = 46
        Height = 24
        Anchors = [akTop, akRight]
        TabOrder = 0
        Text = '2'
      end
      object edtSHSleep: TEdit
        Left = 60
        Top = 18
        Width = 46
        Height = 24
        Anchors = [akTop, akRight]
        TabOrder = 1
        Text = '3'
      end
    end
    object Panel4: TPanel
      Left = 8
      Top = 123
      Width = 173
      Height = 97
      BevelOuter = bvNone
      TabOrder = 3
      Visible = False
      object Label3: TLabel
        Left = 3
        Top = 1
        Width = 74
        Height = 16
        Caption = 'Speed delta'
      end
      object Edit4: TEdit
        Left = 2
        Top = 16
        Width = 166
        Height = 24
        TabOrder = 0
        Text = '1'
      end
    end
  end
  object Panel5: TPanel
    Left = 0
    Top = 0
    Width = 416
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object Label4: TLabel
      Left = 104
      Top = 6
      Width = 177
      Height = 16
      Caption = 'Keypoll interval (milliseconds)'
    end
    object Label5: TLabel
      Left = 104
      Top = 32
      Width = 212
      Height = 16
      Caption = 'Delay between reactivating hotkeys'
    end
    object edtKeypollInterval: TEdit
      Left = 2
      Top = 2
      Width = 95
      Height = 24
      Hint = 'Determines how quickly a hotkey keypress is detected'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Text = '100'
    end
    object edtHotkeyDelay: TEdit
      Left = 2
      Top = 26
      Width = 95
      Height = 24
      Hint = 'Lets you specify how quickly a hotkey is repeated'
      TabOrder = 1
      Text = '100'
    end
  end
end
