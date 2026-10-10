unit CssSvgImgList;
{$mode objfpc}{$H+}

{
  TCssSvgImgList - non-visual component, analog of TImageList.

  Stores images in native SVG format and can provide them:
    - as SVG text (GetSvg);
    - as raster of any size (GetBitmap / DrawToCanvas) with
      anti-aliasing (via primitives from CssAntiAlias) and with
      High DPI support (Width/Height scaled by PixelsPerInch/96,
      if Scaled = True).

  Supported SVG subset:
    - elements: svg, g, path, rect, circle, ellipse, line, polyline, polygon, text, tspan;
    - path commands: M m L l H h V v C c S s Q q T t A a Z z;
    - transforms: translate, scale, rotate, skewX, skewY, matrix;
    - styles: fill, fill-opacity, fill-rule, stroke, stroke-opacity,
      stroke-width, stroke-linecap, stroke-linejoin, stroke-miterlimit,
      opacity, color (currentColor), style="...", display, visibility;
    - gradients: linearGradient, radialGradient (with gradientTransform, spreadMethod);
    - viewBox + preserveAspectRatio (meet/slice, alignment, none).
  Not supported: filters, <use>/references to <defs> (except gradients), <textPath>.
}

interface

uses
  Classes, SysUtils, Graphics, Types, ImgList, IntfGraphics, CssAntiAlias;

type
  // --------------------------------------------------------------------------
  //  2D matrices (SVG transforms)
  // --------------------------------------------------------------------------
  TSvgMatrix = record
    A, B, C, D, E, F: Double;
  end;

function SvgMatrixIdentity: TSvgMatrix;
function SvgMatrixMake(AA, BB, CC, DD, EE, FF: Double): TSvgMatrix;
function SvgMatrixMultiply(const M1, M2: TSvgMatrix): TSvgMatrix;
function SvgMatrixTranslate(X, Y: Double): TSvgMatrix;
function SvgMatrixScale(SX, SY: Double): TSvgMatrix;
function SvgMatrixRotate(AngleDeg: Double): TSvgMatrix;
function SvgMatrixSkewX(AngleDeg: Double): TSvgMatrix;
function SvgMatrixSkewY(AngleDeg: Double): TSvgMatrix;
function SvgMatrixTransformPoint(const M: TSvgMatrix; const P: TPointF): TPointF;
function ParseSvgTransformList(const S: string): TSvgMatrix;

  // --------------------------------------------------------------------------
  //  Styles and geometry (internal representation of parsed SVG)
  // --------------------------------------------------------------------------
type
  TSvgFillRule = (svgfrNonZero, svgfrEvenOdd);
  TSvgLineCap  = (svglcButt, svglcRound, svglcSquare);
  TSvgLineJoin = (svgljMiter, svgljRound, svgljBevel);

  TSvgPaint = record
    IsNone: Boolean;
    IsCurrent: Boolean;   // currentColor
    IsGradient: Boolean;
    GradientId: string;
    Color: TColor;
  end;

  TSvgStyle = record
    Fill: TSvgPaint;
    FillOpacity: Double;
    FillRule: TSvgFillRule;
    Stroke: TSvgPaint;
    StrokeOpacity: Double;
    StrokeWidth: Double;
    LineCap: TSvgLineCap;
    LineJoin: TSvgLineJoin;
    MiterLimit: Double;
    Opacity: Double;       // accumulated through group hierarchy
    CurrentColor: TColor;
  end;

  TSvgCtx = record
    M: TSvgMatrix;
    St: TSvgStyle;
  end;

  TSvgSegKind = (sskLine, sskQuad, sskCubic);

  TSvgSeg = record
    Kind: TSvgSegKind;
    P1, P2, P3: TPointF;   // line: P1=end; quad: P1=ctrl,P2=end; cubic: P1,P2=ctrl,P3=end
  end;

  TSvgSubpath = record
    Start: TPointF;
    Segs: array of TSvgSeg;
    Closed: Boolean;
  end;

  TSvgPathData = array of TSvgSubpath;

  TSvgGradientUnits = (svgguUserSpaceOnUse, svgguObjectBoundingBox);

  TSvgGradientDef = record
    Id: string;
    Kind: TSvgGradientKind;
    X1, Y1, X2, Y2: Double;
    CX, CY, R, FX, FY: Double;
    Stops: array of TSvgGradientStop;
    Transform: TSvgGradientMatrix;
    SpreadMethod: TSvgGradientSpreadMethod;
    GradientUnits: TSvgGradientUnits;
  end;

  TSvgTextAnchor = (svgtaStart, svgtaMiddle, svgtaEnd);

  TSvgTextRun = record
    Text: string;
    HasX, HasY: Boolean;
    X, Y: Double;
    DX, DY: Double;
    Family: string;
    FontSize: Double;
    Bold, Italic: Boolean;
    Style: TSvgStyle;
  end;

  TSvgShape = record
    IsText: Boolean;
    Path: TSvgPathData;
    TextRuns: array of TSvgTextRun;
    TextAnchor: TSvgTextAnchor;
    Style: TSvgStyle;
  end;

  // --------------------------------------------------------------------------
  //  TSvgImage - one parsed SVG picture
  // --------------------------------------------------------------------------
  TSvgImage = class
  private
    FSvg: string;
    FParsed: Boolean;
    FError: string;
    FShapes: array of TSvgShape;
    FGradients: array of TSvgGradientDef;
    FVBX, FVBY, FVBW, FVBH: Double;
    FHasViewBox: Boolean;
    FIntrinsicW, FIntrinsicH: Double;
    FParNone, FParSlice: Boolean;
    FParAlignX, FParAlignY: Integer; // 0=min, 1=mid, 2=max
    procedure ParseSvgRootAttrs(const AAttrs: string);
    procedure ParseViewBoxAttr(const S: string);
    procedure ParsePreserveAspectRatio(const S: string);
    procedure ParseShape(const ATagName, AAttrs: string; const ACtx: TSvgCtx);
    procedure ParseTextElement(const S: string; var APos: Integer;
      const ATextAttrs: string; const ACtx: TSvgCtx);
    procedure ParseGradient(const ATagName, AAttrs: string; var APos: Integer);
    procedure Parse;
    procedure ComputeView(AW, AH: Integer; out SX, SY, OX, OY: Double);
    function FlattenSubpathPts(const ASP: TSvgSubpath;
      SX, SY, OX, OY, ATol: Double): TAAFloatPoints;
    function GetShapeCount: Integer;
    procedure InternalRender(ACanvas: TCanvas; AImg: TLazIntfImage;
      AOfsX, AOfsY, AW, AH: Integer; ACurrentColor: TColor);
    procedure RenderTextShape(const AShp: TSvgShape; ACanvas: TCanvas;
      AImg: TLazIntfImage; AOfsX, AOfsY, AW, AH: Integer;
      SX, SY, OX, OY: Double; ACurrentColor: TColor);
    function BuildTextRunCoverage(const Run: TSvgTextRun;
      AAnchor: TSvgTextAnchor; SX, SY, OX, OY: Double;
      AW, AH: Integer; var PenX, PenY: Double;
      var ACoverage: array of Byte): Boolean;
    function FindGradient(const AId: string): Integer;
    function BuildGradientParams(const ADef: TSvgGradientDef;
      const APath: TSvgPathData; SX, SY, OX, OY: Double): TSvgGradientParams;
  public
    constructor Create(const ASvg: string);
    procedure RenderToCanvas(ACanvas: TCanvas; AX, AY, AW, AH: Integer;
      ACurrentColor: TColor = clDefault);
    procedure RenderToBitmap(ABitmap: TBitmap; AW, AH: Integer;
      ACurrentColor: TColor = clDefault);
    property Error: string read FError;
    property ShapeCount: Integer read GetShapeCount;
    property IntrinsicWidth: Double read FIntrinsicW;
    property IntrinsicHeight: Double read FIntrinsicH;
  end;

  // --------------------------------------------------------------------------
  //  Component
  // --------------------------------------------------------------------------
  TCssSvgImgList = class;

  { Draws a pf32bit bitmap with per-pixel alpha onto ACanvas.

    Manual pixel loop, deliberately not using TBitmap.AlphaFormat (missing
    in older LCL) or TLazIntfImage.AlphaBlend (signature changed across
    LCL versions). For typical icon sizes the per-pixel cost is negligible.

    Used by TCssBitBtn, TCssMenuItem, TCssTabControl to composite an SVG
    glyph that was rendered by TCssSvgImgList. }
  procedure DrawSvgBitmapWithAlpha(ACanvas: TCanvas; AX, AY: Integer;
    ABmp: TBitmap);

type
  TCssSvgImgListItem = class(TCollectionItem)
  private
    FName: string;
    FSvg: string;
    FVariants: TStringList;     // 'VariantName=SVG text'
    FImage: TSvgImage;          // lazily created cache
    FImageVariant: string;      // which variant FImage was built from

    function  GetImage: TSvgImage;
    function  GetVariants: TStrings;
    procedure SetSvg(const AValue: string);
    procedure SetName(const AValue: string);
    procedure SetVariants(const AValue: TStrings);
    procedure OnVariantsChanged(Sender: TObject);
  public
    constructor Create(ACollection: TCollection); override;
    destructor  Destroy; override;

    { Effective SVG for AVariant, falling back to Svg. }
    function EffectiveSvg(const AVariant: string): string;

    { Lazily parsed image for AVariant, cached. }
    function GetImageForVariant(const AVariant: string): TSvgImage;

    property Image: TSvgImage read GetImage;
  published
    property Name: string read FName write SetName;
    property Svg: string read FSvg write SetSvg;

    { Per-variant SVG overrides, in "VariantName=SVG text" format.
      Example:
        dark=<svg ...>
        light=<svg ...>
      Variants not listed fall back to Svg. }
    property Variants: TStrings read GetVariants write SetVariants;
  end;

  TCssSvgImgListItems = class(TCollection)
  private
    FOwner: TCssSvgImgList;
    function GetItem(Index: Integer): TCssSvgImgListItem;
    procedure SetItem(Index: Integer; const AValue: TCssSvgImgListItem);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TCssSvgImgList);
    function Add: TCssSvgImgListItem;
    property Items[Index: Integer]: TCssSvgImgListItem
      read GetItem write SetItem; default;
  end;

  TCssSvgImgList = class(TComponent)
  private
    FItems: TCssSvgImgListItems;
    FWidth: Integer;
    FHeight: Integer;
    FScaled: Boolean;
    FDefaultVariant: string;
    FOnChange: TNotifyEvent;
    FSerial: Integer;
    FCache: TStringList;
    function  GetCount: Integer;
    procedure SetItems(const AValue: TCssSvgImgListItems);
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    procedure SetScaled(AValue: Boolean);
    procedure SetDefaultVariant(const AValue: string);
    procedure ClearCache;
    function  CacheGet(const ASig: string): TBitmap;
    procedure CachePut(const ASig: string; ABitmap: TBitmap);
  protected
    procedure Changed; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Assign(Source: TPersistent); override;

    function  Count: Integer;
    function  IndexOf(const AName: string): Integer;
    function  AddSvg(const AName, ASvg: string): Integer;
    function  AddSvgFromFile(const AName, AFileName: string): Integer;
    procedure Delete(AIndex: Integer);
    procedure Clear;

    { --- Access to the source SVG text --- }
    function  GetSvg(AIndex: Integer): string; overload;
    function  GetSvg(const AName: string): string; overload;
    procedure SetSvg(AIndex: Integer; const AValue: string);
    function  GetParseError(AIndex: Integer): string;

    { --- High DPI --- }
    function  GetScaleFactor: Double;
    function  GetEffectiveWidth: Integer;
    function  GetEffectiveHeight: Integer;

    { --- Variants --- }
    function  GetVariantNames: TStrings;   // caller owns the list
    function  HasVariant(const AVariant: string): Boolean;

    { --- Raster output (caller owns the returned TBitmap) --- }
    function  GetBitmap(AIndex: Integer; AWidth, AHeight: Integer;
      ACurrentColor: TColor = clDefault): TBitmap; overload;
    function  GetBitmap(AIndex: Integer; AWidth, AHeight: Integer;
      ACurrentColor: TColor; const AVariant: string): TBitmap; overload;

    function  GetBitmapByName(const AName: string;
      AWidth, AHeight: Integer;
      ACurrentColor: TColor = clDefault): TBitmap; overload;
    function  GetBitmapByName(const AName: string;
      AWidth, AHeight: Integer;
      ACurrentColor: TColor; const AVariant: string): TBitmap; overload;

    { --- Drawing to canvas --- }
    procedure DrawToCanvas(ACanvas: TCanvas; AIndex: Integer;
      AX, AY: Integer); overload;
    procedure DrawToCanvas(ACanvas: TCanvas; AIndex: Integer;
      AX, AY, AW, AH: Integer;
      ACurrentColor: TColor = clDefault); overload;

    { --- Compatibility with standard TImageList --- }
    procedure AssignToImageList(AImageList: TCustomImageList;
      ACurrentColor: TColor = clDefault);

    { --- Batch save/load --- }
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
  published
    property Width: Integer read FWidth write SetWidth default 16;
    property Height: Integer read FHeight write SetHeight default 16;
    property Scaled: Boolean read FScaled write SetScaled default True;

    { Variant used by parameterless GetBitmap / DrawToCanvas overloads
      and by consumers such as TCssBitBtn / TCssMenuItem / TCssTabControl.
      Leave empty to always use the per-item Svg. }
    property DefaultVariant: string
      read FDefaultVariant write SetDefaultVariant;

    property Items: TCssSvgImgListItems read FItems write SetItems;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Math, StrUtils, FPImage, Forms, LCLIntf, LCLType, CssUtils, CssFontUtils;

// Supersampling factor for text rendering (2 = good balance, 4 = max quality)
const
  CSSVG_TEXT_SUPERSAMPLE = 2;

// ============================================================================
//  Matrices
// ============================================================================

function SvgMatrixIdentity: TSvgMatrix;
begin
  Result.A := 1; Result.B := 0; Result.C := 0;
  Result.D := 1; Result.E := 0; Result.F := 0;
end;

function SvgMatrixMake(AA, BB, CC, DD, EE, FF: Double): TSvgMatrix;
begin
  Result.A := AA; Result.B := BB; Result.C := CC;
  Result.D := DD; Result.E := EE; Result.F := FF;
end;

function SvgMatrixMultiply(const M1, M2: TSvgMatrix): TSvgMatrix;
begin
  Result.A := M1.A * M2.A + M1.C * M2.B;
  Result.B := M1.B * M2.A + M1.D * M2.B;
  Result.C := M1.A * M2.C + M1.C * M2.D;
  Result.D := M1.B * M2.C + M1.D * M2.D;
  Result.E := M1.A * M2.E + M1.C * M2.F + M1.E;
  Result.F := M1.B * M2.E + M1.D * M2.F + M1.F;
end;

function SvgMatrixTranslate(X, Y: Double): TSvgMatrix;
begin
  Result := SvgMatrixIdentity;
  Result.E := X;
  Result.F := Y;
end;

function SvgMatrixScale(SX, SY: Double): TSvgMatrix;
begin
  Result := SvgMatrixIdentity;
  Result.A := SX;
  Result.D := SY;
end;

function SvgMatrixRotate(AngleDeg: Double): TSvgMatrix;
var
  R, C, S: Double;
begin
  R := AngleDeg * Pi / 180;
  C := Cos(R);
  S := Sin(R);
  Result := SvgMatrixMake(C, S, -S, C, 0, 0);
end;

function SvgMatrixSkewX(AngleDeg: Double): TSvgMatrix;
begin
  Result := SvgMatrixIdentity;
  Result.C := Tan(AngleDeg * Pi / 180);
end;

function SvgMatrixSkewY(AngleDeg: Double): TSvgMatrix;
begin
  Result := SvgMatrixIdentity;
  Result.B := Tan(AngleDeg * Pi / 180);
end;

