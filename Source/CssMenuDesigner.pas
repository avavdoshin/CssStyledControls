unit CssMenuDesigner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ComCtrls, ExtCtrls,
  Graphics, Dialogs, LCLType, CssMenuControl, IDEIntf;

type
  { Callback interface used by the designer dialog to tell the IDE
    that items were added to or removed from the menu tree.
    Implemented by the design-time package (see CssMenuReg.pas). }
  IMenuDesignNotifier = interface
    function CreateMenuItem(const AName: string): TCssMenuItem;
    procedure NotifyInserted(AItem: TCssMenuItem);
    procedure NotifyRemoved(AItem: TCssMenuItem);
    procedure SelectInDesigner(AComponent: TComponent);
    procedure RefreshDesigner;
  end;

  { Visual editor dialog for a TCssMenuBase instance.
    Mirrors the standard TMainMenu designer: tree of items on the left,
    property editor on the right, buttons for add/insert/delete/reorder. }
  TCssMenuDesignerForm = class(TForm)
  private
    FTree: TTreeView;
    FBtnAdd, FBtnAddChild, FBtnInsert, FBtnDelete,
    FBtnUp, FBtnDown, FBtnClose: TButton;
    FEdCaption, FEdShortcut: TEdit;
    FCbEnabled, FCbChecked, FCbVisible, FCbSeparator: TCheckBox;
    FMenu: TCssMenuBase;
    FNotifier: IMenuDesignNotifier;
    FUpdating: Boolean;
    FOnChanged: TNotifyEvent;

    procedure BuildUI;
    procedure LoadTree;

    function CreateNewItem: TCssMenuItem;

    // Tree <-> model helpers
    procedure AddNodesRecursive(AParent: TCssMenuItem; ATreeNode: TTreeNode);
    procedure RebuildTree;                        // full rebuild from the model
    procedure RefreshNodeText(AItem: TCssMenuItem);
    function  NodeItem(ANode: TTreeNode): TCssMenuItem;
    function  SelectedItem: TCssMenuItem;
    function  SelectedParentItem: TCssMenuItem;
    procedure SelectItem(AItem: TCssMenuItem);
    procedure UpdateEditorFromSelection;
    procedure NotifyChanged;

    // Event handlers
    procedure TreeSelectionChanged(Sender: TObject; Node: TTreeNode);
    procedure TreeDragOver(Sender, Source: TObject;
      X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure TreeDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure BtnAddClick(Sender: TObject);
    procedure BtnAddChildClick(Sender: TObject);
    procedure BtnInsertClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure BtnUpClick(Sender: TObject);
    procedure BtnDownClick(Sender: TObject);
    procedure FieldChanged(Sender: TObject);

    procedure NotifyInsert(AItem: TCssMenuItem);
    procedure NotifyRemove(AItem: TCssMenuItem);
    procedure NotifyRemoveRecursive(AItem: TCssMenuItem);

    function GenerateItemName: string;

    procedure RefreshDesign;
    procedure RefreshDesignComponent(AComponent: TComponent);
  public
    constructor CreateDesigner(AOwner: TComponent; AMenu: TCssMenuBase; ANotifier: IMenuDesignNotifier);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

{ Opens the designer dialog for the specified menu.
  AOnChanged is called after every structural or property change. }
procedure ShowCssMenuDesigner(AMenu: TCssMenuBase;
  ANotifier: IMenuDesignNotifier = nil; AOnChanged: TNotifyEvent = nil);

implementation

uses
  PropEdits;

{ ============================================================ }
{ Designer dialog                                              }
{ ============================================================ }

constructor TCssMenuDesignerForm.CreateDesigner(AOwner: TComponent;
  AMenu: TCssMenuBase; ANotifier: IMenuDesignNotifier);
begin
  inherited CreateNew(AOwner);

  FMenu := AMenu;
  FNotifier := ANotifier;

  Caption := 'Menu Designer';
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Width := 720;
  Height := 480;
  Constraints.MinWidth := 480;
  Constraints.MinHeight := 320;

  BuildUI;
  LoadTree;
end;

procedure TCssMenuDesignerForm.NotifyInsert(AItem: TCssMenuItem);
begin
  if (FNotifier <> nil) and (AItem <> nil) then
    FNotifier.NotifyInserted(AItem);
end;

procedure TCssMenuDesignerForm.NotifyRemove(AItem: TCssMenuItem);
begin
  if (FNotifier <> nil) and (AItem <> nil) then
    FNotifier.NotifyRemoved(AItem);
end;

procedure TCssMenuDesignerForm.NotifyRemoveRecursive(AItem: TCssMenuItem);
var
  I: Integer;
begin
  if AItem = nil then
    Exit;

  for I := AItem.Count - 1 downto 0 do
    NotifyRemoveRecursive(AItem[I]);

  NotifyRemove(AItem);
end;

function TCssMenuDesignerForm.GenerateItemName: string;
var
  Root: TComponent;
  I: Integer;

  function NameExists(C: TComponent; const AName: string): Boolean;
  var
    K: Integer;
  begin
    if SameText(C.Name, AName) then
      Exit(True);

    for K := 0 to C.ComponentCount - 1 do
      if NameExists(C.Components[K], AName) then
        Exit(True);

    Result := False;
  end;

begin
  Root := FMenu.DesignOwner;

  I := 1;
  repeat
    Result := 'MenuItem' + IntToStr(I);
    Inc(I);
  until (not NameExists(Root, Result)) or (I > 100000);
end;

procedure TCssMenuDesignerForm.RefreshDesign;
begin
  if FNotifier <> nil then
    FNotifier.RefreshDesigner;
end;

procedure TCssMenuDesignerForm.RefreshDesignComponent(AComponent: TComponent);
begin
  if (FNotifier <> nil) and (AComponent <> nil) then
    FNotifier.SelectInDesigner(AComponent);
end;

procedure TCssMenuDesignerForm.BuildUI;
var
  TopP, BottomP, RightP: TPanel;
  Lbl: TLabel;
begin
  // ---------- Top toolbar ----------
  TopP := TPanel.Create(Self);
  TopP.Parent := Self;
  TopP.Align := alTop;
  TopP.Height := 38;
  TopP.BevelOuter := bvNone;

  FBtnAdd := TButton.Create(TopP);
  FBtnAdd.Parent := TopP;
  FBtnAdd.SetBounds(6, 6, 110, 26);
  FBtnAdd.Caption := '&Add';
  FBtnAdd.OnClick := @BtnAddClick;

  FBtnAddChild := TButton.Create(TopP);
  FBtnAddChild.Parent := TopP;
  FBtnAddChild.SetBounds(120, 6, 110, 26);
  FBtnAddChild.Caption := 'Add &Child';
  FBtnAddChild.OnClick := @BtnAddChildClick;

  FBtnInsert := TButton.Create(TopP);
  FBtnInsert.Parent := TopP;
  FBtnInsert.SetBounds(234, 6, 110, 26);
  FBtnInsert.Caption := '&Insert';
  FBtnInsert.OnClick := @BtnInsertClick;

  FBtnDelete := TButton.Create(TopP);
  FBtnDelete.Parent := TopP;
  FBtnDelete.SetBounds(348, 6, 110, 26);
  FBtnDelete.Caption := '&Delete';
  FBtnDelete.OnClick := @BtnDeleteClick;

  FBtnUp := TButton.Create(TopP);
  FBtnUp.Parent := TopP;
  FBtnUp.SetBounds(462, 6, 80, 26);
  FBtnUp.Caption := 'Move &Up';
  FBtnUp.OnClick := @BtnUpClick;

  FBtnDown := TButton.Create(TopP);
  FBtnDown.Parent := TopP;
  FBtnDown.SetBounds(546, 6, 80, 26);
  FBtnDown.Caption := 'Move Do&wn';
  FBtnDown.OnClick := @BtnDownClick;

  // ---------- Bottom Close button ----------
  BottomP := TPanel.Create(Self);
  BottomP.Parent := Self;
  BottomP.Align := alBottom;
  BottomP.Height := 40;
  BottomP.BevelOuter := bvNone;

  FBtnClose := TButton.Create(BottomP);
  FBtnClose.Parent := BottomP;
  FBtnClose.Caption := 'Close';
  FBtnClose.ModalResult := mrOk;
  FBtnClose.SetBounds(BottomP.Width - 100, 6, 90, 28);
  FBtnClose.Anchors := [akRight, akTop];

  // ---------- Right property panel ----------
  RightP := TPanel.Create(Self);
  RightP.Parent := Self;
  RightP.Align := alRight;
  RightP.Width := 250;
  RightP.BevelOuter := bvNone;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 12, 60, 15);
  Lbl.Caption := 'Caption:';

  FEdCaption := TEdit.Create(RightP);
  FEdCaption.Parent := RightP;
  FEdCaption.SetBounds(12, 30, 226, 24);
  FEdCaption.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 62, 60, 15);
  Lbl.Caption := 'Shortcut:';

  FEdShortcut := TEdit.Create(RightP);
  FEdShortcut.Parent := RightP;
  FEdShortcut.SetBounds(12, 80, 226, 24);
  FEdShortcut.OnChange := @FieldChanged;

  FCbEnabled := TCheckBox.Create(RightP);
  FCbEnabled.Parent := RightP;
  FCbEnabled.SetBounds(12, 118, 200, 20);
  FCbEnabled.Caption := 'Enabled';
  FCbEnabled.OnChange := @FieldChanged;

  FCbChecked := TCheckBox.Create(RightP);
  FCbChecked.Parent := RightP;
  FCbChecked.SetBounds(12, 142, 200, 20);
  FCbChecked.Caption := 'Checked';
  FCbChecked.OnChange := @FieldChanged;

  FCbVisible := TCheckBox.Create(RightP);
  FCbVisible.Parent := RightP;
  FCbVisible.SetBounds(12, 166, 200, 20);
  FCbVisible.Caption := 'Visible';
  FCbVisible.OnChange := @FieldChanged;

  FCbSeparator := TCheckBox.Create(RightP);
  FCbSeparator.Parent := RightP;
  FCbSeparator.SetBounds(12, 190, 200, 20);
  FCbSeparator.Caption := 'Separator';
  FCbSeparator.OnChange := @FieldChanged;

  // ---------- Tree (main area) ----------
  FTree := TTreeView.Create(Self);
  FTree.Parent := Self;
  FTree.Align := alClient;
  FTree.ReadOnly := True;
  FTree.HideSelection := False;
  FTree.DragMode := dmAutomatic;                 // enable built-in drag&drop
  FTree.OnChange := @TreeSelectionChanged;
  FTree.OnDragOver := @TreeDragOver;
  FTree.OnDragDrop := @TreeDragDrop;
  FTree.OnKeyDown := @TreeKeyDown;
