unit CssMessageDialogs;

{$mode objfpc}{$H+}

{
  CssMessageDlg - CSS-styled replacements for the standard Dialogs functions.

  Public functions (all prefixed with Css to avoid clashes with Dialogs):
    CssShowMessage, CssShowMessageFmt, CssMessageDlg, CssMessageDlgPos,
    CssMessageBox, CssInputBox, CssInputQuery, CssPasswordBox,
    CssMessageDlgIcon, CssMessageDlgPosIcon, CssMessageBoxIcon.

  HTML formatting of message text is OFF by default. Call
  CssMessageDlgSetHtmlMode(True) once to enable it globally.

  Link-click handling
  -------------------
  HTML links inside the message text can be handled in two ways:

    * globally, for every dialog:
        CssMessageDlgSetOnLinkClick(@MyHandler);

    * per dialog, for one specific instance:
        Dlg := TCssMessageForm.CreateMessageDialog(..., @MyHandler);

  The per-dialog handler wins over the global one. In either case the
  Sender passed to the handler is the TCssMessageForm itself.

  Custom icons
  ------------
  The SVG image source for dialog icons is a single, application-wide
  TCssSvgImgList. It is set once:

      CssMessageDlgSetIconSource(CssSvgImgList1);

  Individual dialog calls then select an item from that source with an
  explicit index:

      CssMessageDlgIcon('msg', mtInformation, [mbOK], 0, 5);

  If the source is nil or the index is out of range, the dialog falls
  back to the built-in shapes (warning triangle, error cross, etc.).
}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, GraphType, Types,
  LCLType, Dialogs,
  CssStyledControl, CssButtonControl,
  CssLabelControl, CssEditControl,
  CssProxyControl, CssPanelControl,
  CssSvgImgList;

type
  TCssMessageIcon = class(TCssStyledControl)
  private
    FKind: TMsgDlgType;
    FSvgImages: TCssSvgImgList;
    FSvgImageIndex: Integer;
    FSvgVariant: string;

    procedure SetKind(AValue: TMsgDlgType);
    procedure SetSvgImages(AValue: TCssSvgImgList);
    procedure SetSvgImageIndex(AValue: Integer);
    procedure SetSvgVariant(const AValue: string);

    function HasSvgIcon: Boolean;
  protected
    procedure Paint; override;
    function  ShouldPaintCaption: Boolean; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    property Kind: TMsgDlgType read FKind write SetKind;
    property SvgImages: TCssSvgImgList
      read FSvgImages write SetSvgImages;
    property SvgImageIndex: Integer
      read FSvgImageIndex write SetSvgImageIndex;
    property SvgVariant: string
      read FSvgVariant write SetSvgVariant;
  end;

  TCssMessageForm = class(TForm)
  private
    FProvider: TCssStyleProvider;
    FStyleName: string;
    FOnLinkClick: TCssLinkClickEvent;

    FSvgImages: TCssSvgImgList;
    FSvgImageIndex: Integer;

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

    procedure SetOnLinkClick(AValue: TCssLinkClickEvent);
    procedure MessageLinkClick(Sender: TObject;
      const AHref, AText: AnsiString);
  public
    constructor CreateMessageDialog(
      AOwner: TComponent;
      ADlgType: TMsgDlgType;
      const AMessage: string;
      AButtons: TMsgDlgButtons;
      ADefault: TMsgDlgBtn;
      AInputMode, APasswordMode: Boolean;
      const ADefaultText: string;
      const ACaption: string = '';
      AOnLinkClick: TCssLinkClickEvent = nil;
      AIconIndex: Integer = -1);

    function GetEditText: string;

    property OnLinkClick: TCssLinkClickEvent
      read FOnLinkClick write SetOnLinkClick;
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

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer): Integer; overload;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
  const ACaption: string): Integer; overload;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
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

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer): Integer; overload;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  const ACaption: string): Integer; overload;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer; overload;

procedure CssShowMessage(const Msg: string);
procedure CssShowMessageFmt(const Msg: string; Params: array of const);

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt): Integer; overload;

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt; ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssMessageBoxIcon(const ACaption, AMsg: string;
  AFlags: LongInt; AIconIndex: Integer): Integer; overload;

