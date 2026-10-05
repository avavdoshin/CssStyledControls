unit CssAntiAlias;

{$mode objfpc}{$H+}

{ Anti-aliased drawing helper unit.

  Provides:
    - parameter types for AA primitives (corner radii, gradients, shadows);
    - base AA primitives: triangle, circle, rounded box, check mark,
      filled rounded-rect overlay;
    - caches of pre-rendered bitmaps and coverage masks so that expensive
      rasterisation is done only once per unique shape signature;
    - a global cache-invalidation helper, to be called when the theme changes. }

interface

uses
  Classes, SysUtils, Graphics, Types;

type
  TCssBorderStyle = (cbsNone, cbsSolid, cbsDotted, cbsDashed);

  TCssCornerRadii = record
    TL, TR, BR, BL: Integer;
  end;

  TCssGradientStop = record
    Position: Double;
    Color: TColor;
  end;

  TCssGradientKind = (cgkNone, cgkLinear, cgkRadial);

  TCssGradient = record
    Kind: TCssGradientKind;
    Angle: Double;
    Stops: array of TCssGradientStop;
  end;

  TCssBoxShadow = record
    OffsetX, OffsetY, Blur, Spread: Integer;
    Color: TColor;
    HasColor: Boolean;
    Used: Boolean;
  end;

  TCssRoundedBoxParams = record
    Radii: TCssCornerRadii;
    FillColor: TColor;
    BorderColor: TColor;
    BorderWidth: Integer;
    BorderStyle: TCssBorderStyle;
    CornerBackColor: array[0..3] of TColor;
    Shadow: TCssBoxShadow;
    Gradient: TCssGradient;
    HasGradient: Boolean;
  end;

  // ----- Cached masks (used by checkboxes, radio buttons and the tree) -----

  TCssCheckMarkMaskEntry = class
    Width, Height: Integer;
    LineWidthX10: Integer;
    Coverage: array of Byte;
    constructor Create;
    function Matches(AW, AH: Integer; ALineWidth: Double): Boolean;
  end;

  TCssDotMaskEntry = class
    Size: Integer;
    Coverage: array of Byte;
    constructor Create;
    function Matches(ASize: Integer): Boolean;
  end;

function EmptyRoundedBoxParams: TCssRoundedBoxParams;

// ----- Basic operations -----

procedure AABlendCoverageToCanvas(
  ACanvas: TCanvas;
  ALeft, ATop, AWidth, AHeight: Integer;
  const ACoverage: array of Byte;
  AColor: TColor);

procedure AABuildCheckMarkCoverage(
  var ACoverage: array of Byte;
  AW, AH: Integer;
  const AX1, AY1, AX2, AY2, AX3, AY3: Double;
  ALineWidth: Double);

// ----- AA primitives -----

procedure DrawAATriangle(
  ACanvas: TCanvas;
  const AP1, AP2, AP3: TPoint;
  AColor: TColor;
  ABackgroundColor: TColor);

procedure DrawAACircle(
  ACanvas: TCanvas;
  const ARect: TRect;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABackgroundColor: TColor);

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AParams: TCssRoundedBoxParams); overload;

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  const ARadii: TCssCornerRadii;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor); overload;

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadius: Integer;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor); overload;

procedure DrawAACheckMark(
  ACanvas: TCanvas;
  const ARect: TRect;
  AColor: TColor);

{ Draws a 1..N px anti-aliased rounded-rect outline ("focus ring") on top
  of already-drawn canvas content. Ring pixels are alpha-blended with the
  existing canvas colours. Coordinates are clipped to the canvas bounds. }
procedure DrawAARoundedRectRing(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadius: Integer;
  ALineWidth: Integer;
  AColor: TColor);

{ Blends a filled rounded-rect mask onto an already-drawn canvas without
  first rasterising the box to a bitmap. Used, for instance, for the
  hover highlight of the tree header. }
procedure DrawAARoundedRectOverlay(
  ACanvas: TCanvas;
  const ARect: TRect;
  const ARadii: TCssCornerRadii;
  AColor: TColor);

// ----- Cached masks -----

function GetCheckMarkMask(AW, AH: Integer;
  ALineWidth: Double): TCssCheckMarkMaskEntry;

function GetDotMask(ASize: Integer): TCssDotMaskEntry;

procedure InvalidateAACaches;

implementation

uses
  Math, IntfGraphics, FPImage;

// ============================================================================
//  Numeric helpers
// ============================================================================

function ClampD(AValue, AMin, AMax: Double): Double; inline;
begin
  if AValue < AMin then Result := AMin
  else if AValue > AMax then Result := AMax
  else Result := AValue;
end;

// Signed distance to a rounded box (centered at origin).
function SdRoundBox(PX, PY, HW, HH, R: Double): Double;
var
  QX, QY: Double;
begin
  QX := Abs(PX) - HW + R;
  QY := Abs(PY) - HH + R;
  Result :=
    Min(Max(QX, QY), 0.0) +
    Sqrt(Sqr(Max(QX, 0.0)) + Sqr(Max(QY, 0.0))) - R;
end;

procedure ClampCornerRadii(
  var RTL, RTR, RBR, RBL: Double;
  W, H: Double);
var
  F, F1, F2, F3, F4: Double;
begin
  F1 := 1.0; F2 := 1.0; F3 := 1.0; F4 := 1.0;

  if (RTL + RTR) > 0 then F1 := W / (RTL + RTR);
  if (RBR + RBL) > 0 then F2 := W / (RBR + RBL);
  if (RTL + RBL) > 0 then F3 := H / (RTL + RBL);
  if (RTR + RBR) > 0 then F4 := H / (RTR + RBR);

  F := F1;
  if F2 < F then F := F2;
  if F3 < F then F := F3;
  if F4 < F then F := F4;
  if F > 1.0 then F := 1.0;
  if F < 0.0 then F := 0.0;

  RTL := RTL * F; RTR := RTR * F;
  RBR := RBR * F; RBL := RBL * F;
end;

function SdRoundBoxPC(
  PX, PY, HW, HH, RTL, RTR, RBR, RBL: Double): Double;
var
  R, QX, QY: Double;
begin
  if (PX >= 0) and (PY < 0) then R := RTR
  else if (PX < 0) and (PY < 0) then R := RTL
  else if (PX < 0) and (PY >= 0) then R := RBL
  else R := RBR;

  QX := Abs(PX) - HW + R;
  QY := Abs(PY) - HH + R;

  Result :=
    Min(Max(QX, QY), 0.0) +
    Sqrt(Sqr(Max(QX, 0.0)) + Sqr(Max(QY, 0.0))) - R;
end;

function SdPerimeterAngle(
  PX, PY, HW, HH, RTL, RTR, RBR, RBL: Double): Double;
