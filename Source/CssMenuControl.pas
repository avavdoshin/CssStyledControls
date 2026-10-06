unit CssMenuControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  Forms, CssStyledControl, CssSvgImgList;

type
  TCssMenuBase = class;

  { Horizontal position of the item icon relative to the caption. }
  TCssMenuIconLayout = (milLeft, milRight);

  { Single menu item. It is a TComponent, so it participates
    in the standard LCL streaming and appears in the IDE
    Structure panel as a child of the owning menu or of the
    parent item. Owner follows the logical parent:
      - top-level item  -> Owner = TCssMenuBase
      - sub-item        -> Owner = parent TCssMenuItem
    This mirrors how TMenuItem / TMainMenu work. }

  TCssMenuItem = class(TComponent)
  private
    FItems: TList;            // child items, mirrors Owner chain
    FParent: TCssMenuItem;    // logical parent, nil for top-level items
    FMenu: TCssMenuBase;

    FCaption: string;
    FShortcut: string;
    FChecked: Boolean;
    FEnabled: Boolean;
    FVisible: Boolean;
    FSeparator: Boolean;

    FSvgImages: TCssSvgImgList;
    FImageIndex: Integer;

    FOnClick: TNotifyEvent;
    FOnChanged: TNotifyEvent;
    FDesignerData: Pointer;   // IDE-only: back-reference to TTreeNode

    function GetCount: Integer;
    function GetItem(Index: Integer): TCssMenuItem;
    function GetMenu: TCssMenuBase;

    procedure DetachLogical;
    function GetCreationOwner: TComponent;

    procedure SetCaption(const AValue: string);
    procedure SetShortcut(const AValue: string);
    procedure SetChecked(AValue: Boolean);
    procedure SetEnabled(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
    procedure SetSeparator(AValue: Boolean);

    procedure SetSvgImages(AValue: TCssSvgImgList);
    procedure SetImageIndex(AValue: Integer);

    procedure DoChanged;
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetParentComponent: TComponent; override;

    // Structure
    function Add: TCssMenuItem;
    function Insert(Index: Integer): TCssMenuItem;
    function IndexOf(AItem: TCssMenuItem): Integer;
    procedure Delete(Index: Integer);
    procedure Clear;
    function HasChildren: Boolean;
    function IsAncestorOf(AItem: TCssMenuItem): Boolean;
    function HasParent: Boolean; override;
    procedure SetParentComponent(Value: TComponent); override;

    // Reparenting
    procedure Detach;
    procedure AttachTo(ANewParent: TCssMenuItem; AIndex: Integer);

    { Item-level SvgImages if set, otherwise the owning menu's. }
    function GetEffectiveSvgImages: TCssSvgImgList;

    { SVG variant name derived from the owning menu's CSS theme. }
    function GetEffectiveSvgVariant: string;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TCssMenuItem read GetItem; default;
    property Parent: TCssMenuItem read FParent;
    property Menu: TCssMenuBase read GetMenu;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property DesignerData: Pointer read FDesignerData write FDesignerData;
  published
    property Caption: string read FCaption write SetCaption;
    property Shortcut: string read FShortcut write SetShortcut;
    property Checked: Boolean read FChecked write SetChecked default False;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Separator: Boolean read FSeparator write SetSeparator default False;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;

    { Optional per-item override; when unset the item uses the menu's
      SvgImages. }
    property SvgImages: TCssSvgImgList
      read FSvgImages write SetSvgImages;

    { Index inside the effective SvgImages. -1 disables the icon. }
    property ImageIndex: Integer
      read FImageIndex write SetImageIndex default -1;
  end;

  { Friend class that exposes protected TComponent methods
    for ownership changes during reparenting. }
  TMenuComponentFriend = class(TComponent)
  public
    procedure AddOwnedComponent(AComponent: TComponent);
    procedure RemoveOwnedComponent(AComponent: TComponent);
  end;

  TCssMenuBase = class(TCssStyledControl)
  private
    FItems: TList;            // top-level items only

    FSvgImages: TCssSvgImgList;

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
    FMenuSeparatorHeight: Integer;FMenuSeparatorHeightSet: Boolean;
    FMenuSeparatorWidth: Integer; FMenuSeparatorWidthSet: Boolean;

    // Icon size (auto by default; overridable via `menu-icon-size`)
    FMenuIconSize: Integer;
    FMenuIconSizeSet: Boolean;

    // Icon position relative to caption (left by default)
    FMenuIconLayout: TCssMenuIconLayout;
    FMenuIconLayoutSet: Boolean;

    // Saved text alignment for HTML drawing
    FSavedVAlign: TCssVAlign;
    FSavedTextAlign: TCssTextAlign;

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
    function GetMenuSeparatorHeight: Integer;
    function GetMenuSeparatorWidth: Integer;
    function GetMenuIconSize(ACanvas: TCanvas): Integer;
    function GetMenuIconLayout: TCssMenuIconLayout;

    procedure SetSvgImages(AValue: TCssSvgImgList);
  protected
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure ResetStyle; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;

    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;

    property ItemsList: TList read FItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetParentComponent: TComponent; override;
    function DesignOwner: TComponent;

    function AddItem: TCssMenuItem;
    function InsertItem(Index: Integer): TCssMenuItem;
    function IndexOfItem(AItem: TCssMenuItem): Integer;
    procedure DetachItem(AItem: TCssMenuItem);
    procedure AttachItem(AItem: TCssMenuItem; AIndex: Integer);
    procedure ClearItems;

    procedure BeginMenuHtmlDraw;
    procedure EndMenuHtmlDraw;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TCssMenuItem read GetItem; default;
  published
    { Default SVG source for all items of this menu. Items with their own
      SvgImages override this value. }
    property SvgImages: TCssSvgImgList
      read FSvgImages write SetSvgImages;
  end;

  TCssMenuPopupForm = class(TForm)
  private
    FMenu: TCssMenuBase;
    FItems: TList;
    FVisibleItems: TList;
    FHoverIndex: Integer;

    FParentPopup: TCssMenuPopupForm;
    FSubPopup: TCssMenuPopupForm;
    FParentMenuItem: TCssMenuItem;

    FCheckColumnWidth: Integer;    // left column reserved for check marks
    FIconColumnWidth: Integer;     // left column reserved for icons
    FRightIconColumnWidth: Integer;// right column reserved for icons
    FIconSize: Integer;            // device-pixel icon size
    FTextOffset: Integer;          // text offset from R.Left
    FIconLayout: TCssMenuIconLayout;

    procedure FormDeactivate(Sender: TObject);
    function IsMouseOverSelf: Boolean;
    function IsMouseOverTree: Boolean;
    procedure BuildVisibleItems;
    procedure CalcSize;
    function ItemRect(Index: Integer): TRect;
    function ItemAtPos(X, Y: Integer): Integer;
    function GetRoot: TCssMenuPopupForm;
    procedure CloseSubPopup;
    procedure CloseChain;
    procedure OpenSubPopup(AItem: TCssMenuItem; Index: Integer);
    procedure ExecuteItem(AItem: TCssMenuItem);
    procedure DrawCheckMark(R: TRect; AColor: TColor);
    procedure DrawSubArrow(R: TRect; AColor: TColor);
    function FindNextSelectable(StartIndex: Integer): Integer;
    function FindPrevSelectable(StartIndex: Integer): Integer;
    function ScalePx(APx: Integer): Integer;
    procedure ApplyMenuFont(ACanvas: TCanvas);
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
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
    FPopupForm: TCssMenuPopupForm;
    FPopupControl: TControl;
    FAutoPopup: Boolean;
    FOnPopup: TNotifyEvent;
    FOnClose: TNotifyEvent;

    procedure SetPopupControl(AValue: TControl);
    procedure PopupFormClosed(Sender: TObject);
    procedure PopupControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  protected
    procedure Paint; override;
    procedure CreateWnd; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

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
    FHoverIndex: Integer;
    FOpenIndex: Integer;
    FDropdown: TCssMenuPopupForm;

    FMenuBarBackground: TColor;
    FMenuBarBackgroundSet: Boolean;

    function GetTopItemRect(Index: Integer): TRect;
    function TopItemAtPos(X, Y: Integer): Integer;
    function GetTopItemWidth(AItem: TCssMenuItem): Integer;

    procedure CloseDropdown;
    procedure OpenDropdown(Index: Integer);
    procedure SelectTopItem(AIndex: Integer);
    procedure ExecuteTopItem(AItem: TCssMenuItem);

    function GetMenuBarBackground: TColor;

    function FindNextTopItem(StartIndex: Integer): Integer;
    function FindPrevTopItem(StartIndex: Integer): Integer;
    procedure DropdownNavigateLeft(Sender: TObject);
    procedure DropdownNavigateRight(Sender: TObject);
    procedure DropdownClosed(Sender: TObject);
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure ResetStyle; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Activate;
    function HandleKeyDown(var Key: Word; Shift: TShiftState): Boolean;
  end;

implementation

{ TMenuComponentFriend }

procedure TMenuComponentFriend.AddOwnedComponent(AComponent: TComponent);
begin
  InsertComponent(AComponent);
end;

procedure TMenuComponentFriend.RemoveOwnedComponent(AComponent: TComponent);
begin
  RemoveComponent(AComponent);
end;

{ TCssMenuItem }

constructor TCssMenuItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Include(FComponentStyle, csSubComponent);

  FItems := TList.Create;
  FEnabled := True;
  FVisible := True;
  FImageIndex := -1;

  if AOwner is TCssMenuItem then
  begin
    FParent := TCssMenuItem(AOwner);
    FParent.FItems.Add(Self);
  end
  else if AOwner is TCssMenuBase then
  begin
    FMenu := TCssMenuBase(AOwner);
    TCssMenuBase(AOwner).FItems.Add(Self);
  end;
end;

destructor TCssMenuItem.Destroy;
var
  Item: TCssMenuItem;
begin
  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);
  DetachLogical;

  while FItems.Count > 0 do
  begin
    Item := TCssMenuItem(FItems[FItems.Count - 1]);
    FItems.Remove(Item);
    Item.FParent := nil;
    Item.Free;
  end;

  FreeAndNil(FItems);

  inherited Destroy;
end;

procedure TCssMenuItem.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    Proc(TCssMenuItem(FItems[I]));
end;

procedure TCssMenuItem.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSvgImages) then
  begin
    FSvgImages := nil;
    DoChanged;
  end;
end;

function TCssMenuItem.GetParentComponent: TComponent;
begin
  if FParent <> nil then
    Result := FParent
  else if FMenu <> nil then
    Result := FMenu
  else
    Result := Owner;
end;

function TCssMenuItem.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TCssMenuItem.GetItem(Index: Integer): TCssMenuItem;
begin
  Result := TCssMenuItem(FItems[Index]);
end;

function TCssMenuItem.GetMenu: TCssMenuBase;
var
  P: TCssMenuItem;
begin
  P := Self;

  while P.FParent <> nil do
    P := P.FParent;

  Result := P.FMenu;

  if (Result = nil) and (P.Owner is TCssMenuBase) then
    Result := TCssMenuBase(P.Owner);
end;

procedure TCssMenuItem.DetachLogical;
begin
  if FParent <> nil then
  begin
    FParent.FItems.Remove(Self);
    FParent := nil;
  end
  else if FMenu <> nil then
  begin
    FMenu.FItems.Remove(Self);
    FMenu := nil;
  end;
end;

function TCssMenuItem.GetCreationOwner: TComponent;
var
  M: TCssMenuBase;
begin
  M := Menu;

  if M <> nil then
    Result := M.DesignOwner
  else
  begin
    Result := Owner;
    if Result = nil then
      Result := Self;
  end;
end;

function TCssMenuItem.Add: TCssMenuItem;
begin
  Result := Insert(Count);
end;

function TCssMenuItem.Insert(Index: Integer): TCssMenuItem;
begin
  Result := TCssMenuItem.Create(GetCreationOwner);
  Result.AttachTo(Self, Index);
end;

function TCssMenuItem.IndexOf(AItem: TCssMenuItem): Integer;
begin
  Result := FItems.IndexOf(AItem);
end;

procedure TCssMenuItem.Delete(Index: Integer);
var
  Item: TCssMenuItem;
begin
  if (Index < 0) or (Index >= FItems.Count) then
    Exit;

  Item := TCssMenuItem(FItems[Index]);
  FItems.Delete(Index);
  Item.FParent := nil;
  Item.Free;
end;

procedure TCssMenuItem.Clear;
begin
  while FItems.Count > 0 do
    Delete(0);
end;

function TCssMenuItem.HasChildren: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FItems.Count - 1 do
    if TCssMenuItem(FItems[I]).Visible then
      Exit(True);
end;

function TCssMenuItem.IsAncestorOf(AItem: TCssMenuItem): Boolean;
var
  P: TCssMenuItem;
begin
  Result := False;
  if AItem = nil then
    Exit;

  P := AItem.FParent;
  while P <> nil do
  begin
    if P = Self then
      Exit(True);
    P := P.FParent;
  end;
end;

function TCssMenuItem.HasParent: Boolean;
begin
  Result :=
    (FParent <> nil) or
    (FMenu <> nil) or
    (Owner is TCssMenuBase) or
    (Owner is TCssMenuItem);
end;

procedure TCssMenuItem.SetParentComponent(Value: TComponent);
begin
  if Value = nil then
    Exit;

  if Value is TCssMenuItem then
  begin
    if (Value <> Self) and not IsAncestorOf(TCssMenuItem(Value)) then
      AttachTo(TCssMenuItem(Value), MaxInt);
  end
  else if Value is TCssMenuBase then
  begin
    TCssMenuBase(Value).AttachItem(Self, MaxInt);
  end;
end;

procedure TCssMenuItem.Detach;
begin
  DetachLogical;
end;

procedure TCssMenuItem.AttachTo(ANewParent: TCssMenuItem; AIndex: Integer);
begin
  if ANewParent = nil then
    Exit;

  if ANewParent = Self then
    Exit;

  if IsAncestorOf(ANewParent) then
    Exit;

  DetachLogical;

  FParent := ANewParent;
  FMenu := nil;

  if AIndex < 0 then
    AIndex := 0;

  if AIndex > ANewParent.FItems.Count then
    AIndex := ANewParent.FItems.Count;

  if ANewParent.FItems.IndexOf(Self) < 0 then
    ANewParent.FItems.Insert(AIndex, Self);
end;

function TCssMenuItem.GetEffectiveSvgImages: TCssSvgImgList;
var
  M: TCssMenuBase;
begin
  if FSvgImages <> nil then
    Exit(FSvgImages);

  M := Menu;
  if (M <> nil) and (M.SvgImages <> nil) then
    Exit(M.SvgImages);

  Result := nil;
end;

function TCssMenuItem.GetEffectiveSvgVariant: string;
var
  M: TCssMenuBase;
  Img: TCssSvgImgList;
begin
  M := Menu;

  if M = nil then
  begin
    Img := GetEffectiveSvgImages;
    if Img <> nil then
      Exit(Img.DefaultVariant);
    Exit('');
  end;

  if M.StyleProvider <> nil then
  begin
    if Trim(M.StyleName) <> '' then
      Exit(M.StyleName);
    Exit(M.StyleProvider.DefaultStyleName);
  end;

  Img := GetEffectiveSvgImages;
  if Img <> nil then
    Exit(Img.DefaultVariant);

  Result := '';
end;

procedure TCssMenuItem.SetCaption(const AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetShortcut(const AValue: string);
begin
  if FShortcut = AValue then Exit;
  FShortcut := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then Exit;
  FChecked := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetEnabled(AValue: Boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then Exit;
  FVisible := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetSeparator(AValue: Boolean);
begin
  if FSeparator = AValue then Exit;
  FSeparator := AValue;
  DoChanged;
end;

procedure TCssMenuItem.SetSvgImages(AValue: TCssSvgImgList);
begin
  if FSvgImages = AValue then Exit;
  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);
  FSvgImages := AValue;
  if FSvgImages <> nil then
    FSvgImages.FreeNotification(Self);
  DoChanged;
end;

procedure TCssMenuItem.SetImageIndex(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FImageIndex = AValue then Exit;
  FImageIndex := AValue;
  DoChanged;
end;

procedure TCssMenuItem.DoChanged;
var
  M: TCssMenuBase;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);

  M := Menu;
  if M <> nil then
    M.Invalidate;
end;

{ TCssMenuBase }

constructor TCssMenuBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FItems := TList.Create;
end;

destructor TCssMenuBase.Destroy;
var
  Item: TCssMenuItem;
begin
  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  while FItems.Count > 0 do
  begin
    Item := TCssMenuItem(FItems[FItems.Count - 1]);
    FItems.Remove(Item);
    Item.FMenu := nil;
    Item.Free;
  end;

  FItems.Free;

  inherited Destroy;
end;

procedure TCssMenuBase.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FSvgImages) then
  begin
    FSvgImages := nil;
    Invalidate;
  end;
end;

procedure TCssMenuBase.SetSvgImages(AValue: TCssSvgImgList);
begin
  if FSvgImages = AValue then Exit;

  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  FSvgImages := AValue;

  if FSvgImages <> nil then
    FSvgImages.FreeNotification(Self);

  Invalidate;
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
  Result := InsertItem(Count);
end;

procedure TCssMenuBase.ClearItems;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  for I := FItems.Count - 1 downto 0 do
  begin
    Item := TCssMenuItem(FItems[I]);
    DetachItem(Item);
    Item.Free;
  end;
end;

function TCssMenuBase.InsertItem(Index: Integer): TCssMenuItem;
begin
  Result := TCssMenuItem.Create(DesignOwner);
  AttachItem(Result, Index);
end;

function TCssMenuBase.IndexOfItem(AItem: TCssMenuItem): Integer;
begin
  Result := FItems.IndexOf(AItem);
end;

procedure TCssMenuBase.DetachItem(AItem: TCssMenuItem);
begin
  if AItem = nil then
    Exit;

  FItems.Remove(AItem);

  AItem.FParent := nil;
  AItem.FMenu := nil;
end;

procedure TCssMenuBase.AttachItem(AItem: TCssMenuItem; AIndex: Integer);
begin
  if AItem = nil then
    Exit;

  AItem.DetachLogical;

  AItem.FParent := nil;
  AItem.FMenu := Self;

  if AIndex < 0 then
    AIndex := 0;

  if AIndex > FItems.Count then
    AIndex := FItems.Count;

  if FItems.IndexOf(AItem) < 0 then
    FItems.Insert(AIndex, AItem);
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
    Result := ScalePx(24);
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

function TCssMenuBase.GetMenuSeparatorHeight: Integer;
begin
  if FMenuSeparatorHeightSet then
    Result := FMenuSeparatorHeight
  else
  begin
    Result := GetMenuItemHeight div 4;

    if Result < ScalePx(4) then
      Result := ScalePx(4);

    if Result > ScalePx(9) then
      Result := ScalePx(9);
  end;

  if Result < 1 then
    Result := 1;
end;

function TCssMenuBase.GetMenuSeparatorWidth: Integer;
begin
  if FMenuSeparatorWidthSet then
    Result := FMenuSeparatorWidth
  else
    Result := ScalePx(8);

  if Result < 1 then
    Result := 1;
end;

{ Returns the device-pixel size of a menu icon.

  Default: follow the height of a line of text on the given canvas,
  capped by the menu item height. When `menu-icon-size` is set via CSS,
  that value (already in device pixels) is used instead. }
function TCssMenuBase.GetMenuIconSize(ACanvas: TCanvas): Integer;
var
  MaxIcon: Integer;
begin
  if FMenuIconSizeSet then
    Exit(FMenuIconSize);

  MaxIcon := GetMenuItemHeight - ScalePx(6);
  if MaxIcon < ScalePx(8) then
    MaxIcon := ScalePx(8);

  if ACanvas = nil then
    Exit(ScalePx(16));

  Result := ACanvas.TextHeight('Mg');
  if Result > MaxIcon then
    Result := MaxIcon;
  if Result < ScalePx(8) then
    Result := ScalePx(8);
end;

function TCssMenuBase.GetMenuIconLayout: TCssMenuIconLayout;
begin
  if FMenuIconLayoutSet then
    Result := FMenuIconLayout
  else
    Result := milLeft;
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
  FMenuSeparatorHeightSet := False;
  FMenuSeparatorWidthSet := False;
  FMenuIconSizeSet := False;
  FMenuIconLayoutSet := False;

  inherited ResetStyle;
end;

procedure TCssMenuBase.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    Proc(TCssMenuItem(FItems[I]));
end;

function TCssMenuBase.GetParentComponent: TComponent;
begin
  if Parent <> nil then
    Result := Parent
  else
    Result := Owner;
end;

function TCssMenuBase.DesignOwner : TComponent;
begin
  Result := Owner;
  if Result = nil then
    Result := Self;
end;

procedure TCssMenuBase.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
  S: string;
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

  if AName = 'menu-separator-height' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FMenuSeparatorHeight := Px;
      FMenuSeparatorHeightSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-separator-width' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FMenuSeparatorWidth := Px;
      FMenuSeparatorWidthSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-icon-size' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FMenuIconSize := Px;
      FMenuIconSizeSet := True;
    end;
    Exit;
  end;

  if AName = 'menu-icon-layout' then
  begin
    S := LowerCase(Trim(AValue));
    if S = 'left' then
    begin
      FMenuIconLayout := milLeft;
      FMenuIconLayoutSet := True;
    end
    else if S = 'right' then
    begin
      FMenuIconLayout := milRight;
      FMenuIconLayoutSet := True;
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
  FCheckColumnWidth := 0;
  FIconColumnWidth := 0;
  FRightIconColumnWidth := 0;

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
  if GetRoot.IsMouseOverTree then
    Exit;

  CloseChain;
end;

procedure TCssMenuPopupForm.BuildVisibleItems;
var
  I: Integer;
  It: TCssMenuItem;
  Img: TCssSvgImgList;
  AnyChecked, AnyIcon: Boolean;
begin
  FVisibleItems.Clear;
  FCheckColumnWidth := 0;
  FIconColumnWidth := 0;
  FRightIconColumnWidth := 0;
  FTextOffset := 0;

  ApplyMenuFont(Canvas);
  FIconSize := FMenu.GetMenuIconSize(Canvas);
  FIconLayout := FMenu.GetMenuIconLayout;

  AnyChecked := False;
  AnyIcon := False;

  for I := 0 to FItems.Count - 1 do
  begin
    It := TCssMenuItem(FItems[I]);
    if It.Visible then
    begin
      FVisibleItems.Add(It);

      if It.Checked then
        AnyChecked := True;

      Img := It.GetEffectiveSvgImages;
      if (Img <> nil) and
         (It.ImageIndex >= 0) and
         (It.ImageIndex < Img.Count) then
        AnyIcon := True;
    end;
  end;

  { The check-mark column is reserved only when at least one item is
    checked. The icon column is reserved only when at least one item has
    an icon, and it goes on the left or right depending on
    `menu-icon-layout`. }
  if AnyChecked then
    FCheckColumnWidth := ScalePx(20);

  if AnyIcon then
  begin
    if FIconLayout = milLeft then
      FIconColumnWidth := FIconSize + ScalePx(6)
    else
      FRightIconColumnWidth := FIconSize + ScalePx(6);
  end;

  FTextOffset := ScalePx(6) + FCheckColumnWidth + FIconColumnWidth;
end;

procedure TCssMenuPopupForm.CalcSize;
var
  I, W, CapW, TotalH, IH, SepH, TextW, RightMargin: Integer;
  Item: TCssMenuItem;
begin
  IH := FMenu.GetMenuItemHeight;
  SepH := FMenu.GetMenuSeparatorHeight;

  ApplyMenuFont(Canvas);

  W := 0;
  TotalH := ScalePx(4);

  for I := 0 to FVisibleItems.Count - 1 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if Item.Separator then
    begin
      Inc(TotalH, SepH);
      Continue;
    end;

    Inc(TotalH, IH);

    if FMenu.HtmlMode then
      TextW := FMenu.MeasureHtmlTextSize(Item.Caption, 0).cx
    else
      TextW := Canvas.TextWidth(Item.Caption);

    { Right margin must match exactly the one used by Paint. Otherwise
      bold HTML text (whose measured width is on the edge of the
      available box) will wrap to a second line at draw time and get
      clipped vertically. }
    RightMargin := ScalePx(10);
    if FRightIconColumnWidth > 0 then
      RightMargin := RightMargin + FRightIconColumnWidth;
    if Item.Shortcut <> '' then
      RightMargin := RightMargin + ScalePx(12) + Canvas.TextWidth(Item.Shortcut);
    if Item.HasChildren then
      RightMargin := RightMargin + ScalePx(18);

    { A few extra pixels guard against rounding differences between the
      measuring font and the drawing font on some platforms. }
    CapW := FTextOffset + TextW + RightMargin + ScalePx(4);

    if CapW > W then
      W := CapW;
  end;

  if W < ScalePx(120) then
    W := ScalePx(120);

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

  Mon := Screen.MonitorFromPoint(Point(X, Y), mdNearest);

  if not Assigned(Mon) then
    Mon := Screen.PrimaryMonitor;

  if Assigned(Mon) then
    MR := Mon.WorkareaRect
  else
    MR := Rect(0, 0, Screen.Width, Screen.Height);

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
  I, aTop, H: Integer;
  Item: TCssMenuItem;
begin
  if (Index < 0) or (Index >= FVisibleItems.Count) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  aTop := ScalePx(2);

  for I := 0 to Index - 1 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);

    if Item.Separator then
      H := FMenu.GetMenuSeparatorHeight
    else
      H := FMenu.GetMenuItemHeight;

    Inc(aTop, H);
  end;

  Item := TCssMenuItem(FVisibleItems[Index]);

  if Item.Separator then
    H := FMenu.GetMenuSeparatorHeight
  else
    H := FMenu.GetMenuItemHeight;

  Result := Rect(ScalePx(2), aTop, ClientWidth - ScalePx(2), aTop + H);
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
  CheckRect: TRect;
  CheckSize: Integer;
