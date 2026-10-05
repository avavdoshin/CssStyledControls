{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit CssStyledControls;

{$warn 5023 off : no warning about unused units}
interface

uses
  CssStyledControlsReg, CssButtonControl, CssCheckboxControl, CssComboControl, 
  CssEditControl, CssGroupControl, CssLabelControl, CssListboxControl, 
  CssMemoControl, CssMenuControl, CssPanelControl, CssRadioControl, 
  CssScrollControl, CssSplitterControl, CssTabbedControl, 
  CssVirtualTreeControl, CssUtils, CssGroupCaptionControl, CssStyledControl, 
  CssProxyControl, CssFormDarkTitle, CssBitBtnControl, CssAntiAlias, 
  CssSvgImgList, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('CssStyledControlsReg', @CssStyledControlsReg.Register);
end;

initialization
  RegisterPackage('CssStyledControls', @Register);
end.
