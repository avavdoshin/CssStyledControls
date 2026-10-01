unit CssTabbedControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  CssStyledControl;

type
  TCssTabPosition = (ctpTop, ctpBottom, ctpLeft, ctpRight);

  TCssPageControl = class;
  TCssTabSheet = class;
  TCssTabControl = class;

  TCssTabSheet = class(TCssStyledControl)
  private
    // Data
    FPageControl: TCssPageControl;
    FTabVisible: Boolean;

    // Property setters
    procedure SetTabVisible(AValue: Boolean);
  protected
    procedure SetParent(AParent: TWinControl); override;
    // Painting
    procedure Paint; override;

    // Caption
    procedure SetCaption(const AValue: TCaption); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    HasParent: Boolean; override;
    function    GetParentComponent: TComponent; override;
    procedure   SetParentComponent(Value: TComponent); override;
    procedure   InheritStyleFromPageControl;
  published
    property TabVisible: Boolean read FTabVisible write SetTabVisible default True;
    property PageControl: TCssPageControl read FPageControl;

    property Align;
    property Color;
    property Enabled;
    property Font;
    property Visible;
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

  TCssTabControl = class(TCssStyledControl)
  private
    // Tabs data
    FTabs: TStringList;
    FTabIndex: Integer;
    FTabPosition: TCssTabPosition;
    FTabHeight: Integer;
    FTabWidth: Integer;
    FHoverIndex: Integer;

    // Tab appearance
    FTabBackground: TColor;
    FTabBackgroundSet: Boolean;
    FTabHoverBackground: TColor;
    FTabHoverBackgroundSet: Boolean;
    FTabActiveBackground: TColor;
    FTabActiveBackgroundSet: Boolean;
    FTabTextColor: TColor;
    FTabTextColorSet: Boolean;
    FTabActiveTextColor: TColor;
    FTabActiveTextColorSet: Boolean;
    FTabBorderColor: TColor;
    FTabBorderColorSet: Boolean;
    FTabRadius: Integer;
    FTabRadiusSet: Boolean;

    // Layout
    FTabSpacing: Integer;
    FTabSpacingSet: Boolean;
    FTabPadding: Integer;
    FTabPaddingSet: Boolean;
    FTabAutoSize: Boolean;

    // Cursors
    FTabCursor: TCursor;      // Cursor over tabs
    FContentCursor: TCursor;  // Cursor over the rest of the control

    // Events
    FOnChange: TNotifyEvent;

    // Appearance getters
    function GetTabBackground: TColor;
    function GetTabHoverBackground: TColor;
    function GetTabActiveBackground: TColor;
    function GetTabTextColor: TColor;
    function GetTabActiveTextColor: TColor;
    function GetTabBorderColor: TColor;
    function GetTabRadius: Integer;

    // Layout getters
    function GetTabPadding: Integer;
    function GetTabSpacing: Integer;
    procedure SetTabSpacing(AValue: Integer);

    // Tab list
    function GetTabs: TStrings;
    procedure SetTabs(AValue: TStrings);
    procedure TabsChanged(Sender: TObject);

    // Tab state setters
    procedure SetTabIndex(AValue: Integer);
    procedure SetTabPosition(AValue: TCssTabPosition);
    procedure SetTabHeight(AValue: Integer);
    procedure SetTabWidth(AValue: Integer);

    // Geometry
    function GetInnerRect: TRect;
    function GetTabRect(Index: Integer): TRect;
    function TabAtPos(X, Y: Integer): Integer;
    function GetTabWidth(Index: Integer): Integer;
  protected
    // Painting
    procedure Paint; override;

    // Initialization and style
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Change notification
    procedure DoChange; virtual;

    // Geometry
    function GetContentRect: TRect; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Tab data
    property Tabs: TStrings read GetTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default -1;
    property TabPosition: TCssTabPosition read FTabPosition write SetTabPosition default ctpTop;
    property TabHeight: Integer read FTabHeight write SetTabHeight default 24;
    property TabWidth: Integer read FTabWidth write SetTabWidth default 90;

    // Layout
    property TabSpacing: Integer read FTabSpacing write SetTabSpacing;
    property TabPadding: Integer read FTabPadding write FTabPadding default 8;
    property TabAutoSize: Boolean read FTabAutoSize write FTabAutoSize default True;

    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Standard properties
    property Align;
    property Enabled;
    property Font;
    property Visible;
    property OnClick;
  end;

  TCssPageControl = class(TCssTabControl)
  private
    // Pages
    FPages: TList;
    FActivePageIndex: Integer;
    FTabToPage: array of Integer;

    // Events
    FOnPageChange: TNotifyEvent;

    // Page accessors
    function GetPageCount: Integer;
    function GetPage(Index: Integer): TCssTabSheet;
    function GetActivePage: TCssTabSheet;
    procedure SetActivePage(AValue: TCssTabSheet);
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(AValue: Integer);

    // Helpers
    function VisibleIndexForPage(APageIndex: Integer): Integer;
    procedure SetActivePageIndexInternal(AValue: Integer);
  protected
    // Change notification
    procedure DoChange; override;

    // Sizing
    procedure Resize; override;

    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure StyleChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Page management
    procedure AddPage(APage: TCssTabSheet);
    procedure RemovePage(APage: TCssTabSheet);
    function AddNewPage: TCssTabSheet;
    procedure SyncTabs;
    procedure LayoutSheets;

    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TCssTabSheet read GetPage;
  published
    property ActivePage: TCssTabSheet read GetActivePage write SetActivePage;
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex default -1;
    property OnPageChange: TNotifyEvent read FOnPageChange write FOnPageChange;
  end;

