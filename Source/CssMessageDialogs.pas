unit CssMessageDialogs;

{$mode objfpc}{$H+}

{
  CssMessageDlg - CSS-styled replacements for the standard Dialogs functions.

  Public functions (all prefixed with Css to avoid clashes with Dialogs):
    CssShowMessage, CssShowMessageFmt, CssMessageDlg, CssMessageDlgPos,
    CssMessageBox, CssInputBox, CssInputQuery, CssPasswordBox.

  HTML formatting of message text is OFF by default. Call
  CssMessageDlgSetHtmlMode(True) once to enable it globally.
}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, GraphType, Types,
  LCLType, Dialogs,
  CssStyledControl, CssButtonControl,
  CssLabelControl, CssEditControl,
  CssProxyControl, CssPanelControl;

type
  TCssMessageIcon = class(TCssStyledControl)
  private
    FKind: TMsgDlgType;
    procedure SetKind(AValue: TMsgDlgType);
  protected
    procedure Paint; override;
    function  ShouldPaintCaption: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Kind: TMsgDlgType read FKind write SetKind;
  end;

  TCssMessageForm = class(TForm)
  private
    FProvider: TCssStyleProvider;
    FStyleName: string;

    FProxy: TCssProxy;
    FBackdrop: TCssPanel;

    FIcon: TCssMessageIcon;
    FDivider: TCssPanel;
    FMessage: TCssLabel;
    FEdit: TCssEdit;
    FButtons: array of TCssButton;
    FDefaultBtn: TCssButton;

    FInputMode: Boolean;
    FPasswordMode: Boolean;

    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure ApplyProvider(AControl: TCssStyledControl);
    function  ScaleDpi(APx: Integer): Integer;

    function  BtnCaption(ABtn: TMsgDlgBtn): string;
    function  BtnResult (ABtn: TMsgDlgBtn): Integer;
  public
    constructor CreateMessageDialog(
      AOwner: TComponent;
      ADlgType: TMsgDlgType;
      const AMessage: string;
      AButtons: TMsgDlgButtons;
      ADefault: TMsgDlgBtn;
      AInputMode, APasswordMode: Boolean;
      const ADefaultText: string;
      const ACaption: string = '');

    function GetEditText: string;
  end;

{ ---- Public API ---- }

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt): Integer; overload;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string): Integer; overload;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer): Integer; overload;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string): Integer; overload;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string;
  ADefaultBtn: TMsgDlgBtn): Integer; overload;

procedure CssShowMessage(const Msg: string);
procedure CssShowMessageFmt(const Msg: string; Params: array of const);

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt): Integer; overload;

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt; ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssInputBox(const ACaption, APrompt, ADefault: string): string;
function CssInputQuery(const ACaption, APrompt: string;
  var AValue: string): Boolean;

function CssPasswordBox(const ACaption, APrompt: string): string;

procedure CssMessageDlgSetStyleProvider(AProvider: TCssStyleProvider;
  const AStyleName: string = '');

procedure CssMessageDlgSetHtmlMode(AEnabled: Boolean);

implementation

uses
  Math;

const
  MSGDLG_PAD       = 16;
  MSGDLG_SPACING   = 12;
  MSGDLG_ICON      = 32;
  MSGDLG_EDIT_H    = 26;
  MSGDLG_BTN_W     = 90;
  MSGDLG_BTN_H     = 22;
  MSGDLG_BTN_GAP   = 8;
  MSGDLG_DEF_W     = 380;
  MSGDLG_DIVIDER_W = 1;

  mrCssHelp        = 100;
  MSGDLG_CSS_CLASS = 'msgdialog';

var
  GProvider:  TCssStyleProvider = nil;
  GStyleName: string = '';
  GHtmlMode:  Boolean = False;

procedure CssMessageDlgSetStyleProvider(AProvider: TCssStyleProvider;
  const AStyleName: string);
begin
  GProvider  := AProvider;
  GStyleName := AStyleName;
end;

procedure CssMessageDlgSetHtmlMode(AEnabled: Boolean);
begin
  GHtmlMode := AEnabled;
end;

