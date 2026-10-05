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
  BASE_VARIANT_TAG = '(base)';

type
  TCssSvgBackupItem = record
    Name: string;
    Svg: string;
    Variants: TStringList;
  end;

  TCssSvgCollectionForm = class(TForm)
  private
    FCollection: TCollection;

    FListBox: TListBox;

    FNameLabel: TLabel;
    FNameEdit: TEdit;

    FVariantLabel: TLabel;
    FVariantCombo: TComboBox;
    FVariantAddBtn: TButton;
    FVariantDelBtn: TButton;
    FVariantLoadBtn: TButton;

    FSvgLabel: TLabel;
    FSvgMemo: TMemo;
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
    FCurrentVariant: string;

    procedure BuildUI;
    procedure SetCollection(AValue: TCollection);

    procedure SaveBackup;
    procedure ClearBackup;

    procedure ClearThumbs;
    procedure RebuildThumbs;
    procedure RebuildThumb(AIndex: Integer);

    procedure RefreshList(AKeepIndex: Integer = -1);
    procedure RefreshInfo;
    procedure RefreshVariantsCombo;
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
    procedure DoVariantChanged(Sender: TObject);
    procedure DoVariantAdd(Sender: TObject);
    procedure DoVariantDelete(Sender: TObject);
    procedure DoVariantLoad(Sender: TObject);
    procedure DoSvgMemoChange(Sender: TObject);

    function  SelIndex: Integer;
    function  ItemAt(AIndex: Integer): TCssSvgImgListItem;
    function  CurrentVariantLabel: string;
    function  EffectiveSvgOf(Item: TCssSvgImgListItem): string;
    procedure SetEffectiveSvgOf(Item: TCssSvgImgListItem; const V: string);
    function  ItemHasCurrentVariant(Item: TCssSvgImgListItem): Boolean;

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
  VarName: string;
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

      VarName := List.DefaultVariant;

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

        if VarName = '' then
          Item.Svg := L.Text
        else
          Item.Variants.Values[VarName] := L.Text;
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
  ClearBackup;
  inherited Destroy;
end;

procedure TCssSvgCollectionForm.BuildUI;
const
  MARGIN  = 8;
  BTN_H   = 28;
  BTN_GAP = 6;
  LIST_W  = 380;
  RIGHT_X = 396;
  ROW_H   = 24;
  LBL_W   = 55;
  VBTN_W  = 85;