begin
  CheckSize := ScalePx(16);

  CheckRect := Rect(
    R.Left + ScalePx(4),
    (R.Top + R.Bottom - CheckSize) div 2,
    R.Left + ScalePx(4) + CheckSize,
    (R.Top + R.Bottom - CheckSize) div 2 + CheckSize
  );

  FMenu.DrawAntiAliasedCheckMark(Canvas, CheckRect, AColor);
end;

procedure TCssMenuPopupForm.DrawSubArrow(R: TRect; AColor: TColor);
var
  CX, CY: Integer;
  Bg: TColor;
begin
  CX := R.Right - ScalePx(10);
  CY := (R.Top + R.Bottom) div 2;

  Bg := FMenu.GetMenuBackground;

  if (FHoverIndex >= 0) and
     (FHoverIndex < FVisibleItems.Count) and
     (ItemRect(FHoverIndex).Top = R.Top) then
  begin
    Bg := FMenu.GetMenuHoverBackground;
  end;

  FMenu.DrawAntiAliasedTriangle(
    Canvas,
    Point(CX - ScalePx(3), CY - ScalePx(4)),
    Point(CX - ScalePx(3), CY + ScalePx(4)),
    Point(CX + ScalePx(3), CY),
    AColor,
    Bg
  );
end;

