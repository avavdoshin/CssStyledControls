unit CssComboControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  Forms, CssAntiAlias, CssStyledControl, CssListboxControl, cssEditControl;

type
  TCssComboStyle = (ccsDropDown, ccsDropDownList);

  TCssComboBox = class(TCssStyledControl)
  private
    // Data
    FItems: TStringList;
    FItemIndex: Integer;
    FPendingItemIndex: Integer;

    // Behavior
    FComboStyle: TCssComboStyle;
    FDropDownCount: Integer;
    FItemHeight: Integer;
    FReadOnly: Boolean;

    // Internal state
    FUpdating: Boolean;
    FClosingPopup: Boolean;

    // Child controls
    FEdit: TCssEdit;
    FPopup: TForm;
    FListBox: TCssListBox;

    // Button visual state
    FButtonHover: Boolean;
    FButtonDown: Boolean;

    // Events
    FOnDropDown: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    FOnChange: TNotifyEvent;
    FOnSelect: TNotifyEvent;

    // Button appearance
    FButtonBackground: TColor;
    FButtonBackgroundSet: Boolean;
    FButtonHoverBackground: TColor;
    FButtonHoverBackgroundSet: Boolean;
    FButtonActiveBackground: TColor;
    FButtonActiveBackgroundSet: Boolean;
    FButtonArrowColor: TColor;
    FButtonArrowColorSet: Boolean;
    FButtonRadius: Integer;
    FButtonRadiusSet: Boolean;
    FButtonBorderColor: TColor;
    FButtonBorderColorSet: Boolean;

    // Child CSS configuration
    FEditCssClass: string;
    FEditCssStyle: string;
    FListBoxCssClass: string;
    FListBoxCssStyle: string;
    FScrollBarCssClass: string;
    FScrollBarCssStyle: string;

    // Placeholder
    FPlaceholder: string;
    FPlaceholderColor: TColor;
    FPlaceholderColorSet: Boolean;
    FPlaceholderAlign: TCssTextAlign;
    FPlaceholderAlignSet: Boolean;
    FPlaceholderFontBold: Boolean;
    FPlaceholderFontBoldSet: Boolean;
    FPlaceholderFontItalic: Boolean;
    FPlaceholderFontItalicSet: Boolean;
    FPlaceholderFontUnderline: Boolean;
    FPlaceholderFontUnderlineSet: Boolean;
    FPlaceholderFontStrikeOut: Boolean;
    FPlaceholderFontStrikeOutSet: Boolean;

    // Items and text
    function GetItems: TStrings;
    procedure SetItems(AValue: TStrings);
    procedure ItemsChanged(Sender: TObject);
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetDisplayText: string;

    // State setters
    procedure SetItemIndex(AValue: Integer);
    procedure SetComboStyle(AValue: TCssComboStyle);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetDropDownCount(AValue: Integer);
    procedure SetItemHeight(AValue: Integer);

    // Layout helpers
    function GetButtonRect: TRect;
    function GetEditRect: TRect;
    procedure UpdateEdit;
    procedure UpdateChildBounds;

    // Popup management
    procedure EnsurePopup;
    function IsPopupVisible: Boolean;
    procedure InternalShowPopup;
    procedure InternalClosePopup(RestoreFocus: Boolean);

    // Event handlers for child controls
    procedure ListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ListMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PopupDeactivate(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditMouseEnter(Sender: TObject);
    procedure EditMouseLeave(Sender: TObject);

    // Style application
    procedure ApplyControlStyles;

    // Button color getters
    function GetButtonBackground: TColor;
    function GetButtonHoverBackground: TColor;
    function GetButtonActiveBackground: TColor;
    function GetButtonArrowColor: TColor;
    function GetButtonRadius: Integer;
    function GetButtonBorderColor: TColor;

    // Child CSS setters
    procedure SetEditCssClass(const AValue: string);
    procedure SetEditCssStyle(const AValue: string);
    procedure SetListBoxCssClass(const AValue: string);
    procedure SetListBoxCssStyle(const AValue: string);
    procedure SetScrollBarCssClass(const AValue: string);
    procedure SetScrollBarCssStyle(const AValue: string);

    // Placeholder
    procedure SetPlaceholder(const AValue: string);
    function  GetPlaceholderColor: TColor;
    function  GetPlaceholderAlign: TCssTextAlign;
    procedure DrawPlaceholderText(ACanvas: TCanvas;
      const ARect: TRect; const AText: string);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Painting
    procedure Paint; override;

    // Sizing
    procedure Resize; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // State changes
    procedure EnabledChanged; override;

    procedure UpdateCursor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Popup control
    procedure DropDown;
    procedure ClosePopup;

    // Style refresh
    procedure RefreshChildStyles;

    property SelText: string read GetDisplayText;
  published
    // Items and text
    property Items: TStrings read GetItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Text: string read GetText write SetText;

    // Behavior
    property ComboStyle: TCssComboStyle read FComboStyle write SetComboStyle default ccsDropDown;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;

    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 8;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 18;

    property Placeholder: string read FPlaceholder write SetPlaceholder;

    // Child CSS
    property EditCssClass: string read FEditCssClass write SetEditCssClass;
    property EditCssStyle: string read FEditCssStyle write SetEditCssStyle;
    property ListBoxCssClass: string read FListBoxCssClass write SetListBoxCssClass;
    property ListBoxCssStyle: string read FListBoxCssStyle write SetListBoxCssStyle;
    property ScrollBarCssClass: string read FScrollBarCssClass write SetScrollBarCssClass;
    property ScrollBarCssStyle: string read FScrollBarCssStyle write SetScrollBarCssStyle;

    // Standard properties
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;

    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

type
  TCssListBoxCracker = class(TCssListBox);

{ TCssComboBox }

constructor TCssComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];

  TabStop := True;

  Width := 160;
  Height := 24;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;

  FItemIndex := -1;
  FPendingItemIndex := -1;

  FComboStyle := ccsDropDown;
  FDropDownCount := 8;
  FItemHeight := 18;
  FReadOnly := False;

  FUpdating := False;
  FClosingPopup := False;

  FEdit := nil;
  FPopup := nil;
  FListBox := nil;

  FButtonHover := False;
  FButtonDown := False;

  FEditCssClass := 'combobox-edit';
  FEditCssStyle :=
    'background-color: transparent;' +
    'border: 0px solid transparent;' +
    'padding: 0px;';

  FListBoxCssClass := 'combobox-list';
  FListBoxCssStyle := '';

  FScrollBarCssClass := 'combobox-scrollbar';
  FScrollBarCssStyle := '';

  // The internal edit control must be created immediately.
  UpdateEdit;