end;

procedure TCssMenuDesignerForm.LoadTree;
begin
  RebuildTree;
end;

function TCssMenuDesignerForm.CreateNewItem: TCssMenuItem;
var
  NewName: string;
begin
  NewName := GenerateItemName;

  if FNotifier <> nil then
    Result := FNotifier.CreateMenuItem(NewName)
  else
    Result := TCssMenuItem.Create(FMenu.DesignOwner);

  if Result.Name = '' then
    Result.Name := NewName;
end;

procedure TCssMenuDesignerForm.AddNodesRecursive(
  AParent: TCssMenuItem; ATreeNode: TTreeNode);
var
  I: Integer;
  Item: TCssMenuItem;
  N: TTreeNode;
begin
  for I := 0 to AParent.Count - 1 do
  begin
    Item := AParent[I];
    N := FTree.Items.AddChild(ATreeNode, Item.Caption);
    N.Data := Item;
    Item.DesignerData := N;
    AddNodesRecursive(Item, N);
  end;
end;

procedure TCssMenuDesignerForm.RebuildTree;
var
  I: Integer;
  Root: TTreeNode;
  Item: TCssMenuItem;
  ToSelect: TCssMenuItem;
begin
  ToSelect := SelectedItem;

  FUpdating := True;
  try
    FTree.Items.BeginUpdate;
    try
      FTree.Items.Clear;

      for I := 0 to FMenu.Count - 1 do
      begin
        Item := FMenu[I];

        Root := FTree.Items.Add(nil, Item.Caption);
        Root.Data := Item;
        Item.DesignerData := Root;

        AddNodesRecursive(Item, Root);
      end;

      FTree.FullExpand;
    finally
      FTree.Items.EndUpdate;
    end;

    if ToSelect <> nil then
      SelectItem(ToSelect)
    else if FTree.Items.Count > 0 then
      FTree.Selected := FTree.Items[0];
  finally
    FUpdating := False;
  end;

  UpdateEditorFromSelection;