begin
  Caption := 'SVG Image List';
  Width := 980;
  Height := 560;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Constraints.MinWidth := 840;
  Constraints.MinHeight := 460;

  { ---------------- List ---------------- }

  FListBox := TListBox.Create(Self);
  FListBox.Parent := Self;
  FListBox.SetBounds(MARGIN, MARGIN, LIST_W,
    Height - 3 * MARGIN - BTN_H - 20);
  FListBox.Anchors := [akLeft, akTop, akBottom];
  FListBox.Style := lbOwnerDrawFixed;
  FListBox.ItemHeight := SVG_THUMB_SIZE + 10;
  FListBox.OnDrawItem := @DoDrawItem;
  FListBox.OnClick := @DoListClick;

  { ---------------- Name row ---------------- }

  FNameLabel := TLabel.Create(Self);
  FNameLabel.Parent := Self;
  FNameLabel.Caption := 'Name:';
  FNameLabel.SetBounds(RIGHT_X, MARGIN + 4, LBL_W, 20);
  FNameLabel.Anchors := [akTop, akRight];

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.SetBounds(RIGHT_X + LBL_W, MARGIN,
    Width - (RIGHT_X + LBL_W) - MARGIN, ROW_H);
  FNameEdit.Anchors := [akTop, akRight];
  FNameEdit.OnChange := @DoNameChange;

  { ---------------- Variant row ---------------- }

  FVariantLabel := TLabel.Create(Self);
  FVariantLabel.Parent := Self;
  FVariantLabel.Caption := 'Variant:';
  FVariantLabel.SetBounds(RIGHT_X, MARGIN + ROW_H + 8, LBL_W, 20);
  FVariantLabel.Anchors := [akTop, akRight];

  FVariantCombo := TComboBox.Create(Self);
  FVariantCombo.Parent := Self;
  FVariantCombo.Style := csDropDownList;
  FVariantCombo.SetBounds(RIGHT_X + LBL_W, MARGIN + ROW_H + 4, 160, ROW_H);
  FVariantCombo.Anchors := [akTop, akRight];
  FVariantCombo.OnChange := @DoVariantChanged;

  FVariantAddBtn := TButton.Create(Self);
  FVariantAddBtn.Parent := Self;
  FVariantAddBtn.Caption := '+ Variant';
  FVariantAddBtn.SetBounds(FVariantCombo.Left + FVariantCombo.Width + BTN_GAP,
    FVariantCombo.Top, VBTN_W, ROW_H);
  FVariantAddBtn.Anchors := [akTop, akRight];
  FVariantAddBtn.OnClick := @DoVariantAdd;

  FVariantDelBtn := TButton.Create(Self);
  FVariantDelBtn.Parent := Self;
  FVariantDelBtn.Caption := 'Remove';
  FVariantDelBtn.SetBounds(FVariantAddBtn.Left + FVariantAddBtn.Width + BTN_GAP,
    FVariantCombo.Top, VBTN_W, ROW_H);
  FVariantDelBtn.Anchors := [akTop, akRight];
  FVariantDelBtn.OnClick := @DoVariantDelete;

  FVariantLoadBtn := TButton.Create(Self);
  FVariantLoadBtn.Parent := Self;
  FVariantLoadBtn.Caption := 'Load SVG...';
  FVariantLoadBtn.SetBounds(FVariantDelBtn.Left + FVariantDelBtn.Width + BTN_GAP,
    FVariantCombo.Top, VBTN_W, ROW_H);
  FVariantLoadBtn.Anchors := [akTop, akRight];
  FVariantLoadBtn.OnClick := @DoVariantLoad;

  { ---------------- SVG memo ---------------- }

  FSvgLabel := TLabel.Create(Self);
  FSvgLabel.Parent := Self;
  FSvgLabel.Caption := 'SVG text (editable):';
  FSvgLabel.SetBounds(RIGHT_X, FVariantCombo.Top + ROW_H + 8, 200, 20);
  FSvgLabel.Anchors := [akTop, akRight];

  FSvgMemo := TMemo.Create(Self);
  FSvgMemo.Parent := Self;
  FSvgMemo.SetBounds(RIGHT_X, FSvgLabel.Top + 20,
    Width - RIGHT_X - MARGIN, 240);
  FSvgMemo.Anchors := [akTop, akRight, akBottom];
  FSvgMemo.ScrollBars := ssBoth;
  FSvgMemo.WordWrap := False;
  FSvgMemo.WantTabs := True;
  FSvgMemo.Font.Name := 'Courier New';
  FSvgMemo.Font.Size := 9;
  FSvgMemo.OnChange := @DoSvgMemoChange;

  FInfoLabel := TLabel.Create(Self);
  FInfoLabel.Parent := Self;
  FInfoLabel.SetBounds(RIGHT_X, FSvgMemo.Top + FSvgMemo.Height + 6,
    Width - RIGHT_X - MARGIN, 60);
  FInfoLabel.Anchors := [akRight, akBottom];
  FInfoLabel.AutoSize := False;
  FInfoLabel.WordWrap := True;
  FInfoLabel.Caption := '';

  { ---------------- Bottom buttons ---------------- }

  FBtnAdd := TButton.Create(Self);
  FBtnAdd.Parent := Self;
  FBtnAdd.Caption := 'Add empty';
  FBtnAdd.SetBounds(MARGIN, Height - MARGIN - BTN_H, 90, BTN_H);
  FBtnAdd.Anchors := [akLeft, akBottom];
  FBtnAdd.OnClick := @DoAdd;

  FBtnLoad := TButton.Create(Self);
  FBtnLoad.Parent := Self;
  FBtnLoad.Caption := 'Add items from file...';
  FBtnLoad.SetBounds(FBtnAdd.Left + FBtnAdd.Width + BTN_GAP,
    FBtnAdd.Top, 170, BTN_H);
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
  FCurrentVariant := '';
  SaveBackup;
  RefreshVariantsCombo;
  RefreshList;