const
  EPS = 0.5;
var
  GX, GY: Double;
begin
  GX := SdRoundBoxPC(PX + EPS, PY, HW, HH, RTL, RTR, RBR, RBL) -
        SdRoundBoxPC(PX - EPS, PY, HW, HH, RTL, RTR, RBR, RBL);
  GY := SdRoundBoxPC(PX, PY + EPS, HW, HH, RTL, RTR, RBR, RBL) -
        SdRoundBoxPC(PX, PY - EPS, HW, HH, RTL, RTR, RBR, RBL);

  Result := ArcTan2(GY, GX);
end;

function LerpColor(C1, C2: TColor; T: Double): TColor;
var
  RGB1, RGB2: LongInt;
  R1, G1, B1, R2, G2, B2: Integer;
begin
  if T <= 0 then Exit(C1);
  if T >= 1 then Exit(C2);

  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);

  R1 := RGB1 and $FF; G1 := (RGB1 shr 8) and $FF; B1 := (RGB1 shr 16) and $FF;
  R2 := RGB2 and $FF; G2 := (RGB2 shr 8) and $FF; B2 := (RGB2 shr 16) and $FF;

  Result := RGBToColor(
    Round(R1 + (R2 - R1) * T),
    Round(G1 + (G2 - G1) * T),
    Round(B1 + (B2 - B1) * T)
  );
end;

procedure EvalGradientColor(
  const G: TCssGradient;
  PX, PY, HW, HH: Double;
  out R, GG, B: Byte);
var
  T, LocalT, DirX, DirY, Proj, L, MaxR: Double;
  I: Integer;
  Col: TColor;
  RGB: LongInt;
begin
  R := 0; GG := 0; B := 0;

  if Length(G.Stops) = 0 then Exit;

  if G.Kind = cgkLinear then
  begin
    DirX := Sin(G.Angle);
    DirY := -Cos(G.Angle);

    Proj := PX * DirX + PY * DirY;
    L := Abs(DirX) * (2 * HW) + Abs(DirY) * (2 * HH);

    if L > 1E-6 then T := Proj / L + 0.5 else T := 0.5;
  end
  else
  begin
    MaxR := Sqrt(HW * HW + HH * HH);
    if MaxR > 1E-6 then T := Sqrt(PX * PX + PY * PY) / MaxR else T := 0;
  end;

  T := ClampD(T, 0, 1);

  if T <= G.Stops[0].Position then
    Col := G.Stops[0].Color
  else if T >= G.Stops[High(G.Stops)].Position then
    Col := G.Stops[High(G.Stops)].Color
  else
  begin
    Col := G.Stops[0].Color;

    for I := 0 to High(G.Stops) - 1 do
    begin
      if (T >= G.Stops[I].Position) and (T <= G.Stops[I + 1].Position) then
      begin
        if G.Stops[I + 1].Position - G.Stops[I].Position > 1E-6 then
          LocalT := (T - G.Stops[I].Position) /
                    (G.Stops[I + 1].Position - G.Stops[I].Position)
        else
          LocalT := 0;

        Col := LerpColor(G.Stops[I].Color, G.Stops[I + 1].Color, LocalT);
        Break;
      end;
    end;
  end;

  RGB := ColorToRGB(Col);
  R  := Byte(RGB and $FF);
  GG := Byte((RGB shr 8) and $FF);
  B  := Byte((RGB shr 16) and $FF);
end;

function EmptyRoundedBoxParams: TCssRoundedBoxParams;
begin
  Result.Radii.TL := 0;
  Result.Radii.TR := 0;
  Result.Radii.BR := 0;
  Result.Radii.BL := 0;
  Result.FillColor := clNone;
  Result.BorderColor := clNone;
  Result.BorderWidth := 0;
  Result.BorderStyle := cbsNone;
  Result.CornerBackColor[0] := clBtnFace;
  Result.CornerBackColor[1] := clBtnFace;
  Result.CornerBackColor[2] := clBtnFace;
  Result.CornerBackColor[3] := clBtnFace;
  Result.Shadow.Used := False;
  Result.Shadow.HasColor := False;
  Result.Shadow.OffsetX := 0;
  Result.Shadow.OffsetY := 0;
  Result.Shadow.Blur := 0;
  Result.Shadow.Spread := 0;
  Result.Shadow.Color := clBlack;
  Result.Gradient.Kind := cgkNone;
  Result.Gradient.Angle := 0;
  SetLength(Result.Gradient.Stops, 0);
  Result.HasGradient := False;
end;

// ============================================================================
//  Rounded rectangle rasteriser (corner radii, shadow, gradient)
// ============================================================================

procedure RenderRoundedRectToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams;
  APadX, APadY: Integer);
