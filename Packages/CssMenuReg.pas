unit CssMenuReg;

{$mode objfpc}{$H+}

interface

procedure Register;

implementation

uses
  Classes, SysUtils, CssMenuControl, CssMenuDesigner,
  IDEIntf,
  ComponentEditors,
  PropEdits;

var
  { Curated list of common shortcuts shown in the Object Inspector
    dropdown for the TCssMenuItem.Shortcut property. }
  GCommonShortcuts: TStringList;

type
  { Wraps the IDE designer and forwards tree-change notifications
    through our IMenuDesignNotifier interface. }
  TCssMenuDesignNotifier = class(TInterfacedObject, IMenuDesignNotifier)
  private
    FDesigner: TComponentEditorDesigner;
    FRoot: TComponent;
  public
    constructor Create(ADesigner: TComponentEditorDesigner; ARoot: TComponent);
    function CreateMenuItem(const AName: string): TCssMenuItem;
    procedure NotifyInserted(AItem: TCssMenuItem);
    procedure NotifyRemoved(AItem: TCssMenuItem);
    procedure SelectInDesigner(AComponent: TComponent);
    procedure RefreshDesigner;
  end;

  { Component editor: adds a "Menu Designer..." verb and opens the
    visual designer dialog on double-click. }
  TCssMenuComponentEditor = class(TComponentEditor)
  private
    procedure MenuDesignerChanged(Sender: TObject);
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

  { Property editor for TCssMenuItem.Shortcut: shows a dropdown with
    common shortcuts. The user can still type any value freely. }
  TCssShortcutPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

constructor TCssMenuDesignNotifier.Create(ADesigner : TComponentEditorDesigner; ARoot: TComponent);
begin
  inherited Create;
  FDesigner := ADesigner;
  FRoot := ARoot;
end;

function TCssMenuDesignNotifier.CreateMenuItem(const AName: string): TCssMenuItem;
begin
  Result := TCssMenuItem.Create(nil);
  try
    if AName <> '' then
      Result.Name := AName;
  except
    Result.Free;
    raise;
  end;
end;

procedure TCssMenuDesignNotifier.NotifyInserted(AItem: TCssMenuItem);
begin
  if AItem = nil then
    Exit;

  if (AItem.Owner = nil) and (FRoot <> nil) then
    TMenuComponentFriend(FRoot).AddOwnedComponent(AItem);

  // PersistentAdded is the IDE-supported way to register a newly-created
  // component. Notification(opInsert) alone does not refresh the Components tree.
  if Assigned(GlobalDesignHook) then
    GlobalDesignHook.PersistentAdded(AItem, True)
  else if FDesigner <> nil then
    FDesigner.Notification(AItem, opInsert);

  if FDesigner <> nil then
    FDesigner.Modified;
end;

procedure TCssMenuDesignNotifier.NotifyRemoved(AItem : TCssMenuItem);
begin
  if (FDesigner <> nil) and (AItem <> nil) then
  begin
    if Assigned(GlobalDesignHook) then
      GlobalDesignHook.Unselect(AItem);

    FDesigner.Notification(AItem, opRemove);
    FDesigner.Modified;
  end;
end;

procedure TCssMenuDesignNotifier.SelectInDesigner(AComponent: TComponent);
begin
  if AComponent = nil then
    Exit;

  if Assigned(GlobalDesignHook) then
  begin
    GlobalDesignHook.SelectOnlyThis(AComponent);
    GlobalDesignHook.Modified(AComponent, ShortString(''));
  end;

  if FDesigner <> nil then
    FDesigner.Modified;
end;

procedure TCssMenuDesignNotifier.RefreshDesigner;
begin
  if Assigned(GlobalDesignHook) and (FRoot <> nil) then
  begin
    GlobalDesignHook.SelectOnlyThis(FRoot);
    GlobalDesignHook.Modified(FRoot, ShortString(''));
  end;

  if FDesigner <> nil then
    FDesigner.Modified;
end;

{ TCssMenuComponentEditor }

procedure TCssMenuComponentEditor.MenuDesignerChanged(Sender: TObject);
begin
  // Mark the form as modified so undo/redo and "Save changes?" work.
  if Designer <> nil then
    Designer.Modified;
end;

function TCssMenuComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TCssMenuComponentEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := 'Menu Designer...'
  else
    Result := inherited GetVerb(Index);
end;

procedure TCssMenuComponentEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    Edit
  else
    inherited ExecuteVerb(Index);
end;

procedure TCssMenuComponentEditor.Edit;
var
  Notifier: IMenuDesignNotifier;
  Root: TComponent;
begin
  if not (Component is TCssMenuBase) then
    Exit;

  Root := Component.Owner;
  if Root = nil then
    Root := Component;

  Notifier := TCssMenuDesignNotifier.Create(Designer, Root);

  ShowCssMenuDesigner(
    TCssMenuBase(Component),
    Notifier,
    @MenuDesignerChanged
  );

  Notifier.SelectInDesigner(Component);
end;

{ TCssShortcutPropertyEditor }

function TCssShortcutPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paSortList];
end;

procedure TCssShortcutPropertyEditor.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := 0 to GCommonShortcuts.Count - 1 do
    Proc(GCommonShortcuts[I]);
end;

{ Registration }

procedure Register;
begin
  // Required so LCL can instantiate TCssMenuItem when reading .lfm files.
  RegisterClass(TCssMenuItem);

  // Hide TCssMenuItem from the palette; it is only created by the menu.
  RegisterNoIcon([TCssMenuItem]);

  RegisterComponentEditor(TCssMainMenu, TCssMenuComponentEditor);
  RegisterComponentEditor(TCssPopupMenu, TCssMenuComponentEditor);

  // Property editor: Shortcut on TCssMenuItem, string type.
  RegisterPropertyEditor(
    TypeInfo(string),
    TCssMenuItem,
    'Shortcut',
    TCssShortcutPropertyEditor
  );
end;

{ Build the curated shortcut list once at unit load. }

procedure BuildCommonShortcuts;
var
  C: Char;
  I: Integer;

  procedure Add(const S: string);
  begin
    GCommonShortcuts.Add(S);
  end;

begin
  GCommonShortcuts := TStringList.Create;
  GCommonShortcuts.Sorted := True;
  GCommonShortcuts.Duplicates := dupIgnore;

  // Empty value clears the shortcut.
  Add('');

  // Ctrl+Letter
  for C := 'A' to 'Z' do
  begin
    Add('Ctrl+' + C);
    Add('Shift+' + C);
    Add('Ctrl+Shift+' + C);
  end;

  // Ctrl+Digit
  for C := '0' to '9' do
    Add('Ctrl+' + C);

  // Function keys
  for I := 1 to 12 do
    Add('F' + IntToStr(I));

  // Common special combinations
  Add('Insert');
  Add('Delete');
  Add('Escape');
  Add('Enter');
  Add('Space');
  Add('Tab');
  Add('Backspace');
  Add('Ctrl+Insert');
  Add('Shift+Insert');
  Add('Ctrl+Delete');
  Add('Shift+Delete');
  Add('Alt+F4');
  Add('Alt+Enter');
  Add('Ctrl+Enter');
  Add('Ctrl+Home');
  Add('Ctrl+End');
  Add('Ctrl+Left');
  Add('Ctrl+Right');
  Add('Ctrl+Up');
  Add('Ctrl+Down');
end;

initialization
  BuildCommonShortcuts;

finalization
  FreeAndNil(GCommonShortcuts);

end.
