unit CssStyledControlDesign;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, PropEdits, ComponentEditors, Forms, Controls,
  StdCtrls, ExtCtrls, Dialogs, FormEditingIntf, CssStyledControl, CssTabbedControl;

type
  TCssPageControlEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TCssTextPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TCssFileNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TCssStyleProviderEditor = class(TDefaultComponentEditor)
  public
    procedure Edit; override;
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

procedure Register;

implementation

{ Shared helper }

procedure ShowCssEditDialog(
  const ACurrentCss: string;
  out ANewCss: string;
  out AApply: Boolean
);
var
  Dlg: TForm;
  Memo: TMemo;
  Bottom: TPanel;
  OkBtn, CancelBtn: TButton;
begin
  AApply := False;
  ANewCss := ACurrentCss;

  Dlg := TForm.Create(nil);
  try
    Dlg.Caption := 'CSS editor';
    Dlg.Width := 900;
    Dlg.Height := 640;
    Dlg.Position := poScreenCenter;

    Memo := TMemo.Create(Dlg);
    Memo.Parent := Dlg;
    Memo.Align := alClient;
    Memo.ScrollBars := ssBoth;
    Memo.WantTabs := True;
    Memo.Lines.Text := ACurrentCss;

    Bottom := TPanel.Create(Dlg);
    Bottom.Parent := Dlg;
    Bottom.Align := alBottom;
    Bottom.Height := 42;
    Bottom.BevelOuter := bvNone;

    CancelBtn := TButton.Create(Dlg);
    CancelBtn.Parent := Bottom;
    CancelBtn.Caption := 'Cancel';
    CancelBtn.ModalResult := mrCancel;
    CancelBtn.Cancel := True;
    CancelBtn.Align := alRight;
    CancelBtn.Width := 100;
    CancelBtn.BorderSpacing.Right := 8;

    OkBtn := TButton.Create(Dlg);
    OkBtn.Parent := Bottom;
    OkBtn.Caption := 'OK';
    OkBtn.ModalResult := mrOk;
    OkBtn.Default := True;
    OkBtn.Align := alRight;
    OkBtn.Width := 100;
    OkBtn.BorderSpacing.Right := 6;

    if Dlg.ShowModal = mrOk then
    begin
      ANewCss := Memo.Lines.Text;
      AApply := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TCssPageControlEditor }

const
  vNewPage      = 0;
  vDeletePage   = 1;
  vNextPage     = 2;
  vPreviousPage = 3;

function TCssPageControlEditor.GetVerbCount: Integer;
begin
  Result := 4;
end;

function TCssPageControlEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    vNewPage:      Result := 'New Page';
    vDeletePage:   Result := 'Delete Page';
    vNextPage:     Result := 'Next Page';
    vPreviousPage: Result := 'Previous Page';
  else
    Result := inherited GetVerb(Index);
  end;
end;

procedure TCssPageControlEditor.ExecuteVerb(Index: Integer);
var
  PC: TCssPageControl;
  NewPage: TCssTabSheet;
begin
  if not (Component is TCssPageControl) then
    Exit;

  PC := TCssPageControl(Component);

  case Index of
    vNewPage:
      begin
        NewPage := TCssTabSheet(
          FormEditingHook.CreateComponent(
            PC,              // ParentComp
            TCssTabSheet,    // TypeClass
            '',              // AUnitName
            0, 0, 200, 150,  // X, Y, W, H
            False            // DisableAutoSize
          )
        );

        if NewPage <> nil then
        begin
          NewPage.Parent := PC;
          NewPage.Caption := 'Page' + IntToStr(PC.PageCount + 1);
          PC.ActivePage := NewPage;

          if Assigned(Designer) then
            Designer.Modified;
        end;
      end;

    vDeletePage:
      begin
        if PC.ActivePage <> nil then
        begin
          PC.ActivePage.Free;
          Designer.Modified;
        end;
      end;

    vNextPage:
      if PC.PageCount > 1 then
        PC.ActivePageIndex := (PC.ActivePageIndex + 1) mod PC.PageCount;

    vPreviousPage:
      if PC.PageCount > 1 then
      begin
        if PC.ActivePageIndex > 0 then
          PC.ActivePageIndex := PC.ActivePageIndex - 1
        else
          PC.ActivePageIndex := PC.PageCount - 1;
      end;
  end;
end;

{ TCssTextPropertyEditor }

function TCssTextPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

procedure TCssTextPropertyEditor.Edit;
var
  NewCss: string;
  Apply: Boolean;
begin
  ShowCssEditDialog(GetStrValue, NewCss, Apply);

  if Apply then
    SetStrValue(NewCss);
end;

{ TCssFileNameProperty }

function TCssFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

procedure TCssFileNameProperty.Edit;
var
  OpenDlg: TOpenDialog;
  CurrentValue: string;
  CurrentDir: string;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    CurrentValue := Trim(GetStrValue);

    OpenDlg.Title := 'Choose CSS file';
    OpenDlg.Filter := 'CSS files (*.css)|*.css|All files (*.*)|*.*';
    OpenDlg.DefaultExt := 'css';
    OpenDlg.FileName := ExtractFileName(CurrentValue);

    CurrentDir := ExtractFilePath(CurrentValue);

    if (CurrentDir <> '') and DirectoryExists(CurrentDir) then
      OpenDlg.InitialDir := CurrentDir;

    OpenDlg.Options := OpenDlg.Options + [ofFileMustExist, ofPathMustExist];

    if OpenDlg.Execute then
      SetStrValue(OpenDlg.FileName);
  finally
    OpenDlg.Free;
  end;
end;

{ TCssStyleProviderEditor }

procedure TCssStyleProviderEditor.Edit;
var
  Provider: TCssStyleProvider;
  NewCss: string;
  Apply: Boolean;
begin
  if Component is TCssStyleProvider then
  begin
    Provider := TCssStyleProvider(Component);

    ShowCssEditDialog(Provider.CssText, NewCss, Apply);

    if Apply then
    begin
      Provider.CssText := NewCss;

      if Assigned(Designer) then
        Designer.Modified;
    end;
  end;
end;

function TCssStyleProviderEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TCssStyleProviderEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := 'Edit CSS...'
  else
    Result := inherited GetVerb(Index);
end;

procedure TCssStyleProviderEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    Edit;
end;

{ Registration }

procedure Register;
begin
  RegisterPropertyEditor(
    TypeInfo(string),
    TCssStyleProvider,
    'CssText',
    TCssTextPropertyEditor
  );

  RegisterPropertyEditor(
    TypeInfo(string),
    TCssStyleProvider,
    'FileName',
    TCssFileNameProperty
  );

  RegisterComponentEditor(
    TCssStyleProvider,
    TCssStyleProviderEditor
  );

  RegisterComponentEditor(
    TCssPageControl,
    TCssPageControlEditor
  );
end;

end.