implementation

{ TCssTabSheet }

constructor TCssTabSheet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];

  FTabVisible := True;
  Caption := 'Page';

  Width := 200;
  Height := 150;

  TCssStyledControl(Self).Caption := '';
end;

destructor TCssTabSheet.Destroy;
var
  PC: TCssPageControl;
begin
  PC := FPageControl;
  FPageControl := nil;

  if (PC <> nil) and not (csDestroying in PC.ComponentState) then
    PC.RemovePage(Self);

  inherited Destroy;
end;

function TCssTabSheet.HasParent : Boolean;
begin
  Result := (FPageControl <> nil) or (Parent <> nil);
end;

function TCssTabSheet.GetParentComponent : TComponent;
begin
  if FPageControl <> nil then
    Result := FPageControl
  else
    Result := Parent;
end;

procedure TCssTabSheet.SetParentComponent(Value : TComponent);
begin
  if Value is TCssPageControl then
    Parent := TCssPageControl(Value)
  else if Value = nil then
    Parent := nil;
end;

procedure TCssTabSheet.Paint;
begin
  // Draw only the CSS background/border; the caption is drawn on the tab
  // by the PageControl itself.
  inherited Paint;
end;

procedure TCssTabSheet.SetCaption(const AValue: TCaption);
begin
  if Caption = AValue then
    Exit;

  inherited SetCaption(AValue);

  if Assigned(FPageControl) then
  begin
    FPageControl.SyncTabs;
    FPageControl.Invalidate;
  end;
end;

procedure TCssTabSheet.SetTabVisible(AValue: Boolean);
begin
  if FTabVisible = AValue then
    Exit;

  FTabVisible := AValue;

  if Assigned(FPageControl) then
  begin
    FPageControl.SyncTabs;
    FPageControl.Invalidate;
  end;
end;

procedure TCssTabSheet.InheritStyleFromPageControl;
begin
  if FPageControl = nil then
    Exit;

  if StyleProvider <> FPageControl.StyleProvider then
    StyleProvider := FPageControl.StyleProvider;

  if (StyleName = '') and (FPageControl.StyleName <> '') then
    StyleName := FPageControl.StyleName;
end;

procedure TCssTabSheet.SetParent(AParent: TWinControl);
var
  OldPC: TCssPageControl;
begin
  if Parent = AParent then
  begin
    inherited SetParent(AParent);
    Exit;
  end;

  OldPC := FPageControl;

  inherited SetParent(AParent);

  if csDestroying in ComponentState then
    Exit;

  if AParent is TCssPageControl then
  begin
    if OldPC <> TCssPageControl(AParent) then
    begin
      FPageControl := TCssPageControl(AParent);
      TCssPageControl(AParent).AddPage(Self);

      if (OldPC <> nil) and not (csDestroying in OldPC.ComponentState) then
        OldPC.RemovePage(Self);
    end;

    InheritStyleFromPageControl;
  end
  else if OldPC <> nil then
  begin
    FPageControl := nil;

    if not (csDestroying in OldPC.ComponentState) then
      OldPC.RemovePage(Self);
  end;
end;

