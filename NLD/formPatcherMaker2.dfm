�
 TFRMPATCHERMAKER2 0�	  TPF0TfrmPatcherMaker2frmPatcherMaker2Left�Top� WidthHeightXBorderIcons CaptionPatcher MakerColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrderPositionpoScreenCenterOnCreate
FormCreateOnShowFormShow
DesignSize6 PixelsPerInch`
TextHeight TLabelLabel1Left Top� Width$HeightAnchorsakLeftakBottom CaptionLegend  TLabelLabel2Left Top� Width� HeightHint4Recommended (I am almost sure this is what you need)AnchorsakLeftakBottom Caption01=The bytes arround this address are as expectedFont.CharsetDEFAULT_CHARSET
Font.ColorclBlackFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontParentShowHintShowHint	  TLabelLabel3Left Top
Width� HeightHint9Recommended (if you needed to nop a opcode near this one)AnchorsakLeftakBottom Caption,2=Some bytes arround this address got noppedFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontParentShowHintShowHint	  TLabelLabel4Left TopWidth� HeightHint�Not really recommended. (The bytes before this opcode, or the bytes after this opcode are different, and I dont think CE did that)AnchorsakLeftakBottom Caption03=Only the bytes before or after are as expectedFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontParentShowHintShowHint	  TLabelLabel5Left�Top*Width� HeightHintqNot Recommended!! (The bytes arround the opcode dont even look the same as when you added the opcode to the list)AnchorsakLeftakBottom Caption04=The bytes arround this opcode are not the sameFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontParentShowHintShowHint	  TLabelLabel6Left Top WidthHeightCaption5Select the address(es) you want to patch and click OK  TListBox	FoundListLeft TopWidth� Height� AnchorsakLeftakTopakRightakBottom 
ItemHeightMultiSelect	ParentShowHintShowHintSorted	TabOrder OnClickFoundListClick  TButtonButton1Left� TopWidthKHeightAnchorsakTopakRight CaptionOKDefault	EnabledTabOrderOnClickButton1Click  TButtonButton2Left� Top8WidthKHeightAnchorsakTopakRight Cancel	CaptionSkipModalResultTabOrder   