function GetDialogOwner: TComponent;
var
  F: TCustomForm;
begin
  F := Screen.ActiveCustomForm;
  if F = nil then
    F := Application.MainForm;
  Result := F;
end;

function FindProvider(AOwner: TComponent): TCssStyleProvider;
var
  I: Integer;
  C: TComponent;
begin
  if AOwner <> nil then
  begin
    for I := 0 to AOwner.ComponentCount - 1 do
    begin
      C := AOwner.Components[I];
      if C is TCssStyleProvider then
        Exit(TCssStyleProvider(C));
    end;
  end;
  Result := GProvider;
end;

function DefaultDialogCaption: string;
begin
  Result := Application.Title;
end;

function PickDefaultButton(Buttons: TMsgDlgButtons): TMsgDlgBtn;
begin
  if mbOK in Buttons then Exit(mbOK);
  if mbYes in Buttons then Exit(mbYes);
  if mbYesToAll in Buttons then Exit(mbYesToAll);
  if mbNo in Buttons then Exit(mbNo);
  if mbNoToAll in Buttons then Exit(mbNoToAll);
  if mbRetry in Buttons then Exit(mbRetry);
  if mbAbort in Buttons then Exit(mbAbort);
  if mbIgnore in Buttons then Exit(mbIgnore);
  if mbAll in Buttons then Exit(mbAll);
  if mbClose in Buttons then Exit(mbClose);
  Result := mbOK;
end;

{ Word-wrap aware measurement for plain-text messages. }
function MeasureDialogPlainText(
  ACanvas: TCanvas;
  const AText: string;
  AAvailableWidth: Integer): TSize;
var
  Lines: TStringList;
  I, P, StartPos: Integer;
  Line, Word: string;
  LineH, W, SpaceW, LineW: Integer;
begin
  Result.cx := 0;
  Result.cy := 0;

  if AText = '' then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    if Lines.Count = 0 then
      Lines.Add('');

    LineH := ACanvas.TextHeight('Ag');

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];

      if AAvailableWidth <= 0 then
      begin
        W := ACanvas.TextWidth(Line);
        if W > Result.cx then Result.cx := W;
        Result.cy := Result.cy + LineH;
        Continue;
      end;

      LineW := 0;
      P := 1;
      while P <= Length(Line) do
      begin
        while (P <= Length(Line)) and (Line[P] = ' ') do Inc(P);
        if P > Length(Line) then Break;

        StartPos := P;
        while (P <= Length(Line)) and (Line[P] <> ' ') do Inc(P);

        Word   := Copy(Line, StartPos, P - StartPos);
        W      := ACanvas.TextWidth(Word);
        SpaceW := ACanvas.TextWidth(' ');

        if (LineW > 0) and (LineW + SpaceW + W > AAvailableWidth) then
        begin
          if LineW > Result.cx then Result.cx := LineW;
          Result.cy := Result.cy + LineH;
          LineW := W;
        end
        else
        begin
          if LineW > 0 then LineW := LineW + SpaceW;
          LineW := LineW + W;
        end;
      end;

      if LineW > Result.cx then Result.cx := LineW;
      Result.cy := Result.cy + LineH;
    end;
  finally
    Lines.Free;
  end;
end;

{ =========================================================================== }
{  TCssMessageIcon                                                            }
{ =========================================================================== }

constructor TCssMessageIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKind   := mtInformation;
  TabStop := False;
  CssTag  := 'msgdlg-icon';

  CssStyle := 'background-color: transparent; border: none; border-radius: 0px;';
end;

procedure TCssMessageIcon.SetKind(AValue: TMsgDlgType);
begin
  if FKind = AValue then Exit;
  FKind := AValue;
  Invalidate;
end;

function TCssMessageIcon.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

procedure TCssMessageIcon.Paint;
var
  R: TRect;
  CX, CY, Rad: Integer;
  BG, SymColor: TColor;
  Sym: string;
  SymOffsetY: Integer;
  SavedFont: TFont;
  TW, TH, TX, TY: Integer;