function SvgMatrixTransformPoint(const M: TSvgMatrix; const P: TPointF): TPointF;
begin
  Result.X := M.A * P.X + M.C * P.Y + M.E;
  Result.Y := M.B * P.X + M.D * P.Y + M.F;
end;

// ============================================================================
//  Common parser helper functions
// ============================================================================

function SvgPointF(X, Y: Double): TPointF; inline;
begin
  Result.X := X;
  Result.Y := Y;
end;

function SvgStrToDouble(const S: string; out V: Double): Boolean;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := TryStrToFloat(S, V, FS);
end;

function SvgClamp01(AValue: Double): Double;
begin
  if AValue < 0 then Result := 0
  else if AValue > 1 then Result := 1
  else Result := AValue;
end;

// ---------------------------------------------------------------------------
//  Supersampled rasterisation for TCssSvgImgList.GetBitmap
//
//  The vector rasteriser produces correct geometry, but at small icon
//  sizes (16..48 px) the diagonal edges of an SVG cannot avoid visible
//  stair-stepping: there are simply not enough pixels for a proper AA
//  gradient, no matter how accurate the coverage mask is.
//
//  The fix here is the classic one: render at a multiple of the target
//  size, then downsample with a box filter. The internal render is
//  capped at CSSVG_SUPER_MAX_DIM px on the longest side, so large
//  requests (>= 256 px) fall through to a plain single-pass render.
//
//  Cache hits are unaffected: the supersampling only runs the very
//  first time a given (image, size, colour, variant) tuple is asked
//  for, and the downsampled bitmap is what gets stored.
// ---------------------------------------------------------------------------

const
  CSSVG_SUPER_MAX_DIM = 256;
  CSSVG_SUPER_MAX_FACTOR = 4;

{ Returns the integer supersampling factor for the requested size:
    32x32  -> 4  (render 128x128, downsample to 32x32)
    48x48  -> 4  (render 192x192, downsample to 48x48)
    64x64  -> 4  (render 256x256, downsample to 64x64)
    128x128 -> 2
    256x256 -> 1
    512x512 -> 1 }
function ComputeSvgSuperFactor(AWidth, AHeight: Integer): Integer;
var
  MaxDim: Integer;
begin
  MaxDim := AWidth;
  if AHeight > MaxDim then
    MaxDim := AHeight;

  if MaxDim <= 0 then
    Exit(1);

  Result := CSSVG_SUPER_MAX_DIM div MaxDim;

  if Result < 1 then
    Result := 1;
  if Result > CSSVG_SUPER_MAX_FACTOR then
    Result := CSSVG_SUPER_MAX_FACTOR;
end;

{ Box-filter downsampling with premultiplied alpha.

  ASrc must be exactly AFactor times larger than ADst in both
  dimensions. Pixels are averaged in premultiplied form, then
  un-premultiplied, so transparent SVG areas with arbitrary (black or
  undefined) RGB do not bleed dark halos into the visible edge. }
procedure DownsampleBitmapAlpha(ASrc, ADst: TLazIntfImage;
  AFactor: Integer);
var
  X, Y, XX, YY: Integer;
  SumR, SumG, SumB, SumA: Int64;
  Pix, OutPix: TFPColor;
  Count: Integer;
begin
  Count := AFactor * AFactor;

  for Y := 0 to ADst.Height - 1 do
    for X := 0 to ADst.Width - 1 do
    begin
      SumR := 0;
      SumG := 0;
      SumB := 0;
      SumA := 0;

      for YY := 0 to AFactor - 1 do
        for XX := 0 to AFactor - 1 do
        begin
          Pix := ASrc.Colors[X * AFactor + XX, Y * AFactor + YY];

          Inc(SumR, Int64(Pix.Red)   * Int64(Pix.Alpha));
          Inc(SumG, Int64(Pix.Green) * Int64(Pix.Alpha));
          Inc(SumB, Int64(Pix.Blue)  * Int64(Pix.Alpha));
          Inc(SumA, Int64(Pix.Alpha));
        end;

      OutPix.Alpha := SumA div Count;

      if SumA > 0 then
      begin
        OutPix.Red   := SumR div SumA;
        OutPix.Green := SumG div SumA;
        OutPix.Blue  := SumB div SumA;
      end
      else
      begin
        OutPix.Red   := 0;
        OutPix.Green := 0;
        OutPix.Blue  := 0;
      end;

      ADst.Colors[X, Y] := OutPix;
    end;
end;

procedure DrawSvgBitmapWithAlpha(ACanvas: TCanvas; AX, AY: Integer;
  ABmp: TBitmap);
var
  Img: TLazIntfImage;
  X, Y, DX, DY: Integer;
  Pix: TFPColor;
  A: Integer;
  DstColor: TColor;
  SR, SG, SB, DR, DG, DB, R, G, B: Integer;
begin
  if (ACanvas = nil) or (ABmp = nil) or ABmp.Empty then Exit;

  Img := ABmp.CreateIntfImage;
  if Img = nil then Exit;

  try
    for Y := 0 to Img.Height - 1 do
    begin
      DY := AY + Y;
      if (DY < 0) or (DY >= ACanvas.Height) then Continue;

      for X := 0 to Img.Width - 1 do
      begin
        DX := AX + X;
        if (DX < 0) or (DX >= ACanvas.Width) then Continue;

        Pix := Img.Colors[X, Y];
        A := Pix.Alpha shr 8;
        if A = 0 then Continue;

        SR := Pix.Red   shr 8;
        SG := Pix.Green shr 8;
        SB := Pix.Blue  shr 8;

        if A = 255 then
          ACanvas.Pixels[DX, DY] := RGBToColor(SR, SG, SB)
        else
        begin
          DstColor := ColorToRGB(ACanvas.Pixels[DX, DY]);
          DR :=  DstColor         and $FF;
          DG := (DstColor shr  8) and $FF;
          DB := (DstColor shr 16) and $FF;

          R := (SR * A + DR * (255 - A)) div 255;
          G := (SG * A + DG * (255 - A)) div 255;
          B := (SB * A + DB * (255 - A)) div 255;

          ACanvas.Pixels[DX, DY] := RGBToColor(R, G, B);
        end;
      end;
    end;
  finally
    Img.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Number/identifier scanner (for path data and transforms)
// ---------------------------------------------------------------------------
type
  TSvgScanner = class
  private
    FText: string;
    FPos: Integer;
  public
    constructor Create(const AText: string);
    function Eof: Boolean;
    procedure SkipSeps;
    function PeekChar: Char;
    function IsCommandChar: Boolean;
    procedure Advance;
    function NextNumber(out AValue: Double): Boolean;
    function NextFlag(out AValue: Boolean): Boolean;
    function NextIdent(out AName: string): Boolean;
  end;

constructor TSvgScanner.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FPos := 1;
end;

function TSvgScanner.Eof: Boolean;
begin
  Result := FPos > Length(FText);
end;

procedure TSvgScanner.SkipSeps;
begin
  while FPos <= Length(FText) do
  begin
    case FText[FPos] of
      ' ', #9, #10, #13, ',': Inc(FPos);
    else
      Break;
    end;
  end;
end;

function TSvgScanner.PeekChar: Char;
begin
  if FPos <= Length(FText) then Result := FText[FPos]
  else Result := #0;
end;

function TSvgScanner.IsCommandChar: Boolean;
var
  C: Char;
begin
  C := PeekChar;
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z'));
end;

procedure TSvgScanner.Advance;
begin
  Inc(FPos);
end;

function TSvgScanner.NextNumber(out AValue: Double): Boolean;
var
  Start, Q: Integer;
  HasDigit, HasDot: Boolean;
  C: Char;
  Tok: string;
  V: Double;
begin
  Result := False;
  SkipSeps;
  if FPos > Length(FText) then Exit;
  Start := FPos;
  if (FText[FPos] = '+') or (FText[FPos] = '-') then Inc(FPos);
  HasDigit := False;
  HasDot := False;
  while FPos <= Length(FText) do
  begin
    C := FText[FPos];
    if (C >= '0') and (C <= '9') then
    begin
      HasDigit := True;
      Inc(FPos);
    end
    else if (C = '.') and (not HasDot) then
    begin
      HasDot := True;
      Inc(FPos);
    end
    else
      Break;
  end;
  if HasDigit and (FPos <= Length(FText)) and
     ((FText[FPos] = 'e') or (FText[FPos] = 'E')) then
  begin
    Q := FPos + 1;
    if (Q <= Length(FText)) and
       ((FText[Q] = '+') or (FText[Q] = '-')) then Inc(Q);
    if (Q <= Length(FText)) and (FText[Q] >= '0') and (FText[Q] <= '9') then
    begin
      FPos := Q;
      while (FPos <= Length(FText)) and
            (FText[FPos] >= '0') and (FText[FPos] <= '9') do
        Inc(FPos);
    end;
  end;
  if not HasDigit then
  begin
    FPos := Start;
    Exit;
  end;
  Tok := Copy(FText, Start, FPos - Start);
  if not SvgStrToDouble(Tok, V) then
  begin
    FPos := Start;
    Exit;
  end;
  AValue := V;
  Result := True;
end;

function TSvgScanner.NextFlag(out AValue: Boolean): Boolean;
begin
  Result := False;
  SkipSeps;
  if FPos > Length(FText) then Exit;
  if FText[FPos] = '0' then
  begin
    AValue := False;
    Inc(FPos);
    Result := True;
  end
  else if FText[FPos] = '1' then
  begin
    AValue := True;
    Inc(FPos);
    Result := True;
  end;
end;

function TSvgScanner.NextIdent(out AName: string): Boolean;
var
  Start: Integer;
  C: Char;
begin
  Result := False;
  SkipSeps;
  Start := FPos;
  while FPos <= Length(FText) do
  begin
    C := FText[FPos];
    if ((C >= 'a') and (C <= 'z')) or ((C >= 'A') and (C <= 'Z')) or
       (C = '-') or (C = '_') then
      Inc(FPos)
    else
      Break;
  end;
  AName := Copy(FText, Start, FPos - Start);
  Result := AName <> '';
end;

function TryParseSvgLength(const S: string; out V: Double): Boolean;
var
  Sc: TSvgScanner;
begin
  Sc := TSvgScanner.Create(S);
  try
    Result := Sc.NextNumber(V);
  finally
    Sc.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Mini-XML: tags, attributes, entities
// ---------------------------------------------------------------------------

function DecodeXmlEntities(const S: string): string;
var
  I, J, V, Code: Integer;
  Tok: string;
  Tmp: string;
begin
  Tmp := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '&') and (I + 2 <= Length(S)) and (S[I + 1] = '#') then
    begin
      J := PosEx(';', S, I);
      if (J > 0) and (J - I <= 9) then
      begin
        Tok := Copy(S, I + 2, J - I - 2);
        V := -1;
        if (Length(Tok) > 0) and ((Tok[1] = 'x') or (Tok[1] = 'X')) then
          V := StrToIntDef('$' + Copy(Tok, 2, MaxInt), -1)
        else
        begin
          Val(Tok, V, Code);
          if Code <> 0 then V := -1;
        end;
        if (V > 0) and (V <= $FFFF) then
        begin
          Tmp := Tmp + UTF8Encode(UnicodeChar(V));
          I := J + 1;
          Continue;
        end;
      end;
    end;
    Tmp := Tmp + S[I];
    Inc(I);
  end;
  Result := Tmp;
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
end;

function NextSvgTag(const S: string; var APos: Integer;
  out AName: string; out AClosing, ASelfClosing: Boolean;
  out AAttrText: string): Boolean;
var
  I, J, Start: Integer;
  Quote: Char;
