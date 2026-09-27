unit CssMenuControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  Forms, CssStyledControl;

type
  TCssMenuItem = class
  private
    // Fields
    FCaption: string;
    FItems: TList;
    FParent: TCssMenuItem;
    FOnClick: TNotifyEvent;
    FChecked: Boolean;
    FEnabled: Boolean;
    FVisible: Boolean;
    FSeparator: Boolean;
    FShortcut: string;
    FTag: NativeInt;

    // Property getters
    function GetCount: Integer;
    function GetItem(Index: Integer): TCssMenuItem;
  public
    constructor Create;
    destructor Destroy; override;

    // Child items
    function Add: TCssMenuItem;
    procedure Delete(Index: Integer);
    procedure Clear;
    function HasChildren: Boolean;

    // Properties
    property Caption: string read FCaption write FCaption;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TCssMenuItem read GetItem; default;
    property Parent: TCssMenuItem read FParent;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property Checked: Boolean read FChecked write FChecked;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Visible: Boolean read FVisible write FVisible;
    property Separator: Boolean read FSeparator write FSeparator;
    property Shortcut: string read FShortcut write FShortcut;
    property Tag: NativeInt read FTag write FTag;
  end;

  TCssMenuBase = class(TCssStyledControl)
  private
    // Items
    FItems: TList;

    // Menu appearance
    FMenuBackground: TColor;      FMenuBackgroundSet: Boolean;
    FMenuBorderColor: TColor;     FMenuBorderColorSet: Boolean;
    FMenuItemHeight: Integer;     FMenuItemHeightSet: Boolean;
    FMenuTextColor: TColor;       FMenuTextColorSet: Boolean;
    FMenuHoverBackground: TColor; FMenuHoverBackgroundSet: Boolean;
    FMenuHoverTextColor: TColor;  FMenuHoverTextColorSet: Boolean;
    FMenuDisabledText: TColor;    FMenuDisabledTextSet: Boolean;
    FMenuSeparatorColor: TColor;  FMenuSeparatorColorSet: Boolean;
    FMenuShortcutColor: TColor;   FMenuShortcutColorSet: Boolean;

    // Saved text alignment for HTML drawing
    FSavedVAlign: TCssVAlign;
    FSavedTextAlign: TCssTextAlign;

    // Property getters
    function GetCount: Integer;
    function GetItem(Index: Integer): TCssMenuItem;
    function GetMenuBackground: TColor;
    function GetMenuBorderColor: TColor;
    function GetMenuItemHeight: Integer;
    function GetMenuTextColor: TColor;
    function GetMenuHoverBackground: TColor;
    function GetMenuHoverTextColor: TColor;
    function GetMenuDisabledText: TColor;
    function GetMenuSeparatorColor: TColor;
    function GetMenuShortcutColor: TColor;
  protected
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure ResetStyle; override;

    property ItemsList: TList read FItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Item management
    function AddItem: TCssMenuItem;
    procedure ClearItems;

    // HTML drawing helpers
    procedure BeginMenuHtmlDraw;
    procedure EndMenuHtmlDraw;

    // Properties
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TCssMenuItem read GetItem; default;
  end;

  TCssMenuPopupForm = class(TForm)
  private
    // Data
    FMenu: TCssMenuBase;
    FItems: TList;
    FVisibleItems: TList;
    FHoverIndex: Integer;

    // Popup hierarchy
    FParentPopup: TCssMenuPopupForm;
    FSubPopup: TCssMenuPopupForm;
    FParentMenuItem: TCssMenuItem;

    // Event handlers
    procedure FormDeactivate(Sender: TObject);

    // Mouse-over helpers
    function IsMouseOverSelf: Boolean;
    function IsMouseOverTree: Boolean;

    // Item layout
    procedure BuildVisibleItems;
    procedure CalcSize;

    // Geometry
    function ItemRect(Index: Integer): TRect;
    function ItemAtPos(X, Y: Integer): Integer;

    // Popup chain management
    function GetRoot: TCssMenuPopupForm;
    procedure CloseSubPopup;
    procedure CloseChain;
    procedure OpenSubPopup(AItem: TCssMenuItem; Index: Integer);
    procedure ExecuteItem(AItem: TCssMenuItem);

    // Drawing helpers
    procedure DrawCheckMark(R: TRect; AColor: TColor);
    procedure DrawSubArrow(R: TRect; AColor: TColor);

    // Navigation helpers
    function FindNextSelectable(StartIndex: Integer): Integer;
    function FindPrevSelectable(StartIndex: Integer): Integer;
  protected
    // Painting
    procedure Paint; override;

    // Mouse events
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    // Events
    FOnClosed: TNotifyEvent;
    FOnNavigateLeft: TNotifyEvent;
    FOnNavigateRight: TNotifyEvent;

    constructor CreateMenu(AOwner: TComponent; AMenu: TCssMenuBase; AItems: TList);
    destructor Destroy; override;

    procedure ShowPopup(X, Y: Integer);
    procedure SelectFirstItem;
  end;

  TCssPopupMenu = class(TCssMenuBase)
  private
    // Data
    FPopupForm: TCssMenuPopupForm;
    FPopupControl: TControl;
    FAutoPopup: Boolean;

    // Events
    FOnPopup: TNotifyEvent;
    FOnClose: TNotifyEvent;

    // Property setter and handlers
    procedure SetPopupControl(AValue: TControl);
    procedure PopupFormClosed(Sender: TObject);
    procedure PopupControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  protected
    // Painting
    procedure Paint; override;

    // Initialization
    procedure CreateWnd; override;
    procedure CreateParams(var Params: TCreateParams); override;

    // Component notification
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Popup control
    procedure Popup(X, Y: Integer);
    procedure PopupAtMouse;
    procedure PopupAtControl(AControl: TControl);
    procedure CloseMenu;

    function IsMenuOpen: Boolean;
  published
    property PopupControl: TControl read FPopupControl write SetPopupControl;
    property AutoPopup: Boolean read FAutoPopup write FAutoPopup default False;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

  TCssMainMenu = class(TCssMenuBase)
  private
    // State
    FHoverIndex: Integer;
    FOpenIndex: Integer;
    FDropdown: TCssMenuPopupForm;

    // Appearance
    FMenuBarBackground: TColor;
    FMenuBarBackgroundSet: Boolean;

    // Geometry
    function GetTopItemRect(Index: Integer): TRect;
    function TopItemAtPos(X, Y: Integer): Integer;

    // Dropdown management
    procedure CloseDropdown;
    procedure OpenDropdown(Index: Integer);

    // Appearance getter
    function GetMenuBarBackground: TColor;

    // Navigation helpers
    function FindNextTopItem(StartIndex: Integer): Integer;
    function FindPrevTopItem(StartIndex: Integer): Integer;
    procedure DropdownNavigateLeft(Sender: TObject);
    procedure DropdownNavigateRight(Sender: TObject);
  protected
    // Painting
    procedure Paint; override;

    // Mouse events
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Initialization and style
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure ResetStyle; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Activate;
    function HandleKeyDown(var Key: Word; Shift: TShiftState): Boolean;
  end;