function CssMessageBoxIcon(const ACaption, AMsg: string;
  AFlags: LongInt; AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer; overload;

function CssInputBox(const ACaption, APrompt, ADefault: string): string;
function CssInputQuery(const ACaption, APrompt: string;
  var AValue: string): Boolean;

function CssPasswordBox(const ACaption, APrompt: string): string;

procedure CssMessageDlgSetStyleProvider(AProvider: TCssStyleProvider;
  const AStyleName: string = '');

procedure CssMessageDlgSetHtmlMode(AEnabled: Boolean);

procedure CssMessageDlgSetOnLinkClick(AHandler: TCssLinkClickEvent);

procedure CssMessageDlgSetIconSource(AImages: TCssSvgImgList);

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
  GProvider:    TCssStyleProvider  = nil;
  GStyleName:   string             = '';
  GHtmlMode:    Boolean            = False;
  GOnLinkClick: TCssLinkClickEvent = nil;
  GSvgImages:   TCssSvgImgList     = nil;

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

procedure CssMessageDlgSetOnLinkClick(AHandler: TCssLinkClickEvent);
begin
  GOnLinkClick := AHandler;
end;

procedure CssMessageDlgSetIconSource(AImages: TCssSvgImgList);
begin
  GSvgImages := AImages;
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
  FKind          := mtInformation;
  FSvgImages     := nil;
  FSvgImageIndex := -1;
  FSvgVariant    := '';
  TabStop        := False;
  CssTag         := 'msgdlg-icon';

  CssStyle := 'background-color: transparent; border: none; border-radius: 0px;';
end;

destructor TCssMessageIcon.Destroy;
begin
  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  inherited Destroy;
end;

procedure TCssMessageIcon.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FSvgImages) then
  begin
    FSvgImages := nil;
    Invalidate;
  end;
end;

procedure TCssMessageIcon.SetKind(AValue: TMsgDlgType);
begin
  if FKind = AValue then Exit;
  FKind := AValue;
  Invalidate;
end;

procedure TCssMessageIcon.SetSvgImages(AValue: TCssSvgImgList);
begin
  if FSvgImages = AValue then Exit;

  if FSvgImages <> nil then
    FSvgImages.RemoveFreeNotification(Self);

  FSvgImages := AValue;

  if FSvgImages <> nil then
    FSvgImages.FreeNotification(Self);

  Invalidate;
end;

procedure TCssMessageIcon.SetSvgImageIndex(AValue: Integer);
begin
  if AValue < -1 then AValue := -1;
  if FSvgImageIndex = AValue then Exit;
  FSvgImageIndex := AValue;
  Invalidate;
end;

procedure TCssMessageIcon.SetSvgVariant(const AValue: string);
begin
  if FSvgVariant = AValue then Exit;
  FSvgVariant := AValue;
  Invalidate;
end;

function TCssMessageIcon.HasSvgIcon: Boolean;
begin
  Result :=
    (FSvgImages <> nil) and
    (FSvgImageIndex >= 0) and
    (FSvgImageIndex < FSvgImages.Count);
end;

function TCssMessageIcon.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

procedure TCssMessageIcon.Paint;
var
  R, IconR: TRect;
  BgColor: TColor;
  CX, CY, Rad: Integer;
  BG, SymColor: TColor;
  Sym: string;
  SymOffsetY: Integer;
  SavedFont: TFont;
  TW, TH, TX, TY, Size: Integer;
  Bmp: TBitmap;
