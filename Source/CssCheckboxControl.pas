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
    FToggleStyle: Boolean;
    FToggleWidth, FToggleHeight: Integer;
    FToggleThumbColor: TColor;
    FToggleThumbColorSet: Boolean;

    // Property getters
    function GetCheckBoxBackground: TColor;
    function GetCheckBoxBorderColor: TColor;
    function GetCheckBoxBorderWidth: Integer;
    function GetCheckBoxRadius: Integer;
    function GetCheckColor: TColor;
    function GetChecked: Boolean;
    function GetBoxSize: Integer;
    function GetBoxWidth: Integer;
    function GetBoxHeight: Integer;
    function GetToggleThumbColor: TColor;

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

    function GetDefaultCaption: string; override;
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
    FGroupFocusRect: Boolean;
    FChildFocused: Boolean;

    // Private helpers
    procedure ApplyChildShowFocusRect;
    procedure ItemEnter(Sender: TObject);
    procedure ItemExit(Sender: TObject);
    procedure SetGroupFocusRect(AValue: Boolean);
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

    // Hover
    function GetEffectiveHoverState: Boolean; override;

    // Painting
    procedure Paint; override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Mouse
    procedure MouseEnter; override;
    procedure MouseLeave; override;

    function GetDefaultCaption: string; override;
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
    property GroupFocusRect: Boolean read FGroupFocusRect write SetGroupFocusRect default True;

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
  TCssCheckMarkMaskEntry = class
    Width, Height: Integer;
    LineWidthX10: Integer;
    Coverage: array of Byte;   // W * H, 0..255
    constructor Create;
    function Matches(AW, AH: Integer; ALineWidth: Double): Boolean;
  end;

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

  PRGBQuadItem = ^TRGBQuadItem;
  TRGBQuadItem = packed record
    B, G, R, A: Byte;
  end;

const
  CSS_CHECKMARK_CACHE_LIMIT = 48;

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

  BuildCheckMarkCoverage(
    E.Coverage, AW, AH,
    X1, Y1, X2, Y2, X3, Y3,
    ALineWidth
  );

  FEntries.Add(E);
  Result := E;
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

  FState := cbUnchecked;
  FAllowGrayed := False;
  FToggleStyle := False;
  FToggleWidth := 40;
  FToggleHeight := 20;
  FToggleThumbColorSet := False;

  FClicked := False;
  FSpacePressed := False;
  FClicking := False;

  ShowFocusRect := False;

  AutoSize := True;
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
  V: string;
begin
  if AName = 'checkbox-style' then
  begin
    V := LowerCase(Trim(AValue));
    FToggleStyle := (V = 'toggle') or (V = 'switch');
    if AutoSize then AdjustSize;
    Invalidate;
    Exit;
  end;

  if (AName = 'toggle-width') or (AName = 'toggle-height') then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      if AName = 'toggle-width' then
      begin
        FToggleWidth := Px;
        if FToggleWidth < 12 then FToggleWidth := 12;
        if FToggleWidth > 200 then FToggleWidth := 200;
      end
      else
      begin
        FToggleHeight := Px;
        if FToggleHeight < 12 then FToggleHeight := 12;
        if FToggleHeight > 80 then FToggleHeight := 80;
      end;
      if AutoSize then AdjustSize;
      Invalidate;
    end;
    Exit;
  end;

  if AName = 'toggle-thumb-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FToggleThumbColor := C;
      FToggleThumbColorSet := True;
    end;
    Exit;
  end;

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

function TCssCheckBox.GetDefaultCaption : string;
begin
  Result := 'CssCheckBox';
end;

procedure TCssCheckBox.ResetStyle;
begin
  FBoxBackgroundSet := False;
  FBoxBorderColorSet := False;
  FBoxBorderWidthSet := False;
  FBoxRadiusSet := False;
  FCheckColorSet := False;
  FToggleStyle := False;
  FToggleWidth := 40;
  FToggleHeight := 20;
  FToggleThumbColorSet := False;
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

function TCssCheckBox.GetBoxWidth: Integer;
begin
  if FToggleStyle then Result := FToggleWidth else Result := GetBoxSize;
end;

function TCssCheckBox.GetBoxHeight: Integer;
begin
  if FToggleStyle then Result := FToggleHeight else Result := GetBoxSize;
end;

