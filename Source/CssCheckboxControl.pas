unit CssCheckboxControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, StdCtrls, LCLType,
  CssStyledControl, CssGroupCaptionControl;

type
  TCssCheckBox = class(TCssStyledControl)
  private
    // State
    FState: TCheckBoxState;
    FAllowGrayed: Boolean;

    // Interaction flags
    FClicked: Boolean;
    FSpacePressed: Boolean;
    FClicking: Boolean;

    // Box appearance
    FBoxBackground: TColor;
    FBoxBackgroundSet: Boolean;
    FBoxBorderColor: TColor;
    FBoxBorderColorSet: Boolean;
    FBoxBorderWidth: Integer;
    FBoxBorderWidthSet: Boolean;
    FBoxRadius: Integer;
    FBoxRadiusSet: Boolean;
    FCheckColor: TColor;
    FCheckColorSet: Boolean;

    // Property getters
    function GetCheckBoxBackground: TColor;
    function GetCheckBoxBorderColor: TColor;
    function GetCheckBoxBorderWidth: Integer;
    function GetCheckBoxRadius: Integer;
    function GetCheckColor: TColor;
    function GetChecked: Boolean;
    function GetBoxSize: Integer;

    // Property setters
    procedure SetChecked(AValue: Boolean);
    procedure SetState(AValue: TCheckBoxState);
    procedure SetAllowGrayed(AValue: Boolean);

    // State toggling
    procedure ToggleState;

    // Drawing helpers
    procedure DrawCheckMark(const R: TRect; AColor: TColor);
    procedure DrawGrayedMark(const R: TRect; AColor: TColor);
    procedure DrawCheckMarkToCanvas(ACanvas: TCanvas; const R: TRect; AColor: TColor);
    procedure DrawGrayedMarkToCanvas(ACanvas: TCanvas; const R: TRect; AColor: TColor);
  protected
    // Initialization and style
    function ShouldPaintCaption: Boolean; override;
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Caption
    procedure SetCaption(const AValue: TCaption); override;

    // Painting
    procedure Paint; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Focus
    procedure DoEnter; override;
    procedure DoExit; override;

    // Click
    procedure Click; override;

    // Navigation
    procedure NavigateStandalone(AKey: Word);
  public
    constructor Create(AOwner: TComponent); override;

    // Sizing
    procedure AdjustSize; override;
    function MeasureBoxSize(ACanvas: TCanvas): Integer;

    // State manipulation
    procedure Toggle;
    procedure SetVisualState(AChecked, AHover: Boolean);

    // Drawing to external canvas
    procedure DrawStateToCanvas(ACanvas: TCanvas; const ARect: TRect; AState: TCheckBoxState);
    procedure DrawToCanvas(ACanvas: TCanvas; const ARect: TRect);
  published
    // State properties
    property Checked: Boolean read GetChecked write SetChecked;
    property State: TCheckBoxState read FState write SetState;
    property AllowGrayed: Boolean read FAllowGrayed write SetAllowGrayed;

    // Standard properties
    property AutoSize;
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property ShowFocusRect default False;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TCheckGroupItemClickEvent = procedure(Sender: TObject; ItemIndex: Integer) of object;

  TCssCheckGroup = class(TCssGroupCaptionControl)
  private
    // Items and child controls
    FItems: TStringList;
    FCheckBoxes: TList;

    // Item states
    FStates: array of TCheckBoxState;
    FItemEnabled: array of Boolean;

    // Appearance and layout
    FAllowGrayed: Boolean;
    FColumns: Integer;
    FItemHeight: Integer;
    FItemIndex: Integer;

    // Internal flags
    FUpdating: Boolean;
    FInMouseStateChange: Boolean;

    // CSS styling for child checkboxes
    FCheckBoxCssClass: string;
    FCheckBoxCssStyle: string;

    // Events
    FOnItemClickNotify: TNotifyEvent;
    FOnItemClick: TCheckGroupItemClickEvent;

    // Focus tracking
    FFocusIndex: Integer;

    // Private helpers
    procedure ApplyChildShowFocusRect;
    procedure ItemEnter(Sender: TObject);
    procedure NavigateFromIndex(AIndex: Integer; AKey: Word);

    procedure SetItems(AValue: TStrings);
    procedure ItemsChanged(Sender: TObject);

    procedure SyncStateArrays;
    procedure RebuildItems;
    procedure UpdateChildStyles;

    function GetColumns: Integer;
    function GetItemHeight: Integer;
    function GetCheckBox(Index: Integer): TCssCheckBox;

    function GetChecked(Index: Integer): Boolean;
    procedure SetChecked(Index: Integer; AValue: Boolean);
    function GetState(Index: Integer): TCheckBoxState;
    procedure SetState(Index: Integer; AValue: TCheckBoxState);
    function GetItemEnabled(Index: Integer): Boolean;
    procedure SetItemEnabled(Index: Integer; AValue: Boolean);

    procedure SetAllowGrayed(AValue: Boolean);
    procedure SetColumns(AValue: Integer);
    procedure SetItemHeight(AValue: Integer);
    procedure SetCheckBoxCssClass(const AValue: string);
    procedure SetCheckBoxCssStyle(const AValue: string);

    procedure ItemCheckBoxClick(Sender: TObject);
    function GetItems: TStrings;
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure EnabledChanged; override;
    procedure SetShowFocusRect(AValue: Boolean); override;
    procedure LayoutItems; override;

    // Painting
    procedure Paint; override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Mouse
    procedure MouseEnter; override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Items management
    procedure Clear;
    procedure CheckAll(AState: TCheckBoxState);
    procedure RefreshChildStyles;

    // Sizing
    procedure AdjustSize; override;

    // Navigation
    function FindEnabledCheckBox(AStart, ADelta: Integer; AWrap: Boolean): Integer;
    procedure FocusItem(Index: Integer);
    procedure NavigateArrow(AKey: Word);
    procedure NavigateFrom(AControl: TControl; AKey: Word);

    // Indexed properties
    property Checked[Index: Integer]: Boolean read GetChecked write SetChecked;
    property State[Index: Integer]: TCheckBoxState read GetState write SetState;
    property ItemEnabled[Index: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
    property ItemIndex: Integer read FItemIndex;
    property FocusedItem: Integer read FFocusIndex;
  published
    // Items and appearance
    property Items: TStrings read GetItems write SetItems;
    property AllowGrayed: Boolean read FAllowGrayed write SetAllowGrayed;
    property Columns: Integer read FColumns write SetColumns;
    property ItemHeight: Integer read FItemHeight write SetItemHeight;
    property CheckBoxCssClass: string read FCheckBoxCssClass write SetCheckBoxCssClass;
    property CheckBoxCssStyle: string read FCheckBoxCssStyle write SetCheckBoxCssStyle;

    // Standard properties
    property AutoSize;
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnItemClickNotify: TNotifyEvent read FOnItemClickNotify write FOnItemClickNotify;
    property OnItemClick: TCheckGroupItemClickEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  Math, IntfGraphics, FPImage;

function MeasurePlainText(ACanvas: TCanvas; const AText: string): TSize;
var
  Lines: TStringList;
  I: Integer;
  W, H: Integer;
begin
  Result.cx := 0;
  Result.cy := 0;

  Lines := TStringList.Create;

  try
    Lines.Text := AText;

    if Lines.Count = 0 then
      Lines.Add('');

    H := ACanvas.TextHeight('Ag');

    for I := 0 to Lines.Count - 1 do
    begin
      W := ACanvas.TextWidth(Lines[I]);

      if W > Result.cx then
        Result.cx := W;
    end;

    Result.cy := Lines.Count * H;
  finally
    Lines.Free;
  end;
end;

type
  TCssCheckMarkCacheEntry = class
    Width, Height: Integer;
    LineColor: TColor;
    BgColor: TColor;
    LineWidthX10: Integer;
    Bitmap: TBitmap;
    constructor Create;
    destructor Destroy; override;
    function Matches(AW, AH: Integer; ALineColor, ABgColor: TColor;
      ALineWidth: Double): Boolean;
  end;

  TCssCheckMarkCache = class
  private
    FEntries: TList;
    function IndexOfEntry(AW, AH: Integer;
      ALineColor, ABgColor: TColor; ALineWidth: Double): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetBitmap(AW, AH: Integer;
      ALineColor, ABgColor: TColor; ALineWidth: Double): TBitmap;
  end;

  PRGBQuadItem = ^TRGBQuadItem;
  TRGBQuadItem = packed record
    B, G, R, A: Byte;
  end;

const
  CSS_CHECKMARK_CACHE_LIMIT = 48;

constructor TCssCheckMarkCacheEntry.Create;
begin
  inherited Create;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf32bit;
end;

destructor TCssCheckMarkCacheEntry.Destroy;
begin
  Bitmap.Free;
  inherited Destroy;
end;

function TCssCheckMarkCacheEntry.Matches(AW, AH: Integer;
  ALineColor, ABgColor: TColor; ALineWidth: Double): Boolean;
begin
  Result :=
    (Width = AW) and (Height = AH) and
    (LineColor = ALineColor) and
    (BgColor = ABgColor) and
    (LineWidthX10 = Round(ALineWidth * 10));
end;

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
    TCssCheckMarkCacheEntry(FEntries[I]).Free;
  FEntries.Clear;
end;

function TCssCheckMarkCache.IndexOfEntry(AW, AH: Integer;
  ALineColor, ABgColor: TColor; ALineWidth: Double): Integer;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    if TCssCheckMarkCacheEntry(FEntries[I]).Matches(
         AW, AH, ALineColor, ABgColor, ALineWidth) then
      Exit(I);
  Result := -1;
end;

procedure RenderCheckMarkToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  const AX1, AY1, AX2, AY2, AX3, AY3: Double;
  ALineWidth: Double;
  ALineColor, ABgColor: TColor);
