unit CssVirtualTreeColumnsEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls,
  LCLType, PropEdits, CssVirtualTreeControl;

type
  TCssTreeColumnsEditorForm = class(TForm)
  private
    FColumns: TCssVirtualTreeColumns;
    FOnChanged: TNotifyEvent;
    FUpdating: Boolean;

    FList: TListBox;
    FBtnAdd, FBtnDelete, FBtnUp, FBtnDown, FBtnClose: TButton;
    FEdText, FEdWidth: TEdit;
    FCbHeaderHAlign, FCbHeaderVAlign, FCbCellHAlign, FCbCellVAlign: TComboBox;

    procedure BuildUI;
    procedure LoadList;
    procedure UpdateEditor;
    procedure ApplyToColumn;
    function  SelectedColumn: TCssVirtualTreeColumn;
    procedure SelectColumn(AIndex: Integer);
    procedure NotifyChanged;

    procedure ListClick(Sender: TObject);
    procedure FieldChanged(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure BtnUpClick(Sender: TObject);
    procedure BtnDownClick(Sender: TObject);
  public
    constructor CreateEditor(AOwner: TComponent;
      AColumns: TCssVirtualTreeColumns);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TCssTreeColumnsPropertyEditor = class(TPropertyEditor)
  private
    procedure DialogChanged(Sender: TObject);
  public
    procedure Edit; override;
    function  GetAttributes: TPropertyAttributes; override;
    function  GetValue: string; override;
  end;

procedure RegisterCssTreeColumnsEditor;

implementation

{ ============================================================ }
{ Column editor dialog                                         }
{ ============================================================ }

constructor TCssTreeColumnsEditorForm.CreateEditor(AOwner: TComponent;
  AColumns: TCssVirtualTreeColumns);
begin
  inherited CreateNew(AOwner);

  FColumns := AColumns;

  Caption := 'Columns Editor';
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Width := 720;
  Height := 420;
  Constraints.MinWidth := 560;
  Constraints.MinHeight := 320;

  BuildUI;
  LoadList;
end;

procedure TCssTreeColumnsEditorForm.BuildUI;
var
  TopP, RightP, BottomP: TPanel;
  Lbl: TLabel;
begin
  // ---- Top toolbar ----
  TopP := TPanel.Create(Self);
  TopP.Parent := Self;
  TopP.Align := alTop;
  TopP.Height := 38;
  TopP.BevelOuter := bvNone;

  FBtnAdd := TButton.Create(TopP);
  FBtnAdd.Parent := TopP;
  FBtnAdd.SetBounds(6, 6, 100, 26);
  FBtnAdd.Caption := '&Add';
  FBtnAdd.OnClick := @BtnAddClick;

  FBtnDelete := TButton.Create(TopP);
  FBtnDelete.Parent := TopP;
  FBtnDelete.SetBounds(110, 6, 100, 26);
  FBtnDelete.Caption := '&Delete';
  FBtnDelete.OnClick := @BtnDeleteClick;

  FBtnUp := TButton.Create(TopP);
  FBtnUp.Parent := TopP;
  FBtnUp.SetBounds(214, 6, 90, 26);
  FBtnUp.Caption := 'Move &Up';
  FBtnUp.OnClick := @BtnUpClick;

  FBtnDown := TButton.Create(TopP);
  FBtnDown.Parent := TopP;
  FBtnDown.SetBounds(308, 6, 90, 26);
  FBtnDown.Caption := 'Move Do&wn';
  FBtnDown.OnClick := @BtnDownClick;

  // ---- Bottom panel with the Close button ----
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

  // ---- Right panel with the column properties ----
  RightP := TPanel.Create(Self);
  RightP.Parent := Self;
  RightP.Align := alRight;
  RightP.Width := 260;
  RightP.BevelOuter := bvNone;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 12, 60, 15);
  Lbl.Caption := 'Text:';

  FEdText := TEdit.Create(RightP);
  FEdText.Parent := RightP;
  FEdText.SetBounds(12, 30, 232, 24);
  FEdText.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 60, 60, 15);
  Lbl.Caption := 'Width:';

  FEdWidth := TEdit.Create(RightP);
  FEdWidth.Parent := RightP;
  FEdWidth.SetBounds(12, 78, 232, 24);
  FEdWidth.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 108, 90, 15);
  Lbl.Caption := 'Header HAlign:';

  FCbHeaderHAlign := TComboBox.Create(RightP);
  FCbHeaderHAlign.Parent := RightP;
  FCbHeaderHAlign.SetBounds(12, 126, 232, 24);
  FCbHeaderHAlign.Style := csDropDownList;
  FCbHeaderHAlign.Items.Add('Inherit');
  FCbHeaderHAlign.Items.Add('Left');
  FCbHeaderHAlign.Items.Add('Center');
  FCbHeaderHAlign.Items.Add('Right');
  FCbHeaderHAlign.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 156, 90, 15);
  Lbl.Caption := 'Header VAlign:';

  FCbHeaderVAlign := TComboBox.Create(RightP);
  FCbHeaderVAlign.Parent := RightP;
  FCbHeaderVAlign.SetBounds(12, 174, 232, 24);
  FCbHeaderVAlign.Style := csDropDownList;
  FCbHeaderVAlign.Items.Add('Inherit');
  FCbHeaderVAlign.Items.Add('Top');
  FCbHeaderVAlign.Items.Add('Middle');
  FCbHeaderVAlign.Items.Add('Bottom');
  FCbHeaderVAlign.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 204, 90, 15);
  Lbl.Caption := 'Cell HAlign:';

  FCbCellHAlign := TComboBox.Create(RightP);
  FCbCellHAlign.Parent := RightP;
  FCbCellHAlign.SetBounds(12, 222, 232, 24);
  FCbCellHAlign.Style := csDropDownList;
  FCbCellHAlign.Items.Add('Inherit');
  FCbCellHAlign.Items.Add('Left');
  FCbCellHAlign.Items.Add('Center');
  FCbCellHAlign.Items.Add('Right');
  FCbCellHAlign.OnChange := @FieldChanged;

  Lbl := TLabel.Create(RightP);
  Lbl.Parent := RightP;
  Lbl.SetBounds(12, 252, 90, 15);
  Lbl.Caption := 'Cell VAlign:';

  FCbCellVAlign := TComboBox.Create(RightP);
  FCbCellVAlign.Parent := RightP;
  FCbCellVAlign.SetBounds(12, 270, 232, 24);
  FCbCellVAlign.Style := csDropDownList;
  FCbCellVAlign.Items.Add('Inherit');
  FCbCellVAlign.Items.Add('Top');
  FCbCellVAlign.Items.Add('Middle');
  FCbCellVAlign.Items.Add('Bottom');
  FCbCellVAlign.OnChange := @FieldChanged;

  // ---- Column list ----
  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.OnClick := @ListClick;
