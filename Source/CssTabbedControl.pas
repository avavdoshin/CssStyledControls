unit CssTabbedControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, LCLIntf,
  IntfGraphics, FPImage, CssStyledControl;

const
  CSS_TAB_SCROLL_EDGE_MARGIN = 6;

  CSS_TAB_SCROLL_GAP = 6;

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

    FLastAppliedRadius: Integer;
    FLastAppliedSize: TPoint;

    // Property setters
    procedure SetTabVisible(AValue: Boolean);
  protected
    procedure SetParent(AParent: TWinControl); override;
    // Painting
    procedure Paint; override;

    // Caption
    procedure SetCaption(const AValue: TCaption); override;

    procedure CreateWnd; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure StyleChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    HasParent: Boolean; override;
    function    GetParentComponent: TComponent; override;
    procedure   SetParentComponent(Value: TComponent); override;
    procedure   InheritStyleFromPageControl;
    procedure   UpdateShape;
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

    // === Scroll buttons ===
    FShowScrollButtons: Boolean;
    FScrollButtonSize: Integer;    // 0 = auto (= FTabHeight)
    FFirstVisibleTab: Integer;
    FHoverScrollButton: Integer;   // -1 no, 0 prev, 1 next

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

    // Scroll button appearance
    FScrollButtonBackground: TColor;         FScrollButtonBackgroundSet: Boolean;
    FScrollButtonHoverBackground: TColor;    FScrollButtonHoverBackgroundSet: Boolean;
    FScrollButtonActiveBackground: TColor;   FScrollButtonActiveBackgroundSet: Boolean;
    FScrollButtonArrowColor: TColor;         FScrollButtonArrowColorSet: Boolean;
    FScrollButtonRadius: Integer;            FScrollButtonRadiusSet: Boolean;
    FScrollButtonDisabledBackground: TColor; FScrollButtonDisabledBackgroundSet: Boolean;
    FScrollButtonDisabledArrowColor: TColor; FScrollButtonDisabledArrowColorSet: Boolean;

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

    // Focus
    FShowFocusWhenChildFocused: Boolean;
    FShowFocusWhenChildFocusedSet: Boolean;
    FHasFocusedChild: Boolean;

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

    // === Scroll buttons ===
    function  GetScrollButtonBackground: TColor;
    function  GetScrollButtonHoverBackground: TColor;
    function  GetScrollButtonActiveBackground: TColor;
    function  GetScrollButtonArrowColor: TColor;
    function  GetScrollButtonRadius: Integer;
    function  GetScrollButtonDisabledBackground: TColor;
    function  GetScrollButtonDisabledArrowColor: TColor;

    function  GetTabsExtentFrom(AIndex: Integer): Integer;
    function  CanScrollPrev: Boolean;
    function  CanScrollNext: Boolean;
    function  IsScrollButtonEnabled(AWhich: Integer): Boolean;

    function  GetScrollButtonSize: Integer;
    function  GetTabStripAvailableExtent: Integer;
    function  GetTotalTabsExtent: Integer;
    function  NeedScrollButtons: Boolean;
    function  GetTabStripRect: TRect;
    function  GetScrollButtonRect(AWhich: Integer): TRect;
    function  ScrollButtonAt(X, Y: Integer): Integer;
    procedure EnsureFirstVisibleTab;
    procedure ScrollTabs(ADelta: Integer);
    procedure DrawScrollButton(AWhich: Integer);
    procedure DrawScrollButtons;
    procedure DrawCornerMasks;

    procedure SetShowScrollButtons(AValue: Boolean);
    procedure SetScrollButtonSize(AValue: Integer);

    // Focus
    function  HasFocusedChild: Boolean;
    procedure UpdateFocusedChildState;

    // Hover
    function  GetEffectiveHoverState: Boolean; override;
  protected
    // Focus
    procedure ChildFocusChanged(AChildFocused: Boolean); override;
    procedure Loaded; override;

    // Painting
    procedure Paint; override;

    // Initialization and style
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure StyleChanged; override;

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
    function ShouldShowChildFocusRing: Boolean;
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

    // Scroll buttons
    property ShowScrollButtons: Boolean read FShowScrollButtons write SetShowScrollButtons default True;
    property ScrollButtonSize: Integer read FScrollButtonSize write SetScrollButtonSize default 0;
    property ScrollButtonDisabledBackground: TColor read GetScrollButtonDisabledBackground write FScrollButtonDisabledBackground;
    property ScrollButtonDisabledArrowColor: TColor read GetScrollButtonDisabledArrowColor write FScrollButtonDisabledArrowColor;

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