var
  Img: TLazIntfImage;
  Pixel: TFPColor;
  X, Y: Integer;
  BgR, BgG, BgB: Byte;
  LR, LG, LB: Byte;
  BgRGB, LineRGB: TColor;
  Half: Double;

  procedure DrawSegment(X1, Y1, X2, Y2: Double);
  var
    MinX, MaxX, MinY, MaxY: Integer;
    LX, LY: Integer;
    DX, DY, LenSq, T, CX, CY, Dist, Coverage: Double;
    PX, PY: Double;
    BlendedR, BlendedG, BlendedB: Integer;
    CurPixel: TFPColor;
  begin
    MinX := Floor(Min(X1, X2) - Half - 1);
    MaxX := Ceil (Max(X1, X2) + Half + 1);
    MinY := Floor(Min(Y1, Y2) - Half - 1);
    MaxY := Ceil (Max(Y1, Y2) + Half + 1);

    if MinX < 0    then MinX := 0;
    if MinY < 0    then MinY := 0;
    if MaxX >= AW  then MaxX := AW - 1;
    if MaxY >= AH  then MaxY := AH - 1;

    if (MinX > MaxX) or (MinY > MaxY) then
      Exit;

    DX := X2 - X1;
    DY := Y2 - Y1;
    LenSq := DX * DX + DY * DY;

    for LY := MinY to MaxY do
    begin
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

        Coverage := Half + 0.5 - Dist;

        if Coverage <= 0 then
          Continue;

        if Coverage > 1 then
          Coverage := 1;

        CurPixel := Img.Colors[LX, LY];

        BlendedR := Round(LR * Coverage +
                         (CurPixel.Red   div 257) * (1 - Coverage));
        BlendedG := Round(LG * Coverage +
                         (CurPixel.Green div 257) * (1 - Coverage));
        BlendedB := Round(LB * Coverage +
                         (CurPixel.Blue  div 257) * (1 - Coverage));

        if BlendedR < 0   then BlendedR := 0
        else if BlendedR > 255 then BlendedR := 255;

        if BlendedG < 0   then BlendedG := 0
        else if BlendedG > 255 then BlendedG := 255;

        if BlendedB < 0   then BlendedB := 0
        else if BlendedB > 255 then BlendedB := 255;

        CurPixel.Red   := BlendedR * 257;
        CurPixel.Green := BlendedG * 257;
        CurPixel.Blue  := BlendedB * 257;
        CurPixel.Alpha := $FFFF;

        Img.Colors[LX, LY] := CurPixel;
      end;
    end;
  end;

begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then
    Exit;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);

  Img := ABitmap.CreateIntfImage;
  try
    BgRGB := ColorToRGB(ABgColor);
    BgR := Byte(BgRGB and $FF);
    BgG := Byte((BgRGB shr 8) and $FF);
    BgB := Byte((BgRGB shr 16) and $FF);

    for Y := 0 to AH - 1 do
    begin
      for X := 0 to AW - 1 do
      begin
        Pixel.Red   := BgR * 257;   // 0..255 → 0..65535
        Pixel.Green := BgG * 257;
        Pixel.Blue  := BgB * 257;
        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;
    end;

    LineRGB := ColorToRGB(ALineColor);
    LR := Byte(LineRGB and $FF);
    LG := Byte((LineRGB shr 8) and $FF);
    LB := Byte((LineRGB shr 16) and $FF);

    Half := ALineWidth / 2;

    DrawSegment(AX1, AY1, AX2, AY2);
    DrawSegment(AX2, AY2, AX3, AY3);

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

function TCssCheckMarkCache.GetBitmap(
  AW, AH: Integer;
  ALineColor, ABgColor: TColor;
  ALineWidth: Double): TBitmap;
var
  Idx: Integer;
  Entry: TCssCheckMarkCacheEntry;
  X1, Y1, X2, Y2, X3, Y3: Double;
begin
  Idx := IndexOfEntry(AW, AH, ALineColor, ABgColor, ALineWidth);

  if Idx >= 0 then
  begin
    Entry := TCssCheckMarkCacheEntry(FEntries[Idx]);
    FEntries.Delete(Idx);
    FEntries.Add(Entry);
    Exit(Entry.Bitmap);
  end;

  if FEntries.Count >= CSS_CHECKMARK_CACHE_LIMIT then
    Clear;

  Entry := TCssCheckMarkCacheEntry.Create;
  Entry.Width := AW;
  Entry.Height := AH;
  Entry.LineColor := ALineColor;
  Entry.BgColor := ABgColor;
  Entry.LineWidthX10 := Round(ALineWidth * 10);

  X1 := AW * 0.20;  Y1 := AH * 0.50;
  X2 := AW * 0.40;  Y2 := AH * 0.75;
  X3 := AW * 0.80;  Y3 := AH * 0.22;

  RenderCheckMarkToBitmap(
    Entry.Bitmap, AW, AH,
    X1, Y1, X2, Y2, X3, Y3,
    ALineWidth,
    ALineColor, ABgColor
  );

  FEntries.Add(Entry);
  Result := Entry.Bitmap;
end;

var
  GCheckMarkCache: TCssCheckMarkCache = nil;

procedure EnsureCheckMarkCache;
begin
  if GCheckMarkCache = nil then
    GCheckMarkCache := TCssCheckMarkCache.Create;
end;

{ TCssCheckBox }

constructor TCssCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle - [csClickEvents];

  TabStop := True;

  Width := 120;
  Height := 20;

  Caption := 'CheckBox';
  FState := cbUnchecked;
  FAllowGrayed := False;

  FClicked := False;
  FSpacePressed := False;
  FClicking := False;

  ShowFocusRect := False;

  AutoSize := True;

  TCssStyledControl(Self).Caption := '';
end;

function TCssCheckBox.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

procedure TCssCheckBox.Loaded;
begin
  inherited Loaded;

  if AutoSize then
    AdjustSize;
end;

function TCssCheckBox.GetCheckBoxBackground: TColor;
begin
  if FBoxBackgroundSet then
  begin
    Result := FBoxBackground;
    Exit;
  end;

  Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := clWindow;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssCheckBox.GetCheckBoxBorderColor: TColor;
begin
  if FBoxBorderColorSet then
  begin
    Result := FBoxBorderColor;
    Exit;
  end;

  Result := GetCssBorderColor;

  if GetCssBorderWidth = 0 then
    Result := GetCssTextColor;
end;

function TCssCheckBox.GetCheckBoxBorderWidth: Integer;
begin
  if FBoxBorderWidthSet then
  begin
    Result := FBoxBorderWidth;
    Exit;
  end;

  Result := GetCssBorderWidth;

  if Result = 0 then
    Result := 1;
end;

function TCssCheckBox.GetCheckBoxRadius: Integer;
begin
  if FBoxRadiusSet then
    Result := FBoxRadius
  else
    Result := GetCssBorderRadius;
end;

function TCssCheckBox.GetCheckColor: TColor;
begin
  if FCheckColorSet then
    Result := FCheckColor
  else
    Result := GetCssTextColor;
end;

function TCssCheckBox.GetChecked: Boolean;
begin
  Result := FState = cbChecked;
end;

procedure TCssCheckBox.SetChecked(AValue: Boolean);
begin
  if AValue then
    State := cbChecked
  else
    State := cbUnchecked;
end;

procedure TCssCheckBox.SetState(AValue: TCheckBoxState);
begin
  if (AValue = cbGrayed) and (not FAllowGrayed) then
    AValue := cbUnchecked;

  if FState = AValue then
    Exit;

  FState := AValue;

  // Notify the base CSS engine whether the control is in :checked state.
  SetCssCheckedState(FState = cbChecked);

  Invalidate;
end;

procedure TCssCheckBox.SetAllowGrayed(AValue: Boolean);
begin
  if FAllowGrayed = AValue then
    Exit;

  FAllowGrayed := AValue;

  if (not FAllowGrayed) and (FState = cbGrayed) then
    State := cbUnchecked;
end;

procedure TCssCheckBox.ToggleState;
begin
  if not Enabled then
    Exit;

  if FAllowGrayed then
  begin
    case FState of
      cbUnchecked: State := cbChecked;
      cbChecked:   State := cbGrayed;
      cbGrayed:    State := cbUnchecked;
    end;
  end
  else
  begin
    Checked := not Checked;
  end;
end;

procedure TCssCheckBox.Toggle;
begin
  if FClicking or (not Enabled) then
    Exit;

  FClicking := True;

  try
    ToggleState;
    inherited Click;
  finally
    FClicking := False;
  end;
end;

procedure TCssCheckBox.Click;
begin
  Toggle;
end;

procedure TCssCheckBox.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckBox.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'checkbox-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FBoxBackground := C;
      FBoxBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'checkbox-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FBoxBorderColor := C;
      FBoxBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'checkbox-border-width' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FBoxBorderWidth := Px;
      FBoxBorderWidthSet := True;
    end;
    Exit;
  end;

  if AName = 'checkbox-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FBoxRadius := Px;
      FBoxRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'check-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FCheckColor := C;
      FCheckColorSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssCheckBox.StyleChanged;
begin
  inherited StyleChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckBox.NavigateStandalone(AKey: Word);
var
  List: TList;
  I, J: Integer;
  Current, Target, Delta, Steps: Integer;
  Temp: Pointer;
  Cb: TCssCheckBox;