end;

destructor TCssComboBox.Destroy;
begin
  if Assigned(FPopup) then
  begin
    FPopup.Visible := False;
  end;

  FItems.OnChange := nil;
  FreeAndNil(FItems);

  inherited Destroy;
end;

procedure TCssComboBox.Loaded;
begin
  inherited Loaded;

  if (FPendingItemIndex >= 0) and (FItems.Count > 0) then
  begin
    FItemIndex := FPendingItemIndex;
    if FItemIndex >= FItems.Count then
      FItemIndex := FItems.Count - 1;
  end;

  FPendingItemIndex := -1;

  UpdateEdit;
  ApplyControlStyles;
  UpdateChildBounds;
  Invalidate;
end;

function TCssComboBox.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TCssComboBox.SetItems(AValue: TStrings);
begin
  FUpdating := True;

  try
    if AValue = nil then
      FItems.Clear
    else
      FItems.Assign(AValue);
  finally
    FUpdating := False;
  end;

  ItemsChanged(Self);
end;

procedure TCssComboBox.ItemsChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  if (FPendingItemIndex >= 0) and (FItems.Count > 0) then
  begin
    FItemIndex := FPendingItemIndex;
    if FItemIndex >= FItems.Count then
      FItemIndex := FItems.Count - 1;
    FPendingItemIndex := -1;
  end;

  if FItemIndex >= FItems.Count then
    FItemIndex := -1;

  if Assigned(FListBox) then
  begin
    FListBox.Items.Assign(FItems);

    if FListBox.ItemIndex <> FItemIndex then
      FListBox.ItemIndex := FItemIndex;
  end;

  if (FComboStyle = ccsDropDown) and Assigned(FEdit) then
  begin
    if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    begin
      FUpdating := True;
      try
        if FEdit.Text <> GetDisplayText then
          FEdit.Text := GetDisplayText;
      finally
        FUpdating := False;
      end;
    end;
  end;

  Invalidate;
end;

function TCssComboBox.GetDisplayText: string;
var
  S: string;
begin
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
  begin
    S := FItems[FItemIndex];

    if HtmlMode then
      S := HtmlToPlainText(S);

    Result := S;
  end
  else
    Result := '';
end;

