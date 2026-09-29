unit CssMenuControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  Forms, CssStyledControl;

type
  TCssMenuBase = class;

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

    procedure DoChanged;
  protected
    { Standard LCL streaming hook: returns child items in order. }
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
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

    // Reparenting (used by the designer and by MoveNode)
    procedure Detach;                                 // detach from current parent
    procedure AttachTo(ANewParent: TCssMenuItem;      // attach as sub-item
      AIndex: Integer);

    // Non-published accessors
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
    // Tag, Name, Owner are inherited from TComponent
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
    function GetMenuSeparatorHeight: Integer;
    function GetMenuSeparatorWidth: Integer;
  protected
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure ResetStyle; override;

    { Standard LCL streaming hook: returns top-level items. }
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;

    property ItemsList: TList read FItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetParentComponent: TComponent; override;
    function DesignOwner: TComponent;

    // Item management
    function AddItem: TCssMenuItem;
    function InsertItem(Index: Integer): TCssMenuItem;
    function IndexOfItem(AItem: TCssMenuItem): Integer;
    procedure DetachItem(AItem: TCssMenuItem);
    procedure AttachItem(AItem: TCssMenuItem; AIndex: Integer);
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
    function GetTopItemWidth(AItem: TCssMenuItem): Integer;

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

  // Auto-register with the logical parent. This is what makes items
  // loaded from the .lfm end up in the parent's item list without any
  // explicit call from the reader.
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

function TCssMenuBase.GetMenuSeparatorHeight: Integer;
begin
  if FMenuSeparatorHeightSet then
    Result := FMenuSeparatorHeight
  else
  begin
    Result := GetMenuItemHeight div 4;

    if Result < 4 then
      Result := 4;

    if Result > 9 then
      Result := 9;
  end;

  if Result < 1 then
    Result := 1;
end;

function TCssMenuBase.GetMenuSeparatorWidth: Integer;
begin
  if FMenuSeparatorWidthSet then
    Result := FMenuSeparatorWidth
  else
    Result := 8;

  if Result < 1 then
    Result := 1;
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
  I, W, CapW, TotalH, IH, SepH: Integer;
  Item: TCssMenuItem;
  S: TSize;
begin
  IH := FMenu.GetMenuItemHeight;
  SepH := FMenu.GetMenuSeparatorHeight;

  Canvas.Font := Font;

  W := 0;
  TotalH := 4;

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
  I, aTop, H: Integer;
  Item: TCssMenuItem;
begin
  if (Index < 0) or (Index >= FVisibleItems.Count) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  aTop := 2;

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

  Result := Rect(2, aTop, ClientWidth - 2, aTop + H);
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
  I: Integer;
  Item: TCssMenuItem;
  R: TRect;
  FG: TColor;
begin
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

    if Item.Separator then
    begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Color := FMenu.GetMenuSeparatorColor;
      Canvas.MoveTo(R.Left + 4, R.Top + ((R.Bottom - R.Top) div 2));
      Canvas.LineTo(R.Right - 4, R.Top + ((R.Bottom - R.Top) div 2));
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

    if Item.Checked then
      DrawCheckMark(R, FG);

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    if FMenu.HtmlMode then
    begin
      FMenu.BeginMenuHtmlDraw;
      try
        FMenu.DrawHtmlText(
          Canvas,
          Rect(R.Left + 26, R.Top, R.Right - 24, R.Bottom),
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
        R.Left + 26,
        R.Top + (((R.Bottom - R.Top) - Canvas.TextHeight(Item.Caption)) div 2),
        Item.Caption
      );
    end;

    if Item.Shortcut <> '' then
    begin
      Canvas.Font.Color := FMenu.GetMenuShortcutColor;
      Canvas.TextOut(
        R.Right - Canvas.TextWidth(Item.Shortcut) - 24,
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
  I, X, W: Integer;
  Item: TCssMenuItem;
begin
  if (Index < 0) or (Index >= FItems.Count) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  Canvas.Font := Font;

  X := 4;

  for I := 0 to Index - 1 do
  begin
    Item := TCssMenuItem(FItems[I]);

    if Item.Visible then
      X := X + GetTopItemWidth(Item);
  end;

  Item := TCssMenuItem(FItems[Index]);
  W := GetTopItemWidth(Item);

  Result := Rect(X, 2, X + W, ClientHeight - 2);
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
begin
  Result := 0;

  if (AItem = nil) or not AItem.Visible then
    Exit;

  if AItem.Separator then
  begin
    Result := GetMenuSeparatorWidth;
    Exit;
  end;

  Canvas.Font := Font;

  if HtmlMode then
  begin
    S := MeasureHtmlTextSize(AItem.Caption, 0);
    Result := S.cx + 20;
  end
  else
    Result := Canvas.TextWidth(AItem.Caption) + 20;

  if Result < 20 then
    Result := 20;
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
  I, TextTop, SepX: Integer;
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

    if Item.Separator then
    begin
      if (R.Bottom - R.Top) > 8 then
      begin
        SepX := R.Left + ((R.Right - R.Left) div 2);

        Canvas.Pen.Width := 1;
        Canvas.Pen.Color := GetMenuSeparatorColor;
        Canvas.MoveTo(SepX, R.Top + 4);
        Canvas.LineTo(SepX, R.Bottom - 4);
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

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FG;

    if HtmlMode then
    begin
      S := MeasureHtmlTextSize(Item.Caption, (R.Right - R.Left) - 20);

      TextTop := R.Top + (((R.Bottom - R.Top) - S.cy) div 2);

      if TextTop < R.Top then
        TextTop := R.Top;

      DrawHtmlText(
        Canvas,
        Rect(R.Left + 10, TextTop, R.Right - 10, TextTop + S.cy),
        Item.Caption,
        FG
      );
    end
    else
    begin
      Canvas.TextOut(
        R.Left + 10,
        R.Top + (((R.Bottom - R.Top) - Canvas.TextHeight(Item.Caption)) div 2),
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
