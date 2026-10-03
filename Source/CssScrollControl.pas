unit CssScrollControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  Forms, CssStyledControl;

type
  TCssScrollPart = (
    cspNone,
    cspArrowMinus,
    cspArrowPlus,
    cspThumb,
    cspTrackMinus,
    cspTrackPlus
  );

  TCssScrollBar = class(TCssStyledControl)
  private
    // State
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FPageSize: Integer;
    FSmallChange: Integer;
    FLargeChange: Integer;
    FKind: TScrollBarKind;

    // Event
    FOnChange: TNotifyEvent;

    // Interaction state
    FHoverPart: TCssScrollPart;
    FActivePart: TCssScrollPart;
    FDragging: Boolean;
    FDragStartPixel: Integer;
    FDragStartPos: Integer;

    // Appearance
    FTrackBackground: TColor;
    FTrackBackgroundSet: Boolean;
    FThumbBackground: TColor;
    FThumbBackgroundSet: Boolean;
    FThumbHoverBackground: TColor;
    FThumbHoverBackgroundSet: Boolean;
    FThumbActiveBackground: TColor;
    FThumbActiveBackgroundSet: Boolean;
    FThumbBorderColor: TColor;
    FThumbBorderColorSet: Boolean;
    FThumbRadius: Integer;
    FThumbRadiusSet: Boolean;
    FArrowColor: TColor;
    FArrowColorSet: Boolean;

    // Position helpers
    function ClampPosition(AValue: Integer): Integer;
    procedure DoChange;
    procedure InternalSetPosition(AValue: Integer; Notify: Boolean);

    // Property setters
    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetPageSize(AValue: Integer);
    procedure SetSmallChange(AValue: Integer);
    procedure SetLargeChange(AValue: Integer);
    procedure SetKind(AValue: TScrollBarKind);

    // Geometry
    function GetTrackRect: TRect;
    procedure CalcThumbSizeAndPos(
      AvailableLen: Integer;
      out ThumbSize, ThumbPos: Integer);
    procedure GetScrollRects(
      out TrackR, ArrowMinusR, ArrowPlusR, ThumbR: TRect);
    function GetThumbDragRange: Integer;
    function GetPartAt(X, Y: Integer): TCssScrollPart;

    // Appearance getters
    function GetTrackBackground: TColor;
    function GetThumbBackground: TColor;
    function GetThumbHoverBackground: TColor;
    function GetThumbActiveBackground: TColor;
    function GetThumbBorderColor: TColor;
    function GetThumbRadius: Integer;
    function GetArrowColor: TColor;

    // Drawing (internal canvas)
    procedure DrawArrowGlyph(
      const R: TRect;
      APart: TCssScrollPart;
      AColor: TColor);
    procedure DrawArrowButton(
      const R: TRect;
      APart: TCssScrollPart);

    // Drawing (external canvas)
    procedure DrawArrowGlyphEx(
      ACanvas: TCanvas;
      const R: TRect;
      APart: TCssScrollPart;
      AColor: TColor);
    procedure DrawArrowButtonEx(
      ACanvas: TCanvas;
      const R: TRect;
      APart: TCssScrollPart);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Painting
    procedure Paint; override;

    // Sizing
    procedure Resize; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;

    // Focus
    function GetFocusColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Range parameters
    procedure SetParams(APosition, AMin, AMax: Integer);

    // External mouse forwarding (for child-of-parent scrollbar scenarios)
    function ExternalMouseDown(
      Button: TMouseButton;
      Shift: TShiftState;
      X, Y: Integer): Boolean;
    function ExternalMouseMove(
      Shift: TShiftState;
      X, Y: Integer): Boolean;
    procedure ExternalMouseUp;
    function ExternalMouseLeave: Boolean;

    function IsDragging: Boolean;

    // Drawing to an external canvas
    procedure DrawToCanvas(
      ACanvas: TCanvas;
      const ARect: TRect);
  published
    // Range
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 0;

    // Behavior
    property PageSize: Integer read FPageSize write SetPageSize default 0;
    property SmallChange: Integer read FSmallChange write SetSmallChange default 1;
    property LargeChange: Integer read FLargeChange write SetLargeChange default 10;
    property Kind: TScrollBarKind read FKind write SetKind default sbHorizontal;

    // Focus
    property ShowFocusRect default False;

    // Standard properties
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  CssUtils;

