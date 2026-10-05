unit CssSvgImgListDesign;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, PropEdits, ComponentEditors,
  Controls, Forms, StdCtrls, Graphics, Dialogs, LCLType,
  CssSvgImgList;

type
  { Expose Svg in the Object Inspector as a read-only short description. }
  TCssSvgTextProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

  { Opens our custom collection editor with thumbnails. }
  TCssSvgItemsProperty = class(TCollectionPropertyEditor)
  public
    procedure Edit; override;
  end;

  { Context-menu verb "Load SVG from file...". }
  TCssSvgImgListEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

procedure Register;

implementation

const
  SVG_THUMB_SIZE   = 32;
  SVG_THUMB_MARGIN = 6;

type
  TCssSvgBackupItem = record
    Name: string;
    Svg: string;
  end;

  TCssSvgCollectionForm = class(TForm)
  private
    FCollection: TCollection;
    FListBox: TListBox;
    FNameLabel: TLabel;
    FNameEdit: TEdit;
    FInfoLabel: TLabel;
    FBtnAdd: TButton;
    FBtnLoad: TButton;
    FBtnDelete: TButton;
    FBtnUp: TButton;
    FBtnDown: TButton;
    FBtnOK: TButton;
    FBtnCancel: TButton;
    FThumbs: array of TBitmap;
    FBackup: array of TCssSvgBackupItem;
    FUpdating: Boolean;
    procedure BuildUI;
    procedure SetCollection(AValue: TCollection);
    procedure SaveBackup;
    procedure ClearThumbs;
    procedure RebuildThumbs;
    procedure RefreshList(AKeepIndex: Integer = -1);
    procedure RefreshInfo;
    procedure UpdateButtons;
    procedure DoDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure DoListClick(Sender: TObject);
    procedure DoAdd(Sender: TObject);
    procedure DoLoad(Sender: TObject);
    procedure DoDelete(Sender: TObject);
    procedure DoUp(Sender: TObject);
    procedure DoDown(Sender: TObject);
    procedure DoNameChange(Sender: TObject);
    function  SelIndex: Integer;
    function  ItemAt(AIndex: Integer): TCssSvgImgListItem;
    procedure LoadSvgFiles(const AFiles: TStrings);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    destructor  Destroy; override;
    procedure RestoreBackup;
    property Collection: TCollection read FCollection write SetCollection;
  end;

{ ----------------------------- helper routines ----------------------------- }

function StripExt(const AFileName: string): string;
var
  E: string;
begin
  Result := ExtractFileName(AFileName);
  E := ExtractFileExt(Result);
  if E <> '' then
    Result := Copy(Result, 1, Length(Result) - Length(E));
end;

function NameExistsInCollection(ACollection: TCollection;
  const AName: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to ACollection.Count - 1 do
    if SameText(TCssSvgImgListItem(ACollection.Items[I]).Name, AName) then
      Exit(True);
  Result := False;
end;

function MakeUniqueName(ACollection: TCollection;
  const ABase: string): string;
var
  N: Integer;
  Base, Candidate: string;
begin
  Base := ABase;
  if Base = '' then Base := 'Image';
  Candidate := Base;
  N := 0;
  while NameExistsInCollection(ACollection, Candidate) do
  begin
    Inc(N);
    Candidate := Base + IntToStr(N);
  end;
  Result := Candidate;
end;

{ ----------------------------- TCssSvgTextProperty ------------------------ }

function TCssSvgTextProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly];
end;

function TCssSvgTextProperty.GetValue: string;
var
  S: string;
begin
  S := GetStrValue;
  if S = '' then
    Result := '(empty)'
  else
    Result := Format('<SVG data: %d bytes>', [Length(S)]);
end;

{ ----------------------------- TCssSvgItemsProperty ----------------------- }

procedure TCssSvgItemsProperty.Edit;
var
  Col: TCollection;
  F: TCssSvgCollectionForm;
begin
  Col := TCollection(GetObjectValue);
  if Col = nil then Exit;
  F := TCssSvgCollectionForm.CreateNew(nil);
  try
    F.Collection := Col;
    if F.ShowModal = mrOk then
      Modified
    else
      F.RestoreBackup;
  finally
    F.Free;
  end;