begin
  if Parent = nil then
    Exit;

  List := TList.Create;

  try
    for I := 0 to Parent.ControlCount - 1 do
    begin
      if Parent.Controls[I] is TCssCheckBox then
        List.Add(Parent.Controls[I]);
    end;

    if List.Count <= 1 then
      Exit;

    // Sort by visual position: top to bottom, then left to right.
    for I := 0 to List.Count - 2 do
    begin
      for J := I + 1 to List.Count - 1 do
      begin
        if (TControl(List[I]).Top > TControl(List[J]).Top) or
           ((TControl(List[I]).Top = TControl(List[J]).Top) and
            (TControl(List[I]).Left > TControl(List[J]).Left)) then
        begin
          Temp := List[I];
          List[I] := List[J];
          List[J] := Temp;
        end;
      end;
    end;

    Current := List.IndexOf(Self);

    if Current < 0 then
      Exit;

    case AKey of
      VK_LEFT, VK_UP:   Delta := -1;
      VK_RIGHT, VK_DOWN: Delta := 1;
    else
      Exit;
    end;

    Target := Current;

    for Steps := 0 to List.Count - 1 do
    begin
      Target := Target + Delta;

      if Target < 0 then
        Target := List.Count - 1;

      if Target >= List.Count then
        Target := 0;

      if Target = Current then
        Break;

      Cb := TCssCheckBox(List[Target]);

      if Cb.Enabled and Cb.Visible then
      begin
        if Cb.CanFocus then
          Cb.SetFocus;

        Exit;
      end;
    end;
  finally
    List.Free;
  end;
end;

procedure TCssCheckBox.ResetStyle;
begin
  FBoxBackgroundSet := False;
  FBoxBorderColorSet := False;
  FBoxBorderWidthSet := False;
  FBoxRadiusSet := False;
  FCheckColorSet := False;
  inherited ResetStyle;
end;

procedure TCssCheckBox.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssCheckBox.DoEnter;
begin
  inherited DoEnter;

  SetFocusedState(True);
  Invalidate;
end;

procedure TCssCheckBox.DoExit;
begin
  SetFocusedState(False);

  inherited DoExit;
  Invalidate;
end;

procedure TCssCheckBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  if (ssCtrl in Shift) or (ssAlt in Shift) then
    Exit;

  if (Key = VK_LEFT) or
     (Key = VK_RIGHT) or
     (Key = VK_UP) or
     (Key = VK_DOWN) then
  begin
    if Parent is TCssCheckGroup then
      TCssCheckGroup(Parent).NavigateFrom(Self, Key)
    else
      NavigateStandalone(Key);

    Key := 0;
    Exit;
  end;

  if Key = VK_SPACE then
  begin
    FSpacePressed := True;
    SetMousePressedState(True);
    Key := 0;
  end;
end;

procedure TCssCheckBox.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and FSpacePressed then
  begin
    FSpacePressed := False;

    SetMousePressedState(False);

    if Enabled then
      Toggle;

    Key := 0;
  end;

  inherited KeyUp(Key, Shift);
end;

procedure TCssCheckBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Enabled and (Button = mbLeft) then
  begin
    if CanFocus then
      SetFocus;

    FClicked := True;
  end;
end;

procedure TCssCheckBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DoToggle: Boolean;
begin
  DoToggle :=
    Enabled and
    (Button = mbLeft) and
    FClicked and
    PtInRect(ClientRect, Point(X, Y));

  inherited MouseUp(Button, Shift, X, Y);

  FClicked := False;

  if DoToggle then
    Toggle;
end;

procedure TCssCheckBox.MouseLeave;
begin
  FClicked := False;

  inherited MouseLeave;
end;

function TCssCheckBox.GetBoxSize: Integer;
begin
  if HandleAllocated then
  begin
    AssignCssFontToFont(Canvas.Font);

    Result := Canvas.TextHeight('Ag');

    if Result < 13 then
      Result := 13;

    if Result > 25 then
      Result := 25;
  end
  else
  begin
    Result := 16;
  end;
end;

procedure TCssCheckBox.DrawCheckMark(const R: TRect; AColor: TColor);
begin
  DrawCheckMarkToCanvas(Canvas, R, AColor);
end;

procedure TCssCheckBox.DrawGrayedMark(const R: TRect; AColor: TColor);
begin
  DrawGrayedMarkToCanvas(Canvas, R, AColor);
end;

procedure TCssCheckBox.Paint;
var
  R, Box, TextR: TRect;
  B: Integer;
  P: TRect;
  BoxSize: Integer;
  TextColor: TColor;
begin
  inherited Paint;

  R := ClientRect;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  R.Left := R.Left + B + P.Left;
  R.Top := R.Top + B + P.Top;
  R.Right := R.Right - B - P.Right;
  R.Bottom := R.Bottom - B - P.Bottom;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  BoxSize := GetBoxSize;

  Box.Left := R.Left;
  Box.Top := R.Top + (((R.Bottom - R.Top) - BoxSize) div 2);
  Box.Right := Box.Left + BoxSize;
  Box.Bottom := Box.Top + BoxSize;

  AssignCssFontToFont(Canvas.Font);

  TextColor := GetCssTextColor;

  DrawStateToCanvas(Canvas, Box, FState);

  TextR := Rect(Box.Right + 4, R.Top, R.Right, R.Bottom);

  Canvas.Font.Color := TextColor;

  if HtmlMode then
    DrawHtmlText(TextR, Caption)
  else
    DrawStyledText(TextR, Caption);

  if Focused and ShowFocusRect and Enabled then
    DrawFocusRect(Canvas, R);
end;

procedure TCssCheckBox.AdjustSize;
var
  S: TSize;
  P: TRect;
  B: Integer;
  BoxSize: Integer;
  Spacing: Integer;
  NewWidth, NewHeight: Integer;
  TextToMeasure: string;
begin
  if (csDestroying in ComponentState) or
     (csLoading in ComponentState) or
     (Align <> alNone) or
     (not AutoSize) or
     (not HandleAllocated) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  B := GetCssBorderWidth;
  P := GetCssPadding;

  BoxSize := GetBoxSize;
  Spacing := 4;

  TextToMeasure := Caption;

  if HtmlMode then
    TextToMeasure := HtmlToPlainText(TextToMeasure);

  S := MeasurePlainText(Canvas, TextToMeasure);

  NewWidth :=
    (B * 2) +
    P.Left +
    P.Right +
    BoxSize +
    Spacing +
    S.cx;

  NewHeight :=
    (B * 2) +
    P.Top +
    P.Bottom +
    BoxSize;

  if S.cy > NewHeight then
    NewHeight :=
      (B * 2) +
      P.Top +
      P.Bottom +
      S.cy;

  if NewWidth < 0 then
    NewWidth := 0;

  if NewHeight < 0 then
    NewHeight := 0;

  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);

  inherited AdjustSize;