var
  Img: TLazIntfImage;
  PW, PH, X, Y: Integer;
  BgR, BgG, BgB: Byte;
  BgRGB: TColor;
  FillR, FillG, FillB: Byte;
  BorderR, BorderG, BorderB: Byte;
  ShadowR, ShadowG, ShadowB: Byte;
  HasFill, HasBorder, HasShadow: Boolean;
  Pixel: TFPColor;
  HW, HH, RTL, RTR, RBR, RBL, BW: Double;
  Blur, Spread, ShadowOffX, ShadowOffY: Double;
  PX, PY, SDF, SDF_Shadow: Double;
  OuterCov, InnerCov, BorderCov, ShadowCov: Double;
  FillRGB, BorderRGB, ShadowRGB: TColor;
  CompR, CompG, CompB: Double;
  DashMask, Param: Double;
  IsDash, IsDot: Boolean;
  FFR, FFG, FFB: Byte;
  UseGrad: Boolean;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then Exit;

  PW := AW + APadX * 2;
  PH := AH + APadY * 2;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(PW, PH);

  HasFill := (AParams.FillColor <> clNone) and
             (AParams.FillColor <> clDefault);
  HasBorder := (AParams.BorderWidth > 0) and
               (AParams.BorderColor <> clNone) and
               (AParams.BorderColor <> clDefault);
  HasShadow := AParams.Shadow.Used and AParams.Shadow.HasColor;

  UseGrad := AParams.HasGradient and
             (AParams.Gradient.Kind <> cgkNone) and
             (Length(AParams.Gradient.Stops) > 0);

  IsDash := AParams.BorderStyle = cbsDashed;
  IsDot  := AParams.BorderStyle = cbsDotted;

  if HasFill then
  begin
    FillRGB := ColorToRGB(AParams.FillColor);
    FillR := Byte(FillRGB and $FF);
    FillG := Byte((FillRGB shr 8) and $FF);
    FillB := Byte((FillRGB shr 16) and $FF);
  end
  else
  begin
    FillR := 0; FillG := 0; FillB := 0;
  end;

  if HasBorder then
  begin
    BorderRGB := ColorToRGB(AParams.BorderColor);
    BorderR := Byte(BorderRGB and $FF);
    BorderG := Byte((BorderRGB shr 8) and $FF);
    BorderB := Byte((BorderRGB shr 16) and $FF);
  end
  else
  begin
    BorderR := 0; BorderG := 0; BorderB := 0;
  end;

  if HasShadow then
  begin
    ShadowRGB := ColorToRGB(AParams.Shadow.Color);
    ShadowR := Byte(ShadowRGB and $FF);
    ShadowG := Byte((ShadowRGB shr 8) and $FF);
    ShadowB := Byte((ShadowRGB shr 16) and $FF);
  end
  else
  begin
    ShadowR := 0; ShadowG := 0; ShadowB := 0;
  end;

  Img := ABitmap.CreateIntfImage;
  try
    HW := AW / 2.0;
    HH := AH / 2.0;

    RTL := AParams.Radii.TL;
    RTR := AParams.Radii.TR;
    RBR := AParams.Radii.BR;
    RBL := AParams.Radii.BL;
    ClampCornerRadii(RTL, RTR, RBR, RBL, AW, AH);

    BW := AParams.BorderWidth;
    if BW < 0 then BW := 0;

    ShadowOffX := AParams.Shadow.OffsetX;
    ShadowOffY := AParams.Shadow.OffsetY;
    Blur       := AParams.Shadow.Blur;
    Spread     := AParams.Shadow.Spread;

    for Y := 0 to PH - 1 do
    begin
      for X := 0 to PW - 1 do
      begin
        PX := X + 0.5 - APadX - HW;
        PY := Y + 0.5 - APadY - HH;

        // Pick the "outside" colour for the current corner quadrant.
        if (PX < 0) and (PY < 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[0])   // TL
        else if (PX >= 0) and (PY < 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[1])   // TR
        else if (PX >= 0) and (PY >= 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[2])   // BR
        else
          BgRGB := ColorToRGB(AParams.CornerBackColor[3]);  // BL

        BgR := Byte(BgRGB and $FF);
        BgG := Byte((BgRGB shr 8) and $FF);
        BgB := Byte((BgRGB shr 16) and $FF);

        // Box shadow coverage.
        ShadowCov := 0;
        if HasShadow then
        begin
          SDF_Shadow := SdRoundBoxPC(
            PX - ShadowOffX, PY - ShadowOffY,
            HW + Spread, HH + Spread,
            RTL + Spread, RTR + Spread,
            RBR + Spread, RBL + Spread
          );

          if Blur > 0.5 then
            ShadowCov := ClampD(0.5 - SDF_Shadow / Blur, 0, 1)
          else
            ShadowCov := ClampD(0.5 - SDF_Shadow, 0, 1);
        end;

        SDF := SdRoundBoxPC(PX, PY, HW, HH, RTL, RTR, RBR, RBL);
        OuterCov := ClampD(0.5 - SDF, 0, 1);

        if HasBorder then
          InnerCov := ClampD(0.5 - (SDF + BW), 0, 1)
        else
          InnerCov := OuterCov;

        BorderCov := OuterCov - InnerCov;

        // Dashed / dotted borders use a perimeter parameter.
        if HasBorder and (IsDash or IsDot) and (BorderCov > 0.001) then
        begin
          Param := SdPerimeterAngle(PX, PY, HW, HH, RTL, RTR, RBR, RBL);
          Param := (Param + Pi) / (2 * Pi);

          if IsDash then
            DashMask := Frac(Param * 24)
          else
            DashMask := Frac(Param * 48);

          if IsDash then
            if DashMask < 0.6 then DashMask := 1 else DashMask := 0
          else
            if DashMask < 0.35 then DashMask := 1 else DashMask := 0;

          BorderCov := BorderCov * DashMask;
        end;

        if ShadowCov > 0 then
          ShadowCov := ShadowCov * (1 - OuterCov);

        CompR := BgR * (1 - ShadowCov) + ShadowR * ShadowCov;
        CompG := BgG * (1 - ShadowCov) + ShadowG * ShadowCov;
        CompB := BgB * (1 - ShadowCov) + ShadowB * ShadowCov;

        if UseGrad then
        begin
          EvalGradientColor(AParams.Gradient, PX, PY, HW, HH, FFR, FFG, FFB);
          CompR := CompR * (1 - InnerCov) + FFR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FFG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FFB * InnerCov;
        end
        else if HasFill then
        begin
          CompR := CompR * (1 - InnerCov) + FillR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FillG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FillB * InnerCov;
        end;

        if HasBorder then
        begin
          CompR := CompR * (1 - BorderCov) + BorderR * BorderCov;
          CompG := CompG * (1 - BorderCov) + BorderG * BorderCov;
          CompB := CompB * (1 - BorderCov) + BorderB * BorderCov;
        end;

        Pixel.Red   := Round(ClampD(CompR, 0, 255)) * 257;
        Pixel.Green := Round(ClampD(CompG, 0, 255)) * 257;
        Pixel.Blue  := Round(ClampD(CompB, 0, 255)) * 257;
        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;
    end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

// ============================================================================
//  Triangle and circle rasterisers
// ============================================================================

function EdgeDistanceSigned(
  const A, B: TPoint;
  PX, PY: Double;
  AOutSign: Double): Double; inline;
var
  DX, DY, L: Double;
begin
  DX := B.X - A.X;
  DY := B.Y - A.Y;
  Result := (DX * (PY - A.Y) - DY * (PX - A.X)) * AOutSign;
  L := Sqrt(DX * DX + DY * DY);
  if L > 1E-9 then
    Result := Result / L
  else
    Result := 0;
end;

procedure RenderTriangleToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  const AP1, AP2, AP3: TPoint;
  AColor, ABgColor: TColor);