function LerpColorRGB(C1, C2: TColor; T: Double): TColor;
var
  RGB1, RGB2: LongInt;
  R1, G1, B1, R2, G2, B2: Integer;
begin
  if T <= 0 then Exit(C1);
  if T >= 1 then Exit(C2);

  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);

  R1 := RGB1 and $FF;
  G1 := (RGB1 shr 8) and $FF;
  B1 := (RGB1 shr 16) and $FF;
  R2 := RGB2 and $FF;
  G2 := (RGB2 shr 8) and $FF;
  B2 := (RGB2 shr 16) and $FF;

  Result := RGBToColor(
    Round(R1 + (R2 - R1) * T),
    Round(G1 + (G2 - G1) * T),
    Round(B1 + (B2 - B1) * T)
  );
end;

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
var
  ParentR: TRect;
begin
  inherited Paint;

  if (FPageControl = nil) or not FPageControl.ShouldShowChildFocusRing then
    Exit;

  ParentR := FPageControl.ClientRect;
  OffsetRect(ParentR, -Left, -Top);

  FPageControl.DrawFocusRect(Canvas, ParentR);
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

procedure TCssTabSheet.CreateWnd;
begin
  inherited CreateWnd;
  UpdateShape;
end;

procedure TCssTabSheet.Resize;
begin
  inherited Resize;
  UpdateShape;
end;

procedure TCssTabSheet.Loaded;
begin
  inherited Loaded;
  UpdateShape;
end;

procedure TCssTabSheet.StyleChanged;
begin
  inherited StyleChanged;
  UpdateShape;
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

procedure TCssTabSheet.UpdateShape;
var
  R, W, H: Integer;
  ParentPage: TCssPageControl;
  RgnAll, RgnTopFlat: HRGN;
  Rgn: TRegion;
  ParentInset, Inset: Integer;
  Pad: TRect;
begin
  if not HandleAllocated then
    Exit;

  W := Width;
  H := Height;

  if (W <= 0) or (H <= 0) then
    Exit;

  ParentPage := FPageControl;

  R := GetCssBorderRadius;

  if (R <= 0) and (ParentPage <> nil) then
  begin
    R := ParentPage.GetCssBorderRadius;

    if R > 0 then
    begin
      ParentInset := ParentPage.GetCssBorderWidth;
      Pad := ParentPage.GetCssPadding;

      Inset := ParentInset + Pad.Left;
      if ParentInset + Pad.Bottom > Inset then
        Inset := ParentInset + Pad.Bottom;
      if ParentInset + Pad.Right > Inset then
        Inset := ParentInset + Pad.Right;
      if ParentInset + Pad.Top > Inset then
        Inset := ParentInset + Pad.Top;

      R := R - Inset;
      if R < 0 then
        R := 0;
    end;
  end;

  if R <= 0 then
  begin
    if FLastAppliedRadius <> 0 then
    begin
      SetShape(TRegion(nil));
      FLastAppliedRadius := 0;
      FLastAppliedSize := Point(0, 0);
    end;
    Exit;
  end;

  if R > W div 2 then
    R := W div 2;

  if R > H div 2 then
    R := H div 2;

  if (R = FLastAppliedRadius) and
     (FLastAppliedSize.X = W) and
     (FLastAppliedSize.Y = H) then
    Exit;

  RgnAll := CreateRoundRectRgn(0, 0, W + 1, H + 1, 2 * R, 2 * R);
  RgnTopFlat := CreateRectRgn(0, 0, W + 1, R);
  CombineRgn(RgnAll, RgnAll, RgnTopFlat, RGN_OR);
  DeleteObject(RgnTopFlat);

  Rgn := TRegion.Create;
  try
    {$push}
    {$warn 6058 off}
    Rgn.Handle := RgnAll;
    {$pop}

    SetShape(Rgn);
  finally
    Rgn.Free;
  end;

  FLastAppliedRadius := R;
  FLastAppliedSize := Point(W, H);
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

  if HandleAllocated then
    UpdateShape;
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

  FShowScrollButtons := True;
  FScrollButtonSize := 0;
  FFirstVisibleTab := 0;
  FHoverScrollButton := -1;

  TCssStyledControl(Self).Caption := '';