end;

function TCssCheckBox.MeasureBoxSize(ACanvas: TCanvas): Integer;
var
  SavedFont: TFont;
begin
  if ACanvas = nil then
    Exit(GetBoxSize);

  SavedFont := TFont.Create;
  try
    SavedFont.Assign(ACanvas.Font);

    AssignCssFontToFont(ACanvas.Font);
    Result := ACanvas.TextHeight('Ag');
  finally
    ACanvas.Font.Assign(SavedFont);
    SavedFont.Free;
  end;

  if Result < 13 then
    Result := 13;

  if Result > 25 then
    Result := 25;
end;

procedure TCssCheckBox.SetVisualState(AChecked, AHover: Boolean);
begin
  if AChecked then
    Checked := True
  else
    Checked := False;

  SetMouseInControlState(AHover);
end;

procedure TCssCheckBox.DrawCheckMarkToCanvas(
  ACanvas: TCanvas;
  const R: TRect;
  AColor: TColor
);
var
  W, H: Integer;
  LineWidth: Double;
  BgColor: TColor;
  Bmp: TBitmap;
begin
  if ACanvas = nil then
    Exit;

  W := R.Right - R.Left;
  H := R.Bottom - R.Top;

  if (W <= 0) or (H <= 0) then
    Exit;

  if W < 12 then
    LineWidth := 1.5
  else if W < 20 then
    LineWidth := 2.0
  else
    LineWidth := 2.5;

  BgColor := GetCheckBoxBackground;

  EnsureCheckMarkCache;
  Bmp := GCheckMarkCache.GetBitmap(W, H, AColor, BgColor, LineWidth);

  ACanvas.Draw(R.Left, R.Top, Bmp);
end;

procedure TCssCheckBox.DrawGrayedMarkToCanvas(
  ACanvas: TCanvas;
  const R: TRect;
  AColor: TColor
);
var
  GR: TRect;
begin
  if ACanvas = nil then
    Exit;

  GR := Rect(R.Left + 3, R.Top + 3, R.Right - 3, R.Bottom - 3);

  if (GR.Right > GR.Left) and (GR.Bottom > GR.Top) then
  begin
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AColor;
    ACanvas.FillRect(GR);
  end;
end;

procedure TCssCheckBox.SetCaption(const AValue: TCaption);
begin
  if Caption = AValue then Exit;
  inherited SetCaption(AValue);
  if AutoSize then
    AdjustSize;
end;

procedure TCssCheckBox.DrawStateToCanvas(
  ACanvas: TCanvas;
  const ARect: TRect;
  AState: TCheckBoxState
);
var
  BG: TColor;
  BorderColor: TColor;
  CheckColor: TColor;
  LBorderWidth: Integer;
  Radius: Integer;
  Size: Integer;
begin
  if ACanvas = nil then
    Exit;

  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  Size := ARect.Bottom - ARect.Top;

  if (ARect.Right - ARect.Left) < Size then
    Size := ARect.Right - ARect.Left;

  BG := GetCheckBoxBackground;
  BorderColor := GetCheckBoxBorderColor;
  LBorderWidth := GetCheckBoxBorderWidth;
  Radius := GetCheckBoxRadius;
  CheckColor := GetCheckColor;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := BG;

  if LBorderWidth <= 0 then
  begin
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Color := BG;
  end
  else
  begin
    ACanvas.Pen.Width := LBorderWidth;
    ACanvas.Pen.Color := BorderColor;
  end;

  ACanvas.Pen.Style := psSolid;

  if Radius > (Size div 2) then
    Radius := Size div 2;

  if Radius > 0 then
    ACanvas.RoundRect(
      ARect.Left,
      ARect.Top,
      ARect.Right,
      ARect.Bottom,
      Radius,
      Radius
    )
  else
    ACanvas.Rectangle(
      ARect.Left,
      ARect.Top,
      ARect.Right,
      ARect.Bottom
    );

  if AState = cbChecked then
    DrawCheckMarkToCanvas(ACanvas, ARect, CheckColor)
  else if AState = cbGrayed then
    DrawGrayedMarkToCanvas(ACanvas, ARect, CheckColor);
end;

procedure TCssCheckBox.DrawToCanvas(
  ACanvas: TCanvas;
  const ARect: TRect
);
begin
  DrawStateToCanvas(ACanvas, ARect, FState);
end;

{ TCssCheckGroup }

constructor TCssCheckGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := False;

  Width := 185;
  Height := 105;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;

  FCheckBoxes := TList.Create;

  FAllowGrayed := False;
  FColumns := 1;
  FItemHeight := 0;
  FItemIndex := -1;

  FCheckBoxCssClass := 'checkbox';
  FCheckBoxCssStyle := '';

  Caption := 'CheckGroup';

  TCssStyledControl(Self).Caption := '';

  FFocusIndex := -1;
  ShowFocusRect := False;
end;

destructor TCssCheckGroup.Destroy;
begin
  FItems.OnChange := nil;

  FCheckBoxes.Clear;

  FreeAndNil(FItems);
  FreeAndNil(FCheckBoxes);

  inherited Destroy;
end;

procedure TCssCheckGroup.Loaded;
begin
  inherited Loaded;

  SyncStateArrays;
  RebuildItems;
  UpdateChildStyles;
  LayoutItems;

  if AutoSize then
    AdjustSize;
end;

procedure TCssCheckGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  if (ssCtrl in Shift) or (ssAlt in Shift) then
    Exit;

  if (Key = VK_LEFT) or
     (Key = VK_RIGHT) or
     (Key = VK_UP) or
     (Key = VK_DOWN) then
  begin
    NavigateArrow(Key);
    Key := 0;
  end;
end;

procedure TCssCheckGroup.CreateWnd;
begin
  inherited CreateWnd;

  if Assigned(FCheckBoxes) and (FCheckBoxes.Count > 0) then
  begin
    LayoutItems;

    if AutoSize then
      AdjustSize;
  end;
end;