var
  Img: TLazIntfImage;
  X, Y: Integer;
  BgR, BgG, BgB: Byte;
  FR, FG, FB: Byte;
  BgRGB, FillRGB: TColor;
  Pixel: TFPColor;
  PX, PY: Double;
  Area, Sign: Double;
  D12, D23, D31: Double;
  MinD, Cov: Double;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then Exit;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);

  BgRGB := ColorToRGB(ABgColor);
  BgR := Byte(BgRGB and $FF);
  BgG := Byte((BgRGB shr 8) and $FF);
  BgB := Byte((BgRGB shr 16) and $FF);

  FillRGB := ColorToRGB(AColor);
  FR := Byte(FillRGB and $FF);
  FG := Byte((FillRGB shr 8) and $FF);
  FB := Byte((FillRGB shr 16) and $FF);

  // Orientation sign: inside is where all edge distances are positive.
  Area := (AP2.X - AP1.X) * (AP3.Y - AP1.Y) - (AP2.Y - AP1.Y) * (AP3.X - AP1.X);
  if Area >= 0 then Sign := 1 else Sign := -1;

  Img := ABitmap.CreateIntfImage;
  try
    for Y := 0 to AH - 1 do
      for X := 0 to AW - 1 do
      begin
        PX := X + 0.5;
        PY := Y + 0.5;

        D12 := EdgeDistanceSigned(AP1, AP2, PX, PY, Sign);
        D23 := EdgeDistanceSigned(AP2, AP3, PX, PY, Sign);
        D31 := EdgeDistanceSigned(AP3, AP1, PX, PY, Sign);

        MinD := D12;
        if D23 < MinD then MinD := D23;
        if D31 < MinD then MinD := D31;

        Cov := 0.5 + MinD;

        if Cov <= 0 then
        begin
          Pixel.Red   := BgR * 257;
          Pixel.Green := BgG * 257;
          Pixel.Blue  := BgB * 257;
        end
        else if Cov >= 1 then
        begin
          Pixel.Red   := FR * 257;
          Pixel.Green := FG * 257;
          Pixel.Blue  := FB * 257;
        end
        else
        begin
          Pixel.Red   := Round(FR * Cov + BgR * (1 - Cov)) * 257;
          Pixel.Green := Round(FG * Cov + BgG * (1 - Cov)) * 257;
          Pixel.Blue  := Round(FB * Cov + BgB * (1 - Cov)) * 257;
        end;

        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

procedure RenderCircleToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABgColor: TColor);
var
  Img: TLazIntfImage;
  X, Y: Integer;
  BgR, BgG, BgB: Byte;
  FillR, FillG, FillB: Byte;
  BorR, BorG, BorB: Byte;
  BgRGB, FillRGB, BorRGB: TColor;
  Pixel: TFPColor;
  CX, CY, R: Double;
  Dist, OuterCov, InnerCov, BorderCov: Double;
  HasFill, HasBorder: Boolean;
  PX, PY, CompR, CompG, CompB: Double;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then Exit;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);

  BgRGB := ColorToRGB(ABgColor);
  BgR := Byte(BgRGB and $FF);
  BgG := Byte((BgRGB shr 8) and $FF);
  BgB := Byte((BgRGB shr 16) and $FF);

  HasFill := (AFillColor <> clNone) and (AFillColor <> clDefault);
  HasBorder := (ABorderWidth > 0) and
               (ABorderColor <> clNone) and (ABorderColor <> clDefault);

  if HasFill then
  begin
    FillRGB := ColorToRGB(AFillColor);
    FillR := Byte(FillRGB and $FF);
    FillG := Byte((FillRGB shr 8) and $FF);
    FillB := Byte((FillRGB shr 16) and $FF);
  end
  else
  begin
    FillR := 0; FillG := 0; FillB := 0;
  end;

  if HasBorder then
  begin
    BorRGB := ColorToRGB(ABorderColor);
    BorR := Byte(BorRGB and $FF);
    BorG := Byte((BorRGB shr 8) and $FF);
    BorB := Byte((BorRGB shr 16) and $FF);
  end
  else
  begin
    BorR := 0; BorG := 0; BorB := 0;
  end;

  CX := AW / 2.0;
  CY := AH / 2.0;
  R := Min(AW, AH) / 2.0 - 0.5;
  if R < 0 then R := 0;

  Img := ABitmap.CreateIntfImage;
  try
    for Y := 0 to AH - 1 do
      for X := 0 to AW - 1 do
      begin
        PX := X + 0.5 - CX;
        PY := Y + 0.5 - CY;
        Dist := Sqrt(PX * PX + PY * PY);

        OuterCov := 0.5 + (R - Dist);
        if OuterCov < 0 then OuterCov := 0
        else if OuterCov > 1 then OuterCov := 1;

        InnerCov := 0.5 + (R - ABorderWidth - Dist);
        if InnerCov < 0 then InnerCov := 0
        else if InnerCov > 1 then InnerCov := 1;

        BorderCov := OuterCov - InnerCov;
        if BorderCov < 0 then BorderCov := 0;

        CompR := BgR; CompG := BgG; CompB := BgB;

        if HasFill and (InnerCov > 0) then
        begin
          CompR := CompR * (1 - InnerCov) + FillR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FillG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FillB * InnerCov;
        end;

        if HasBorder and (BorderCov > 0) then
        begin
          CompR := CompR * (1 - BorderCov) + BorR * BorderCov;
          CompG := CompG * (1 - BorderCov) + BorG * BorderCov;
          CompB := CompB * (1 - BorderCov) + BorB * BorderCov;
        end;

        Pixel.Red   := Round(CompR) * 257;
        Pixel.Green := Round(CompG) * 257;
        Pixel.Blue  := Round(CompB) * 257;
        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

// ============================================================================
//  Caches
// ============================================================================

type
  TCssRoundedRectCacheEntry = class
    Signature: string;
    Bitmap: TBitmap;
    constructor Create;
    destructor Destroy; override;
  end;

  TCssRoundedRectCache = class
  private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetBitmap(
      AW, AH: Integer;
      const AParams: TCssRoundedBoxParams): TBitmap;
  end;

const
  CSS_ROUNDED_RECT_CACHE_LIMIT = 96;

constructor TCssRoundedRectCacheEntry.Create;
begin
  inherited;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf32bit;
end;

destructor TCssRoundedRectCacheEntry.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

constructor TCssRoundedRectCache.Create;
begin
  inherited;
  FEntries := TStringList.Create;
  FEntries.CaseSensitive := True;
  FEntries.Sorted := False;
end;

destructor TCssRoundedRectCache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited;
end;

procedure TCssRoundedRectCache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssRoundedRectCacheEntry(FEntries.Objects[I]).Free;
  FEntries.Clear;
end;

