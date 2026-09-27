unit CssListboxControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, Forms,
  CssStyledControl, CssScrollControl;

type
  TCssListBox = class(TCssStyledControl)
  private
    // Items and selection
    FItems: TStringList;
    FSelected: array of Boolean;
    FItemIndex: Integer;
    FTopIndex: Integer;
    FHoverIndex: Integer;
    FAnchorIndex: Integer;

    // Behavior
    FMultiSelect: Boolean;
    FItemHeight: Integer;
    FItemPadding: Integer;
    FMouseWheelLines: Integer;

    // Internal state
    FUpdating: Boolean;

    // Events
    FOnSelectionChange: TNotifyEvent;

    // Item appearance
    FItemBackground: TColor;
    FItemBackgroundSet: Boolean;
    FItemColor: TColor;
    FItemColorSet: Boolean;
    FItemHoverBackground: TColor;
    FItemHoverBackgroundSet: Boolean;
    FItemHoverColor: TColor;
    FItemHoverColorSet: Boolean;
    FItemSelectedBackground: TColor;
    FItemSelectedBackgroundSet: Boolean;
    FItemSelectedColor: TColor;
    FItemSelectedColorSet: Boolean;

    // Scrollbar
    FScrollBar: TCssScrollBar;
    FScrollBarCssClass: string;
    FScrollBarCssStyle: string;
    FScrollBarWidth: Integer;
    FAlwaysReserveScrollBar: Boolean;

    // Scrollbar property setters
    procedure SetScrollBarCssClass(const AValue: string);
    procedure SetScrollBarCssStyle(const AValue: string);
    procedure SetScrollBarWidth(AValue: Integer);
    procedure ApplyScrollBarStyle;
    procedure SetAlwaysReserveScrollBar(AValue: Boolean);

    // Items
    function GetItems: TStrings;
    procedure SetItems(AValue: TStrings);
    procedure ItemsChanged(Sender: TObject);

    // Selection
    procedure SyncSelectionLength;
    function GetSelected(Index: Integer): Boolean;
    procedure SetSelected(Index: Integer; AValue: Boolean);
    procedure SetSelectedInternal(Index: Integer; AValue: Boolean);
    function GetSelCount: Integer;
    procedure ClearSelectionInternal;
    procedure SelectRange(AStart, AEnd: Integer);
    procedure MoveSelectionTo(NewIndex: Integer; Extend: Boolean);
    procedure EnsureItemVisible(Index: Integer);
    procedure DoSelectionChange;

    // Behavior property setters
    procedure SetItemIndex(AValue: Integer);
    procedure SetMultiSelect(AValue: Boolean);
    procedure SetItemHeight(AValue: Integer);
    procedure SetTopIndex(AValue: Integer);

    // Sorting
    function GetSorted: Boolean;
    procedure SetSorted(AValue: Boolean);

    // Geometry
    function GetMaxTopIndex: Integer;
    function GetVisibleCount: Integer;
    function GetListRect: TRect;
    function ItemAtPos(X, Y: Integer): Integer;

    // Scrollbar synchronization
    procedure UpdateScrollBars;
    procedure ScrollBarChanged(Sender: TObject);

    // Item color getters
    function GetItemBackground: TColor;
    function GetItemColor: TColor;
    function GetHoverItemBackground: TColor;
    function GetHoverItemColor: TColor;
    function GetSelectedItemBackground: TColor;
    function GetSelectedItemColor: TColor;
  protected
    // Initialization and style
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure EnabledChanged; override;

    // Painting
    procedure Paint; override;

    // Sizing
    procedure Resize; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;

    // Focus
    function GetFocusColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Items management
    procedure Clear;

    // Selection
    procedure ClearSelection;
    property SelCount: Integer read GetSelCount;
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected;
    property TopIndex: Integer read FTopIndex write SetTopIndex;

    // Scrollbar refresh
    procedure RefreshScrollBarStyle;
  published
    // Items
    property Items: TStrings read GetItems write SetItems;

    // Behavior
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    property Sorted: Boolean read GetSorted write SetSorted default False;

    property ItemHeight: Integer read FItemHeight write SetItemHeight default 18;
    property ItemPadding: Integer read FItemPadding write FItemPadding default 2;

    // Scrollbar
    property ScrollBarCssClass: string read FScrollBarCssClass write SetScrollBarCssClass;
    property ScrollBarCssStyle: string read FScrollBarCssStyle write SetScrollBarCssStyle;
    property ScrollBarWidth: Integer read FScrollBarWidth write SetScrollBarWidth default 16;
    property MouseWheelLines: Integer read FMouseWheelLines write FMouseWheelLines default 3;
    property AlwaysReserveScrollBar: Boolean read FAlwaysReserveScrollBar write SetAlwaysReserveScrollBar default True;

    // Standard properties
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;

    property OnClick;
    property OnDblClick;
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