procedure TCssCheckGroup.MouseEnter;
begin
  FInMouseStateChange := True;
  try
    inherited MouseEnter;
  finally
    FInMouseStateChange := False;
  end;
end;

procedure TCssCheckGroup.MouseLeave;
begin
  FInMouseStateChange := True;
  try
    inherited MouseLeave;
  finally
    FInMouseStateChange := False;
  end;
end;

procedure TCssCheckGroup.SetShowFocusRect(AValue: Boolean);
begin
  inherited;

  ApplyChildShowFocusRect;
end;

procedure TCssCheckGroup.ApplyChildShowFocusRect;
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  if not Assigned(FCheckBoxes) then
    Exit;

  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if Assigned(Cb) then
      Cb.ShowFocusRect := ShowFocusRect;
  end;
end;

procedure TCssCheckGroup.ItemEnter(Sender: TObject);
begin
  if Sender is TCssCheckBox then
    FFocusIndex := TCssCheckBox(Sender).Tag;
end;

procedure TCssCheckGroup.NavigateFromIndex(AIndex: Integer; AKey: Word);
var
  Count, ColCount, Target: Integer;
begin
  Count := FItems.Count;

  if Count = 0 then
    Exit;

  ColCount := GetColumns;

  case AKey of
    VK_LEFT:  Target := FindEnabledCheckBox(AIndex, -1, True);
    VK_RIGHT: Target := FindEnabledCheckBox(AIndex, 1, True);
    VK_UP:    Target := FindEnabledCheckBox(AIndex, -ColCount, True);
    VK_DOWN:  Target := FindEnabledCheckBox(AIndex, ColCount, True);
  else
    Exit;
  end;

  // If vertical movement gave no result, fall back to linear navigation.
  if Target = AIndex then
  begin
    if AKey = VK_UP then
      Target := FindEnabledCheckBox(AIndex, -1, True)
    else if AKey = VK_DOWN then
      Target := FindEnabledCheckBox(AIndex, 1, True);
  end;

  if (Target >= 0) and (Target <> AIndex) then
    FocusItem(Target);
end;

procedure TCssCheckGroup.SetItems(AValue: TStrings);
begin
  FUpdating := True;

  try
    if AValue = nil then
      FItems.Clear
    else
      FItems.Assign(AValue);
  finally
    FUpdating := False;
  end;

  ItemsChanged(Self);
end;

procedure TCssCheckGroup.ItemsChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  if (csLoading in ComponentState) or
     (csDestroying in ComponentState) then
    Exit;

  SyncStateArrays;
  RebuildItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckGroup.SyncStateArrays;
var
  OldCount, NewCount, I: Integer;
begin
  OldCount := Length(FStates);
  NewCount := FItems.Count;

  SetLength(FStates, NewCount);
  SetLength(FItemEnabled, NewCount);

  for I := OldCount to NewCount - 1 do
  begin
    FStates[I] := cbUnchecked;
    FItemEnabled[I] := True;
  end;
end;

function TCssCheckGroup.GetColumns: Integer;
begin
  if FColumns < 1 then
    Result := 1
  else
    Result := FColumns;
end;

function TCssCheckGroup.GetCheckBox(Index: Integer): TCssCheckBox;
begin
  if (Index >= 0) and (Index < FCheckBoxes.Count) then
    Result := TCssCheckBox(FCheckBoxes[Index])
  else
    Result := nil;
end;

procedure TCssCheckGroup.RebuildItems;
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  if csDestroying in ComponentState then
    Exit;

  FUpdating := True;

  try
    for I := FCheckBoxes.Count - 1 downto 0 do
      TCssCheckBox(FCheckBoxes[I]).Free;

    FCheckBoxes.Clear;

    SyncStateArrays;

    FFocusIndex := -1;

    for I := 0 to FItems.Count - 1 do
    begin
      Cb := TCssCheckBox.Create(Self);
      Cb.Parent := Self;
      Cb.ShowFocusRect := ShowFocusRect;

      Cb.Tag := I;
      Cb.AutoSize := False;
      Cb.TabStop := True;
      Cb.TabOrder := I;

      Cb.Caption := FItems[I];

      Cb.AllowGrayed := FAllowGrayed;
      Cb.HtmlMode := HtmlMode;

      Cb.HintHtmlMode := HintHtmlMode;
      Cb.ShowHint := ShowHint;
      Cb.Hint := Hint;

      Cb.CssTag := 'checkbox';
      Cb.CssClass := FCheckBoxCssClass;
      Cb.CssStyle := FCheckBoxCssStyle;

      Cb.StyleProvider := StyleProvider;
      Cb.StyleName := StyleName;

      Cb.State := FStates[I];
      FStates[I] := Cb.State;

      Cb.Enabled := Enabled and FItemEnabled[I];

      Cb.OnClick := @ItemCheckBoxClick;
      Cb.OnEnter := @ItemEnter;

      FCheckBoxes.Add(Cb);
    end;
  finally
    FUpdating := False;
  end;

  LayoutItems;
end;

procedure TCssCheckGroup.UpdateChildStyles;
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if not Assigned(Cb) then
      Continue;

    if Cb.StyleProvider <> StyleProvider then
      Cb.StyleProvider := StyleProvider;

    if Cb.StyleName <> StyleName then
      Cb.StyleName := StyleName;

    Cb.CssClass := FCheckBoxCssClass;
    Cb.CssStyle := FCheckBoxCssStyle;
    Cb.HtmlMode := HtmlMode;
    Cb.HintHtmlMode := HintHtmlMode;
    Cb.ShowHint := ShowHint;
    Cb.Hint := Hint;
    Cb.AllowGrayed := FAllowGrayed;

    if I < Length(FItemEnabled) then
      Cb.Enabled := Enabled and FItemEnabled[I]
    else
      Cb.Enabled := Enabled;
  end;

  ApplyChildShowFocusRect;

  LayoutItems;
  Invalidate;
end;

procedure TCssCheckGroup.RefreshChildStyles;
begin
  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

function TCssCheckGroup.GetItemHeight: Integer;
begin
  if FItemHeight > 0 then
    Exit(FItemHeight);

  if HandleAllocated then
  begin
    AssignCssFontToFont(Canvas.Font);

    Result := Canvas.TextHeight('Ag') + 6;

    if Result < 18 then
      Result := 18;
  end
  else
  begin
    Result := 20;
  end;
end;

