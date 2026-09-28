{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit CssStyledControlsDesign;

{$warn 5023 off : no warning about unused units}
interface

uses
  CssStyledControlDesign, CssMenuReg, CssMenuDesigner, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('CssStyledControlDesign', @CssStyledControlDesign.Register);
  RegisterUnit('CssMenuReg', @CssMenuReg.Register);
end;

initialization
  RegisterPackage('CssStyledControlsDesign', @Register);
end.