function BuildRoundedRectSignature(
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams): string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(AW).Append(',').Append(AH).Append('|');
    SB.Append(AParams.Radii.TL).Append(',')
      .Append(AParams.Radii.TR).Append(',')
      .Append(AParams.Radii.BR).Append(',')
      .Append(AParams.Radii.BL).Append('|');

    SB.Append(AParams.BorderWidth).Append(',')
      .Append(Ord(AParams.BorderStyle)).Append('|');

    SB.Append(IntToStr(AParams.FillColor)).Append(',')
      .Append(IntToStr(AParams.BorderColor)).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[0])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[1])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[2])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[3])).Append('|');

    SB.Append(Ord(AParams.Shadow.Used)).Append(';');
    if AParams.Shadow.Used then
      SB.Append(AParams.Shadow.OffsetX).Append(',')
        .Append(AParams.Shadow.OffsetY).Append(',')
        .Append(AParams.Shadow.Blur).Append(',')
        .Append(AParams.Shadow.Spread).Append(',')
        .Append(IntToStr(AParams.Shadow.Color));

    SB.Append('|').Append(Ord(AParams.HasGradient)).Append(';');
    if AParams.HasGradient and (AParams.Gradient.Kind <> cgkNone) then
    begin
      SB.Append(Ord(AParams.Gradient.Kind)).Append(',');
      SB.Append(FormatFloat('0.0000', AParams.Gradient.Angle)).Append(';');

      for I := 0 to High(AParams.Gradient.Stops) do
        SB.Append(FormatFloat('0.0000', AParams.Gradient.Stops[I].Position))
          .Append(':')
          .Append(IntToStr(AParams.Gradient.Stops[I].Color))
          .Append(';');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure ComputeShadowPad(
  const AShadow: TCssBoxShadow;
  out APadX, APadY: Integer);
begin
  if AShadow.Used then
  begin
    APadX := Abs(AShadow.OffsetX) + AShadow.Blur + AShadow.Spread + 2;
    APadY := Abs(AShadow.OffsetY) + AShadow.Blur + AShadow.Spread + 2;
  end
  else
  begin
    APadX := 0;
    APadY := 0;
  end;
end;

function TCssRoundedRectCache.GetBitmap(
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams): TBitmap;
var
  Sig: string;
  Idx, PadX, PadY: Integer;
  Entry: TCssRoundedRectCacheEntry;
begin
  Sig := BuildRoundedRectSignature(AW, AH, AParams);

  Idx := FEntries.IndexOf(Sig);

  if Idx >= 0 then
  begin
    Entry := TCssRoundedRectCacheEntry(FEntries.Objects[Idx]);

    // Move to the end (LRU).
    FEntries.Delete(Idx);
    FEntries.AddObject(Sig, Entry);

    Exit(Entry.Bitmap);
  end;

  while FEntries.Count >= CSS_ROUNDED_RECT_CACHE_LIMIT do
  begin
    TCssRoundedRectCacheEntry(FEntries.Objects[0]).Free;
    FEntries.Delete(0);
  end;

  ComputeShadowPad(AParams.Shadow, PadX, PadY);

  Entry := TCssRoundedRectCacheEntry.Create;
  Entry.Signature := Sig;

  RenderRoundedRectToBitmap(Entry.Bitmap, AW, AH, AParams, PadX, PadY);

  FEntries.AddObject(Sig, Entry);
  Result := Entry.Bitmap;
end;

type
  TCssAACacheEntry = class
    Signature: string;
    Bitmap: TBitmap;
    constructor Create;
    destructor Destroy; override;
  end;

  TCssAACache = class
  private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetBitmap(const ASignature: string): TBitmap;
    procedure PutBitmap(const ASignature: string; ABitmap: TBitmap);
  end;

const
  CSS_AA_CACHE_LIMIT = 128;

constructor TCssAACacheEntry.Create;
begin
  inherited;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf32bit;
end;

destructor TCssAACacheEntry.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

constructor TCssAACache.Create;
begin
  inherited;
  FEntries := TStringList.Create;
  FEntries.CaseSensitive := True;
  FEntries.Sorted := False;
end;

destructor TCssAACache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited;
end;

procedure TCssAACache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssAACacheEntry(FEntries.Objects[I]).Free;
  FEntries.Clear;
end;

function TCssAACache.GetBitmap(const ASignature: string): TBitmap;
var
  Idx: Integer;
  E: TCssAACacheEntry;
begin
  Idx := FEntries.IndexOf(ASignature);

  if Idx < 0 then
    Exit(nil);

  E := TCssAACacheEntry(FEntries.Objects[Idx]);

  // Move to the end (LRU).
  FEntries.Delete(Idx);
  FEntries.AddObject(ASignature, E);

  Result := E.Bitmap;
end;

procedure TCssAACache.PutBitmap(const ASignature: string; ABitmap: TBitmap);
var
  E: TCssAACacheEntry;
begin
  while FEntries.Count >= CSS_AA_CACHE_LIMIT do
  begin
    TCssAACacheEntry(FEntries.Objects[0]).Free;
    FEntries.Delete(0);
  end;

  E := TCssAACacheEntry.Create;
  E.Signature := ASignature;
  E.Bitmap.Assign(ABitmap);

  FEntries.AddObject(ASignature, E);
end;

var
  GRoundedRectCache: TCssRoundedRectCache = nil;
  GShapeCache: TCssAACache = nil;

procedure EnsureRoundedRectCache;
begin
  if GRoundedRectCache = nil then
    GRoundedRectCache := TCssRoundedRectCache.Create;
end;

procedure EnsureShapeCache;
begin
  if GShapeCache = nil then
    GShapeCache := TCssAACache.Create;
end;

// ============================================================================
//  Check mark mask cache
// ============================================================================

constructor TCssCheckMarkMaskEntry.Create;
begin
  inherited Create;
  SetLength(Coverage, 0);
end;

function TCssCheckMarkMaskEntry.Matches(AW, AH: Integer;
  ALineWidth: Double): Boolean;
begin
  Result :=
    (Width = AW) and (Height = AH) and
    (LineWidthX10 = Round(ALineWidth * 10));
end;

type
  TCssCheckMarkCache = class
  private
    FEntries: TList;
    function IndexOfEntry(AW, AH: Integer; ALineWidth: Double): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetMask(AW, AH: Integer; ALineWidth: Double): TCssCheckMarkMaskEntry;
  end;

const
  CSS_CHECKMARK_CACHE_LIMIT = 48;

constructor TCssCheckMarkCache.Create;
begin
  inherited Create;
  FEntries := TList.Create;
end;

destructor TCssCheckMarkCache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited Destroy;
end;

procedure TCssCheckMarkCache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssCheckMarkMaskEntry(FEntries[I]).Free;
  FEntries.Clear;
end;

function TCssCheckMarkCache.IndexOfEntry(AW, AH: Integer;
  ALineWidth: Double): Integer;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    if TCssCheckMarkMaskEntry(FEntries[I]).Matches(AW, AH, ALineWidth) then
      Exit(I);
  Result := -1;
end;

function TCssCheckMarkCache.GetMask(
  AW, AH: Integer; ALineWidth: Double): TCssCheckMarkMaskEntry;
var
  Idx: Integer;
  E: TCssCheckMarkMaskEntry;
  X1, Y1, X2, Y2, X3, Y3: Double;