procedure TCssCheckGroup.LayoutItems;
var
  ClientR: TRect;
  B: Integer;
  P: TRect;
  CapH: Integer;
  ItemH: Integer;
  ColW: Integer;
  ColCount: Integer;
  ContentLeft: Integer;
  ContentRight: Integer;
  ContentWidth: Integer;
  ContentTop: Integer;
  TopBlock: Integer;
  I, Row, Col, X, Y: Integer;
  Cb: TCssCheckBox;
begin
  if FCheckBoxes.Count = 0 then
    Exit;

  ClientR := ClientRect;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  ContentLeft := ClientR.Left + B + P.Left;
  ContentRight := ClientR.Right - B - P.Right;

  ContentWidth := ContentRight - ContentLeft;

  if ContentWidth < 0 then
    ContentWidth := 0;

  CapH := GetCaptionHeight(ContentWidth);
  ItemH := GetItemHeight;
  ColCount := GetColumns;

  if CaptionMode = gcmInside then
  begin
    ContentTop := ClientR.Top + B + P.Top + CapH;
  end
  else
  begin
    TopBlock := B;

    if CapH > TopBlock then
      TopBlock := CapH;

    ContentTop := ClientR.Top + TopBlock + P.Top;
  end;

  ColW := ContentWidth div ColCount;

  if ColW < 0 then
    ColW := 0;

  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if not Assigned(Cb) then
      Continue;

    Row := I div ColCount;
    Col := I mod ColCount;

    X := ContentLeft + (Col * ColW);
    Y := ContentTop + (Row * ItemH);

    Cb.SetBounds(X, Y, ColW, ItemH);
  end;
end;

function TCssCheckGroup.GetChecked(Index: Integer): Boolean;
begin
  Result := State[Index] = cbChecked;
end;

procedure TCssCheckGroup.SetChecked(Index: Integer; AValue: Boolean);
begin
  if AValue then
    State[Index] := cbChecked
  else
    State[Index] := cbUnchecked;
end;

function TCssCheckGroup.GetState(Index: Integer): TCheckBoxState;
var
  Cb: TCssCheckBox;
begin
  Cb := GetCheckBox(Index);

  if Assigned(Cb) then
    Result := Cb.State
  else
  begin
    if (Index >= 0) and (Index < Length(FStates)) then
      Result := FStates[Index]
    else
      Result := cbUnchecked;
  end;
end;

procedure TCssCheckGroup.SetState(Index: Integer; AValue: TCheckBoxState);
var
  Cb: TCssCheckBox;
begin
  if (Index < 0) or (Index >= FItems.Count) then
    Exit;

  if (AValue = cbGrayed) and (not FAllowGrayed) then
    AValue := cbUnchecked;

  if Index >= Length(FStates) then
    SyncStateArrays;

  FStates[Index] := AValue;

  Cb := GetCheckBox(Index);

  if Assigned(Cb) then
  begin
    Cb.State := AValue;
    FStates[Index] := Cb.State;
  end;
end;

function TCssCheckGroup.GetItemEnabled(Index: Integer): Boolean;
begin
  if (Index >= 0) and (Index < Length(FItemEnabled)) then
    Result := FItemEnabled[Index]
  else
    Result := True;
end;

procedure TCssCheckGroup.SetItemEnabled(Index: Integer; AValue: Boolean);
var
  Cb: TCssCheckBox;
begin
  if (Index < 0) or (Index >= FItems.Count) then
    Exit;

  if Index >= Length(FItemEnabled) then
    SyncStateArrays;

  FItemEnabled[Index] := AValue;

  Cb := GetCheckBox(Index);

  if Assigned(Cb) then
    Cb.Enabled := Enabled and AValue;
end;

procedure TCssCheckGroup.SetAllowGrayed(AValue: Boolean);
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  if FAllowGrayed = AValue then
    Exit;

  FAllowGrayed := AValue;

  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if not Assigned(Cb) then
      Continue;

    Cb.AllowGrayed := AValue;

    if (not AValue) and (I < Length(FStates)) and (FStates[I] = cbGrayed) then
    begin
      FStates[I] := cbUnchecked;
      Cb.State := cbUnchecked;
    end;
  end;
end;