begin
  inherited Paint;

  R := ClientRect;
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;

  CX  := (R.Left + R.Right) div 2;
  CY  := (R.Top  + R.Bottom) div 2;
  Rad := Min(R.Right - R.Left, R.Bottom - R.Top) div 2 - ScaleForDpi(1);
  if Rad < 4 then Rad := 4;

  Sym        := '';
  SymColor   := clWhite;
  SymOffsetY := 0;

  case FKind of
    mtWarning:
      begin
        DrawAntiAliasedTriangle(Canvas,
          Point(CX,       CY - Rad),
          Point(CX + Rad, CY + Rad),
          Point(CX - Rad, CY + Rad),
          RGBToColor(245, 190, 20),
          GetCornerBackgroundColor);
        Sym      := '!';
        SymColor := clBlack;
        // The triangle's mass is concentrated towards its base, so its
        // visual centre lies below the geometric one. Placing the mark
        // at the centroid (CY + Rad/3) keeps it visually balanced.
        SymOffsetY := Rad div 3 - ScaleForDpi(2);
      end;

    mtError:
      begin
        BG := RGBToColor(210, 40, 40);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, GetCornerBackgroundColor);
        Sym := 'X';
      end;

    mtInformation:
      begin
        BG := RGBToColor(40, 120, 220);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, GetCornerBackgroundColor);
        Sym := 'i';
      end;

    mtConfirmation:
      begin
        BG := RGBToColor(40, 120, 220);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, GetCornerBackgroundColor);
        Sym := '?';
      end;
  end;

  if Sym = '' then Exit;

  SavedFont := TFont.Create;
  try
    SavedFont.Assign(Canvas.Font);
    Canvas.Font.Name  := 'Arial';
    Canvas.Font.Size  := Max(8, Rad);
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := SymColor;

    TW := Canvas.TextWidth(Sym);
    TH := Canvas.TextHeight(Sym);
    TX := CX - TW div 2;
    TY := CY - TH div 2 + SymOffsetY;

    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(TX, TY, Sym);
  finally
    Canvas.Font.Assign(SavedFont);
    SavedFont.Free;
  end;
end;

{ =========================================================================== }
{  TCssMessageForm                                                            }
{ =========================================================================== }

constructor TCssMessageForm.CreateMessageDialog(
  AOwner: TComponent;
  ADlgType: TMsgDlgType;
  const AMessage: string;
  AButtons: TMsgDlgButtons;
  ADefault: TMsgDlgBtn;
  AInputMode, APasswordMode: Boolean;
  const ADefaultText: string;
  const ACaption: string);
const
  ORDER: array[0..11] of TMsgDlgBtn = (
    mbYes, mbYesToAll, mbNo, mbNoToAll,
    mbOK,  mbAbort,    mbRetry, mbIgnore,
    mbAll, mbCancel,   mbClose, mbHelp
  );
var
  PadPx, SpacingPx, IconPx, EditHPx: Integer;
  BtnWPx, BtnHPx, BtnGapPx: Integer;
  ClientW, ContentTop, ContentBottom: Integer;
  MsgWidth, MsgHeight, MsgTextH: Integer;
  LabelBorder: Integer;
  LabelPad: TRect;
  ContentW, ContentH: Integer;
  DividerW, Gap1, Gap2: Integer;
  IconLeft, DivLeft, TextLeft: Integer;
  IconTop, LabelTop: Integer;
  DivInset, DivTop, DivHeight: Integer;
  S: TSize;
  HasIcon, IsSingleLine: Boolean;
  Ordered: array of TMsgDlgBtn;
  I, TotalBtnW, BtnX, BtnY: Integer;
  B: TCssButton;
  IsCancelLike: Boolean;