function TCssComboBox.GetText: string;
begin
  if (FComboStyle = ccsDropDown) and Assigned(FEdit) then
    Result := FEdit.Text
  else
    Result := GetDisplayText;
end;

procedure TCssComboBox.SetText(const AValue: string);
var
  I, Found: Integer;
  PlainItem: string;
begin
  if FComboStyle = ccsDropDown then
  begin
    if Assigned(FEdit) then
      FEdit.Text := AValue;
  end
  else
  begin
    Found := -1;

    for I := 0 to FItems.Count - 1 do
    begin
      PlainItem := FItems[I];

      if HtmlMode then
        PlainItem := HtmlToPlainText(PlainItem);

      if PlainItem = AValue then
      begin
        Found := I;
        Break;
      end;
    end;

    if Found >= 0 then
      ItemIndex := Found
    else
      ItemIndex := -1;
  end;
end;

procedure TCssComboBox.SetItemIndex(AValue: Integer);
var
  OldIndex: Integer;
begin
  if AValue < -1 then
    AValue := -1;

  if csLoading in ComponentState then
  begin
    FPendingItemIndex := AValue;
    Exit;
  end;

  if (FItems.Count = 0) and (AValue > -1) then
  begin
    FPendingItemIndex := AValue;
    Exit;
  end;

  if AValue >= FItems.Count then
    AValue := FItems.Count - 1;

  if FItemIndex = AValue then
  begin
    if (FComboStyle = ccsDropDown) and Assigned(FEdit) then
    begin
      FUpdating := True;
      try
        if FEdit.Text <> GetDisplayText then
          FEdit.Text := GetDisplayText;
      finally
        FUpdating := False;
      end;
    end;
    Exit;
  end;

  OldIndex := FItemIndex;
  FItemIndex := AValue;

  if (FComboStyle = ccsDropDown) and Assigned(FEdit) then
  begin
    FUpdating := True;
    try
      FEdit.Text := GetDisplayText;
    finally
      FUpdating := False;
    end;
  end;

  if Assigned(FListBox) then
    FListBox.ItemIndex := FItemIndex;

  Invalidate;

  if FItemIndex <> OldIndex then
  begin
    if Assigned(FOnSelect) then
      FOnSelect(Self);

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TCssComboBox.SetComboStyle(AValue: TCssComboStyle);
begin
  if FComboStyle = AValue then
    Exit;

  FComboStyle := AValue;

  UpdateEdit;
  UpdateChildBounds;
  Invalidate;
end;

procedure TCssComboBox.SetReadOnly(AValue: Boolean);
begin
  if FReadOnly = AValue then
    Exit;

  FReadOnly := AValue;

  if Assigned(FEdit) then
    FEdit.ReadOnly := AValue;

  UpdateCursor;
  Invalidate;
end;