end;

procedure TCssSvgCollectionForm.SaveBackup;
var
  I: Integer;
  Item: TCssSvgImgListItem;
begin
  ClearBackup;
  SetLength(FBackup, FCollection.Count);
  for I := 0 to FCollection.Count - 1 do
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    FBackup[I].Name := Item.Name;
    FBackup[I].Svg  := Item.Svg;
    FBackup[I].Variants := TStringList.Create;
    FBackup[I].Variants.Assign(Item.Variants);
  end;
end;

procedure TCssSvgCollectionForm.ClearBackup;
var
  I: Integer;
begin
  for I := 0 to High(FBackup) do
    FreeAndNil(FBackup[I].Variants);
  SetLength(FBackup, 0);
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
      if FBackup[I].Variants <> nil then
        Item.Variants.Assign(FBackup[I].Variants);
    end;
  finally
    FCollection.EndUpdate;
  end;
  FCurrentVariant := '';
  RefreshVariantsCombo;
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

procedure TCssSvgCollectionForm.RebuildThumb(AIndex: Integer);
var
  Item: TCssSvgImgListItem;
  Bmp: TBitmap;
  SvgText: string;
begin
  if (AIndex < 0) or (AIndex >= FCollection.Count) then Exit;
  if (AIndex >= Length(FThumbs)) then Exit;

  Item := TCssSvgImgListItem(FCollection.Items[AIndex]);
  SvgText := EffectiveSvgOf(Item);

  if FThumbs[AIndex] = nil then
    FThumbs[AIndex] := TBitmap.Create;

  Bmp := FThumbs[AIndex];
  Bmp.PixelFormat := pf24bit;
  Bmp.SetSize(SVG_THUMB_SIZE, SVG_THUMB_SIZE);
  Bmp.Canvas.Brush.Color := clWhite;
  Bmp.Canvas.Brush.Style := bsSolid;
  Bmp.Canvas.FillRect(0, 0, SVG_THUMB_SIZE, SVG_THUMB_SIZE);

  if Trim(SvgText) <> '' then
  begin
    try
      Item.GetImageForVariant(FCurrentVariant)
          .RenderToCanvas(Bmp.Canvas, 0, 0, SVG_THUMB_SIZE, SVG_THUMB_SIZE);
    except
      // Invalid SVG - leave the thumbnail blank.
    end;
  end;
end;

procedure TCssSvgCollectionForm.RebuildThumbs;
var
  I: Integer;
begin
  ClearThumbs;
  SetLength(FThumbs, FCollection.Count);
  for I := 0 to FCollection.Count - 1 do
  begin
    FThumbs[I] := nil;
    RebuildThumb(I);
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

function TCssSvgCollectionForm.CurrentVariantLabel: string;
begin
  if FCurrentVariant = '' then
    Result := 'base'
  else
    Result := FCurrentVariant;
end;

function TCssSvgCollectionForm.EffectiveSvgOf(
  Item: TCssSvgImgListItem): string;
begin
  Result := Item.EffectiveSvg(FCurrentVariant);
end;

procedure TCssSvgCollectionForm.SetEffectiveSvgOf(
  Item: TCssSvgImgListItem; const V: string);
begin
  if FCurrentVariant = '' then
    Item.Svg := V
  else
    Item.Variants.Values[FCurrentVariant] := V;
end;

function TCssSvgCollectionForm.ItemHasCurrentVariant(
  Item: TCssSvgImgListItem): Boolean;
begin
  if FCurrentVariant = '' then
    Result := True
  else
    Result := Item.Variants.IndexOfName(FCurrentVariant) >= 0;
end;

procedure TCssSvgCollectionForm.RefreshInfo;
var
  Item: TCssSvgImgListItem;
  I: Integer;
  SvgText: string;
  HasVar: Boolean;
  VariantHint: string;
