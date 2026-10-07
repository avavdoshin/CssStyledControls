unit CssBitBtnControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, Forms,
  ImgList, LCLType,
  CssStyledControl, CssButtonControl, CssAntiAlias, CssSvgImgList;

type
  TCssButtonLayout = (blGlyphLeft, blGlyphRight, blGlyphTop, blGlyphBottom);

  TCssBitBtnKind = (
    bkCustom, bkOK, bkCancel, bkHelp, bkYes, bkNo,
    bkClose, bkAbort, bkRetry, bkIgnore, bkAll
  );

  { TCssBitBtn — a TCssButton with TBitBtn-like glyph support.

    Glyph source priority (highest first):
      1. Kind <> bkCustom       — standard glyph + standard caption
      2. Images + ImageIndex    — from a TImageList
      3. Glyph                  — user bitmap, split into NumGlyphs states

    NumGlyphs splits the source bitmap vertically:
      1 = normal
      2 = normal, disabled
      3 = normal, disabled, clicked
      4 = normal, disabled, clicked, down

    GlyphScaled stretches the glyph by the current DPI scale. The Kind
    glyph is always DPI-scaled automatically.

    Presentation (glyph layout, spacing, margin) is controlled exclusively
    through CSS, so that the same theme stays consistent across DPI values:

      glyph-layout:  left | right | top | bottom
      glyph-spacing: <length>        (DPI-aware)
      glyph-margin:  <length> | auto (DPI-aware; `auto` uses CSS padding)

    The current resolved values are readable via the public GlyphLayout,
    GlyphSpacing, and GlyphMargin properties. }
  TCssBitBtn = class(TCssButton)
  private
    FGlyph: TBitmap;
    FKindGlyph: TBitmap;
    FKindGlyphDisabled: TBitmap;
    FNumGlyphs: Integer;
    FKind: TCssBitBtnKind;

    FImages: TCustomImageList;
    FSvgImages: TCssSvgImgList;
    FImageIndex: Integer;
    FImageIndexDisabled: Integer;
    FImageIndexPressed: Integer;
    FImageIndexFocused: Integer;

    FTransparent: Boolean;
    FGlyphScaled: Boolean;

    // CSS-driven presentation (device pixels after scaling)
    FGlyphLayout: TCssButtonLayout;
    FGlyphSpacing: Integer;   // device px
    FGlyphMargin: Integer;    // device px; < 0 means "use CSS padding"

    FSettingKindCaption: Boolean;

    FScaledGlyphs: array[0..7] of TBitmap;
    FScaledGlyphValid: array[0..7] of Boolean;

    FUseKindCaption: Boolean;

    // setters
    procedure SetGlyph(AValue: TBitmap);
    procedure SetNumGlyphs(AValue: Integer);
    procedure SetKind(AValue: TCssBitBtnKind);
    procedure SetImages(AValue: TCustomImageList);
    procedure SetSvgImages(AValue: TCssSvgImgList);
    procedure SetImageIndex(AValue: Integer);
    procedure SetImageIndexDisabled(AValue: Integer);
    procedure SetImageIndexPressed(AValue: Integer);
    procedure SetImageIndexFocused(AValue: Integer);
    procedure SetTransparent(AValue: Boolean);
    procedure SetGlyphScaled(AValue: Boolean);

    procedure GlyphChanged(Sender: TObject);
    procedure ApplyGlyphTransparency;

    procedure InvalidateScaledGlyphs;
    procedure RegenerateKindGlyph;

    function  KindToCaption(AKind: TCssBitBtnKind): string;

    function  UsesKindGlyph: Boolean;
    function  HasGlyph: Boolean;
    function  GetSourceGlyphCount: Integer;
    function  GetDisplayGlyphSize: TSize;
    function  GetGlyphStateIndex: Integer;

    function  GetEffectiveMargin: Integer;
    function  GetCaptionSize: TSize;
    procedure DrawGlyphAndCaption(ACanvas: TCanvas; const ARect: TRect);
    procedure DrawCaptionAt(ACanvas: TCanvas; const ARect: TRect);

    procedure DrawAALine(ABmp: TBitmap; X1, Y1, X2, Y2: Double;
      AColor: TColor; ALineWidth: Double);
    procedure DrawKindArc(ABmp: TBitmap; CX, CY, R: Double;
      AStartDeg, AEndDeg: Double; AColor: TColor; ALineWidth: Double);
    procedure DrawKindGlyph(ABmp: TBitmap; AKind: TCssBitBtnKind; ASize: Integer);
    procedure SetUseKindCaption(AValue: Boolean);

    procedure MakeDisabledBitmap(ABitmap: TBitmap; ATransparentColor, ATextColor: TColor);
    procedure MakeDisabledBitmapAlpha(ABitmap: TBitmap; ATextColor: TColor);
    function  GetScaledGlyphForState(AState: Integer; ADisabled: Boolean): TBitmap;

    function  ImageIndexForState(AState: Integer): Integer;
    function  HasAnyValidImageIndex: Boolean;
    procedure DrawBitmapWithAlpha(ACanvas: TCanvas; AX, AY: Integer; ABmp: TBitmap);

    function  GetEffectiveSvgVariant: string;
    procedure MakeChromaTransparent(ABitmap: TBitmap; AChromaColor: TColor);
  protected
    procedure SetCaption(const AValue: TCaption); override;
    procedure Loaded; override;
    procedure ChangeScale(M, D: Integer); override;
    procedure StyleChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    function  ShouldPaintCaption: Boolean; override;
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function  GetDefaultCaption: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   AdjustSize; override;

    // Current effective values, as resolved from CSS.
    // Configure them through the `glyph-*` CSS properties, not at design time.
    property GlyphLayout: TCssButtonLayout read FGlyphLayout;
    property GlyphSpacing: Integer read FGlyphSpacing;
    property GlyphMargin: Integer read FGlyphMargin;
  published
    property Glyph: TBitmap read FGlyph write SetGlyph;
    property NumGlyphs: Integer read FNumGlyphs write SetNumGlyphs default 1;
    property Kind: TCssBitBtnKind read FKind write SetKind default bkCustom;

    property Images: TCustomImageList read FImages write SetImages;
    property SvgImages: TCssSvgImgList read FSvgImages write SetSvgImages;

    property ImageIndex: Integer
      read FImageIndex write SetImageIndex default -1;
    property ImageIndexDisabled: Integer
      read FImageIndexDisabled write SetImageIndexDisabled default -1;
    property ImageIndexPressed: Integer
      read FImageIndexPressed write SetImageIndexPressed default -1;
    property ImageIndexFocused: Integer
      read FImageIndexFocused write SetImageIndexFocused default -1;

    property Transparent: Boolean read FTransparent write SetTransparent default True;
    property GlyphScaled: Boolean read FGlyphScaled write SetGlyphScaled default False;
    property UseKindCaption: Boolean read FUseKindCaption write SetUseKindCaption default True;

    property Default;
    property Cancel;
    property ModalResult;
    property AutoSize;
    property Caption;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  Math, IntfGraphics, FPImage;