begin
  Result := False;
  while APos <= Length(S) do
  begin
    if S[APos] <> '<' then
    begin
      Inc(APos);
      Continue;
    end;
    if Copy(S, APos, 4) = '<!--' then
    begin
      J := PosEx('-->', S, APos + 4);
      if J = 0 then
      begin
        APos := Length(S) + 1;
        Exit;
      end;
      APos := J + 3;
      Continue;
    end;
    if (Copy(S, APos, 2) = '<?') or (Copy(S, APos, 2) = '<!') then
    begin
      J := PosEx('>', S, APos + 2);
      if J = 0 then
      begin
        APos := Length(S) + 1;
        Exit;
      end;
      APos := J + 1;
      Continue;
    end;
    I := APos + 1;
    AClosing := False;
    ASelfClosing := False;
    if (I <= Length(S)) and (S[I] = '/') then
    begin
      AClosing := True;
      Inc(I);
    end;
    Start := I;
    while (I <= Length(S)) and (S[I] > ' ') and
          not (S[I] in ['/', '>']) do
      Inc(I);
    AName := LowerCase(Copy(S, Start, I - Start));
    J := I;
    Quote := #0;
    while J <= Length(S) do
    begin
      if Quote <> #0 then
      begin
        if S[J] = Quote then Quote := #0;
      end
      else if (S[J] = '"') or (S[J] = '''') then
        Quote := S[J]
      else if S[J] = '>' then
        Break;
      Inc(J);
    end;
    if J > Length(S) then
    begin
      APos := Length(S) + 1;
      Exit;
    end;
    AAttrText := Copy(S, I, J - I);
    if (AAttrText <> '') and (AAttrText[Length(AAttrText)] = '/') then
    begin
      ASelfClosing := True;
      Delete(AAttrText, Length(AAttrText), 1);
    end;
    APos := J + 1;
    if AName <> '' then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function SvgGetAttr(const AAttrText, AName: string): string;
var
  I, J, L: Integer;
  AttrName, AttrValue: string;
  Quote: Char;
  FName: String;
begin
  Result := '';
  L := Length(AAttrText);
  I := 1;
  FName := LowerCase(AName);
  while I <= L do
  begin
    while (I <= L) and (AAttrText[I] <= ' ') do Inc(I);
    if I > L then Exit;
    J := I;
    while (J <= L) and not (AAttrText[J] in ['=', ' ', #9, #10, #13, '/']) do
      Inc(J);
    AttrName := LowerCase(Copy(AAttrText, I, J - I));
    I := J;
    while (I <= L) and (AAttrText[I] <= ' ') do Inc(I);
    if (I <= L) and (AAttrText[I] = '=') then
    begin
      Inc(I);
      while (I <= L) and (AAttrText[I] <= ' ') do Inc(I);
      if (I <= L) and ((AAttrText[I] = '"') or (AAttrText[I] = '''')) then
      begin
        Quote := AAttrText[I];
        Inc(I);
        J := I;
        while (J <= L) and (AAttrText[J] <> Quote) do Inc(J);
        AttrValue := Copy(AAttrText, I, J - I);
        I := J + 1;
      end
      else
      begin
        J := I;
        while (J <= L) and (AAttrText[J] > ' ') do Inc(J);
        AttrValue := Copy(AAttrText, I, J - I);
        I := J;
      end;
      if AttrName = FName then
        Exit(DecodeXmlEntities(AttrValue));
    end
    else
    begin
      if AttrName = FName then Exit('');
    end;
  end;
end;

procedure SkipUntilClose(const S: string; var APos: Integer; const ATag: string);
var
  I, J: Integer;
  Pat: string;
begin
  Pat := '</' + ATag;
  I := APos;
  while I <= Length(S) do
  begin
    if (S[I] = '<') and SameText(Copy(S, I, Length(Pat)), Pat) then
    begin
      J := PosEx('>', S, I);
      if J = 0 then
        APos := Length(S) + 1
      else
        APos := J + 1;
      Exit;
    end;
    Inc(I);
  end;
  APos := Length(S) + 1;
end;

function SvgElementHidden(const AAttrs: string): Boolean;
var
  Sv, L: string;
begin
  Result := False;

  if SameText(SvgGetAttr(AAttrs, 'display'), 'none') then
    Exit(True);
  if SameText(SvgGetAttr(AAttrs, 'visibility'), 'hidden') then
    Exit(True);

  Sv := SvgGetAttr(AAttrs, 'style');
  if Sv <> '' then
  begin
    L := LowerCase(Sv);
    L := StringReplace(L, ' ', '', [rfReplaceAll]);
    L := StringReplace(L, #9, '', [rfReplaceAll]);
    L := StringReplace(L, #10, '', [rfReplaceAll]);
    L := StringReplace(L, #13, '', [rfReplaceAll]);

    if Pos('display:none', L) > 0 then Exit(True);
    if Pos('visibility:hidden', L) > 0 then Exit(True);
  end;
end;

procedure SkipElement(const S: string; var APos: Integer; const ATag: string);
var
  Depth: Integer;
  TagName, Attrs: string;
  Closing, SelfClosing: Boolean;
begin
  Depth := 1;

  while (APos <= Length(S)) and (Depth > 0) do
  begin
    if not NextSvgTag(S, APos, TagName, Closing, SelfClosing, Attrs) then
      Break;

    if not SameText(TagName, ATag) then
      Continue;

    if Closing then
      Dec(Depth)
    else if not SelfClosing then
      Inc(Depth);
  end;
end;

// Split string by whitespace (compatible with all FPC versions)
procedure SvgSplitWhitespace(const S: string; AList: TStrings);
var
  I, Start: Integer;
begin
  Start := 1;
  for I := 1 to Length(S) + 1 do
  begin
    if (I > Length(S)) or (S[I] <= ' ') then
    begin
      if I > Start then
        AList.Add(Copy(S, Start, I - Start));
      Start := I + 1;
    end;
  end;
end;

// Normalize whitespace in text chunks
function SvgNormalizeTextChunk(const S: string): string;
var
  I: Integer;
  C: Char;
  LastWasSpace: Boolean;
  Tmp: string;
begin
  Tmp := DecodeXmlEntities(S);
  Result := '';
  LastWasSpace := True;
  for I := 1 to Length(Tmp) do
  begin
    C := Tmp[I];
    if (C = ' ') or (C = #9) or (C = #10) or (C = #13) then
    begin
      if not LastWasSpace then
        Result := Result + ' ';
      LastWasSpace := True;
    end
    else
    begin
      Result := Result + C;
      LastWasSpace := False;
    end;
  end;
  Result := Trim(Result);
end;

// ============================================================================
//  Styles
// ============================================================================

function DefaultSvgStyle: TSvgStyle;
begin
  Result.Fill.IsNone := False;
  Result.Fill.IsCurrent := False;
  Result.Fill.IsGradient := False;
  Result.Fill.GradientId := '';
  Result.Fill.Color := clBlack;
  Result.FillOpacity := 1;
  Result.FillRule := svgfrNonZero;
  Result.Stroke.IsNone := True;
  Result.Stroke.IsCurrent := False;
  Result.Stroke.IsGradient := False;
  Result.Stroke.GradientId := '';
  Result.Stroke.Color := clBlack;
  Result.StrokeOpacity := 1;
  Result.StrokeWidth := 1;
  Result.LineCap := svglcButt;
  Result.LineJoin := svgljMiter;
  Result.MiterLimit := 4;
  Result.Opacity := 1;
  Result.CurrentColor := clBlack;
end;

function ParseSvgPaintSpec(const AValue: string; out APaint: TSvgPaint): Boolean;
var
  S: string;
  C: TColor;
  P1, P2: Integer;
begin
  Result := True;
  APaint.IsNone := False;
  APaint.IsCurrent := False;
  APaint.IsGradient := False;
  APaint.GradientId := '';
  APaint.Color := clBlack;
  S := Trim(AValue);
  if SameText(S, 'none') then
    APaint.IsNone := True
  else if SameText(S, 'currentcolor') then
    APaint.IsCurrent := True
  else if Pos('url(', LowerCase(S)) = 1 then
  begin
    P1 := Pos('#', S);
    if P1 > 0 then
    begin
      P2 := PosEx(')', S, P1);
      if P2 = 0 then P2 := Length(S) + 1;
      APaint.GradientId := Trim(Copy(S, P1 + 1, P2 - P1 - 1));
      // Remove quotes if any
      if (Length(APaint.GradientId) > 0) and
         ((APaint.GradientId[1] = '"') or (APaint.GradientId[1] = '''')) then
        Delete(APaint.GradientId, 1, 1);
      if (Length(APaint.GradientId) > 0) and
         ((APaint.GradientId[Length(APaint.GradientId)] = '"') or
          (APaint.GradientId[Length(APaint.GradientId)] = '''')) then
        Delete(APaint.GradientId, Length(APaint.GradientId), 1);
      APaint.IsGradient := APaint.GradientId <> '';
      if not APaint.IsGradient then
        APaint.IsNone := True;
    end
    else
      APaint.IsNone := True;
  end
  else
  begin
    if CssParseColor(S, C) then
      APaint.Color := C
    else
      Result := False;
  end;
end;

function ParseSvgOpacity(const AValue: string; out AOpacity: Double): Boolean;
var
  S: string;
  V: Double;
begin
  Result := False;
  S := Trim(AValue);
  if S = '' then Exit;
  if EndsText('%', S) then
  begin
    if SvgStrToDouble(Copy(S, 1, Length(S) - 1), V) then
    begin
      AOpacity := SvgClamp01(V / 100);
      Result := True;
    end;
    Exit;
  end;
  if SvgStrToDouble(S, V) then
  begin
    AOpacity := SvgClamp01(V);
    Result := True;
  end;
end;

procedure ApplySvgStyleProp(const AName, AValue: string; var St: TSvgStyle);
var
  Paint: TSvgPaint;
  V: Double;
  SV: string;
  C: TColor;
begin
  SV := LowerCase(Trim(AValue));
  if SV = '' then Exit;
  if SV = 'inherit' then Exit;
  if AName = 'fill' then
  begin
    if ParseSvgPaintSpec(AValue, Paint) then St.Fill := Paint;
  end
  else if AName = 'fill-opacity' then
  begin
    if ParseSvgOpacity(AValue, V) then St.FillOpacity := V;
  end
  else if AName = 'fill-rule' then
  begin
    if SV = 'evenodd' then St.FillRule := svgfrEvenOdd
    else if SV = 'nonzero' then St.FillRule := svgfrNonZero;
  end
  else if AName = 'stroke' then
  begin
    if ParseSvgPaintSpec(AValue, Paint) then St.Stroke := Paint;
  end
  else if AName = 'stroke-opacity' then
  begin
    if ParseSvgOpacity(AValue, V) then St.StrokeOpacity := V;
  end
  else if AName = 'stroke-width' then
  begin
    if TryParseSvgLength(AValue, V) and (V >= 0) then St.StrokeWidth := V;
  end
  else if AName = 'stroke-linecap' then
  begin
    if SV = 'round' then St.LineCap := svglcRound
    else if SV = 'square' then St.LineCap := svglcSquare
    else if SV = 'butt' then St.LineCap := svglcButt;
  end
  else if AName = 'stroke-linejoin' then
  begin
    if SV = 'round' then St.LineJoin := svgljRound
    else if SV = 'bevel' then St.LineJoin := svgljBevel
    else if SV = 'miter' then St.LineJoin := svgljMiter;
  end
  else if AName = 'stroke-miterlimit' then
  begin
    if SvgStrToDouble(SV, V) and (V >= 1) then St.MiterLimit := V;
  end
  else if AName = 'opacity' then
  begin
    if ParseSvgOpacity(AValue, V) then St.Opacity := St.Opacity * V;
  end
  else if AName = 'color' then
  begin
    if CssParseColor(AValue, C) then St.CurrentColor := C;
  end;
end;

procedure ApplySvgStyleDeclarations(const S: string; var St: TSvgStyle);
var
  I, P, Start: Integer;
  Item, Name, Value: string;

  procedure ApplyOne(const AItem: string);
  begin
    P := Pos(':', AItem);
    if P <= 1 then Exit;
    Name := LowerCase(Trim(Copy(AItem, 1, P - 1)));
    Value := Trim(Copy(AItem, P + 1, MaxInt));
    ApplySvgStyleProp(Name, Value, St);
  end;

begin
  Start := 1;
  for I := 1 to Length(S) do
  begin
    if S[I] = ';' then
    begin
      Item := Trim(Copy(S, Start, I - Start));
      if Item <> '' then ApplyOne(Item);
      Start := I + 1;
    end;
  end;
  Item := Trim(Copy(S, Start, MaxInt));
  if Item <> '' then ApplyOne(Item);
end;

procedure ApplySvgPresentationAttrs(const AAttrText: string; var St: TSvgStyle);
const
  PropNames: array[0..10] of string = (
    'fill', 'fill-rule', 'fill-opacity',
    'stroke', 'stroke-opacity', 'stroke-width', 'stroke-linecap',
    'stroke-linejoin', 'stroke-miterlimit', 'opacity', 'color');
var
  I: Integer;
  V: string;
begin
  for I := Low(PropNames) to High(PropNames) do
  begin
    V := SvgGetAttr(AAttrText, PropNames[I]);
    if V <> '' then
      ApplySvgStyleProp(PropNames[I], V, St);
  end;
end;

function SvgAttrDouble(const AAttrText, AName: string; ADefault: Double): Double;
var
  S: string;
  V: Double;
begin
  S := SvgGetAttr(AAttrText, AName);
  if (S <> '') and TryParseSvgLength(S, V) then
    Result := V
  else
    Result := ADefault;
end;

// ============================================================================
//  Primitive geometry builders
// ============================================================================

procedure BuildRectPath(X, Y, W, H, RX, RY: Double; out Path: TSvgPathData);
const
  K = 0.5522847498374375;
var
  Sub: TSvgSubpath;
  Cur: TPointF;

  procedure Mov(const P: TPointF);
  begin
    Sub.Start := P;
    Cur := P;
  end;

  procedure Lin(const P: TPointF);
  var N: Integer;
  begin
    N := Length(Sub.Segs);
    SetLength(Sub.Segs, N + 1);
    Sub.Segs[N].Kind := sskLine;
    Sub.Segs[N].P1 := P;
    Cur := P;
  end;

  procedure Cub(const C1, C2, P: TPointF);
  var N: Integer;
  begin
    N := Length(Sub.Segs);
    SetLength(Sub.Segs, N + 1);
    Sub.Segs[N].Kind := sskCubic;
    Sub.Segs[N].P1 := C1;
    Sub.Segs[N].P2 := C2;
    Sub.Segs[N].P3 := P;
    Cur := P;
  end;

begin
  Path := nil;
  if (W <= 0) or (H <= 0) then Exit;
  if RX < 0 then RX := 0;
  if RY < 0 then RY := 0;
  if RX > W / 2 then RX := W / 2;
  if RY > H / 2 then RY := H / 2;
  Sub.Segs := nil;
  Sub.Closed := True;
  if (RX <= 0) or (RY <= 0) then
  begin
    Mov(SvgPointF(X, Y));
    Lin(SvgPointF(X + W, Y));
    Lin(SvgPointF(X + W, Y + H));
    Lin(SvgPointF(X, Y + H));
  end
  else
  begin
    Mov(SvgPointF(X + RX, Y));
    Lin(SvgPointF(X + W - RX, Y));
    Cub(SvgPointF(X + W - RX + K * RX, Y),
        SvgPointF(X + W, Y + RY - K * RY),
        SvgPointF(X + W, Y + RY));
    Lin(SvgPointF(X + W, Y + H - RY));
    Cub(SvgPointF(X + W, Y + H - RY + K * RY),
        SvgPointF(X + W - RX + K * RX, Y + H),
        SvgPointF(X + W - RX, Y + H));
    Lin(SvgPointF(X + RX, Y + H));
    Cub(SvgPointF(X + RX - K * RX, Y + H),
        SvgPointF(X, Y + H - RY + K * RY),
        SvgPointF(X, Y + H - RY));
    Lin(SvgPointF(X, Y + RY));
    Cub(SvgPointF(X, Y + RY - K * RY),
        SvgPointF(X + RX - K * RX, Y),
        SvgPointF(X + RX, Y));
  end;
  SetLength(Path, 1);
  Path[0] := Sub;
end;

procedure BuildEllipsePath(CX, CY, RX, RY: Double; out Path: TSvgPathData);
const
  K = 0.5522847498374375;
var
  Sub: TSvgSubpath;
  N: Integer;

  procedure Mov(const P: TPointF);
  begin
    Sub.Start := P;
  end;

  procedure Cub(const C1, C2, P: TPointF);
  begin
    N := Length(Sub.Segs);
    SetLength(Sub.Segs, N + 1);
    Sub.Segs[N].Kind := sskCubic;
    Sub.Segs[N].P1 := C1;
    Sub.Segs[N].P2 := C2;
    Sub.Segs[N].P3 := P;
  end;

begin
  Path := nil;
  if (RX <= 0) or (RY <= 0) then Exit;
  Sub.Segs := nil;
  Sub.Closed := True;
  N := 0;
  Mov(SvgPointF(CX + RX, CY));
  Cub(SvgPointF(CX + RX, CY + K * RY), SvgPointF(CX + K * RX, CY + RY),
      SvgPointF(CX, CY + RY));
  Cub(SvgPointF(CX - K * RX, CY + RY), SvgPointF(CX - RX, CY + K * RY),
      SvgPointF(CX - RX, CY));
  Cub(SvgPointF(CX - RX, CY - K * RY), SvgPointF(CX - K * RX, CY - RY),
      SvgPointF(CX, CY - RY));
  Cub(SvgPointF(CX + K * RX, CY - RY), SvgPointF(CX + RX, CY - K * RY),
      SvgPointF(CX + RX, CY));
  SetLength(Path, 1);
  Path[0] := Sub;
end;

procedure BuildLinePath(X1, Y1, X2, Y2: Double; out Path: TSvgPathData);
var
  Sub: TSvgSubpath;
begin
  Path := nil;
  if (Abs(X2 - X1) < 1E-9) and (Abs(Y2 - Y1) < 1E-9) then Exit;
  Sub.Segs := nil;
  Sub.Closed := False;
  Sub.Start := SvgPointF(X1, Y1);
  SetLength(Sub.Segs, 1);
  Sub.Segs[0].Kind := sskLine;
  Sub.Segs[0].P1 := SvgPointF(X2, Y2);
  SetLength(Path, 1);
  Path[0] := Sub;
end;

procedure ParsePointsAttr(const S: string; AClosed: Boolean; out Path: TSvgPathData);
var
  Sc: TSvgScanner;
  X, Y: Double;
  Sub: TSvgSubpath;
  First: Boolean;
  N: Integer;
begin
  Path := nil;
  Sub.Segs := nil;
  Sub.Closed := AClosed;
  First := True;
  Sc := TSvgScanner.Create(S);
  try
    while Sc.NextNumber(X) do
    begin
      if not Sc.NextNumber(Y) then Break;
      if First then
      begin
        Sub.Start := SvgPointF(X, Y);
        First := False;
      end
      else
      begin
        N := Length(Sub.Segs);
        SetLength(Sub.Segs, N + 1);
        Sub.Segs[N].Kind := sskLine;
        Sub.Segs[N].P1 := SvgPointF(X, Y);
      end;
    end;
  finally
    Sc.Free;
  end;
  if (not First) and (Length(Sub.Segs) > 0) then
  begin
    SetLength(Path, 1);
    Path[0] := Sub;
  end;
end;

// ---------------------------------------------------------------------------
//  Path data parser (including arcs -> cubic curves)
// ---------------------------------------------------------------------------

function SvgAngleBetween(UX, UY, VX, VY: Double): Double;
begin
  Result := ArcTan2(UX * VY - UY * VX, UX * VX + UY * VY);
end;

function SvgEllipsePoint(CX, CY, CosPhi, SinPhi, ARX, ARY, T: Double): TPointF;
var
  X, Y: Double;
begin
  X := ARX * Cos(T);
  Y := ARY * Sin(T);
  Result.X := CosPhi * X - SinPhi * Y + CX;
  Result.Y := SinPhi * X + CosPhi * Y + CY;
end;

function SvgEllipseDeriv(CosPhi, SinPhi, ARX, ARY, T: Double): TPointF;
var
  X, Y: Double;
begin
  X := -ARX * Sin(T);
  Y := ARY * Cos(T);
  Result.X := CosPhi * X - SinPhi * Y;
  Result.Y := SinPhi * X + CosPhi * Y;
end;

procedure ParseSvgPathData(const D: string; out Path: TSvgPathData);
var
  Sc: TSvgScanner;
  Cmd: Char;
  Cur, SubStart, LastCtrl: TPointF;
  HaveCtrl, CtrlCubic, HasCur: Boolean;
  Sub: TSvgSubpath;
  SubCount: Integer;
  X, Y, X1, Y1, X2, Y2, RXv, RYv, Rot: Double;
  Laf, Sf: Boolean;

  procedure FlushSub;
  begin
    if Length(Sub.Segs) > 0 then
    begin
      SetLength(Path, SubCount + 1);
      Path[SubCount] := Sub;
      Inc(SubCount);
    end;
    Sub.Segs := nil;
    Sub.Closed := False;
  end;

  procedure AddSegRec(Kind: TSvgSegKind; const P1, P2, P3, Ctrl: TPointF;
    CubicCtrl: Boolean);
  var N: Integer;
  begin
    N := Length(Sub.Segs);
    SetLength(Sub.Segs, N + 1);
    Sub.Segs[N].Kind := Kind;
    Sub.Segs[N].P1 := P1;
    Sub.Segs[N].P2 := P2;
    Sub.Segs[N].P3 := P3;
    case Kind of
      sskLine: Cur := P1;
      sskQuad: Cur := P2;
      sskCubic: Cur := P3;
    end;
    HaveCtrl := Kind <> sskLine;
    CtrlCubic := CubicCtrl;
    LastCtrl := Ctrl;
  end;

  procedure AddLine(const P: TPointF);
  begin
    AddSegRec(sskLine, P, SvgPointF(0, 0), SvgPointF(0, 0),
      SvgPointF(0, 0), False);
  end;

  procedure AddQuad(const C, P: TPointF);
  begin
    AddSegRec(sskQuad, C, P, SvgPointF(0, 0), C, False);
  end;

  procedure AddCubic(const C1, C2, P: TPointF);
  begin
    AddSegRec(sskCubic, C1, C2, P, C2, True);
  end;

  procedure AppendArc(const FromP: TPointF; ARX, ARY, ARot: Double;
    ALargeArc, ASweep: Boolean; const ToP: TPointF);
  var
    Phi, CosPhi, SinPhi, DX2, DY2, X1p, Y1p, Lam, Den2, Num2, Coef,
    Cxp, Cyp, CCx, CCy, Theta1, Delta, T1, T2, Alpha: Double;
    Segs, K: Integer;
    PP1, PP2, DD1, DD2, CC1, CC2: TPointF;
  begin
    if (Abs(ARX) < 1E-9) or (Abs(ARY) < 1E-9) then
    begin
      AddLine(ToP);
      Exit;
    end;
    if (Abs(FromP.X - ToP.X) < 1E-9) and (Abs(FromP.Y - ToP.Y) < 1E-9) then
      Exit;
    ARX := Abs(ARX);
    ARY := Abs(ARY);
    Phi := ARot * Pi / 180;
    CosPhi := Cos(Phi);
    SinPhi := Sin(Phi);
    DX2 := (FromP.X - ToP.X) / 2;
    DY2 := (FromP.Y - ToP.Y) / 2;
    X1p := CosPhi * DX2 + SinPhi * DY2;
    Y1p := -SinPhi * DX2 + CosPhi * DY2;
    Lam := Sqr(X1p) / Sqr(ARX) + Sqr(Y1p) / Sqr(ARY);
    if Lam > 1 then
    begin
      ARX := ARX * Sqrt(Lam);
      ARY := ARY * Sqrt(Lam);
    end;
    Den2 := Sqr(ARX) * Sqr(Y1p) + Sqr(ARY) * Sqr(X1p);
    Num2 := Sqr(ARX) * Sqr(ARY) - Den2;
    if (Den2 < 1E-12) or (Num2 < 0) then
      Coef := 0
    else
      Coef := Sqrt(Num2 / Den2);
    if ALargeArc = ASweep then
      Coef := -Coef;
    Cxp := Coef * ARX * Y1p / ARY;
    Cyp := -Coef * ARY * X1p / ARX;
    CCx := CosPhi * Cxp - SinPhi * Cyp + (FromP.X + ToP.X) / 2;
    CCy := SinPhi * Cxp + CosPhi * Cyp + (FromP.Y + ToP.Y) / 2;
    Theta1 := SvgAngleBetween(1, 0, (X1p - Cxp) / ARX, (Y1p - Cyp) / ARY);
    Delta := SvgAngleBetween((X1p - Cxp) / ARX, (Y1p - Cyp) / ARY,
                             (-X1p - Cxp) / ARX, (-Y1p - Cyp) / ARY);
    if (not ASweep) and (Delta > 0) then Delta := Delta - 2 * Pi;
    if ASweep and (Delta < 0) then Delta := Delta + 2 * Pi;
    Segs := Ceil(Abs(Delta) / (Pi / 2));
    if Segs < 1 then Segs := 1;
    for K := 0 to Segs - 1 do
    begin
      T1 := Theta1 + Delta * K / Segs;
      T2 := Theta1 + Delta * (K + 1) / Segs;
      Alpha := 4.0 / 3.0 * Tan((T2 - T1) / 4);
      PP1 := SvgEllipsePoint(CCx, CCy, CosPhi, SinPhi, ARX, ARY, T1);
      DD1 := SvgEllipseDeriv(CosPhi, SinPhi, ARX, ARY, T1);
      PP2 := SvgEllipsePoint(CCx, CCy, CosPhi, SinPhi, ARX, ARY, T2);
      DD2 := SvgEllipseDeriv(CosPhi, SinPhi, ARX, ARY, T2);
      CC1 := SvgPointF(PP1.X + Alpha * DD1.X, PP1.Y + Alpha * DD1.Y);
      CC2 := SvgPointF(PP2.X - Alpha * DD2.X, PP2.Y - Alpha * DD2.Y);
      AddCubic(CC1, CC2, PP2);
    end;
  end;

begin
  Path := nil;
  Sub.Segs := nil;
  Sub.Closed := False;
  Sub.Start := SvgPointF(0, 0);
  SubCount := 0;
  HasCur := False;
  HaveCtrl := False;
  CtrlCubic := False;
  Cmd := #0;
  Cur := SvgPointF(0, 0);
  SubStart := Cur;
  LastCtrl := Cur;
  Sc := TSvgScanner.Create(D);
  try
    while True do
    begin
      Sc.SkipSeps;
      if Sc.Eof then Break;
      if Sc.IsCommandChar then
      begin
        Cmd := Sc.PeekChar;
        Sc.Advance;
      end
      else if Cmd = #0 then
        Break
      else if (Cmd = 'M') or (Cmd = 'm') then
      begin
        if Cmd = 'M' then Cmd := 'L' else Cmd := 'l';
      end;
      case Cmd of
        'M', 'm':
        begin
          if not Sc.NextNumber(X) then Break;
          if not Sc.NextNumber(Y) then Break;
          FlushSub;
          if (Cmd = 'm') and HasCur then
          begin
            X := Cur.X + X;
            Y := Cur.Y + Y;
          end;
          Cur := SvgPointF(X, Y);
          SubStart := Cur;
          Sub.Start := Cur;
          HasCur := True;
          HaveCtrl := False;
          while Sc.NextNumber(X) do
          begin
            if not Sc.NextNumber(Y) then Break;
            if Cmd = 'm' then
            begin
              X := Cur.X + X;
              Y := Cur.Y + Y;
            end;
            AddLine(SvgPointF(X, Y));
          end;
        end;
        'L', 'l':
        begin
          while Sc.NextNumber(X) do
          begin
            if not Sc.NextNumber(Y) then Break;
            if Cmd = 'l' then
            begin
              X := Cur.X + X;
              Y := Cur.Y + Y;
            end;
            AddLine(SvgPointF(X, Y));
          end;
        end;
        'H', 'h':
        begin
          while Sc.NextNumber(X) do
          begin
            if Cmd = 'h' then X := Cur.X + X;
            AddLine(SvgPointF(X, Cur.Y));
          end;
        end;
        'V', 'v':
        begin
          while Sc.NextNumber(Y) do
          begin
            if Cmd = 'v' then Y := Cur.Y + Y;
            AddLine(SvgPointF(Cur.X, Y));
          end;
        end;
        'C', 'c':
        begin
          while Sc.NextNumber(X1) do
          begin
            if not (Sc.NextNumber(Y1) and Sc.NextNumber(X2) and
                    Sc.NextNumber(Y2) and Sc.NextNumber(X) and
                    Sc.NextNumber(Y)) then Break;
            if Cmd = 'c' then
            begin
              X1 := Cur.X + X1; Y1 := Cur.Y + Y1;
              X2 := Cur.X + X2; Y2 := Cur.Y + Y2;
              X := Cur.X + X;   Y := Cur.Y + Y;
            end;
            AddCubic(SvgPointF(X1, Y1), SvgPointF(X2, Y2), SvgPointF(X, Y));
          end;
        end;
        'S', 's':
        begin
          while Sc.NextNumber(X2) do
          begin
            if not (Sc.NextNumber(Y2) and Sc.NextNumber(X) and
                    Sc.NextNumber(Y)) then Break;
            if Cmd = 's' then
            begin
              X2 := Cur.X + X2; Y2 := Cur.Y + Y2;
              X := Cur.X + X;   Y := Cur.Y + Y;
            end;
            if HaveCtrl and CtrlCubic then
            begin
              X1 := 2 * Cur.X - LastCtrl.X;
              Y1 := 2 * Cur.Y - LastCtrl.Y;
            end
            else
            begin
              X1 := Cur.X;
              Y1 := Cur.Y;
            end;
            AddCubic(SvgPointF(X1, Y1), SvgPointF(X2, Y2), SvgPointF(X, Y));
          end;
        end;
        'Q', 'q':
        begin
          while Sc.NextNumber(X1) do
          begin
            if not (Sc.NextNumber(Y1) and Sc.NextNumber(X) and
                    Sc.NextNumber(Y)) then Break;
            if Cmd = 'q' then
            begin
              X1 := Cur.X + X1; Y1 := Cur.Y + Y1;
              X := Cur.X + X;   Y := Cur.Y + Y;
            end;
            AddQuad(SvgPointF(X1, Y1), SvgPointF(X, Y));
          end;
        end;
        'T', 't':
        begin
          while Sc.NextNumber(X) do
          begin
            if not Sc.NextNumber(Y) then Break;
            if Cmd = 't' then
            begin
              X := Cur.X + X;
              Y := Cur.Y + Y;
            end;
            if HaveCtrl and (not CtrlCubic) then
            begin
              X1 := 2 * Cur.X - LastCtrl.X;
              Y1 := 2 * Cur.Y - LastCtrl.Y;
            end
            else
            begin
              X1 := Cur.X;
              Y1 := Cur.Y;
            end;
            AddQuad(SvgPointF(X1, Y1), SvgPointF(X, Y));
          end;
        end;
        'A', 'a':
        begin
          while Sc.NextNumber(RXv) do
          begin
            if not (Sc.NextNumber(RYv) and Sc.NextNumber(Rot) and
                    Sc.NextFlag(Laf) and Sc.NextFlag(Sf) and
                    Sc.NextNumber(X) and Sc.NextNumber(Y)) then Break;
            if Cmd = 'a' then
            begin
              X := Cur.X + X;
              Y := Cur.Y + Y;
            end;
            AppendArc(Cur, RXv, RYv, Rot, Laf, Sf, SvgPointF(X, Y));
          end;
        end;
        'Z', 'z':
        begin
          Sub.Closed := True;
          FlushSub;
          Cur := SubStart;
          HaveCtrl := False;
          Cmd := #0;
        end;
      else
        Break;
      end;
    end;
    FlushSub;
  finally
    Sc.Free;
  end;
end;

function ParseSvgTransformList(const S: string): TSvgMatrix;
var
  Sc: TSvgScanner;
  Name: string;
  A, B, C, D, E, F: Double;
  M: TSvgMatrix;
begin
  Result := SvgMatrixIdentity;
  Sc := TSvgScanner.Create(S);
  try
    while Sc.NextIdent(Name) do
    begin
      Sc.SkipSeps;
      if Sc.PeekChar <> '(' then Break;
      Sc.Advance;
      M := SvgMatrixIdentity;
      Name := LowerCase(Name);
      if Name = 'translate' then
      begin
        if Sc.NextNumber(A) then
        begin
          B := 0;
          Sc.NextNumber(B);
          M := SvgMatrixTranslate(A, B);
        end;
      end
      else if Name = 'scale' then
      begin
        if Sc.NextNumber(A) then
        begin
          B := A;
          Sc.NextNumber(B);
          M := SvgMatrixScale(A, B);
        end;
      end
      else if Name = 'rotate' then
      begin
        if Sc.NextNumber(A) then
        begin
          if Sc.NextNumber(B) and Sc.NextNumber(C) then
            M := SvgMatrixMultiply(
                   SvgMatrixMultiply(SvgMatrixTranslate(B, C),
                                     SvgMatrixRotate(A)),
                   SvgMatrixTranslate(-B, -C))
          else
            M := SvgMatrixRotate(A);
        end;
      end
      else if Name = 'skewx' then
      begin
        if Sc.NextNumber(A) then M := SvgMatrixSkewX(A);
      end
      else if Name = 'skewy' then
      begin
        if Sc.NextNumber(A) then M := SvgMatrixSkewY(A);
      end
      else if Name = 'matrix' then
      begin
        if Sc.NextNumber(A) and Sc.NextNumber(B) and Sc.NextNumber(C) and
           Sc.NextNumber(D) and Sc.NextNumber(E) and Sc.NextNumber(F) then
          M := SvgMatrixMake(A, B, C, D, E, F);
      end;
      while (not Sc.Eof) and (Sc.PeekChar <> ')') do Sc.Advance;
      if not Sc.Eof then Sc.Advance;
      Result := SvgMatrixMultiply(Result, M);
    end;
  finally
    Sc.Free;
  end;
end;

procedure TransformPath(var Path: TSvgPathData; const M: TSvgMatrix);
var
  I, J: Integer;
begin
  for I := 0 to High(Path) do
  begin
    Path[I].Start := SvgMatrixTransformPoint(M, Path[I].Start);
    for J := 0 to High(Path[I].Segs) do
    begin
      Path[I].Segs[J].P1 := SvgMatrixTransformPoint(M, Path[I].Segs[J].P1);
      Path[I].Segs[J].P2 := SvgMatrixTransformPoint(M, Path[I].Segs[J].P2);
      Path[I].Segs[J].P3 := SvgMatrixTransformPoint(M, Path[I].Segs[J].P3);
    end;
  end;
end;

// ============================================================================
//  Flattening (curve approximation with line segments in device coordinates)
// ============================================================================

procedure AppendPointF(var AArr: TAAFloatPoints; var ACnt: Integer;
  const AP: TPointF);
begin
  if (ACnt > 0) and
     (Abs(AArr[ACnt - 1].X - AP.X) < 1E-6) and
     (Abs(AArr[ACnt - 1].Y - AP.Y) < 1E-6) then
    Exit;
  if ACnt >= Length(AArr) then
    SetLength(AArr, Length(AArr) + 64);
  AArr[ACnt] := AP;
  Inc(ACnt);
end;

function SvgDistToLine(const P, A, B: TPointF): Double;
var
  DX, DY, L: Double;
begin
  DX := B.X - A.X;
  DY := B.Y - A.Y;
  L := Sqrt(DX * DX + DY * DY);
  if L < 1E-9 then
    Result := Sqrt(Sqr(P.X - A.X) + Sqr(P.Y - A.Y))
  else
    Result := Abs(DX * (P.Y - A.Y) - DY * (P.X - A.X)) / L;
end;

function SvgMid(const A, B: TPointF): TPointF; inline;
begin
  Result.X := (A.X + B.X) / 2;
  Result.Y := (A.Y + B.Y) / 2;
end;

{ TSvgImage }

constructor TSvgImage.Create(const ASvg: string);
begin
  inherited Create;
  FSvg := ASvg;
  FParsed := False;
end;

procedure TSvgImage.ParseSvgRootAttrs(const AAttrs: string);
var
  S: string;
  V: Double;
begin
  S := SvgGetAttr(AAttrs, 'width');
  if (S <> '') and (Pos('%', S) = 0) and TryParseSvgLength(S, V) and (V > 0) then
    FIntrinsicW := V;
  S := SvgGetAttr(AAttrs, 'height');
  if (S <> '') and (Pos('%', S) = 0) and TryParseSvgLength(S, V) and (V > 0) then
    FIntrinsicH := V;
  ParseViewBoxAttr(SvgGetAttr(AAttrs, 'viewBox'));
  ParsePreserveAspectRatio(SvgGetAttr(AAttrs, 'preserveAspectRatio'));
end;

procedure TSvgImage.ParseViewBoxAttr(const S: string);
var
  Sc: TSvgScanner;
  A, B, C, DD: Double;
begin
  FHasViewBox := False;
  if Trim(S) = '' then Exit;
  Sc := TSvgScanner.Create(S);
  try
    if Sc.NextNumber(A) and Sc.NextNumber(B) and
       Sc.NextNumber(C) and Sc.NextNumber(DD) then
    begin
      if (C > 0) and (DD > 0) then
      begin
        FVBX := A;
        FVBY := B;
        FVBW := C;
        FVBH := DD;
        FHasViewBox := True;
      end;
    end;
  finally
    Sc.Free;
  end;
end;

procedure TSvgImage.ParsePreserveAspectRatio(const S: string);
var
  Tokens: TStringList;
  W1, XPart, YPart: string;
begin
  FParNone := False;
  FParSlice := False;
  FParAlignX := 1;
  FParAlignY := 1;
  if Trim(S) = '' then Exit;
  Tokens := TStringList.Create;
  try
    SvgSplitWhitespace(Trim(S), Tokens);
    if Tokens.Count = 0 then Exit;
    W1 := LowerCase(Tokens[0]);
    if W1 = 'none' then
    begin
      FParNone := True;
      Exit;
    end;
    if Length(W1) >= 8 then
    begin
      XPart := Copy(W1, 2, 3);
      YPart := Copy(W1, 6, 3);
      if XPart = 'min' then FParAlignX := 0
      else if XPart = 'max' then FParAlignX := 2
      else FParAlignX := 1;
      if YPart = 'min' then FParAlignY := 0
      else if YPart = 'max' then FParAlignY := 2
      else FParAlignY := 1;
    end;
    if (Tokens.Count > 1) and SameText(Tokens[1], 'slice') then
      FParSlice := True;
  finally
    Tokens.Free;
  end;
end;

{ Parses style="stop-color:...;stop-opacity:..." that is commonly used
  on <stop> elements in Illustrator/Inkscape output. }
procedure ApplyStopStyleProps(const AStyle: string;
  var AColor: TColor; var AOpacity: Double);
var
  I, P, Start: Integer;
  Item, Name, Value: string;
  C: TColor;
  V: Double;

  procedure ApplyOne(const AItem: string);
  begin
    P := Pos(':', AItem);
    if P <= 1 then Exit;
    Name := LowerCase(Trim(Copy(AItem, 1, P - 1)));
    Value := Trim(Copy(AItem, P + 1, MaxInt));
    if Name = 'stop-color' then
    begin
      if CssParseColor(Value, C) then AColor := C;
    end
    else if Name = 'stop-opacity' then
    begin
      if ParseSvgOpacity(Value, V) then AOpacity := V;
    end;
  end;

begin
  Start := 1;
  for I := 1 to Length(AStyle) do
  begin
    if AStyle[I] = ';' then
    begin
      Item := Trim(Copy(AStyle, Start, I - Start));
      if Item <> '' then ApplyOne(Item);
      Start := I + 1;
    end;
  end;
  Item := Trim(Copy(AStyle, Start, MaxInt));
  if Item <> '' then ApplyOne(Item);
end;

procedure TSvgImage.ParseGradient(const ATagName, AAttrs: string; var APos: Integer);
var
  Def: TSvgGradientDef;
  TagName, Attrs, Sv: string;
  Closing, SelfClosing: Boolean;
  M: TSvgMatrix;
  V: Double;
  StopOffset, StopOpacity: Double;
  StopColor: TColor;
  N: Integer;
  Stop: TSvgGradientStop;
begin
  Def.Id := SvgGetAttr(AAttrs, 'id');
  if Def.Id = '' then
  begin
    SkipUntilClose(FSvg, APos, ATagName);
    Exit;
  end;

  if ATagName = 'lineargradient' then
    Def.Kind := svgkLinear
  else
    Def.Kind := svgkRadial;

  // Default values
  Def.X1 := 0; Def.Y1 := 0; Def.X2 := 1; Def.Y2 := 0;
  Def.CX := 0.5; Def.CY := 0.5; Def.R := 0.5;
  Def.FX := 0.5; Def.FY := 0.5;
  Def.Stops := nil;
  Def.Transform := SvgGradientMatrixIdentity;
  Def.SpreadMethod := svgsmPad;
  Def.GradientUnits := svgguObjectBoundingBox;

  Sv := LowerCase(SvgGetAttr(AAttrs, 'gradientunits'));
  if Sv = 'userspaceonuse' then
    Def.GradientUnits := svgguUserSpaceOnUse;

  Sv := LowerCase(SvgGetAttr(AAttrs, 'spreadmethod'));
  if Sv = 'reflect' then Def.SpreadMethod := svgsmReflect
  else if Sv = 'repeat' then Def.SpreadMethod := svgsmRepeat;

  Sv := SvgGetAttr(AAttrs, 'gradienttransform');
  if Sv <> '' then
  begin
    M := ParseSvgTransformList(Sv);
    Def.Transform.A := M.A;
    Def.Transform.B := M.B;
    Def.Transform.C := M.C;
    Def.Transform.D := M.D;
    Def.Transform.E := M.E;
    Def.Transform.F := M.F;
  end;

  if Def.Kind = svgkLinear then
  begin
    Def.X1 := SvgAttrDouble(AAttrs, 'x1', 0);
    Def.Y1 := SvgAttrDouble(AAttrs, 'y1', 0);
    Def.X2 := SvgAttrDouble(AAttrs, 'x2', 1);
    Def.Y2 := SvgAttrDouble(AAttrs, 'y2', 0);
  end
  else
  begin
    Def.CX := SvgAttrDouble(AAttrs, 'cx', 0.5);
    Def.CY := SvgAttrDouble(AAttrs, 'cy', 0.5);
    Def.R := SvgAttrDouble(AAttrs, 'r', 0.5);
    Def.FX := SvgAttrDouble(AAttrs, 'fx', Def.CX);
    Def.FY := SvgAttrDouble(AAttrs, 'fy', Def.CY);
  end;

  // Parse child <stop> elements
  while APos <= Length(FSvg) do
  begin
    if not NextSvgTag(FSvg, APos, TagName, Closing, SelfClosing, Attrs) then
      Break;
    if Closing and (TagName = ATagName) then
      Break;
    if TagName = 'stop' then
    begin
      StopOffset := 0;
      StopOpacity := 1;
      StopColor := clBlack;

      Sv := SvgGetAttr(Attrs, 'offset');
      if Sv <> '' then
      begin
        if EndsText('%', Sv) then
        begin
          if SvgStrToDouble(Copy(Sv, 1, Length(Sv) - 1), V) then
            StopOffset := SvgClamp01(V / 100);
        end
        else if SvgStrToDouble(Sv, V) then
          StopOffset := SvgClamp01(V);
      end;

      { style="stop-color:...;stop-opacity:..." takes priority because
        Illustrator/Inkscape always emit it instead of the presentation
        attributes; then the presentation attributes are honoured
        (a plain attribute wins over the style, per CSS rules). }
      Sv := SvgGetAttr(Attrs, 'style');
      if Sv <> '' then
        ApplyStopStyleProps(Sv, StopColor, StopOpacity);

      Sv := SvgGetAttr(Attrs, 'stop-color');
      if Sv <> '' then
        CssParseColor(Sv, StopColor);

      Sv := SvgGetAttr(Attrs, 'stop-opacity');
      if Sv <> '' then
        ParseSvgOpacity(Sv, StopOpacity);

      Stop.Offset := StopOffset;
      Stop.Color := StopColor;
      Stop.Opacity := StopOpacity;
      N := Length(Def.Stops);
      SetLength(Def.Stops, N + 1);
      Def.Stops[N] := Stop;
    end;
  end;

  // Sort stops by offset
  // (simplified - assumes they are already in order)

  N := Length(FGradients);
  SetLength(FGradients, N + 1);
  FGradients[N] := Def;
end;

procedure TSvgImage.ParseShape(const ATagName, AAttrs: string;
  const ACtx: TSvgCtx);
var
  St: TSvgStyle;
  Path: TSvgPathData;
  M: TSvgMatrix;
  S: string;
  X, Y, W, H, RX, RY, CXc, CYc, RXe, RYe, X1, Y1, X2, Y2: Double;
  HasRX, HasRY: Boolean;
  N: Integer;
begin
  St := ACtx.St;
  ApplySvgPresentationAttrs(AAttrs, St);
  S := SvgGetAttr(AAttrs, 'style');
  if S <> '' then ApplySvgStyleDeclarations(S, St);
  if SameText(SvgGetAttr(AAttrs, 'display'), 'none') then Exit;
  if SameText(SvgGetAttr(AAttrs, 'visibility'), 'hidden') then Exit;
  M := ACtx.M;
  S := SvgGetAttr(AAttrs, 'transform');
  if S <> '' then M := SvgMatrixMultiply(M, ParseSvgTransformList(S));
  Path := nil;
  if ATagName = 'path' then
    ParseSvgPathData(SvgGetAttr(AAttrs, 'd'), Path)
  else if ATagName = 'rect' then
  begin
    X := SvgAttrDouble(AAttrs, 'x', 0);
    Y := SvgAttrDouble(AAttrs, 'y', 0);
    W := SvgAttrDouble(AAttrs, 'width', 0);
    H := SvgAttrDouble(AAttrs, 'height', 0);
    HasRX := SvgGetAttr(AAttrs, 'rx') <> '';
    HasRY := SvgGetAttr(AAttrs, 'ry') <> '';
    RX := SvgAttrDouble(AAttrs, 'rx', 0);
    RY := SvgAttrDouble(AAttrs, 'ry', 0);
    if HasRX and (not HasRY) then RY := RX;
    if HasRY and (not HasRX) then RX := RY;
    BuildRectPath(X, Y, W, H, RX, RY, Path);
  end
  else if ATagName = 'circle' then
  begin
    CXc := SvgAttrDouble(AAttrs, 'cx', 0);
    CYc := SvgAttrDouble(AAttrs, 'cy', 0);
    RX := SvgAttrDouble(AAttrs, 'r', 0);
    BuildEllipsePath(CXc, CYc, RX, RX, Path);
  end
  else if ATagName = 'ellipse' then
  begin
    CXc := SvgAttrDouble(AAttrs, 'cx', 0);
    CYc := SvgAttrDouble(AAttrs, 'cy', 0);
    RXe := SvgAttrDouble(AAttrs, 'rx', 0);
    RYe := SvgAttrDouble(AAttrs, 'ry', 0);
    BuildEllipsePath(CXc, CYc, RXe, RYe, Path);
  end
  else if ATagName = 'line' then
  begin
    X1 := SvgAttrDouble(AAttrs, 'x1', 0);
    Y1 := SvgAttrDouble(AAttrs, 'y1', 0);
    X2 := SvgAttrDouble(AAttrs, 'x2', 0);
    Y2 := SvgAttrDouble(AAttrs, 'y2', 0);
    BuildLinePath(X1, Y1, X2, Y2, Path);
  end
  else if ATagName = 'polyline' then
    ParsePointsAttr(SvgGetAttr(AAttrs, 'points'), False, Path)
  else if ATagName = 'polygon' then
    ParsePointsAttr(SvgGetAttr(AAttrs, 'points'), True, Path);
  if Length(Path) = 0 then Exit;
  TransformPath(Path, M);
  N := Length(FShapes);
  SetLength(FShapes, N + 1);
  FShapes[N].IsText := False;
  FShapes[N].Path := Path;
  FShapes[N].TextRuns := nil;
  FShapes[N].TextAnchor := svgtaStart;
  FShapes[N].Style := St;
end;

procedure TSvgImage.ParseTextElement(const S: string; var APos: Integer;
  const ATextAttrs: string; const ACtx: TSvgCtx);
type
  TSvgTextState = record
    HasX, HasY: Boolean;
    X, Y, DX, DY: Double;
    Family: string; HasFamily: Boolean;
    FontSize: Double; HasFontSize: Boolean;
    Bold: Boolean; HasBold: Boolean;
    Italic: Boolean; HasItalic: Boolean;
    Style: TSvgStyle;
  end;
var
  Stack: array of TSvgTextState;
  StackCount: Integer;
  Runs: array of TSvgTextRun;
  RunCount: Integer;
  Anchor: TSvgTextAnchor;
  M: TSvgMatrix;
  Lt, I, N: Integer;
  TagName, Attrs, Chunk, Sv: string;
  Closing, SelfClosing: Boolean;
  PT: TPointF;
  VX, VY: Double;

  procedure ScanFontDeclarations(const AStyle: string;
    var AState: TSvgTextState);
  var
    J, P, Start: Integer;
    Item, Name, Value: string;
    V: Double;
  begin
    Start := 1;
    for J := 1 to Length(AStyle) + 1 do
    begin
      if (J > Length(AStyle)) or (AStyle[J] = ';') then
      begin
        Item := Trim(Copy(AStyle, Start, J - Start));
        P := Pos(':', Item);
        if P > 1 then
        begin
          Name := LowerCase(Trim(Copy(Item, 1, P - 1)));
          Value := Trim(Copy(Item, P + 1, MaxInt));
          if Name = 'font-family' then
          begin
            AState.Family := Value;
            AState.HasFamily := True;
          end
          else if Name = 'font-size' then
          begin
            if TryParseSvgLength(Value, V) and (V > 0) then
            begin
              AState.FontSize := V;
              AState.HasFontSize := True;
            end;
          end
          else if Name = 'font-weight' then
          begin
            AState.HasBold := True;
            Value := LowerCase(Value);
            if (Value = 'bold') or (Value = 'bolder') then
              AState.Bold := True
            else if SvgStrToDouble(Value, V) then
              AState.Bold := V >= 600
            else
              AState.Bold := False;
          end
          else if Name = 'font-style' then
          begin
            AState.HasItalic := True;
            Value := LowerCase(Value);
            AState.Italic := (Value = 'italic') or (Value = 'oblique');
          end;
        end;
        Start := J + 1;
      end;
    end;
  end;

  procedure ApplyAttrs(const AAttrText: string; var ASt: TSvgStyle;
    var AState: TSvgTextState);
  var
    V: Double;
  begin
    ApplySvgPresentationAttrs(AAttrText, ASt);
    Sv := SvgGetAttr(AAttrText, 'style');
    if Sv <> '' then
    begin
      ApplySvgStyleDeclarations(Sv, ASt);
      ScanFontDeclarations(Sv, AState);
    end;
    Sv := SvgGetAttr(AAttrText, 'x');
    if (Sv <> '') and TryParseSvgLength(Sv, V) then
    begin
      AState.HasX := True;
      AState.X := V;
    end;
    Sv := SvgGetAttr(AAttrText, 'y');
    if (Sv <> '') and TryParseSvgLength(Sv, V) then
    begin
      AState.HasY := True;
      AState.Y := V;
    end;
    Sv := SvgGetAttr(AAttrText, 'dx');
    if (Sv <> '') and TryParseSvgLength(Sv, V) then
      AState.DX := AState.DX + V;
    Sv := SvgGetAttr(AAttrText, 'dy');
    if (Sv <> '') and TryParseSvgLength(Sv, V) then
      AState.DY := AState.DY + V;
    Sv := SvgGetAttr(AAttrText, 'font-family');
    if Sv <> '' then
    begin
      AState.Family := Sv;
      AState.HasFamily := True;
    end;
    Sv := SvgGetAttr(AAttrText, 'font-size');
    if (Sv <> '') and TryParseSvgLength(Sv, V) and (V > 0) then
    begin
      AState.FontSize := V;
      AState.HasFontSize := True;
    end;
    Sv := LowerCase(SvgGetAttr(AAttrText, 'font-weight'));
    if Sv <> '' then
    begin
      AState.HasBold := True;
      if (Sv = 'bold') or (Sv = 'bolder') then
        AState.Bold := True
      else if (Sv = 'normal') or (Sv = 'lighter') then
        AState.Bold := False
      else if SvgStrToDouble(Sv, V) then
        AState.Bold := V >= 600
      else
        AState.Bold := False;
    end;
    Sv := LowerCase(SvgGetAttr(AAttrText, 'font-style'));
    if Sv <> '' then
    begin
      AState.HasItalic := True;
      AState.Italic := (Sv = 'italic') or (Sv = 'oblique');
    end;
  end;

  procedure AddRun(const AState: TSvgTextState; const AText: string);
  begin
    SetLength(Runs, RunCount + 1);
    Runs[RunCount].Text := AText;
    Runs[RunCount].HasX := AState.HasX;
    Runs[RunCount].X := AState.X;
    Runs[RunCount].HasY := AState.HasY;
    Runs[RunCount].Y := AState.Y;
    Runs[RunCount].DX := AState.DX;
    Runs[RunCount].DY := AState.DY;
    Runs[RunCount].Family := AState.Family;
    Runs[RunCount].FontSize := 0;
    if AState.HasFontSize then
      Runs[RunCount].FontSize := AState.FontSize;
    Runs[RunCount].Bold := AState.HasBold and AState.Bold;
    Runs[RunCount].Italic := AState.HasItalic and AState.Italic;
    Runs[RunCount].Style := AState.Style;
    Inc(RunCount);
    with Stack[StackCount - 1] do
    begin
      HasX := False;
      HasY := False;
      DX := 0;
      DY := 0;
    end;
  end;

begin
  if SameText(SvgGetAttr(ATextAttrs, 'display'), 'none') then
  begin
    SkipUntilClose(S, APos, 'text');
    Exit;
  end;

  Anchor := svgtaStart;
  Sv := LowerCase(SvgGetAttr(ATextAttrs, 'text-anchor'));
  if Sv = 'middle' then Anchor := svgtaMiddle
  else if Sv = 'end' then Anchor := svgtaEnd;

  M := ACtx.M;
  Sv := SvgGetAttr(ATextAttrs, 'transform');
  if Sv <> '' then
    M := SvgMatrixMultiply(M, ParseSvgTransformList(Sv));

  SetLength(Stack, 1);
  StackCount := 1;
  with Stack[0] do
  begin
    HasX := False; HasY := False;
    X := 0; Y := 0; DX := 0; DY := 0;
    Family := ''; HasFamily := False;
    FontSize := 16; HasFontSize := False;
    Bold := False; HasBold := False;
    Italic := False; HasItalic := False;
    Style := ACtx.St;
  end;
  ApplyAttrs(ATextAttrs, Stack[0].Style, Stack[0]);

  Runs := nil;
  RunCount := 0;

  while APos <= Length(S) do
  begin
    Lt := PosEx('<', S, APos);
    if Lt = 0 then
    begin
      Chunk := Copy(S, APos, MaxInt);
      APos := Length(S) + 1;
    end
    else
    begin
      Chunk := Copy(S, APos, Lt - APos);
      APos := Lt;
    end;
    Chunk := SvgNormalizeTextChunk(Chunk);
    if Chunk <> '' then
      AddRun(Stack[StackCount - 1], Chunk);
    if Lt = 0 then Break;
    if not NextSvgTag(S, APos, TagName, Closing, SelfClosing, Attrs) then
      Break;
    if Closing and (TagName = 'text') then
      Break;
    if TagName = 'tspan' then
    begin
      if Closing then
      begin
        if StackCount > 1 then Dec(StackCount);
      end
      else if not SelfClosing then
      begin
        SetLength(Stack, StackCount + 1);
        Stack[StackCount] := Stack[StackCount - 1];
        ApplyAttrs(Attrs, Stack[StackCount].Style, Stack[StackCount]);
        Inc(StackCount);
      end;
      Continue;
    end;
    if (TagName = 'style') or (TagName = 'title') or (TagName = 'desc') then
    begin
      if (not Closing) and (not SelfClosing) then
        SkipUntilClose(S, APos, TagName);
      Continue;
    end;
  end;

  if RunCount = 0 then Exit;

  for I := 0 to RunCount - 1 do
  begin
    if Runs[I].HasX or Runs[I].HasY then
    begin
      PT := SvgMatrixTransformPoint(M, SvgPointF(Runs[I].X, Runs[I].Y));
      Runs[I].X := PT.X;
      Runs[I].Y := PT.Y;
    end;
    VX := Runs[I].DX;
    VY := Runs[I].DY;
    Runs[I].DX := M.A * VX + M.C * VY;
    Runs[I].DY := M.B * VX + M.D * VY;
  end;

  N := Length(FShapes);
  SetLength(FShapes, N + 1);
  FShapes[N].IsText := True;
  FShapes[N].Path := nil;
  FShapes[N].TextRuns := Runs;
  FShapes[N].TextAnchor := Anchor;
  FShapes[N].Style := Stack[0].Style;
end;

procedure TSvgImage.Parse;
var
  P: Integer;
  TagName, Attrs: string;
  Closing, SelfClosing: Boolean;
  CtxStack: array of TSvgCtx;
  InDefs: Integer;
  RootOpen: Boolean;
  BaseCtx: TSvgCtx;

  procedure PushCtx(const AParent: TSvgCtx; const AAttrs: string);
  var
    N: Integer;
    S: string;
  begin
    N := Length(CtxStack);
    SetLength(CtxStack, N + 1);
    CtxStack[N] := AParent;
    S := SvgGetAttr(AAttrs, 'transform');
    if S <> '' then
      CtxStack[N].M := SvgMatrixMultiply(CtxStack[N].M, ParseSvgTransformList(S));
    ApplySvgPresentationAttrs(AAttrs, CtxStack[N].St);
    S := SvgGetAttr(AAttrs, 'style');
    if S <> '' then ApplySvgStyleDeclarations(S, CtxStack[N].St);
  end;

  procedure PopCtx;
  begin
    if Length(CtxStack) > 1 then
      SetLength(CtxStack, Length(CtxStack) - 1);
  end;

begin
  FParsed := True;
  FError := '';
  FShapes := nil;
  FGradients := nil;
  FHasViewBox := False;
  FIntrinsicW := 0;
  FIntrinsicH := 0;
  FParNone := False;
  FParSlice := False;
  FParAlignX := 1;
  FParAlignY := 1;
  CtxStack := nil;
  InDefs := 0;
  RootOpen := False;
  P := 1;
  while NextSvgTag(FSvg, P, TagName, Closing, SelfClosing, Attrs) do
  begin
    if InDefs > 0 then
    begin
      if TagName = 'defs' then
      begin
        if Closing then Dec(InDefs)
        else if not SelfClosing then Inc(InDefs);
      end
      else if (TagName = 'lineargradient') or (TagName = 'radialgradient') then
      begin
        if (not Closing) and (not SelfClosing) then
          ParseGradient(TagName, Attrs, P);
      end;
      Continue;
    end;
    if TagName = 'defs' then
    begin
      if (not Closing) and (not SelfClosing) then Inc(InDefs);
      Continue;
    end;
    { Gradients are frequently declared as direct children of <svg>,
      not only inside <defs>. Handle that case here as well. }
    if (TagName = 'lineargradient') or (TagName = 'radialgradient') then
    begin
      if (not Closing) and (not SelfClosing) then
        ParseGradient(TagName, Attrs, P);
      Continue;
    end;
    if (TagName = 'style') or (TagName = 'title') or
       (TagName = 'desc') or (TagName = 'script') then
    begin
      if (not Closing) and (not SelfClosing) then
        SkipUntilClose(FSvg, P, TagName);
      Continue;
    end;
    if TagName = 'svg' then
    begin
      if Closing then
      begin
        if RootOpen then Break;
      end
      else if not RootOpen then
      begin
        RootOpen := True;
        ParseSvgRootAttrs(Attrs);
        BaseCtx.M := SvgMatrixIdentity;
        BaseCtx.St := DefaultSvgStyle;
        PushCtx(BaseCtx, Attrs);
      end;
      Continue;
    end;
    if not RootOpen then Continue;
    if TagName = 'g' then
    begin
      if Closing then
        PopCtx
      else if SvgElementHidden(Attrs) then
      begin
        if not SelfClosing then
          SkipElement(FSvg, P, TagName);
      end
      else
      begin
        PushCtx(CtxStack[High(CtxStack)], Attrs);
        if SelfClosing then PopCtx;
      end;
      Continue;
    end;
    if TagName = 'text' then
    begin
      if (not Closing) and (not SelfClosing) then
        ParseTextElement(FSvg, P, Attrs, CtxStack[High(CtxStack)]);
      Continue;
    end;
    if (TagName = 'path') or (TagName = 'rect') or (TagName = 'circle') or
       (TagName = 'ellipse') or (TagName = 'line') or (TagName = 'polyline') or
       (TagName = 'polygon') then
    begin
      if not Closing then
        ParseShape(TagName, Attrs, CtxStack[High(CtxStack)]);
      Continue;
    end;
  end;
  if not RootOpen then
    FError := '<svg> root element not found';
end;

procedure TSvgImage.ComputeView(AW, AH: Integer; out SX, SY, OX, OY: Double);
var
  VBX, VBY, VBW, VBH, S: Double;
begin
  if FHasViewBox then
  begin
    VBX := FVBX; VBY := FVBY; VBW := FVBW; VBH := FVBH;
  end
  else if (FIntrinsicW > 0) and (FIntrinsicH > 0) then
  begin
    VBX := 0; VBY := 0; VBW := FIntrinsicW; VBH := FIntrinsicH;
  end
  else
  begin
    VBX := 0; VBY := 0; VBW := AW; VBH := AH;
  end;
  if (VBW <= 0) or (VBH <= 0) then
  begin
    VBX := 0; VBY := 0; VBW := AW; VBH := AH;
  end;
  if FParNone then
  begin
    SX := AW / VBW;
    SY := AH / VBH;
    OX := 0;
    OY := 0;
  end
  else
  begin
    if FParSlice then
      S := Max(AW / VBW, AH / VBH)
    else
      S := Min(AW / VBW, AH / VBH);
    SX := S;
    SY := S;
    case FParAlignX of
      0: OX := 0;
      2: OX := AW - VBW * S;
    else
      OX := (AW - VBW * S) / 2;
    end;
    case FParAlignY of
      0: OY := 0;
      2: OY := AH - VBH * S;
    else
      OY := (AH - VBH * S) / 2;
    end;
  end;
  OX := OX - VBX * SX;
  OY := OY - VBY * SY;
end;

function TSvgImage.FlattenSubpathPts(const ASP: TSvgSubpath;
  SX, SY, OX, OY, ATol: Double): TAAFloatPoints;
var
  Pts: TAAFloatPoints;
  Cnt: Integer;
  CurU: TPointF;

  function Map(const P: TPointF): TPointF; inline;
  begin
    Result.X := P.X * SX + OX;
    Result.Y := P.Y * SY + OY;
  end;

  procedure App(const P: TPointF);
  begin
    AppendPointF(Pts, Cnt, P);
  end;

  procedure FlattenCubicRec(const P0, P1, P2, P3: TPointF; Depth: Integer);
  var
    M01, M12, M23, M012, M123, M0123: TPointF;
    D1, D2: Double;
  begin
    if Depth >= 14 then
    begin
      App(P3);
      Exit;
    end;
    D1 := SvgDistToLine(P1, P0, P3);
    D2 := SvgDistToLine(P2, P0, P3);
    if Max(D1, D2) <= ATol then
    begin
      App(P3);
      Exit;
    end;
    M01 := SvgMid(P0, P1);
    M12 := SvgMid(P1, P2);
    M23 := SvgMid(P2, P3);
    M012 := SvgMid(M01, M12);
    M123 := SvgMid(M12, M23);
    M0123 := SvgMid(M012, M123);
    FlattenCubicRec(P0, M01, M012, M0123, Depth + 1);
    FlattenCubicRec(M0123, M123, M23, P3, Depth + 1);
  end;

var
  I: Integer;
  Seg: TSvgSeg;
  C1, C2: TPointF;
begin
  Pts := nil;
  Cnt := 0;
  CurU := ASP.Start;
  App(Map(CurU));
  for I := 0 to High(ASP.Segs) do
  begin
    Seg := ASP.Segs[I];
    case Seg.Kind of
      sskLine:
      begin
        CurU := Seg.P1;
        App(Map(CurU));
      end;
      sskQuad:
      begin
        C1 := SvgPointF(CurU.X + 2 / 3 * (Seg.P1.X - CurU.X),
                        CurU.Y + 2 / 3 * (Seg.P1.Y - CurU.Y));
        C2 := SvgPointF(Seg.P2.X + 2 / 3 * (Seg.P1.X - Seg.P2.X),
                        Seg.P2.Y + 2 / 3 * (Seg.P1.Y - Seg.P2.Y));
        FlattenCubicRec(Map(CurU), Map(C1), Map(C2), Map(Seg.P2), 0);
        CurU := Seg.P2;
      end;
      sskCubic:
      begin
        FlattenCubicRec(Map(CurU), Map(Seg.P1), Map(Seg.P2), Map(Seg.P3), 0);
        CurU := Seg.P3;
      end;
    end;
  end;
  Result := Copy(Pts, 0, Cnt);
end;

function TSvgImage.GetShapeCount: Integer;
begin
  if not FParsed then Parse;
  Result := Length(FShapes);
end;

function TSvgImage.FindGradient(const AId: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FGradients) do
    if SameText(FGradients[I].Id, AId) then
      Exit(I);
  Result := -1;
end;

function TSvgImage.BuildGradientParams(const ADef: TSvgGradientDef;
  const APath: TSvgPathData; SX, SY, OX, OY: Double): TSvgGradientParams;
var
  MinX, MinY, MaxX, MaxY: Double;
  I, J: Integer;
  Pts: TAAFloatPoints;
  P: TPointF;
  Mgt, Mutd, Mcombined: TSvgMatrix;
begin
  Result.Kind := ADef.Kind;
  Result.Stops := ADef.Stops;
  Result.Transform := ADef.Transform;
  Result.SpreadMethod := ADef.SpreadMethod;

  // Compose the parsed gradientTransform (gradient -> user) with the
  // user-to-device transform, so SvgGradientColorAtPoint can apply
  // the inverse directly to device pixel coordinates.
  //
  //   device -> user        : Mutd^-1
  //   user   -> gradient    : Mgt^-1
  //   device -> gradient    : (Mutd * Mgt)^-1
  //
  Mgt.A := ADef.Transform.A;
  Mgt.B := ADef.Transform.B;
  Mgt.C := ADef.Transform.C;
  Mgt.D := ADef.Transform.D;
  Mgt.E := ADef.Transform.E;
  Mgt.F := ADef.Transform.F;

  Mutd := SvgMatrixMake(SX, 0, 0, SY, OX, OY);
  Mcombined := SvgMatrixMultiply(Mutd, Mgt);

  Result.Transform.A := Mcombined.A;
  Result.Transform.B := Mcombined.B;
  Result.Transform.C := Mcombined.C;
  Result.Transform.D := Mcombined.D;
  Result.Transform.E := Mcombined.E;
  Result.Transform.F := Mcombined.F;

  if ADef.GradientUnits = svgguObjectBoundingBox then
  begin
    // Compute bounding box of the shape in device coordinates
    MinX := MaxDouble;
    MinY := MaxDouble;
    MaxX := -MaxDouble;
    MaxY := -MaxDouble;
    for I := 0 to High(APath) do
    begin
      Pts := FlattenSubpathPts(APath[I], SX, SY, OX, OY, 0.25);
      for J := 0 to High(Pts) do
      begin
        P := Pts[J];
        if P.X < MinX then MinX := P.X;
        if P.Y < MinY then MinY := P.Y;
        if P.X > MaxX then MaxX := P.X;
        if P.Y > MaxY then MaxY := P.Y;
      end;
    end;
    if MinX > MaxX then
    begin
      MinX := OX; MaxX := OX + 1;
      MinY := OY; MaxY := OY + 1;
    end;
    // Map gradient coordinates from [0,1] to bounding box
    Result.X1 := MinX + ADef.X1 * (MaxX - MinX);
    Result.Y1 := MinY + ADef.Y1 * (MaxY - MinY);
    Result.X2 := MinX + ADef.X2 * (MaxX - MinX);
    Result.Y2 := MinY + ADef.Y2 * (MaxY - MinY);
    Result.CX := MinX + ADef.CX * (MaxX - MinX);
    Result.CY := MinY + ADef.CY * (MaxY - MinY);
    Result.R := ADef.R * Sqrt(Sqr(MaxX - MinX) + Sqr(MaxY - MinY));
    Result.FX := MinX + ADef.FX * (MaxX - MinX);
    Result.FY := MinY + ADef.FY * (MaxY - MinY);
  end
  else // svgguUserSpaceOnUse
  begin
    // Coordinates stay in SVG user space; the composed transform
    // above takes care of mapping device pixels back into it.
    Result.X1 := ADef.X1;
    Result.Y1 := ADef.Y1;
    Result.X2 := ADef.X2;
    Result.Y2 := ADef.Y2;
    Result.CX := ADef.CX;
    Result.CY := ADef.CY;
    Result.R := ADef.R;
    Result.FX := ADef.FX;
    Result.FY := ADef.FY;
  end;
end;

procedure TSvgImage.InternalRender(ACanvas: TCanvas; AImg: TLazIntfImage;
  AOfsX, AOfsY, AW, AH: Integer; ACurrentColor: TColor);
var
  SX, SY, OX, OY: Double;
  Cov: array of Byte;
  I, J, PC, GradIdx: Integer;
  Shp: TSvgShape;
  FillCol, StrokeCol: TColor;
  Alpha, SW: Double;
  Poly: TAAFloatPolygons;
  Pts: TAAFloatPoints;
  GradParams: TSvgGradientParams;

  function ResolvePaint(const PPaint: TSvgPaint): TColor;
  begin
    if PPaint.IsCurrent then Result := ACurrentColor
    else Result := PPaint.Color;
  end;

  function CapMap(C: TSvgLineCap): TAAStrokeCap;
  begin
    case C of
      svglcRound: Result := aascRound;
      svglcSquare: Result := aascSquare;
    else
      Result := aascButt;
    end;
  end;

  function JoinMap(J: TSvgLineJoin): TAAStrokeJoin;
  begin
    case J of
      svgljRound: Result := aasjRound;
      svgljBevel: Result := aasjBevel;
    else
      Result := aasjMiter;
    end;
  end;

  procedure BlendCov(const CovArr: array of Byte; AColor: TColor;
    AAlpha: Double);
  begin
    if AAlpha <= 0 then Exit;
    if AAlpha > 1 then AAlpha := 1;
    if AImg <> nil then
      AABlendCoverageToImage(AImg, 0, 0, AW, AH, CovArr, AColor, AAlpha)
    else
      AABlendCoverageWithAlphaToCanvas(ACanvas, AOfsX, AOfsY, AW, AH,
        CovArr, AColor, AAlpha);
  end;

  procedure BlendCovWithGradient(const CovArr: array of Byte;
    const AGradParams: TSvgGradientParams; AAlpha: Double);
  begin
    if AAlpha <= 0 then Exit;
    if AAlpha > 1 then AAlpha := 1;
    if AImg <> nil then
      AABlendCoverageWithGradientToImage(AImg, 0, 0, AW, AH, CovArr,
        AGradParams, AAlpha)
    else
      AABlendCoverageWithGradientToCanvas(ACanvas, AOfsX, AOfsY, AW, AH,
        CovArr, AGradParams, AAlpha);
  end;

begin
  if not FParsed then Parse;
  if (AW <= 0) or (AH <= 0) then Exit;
  if Length(FShapes) = 0 then Exit;
  if ACurrentColor = clDefault then ACurrentColor := clBlack;
  ComputeView(AW, AH, SX, SY, OX, OY);
  SetLength(Cov, AW * AH);
  for I := 0 to High(FShapes) do
  begin
    Shp := FShapes[I];
    if Shp.IsText then
    begin
      RenderTextShape(Shp, ACanvas, AImg, AOfsX, AOfsY, AW, AH,
        SX, SY, OX, OY, ACurrentColor);
      Continue;
    end;
    // Fill
    if (not Shp.Style.Fill.IsNone) and (Length(Shp.Path) > 0) then
    begin
      Poly := nil;
      PC := 0;
      for J := 0 to High(Shp.Path) do
      begin
        Pts := FlattenSubpathPts(Shp.Path[J], SX, SY, OX, OY, 0.25);
        if Length(Pts) >= 3 then
        begin
          if PC >= Length(Poly) then SetLength(Poly, Length(Poly) + 4);
          Poly[PC] := Pts;
          Inc(PC);
        end;
      end;
      if PC > 0 then
      begin
        SetLength(Poly, PC);
        if Shp.Style.FillRule = svgfrEvenOdd then
          AABuildPolygonsCoverage(Cov, AW, AH, Poly, aafrEvenOdd)
        else
          AABuildPolygonsCoverage(Cov, AW, AH, Poly, aafrNonZero);

        if Shp.Style.Fill.IsGradient then
        begin
          GradIdx := FindGradient(Shp.Style.Fill.GradientId);
          if GradIdx >= 0 then
          begin
            GradParams := BuildGradientParams(FGradients[GradIdx], Shp.Path,
              SX, SY, OX, OY);
            Alpha := Shp.Style.FillOpacity * Shp.Style.Opacity;
            BlendCovWithGradient(Cov, GradParams, Alpha);
          end;
        end
        else
        begin
          FillCol := ResolvePaint(Shp.Style.Fill);
          Alpha := Shp.Style.FillOpacity * Shp.Style.Opacity;
          BlendCov(Cov, FillCol, Alpha);
        end;
      end;
    end;
    // Stroke
    if (not Shp.Style.Stroke.IsNone) and (Shp.Style.StrokeWidth > 0) then
    begin
      SW := Shp.Style.StrokeWidth * (SX + SY) / 2;
      if SW > 0 then
      begin
        if Shp.Style.Stroke.IsGradient then
        begin
          GradIdx := FindGradient(Shp.Style.Stroke.GradientId);
          if GradIdx >= 0 then
          begin
            GradParams := BuildGradientParams(FGradients[GradIdx], Shp.Path,
              SX, SY, OX, OY);
            Alpha := Shp.Style.StrokeOpacity * Shp.Style.Opacity;
            for J := 0 to High(Shp.Path) do
            begin
              Pts := FlattenSubpathPts(Shp.Path[J], SX, SY, OX, OY, 0.25);
              if Length(Pts) >= 2 then
              begin
                AABuildStrokeCoverage(Cov, AW, AH, Pts, SW,
                  CapMap(Shp.Style.LineCap), JoinMap(Shp.Style.LineJoin),
                  Shp.Style.MiterLimit, Shp.Path[J].Closed);
                BlendCovWithGradient(Cov, GradParams, Alpha);
              end;
            end;
          end;
        end
        else
        begin
          StrokeCol := ResolvePaint(Shp.Style.Stroke);
          Alpha := Shp.Style.StrokeOpacity * Shp.Style.Opacity;
          for J := 0 to High(Shp.Path) do
          begin
            Pts := FlattenSubpathPts(Shp.Path[J], SX, SY, OX, OY, 0.25);
            if Length(Pts) >= 2 then
            begin
              AABuildStrokeCoverage(Cov, AW, AH, Pts, SW,
                CapMap(Shp.Style.LineCap), JoinMap(Shp.Style.LineJoin),
                Shp.Style.MiterLimit, Shp.Path[J].Closed);
              BlendCov(Cov, StrokeCol, Alpha);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TSvgImage.RenderTextShape(const AShp: TSvgShape; ACanvas: TCanvas;
  AImg: TLazIntfImage; AOfsX, AOfsY, AW, AH: Integer;
  SX, SY, OX, OY: Double; ACurrentColor: TColor);
var
  Cov: array of Byte;
  PenX, PenY: Double;
  I: Integer;
  Col: TColor;
  Alpha: Double;
begin
  if Length(AShp.TextRuns) = 0 then Exit;
  SetLength(Cov, AW * AH);
  PenX := OX;
  PenY := OY;
  for I := 0 to High(AShp.TextRuns) do
  begin
    if AShp.TextRuns[I].Style.Fill.IsNone then Continue;
    if not BuildTextRunCoverage(AShp.TextRuns[I], AShp.TextAnchor,
      SX, SY, OX, OY, AW, AH, PenX, PenY, Cov) then Continue;
    if AShp.TextRuns[I].Style.Fill.IsCurrent then
      Col := ACurrentColor
    else
      Col := AShp.TextRuns[I].Style.Fill.Color;
    Alpha := AShp.TextRuns[I].Style.FillOpacity * AShp.TextRuns[I].Style.Opacity;
    if Alpha <= 0 then Continue;
    if AImg <> nil then
      AABlendCoverageToImage(AImg, 0, 0, AW, AH, Cov, Col, Alpha)
    else
      AABlendCoverageWithAlphaToCanvas(ACanvas, AOfsX, AOfsY, AW, AH,
        Cov, Col, Alpha);
  end;
end;

function TSvgImage.BuildTextRunCoverage(const Run: TSvgTextRun;
  AAnchor: TSvgTextAnchor; SX, SY, OX, OY: Double;
  AW, AH: Integer; var PenX, PenY: Double;
  var ACoverage: array of Byte): Boolean;
var
  Bmp: TBitmap;
  Img: TLazIntfImage;
  TM: TTextMetric;
  Scale, FontDev: Double;
  SS, FontPxSS, TW, TH, BaselineSS, Pad, X0, Y0: Integer;
  Sx2, Sy2, Dx2, Dy2, Idx, CovAdd: Integer;
  Pix: TFPColor;
  S: string;
begin
  Result := False;
  for Idx := 0 to AW * AH - 1 do
    ACoverage[Idx] := 0;
  S := Run.Text;
  if S = '' then Exit;
  Scale := (SX + SY) / 2;
  if Scale <= 0 then Exit;
  FontDev := Run.FontSize;
  if FontDev <= 0 then FontDev := 16;
  FontDev := FontDev * Scale;
  if FontDev < 0.4 then Exit;
  SS := CSSVG_TEXT_SUPERSAMPLE;
  FontPxSS := Round(FontDev * SS);
  if FontPxSS < 1 then FontPxSS := 1;

  if Run.HasX then PenX := Run.X * SX + OX;
  if Run.HasY then PenY := Run.Y * SY + OY;
  PenX := PenX + Run.DX * SX;
  PenY := PenY + Run.DY * SY;

  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.Font.Style := [];
    if Run.Family <> '' then
      Bmp.Canvas.Font.Name := ResolveFontFamily(Run.Family);
    Bmp.Canvas.Font.Height := -FontPxSS;
    if Run.Bold then
      Bmp.Canvas.Font.Style := Bmp.Canvas.Font.Style + [fsBold];
    if Run.Italic then
      Bmp.Canvas.Font.Style := Bmp.Canvas.Font.Style + [fsItalic];
    Bmp.Canvas.Font.Quality := fqAntialiased;
    Bmp.Canvas.Font.Color := clBlack;

    TW := Bmp.Canvas.TextWidth(S);
    TH := Bmp.Canvas.TextHeight(S);
    if (TW <= 0) or (TH <= 0) then Exit;

    if Run.HasX then
    begin
      case AAnchor of
        svgtaMiddle: PenX := PenX - (TW / SS) / 2;
        svgtaEnd:    PenX := PenX - (TW / SS);
      end;
    end;

    BaselineSS := Round(TH * 0.8);
    if GetTextMetrics(Bmp.Canvas.Handle, TM) then
    begin
      BaselineSS := TM.tmAscent - TM.tmInternalLeading;
      if BaselineSS < 1 then BaselineSS := TM.tmAscent;
      if BaselineSS > TH then BaselineSS := TH;
    end;

    Pad := 2;
    Bmp.SetSize(TW + Pad * 2, TH + Pad * 2);
    Bmp.Canvas.FillRect(0, 0, Bmp.Width, Bmp.Height);
    Bmp.Canvas.TextOut(Pad, Pad, S);

    X0 := Round((PenX - Pad / SS) * SS);
    Y0 := Round((PenY - (BaselineSS + Pad) / SS) * SS);
    Img := Bmp.CreateIntfImage;
    try
      for Sy2 := 0 to Bmp.Height - 1 do
      begin
        Dy2 := Floor((Y0 + Sy2) / SS);
        if (Dy2 < 0) or (Dy2 >= AH) then Continue;
        for Sx2 := 0 to Bmp.Width - 1 do
        begin
          Dx2 := Floor((X0 + Sx2) / SS);
          if (Dx2 < 0) or (Dx2 >= AW) then Continue;
          Pix := Img.Colors[Sx2, Sy2];
          CovAdd := 255 - (Pix.Red shr 8);
          if CovAdd <= 0 then Continue;
          Idx := Dy2 * AW + Dx2;
          CovAdd := ACoverage[Idx] + CovAdd;
          if CovAdd > 255 then CovAdd := 255;
          ACoverage[Idx] := Byte(CovAdd);
        end;
      end;
    finally
      Img.Free;
    end;

    PenX := PenX + TW / SS;
    Result := True;
  finally
    Bmp.Free;
  end;
end;

procedure TSvgImage.RenderToCanvas(ACanvas: TCanvas; AX, AY, AW, AH: Integer;
  ACurrentColor: TColor);
begin
  if ACanvas = nil then Exit;
  InternalRender(ACanvas, nil, AX, AY, AW, AH, ACurrentColor);
end;

procedure TSvgImage.RenderToBitmap(ABitmap: TBitmap; AW, AH: Integer;
  ACurrentColor: TColor);
var
  Img: TLazIntfImage;
  C: TFPColor;
  X, Y: Integer;
begin
  if ABitmap = nil then Exit;
  if not FParsed then Parse;
  if (AW <= 0) or (AH <= 0) then Exit;
  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);
  Img := ABitmap.CreateIntfImage;
  try
    C.Red := 0;
    C.Green := 0;
    C.Blue := 0;
    C.Alpha := 0;
    for Y := 0 to AH - 1 do
      for X := 0 to AW - 1 do
        Img.Colors[X, Y] := C;
    InternalRender(nil, Img, 0, 0, AW, AH, ACurrentColor);
    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

// ============================================================================
//  Collection item
// ============================================================================

constructor TCssSvgImgListItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FVariants := TStringList.Create;
  FVariants.NameValueSeparator := '=';
  FVariants.OnChange := @OnVariantsChanged;
end;

destructor TCssSvgImgListItem.Destroy;
begin
  FreeAndNil(FVariants);
  FreeAndNil(FImage);
  inherited Destroy;
end;

function TCssSvgImgListItem.GetImage: TSvgImage;
begin
  Result := GetImageForVariant('');
end;

function TCssSvgImgListItem.GetVariants: TStrings;
begin
  Result := FVariants;
end;

procedure TCssSvgImgListItem.SetSvg(const AValue: string);
begin
  if FSvg = AValue then Exit;
  FSvg := AValue;
  FreeAndNil(FImage);
  FImageVariant := '';
  Changed(False);
end;

procedure TCssSvgImgListItem.SetName(const AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed(False);
end;

procedure TCssSvgImgListItem.SetVariants(const AValue: TStrings);
begin
  FVariants.Assign(AValue);
  { FVariants.OnChange fires automatically and invalidates the cache. }
end;

procedure TCssSvgImgListItem.OnVariantsChanged(Sender: TObject);
begin
  FreeAndNil(FImage);
  FImageVariant := '';
  Changed(False);
end;

function TCssSvgImgListItem.EffectiveSvg(const AVariant: string): string;
var
  I: Integer;
begin
  { Case-insensitive lookup, because the CSS variant name
    ("Dark" / "Light") does not necessarily match the exact casing
    used when the SVG variant was added ("dark" / "light"). }
  if (AVariant <> '') and (FVariants <> nil) then
  begin
    for I := 0 to FVariants.Count - 1 do
    begin
      if SameText(FVariants.Names[I], AVariant) then
      begin
        Result := FVariants.ValueFromIndex[I];
        if Result <> '' then
          Exit;
      end;
    end;
  end;
  Result := FSvg;
end;

function TCssSvgImgListItem.GetImageForVariant(
  const AVariant: string): TSvgImage;
var
  E: string;
begin
  if (FImage <> nil) and (FImageVariant = AVariant) then
    Exit(FImage);

  E := EffectiveSvg(AVariant);

  FreeAndNil(FImage);
  FImage := TSvgImage.Create(E);
  FImageVariant := AVariant;
  Result := FImage;
end;

// ============================================================================
//  Collection
// ============================================================================

constructor TCssSvgImgListItems.Create(AOwner: TCssSvgImgList);
begin
  inherited Create(TCssSvgImgListItem);
  FOwner := AOwner;
end;

function TCssSvgImgListItems.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TCssSvgImgListItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOwner) then
    FOwner.Changed;
end;

function TCssSvgImgListItems.Add: TCssSvgImgListItem;
begin
  Result := TCssSvgImgListItem(inherited Add);
end;

function TCssSvgImgListItems.GetItem(Index: Integer): TCssSvgImgListItem;
begin
  Result := TCssSvgImgListItem(inherited GetItem(Index));
end;

procedure TCssSvgImgListItems.SetItem(Index: Integer;
  const AValue: TCssSvgImgListItem);
begin
  inherited SetItem(Index, AValue);
end;

// ============================================================================
//  Component
// ============================================================================

constructor TCssSvgImgList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TCssSvgImgListItems.Create(Self);
  FWidth := 16;
  FHeight := 16;
  FScaled := True;
  FCache := TStringList.Create;
  FCache.CaseSensitive := True;
  FSerial := 0;
end;

destructor TCssSvgImgList.Destroy;
begin
  ClearCache;
  FreeAndNil(FCache);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TCssSvgImgList.Assign(Source: TPersistent);
begin
  if Source is TCssSvgImgList then
  begin
    FItems.Assign(TCssSvgImgList(Source).FItems);
    FWidth := TCssSvgImgList(Source).FWidth;
    FHeight := TCssSvgImgList(Source).FHeight;
    FScaled := TCssSvgImgList(Source).FScaled;
    Changed;
  end
  else
    inherited Assign(Source);
end;

procedure TCssSvgImgList.Changed;
begin
  Inc(FSerial);
  ClearCache;
  if (ComponentState * [csLoading, csReading, csDestroying]) = [] then
    if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TCssSvgImgList.ClearCache;
var
  I: Integer;
begin
  for I := 0 to FCache.Count - 1 do
    FCache.Objects[I].Free;
  FCache.Clear;
end;

function TCssSvgImgList.CacheGet(const ASig: string): TBitmap;
var
  I: Integer;
begin
  Result := nil;
  I := FCache.IndexOf(ASig);
  if I < 0 then Exit;
  Result := TBitmap(FCache.Objects[I]);
  FCache.Delete(I);
  FCache.AddObject(ASig, Result);
end;

procedure TCssSvgImgList.CachePut(const ASig: string; ABitmap: TBitmap);
begin
  while FCache.Count >= 64 do
  begin
    FCache.Objects[0].Free;
    FCache.Delete(0);
  end;
  FCache.AddObject(ASig, ABitmap);
end;

procedure TCssSvgImgList.SetDefaultVariant(const AValue: string);
begin
  if FDefaultVariant = AValue then Exit;
  FDefaultVariant := AValue;
  Changed;
end;

function TCssSvgImgList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TCssSvgImgList.SetItems(const AValue: TCssSvgImgListItems);
begin
  FItems.Assign(AValue);
end;

procedure TCssSvgImgList.SetWidth(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FWidth = AValue then Exit;
  FWidth := AValue;
  Changed;
end;

procedure TCssSvgImgList.SetHeight(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FHeight = AValue then Exit;
  FHeight := AValue;
  Changed;
end;

procedure TCssSvgImgList.SetScaled(AValue: Boolean);
begin
  if FScaled = AValue then Exit;
  FScaled := AValue;
  Changed;
end;

function TCssSvgImgList.Count: Integer;
begin
  Result := FItems.Count;
end;

function TCssSvgImgList.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to Count - 1 do
    if SameText(FItems[Result].Name, AName) then Exit;
  Result := -1;
end;

function TCssSvgImgList.AddSvg(const AName, ASvg: string): Integer;
var
  Item: TCssSvgImgListItem;
begin
  Item := FItems.Add;
  Item.Name := AName;
  Item.Svg := ASvg;
  Result := Item.Index;
end;

function TCssSvgImgList.AddSvgFromFile(const AName, AFileName: string): Integer;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.LoadFromFile(AFileName);
    Result := AddSvg(AName, L.Text);
  finally
    L.Free;
  end;
end;

procedure TCssSvgImgList.Delete(AIndex: Integer);
begin
  FItems.Delete(AIndex);
end;

procedure TCssSvgImgList.Clear;
begin
  FItems.Clear;
end;

function TCssSvgImgList.GetSvg(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Count) then
    Result := ''
  else
    Result := FItems[AIndex].Svg;
end;

function TCssSvgImgList.GetSvg(const AName: string): string;
begin
  Result := GetSvg(IndexOf(AName));
end;

procedure TCssSvgImgList.SetSvg(AIndex: Integer; const AValue: string);
begin
  if (AIndex >= 0) and (AIndex < Count) then
    FItems[AIndex].Svg := AValue;
end;

function TCssSvgImgList.GetParseError(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Count) then
    Result := ''
  else
    Result := FItems[AIndex].Image.Error;
end;

function TCssSvgImgList.GetScaleFactor: Double;
var
  PPI: Integer;
begin
  if not FScaled then
    Exit(1.0);
  PPI := Screen.PixelsPerInch;
  if PPI <= 0 then PPI := 96;
  Result := PPI / 96.0;
end;

function TCssSvgImgList.GetEffectiveWidth: Integer;
begin
  Result := Max(1, Round(FWidth * GetScaleFactor));
end;

function TCssSvgImgList.GetEffectiveHeight: Integer;
begin
  Result := Max(1, Round(FHeight * GetScaleFactor));
end;

function TCssSvgImgList.GetBitmapByName(const AName: string;
  AWidth, AHeight: Integer; ACurrentColor: TColor): TBitmap;
begin
  Result := GetBitmap(IndexOf(AName), AWidth, AHeight, ACurrentColor,
    FDefaultVariant);
end;

function TCssSvgImgList.GetBitmapByName(const AName: string;
  AWidth, AHeight: Integer; ACurrentColor: TColor;
  const AVariant: string): TBitmap;
begin
  Result := GetBitmap(IndexOf(AName), AWidth, AHeight, ACurrentColor, AVariant);
end;

procedure TCssSvgImgList.DrawToCanvas(ACanvas: TCanvas; AIndex: Integer;
  AX, AY: Integer);
begin
  DrawToCanvas(ACanvas, AIndex, AX, AY,
    GetEffectiveWidth, GetEffectiveHeight);
end;

procedure TCssSvgImgList.DrawToCanvas(ACanvas: TCanvas; AIndex: Integer;
  AX, AY, AW, AH: Integer; ACurrentColor: TColor);
var
  Bmp: TBitmap;
begin
  if ACanvas = nil then Exit;
  Bmp := GetBitmap(AIndex, AW, AH, ACurrentColor);
  try
    ACanvas.Draw(AX, AY, Bmp);
  finally
    Bmp.Free;
  end;
end;

function CreateAlphaMaskBitmap(ABitmap: TBitmap): TBitmap;
var
  Src, Dst: TLazIntfImage;
  X, Y: Integer;
  C: TFPColor;
  White, Black: TFPColor;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(ABitmap.Width, ABitmap.Height);
  White.Red := $FFFF; White.Green := $FFFF; White.Blue := $FFFF; White.Alpha := $FFFF;
  Black.Red := 0; Black.Green := 0; Black.Blue := 0; Black.Alpha := $FFFF;
  Src := ABitmap.CreateIntfImage;
  try
    Dst := Result.CreateIntfImage;
    try
      for Y := 0 to ABitmap.Height - 1 do
        for X := 0 to ABitmap.Width - 1 do
        begin
          C := Src.Colors[X, Y];
          if C.Alpha >= 32768 then
            Dst.Colors[X, Y] := Black
          else
            Dst.Colors[X, Y] := White;
        end;
      Result.LoadFromIntfImage(Dst);
    finally
      Dst.Free;
    end;
  finally
    Src.Free;
  end;
end;

procedure TCssSvgImgList.AssignToImageList(AImageList: TCustomImageList;
  ACurrentColor: TColor);
var
  I, W, H: Integer;
  Bmp, Msk: TBitmap;
begin
  if AImageList = nil then Exit;
  AImageList.Clear;
  W := AImageList.Width;
  H := AImageList.Height;
  if (W <= 0) or (H <= 0) then Exit;
  for I := 0 to Count - 1 do
  begin
    Bmp := GetBitmap(I, W, H, ACurrentColor);
    try
      Msk := CreateAlphaMaskBitmap(Bmp);
      try
        AImageList.Add(Bmp, Msk);
      finally
        Msk.Free;
      end;
    finally
      Bmp.Free;
    end;
  end;
end;

function TCssSvgImgList.GetVariantNames: TStrings;
var
  L: TStringList;
  I, J: Integer;
  Item: TCssSvgImgListItem;
  N: string;
begin
  L := TStringList.Create;
  L.Sorted := True;
  L.Duplicates := dupIgnore;

  try
    for I := 0 to FItems.Count - 1 do
    begin
      Item := FItems[I];
      for J := 0 to Item.Variants.Count - 1 do
      begin
        N := Item.Variants.Names[J];
        if Trim(N) <> '' then
          L.Add(N);
      end;
    end;
  except
    L.Free;
    raise;
  end;

  Result := L;
end;

function TCssSvgImgList.HasVariant(const AVariant: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if AVariant = '' then Exit;

  for I := 0 to FItems.Count - 1 do
    if FItems[I].Variants.IndexOfName(AVariant) >= 0 then
      Exit(True);
end;

function TCssSvgImgList.GetBitmap(AIndex, AWidth, AHeight: Integer;
  ACurrentColor: TColor): TBitmap;
begin
  Result := GetBitmap(AIndex, AWidth, AHeight, ACurrentColor,
    FDefaultVariant);
end;

function TCssSvgImgList.GetBitmap(AIndex, AWidth, AHeight: Integer;
  ACurrentColor: TColor; const AVariant: string): TBitmap;
var
  Sig: string;
  Cached: TBitmap;
  Item: TCssSvgImgListItem;
  C: TColor;
  SuperFactor, SuperW, SuperH: Integer;
  Big: TBitmap;
  BigImg, DstImg: TLazIntfImage;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  if (AIndex < 0) or (AIndex >= Count) or
     (AWidth <= 0) or (AHeight <= 0) then
    Exit;

  C := ACurrentColor;
  if C = clDefault then C := clBlack;

  // NOTE: the cache signature intentionally stays the same — the
  // supersampling factor is derived deterministically from
  // (AWidth, AHeight), so two calls with identical arguments can never
  // disagree about which internal render size to use.
  Sig := Format('%d;%d;%s;%dx%d;%d',
    [FSerial, AIndex, AVariant, AWidth, AHeight, Integer(ColorToRGB(C))]);

  Cached := CacheGet(Sig);
  if Cached = nil then
  begin
    Item := FItems[AIndex];
    SuperFactor := ComputeSvgSuperFactor(AWidth, AHeight);

    if SuperFactor <= 1 then
    begin
      // Large target — the native resolution is already fine, render
      // straight to the destination bitmap.
      Cached := TBitmap.Create;
      Cached.PixelFormat := pf32bit;
      Item.GetImageForVariant(AVariant)
          .RenderToBitmap(Cached, AWidth, AHeight, C);
    end
    else
    begin
      SuperW := AWidth  * SuperFactor;
      SuperH := AHeight * SuperFactor;

      Big := TBitmap.Create;
      try
        Big.PixelFormat := pf32bit;
        Big.SetSize(SuperW, SuperH);

        Item.GetImageForVariant(AVariant)
            .RenderToBitmap(Big, SuperW, SuperH, C);

        Cached := TBitmap.Create;
        Cached.PixelFormat := pf32bit;
        Cached.SetSize(AWidth, AHeight);

        BigImg := Big.CreateIntfImage;
        try
          DstImg := Cached.CreateIntfImage;
          try
            DownsampleBitmapAlpha(BigImg, DstImg, SuperFactor);
            Cached.LoadFromIntfImage(DstImg);
          finally
            DstImg.Free;
          end;
        finally
          BigImg.Free;
        end;
      finally
        Big.Free;
      end;
    end;

    CachePut(Sig, Cached);
  end;

  Result.Assign(Cached);
end;

procedure TCssSvgImgList.SaveToStream(AStream: TStream);
var
  L: TStringList;
  I: Integer;
begin
  L := TStringList.Create;
  try
    L.Add('SVGIMGLIST v1');
    for I := 0 to Count - 1 do
    begin
      L.Add('@@ITEM ' + FItems[I].Name);
      L.Add(FItems[I].Svg);
    end;
    L.SaveToStream(AStream);
  finally
    L.Free;
  end;
end;

procedure TCssSvgImgList.LoadFromStream(AStream: TStream);
var
  L: TStringList;
  I: Integer;
  Line, CurName: string;
  CurText: TStringList;
  InItem: Boolean;
begin
  L := TStringList.Create;
  try
    L.LoadFromStream(AStream);
    FItems.BeginUpdate;
    try
      Clear;
      CurText := TStringList.Create;
      try
        InItem := False;
        CurName := '';
        for I := 0 to L.Count - 1 do
        begin
          Line := L[I];
          if Copy(Line, 1, 7) = '@@ITEM ' then
          begin
            if InItem then
              AddSvg(CurName, Trim(CurText.Text));
            CurName := Copy(Line, 8, MaxInt);
            CurText.Clear;
            InItem := True;
          end
          else if Line = '@@ITEM' then
          begin
            if InItem then
              AddSvg(CurName, Trim(CurText.Text));
            CurName := '';
            CurText.Clear;
            InItem := True;
          end
          else if InItem then
            CurText.Add(Line);
        end;
        if InItem then
          AddSvg(CurName, Trim(CurText.Text));
      finally
        CurText.Free;
      end;
    finally
      FItems.EndUpdate;
    end;
  finally
    L.Free;
  end;
  Changed;
end;

procedure TCssSvgImgList.SaveToFile(const AFileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TCssSvgImgList.LoadFromFile(const AFileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

end.