implementation

{ TCssMenuItem }

constructor TCssMenuItem.Create;
begin
  inherited Create;

  FItems := TList.Create;
  FEnabled := True;
  FVisible := True;
end;

destructor TCssMenuItem.Destroy;
begin
  Clear;
  FItems.Free;

  inherited Destroy;
end;

function TCssMenuItem.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TCssMenuItem.GetItem(Index: Integer): TCssMenuItem;
begin
  Result := TCssMenuItem(FItems[Index]);
end;

function TCssMenuItem.Add: TCssMenuItem;
begin
  Result := TCssMenuItem.Create;
  Result.FParent := Self;
  FItems.Add(Result);
end;

procedure TCssMenuItem.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < FItems.Count) then
  begin
    TCssMenuItem(FItems[Index]).Free;
    FItems.Delete(Index);
  end;
end;

procedure TCssMenuItem.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TCssMenuItem(FItems[I]).Free;

  FItems.Clear;
end;

function TCssMenuItem.HasChildren: Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to FItems.Count - 1 do
  begin
    if TCssMenuItem(FItems[I]).Visible then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{ TCssMenuBase }

constructor TCssMenuBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FItems := TList.Create;
end;

destructor TCssMenuBase.Destroy;
begin
  ClearItems;
  FItems.Free;

  inherited Destroy;
end;

function TCssMenuBase.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TCssMenuBase.GetItem(Index: Integer): TCssMenuItem;
begin
  Result := TCssMenuItem(FItems[Index]);
end;

function TCssMenuBase.AddItem: TCssMenuItem;
begin
  Result := TCssMenuItem.Create;
  FItems.Add(Result);
end;

procedure TCssMenuBase.ClearItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TCssMenuItem(FItems[I]).Free;

  FItems.Clear;
end;

procedure TCssMenuBase.BeginMenuHtmlDraw;
begin
  FSavedVAlign := GetCssVAlign;
  FSavedTextAlign := GetCssTextAlign;

  SetVAlign(cvaMiddle);
  SetTextAlign(ctaLeft);
end;

procedure TCssMenuBase.EndMenuHtmlDraw;
begin
  SetVAlign(FSavedVAlign);
  SetTextAlign(FSavedTextAlign);
end;

function TCssMenuBase.GetMenuBackground: TColor;
begin
  if FMenuBackgroundSet then
    Result := FMenuBackground
  else
    Result := GetCssBackgroundColor;
end;

function TCssMenuBase.GetMenuBorderColor: TColor;
begin
  if FMenuBorderColorSet then
    Result := FMenuBorderColor
  else
    Result := GetCssBorderColor;
end;

function TCssMenuBase.GetMenuItemHeight: Integer;
begin
  if FMenuItemHeightSet then
    Result := FMenuItemHeight
  else
    Result := 24;
end;

function TCssMenuBase.GetMenuTextColor: TColor;
begin
  if FMenuTextColorSet then
    Result := FMenuTextColor
  else
    Result := GetCssTextColor;
end;