// ============================================================================
//  TCssBitBtn
// ============================================================================

constructor TCssBitBtn.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);

  FGlyph := TBitmap.Create;
  FGlyph.OnChange := @GlyphChanged;

  FKindGlyph := TBitmap.Create;
  FKindGlyphDisabled := TBitmap.Create;

  for I := 0 to High(FScaledGlyphs) do
  begin
    FScaledGlyphs[I] := TBitmap.Create;
    FScaledGlyphValid[I] := False;
  end;

  FNumGlyphs := 1;
  FKind := bkCustom;
  FSvgImages := nil;
  FImageIndex := -1;
  FImageIndexDisabled := -1;
  FImageIndexPressed := -1;
  FImageIndexFocused := -1;
  FTransparent := True;
  FGlyphScaled := False;

  FSettingKindCaption := False;
  FUseKindCaption := True;

  // Presentation defaults come from ResetStyle, which the base constructor
  // already called once. We only need to refresh derived glyphs here.
  ApplyGlyphTransparency;
end;

destructor TCssBitBtn.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FScaledGlyphs) do
    FreeAndNil(FScaledGlyphs[I]);

  if FGlyph <> nil then
  begin
    FGlyph.OnChange := nil;
    FreeAndNil(FGlyph);
  end;

  FreeAndNil(FKindGlyph);
  FreeAndNil(FKindGlyphDisabled);

  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  if FImages <> nil then
    FImages.RemoveFreeNotification(Self);

  inherited Destroy;
end;

procedure TCssBitBtn.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FImages then
    begin
      FImages := nil;
      InvalidateScaledGlyphs;
      if AutoSize then AdjustSize;
      Invalidate;
    end
    else if AComponent = FSvgImages then
    begin
      FSvgImages := nil;
      InvalidateScaledGlyphs;
      if AutoSize then AdjustSize;
      Invalidate;
    end;
  end;
end;

function TCssBitBtn.GetDefaultCaption : string;
begin
  Result := 'CssBitBtn';
end;

procedure TCssBitBtn.ApplyGlyphTransparency;
begin
  if FGlyph = nil then Exit;

  if FTransparent then
  begin
    FGlyph.Transparent := True;
    FGlyph.TransparentMode := tmAuto;
  end
  else
    FGlyph.Transparent := False;
end;

procedure TCssBitBtn.GlyphChanged(Sender: TObject);
begin
  ApplyGlyphTransparency;
  InvalidateScaledGlyphs;

  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.InvalidateScaledGlyphs;
var
  I: Integer;
begin
  for I := 0 to High(FScaledGlyphs) do
    FScaledGlyphValid[I] := False;
end;

procedure TCssBitBtn.SetGlyph(AValue: TBitmap);
begin
  if AValue = nil then
  begin
    if FGlyph.Empty then Exit;
    FGlyph.Clear;
    Exit;
  end;

  // Mirror TBitBtn: assigning a custom glyph switches to bkCustom.
  if (not AValue.Empty) and (FKind <> bkCustom) then
  begin
    FKind := bkCustom;
    FKindGlyph.Clear;
  end;

  FGlyph.Assign(AValue);
end;