{ TCssListBox }

constructor TCssListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := True;

  Width := 185;
  Height := 120;

  FItems := TStringList.Create;
  FItems.Duplicates := dupAccept;
  FItems.OnChange := @ItemsChanged;

  FItemIndex := -1;
  FTopIndex := 0;
  FHoverIndex := -1;
  FAnchorIndex := -1;
  FMouseWheelLines := 3;

  FMultiSelect := False;
  FItemHeight := 18;
  FItemPadding := 2;

  FScrollBarCssClass := 'listbox-scrollbar';
  FScrollBarCssStyle := '';
  FScrollBarWidth := 16;

  FScrollBar := TCssScrollBar.Create(Self);
  FScrollBar.Parent := Self;

  FScrollBar.Kind := sbVertical;
  FScrollBar.TabStop := False;
  FScrollBar.Enabled := False;
  FScrollBar.Visible := False;
  FScrollBar.Width := FScrollBarWidth;
  FScrollBar.Height := 0;
  FScrollBar.SetBounds(0, 0, 0, 0);

  FScrollBar.CssTag := 'scrollbar';
  FScrollBar.CssClass := FScrollBarCssClass;
  FScrollBar.OnChange := @ScrollBarChanged;
  FAlwaysReserveScrollBar := True;

  TCssStyledControl(Self).Caption := '';
end;

destructor TCssListBox.Destroy;
begin
  FItems.OnChange := nil;

  FreeAndNil(FItems);

  inherited Destroy;
end;

procedure TCssListBox.CreateWnd;
begin
  inherited CreateWnd;

  UpdateScrollBars;
end;

procedure TCssListBox.Loaded;
begin
  inherited Loaded;

  ApplyScrollBarStyle;

  SyncSelectionLength;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssListBox.StyleChanged;
begin
  inherited StyleChanged;

  ApplyScrollBarStyle;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  Invalidate;
end;

procedure TCssListBox.ResetStyle;
begin
  FItemBackgroundSet := False;
  FItemColorSet := False;

  FItemHoverBackgroundSet := False;
  FItemHoverColorSet := False;

  FItemSelectedBackgroundSet := False;
  FItemSelectedColorSet := False;

  inherited ResetStyle;
end;

procedure TCssListBox.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'item-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemBackground := C;
      FItemBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemColor := C;
      FItemColorSet := True;
    end;
    Exit;
  end;

  if AName = 'item-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemHoverBackground := C;
      FItemHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-hover-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemHoverColor := C;
      FItemHoverColorSet := True;
    end;
    Exit;
  end;

  if AName = 'item-selected-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemSelectedBackground := C;
      FItemSelectedBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-selected-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemSelectedColor := C;
      FItemSelectedColorSet := True;
    end;
    Exit;
  end;

  if AName = 'item-height' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      ItemHeight := Px;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssListBox.EnabledChanged;
begin
  inherited EnabledChanged;

  if Assigned(FScrollBar) then
    FScrollBar.Enabled := Enabled;

  Invalidate;
end;

procedure TCssListBox.SetScrollBarCssClass(const AValue: string);
begin
  if FScrollBarCssClass = AValue then
    Exit;

  FScrollBarCssClass := AValue;

  ApplyScrollBarStyle;

  Invalidate;
end;

procedure TCssListBox.SetScrollBarCssStyle(const AValue: string);
begin
  if FScrollBarCssStyle = AValue then
    Exit;

  FScrollBarCssStyle := AValue;

  ApplyScrollBarStyle;

  Invalidate;
end;

procedure TCssListBox.SetScrollBarWidth(AValue: Integer);
begin
  if AValue < 8 then
    AValue := 8;

  if FScrollBarWidth = AValue then
    Exit;

  FScrollBarWidth := AValue;

  if Assigned(FScrollBar) then
    FScrollBar.Width := AValue;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.ApplyScrollBarStyle;