begin
  inherited CreateNew(AOwner);

  // The form is created entirely in code, so it has no design-time
  // size for the auto-scaler to use as a reference. Leaving Scaled on
  // makes LCL's dialog-unit machinery divide by a zero base unit while
  // the form is still being sized. Turn it off; the dialog lays itself
  // out explicitly below.
  Scaled := False;

  // A programmatically-created form does not inherit a valid font
  // from a design-time resource. The dialog-unit math needs a usable
  // font metric; without it the widgetset may divide by the base
  // unit's zero width.
  Font.Assign(Screen.SystemFont);

  FProvider     := FindProvider(AOwner);
  FStyleName    := GStyleName;
  FInputMode    := AInputMode;
  FPasswordMode := APasswordMode;
  FDefaultBtn   := nil;

  BorderStyle    := bsDialog;
  BorderIcons    := [biSystemMenu];
  Position       := poOwnerFormCenter;
  DoubleBuffered := True;
  KeyPreview     := True;
  OnKeyDown      := @FormKeyDown;
  OnClose        := @FormClose;
  Color          := clBtnFace;
  Caption        := ACaption;

  // --- Form-level CSS via TCssProxy ------------------------------------
  FProxy := TCssProxy.Create(Self);
  FProxy.FormStyleName := MSGDLG_CSS_CLASS;
  FProxy.ThemeProvider := FProvider;

  // --- Backdrop panel --------------------------------------------------
  FBackdrop := TCssPanel.Create(Self);
  FBackdrop.Parent        := Self;
  FBackdrop.Align         := alClient;
  FBackdrop.CssTag        := MSGDLG_CSS_CLASS;
  FBackdrop.CssClass      := MSGDLG_CSS_CLASS;
  FBackdrop.Caption       := '';
  FBackdrop.ShowFocusRect := False;
  ApplyProvider(FBackdrop);

  // --- DPI scaling -----------------------------------------------------
  PadPx     := ScaleDpi(MSGDLG_PAD);
  SpacingPx := ScaleDpi(MSGDLG_SPACING);
  IconPx    := ScaleDpi(MSGDLG_ICON);
  EditHPx   := ScaleDpi(MSGDLG_EDIT_H);
  BtnWPx    := ScaleDpi(MSGDLG_BTN_W);
  BtnHPx    := ScaleDpi(MSGDLG_BTN_H);
  BtnGapPx  := ScaleDpi(MSGDLG_BTN_GAP);

  HasIcon := ADlgType in [mtWarning, mtError, mtInformation, mtConfirmation];
  ClientW := ScaleDpi(MSGDLG_DEF_W);

  // --- Message label ---------------------------------------------------
  // Created before the icon so that its CSS metrics (padding, border)
  // are known when the horizontal layout is computed.
  FMessage := TCssLabel.Create(Self);
  FMessage.Parent   := FBackdrop;
  FMessage.AutoSize := False;
  FMessage.WordWrap := True;
  FMessage.HtmlMode := GHtmlMode;
  FMessage.Caption  := AMessage;
  ApplyProvider(FMessage);

  LabelBorder := FMessage.GetStyledBorderWidth;
  LabelPad    := FMessage.GetStyledPadding;

  // Divider between icon and message. Only meaningful when there is an
  // icon; without it the label uses the full content width.
  if HasIcon then
    DividerW := ScaleDpi(MSGDLG_DIVIDER_W)
  else
    DividerW := 0;

  // Horizontal layout with symmetric gaps around the divider:
  //
  //   [ PadPx ][ Icon ][ PadPx ][ div ][ PadPx ][ Label ... ][ PadPx ]
  //
  // The gap to the left of the icon equals the gap between icon and
  // divider, which equals the gap between divider and text. The three
  // whitespace bands are therefore visually balanced.
  if HasIcon then
  begin
    Gap1     := PadPx;
    Gap2     := PadPx;
    IconLeft := PadPx;
    DivLeft  := IconLeft + IconPx + Gap1;
    TextLeft := DivLeft + DividerW + Gap2;
  end
  else
  begin
    Gap1     := 0;
    Gap2     := 0;
    IconLeft := 0;
    DivLeft  := 0;
    TextLeft := PadPx;
  end;

  MsgWidth := ClientW - TextLeft - PadPx;
  if MsgWidth < ScaleDpi(20) then
    MsgWidth := ScaleDpi(20);

  ContentW := MsgWidth - 2 * LabelBorder - LabelPad.Left - LabelPad.Right;
  if ContentW < ScaleDpi(20) then
    ContentW := ScaleDpi(20);

  // Realise the handle chain before measuring. A handleless TCanvas
  // returns garbage from TextHeight / TextWidth in LCL instead of
  // failing, and that garbage used to propagate into ClientHeight,
  // triggering the INT DIVIDE BY ZERO inside the widgetset's dialog
  // unit code. HandleNeeded walks up the parent chain, so this single
  // call creates the window handles for the form, the backdrop and
  // the label in one go.
  FMessage.HandleNeeded;

  if FMessage.HtmlMode then
    S := FMessage.MeasureStyledTextSize(FMessage.Canvas, AMessage, ContentW)
  else
    S := MeasureDialogPlainText(FMessage.Canvas, AMessage, ContentW);

  // Sanity clamp. Even with a valid HDC some fonts under some
  // widgetsets return absurd numbers for an empty or whitespace-only
  // string. Never allow that to reach the layout math.
  if (S.cy <= 0) or (S.cy > ScaleDpi(4000)) then
    S.cy := ScaleDpi(20);

  if (S.cx < 0) or (S.cx > ScaleDpi(4000)) then
    S.cx := ContentW;

  ContentH := S.cy;
  if ContentH < ScaleDpi(20) then
    ContentH := ScaleDpi(20);

  MsgTextH := ContentH + 2 * LabelBorder + LabelPad.Top + LabelPad.Bottom;

  // "Single-line" here means the whole text block fits within the
  // height of the icon. In that case the vertical centres of the text
  // and the icon can be aligned and the result reads as one row.
  // Anything taller is treated as a multi-line message: the text stays
  // anchored at the top and the icon floats in the middle of the block,
  // which is how the standard Windows MessageBox behaves.
  IsSingleLine := HasIcon and (ContentH <= IconPx);

  // --- Divider ---------------------------------------------------------
  // A one-pixel vertical strip between the icon and the text. Its
  // colour comes from the `.msgdialog-divider` CSS rule, so it follows
  // the active theme automatically.
  if HasIcon then
  begin
    FDivider := TCssPanel.Create(Self);
    FDivider.Parent        := FBackdrop;
    FDivider.CssTag        := 'msgdialog-divider';
    FDivider.CssClass      := 'msgdialog-divider';
    FDivider.Caption       := '';
    FDivider.ShowFocusRect := False;
    ApplyProvider(FDivider);
  end;

  // --- Icon and vertical placement -------------------------------------
  if HasIcon then
  begin
    FIcon := TCssMessageIcon.Create(Self);
    FIcon.Parent := FBackdrop;
    FIcon.Kind   := ADlgType;
    ApplyProvider(FIcon);

    if IsSingleLine then
    begin
      // Single line: the icon and the text share a common vertical
      // centre. The block height is whichever of the two is taller;
      // both are centred within it.
      MsgHeight := Max(MsgTextH, IconPx);
      IconTop   := PadPx + (MsgHeight - IconPx) div 2;
      LabelTop  := PadPx + (MsgHeight - MsgTextH) div 2;
    end
    else
    begin
      // Multi-line: the text anchors to the top, the icon floats in
      // the middle of the whole block. The block height accommodates
      // the taller of the two so neither is clipped.
      MsgHeight := Max(MsgTextH, IconPx);
      IconTop   := PadPx + (MsgHeight - IconPx) div 2;
      LabelTop  := PadPx;
    end;

    FIcon.SetBounds(IconLeft, IconTop, IconPx, IconPx);

    // Divider: vertically centred within the message block, with a
    // small top and bottom inset so it does not touch the panel edges.
    DivInset := ScaleDpi(4);
    if MsgHeight < DivInset * 3 then
      DivInset := 0;

    DivTop    := PadPx + DivInset;
    DivHeight := MsgHeight - 2 * DivInset;
    if DivHeight < ScaleDpi(4) then
      DivHeight := MsgHeight;

    FDivider.SetBounds(DivLeft, DivTop, DividerW, DivHeight);
  end
  else
  begin
    MsgHeight := MsgTextH;
    LabelTop  := PadPx;
  end;

  // --- Label geometry --------------------------------------------------
  FMessage.SetBounds(TextLeft, LabelTop, MsgWidth, MsgTextH);

  ContentTop := PadPx + MsgHeight + SpacingPx;

  // --- Input edit ------------------------------------------------------
  if FInputMode then
  begin
    FEdit := TCssEdit.Create(Self);
    FEdit.Parent := FBackdrop;
    FEdit.Text   := ADefaultText;
    if FPasswordMode then
      FEdit.PasswordChar := '*';
    FEdit.SetBounds(PadPx, ContentTop, ClientW - PadPx * 2, EditHPx);
    ApplyProvider(FEdit);

    FEdit.SelectAll;

    ContentTop := ContentTop + EditHPx + SpacingPx;
  end;

  // --- Buttons ---------------------------------------------------------
  SetLength(Ordered, 0);
  for I := Low(ORDER) to High(ORDER) do
    if ORDER[I] in AButtons then
    begin
      SetLength(Ordered, Length(Ordered) + 1);
      Ordered[High(Ordered)] := ORDER[I];
    end;

  if Length(Ordered) = 0 then
  begin
    SetLength(Ordered, 1);
    Ordered[0] := mbOK;
  end;

  TotalBtnW := Length(Ordered) * BtnWPx + (Length(Ordered) - 1) * BtnGapPx;
  BtnX      := ClientW - PadPx - TotalBtnW;
  BtnY      := ContentTop;

  SetLength(FButtons, Length(Ordered));

  for I := 0 to High(Ordered) do
  begin
    B := TCssButton.Create(Self);
    B.Parent      := FBackdrop;
    B.AutoSize    := False;
    B.Caption     := BtnCaption(Ordered[I]);
    B.ModalResult := TModalResult(BtnResult(Ordered[I]));
    B.Tag         := BtnResult(Ordered[I]);

    if Ordered[I] = ADefault then
    begin
      B.Default   := True;
      FDefaultBtn := B;
    end;

    // Esc should pick Cancel > No > Close > Abort, matching LCL.
    IsCancelLike :=
      (Ordered[I] = mbCancel) or
      ((Ordered[I] = mbNo)    and not (mbCancel in AButtons)) or
      ((Ordered[I] = mbClose) and not (mbCancel in AButtons)) or
      ((Ordered[I] = mbAbort) and not (mbCancel in AButtons)
                              and not (mbNo in AButtons));

    if IsCancelLike then
      B.Cancel := True;

    ApplyProvider(B);
    B.SetBounds(BtnX, BtnY, BtnWPx, BtnHPx);
    FButtons[I] := B;

    Inc(BtnX, BtnWPx + BtnGapPx);
  end;

  ContentBottom := BtnY + BtnHPx + PadPx;

  // Set both client dimensions with align recalculation suspended.
  // Two consecutive assignments without this guard produce an
  // intermediate WM_SIZE with the form partially sized; on some LCL
  // versions that intermediate state makes the widgetset divide by
  // zero while it recomputes the dialog's border / dialog-unit metrics.
  DisableAlign;
  try
    ClientWidth  := ClientW;
    ClientHeight := ContentBottom;
  finally
    EnableAlign;
  end;

  // Apply form-level CSS synchronously; the async queue has not started.
  if FProvider <> nil then
    FProxy.ApplyStyles;

  // --- Active control --------------------------------------------------
  if FEdit <> nil then
    ActiveControl := FEdit
  else if FDefaultBtn <> nil then
    ActiveControl := FDefaultBtn;