end;

procedure TCssTreeColumnsEditorForm.LoadList;
var
  I, Sel: Integer;
  Col: TCssVirtualTreeColumn;
begin
  Sel := FList.ItemIndex;

  FUpdating := True;
  try
    FList.Items.BeginUpdate;
    try
      FList.Items.Clear;

      for I := 0 to FColumns.Count - 1 do
      begin
        Col := TCssVirtualTreeColumn(FColumns.Items[I]);
        FList.Items.Add(Format('%d: %s (w=%d)', [I, Col.Text, Col.Width]));
      end;
    finally
      FList.Items.EndUpdate;
    end;

    if FList.Items.Count > 0 then
    begin
      if (Sel < 0) or (Sel >= FList.Items.Count) then
        Sel := 0;
      FList.ItemIndex := Sel;
    end
    else
      FList.ItemIndex := -1;
  finally
    FUpdating := False;
  end;

  UpdateEditor;
end;

procedure TCssTreeColumnsEditorForm.UpdateEditor;
var
  Col: TCssVirtualTreeColumn;
begin
  Col := SelectedColumn;

  FUpdating := True;
  try
    if Col = nil then
    begin
      FEdText.Text := '';
      FEdWidth.Text := '';
      FCbHeaderHAlign.ItemIndex := 0;
      FCbHeaderVAlign.ItemIndex := 0;
      FCbCellHAlign.ItemIndex := 0;
      FCbCellVAlign.ItemIndex := 0;

      FEdText.Enabled := False;
      FEdWidth.Enabled := False;
      FCbHeaderHAlign.Enabled := False;
      FCbHeaderVAlign.Enabled := False;
      FCbCellHAlign.Enabled := False;
      FCbCellVAlign.Enabled := False;

      FBtnDelete.Enabled := False;
      FBtnUp.Enabled := False;
      FBtnDown.Enabled := False;
    end
    else
    begin
      FEdText.Text := Col.Text;
      FEdWidth.Text := IntToStr(Col.Width);
      FCbHeaderHAlign.ItemIndex := Ord(Col.HeaderHAlign);
      FCbHeaderVAlign.ItemIndex := Ord(Col.HeaderVAlign);
      FCbCellHAlign.ItemIndex := Ord(Col.CellHAlign);
      FCbCellVAlign.ItemIndex := Ord(Col.CellVAlign);

      FEdText.Enabled := True;
      FEdWidth.Enabled := True;
      FCbHeaderHAlign.Enabled := True;
      FCbHeaderVAlign.Enabled := True;
      FCbCellHAlign.Enabled := True;
      FCbCellVAlign.Enabled := True;

      FBtnDelete.Enabled := True;
      FBtnUp.Enabled := FList.ItemIndex > 0;
      FBtnDown.Enabled := FList.ItemIndex < FColumns.Count - 1;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TCssTreeColumnsEditorForm.ApplyToColumn;