end;

destructor TCssTabControl.Destroy;
begin
  FTabs.Free;

  inherited Destroy;
end;

function TCssTabControl.ShouldShowChildFocusRing: Boolean;
begin
  Result :=
    FShowFocusWhenChildFocused and
    ShowFocusRect and
    FHasFocusedChild and
    Enabled;
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

  FFirstVisibleTab := 0;
  EnsureFirstVisibleTab;
  Invalidate;
end;

procedure TCssTabControl.TabsChanged(Sender: TObject);
begin
  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;

  EnsureFirstVisibleTab;
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

  if FTabIndex >= 0 then
  begin
    if FTabIndex < FFirstVisibleTab then
      FFirstVisibleTab := FTabIndex
    else
    begin
      while (FFirstVisibleTab < FTabIndex) and
            (GetTabsExtentFrom(FFirstVisibleTab) >
             GetTabStripAvailableExtent) do
        Inc(FFirstVisibleTab);
    end;
  end;

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
  Strip: TRect;
  X, Y, Spacing, TabW, I: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  if (Index < 0) or (Index >= FTabs.Count) then
    Exit;

  if Index < FFirstVisibleTab then
    Exit;

  Strip := GetTabStripRect;
  Spacing := GetTabSpacing;

  case FTabPosition of
    ctpTop, ctpBottom:
    begin
      X := Strip.Left;

      for I := FFirstVisibleTab to Index - 1 do
        X := X + GetTabWidth(I) + Spacing;

      TabW := GetTabWidth(Index);
      Result := Rect(X, Strip.Top, X + TabW, Strip.Bottom);
    end;

    ctpLeft, ctpRight:
    begin
      Y := Strip.Top;

      for I := FFirstVisibleTab to Index - 1 do
        Y := Y + FTabHeight + Spacing;

      Result := Rect(Strip.Left, Y, Strip.Right, Y + FTabHeight);
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
  R, Strip: TRect;
  P: TPoint;
begin
  Result := -1;
  P := Point(X, Y);

  if ScrollButtonAt(X, Y) >= 0 then
    Exit;

  Strip := GetTabStripRect;

  if not PtInRect(Strip, P) then
    Exit;

  for I := FFirstVisibleTab to FTabs.Count - 1 do
  begin
    R := GetTabRect(I);

    if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
      Continue;

    if PtInRect(R, P) then
      Exit(I);

    case FTabPosition of
      ctpTop, ctpBottom:
        if R.Left >= Strip.Right then
          Break;
    else
      if R.Top >= Strip.Bottom then
        Break;
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

function TCssTabControl.GetScrollButtonBackground: TColor;
begin
  if FScrollButtonBackgroundSet then
    Result := FScrollButtonBackground
  else
    Result := GetTabBackground;
end;

function TCssTabControl.GetScrollButtonHoverBackground: TColor;
begin
  if FScrollButtonHoverBackgroundSet then
    Result := FScrollButtonHoverBackground
  else
    Result := GetTabHoverBackground;
end;

function TCssTabControl.GetScrollButtonActiveBackground: TColor;
begin
  if FScrollButtonActiveBackgroundSet then
    Result := FScrollButtonActiveBackground
  else
    Result := GetTabActiveBackground;
end;

function TCssTabControl.GetScrollButtonArrowColor: TColor;
begin
  if FScrollButtonArrowColorSet then
    Result := FScrollButtonArrowColor
  else
    Result := GetTabTextColor;
end;

function TCssTabControl.GetScrollButtonRadius: Integer;
begin
  if FScrollButtonRadiusSet then
    Result := FScrollButtonRadius
  else
    Result := 0;
end;

function TCssTabControl.GetScrollButtonDisabledBackground: TColor;
begin
  if FScrollButtonDisabledBackgroundSet then
    Result := FScrollButtonDisabledBackground
  else
    Result := GetScrollButtonBackground;
end;

function TCssTabControl.GetScrollButtonDisabledArrowColor: TColor;
begin
  if FScrollButtonDisabledArrowColorSet then
    Result := FScrollButtonDisabledArrowColor
  else
    Result := GetScrollButtonArrowColor;