end;

{ ----------------------------- TCssSvgImgListEditor ----------------------- }

function TCssSvgImgListEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TCssSvgImgListEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := 'Load SVG from file...'
  else
    Result := inherited GetVerb(Index);
end;

procedure TCssSvgImgListEditor.ExecuteVerb(Index: Integer);
var
  List: TCssSvgImgList;
  Dlg: TOpenDialog;
  L: TStringList;
  I: Integer;
  Item: TCssSvgImgListItem;
  BaseName: string;
begin
  if not (Component is TCssSvgImgList) then
  begin
    inherited ExecuteVerb(Index);
    Exit;
  end;
  List := TCssSvgImgList(Component);

  if Index = 0 then
  begin
    Dlg := TOpenDialog.Create(nil);
    L := TStringList.Create;
    try
      Dlg.Title := 'Load SVG file(s)';
      Dlg.Filter := 'SVG files (*.svg)|*.svg|All files (*.*)|*.*';
      Dlg.Options := Dlg.Options +
        [ofFileMustExist, ofAllowMultiSelect, ofPathMustExist];
      if not Dlg.Execute then Exit;

      for I := 0 to Dlg.Files.Count - 1 do
      begin
        L.Clear;
        try
          L.LoadFromFile(Dlg.Files[I]);
        except
          on E: Exception do
          begin
            MessageDlg('Failed to load ' + Dlg.Files[I] + #13#10 + E.Message,
              mtError, [mbOK], 0);
            Continue;
          end;
        end;

        BaseName := StripExt(Dlg.Files[I]);
        Item := List.Items.Add;
        Item.Name := MakeUniqueName(List.Items, BaseName);
        Item.Svg := L.Text;
      end;

      if Assigned(Designer) then
        Designer.Modified;
    finally
      L.Free;
      Dlg.Free;
    end;
  end
  else
    inherited ExecuteVerb(Index);
end;

{ ----------------------------- TCssSvgCollectionForm ---------------------- }

constructor TCssSvgCollectionForm.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  BuildUI;
end;

destructor TCssSvgCollectionForm.Destroy;
begin
  ClearThumbs;
  inherited Destroy;
end;

procedure TCssSvgCollectionForm.BuildUI;
const
  MARGIN  = 8;
  BTN_H   = 28;
  BTN_GAP = 6;
  LIST_W  = 380;