begin
  I := SelIndex;

  if (I < 0) or (I >= FCollection.Count) then
  begin
    FUpdating := True;
    try
      FNameEdit.Text := '';
      FSvgMemo.Lines.Clear;
      FSvgMemo.Enabled := False;
      FSvgMemo.Color := clBtnFace;
    finally
      FUpdating := False;
    end;
    FInfoLabel.Caption := 'No item selected.';
    Exit;
  end;

  Item := TCssSvgImgListItem(FCollection.Items[I]);
  SvgText := EffectiveSvgOf(Item);
  HasVar := ItemHasCurrentVariant(Item);

  FUpdating := True;
  try
    FNameEdit.Text := Item.Name;
    FSvgMemo.Lines.Text := SvgText;

    FSvgMemo.Enabled := HasVar;
    if HasVar then
      FSvgMemo.Color := clWindow
    else
      FSvgMemo.Color := clBtnFace;
  finally
    FUpdating := False;
  end;

  if not HasVar then
    VariantHint := Format('variant "%s" not set on this item yet',
      [FCurrentVariant])
  else if SvgText = '' then
    VariantHint := '(empty)'
  else
    VariantHint := Format('%d bytes', [Length(SvgText)]);

  if FCurrentVariant = '' then
    FInfoLabel.Caption :=
      Format('SVG data (base): %s', [VariantHint])
  else
    FInfoLabel.Caption :=
      Format('SVG data (%s): %s', [FCurrentVariant, VariantHint]);

  if (FCurrentVariant <> '') and
     (Item.Variants.IndexOfName(FCurrentVariant) >= 0) and
     (Item.Variants.Values[FCurrentVariant] = '') then
    FInfoLabel.Caption := FInfoLabel.Caption + ' - variant is empty';
end;

procedure TCssSvgCollectionForm.RefreshVariantsCombo;
var
  Names: TStringList;
  I, J, Idx: Integer;
  Item: TCssSvgImgListItem;
  SavedVariant: string;
  Found: Boolean;
begin
  SavedVariant := FCurrentVariant;
  Found := (SavedVariant = '');

  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;

    for I := 0 to FCollection.Count - 1 do
    begin
      Item := TCssSvgImgListItem(FCollection.Items[I]);
      for J := 0 to Item.Variants.Count - 1 do
      begin
        if Trim(Item.Variants.Names[J]) <> '' then
          Names.Add(Item.Variants.Names[J]);
      end;
    end;

    FVariantCombo.Items.BeginUpdate;
    try
      FVariantCombo.Items.Clear;
      FVariantCombo.Items.Add(BASE_VARIANT_TAG);

      for I := 0 to Names.Count - 1 do
      begin
        FVariantCombo.Items.Add(Names[I]);
        if not Found and SameText(Names[I], SavedVariant) then
          Found := True;
      end;

      if not Found and (SavedVariant <> '') then
        FVariantCombo.Items.Add(SavedVariant);

      if SavedVariant = '' then
        FVariantCombo.ItemIndex := 0
      else
      begin
        Idx := FVariantCombo.Items.IndexOf(SavedVariant);
        if Idx < 0 then Idx := 0;
        FVariantCombo.ItemIndex := Idx;
      end;
    finally
      FVariantCombo.Items.EndUpdate;
    end;
  finally
    Names.Free;
  end;
end;

procedure TCssSvgCollectionForm.UpdateButtons;
var
  I: Integer;
  HasSel, HasVar: Boolean;
  Item: TCssSvgImgListItem;
begin
  I := SelIndex;
  HasSel := (I >= 0) and (I < FCollection.Count);

  FBtnDelete.Enabled := HasSel;
  FBtnUp.Enabled     := HasSel and (I > 0);
  FBtnDown.Enabled   := HasSel and (I < FCollection.Count - 1);
  FNameEdit.Enabled  := HasSel;

  HasVar := False;
  if HasSel then
  begin
    Item := TCssSvgImgListItem(FCollection.Items[I]);
    HasVar := ItemHasCurrentVariant(Item);
  end;

  // "+ Variant": available whenever an item is selected.
  FVariantAddBtn.Enabled := HasSel;

  // "Remove": only for a specific variant that exists on the selected item.
  FVariantDelBtn.Enabled := HasSel and (FCurrentVariant <> '') and HasVar;

  // "Load SVG...": base variant is always loadable; a specific variant
  // requires that the variant already exists on the item.
  FVariantLoadBtn.Enabled := HasSel and HasVar;
