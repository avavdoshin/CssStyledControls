unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CssStyledControl,
  CssPanelControl, CssCheckboxControl, CssRadioControl, CssProxyControl,
  CssLabelControl, CssTabbedControl, CssButtonControl, CssGroupControl,
  CssMenuControl, CssBitBtnControl, CssSvgImgList, CssSplitterControl,
  CssEditControl, CssComboControl, CssListboxControl, CssMemoControl,
  CssVirtualTreeControl;

type
  PNodeData = ^TNodeData;
  TNodeData = record
    Caption: String;
  end;

  TForm1 = class(TForm)
    CssBitBtn1 : TCssBitBtn;
    CssBitBtn2 : TCssBitBtn;
    CssBitBtn3 : TCssBitBtn;
    CssBitBtn4 : TCssBitBtn;
    CssButton1 : TCssButton;
    CssButton2 : TCssButton;
    CssButton3 : TCssButton;
    CssButton4 : TCssButton;
    CssButton5 : TCssButton;
    CssCheckBox1 : TCssCheckBox;
    CssCheckBox2 : TCssCheckBox;
    CssCheckBox3 : TCssCheckBox;
    CssCheckBox4 : TCssCheckBox;
    CssCheckBox5 : TCssCheckBox;
    CssCheckGroup1 : TCssCheckGroup;
    CssCheckGroup2 : TCssCheckGroup;
    CssCheckGroup3 : TCssCheckGroup;
    CssCheckGroup4 : TCssCheckGroup;
    CssComboBox1 : TCssComboBox;
    CssComboBox2 : TCssComboBox;
    CssComboBox3 : TCssComboBox;
    CssComboBox4 : TCssComboBox;
    CssEdit1 : TCssEdit;
    CssEdit2 : TCssEdit;
    CssEdit3 : TCssEdit;
    CssEdit4 : TCssEdit;
    CssGroupBox1 : TCssGroupBox;
    CssLabel1 : TCssLabel;
    CssLabel2 : TCssLabel;
    CssListBox1 : TCssListBox;
    CssListBox2 : TCssListBox;
    CssListBox3 : TCssListBox;
    CssMainMenu1 : TCssMainMenu;
    CssMemo1 : TCssMemo;
    CssPageControl1 : TCssPageControl;
    CssPanel1 : TCssPanel;
    CssPanel10 : TCssPanel;
    CssPanel11 : TCssPanel;
    CssPanel12 : TCssPanel;
    CssPanel13 : TCssPanel;
    CssPanel2 : TCssPanel;
    CssPanel3 : TCssPanel;
    CssPanel4 : TCssPanel;
    CssPanel5 : TCssPanel;
    CssPanel6 : TCssPanel;
    CssPanel7 : TCssPanel;
    CssPanel8 : TCssPanel;
    CssPanel9 : TCssPanel;
    CssPopupMenu1 : TCssPopupMenu;
    CssProxy1 : TCssProxy;
    CssRadioButton1 : TCssRadioButton;
    CssRadioButton2 : TCssRadioButton;
    CssRadioButton3 : TCssRadioButton;
    CssRadioButton4 : TCssRadioButton;
    CssRadioGroup1 : TCssRadioGroup;
    CssRadioGroup2 : TCssRadioGroup;
    CssRadioGroup3 : TCssRadioGroup;
    CssRadioGroup4 : TCssRadioGroup;
    CssSplitter1 : TCssSplitter;
    CssSplitter2 : TCssSplitter;
    CssStyleProvider1 : TCssStyleProvider;
    CssSvgImgList1 : TCssSvgImgList;
    CssTabSheet1 : TCssTabSheet;
    CssTabSheet2 : TCssTabSheet;
    CssTabSheet3 : TCssTabSheet;
    CssTabSheet4 : TCssTabSheet;
    LeftTree : TCssVirtualStringTree;
    RightTree : TCssVirtualStringTree;
    MenuItem1 : TCssMenuItem;
    MenuItem2 : TCssMenuItem;
    MenuItem3 : TCssMenuItem;
    MenuItem4 : TCssMenuItem;
    MenuItem5 : TCssMenuItem;
    MenuItem6 : TCssMenuItem;
    MenuItem7 : TCssMenuItem;
    MenuItem8 : TCssMenuItem;
    procedure CssCheckBox1Click(Sender : TObject);
    procedure CssLabel2LinkClick(Sender : TObject; const AHref, AText: String);
    procedure FormCreate(Sender : TObject);
    procedure FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState
      );
    procedure LeftTreeFreeNode(Sender : TObject; Node : TCssVirtualNode);
    procedure LeftTreeGetNodeDataSize(
      Sender : TObject; var NodeDataSize : Integer);
    procedure LeftTreeGetText(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer;
      TextType : TCssVirtualTreeTextType; var CellText : String);
    procedure LeftTreeInitNode(Sender : TObject; Node : TCssVirtualNode);
    procedure LeftTreeNewText(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer; const NewText : string);
    procedure MenuItem1Click(Sender : TObject);
    procedure MenuItem2Click(Sender : TObject);
    procedure MenuItem5Click(Sender : TObject);
    procedure MenuItem8Click(Sender : TObject);
  private

  public

  end;