begin
  Idx := IndexOfEntry(AW, AH, ALineWidth);

  if Idx >= 0 then
  begin
    E := TCssCheckMarkMaskEntry(FEntries[Idx]);
    FEntries.Delete(Idx);
    FEntries.Add(E);
    Exit(E);
  end;

  if FEntries.Count >= CSS_CHECKMARK_CACHE_LIMIT then
    Clear;

  E := TCssCheckMarkMaskEntry.Create;
  E.Width := AW;
  E.Height := AH;
  E.LineWidthX10 := Round(ALineWidth * 10);

  SetLength(E.Coverage, AW * AH);

  X1 := AW * 0.20;  Y1 := AH * 0.50;
  X2 := AW * 0.40;  Y2 := AH * 0.75;
  X3 := AW * 0.80;  Y3 := AH * 0.22;

  AABuildCheckMarkCoverage(
    E.Coverage, AW, AH,
    X1, Y1, X2, Y2, X3, Y3,
    ALineWidth
  );

  FEntries.Add(E);
  Result := E;
end;

// ============================================================================
//  Radio dot mask cache
// ============================================================================

constructor TCssDotMaskEntry.Create;
begin
  inherited Create;
  SetLength(Coverage, 0);
end;

function TCssDotMaskEntry.Matches(ASize: Integer): Boolean;
begin
  Result := Size = ASize;
end;

procedure BuildDotCoverage(
  var ACoverage: array of Byte;
  ASize: Integer);
var
  X, Y: Integer;
  CX, CY, R, Dist, Cov: Double;
  Idx: Integer;
begin
  for Idx := 0 to ASize * ASize - 1 do
    ACoverage[Idx] := 0;

  CX := ASize / 2.0;
  CY := ASize / 2.0;
  R  := ASize * 0.28;

  for Y := 0 to ASize - 1 do
    for X := 0 to ASize - 1 do
    begin
      Dist := Sqrt(Sqr(X + 0.5 - CX) + Sqr(Y + 0.5 - CY));
      Cov := R + 0.5 - Dist;

      if Cov <= 0 then
        Continue;
      if Cov > 1 then
        Cov := 1;

      ACoverage[Y * ASize + X] := Round(Cov * 255);
    end;
end;