{ TCssTabControl }

constructor TCssTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTabs := TStringList.Create;
  FTabs.OnChange := @TabsChanged;

  FTabIndex := -1;
  FTabPosition := ctpTop;
  FTabHeight := 24;
  FTabWidth := 90;
  FHoverIndex := -1;

  FTabSpacing := 0;
  FTabPadding := 8;
  FTabAutoSize := True;

  FTabCursor := crHandPoint;   // default: hand, since tabs are clickable
  FContentCursor := crDefault;

  TCssStyledControl(Self).Caption := '';
end;

destructor TCssTabControl.Destroy;
begin
  FTabs.Free;

  inherited Destroy;
end;

function TCssTabControl.GetTabPadding: Integer;
begin
  if FTabPaddingSet then
    Result := FTabPadding
  else
    Result := 8;
end;

function TCssTabControl.GetTabSpacing: Integer;
begin
  if FTabSpacingSet then
    Result := FTabSpacing
  else
    Result := 0;
end;

procedure TCssTabControl.SetTabSpacing(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  FTabSpacing := AValue;
  FTabSpacingSet := True;

  Invalidate;
end;

function TCssTabControl.GetTabs: TStrings;
begin
  Result := FTabs;
end;

procedure TCssTabControl.SetTabs(AValue: TStrings);
begin
  FTabs.Assign(AValue);

  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;

  Invalidate;
end;

procedure TCssTabControl.TabsChanged(Sender: TObject);
begin
  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;

  Invalidate;
end;

procedure TCssTabControl.SetTabIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue := -1;

  if AValue >= FTabs.Count then
    AValue := FTabs.Count - 1;

  if FTabIndex = AValue then
    Exit;

  FTabIndex := AValue;

  DoChange;
  Invalidate;
end;

procedure TCssTabControl.SetTabPosition(AValue: TCssTabPosition);
begin
  if FTabPosition = AValue then
    Exit;

  FTabPosition := AValue;
  Invalidate;
end;

procedure TCssTabControl.SetTabHeight(AValue: Integer);
begin
  if AValue < 8 then
    AValue := 8;

  if FTabHeight = AValue then
    Exit;

  FTabHeight := AValue;
  Invalidate;
end;

procedure TCssTabControl.SetTabWidth(AValue: Integer);
begin
  if AValue < 16 then
    AValue := 16;

  if FTabWidth = AValue then
    Exit;

  FTabWidth := AValue;
  Invalidate;
end;

procedure TCssTabControl.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TCssTabControl.GetInnerRect: TRect;
begin
  Result := inherited GetContentRect;
end;

function TCssTabControl.GetTabRect(Index: Integer): TRect;
var
  R: TRect;
  X, Y, Spacing, TabW, I: Integer;
begin
  R := GetInnerRect;
  Result := Rect(0, 0, 0, 0);

  Spacing := GetTabSpacing;

  // Compute X as the sum of the widths of the previous tabs.
  X := R.Left + 4;

  for I := 0 to Index - 1 do
    X := X + GetTabWidth(I) + Spacing;

  TabW := GetTabWidth(Index);

  case FTabPosition of
    ctpTop:
      Result := Rect(X, R.Top + 2, X + TabW, R.Top + 2 + FTabHeight);

    ctpBottom:
      Result := Rect(X, R.Bottom - 2 - FTabHeight, X + TabW, R.Bottom - 2);

    ctpLeft:
    begin
      // For vertical tabs, use a fixed width.
      Y := R.Top + 4;

      for I := 0 to Index - 1 do
        Y := Y + FTabHeight + Spacing;

      Result := Rect(R.Left + 2, Y, R.Left + 2 + FTabHeight * 3, Y + FTabHeight);
    end;

    ctpRight:
    begin
      Y := R.Top + 4;

      for I := 0 to Index - 1 do
        Y := Y + FTabHeight + Spacing;

      Result := Rect(R.Right - 2 - FTabHeight * 3, Y, R.Right - 2, Y + FTabHeight);
    end;
  end;
end;

function TCssTabControl.GetContentRect: TRect;
begin
  Result := GetInnerRect;

  case FTabPosition of
    ctpTop:
      Result.Top := Result.Top + FTabHeight + 4;

    ctpBottom:
      Result.Bottom := Result.Bottom - FTabHeight - 4;

    ctpLeft:
      Result.Left := Result.Left + FTabHeight * 3 + 4;

    ctpRight:
      Result.Right := Result.Right - FTabHeight * 3 - 4;
  end;
end;

function TCssTabControl.TabAtPos(X, Y: Integer): Integer;
var
  I: Integer;
  R: TRect;
begin
  Result := -1;

  for I := 0 to FTabs.Count - 1 do
  begin
    R := GetTabRect(I);

    if PtInRect(R, Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssTabControl.GetTabBackground: TColor;
begin
  if FTabBackgroundSet then
    Result := FTabBackground
  else
    Result := RGBToColor(228, 228, 228);
end;

function TCssTabControl.GetTabHoverBackground: TColor;
begin
  if FTabHoverBackgroundSet then
    Result := FTabHoverBackground
  else
    Result := RGBToColor(210, 215, 222);
end;

function TCssTabControl.GetTabActiveBackground: TColor;
begin
  if FTabActiveBackgroundSet then
    Result := FTabActiveBackground
  else
    Result := GetCssBackgroundColor;
end;

function TCssTabControl.GetTabTextColor: TColor;
begin
  if FTabTextColorSet then
    Result := FTabTextColor
  else
    Result := GetCssTextColor;
end;

function TCssTabControl.GetTabActiveTextColor: TColor;
begin
  if FTabActiveTextColorSet then
    Result := FTabActiveTextColor
  else
    Result := GetCssTextColor;
end;

function TCssTabControl.GetTabBorderColor: TColor;
begin
  if FTabBorderColorSet then
    Result := FTabBorderColor
  else
    Result := GetCssBorderColor;
end;

function TCssTabControl.GetTabRadius: Integer;
begin
  if FTabRadiusSet then
    Result := FTabRadius
  else
    Result := 4;
end;

function TCssTabControl.GetTabWidth(Index: Integer): Integer;
var
  TextW: Integer;
  S: TSize;
begin
  if not FTabAutoSize then
  begin
    Result := FTabWidth;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  if (Index >= 0) and (Index < FTabs.Count) then
  begin
    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(FTabs[Index], 0);
      TextW := S.cx;
    end
    else
      TextW := Canvas.TextWidth(FTabs[Index]);
  end
  else
    TextW := 0;

  Result := TextW + GetTabPadding * 2;

  if Result < FTabWidth then
    Result := FTabWidth;
end;

procedure TCssTabControl.Paint;
var
  I: Integer;
  TabR: TRect;
  BG, FG, BorderC: TColor;
  TS: TTextStyle;
begin
  inherited Paint;

  AssignCssFontToFont(Canvas.Font);

  for I := 0 to FTabs.Count - 1 do
  begin
    TabR := GetTabRect(I);

    if I = FTabIndex then
    begin
      BG := GetTabActiveBackground;
      FG := GetTabActiveTextColor;
    end
    else if I = FHoverIndex then
    begin
      BG := GetTabHoverBackground;
      FG := GetTabTextColor;
    end
    else
    begin
      BG := GetTabBackground;
      FG := GetTabTextColor;
    end;

    BorderC := GetTabBorderColor;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := BG;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color := BorderC;
    Canvas.Pen.Width := 1;

    if GetTabRadius > 0 then
      Canvas.RoundRect(TabR.Left, TabR.Top, TabR.Right, TabR.Bottom, GetTabRadius, GetTabRadius)
    else
      Canvas.Rectangle(TabR.Left, TabR.Top, TabR.Right, TabR.Bottom);

    Canvas.Font.Color := FG;

    if HtmlMode then
      DrawHtmlText(TabR, FTabs[I])
    else
    begin
      TS := Default(TTextStyle);
      FillChar(TS, SizeOf(TS), 0);
      TS.Alignment := taCenter;
      TS.Layout := tlCenter;
      TS.Clipping := True;

      Canvas.TextRect(TabR, TabR.Left, TabR.Top, FTabs[I], TS);
    end;
  end;
end;

procedure TCssTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if Button <> mbLeft then
    Exit;

  Idx := TabAtPos(X, Y);

  if (Idx >= 0) and (Idx <> FTabIndex) then
    TabIndex := Idx;
end;

procedure TCssTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  Idx := TabAtPos(X, Y);

  if Idx >= 0 then
  begin
    // Over the active tab — content-area cursor;
    // over an inactive tab — tab cursor.
    if Idx = TabIndex then
      Cursor := FContentCursor
    else
      Cursor := FTabCursor;
  end
  else
    Cursor := FContentCursor;

  if Idx <> FHoverIndex then
  begin
    FHoverIndex := Idx;
    Invalidate;
  end;
end;

procedure TCssTabControl.MouseLeave;
begin
  Cursor := FContentCursor;

  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;

  inherited MouseLeave;
end;

procedure TCssTabControl.ResetStyle;
begin
  FTabBackgroundSet := False;
  FTabHoverBackgroundSet := False;
  FTabActiveBackgroundSet := False;
  FTabTextColorSet := False;
  FTabActiveTextColorSet := False;
  FTabBorderColorSet := False;
  FTabRadiusSet := False;
  FTabSpacingSet := False;
  FTabPaddingSet := False;
  FTabAutoSize := True;
  FTabCursor := crHandPoint;
  FContentCursor := crDefault;

  inherited ResetStyle;
end;

procedure TCssTabControl.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'tab-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabBackground := C;
      FTabBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabHoverBackground := C;
      FTabHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-active-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabActiveBackground := C;
      FTabActiveBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabTextColor := C;
      FTabTextColorSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-active-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabActiveTextColor := C;
      FTabActiveTextColorSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FTabBorderColor := C;
      FTabBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FTabRadius := Px;
      FTabRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-spacing' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FTabSpacing := Px;
      FTabSpacingSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-padding' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FTabPadding := Px;
      FTabPaddingSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-auto-size' then
  begin
    FTabAutoSize := (LowerCase(Trim(AValue)) = 'true') or (AValue = '1');
    Exit;
  end;

  if AName = 'tab-cursor' then
  begin
    FTabCursor := ParseCssCursor(AValue);
    Exit;
  end;

  if AName = 'cursor' then
  begin
    FContentCursor := ParseCssCursor(AValue);
    Cursor := FContentCursor;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

{ TCssPageControl }

constructor TCssPageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPages := TList.Create;
  FActivePageIndex := -1;
end;

destructor TCssPageControl.Destroy;
var
  I: Integer;
  Sheet: TCssTabSheet;
begin
  if Assigned(FPages) then
  begin
    for I := 0 to FPages.Count - 1 do
    begin
      Sheet := TCssTabSheet(FPages[I]);

      if Sheet.FPageControl = Self then
        Sheet.FPageControl := nil;
    end;

    FPages.Clear;
    FreeAndNil(FPages);
  end;

  inherited Destroy;
end;

function TCssPageControl.GetPageCount: Integer;
begin
  if not Assigned(FPages) then
  begin
    Result := 0;
    Exit;
  end;

  Result := FPages.Count;
end;

function TCssPageControl.GetPage(Index: Integer): TCssTabSheet;
begin
  if not Assigned(FPages) then
  begin
    Result := nil;
    Exit;
  end;

  if (Index >= 0) and (Index < FPages.Count) then
    Result := TCssTabSheet(FPages[Index])
  else
    Result := nil;
end;

function TCssPageControl.GetActivePage: TCssTabSheet;
begin
  Result := GetPage(FActivePageIndex);
end;

procedure TCssPageControl.SetActivePage(AValue: TCssTabSheet);
var
  Idx: Integer;
begin
  if not Assigned(FPages) then
    Exit;

  if AValue = nil then
  begin
    SetActivePageIndex(-1);
    Exit;
  end;

  Idx := FPages.IndexOf(AValue);

  if Idx >= 0 then
    SetActivePageIndex(Idx);
end;

function TCssPageControl.GetActivePageIndex: Integer;
begin
  Result := FActivePageIndex;
end;

procedure TCssPageControl.SetActivePageIndex(AValue: Integer);
var
  VIdx: Integer;
begin
  if not Assigned(FPages) then
    Exit;

  if (AValue < 0) or (AValue >= FPages.Count) then
    Exit;

  if FActivePageIndex = AValue then
    Exit;

  FActivePageIndex := AValue;

  VIdx := VisibleIndexForPage(AValue);

  if VIdx >= 0 then
    FTabIndex := VIdx;

  LayoutSheets;

  if Assigned(FOnPageChange) then
    FOnPageChange(Self);

  if Assigned(FOnChange) then
    FOnChange(Self);

  Invalidate;
end;

function TCssPageControl.VisibleIndexForPage(APageIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to High(FTabToPage) do
  begin
    if FTabToPage[I] = APageIndex then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TCssPageControl.SetActivePageIndexInternal(AValue: Integer);
begin
  FActivePageIndex := AValue;

  LayoutSheets;

  if Assigned(FOnPageChange) then
    FOnPageChange(Self);
end;

procedure TCssPageControl.DoChange;
var
  PageIndex: Integer;
begin
  if (TabIndex >= 0) and (TabIndex < Length(FTabToPage)) then
  begin
    PageIndex := FTabToPage[TabIndex];
    SetActivePageIndexInternal(PageIndex);
  end;

  inherited DoChange;
end;

procedure TCssPageControl.AddPage(APage: TCssTabSheet);
begin
  if not Assigned(FPages) then
    Exit;

  if FPages.IndexOf(APage) >= 0 then
    Exit;

  FPages.Add(APage);

  APage.FPageControl := Self;
  APage.Parent := Self;

  SyncTabs;

  if FPages.Count = 1 then
    SetActivePageIndex(0);

  Invalidate;
end;

procedure TCssPageControl.RemovePage(APage: TCssTabSheet);
var
  Idx: Integer;
begin
  if csDestroying in ComponentState then
    Exit;

  if not Assigned(FPages) then
    Exit;

  Idx := FPages.IndexOf(APage);
  if Idx < 0 then
    Exit;

  FPages.Delete(Idx);

  if APage.FPageControl = Self then
    APage.FPageControl := nil;

  if FActivePageIndex >= FPages.Count then
    FActivePageIndex := FPages.Count - 1;

  SyncTabs;
  LayoutSheets;
  Invalidate;
end;

function TCssPageControl.AddNewPage: TCssTabSheet;
begin
  if not Assigned(FPages) then
    Exit;

  Result := TCssTabSheet.Create(Owner);
  Result.Caption := 'Page ' + IntToStr(FPages.Count + 1);
  AddPage(Result);
end;

procedure TCssPageControl.SyncTabs;
var
  I, SavedPage, VIdx: Integer;
begin
  if not Assigned(FPages) then
    Exit;

  SavedPage := FActivePageIndex;

  SetLength(FTabToPage, 0);
  FTabs.Clear;

  for I := 0 to FPages.Count - 1 do
  begin
    if TCssTabSheet(FPages[I]).TabVisible then
    begin
      FTabs.Add(TCssTabSheet(FPages[I]).Caption);

      SetLength(FTabToPage, Length(FTabToPage) + 1);
      FTabToPage[High(FTabToPage)] := I;
    end;
  end;

  // Restore the active tab after rebuilding.
  if SavedPage >= 0 then
  begin
    VIdx := VisibleIndexForPage(SavedPage);

    if VIdx >= 0 then
      FTabIndex := VIdx;
  end;

  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;

  Invalidate;
end;

procedure TCssPageControl.LayoutSheets;
var
  I: Integer;
  ContentR: TRect;
  Sheet: TCssTabSheet;
begin
  if not Assigned(FPages) then
    Exit;

  ContentR := GetContentRect;

  for I := 0 to FPages.Count - 1 do
  begin
    Sheet := TCssTabSheet(FPages[I]);

    if I = FActivePageIndex then
    begin
      Sheet.Visible := True;
      Sheet.SetBounds(
        ContentR.Left,
        ContentR.Top,
        ContentR.Right - ContentR.Left,
        ContentR.Bottom - ContentR.Top
      );
      Sheet.BringToFront;
    end
    else
      Sheet.Visible := False;
  end;
end;

procedure TCssPageControl.Resize;
begin
  inherited Resize;

  if Assigned(FPages) then
    LayoutSheets;
end;

procedure TCssPageControl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  if not Assigned(FPages) then Exit;

  for I := 0 to FPages.Count - 1 do
    Proc(TCssTabSheet(FPages[I]));
end;

procedure TCssPageControl.StyleChanged;
var
  I: Integer;
begin
  inherited StyleChanged;

  if not Assigned(FPages) then
    Exit;

  for I := 0 to FPages.Count - 1 do
    TCssTabSheet(FPages[I]).InheritStyleFromPageControl;
end;

initialization
  RegisterClass(TCssTabSheet);
  RegisterClass(TCssTabControl);
  RegisterClass(TCssPageControl);

finalization
  UnregisterClass(TCssTabSheet);
  UnregisterClass(TCssTabControl);
  UnregisterClass(TCssPageControl);

end.