end;

function TCssMessageForm.ScaleDpi(APx: Integer): Integer;
var
  PPI: Integer;
begin
  PPI := Screen.PixelsPerInch;
  if PPI <= 0 then PPI := 96;
  Result := Round(APx * PPI / 96.0);
end;

procedure TCssMessageForm.ApplyProvider(AControl: TCssStyledControl);
begin
  if FProvider <> nil then
  begin
    AControl.StyleProvider := FProvider;
    AControl.StyleName     := FStyleName;
  end;
end;

function TCssMessageForm.BtnCaption(ABtn: TMsgDlgBtn): string;
begin
  case ABtn of
    mbYes:      Result := 'Yes';
    mbYesToAll: Result := 'Yes to All';
    mbNo:       Result := 'No';
    mbNoToAll:  Result := 'No to All';
    mbOK:       Result := 'OK';
    mbCancel:   Result := 'Cancel';
    mbAbort:    Result := 'Abort';
    mbRetry:    Result := 'Retry';
    mbIgnore:   Result := 'Ignore';
    mbAll:      Result := 'All';
    mbClose:    Result := 'Close';
    mbHelp:     Result := 'Help';
  else
    Result := '';
  end;
end;

function TCssMessageForm.BtnResult(ABtn: TMsgDlgBtn): Integer;
begin
  case ABtn of
    mbYes:      Result := mrYes;
    mbYesToAll: Result := mrYesToAll;
    mbNo:       Result := mrNo;
    mbNoToAll:  Result := mrNoToAll;
    mbOK:       Result := mrOk;
    mbCancel:   Result := mrCancel;
    mbAbort:    Result := mrAbort;
    mbRetry:    Result := mrRetry;
    mbIgnore:   Result := mrIgnore;
    mbAll:      Result := mrAll;
    mbClose:    Result := mrClose;
    mbHelp:     Result := mrCssHelp;
  else
    Result := mrNone;
  end;