begin
  Caption := 'SVG Image List';
  Width := 720;
  Height := 480;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 360;

  FListBox := TListBox.Create(Self);
  FListBox.Parent := Self;
  FListBox.SetBounds(MARGIN, MARGIN, LIST_W,
    Height - 3 * MARGIN - BTN_H - 20);
  FListBox.Anchors := [akLeft, akTop, akBottom];
  FListBox.Style := lbOwnerDrawFixed;
  FListBox.ItemHeight := SVG_THUMB_SIZE + 10;
  FListBox.OnDrawItem := @DoDrawItem;
  FListBox.OnClick := @DoListClick;

  FNameLabel := TLabel.Create(Self);
  FNameLabel.Parent := Self;
  FNameLabel.Caption := 'Name:';
  FNameLabel.SetBounds(MARGIN + LIST_W + MARGIN, MARGIN + 4, 50, 20);
  FNameLabel.Anchors := [akTop, akRight];

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.SetBounds(MARGIN + LIST_W + MARGIN + 50, MARGIN, 200, 24);
  FNameEdit.Anchors := [akTop, akRight];
  FNameEdit.OnChange := @DoNameChange;

  FInfoLabel := TLabel.Create(Self);
  FInfoLabel.Parent := Self;
  FInfoLabel.SetBounds(MARGIN + LIST_W + MARGIN, MARGIN + 36, 220, 200);
  FInfoLabel.Anchors := [akTop, akRight];
  FInfoLabel.AutoSize := False;
  FInfoLabel.WordWrap := True;
  FInfoLabel.Caption := '';

  FBtnAdd := TButton.Create(Self);
  FBtnAdd.Parent := Self;
  FBtnAdd.Caption := 'Add empty';
  FBtnAdd.SetBounds(MARGIN, Height - MARGIN - BTN_H, 90, BTN_H);
  FBtnAdd.Anchors := [akLeft, akBottom];
  FBtnAdd.OnClick := @DoAdd;

  FBtnLoad := TButton.Create(Self);
  FBtnLoad.Parent := Self;
  FBtnLoad.Caption := 'Load from file...';
  FBtnLoad.SetBounds(FBtnAdd.Left + FBtnAdd.Width + BTN_GAP,
    FBtnAdd.Top, 130, BTN_H);
  FBtnLoad.Anchors := [akLeft, akBottom];
  FBtnLoad.OnClick := @DoLoad;

  FBtnDelete := TButton.Create(Self);
  FBtnDelete.Parent := Self;
  FBtnDelete.Caption := 'Delete';
  FBtnDelete.SetBounds(FBtnLoad.Left + FBtnLoad.Width + BTN_GAP,
    FBtnAdd.Top, 80, BTN_H);
  FBtnDelete.Anchors := [akLeft, akBottom];
  FBtnDelete.OnClick := @DoDelete;

  FBtnUp := TButton.Create(Self);
  FBtnUp.Parent := Self;
  FBtnUp.Caption := 'Up';
  FBtnUp.SetBounds(FBtnDelete.Left + FBtnDelete.Width + BTN_GAP,
    FBtnAdd.Top, 50, BTN_H);
  FBtnUp.Anchors := [akLeft, akBottom];
  FBtnUp.OnClick := @DoUp;

  FBtnDown := TButton.Create(Self);
  FBtnDown.Parent := Self;
  FBtnDown.Caption := 'Down';
  FBtnDown.SetBounds(FBtnUp.Left + FBtnUp.Width + BTN_GAP,
    FBtnAdd.Top, 50, BTN_H);
  FBtnDown.Anchors := [akLeft, akBottom];
  FBtnDown.OnClick := @DoDown;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.SetBounds(Width - MARGIN - 90, FBtnAdd.Top, 90, BTN_H);
  FBtnCancel.Anchors := [akRight, akBottom];
  FBtnCancel.Cancel := True;

  FBtnOK := TButton.Create(Self);
  FBtnOK.Parent := Self;
  FBtnOK.Caption := 'OK';
  FBtnOK.ModalResult := mrOk;
  FBtnOK.SetBounds(FBtnCancel.Left - BTN_GAP - 90, FBtnAdd.Top, 90, BTN_H);
  FBtnOK.Anchors := [akRight, akBottom];
  FBtnOK.Default := True;
end;

procedure TCssSvgCollectionForm.SetCollection(AValue: TCollection);
begin
  FCollection := AValue;
  SaveBackup;
  RefreshList;
end;

procedure TCssSvgCollectionForm.SaveBackup;
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  SetLength(FBackup, FCollection.Count);
  for I := 0 to FCollection.Count - 1 do
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    FBackup[I].Name := Item.Name;
    FBackup[I].Svg  := Item.Svg;
  end;
end;

procedure TCssSvgCollectionForm.RestoreBackup;
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  if FCollection = nil then Exit;
  FCollection.BeginUpdate;
  try
    FCollection.Clear;
    for I := 0 to High(FBackup) do
    begin
      Item := TCssSvgImgListItem(FCollection.Add);
      Item.Name := FBackup[I].Name;
      Item.Svg  := FBackup[I].Svg;
    end;
  finally
    FCollection.EndUpdate;
  end;
  RefreshList;
end;

procedure TCssSvgCollectionForm.ClearThumbs;
var
  I: Integer;
begin
  for I := 0 to High(FThumbs) do
    FThumbs[I].Free;
  SetLength(FThumbs, 0);
end;

procedure TCssSvgCollectionForm.RebuildThumbs;
var
  I: Integer;
  Item: TCssSvgImgListItem;
  Bmp: TBitmap;
begin
  ClearThumbs;
  SetLength(FThumbs, FCollection.Count);
  for I := 0 to FCollection.Count - 1 do
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    Bmp := TBitmap.Create;
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(SVG_THUMB_SIZE, SVG_THUMB_SIZE);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.FillRect(0, 0, SVG_THUMB_SIZE, SVG_THUMB_SIZE);
    if Trim(Item.Svg) <> '' then
    begin
      try
        Item.Image.RenderToCanvas(Bmp.Canvas, 0, 0,
          SVG_THUMB_SIZE, SVG_THUMB_SIZE);
      except
        // Invalid SVG - just leave the thumbnail blank.
      end;
    end;
    FThumbs[I] := Bmp;
  end;