begin
  R := ClientRect;
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  // ------------------------------------------------------------------
  //  Background.
  //
  //  Deliberately NOT calling inherited Paint: the base class fills
  //  the control with GetParentBackgroundColor, which silently falls
  //  back to clBtnFace whenever the CSS lookup fails at paint time.
  //  On a themed dialog panel that produces an ugly grey block around
  //  the icon. Here we use the colour the dialog passed explicitly via
  //  SetExternalBackgroundColor, or — as a fallback — the same value
  //  the parent lookup would produce.
  // ------------------------------------------------------------------
  BgColor := GetCornerBackgroundColor;      // honour SetExternalBackgroundColor
  if (BgColor = clNone) or (BgColor = clDefault) then
    BgColor := GetParentBackgroundColor;
  if (BgColor = clNone) or (BgColor = clDefault) then
    BgColor := clWindow;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BgColor;
  Canvas.FillRect(R);

  // ------------------------------------------------------------------
  //  SVG path: a custom icon fully replaces the built-in shapes.
  // ------------------------------------------------------------------
  if HasSvgIcon then
  begin
    Size := Min(R.Width, R.Height);
    if Size <= 0 then Exit;

    IconR := Rect(
      R.Left + (R.Width  - Size) div 2,
      R.Top  + (R.Height - Size) div 2,
      R.Left + (R.Width  - Size) div 2 + Size,
      R.Top  + (R.Height - Size) div 2 + Size);

    Bmp := FSvgImages.GetBitmap(
      FSvgImageIndex, Size, Size,
      GetEffectiveTextColor,
      FSvgVariant);
    try
      DrawSvgBitmapWithAlpha(Canvas, IconR.Left, IconR.Top, Bmp);
    finally
      Bmp.Free;
    end;

    Exit;
  end;

  // ------------------------------------------------------------------
  //  Built-in shapes.
  // ------------------------------------------------------------------
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
          BgColor);
        Sym      := '!';
        SymColor := clBlack;
        SymOffsetY := Rad div 3 - ScaleForDpi(2);
      end;

    mtError:
      begin
        BG := RGBToColor(210, 40, 40);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, BgColor);
        Sym := 'X';
      end;

    mtInformation:
      begin
        BG := RGBToColor(40, 120, 220);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, BgColor);
        Sym := 'i';
      end;

    mtConfirmation:
      begin
        BG := RGBToColor(40, 120, 220);
        DrawAntiAliasedCircle(Canvas,
          Rect(CX - Rad, CY - Rad, CX + Rad, CY + Rad),
          BG, BG, 0, BgColor);
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
  const ACaption: string;
  AOnLinkClick: TCssLinkClickEvent;
  AIconIndex: Integer);
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

  Scaled := False;
  Font.Assign(Screen.SystemFont);

  FProvider     := FindProvider(AOwner);
  FStyleName    := GStyleName;
  FInputMode    := AInputMode;
  FPasswordMode := APasswordMode;
  FDefaultBtn   := nil;

  FOnLinkClick := AOnLinkClick;
  if FOnLinkClick = nil then
    FOnLinkClick := GOnLinkClick;

  FSvgImages     := GSvgImages;
  FSvgImageIndex := AIconIndex;

  BorderStyle    := bsDialog;
  BorderIcons    := [biSystemMenu];
  Position       := poOwnerFormCenter;
  DoubleBuffered := True;
  KeyPreview     := True;
  OnKeyDown      := @FormKeyDown;
  OnClose        := @FormClose;
  Color          := clBtnFace;
  Caption        := ACaption;

  FProxy := TCssProxy.Create(Self);
  FProxy.FormStyleName := MSGDLG_CSS_CLASS;
  FProxy.ThemeProvider := FProvider;

  FBackdrop := TCssPanel.Create(Self);
  FBackdrop.Parent        := Self;
  FBackdrop.Align         := alClient;
  FBackdrop.CssTag        := MSGDLG_CSS_CLASS;
  FBackdrop.CssClass      := MSGDLG_CSS_CLASS;
  FBackdrop.Caption       := '';
  FBackdrop.ShowFocusRect := False;
  ApplyProvider(FBackdrop);

  PadPx     := ScaleDpi(MSGDLG_PAD);
  SpacingPx := ScaleDpi(MSGDLG_SPACING);
  IconPx    := ScaleDpi(MSGDLG_ICON);
  EditHPx   := ScaleDpi(MSGDLG_EDIT_H);
  BtnWPx    := ScaleDpi(MSGDLG_BTN_W);
  BtnHPx    := ScaleDpi(MSGDLG_BTN_H);
  BtnGapPx  := ScaleDpi(MSGDLG_BTN_GAP);

  HasIcon :=
    (ADlgType in [mtWarning, mtError, mtInformation, mtConfirmation]) or
    ((FSvgImages <> nil) and
     (FSvgImageIndex >= 0) and
     (FSvgImageIndex < FSvgImages.Count));

  ClientW := ScaleDpi(MSGDLG_DEF_W);

  FMessage := TCssLabel.Create(Self);
  FMessage.Parent   := FBackdrop;
  FMessage.AutoSize := False;
  FMessage.WordWrap := True;
  FMessage.HtmlMode := GHtmlMode;
  FMessage.Caption  := AMessage;
  ApplyProvider(FMessage);

  FMessage.OnLinkClick := @MessageLinkClick;

  LabelBorder := FMessage.GetStyledBorderWidth;
  LabelPad    := FMessage.GetStyledPadding;

  if HasIcon then
    DividerW := ScaleDpi(MSGDLG_DIVIDER_W)
  else
    DividerW := 0;

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

  FMessage.HandleNeeded;

  if FMessage.HtmlMode then
    S := FMessage.MeasureStyledTextSize(FMessage.Canvas, AMessage, ContentW)
  else
    S := MeasureDialogPlainText(FMessage.Canvas, AMessage, ContentW);

  if (S.cy <= 0) or (S.cy > ScaleDpi(4000)) then
    S.cy := ScaleDpi(20);

  if (S.cx < 0) or (S.cx > ScaleDpi(4000)) then
    S.cx := ContentW;

  ContentH := S.cy;
  if ContentH < ScaleDpi(20) then
    ContentH := ScaleDpi(20);

  MsgTextH := ContentH + 2 * LabelBorder + LabelPad.Top + LabelPad.Bottom;

  IsSingleLine := HasIcon and (ContentH <= IconPx);

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

  if HasIcon then
  begin
    FIcon := TCssMessageIcon.Create(Self);
    FIcon.Parent        := FBackdrop;

    if FBackdrop <> nil then
      FIcon.SetExternalBackgroundColor(FBackdrop.GetStyledBackgroundColor);

    FIcon.Kind          := ADlgType;
    FIcon.SvgImages     := FSvgImages;
    FIcon.SvgImageIndex := FSvgImageIndex;

    if FSvgImages <> nil then
      FIcon.SvgVariant := FStyleName
    else
      FIcon.SvgVariant := '';

    ApplyProvider(FIcon);

    if IsSingleLine then
    begin
      MsgHeight := Max(MsgTextH, IconPx);
      IconTop   := PadPx + (MsgHeight - IconPx) div 2;
      LabelTop  := PadPx + (MsgHeight - MsgTextH) div 2;
    end
    else
    begin
      MsgHeight := Max(MsgTextH, IconPx);
      IconTop   := PadPx + (MsgHeight - IconPx) div 2;
      LabelTop  := PadPx;
    end;

    FIcon.SetBounds(IconLeft, IconTop, IconPx, IconPx);

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

  FMessage.SetBounds(TextLeft, LabelTop, MsgWidth, MsgTextH);

  ContentTop := PadPx + MsgHeight + SpacingPx;

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

  DisableAlign;
  try
    ClientWidth  := ClientW;
    ClientHeight := ContentBottom;
  finally
    EnableAlign;
  end;

  if FProvider <> nil then
    FProxy.ApplyStyles;

  if FEdit <> nil then
    ActiveControl := FEdit
  else if FDefaultBtn <> nil then
    ActiveControl := FDefaultBtn;