type
  TCssDotCache = class
  private
    FEntries: TList;
    function IndexOfEntry(ASize: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetMask(ASize: Integer): TCssDotMaskEntry;
  end;

const
  CSS_DOT_CACHE_LIMIT = 48;

constructor TCssDotCache.Create;
begin
  inherited Create;
  FEntries := TList.Create;
end;

destructor TCssDotCache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited Destroy;
end;

procedure TCssDotCache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssDotMaskEntry(FEntries[I]).Free;
  FEntries.Clear;
end;

function TCssDotCache.IndexOfEntry(ASize: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    if TCssDotMaskEntry(FEntries[I]).Matches(ASize) then
      Exit(I);
  Result := -1;
end;

function TCssDotCache.GetMask(ASize: Integer): TCssDotMaskEntry;
var
  Idx: Integer;
  E: TCssDotMaskEntry;
begin
  Idx := IndexOfEntry(ASize);

  if Idx >= 0 then
  begin
    E := TCssDotMaskEntry(FEntries[Idx]);
    FEntries.Delete(Idx);
    FEntries.Add(E);
    Exit(E);
  end;

  if FEntries.Count >= CSS_DOT_CACHE_LIMIT then
    Clear;

  E := TCssDotMaskEntry.Create;
  E.Size := ASize;
  SetLength(E.Coverage, ASize * ASize);

  BuildDotCoverage(E.Coverage, ASize);

  FEntries.Add(E);
  Result := E;
end;

var
  GCheckMarkCache: TCssCheckMarkCache = nil;
  GDotCache: TCssDotCache = nil;

function GetCheckMarkMask(AW, AH: Integer;
  ALineWidth: Double): TCssCheckMarkMaskEntry;
begin
  if GCheckMarkCache = nil then
    GCheckMarkCache := TCssCheckMarkCache.Create;

  Result := GCheckMarkCache.GetMask(AW, AH, ALineWidth);
end;

function GetDotMask(ASize: Integer): TCssDotMaskEntry;
begin
  if GDotCache = nil then
    GDotCache := TCssDotCache.Create;

  Result := GDotCache.GetMask(ASize);
end;

// ============================================================================
//  Public operations
// ============================================================================

procedure AABlendCoverageToCanvas(
  ACanvas: TCanvas;
  ALeft, ATop, AWidth, AHeight: Integer;
  const ACoverage: array of Byte;
  AColor: TColor);
var
  X, Y, Idx: Integer;
  Cov, InvCov: Double;
  LineRGB, BgRGB: TColor;
  LR, LG, LB: Byte;
  BR, BG, BB: Byte;
  R, G, B: Integer;
  DstColor: TColor;
begin
  if ACanvas = nil then Exit;
  if (AWidth <= 0) or (AHeight <= 0) then Exit;
  if Length(ACoverage) < AWidth * AHeight then Exit;

  LineRGB := ColorToRGB(AColor);
  LR := Byte(LineRGB and $FF);
  LG := Byte((LineRGB shr 8) and $FF);
  LB := Byte((LineRGB shr 16) and $FF);

  for Y := 0 to AHeight - 1 do
    for X := 0 to AWidth - 1 do
    begin
      Idx := Y * AWidth + X;
      if ACoverage[Idx] = 0 then
        Continue;

      Cov := ACoverage[Idx] / 255.0;
      InvCov := 1.0 - Cov;

      DstColor := ACanvas.Pixels[ALeft + X, ATop + Y];
      BgRGB := ColorToRGB(DstColor);
      BR := Byte(BgRGB and $FF);
      BG := Byte((BgRGB shr 8) and $FF);
      BB := Byte((BgRGB shr 16) and $FF);

      R := Round(LR * Cov + BR * InvCov);
      G := Round(LG * Cov + BG * InvCov);
      B := Round(LB * Cov + BB * InvCov);

      ACanvas.Pixels[ALeft + X, ATop + Y] := RGBToColor(R, G, B);
    end;
end;

procedure AABuildCheckMarkCoverage(
  var ACoverage: array of Byte;
  AW, AH: Integer;
  const AX1, AY1, AX2, AY2, AX3, AY3: Double;
  ALineWidth: Double);
var
  I: Integer;
  Half: Double;

  // Rasterises one AA line segment into the coverage buffer.
  // Coverage values are accumulated with max() so overlapping segments
  // (the corner of a check mark) do not darken each other.
  procedure FillSegment(X1, Y1, X2, Y2: Double);
  var
    MinX, MaxX, MinY, MaxY: Integer;
    LX, LY: Integer;
    DX, DY, LenSq, T, CX, CY, Dist, Cov: Double;
    PX, PY: Double;
    ByteCov: Byte;
    Idx: Integer;
  begin
    MinX := Floor(Min(X1, X2) - Half - 1);
    MaxX := Ceil (Max(X1, X2) + Half + 1);
    MinY := Floor(Min(Y1, Y2) - Half - 1);
    MaxY := Ceil (Max(Y1, Y2) + Half + 1);

    if MinX < 0   then MinX := 0;
    if MinY < 0   then MinY := 0;
    if MaxX >= AW then MaxX := AW - 1;
    if MaxY >= AH then MaxY := AH - 1;

    if (MinX > MaxX) or (MinY > MaxY) then Exit;

    DX := X2 - X1;
    DY := Y2 - Y1;
    LenSq := DX * DX + DY * DY;

    for LY := MinY to MaxY do
      for LX := MinX to MaxX do
      begin
        if LenSq > 1E-9 then
        begin
          T := ((LX + 0.5 - X1) * DX + (LY + 0.5 - Y1) * DY) / LenSq;
          if T < 0 then T := 0
          else if T > 1 then T := 1;

          CX := X1 + T * DX;
          CY := Y1 + T * DY;

          PX := LX + 0.5 - CX;
          PY := LY + 0.5 - CY;
          Dist := Sqrt(PX * PX + PY * PY);
        end
        else
        begin
          PX := LX + 0.5 - X1;
          PY := LY + 0.5 - Y1;
          Dist := Sqrt(PX * PX + PY * PY);
        end;

        Cov := Half + 0.5 - Dist;
        if Cov <= 0 then
          Continue;
        if Cov > 1 then
          Cov := 1;

        ByteCov := Round(Cov * 255);
        Idx := LY * AW + LX;

        if ByteCov > ACoverage[Idx] then
          ACoverage[Idx] := ByteCov;
      end;
  end;

begin
  if (AW <= 0) or (AH <= 0) then Exit;
  if Length(ACoverage) < AW * AH then Exit;

  for I := 0 to AW * AH - 1 do
    ACoverage[I] := 0;

  Half := ALineWidth / 2;

  FillSegment(AX1, AY1, AX2, AY2);
  FillSegment(AX2, AY2, AX3, AY3);
end;

procedure DrawAATriangle(
  ACanvas: TCanvas;
  const AP1, AP2, AP3: TPoint;
  AColor: TColor;
  ABackgroundColor: TColor);
var
  MinX, MinY, MaxX, MaxY, W, H: Integer;
  Sig: string;
  Bmp: TBitmap;
  Buf: TBitmap;
  P1, P2, P3: TPoint;
begin
  if ACanvas = nil then Exit;
  if AColor = clNone then Exit;

  MinX := AP1.X; if AP2.X < MinX then MinX := AP2.X; if AP3.X < MinX then MinX := AP3.X;
  MinY := AP1.Y; if AP2.Y < MinY then MinY := AP2.Y; if AP3.Y < MinY then MinY := AP3.Y;
  MaxX := AP1.X; if AP2.X > MaxX then MaxX := AP2.X; if AP3.X > MaxX then MaxX := AP3.X;
  MaxY := AP1.Y; if AP2.Y > MaxY then MaxY := AP2.Y; if AP3.Y > MaxY then MaxY := AP3.Y;

  // Leave a 1px margin for AA on both sides.
  Dec(MinX); Dec(MinY);
  Inc(MaxX); Inc(MaxY);

  W := MaxX - MinX;
  H := MaxY - MinY;

  if (W <= 0) or (H <= 0) then Exit;

  P1 := Point(AP1.X - MinX, AP1.Y - MinY);
  P2 := Point(AP2.X - MinX, AP2.Y - MinY);
  P3 := Point(AP3.X - MinX, AP3.Y - MinY);

  Sig := Format('T|%d,%d|%d,%d|%d,%d|%d,%d|%d|%d',
    [W, H,
     P1.X, P1.Y,
     P2.X, P2.Y,
     P3.X, P3.Y,
     Integer(AColor), Integer(ABackgroundColor)]);

  EnsureShapeCache;

  Bmp := GShapeCache.GetBitmap(Sig);

  if Bmp = nil then
  begin
    Buf := TBitmap.Create;
    try
      RenderTriangleToBitmap(Buf, W, H, P1, P2, P3, AColor, ABackgroundColor);
      GShapeCache.PutBitmap(Sig, Buf);
      Bmp := GShapeCache.GetBitmap(Sig);
    finally
      Buf.Free;
    end;
  end;

  if Bmp <> nil then
    ACanvas.Draw(MinX, MinY, Bmp);
end;

procedure DrawAACircle(
  ACanvas: TCanvas;
  const ARect: TRect;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABackgroundColor: TColor);
var
  W, H: Integer;
  Sig: string;
  Buf: TBitmap;
  Bmp: TBitmap;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  Sig := Format('C|%d,%d|%d|%d|%d|%d',
    [W, H, Integer(AFillColor), Integer(ABorderColor),
     ABorderWidth, Integer(ABackgroundColor)]);

  EnsureShapeCache;

  Bmp := GShapeCache.GetBitmap(Sig);

  if Bmp = nil then
  begin
    Buf := TBitmap.Create;
    try
      RenderCircleToBitmap(Buf, W, H, AFillColor, ABorderColor,
        ABorderWidth, ABackgroundColor);
      GShapeCache.PutBitmap(Sig, Buf);
      Bmp := GShapeCache.GetBitmap(Sig);
    finally
      Buf.Free;
    end;
  end;

  if Bmp <> nil then
    ACanvas.Draw(ARect.Left, ARect.Top, Bmp);
end;

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AParams: TCssRoundedBoxParams);
var
  W, H, PadX, PadY: Integer;
  Bmp: TBitmap;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  EnsureRoundedRectCache;

  Bmp := GRoundedRectCache.GetBitmap(W, H, AParams);

  ComputeShadowPad(AParams.Shadow, PadX, PadY);

  ACanvas.Draw(ARect.Left - PadX, ARect.Top - PadY, Bmp);
end;

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  const ARadii: TCssCornerRadii;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor);
var
  Params: TCssRoundedBoxParams;
begin
  Params := EmptyRoundedBoxParams;
  Params.Radii := ARadii;
  Params.FillColor := AFillColor;
  Params.BorderColor := ABorderColor;
  Params.BorderWidth := ABorderWidth;
  Params.BorderStyle := ABorderStyle;
  Params.CornerBackColor[0] := ABackgroundColor;
  Params.CornerBackColor[1] := ABackgroundColor;
  Params.CornerBackColor[2] := ABackgroundColor;
  Params.CornerBackColor[3] := ABackgroundColor;

  DrawAARoundedBox(ACanvas, ARect, Params);
end;

procedure DrawAARoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadius: Integer;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor);
var
  Radii: TCssCornerRadii;