end;

procedure TCssSvgCollectionForm.RefreshList(AKeepIndex: Integer);
var
  I, NewIndex: Integer;
  Item: TCssSvgImgListItem;
begin
  if AKeepIndex < 0 then
    NewIndex := FListBox.ItemIndex
  else
    NewIndex := AKeepIndex;

  FListBox.Items.BeginUpdate;
  try
    FListBox.Items.Clear;
    for I := 0 to FCollection.Count - 1 do
    begin
      Item := TCssSvgImgListItem(FCollection.Items[I]);
      FListBox.Items.Add(Item.Name);
    end;
  finally
    FListBox.Items.EndUpdate;
  end;

  RebuildThumbs;

  if NewIndex >= FListBox.Items.Count then
    NewIndex := FListBox.Items.Count - 1;
  if NewIndex < 0 then
    NewIndex := -1;
  FListBox.ItemIndex := NewIndex;

  RefreshInfo;
  UpdateButtons;
  FListBox.Invalidate;
end;

procedure TCssSvgCollectionForm.RefreshInfo;
var
  Item: TCssSvgImgListItem;
  I: Integer;
begin
  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then
  begin
    FUpdating := True;
    try
      FNameEdit.Text := '';
    finally
      FUpdating := False;
    end;
    FInfoLabel.Caption := 'No item selected.';
    Exit;
  end;

  Item := TCssSvgImgListItem(FCollection.Items[I]);
  FUpdating := True;
  try
    FNameEdit.Text := Item.Name;
  finally
    FUpdating := False;
  end;

  if Item.Svg = '' then
    FInfoLabel.Caption := 'SVG data: (empty)'
  else
    FInfoLabel.Caption := Format('SVG data: %d bytes', [Length(Item.Svg)]);
end;

procedure TCssSvgCollectionForm.UpdateButtons;
var
  I: Integer;
  HasSel, CanUp, CanDown: Boolean;
begin
  I := SelIndex;
  HasSel  := (I >= 0) and (I < FCollection.Count);
  CanUp   := HasSel and (I > 0);
  CanDown := HasSel and (I < FCollection.Count - 1);

  FBtnDelete.Enabled := HasSel;
  FBtnUp.Enabled     := CanUp;
  FBtnDown.Enabled   := CanDown;
  FNameEdit.Enabled  := HasSel;
end;

procedure TCssSvgCollectionForm.DoDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  LB: TListBox;
  BgColor, FgColor: TColor;
  Item: TCssSvgImgListItem;
  TextX, TextY: Integer;
begin
  LB := TListBox(Control);

  if odSelected in State then
  begin
    BgColor := clHighlight;
    FgColor := clHighlightText;
  end
  else
  begin
    BgColor := clWindow;
    FgColor := clWindowText;
  end;

  LB.Canvas.Brush.Color := BgColor;
  LB.Canvas.Brush.Style := bsSolid;
  LB.Canvas.FillRect(Rect);

  if (Index < 0) or (Index >= LB.Items.Count) then Exit;

  if (Index < Length(FThumbs)) and (FThumbs[Index] <> nil) then
    LB.Canvas.Draw(
      Rect.Left + SVG_THUMB_MARGIN,
      Rect.Top + (Rect.Height - SVG_THUMB_SIZE) div 2,
      FThumbs[Index]);

  Item := ItemAt(Index);
  if Item <> nil then
  begin
    LB.Canvas.Font.Color := FgColor;
    TextX := Rect.Left + SVG_THUMB_SIZE + 2 * SVG_THUMB_MARGIN;
    TextY := Rect.Top + (Rect.Height - LB.Canvas.TextHeight('Ag')) div 2;
    LB.Canvas.TextOut(TextX, TextY, Item.Name);
  end;
end;

procedure TCssSvgCollectionForm.DoListClick(Sender: TObject);
begin
  RefreshInfo;
  UpdateButtons;
end;