end;

procedure TCssMenuDesignerForm.RefreshNodeText(AItem: TCssMenuItem);
var
  N: TTreeNode;
  S: string;
begin
  if AItem = nil then Exit;

  N := TTreeNode(AItem.DesignerData);
  if N = nil then Exit;

  S := AItem.Caption;

  if AItem.Separator then
    S := '─────────'
  else if S = '' then
    S := '(empty)';

  if AItem.Shortcut <> '' then
    S := S + #9 + AItem.Shortcut;

  N.Text := S;
end;

function TCssMenuDesignerForm.NodeItem(ANode: TTreeNode): TCssMenuItem;
begin
  if ANode = nil then
    Result := nil
  else
    Result := TCssMenuItem(ANode.Data);
end;

function TCssMenuDesignerForm.SelectedItem: TCssMenuItem;
begin
  Result := NodeItem(FTree.Selected);
end;

function TCssMenuDesignerForm.SelectedParentItem: TCssMenuItem;
var
  It: TCssMenuItem;
begin
  Result := nil;
  It := SelectedItem;
  if It <> nil then
    Result := It.Parent;
end;

procedure TCssMenuDesignerForm.SelectItem(AItem: TCssMenuItem);
var
  N: TTreeNode;
begin
  if AItem = nil then Exit;

  N := TTreeNode(AItem.DesignerData);
  if N <> nil then
    FTree.Selected := N;