end;

procedure TCssMessageForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
  Target: TCssButton;
begin
  if Key = VK_ESCAPE then
  begin
    Target := nil;
    for I := 0 to High(FButtons) do
      if FButtons[I].ModalResult = mrCancel then
      begin
        Target := FButtons[I];
        Break;
      end;

    if Target = nil then
      for I := 0 to High(FButtons) do
        if FButtons[I].ModalResult = mrNo then
        begin
          Target := FButtons[I];
          Break;
        end;

    if Target = nil then
      for I := 0 to High(FButtons) do
        if FButtons[I].ModalResult = mrAbort then
        begin
          Target := FButtons[I];
          Break;
        end;

    if Target <> nil then
    begin
      Target.Click;
      Key := 0;
    end;

    Exit;
  end;

  if Key = VK_RETURN then
  begin
    if (FDefaultBtn <> nil) and FDefaultBtn.Enabled then
    begin
      FDefaultBtn.Click;
      Key := 0;
    end;
  end;
end;

procedure TCssMessageForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if ModalResult = mrNone then
    ModalResult := mrCancel;
end;

function TCssMessageForm.GetEditText: string;
begin
  if FEdit <> nil then
    Result := FEdit.Text
  else
    Result := '';
end;

{ =========================================================================== }
{  Public API                                                                 }
{ =========================================================================== }

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string;
  ADefaultBtn: TMsgDlgBtn): Integer;