begin
  Radii.TL := ARadius;
  Radii.TR := ARadius;
  Radii.BR := ARadius;
  Radii.BL := ARadius;

  DrawAARoundedBox(
    ACanvas, ARect, Radii,
    AFillColor, ABorderColor, ABorderWidth,
    ABorderStyle, ABackgroundColor
  );
end;

procedure DrawAACheckMark(
  ACanvas: TCanvas;
  const ARect: TRect;
  AColor: TColor);
var
  W, H: Integer;
  Coverage: array of Byte;
  LineWidth: Double;
  X1, Y1, X2, Y2, X3, Y3: Double;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  if W < 12 then
    LineWidth := 1.5
  else if W < 20 then
    LineWidth := 2.0
  else
    LineWidth := 2.5;

  SetLength(Coverage, W * H);

  X1 := W * 0.20;  Y1 := H * 0.50;
  X2 := W * 0.40;  Y2 := H * 0.75;
  X3 := W * 0.80;  Y3 := H * 0.22;

  AABuildCheckMarkCoverage(
    Coverage, W, H,
    X1, Y1, X2, Y2, X3, Y3,
    LineWidth
  );

  AABlendCoverageToCanvas(
    ACanvas,
    ARect.Left, ARect.Top,
    W, H,
    Coverage,
    AColor
  );
end;

procedure DrawAARoundedRectRing(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadius: Integer;
  ALineWidth: Integer;
  AColor: TColor);
var
  GeomR, LoopR: TRect;
  W, H, X, Y: Integer;
  Coverage: array of Byte;
  HW, HH, RR: Double;
  CX, CY, PX, PY: Double;
  SDOuter, SDInner, OuterCov, InnerCov, RingCov: Double;
begin
  if ACanvas = nil then Exit;
  if AColor = clNone then Exit;
  if ALineWidth < 1 then ALineWidth := 1;

  GeomR := ARect;
  InflateRect(GeomR, -1, -1);
  if (GeomR.Right <= GeomR.Left) or (GeomR.Bottom <= GeomR.Top) then Exit;

  if ARadius > (GeomR.Bottom - GeomR.Top) div 2 then
    ARadius := (GeomR.Bottom - GeomR.Top) div 2;
  if ARadius > (GeomR.Right - GeomR.Left) div 2 then
    ARadius := (GeomR.Right - GeomR.Left) div 2;

  // Sharp-corner fast path: plain Rectangle.
  if ARadius <= 0 then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := ALineWidth;
    ACanvas.Pen.Color := AColor;
    ACanvas.Rectangle(GeomR.Left, GeomR.Top, GeomR.Right, GeomR.Bottom);
    Exit;
  end;

  // Clip iteration to the canvas bounds; pixels outside are not touched.
  LoopR := GeomR;
  if LoopR.Left < 0 then LoopR.Left := 0;
  if LoopR.Top < 0 then LoopR.Top := 0;
  if LoopR.Right > ACanvas.Width then LoopR.Right := ACanvas.Width;
  if LoopR.Bottom > ACanvas.Height then LoopR.Bottom := ACanvas.Height;

  W := LoopR.Right - LoopR.Left;
  H := LoopR.Bottom - LoopR.Top;

  if (W <= 0) or (H <= 0) then Exit;

  HW := (GeomR.Right - GeomR.Left) / 2.0;
  HH := (GeomR.Bottom - GeomR.Top) / 2.0;
  CX := GeomR.Left + HW;
  CY := GeomR.Top + HH;
  RR := ARadius;

  SetLength(Coverage, W * H);

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      PX := LoopR.Left + X + 0.5 - CX;
      PY := LoopR.Top + Y + 0.5 - CY;

      SDOuter := SdRoundBox(PX, PY, HW, HH, RR);
      if SDOuter > 1.0 then
        Continue;

      SDInner := SdRoundBox(PX, PY, HW - ALineWidth, HH - ALineWidth,
        RR - ALineWidth);

      OuterCov := ClampD(0.5 - SDOuter, 0, 1);
      InnerCov := ClampD(0.5 - SDInner, 0, 1);
      RingCov := OuterCov - InnerCov;

      if RingCov <= 0 then
        Continue;
      if RingCov > 1 then
        RingCov := 1;

      Coverage[Y * W + X] := Round(RingCov * 255);
    end;

  AABlendCoverageToCanvas(ACanvas, LoopR.Left, LoopR.Top, W, H,
    Coverage, AColor);
end;

procedure DrawAARoundedRectOverlay(
  ACanvas: TCanvas;
  const ARect: TRect;
  const ARadii: TCssCornerRadii;
  AColor: TColor);
var
  W, H, X, Y: Integer;
  Coverage: array of Byte;
  HW, HH, R: Double;
  CX, CY, QX, QY, SDF, Cov: Double;
  RTL, RTR, RBR, RBL: Double;
begin
  if ACanvas = nil then Exit;
  if AColor = clNone then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  HW := W / 2.0;
  HH := H / 2.0;

  RTL := ARadii.TL;
  RTR := ARadii.TR;
  RBR := ARadii.BR;
  RBL := ARadii.BL;
  ClampCornerRadii(RTL, RTR, RBR, RBL, W, H);

  SetLength(Coverage, W * H);

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      CX := X + 0.5 - HW;
      CY := Y + 0.5 - HH;

      if (CX >= 0) and (CY < 0) then
        R := RTR
      else if (CX < 0) and (CY < 0) then
        R := RTL
      else if (CX < 0) and (CY >= 0) then
        R := RBL
      else
        R := RBR;

      if R < 0 then
        R := 0;

      QX := Abs(CX) - HW + R;
      QY := Abs(CY) - HH + R;

      SDF :=
        Min(Max(QX, QY), 0.0) +
        Sqrt(Sqr(Max(QX, 0.0)) + Sqr(Max(QY, 0.0))) - R;

      Cov := 0.5 - SDF;
      if Cov < 0 then Cov := 0
      else if Cov > 1 then Cov := 1;

      Coverage[Y * W + X] := Round(Cov * 255);
    end;

  AABlendCoverageToCanvas(ACanvas, ARect.Left, ARect.Top, W, H, Coverage, AColor);
end;

procedure InvalidateAACaches;
begin
  if Assigned(GRoundedRectCache) then
    GRoundedRectCache.Clear;

  if Assigned(GShapeCache) then
    GShapeCache.Clear;

  if Assigned(GCheckMarkCache) then
    GCheckMarkCache.Clear;

  if Assigned(GDotCache) then
    GDotCache.Clear;
end;

initialization
  // Caches are created lazily (see Ensure* procedures).

finalization
  FreeAndNil(GRoundedRectCache);
  FreeAndNil(GShapeCache);
  FreeAndNil(GCheckMarkCache);
  FreeAndNil(GDotCache);

end.
