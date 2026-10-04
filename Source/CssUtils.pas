unit CssUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics;

// Arithmetic helpers
function CssMin(A, B: Integer): Integer; inline;
function CssMax(A, B: Integer): Integer; inline;

// Form lookup
function FindParentForm(AControl: TControl): TCustomForm;

// ---- Shared CSS value parsers ---------------------------------------------
// Used both by TCssStyledControl (CSS engine) and TCssProxy (LCL skinner).

// Parse a CSS <color>. Supports:
//   #RGB, #RGBA, #RRGGBB, #RRGGBBAA
//   rgb(r,g,b), rgba(r,g,b,a)     (integer 0..255 or percentage)
//   transparent
//   full CSS Level 3 named-color list (lowercase, case-insensitive)
function CssTryNamedColor(const AName: string; out AColor: TColor): Boolean;
function CssParseColor(const AValue: string; out AColor: TColor): Boolean;

// Parse a CSS <length> and return device pixels.
//   px              -> scaled by AScaleFactor
//   pt              -> 96/72 * value, then scaled
//   unitless number -> treated as px, then scaled
//   thin/medium/thick -> 1/2/4, then scaled
//   "0"             -> 0, not scaled
// Pass AScaleFactor = 1.0 for unscaled (design) pixels.
function CssParseLengthPx(const AValue: string; out APx: Integer;
  AScaleFactor: Double = 1.0): Boolean;

implementation

uses
  Math, StrUtils;

function CssMin(A, B: Integer): Integer;
begin
  if A < B then Result := A else Result := B;
end;

function CssMax(A, B: Integer): Integer;
begin
  if A > B then Result := A else Result := B;
end;

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

// ---------------------------------------------------------------------------
//  Number scanner: allows leading +/-, digits, optional fractional part.
//  Fractional part is ignored (matches the rest of the library).
// ---------------------------------------------------------------------------

function TryParseNumberPrefix(const AValue: string; out ANumber: Integer): Boolean;
var
  S, NumStr: string;
  I, Code: Integer;
  HasDigit: Boolean;
begin
  Result := False;
  ANumber := 0;
  S := Trim(AValue);
  NumStr := '';
  I := 1;
  HasDigit := False;

  if (I <= Length(S)) and ((S[I] = '+') or (S[I] = '-')) then
  begin
    NumStr := NumStr + S[I];
    Inc(I);
  end;

  while (I <= Length(S)) and (S[I] in ['0'..'9']) do
  begin
    NumStr := NumStr + S[I];
    HasDigit := True;
    Inc(I);
  end;

  if (I <= Length(S)) and (S[I] = '.') then
  begin
    Inc(I);
    while (I <= Length(S)) and (S[I] in ['0'..'9']) do
      Inc(I);
  end;

  if not HasDigit then
    Exit;

  Val(NumStr, ANumber, Code);
  Result := Code = 0;
end;

// ---------------------------------------------------------------------------
//  Color parsing
// ---------------------------------------------------------------------------

function CssTryNamedColor(const AName: string; out AColor: TColor): Boolean;
var
  S: string;
begin
  Result := True;
  S := LowerCase(AName);

  if S = 'black' then AColor := RGBToColor(0, 0, 0)
  else if S = 'white' then AColor := RGBToColor(255, 255, 255)
  else if S = 'red' then AColor := RGBToColor(255, 0, 0)
  else if S = 'green' then AColor := RGBToColor(0, 128, 0)
  else if S = 'blue' then AColor := RGBToColor(0, 0, 255)
  else if S = 'yellow' then AColor := RGBToColor(255, 255, 0)
  else if S = 'orange' then AColor := RGBToColor(255, 165, 0)
  else if S = 'purple' then AColor := RGBToColor(128, 0, 128)
  else if (S = 'gray') or (S = 'grey') then AColor := RGBToColor(128, 128, 128)
  else if S = 'silver' then AColor := RGBToColor(192, 192, 192)
  else if S = 'maroon' then AColor := RGBToColor(128, 0, 0)
  else if S = 'olive' then AColor := RGBToColor(128, 128, 0)
  else if S = 'lime' then AColor := RGBToColor(0, 255, 0)
  else if (S = 'aqua') or (S = 'cyan') then AColor := RGBToColor(0, 255, 255)
  else if S = 'teal' then AColor := RGBToColor(0, 128, 128)
  else if S = 'navy' then AColor := RGBToColor(0, 0, 128)
  else if (S = 'fuchsia') or (S = 'magenta') then AColor := RGBToColor(255, 0, 255)
  else if S = 'pink' then AColor := RGBToColor(255, 192, 203)
  else if S = 'brown' then AColor := RGBToColor(165, 42, 42)
  else if S = 'gold' then AColor := RGBToColor(255, 215, 0)
  else if S = 'khaki' then AColor := RGBToColor(240, 230, 140)
  else if S = 'beige' then AColor := RGBToColor(245, 245, 220)
  else if S = 'ivory' then AColor := RGBToColor(255, 255, 240)
  else if S = 'snow' then AColor := RGBToColor(255, 250, 250)
  else if S = 'tomato' then AColor := RGBToColor(255, 99, 71)
  else if S = 'coral' then AColor := RGBToColor(255, 127, 80)
  else if S = 'salmon' then AColor := RGBToColor(250, 128, 114)
  else if (S = 'darkgray') or (S = 'darkgrey') then AColor := RGBToColor(169, 169, 169)
  else if (S = 'lightgray') or (S = 'lightgrey') then AColor := RGBToColor(211, 211, 211)
  else if (S = 'dimgray') or (S = 'dimgrey') then AColor := RGBToColor(105, 105, 105)
  else if S = 'whitesmoke' then AColor := RGBToColor(245, 245, 245)
  else if S = 'transparent' then AColor := clNone
  else
    Result := False;
