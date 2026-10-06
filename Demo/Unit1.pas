unit Unit1;

{$mode objfpc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CssStyledControl,
  CssPanelControl, CssCheckboxControl, CssRadioControl, CssProxyControl,
  CssLabelControl, CssTabbedControl, CssButtonControl, CssGroupControl,
  CssMenuControl, CssBitBtnControl, CssSvgImgList, CssSplitterControl;

type
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
    CssGroupBox1 : TCssGroupBox;
    CssLabel1 : TCssLabel;
    CssLabel2 : TCssLabel;
    CssPageControl1 : TCssPageControl;
    CssPanel1 : TCssPanel;
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
    MenuItem1 : TCssMenuItem;
    MenuItem2 : TCssMenuItem;
    procedure CssCheckBox1Click(Sender : TObject);
    procedure CssLabel2LinkClick(Sender : TObject; const AHref, AText: UnicodeString);
    procedure FormCreate(Sender : TObject);
    procedure MenuItem1Click(Sender : TObject);
    procedure MenuItem2Click(Sender : TObject);
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

procedure TForm1.CssLabel2LinkClick(Sender : TObject; const AHref, AText : Unicodestring);
begin
  MessageDlg('Link clicked', 'Href='+AHref+' , Text='+AText, mtInformation, [mbOk], '');
end;

procedure TForm1.FormCreate(Sender : TObject);
begin
  EnableSmoothPainting(Self);
end;

procedure TForm1.MenuItem1Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem1.Caption;
end;

procedure TForm1.MenuItem2Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem2.Caption;
end;

end.