function TCssCheckBox.GetToggleThumbColor: TColor;
begin
  if FToggleThumbColorSet then Result := FToggleThumbColor
  else if FCheckColorSet then Result := FCheckColor
  else Result := clWhite;
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
  BoxSize, BoxHeight: Integer;
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

  BoxSize := GetBoxWidth;
  BoxHeight := GetBoxHeight;

  Box.Left := R.Left;
  Box.Top := R.Top + (((R.Bottom - R.Top) - BoxHeight) div 2);
  Box.Right := Box.Left + BoxSize;
  Box.Bottom := Box.Top + BoxHeight;

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
  BoxSize, BoxHeight: Integer;
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

  BoxSize := GetBoxWidth;
  BoxHeight := GetBoxHeight;
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
    BoxHeight;

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
  Mask: TCssCheckMarkMaskEntry;
begin
  if ACanvas = nil then Exit;

  W := R.Right - R.Left;
  H := R.Bottom - R.Top;

  if (W <= 0) or (H <= 0) then Exit;

  if W < 12 then
    LineWidth := 1.5
  else if W < 20 then
    LineWidth := 2.0
  else
    LineWidth := 2.5;

  EnsureCheckMarkCache;
  Mask := GCheckMarkCache.GetMask(W, H, LineWidth);

  BlendCoverageToCanvas(
    ACanvas,
    R.Left, R.Top,
    W, H,
    Mask.Coverage,
    AColor
  );
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
  AState: TCheckBoxState);
var
  BG, BorderColor, CheckColor: TColor;
  LBorderWidth, Radius, Size: Integer;
  ABorderStyle: TCssBorderStyle;
  ParentBG: TColor;
begin
  if ACanvas = nil then Exit;
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then Exit;

  Size := ARect.Bottom - ARect.Top;
  if (ARect.Right - ARect.Left) < Size then
    Size := ARect.Right - ARect.Left;

  BG := GetCheckBoxBackground;
  BorderColor := GetCheckBoxBorderColor;
  LBorderWidth := GetCheckBoxBorderWidth;
  Radius := GetCheckBoxRadius;
  CheckColor := GetCheckColor;

  if FToggleStyle then
  begin
    Size := ARect.Bottom - ARect.Top;
    Radius := Size div 2;
    DrawAntiAliasedRoundedBox(ACanvas, ARect, Radius, BG, BorderColor,
      LBorderWidth, cbsSolid, GetParentBackgroundColor);
    Size := ARect.Bottom - ARect.Top;
    if Size > ARect.Right - ARect.Left then
      Size := ARect.Right - ARect.Left;
    Dec(Size, 8);
    if Size < 2 then Size := 2;
    { DrawAntiAliasedCircle composites its rectangular bitmap using the track
      color outside the circle. A 4px inset keeps those corners clear of the
      AA outline at the rounded ends, while centering the thumb in each end. }
    if AState = cbChecked then
      Radius := ARect.Right - ARect.Left - Size - 4
    else if AState = cbGrayed then
      Radius := (ARect.Right - ARect.Left - Size) div 2
    else
      Radius := 4;
    if Radius < 4 then Radius := 4;
    DrawAntiAliasedCircle(ACanvas,
      Rect(ARect.Left + Radius, ARect.Top + ((ARect.Bottom - ARect.Top - Size) div 2),
           ARect.Left + Radius + Size, ARect.Top + ((ARect.Bottom - ARect.Top - Size) div 2) + Size),
      GetToggleThumbColor, GetToggleThumbColor, 0, BG);
    Exit;
  end;

  if Radius > (Size div 2) then
    Radius := Size div 2;

  if LBorderWidth <= 0 then
    ABorderStyle := cbsNone
  else
    ABorderStyle := cbsSolid;

  ParentBG := GetParentBackgroundColor;

  DrawAntiAliasedRoundedBox(
    ACanvas,
    ARect,
    Radius,
    BG,
    BorderColor,
    LBorderWidth,
    ABorderStyle,
    ParentBG
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

  TCssStyledControl(Self).Caption := '';

  FFocusIndex := -1;
  FGroupFocusRect := True;
  FChildFocused := False;
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

function TCssCheckGroup.GetDefaultCaption : string;
begin
  Result := 'CssCheckGroup';
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

  if not FChildFocused then
  begin
    FChildFocused := True;
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssCheckGroup.ItemExit(Sender : TObject);
begin
  if FChildFocused then
  begin
    FChildFocused := False;
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssCheckGroup.SetGroupFocusRect(AValue : Boolean);
begin
  if FGroupFocusRect = AValue then
    Exit;

  FGroupFocusRect := AValue;
  Invalidate;
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
    FChildFocused := False;

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
      Cb.OnExit  := @ItemExit;

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

function TCssCheckGroup.GetEffectiveHoverState : Boolean;
begin
  if FGroupFocusRect and FChildFocused then
    Exit(False);

  Result := inherited GetEffectiveHoverState;
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

  if FGroupFocusRect and FChildFocused and Enabled then
    DrawFocusRect(Canvas, ClientRect);

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