end;

procedure TCssSvgCollectionForm.DoDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  IDX_W = 32;   // width of the "[N]" column, in pixels
var
  LB: TListBox;
  BgColor, FgColor, IdxColor: TColor;
  Item: TCssSvgImgListItem;
  TextX, TextY, NameW: Integer;
  Suffix, IdxStr: string;
  J: Integer;
begin
  LB := TListBox(Control);

  if odSelected in State then
  begin
    BgColor := clHighlight;
    FgColor := clHighlightText;
    IdxColor := clHighlightText;
  end
  else
  begin
    BgColor := clWindow;
    FgColor := clWindowText;
    IdxColor := clGray;
  end;

  LB.Canvas.Brush.Color := BgColor;
  LB.Canvas.Brush.Style := bsSolid;
  LB.Canvas.FillRect(Rect);

  if (Index < 0) or (Index >= LB.Items.Count) then Exit;

  { Index column, drawn first, before the thumbnail. The value shown is
    the actual collection index of the item, so it can be typed directly
    into ImageIndex on any consumer (button, menu item, tab). }
  IdxStr := '[' + IntToStr(Index) + ']';
  LB.Canvas.Font.Color := IdxColor;
  TextY := Rect.Top + (Rect.Height - LB.Canvas.TextHeight('Ag')) div 2;
  LB.Canvas.TextOut(Rect.Left + SVG_THUMB_MARGIN, TextY, IdxStr);

  { Thumbnail column. }
  if (Index < Length(FThumbs)) and (FThumbs[Index] <> nil) then
    LB.Canvas.Draw(
      Rect.Left + IDX_W + SVG_THUMB_MARGIN,
      Rect.Top + (Rect.Height - SVG_THUMB_SIZE) div 2,
      FThumbs[Index]);

  Item := ItemAt(Index);
  if Item <> nil then
  begin
    Suffix := '';
    if Item.Variants.Count > 0 then
    begin
      for J := 0 to Item.Variants.Count - 1 do
      begin
        if J = 0 then
          Suffix := '  ['
        else
          Suffix := Suffix + ', ';
        Suffix := Suffix + Item.Variants.Names[J];
      end;
      Suffix := Suffix + ']';
    end;

    LB.Canvas.Font.Color := FgColor;
    TextX := Rect.Left + IDX_W + SVG_THUMB_SIZE + 2 * SVG_THUMB_MARGIN;

    LB.Canvas.TextOut(TextX, TextY, Item.Name);
    NameW := LB.Canvas.TextWidth(Item.Name);

    if Suffix <> '' then
    begin
      LB.Canvas.Font.Color := clGray;
      LB.Canvas.TextOut(TextX + NameW, TextY, Suffix);
    end;
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
  RefreshVariantsCombo;
  RefreshList(Item.Index);
end;