var
  Col: TCssVirtualTreeColumn;
  W, Idx: Integer;
begin
  if FUpdating then
    Exit;

  Col := SelectedColumn;
  if Col = nil then
    Exit;

  Idx := FList.ItemIndex;

  Col.Text := FEdText.Text;

  if TryStrToInt(FEdWidth.Text, W) and (W >= 0) then
    Col.Width := W;

  Col.HeaderHAlign := TCssTreeHAlign(FCbHeaderHAlign.ItemIndex);
  Col.HeaderVAlign := TCssTreeVAlign(FCbHeaderVAlign.ItemIndex);
  Col.CellHAlign := TCssTreeHAlign(FCbCellHAlign.ItemIndex);
  Col.CellVAlign := TCssTreeVAlign(FCbCellVAlign.ItemIndex);

  FUpdating := True;
  try
    if (Idx >= 0) and (Idx < FList.Items.Count) then
      FList.Items[Idx] := Format('%d: %s (w=%d)', [Idx, Col.Text, Col.Width]);
  finally
    FUpdating := False;
  end;

  NotifyChanged;
end;

function TCssTreeColumnsEditorForm.SelectedColumn: TCssVirtualTreeColumn;
begin
  if (FList.ItemIndex >= 0) and (FList.ItemIndex < FColumns.Count) then
    Result := TCssVirtualTreeColumn(FColumns.Items[FList.ItemIndex])
  else
    Result := nil;
end;

procedure TCssTreeColumnsEditorForm.SelectColumn(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FList.Items.Count) then
    FList.ItemIndex := AIndex;

  UpdateEditor;
end;

procedure TCssTreeColumnsEditorForm.NotifyChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TCssTreeColumnsEditorForm.ListClick(Sender: TObject);
begin
  if FUpdating then
    Exit;

  UpdateEditor;
end;

procedure TCssTreeColumnsEditorForm.FieldChanged(Sender: TObject);
begin
  ApplyToColumn;