begin
  if not Assigned(FScrollBar) then
    Exit;

  FScrollBar.StyleProvider := StyleProvider;
  FScrollBar.StyleName := StyleName;

  FScrollBar.Enabled := Enabled;

  FScrollBar.CssClass := FScrollBarCssClass;
  FScrollBar.CssStyle := FScrollBarCssStyle;

  FScrollBar.Width := FScrollBarWidth;
end;

procedure TCssListBox.SetAlwaysReserveScrollBar(AValue: Boolean);
begin
  if FAlwaysReserveScrollBar = AValue then
    Exit;

  FAlwaysReserveScrollBar := AValue;

  UpdateScrollBars;
  Invalidate;
end;

function TCssListBox.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TCssListBox.SetItems(AValue: TStrings);
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

procedure TCssListBox.ItemsChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  SyncSelectionLength;

  if FItemIndex >= FItems.Count then
    FItemIndex := -1;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.SyncSelectionLength;
var
  OldCount, NewCount, I: Integer;
begin
  OldCount := Length(FSelected);
  NewCount := FItems.Count;

  SetLength(FSelected, NewCount);

  for I := OldCount to NewCount - 1 do
    FSelected[I] := False;

  if NewCount = 0 then
  begin
    FItemIndex := -1;
    FAnchorIndex := -1;
  end;
end;

function TCssListBox.GetSelected(Index: Integer): Boolean;
begin
  if (Index >= 0) and (Index < Length(FSelected)) then
    Result := FSelected[Index]
  else
    Result := False;
end;

procedure TCssListBox.SetSelectedInternal(Index: Integer; AValue: Boolean);
begin
  if (Index >= 0) and (Index < Length(FSelected)) then
    FSelected[Index] := AValue;
end;

procedure TCssListBox.SetSelected(Index: Integer; AValue: Boolean);
begin
  if (Index < 0) or (Index >= FItems.Count) then
    Exit;

  if (not FMultiSelect) and AValue then
    ClearSelectionInternal;

  SetSelectedInternal(Index, AValue);

  if AValue then
    FItemIndex := Index;

  Invalidate;
  DoSelectionChange;
end;

function TCssListBox.GetSelCount: Integer;
var
  I: Integer;
begin
  Result := 0;

  for I := 0 to High(FSelected) do
  begin
    if FSelected[I] then
      Inc(Result);
  end;
end;

procedure TCssListBox.ClearSelectionInternal;
var
  I: Integer;
begin
  for I := 0 to High(FSelected) do
    FSelected[I] := False;
end;

procedure TCssListBox.ClearSelection;
begin
  ClearSelectionInternal;

  Invalidate;
  DoSelectionChange;
end;

procedure TCssListBox.SelectRange(AStart, AEnd: Integer);
var
  I, Tmp: Integer;
begin
  if AStart > AEnd then
  begin
    Tmp := AStart;
    AStart := AEnd;
    AEnd := Tmp;
  end;

  if AStart < 0 then
    AStart := 0;

  if AEnd >= FItems.Count then
    AEnd := FItems.Count - 1;

  for I := AStart to AEnd do
    SetSelectedInternal(I, True);
end;

procedure TCssListBox.MoveSelectionTo(NewIndex: Integer; Extend: Boolean);
begin
  if FItems.Count = 0 then
    Exit;

  if NewIndex < 0 then
    NewIndex := 0;

  if NewIndex >= FItems.Count then
    NewIndex := FItems.Count - 1;

  if Extend and FMultiSelect then
  begin
    if FAnchorIndex < 0 then
      FAnchorIndex := FItemIndex;

    if FAnchorIndex < 0 then
      FAnchorIndex := NewIndex;

    ClearSelectionInternal;
    SelectRange(FAnchorIndex, NewIndex);

    FItemIndex := NewIndex;
  end
  else
  begin
    ClearSelectionInternal;

    FItemIndex := NewIndex;
    SetSelectedInternal(NewIndex, True);
    FAnchorIndex := NewIndex;
  end;

  EnsureItemVisible(NewIndex);

  Invalidate;
  DoSelectionChange;
end;

procedure TCssListBox.EnsureItemVisible(Index: Integer);
var
  VisibleCount: Integer;