procedure TCssSvgCollectionForm.DoLoad(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Add SVG files as new items';
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
      Item.Svg := L.Text;
      LastIndex := Item.Index;
    end;

    RefreshVariantsCombo;

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
    RefreshVariantsCombo;
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

procedure TCssSvgCollectionForm.DoVariantChanged(Sender: TObject);
begin
  if FUpdating then Exit;

  if FVariantCombo.ItemIndex <= 0 then
    FCurrentVariant := ''
  else
    FCurrentVariant := FVariantCombo.Items[FVariantCombo.ItemIndex];

  RebuildThumbs;
  FListBox.Invalidate;
  RefreshInfo;
  UpdateButtons;
end;

procedure TCssSvgCollectionForm.DoVariantAdd(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
  NewName: string;
begin
  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then Exit;

  Item := TCssSvgImgListItem(FCollection.Items[I]);

  // Suggest a name: current variant (if specific), or "dark", or "light".
  if FCurrentVariant <> '' then
    NewName := FCurrentVariant
  else if Item.Variants.IndexOfName('dark') < 0 then
    NewName := 'dark'
  else if Item.Variants.IndexOfName('light') < 0 then
    NewName := 'light'
  else
    NewName := '';

  if not InputQuery('New variant',
    'Enter variant name (for example: "dark", "light"):', NewName) then
    Exit;

  NewName := Trim(NewName);
  if NewName = '' then Exit;

  if Item.Variants.IndexOfName(NewName) >= 0 then
  begin
    FCurrentVariant := NewName;
    RefreshVariantsCombo;
    RefreshInfo;
    UpdateButtons;
    Exit;
  end;

  // Seed the new variant with a copy of the base SVG, so the user has a
  // starting point instead of a blank editor.
  Item.Variants.Values[NewName] := Item.Svg;

  FCurrentVariant := NewName;
  RefreshVariantsCombo;
  RefreshInfo;
  UpdateButtons;
  RebuildThumb(I);
  FListBox.Invalidate;
end;

procedure TCssSvgCollectionForm.DoVariantDelete(Sender: TObject);
var
  I, Idx: Integer;
  Item: TCssSvgImgListItem;
begin
  if FCurrentVariant = '' then Exit;

  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then Exit;

  Item := TCssSvgImgListItem(FCollection.Items[I]);
  Idx := Item.Variants.IndexOfName(FCurrentVariant);
  if Idx < 0 then Exit;

  if MessageDlg('Delete variant "' + FCurrentVariant + '" from item "' +
    Item.Name + '"?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Item.Variants.Delete(Idx);

  RefreshVariantsCombo;
  RefreshInfo;
  UpdateButtons;
  RebuildThumb(I);
  FListBox.Invalidate;
end;

procedure TCssSvgCollectionForm.DoVariantLoad(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
  Dlg: TOpenDialog;
  L: TStringList;
begin
  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then Exit;

  Item := TCssSvgImgListItem(FCollection.Items[I]);
  if not ItemHasCurrentVariant(Item) then Exit;

  Dlg := TOpenDialog.Create(Self);
  L := TStringList.Create;
  try
    if FCurrentVariant = '' then
      Dlg.Title := 'Load SVG for base variant'
    else
      Dlg.Title := 'Load SVG for variant "' + FCurrentVariant + '"';
    Dlg.Filter := 'SVG files (*.svg)|*.svg|All files (*.*)|*.*';
    Dlg.Options := Dlg.Options + [ofFileMustExist, ofPathMustExist];

    if not Dlg.Execute then Exit;

    try
      L.LoadFromFile(Dlg.FileName);
    except
      on E: Exception do
      begin
        MessageDlg('Failed to load ' + Dlg.FileName + #13#10 + E.Message,
          mtError, [mbOK], 0);
        Exit;
      end;
    end;

    SetEffectiveSvgOf(Item, L.Text);

    RefreshInfo;
    UpdateButtons;
    RebuildThumb(I);
    FListBox.Invalidate;
  finally
    L.Free;
    Dlg.Free;
  end;
end;

procedure TCssSvgCollectionForm.DoSvgMemoChange(Sender: TObject);
var
  I: Integer;
  Item: TCssSvgImgListItem;
  SvgText: string;
begin
  if FUpdating then Exit;

  I := SelIndex;
  if (I < 0) or (I >= FCollection.Count) then Exit;

  Item := TCssSvgImgListItem(FCollection.Items[I]);
  SvgText := FSvgMemo.Lines.Text;

  if EffectiveSvgOf(Item) = SvgText then Exit;

  SetEffectiveSvgOf(Item, SvgText);

  RebuildThumb(I);
  FListBox.Invalidate;
  RefreshVariantsCombo;

  if SvgText = '' then
    FInfoLabel.Caption :=
      Format('SVG data (%s): (empty)', [CurrentVariantLabel])
  else
    FInfoLabel.Caption :=
      Format('SVG data (%s): %d bytes',
        [CurrentVariantLabel, Length(SvgText)]);

  UpdateButtons;
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
  RegisterPropertyEditor(
    TypeInfo(string),
    TCssSvgImgListItem,
    'Svg',
    TCssSvgTextProperty);

  RegisterPropertyEditor(
    TypeInfo(TCssSvgImgListItems),
    TCssSvgImgList,
    'Items',
    TCssSvgItemsProperty);

  RegisterComponentEditor(
    TCssSvgImgList,
    TCssSvgImgListEditor);
end;

end.