var
  Dlg: TCssMessageForm;
  DefBtn: TMsgDlgBtn;
  Cap: string;
begin
  if ADefaultBtn in Buttons then
    DefBtn := ADefaultBtn
  else
    DefBtn := PickDefaultButton(Buttons);

  if ACaption = '' then
    Cap := DefaultDialogCaption
  else
    Cap := ACaption;

  Dlg := TCssMessageForm.CreateMessageDialog(
    GetDialogOwner, DlgType, Msg, Buttons, DefBtn,
    False, False, '', Cap);
  try
    if (X <> -1) or (Y <> -1) then
      Dlg.Position := poDesigned;
    if X <> -1 then Dlg.Left := X;
    if Y <> -1 then Dlg.Top  := Y;

    Result := Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, X, Y,
    ACaption, PickDefaultButton(Buttons));
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', ADefaultBtn);
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt; X, Y: Integer): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', PickDefaultButton(Buttons));
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, ADefaultBtn);
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, PickDefaultButton(Buttons));
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', ADefaultBtn);
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt): Integer;
begin
  Result := CssMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', PickDefaultButton(Buttons));
end;

procedure CssShowMessage(const Msg: string);
begin
  CssMessageDlg(Msg, mtCustom, [mbOK], 0);
end;

procedure CssShowMessageFmt(const Msg: string; Params: array of const);
begin
  CssShowMessage(Format(Msg, Params));
end;

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt; ADefaultBtn: TMsgDlgBtn): Integer;
var
  DlgType: TMsgDlgType;
  Btns: TMsgDlgButtons;
  DefBtn: TMsgDlgBtn;
  BtnFlags: Integer;