end;

function TCssTabControl.GetTabsExtentFrom(AIndex: Integer): Integer;
var
  I: Integer;
  Spacing: Integer;
begin
  Result := 0;

  if (AIndex < 0) or (AIndex >= FTabs.Count) then
    Exit;

  Spacing := GetTabSpacing;

  for I := AIndex to FTabs.Count - 1 do
  begin
    if I > AIndex then
      Inc(Result, Spacing);
    Inc(Result, GetTabWidth(I));
  end;
end;

function TCssTabControl.CanScrollPrev: Boolean;
begin
  Result := NeedScrollButtons and (FFirstVisibleTab > 0);
end;

function TCssTabControl.CanScrollNext: Boolean;
begin
  if not NeedScrollButtons then
    Exit(False);

  if FFirstVisibleTab >= FTabs.Count - 1 then
    Exit(False);

  Result := GetTabsExtentFrom(FFirstVisibleTab) > GetTabStripAvailableExtent;
end;

function TCssTabControl.IsScrollButtonEnabled(AWhich: Integer): Boolean;
begin
  if AWhich = 0 then
    Result := CanScrollPrev
  else if AWhich = 1 then
    Result := CanScrollNext
  else
    Result := False;
end;

function TCssTabControl.GetScrollButtonSize: Integer;
begin
  if FScrollButtonSize > 0 then
    Result := FScrollButtonSize
  else
    Result := FTabHeight;

  if Result < 10 then
    Result := 10;
end;

function TCssTabControl.GetTabStripAvailableExtent: Integer;
var
  R: TRect;
begin
  R := GetInnerRect;

  case FTabPosition of
    ctpTop, ctpBottom:
      Result := (R.Right - 4) - (R.Left + 4);
    ctpLeft, ctpRight:
      Result := (R.Bottom - 4) - (R.Top + 4);
  else
    Result := 0;
  end;

  if Result < 0 then
    Result := 0;
end;

function TCssTabControl.GetTotalTabsExtent: Integer;
var
  I: Integer;
  Spacing: Integer;
begin
  Result := 0;

  if FTabs.Count = 0 then
    Exit;

  Spacing := GetTabSpacing;

  for I := 0 to FTabs.Count - 1 do
  begin
    if I > 0 then
      Inc(Result, Spacing);
    Inc(Result, GetTabWidth(I));
  end;
end;

function TCssTabControl.NeedScrollButtons: Boolean;
begin
  Result :=
    FShowScrollButtons and
    (FTabs.Count > 0) and
    (GetTotalTabsExtent > GetTabStripAvailableExtent);
end;

function TCssTabControl.GetTabStripRect: TRect;
var
  R: TRect;
  BtnArea: Integer;
begin
  R := GetInnerRect;

  if NeedScrollButtons then
    BtnArea := GetScrollButtonSize * 2 + CSS_TAB_SCROLL_GAP
  else
    BtnArea := 0;

  case FTabPosition of
    ctpTop:
      Result := Rect(
        R.Left + 4,
        R.Top + 2,
        R.Right - CSS_TAB_SCROLL_EDGE_MARGIN - BtnArea,
        R.Top + 2 + FTabHeight
      );

    ctpBottom:
      Result := Rect(
        R.Left + 4,
        R.Bottom - 2 - FTabHeight,
        R.Right - CSS_TAB_SCROLL_EDGE_MARGIN - BtnArea,
        R.Bottom - 2
      );

    ctpLeft:
      Result := Rect(
        R.Left + 2,
        R.Top + 4,
        R.Left + 2 + FTabHeight * 3,
        R.Bottom - CSS_TAB_SCROLL_EDGE_MARGIN - BtnArea
      );

    ctpRight:
      Result := Rect(
        R.Right - 2 - FTabHeight * 3,
        R.Top + 4,
        R.Right - 2,
        R.Bottom - CSS_TAB_SCROLL_EDGE_MARGIN - BtnArea
      );
  else
    Result := R;
  end;
end;

