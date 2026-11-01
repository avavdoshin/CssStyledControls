unit CssStyledControlsReg;

{$mode objfpc}{$H+}

interface

procedure Register;

implementation

uses
  Classes, LResources, CssStyledControl, CssButtonControl, CssCheckboxControl, CssComboControl, CssEditControl, CssGroupControl, CssLabelControl,
  CssListboxControl, CssListViewControl, CssMemoControl, CssMenuControl, CssPanelControl, CssRadioControl, CssScrollControl, CssSplitterControl, CssTabbedControl,
  CssVirtualTreeControl, CssProxyControl, CssBitBtnControl, CssSvgImgList, CssProgressBarControl;

procedure Register;
begin
  RegisterComponents('CSSStyledControls', [
    TCssStyleProvider, TCssProxy,
    TCssButton, TCssBitBtn, TCssCheckBox, TCssCheckGroup, TCssComboBox,
    TCssEdit, TCssGroupBox, TCssLabel, TCssListBox, TCssListView,
    TCssMemo, TCssMainMenu, TCssPopupMenu, TCssPanel,
    TCssRadioButton, TCssRadioGroup, TCssScrollBar, TCssSplitter,
    TCssVirtualStringTree, TCssPageControl, TCssTabControl, TCssTabSheet,
    TCssSvgImgList, TCssProgressBar
  ]);
end;

initialization
  {$I CssStyledControls.lrs}
end.