procedure TCssSvgCollectionForm.DoAdd(Sender: TObject);
var
  Item: TCssSvgImgListItem;
begin
  Item := TCssSvgImgListItem(FCollection.Add);
  Item.Name := MakeUniqueName(FCollection, 'Image');
  Item.Svg  := '';
  RefreshList(Item.Index);
end;

procedure TCssSvgCollectionForm.DoLoad(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Load SVG file(s)';
    Dlg.Filter := 'SVG files (*.svg)|*.svg|All files (*.*)|*.*';
    Dlg.Options := Dlg.Options +
      [ofFileMustExist, ofAllowMultiSelect, ofPathMustExist];
    if Dlg.Execute then
      LoadSvgFiles(Dlg.Files);
  finally
    Dlg.Free;
  end;
end;

procedure TCssSvgCollectionForm.LoadSvgFiles(const AFiles: TStrings);
var
  I, LastIndex: Integer;
  L: TStringList;
  Item: TCssSvgImgListItem;
  BaseName: string;
begin
  L := TStringList.Create;
  try
    LastIndex := -1;
    for I := 0 to AFiles.Count - 1 do
    begin
      L.Clear;
      try
        L.LoadFromFile(AFiles[I]);
      except
        on E: Exception do
        begin
          MessageDlg('Failed to load ' + AFiles[I] + #13#10 + E.Message,
            mtError, [mbOK], 0);
          Continue;
        end;
      end;

      BaseName := StripExt(AFiles[I]);
      Item := TCssSvgImgListItem(FCollection.Add);
      Item.Name := MakeUniqueName(FCollection, BaseName);
      Item.Svg  := L.Text;
      LastIndex := Item.Index;
    end;

    if LastIndex >= 0 then
      RefreshList(LastIndex)
    else
      RefreshList;
  finally
    L.Free;
  end;
end;

procedure TCssSvgCollectionForm.DoDelete(Sender: TObject);
var
  I: Integer;
begin
  I := SelIndex;
  if (I >= 0) and (I < FCollection.Count) then
  begin
    FCollection.Delete(I);
    if I >= FCollection.Count then
      I := FCollection.Count - 1;
    RefreshList(I);
  end;
end;

procedure TCssSvgCollectionForm.DoUp(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  I := SelIndex;
  if (I > 0) and (I < FCollection.Count) then
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    Item.Index := I - 1;
    RefreshList(I - 1);
  end;
end;

procedure TCssSvgCollectionForm.DoDown(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  I := SelIndex;
  if (I >= 0) and (I < FCollection.Count - 1) then
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    Item.Index := I + 1;
    RefreshList(I + 1);
  end;
end;

procedure TCssSvgCollectionForm.DoNameChange(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  if FUpdating then Exit;
  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then Exit;
  Item := TCssSvgImgListItem(FCollection.Items[I]);
  if Item.Name <> FNameEdit.Text then
  begin
    Item.Name := FNameEdit.Text;
    FUpdating := True;
    try
      FListBox.Items[I] := Item.Name;
    finally
      FUpdating := False;
    end;
    FListBox.Invalidate;
  end;
end;

function TCssSvgCollectionForm.SelIndex: Integer;
begin
  Result := FListBox.ItemIndex;
end;

function TCssSvgCollectionForm.ItemAt(AIndex: Integer): TCssSvgImgListItem;
begin
  if (AIndex >= 0) and (AIndex < FCollection.Count) then
    Result := TCssSvgImgListItem(FCollection.Items[AIndex])
  else
    Result := nil;
end;

{ ----------------------------- Registration -------------------------------- }

procedure Register;
begin
  // 1) Svg in the Object Inspector - read-only with a short summary.
  RegisterPropertyEditor(
    TypeInfo(string),
    TCssSvgImgListItem,
    'Svg',
    TCssSvgTextProperty);

  // 2) The Items property of TCssSvgImgList - opens our editor with thumbnails.
  RegisterPropertyEditor(
    TypeInfo(TCssSvgImgListItems),
    TCssSvgImgList,
    'Items',
    TCssSvgItemsProperty);

  // 3) The component's context menu in the designer.
  RegisterComponentEditor(
    TCssSvgImgList,
    TCssSvgImgListEditor);
end;

end.