function TCssTabControl.GetScrollButtonRect(AWhich: Integer): TRect;
var
  R: TRect;
  BtnSize, X, Y: Integer;
  BtnGroupW: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  if not NeedScrollButtons then
    Exit;

  R := GetInnerRect;
  BtnSize := GetScrollButtonSize;
  BtnGroupW := BtnSize * 2;

  case FTabPosition of
    ctpTop, ctpBottom:
    begin
      X := R.Right
           - CSS_TAB_SCROLL_EDGE_MARGIN
           - BtnGroupW
           + AWhich * (BtnSize + 2);

      if FTabPosition = ctpTop then
        Y := R.Top + 2 + (FTabHeight - BtnSize) div 2
      else
        Y := R.Bottom - 2 - FTabHeight + (FTabHeight - BtnSize) div 2;

      Result := Rect(X, Y, X + BtnSize, Y + BtnSize);
    end;

    ctpLeft, ctpRight:
    begin
      Y := R.Bottom
           - CSS_TAB_SCROLL_EDGE_MARGIN
           - BtnGroupW
           + AWhich * BtnSize;

      if FTabPosition = ctpLeft then
        X := R.Left + 2 + (FTabHeight * 3 - BtnSize) div 2
      else
        X := R.Right - 2 - FTabHeight * 3 + (FTabHeight * 3 - BtnSize) div 2;

      Result := Rect(X, Y, X + BtnSize, Y + BtnSize);
    end;
  end;
end;

function TCssTabControl.ScrollButtonAt(X, Y: Integer): Integer;
begin
  Result := -1;

  if not NeedScrollButtons then
    Exit;

  if PtInRect(GetScrollButtonRect(0), Point(X, Y)) then
    Result := 0
  else if PtInRect(GetScrollButtonRect(1), Point(X, Y)) then
    Result := 1;
end;

procedure TCssTabControl.EnsureFirstVisibleTab;
begin
  if FTabs.Count = 0 then
    FFirstVisibleTab := 0
  else
  begin
    if FFirstVisibleTab < 0 then
      FFirstVisibleTab := 0;
    if FFirstVisibleTab >= FTabs.Count then
      FFirstVisibleTab := FTabs.Count - 1;
  end;
end;

procedure TCssTabControl.ScrollTabs(ADelta: Integer);
var
  NewFirst: Integer;
begin
  NewFirst := FFirstVisibleTab + ADelta;

  if NewFirst < 0 then
    NewFirst := 0;

  if (FTabs.Count > 0) and (NewFirst >= FTabs.Count) then
    NewFirst := FTabs.Count - 1;

  if NewFirst <> FFirstVisibleTab then
  begin
    FFirstVisibleTab := NewFirst;
    Invalidate;
  end;
end;

procedure TCssTabControl.DrawScrollButton(AWhich: Integer);
var
  R: TRect;
  Bg, ArrowColor, BgColorForBlend: TColor;
  Radius, CX, CY, S: Integer;
  BtnEnabled: Boolean;
begin
  R := GetScrollButtonRect(AWhich);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  BtnEnabled := IsScrollButtonEnabled(AWhich);

  if not BtnEnabled then
  begin
    Bg := GetScrollButtonDisabledBackground;

    if FScrollButtonDisabledArrowColorSet then
      ArrowColor := GetScrollButtonDisabledArrowColor
    else
      ArrowColor := LerpColorRGB(
        GetScrollButtonArrowColor, Bg, 0.6
      );
  end
  else if (FHoverScrollButton = AWhich) and GetMousePressedState then
    Bg := GetScrollButtonActiveBackground
  else if FHoverScrollButton = AWhich then
    Bg := GetScrollButtonHoverBackground
  else
    Bg := GetScrollButtonBackground;

  if BtnEnabled then
    ArrowColor := GetScrollButtonArrowColor;

  Radius := GetScrollButtonRadius;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Bg;
  Canvas.Pen.Style := psClear;

  if Radius > 0 then
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, Radius, Radius)
  else
    Canvas.FillRect(R);

  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  S := (R.Right - R.Left) div 4;

  if S < 3 then S := 3;
  if S > 7 then S := 7;

  BgColorForBlend := Bg;

  case FTabPosition of
    ctpTop, ctpBottom:
      if AWhich = 0 then
        DrawAntiAliasedTriangle(Canvas,
          Point(CX + S div 2, CY - S),
          Point(CX - S div 2, CY),
          Point(CX + S div 2, CY + S),
          ArrowColor, BgColorForBlend)
      else
        DrawAntiAliasedTriangle(Canvas,
          Point(CX - S div 2, CY - S),
          Point(CX + S div 2, CY),
          Point(CX - S div 2, CY + S),
          ArrowColor, BgColorForBlend);

    ctpLeft, ctpRight:
      if AWhich = 0 then
        DrawAntiAliasedTriangle(Canvas,
          Point(CX - S, CY + S div 2),
          Point(CX,     CY - S div 2),
          Point(CX + S, CY + S div 2),
          ArrowColor, BgColorForBlend)
      else
        DrawAntiAliasedTriangle(Canvas,
          Point(CX - S, CY - S div 2),
          Point(CX,     CY + S div 2),
          Point(CX + S, CY - S div 2),
          ArrowColor, BgColorForBlend);
  end;
