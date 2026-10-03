unit Unit1;

{$mode objfpc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CssStyledControl,
  CssPanelControl, CssCheckboxControl, CssRadioControl, CssProxyControl,
  CssLabelControl, CssTabbedControl, CssButtonControl, CssGroupControl;

type
  TForm1 = class(TForm)
    CssButton1 : TCssButton;
    CssButton2 : TCssButton;
    CssButton3 : TCssButton;
    CssButton4 : TCssButton;
    CssCheckBox1 : TCssCheckBox;
    CssGroupBox1 : TCssGroupBox;
    CssLabel1 : TCssLabel;
    CssLabel2 : TCssLabel;
    CssPageControl1 : TCssPageControl;
    CssPanel1 : TCssPanel;
    CssPanel2 : TCssPanel;
    CssProxy1 : TCssProxy;
    CssStyleProvider1 : TCssStyleProvider;
    CssTabSheet1 : TCssTabSheet;
    procedure CssCheckBox1Click(Sender : TObject);
    procedure CssLabel2LinkClick(Sender : TObject; const AHref, AText: UnicodeString);
  private

  public

  end;

var
  Form1 : TForm1;

implementation

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

end.