end;

procedure TCssTreeColumnsEditorForm.BtnAddClick(Sender: TObject);
var
  Col: TCssVirtualTreeColumn;
begin
  Col := FColumns.Add;
  Col.Text := 'Column ' + IntToStr(FColumns.Count);
  Col.Width := 100;

  LoadList;
  SelectColumn(FColumns.Count - 1);
  NotifyChanged;
end;

procedure TCssTreeColumnsEditorForm.BtnDeleteClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := FList.ItemIndex;

  if (Idx < 0) or (Idx >= FColumns.Count) then
    Exit;

  FColumns.Delete(Idx);

  LoadList;

  if FList.Items.Count > 0 then
  begin
    if Idx >= FList.Items.Count then
      SelectColumn(FList.Items.Count - 1)
    else
      SelectColumn(Idx);
  end
  else
    UpdateEditor;

  NotifyChanged;
end;

procedure TCssTreeColumnsEditorForm.BtnUpClick(Sender: TObject);
var
  Idx: Integer;
  Col: TCollectionItem;
begin
  Idx := FList.ItemIndex;
  if Idx <= 0 then
    Exit;

  Col := FColumns.Items[Idx];
  Col.Index := Idx - 1;

  LoadList;
  SelectColumn(Idx - 1);
  NotifyChanged;
end;

procedure TCssTreeColumnsEditorForm.BtnDownClick(Sender: TObject);
var
  Idx: Integer;
  Col: TCollectionItem;
begin
  Idx := FList.ItemIndex;
  if (Idx < 0) or (Idx >= FColumns.Count - 1) then
    Exit;

  Col := FColumns.Items[Idx];
  Col.Index := Idx + 1;

  LoadList;
  SelectColumn(Idx + 1);
  NotifyChanged;
end;

{ ============================================================ }
{ Property editor                                              }
{ ============================================================ }

procedure TCssTreeColumnsPropertyEditor.Edit;
var
  Tree: TCssVirtualStringTree;
  Dlg: TCssTreeColumnsEditorForm;
begin
  if not (GetComponent(0) is TCssVirtualStringTree) then
    Exit;

  Tree := TCssVirtualStringTree(GetComponent(0));

  Dlg := TCssTreeColumnsEditorForm.CreateEditor(nil, Tree.Columns);
  try
    Dlg.OnChanged := @DialogChanged;
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;

  // Final notification to the IDE that the property value has changed.
  Modified;
end;

procedure TCssTreeColumnsPropertyEditor.DialogChanged(Sender: TObject);
begin
  // Live update: every change in the dialog is applied to the collection
  // immediately (which in turn triggers Update on the tree). We also
  // notify the IDE so it marks the form as modified.
  Modified;
end;

function TCssTreeColumnsPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  // paReadOnly — disallow inline editing in the Object Inspector;
  // paDialog    — show the "..." button that opens the dialog.
  Result := [paReadOnly, paDialog];
end;

function TCssTreeColumnsPropertyEditor.GetValue: string;
var
  Tree: TCssVirtualStringTree;
begin
  Tree := nil;

  try
    if GetComponent(0) is TCssVirtualStringTree then
      Tree := TCssVirtualStringTree(GetComponent(0));
  except
    // No components are being edited — nothing to display.
    Tree := nil;
  end;

  if Tree <> nil then
    Result := Format('(%d columns)', [Tree.Columns.Count])
  else
    Result := inherited GetValue;
end;

{ ============================================================ }
{ Registration                                                 }
{ ============================================================ }

procedure RegisterCssTreeColumnsEditor;
begin
  RegisterPropertyEditor(
    TypeInfo(TCssVirtualTreeColumns),
    TCssVirtualStringTree,
    'Columns',
    TCssTreeColumnsPropertyEditor
  );
end;

initialization
  RegisterCssTreeColumnsEditor;

end.
