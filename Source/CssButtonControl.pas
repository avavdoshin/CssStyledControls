unit CssButtonControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, Forms, CssStyledControl;

type
  TCssButton = class(TCssStyledControl)
  private
    FDefault: Boolean;
    FCancel: Boolean;
    FModalResult: TModalResult;
    FSpacePressed: Boolean;

    procedure SetDefault(AValue: Boolean);
    procedure SetCancel(AValue: Boolean);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    function MatchPseudo(const APseudo: string): Boolean; override;

    // Caption
    procedure SetCaption(const AValue: TCaption); override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Focus
    procedure DoExit; override;

    function GetDefaultCaption: string; override;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Click; override;

    // Sizing
    procedure AdjustSize; override;
    procedure AutoSizeNow;
  published
    property Default: Boolean read FDefault write SetDefault default False;
    property Cancel: Boolean read FCancel write SetCancel default False;
    property ModalResult: TModalResult read FModalResult write FModalResult default mrNone;

    property AutoSize;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  LCLType, CssUtils;

function MeasureTextSize(ACanvas: TCanvas; const AText: string): TSize;
var
  Lines: TStringList;
  I: Integer;
  W, H: Integer;
begin
  Result.cx := 0;
  Result.cy := 0;

  if AText = '' then
    Exit;

  Lines := TStringList.Create;

  try
    Lines.Text := AText;

    if Lines.Count = 0 then
      Lines.Add(AText);

    for I := 0 to Lines.Count - 1 do
    begin
      W := ACanvas.TextWidth(Lines[I]);
      H := ACanvas.TextHeight(Lines[I]);

      if W > Result.cx then
        Result.cx := W;

      Result.cy := Result.cy + H;
    end;
  finally
    Lines.Free;
  end;
end;

constructor TCssButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width := 75;
  Height := 25;

  TabStop := True;

  FDefault := False;
  FCancel := False;
  FModalResult := mrNone;
  FSpacePressed := False;
end;

procedure TCssButton.SetDefault(AValue: Boolean);
begin
  if FDefault = AValue then
    Exit;

  FDefault := AValue;

  if not (csLoading in ComponentState) then
  begin
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssButton.SetCancel(AValue: Boolean);
begin
  if FCancel = AValue then
    Exit;

  FCancel := AValue;

  if not (csLoading in ComponentState) then
  begin
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssButton.Loaded;
begin
  inherited Loaded;

  if AutoSize then
    AdjustSize;
end;

procedure TCssButton.InitTextProps;
begin
  SetTextAlign(ctaCenter);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssButton.StyleChanged;
begin
  inherited StyleChanged;

  if AutoSize then
    AdjustSize;
end;

procedure TCssButton.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

function TCssButton.MatchPseudo(const APseudo: string): Boolean;
var
  P: string;
begin
  P := LowerCase(APseudo);

  if P = 'default' then
    Exit(FDefault);

  if P = 'cancel' then
    Exit(FCancel);

  Result := inherited MatchPseudo(APseudo);
end;

procedure TCssButton.SetCaption(const AValue: TCaption);
begin
  if Caption = AValue then Exit;
  inherited SetCaption(AValue);
  if AutoSize then
    AdjustSize;
end;

procedure TCssButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Enabled and (Button = mbLeft) then
  begin
    if CanFocus then
      SetFocus;

    SetMouseInControlState(True);
    SetMousePressedState(True);
  end;
end;

procedure TCssButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  DoClick: Boolean;
begin
  DoClick :=
    Enabled and
    (Button = mbLeft) and
    GetMousePressedState and
    PtInRect(ClientRect, Point(X, Y));

  inherited MouseUp(Button, Shift, X, Y);

  FSpacePressed := False;
  SetMousePressedState(False);

  if DoClick then
    Click;
end;

procedure TCssButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  if Key = VK_SPACE then
  begin
    FSpacePressed := True;
    SetMousePressedState(True);
    Key := 0;
  end
  else if Key = VK_RETURN then
  begin
    Click;
    Key := 0;
  end
  else if (Key = VK_ESCAPE) and FCancel then
  begin
    Click;
    Key := 0;
  end;
end;

procedure TCssButton.KeyUp(var Key: Word; Shift: TShiftState);
var
  DoClick: Boolean;
begin
  DoClick :=
    Enabled and
    FSpacePressed and
    (Key = VK_SPACE);

  inherited KeyUp(Key, Shift);

  if Key = VK_SPACE then
  begin
    FSpacePressed := False;
    SetMousePressedState(False);

    if DoClick then
      Click;

    Key := 0;
  end;
end;

procedure TCssButton.DoExit;
begin
  FSpacePressed := False;
  SetMousePressedState(False);

  inherited DoExit;
end;

function TCssButton.GetDefaultCaption : string;
begin
  Result := 'CssButton';
end;

procedure TCssButton.Click;
var
  Form: TCustomForm;
begin
  inherited Click;

  if FModalResult <> mrNone then
  begin
    Form := FindParentForm(Self);

    if Assigned(Form) then
      Form.ModalResult := FModalResult;
  end;
end;

procedure TCssButton.AutoSizeNow;
var
  SavedAutoSize: Boolean;
  SavedAlign: TAlign;
begin
  if (csLoading in ComponentState) or
     (csDestroying in ComponentState) then
    Exit;

  SavedAutoSize := AutoSize;
  SavedAlign := Align;

  AutoSize := True;
  Align := alNone;

  try
    AdjustSize;
  finally
    AutoSize := SavedAutoSize;
    Align := SavedAlign;
  end;
end;

procedure TCssButton.AdjustSize;
var
  S: TSize;
  P: TRect;
  B: Integer;
  NewWidth, NewHeight: Integer;
begin
  if (csDestroying in ComponentState) or
     (csLoading in ComponentState) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  // If size is managed via Align, AutoSize is better ignored.
  if (not AutoSize) or
     (not HandleAllocated) or
     (Align <> alNone) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  if HtmlMode then
    S := MeasureHtmlTextSize(Canvas, Caption, 0)
  else
    S := MeasureTextSize(Canvas, Caption);

  B := GetCssBorderWidth;
  P := GetCssPadding;

  NewWidth := S.cx + (B * 2) + P.Left + P.Right;
  NewHeight := S.cy + (B * 2) + P.Top + P.Bottom;

  if NewWidth < 0 then
    NewWidth := 0;

  if NewHeight < 0 then
    NewHeight := 0;

  // Change size only if it actually changed.
  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);

  inherited AdjustSize;
end;

end.
