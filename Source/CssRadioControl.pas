unit CssRadioControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  CssStyledControl, CssGroupCaptionControl, CssAntiAlias;

type
  TCssRadioButton = class;

  TRadioGroupItemClickEvent = procedure(Sender: TObject; ItemIndex: Integer) of object;

  TCssRadioGroup = class(TCssGroupCaptionControl)
  private
    // Items and child controls
    FItems: TStringList;
    FRadioButtons: TList;
    FItemEnabled: array of Boolean;

    // State
    FItemIndex: Integer;

    // Appearance and layout
    FColumns: Integer;
    FItemHeight: Integer;
    FItemSpacing: Integer;

    // Internal flags
    FUpdating: Boolean;
    FInMouseStateChange: Boolean;

    // CSS styling for child radio buttons
    FRadioCssClass: string;
    FRadioCssStyle: string;

    // Events
    FOnItemClickNotify: TNotifyEvent;
    FOnItemClick: TRadioGroupItemClickEvent;

    // Focus tracking
    FGroupFocusRect: Boolean;
    FChildFocused: Boolean;

    // Items
    function GetItems: TStrings;
    procedure SetItems(AValue: TStrings);
    procedure ItemsChanged(Sender: TObject);

    // State
    procedure SetItemIndex(AValue: Integer);
    procedure SyncEnabledArray;
    procedure RebuildItems;
    procedure UpdateChildStyles;

    // Geometry
    function GetColumns: Integer;
    function GetItemHeight: Integer;
    function GetRadio(Index: Integer): TCssRadioButton;

    // Item enabled state
    function GetItemEnabled(Index: Integer): Boolean;
    procedure SetItemEnabled(Index: Integer; AValue: Boolean);

    // Layout setters
    procedure SetColumns(AValue: Integer);
    procedure SetItemHeight(AValue: Integer);

    // Child CSS setters
    procedure SetRadioCssClass(const AValue: string);
    procedure SetRadioCssStyle(const AValue: string);

    // Child events
    procedure ItemRadioClick(Sender: TObject);
    procedure ItemEnter(Sender: TObject);
    procedure ItemExit(Sender: TObject);
    procedure SetGroupFocusRect(AValue: Boolean);

    function GetEffectiveItemSpacing: Integer;
    function GetEffectiveCaptionSpacing: Integer;
    procedure SetItemSpacing(AValue: Integer);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure EnabledChanged; override;
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
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Items management
    procedure Clear;
    procedure RefreshChildStyles;

    // Sizing
    procedure AdjustSize; override;

    // Navigation
    function FindEnabledItem(AStart, ADelta: Integer; AWrap: Boolean): Integer;
    procedure NavigateArrow(AKey: Word);
    procedure SelectItemByUser(Index: Integer);

    // Indexed property
    property ItemEnabled[Index: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
  published
    // Items and state
    property Items: TStrings read GetItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property ItemSpacing: Integer read FItemSpacing write SetItemSpacing default -1;

    // Layout
    property Columns: Integer read FColumns write SetColumns;
    property ItemHeight: Integer read FItemHeight write SetItemHeight;

    // Child CSS
    property RadioCssClass: string read FRadioCssClass write SetRadioCssClass;
    property RadioCssStyle: string read FRadioCssStyle write SetRadioCssStyle;

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
    property OnItemClick: TRadioGroupItemClickEvent read FOnItemClick write FOnItemClick;
    property GroupFocusRect: Boolean read FGroupFocusRect write SetGroupFocusRect default True;
  end;

  TCssRadioButton = class(TCssStyledControl)
  private
    // State
    FChecked: Boolean;

    // Interaction flags
    FClicked: Boolean;
    FSpacePressed: Boolean;

    // Box appearance
    FBoxBackground: TColor;
    FBoxBackgroundSet: Boolean;
    FBoxBorderColor: TColor;
    FBoxBorderColorSet: Boolean;
    FBoxBorderWidth: Integer;
    FBoxBorderWidthSet: Boolean;
    FBoxRadius: Integer;
    FBoxRadiusSet: Boolean;
    FDotColor: TColor;
    FDotColorSet: Boolean;
    FToggleStyle: Boolean;
    FToggleWidth, FToggleHeight: Integer;
    FToggleThumbColor: TColor;
    FToggleThumbColorSet: Boolean;

    // Events
    FOnChange: TNotifyEvent;

    // State setters
    procedure SetChecked(AValue: Boolean);
    procedure UncheckSiblingRadios;

    // Appearance getters
    function GetBoxSize: Integer;
    function GetBoxWidth: Integer;
    function GetBoxHeight: Integer;
    function GetToggleThumbColor: TColor;
    function GetRadioBackground: TColor;
    function GetRadioBorderColor: TColor;
    function GetRadioBorderWidth: Integer;
    function GetRadioRadius(ABoxSize: Integer): Integer;
    function GetDotColor: TColor;

    // Drawing helpers
    procedure DrawDot(const R: TRect; AColor: TColor);
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
    property ToggleStyle: Boolean read FToggleStyle;

    // Sizing
    procedure AdjustSize; override;

    // Silent state change (no OnChange)
    procedure SetCheckedSilent(AValue: Boolean);
  published
    property Checked: Boolean read FChecked write SetChecked;

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
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  IntfGraphics, FPImage;

function RadioMeasurePlainText(ACanvas: TCanvas; const AText: string): TSize;
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

{ TCssRadioButton }

constructor TCssRadioButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle - [csClickEvents];

  TabStop := True;

  Width := 120;
  Height := 20;

  FChecked := False;

  FToggleStyle := False;
  FToggleWidth := 40;
  FToggleHeight := 20;
  FToggleThumbColorSet := False;

  FClicked := False;
  FSpacePressed := False;
  ShowFocusRect := False;
end;

procedure TCssRadioButton.Loaded;
begin
  inherited Loaded;

  if AutoSize then
    AdjustSize;
end;

procedure TCssRadioButton.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssRadioButton.StyleChanged;
begin
  inherited StyleChanged;

  if AutoSize and (not IsApplyingCss) then
    AdjustSize;

  Invalidate;
end;

procedure TCssRadioButton.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssRadioButton.ResetStyle;
begin
  FBoxBackgroundSet := False;
  FBoxBorderColorSet := False;
  FBoxBorderWidthSet := False;
  FBoxRadiusSet := False;
  FDotColorSet := False;
  FToggleStyle := False;
  FToggleWidth := 40;
  FToggleHeight := 20;
  FToggleThumbColorSet := False;

  inherited ResetStyle;
end;

procedure TCssRadioButton.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
  V: string;
begin
  if AName = 'radio-style' then
  begin
    V := LowerCase(Trim(AValue));
    FToggleStyle := (V = 'toggle') or (V = 'switch');
    if AutoSize and (not IsApplyingCss) then
      AdjustSize;
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
      if AutoSize and (not IsApplyingCss) then
        AdjustSize;
      Invalidate;
    end;
    Exit;
  end;

  if AName = 'toggle-thumb-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin FToggleThumbColor := C; FToggleThumbColorSet := True; end;
    Exit;
  end;

  if AName = 'radio-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FBoxBackground := C;
      FBoxBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'radio-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FBoxBorderColor := C;
      FBoxBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'radio-border-width' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FBoxBorderWidth := Px;
      FBoxBorderWidthSet := True;
    end;
    Exit;
  end;

  if AName = 'radio-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FBoxRadius := Px;
      FBoxRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'dot-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FDotColor := C;
      FDotColorSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssRadioButton.SetCaption(const AValue: TCaption);
begin
  if Caption = AValue then
    Exit;

  inherited SetCaption(AValue);

  if AutoSize then
    AdjustSize;
end;

procedure TCssRadioButton.SetCheckedSilent(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;

  FChecked := AValue;

  SetCssCheckedState(AValue);

  Invalidate;
end;

procedure TCssRadioButton.UncheckSiblingRadios;
var
  I: Integer;
  Ctrl: TControl;
begin
  if Parent = nil then
    Exit;

  for I := 0 to Parent.ControlCount - 1 do
  begin
    Ctrl := Parent.Controls[I];

    if (Ctrl is TCssRadioButton) and (Ctrl <> Self) then
      TCssRadioButton(Ctrl).SetCheckedSilent(False);
  end;
end;

procedure TCssRadioButton.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;

  if AValue then
    UncheckSiblingRadios;

  SetCheckedSilent(AValue);

  if AValue and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCssRadioButton.Click;
begin
  if not FChecked then
    SetChecked(True);

  inherited Click;
end;

function TCssRadioButton.GetBoxSize: Integer;
begin
  if HandleAllocated then
  begin
    AssignCssFontToFont(Canvas.Font);

    Result := Canvas.TextHeight('Ag');

    if Result < ScalePx(13) then
      Result := ScalePx(13);

    if Result > ScalePx(25) then
      Result := ScalePx(25);
  end
  else
  begin
    Result := ScalePx(16);
  end;
end;

function TCssRadioButton.GetBoxWidth: Integer;
begin
  if FToggleStyle then Result := FToggleWidth else Result := GetBoxSize;
end;

function TCssRadioButton.GetBoxHeight: Integer;
begin
  if FToggleStyle then Result := FToggleHeight else Result := GetBoxSize;
end;

function TCssRadioButton.GetToggleThumbColor: TColor;
begin
  if FToggleThumbColorSet then Result := FToggleThumbColor
  else if FDotColorSet then Result := FDotColor
  else Result := clWhite;
end;

function TCssRadioButton.GetRadioBackground: TColor;
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

function TCssRadioButton.GetRadioBorderColor: TColor;
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

function TCssRadioButton.GetRadioBorderWidth: Integer;
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

function TCssRadioButton.GetRadioRadius(ABoxSize: Integer): Integer;
begin
  if FBoxRadiusSet then
    Result := FBoxRadius
  else
    Result := ABoxSize div 2;
end;

function TCssRadioButton.GetDotColor: TColor;
begin
  if FDotColorSet then
    Result := FDotColor
  else
    Result := GetCssTextColor;
end;

procedure TCssRadioButton.DrawDot(const R: TRect; AColor: TColor);
var
  DotSize: Integer;
  Mask: TCssDotMaskEntry;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;

  DotSize := R.Right - R.Left;
  if DotSize > (R.Bottom - R.Top) then DotSize := R.Bottom - R.Top;
  if DotSize <= 0 then Exit;

  Mask := GetDotMask(DotSize);

  BlendCoverageToCanvas(Canvas, R.Left, R.Top, DotSize, DotSize,
    Mask.Coverage, AColor);
end;

procedure TCssRadioButton.Paint;
var
  R, Box, TextR: TRect;
  B: Integer;
  P: TRect;
  BoxSize, BoxHeight: Integer;
  Radius: Integer;
  LBorderWidth: Integer;
  BG, BorderColor, TextColor, DotColor: TColor;
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

  BG := GetRadioBackground;
  BorderColor := GetRadioBorderColor;
  LBorderWidth := GetRadioBorderWidth;
  Radius := GetRadioRadius(BoxSize);
  TextColor := GetCssTextColor;
  DotColor := GetDotColor;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BG;

  if LBorderWidth <= 0 then
  begin
    Canvas.Pen.Width := 1;
    Canvas.Pen.Color := BG;
  end
  else
  begin
    Canvas.Pen.Width := LBorderWidth;
    Canvas.Pen.Color := BorderColor;
  end;

  Canvas.Pen.Style := psSolid;

  if FToggleStyle then
  begin
    Radius := BoxHeight div 2;
    DrawAntiAliasedRoundedBox(Canvas, Box, Radius, BG, BorderColor,
      LBorderWidth, cbsSolid, GetParentBackgroundColor);
    BoxHeight := Box.Bottom - Box.Top;
    if BoxHeight > Box.Right - Box.Left then
      BoxHeight := Box.Right - Box.Left;
    Dec(BoxHeight, ScalePx(8));
    if BoxHeight < ScalePx(2) then BoxHeight := ScalePx(2);
    { Keep the circular thumb's opaque bitmap corners clear of the track rim. }
    if FChecked then
      Radius := Box.Right - Box.Left - BoxHeight - ScalePx(4)
    else
      Radius := ScalePx(4);
    if Radius < ScalePx(4) then Radius := ScalePx(4);
    DrawAntiAliasedCircle(Canvas,
      Rect(Box.Left + Radius, Box.Top + ((Box.Bottom - Box.Top - BoxHeight) div 2),
           Box.Left + Radius + BoxHeight, Box.Top + ((Box.Bottom - Box.Top - BoxHeight) div 2) + BoxHeight),
      GetToggleThumbColor, GetToggleThumbColor, 0, BG);
  end
  else if FBoxRadiusSet and (Radius < (BoxSize div 2)) then
  begin
    DrawAntiAliasedRoundedBox(
      Canvas,
      Box,
      Radius,
      BG,
      BorderColor,
      LBorderWidth,
      cbsSolid,
      GetParentBackgroundColor
    );
  end
  else
  begin
    DrawAntiAliasedCircle(
      Canvas,
      Box,
      BG,
      BorderColor,
      LBorderWidth,
      GetParentBackgroundColor
    );
  end;

  if FChecked and (not FToggleStyle) then
    DrawDot(Box, DotColor);

  TextR := Rect(Box.Right + ScalePx(4), R.Top, R.Right, R.Bottom);

  Canvas.Font.Color := TextColor;

  if HtmlMode then
    DrawHtmlText(TextR, Caption)
  else
    DrawStyledText(TextR, Caption);
end;

procedure TCssRadioButton.AdjustSize;
var
  S: TSize;
  P: TRect;
  B: Integer;
  BoxSize, BoxHeight: Integer;
  Spacing: Integer;
  NewWidth, NewHeight: Integer;
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
  Spacing := ScalePx(4);

  if HtmlMode then
    S := MeasureHtmlTextSize(Caption, 0)
  else
    S := RadioMeasurePlainText(Canvas, Caption);

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

procedure TCssRadioButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Enabled and (Button = mbLeft) then
  begin
    if CanFocus then
      SetFocus;

    FClicked := True;
  end;
end;

procedure TCssRadioButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DoClick: Boolean;
begin
  DoClick :=
    Enabled and
    (Button = mbLeft) and
    FClicked and
    PtInRect(ClientRect, Point(X, Y));

  inherited MouseUp(Button, Shift, X, Y);

  FClicked := False;

  if DoClick then
    Click;
end;

procedure TCssRadioButton.MouseLeave;
begin
  FClicked := False;

  inherited MouseLeave;
end;

procedure TCssRadioButton.KeyDown(var Key: Word; Shift: TShiftState);
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
    if Parent is TCssRadioGroup then
      TCssRadioGroup(Parent).NavigateArrow(Key)
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

procedure TCssRadioButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and FSpacePressed then
  begin
    FSpacePressed := False;

    SetMousePressedState(False);

    if Enabled then
      Click;

    Key := 0;
  end;

  inherited KeyUp(Key, Shift);
end;

procedure TCssRadioButton.DoEnter;
begin
  inherited DoEnter;

  Invalidate;
end;

procedure TCssRadioButton.DoExit;
begin
  inherited DoExit;

  Invalidate;
end;

procedure TCssRadioButton.NavigateStandalone(AKey: Word);
var
  List: TList;
  I, J: Integer;
  Current, Target, Delta, Steps: Integer;
  Temp: Pointer;
  Rb: TCssRadioButton;
begin
  if Parent = nil then
    Exit;

  List := TList.Create;

  try
    for I := 0 to Parent.ControlCount - 1 do
    begin
      if Parent.Controls[I] is TCssRadioButton then
        List.Add(Parent.Controls[I]);
    end;

    if List.Count <= 1 then
      Exit;

    // Sort radio buttons by visual position:
    // top to bottom, then left to right.
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
      VK_LEFT, VK_UP:
        Delta := -1;

      VK_RIGHT, VK_DOWN:
        Delta := 1;
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

      Rb := TCssRadioButton(List[Target]);

      if Rb.Enabled and Rb.Visible then
      begin
        if Rb.CanFocus then
          Rb.SetFocus;

        Rb.Click;
        Exit;
      end;
    end;
  finally
    List.Free;
  end;
end;

function TCssRadioButton.GetDefaultCaption : string;
begin
  Result := 'CssRadioButton';
end;

{ TCssRadioGroup }

constructor TCssRadioGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := False;

  Width := 185;
  Height := 105;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;

  FRadioButtons := TList.Create;

  FItemIndex := -1;
  FGroupFocusRect := True;
  FChildFocused := False;
  FColumns := 1;
  FItemHeight := 0;
  FItemSpacing := -1;

  FRadioCssClass := 'radio';
  FRadioCssStyle := '';
end;

destructor TCssRadioGroup.Destroy;
begin
  FItems.OnChange := nil;

  FRadioButtons.Clear;

  FreeAndNil(FItems);
  FreeAndNil(FRadioButtons);

  inherited Destroy;
end;

function TCssRadioButton.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

procedure TCssRadioGroup.Loaded;
begin
  inherited Loaded;

  SyncEnabledArray;
  RebuildItems;
  UpdateChildStyles;
  LayoutItems;

  if AutoSize then
    AdjustSize;
end;

procedure TCssRadioGroup.CreateWnd;
begin
  inherited CreateWnd;

  if Assigned(FRadioButtons) and (FRadioButtons.Count > 0) then
  begin
    LayoutItems;

    if AutoSize then
      AdjustSize;
  end;
end;

procedure TCssRadioGroup.StyleChanged;
begin
  inherited StyleChanged;

  if FInMouseStateChange then
  begin
    // On mouse enter/leave only :hover usually changes.
    // Full rebuild of child radio buttons and layout is not needed here.
    Invalidate;
    Exit;
  end;

  UpdateChildStyles;

  if AutoSize and (not IsApplyingCss) then
    AdjustSize;
end;

procedure TCssRadioGroup.HtmlModeChanged;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  inherited HtmlModeChanged;

  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Rb := GetRadio(I);

    if Assigned(Rb) then
      Rb.HtmlMode := HtmlMode;
  end;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssRadioGroup.EnabledChanged;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  inherited EnabledChanged;

  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Rb := GetRadio(I);

    if not Assigned(Rb) then
      Continue;

    if I < Length(FItemEnabled) then
      Rb.Enabled := Enabled and FItemEnabled[I]
    else
      Rb.Enabled := Enabled;
  end;
end;

procedure TCssRadioGroup.MouseEnter;
begin
  FInMouseStateChange := True;
  try
    inherited MouseEnter;
  finally
    FInMouseStateChange := False;
  end;
end;

procedure TCssRadioGroup.MouseLeave;
begin
  FInMouseStateChange := True;
  try
    inherited MouseLeave;
  finally
    FInMouseStateChange := False;
  end;
end;

function TCssRadioGroup.GetDefaultCaption : string;
begin
  Result := 'CssRadioGroup';
end;

procedure TCssRadioGroup.Resize;
begin
  inherited Resize;

  if Assigned(FRadioButtons) and (FRadioButtons.Count > 0) then
    LayoutItems;

  Invalidate;
end;

procedure TCssRadioGroup.KeyDown(var Key: Word; Shift: TShiftState);
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

procedure TCssRadioGroup.Paint;
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

procedure TCssRadioGroup.AdjustSize;
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
    TopSpace := B + P.Top + CapH + GetEffectiveCaptionSpacing;
  end
  else
  begin
    TopBlock := B;

    if CapH > TopBlock then
      TopBlock := CapH;

    TopSpace := TopBlock + P.Top + GetEffectiveCaptionSpacing;
  end;

  if RowCount > 0 then
    NewHeight :=
      TopSpace +
      (RowCount * ItemH) +
      ((RowCount - 1) * GetEffectiveItemSpacing) +
      P.Bottom +
      B
  else
    NewHeight := TopSpace + P.Bottom + B;

  if NewHeight < 0 then
    NewHeight := 0;

  if NewHeight <> Height then
    SetBounds(Left, Top, Width, NewHeight);

  inherited AdjustSize;
end;

function TCssRadioGroup.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TCssRadioGroup.SetItems(AValue: TStrings);
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

procedure TCssRadioGroup.ItemsChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  if (csLoading in ComponentState) or
     (csDestroying in ComponentState) then
    Exit;

  SyncEnabledArray;
  RebuildItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssRadioGroup.SetItemIndex(AValue: Integer);
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  if AValue < -1 then
    AValue := -1;

  if AValue >= FItems.Count then
    AValue := FItems.Count - 1;

  if FItemIndex = AValue then
    Exit;

  FUpdating := True;

  try
    FItemIndex := AValue;

    for I := 0 to FRadioButtons.Count - 1 do
    begin
      Rb := GetRadio(I);

      if Assigned(Rb) then
        Rb.SetCheckedSilent(I = FItemIndex);
    end;
  finally
    FUpdating := False;
  end;

  Invalidate;
end;

procedure TCssRadioGroup.SyncEnabledArray;
var
  OldCount, NewCount, I: Integer;
begin
  OldCount := Length(FItemEnabled);
  NewCount := FItems.Count;

  SetLength(FItemEnabled, NewCount);

  for I := OldCount to NewCount - 1 do
    FItemEnabled[I] := True;
end;

procedure TCssRadioGroup.RebuildItems;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  if csDestroying in ComponentState then
    Exit;

  FUpdating := True;

  try
    for I := FRadioButtons.Count - 1 downto 0 do
      TCssRadioButton(FRadioButtons[I]).Free;

    FRadioButtons.Clear;

    SyncEnabledArray;

    for I := 0 to FItems.Count - 1 do
    begin
      Rb := TCssRadioButton.Create(Self);
      Rb.Parent := Self;

      Rb.Tag := I;
      Rb.AutoSize := False;
      Rb.TabStop := True;
      Rb.TabOrder := I;

      Rb.Caption := FItems[I];

      Rb.HtmlMode := HtmlMode;

      Rb.HintHtmlMode := HintHtmlMode;
      Rb.ShowHint := ShowHint;
      Rb.Hint := Hint;

      Rb.CssTag := 'radio';
      Rb.CssClass := FRadioCssClass;
      Rb.CssStyle := FRadioCssStyle;

      Rb.StyleProvider := StyleProvider;
      Rb.StyleName := StyleName;

      Rb.Enabled := Enabled and FItemEnabled[I];

      Rb.OnClick := @ItemRadioClick;
      Rb.OnEnter := @ItemEnter;
      Rb.OnExit  := @ItemExit;

      Rb.SetCheckedSilent(I = FItemIndex);

      FRadioButtons.Add(Rb);
    end;
  finally
    FUpdating := False;
  end;

  FChildFocused := False;
  LayoutItems;
end;

procedure TCssRadioGroup.LayoutItems;
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
  I, Row, Col, X, Y, RowStep: Integer;
  Cb: TCssRadioButton;
begin
  if FRadioButtons.Count = 0 then
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
    ContentTop := ClientR.Top + B + P.Top + CapH + GetEffectiveCaptionSpacing;
  end
  else
  begin
    TopBlock := B;

    if CapH > TopBlock then
      TopBlock := CapH;

    ContentTop := ClientR.Top + TopBlock + P.Top + GetEffectiveCaptionSpacing;
  end;

  ColW := ContentWidth div ColCount;

  if ColW < 0 then
    ColW := 0;

  RowStep := ItemH + GetEffectiveItemSpacing;

  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Cb := GetRadio(I);

    if not Assigned(Cb) then
      Continue;

    Row := I div ColCount;
    Col := I mod ColCount;

    X := ContentLeft + (Col * ColW);
    Y := ContentTop + (Row * RowStep);

    Cb.SetBounds(X, Y, ColW, ItemH);
  end;
end;

function TCssRadioGroup.GetEffectiveHoverState: Boolean;
begin
  if FGroupFocusRect and FChildFocused then
    Exit(False);

  Result := inherited GetEffectiveHoverState;
end;

procedure TCssRadioGroup.UpdateChildStyles;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Rb := GetRadio(I);

    if not Assigned(Rb) then
      Continue;

    if Rb.StyleProvider <> StyleProvider then
      Rb.StyleProvider := StyleProvider;

    if Rb.StyleName <> StyleName then
      Rb.StyleName := StyleName;

    Rb.CssClass := FRadioCssClass;
    Rb.CssStyle := FRadioCssStyle;
    Rb.HtmlMode := HtmlMode;
    Rb.HintHtmlMode := HintHtmlMode;
    Rb.ShowHint := ShowHint;
    Rb.Hint := Hint;

    if I < Length(FItemEnabled) then
      Rb.Enabled := Enabled and FItemEnabled[I]
    else
      Rb.Enabled := Enabled;
  end;

  LayoutItems;
  Invalidate;
end;

function TCssRadioGroup.GetColumns: Integer;
begin
  if FColumns < 1 then
    Result := 1
  else
    Result := FColumns;
end;

function TCssRadioGroup.GetItemHeight: Integer;
begin
  if FItemHeight > 0 then
    Exit(FItemHeight);

  if HandleAllocated then
  begin
    AssignCssFontToFont(Canvas.Font);

    Result := Canvas.TextHeight('Ag') + ScalePx(6);

    if Result < ScalePx(18) then
      Result := ScalePx(18);
  end
  else
  begin
    Result := ScalePx(20);
  end;
end;

function TCssRadioGroup.GetRadio(Index: Integer): TCssRadioButton;
begin
  if (Index >= 0) and (Index < FRadioButtons.Count) then
    Result := TCssRadioButton(FRadioButtons[Index])
  else
    Result := nil;
end;

function TCssRadioGroup.GetItemEnabled(Index: Integer): Boolean;
begin
  if (Index >= 0) and (Index < Length(FItemEnabled)) then
    Result := FItemEnabled[Index]
  else
    Result := True;
end;

procedure TCssRadioGroup.SetItemEnabled(Index: Integer; AValue: Boolean);
var
  Rb: TCssRadioButton;
begin
  if (Index < 0) or (Index >= FItems.Count) then
    Exit;

  if Index >= Length(FItemEnabled) then
    SyncEnabledArray;

  FItemEnabled[Index] := AValue;

  Rb := GetRadio(Index);

  if Assigned(Rb) then
    Rb.Enabled := Enabled and AValue;
end;

procedure TCssRadioGroup.SetColumns(AValue: Integer);
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

procedure TCssRadioGroup.SetItemHeight(AValue: Integer);
begin
  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssRadioGroup.SetRadioCssClass(const AValue: string);
begin
  if FRadioCssClass = AValue then
    Exit;

  FRadioCssClass := AValue;

  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

procedure TCssRadioGroup.SetRadioCssStyle(const AValue: string);
begin
  if FRadioCssStyle = AValue then
    Exit;

  FRadioCssStyle := AValue;

  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

procedure TCssRadioGroup.ItemRadioClick(Sender: TObject);
var
  Rb: TCssRadioButton;
  Idx: Integer;
begin
  if not (Sender is TCssRadioButton) then
    Exit;

  Rb := TCssRadioButton(Sender);
  Idx := Rb.Tag;

  if FUpdating then
    Exit;

  FItemIndex := Idx;

  if Assigned(FOnItemClickNotify) then
    FOnItemClickNotify(Self);

  if Assigned(FOnItemClick) then
    FOnItemClick(Self, Idx);
end;

procedure TCssRadioGroup.ItemEnter(Sender: TObject);
begin
  if not FChildFocused then
  begin
    FChildFocused := True;
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssRadioGroup.ItemExit(Sender: TObject);
begin
  if FChildFocused then
  begin
    FChildFocused := False;
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssRadioGroup.SetGroupFocusRect(AValue: Boolean);
begin
  if FGroupFocusRect = AValue then
    Exit;

  FGroupFocusRect := AValue;
  Invalidate;
end;

function TCssRadioGroup.GetEffectiveItemSpacing: Integer;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  if FItemSpacing >= 0 then
    Exit(FItemSpacing);

  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Rb := GetRadio(I);
    if Assigned(Rb) and Rb.ToggleStyle then
      Exit(ScalePx(4));
  end;

  Result := ScalePx(2);
end;

function TCssRadioGroup.GetEffectiveCaptionSpacing: Integer;
var
  I: Integer;
  Rb: TCssRadioButton;
begin
  if Caption = '' then
    Exit(0);

  for I := 0 to FRadioButtons.Count - 1 do
  begin
    Rb := GetRadio(I);
    if Assigned(Rb) and Rb.ToggleStyle then
      Exit(ScalePx(4));
  end;

  Result := 0;
end;

procedure TCssRadioGroup.SetItemSpacing(AValue: Integer);
begin
  if FItemSpacing = AValue then
    Exit;

  FItemSpacing := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

function TCssRadioGroup.FindEnabledItem(AStart, ADelta: Integer;
  AWrap: Boolean): Integer;
var
  Count, I, Steps: Integer;
  Rb: TCssRadioButton;
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
      Rb := GetRadio(I);

      if Assigned(Rb) and Rb.Enabled and Rb.Visible then
        Exit(I);
    end;
  end;
end;

procedure TCssRadioGroup.NavigateArrow(AKey: Word);
var
  Count, ColCount, Target: Integer;
begin
  Count := FItems.Count;

  if Count = 0 then
    Exit;

  ColCount := GetColumns;

  if ItemIndex < 0 then
  begin
    if (AKey = VK_RIGHT) or (AKey = VK_DOWN) then
      Target := FindEnabledItem(-1, 1, False)
    else
      Target := FindEnabledItem(Count, -1, False);

    if Target >= 0 then
      SelectItemByUser(Target);

    Exit;
  end;

  case AKey of
    VK_LEFT:
      Target := FindEnabledItem(ItemIndex, -1, True);

    VK_RIGHT:
      Target := FindEnabledItem(ItemIndex, 1, True);

    VK_UP:
      Target := FindEnabledItem(ItemIndex, -ColCount, True);

    VK_DOWN:
      Target := FindEnabledItem(ItemIndex, ColCount, True);
  else
    Exit;
  end;

  // If grid vertical movement gave no result,
  // fall back to linear navigation.
  if Target = ItemIndex then
  begin
    if AKey = VK_UP then
      Target := FindEnabledItem(ItemIndex, -1, True)
    else if AKey = VK_DOWN then
      Target := FindEnabledItem(ItemIndex, 1, True);
  end;

  if (Target >= 0) and (Target <> ItemIndex) then
    SelectItemByUser(Target);
end;

procedure TCssRadioGroup.SelectItemByUser(Index: Integer);
var
  Rb: TCssRadioButton;
begin
  Rb := GetRadio(Index);

  if not Assigned(Rb) then
    Exit;

  if not Rb.Enabled or not Rb.Visible then
    Exit;

  if Rb.CanFocus then
    Rb.SetFocus;

  Rb.Click;
end;

procedure TCssRadioGroup.Clear;
begin
  Items.Clear;
end;

procedure TCssRadioGroup.RefreshChildStyles;
begin
  UpdateChildStyles;

  if AutoSize then
    AdjustSize;
end;

end.