var
  Form1 : TForm1;

implementation

uses
  CssUtils;

{$R *.lfm}

procedure TForm1.CssCheckBox1Click(Sender : TObject);
begin
  if CssCheckBox1.Checked then
    CssStyleProvider1.DefaultStyleName := 'Dark'
  else
    CssStyleProvider1.DefaultStyleName := 'Light';
end;

procedure TForm1.CssLabel2LinkClick(Sender : TObject; const AHref, AText : string);
begin
  MessageDlg('Link clicked', 'Href='+AHref+' , Text='+AText, mtInformation, [mbOk], '');
end;

procedure TForm1.FormCreate(Sender : TObject);

  function AddTextNode(
  Tree: TCssVirtualStringTree;
  Parent: TCssVirtualNode;
  const S: String
): TCssVirtualNode;
begin
  Result := Tree.AddChild(Parent);

  if Assigned(Result.Data) then
    PNodeData(Result.Data)^.Caption := S;
end;

var
  Root, tmpNode: TCssVirtualNode;
begin
  EnableSmoothPainting(Self);

  Root := AddTextNode(LeftTree, nil, 'Fruits');
  AddTextNode(LeftTree, Root, '<b>Apples</b>');
  tmpNode := AddTextNode(LeftTree, Root, '<i>Pears</i>');
  LeftTree.DisableNode(tmpNode);
  AddTextNode(LeftTree, Root, 'Oranges');

  Root := AddTextNode(LeftTree, nil, 'Vegetables');
  AddTextNode(LeftTree, Root, 'Carrots');
  AddTextNode(LeftTree, Root, 'Potatoes');
  AddTextNode(LeftTree, Root, 'Cucumbers');

  Root := AddTextNode(LeftTree, nil, 'Berries');
  AddTextNode(LeftTree, Root, 'Raspberries');
  AddTextNode(LeftTree, Root, 'Currants');

  LeftTree.FullExpand;
end;

procedure TForm1.FormKeyDown(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if Assigned(CssMainMenu1) and CssMainMenu1.HandleKeyDown(Key, Shift) then
    Key := 0;
end;

procedure TForm1.LeftTreeFreeNode(Sender : TObject; Node : TCssVirtualNode);
begin
  Finalize(PNodeData(Node.Data)^);
end;

procedure TForm1.LeftTreeGetNodeDataSize(
  Sender : TObject; var NodeDataSize : Integer);
begin
  NodeDataSize := SizeOf(TNodeData);
end;

procedure TForm1.LeftTreeGetText(Sender : TObject; Node : TCssVirtualNode;
  Column : Integer; TextType : TCssVirtualTreeTextType; var CellText : String);
begin
  if Assigned(Node.Data) then
    CellText := PNodeData(Node.Data)^.Caption
  else
    CellText := '';
end;

procedure TForm1.LeftTreeInitNode(Sender : TObject; Node : TCssVirtualNode);
begin
  Initialize(PNodeData(Node.Data)^);
end;

procedure TForm1.LeftTreeNewText(Sender : TObject; Node : TCssVirtualNode;
  Column : Integer; const NewText : string);
begin
  if Assigned(Node.Data) then
    PNodeData(Node.Data)^.Caption := NewText;
end;


procedure TForm1.MenuItem1Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem1.Caption;
end;

procedure TForm1.MenuItem2Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem2.Caption;
end;

procedure TForm1.MenuItem5Click(Sender : TObject);
begin
  CssCheckBox1.Checked := not CssCheckBox1.Checked;
  CssCheckBox1Click(Sender);
end;

procedure TForm1.MenuItem8Click(Sender : TObject);
begin
  Application.Terminate;
end;

end.