function TCssMenuBase.GetMenuHoverBackground: TColor;
begin
  if FMenuHoverBackgroundSet then
    Result := FMenuHoverBackground
  else
    Result := RGBToColor(13, 110, 253);
end;

function TCssMenuBase.GetMenuHoverTextColor: TColor;
begin
  if FMenuHoverTextColorSet then
    Result := FMenuHoverTextColor
  else
    Result := clWhite;
end;

function TCssMenuBase.GetMenuDisabledText: TColor;
begin
  if FMenuDisabledTextSet then
    Result := FMenuDisabledText
  else
    Result := RGBToColor(150, 150, 150);
end;

function TCssMenuBase.GetMenuSeparatorColor: TColor;
begin
  if FMenuSeparatorColorSet then
    Result := FMenuSeparatorColor
  else
    Result := RGBToColor(200, 200, 200);
end;

function TCssMenuBase.GetMenuShortcutColor: TColor;
begin
  if FMenuShortcutColorSet then
    Result := FMenuShortcutColor
  else
    Result := RGBToColor(130, 130, 130);
end;

procedure TCssMenuBase.ResetStyle;
begin
  FMenuBackgroundSet := False;
  FMenuBorderColorSet := False;
  FMenuItemHeightSet := False;
  FMenuTextColorSet := False;
  FMenuHoverBackgroundSet := False;
  FMenuHoverTextColorSet := False;
  FMenuDisabledTextSet := False;
  FMenuSeparatorColorSet := False;
  FMenuShortcutColorSet := False;

  inherited ResetStyle;
end;

procedure TCssMenuBase.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'menu-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuBackground := C;
      FMenuBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuBorderColor := C;
      FMenuBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-item-height' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FMenuItemHeight := Px;
      FMenuItemHeightSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuTextColor := C;
      FMenuTextColorSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuHoverBackground := C;
      FMenuHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-hover-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuHoverTextColor := C;
      FMenuHoverTextColorSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-disabled-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuDisabledText := C;
      FMenuDisabledTextSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-separator-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuSeparatorColor := C;
      FMenuSeparatorColorSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-shortcut-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuShortcutColor := C;
      FMenuShortcutColorSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

{ TCssMenuPopupForm }

constructor TCssMenuPopupForm.CreateMenu(AOwner: TComponent;
  AMenu: TCssMenuBase; AItems: TList);
begin
  inherited CreateNew(AOwner);

  FMenu := AMenu;
  FItems := AItems;
  FVisibleItems := TList.Create;
  FHoverIndex := -1;

  BorderStyle := bsNone;
  ShowInTaskBar := stNever;
  FormStyle := fsStayOnTop;
  Color := FMenu.GetMenuBackground;
  OnDeactivate := @FormDeactivate;
end;

destructor TCssMenuPopupForm.Destroy;
begin
  CloseSubPopup;
  FVisibleItems.Free;

  inherited Destroy;
end;

function TCssMenuPopupForm.IsMouseOverSelf: Boolean;
var
  MP: TPoint;
begin
  MP := Mouse.CursorPos;

  Result := (MP.X >= Left) and (MP.X <= Left + Width) and
            (MP.Y >= Top)  and (MP.Y <= Top + Height);
end;

function TCssMenuPopupForm.IsMouseOverTree: Boolean;
begin
  Result := IsMouseOverSelf;

  if (not Result) and Assigned(FSubPopup) then
    Result := FSubPopup.IsMouseOverTree;
end;

procedure TCssMenuPopupForm.FormDeactivate(Sender: TObject);
begin
  // If the mouse is over any window in this menu chain — do not close.
  if GetRoot.IsMouseOverTree then
    Exit;

  CloseChain;
end;

procedure TCssMenuPopupForm.BuildVisibleItems;
var
  I: Integer;
begin
  FVisibleItems.Clear;

  for I := 0 to FItems.Count - 1 do
  begin
    if TCssMenuItem(FItems[I]).Visible then
      FVisibleItems.Add(FItems[I]);
  end;
end;

procedure TCssMenuPopupForm.CalcSize;
var
  I, W, CapW, TotalH, IH: Integer;
  Item: TCssMenuItem;
  S: TSize;
begin
  IH := FMenu.GetMenuItemHeight;

  Canvas.Font := Font;

  W := 0;

  for I := 0 to FVisibleItems.Count - 1 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if FMenu.HtmlMode then
    begin
      S := FMenu.MeasureHtmlTextSize(Item.Caption, 0);
      CapW := S.cx + 60;
    end
    else
      CapW := Canvas.TextWidth(Item.Caption) + 60;

    if Item.Shortcut <> '' then
      CapW := CapW + Canvas.TextWidth(Item.Shortcut) + 20;

    if CapW > W then
      W := CapW;
  end;

  if W < 120 then
    W := 120;

  TotalH := FVisibleItems.Count * IH + 4;

  ClientWidth := W;
  ClientHeight := TotalH;
end;

procedure TCssMenuPopupForm.ShowPopup(X, Y: Integer);
var
  Mon: TMonitor;
  MR: TRect;