end;

procedure TCssMenuDesignerForm.UpdateEditorFromSelection;
var
  It: TCssMenuItem;
begin
  FUpdating := True;
  try
    It := SelectedItem;

    if It = nil then
    begin
      FEdCaption.Text := '';
      FEdShortcut.Text := '';
      FCbEnabled.Checked := False;
      FCbChecked.Checked := False;
      FCbVisible.Checked := False;
      FCbSeparator.Checked := False;

      FEdCaption.Enabled := False;
      FEdShortcut.Enabled := False;
      FCbEnabled.Enabled := False;
      FCbChecked.Enabled := False;
      FCbVisible.Enabled := False;
      FCbSeparator.Enabled := False;
    end
    else
    begin
      FEdCaption.Text := It.Caption;
      FEdShortcut.Text := It.Shortcut;
      FCbEnabled.Checked := It.Enabled;
      FCbChecked.Checked := It.Checked;
      FCbVisible.Checked := It.Visible;
      FCbSeparator.Checked := It.Separator;

      FEdCaption.Enabled := True;
      FEdShortcut.Enabled := True;
      FCbEnabled.Enabled := True;
      FCbChecked.Enabled := True;
      FCbVisible.Enabled := True;
      FCbSeparator.Enabled := True;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TCssMenuDesignerForm.NotifyChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

// ---------- Tree events ----------

procedure TCssMenuDesignerForm.TreeSelectionChanged(Sender: TObject; Node: TTreeNode);
begin
  if FUpdating then Exit;
  UpdateEditorFromSelection;
end;