{ TCssScrollBar }

constructor TCssScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := True;

  Width := 200;
  Height := 16;

  ShowFocusRect := False;

  FMin := 0;
  FMax := 100;
  FPosition := 0;

  FPageSize := 0;
  FSmallChange := 1;
  FLargeChange := 10;

  FKind := sbHorizontal;

  FHoverPart := cspNone;
  FActivePart := cspNone;

  FDragging := False;
  FDragStartPixel := 0;
  FDragStartPos := 0;
end;

destructor TCssScrollBar.Destroy;
begin
  inherited Destroy;
end;

procedure TCssScrollBar.Loaded;
begin
  inherited Loaded;

  Invalidate;
end;

procedure TCssScrollBar.StyleChanged;
begin
  inherited StyleChanged;

  Invalidate;
end;

procedure TCssScrollBar.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  Invalidate;
end;

procedure TCssScrollBar.ResetStyle;
begin
  FTrackBackgroundSet := False;
  FThumbBackgroundSet := False;
  FThumbHoverBackgroundSet := False;
  FThumbActiveBackgroundSet := False;
  FThumbBorderColorSet := False;
  FThumbRadiusSet := False;
  FArrowColorSet := False;

  inherited ResetStyle;
end;

procedure TCssScrollBar.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'scrolltrack-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTrackBackground := C;
      FTrackBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'thumb-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FThumbBackground := C;
      FThumbBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'thumb-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FThumbHoverBackground := C;
      FThumbHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'thumb-active-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FThumbActiveBackground := C;
      FThumbActiveBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'thumb-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FThumbBorderColor := C;
      FThumbBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'thumb-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FThumbRadius := Px;
      FThumbRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'arrow-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FArrowColor := C;
      FArrowColorSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

function TCssScrollBar.ClampPosition(AValue: Integer): Integer;
begin
  if FMax < FMin then
  begin
    Result := FMin;
    Exit;
  end;

  if AValue < FMin then
    Result := FMin
  else if AValue > FMax then
    Result := FMax
  else
    Result := AValue;
end;

procedure TCssScrollBar.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCssScrollBar.InternalSetPosition(AValue: Integer; Notify: Boolean);
var
  NewPosition: Integer;
begin
  NewPosition := ClampPosition(AValue);

  if FPosition = NewPosition then
    Exit;

  FPosition := NewPosition;

  Invalidate;

  if Notify then
    DoChange;
end;

procedure TCssScrollBar.SetMin(AValue: Integer);
begin
  if FMin = AValue then
    Exit;

  FMin := AValue;

  if FMax < FMin then
    FMax := FMin;

  InternalSetPosition(FPosition, True);
  Invalidate;
end;

procedure TCssScrollBar.SetMax(AValue: Integer);
begin
  if FMax = AValue then
    Exit;

  FMax := AValue;

  if FMax < FMin then
    FMax := FMin;

  InternalSetPosition(FPosition, True);
  Invalidate;
end;

procedure TCssScrollBar.SetPosition(AValue: Integer);
begin
  InternalSetPosition(AValue, True);
end;

procedure TCssScrollBar.SetPageSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FPageSize = AValue then
    Exit;

  FPageSize := AValue;

  Invalidate;
end;