begin
  BuildVisibleItems;
  CalcSize;

  Left := X;
  Top := Y;

  // Determine the monitor on which the invocation point is located.
  Mon := Screen.MonitorFromPoint(Point(X, Y), mdNearest);

  if not Assigned(Mon) then
    Mon := Screen.PrimaryMonitor;

  if Assigned(Mon) then
    MR := Mon.WorkareaRect
  else
    MR := Rect(0, 0, Screen.Width, Screen.Height);

  // Do not let the menu go beyond the monitor's work area.
  if Left + Width > MR.Right then
    Left := MR.Right - Width;

  if Top + Height > MR.Bottom then
    Top := MR.Bottom - Height;

  if Left < MR.Left then
    Left := MR.Left;

  if Top < MR.Top then
    Top := MR.Top;

  Show;
end;

function TCssMenuPopupForm.ItemRect(Index: Integer): TRect;
var
  IH: Integer;
begin
  IH := FMenu.GetMenuItemHeight;
  Result := Rect(2, 2 + Index * IH, ClientWidth - 2, 2 + (Index + 1) * IH);
end;

function TCssMenuPopupForm.ItemAtPos(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to FVisibleItems.Count - 1 do
  begin
    if PtInRect(ItemRect(I), Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssMenuPopupForm.GetRoot: TCssMenuPopupForm;
begin
  Result := Self;

  while Assigned(Result.FParentPopup) do
    Result := Result.FParentPopup;
end;

procedure TCssMenuPopupForm.CloseSubPopup;
begin
  if Assigned(FSubPopup) then
  begin
    FSubPopup.CloseSubPopup;
    FSubPopup.Hide;
    FSubPopup.Free;
    FSubPopup := nil;
  end;
end;

procedure TCssMenuPopupForm.CloseChain;
var
  Root: TCssMenuPopupForm;
begin
  Root := GetRoot;
  Root.CloseSubPopup;
  Root.Hide;

  if Assigned(Root.FOnClosed) then
    Root.FOnClosed(Root);
end;

procedure TCssMenuPopupForm.OpenSubPopup(AItem: TCssMenuItem; Index: Integer);
var
  R: TRect;
  P: TPoint;
begin
  if Assigned(FSubPopup) then
  begin
    if FSubPopup.FParentMenuItem = AItem then
      Exit;

    CloseSubPopup;
  end;

  FSubPopup := TCssMenuPopupForm.CreateMenu(Self, FMenu, AItem.FItems);
  FSubPopup.FParentPopup := Self;
  FSubPopup.FParentMenuItem := AItem;

  R := ItemRect(Index);
  P := ClientToScreen(Point(R.Right - 2, R.Top));

  FSubPopup.ShowPopup(P.X, P.Y);
end;

procedure TCssMenuPopupForm.ExecuteItem(AItem: TCssMenuItem);
begin
  if not AItem.Enabled then
    Exit;

  if AItem.Separator then
    Exit;

  if Assigned(AItem.FOnClick) then
    AItem.FOnClick(AItem);

  CloseChain;
end;

procedure TCssMenuPopupForm.DrawCheckMark(R: TRect; AColor: TColor);
var
  CX, CY: Integer;
begin
  CX := R.Left + 12;
  CY := (R.Top + R.Bottom) div 2;

  Canvas.Pen.Color := AColor;
  Canvas.Pen.Width := 2;
  Canvas.MoveTo(CX - 4, CY);
  Canvas.LineTo(CX - 1, CY + 3);
  Canvas.LineTo(CX + 4, CY - 4);
  Canvas.Pen.Width := 1;
end;

procedure TCssMenuPopupForm.DrawSubArrow(R: TRect; AColor: TColor);
var
  CX, CY: Integer;
begin
  CX := R.Right - 10;
  CY := (R.Top + R.Bottom) div 2;

  Canvas.Brush.Color := AColor;
  Canvas.Pen.Color := AColor;

  Canvas.Polygon([
    Point(CX - 3, CY - 4),
    Point(CX - 3, CY + 4),
    Point(CX + 3, CY)
  ]);
end;

function TCssMenuPopupForm.FindNextSelectable(StartIndex: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

  // Search forward from the current position.
  I := StartIndex + 1;

  while I < FVisibleItems.Count do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if (not Item.Separator) and Item.Visible and Item.Enabled then
    begin
      Result := I;
      Exit;
    end;

    Inc(I);
  end;

  // If not found — search from the beginning.
  I := 0;

  while I < StartIndex do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if (not Item.Separator) and Item.Visible and Item.Enabled then
    begin
      Result := I;
      Exit;
    end;

    Inc(I);
  end;
end;

function TCssMenuPopupForm.FindPrevSelectable(StartIndex: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

  // Search backward from the current position.
  I := StartIndex - 1;

  while I >= 0 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if (not Item.Separator) and Item.Visible and Item.Enabled then
    begin
      Result := I;
      Exit;
    end;

    Dec(I);
  end;

  // If not found — search from the end.
  I := FVisibleItems.Count - 1;

  while I > StartIndex do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if (not Item.Separator) and Item.Visible and Item.Enabled then
    begin
      Result := I;
      Exit;
    end;

    Dec(I);
  end;
end;

procedure TCssMenuPopupForm.SelectFirstItem;
begin
  FHoverIndex := FindNextSelectable(-1);
  Invalidate;
end;

procedure TCssMenuPopupForm.Paint;
var
  I, Y, IH: Integer;
  Item: TCssMenuItem;
  R: TRect;
  FG: TColor;
begin
  IH := FMenu.GetMenuItemHeight;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FMenu.GetMenuBackground;
  Canvas.FillRect(ClientRect);

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FMenu.GetMenuBorderColor;
  Canvas.Rectangle(0, 0, ClientWidth, ClientHeight);

  Canvas.Font := Font;

  for I := 0 to FVisibleItems.Count - 1 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);
    R := ItemRect(I);
    Y := R.Top;

    if Item.Separator then
    begin
      Canvas.Pen.Color := FMenu.GetMenuSeparatorColor;
      Canvas.MoveTo(R.Left + 4, Y + IH div 2);
      Canvas.LineTo(R.Right - 4, Y + IH div 2);
      Continue;
    end;

    if Item.Enabled then
    begin
      if I = FHoverIndex then
      begin
        Canvas.Brush.Style := bsSolid;
        Canvas.Brush.Color := FMenu.GetMenuHoverBackground;
        Canvas.FillRect(R);
        FG := FMenu.GetMenuHoverTextColor;
      end
      else
        FG := FMenu.GetMenuTextColor;
    end
    else
    begin
      // Disabled item: no hover background, gray text.
      FG := FMenu.GetMenuDisabledText;
    end;

    if Item.Checked then
      DrawCheckMark(R, FG);

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    if FMenu.HtmlMode then
    begin
      FMenu.BeginMenuHtmlDraw;
      try
        FMenu.DrawHtmlText(Canvas,
          Rect(R.Left + 26, Y, R.Right - 24, Y + IH),
          Item.Caption,
          FG
        );
      finally
        FMenu.EndMenuHtmlDraw;
      end;
    end
    else
    begin
      Canvas.Font.Color := FG;
      Canvas.TextOut(
        R.Left + 26,
        Y + ((IH - Canvas.TextHeight(Item.Caption)) div 2),
        Item.Caption
      );
    end;

    if Item.Shortcut <> '' then
    begin
      Canvas.Font.Color := FMenu.GetMenuShortcutColor;
      Canvas.TextOut(R.Right - Canvas.TextWidth(Item.Shortcut) - 24,
        Y + ((IH - Canvas.TextHeight(Item.Shortcut)) div 2), Item.Shortcut);
    end;

    if Item.HasChildren then
      DrawSubArrow(R, FG);
  end;
end;

procedure TCssMenuPopupForm.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
  Item: TCssMenuItem;
begin
  inherited MouseMove(Shift, X, Y);

  Idx := ItemAtPos(X, Y);

  // Do not highlight disabled items or separators.
  if Idx >= 0 then
  begin
    Item := TCssMenuItem(FVisibleItems[Idx]);

    if (not Item.Enabled) or Item.Separator then
      Idx := -1;
  end;

  if Idx <> FHoverIndex then
  begin
    FHoverIndex := Idx;
    Invalidate;
  end;

  if Idx >= 0 then
  begin
    Item := TCssMenuItem(FVisibleItems[Idx]);

    if Item.HasChildren and Item.Enabled then
      OpenSubPopup(Item, Idx)
    else
      CloseSubPopup;
  end
  else
    CloseSubPopup;
end;

procedure TCssMenuPopupForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
  Item: TCssMenuItem;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
    Exit;

  Idx := ItemAtPos(X, Y);

  if Idx < 0 then
    Exit;

  Item := TCssMenuItem(FVisibleItems[Idx]);

  if (not Item.Enabled) or Item.Separator then
    Exit;

  if Item.HasChildren and Item.Enabled then
    OpenSubPopup(Item, Idx)
  else
    ExecuteItem(Item);
end;

procedure TCssMenuPopupForm.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewIndex: Integer;
  Item: TCssMenuItem;
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_ESCAPE:
    begin
      CloseChain;
      Key := 0;
    end;

    VK_DOWN:
    begin
      NewIndex := FindNextSelectable(FHoverIndex);

      if NewIndex >= 0 then
      begin
        FHoverIndex := NewIndex;
        Invalidate;
      end;

      Key := 0;
    end;

    VK_UP:
    begin
      NewIndex := FindPrevSelectable(FHoverIndex);

      if NewIndex >= 0 then
      begin
        FHoverIndex := NewIndex;
        Invalidate;
      end;

      Key := 0;
    end;

    VK_HOME:
    begin
      NewIndex := FindNextSelectable(-1);

      if NewIndex >= 0 then
      begin
        FHoverIndex := NewIndex;
        Invalidate;
      end;

      Key := 0;
    end;

    VK_END:
    begin
      NewIndex := FindPrevSelectable(FVisibleItems.Count);

      if NewIndex >= 0 then
      begin
        FHoverIndex := NewIndex;
        Invalidate;
      end;

      Key := 0;
    end;

    VK_RIGHT:
    begin
      if (FHoverIndex >= 0) and (FHoverIndex < FVisibleItems.Count) then
      begin
        Item := TCssMenuItem(FVisibleItems[FHoverIndex]);

        if Item.HasChildren and Item.Enabled then
        begin
          OpenSubPopup(Item, FHoverIndex);

          if Assigned(FSubPopup) then
          begin
            FSubPopup.SetFocus;
            FSubPopup.SelectFirstItem;
          end;
        end
        else if Assigned(FOnNavigateRight) then
          FOnNavigateRight(Self);
      end
      else if Assigned(FOnNavigateRight) then
        FOnNavigateRight(Self);

      Key := 0;
    end;

    VK_LEFT:
    begin
      if Assigned(FParentPopup) then
      begin
        FParentPopup.CloseSubPopup;
        FParentPopup.SetFocus;
        FParentPopup.Invalidate;
      end
      else if Assigned(FOnNavigateLeft) then
        FOnNavigateLeft(Self)
      else
        CloseChain;

      Key := 0;
    end;

    VK_RETURN:
    begin
      if (FHoverIndex >= 0) and (FHoverIndex < FVisibleItems.Count) then
      begin
        Item := TCssMenuItem(FVisibleItems[FHoverIndex]);

        if Item.HasChildren and Item.Enabled then
        begin
          OpenSubPopup(Item, FHoverIndex);

          if Assigned(FSubPopup) then
          begin
            FSubPopup.SetFocus;
            FSubPopup.SelectFirstItem;
          end;
        end
        else
          ExecuteItem(Item);
      end;

      Key := 0;
    end;
  end;
end;

{ TCssMainMenu }

constructor TCssMainMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FHoverIndex := -1;
  FOpenIndex := -1;

  Height := 28;
  Align := alTop;
  TabStop := True;
end;

destructor TCssMainMenu.Destroy;
begin
  CloseDropdown;

  inherited Destroy;
end;

function TCssMainMenu.FindNextTopItem(StartIndex: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

  I := StartIndex + 1;

  while I < FItems.Count do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible and Item.Enabled and (not Item.Separator) then
    begin
      Result := I;
      Exit;
    end;

    Inc(I);
  end;

  I := 0;

  while I < StartIndex do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible and Item.Enabled and (not Item.Separator) then
    begin
      Result := I;
      Exit;
    end;

    Inc(I);
  end;
end;

function TCssMainMenu.FindPrevTopItem(StartIndex: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

  I := StartIndex - 1;

  while I >= 0 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible and Item.Enabled and (not Item.Separator) then
    begin
      Result := I;
      Exit;
    end;

    Dec(I);
  end;

  I := FItems.Count - 1;

  while I > StartIndex do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible and Item.Enabled and (not Item.Separator) then
    begin
      Result := I;
      Exit;
    end;

    Dec(I);
  end;
end;

procedure TCssMainMenu.DropdownNavigateLeft(Sender: TObject);
var
  NewIndex: Integer;
begin
  NewIndex := FindPrevTopItem(FOpenIndex);

  if NewIndex >= 0 then
  begin
    OpenDropdown(NewIndex);

    if Assigned(FDropdown) then
    begin
      FDropdown.SetFocus;
      FDropdown.SelectFirstItem;
    end;

    Invalidate; // additional repaint of the menu bar
  end;
end;

procedure TCssMainMenu.DropdownNavigateRight(Sender: TObject);
var
  NewIndex: Integer;
begin
  NewIndex := FindNextTopItem(FOpenIndex);

  if NewIndex >= 0 then
  begin
    OpenDropdown(NewIndex);

    if Assigned(FDropdown) then
    begin
      FDropdown.SetFocus;
      FDropdown.SelectFirstItem;
    end;

    Invalidate; // additional repaint of the menu bar
  end;
end;

procedure TCssMainMenu.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewIndex: Integer;
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_LEFT:
    begin
      if FOpenIndex >= 0 then
        NewIndex := FindPrevTopItem(FOpenIndex)
      else
        NewIndex := FindPrevTopItem(FHoverIndex);

      if NewIndex >= 0 then
      begin
        if FOpenIndex >= 0 then
          OpenDropdown(NewIndex)
        else
        begin
          FHoverIndex := NewIndex;
          Invalidate;
        end;
      end;

      Key := 0;
    end;

    VK_RIGHT:
    begin
      if FOpenIndex >= 0 then
        NewIndex := FindNextTopItem(FOpenIndex)
      else
        NewIndex := FindNextTopItem(FHoverIndex);

      if NewIndex >= 0 then
      begin
        if FOpenIndex >= 0 then
          OpenDropdown(NewIndex)
        else
        begin
          FHoverIndex := NewIndex;
          Invalidate;
        end;
      end;

      Key := 0;
    end;

    VK_DOWN:
    begin
      if FOpenIndex < 0 then
        Activate
      else if Assigned(FDropdown) then
      begin
        FDropdown.SetFocus;
        FDropdown.SelectFirstItem;
      end;

      Key := 0;
    end;

    VK_UP:
    begin
      if Assigned(FDropdown) then
      begin
        FDropdown.SetFocus;
        FDropdown.FHoverIndex := FDropdown.FindPrevSelectable(0);
        FDropdown.Invalidate;
      end;

      Key := 0;
    end;

    VK_ESCAPE:
    begin
      CloseDropdown;
      Invalidate;
      Key := 0;
    end;

    VK_RETURN:
    begin
      if FOpenIndex < 0 then
        Activate
      else if Assigned(FDropdown) then
      begin
        FDropdown.SetFocus;
        FDropdown.SelectFirstItem;
      end;

      Key := 0;
    end;
  end;
end;

procedure TCssMainMenu.Activate;
var
  FirstIndex: Integer;
begin
  FirstIndex := FindNextTopItem(-1);

  if FirstIndex >= 0 then
  begin
    SetFocus;
    OpenDropdown(FirstIndex);

    if Assigned(FDropdown) then
    begin
      FDropdown.SetFocus;
      FDropdown.SelectFirstItem;
    end;
  end;
end;

function TCssMainMenu.HandleKeyDown(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;

  // Alt or F10 activate the menu.
  if (Key = VK_MENU) or (Key = VK_F10) then
  begin
    Activate;
    Exit;
  end;

  // If the menu is open, handle navigation.
  if (FOpenIndex >= 0) or (FHoverIndex >= 0) then
  begin
    case Key of
      VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_ESCAPE, VK_RETURN:
      begin
        KeyDown(Key, Shift);
        Exit;
      end;
    end;
  end;

  Result := False;
end;

function TCssMainMenu.GetMenuBarBackground: TColor;
begin
  if FMenuBarBackgroundSet then
    Result := FMenuBarBackground
  else
    Result := GetCssBackgroundColor;
end;

function TCssMainMenu.GetTopItemRect(Index: Integer): TRect;
var
  X, I, W: Integer;
  S: TSize;
begin
  Canvas.Font := Font;
  X := 4;

  for I := 0 to Index - 1 do
  begin
    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(TCssMenuItem(FItems[I]).Caption, 0);
      W := S.cx + 20;
    end
    else
      W := Canvas.TextWidth(TCssMenuItem(FItems[I]).Caption) + 20;

    X := X + W;
  end;

  if HtmlMode then
  begin
    S := MeasureHtmlTextSize(TCssMenuItem(FItems[Index]).Caption, 0);
    W := S.cx + 20;
  end
  else
    W := Canvas.TextWidth(TCssMenuItem(FItems[Index]).Caption) + 20;

  Result := Rect(X, 2, X + W, ClientHeight - 2);
end;

function TCssMainMenu.TopItemAtPos(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to FItems.Count - 1 do
  begin
    if not TCssMenuItem(FItems[I]).Visible then
      Continue;

    if PtInRect(GetTopItemRect(I), Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TCssMainMenu.CloseDropdown;
begin
  if Assigned(FDropdown) then
  begin
    FDropdown.Hide;
    FDropdown.Free;
    FDropdown := nil;
  end;

  FOpenIndex := -1;
  FHoverIndex := -1; // reset the highlight

  Invalidate; // repaint the menu bar
end;

procedure TCssMainMenu.OpenDropdown(Index: Integer);
var
  Item: TCssMenuItem;
  R: TRect;
  P: TPoint;
begin
  CloseDropdown;

  Item := TCssMenuItem(FItems[Index]);

  if not Item.HasChildren then
    Exit;

  FOpenIndex := Index;
  FHoverIndex := Index; // synchronize so the old section is not highlighted

  FDropdown := TCssMenuPopupForm.CreateMenu(Self, Self, Item.FItems);
  FDropdown.FParentMenuItem := Item;

  FDropdown.FOnNavigateLeft := @DropdownNavigateLeft;
  FDropdown.FOnNavigateRight := @DropdownNavigateRight;

  R := GetTopItemRect(Index);
  P := ClientToScreen(Point(R.Left, R.Bottom));

  FDropdown.ShowPopup(P.X, P.Y);

  Invalidate; // repaint the menu bar
end;

procedure TCssMainMenu.Paint;
var
  I, TextTop: Integer;
  Item: TCssMenuItem;
  R: TRect;
  S: TSize;
  FG: TColor;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := GetMenuBarBackground;
  Canvas.FillRect(ClientRect);

  Canvas.Font := Font;

  for I := 0 to FItems.Count - 1 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if not Item.Visible then
      Continue;

    R := GetTopItemRect(I);

    if (I = FHoverIndex) or (I = FOpenIndex) then
    begin
      Canvas.Brush.Color := GetMenuHoverBackground;
      Canvas.Brush.Style := bsSolid;
      Canvas.FillRect(R);
      FG := GetMenuHoverTextColor;
    end
    else
      FG := GetMenuTextColor;

    if not Item.Enabled then
      FG := GetMenuDisabledText;

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(Item.Caption, R.Right - R.Left - 20);

      TextTop := R.Top + ((R.Bottom - R.Top - S.cy) div 2);

      if TextTop < R.Top then
        TextTop := R.Top;

      DrawHtmlText(Canvas,
        Rect(R.Left + 10, TextTop, R.Right - 10, TextTop + S.cy),
        Item.Caption,
        FG
      );
    end
    else
    begin
      Canvas.Font.Color := FG;
      Canvas.TextOut(
        R.Left + 10,
        R.Top + ((R.Bottom - R.Top - Canvas.TextHeight(Item.Caption)) div 2),
        Item.Caption
      );
    end;
  end;
end;

procedure TCssMainMenu.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  Idx := TopItemAtPos(X, Y);

  if Idx <> FHoverIndex then
  begin
    FHoverIndex := Idx;
    Invalidate;
  end;

  // If the menu is already open and the mouse moved to another item — switch.
  if (FOpenIndex >= 0) and (Idx >= 0) and (Idx <> FOpenIndex) then
    OpenDropdown(Idx);
end;

procedure TCssMainMenu.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
    Exit;

  Idx := TopItemAtPos(X, Y);

  if Idx < 0 then
  begin
    CloseDropdown;
    Invalidate;
    Exit;
  end;

  if not TCssMenuItem(FItems[Idx]).Enabled then
    Exit;

  if FOpenIndex = Idx then
  begin
    CloseDropdown;
    Invalidate;
  end
  else
    OpenDropdown(Idx);
end;

procedure TCssMainMenu.MouseLeave;
begin
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;

  inherited MouseLeave;
end;

procedure TCssMainMenu.ResetStyle;
begin
  FMenuBarBackgroundSet := False;

  inherited ResetStyle;
end;

procedure TCssMainMenu.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
begin
  if AName = 'menubar-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FMenuBarBackground := C;
      FMenuBarBackgroundSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

{ TCssPopupMenu }

constructor TCssPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPopupForm := nil;
  FPopupControl := nil;
  FAutoPopup := False;

  // So that the control is not drawn as a normal visual element.
  Width := 100;
  Height := 24;
end;

destructor TCssPopupMenu.Destroy;
begin
  SetPopupControl(nil);
  CloseMenu;

  inherited Destroy;
end;

procedure TCssPopupMenu.Paint;
begin
  // At runtime we draw nothing.
  // At design time we show a placeholder.
  if csDesigning in ComponentState then
  begin
    Canvas.Pen.Style := psDash;
    Canvas.Pen.Color := clGray;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width, Height);
    Canvas.Font.Color := clGray;
    Canvas.TextOut(4, 4, 'PopupMenu');
  end;
end;

procedure TCssPopupMenu.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FPopupControl) then
    FPopupControl := nil;
end;

procedure TCssPopupMenu.CreateWnd;
begin
  // Do not create a window if there is no parent.
  if not Assigned(Parent) then
    Exit;

  inherited CreateWnd;
end;

procedure TCssPopupMenu.CreateParams(var Params: TCreateParams);
begin
  if not Assigned(Parent) then
    Exit;

  inherited CreateParams(Params);
end;

procedure TCssPopupMenu.SetPopupControl(AValue: TControl);
begin
  if FPopupControl = AValue then
    Exit;

  FPopupControl := AValue;

  if Assigned(FPopupControl) then
  begin
    FPopupControl.FreeNotification(Self);

    if FPopupControl is TWinControl then
      TWinControl(FPopupControl).OnMouseDown := @PopupControlMouseDown;
  end;
end;

procedure TCssPopupMenu.PopupControlMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if not FAutoPopup then
    Exit;

  if Button <> mbRight then
    Exit;

  if not Assigned(FPopupControl) then
    Exit;

  P := FPopupControl.ClientToScreen(Point(X, Y));
  Popup(P.X, P.Y);
end;

procedure TCssPopupMenu.Popup(X, Y: Integer);
begin
  if Count = 0 then
    Exit;

  CloseMenu;

  if Assigned(FOnPopup) then
    FOnPopup(Self);

  FPopupForm := TCssMenuPopupForm.CreateMenu(Self, Self, ItemsList);
  FPopupForm.FOnClosed := @PopupFormClosed;
  FPopupForm.ShowPopup(X, Y);
end;

procedure TCssPopupMenu.PopupAtMouse;
var
  P: TPoint;
begin
  P := Mouse.CursorPos;
  Popup(P.X, P.Y);
end;

procedure TCssPopupMenu.PopupAtControl(AControl: TControl);
var
  P: TPoint;
begin
  if not Assigned(AControl) then
    Exit;

  P := AControl.ClientToScreen(Point(0, AControl.Height));
  Popup(P.X, P.Y);
end;

procedure TCssPopupMenu.CloseMenu;
begin
  if Assigned(FPopupForm) then
  begin
    FPopupForm.FOnClosed := nil;
    FPopupForm.Hide;
    FPopupForm.Free;
    FPopupForm := nil;

    if Assigned(FOnClose) then
      FOnClose(Self);
  end;
end;

procedure TCssPopupMenu.PopupFormClosed(Sender: TObject);
begin
  if Sender = FPopupForm then
  begin
    FPopupForm.Release;
    FPopupForm := nil;

    if Assigned(FOnClose) then
      FOnClose(Self);
  end;
end;

function TCssPopupMenu.IsMenuOpen: Boolean;
begin
  Result := Assigned(FPopupForm) and FPopupForm.Visible;
end;

end.