procedure TCssBitBtn.SetNumGlyphs(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if AValue > 4 then AValue := 4;
  if FNumGlyphs = AValue then Exit;
  FNumGlyphs := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

function TCssBitBtn.KindToCaption(AKind: TCssBitBtnKind): string;
begin
  case AKind of
    bkOK:     Result := 'OK';
    bkCancel: Result := 'Cancel';
    bkHelp:   Result := 'Help';
    bkYes:    Result := 'Yes';
    bkNo:     Result := 'No';
    bkClose:  Result := 'Close';
    bkAbort:  Result := 'Abort';
    bkRetry:  Result := 'Retry';
    bkIgnore: Result := 'Ignore';
    bkAll:    Result := 'All';
  else
    Result := '';
  end;
end;

procedure TCssBitBtn.RegenerateKindGlyph;
var
  Size: Integer;
begin
  if FKindGlyph = nil then Exit;
  if FKindGlyphDisabled = nil then Exit;

  FKindGlyph.Transparent := False;
  FKindGlyph.Clear;

  FKindGlyphDisabled.Transparent := False;
  FKindGlyphDisabled.Clear;

  if FKind = bkCustom then
    Exit;

  Size := ScaleForDpi(16);
  if Size < 8 then Size := 8;

  // ---- Enabled variant ------------------------------------------------
  FKindGlyph.PixelFormat := pf32bit;
  FKindGlyph.SetSize(Size, Size);

  FKindGlyph.Canvas.Brush.Style := bsSolid;
  FKindGlyph.Canvas.Brush.Color := clFuchsia;
  FKindGlyph.Canvas.FillRect(0, 0, Size, Size);

  DrawKindGlyph(FKindGlyph, FKind, Size);

  // Fuchsia -> alpha = 0. After this the bitmap has a real alpha channel
  // and no chroma key remains.
  MakeChromaTransparent(FKindGlyph, clFuchsia);

  FKindGlyph.Transparent     := False;
  FKindGlyph.TransparentMode := tmAuto;
  FKindGlyph.TransparentColor := clNone;

  // ---- Disabled variant ----------------------------------------------
  FKindGlyphDisabled.PixelFormat := pf32bit;
  FKindGlyphDisabled.SetSize(Size, Size);

  FKindGlyphDisabled.Canvas.Brush.Style := bsSolid;
  FKindGlyphDisabled.Canvas.Brush.Color := clFuchsia;
  FKindGlyphDisabled.Canvas.FillRect(0, 0, Size, Size);

  DrawKindGlyph(FKindGlyphDisabled, FKind, Size);

  // Same chroma key, then desaturate - alpha-preserving version, so
  // the transparent background stays transparent.
  MakeChromaTransparent(FKindGlyphDisabled, clFuchsia);
  MakeDisabledBitmapAlpha(FKindGlyphDisabled, GetEffectiveTextColor);

  FKindGlyphDisabled.Transparent     := False;
  FKindGlyphDisabled.TransparentMode := tmAuto;
  FKindGlyphDisabled.TransparentColor := clNone;
end;

procedure TCssBitBtn.SetKind(AValue: TCssBitBtnKind);
begin
  if FKind = AValue then Exit;
  FKind := AValue;

  // Only auto-set the caption when the user has not supplied their own.
  if (FKind <> bkCustom) and FUseKindCaption then
  begin
    FSettingKindCaption := True;
    try
      Caption := KindToCaption(FKind);
    finally
      FSettingKindCaption := False;
    end;
  end;

  if csDestroying in ComponentState then
    Exit;

  RegenerateKindGlyph;
  InvalidateScaledGlyphs;

  if AutoSize then AdjustSize;
  Invalidate;

  if csDesigning in ComponentState then
  begin
    if Parent <> nil then
      Parent.Update
    else
      Update;
  end;
end;

procedure TCssBitBtn.SetImages(AValue: TCustomImageList);
begin
  if FImages = AValue then Exit;

  if FImages <> nil then
    FImages.RemoveFreeNotification(Self);

  FImages := AValue;

  if FImages <> nil then
    FImages.FreeNotification(Self);

  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetSvgImages(AValue: TCssSvgImgList);
begin
  if FSvgImages = AValue then Exit;

  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  FSvgImages := AValue;

  if FSvgImages <> nil then
    FSvgImages.FreeNotification(Self);

  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetImageIndex(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FImageIndex = AValue then Exit;
  FImageIndex := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetImageIndexDisabled(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FImageIndexDisabled = AValue then Exit;
  FImageIndexDisabled := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetImageIndexPressed(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FImageIndexPressed = AValue then Exit;
  FImageIndexPressed := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetImageIndexFocused(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FImageIndexFocused = AValue then Exit;
  FImageIndexFocused := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCssBitBtn.SetTransparent(AValue: Boolean);
begin
  if FTransparent = AValue then Exit;
  FTransparent := AValue;
  ApplyGlyphTransparency;
  Invalidate;
end;

procedure TCssBitBtn.SetGlyphScaled(AValue: Boolean);
begin
  if FGlyphScaled = AValue then Exit;
  FGlyphScaled := AValue;
  InvalidateScaledGlyphs;
  if AutoSize then AdjustSize;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  CSS integration
// ---------------------------------------------------------------------------

procedure TCssBitBtn.ResetStyle;
begin
  // Design-time default for spacing is 4 px, scaled to the current DPI.
  // Margin uses the sentinel -1 = "auto" (fall back to CSS padding).
  FGlyphLayout  := blGlyphLeft;
  FGlyphSpacing := ScaleForDpi(4);
  FGlyphMargin  := -1;

  InvalidateScaledGlyphs;

  inherited ResetStyle;
end;

procedure TCssBitBtn.ApplyDeclaration(const AName, AValue: string);
var
  Px: Integer;
  S: string;
begin
  if AValue = '' then
    Exit;

  if AName = 'glyph-layout' then
  begin
    S := LowerCase(Trim(AValue));
    if      S = 'left'   then FGlyphLayout := blGlyphLeft
    else if S = 'right'  then FGlyphLayout := blGlyphRight
    else if S = 'top'    then FGlyphLayout := blGlyphTop
    else if S = 'bottom' then FGlyphLayout := blGlyphBottom
    else
      Exit;   // Unknown keyword: leave the current value untouched.

    Exit;
  end;

  if AName = 'glyph-spacing' then
  begin
    // ParseCssLengthPx already multiplies by FScaleFactor, so the stored
    // value is device pixels — HiDPI-aware.
    if ParseCssLengthPx(AValue, Px) then
      FGlyphSpacing := Px;
    Exit;
  end;

  if AName = 'glyph-margin' then
  begin
    S := LowerCase(Trim(AValue));
    if (S = 'auto') or (S = 'none') then
    begin
      FGlyphMargin := -1;
      Exit;
    end;

    if ParseCssLengthPx(AValue, Px) then
      FGlyphMargin := Px;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

// ---------------------------------------------------------------------------
//  Glyph source resolution
// ---------------------------------------------------------------------------

function TCssBitBtn.UsesKindGlyph: Boolean;
begin
  Result := (FKind <> bkCustom) and (FKindGlyph <> nil) and (not FKindGlyph.Empty);
end;

function TCssBitBtn.HasGlyph: Boolean;
begin
  if UsesKindGlyph then
    Exit(True);

  // Image-list sources take priority over the raw Glyph bitmap.
  // Either SvgImages or Images can provide the bitmap; the actual
  // choice is made in GetScaledGlyphForState.
  if ((FSvgImages <> nil) or (FImages <> nil)) and HasAnyValidImageIndex then
    Exit(True);

  Result := (FGlyph <> nil) and (not FGlyph.Empty);
end;

function TCssBitBtn.GetSourceGlyphCount: Integer;
begin
  if UsesKindGlyph then
    Exit(1);

  if ((FSvgImages <> nil) or (FImages <> nil)) and HasAnyValidImageIndex then
    Exit(1);

  if FNumGlyphs < 1 then Result := 1
  else if FNumGlyphs > 4 then Result := 4
  else Result := FNumGlyphs;
end;

function TCssBitBtn.GetDisplayGlyphSize: TSize;
var
  Src: TSize;
  F: Double;
  Idx: Integer;
begin
  Result.cx := 0;
  Result.cy := 0;

  if UsesKindGlyph then
  begin
    Result.cx := FKindGlyph.Width;
    Result.cy := FKindGlyph.Height;
    Exit;
  end;

  Idx := ImageIndexForState(GetGlyphStateIndex);

  if (FSvgImages <> nil) and (Idx >= 0) then
  begin
    // SvgImages already accounts for its own Scaled property.
    Src.cx := FSvgImages.GetEffectiveWidth;
    Src.cy := FSvgImages.GetEffectiveHeight;
  end
  else if (FImages <> nil) and (Idx >= 0) then
  begin
    Src.cx := FImages.Width;
    Src.cy := FImages.Height;
  end
  else if (FGlyph <> nil) and (not FGlyph.Empty) then
  begin
    Src.cx := FGlyph.Width;
    Src.cy := FGlyph.Height div GetSourceGlyphCount;
  end
  else
    Exit;

  if FGlyphScaled then
  begin
    F := ScaleFactor;
    if F <= 0 then F := 1;
    Result.cx := Round(Src.cx * F);
    Result.cy := Round(Src.cy * F);
  end
  else
  begin
    Result.cx := Src.cx;
    Result.cy := Src.cy;
  end;
end;

function TCssBitBtn.GetGlyphStateIndex: Integer;
var
  Count: Integer;
begin
  Count := GetSourceGlyphCount;

  if not Enabled then
  begin
    if Count >= 2 then Exit(1) else Exit(0);
  end;

  if GetMousePressedState then
  begin
    if Count >= 3 then Exit(2)
    else if Count >= 2 then Exit(1)
    else Exit(0);
  end;

  if GetFocusedState and (Count >= 4) then
    Exit(3);

  Result := 0;
end;

// ---------------------------------------------------------------------------
//  Layout helpers
// ---------------------------------------------------------------------------

function TCssBitBtn.GetEffectiveMargin: Integer;
var
  P: TRect;
begin
  if FGlyphMargin >= 0 then
    Exit(FGlyphMargin);

  // Sentinel: use the smallest side of the CSS padding.
  P := GetCssPadding;

  Result := P.Left;
  if P.Top    < Result then Result := P.Top;
  if P.Right  < Result then Result := P.Right;
  if P.Bottom < Result then Result := P.Bottom;
  if Result < 0 then Result := 0;
end;

function TCssBitBtn.GetCaptionSize: TSize;
begin
  if Caption = '' then
  begin
    Result.cx := 0;
    Result.cy := 0;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  if HtmlMode then
    Result := MeasureHtmlTextSize(Canvas, Caption, 0)
  else
  begin
    Result.cx := Canvas.TextWidth(Caption);
    Result.cy := Canvas.TextHeight('Ag');
  end;
end;

procedure TCssBitBtn.DrawCaptionAt(ACanvas: TCanvas; const ARect: TRect);
begin
  if Caption = '' then
    Exit;

  if HtmlMode then
  begin
    DrawHtmlTextWithAlign(ACanvas, ARect, Caption, ctaLeft, cvaTop,
      GetCssTextColor);
    Exit;
  end;

  // Do NOT use SetTextAlign / SetVAlign here. Their setters call
  // Invalidate, and this method runs from inside Paint — that would
  // schedule another paint and loop forever (paint -> invalidate -> paint).
  // DrawStyledTextWithAlign changes the alignment fields directly and
  // restores them afterwards, without touching Invalidate.
  DrawStyledTextWithAlign(ACanvas, ARect, Caption, ctaLeft, cvaTop);
end;

// ============================================================================
//  Anti-aliased glyph rasterizers
// ============================================================================

{ Renders a single line segment with anti-aliased edges into ABmp.
  Uses per-pixel signed distance to the segment, then blends through
  the destination canvas (BlendCoverageToCanvas handles the alpha). }
procedure TCssBitBtn.DrawAALine(ABmp: TBitmap; X1, Y1, X2, Y2: Double;
  AColor: TColor; ALineWidth: Double);
var
  MinX, MaxX, MinY, MaxY: Integer;
  LX, LY, Idx: Integer;
  W, H: Integer;
  Coverage: array of Byte;
  DX, DY, LenSq, T, CX, CY, PX, PY, Dist, Cov, Half: Double;
begin
  if ABmp = nil then Exit;
  if AColor = clNone then Exit;

  Half := ALineWidth / 2;

  MinX := Floor(Min(X1, X2) - Half - 1);
  MaxX := Ceil (Max(X1, X2) + Half + 1);
  MinY := Floor(Min(Y1, Y2) - Half - 1);
  MaxY := Ceil (Max(Y1, Y2) + Half + 1);

  if MinX < 0              then MinX := 0;
  if MinY < 0              then MinY := 0;
  if MaxX >= ABmp.Width    then MaxX := ABmp.Width  - 1;
  if MaxY >= ABmp.Height   then MaxY := ABmp.Height - 1;
  if (MinX > MaxX) or (MinY > MaxY) then Exit;

  W := MaxX - MinX + 1;
  H := MaxY - MinY + 1;
  SetLength(Coverage, W * H);

  DX := X2 - X1;
  DY := Y2 - Y1;
  LenSq := DX * DX + DY * DY;

  for LY := MinY to MaxY do
    for LX := MinX to MaxX do
    begin
      if LenSq > 1E-9 then
      begin
        T := ((LX + 0.5 - X1) * DX + (LY + 0.5 - Y1) * DY) / LenSq;
        if T < 0 then T := 0 else if T > 1 then T := 1;

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
      if Cov <= 0 then Continue;
      if Cov > 1 then Cov := 1;

      Idx := (LY - MinY) * W + (LX - MinX);
      Coverage[Idx] := Round(Cov * 255);
    end;

  BlendCoverageToCanvas(ABmp.Canvas, MinX, MinY, W, H, Coverage, AColor);
end;

{ Renders an anti-aliased circular arc between two angles (degrees).
  Screen coordinates: X right, Y down; 0° points right, angles grow
  clockwise on the screen. }
procedure TCssBitBtn.DrawKindArc(ABmp: TBitmap; CX, CY, R: Double;
  AStartDeg, AEndDeg: Double; AColor: TColor; ALineWidth: Double);
const
  SEGMENTS = 16;
var
  I: Integer;
  A1, A2, X1, Y1, X2, Y2: Double;
begin
  for I := 0 to SEGMENTS - 1 do
  begin
    A1 := (AStartDeg + (AEndDeg - AStartDeg) * I / SEGMENTS) * Pi / 180;
    A2 := (AStartDeg + (AEndDeg - AStartDeg) * (I + 1) / SEGMENTS) * Pi / 180;

    X1 := CX + R * Cos(A1);
    Y1 := CY + R * Sin(A1);
    X2 := CX + R * Cos(A2);
    Y2 := CY + R * Sin(A2);

    DrawAALine(ABmp, X1, Y1, X2, Y2, AColor, ALineWidth);
  end;
end;

{ Draws one standard "Kind" glyph into ABmp, using anti-aliased
  primitives from TCssStyledControl. Background is fuchsia so that
  TransparentColor picks it up as transparent. }
procedure TCssBitBtn.DrawKindGlyph(ABmp: TBitmap; AKind: TCssBitBtnKind;
  ASize: Integer);
var
  S, PenW: Double;
  Green, Red, Blue, Gray: TColor;
  BgCol: TColor;
begin
  S := ASize;
  PenW := S / 9;
  if PenW < 1 then PenW := 1;

  Green := RGBToColor(22, 163, 74);
  Red   := RGBToColor(220, 38, 38);
  Blue  := RGBToColor(37, 99, 235);
  Gray  := RGBToColor(71, 85, 105);
  BgCol := clFuchsia;

  case AKind of
    bkOK, bkYes:
      DrawAntiAliasedCheckMark(ABmp.Canvas,
        Rect(0, 0, ASize, ASize), Green);

    bkCancel, bkNo:
      begin
        DrawAALine(ABmp, S*0.25, S*0.25, S*0.75, S*0.75, Red, PenW * 1.5);
        DrawAALine(ABmp, S*0.75, S*0.25, S*0.25, S*0.75, Red, PenW * 1.5);
      end;

    bkClose:
      begin
        DrawAALine(ABmp, S*0.25, S*0.25, S*0.75, S*0.75, Gray, PenW * 1.5);
        DrawAALine(ABmp, S*0.75, S*0.25, S*0.25, S*0.75, Gray, PenW * 1.5);
      end;

    bkHelp:
      begin
        DrawAntiAliasedCircle(ABmp.Canvas,
          Rect(Round(S * 0.10), Round(S * 0.10),
               Round(S * 0.90), Round(S * 0.90)),
          Blue, Blue, 0, BgCol);

        // "?" — top hook (arc from 180° to 360° through the top)
        DrawKindArc(ABmp, S * 0.50, S * 0.42, S * 0.17,
          180, 360, clWhite, PenW * 1.4);

        // "?" — diagonal stem from the right end of the arc down to centre
        DrawAALine(ABmp, S * 0.67, S * 0.42, S * 0.50, S * 0.60,
          clWhite, PenW * 1.4);

        // "?" — dot
        DrawAntiAliasedCircle(ABmp.Canvas,
          Rect(Round(S * 0.44), Round(S * 0.70),
               Round(S * 0.56), Round(S * 0.82)),
          clWhite, clWhite, 0, BgCol);
      end;

    bkAbort:
      begin
        DrawAntiAliasedCircle(ABmp.Canvas,
          Rect(Round(S * 0.12), Round(S * 0.12),
               Round(S * 0.88), Round(S * 0.88)),
          Red, Red, 0, BgCol);

        DrawAALine(ABmp, S * 0.30, S * 0.50, S * 0.70, S * 0.50,
          clWhite, PenW + 1);
      end;

    bkRetry:
      begin
        // Circular arc with a gap at the top-right
        DrawKindArc(ABmp, S * 0.50, S * 0.50, S * 0.32,
          -45, 225, Blue, PenW + 1);

        // Arrowhead pointing right in the gap
        DrawAntiAliasedTriangle(ABmp.Canvas,
          Point(Round(S * 0.55), Round(S * 0.10)),
          Point(Round(S * 0.85), Round(S * 0.30)),
          Point(Round(S * 0.50), Round(S * 0.42)),
          Blue, BgCol);
      end;

    bkIgnore:
      begin
        // Rectangle body
        DrawAntiAliasedRoundedBox(ABmp.Canvas,
          Rect(Round(S * 0.15), Round(S * 0.38),
               Round(S * 0.55), Round(S * 0.62)),
          0, Blue, clNone, 0, cbsNone, BgCol);

        // Triangle head
        DrawAntiAliasedTriangle(ABmp.Canvas,
          Point(Round(S * 0.50), Round(S * 0.18)),
          Point(Round(S * 0.88), Round(S * 0.50)),
          Point(Round(S * 0.50), Round(S * 0.82)),
          Blue, BgCol);
      end;

    bkAll:
      begin
        // Two overlapping checkmarks
        DrawAntiAliasedCheckMark(ABmp.Canvas,
          Rect(0, Round(S * 0.15), Round(S * 0.70), Round(S * 0.90)),
          Green);

        DrawAntiAliasedCheckMark(ABmp.Canvas,
          Rect(Round(S * 0.35), Round(S * 0.15), ASize, Round(S * 0.90)),
          Green);
      end;
  end;
end;

procedure TCssBitBtn.SetCaption(const AValue: TCaption);
begin
  // Any caption assignment that does NOT come from inside SetKind is
  // treated as user-provided. If it matches the caption the current Kind
  // would generate, we keep treating it as "auto" (this makes LFM
  // streaming safe: the .lfm contains Caption = 'OK' alongside Kind = bkOK).
  if not FSettingKindCaption then
  begin
    if (FKind = bkCustom) or (AValue <> KindToCaption(FKind)) then
      FUseKindCaption := False;
  end;

  inherited SetCaption(AValue);
end;

procedure TCssBitBtn.SetUseKindCaption(AValue: Boolean);
begin
  if FUseKindCaption = AValue then Exit;
  FUseKindCaption := AValue;

  // Turning the flag on means "show the caption from Kind right now".
  if FUseKindCaption and (FKind <> bkCustom) then
  begin
    FSettingKindCaption := True;
    try
      Caption := KindToCaption(FKind);
    finally
      FSettingKindCaption := False;
    end;
  end;

  if AutoSize then AdjustSize;
  Invalidate;
end;

{ Desaturates and re-tints all non-transparent pixels of ABitmap so that
  a disabled glyph visually matches the disabled caption.

  The algorithm:
    1. full desaturation to grayscale (luma-weighted);
    2. contrast compression around mid-gray, so bright/dark spots of the
       original icon lose most of their "pop";
    3. heavy blend toward ATextColor — the effective text color that
       CSS currently provides for the :disabled state.

  As a result the icon takes on the same muted tone as the caption, with
  just enough luminance variation left to keep the shape readable. }
procedure TCssBitBtn.MakeDisabledBitmap(ABitmap: TBitmap;
  ATransparentColor, ATextColor: TColor);
const
  // How much of the original contrast survives (0 = flat, 100 = untouched).
  CONTRAST_KEEP = 70;
  // How much of the final color comes from the text color
  // (100 = text color only, 0 = just gray).
  TEXT_BLEND = 60;
var
  X, Y, W, H: Integer;
  Col: TColor;
  R, G, B, Gray, Compressed: Integer;
  TR, TG, TB_: Integer;
begin
  if ABitmap = nil then Exit;
  if ABitmap.Empty then Exit;

  TR := ATextColor and $FF;
  TG := (ATextColor shr 8) and $FF;
  TB_ := (ATextColor shr 16) and $FF;

  W := ABitmap.Width;
  H := ABitmap.Height;

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Col := ABitmap.Canvas.Pixels[X, Y];

      if Col = ATransparentColor then
        Continue;

      // TColor layout in LCL: $00BBGGRR
      R := Col and $FF;
      G := (Col shr 8) and $FF;
      B := (Col shr 16) and $FF;

      // 1. Full desaturation (luma weighted).
      Gray := (R * 30 + G * 59 + B * 11) div 100;

      // 2. Contrast compression around mid-gray.
      Compressed := 128 + ((Gray - 128) * CONTRAST_KEEP) div 100;
      if Compressed < 0 then Compressed := 0;
      if Compressed > 255 then Compressed := 255;

      // 3. Blend the compressed gray with the disabled text color.
      R := (Compressed * (100 - TEXT_BLEND) + TR * TEXT_BLEND) div 100;
      G := (Compressed * (100 - TEXT_BLEND) + TG * TEXT_BLEND) div 100;
      B := (Compressed * (100 - TEXT_BLEND) + TB_ * TEXT_BLEND) div 100;

      if R < 0 then R := 0 else if R > 255 then R := 255;
      if G < 0 then G := 0 else if G > 255 then G := 255;
      if B < 0 then B := 0 else if B > 255 then B := 255;

      ABitmap.Canvas.Pixels[X, Y] := RGBToColor(R, G, B);
    end;
end;

{ Alpha-aware desaturation, modifies ABitmap in place.

  Only pixels with alpha > 0 are touched, and the alpha channel itself is
  preserved. This is the SVG-safe counterpart of MakeDisabledBitmap: for
  SvgImages the shape is stored as pf32bit with real per-pixel alpha, so
  copying to pf24bit (as MakeDisabledBitmap requires) would turn the
  transparent background into opaque black and produce a visible square. }
procedure TCssBitBtn.MakeDisabledBitmapAlpha(ABitmap: TBitmap;
  ATextColor: TColor);
const
  CONTRAST_KEEP = 70;
  TEXT_BLEND    = 60;
var
  Img: TLazIntfImage;
  X, Y: Integer;
  Pix: TFPColor;
  A, R, G, B, Gray, Compressed: Integer;
  TR, TG, TB_: Integer;
begin
  if ABitmap = nil then Exit;
  if ABitmap.Empty then Exit;

  TR  :=  ATextColor         and $FF;
  TG  := (ATextColor shr  8) and $FF;
  TB_ := (ATextColor shr 16) and $FF;

  Img := ABitmap.CreateIntfImage;
  if Img = nil then Exit;
  try
    for Y := 0 to Img.Height - 1 do
      for X := 0 to Img.Width - 1 do
      begin
        Pix := Img.Colors[X, Y];
        A := Pix.Alpha shr 8;
        if A = 0 then
          Continue;  // leave fully transparent pixels alone

        R := Pix.Red   shr 8;
        G := Pix.Green shr 8;
        B := Pix.Blue  shr 8;

        // 1. Full desaturation (luma weighted).
        Gray := (R * 30 + G * 59 + B * 11) div 100;

        // 2. Contrast compression around mid-gray.
        Compressed := 128 + ((Gray - 128) * CONTRAST_KEEP) div 100;
        if Compressed < 0   then Compressed := 0;
        if Compressed > 255 then Compressed := 255;

        // 3. Blend the compressed gray with the disabled text color.
        R := (Compressed * (100 - TEXT_BLEND) + TR  * TEXT_BLEND) div 100;
        G := (Compressed * (100 - TEXT_BLEND) + TG  * TEXT_BLEND) div 100;
        B := (Compressed * (100 - TEXT_BLEND) + TB_ * TEXT_BLEND) div 100;

        if R < 0 then R := 0 else if R > 255 then R := 255;
        if G < 0 then G := 0 else if G > 255 then G := 255;
        if B < 0 then B := 0 else if B > 255 then B := 255;

        Pix.Red   := R * 257;
        Pix.Green := G * 257;
        Pix.Blue  := B * 257;
        // Alpha is preserved as-is.
        Img.Colors[X, Y] := Pix;
      end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

function TCssBitBtn.GetScaledGlyphForState(AState: Integer;
  ADisabled: Boolean): TBitmap;
var
  SrcBitmap: TBitmap;
  SrcRect: TRect;
  SrcSize, DstSize: TSize;
  Bmp: TBitmap;
  Count, SubH, CacheIndex, ImgIdx, RW, RH: Integer;
  TempSrc, TempDisabled: TBitmap;
  TransColor: TColor;
  HasTransparency: Boolean;
  NeedsDesat: Boolean;
  UseSvgList: Boolean;
  UseAlphaCopy: Boolean;
  SrcIntf: TLazIntfImage;
begin
  if (AState < 0) or (AState > 3) then AState := 0;

  // Two halves of the cache: [0..3] enabled, [4..7] disabled.
  CacheIndex := AState + Ord(ADisabled) * 4;

  if FScaledGlyphValid[CacheIndex] and (FScaledGlyphs[CacheIndex] <> nil) then
    Exit(FScaledGlyphs[CacheIndex]);

  TempSrc := nil;
  TempDisabled := nil;
  HasTransparency := False;
  TransColor := clFuchsia;
  NeedsDesat := False;
  UseSvgList := False;
  UseAlphaCopy := False;

  ImgIdx := ImageIndexForState(AState);

  if UsesKindGlyph then
  begin
    // Kind glyphs are pre-rendered as pf32bit with a real alpha channel.
    if ADisabled and (FKindGlyphDisabled <> nil) and
       (not FKindGlyphDisabled.Empty) then
    begin
      SrcBitmap := FKindGlyphDisabled;
      NeedsDesat := False;   // Already desaturated in RegenerateKindGlyph
    end
    else
    begin
      SrcBitmap := FKindGlyph;
      // Fallback: if a dedicated disabled variant was not available,
      // desaturate the enabled one in place (alpha-aware).
      NeedsDesat := ADisabled;
    end;

    SrcRect := Rect(0, 0, SrcBitmap.Width, SrcBitmap.Height);

    HasTransparency := False;
    TransColor := clNone;
    UseAlphaCopy := True;
  end
  else if (FSvgImages <> nil) and
          (ImgIdx >= 0) and (ImgIdx < FSvgImages.Count) then
  begin
    UseSvgList := True;

    RW := FSvgImages.GetEffectiveWidth;
    RH := FSvgImages.GetEffectiveHeight;

    if FGlyphScaled then
    begin
      RW := Round(RW * ScaleFactor);
      RH := Round(RH * ScaleFactor);
    end;

    if (RW < 1) or (RH < 1) then
      Exit(nil);

    TempSrc := FSvgImages.GetBitmap(ImgIdx, RW, RH, GetEffectiveTextColor,
      GetEffectiveSvgVariant);

    if TempSrc = nil then
      Exit(nil);

    SrcBitmap := TempSrc;
    SrcRect := Rect(0, 0, SrcBitmap.Width, SrcBitmap.Height);
    HasTransparency := False;
    TransColor := clNone;

    NeedsDesat := ADisabled and (FImageIndexDisabled < 0);
    UseAlphaCopy := True;
  end
  else if (FImages <> nil) and
          (ImgIdx >= 0) and (ImgIdx < FImages.Count) then
  begin
    TempSrc := TBitmap.Create;
    TempSrc.PixelFormat := pf24bit;
    TempSrc.SetSize(FImages.Width, FImages.Height);

    TempSrc.Canvas.Brush.Style := bsSolid;
    TempSrc.Canvas.Brush.Color := clFuchsia;
    TempSrc.Canvas.FillRect(0, 0, TempSrc.Width, TempSrc.Height);

    FImages.GetBitmap(ImgIdx, TempSrc);

    SrcBitmap := TempSrc;
    SrcRect := Rect(0, 0, SrcBitmap.Width, SrcBitmap.Height);
    HasTransparency := True;
    TransColor := clFuchsia;

    NeedsDesat := ADisabled and (FImageIndexDisabled < 0);
  end
  else if (FGlyph <> nil) and (not FGlyph.Empty) then
  begin
    SrcBitmap := FGlyph;
    Count := GetSourceGlyphCount;
    SubH := SrcBitmap.Height div Count;
    if SubH < 1 then SubH := SrcBitmap.Height;

    if AState >= Count then AState := 0;

    SrcRect := Rect(0, AState * SubH,
                    SrcBitmap.Width, AState * SubH + SubH);

    if SrcBitmap.Transparent then
    begin
      HasTransparency := True;
      TransColor := SrcBitmap.TransparentColor;
    end;

    NeedsDesat := ADisabled and (Count < 2);
  end
  else
    Exit(nil);

  try
    if NeedsDesat then
    begin
      if UseSvgList or UseAlphaCopy then
      begin
        { Alpha-aware desaturation: works in place, preserves alpha,
          so no chroma key is needed for the result. }
        MakeDisabledBitmapAlpha(TempSrc, GetEffectiveTextColor);
        NeedsDesat := False;
      end
      else
      begin
        TempDisabled := TBitmap.Create;
        TempDisabled.PixelFormat := pf24bit;
        TempDisabled.SetSize(SrcRect.Right - SrcRect.Left,
                             SrcRect.Bottom - SrcRect.Top);

        TempDisabled.Canvas.Brush.Style := bsSolid;
        TempDisabled.Canvas.Brush.Color := TransColor;
        TempDisabled.Canvas.FillRect(0, 0, TempDisabled.Width,
                                          TempDisabled.Height);

        TempDisabled.Canvas.CopyRect(
          Rect(0, 0, TempDisabled.Width, TempDisabled.Height),
          SrcBitmap.Canvas,
          SrcRect);

        if HasTransparency then
        begin
          // TransparentColor before Transparent — the mask is built
          // from the current value when Transparent becomes True.
          TempDisabled.TransparentMode := tmFixed;
          TempDisabled.TransparentColor := TransColor;
          TempDisabled.Transparent := True;
        end;

        MakeDisabledBitmap(TempDisabled, TransColor, GetEffectiveTextColor);

        SrcBitmap := TempDisabled;
        SrcRect := Rect(0, 0, TempDisabled.Width, TempDisabled.Height);

        UseSvgList := False;
        UseAlphaCopy := False;
        HasTransparency := TransColor <> clNone;
      end;
    end;

    SrcSize.cx := SrcRect.Right  - SrcRect.Left;
    SrcSize.cy := SrcRect.Bottom - SrcRect.Top;

    // Kind glyphs and SvgImages return a properly sized bitmap;
    // only the raw Glyph path scales via Canvas.CopyRect.
    if UsesKindGlyph or UseSvgList or UseAlphaCopy then
      DstSize := SrcSize
    else if FGlyphScaled then
    begin
      DstSize.cx := Round(SrcSize.cx * ScaleFactor);
      DstSize.cy := Round(SrcSize.cy * ScaleFactor);
    end
    else
      DstSize := SrcSize;

    if DstSize.cx < 1 then DstSize.cx := 1;
    if DstSize.cy < 1 then DstSize.cy := 1;

    Bmp := FScaledGlyphs[CacheIndex];
    if Bmp = nil then
    begin
      Bmp := TBitmap.Create;
      FScaledGlyphs[CacheIndex] := Bmp;
    end;

    if UseAlphaCopy or UseSvgList then
    begin
      { Alpha-aware copy: pf32bit RGBA is transferred via IntfImage.
        Canvas.CopyRect would lose per-pixel alpha on some widgetsets. }
      Bmp.PixelFormat := pf32bit;
      Bmp.SetSize(SrcBitmap.Width, SrcBitmap.Height);

      SrcIntf := SrcBitmap.CreateIntfImage;
      try
        Bmp.LoadFromIntfImage(SrcIntf);
      finally
        SrcIntf.Free;
      end;

      Bmp.Transparent := False;
    end
    else
    begin
      Bmp.PixelFormat := SrcBitmap.PixelFormat;
      Bmp.SetSize(DstSize.cx, DstSize.cy);

      Bmp.Canvas.CopyRect(
        Rect(0, 0, DstSize.cx, DstSize.cy),
        SrcBitmap.Canvas,
        SrcRect);

      if HasTransparency then
      begin
        // Order matters: color first, flag last.
        Bmp.TransparentMode := tmFixed;
        Bmp.TransparentColor := TransColor;
        Bmp.Transparent := True;
      end
      else
        Bmp.Transparent := False;
    end;

    FScaledGlyphValid[CacheIndex] := True;
    Result := Bmp;
  finally
    if TempSrc <> nil then TempSrc.Free;
    if TempDisabled <> nil then TempDisabled.Free;
  end;
end;

function TCssBitBtn.ImageIndexForState(AState: Integer): Integer;
begin
  case AState of
    1: if FImageIndexDisabled >= 0 then Exit(FImageIndexDisabled);
    2: if FImageIndexPressed  >= 0 then Exit(FImageIndexPressed);
    3: if FImageIndexFocused  >= 0 then Exit(FImageIndexFocused);
  end;
  Result := FImageIndex;
end;

function TCssBitBtn.HasAnyValidImageIndex: Boolean;
begin
  Result :=
    (FImageIndex >= 0) or
    (FImageIndexDisabled >= 0) or
    (FImageIndexPressed >= 0) or
    (FImageIndexFocused >= 0);
end;

{ Draws ABmp onto ACanvas honouring per-pixel alpha.

  Implemented with manual pixel compositing, because:
    - TBitmap.AlphaFormat does not exist in older LCL versions;
    - TLazIntfImage.AlphaBlend has a different signature in older LCL;
    - colTransparent may also be missing.

  For 32x32 button glyphs the per-pixel loop is fast enough. }
procedure TCssBitBtn.DrawBitmapWithAlpha(ACanvas: TCanvas;
  AX, AY: Integer; ABmp: TBitmap);
begin
  DrawSvgBitmapWithAlpha(ACanvas, AX, AY, ABmp);
end;

{ Returns the variant name that the SVG icon should be rendered with.

  Priority:
    1. StyleName of this control, when set;
    2. StyleProvider.DefaultStyleName, when a provider is assigned;
    3. SvgImages.DefaultVariant, for standalone use without CSS;
    4. empty string (base Svg).

  This is what ties TCssSvgImgList variants to the active CSS theme:
  switching DefaultStyleName on the provider immediately changes the
  variant used by every bit button that references it. }
function TCssBitBtn.GetEffectiveSvgVariant: string;
begin
  if StyleProvider <> nil then
  begin
    if Trim(StyleName) <> '' then
      Exit(StyleName);
    Exit(StyleProvider.DefaultStyleName);
  end;

  if FSvgImages <> nil then
    Exit(FSvgImages.DefaultVariant);

  Result := '';
end;

procedure TCssBitBtn.MakeChromaTransparent(ABitmap: TBitmap;
  AChromaColor: TColor);
var
  Img: TLazIntfImage;
  X, Y: Integer;
  Pix: TFPColor;
  ChromaRGB: LongInt;
  CR, CG, CB: Byte;
begin
  if (ABitmap = nil) or ABitmap.Empty then
    Exit;

  ChromaRGB := ColorToRGB(AChromaColor);
  CR :=  ChromaRGB         and $FF;
  CG := (ChromaRGB shr  8) and $FF;
  CB := (ChromaRGB shr 16) and $FF;

  Img := ABitmap.CreateIntfImage;
  try
    for Y := 0 to Img.Height - 1 do
      for X := 0 to Img.Width - 1 do
      begin
        Pix := Img.Colors[X, Y];

        if (Pix.Red   shr 8 = CR) and
           (Pix.Green shr 8 = CG) and
           (Pix.Blue  shr 8 = CB) then
          Pix.Alpha := 0
        else
          Pix.Alpha := $FFFF;

        Img.Colors[X, Y] := Pix;
      end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

procedure TCssBitBtn.DrawGlyphAndCaption(ACanvas: TCanvas; const ARect: TRect);
var
  GlyphBmp: TBitmap;
  GlyphSize, CapSize: TSize;
  Spacing, Margin: Integer;
  TotalW, TotalH: Integer;
  GroupX, GroupY: Integer;
  GlyphX, GlyphY, CapX, CapY: Integer;
  HasCap: Boolean;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
  State: Integer;
  NeedsDesat: Boolean;
begin
  if not HasGlyph then
  begin
    if Caption = '' then Exit;

    if HtmlMode then
      DrawHtmlTextWithAlign(ACanvas, ARect, Caption,
        GetCssTextAlign, GetCssVAlign, GetCssTextColor)
    else
    begin
      AssignCssFontToFont(ACanvas.Font);
      DrawStyledTextToCanvas(ACanvas, ARect, Caption);
    end;
    Exit;
  end;

  State := GetGlyphStateIndex;
  // Only desaturate if the user did not already provide a dedicated
  // disabled sub-glyph (NumGlyphs >= 2 handles that case via state 1).
  NeedsDesat := (not Enabled) and (GetSourceGlyphCount < 2);
  GlyphBmp := GetScaledGlyphForState(State, NeedsDesat);
  if GlyphBmp = nil then
  begin
    if Caption <> '' then
    begin
      AssignCssFontToFont(ACanvas.Font);
      DrawStyledTextToCanvas(ACanvas, ARect, Caption);
    end;
    Exit;
  end;

  GlyphSize.cx := GlyphBmp.Width;
  GlyphSize.cy := GlyphBmp.Height;

  HasCap := Caption <> '';
  if HasCap then
    CapSize := GetCaptionSize
  else
  begin
    CapSize.cx := 0;
    CapSize.cy := 0;
  end;

  Spacing := FGlyphSpacing;
  if not HasCap then
    Spacing := 0;

  case FGlyphLayout of
    blGlyphLeft, blGlyphRight:
      begin
        TotalW := GlyphSize.cx + Spacing + CapSize.cx;
        TotalH := GlyphSize.cy;
        if CapSize.cy > TotalH then TotalH := CapSize.cy;
      end;
  else
    begin
      TotalW := GlyphSize.cx;
      if CapSize.cx > TotalW then TotalW := CapSize.cx;
      TotalH := GlyphSize.cy + Spacing + CapSize.cy;
    end;
  end;

  HAlign := GetCssTextAlign;
  VAlign := GetCssVAlign;
  Margin := GetEffectiveMargin;

  case HAlign of
    ctaLeft:  GroupX := ARect.Left + Margin;
    ctaRight: GroupX := ARect.Right - Margin - TotalW;
  else
    GroupX := ARect.Left + (ARect.Width - TotalW) div 2;
  end;

  case VAlign of
    cvaTop:    GroupY := ARect.Top + Margin;
    cvaBottom: GroupY := ARect.Bottom - Margin - TotalH;
  else
    GroupY := ARect.Top + (ARect.Height - TotalH) div 2;
  end;

  if GroupX < ARect.Left then GroupX := ARect.Left;
  if GroupY < ARect.Top  then GroupY := ARect.Top;

  case FGlyphLayout of
    blGlyphLeft:
      begin
        GlyphX := GroupX;
        GlyphY := GroupY + (TotalH - GlyphSize.cy) div 2;
        CapX := GroupX + GlyphSize.cx + Spacing;
        CapY := GroupY + (TotalH - CapSize.cy) div 2;
      end;
    blGlyphRight:
      begin
        CapX := GroupX;
        CapY := GroupY + (TotalH - CapSize.cy) div 2;
        GlyphX := GroupX + CapSize.cx + Spacing;
        GlyphY := GroupY + (TotalH - GlyphSize.cy) div 2;
      end;
    blGlyphTop:
      begin
        GlyphX := GroupX + (TotalW - GlyphSize.cx) div 2;
        GlyphY := GroupY;
        CapX := GroupX + (TotalW - CapSize.cx) div 2;
        CapY := GroupY + GlyphSize.cy + Spacing;
      end;
    blGlyphBottom:
      begin
        CapX := GroupX + (TotalW - CapSize.cx) div 2;
        CapY := GroupY;
        GlyphX := GroupX + (TotalW - GlyphSize.cx) div 2;
        GlyphY := GroupY + CapSize.cy + Spacing;
      end;
  else
    Exit;
  end;

  if (FSvgImages <> nil) and
     (GlyphBmp <> nil) and
     (GlyphBmp.PixelFormat = pf32bit) then
    DrawBitmapWithAlpha(ACanvas, GlyphX, GlyphY, GlyphBmp)
  else
    ACanvas.Draw(GlyphX, GlyphY, GlyphBmp);

  if HasCap then
    DrawCaptionAt(ACanvas,
      Rect(CapX, CapY, CapX + CapSize.cx, CapY + CapSize.cy));
end;


// ---------------------------------------------------------------------------
//  Lifecycle
// ---------------------------------------------------------------------------

procedure TCssBitBtn.Loaded;
begin
  inherited Loaded;

  RegenerateKindGlyph;
  InvalidateScaledGlyphs;
  ApplyGlyphTransparency;

  if (FKind <> bkCustom) and FUseKindCaption and (Caption = '') then
  begin
    FSettingKindCaption := True;
    try
      Caption := KindToCaption(FKind);
    finally
      FSettingKindCaption := False;
    end;
  end;

  if AutoSize then AdjustSize;
end;

procedure TCssBitBtn.ChangeScale(M, D: Integer);
begin
  inherited ChangeScale(M, D);

  if csDestroying in ComponentState then
    Exit;

  RegenerateKindGlyph;
  InvalidateScaledGlyphs;
  Invalidate;

  if csDesigning in ComponentState then
  begin
    if Parent <> nil then
      Parent.Update
    else
      Update;
  end;
end;

procedure TCssBitBtn.StyleChanged;
begin
  inherited StyleChanged;
  InvalidateScaledGlyphs;

  // The disabled tint color comes from CSS. If the theme (or just the
  // :disabled rule) changed, rebuild the disabled Kind variant so its
  // tint matches the new caption color.
  RegenerateKindGlyph;
end;

function TCssBitBtn.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

procedure TCssBitBtn.Paint;
var
  ContentR: TRect;
begin
  inherited Paint;

  ContentR := GetContentRect;

  if (ContentR.Right <= ContentR.Left) or
     (ContentR.Bottom <= ContentR.Top) then
    Exit;

  DrawGlyphAndCaption(Canvas, ContentR);
end;

// ---------------------------------------------------------------------------
//  Sizing
// ---------------------------------------------------------------------------

procedure TCssBitBtn.AdjustSize;
var
  GlyphSize, CapSize: TSize;
  B: Integer;
  P: TRect;
  NewWidth, NewHeight: Integer;
  Spacing: Integer;
  HasCap: Boolean;
begin
  if (csDestroying in ComponentState) or
     (csLoading in ComponentState) or
     (not AutoSize) or
     (not HandleAllocated) or
     (Align <> alNone) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  if not HasGlyph then
  begin
    inherited AdjustSize;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  B := GetCssBorderWidth;
  P := GetCssPadding;

  GlyphSize := GetDisplayGlyphSize;

  HasCap := Caption <> '';
  if HasCap then
    CapSize := GetCaptionSize
  else
  begin
    CapSize.cx := 0;
    CapSize.cy := 0;
  end;

  Spacing := FGlyphSpacing;
  if not HasCap then
    Spacing := 0;

  case FGlyphLayout of
    blGlyphLeft, blGlyphRight:
      begin
        NewWidth := GlyphSize.cx + Spacing + CapSize.cx;
        NewHeight := GlyphSize.cy;
        if CapSize.cy > NewHeight then NewHeight := CapSize.cy;
      end;
  else
    begin
      NewWidth := GlyphSize.cx;
      if CapSize.cx > NewWidth then NewWidth := CapSize.cx;
      NewHeight := GlyphSize.cy + Spacing + CapSize.cy;
    end;
  end;

  NewWidth  := NewWidth  + (B * 2) + P.Left + P.Right;
  NewHeight := NewHeight + (B * 2) + P.Top  + P.Bottom;

  if NewWidth  < 0 then NewWidth  := 0;
  if NewHeight < 0 then NewHeight := 0;

  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);
end;

end.