procedure TCssComboBox.SetDropDownCount(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FDropDownCount = AValue then
    Exit;

  FDropDownCount := AValue;
end;

procedure TCssComboBox.SetItemHeight(AValue: Integer);
begin
  if AValue < 10 then
    AValue := 10;

  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;

  if Assigned(FListBox) then
    ApplyControlStyles;
end;

function TCssComboBox.GetButtonRect: TRect;
var
  R: TRect;
  BW: Integer;
begin
  R := GetContentRect;

  BW := R.Bottom - R.Top;

  if BW < ScalePx(12) then
    BW := ScalePx(12);

  if BW > ScalePx(22) then
    BW := ScalePx(22);

  Result := Rect(R.Right - BW, R.Top, R.Right, R.Bottom);
end;

function TCssComboBox.GetEditRect: TRect;
var
  R: TRect;
  ButtonR: TRect;
begin
  R := GetContentRect;
  ButtonR := GetButtonRect;

  Result := Rect(R.Left, R.Top, ButtonR.Left - 1, R.Bottom);

  if Result.Right < Result.Left then
    Result.Right := Result.Left;
end;

procedure TCssComboBox.UpdateEdit;
begin
  if FComboStyle = ccsDropDown then
  begin
    if not Assigned(FEdit) then
    begin
      FEdit := TCssEdit.Create(Self);
      FEdit.Parent := Self;

      FEdit.Visible := True;
      FEdit.AutoSize := False;
      FEdit.TabStop := True;

      FEdit.OnChange := @EditChange;
      FEdit.OnKeyDown := @EditKeyDown;

      FEdit.OnMouseEnter := @EditMouseEnter;
      FEdit.OnMouseLeave := @EditMouseLeave;

      FEdit.CssTag := 'edit';
    end;

    FEdit.Enabled := Enabled;
    FEdit.ReadOnly := FReadOnly;
    FEdit.Placeholder := FPlaceholder;

    // If an item is selected, insert its text.
    // If the user simply typed text without selecting, do not overwrite it.
    if FItemIndex >= 0 then
    begin
      FUpdating := True;

      try
        if FEdit.Text <> GetDisplayText then
          FEdit.Text := GetDisplayText;
      finally
        FUpdating := False;
      end;
    end;

    FEdit.BringToFront;
  end
  else
  begin
    if Assigned(FEdit) then
      FreeAndNil(FEdit);
  end;

  ApplyControlStyles;
  UpdateChildBounds;
end;

procedure TCssComboBox.UpdateChildBounds;
var
  EditR: TRect;
begin
  if Assigned(FEdit) then
  begin
    EditR := GetEditRect;

    FEdit.SetBounds(
      EditR.Left,
      EditR.Top,
      EditR.Right - EditR.Left,
      EditR.Bottom - EditR.Top
    );
  end;
end;

procedure TCssComboBox.ApplyControlStyles;
begin
  if Assigned(FEdit) then
  begin
    FEdit.StyleProvider := StyleProvider;
    FEdit.StyleName := StyleName;

    FEdit.CssClass := FEditCssClass;
    FEdit.CssStyle := FEditCssStyle;

    FEdit.HtmlMode := False;
  end;

  if Assigned(FListBox) then
  begin
    FListBox.StyleProvider := StyleProvider;
    FListBox.StyleName := StyleName;

    FListBox.CssClass := FListBoxCssClass;
    FListBox.CssStyle :=
      'item-height: ' + IntToStr(FItemHeight) + 'px;' +
      FListBoxCssStyle;

    FListBox.HtmlMode := HtmlMode;
    FListBox.ItemHeight := FItemHeight;

    FListBox.ScrollBarCssClass := FScrollBarCssClass;
    FListBox.ScrollBarCssStyle := FScrollBarCssStyle;
    if Assigned(FPopup) then
    begin
      FPopup.Color := TCssListBoxCracker(FListBox).GetCssBackgroundColor;
      if (FPopup.Color = clNone) or (FPopup.Color = clDefault) then
        FPopup.Color := GetCssBackgroundColor;

      if (FPopup.Color = clNone) or (FPopup.Color = clDefault) then
        FPopup.Color := clWindow;
    end;
  end;
end;

procedure TCssComboBox.EnsurePopup;
var
  PopupBG: TColor;
begin
  if Assigned(FPopup) then
    Exit;

  FPopup := TForm.CreateNew(Self);

  FPopup.BorderStyle := bsNone;
  FPopup.ShowInTaskBar := stNever;
  FPopup.Visible := False;
  FPopup.OnDeactivate := @PopupDeactivate;

  PopupBG := GetCssBackgroundColor;
  if (PopupBG = clNone) or (PopupBG = clDefault) then
    PopupBG := clBtnFace;
  FPopup.Color := PopupBG;
  FPopup.DoubleBuffered := True;

  FListBox := TCssListBox.Create(FPopup);
  FListBox.Parent := FPopup;

  FListBox.Align := alClient;

  FListBox.MultiSelect := False;
  FListBox.ItemHeight := FItemHeight;

  FListBox.ShowFocusRect := False;

  FListBox.OnMouseUp := @ListMouseUp;
  FListBox.OnKeyDown := @ListKeyDown;

  ApplyControlStyles;
end;

function TCssComboBox.IsPopupVisible: Boolean;
begin
  Result := Assigned(FPopup) and FPopup.Visible;
end;

procedure TCssComboBox.DropDown;
begin
  InternalShowPopup;
end;

procedure TCssComboBox.ClosePopup;
begin
  InternalClosePopup(False);
end;

procedure TCssComboBox.RefreshChildStyles;
begin
  ApplyControlStyles;
  Invalidate;
end;

procedure TCssComboBox.InternalShowPopup;
var
  P: TPoint;
  PopupWidth, PopupHeight: Integer;
  VisibleCount, ItemCount: Integer;
begin
  if not Enabled then
    Exit;

  if FReadOnly and (FComboStyle = ccsDropDownList) then
    Exit;

  if IsPopupVisible then
    Exit;

  EnsurePopup;

  FListBox.Items.Assign(FItems);
  FListBox.ItemIndex := FItemIndex;

  ApplyControlStyles;

  ItemCount := FItems.Count;
  if ItemCount < 1 then
    ItemCount := 1;

  VisibleCount := ItemCount;
  if VisibleCount > FDropDownCount then
    VisibleCount := FDropDownCount;
  if VisibleCount < 1 then
    VisibleCount := 1;

  PopupWidth := Width;

  if FItemHeight > 0 then
    PopupHeight := VisibleCount * FItemHeight + 6
  else
    PopupHeight := 6;

  P := ClientToScreen(Point(0, Height));

  if P.Y + PopupHeight > Screen.Height then
    P.Y := ClientToScreen(Point(0, 0)).Y - PopupHeight;

  if P.Y < 0 then
    P.Y := 0;

  FPopup.SetBounds(P.X, P.Y, PopupWidth, PopupHeight);

  FPopup.Show;

  if FListBox.CanFocus then
    FListBox.SetFocus;

  if Assigned(FOnDropDown) then
    FOnDropDown(Self);
end;

procedure TCssComboBox.InternalClosePopup(RestoreFocus: Boolean);
begin
  if not Assigned(FPopup) then
    Exit;

  if not FPopup.Visible then
    Exit;

  if FClosingPopup then
    Exit;

  FClosingPopup := True;

  try
    FPopup.Hide;

    if RestoreFocus then
    begin
      if Assigned(FEdit) then
      begin
        if FEdit.CanFocus then
          FEdit.SetFocus;
      end
      else if CanFocus then
      begin
        SetFocus;
      end;
    end;

    if Assigned(FOnCloseUp) then
      FOnCloseUp(Self);
  finally
    FClosingPopup := False;
  end;
end;

procedure TCssComboBox.ListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if FListBox.ItemIndex >= 0 then
      ItemIndex := FListBox.ItemIndex;

    InternalClosePopup(True);
    Key := 0;
  end
  else if Key = VK_ESCAPE then
  begin
    InternalClosePopup(True);
    Key := 0;
  end;
end;

procedure TCssComboBox.ListMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  if not Assigned(FListBox) then
    Exit;

  if FListBox.ItemIndex >= 0 then
    ItemIndex := FListBox.ItemIndex;

  InternalClosePopup(True);
end;

procedure TCssComboBox.PopupDeactivate(Sender: TObject);
begin
  if FClosingPopup then
    Exit;

  InternalClosePopup(False);
end;

procedure TCssComboBox.EditChange(Sender: TObject);
var
  I, Found: Integer;
  PlainItem: string;
begin
  if FUpdating then
    Exit;

  if not Assigned(FEdit) then
    Exit;

  Found := -1;

  for I := 0 to FItems.Count - 1 do
  begin
    PlainItem := FItems[I];

    if HtmlMode then
      PlainItem := HtmlToPlainText(PlainItem);

    if PlainItem = FEdit.Text then
    begin
      Found := I;
      Break;
    end;
  end;

  if Found <> FItemIndex then
  begin
    FItemIndex := Found;

    if Assigned(FListBox) then
      FListBox.ItemIndex := FItemIndex;

    Invalidate;
  end;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCssComboBox.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    InternalShowPopup;
    Key := 0;
  end
  else if Key = VK_ESCAPE then
  begin
    InternalClosePopup(True);
    Key := 0;
  end;
end;

procedure TCssComboBox.EditMouseEnter(Sender : TObject);
begin
  SetMouseInControlState(True);
end;

procedure TCssComboBox.EditMouseLeave(Sender: TObject);
var
  P: TPoint;
begin
  P := ScreenToClient(Mouse.CursorPos);

  if not PtInRect(ClientRect, P) then
    SetMouseInControlState(False);
end;

procedure TCssComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  if Key = VK_F4 then
  begin
    if IsPopupVisible then
      InternalClosePopup(True)
    else if FItems.Count > 0 then
      InternalShowPopup;

    Key := 0;
    Exit;
  end;

  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    if FItems.Count > 0 then
      InternalShowPopup;
    Key := 0;
    Exit;
  end;

  if Key = VK_DOWN then
  begin
    if FComboStyle = ccsDropDownList then
    begin
      if FReadOnly then
      begin
        Key := 0;
        Exit;
      end;

      if not IsPopupVisible then
      begin
        if FItems.Count > 0 then
          InternalShowPopup;
      end;
    end
    else
    begin
      if FItemIndex < FItems.Count - 1 then
        ItemIndex := FItemIndex + 1;
    end;

    Key := 0;
    Exit;
  end;

  if Key = VK_UP then
  begin
    if FComboStyle = ccsDropDownList then
    begin
      if FReadOnly then
      begin
        Key := 0;
        Exit;
      end;

      if not IsPopupVisible then
      begin
        if FItems.Count > 0 then
          InternalShowPopup;
      end;
    end
    else
    begin
      if FItemIndex > 0 then
        ItemIndex := FItemIndex - 1;
    end;

    Key := 0;
    Exit;
  end;

  if Key = VK_RETURN then
  begin
    if IsPopupVisible then
      InternalClosePopup(True)
    else if FItems.Count > 0 then
      InternalShowPopup;

    Key := 0;
    Exit;
  end;

  if Key = VK_ESCAPE then
  begin
    InternalClosePopup(True);
    Key := 0;
    Exit;
  end;
end;

procedure TCssComboBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ButtonR: TRect;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  ButtonR := GetButtonRect;

  if PtInRect(ButtonR, Point(X, Y)) then
  begin
    FButtonDown := True;
    Invalidate;

    if IsPopupVisible then
      InternalClosePopup(False)
    else
      InternalShowPopup;
  end
  else if FComboStyle = ccsDropDownList then
  begin
    if CanFocus then
      SetFocus;

    if IsPopupVisible then
      InternalClosePopup(False)
    else
      InternalShowPopup;
  end;
end;

procedure TCssComboBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  ButtonR: TRect;
  Hover: Boolean;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  ButtonR := GetButtonRect;
  Hover := PtInRect(ButtonR, Point(X, Y));

  if Hover <> FButtonHover then
  begin
    FButtonHover := Hover;
    Invalidate;
  end;
end;

procedure TCssComboBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FButtonDown then
  begin
    FButtonDown := False;
    Invalidate;
  end;
end;

procedure TCssComboBox.MouseLeave;
begin
  if FButtonHover then
  begin
    FButtonHover := False;
    Invalidate;
  end;

  inherited MouseLeave;
end;

procedure TCssComboBox.Resize;
begin
  inherited Resize;

  UpdateChildBounds;
  Invalidate;
end;

procedure TCssComboBox.EnabledChanged;
begin
  inherited EnabledChanged;

  if Assigned(FEdit) then
    FEdit.Enabled := Enabled;

  Invalidate;
end;

procedure TCssComboBox.UpdateCursor;
var
  Blocked: Boolean;
begin
  Blocked := FReadOnly and (FComboStyle = ccsDropDownList);

  if Blocked then
    Cursor := crDefault
  else
    inherited UpdateCursor;
end;

procedure TCssComboBox.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if Assigned(FListBox) then
    FListBox.HtmlMode := HtmlMode;

  Invalidate;
end;

procedure TCssComboBox.StyleChanged;
begin
  inherited StyleChanged;

  ApplyControlStyles;
  Invalidate;
end;

procedure TCssComboBox.ResetStyle;
begin
  FButtonBackgroundSet := False;
  FButtonHoverBackgroundSet := False;
  FButtonActiveBackgroundSet := False;
  FButtonArrowColorSet := False;
  FButtonRadiusSet := False;
  FButtonBorderColorSet := False;

  FPlaceholderColorSet := False;
  FPlaceholderColor := clNone;
  FPlaceholderAlignSet := False;
  FPlaceholderAlign := ctaLeft;
  FPlaceholderFontBoldSet := False;
  FPlaceholderFontBold := False;
  FPlaceholderFontItalicSet := False;
  FPlaceholderFontItalic := False;
  FPlaceholderFontUnderlineSet := False;
  FPlaceholderFontUnderline := False;
  FPlaceholderFontStrikeOutSet := False;
  FPlaceholderFontStrikeOut := False;

  inherited ResetStyle;
end;

procedure TCssComboBox.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssComboBox.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
  S: String;
begin
  if AName = 'combo-button-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonBackground := C;
      FButtonBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'combo-button-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonHoverBackground := C;
      FButtonHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'combo-button-active-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonActiveBackground := C;
      FButtonActiveBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'combo-button-arrow-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonArrowColor := C;
      FButtonArrowColorSet := True;
    end;
    Exit;
  end;

  if AName = 'combo-button-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FButtonRadius := Px;
      FButtonRadiusSet := True;
    end;
    Exit;
  end;

  if AName = 'combo-button-border-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonBorderColor := C;
      FButtonBorderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'placeholder-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FPlaceholderColor := C;
      FPlaceholderColorSet := True;
    end;
    Exit;
  end
  else if AName = 'placeholder-align' then
  begin
    S := LowerCase(AValue);
    FPlaceholderAlignSet := True;

    if S = 'center' then
      FPlaceholderAlign := ctaCenter
    else if S = 'right' then
      FPlaceholderAlign := ctaRight
    else
      FPlaceholderAlign := ctaLeft;

    Exit;
  end
  else if AName = 'placeholder-font-weight' then
  begin
    S := LowerCase(AValue);
    FPlaceholderFontBoldSet := True;
    FPlaceholderFontBold := (S = 'bold') or (S = 'bolder');
    Exit;
  end
  else if AName = 'placeholder-font-style' then
  begin
    S := LowerCase(AValue);
    FPlaceholderFontItalicSet := True;
    FPlaceholderFontItalic := (S = 'italic') or (S = 'oblique');
    Exit;
  end
  else if AName = 'placeholder-text-decoration' then
  begin
    S := LowerCase(AValue);
    FPlaceholderFontUnderlineSet := True;
    FPlaceholderFontStrikeOutSet := True;
    FPlaceholderFontUnderline := Pos('underline', S) > 0;
    FPlaceholderFontStrikeOut := Pos('line-through', S) > 0;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

function TCssComboBox.GetButtonBackground: TColor;
begin
  if FButtonBackgroundSet then
  begin
    Result := FButtonBackground;
    Exit;
  end;

  Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := clBtnFace;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssComboBox.GetButtonHoverBackground: TColor;
begin
  if FButtonHoverBackgroundSet then
  begin
    Result := FButtonHoverBackground;
    Exit;
  end;

  Result := RGBToColor(230, 235, 240);
end;

function TCssComboBox.GetButtonActiveBackground: TColor;
begin
  if FButtonActiveBackgroundSet then
  begin
    Result := FButtonActiveBackground;
    Exit;
  end;

  Result := RGBToColor(210, 220, 230);
end;

function TCssComboBox.GetButtonArrowColor: TColor;
begin
  if FButtonArrowColorSet then
  begin
    Result := FButtonArrowColor;
    Exit;
  end;

  Result := GetCssTextColor;
end;

function TCssComboBox.GetButtonRadius: Integer;
begin
  if FButtonRadiusSet then
    Result := FButtonRadius
  else
    Result := 0;
end;

function TCssComboBox.GetButtonBorderColor: TColor;
begin
  if FButtonBorderColorSet then
    Exit(FButtonBorderColor);

  Result := GetEffectiveBorderColor;

  if (Result = clNone) or (Result = clDefault) then
    Result := GetButtonBackground;
end;

procedure TCssComboBox.Paint;
var
  ButtonR, EditR, TextR: TRect;
  BG, ArrowColor: TColor;
  Radius: Integer;
  CX, CY: Integer;
begin
  inherited Paint;

  ButtonR := GetButtonRect;
  EditR := GetEditRect;

  if FComboStyle = ccsDropDownList then
  begin
    AssignCssFontToFont(Canvas.Font);

    TextR := EditR;
    TextR.Left := TextR.Left + ScalePx(3);
    TextR.Right := TextR.Right - ScalePx(3);

    if (FItemIndex < 0) and (FPlaceholder <> '') and (not Focused) then
      DrawPlaceholderText(Canvas, TextR, FPlaceholder)
    else
    begin
      Canvas.Font.Color := GetCssTextColor;
      DrawStyledText(TextR, GetDisplayText);
    end;
  end;

  if FButtonDown then
    BG := GetButtonActiveBackground
  else if FButtonHover then
    BG := GetButtonHoverBackground
  else
    BG := GetButtonBackground;

  ArrowColor := GetButtonArrowColor;
  Radius := GetButtonRadius;

  if Radius > 0 then
  begin
    DrawAntiAliasedRoundedBox(
      Canvas,
      ButtonR,
      Radius,
      BG,
      GetButtonBorderColor,
      Ord(FButtonBorderColorSet),
      cbsSolid,
      GetCssBackgroundColor
    );
  end
  else
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := BG;

    if FButtonBorderColorSet then
    begin
      Canvas.Pen.Style := psSolid;
      Canvas.Pen.Color := GetButtonBorderColor;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(ButtonR.Left, ButtonR.Top, ButtonR.Right, ButtonR.Bottom);
    end
    else
    begin
      Canvas.Pen.Style := psClear;
      Canvas.FillRect(ButtonR);
    end;
  end;

  CX := (ButtonR.Left + ButtonR.Right) div 2;
  CY := (ButtonR.Top + ButtonR.Bottom) div 2;

  // Anti-aliased arrow (down). Background is taken from the button.
  DrawAntiAliasedTriangle(
    Canvas,
    Point(CX - ScalePx(4), CY - ScalePx(2)),
    Point(CX + ScalePx(4), CY - ScalePx(2)),
    Point(CX,     CY + ScalePx(3)),
    ArrowColor,
    BG
  );
end;

procedure TCssComboBox.SetEditCssClass(const AValue: string);
begin
  if FEditCssClass = AValue then
    Exit;

  FEditCssClass := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetEditCssStyle(const AValue: string);
begin
  if FEditCssStyle = AValue then
    Exit;

  FEditCssStyle := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetListBoxCssClass(const AValue: string);
begin
  if FListBoxCssClass = AValue then
    Exit;

  FListBoxCssClass := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetListBoxCssStyle(const AValue: string);
begin
  if FListBoxCssStyle = AValue then
    Exit;

  FListBoxCssStyle := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetScrollBarCssClass(const AValue: string);
begin
  if FScrollBarCssClass = AValue then
    Exit;

  FScrollBarCssClass := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetScrollBarCssStyle(const AValue: string);
begin
  if FScrollBarCssStyle = AValue then
    Exit;

  FScrollBarCssStyle := AValue;

  ApplyControlStyles;
end;

procedure TCssComboBox.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder = AValue then
    Exit;

  FPlaceholder := AValue;

  if Assigned(FEdit) then
    FEdit.Placeholder := FPlaceholder;

  Invalidate;
end;

function TCssComboBox.GetPlaceholderColor: TColor;
begin
  if FPlaceholderColorSet and (FPlaceholderColor <> clNone) then
    Result := FPlaceholderColor
  else
    Result := RGBToColor(150, 150, 150);
end;

function TCssComboBox.GetPlaceholderAlign: TCssTextAlign;
begin
  if FPlaceholderAlignSet then
    Result := FPlaceholderAlign
  else
    Result := ctaLeft;
end;

procedure TCssComboBox.DrawPlaceholderText(ACanvas: TCanvas;
  const ARect: TRect; const AText: string);
var
  TS: TTextStyle;
  SavedColor: TColor;
  SavedStyle: TFontStyles;
begin
  if ACanvas = nil then Exit;
  if AText = '' then Exit;
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then Exit;

  SavedColor := ACanvas.Font.Color;
  SavedStyle := ACanvas.Font.Style;
  try
    ACanvas.Font.Color := GetPlaceholderColor;

    if FPlaceholderFontBoldSet then
    begin
      if FPlaceholderFontBold then
        ACanvas.Font.Style := ACanvas.Font.Style + [fsBold]
      else
        ACanvas.Font.Style := ACanvas.Font.Style - [fsBold];
    end;

    if FPlaceholderFontItalicSet then
    begin
      if FPlaceholderFontItalic then
        ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic]
      else
        ACanvas.Font.Style := ACanvas.Font.Style - [fsItalic];
    end;

    if FPlaceholderFontUnderlineSet then
    begin
      if FPlaceholderFontUnderline then
        ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline]
      else
        ACanvas.Font.Style := ACanvas.Font.Style - [fsUnderline];
    end;

    if FPlaceholderFontStrikeOutSet then
    begin
      if FPlaceholderFontStrikeOut then
        ACanvas.Font.Style := ACanvas.Font.Style + [fsStrikeOut]
      else
        ACanvas.Font.Style := ACanvas.Font.Style - [fsStrikeOut];
    end;

    TS := ACanvas.TextStyle;
    TS.Layout := tlCenter;
    TS.Wordbreak := False;
    TS.Clipping := True;
    TS.Opaque := False;
    TS.ShowPrefix := False;

    case GetPlaceholderAlign of
      ctaCenter: TS.Alignment := taCenter;
      ctaRight:  TS.Alignment := taRightJustify;
    else
      TS.Alignment := taLeftJustify;
    end;

    ACanvas.Brush.Style := bsClear;
    ACanvas.TextRect(ARect, ARect.Left, ARect.Top, AText, TS);
  finally
    ACanvas.Font.Color := SavedColor;
    ACanvas.Font.Style := SavedStyle;
  end;
end;

end.