end;

procedure TCssTabControl.DrawScrollButtons;
begin
  if not NeedScrollButtons then Exit;

  DrawScrollButton(0);
  DrawScrollButton(1);
end;

procedure TCssTabControl.DrawCornerMasks;
var
  R: TRect;
  Radius, PtCount: Integer;
  Pts: array of TPoint;
  BgColor: TColor;

  procedure AddPt(X, Y: Integer);
  begin
    SetLength(Pts, PtCount + 1);
    Pts[PtCount] := Point(X, Y);
    Inc(PtCount);
  end;

  procedure DrawCorner(Corner: Integer);
  var
    K, CX, CY: Integer;
    StartAngle, EndAngle, Angle: Double;
  begin
    PtCount := 0;
    SetLength(Pts, 0);

    case Corner of
      0: begin // top-left
        AddPt(R.Left, R.Top);
        AddPt(R.Left + Radius, R.Top);
        CX := R.Left + Radius; CY := R.Top + Radius;
        StartAngle := Pi * 1.5; EndAngle := Pi;
        for K := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (K / 16);
          AddPt(CX + Round(Radius * Cos(Angle)),
                CY + Round(Radius * Sin(Angle)));
        end;
        AddPt(R.Left, R.Top + Radius);
      end;
      1: begin // top-right
        AddPt(R.Right, R.Top);
        AddPt(R.Right - Radius, R.Top);
        CX := R.Right - Radius; CY := R.Top + Radius;
        StartAngle := Pi * 1.5; EndAngle := Pi * 2;
        for K := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (K / 16);
          AddPt(CX + Round(Radius * Cos(Angle)),
                CY + Round(Radius * Sin(Angle)));
        end;
        AddPt(R.Right, R.Top + Radius);
      end;
      2: begin // bottom-right
        AddPt(R.Right, R.Bottom);
        AddPt(R.Right, R.Bottom - Radius);
        CX := R.Right - Radius; CY := R.Bottom - Radius;
        StartAngle := 0; EndAngle := Pi * 0.5;
        for K := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (K / 16);
          AddPt(CX + Round(Radius * Cos(Angle)),
                CY + Round(Radius * Sin(Angle)));
        end;
        AddPt(R.Right - Radius, R.Bottom);
      end;
      3: begin // bottom-left
        AddPt(R.Left, R.Bottom);
        AddPt(R.Left + Radius, R.Bottom);
        CX := R.Left + Radius; CY := R.Bottom - Radius;
        StartAngle := Pi * 0.5; EndAngle := Pi;
        for K := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (K / 16);
          AddPt(CX + Round(Radius * Cos(Angle)),
                CY + Round(Radius * Sin(Angle)));
        end;
        AddPt(R.Left, R.Bottom - Radius);
      end;
    end;

    if PtCount > 2 then
      Canvas.Polygon(Pts);
  end;

begin
  Radius := GetCssBorderRadius;
  if Radius <= 0 then Exit;

  R := ClientRect;

  if Radius > (R.Right - R.Left) div 2 then
    Radius := (R.Right - R.Left) div 2;
  if Radius > (R.Bottom - R.Top) div 2 then
    Radius := (R.Bottom - R.Top) div 2;
  if Radius <= 0 then Exit;

  Canvas.Pen.Style := psClear;
  Canvas.Brush.Style := bsSolid;

  BgColor := GetBackgroundBeneathAtClientPoint(Point(R.Left, R.Top));
  Canvas.Brush.Color := BgColor;
  DrawCorner(0);

  BgColor := GetBackgroundBeneathAtClientPoint(Point(R.Right - 1, R.Top));
  Canvas.Brush.Color := BgColor;
  DrawCorner(1);

  BgColor := GetBackgroundBeneathAtClientPoint(Point(R.Right - 1, R.Bottom - 1));
  Canvas.Brush.Color := BgColor;
  DrawCorner(2);

  BgColor := GetBackgroundBeneathAtClientPoint(Point(R.Left, R.Bottom - 1));
  Canvas.Brush.Color := BgColor;
  DrawCorner(3);

  Canvas.Pen.Style := psSolid;