procedure TCssMenuDesignerForm.TreeDragOver(Sender, Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  Target: TTreeNode;
  SourceItem, TargetItem: TCssMenuItem;
begin
  Accept := False;

  if Sender <> FTree then Exit;
  if not (Source is TTreeView) then Exit;
  if TTreeView(Source) <> FTree then Exit;

  SourceItem := SelectedItem;
  if SourceItem = nil then Exit;

  Target := FTree.GetNodeAt(X, Y);
  TargetItem := NodeItem(Target);

  // Cannot drop onto itself or into its own subtree.
  if TargetItem = SourceItem then Exit;
  if (TargetItem <> nil) and SourceItem.IsAncestorOf(TargetItem) then Exit;

  Accept := True;
end;

procedure TCssMenuDesignerForm.TreeDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  Target: TTreeNode;
  SourceItem, TargetItem, NewParent: TCssMenuItem;
  NewIndex: Integer;
begin
  if Sender <> FTree then
    Exit;

  if not (Source is TTreeView) then
    Exit;

  SourceItem := SelectedItem;
  if SourceItem = nil then
    Exit;

  Target := FTree.GetNodeAt(X, Y);
  TargetItem := NodeItem(Target);

  if TargetItem <> nil then
  begin
    NewParent := TargetItem.Parent;

    if NewParent <> nil then
      NewIndex := NewParent.IndexOf(TargetItem) + 1
    else
      NewIndex := FMenu.IndexOfItem(TargetItem) + 1;
  end
  else
  begin
    NewParent := nil;
    NewIndex := FMenu.Count;
  end;

  SourceItem.Detach;

  if NewParent <> nil then
    SourceItem.AttachTo(NewParent, NewIndex)
  else
    FMenu.AttachItem(SourceItem, NewIndex);

  RebuildTree;
  SelectItem(SourceItem);
  RefreshDesignComponent(SourceItem);
  NotifyChanged;
end;

procedure TCssMenuDesignerForm.TreeKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DELETE: BtnDeleteClick(Sender);
    VK_INSERT:
      if ssShift in Shift then
        BtnInsertClick(Sender)
      else
        BtnAddClick(Sender);
    VK_F2: FEdCaption.SetFocus;
  end;
end;

// ---------- Toolbar buttons ----------

procedure TCssMenuDesignerForm.BtnAddClick(Sender: TObject);
var
  It, aParent: TCssMenuItem;
  NewItem: TCssMenuItem;
begin
  It := SelectedItem;

  NewItem := CreateNewItem;

  if It = nil then
  begin
    FMenu.AttachItem(NewItem, FMenu.Count);
    NewItem.Caption := 'Item' + IntToStr(FMenu.Count);
  end
  else
  begin
    aParent := It.Parent;

    if aParent <> nil then
      NewItem.AttachTo(aParent, aParent.IndexOf(It) + 1)
    else
      FMenu.AttachItem(NewItem, FMenu.IndexOfItem(It) + 1);

    NewItem.Caption := 'Item';
  end;

  NotifyInsert(NewItem);
  RebuildTree;
  SelectItem(NewItem);
  RefreshDesignComponent(NewItem);
  NotifyChanged;
end;

procedure TCssMenuDesignerForm.BtnAddChildClick(Sender: TObject);
var
  aParent, NewItem: TCssMenuItem;
begin
  aParent := SelectedItem;
  if aParent = nil then
    Exit;

  NewItem := CreateNewItem;
  NewItem.AttachTo(aParent, aParent.Count);
  NewItem.Caption := 'Child';

  NotifyInsert(NewItem);
  RebuildTree;
  SelectItem(NewItem);
  RefreshDesignComponent(NewItem);
  NotifyChanged;
end;

procedure TCssMenuDesignerForm.BtnInsertClick(Sender: TObject);
var
  It, aParent, NewItem: TCssMenuItem;
begin
  It := SelectedItem;

  if It = nil then
  begin
    BtnAddClick(Sender);
    Exit;
  end;

  NewItem := CreateNewItem;

  aParent := It.Parent;

  if aParent <> nil then
    NewItem.AttachTo(aParent, aParent.IndexOf(It))
  else
    FMenu.AttachItem(NewItem, FMenu.IndexOfItem(It));

  NewItem.Caption := 'Item';

  NotifyInsert(NewItem);
  RebuildTree;
  SelectItem(NewItem);
  RefreshDesignComponent(NewItem);
  NotifyChanged;
end;

procedure TCssMenuDesignerForm.BtnDeleteClick(Sender: TObject);
var
  It, aParent: TCssMenuItem;
  NextToSelect: TCssMenuItem;
  DeleteIndex: Integer;
begin
  It := SelectedItem;
  if It = nil then
    Exit;

  aParent := It.Parent;

  NextToSelect := nil;

  if aParent <> nil then
  begin
    NextToSelect := aParent;
  end
  else
  begin
    DeleteIndex := FMenu.IndexOfItem(It);

    if FMenu.Count > 1 then
      NextToSelect := FMenu[Ord(DeleteIndex = 0)]
    else
      NextToSelect := nil;
  end;

  FTree.Selected := nil;

  NotifyRemove(It);

  RebuildTree;

  if NextToSelect <> nil then
  begin
    SelectItem(NextToSelect);
    RefreshDesignComponent(NextToSelect);
  end
  else
  begin
    if FTree.Items.Count > 0 then
      FTree.Selected := FTree.Items[0];

    RefreshDesign;
  end;

  NotifyChanged;
end;

procedure TCssMenuDesignerForm.BtnUpClick(Sender: TObject);
var
  It, aParent: TCssMenuItem;
  Index: Integer;
begin
  It := SelectedItem;
  if It = nil then
    Exit;

  aParent := It.Parent;

  if aParent <> nil then
  begin
    Index := aParent.IndexOf(It);
    if Index <= 0 then
      Exit;

    It.Detach;
    It.AttachTo(aParent, Index - 1);
  end
  else
  begin
    Index := FMenu.IndexOfItem(It);
    if Index <= 0 then
      Exit;

    FMenu.DetachItem(It);
    FMenu.AttachItem(It, Index - 1);
  end;

  RebuildTree;
  SelectItem(It);
  RefreshDesignComponent(It);
  NotifyChanged;
end;

procedure TCssMenuDesignerForm.BtnDownClick(Sender: TObject);
var
  It, aParent: TCssMenuItem;
  Index: Integer;
begin
  It := SelectedItem;
  if It = nil then
    Exit;

  aParent := It.Parent;

  if aParent <> nil then
  begin
    Index := aParent.IndexOf(It);
    if (Index < 0) or (Index >= aParent.Count - 1) then
      Exit;

    It.Detach;
    It.AttachTo(aParent, Index + 1);
  end
  else
  begin
    Index := FMenu.IndexOfItem(It);
    if (Index < 0) or (Index >= FMenu.Count - 1) then
      Exit;

    FMenu.DetachItem(It);
    FMenu.AttachItem(It, Index + 1);
  end;

  RebuildTree;
  SelectItem(It);
  RefreshDesignComponent(It);
  NotifyChanged;
end;

// ---------- Property panel ----------

procedure TCssMenuDesignerForm.FieldChanged(Sender: TObject);
var
  It: TCssMenuItem;
begin
  if FUpdating then Exit;

  It := SelectedItem;
  if It = nil then Exit;

  It.Caption := FEdCaption.Text;
  It.Shortcut := FEdShortcut.Text;
  It.Enabled := FCbEnabled.Checked;
  It.Checked := FCbChecked.Checked;
  It.Visible := FCbVisible.Checked;
  It.Separator := FCbSeparator.Checked;

  RefreshNodeText(It);
  NotifyChanged;
end;

{ ============================================================ }
{ Public entry point                                           }
{ ============================================================ }

procedure ShowCssMenuDesigner(AMenu: TCssMenuBase;
  ANotifier: IMenuDesignNotifier; AOnChanged: TNotifyEvent);
var
  Frm: TCssMenuDesignerForm;
begin
  if AMenu = nil then Exit;

  Frm := TCssMenuDesignerForm.CreateDesigner(nil, AMenu, ANotifier);
  try
    Frm.OnChanged := AOnChanged;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

end.