begin
  if (AFlags and MB_ICONERROR) = MB_ICONERROR then
    DlgType := mtError
  else if (AFlags and MB_ICONQUESTION) = MB_ICONQUESTION then
    DlgType := mtConfirmation
  else if (AFlags and MB_ICONWARNING) = MB_ICONWARNING then
    DlgType := mtWarning
  else if (AFlags and MB_ICONINFORMATION) = MB_ICONINFORMATION then
    DlgType := mtInformation
  else
    DlgType := mtCustom;

  BtnFlags := AFlags and $0F;
  case BtnFlags of
    MB_OKCANCEL:         Btns := [mbOK, mbCancel];
    MB_YESNO:            Btns := [mbYes, mbNo];
    MB_YESNOCANCEL:      Btns := [mbYes, mbNo, mbCancel];
    MB_ABORTRETRYIGNORE: Btns := [mbAbort, mbRetry, mbIgnore];
    MB_RETRYCANCEL:      Btns := [mbRetry, mbCancel];
  else
    Btns := [mbOK];
  end;

  if ADefaultBtn in Btns then
    DefBtn := ADefaultBtn
  else
    DefBtn := PickDefaultButton(Btns);

  with TCssMessageForm.CreateMessageDialog(
    GetDialogOwner, DlgType, AMsg, Btns, DefBtn,
    False, False, '', ACaption) do
  try
    Result := ShowModal;
  finally
    Free;
  end;
end;

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt): Integer;
var
  BtnFlags, DefFlags: Integer;
  Btns: TMsgDlgButtons;
  DefBtn: TMsgDlgBtn;
begin
  BtnFlags := AFlags and $0F;
  case BtnFlags of
    MB_OKCANCEL:         Btns := [mbOK, mbCancel];
    MB_YESNO:            Btns := [mbYes, mbNo];
    MB_YESNOCANCEL:      Btns := [mbYes, mbNo, mbCancel];
    MB_ABORTRETRYIGNORE: Btns := [mbAbort, mbRetry, mbIgnore];
    MB_RETRYCANCEL:      Btns := [mbRetry, mbCancel];
  else
    Btns := [mbOK];
  end;

  DefFlags := (AFlags and $F00) shr 8;
  DefBtn := mbOK;
  case DefFlags of
    2: if mbYes in Btns then DefBtn := mbYes
       else if mbCancel in Btns then DefBtn := mbCancel;
    3: if mbNo in Btns then DefBtn := mbNo
       else if mbRetry in Btns then DefBtn := mbRetry;
    4: if mbIgnore in Btns then DefBtn := mbIgnore;
  else
    if mbOK in Btns then DefBtn := mbOK;
  end;

  Result := CssMessageBox(ACaption, AMsg, AFlags, DefBtn);
end;

function CssInputQuery(const ACaption, APrompt: string;
  var AValue: string): Boolean;
var
  Dlg: TCssMessageForm;
begin
  Dlg := TCssMessageForm.CreateMessageDialog(
    GetDialogOwner, mtCustom, APrompt,
    [mbOK, mbCancel], mbOK, True, False, AValue, ACaption);
  try
    Result := Dlg.ShowModal = mrOk;
    if Result then
      AValue := Dlg.GetEditText;
  finally
    Dlg.Free;
  end;
end;

function CssInputBox(const ACaption, APrompt, ADefault: string): string;
var
  Value: string;
begin
  Value := ADefault;
  if not CssInputQuery(ACaption, APrompt, Value) then
    Value := ADefault;
  Result := Value;
end;

function CssPasswordBox(const ACaption, APrompt: string): string;
var
  Dlg: TCssMessageForm;
begin
  Dlg := TCssMessageForm.CreateMessageDialog(
    GetDialogOwner, mtCustom, APrompt,
    [mbOK, mbCancel], mbOK, True, True, '', ACaption);
  try
    if Dlg.ShowModal = mrOk then
      Result := Dlg.GetEditText
    else
      Result := '';
  finally
    Dlg.Free;
  end;
end;

end.