end;

procedure TCssTabControl.SetShowScrollButtons(AValue: Boolean);
begin
  if FShowScrollButtons = AValue then Exit;
  FShowScrollButtons := AValue;
  EnsureFirstVisibleTab;
  Invalidate;
end;

procedure TCssTabControl.SetScrollButtonSize(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FScrollButtonSize = AValue then Exit;
  FScrollButtonSize := AValue;
  Invalidate;
end;

function TCssTabControl.HasFocusedChild: Boolean;
var
  H: HWND;
  aFocused: TWinControl;
  C: TControl;
begin
  Result := False;

  H := GetFocus;
  if H = 0 then
    Exit;

  aFocused := FindControl(H);
  if aFocused = nil then
    Exit;

  C := aFocused;
  while C <> nil do
  begin
    if C = Self then
      Exit(True);

    C := C.Parent;
  end;
end;

procedure TCssTabControl.UpdateFocusedChildState;
var
  NewState: Boolean;
begin
  NewState := HasFocusedChild;

  if NewState <> FHasFocusedChild then
  begin
    FHasFocusedChild := NewState;

    if FShowFocusWhenChildFocused then
    begin
      RefreshStylesByState;
      Invalidate;
    end;
  end;
end;

function TCssTabControl.GetEffectiveHoverState: Boolean;
begin
  if FShowFocusWhenChildFocused and FHasFocusedChild then
    Exit(False);

  Result := inherited GetEffectiveHoverState;
end;

procedure TCssTabControl.ChildFocusChanged(AChildFocused : Boolean);
begin
  UpdateFocusedChildState;
end;

procedure TCssTabControl.Loaded;
begin
  inherited Loaded;
  UpdateFocusedChildState;
end;

procedure TCssTabControl.Paint;
var
  I: Integer;
  TabR, Strip, SavedClip: TRect;
  BG, FG, BorderC: TColor;
  TS: TTextStyle;
begin
  inherited Paint;

  AssignCssFontToFont(Canvas.Font);

  EnsureFirstVisibleTab;

  Strip := GetTabStripRect;

  if (Strip.Right > Strip.Left) and (Strip.Bottom > Strip.Top) then
  begin
    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := Strip;
    try
      for I := FFirstVisibleTab to FTabs.Count - 1 do
      begin
        TabR := GetTabRect(I);

        case FTabPosition of
          ctpTop, ctpBottom:
            if TabR.Left >= Strip.Right then
              Break;
        else
          if TabR.Top >= Strip.Bottom then
            Break;
        end;

        if TabR.Right > Strip.Right then
          TabR.Right := Strip.Right;

        if TabR.Bottom > Strip.Bottom then
          TabR.Bottom := Strip.Bottom;

        if (TabR.Right <= TabR.Left) or (TabR.Bottom <= TabR.Top) then
          Continue;

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

        if BG <> clNone then
        begin
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := BG;
        end
        else
          Canvas.Brush.Style := bsClear;

        if BorderC <> clNone then
        begin
          Canvas.Pen.Style := psSolid;
          Canvas.Pen.Color := BorderC;
          Canvas.Pen.Width := 1;
        end
        else
          Canvas.Pen.Style := psClear;

        if GetTabRadius > 0 then
          Canvas.RoundRect(TabR.Left, TabR.Top, TabR.Right, TabR.Bottom,
                           GetTabRadius, GetTabRadius)
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
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;

  if NeedScrollButtons then
    DrawScrollButtons;

  if ShouldShowChildFocusRing then
  begin
    DrawFocusRect(Canvas, ClientRect);
  end;

//  DrawCornerMasks;
end;

procedure TCssTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Idx, BtnIdx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then Exit;
  if Button <> mbLeft then Exit;

  BtnIdx := ScrollButtonAt(X, Y);
  if BtnIdx >= 0 then
  begin
    if not IsScrollButtonEnabled(BtnIdx) then
      Exit;

    if BtnIdx = 0 then
      ScrollTabs(-1)
    else
      ScrollTabs(1);
    Exit;
  end;

  Idx := TabAtPos(X, Y);
  if (Idx >= 0) and (Idx <> FTabIndex) then
    TabIndex := Idx;
end;

procedure TCssTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx, BtnIdx: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then Exit;

  BtnIdx := ScrollButtonAt(X, Y);

  if (BtnIdx >= 0) and not IsScrollButtonEnabled(BtnIdx) then
    BtnIdx := -1;

  if BtnIdx <> FHoverScrollButton then
  begin
    FHoverScrollButton := BtnIdx;
    Invalidate;
  end;

  if BtnIdx >= 0 then
  begin
    Cursor := FTabCursor;
    Exit;
  end;

  Idx := TabAtPos(X, Y);

  if Idx >= 0 then
  begin
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

  if (FHoverIndex <> -1) or (FHoverScrollButton <> -1) then
  begin
    FHoverIndex := -1;
    FHoverScrollButton := -1;
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
  FScrollButtonBackgroundSet := False;
  FScrollButtonHoverBackgroundSet := False;
  FScrollButtonActiveBackgroundSet := False;
  FScrollButtonArrowColorSet := False;
  FScrollButtonRadiusSet := False;
  FScrollButtonDisabledBackgroundSet := False;
  FScrollButtonDisabledArrowColorSet := False;

  inherited ResetStyle;
end;

procedure TCssTabControl.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
  S: string;
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

  if AName = 'tab-scroll-button-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonBackground := C;
      FScrollButtonBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-button-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonHoverBackground := C;
      FScrollButtonHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-button-active-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonActiveBackground := C;
      FScrollButtonActiveBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-arrow-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonArrowColor := C;
      FScrollButtonArrowColorSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-button-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FScrollButtonRadius := Px;
      FScrollButtonRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-button-size' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      SetScrollButtonSize(Px);
    Exit;
  end;

  if AName = 'tab-scroll-button-disabled-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonDisabledBackground := C;
      FScrollButtonDisabledBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'tab-scroll-arrow-disabled-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FScrollButtonDisabledArrowColor := C;
      FScrollButtonDisabledArrowColorSet := True;
    end;
    Exit;
  end;

  if AName = 'focus-within' then
  begin
    S := LowerCase(Trim(AValue));
    FShowFocusWhenChildFocused := (S = 'true') or (S = '1') or (S = 'yes');
    FShowFocusWhenChildFocusedSet := True;
    Invalidate;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssTabControl.StyleChanged;
begin
  inherited StyleChanged;
  UpdateFocusedChildState;
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
    SetActivePageIndex(0)
  else
  begin
    LayoutSheets;
    if csDesigning in ComponentState then
      SetActivePageIndex(FPages.Count - 1);
  end;

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
  ActiveSheet: TCssTabSheet;
begin
  if not Assigned(FPages) then
    Exit;

  ContentR := GetContentRect;

  ActiveSheet := nil;
  if (FActivePageIndex >= 0) and (FActivePageIndex < FPages.Count) then
    ActiveSheet := TCssTabSheet(FPages[FActivePageIndex]);

  for I := 0 to FPages.Count - 1 do
  begin
    Sheet := TCssTabSheet(FPages[I]);

    if Sheet = ActiveSheet then
      Continue;

    Sheet.Visible := False;

    if (Sheet.Left <> -32000) or (Sheet.Top <> -32000) then
      Sheet.SetBounds(-32000, -32000, 1, 1);
  end;

  if ActiveSheet <> nil then
  begin
    ActiveSheet.SetBounds(
      ContentR.Left,
      ContentR.Top,
      ContentR.Right - ContentR.Left,
      ContentR.Bottom - ContentR.Top
    );
    ActiveSheet.Visible := True;
    ActiveSheet.BringToFront;
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
  begin
    TCssTabSheet(FPages[I]).InheritStyleFromPageControl;
    TCssTabSheet(FPages[I]).UpdateShape;
  end;
  UpdateFocusedChildState;
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