procedure TCssCheckGroup.SetColumns(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FColumns = AValue then
    Exit;

  FColumns := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckGroup.SetItemHeight(AValue: Integer);
begin
  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckGroup.SetCheckBoxCssClass(const AValue: string);
begin
  if FCheckBoxCssClass = AValue then
    Exit;

  FCheckBoxCssClass := AValue;

  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

procedure TCssCheckGroup.SetCheckBoxCssStyle(const AValue: string);
begin
  if FCheckBoxCssStyle = AValue then
    Exit;

  FCheckBoxCssStyle := AValue;

  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

procedure TCssCheckGroup.ItemCheckBoxClick(Sender: TObject);
var
  Cb: TCssCheckBox;
  Idx: Integer;
begin
  if not (Sender is TCssCheckBox) then
    Exit;

  Cb := TCssCheckBox(Sender);
  Idx := Cb.Tag;

  if (Idx >= 0) and (Idx < Length(FStates)) then
    FStates[Idx] := Cb.State;

  FItemIndex := Idx;

  if Assigned(FOnItemClickNotify) then
    FOnItemClickNotify(Self);

  if Assigned(FOnItemClick) then
    FOnItemClick(Self, Idx);
end;

function TCssCheckGroup.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TCssCheckGroup.Clear;
begin
  Items.Clear;
end;

procedure TCssCheckGroup.CheckAll(AState: TCheckBoxState);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    State[I] := AState;
end;

procedure TCssCheckGroup.HtmlModeChanged;
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  inherited HtmlModeChanged;

  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if Assigned(Cb) then
      Cb.HtmlMode := HtmlMode;
  end;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssCheckGroup.StyleChanged;
begin
  inherited StyleChanged;

  if FInMouseStateChange then
  begin
    // On mouse enter/leave only :hover usually changes.
    // Full rebuild of child checkboxes and layout is not needed here.
    Invalidate;
    Exit;
  end;

  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

procedure TCssCheckGroup.EnabledChanged;
var
  I: Integer;
  Cb: TCssCheckBox;
begin
  inherited EnabledChanged;

  for I := 0 to FCheckBoxes.Count - 1 do
  begin
    Cb := GetCheckBox(I);

    if not Assigned(Cb) then
      Continue;

    if I < Length(FItemEnabled) then
      Cb.Enabled := Enabled and FItemEnabled[I]
    else
      Cb.Enabled := Enabled;
  end;
end;

procedure TCssCheckGroup.Paint;
var
  R: TRect;
  B: Integer;
  P: TRect;
  CapH: Integer;
  ContentWidth: Integer;
  CaptionRect: TRect;
  CaptionX, CaptionY, CaptionW: Integer;
  S: TSize;
begin
  inherited Paint;

  if Caption = '' then
    Exit;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  ContentWidth := ClientWidth - (B * 2) - P.Left - P.Right;

  if ContentWidth < 0 then
    ContentWidth := 0;

  CapH := GetCaptionHeight(ContentWidth);

  if CapH <= 0 then
    Exit;

  AssignCssFontToFont(Canvas.Font);
  Canvas.Font.Color := GetCssTextColor;

  if CaptionMode = gcmInside then
  begin
    R := ClientRect;

    R.Left := R.Left + B + P.Left;
    R.Top := R.Top + B + P.Top;
    R.Right := R.Right - B - P.Right;
    R.Bottom := R.Bottom - B - P.Bottom;

    if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
      Exit;

    CaptionRect := Rect(R.Left, R.Top, R.Right, R.Top + CapH);

    if HtmlMode then
      DrawHtmlText(CaptionRect, Caption)
    else
      DrawStyledText(CaptionRect, Caption);
  end
  else
  begin
    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(Caption, ContentWidth);
    end
    else
    begin
      S.cx := Canvas.TextWidth(Caption);
      S.cy := Canvas.TextHeight('Ag');
    end;

    CaptionW := S.cx + 6;

    CaptionX := B + P.Left;

    if CaptionX < B + 2 then
      CaptionX := B + 2;

    CaptionY := 0;

    CaptionRect := Rect(
      CaptionX - 3,
      CaptionY,
      CaptionX + CaptionW,
      CaptionY + CapH
    );

    if CaptionRect.Left < 0 then
      CaptionRect.Left := 0;

    if CaptionRect.Top < 0 then
      CaptionRect.Top := 0;

    if CaptionRect.Right > ClientWidth then
      CaptionRect.Right := ClientWidth;

    if CaptionRect.Bottom > ClientHeight then
      CaptionRect.Bottom := ClientHeight;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetCaptionBackground;
    Canvas.FillRect(CaptionRect);

    if HtmlMode then
      DrawHtmlText(CaptionRect, Caption)
    else
      DrawStyledText(CaptionRect, Caption);
  end;
end;

procedure TCssCheckGroup.AdjustSize;
var
  B: Integer;
  P: TRect;
  CapH: Integer;
  ItemH: Integer;
  RowCount: Integer;
  TopSpace: Integer;
  TopBlock: Integer;
  NewHeight: Integer;
begin
  if (csDestroying in ComponentState) or
     (csLoading in ComponentState) or
     (Align <> alNone) or
     (not AutoSize) or
     (not HandleAllocated) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  CapH := GetCaptionHeight(Width - (B * 2) - P.Left - P.Right);
  ItemH := GetItemHeight;

  if FItems.Count > 0 then
    RowCount := (FItems.Count + GetColumns - 1) div GetColumns
  else
    RowCount := 0;

  if CaptionMode = gcmInside then
  begin
    TopSpace := B + P.Top + CapH;
  end
  else
  begin
    TopBlock := B;

    if CapH > TopBlock then
      TopBlock := CapH;

    TopSpace := TopBlock + P.Top;
  end;

  NewHeight :=
    TopSpace +
    (RowCount * ItemH) +
    P.Bottom +
    B;

  if NewHeight < 0 then
    NewHeight := 0;

  if NewHeight <> Height then
    SetBounds(Left, Top, Width, NewHeight);

  inherited AdjustSize;
end;

function TCssCheckGroup.FindEnabledCheckBox(AStart, ADelta: Integer; AWrap: Boolean): Integer;
var
  Count, I, Steps: Integer;
  Cb: TCssCheckBox;
begin
  Result := -1;

  Count := FItems.Count;

  if Count = 0 then
    Exit;

  I := AStart;

  for Steps := 0 to Count - 1 do
  begin
    I := I + ADelta;

    if I < 0 then
    begin
      if AWrap then
        I := Count - 1
      else
        Exit;
    end;

    if I >= Count then
    begin
      if AWrap then
        I := 0
      else
        Exit;
    end;

    if (I >= 0) and (I < Length(FItemEnabled)) and FItemEnabled[I] then
    begin
      Cb := GetCheckBox(I);

      if Assigned(Cb) and Cb.Enabled and Cb.Visible then
        Exit(I);
    end;
  end;
end;

procedure TCssCheckGroup.FocusItem(Index: Integer);
var
  Cb: TCssCheckBox;
begin
  Cb := GetCheckBox(Index);

  if not Assigned(Cb) then
    Exit;

  if not Cb.Enabled or not Cb.Visible then
    Exit;

  if Cb.CanFocus then
  begin
    FFocusIndex := Index;
    Cb.SetFocus;
  end;
end;

procedure TCssCheckGroup.NavigateArrow(AKey: Word);
var
  Count, Target, Start: Integer;
begin
  Count := FItems.Count;

  if Count = 0 then
    Exit;

  Start := FFocusIndex;

  if (Start < 0) or (Start >= Count) then
    Start := FItemIndex;

  if (Start < 0) or (Start >= Count) then
  begin
    if (AKey = VK_RIGHT) or (AKey = VK_DOWN) then
      Target := FindEnabledCheckBox(-1, 1, False)
    else
      Target := FindEnabledCheckBox(Count, -1, False);

    if Target >= 0 then
      FocusItem(Target);

    Exit;
  end;

  NavigateFromIndex(Start, AKey);
end;

procedure TCssCheckGroup.NavigateFrom(AControl: TControl; AKey: Word);
var
  Idx: Integer;
begin
  Idx := -1;

  if AControl is TCssCheckBox then
    Idx := TCssCheckBox(AControl).Tag;

  if (Idx < 0) or (Idx >= FItems.Count) then
    Idx := FFocusIndex;

  if (Idx < 0) or (Idx >= FItems.Count) then
    Idx := FItemIndex;

  if (Idx < 0) or (Idx >= FItems.Count) then
  begin
    NavigateArrow(AKey);
    Exit;
  end;

  NavigateFromIndex(Idx, AKey);
end;

initialization

finalization
  FreeAndNil(GCheckMarkCache);

end.