begin
  if Index < 0 then
    Exit;

  VisibleCount := GetVisibleCount;

  if VisibleCount <= 0 then
    Exit;

  if Index < FTopIndex then
    SetTopIndex(Index)
  else if Index >= FTopIndex + VisibleCount then
    SetTopIndex(Index - VisibleCount + 1);
end;

procedure TCssListBox.DoSelectionChange;
begin
  if FUpdating then
    Exit;

  if Assigned(FOnSelectionChange) then
    FOnSelectionChange(Self);
end;

procedure TCssListBox.SetItemIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue := -1;

  if AValue >= FItems.Count then
    AValue := FItems.Count - 1;

  if FItemIndex = AValue then
    Exit;

  if AValue = -1 then
  begin
    ClearSelectionInternal;
    FItemIndex := -1;
    FAnchorIndex := -1;
  end
  else
  begin
    if not FMultiSelect then
      ClearSelectionInternal;

    FItemIndex := AValue;
    SetSelectedInternal(AValue, True);
    FAnchorIndex := AValue;

    EnsureItemVisible(AValue);
  end;

  Invalidate;
  DoSelectionChange;
end;

procedure TCssListBox.SetMultiSelect(AValue: Boolean);
begin
  if FMultiSelect = AValue then
    Exit;

  FMultiSelect := AValue;

  if not AValue then
  begin
    ClearSelectionInternal;

    if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
      SetSelectedInternal(FItemIndex, True);
  end;

  Invalidate;
  DoSelectionChange;
end;

