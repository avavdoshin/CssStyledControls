unit CssStyledControlsReg;

{$mode objfpc}{$H+}

interface

procedure Register;

implementation

uses
  Classes, LResources, CssStyledControl, CssButtonControl, CssCheckboxControl, CssComboControl, CssEditControl, CssGroupControl, CssLabelControl,
  CssListboxControl, CssMemoControl, CssMenuControl, CssPanelControl, CssRadioControl, CssScrollControl, CssSplitterControl, CssTabbedControl,
  CssVirtualTreeControl, CssProxyControl, CssBitBtnControl;

procedure Register;
begin
  RegisterComponents('CSSStyledControls', [
    TCssStyleProvider, TCssProxy,
    TCssButton, TCssCheckBox, TCssCheckGroup, TCssComboBox,
    TCssEdit, TCssGroupBox, TCssLabel, TCssListBox,
    TCssMemo, TCssMainMenu, TCssPopupMenu, TCssPanel,
    TCssRadioButton, TCssRadioGroup, TCssScrollBar, TCssSplitter,
    TCssVirtualStringTree, TCssPageControl, TCssTabControl, TCssTabSheet, TCssBitBtn
  ]);
end;

initialization
  {$I CssStyledControls.lrs}
end.