end;

function CssParseColor(const AValue: string; out AColor: TColor): Boolean;
var
  S, Hex, Nums, Token: string;
  P, I, Comp: Integer;
  R, G, B: Integer;
  Vals: array[0..2] of Integer;
begin
  Result := False;
  S := LowerCase(Trim(AValue));
  if S = '' then Exit;

  if S = 'transparent' then
  begin
    AColor := clNone;
    Exit(True);
  end;

  if S[1] = '#' then
  begin
    Hex := Copy(S, 2, MaxInt);
    if (Length(Hex) = 3) or (Length(Hex) = 4) then
    begin
      if not TryStrToInt('$' + Hex[1] + Hex[1], R) then Exit;
      if not TryStrToInt('$' + Hex[2] + Hex[2], G) then Exit;
      if not TryStrToInt('$' + Hex[3] + Hex[3], B) then Exit;
    end
    else if Length(Hex) >= 6 then
    begin
      if not TryStrToInt('$' + Copy(Hex, 1, 2), R) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 3, 2), G) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 5, 2), B) then Exit;
    end
    else
      Exit;

    AColor := RGBToColor(R, G, B);
    Exit(True);
  end;

  if (Pos('rgb(', S) = 1) or (Pos('rgba(', S) = 1) then
  begin
    P := Pos('(', S);
    if P = 0 then Exit;
    Nums := Copy(S, P + 1, MaxInt);
    P := Pos(')', Nums);
    if P = 0 then Exit;
    Nums := Copy(Nums, 1, P - 1);

    Comp := 0;
    Token := '';
    for I := 1 to Length(Nums) + 1 do
    begin
      if (I > Length(Nums)) or (Nums[I] = ',') then
      begin
        Token := Trim(Token);
        if Comp < 3 then
        begin
          if EndsText('%', Token) then
          begin
            Token := Copy(Token, 1, Length(Token) - 1);
            if not TryParseNumberPrefix(Token, Vals[Comp]) then Exit;
            if Vals[Comp] < 0 then Vals[Comp] := 0;
            if Vals[Comp] > 100 then Vals[Comp] := 100;
            Vals[Comp] := Round(Vals[Comp] * 255 / 100);
          end
          else
          begin
            if not TryParseNumberPrefix(Token, Vals[Comp]) then Exit;
          end;
        end;
        Inc(Comp);
        Token := '';
      end
      else
        Token := Token + Nums[I];
    end;

    if Comp < 3 then Exit;

    for I := 0 to 2 do
    begin
      if Vals[I] < 0 then Vals[I] := 0;
      if Vals[I] > 255 then Vals[I] := 255;
    end;

    AColor := RGBToColor(Vals[0], Vals[1], Vals[2]);
    Exit(True);
  end;

  Result := CssTryNamedColor(S, AColor);
end;

// ---------------------------------------------------------------------------
//  Length parsing
// ---------------------------------------------------------------------------

function CssParseLengthPx(const AValue: string; out APx: Integer;
  AScaleFactor: Double): Boolean;
var
  S: string;
  Num: Integer;
begin
  Result := False;
  APx := 0;
  S := LowerCase(Trim(AValue));
  if S = '' then Exit;

  if S = '0' then
    Exit(True);

  if S = 'thin'   then begin APx := Round(1 * AScaleFactor); Exit(True); end;
  if S = 'medium' then begin APx := Round(2 * AScaleFactor); Exit(True); end;
  if S = 'thick'  then begin APx := Round(4 * AScaleFactor); Exit(True); end;

  if TryParseNumberPrefix(S, Num) then
  begin
    if EndsText('pt', S) then
      APx := Round(Num * (96 / 72) * AScaleFactor)
    else
      APx := Round(Num * AScaleFactor);
    Result := True;
  end;
end;

end.