procedure TCssListBox.SetItemHeight(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.SetTopIndex(AValue: Integer);
var
  MaxTop: Integer;
begin
  MaxTop := GetMaxTopIndex;

  if AValue < 0 then
    AValue := 0;

  if AValue > MaxTop then
    AValue := MaxTop;

  if FTopIndex = AValue then
    Exit;

  FTopIndex := AValue;

  if Assigned(FScrollBar) and (not FUpdating) then
  begin
    FUpdating := True;

    try
      FScrollBar.Position := FTopIndex;
    finally
      FUpdating := False;
    end;
  end;

  Invalidate;
end;

function TCssListBox.GetSorted: Boolean;
begin
  Result := FItems.Sorted;
end;

procedure TCssListBox.SetSorted(AValue: Boolean);
begin
  if FItems.Sorted = AValue then
    Exit;

  FItems.Sorted := AValue;

  if AValue then
    FItems.Sort;

  ClearSelectionInternal;

  FItemIndex := -1;
  FAnchorIndex := -1;

  ItemsChanged(Self);
end;

function TCssListBox.GetMaxTopIndex: Integer;
begin
  Result := FItems.Count - GetVisibleCount;

  if Result < 0 then
    Result := 0;
end;

function TCssListBox.GetVisibleCount: Integer;
var
  R: TRect;
begin
  R := GetListRect;

  if FItemHeight <= 0 then
    Exit(0);

  Result := (R.Bottom - R.Top) div FItemHeight;

  if Result < 0 then
    Result := 0;
end;

function TCssListBox.GetListRect: TRect;
begin
  Result := GetContentRect;

  if (FScrollBarWidth > 0) and
     (FAlwaysReserveScrollBar or
      (Assigned(FScrollBar) and FScrollBar.Visible)) then
    Result.Right := Result.Right - FScrollBarWidth;

  if Result.Right < Result.Left then
    Result.Right := Result.Left;
end;

function TCssListBox.ItemAtPos(X, Y: Integer): Integer;
var
  R: TRect;
begin
  Result := -1;

  R := GetListRect;

  if (X < R.Left) or (X > R.Right) then
    Exit;

  if (Y < R.Top) or (Y > R.Bottom) then
    Exit;

  if FItemHeight <= 0 then
    Exit;

  Result := FTopIndex + ((Y - R.Top) div FItemHeight);

  if (Result < 0) or (Result >= FItems.Count) then
    Result := -1;
end;

procedure TCssListBox.UpdateScrollBars;
var
  ContentR: TRect;
  VisibleCount, Count, MaxTop, SBWidth: Integer;
begin
  if not Assigned(FScrollBar) then
    Exit;

  ContentR := GetContentRect;

  Count := FItems.Count;

  if FItemHeight > 0 then
    VisibleCount := (ContentR.Bottom - ContentR.Top) div FItemHeight
  else
    VisibleCount := 0;

  if VisibleCount < 0 then
    VisibleCount := 0;

  MaxTop := Count - VisibleCount;

  if MaxTop < 0 then
    MaxTop := 0;

  SBWidth := FScrollBarWidth;

  FUpdating := True;

  try
    FScrollBar.Visible := Count > VisibleCount;

    if FScrollBar.Visible then
    begin
      FScrollBar.SetBounds(
        ContentR.Right - SBWidth,
        ContentR.Top,
        SBWidth,
        ContentR.Bottom - ContentR.Top
      );

      FScrollBar.Min := 0;
      FScrollBar.Max := MaxTop;
      FScrollBar.PageSize := VisibleCount;

      if FTopIndex > MaxTop then
        FTopIndex := MaxTop;

      FScrollBar.Position := FTopIndex;
      FScrollBar.Enabled := True;
    end
    else
    begin
      FScrollBar.SetBounds(0, 0, 0, 0);

      FScrollBar.PageSize := 0;
      FScrollBar.Position := 0;
      FScrollBar.Enabled := False;

      if FTopIndex > MaxTop then
        FTopIndex := MaxTop;
    end;
  finally
    FUpdating := False;
  end;

  Invalidate;
end;

procedure TCssListBox.ScrollBarChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  SetTopIndex(FScrollBar.Position);
end;

procedure TCssListBox.RefreshScrollBarStyle;
begin
  ApplyScrollBarStyle;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListBox.Clear;
begin
  Items.Clear;
end;

function TCssListBox.GetItemBackground: TColor;
begin
  if FItemBackgroundSet then
  begin
    Result := FItemBackground;
    Exit;
  end;

  Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := clWindow;

  if Result = clDefault then
    Result := clWindow;
end;

function TCssListBox.GetItemColor: TColor;
begin
  if FItemColorSet then
  begin
    Result := FItemColor;
    Exit;
  end;

  Result := GetCssTextColor;
end;

function TCssListBox.GetHoverItemBackground: TColor;
begin
  if FItemHoverBackgroundSet then
  begin
    Result := FItemHoverBackground;
    Exit;
  end;

  Result := RGBToColor(235, 240, 245);
end;

function TCssListBox.GetHoverItemColor: TColor;
begin
  if FItemHoverColorSet then
  begin
    Result := FItemHoverColor;
    Exit;
  end;

  Result := GetItemColor;
end;

function TCssListBox.GetSelectedItemBackground: TColor;
begin
  if FItemSelectedBackgroundSet then
  begin
    Result := FItemSelectedBackground;
    Exit;
  end;

  Result := clHighlight;
end;

function TCssListBox.GetSelectedItemColor: TColor;
begin
  if FItemSelectedColorSet then
  begin
    Result := FItemSelectedColor;
    Exit;
  end;

  Result := clHighlightText;
end;

procedure TCssListBox.Resize;
begin
  inherited Resize;

  UpdateScrollBars;
end;

procedure TCssListBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if CanFocus then
    SetFocus;

  Idx := ItemAtPos(X, Y);

  if Idx < 0 then
    Exit;

  if FMultiSelect then
  begin
    if ssShift in Shift then
    begin
      MoveSelectionTo(Idx, True);
    end
    else if ssCtrl in Shift then
    begin
      SetSelectedInternal(Idx, not GetSelected(Idx));

      if GetSelected(Idx) then
        FItemIndex := Idx;

      FAnchorIndex := Idx;

      EnsureItemVisible(Idx);

      Invalidate;
      DoSelectionChange;
    end
    else
    begin
      MoveSelectionTo(Idx, False);
    end;
  end
  else
  begin
    MoveSelectionTo(Idx, False);
  end;
end;

procedure TCssListBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  Idx := ItemAtPos(X, Y);

  if Idx <> FHoverIndex then
  begin
    FHoverIndex := Idx;
    Invalidate;
  end;
end;

procedure TCssListBox.MouseLeave;
begin
  FHoverIndex := -1;

  inherited MouseLeave;

  Invalidate;
end;

function TCssListBox.GetFocusColor: TColor;
begin
  if FocusColor <> clDefault then
    Exit(inherited GetFocusColor);

  Result := GetCssTextColor;
  if Result = clDefault then
    Result := clWindowText;
end;

procedure TCssListBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  Count, VisibleCount, Current, NewIndex: Integer;
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  Count := FItems.Count;

  if Count = 0 then
    Exit;

  VisibleCount := GetVisibleCount;

  Current := FItemIndex;

  if Current < 0 then
    Current := 0;

  case Key of
    VK_UP:
    begin
      NewIndex := CssMax(0, Current - 1);
      MoveSelectionTo(NewIndex, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_DOWN:
    begin
      NewIndex := CssMin(Count - 1, Current + 1);
      MoveSelectionTo(NewIndex, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_HOME:
    begin
      MoveSelectionTo(0, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_END:
    begin
      MoveSelectionTo(Count - 1, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_PRIOR:
    begin
      NewIndex := CssMax(0, Current - CssMax(1, VisibleCount));
      MoveSelectionTo(NewIndex, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_NEXT:
    begin
      NewIndex := CssMin(Count - 1, Current + CssMax(1, VisibleCount));
      MoveSelectionTo(NewIndex, FMultiSelect and (ssShift in Shift));
      Key := 0;
    end;

    VK_SPACE:
    begin
      if FMultiSelect and (FItemIndex >= 0) and (FItemIndex < Count) then
      begin
        SetSelectedInternal(FItemIndex, not GetSelected(FItemIndex));

        Invalidate;
        DoSelectionChange;

        Key := 0;
      end;
    end;

    VK_RETURN:
    begin
      if Assigned(OnDblClick) then
        OnDblClick(Self);

      Key := 0;
    end;
  end;
end;

function TCssListBox.DoMouseWheel(
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

  if FMouseWheelLines <= 0 then
    Exit;

  if WheelDelta > 0 then
    Delta := -FMouseWheelLines
  else if WheelDelta < 0 then
    Delta := FMouseWheelLines
  else
    Exit;

  SetTopIndex(FTopIndex + Delta);

  Result := True;
end;

procedure TCssListBox.Paint;
var
  ListR, ItemR, TextR: TRect;
  I, First, Last, VisibleCount: Integer;
  BG, FG: TColor;
  ItemText: string;
begin
  inherited Paint;

  ListR := GetListRect;

  if (ListR.Right <= ListR.Left) or (ListR.Bottom <= ListR.Top) then
    Exit;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := GetItemBackground;
  Canvas.FillRect(ListR);

  AssignCssFontToFont(Canvas.Font);

  VisibleCount := GetVisibleCount;

  First := FTopIndex;
  Last := CssMin(FItems.Count - 1, First + VisibleCount);

  for I := First to Last do
  begin
    ItemR := Rect(
      ListR.Left,
      ListR.Top + ((I - First) * FItemHeight),
      ListR.Right,
      ListR.Top + ((I - First + 1) * FItemHeight)
    );

    if ItemR.Bottom > ListR.Bottom then
      ItemR.Bottom := ListR.Bottom;

    if ItemR.Bottom <= ItemR.Top then
      Continue;

    if GetSelected(I) then
    begin
      BG := GetSelectedItemBackground;
      FG := GetSelectedItemColor;
    end
    else if I = FHoverIndex then
    begin
      BG := GetHoverItemBackground;
      FG := GetHoverItemColor;
    end
    else
    begin
      BG := GetItemBackground;
      FG := GetItemColor;
    end;

    if BG <> clNone then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := BG;
      Canvas.FillRect(ItemR);
    end;

    Canvas.Font.Color := FG;

    TextR := ItemR;

    TextR.Left := TextR.Left + FItemPadding + 2;
    TextR.Right := TextR.Right - FItemPadding - 2;

    ItemText := FItems[I];

    if HtmlMode then
      DrawHtmlText(TextR, ItemText)
    else
      DrawStyledText(TextR, ItemText);
  end;

  if Focused and ShowFocusRect and
     (FItemIndex >= First) and (FItemIndex <= Last) then
  begin
    ItemR := Rect(
      ListR.Left,
      ListR.Top + ((FItemIndex - First) * FItemHeight),
      ListR.Right,
      ListR.Top + ((FItemIndex - First + 1) * FItemHeight)
    );

    if ItemR.Bottom > ListR.Bottom then
      ItemR.Bottom := ListR.Bottom;

    if ItemR.Bottom > ItemR.Top then
      DrawFocusRect(Canvas, ItemR);
  end;
end;

end.