procedure TCssScrollBar.SetSmallChange(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FSmallChange = AValue then
    Exit;

  FSmallChange := AValue;
end;

procedure TCssScrollBar.SetLargeChange(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FLargeChange = AValue then
    Exit;

  FLargeChange := AValue;
end;

procedure TCssScrollBar.SetKind(AValue: TScrollBarKind);
begin
  if FKind = AValue then
    Exit;

  FKind := AValue;

  Invalidate;
end;

procedure TCssScrollBar.SetParams(APosition, AMin, AMax: Integer);
var
  OldPosition: Integer;
begin
  OldPosition := FPosition;

  FMin := AMin;
  FMax := AMax;

  if FMax < FMin then
    FMax := FMin;

  InternalSetPosition(APosition, False);

  Invalidate;

  if FPosition <> OldPosition then
    DoChange;
end;

function TCssScrollBar.GetTrackRect: TRect;
begin
  Result := inherited GetContentRect;
end;

procedure TCssScrollBar.CalcThumbSizeAndPos(AvailableLen: Integer; out
  ThumbSize, ThumbPos: Integer);
var
  Range, PageSpan: Integer;
begin
  if AvailableLen < 0 then
    AvailableLen := 0;

  Range := FMax - FMin;

  if Range < 0 then
    Range := 0;

  PageSpan := FPageSize;

  if PageSpan <= 0 then
    PageSpan := FLargeChange;

  if PageSpan < 0 then
    PageSpan := 0;

  if Range <= 0 then
  begin
    ThumbSize := AvailableLen;
    ThumbPos := 0;
    Exit;
  end;

  if PageSpan > 0 then
    ThumbSize := Round(AvailableLen * PageSpan / (Range + PageSpan))
  else
    ThumbSize := CssMin(AvailableLen, CssMax(16, AvailableLen div 5));

  if ThumbSize < 8 then
    ThumbSize := CssMin(8, AvailableLen);

  if ThumbSize > AvailableLen then
    ThumbSize := AvailableLen;

  if AvailableLen <= ThumbSize then
    ThumbPos := 0
  else
    ThumbPos := Round((FPosition - FMin) / Range * (AvailableLen - ThumbSize));
end;

procedure TCssScrollBar.GetScrollRects(out TrackR, ArrowMinusR, ArrowPlusR,
  ThumbR: TRect);
var
  TrackLen, ArrowSize: Integer;
  ThumbAreaStart, ThumbAreaEnd, ThumbAreaLen: Integer;
  ThumbSize, ThumbPos: Integer;
begin
  TrackR := GetTrackRect;

  ArrowMinusR := Rect(0, 0, 0, 0);
  ArrowPlusR := Rect(0, 0, 0, 0);
  ThumbR := Rect(0, 0, 0, 0);

  if (TrackR.Right <= TrackR.Left) or (TrackR.Bottom <= TrackR.Top) then
    Exit;

  if FKind = sbVertical then
  begin
    TrackLen := TrackR.Bottom - TrackR.Top;
    ArrowSize := TrackR.Right - TrackR.Left;

    if ArrowSize > TrackLen div 3 then
      ArrowSize := TrackLen div 3;

    if ArrowSize < 0 then
      ArrowSize := 0;

    ArrowMinusR := Rect(
      TrackR.Left,
      TrackR.Top,
      TrackR.Right,
      TrackR.Top + ArrowSize
    );

    ArrowPlusR := Rect(
      TrackR.Left,
      TrackR.Bottom - ArrowSize,
      TrackR.Right,
      TrackR.Bottom
    );

    ThumbAreaStart := ArrowMinusR.Bottom;
    ThumbAreaEnd := ArrowPlusR.Top;
    ThumbAreaLen := ThumbAreaEnd - ThumbAreaStart;

    if ThumbAreaLen <= 0 then
      Exit;

    CalcThumbSizeAndPos(ThumbAreaLen, ThumbSize, ThumbPos);

    ThumbR := Rect(
      TrackR.Left,
      ThumbAreaStart + ThumbPos,
      TrackR.Right,
      ThumbAreaStart + ThumbPos + ThumbSize
    );
  end
  else
  begin
    TrackLen := TrackR.Right - TrackR.Left;
    ArrowSize := TrackR.Bottom - TrackR.Top;

    if ArrowSize > TrackLen div 3 then
      ArrowSize := TrackLen div 3;

    if ArrowSize < 0 then
      ArrowSize := 0;

    ArrowMinusR := Rect(
      TrackR.Left,
      TrackR.Top,
      TrackR.Left + ArrowSize,
      TrackR.Bottom
    );

    ArrowPlusR := Rect(
      TrackR.Right - ArrowSize,
      TrackR.Top,
      TrackR.Right,
      TrackR.Bottom
    );

    ThumbAreaStart := ArrowMinusR.Right;
    ThumbAreaEnd := ArrowPlusR.Left;
    ThumbAreaLen := ThumbAreaEnd - ThumbAreaStart;

    if ThumbAreaLen <= 0 then
      Exit;

    CalcThumbSizeAndPos(ThumbAreaLen, ThumbSize, ThumbPos);

    ThumbR := Rect(
      ThumbAreaStart + ThumbPos,
      TrackR.Top,
      ThumbAreaStart + ThumbPos + ThumbSize,
      TrackR.Bottom
    );
  end;
end;

function TCssScrollBar.GetThumbDragRange: Integer;
var
  TrackR, ArrowMinusR, ArrowPlusR, ThumbR: TRect;
  AreaLen, ThumbSize, ThumbPos: Integer;
begin
  GetScrollRects(TrackR, ArrowMinusR, ArrowPlusR, ThumbR);

  if FKind = sbVertical then
    AreaLen := ArrowPlusR.Top - ArrowMinusR.Bottom
  else
    AreaLen := ArrowPlusR.Left - ArrowMinusR.Right;

  if AreaLen <= 0 then
  begin
    Result := 0;
    Exit;
  end;

  CalcThumbSizeAndPos(AreaLen, ThumbSize, ThumbPos);

  Result := AreaLen - ThumbSize;

  if Result < 0 then
    Result := 0;
end;

function TCssScrollBar.GetPartAt(X, Y: Integer): TCssScrollPart;
var
  P: TPoint;
  TrackR, ArrowMinusR, ArrowPlusR, ThumbR: TRect;
begin
  P := Point(X, Y);

  GetScrollRects(TrackR, ArrowMinusR, ArrowPlusR, ThumbR);

  if PtInRect(ArrowMinusR, P) then
  begin
    Result := cspArrowMinus;
    Exit;
  end;

  if PtInRect(ArrowPlusR, P) then
  begin
    Result := cspArrowPlus;
    Exit;
  end;

  if (ThumbR.Right > ThumbR.Left) and
     (ThumbR.Bottom > ThumbR.Top) and
     PtInRect(ThumbR, P) then
  begin
    Result := cspThumb;
    Exit;
  end;

  if FKind = sbVertical then
  begin
    if P.Y < ThumbR.Top then
      Result := cspTrackMinus
    else
      Result := cspTrackPlus;
  end
  else
  begin
    if P.X < ThumbR.Left then
      Result := cspTrackMinus
    else
      Result := cspTrackPlus;
  end;
end;

function TCssScrollBar.GetTrackBackground: TColor;
begin
  if FTrackBackgroundSet then
  begin
    Result := FTrackBackground;
    Exit;
  end;

  Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := clBtnFace;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssScrollBar.GetThumbBackground: TColor;
begin
  if FThumbBackgroundSet then
  begin
    Result := FThumbBackground;
    Exit;
  end;

  if not Enabled then
  begin
    Result := clBtnFace;
    Exit;
  end;

  Result := RGBToColor(205, 205, 205);
end;

function TCssScrollBar.GetThumbHoverBackground: TColor;
begin
  if FThumbHoverBackgroundSet then
  begin
    Result := FThumbHoverBackground;
    Exit;
  end;

  Result := GetThumbBackground;
end;

function TCssScrollBar.GetThumbActiveBackground: TColor;
begin
  if FThumbActiveBackgroundSet then
  begin
    Result := FThumbActiveBackground;
    Exit;
  end;

  Result := GetThumbHoverBackground;
end;

function TCssScrollBar.GetThumbBorderColor: TColor;
begin
  if FThumbBorderColorSet then
  begin
    Result := FThumbBorderColor;
    Exit;
  end;

  Result := RGBToColor(150, 150, 150);
end;

function TCssScrollBar.GetThumbRadius: Integer;
begin
  if FThumbRadiusSet then
    Result := FThumbRadius
  else
    Result := 0;
end;

function TCssScrollBar.GetArrowColor: TColor;
begin
  if FArrowColorSet then
  begin
    Result := FArrowColor;
    Exit;
  end;

  if not Enabled then
  begin
    Result := clGray;
    Exit;
  end;

  Result := GetCssTextColor;
end;

procedure TCssScrollBar.DrawArrowGlyph(
  const R: TRect; APart: TCssScrollPart; AColor: TColor);
var
  CX, CY: Integer;
  BG: TColor;
begin
  if (R.Right - R.Left < 5) or (R.Bottom - R.Top < 5) then Exit;

  if FActivePart = APart then
    BG := GetThumbActiveBackground
  else if FHoverPart = APart then
    BG := GetThumbHoverBackground
  else
    BG := GetTrackBackground;

  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;

  if FKind = sbVertical then
  begin
    if APart = cspArrowMinus then
      DrawAntiAliasedTriangle(Canvas,
        Point(CX, R.Top + 3),
        Point(R.Left + 3, R.Bottom - 3),
        Point(R.Right - 3, R.Bottom - 3),
        AColor, BG)
    else if APart = cspArrowPlus then
      DrawAntiAliasedTriangle(Canvas,
        Point(CX, R.Bottom - 3),
        Point(R.Left + 3, R.Top + 3),
        Point(R.Right - 3, R.Top + 3),
        AColor, BG);
  end
  else
  begin
    if APart = cspArrowMinus then
      DrawAntiAliasedTriangle(Canvas,
        Point(R.Left + 3, CY),
        Point(R.Right - 3, R.Top + 3),
        Point(R.Right - 3, R.Bottom - 3),
        AColor, BG)
    else if APart = cspArrowPlus then
      DrawAntiAliasedTriangle(Canvas,
        Point(R.Right - 3, CY),
        Point(R.Left + 3, R.Top + 3),
        Point(R.Left + 3, R.Bottom - 3),
        AColor, BG);
  end;
end;

procedure TCssScrollBar.DrawArrowButton(const R: TRect; APart: TCssScrollPart);
var
  BG: TColor;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  if FActivePart = APart then
    BG := GetThumbActiveBackground
  else if FHoverPart = APart then
    BG := GetThumbHoverBackground
  else
    BG := GetTrackBackground;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BG;
  Canvas.FillRect(R);

  DrawArrowGlyph(R, APart, GetArrowColor);
end;

procedure TCssScrollBar.Paint;
var
  TrackR, ArrowMinusR, ArrowPlusR, ThumbR: TRect;
  TrackColor, ThumbBG, ThumbBorder: TColor;
  Radius: Integer;
  FocusR: TRect;
begin
  inherited Paint;

  GetScrollRects(TrackR, ArrowMinusR, ArrowPlusR, ThumbR);

  if (TrackR.Right <= TrackR.Left) or (TrackR.Bottom <= TrackR.Top) then
    Exit;

  TrackColor := GetTrackBackground;

  if TrackColor <> clNone then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := TrackColor;
    Canvas.FillRect(TrackR);
  end;

  DrawArrowButton(ArrowMinusR, cspArrowMinus);
  DrawArrowButton(ArrowPlusR, cspArrowPlus);

  if (ThumbR.Right > ThumbR.Left) and (ThumbR.Bottom > ThumbR.Top) then
  begin
    if FDragging or (FActivePart = cspThumb) then
      ThumbBG := GetThumbActiveBackground
    else if FHoverPart = cspThumb then
      ThumbBG := GetThumbHoverBackground
    else
      ThumbBG := GetThumbBackground;

    ThumbBorder := GetThumbBorderColor;
    Radius := GetThumbRadius;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := ThumbBG;

    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color := ThumbBorder;
    Canvas.Pen.Width := 1;

    if Radius > 0 then
      Canvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, Radius, Radius)
    else
      Canvas.Rectangle(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom);
  end;

  if Focused and ShowFocusRect and Enabled then
  begin
    if (ThumbR.Right > ThumbR.Left) and (ThumbR.Bottom > ThumbR.Top) then
      FocusR := ThumbR
    else
      FocusR := TrackR;

    DrawFocusRect(Canvas, FocusR);
  end;
end;

function TCssScrollBar.GetFocusColor: TColor;
begin
  if FocusColor <> clDefault then
    Exit(inherited GetFocusColor);

  Result := GetArrowColor;
end;

procedure TCssScrollBar.Resize;
begin
  inherited Resize;

  Invalidate;
end;

procedure TCssScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Part: TCssScrollPart;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if CanFocus then
    SetFocus;

  Part := GetPartAt(X, Y);

  case Part of
    cspArrowMinus:
    begin
      FActivePart := cspArrowMinus;
      InternalSetPosition(FPosition - FSmallChange, True);
      Invalidate;
    end;

    cspArrowPlus:
    begin
      FActivePart := cspArrowPlus;
      InternalSetPosition(FPosition + FSmallChange, True);
      Invalidate;
    end;

    cspTrackMinus:
    begin
      FActivePart := cspTrackMinus;
      InternalSetPosition(FPosition - FLargeChange, True);
      Invalidate;
    end;

    cspTrackPlus:
    begin
      FActivePart := cspTrackPlus;
      InternalSetPosition(FPosition + FLargeChange, True);
      Invalidate;
    end;

    cspThumb:
    begin
      FDragging := True;
      FActivePart := cspThumb;

      if FKind = sbVertical then
        FDragStartPixel := Y
      else
        FDragStartPixel := X;

      FDragStartPos := FPosition;

      MouseCapture := True;

      Invalidate;
    end;

    else
  end;
end;

procedure TCssScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Part: TCssScrollPart;
  Pixel, Delta, DragRange, Range, ValueDelta: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  if FDragging then
  begin
    if FKind = sbVertical then
      Pixel := Y
    else
      Pixel := X;

    Delta := Pixel - FDragStartPixel;
    DragRange := GetThumbDragRange;
    Range := FMax - FMin;

    if Range < 0 then
      Range := 0;

    if (DragRange > 0) and (Range > 0) then
      ValueDelta := Round(Delta / DragRange * Range)
    else
      ValueDelta := 0;

    InternalSetPosition(FDragStartPos + ValueDelta, True);
  end
  else
  begin
    Part := GetPartAt(X, Y);

    if Part <> FHoverPart then
    begin
      FHoverPart := Part;
      Invalidate;
    end;
  end;
end;

procedure TCssScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FDragging then
  begin
    FDragging := False;
    MouseCapture := False;
  end;

  FActivePart := cspNone;

  Invalidate;
end;

procedure TCssScrollBar.MouseLeave;
begin
  if not FDragging then
    FHoverPart := cspNone;

  inherited MouseLeave;

  Invalidate;
end;

procedure TCssScrollBar.KeyDown(var Key: Word; Shift: TShiftState);
var
  Delta: Integer;
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  Delta := 0;

  case Key of
    VK_LEFT, VK_UP:
      Delta := -FSmallChange;

    VK_RIGHT, VK_DOWN:
      Delta := FSmallChange;

    VK_PRIOR:
      Delta := -FLargeChange;

    VK_NEXT:
      Delta := FLargeChange;

    VK_HOME:
    begin
      InternalSetPosition(FMin, True);
      Key := 0;
      Exit;
    end;

    VK_END:
    begin
      InternalSetPosition(FMax, True);
      Key := 0;
      Exit;
    end;
  else
    Exit;
  end;

  InternalSetPosition(FPosition + Delta, True);
  Key := 0;
end;

function TCssScrollBar.DoMouseWheel(
  Shift: TShiftState;
  WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Delta: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);

  if Result then
    Exit;

  if not Enabled then
    Exit;

  Delta := FSmallChange * 3;

  if Delta < 1 then
    Delta := 1;

  if WheelDelta > 0 then
    InternalSetPosition(FPosition - Delta, True)
  else if WheelDelta < 0 then
    InternalSetPosition(FPosition + Delta, True)
  else
    Exit;

  Result := True;
end;

function TCssScrollBar.IsDragging: Boolean;
begin
  Result := FDragging;
end;

function TCssScrollBar.ExternalMouseLeave: Boolean;
begin
  Result := False;

  if not FDragging and (FHoverPart <> cspNone) then
  begin
    FHoverPart := cspNone;
    Result := True;
  end;
end;

procedure TCssScrollBar.ExternalMouseUp;
begin
  if FDragging then
    FDragging := False;

  FActivePart := cspNone;
end;

function TCssScrollBar.ExternalMouseDown(
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Integer): Boolean;
var
  Part: TCssScrollPart;
begin
  Result := False;

  if not Enabled then
    Exit;

  if Button <> mbLeft then
    Exit;

  Part := GetPartAt(X, Y);

  if Part = cspNone then
    Exit;

  FHoverPart := Part;

  case Part of
    cspArrowMinus:
    begin
      FActivePart := cspArrowMinus;
      InternalSetPosition(FPosition - FSmallChange, True);
      Result := True;
    end;

    cspArrowPlus:
    begin
      FActivePart := cspArrowPlus;
      InternalSetPosition(FPosition + FSmallChange, True);
      Result := True;
    end;

    cspTrackMinus:
    begin
      FActivePart := cspTrackMinus;
      InternalSetPosition(FPosition - FLargeChange, True);
      Result := True;
    end;

    cspTrackPlus:
    begin
      FActivePart := cspTrackPlus;
      InternalSetPosition(FPosition + FLargeChange, True);
      Result := True;
    end;

    cspThumb:
    begin
      FDragging := True;
      FActivePart := cspThumb;

      if FKind = sbVertical then
        FDragStartPixel := Y
      else
        FDragStartPixel := X;

      FDragStartPos := FPosition;

      Result := True;
    end;

    else
  end;
end;

function TCssScrollBar.ExternalMouseMove(
  Shift: TShiftState;
  X, Y: Integer): Boolean;
var
  Part: TCssScrollPart;
  Pixel, Delta, DragRange, Range, ValueDelta: Integer;
begin
  Result := False;

  if not Enabled then
    Exit;

  if FDragging then
  begin
    if FKind = sbVertical then
      Pixel := Y
    else
      Pixel := X;

    Delta := Pixel - FDragStartPixel;
    DragRange := GetThumbDragRange;
    Range := FMax - FMin;

    if Range < 0 then
      Range := 0;

    if (DragRange > 0) and (Range > 0) then
      ValueDelta := Round(Delta / DragRange * Range)
    else
      ValueDelta := 0;

    InternalSetPosition(FDragStartPos + ValueDelta, True);
    Result := True;
  end
  else
  begin
    Part := GetPartAt(X, Y);

    if Part <> FHoverPart then
    begin
      FHoverPart := Part;
      Result := True;
    end;
  end;
end;

procedure TCssScrollBar.DrawArrowGlyphEx(
  ACanvas: TCanvas; const R: TRect;
  APart: TCssScrollPart; AColor: TColor);
var
  CX, CY: Integer;
  BG: TColor;
begin
  if (R.Right - R.Left < 5) or (R.Bottom - R.Top < 5) then Exit;

  if FActivePart = APart then
    BG := GetThumbActiveBackground
  else if FHoverPart = APart then
    BG := GetThumbHoverBackground
  else
    BG := GetTrackBackground;

  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;

  if FKind = sbVertical then
  begin
    if APart = cspArrowMinus then
      DrawAntiAliasedTriangle(ACanvas,
        Point(CX, R.Top + 3),
        Point(R.Left + 3, R.Bottom - 3),
        Point(R.Right - 3, R.Bottom - 3),
        AColor, BG)
    else if APart = cspArrowPlus then
      DrawAntiAliasedTriangle(ACanvas,
        Point(CX, R.Bottom - 3),
        Point(R.Left + 3, R.Top + 3),
        Point(R.Right - 3, R.Top + 3),
        AColor, BG);
  end
  else
  begin
    if APart = cspArrowMinus then
      DrawAntiAliasedTriangle(ACanvas,
        Point(R.Left + 3, CY),
        Point(R.Right - 3, R.Top + 3),
        Point(R.Right - 3, R.Bottom - 3),
        AColor, BG)
    else if APart = cspArrowPlus then
      DrawAntiAliasedTriangle(ACanvas,
        Point(R.Right - 3, CY),
        Point(R.Left + 3, R.Top + 3),
        Point(R.Left + 3, R.Bottom - 3),
        AColor, BG);
  end;
end;

procedure TCssScrollBar.DrawArrowButtonEx(
  ACanvas: TCanvas;
  const R: TRect;
  APart: TCssScrollPart);
var
  BG: TColor;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  if FActivePart = APart then
    BG := GetThumbActiveBackground
  else if FHoverPart = APart then
    BG := GetThumbHoverBackground
  else
    BG := GetTrackBackground;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := BG;
  ACanvas.FillRect(R);

  DrawArrowGlyphEx(ACanvas, R, APart, GetArrowColor);
end;

procedure TCssScrollBar.DrawToCanvas(
  ACanvas: TCanvas;
  const ARect: TRect);
var
  TrackR, ArrowMinusR, ArrowPlusR, ThumbR: TRect;
  OldW, OldH: Integer;
  DX, DY: Integer;
  TrackColor, ThumbBG, ThumbBorder: TColor;
  Radius: Integer;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  OldW := Width;
  OldH := Height;

  // Temporarily set the size to match the target area
  // so that internal calculations work correctly.
  SetBounds(0, 0, ARect.Width, ARect.Height);
  try
    GetScrollRects(TrackR, ArrowMinusR, ArrowPlusR, ThumbR);

    DX := ARect.Left;
    DY := ARect.Top;

    OffsetRect(TrackR, DX, DY);
    OffsetRect(ArrowMinusR, DX, DY);
    OffsetRect(ArrowPlusR, DX, DY);
    OffsetRect(ThumbR, DX, DY);

    TrackColor := GetTrackBackground;
    if TrackColor <> clNone then
    begin
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := TrackColor;
      ACanvas.FillRect(TrackR);
    end;

    DrawArrowButtonEx(ACanvas, ArrowMinusR, cspArrowMinus);
    DrawArrowButtonEx(ACanvas, ArrowPlusR, cspArrowPlus);

    if (ThumbR.Right > ThumbR.Left) and (ThumbR.Bottom > ThumbR.Top) then
    begin
      if FDragging or (FActivePart = cspThumb) then
        ThumbBG := GetThumbActiveBackground
      else if FHoverPart = cspThumb then
        ThumbBG := GetThumbHoverBackground
      else
        ThumbBG := GetThumbBackground;

      ThumbBorder := GetThumbBorderColor;
      Radius := GetThumbRadius;

      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := ThumbBG;

      ACanvas.Pen.Style := psSolid;
      ACanvas.Pen.Color := ThumbBorder;
      ACanvas.Pen.Width := 1;

      if Radius > 0 then
        ACanvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, Radius, Radius)
      else
        ACanvas.Rectangle(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom);
    end;
  finally
    SetBounds(0, 0, OldW, OldH);
  end;
end;

end.
