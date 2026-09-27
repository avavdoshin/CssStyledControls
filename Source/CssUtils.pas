unit CssUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms;

// Arithmetic helpers
function CssMin(A, B: Integer): Integer; inline;
function CssMax(A, B: Integer): Integer; inline;

// Form lookup
function FindParentForm(AControl: TControl): TCustomForm;

implementation

{ Arithmetic helpers }

function CssMin(A, B: Integer): Integer;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;

function CssMax(A, B: Integer): Integer;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

{ Form lookup }

function FindParentForm(AControl: TControl): TCustomForm;
begin
  Result := nil;

  while Assigned(AControl) do
  begin
    if AControl is TCustomForm then
    begin
      Result := TCustomForm(AControl);
      Exit;
    end;

    AControl := AControl.Parent;
  end;
end;

end.