end;

procedure TCssMessageForm.SetOnLinkClick(AValue: TCssLinkClickEvent);
begin
  FOnLinkClick := AValue;
end;

procedure TCssMessageForm.MessageLinkClick(Sender: TObject;
  const AHref, AText: AnsiString);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, AHref, AText);
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

{ =========================================================================== }
{  Public API                                                                 }
{ =========================================================================== }

{ Internal worker. All public wrappers — with and without an explicit
  icon index — funnel through here. It is intentionally NOT declared in
  the interface section, so it never collides with the public overloads
  of CssMessageDlgPos during overload resolution. }
function CssMessageDlgPosEx(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string;
  ADefaultBtn: TMsgDlgBtn; AIconIndex: Integer): Integer;
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
    False, False, '', Cap, nil, AIconIndex);
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

{ --- CssMessageDlgPos: all four overloads declared in interface --- }

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', PickDefaultButton(Buttons), -1);
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', ADefaultBtn, -1);
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    ACaption, PickDefaultButton(Buttons), -1);
end;

function CssMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; const ACaption: string;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    ACaption, ADefaultBtn, -1);
end;

{ --- CssMessageDlg: all four overloads declared in interface --- }

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', PickDefaultButton(Buttons), -1);
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', ADefaultBtn, -1);
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, PickDefaultButton(Buttons), -1);
end;

function CssMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, ADefaultBtn, -1);
end;

{ --- CssMessageDlgIcon: all four overloads declared in interface --- }

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', PickDefaultButton(Buttons), AIconIndex);
end;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    '', ADefaultBtn, AIconIndex);
end;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
  const ACaption: string): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, PickDefaultButton(Buttons), AIconIndex);
end;

function CssMessageDlgIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  AIconIndex: Integer;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, -1, -1,
    ACaption, ADefaultBtn, AIconIndex);
end;

{ --- CssMessageDlgPosIcon: all four overloads declared in interface --- }

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', PickDefaultButton(Buttons), AIconIndex);
end;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    '', ADefaultBtn, AIconIndex);
end;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  const ACaption: string): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    ACaption, PickDefaultButton(Buttons), AIconIndex);
end;

function CssMessageDlgPosIcon(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: LongInt;
  X, Y: Integer; AIconIndex: Integer;
  const ACaption: string; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageDlgPosEx(Msg, DlgType, Buttons, HelpCtx, X, Y,
    ACaption, ADefaultBtn, AIconIndex);
end;

{ --- Simple helpers --- }

procedure CssShowMessage(const Msg: string);
begin
  CssMessageDlg(Msg, mtCustom, [mbOK], 0);
end;

procedure CssShowMessageFmt(const Msg: string; Params: array of const);
begin
  CssShowMessage(Format(Msg, Params));
end;

{ --- CssMessageBox family --- }

function CssMessageBoxEx(const ACaption, AMsg: string;
  AFlags: LongInt; ADefaultBtn: TMsgDlgBtn;
  AIconIndex: Integer): Integer;
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
    False, False, '', ACaption, nil, AIconIndex) do
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

  Result := CssMessageBoxEx(ACaption, AMsg, AFlags, DefBtn, -1);
end;

function CssMessageBox(const ACaption, AMsg: string;
  AFlags: LongInt; ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageBoxEx(ACaption, AMsg, AFlags, ADefaultBtn, -1);
end;

function CssMessageBoxIcon(const ACaption, AMsg: string;
  AFlags: LongInt; AIconIndex: Integer): Integer;
begin
  Result := CssMessageBoxEx(ACaption, AMsg, AFlags,
    PickDefaultButton([mbOK]), AIconIndex);
end;

function CssMessageBoxIcon(const ACaption, AMsg: string;
  AFlags: LongInt; AIconIndex: Integer;
  ADefaultBtn: TMsgDlgBtn): Integer;
begin
  Result := CssMessageBoxEx(ACaption, AMsg, AFlags,
    ADefaultBtn, AIconIndex);
end;

{ --- Input helpers --- }

function CssInputQuery(const ACaption, APrompt: string;
  var AValue: string): Boolean;
var
  Dlg: TCssMessageForm;
begin
  Dlg := TCssMessageForm.CreateMessageDialog(
    GetDialogOwner, mtCustom, APrompt,
    [mbOK, mbCancel], mbOK, True, False, AValue, ACaption, nil, -1);
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
    [mbOK, mbCancel], mbOK, True, True, '', ACaption, nil, -1);
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
