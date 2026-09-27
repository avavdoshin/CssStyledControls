unit CssStyledControlsReg;

{$mode objfpc}{$H+}

interface

procedure Register;

implementation

uses
  Classes, LResources, CssStyledControl, CssButtonControl, CssCheckboxControl, CssComboControl, CssEditControl, CssGroupControl, CssLabelControl,
  CssListboxControl, CssMemoControl, CssMenuControl, CssPanelControl, CssRadioControl, CssScrollControl, CssSplitterControl, CssTabbedControl,
  CssVirtualTreeControl;

procedure Register;
begin
  RegisterComponents('CSSStyledControls', [
    TCssStyleProvider,
    TCssButton, TCssCheckBox, TCssCheckGroup, TCssComboBox,
    TCssEdit, TCssGroupBox, TCssLabel, TCssListBox,
    TCssMemo, TCssMainMenu, TCssPopupMenu, TCssPanel,
    TCssRadioButton, TCssRadioGroup, TCssScrollBar, TCssSplitter,
    TCssVirtualStringTree, TCssPageControl, TCssTabControl, TCssTabSheet
  ]);
end;

initialization
  {$I CssStyledControls.lrs}
end.