function TCssMenuPopupForm.FindNextSelectable(StartIndex: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

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

function TCssMenuPopupForm.ScalePx(APx : Integer) : Integer;
begin
  if Assigned(FMenu) then
    Result := FMenu.ScaleForDpi(APx)
  else
    Result := APx;
end;

procedure TCssMenuPopupForm.ApplyMenuFont(ACanvas: TCanvas);
begin
  if ACanvas = nil then
    Exit;

  if Assigned(FMenu) then
    FMenu.AssignEffectiveCssFontToFont(ACanvas.Font)
  else
    ACanvas.Font := Self.Font;
end;

procedure TCssMenuPopupForm.SelectFirstItem;
begin
  FHoverIndex := FindNextSelectable(-1);
  Invalidate;
end;

procedure TCssMenuPopupForm.Paint;
var
  I: Integer;
  Item: TCssMenuItem;
  R: TRect;
  FG: TColor;
  Img: TCssSvgImgList;
  IconBmp: TBitmap;
  IconX, IconY, IconW, IconH: Integer;
  HasIcon: Boolean;
  RightEdge, ShortcutX, RightIconX, TextRight, TextW: Integer;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FMenu.GetMenuBackground;
  Canvas.FillRect(ClientRect);

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FMenu.GetMenuBorderColor;
  Canvas.Rectangle(0, 0, ClientWidth, ClientHeight);

  ApplyMenuFont(Canvas);

  for I := 0 to FVisibleItems.Count - 1 do
  begin
    Item := TCssMenuItem(FVisibleItems[I]);
    R := ItemRect(I);

    if Item.Separator then
    begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Color := FMenu.GetMenuSeparatorColor;
      Canvas.MoveTo(R.Left + ScalePx(4), R.Top + ((R.Bottom - R.Top) div 2));
      Canvas.LineTo(R.Right - ScalePx(4), R.Top + ((R.Bottom - R.Top) div 2));
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
      FG := FMenu.GetMenuDisabledText;

    { Check-mark column: reserved whether or not this row has a check. }
    if Item.Checked and (FCheckColumnWidth > 0) then
      DrawCheckMark(R, FG);

    Img := Item.GetEffectiveSvgImages;
    HasIcon := (Img <> nil) and
               (Item.ImageIndex >= 0) and
               (Item.ImageIndex < Img.Count);

    { Left icon: sits right after the check column. }
    if HasIcon and (FIconLayout = milLeft) then
    begin
      IconW := FIconSize;
      IconH := FIconSize;
      IconX := R.Left + ScalePx(6) + FCheckColumnWidth;
      IconY := R.Top + (R.Height - IconH) div 2;

      IconBmp := Img.GetBitmap(
        Item.ImageIndex, IconW, IconH, FG, Item.GetEffectiveSvgVariant);
      try
        DrawSvgBitmapWithAlpha(Canvas, IconX, IconY, IconBmp);
      finally
        IconBmp.Free;
      end;
    end;

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    { Right-side layout, resolved from the right edge inwards:
        [pad] [arrow] [shortcut] [right icon] [caption ...] }
    RightEdge := R.Right - ScalePx(10);

    if Item.HasChildren then
      RightEdge := RightEdge - ScalePx(18);

    ShortcutX := 0;
    if Item.Shortcut <> '' then
    begin
      TextW := Canvas.TextWidth(Item.Shortcut);
      RightEdge := RightEdge - TextW;
      ShortcutX := RightEdge;
      RightEdge := RightEdge - ScalePx(12);
    end;

    RightIconX := 0;
    if HasIcon and (FIconLayout = milRight) then
    begin
      RightEdge := RightEdge - FIconSize;
      RightIconX := RightEdge;
      RightEdge := RightEdge - ScalePx(6);
    end;

    TextRight := RightEdge;

    if FMenu.HtmlMode then
    begin
      FMenu.BeginMenuHtmlDraw;
      try
        FMenu.DrawHtmlText(
          Canvas,
          Rect(R.Left + FTextOffset, R.Top, TextRight, R.Bottom),
          Item.Caption,
          FG
        );
      finally
        FMenu.EndMenuHtmlDraw;
      end;
    end
    else
    begin
      Canvas.TextOut(
        R.Left + FTextOffset,
        R.Top + (((R.Bottom - R.Top) - Canvas.TextHeight(Item.Caption)) div 2),
        Item.Caption
      );
    end;

    { Right icon: between the caption and the shortcut. }
    if HasIcon and (FIconLayout = milRight) then
    begin
      IconW := FIconSize;
      IconH := FIconSize;
      IconY := R.Top + (R.Height - IconH) div 2;

      IconBmp := Img.GetBitmap(
        Item.ImageIndex, IconW, IconH, FG, Item.GetEffectiveSvgVariant);
      try
        DrawSvgBitmapWithAlpha(Canvas, RightIconX, IconY, IconBmp);
      finally
        IconBmp.Free;
      end;
    end;

    if Item.Shortcut <> '' then
    begin
      Canvas.Font.Color := FMenu.GetMenuShortcutColor;
      Canvas.TextOut(
        ShortcutX,
        R.Top + (((R.Bottom - R.Top) - Canvas.TextHeight(Item.Shortcut)) div 2),
        Item.Shortcut
      );
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
    SelectTopItem(NewIndex);
end;

procedure TCssMainMenu.DropdownNavigateRight(Sender: TObject);
var
  NewIndex: Integer;
begin
  NewIndex := FindNextTopItem(FOpenIndex);

  if NewIndex >= 0 then
    SelectTopItem(NewIndex);
end;

procedure TCssMainMenu.DropdownClosed(Sender: TObject);
begin
  if Sender <> FDropdown then
    Exit;

  FDropdown.FOnClosed := nil;
  FDropdown.FOnNavigateLeft := nil;
  FDropdown.FOnNavigateRight := nil;
  FDropdown.OnDeactivate := nil;

  FDropdown.Hide;
  FDropdown.Release;
  FDropdown := nil;

  FOpenIndex := -1;
  FHoverIndex := -1;

  Invalidate;
end;

procedure TCssMainMenu.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewIndex: Integer;
  Item: TCssMenuItem;
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
        begin
          SelectTopItem(NewIndex);
        end
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
        begin
          SelectTopItem(NewIndex);
        end
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
      begin
        if FHoverIndex >= 0 then
          SelectTopItem(FHoverIndex)
        else
          Activate;
      end
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

        FDropdown.FHoverIndex :=
          FDropdown.FindPrevSelectable(FDropdown.FVisibleItems.Count);

        FDropdown.Invalidate;
      end;

      Key := 0;
    end;

    VK_ESCAPE:
    begin
      CloseDropdown;
      Key := 0;
    end;

    VK_RETURN:
    begin
      if FOpenIndex < 0 then
      begin
        if FHoverIndex >= 0 then
        begin
          Item := TCssMenuItem(FItems[FHoverIndex]);

          if Item.HasChildren then
          begin
            SelectTopItem(FHoverIndex);
          end
          else
          begin
            ExecuteTopItem(Item);
          end;
        end
        else
        begin
          Activate;
        end;
      end
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
    SelectTopItem(FirstIndex);
end;

function TCssMainMenu.HandleKeyDown(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;

  if (Key = VK_MENU) or (Key = VK_F10) then
  begin
    Activate;
    Exit;
  end;

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
  I, X, W: Integer;
  Item: TCssMenuItem;
begin
  if (Index < 0) or (Index >= FItems.Count) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  UpdateCanvasFont;

  X := ScalePx(4);

  for I := 0 to Index - 1 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible then
      X := X + GetTopItemWidth(Item);
  end;

  Item := TCssMenuItem(FItems[Index]);
  W := GetTopItemWidth(Item);

  Result := Rect(X, ScalePx(2), X + W, ClientHeight - ScalePx(2));
end;

function TCssMainMenu.TopItemAtPos(X, Y: Integer): Integer;
var
  I: Integer;
  Item: TCssMenuItem;
begin
  Result := -1;

  for I := 0 to FItems.Count - 1 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if not Item.Visible or Item.Separator then
      Continue;

    if PtInRect(GetTopItemRect(I), Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssMainMenu.GetTopItemWidth(AItem: TCssMenuItem): Integer;
var
  S: TSize;
  Img: TCssSvgImgList;
  IconW, IconSize: Integer;
begin
  Result := 0;

  if (AItem = nil) or not AItem.Visible then
    Exit;

  if AItem.Separator then
  begin
    Result := GetMenuSeparatorWidth;
    Exit;
  end;

  UpdateCanvasFont;

  { Reserve space for the icon when the item has one. The reservation
    is the same whether the icon sits to the left or to the right of
    the caption: icon size + 6 px gap on each side. }
  IconW := 0;
  Img := AItem.GetEffectiveSvgImages;
  if (Img <> nil) and (AItem.ImageIndex >= 0) and (AItem.ImageIndex < Img.Count) then
  begin
    IconSize := GetMenuIconSize(Canvas);
    IconW := IconSize + ScalePx(12);
  end;

  if HtmlMode then
  begin
    S := MeasureHtmlTextSize(AItem.Caption, 0);
    Result := S.cx + ScalePx(20) + IconW;
  end
  else
    Result := Canvas.TextWidth(AItem.Caption) + ScalePx(20) + IconW;

  if Result < ScalePx(20) then
    Result := ScalePx(20);
end;

procedure TCssMainMenu.CloseDropdown;
var
  Popup: TCssMenuPopupForm;
begin
  if Assigned(FDropdown) then
  begin
    Popup := FDropdown;
    FDropdown := nil;

    Popup.FOnClosed := nil;
    Popup.FOnNavigateLeft := nil;
    Popup.FOnNavigateRight := nil;
    Popup.OnDeactivate := nil;

    Popup.CloseSubPopup;

    Popup.Hide;

    if (csDestroying in ComponentState) or (csDestroying in Popup.ComponentState) then
      Popup.Free
    else
      Popup.Release;
  end;

  FOpenIndex := -1;
  FHoverIndex := -1;
  Invalidate;
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
  FHoverIndex := Index;

  FDropdown := TCssMenuPopupForm.CreateMenu(Self, Self, Item.FItems);
  FDropdown.FParentMenuItem := Item;

  FDropdown.FOnClosed       := @DropdownClosed;
  FDropdown.FOnNavigateLeft := @DropdownNavigateLeft;
  FDropdown.FOnNavigateRight := @DropdownNavigateRight;

  R := GetTopItemRect(Index);
  P := ClientToScreen(Point(R.Left, R.Bottom));

  FDropdown.ShowPopup(P.X, P.Y);

  Invalidate;
end;

procedure TCssMainMenu.ExecuteTopItem(AItem: TCssMenuItem);
begin
  if AItem = nil then
    Exit;

  if AItem.Separator then
    Exit;

  if not AItem.Enabled then
    Exit;

  if Assigned(AItem.FOnClick) then
    AItem.FOnClick(AItem);
end;

procedure TCssMainMenu.SelectTopItem(AIndex: Integer);
var
  Item: TCssMenuItem;
  R: TRect;
  P: TPoint;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  Item := TCssMenuItem(FItems[AIndex]);

  if not Item.Visible then
    Exit;

  if not Item.Enabled then
    Exit;

  if Item.Separator then
    Exit;

  CloseDropdown;

  FHoverIndex := AIndex;
  Invalidate;

  if not Item.HasChildren then
  begin
    SetFocus;
    Exit;
  end;

  FOpenIndex := AIndex;

  FDropdown := TCssMenuPopupForm.CreateMenu(Self, Self, Item.FItems);
  FDropdown.FParentMenuItem := Item;
  FDropdown.FOnClosed       := @DropdownClosed;
  FDropdown.FOnNavigateLeft := @DropdownNavigateLeft;
  FDropdown.FOnNavigateRight := @DropdownNavigateRight;

  R := GetTopItemRect(AIndex);
  P := ClientToScreen(Point(R.Left, R.Bottom));

  FDropdown.ShowPopup(P.X, P.Y);

  if Assigned(FDropdown) then
  begin
    FDropdown.SetFocus;
    FDropdown.SelectFirstItem;
  end;
end;

procedure TCssMainMenu.Paint;
var
  I, TextTop, SepX: Integer;
  Item: TCssMenuItem;
  R: TRect;
  S: TSize;
  FG: TColor;
  Img: TCssSvgImgList;
  IconBmp: TBitmap;
  IconX, IconY, IconW, IconH, TextLeft: Integer;
  IconSize, TextRight: Integer;
  HasIcon: Boolean;
  Layout: TCssMenuIconLayout;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := GetMenuBarBackground;
  Canvas.FillRect(ClientRect);

  UpdateCanvasFont;

  Layout := GetMenuIconLayout;

  for I := 0 to FItems.Count - 1 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if not Item.Visible then
      Continue;

    R := GetTopItemRect(I);

    if Item.Separator then
    begin
      if (R.Bottom - R.Top) > ScalePx(8) then
      begin
        SepX := R.Left + ((R.Right - R.Left) div 2);

        Canvas.Pen.Width := 1;
        Canvas.Pen.Color := GetMenuSeparatorColor;
        Canvas.MoveTo(SepX, R.Top + ScalePx(4));
        Canvas.LineTo(SepX, R.Bottom - ScalePx(4));
      end;

      Continue;
    end;

    if (I = FHoverIndex) or (I = FOpenIndex) then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GetMenuHoverBackground;
      Canvas.FillRect(R);
      FG := GetMenuHoverTextColor;
    end
    else
      FG := GetMenuTextColor;

    if not Item.Enabled then
      FG := GetMenuDisabledText;

    Img := Item.GetEffectiveSvgImages;
    HasIcon := (Img <> nil) and
               (Item.ImageIndex >= 0) and
               (Item.ImageIndex < Img.Count);

    { Left icon. }
    IconW := 0;
    if HasIcon and (Layout = milLeft) then
    begin
      IconSize := GetMenuIconSize(Canvas);
      IconW := IconSize;
      IconH := IconSize;
      IconX := R.Left + ScalePx(6);
      IconY := R.Top + (R.Height - IconH) div 2;

      IconBmp := Img.GetBitmap(
        Item.ImageIndex, IconW, IconH, FG, Item.GetEffectiveSvgVariant);
      try
        DrawSvgBitmapWithAlpha(Canvas, IconX, IconY, IconBmp);
      finally
        IconBmp.Free;
      end;

      Inc(IconW, ScalePx(6));
    end;

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    if HasIcon and (Layout = milRight) then
    begin
      IconSize := GetMenuIconSize(Canvas);
      IconW := IconSize + ScalePx(12);
    end
    else if HasIcon then
      IconSize := GetMenuIconSize(Canvas)
    else
      IconSize := 0;

    { Text placement. }
    if HasIcon and (Layout = milLeft) then
      TextLeft := R.Left + ScalePx(6) + IconW
    else
      TextLeft := R.Left + ScalePx(10);

    if HasIcon and (Layout = milRight) then
      TextRight := R.Right - ScalePx(6) - IconSize - ScalePx(6)
    else
      TextRight := R.Right - ScalePx(10);

    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(Item.Caption, TextRight - TextLeft);

      TextTop := R.Top + (((R.Bottom - R.Top) - S.cy) div 2);

      if TextTop < R.Top then
        TextTop := R.Top;

      DrawHtmlText(
        Canvas,
        Rect(TextLeft, TextTop, TextRight, TextTop + S.cy),
        Item.Caption,
        FG
      );
    end
    else
    begin
      Canvas.TextOut(
        TextLeft,
        R.Top + (((R.Bottom - R.Top) - Canvas.TextHeight(Item.Caption)) div 2),
        Item.Caption
      );
    end;

    { Right icon. }
    if HasIcon and (Layout = milRight) then
    begin
      IconSize := GetMenuIconSize(Canvas);
      IconW := IconSize;
      IconH := IconSize;
      IconX := R.Right - ScalePx(6) - IconW;
      IconY := R.Top + (R.Height - IconH) div 2;

      IconBmp := Img.GetBitmap(
        Item.ImageIndex, IconW, IconH, FG, Item.GetEffectiveSvgVariant);
      try
        DrawSvgBitmapWithAlpha(Canvas, IconX, IconY, IconBmp);
      finally
        IconBmp.Free;
      end;
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

procedure TCssMainMenu.DoExit;
begin
  inherited DoExit;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;
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
  if csDesigning in ComponentState then
  begin
    Canvas.Pen.Style := psDash;
    Canvas.Pen.Color := clGray;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width, Height);
    Canvas.Font.Color := clGray;
    Canvas.TextOut(ScalePx(4), ScalePx(4), 'PopupMenu');
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

procedure RegisterCssMenuRuntimeClasses;
begin
  if GetClass('TCssMenuItem') = nil then
    RegisterClass(TCssMenuItem);

  if GetClass('TCssMainMenu') = nil then
    RegisterClass(TCssMainMenu);

  if GetClass('TCssPopupMenu') = nil then
    RegisterClass(TCssPopupMenu);
end;

initialization
  RegisterCssMenuRuntimeClasses;

finalization
  UnregisterClass(TCssMenuItem);
  UnregisterClass(TCssMainMenu);
  UnregisterClass(TCssPopupMenu);

end.
