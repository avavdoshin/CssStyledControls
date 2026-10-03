unit CssStyledControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, LMessages, Forms;

type
  TCssTextAlign = (ctaLeft, ctaCenter, ctaRight);
  TCssVAlign = (cvaTop, cvaMiddle, cvaBottom);
  TCssBorderStyle = (cbsNone, cbsSolid, cbsDotted, cbsDashed);

  TCssLinkClickEvent = procedure(Sender: TObject; const AHref, AText: string) of object;

  TCssLinkStyle = record
    Color: TColor;
    HasColor: Boolean;
    Underline: Boolean;
    HasUnderline: Boolean;
    Cursor: TCursor;
    HasCursor: Boolean;
  end;

  TCssHtmlLinkInfo = record
    LinkId: Integer;
    Href: string;
    Text: string;
  end;

  TCssHtmlLinkInfos = array of TCssHtmlLinkInfo;

  TCssLinkArea = record
    LinkId: Integer;
    Href: string;
    Rect: TRect;
  end;

  TCssLinkAreas = array of TCssLinkArea;

  TCssStyledControl = class;

type
  TCssStyleProvider = class(TComponent)
  private
    FStyles: TStringList;
    FControls: TList;
    FDefaultStyleName: string;
    FFileName: string;
    FOnChange: TNotifyEvent;
    FLoading: Boolean;

    FRawCssText: string;
    FApplyingCssText: Boolean;

    function HasCssContent(const AText: string): Boolean;
    function SerializeStylesToCss: string;
    procedure InvalidateRawCss;

    function GetStyleCount: Integer;
    function GetStyleName(Index: Integer): string;
    function GetCssText: string;
    procedure SetCssText(const AValue: string);
    procedure SetDefaultStyleName(const AValue: string);
    procedure SetFileName(const AValue: string);

    function IndexOfStyle(const AName: string): Integer;
    procedure ClearStyles(Silent: Boolean);
    procedure DoChange;

    function IsVariantLine(const ALine: string; out AName: string): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    function HasStyle(const AName: string): Boolean;
    procedure AddOrUpdateStyle(const AName, ACss: string);
    procedure RemoveStyle(const AName: string);

    function GetCss(const AName: string): string;
    procedure SetCss(const AName, ACss: string);

    function GetCssForControl(const AStyleName: string): string;

    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStrings(const AStrings: TStrings);
    procedure LoadFromCss(const ACss: string);
    procedure SaveToFile(const AFileName: string);

    procedure RegisterControl(AControl: TCssStyledControl);
    procedure UnRegisterControl(AControl: TCssStyledControl);

    property StyleCount: Integer read GetStyleCount;
    property StyleNames[Index: Integer]: string read GetStyleName;
    property CssByName[AName: string]: string read GetCss write SetCss;
  published
    property DefaultStyleName: string read FDefaultStyleName write SetDefaultStyleName;
    property FileName: string read FFileName write SetFileName;
    property CssText: string read GetCssText write SetCssText;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TCssCornerRadii = record
    TL, TR, BR, BL: Integer;
  end;

  TCssGradientStop = record
    Position: Double;   // 0..1
    Color: TColor;
  end;

  TCssGradientKind = (cgkNone, cgkLinear, cgkRadial);

  TCssGradient = record
    Kind: TCssGradientKind;
    Angle: Double;
    Stops: array of TCssGradientStop;
  end;

  TCssBoxShadow = record
    OffsetX, OffsetY, Blur, Spread: Integer;
    Color: TColor;
    HasColor: Boolean;
    Used: Boolean;
  end;

  TCssRoundedBoxParams = record
    Radii: TCssCornerRadii;
    FillColor: TColor;
    BorderColor: TColor;
    BorderWidth: Integer;
    BorderStyle: TCssBorderStyle;
    CornerBackColor: array[0..3] of TColor;
    Shadow: TCssBoxShadow;
    Gradient: TCssGradient;
    HasGradient: Boolean;
  end;

  TCssStyledControl = class(TCustomControl)
  private
    FCaption: TCaption;
    FCssTag: string;
    FCssID: string;
    FCssClass: string;
    FInlineStyle: string;
    FStyleSheet: string;

    FMonospaceFontName: string;

    FBackground: TColor;
    FHasBackground: Boolean;
    FTextColor: TColor;
    FHasTextColor: Boolean;

    FBorderWidth: Integer;
    FBorderColor: TColor;
    FBorderStyle: TCssBorderStyle;
    FBorderRadius: Integer;

    FPadding: TRect;
    FTextAlign: TCssTextAlign;
    FVAlign: TCssVAlign;

    FFontFamily: string;
    FFontPixelHeight: Integer;
    FFontPointSize: Integer;
    FFontBold: Boolean;
    FFontItalic: Boolean;

    FHasFontFamily: Boolean;
    FHasFontPixelHeight: Boolean;
    FHasFontPointSize: Boolean;
    FHasFontBold: Boolean;
    FHasFontItalic: Boolean;

    FMouseInControl: Boolean;
    FMousePressed: Boolean;
    FFocused: Boolean;
    FChecked: Boolean;
    FAutoToggle: Boolean;

    FHtmlMode: Boolean;

    FStyleProvider: TCssStyleProvider;
    FStyleName: string;

    FWordWrap: Boolean;

    FHintCss: string;
    FHintHtmlMode: Boolean;

    FOnLinkClick: TCssLinkClickEvent;

    FLinkNormal: TCssLinkStyle;
    FLinkHover: TCssLinkStyle;

    FLinkAreas: TCssLinkAreas;
    FLinkInfos: TCssHtmlLinkInfos;

    FHoverLinkId: Integer;
    FSuppressClick: Boolean;

    FCssCursor: TCursor;

    FOpacity: Double;

    FTextShadow: Boolean;
    FTextShadowColor: TColor;
    FTextShadowX: Integer;
    FTextShadowY: Integer;

    FTextPropsInitialized: Boolean;

    FShowFocusRect: Boolean;
    FFocusColor: TColor;
    FFocusColorSet: Boolean;

    FHoveredChildrenCount: Integer;
    FExternalHoverCount: Integer;

    FBorderRadiusTL, FBorderRadiusTR, FBorderRadiusBR, FBorderRadiusBL: Integer;
    FBackgroundGradient: TCssGradient;
    FBoxShadow: TCssBoxShadow;
    FExternalCornerBitmap: TBitmap;
    FExternalCornerOrigin: TPoint;

    { CSS parsing helpers }
    procedure ParseTextShadow(const AValue: string);
    procedure ParseBorder(const AValue: string);
    procedure ParsePadding(const AValue: string);
    procedure ParseFont(const AValue: string);
    procedure ParseFontSize(const AValue: string);
    procedure ParseFontFamily(const AValue: string);
    procedure ParseBackground(const AValue: string);
    procedure ParseBorderRadius(const AValue: string);
    procedure ParseBoxShadow(const AValue: string);
    procedure ParseBackgroundGradient(const AValue: string);

    function TryNamedColor(const AName: string; out AColor: TColor): Boolean;
    function CssClassContains(const AClass: string): Boolean;
    function GetBorderPenStyle: TPenStyle;

    { Style (re)application }
    procedure SetStyleProvider(AValue: TCssStyleProvider);
    procedure SetStyleName(const AValue: string);
    function GetEffectiveStyleSheet: string;
    procedure ApplyCss(const ACss: string);
    procedure ApplyDeclarations(const ADeclarations: string);
    procedure ReapplyStyles;

    { Property setters }
    procedure SetCssClass(const AValue: string);
    procedure SetCssID(const AValue: string);
    procedure SetCssTag(const AValue: string);
    procedure SetInlineStyle(const AValue: string);
    procedure SetMonospaceFontName(const AValue: string);
    procedure SetHtmlMode(AValue: Boolean);
    procedure SetChecked(AValue: Boolean);
    procedure SetHintHtmlMode(AValue: Boolean);
    procedure SetFocusColor(AValue: TColor);

    { State }
    function MatchPseudo(const APseudo: string): Boolean;
    function TryEvaluateSelector(const ASelector: string; out SpecA, SpecB, SpecC: Integer): Boolean;

    { Links }
    procedure ApplyLinkDeclaration(var AStyle: TCssLinkStyle; const AName, AValue: string);
    procedure ApplyLinkDeclarations(var AStyle: TCssLinkStyle; const ADeclarations: string);
    function IsLinkSelector(const ASelector: string; out AHover: Boolean): Boolean;
    function LinkAt(const P: TPoint): Integer;
    function GetLinkInfoById(ALinkId: Integer): TCssHtmlLinkInfo;
    procedure AddLinkArea(ALinkId: Integer; const AHref: string; const ARect: TRect);
    procedure SetHoverLinkId(ALinkId: Integer);
    function GetLinkCursor: TCursor;
    function GetEffectiveLinkColor(AHover: Boolean): TColor;
    function GetEffectiveLinkUnderline(AHover: Boolean): Boolean;

    { Hint }
    function UseCustomHint: Boolean;
    function GetHintOwner: TCssStyledControl;

    { Opacity }
    function GetOpacityBaseColor: TColor;
    function ApplyOpacity(AColor: TColor): TColor;

    procedure NotifyUpperSiblingsRepaint(AOldBounds: PRect = nil);
    function  IsCaptionStored: Boolean;
  protected
    { AA rounded rect }
    procedure DrawRoundedRectAA(
      ACanvas: TCanvas;
      const ARect: TRect;
      const AParams: TCssRoundedBoxParams);
    function GetParentBackgroundColor: TColor;
    function GetBackgroundBeneathAtClientPoint(const AClientPoint: TPoint): TColor;

    { Lifecycle }
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    { State (events) }
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Click; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure EnabledChanged; override;
    procedure ChildFocusChanged(AChildFocused: Boolean); virtual;
    procedure NotifyParentsFocusChanged(AFocused: Boolean);

    procedure ChildHoverChanged(AChildHovered: Boolean); virtual;
    procedure NotifyParentsHoverChanged(AHovered: Boolean);

    procedure UpdateCursor; virtual;

    { State (setters) }
    procedure SetMouseInControlState(AValue: Boolean);
    procedure SetMousePressedState(AValue: Boolean);
    procedure SetFocusedState(AValue: Boolean);
    procedure SetCssCheckedState(AValue: Boolean);
    procedure SetTextAlign(AValue: TCssTextAlign);
    procedure SetVAlign(AValue: TCssVAlign);
    procedure SetWordWrap(AValue: Boolean);
    procedure SetShowFocusRect(AValue: Boolean); virtual;
    procedure SetVisible(AValue: Boolean); override;

    { State (getters) }
    function GetMouseInControlState: Boolean;
    function GetMousePressedState: Boolean;
    function GetFocusedState: Boolean;
    function GetFocusColor: TColor; virtual;
    function GetEffectiveHoverState: Boolean; virtual;
    function GetShowPrefix: Boolean; virtual;
    procedure HtmlModeChanged; virtual;
    function ShouldPaintCaption: Boolean; virtual;

    { Virtual }
    procedure SetCaption(const AValue: TCaption); virtual;
    procedure DoLinkClick(const AHref, AText: string); virtual;
    procedure StyleChanged; virtual;
    procedure ResetStyle; virtual;
    procedure ApplyDeclaration(const AName, AValue: string); virtual;
    procedure InitTextProps; virtual;

    { Layout helpers }
    function  GetContentRect: TRect; virtual;
    function  GetContentRectNoScroll: TRect; virtual;
    function  GetBorderTopOffset: Integer; virtual;

    function  GetAlignment: TAlignment;
    procedure SetAlignment(AValue: TAlignment);
    function  GetLayout: TTextLayout;
    procedure SetLayout(AValue: TTextLayout);
    function  GetWordWrapProp: Boolean;
    procedure SetWordWrapProp(AValue: Boolean);

    { CSS accessors }
    function GetCssBackgroundColor: TColor;
    function GetCssTextColor: TColor;
    function GetCssBorderWidth: Integer;
    function GetCssPadding: TRect;
    function GetCssTextAlign: TCssTextAlign;
    function GetCssVAlign: TCssVAlign;
    function GetCssWordWrap: Boolean;
    function GetCssBorderColor: TColor;
    function GetCssBorderRadius: Integer;
    function GetEffectiveTextColor: TColor;
    function GetEffectiveBorderColor: TColor;

    { Font }
    procedure AssignCssFontToFont(AFont: TFont);
    procedure UpdateCanvasFont;

    { Style }
    procedure RefreshStylesByState;

    { Parsing }
    function ParseColor(const AValue: string; out AColor: TColor): Boolean;
    function ParseLengthPx(const AValue: string; out APx: Integer): Boolean;
    function ParseCssColor(const AValue: string; out AColor: TColor): Boolean;
    function ParseCssLengthPx(const AValue: string; out APx: Integer): Boolean;
    function ParseCssCursor(const AValue: string): TCursor;

    { Painting }
    procedure Paint; override;
    procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: Integer; KeepBase: Boolean); override;

    procedure DrawHtmlText(const ARect: TRect; const AText: string); overload;
    procedure DrawHtmlText(ACanvas: TCanvas; const ARect: TRect; const AText: string); overload;
    procedure DrawHtmlText(ACanvas: TCanvas; const ARect: TRect; const AText: string; ADefaultTextColor: TColor); overload;
    procedure DrawStyledText(const ARect: TRect; const AText: string);

    procedure DrawHtmlTextWithAlign(
      ACanvas: TCanvas;
      const ARect: TRect;
      const AText: string;
      AAlign: TCssTextAlign;
      AVAlign: TCssVAlign
    ); overload;

    procedure DrawHtmlTextWithAlign(
      ACanvas: TCanvas;
      const ARect: TRect;
      const AText: string;
      AAlign: TCssTextAlign;
      AVAlign: TCssVAlign;
      ADefaultTextColor: TColor
    ); overload;

    procedure BlendCoverageToCanvas(
      ACanvas: TCanvas;
      ALeft, ATop, AWidth, AHeight: Integer;
      const ACoverage: array of Byte;
      AColor: TColor);

    function MeasureHtmlTextSize(
      ACanvas: TCanvas;
      const AText: string;
      AvailableWidth: Integer): TSize; overload;

    function MeasureHtmlTextSize(
      const AText: string;
      AvailableWidth: Integer): TSize; overload;

    { Hint }
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    function CustomHintForPoint(const APoint: TPoint; out AHint: string): Boolean; virtual;

    function GetDefaultCaption: string; virtual;
    procedure SetName(const NewName: TComponentName); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DrawFocusRect(ACanvas: TCanvas; const ARect: TRect); virtual;

    // === Anti-aliased primitives (public for descendants) ===
    // Triangle with anti-aliased edges. AP1..AP3 - polygon vertices,
    // ABackgroundColor - color used for edge blending; if clNone is given,
    // the parent background color is used.
    procedure DrawAntiAliasedTriangle(
      ACanvas: TCanvas;
      const AP1, AP2, AP3: TPoint;
      AColor: TColor;
      ABackgroundColor: TColor = clNone);

    // Circle with anti-aliased edges, optional fill and border.
    // ARect defines the bounding box of the circle (use equal W/H for a round circle).
    procedure DrawAntiAliasedCircle(
      ACanvas: TCanvas;
      const ARect: TRect;
      AFillColor: TColor;
      ABorderColor: TColor;
      ABorderWidth: Integer = 1;
      ABackgroundColor: TColor = clNone);

    procedure DrawAntiAliasedRoundedBox(
      ACanvas: TCanvas;
      const ARect: TRect;
      ARadii: TCssCornerRadii;
      AFillColor: TColor;
      ABorderColor: TColor;
      ABorderWidth: Integer;
      ABorderStyle: TCssBorderStyle = cbsSolid;
      ABackgroundColor: TColor = clNone); overload;

    procedure DrawAntiAliasedRoundedBox(
      ACanvas: TCanvas;
      const ARect: TRect;
      ARadius: Integer;
      AFillColor: TColor;
      ABorderColor: TColor;
      ABorderWidth: Integer;
      ABorderStyle: TCssBorderStyle = cbsSolid;
      ABackgroundColor: TColor = clNone); overload;

    procedure DrawAntiAliasedCheckMark(
      ACanvas: TCanvas;
      const ARect: TRect;
      AColor: TColor);

    procedure ApplyStyleSheet(const ACss: string);
    procedure ProviderStyleChanged;
    function HtmlToPlainText(const AText: string): string;

    procedure DrawStyledBackground(ACanvas: TCanvas; const ARect: TRect);
    procedure DrawStyledTextToCanvas(ACanvas: TCanvas; const ARect: TRect; const AText: string);
    procedure DrawCaptionToCanvas(ACanvas: TCanvas; const ARect: TRect; const AText: string);

    function MeasureStyledTextSize(ACanvas: TCanvas; const AText: string; AvailableWidth: Integer): TSize;
    procedure AssignEffectiveCssFontToFont(AFont: TFont);

    function GetStyledBackgroundColor: TColor;
    function GetStyledBorderWidth: Integer;
    function GetStyledPadding: TRect;
    function GetStyledBorderRadius: Integer;
    function GetStyledTextColor: TColor;
    function GetCssBorderRadii: TCssCornerRadii;
    function GetCssGradient: TCssGradient;
    function GetCssBoxShadow: TCssBoxShadow;

    function TryGetLinkAt(const P: TPoint; out AHref, AText: string): Boolean;
    procedure ClickLinkAtPoint(const P: TPoint);

    procedure UpdateEnabledVisualState;

    procedure SetExternalHoverState(AHover: Boolean);
    procedure SetExternalCornerSource(ABitmap: TBitmap; const AOrigin: TPoint);
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption: TCaption read FCaption write SetCaption stored IsCaptionStored;
    property Color;
    property Constraints;
    property CssTag: string read FCssTag write SetCssTag;
    property CssID: string read FCssID write SetCssID;
    property CssClass: string read FCssClass write SetCssClass;
    property CssStyle: string read FInlineStyle write SetInlineStyle;
    property Checked: Boolean read FChecked write SetChecked default False;
    property AutoToggle: Boolean read FAutoToggle write FAutoToggle default False;
    property HtmlMode: Boolean read FHtmlMode write SetHtmlMode default False;
    property StyleProvider: TCssStyleProvider read FStyleProvider write SetStyleProvider;
    property StyleName: string read FStyleName write SetStyleName;
    property OnLinkClick: TCssLinkClickEvent read FOnLinkClick write FOnLinkClick;
    property Hint;
    property ShowFocusRect: Boolean read FShowFocusRect write SetShowFocusRect default True;
    property FocusColor: TColor read FFocusColor write SetFocusColor default clDefault;
    property ShowHint;
    property HintHtmlMode: Boolean read FHintHtmlMode write SetHintHtmlMode default True;
    property MonospaceFontName: string read FMonospaceFontName write SetMonospaceFontName;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;

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
    property OnPaint;
    property OnResize;
  end;

  TCssGroupCaptionMode = (gcmInside, gcmOnBorder);

procedure BuildCheckMarkCoverage(
  var ACoverage: array of Byte;
  AW, AH: Integer;
  const AX1, AY1, AX2, AY2, AX3, AY3: Double;
  ALineWidth: Double);

implementation

uses
  StrUtils, IntfGraphics, FPImage, Math, LCLIntf, CssFontUtils;

procedure BuildCheckMarkCoverage(
  var ACoverage: array of Byte;
  AW, AH: Integer;
  const AX1, AY1, AX2, AY2, AX3, AY3: Double;
  ALineWidth: Double);
var
  I: Integer;
  Half: Double;

  procedure FillSegment(X1, Y1, X2, Y2: Double);
  var
    MinX, MaxX, MinY, MaxY: Integer;
    LX, LY: Integer;
    DX, DY, LenSq, T, CX, CY, Dist, Cov: Double;
    PX, PY: Double;
    ByteCov: Byte;
    Idx: Integer;
  begin
    MinX := Floor(Min(X1, X2) - Half - 1);
    MaxX := Ceil (Max(X1, X2) + Half + 1);
    MinY := Floor(Min(Y1, Y2) - Half - 1);
    MaxY := Ceil (Max(Y1, Y2) + Half + 1);

    if MinX < 0   then MinX := 0;
    if MinY < 0   then MinY := 0;
    if MaxX >= AW then MaxX := AW - 1;
    if MaxY >= AH then MaxY := AH - 1;

    if (MinX > MaxX) or (MinY > MaxY) then Exit;

    DX := X2 - X1;
    DY := Y2 - Y1;
    LenSq := DX * DX + DY * DY;

    for LY := MinY to MaxY do
      for LX := MinX to MaxX do
      begin
        if LenSq > 1E-9 then
        begin
          T := ((LX + 0.5 - X1) * DX + (LY + 0.5 - Y1) * DY) / LenSq;
          if T < 0 then T := 0
          else if T > 1 then T := 1;

          CX := X1 + T * DX;
          CY := Y1 + T * DY;

          PX := LX + 0.5 - CX;
          PY := LY + 0.5 - CY;
          Dist := Sqrt(PX * PX + PY * PY);
        end
        else
        begin
          PX := LX + 0.5 - X1;
          PY := LY + 0.5 - Y1;
          Dist := Sqrt(PX * PX + PY * PY);
        end;

        Cov := Half + 0.5 - Dist;
        if Cov <= 0 then
          Continue;
        if Cov > 1 then
          Cov := 1;

        ByteCov := Round(Cov * 255);
        Idx := LY * AW + LX;

        if ByteCov > ACoverage[Idx] then
          ACoverage[Idx] := ByteCov;
      end;
  end;

begin
  if (AW <= 0) or (AH <= 0) then Exit;
  if Length(ACoverage) < AW * AH then Exit;

  for I := 0 to AW * AH - 1 do
    ACoverage[I] := 0;

  Half := ALineWidth / 2;

  FillSegment(AX1, AY1, AX2, AY2);
  FillSegment(AX2, AY2, AX3, AY3);
end;

{ ============================================================ }
{ Global helper functions                                      }
{ ============================================================ }

function RemoveCssComments(const AValue: string): string;
var
  P1, P2: Integer;
begin
  Result := AValue;
  repeat
    P1 := Pos('/*', Result);
    if P1 = 0 then
      Break;

    P2 := PosEx('*/', Result, P1 + 2);
    if P2 = 0 then
    begin
      Delete(Result, P1, MaxInt);
      Break;
    end;

    Delete(Result, P1, P2 - P1 + 2);
  until False;
end;

function LastSimpleSelector(const ASelector: string): string;
var
  I, Start, P: Integer;
  Ch: Char;
begin
  Start := 1;

  for I := Length(ASelector) downto 1 do
  begin
    Ch := ASelector[I];
    if (Ch = ' ') or (Ch = '>') or (Ch = '+') or (Ch = '~') then
    begin
      Start := I + 1;
      Break;
    end;
  end;

  Result := Trim(Copy(ASelector, Start, MaxInt));

  // Ignore pseudo-classes and attributes: .btn:hover -> .btn
  P := Pos(':', Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);

  P := Pos('[', Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);

  Result := Trim(Result);
end;

function TryParseNumberPrefix(const AValue: string; out ANumber: Integer): Boolean;
var
  S, NumStr: string;
  I, Code: Integer;
  HasDigit: Boolean;
begin
  Result := False;
  ANumber := 0;

  S := Trim(AValue);
  NumStr := '';
  I := 1;
  HasDigit := False;

  if (I <= Length(S)) and ((S[I] = '+') or (S[I] = '-')) then
  begin
    NumStr := NumStr + S[I];
    Inc(I);
  end;

  while (I <= Length(S)) and (S[I] in ['0'..'9']) do
  begin
    NumStr := NumStr + S[I];
    HasDigit := True;
    Inc(I);
  end;

  // The fractional part is simply ignored for now, to avoid pulling in a float parser.
  if (I <= Length(S)) and (S[I] = '.') then
  begin
    Inc(I);
    while (I <= Length(S)) and (S[I] in ['0'..'9']) do
      Inc(I);
  end;

  if not HasDigit then
    Exit;

  Val(NumStr, ANumber, Code);
  Result := Code = 0;
end;

procedure SplitBySpaces(const AValue: string; AList: TStrings);
var
  I, Start, ParenDepth: Integer;
  InQuote: Boolean;
  QuoteChar, Ch: Char;
begin
  Start := 1;
  ParenDepth := 0;
  InQuote := False;
  QuoteChar := #0;

  for I := 1 to Length(AValue) do
  begin
    Ch := AValue[I];

    if InQuote then
    begin
      if Ch = QuoteChar then
        InQuote := False;
    end
    else
    begin
      if (Ch = '''') or (Ch = '"') then
      begin
        InQuote := True;
        QuoteChar := Ch;
      end
      else if Ch = '(' then
        Inc(ParenDepth)
      else if Ch = ')' then
      begin
        if ParenDepth > 0 then
          Dec(ParenDepth);
      end;
    end;

    if (ParenDepth = 0) and (not InQuote) and
       (Ch in [' ', #9, #10, #13]) then
    begin
      if I > Start then
        AList.Add(Copy(AValue, Start, I - Start));
      Start := I + 1;
    end;
  end;

  if Length(AValue) >= Start then
    AList.Add(Copy(AValue, Start, Length(AValue) - Start + 1));
end;

procedure SplitByChar(const AValue: string; AChar: Char; AList: TStrings);
var
  I, Start: Integer;
begin
  Start := 1;

  for I := 1 to Length(AValue) + 1 do
  begin
    if (I > Length(AValue)) or (AValue[I] = AChar) then
    begin
      if I > Start then
        AList.Add(Trim(Copy(AValue, Start, I - Start)));
      Start := I + 1;
    end;
  end;
end;

function FirstToken(const AValue: string): string;
var
  I: Integer;
begin
  I := 1;

  while (I <= Length(AValue)) and ((AValue[I] = ' ') or (AValue[I] = #9)) do
    Inc(I);

  Result := '';

  while (I <= Length(AValue)) and
        not ((AValue[I] = ' ') or (AValue[I] = #9)) do
  begin
    Result := Result + AValue[I];
    Inc(I);
  end;
end;

function IsFontSizeToken(const AToken: string): Boolean;
var
  S: string;
  N, P: Integer;
begin
  S := LowerCase(AToken);

  P := Pos('/', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);

  Result := False;

  if (S = 'xx-small') or (S = 'x-small') or (S = 'small') or
     (S = 'medium') or (S = 'large') or (S = 'x-large') or
     (S = 'xx-large') then
    Exit(True);

  if TryParseNumberPrefix(S, N) then
    Result := EndsText('px', S) or EndsText('pt', S);
end;

function LastSimpleSelectorRaw(const ASelector: string): string;
var
  I, Start: Integer;
  Ch: Char;
begin
  Start := 1;

  for I := Length(ASelector) downto 1 do
  begin
    Ch := ASelector[I];

    if (Ch = ' ') or (Ch = '>') or (Ch = '+') or (Ch = '~') then
    begin
      Start := I + 1;
      Break;
    end;
  end;

  Result := Trim(Copy(ASelector, Start, MaxInt));
end;

procedure SkipParentheses(const S: string; var I: Integer);
var
  Depth: Integer;
begin
  if (I > Length(S)) or (S[I] <> '(') then
    Exit;

  Depth := 0;

  while I <= Length(S) do
  begin
    if S[I] = '(' then
      Inc(Depth)
    else if S[I] = ')' then
    begin
      Dec(Depth);

      if Depth = 0 then
      begin
        Inc(I);
        Break;
      end;
    end;

    Inc(I);
  end;
end;

procedure ParseSimpleSelector(
  const ASelector: string;
  out TypeName, ID: string;
  AClasses, APseudos: TStrings;
  out HasAttribute, HasFunctional, HasPseudoElement: Boolean);
var
  S, Part: string;
  I: Integer;
  IsPseudoElement: Boolean;
begin
  TypeName := '';
  ID := '';

  if Assigned(AClasses) then
    AClasses.Clear;

  if Assigned(APseudos) then
    APseudos.Clear;

  HasAttribute := False;
  HasFunctional := False;
  HasPseudoElement := False;

  S := LastSimpleSelectorRaw(ASelector);
  I := 1;

  while (I <= Length(S)) and not (S[I] in ['.', '#', ':', '[']) do
  begin
    TypeName := TypeName + S[I];
    Inc(I);
  end;

  TypeName := Trim(TypeName);

  while I <= Length(S) do
  begin
    if S[I] = '.' then
    begin
      Inc(I);
      Part := '';

      while (I <= Length(S)) and
            not (S[I] in ['.', '#', ':', '[', '(']) do
      begin
        Part := Part + S[I];
        Inc(I);
      end;

      if (Part <> '') and Assigned(AClasses) then
        AClasses.Add(Part);
    end
    else if S[I] = '#' then
    begin
      Inc(I);
      Part := '';

      while (I <= Length(S)) and
            not (S[I] in ['.', '#', ':', '[', '(']) do
      begin
        Part := Part + S[I];
        Inc(I);
      end;

      ID := Part;
    end
    else if S[I] = ':' then
    begin
      Inc(I);

      IsPseudoElement := False;

      if (I <= Length(S)) and (S[I] = ':') then
      begin
        IsPseudoElement := True;
        Inc(I);
      end;

      Part := '';

      while (I <= Length(S)) and
            not (S[I] in ['.', '#', ':', '[', '(']) do
      begin
        Part := Part + S[I];
        Inc(I);
      end;

      if (I <= Length(S)) and (S[I] = '(') then
      begin
        HasFunctional := True;
        SkipParentheses(S, I);
      end
      else if Part <> '' then
      begin
        if IsPseudoElement then
          HasPseudoElement := True
        else if Assigned(APseudos) then
          APseudos.Add(LowerCase(Part));
      end;
    end
    else if S[I] = '[' then
    begin
      HasAttribute := True;
      Break;
    end
    else
    begin
      Inc(I);
    end;
  end;
end;

function TryParseCssFloat(const AValue: string; out AFloat: Double): Boolean;
var
  S: string;
  Code: Integer;
begin
  Result := False;
  S := Trim(AValue);
  if S = '' then
    Exit;

  if EndsText('%', S) then
  begin
    S := Copy(S, 1, Length(S) - 1);
    Val(S, AFloat, Code);
    if Code = 0 then
    begin
      AFloat := AFloat / 100;
      Result := True;
    end;
    Exit;
  end;

  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  Val(S, AFloat, Code);
  Result := Code = 0;
end;

function TryParseGradientAngle(const S: string; out ADeg: Double): Boolean;
var
  T: string;
  N: Double;
  Code: Integer;
begin
  T := LowerCase(Trim(S));

  if EndsText('deg', T) then
  begin
    T := Copy(T, 1, Length(T) - 3);
    Val(T, N, Code);
    if Code = 0 then begin ADeg := N; Exit(True); end;
  end
  else if EndsText('grad', T) then
  begin
    T := Copy(T, 1, Length(T) - 4);
    Val(T, N, Code);
    if Code = 0 then begin ADeg := N * 0.9; Exit(True); end;
  end
  else if EndsText('rad', T) then
  begin
    T := Copy(T, 1, Length(T) - 3);
    Val(T, N, Code);
    if Code = 0 then begin ADeg := N * 180 / Pi; Exit(True); end;
  end
  else if EndsText('turn', T) then
  begin
    T := Copy(T, 1, Length(T) - 4);
    Val(T, N, Code);
    if Code = 0 then begin ADeg := N * 360; Exit(True); end;
  end;

  Result := False;
end;

function TryParseGradientPosition(const S: string; out APos: Double): Boolean;
var
  T: string;
  N: Double;
  Code: Integer;
begin
  Result := False;
  T := Trim(S);

  if EndsText('%', T) then
  begin
    T := Copy(T, 1, Length(T) - 1);
    Val(T, N, Code);
    if Code = 0 then
    begin
      APos := N / 100;
      Result := True;
    end;
  end;
end;

procedure SplitByTopCommas(const S: string; AList: TStrings);
var
  I, Start, Depth: Integer;
  InQuote: Boolean;
  Quote: Char;
begin
  Start := 1;
  Depth := 0;
  InQuote := False;
  Quote := #0;

  for I := 1 to Length(S) do
  begin
    if InQuote then
    begin
      if S[I] = Quote then InQuote := False;
    end
    else if (S[I] = '''') or (S[I] = '"') then
    begin
      InQuote := True;
      Quote := S[I];
    end
    else if S[I] = '(' then Inc(Depth)
    else if S[I] = ')' then Dec(Depth)
    else if (S[I] = ',') and (Depth = 0) then
    begin
      AList.Add(Trim(Copy(S, Start, I - Start)));
      Start := I + 1;
    end;
  end;

  if Start <= Length(S) then
    AList.Add(Trim(Copy(S, Start, Length(S) - Start + 1)));
end;

procedure EnsureStopPositions(var Stops: array of TCssGradientStop);
var
  I, J, Count, First, Last: Integer;
  AllSet, AnySet: Boolean;
begin
  Count := Length(Stops);
  if Count = 0 then Exit;

  AllSet := True;
  AnySet := False;

  for I := 0 to Count - 1 do
  begin
    if Stops[I].Position < 0 then AllSet := False
    else AnySet := True;
  end;

  if not AnySet then
  begin
    if Count = 1 then
      Stops[0].Position := 0
    else
      for I := 0 to Count - 1 do
        Stops[I].Position := I / (Count - 1);
    Exit;
  end;

  if Stops[0].Position < 0 then Stops[0].Position := 0;
  if Stops[Count - 1].Position < 0 then Stops[Count - 1].Position := 1;

  I := 1;
  while I < Count do
  begin
    if Stops[I].Position < 0 then
    begin
      First := I - 1;
      Last := I + 1;
      while (Last < Count) and (Stops[Last].Position < 0) do
        Inc(Last);
      if Last >= Count then Last := Count - 1;

      for J := First + 1 to Last - 1 do
        Stops[J].Position :=
          Stops[First].Position +
          (Stops[Last].Position - Stops[First].Position) *
          (J - First) / (Last - First);

      I := Last;
    end
    else
      Inc(I);
  end;

  for I := 1 to Count - 1 do
    if Stops[I].Position < Stops[I - 1].Position then
      Stops[I].Position := Stops[I - 1].Position;
end;

type
  THtmlInlineStyle = record
    Bold: Boolean;
    Italic: Boolean;
    Underline: Boolean;
    StrikeOut: Boolean;
    Sup: Boolean;
    Sub: Boolean;
    Mono: Boolean;
    Color: TColor;
    HasColor: Boolean;

    Link: Boolean;
    Href: string;
    LinkId: Integer;
  end;

  THtmlStyleMods = record
    HasBold: Boolean;
    Bold: Boolean;
    HasItalic: Boolean;
    Italic: Boolean;
    HasUnderline: Boolean;
    Underline: Boolean;
    HasStrikeOut: Boolean;
    StrikeOut: Boolean;
    HasSup: Boolean;
    Sup: Boolean;
    HasSub: Boolean;
    Sub: Boolean;
    HasMono: Boolean;
    Mono: Boolean;
    HasColor: Boolean;
    Color: TColor;

    HasLink: Boolean;
    Link: Boolean;
    Href: string;
    LinkId: Integer;
  end;

  THtmlInlineMod = record
    TagName: string;
    Mods: THtmlStyleMods;
  end;

  THtmlRun = record
    Text: string;
    Style: THtmlInlineStyle;
  end;

  THtmlBlockKind = (hbParagraph, hbHeading, hbPre, hbHr, hbXmp, hbListItem);

  THtmlBlock = record
    Kind: THtmlBlockKind;
    Level: Integer;
    Align: TCssTextAlign;
    HasAlign: Boolean;

    ListIndent: Integer;
    ListBullet: string;

    Runs: array of THtmlRun;
  end;

  THtmlBlocks = array of THtmlBlock;

  THtmlListStackItem = record
    Ordered: Boolean;
    Counter: Integer;
  end;

  THtmlWord = record
    Text: string;
    Style: THtmlInlineStyle;
    Width: Integer;
    SpaceBefore: Boolean;
  end;

function EmptyHtmlInlineStyle: THtmlInlineStyle;
begin
  Result.Bold := False;
  Result.Italic := False;
  Result.Underline := False;
  Result.StrikeOut := False;
  Result.Sup := False;
  Result.Sub := False;
  Result.Mono := False;
  Result.Color := clNone;
  Result.HasColor := False;

  Result.Link := False;
  Result.Href := '';
  Result.LinkId := 0;
end;

function EmptyHtmlStyleMods: THtmlStyleMods;
begin
  Result.HasBold := False;
  Result.Bold := False;

  Result.HasItalic := False;
  Result.Italic := False;

  Result.HasUnderline := False;
  Result.Underline := False;

  Result.HasStrikeOut := False;
  Result.StrikeOut := False;

  Result.HasSup := False;
  Result.Sup := False;

  Result.HasSub := False;
  Result.Sub := False;

  Result.HasMono := False;
  Result.Mono := False;

  Result.HasColor := False;
  Result.Color := clNone;

  Result.HasLink := False;
  Result.Link := False;
  Result.Href := '';
  Result.LinkId := 0;
end;

function TryParseHtmlColor(const AValue: string; out AColor: TColor): Boolean;
var
  S, Hex, Nums, Token: string;
  P, I, Comp: Integer;
  R, G, B: Integer;
  Vals: array[0..2] of Integer;
begin
  Result := False;

  S := LowerCase(Trim(AValue));

  if S = '' then
    Exit;

  if S = 'transparent' then
  begin
    AColor := clNone;
    Exit(True);
  end;

  if S[1] = '#' then
  begin
    Hex := Copy(S, 2, MaxInt);

    if (Length(Hex) = 3) or (Length(Hex) = 4) then
    begin
      if not TryStrToInt('$' + Hex[1] + Hex[1], R) then Exit;
      if not TryStrToInt('$' + Hex[2] + Hex[2], G) then Exit;
      if not TryStrToInt('$' + Hex[3] + Hex[3], B) then Exit;
    end
    else if Length(Hex) >= 6 then
    begin
      if not TryStrToInt('$' + Copy(Hex, 1, 2), R) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 3, 2), G) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 5, 2), B) then Exit;
    end
    else
      Exit;

    AColor := RGBToColor(R, G, B);
    Exit(True);
  end;

  if (Pos('rgb(', S) = 1) or (Pos('rgba(', S) = 1) then
  begin
    P := Pos('(', S);
    if P = 0 then
      Exit;

    Nums := Copy(S, P + 1, MaxInt);

    P := Pos(')', Nums);
    if P = 0 then
      Exit;

    Nums := Copy(Nums, 1, P - 1);

    Comp := 0;
    Token := '';

    for I := 1 to Length(Nums) + 1 do
    begin
      if (I > Length(Nums)) or (Nums[I] = ',') then
      begin
        Token := Trim(Token);

        if Comp < 3 then
        begin
          if not TryParseNumberPrefix(Token, Vals[Comp]) then
            Exit;
        end;

        Inc(Comp);
        Token := '';
      end
      else
      begin
        Token := Token + Nums[I];
      end;
    end;

    if Comp < 3 then
      Exit;

    for I := 0 to 2 do
    begin
      if Vals[I] < 0 then
        Vals[I] := 0;

      if Vals[I] > 255 then
        Vals[I] := 255;
    end;

    AColor := RGBToColor(Vals[0], Vals[1], Vals[2]);
    Exit(True);
  end;

  Result := True;

  if S = 'black' then AColor := RGBToColor(0, 0, 0)
  else if S = 'white' then AColor := RGBToColor(255, 255, 255)
  else if S = 'red' then AColor := RGBToColor(255, 0, 0)
  else if S = 'green' then AColor := RGBToColor(0, 128, 0)
  else if S = 'blue' then AColor := RGBToColor(0, 0, 255)
  else if S = 'yellow' then AColor := RGBToColor(255, 255, 0)
  else if S = 'orange' then AColor := RGBToColor(255, 165, 0)
  else if S = 'purple' then AColor := RGBToColor(128, 0, 128)
  else if (S = 'gray') or (S = 'grey') then AColor := RGBToColor(128, 128, 128)
  else if S = 'silver' then AColor := RGBToColor(192, 192, 192)
  else if S = 'maroon' then AColor := RGBToColor(128, 0, 0)
  else if S = 'olive' then AColor := RGBToColor(128, 128, 0)
  else if S = 'lime' then AColor := RGBToColor(0, 255, 0)
  else if (S = 'aqua') or (S = 'cyan') then AColor := RGBToColor(0, 255, 255)
  else if S = 'teal' then AColor := RGBToColor(0, 128, 128)
  else if S = 'navy' then AColor := RGBToColor(0, 0, 128)
  else if (S = 'fuchsia') or (S = 'magenta') then AColor := RGBToColor(255, 0, 255)
  else if S = 'pink' then AColor := RGBToColor(255, 192, 203)
  else if S = 'brown' then AColor := RGBToColor(165, 42, 42)
  else if S = 'gold' then AColor := RGBToColor(255, 215, 0)
  else
    Result := False;
end;

function GetHtmlAttribute(const ATag, AName: string): string;
var
  S, AttrName, AttrValue: string;
  I, J, StartLoop: Integer;
  Quote: Char;
begin
  Result := '';

  S := ATag;
  I := 1;

  while I <= Length(S) do
  begin
    StartLoop := I;

    while (I <= Length(S)) and (S[I] in [' ', #9, #10, #13]) do
      Inc(I);

    if I > Length(S) then
      Break;

    J := I;

    while (J <= Length(S)) and
          not (S[J] in ['=', ' ', #9, #10, #13, '/', '>']) do
    begin
      Inc(J);
    end;

    AttrName := LowerCase(Copy(S, I, J - I));
    I := J;

    while (I <= Length(S)) and (S[I] in [' ', #9, #10, #13]) do
      Inc(I);

    if (I <= Length(S)) and (S[I] = '=') then
    begin
      Inc(I);

      while (I <= Length(S)) and (S[I] in [' ', #9, #10, #13]) do
        Inc(I);

      if I <= Length(S) then
      begin
        if (S[I] = '"') or (S[I] = '''') then
        begin
          Quote := S[I];
          Inc(I);

          J := I;

          while (J <= Length(S)) and (S[J] <> Quote) do
            Inc(J);

          AttrValue := Copy(S, I, J - I);
          I := J + 1;
        end
        else
        begin
          J := I;

          while (J <= Length(S)) and
                not (S[J] in [' ', #9, #10, #13, '>']) do
          begin
            Inc(J);
          end;

          AttrValue := Copy(S, I, J - I);
          I := J;
        end;

        if SameText(AttrName, AName) then
          Exit(AttrValue);
      end;
    end
    else
    begin
      if SameText(AttrName, AName) then
        Exit('');

      if (I <= Length(S)) and (S[I] in ['/', '>']) then
        Inc(I);
    end;

    if I = StartLoop then
      Inc(I);
  end;
end;

procedure ApplyHtmlStyleDeclaration(var Mods: THtmlStyleMods; const AItem: string);
var
  P: Integer;
  Name, Value, S: string;
  C: TColor;
  Num: Integer;
begin
  P := Pos(':', AItem);
  if P = 0 then
    Exit;

  Name := LowerCase(Trim(Copy(AItem, 1, P - 1)));
  Value := Trim(Copy(AItem, P + 1, MaxInt));

  Value := StringReplace(Value, '!important', '', [rfReplaceAll, rfIgnoreCase]);
  Value := Trim(Value);

  S := LowerCase(Value);

  if Name = 'color' then
  begin
    if TryParseHtmlColor(Value, C) then
    begin
      Mods.HasColor := True;
      Mods.Color := C;
    end;
  end
  else if Name = 'font-weight' then
  begin
    Mods.HasBold := True;

    if (S = 'bold') or (S = 'bolder') then
    begin
      Mods.Bold := True;
    end
    else if (S = 'normal') or (S = 'lighter') then
    begin
      Mods.Bold := False;
    end
    else if TryParseNumberPrefix(S, Num) then
    begin
      Mods.Bold := Num >= 600;
    end
    else
    begin
      Mods.Bold := False;
    end;
  end
  else if Name = 'font-style' then
  begin
    Mods.HasItalic := True;

    if (S = 'italic') or (S = 'oblique') then
      Mods.Italic := True
    else
      Mods.Italic := False;
  end
  else if Name = 'text-decoration' then
  begin
    if Pos('none', S) > 0 then
    begin
      Mods.HasUnderline := True;
      Mods.Underline := False;

      Mods.HasStrikeOut := True;
      Mods.StrikeOut := False;
    end
    else
    begin
      if Pos('underline', S) > 0 then
      begin
        Mods.HasUnderline := True;
        Mods.Underline := True;
      end;

      if Pos('line-through', S) > 0 then
      begin
        Mods.HasStrikeOut := True;
        Mods.StrikeOut := True;
      end;
    end;
  end;
end;

function ParseHtmlInlineStyle(const AStyle: string): THtmlStyleMods;
var
  I, Start: Integer;
  Item: string;
begin
  Result := EmptyHtmlStyleMods;

  Start := 1;

  for I := 1 to Length(AStyle) do
  begin
    if AStyle[I] = ';' then
    begin
      Item := Trim(Copy(AStyle, Start, I - Start));

      if Item <> '' then
        ApplyHtmlStyleDeclaration(Result, Item);

      Start := I + 1;
    end;
  end;

  Item := Trim(Copy(AStyle, Start, MaxInt));

  if Item <> '' then
    ApplyHtmlStyleDeclaration(Result, Item);
end;

function NormalizeLineEndings(const S: string): string;
begin
  Result := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

function NormalizeInlineSpaces(const S: string): string;
begin
  Result := NormalizeLineEndings(S);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #9, ' ', [rfReplaceAll]);
end;

function DecodeHtmlEntities(const S: string): string;
begin
  Result := S;

  Result := StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&#39;', '''', [rfReplaceAll, rfIgnoreCase]);

  // It is important to process this last, so as not to corrupt already-replaced entities.
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
end;

function HtmlHeadingLevel(const AName: string): Integer;
begin
  if AName = 'h1' then Result := 1
  else if AName = 'h2' then Result := 2
  else if AName = 'h3' then Result := 3
  else if AName = 'h4' then Result := 4
  else if AName = 'h5' then Result := 5
  else if AName = 'h6' then Result := 6
  else Result := 0;
end;

function FindXmpClosingTag(const AText: string; StartPos: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  I := StartPos;

  while I + 4 <= Length(AText) do
  begin
    if (AText[I] = '<') and (AText[I + 1] = '/') and
       (AText[I + 2] in ['x', 'X']) and
       (AText[I + 3] in ['m', 'M']) and
       (AText[I + 4] in ['p', 'P']) and
       ((I + 5 > Length(AText)) or
        (AText[I + 5] in [' ', #9, #10, #13, '>', '/'])) then
    begin
      Result := I;
      Exit;
    end;

    Inc(I);
  end;
end;

function TryParseTextAlignValue(const AValue: string; out AAlign: TCssTextAlign): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AValue));
  Result := True;

  if (S = 'left') or (S = 'start') then
    AAlign := ctaLeft
  else if S = 'center' then
    AAlign := ctaCenter
  else if S = 'right' then
    AAlign := ctaRight
  else
    Result := False;
end;

function TryGetTextAlignFromStyle(const AStyle: string; out AAlign: TCssTextAlign): Boolean;
var
  I, Start, P: Integer;
  Item, Name, Value: string;
begin
  Result := False;
  Start := 1;

  for I := 1 to Length(AStyle) + 1 do
  begin
    if (I > Length(AStyle)) or (AStyle[I] = ';') then
    begin
      Item := Trim(Copy(AStyle, Start, I - Start));
      P := Pos(':', Item);

      if P > 0 then
      begin
        Name := LowerCase(Trim(Copy(Item, 1, P - 1)));
        Value := Trim(Copy(Item, P + 1, MaxInt));
        Value := StringReplace(Value, '!important', '', [rfReplaceAll, rfIgnoreCase]);
        Value := Trim(Value);

        if Name = 'text-align' then
        begin
          if TryParseTextAlignValue(Value, AAlign) then
            Exit(True);
        end;
      end;

      Start := I + 1;
    end;
  end;
end;

function IsHintSelector(const ASelector: string; out ABaseSelector: string): Boolean;
var
  S, L: string;
  P: Integer;
begin
  Result := False;
  S := Trim(ASelector);
  L := LowerCase(S);

  // Supported simple form:
  // hint { ... }
  if SameText(L, 'hint') then
  begin
    Result := True;
    ABaseSelector := '*';
    Exit;
  end;

  // Main form:
  // control::hint
  // .btn::hint
  // #id:hover::hint
  P := Pos('::hint', L);
  if (P > 0) and (Trim(Copy(S, P + 6, MaxInt)) = '') then
  begin
    Result := True;
    ABaseSelector := Trim(Copy(S, 1, P - 1));
    if ABaseSelector = '' then
      ABaseSelector := '*';
    Exit;
  end;

  // Additionally, the old/simplified form is supported:
  // control:hint
  P := PosEx(':hint', L, 1);
  if (P > 0) and
     ((P = 1) or (L[P - 1] <> ':')) and
     (Trim(Copy(S, P + 5, MaxInt)) = '') then
  begin
    Result := True;
    ABaseSelector := Trim(Copy(S, 1, P - 1));
    if ABaseSelector = '' then
      ABaseSelector := '*';
    Exit;
  end;

  ABaseSelector := S;
end;

procedure ParseHtmlBlocks(
  const AText: string;
  out Blocks: THtmlBlocks;
  out Links: TCssHtmlLinkInfos);
var
  I, J, P, Level: Integer;
  TagContent, Tag, Name, TextPart, AttrValue: string;
  Closing, SelfClosing: Boolean;
  BlockCount: Integer;
  CurrentBlock: THtmlBlock;
  HasBlock: Boolean;

  StyleStack: array of THtmlInlineMod;
  M: THtmlStyleMods;
  C: TColor;
  NextLinkId: Integer;
  ListStack: array of THtmlListStackItem;

  function LinkIndexById(ALinkId: Integer): Integer;
  var
    K: Integer;
  begin
    Result := -1;
    for K := 0 to High(Links) do
    begin
      if Links[K].LinkId = ALinkId then
      begin
        Result := K;
        Exit;
      end;
    end;
  end;

  procedure AddLinkInfo(ALinkId: Integer; const AHref: string);
  var
    N: Integer;
  begin
    N := Length(Links);
    SetLength(Links, N + 1);
    Links[N].LinkId := ALinkId;
    Links[N].Href := AHref;
    Links[N].Text := '';
  end;

  procedure AppendLinkText(ALinkId: Integer; const S: string);
  var
    Idx: Integer;
  begin
    if S = '' then
      Exit;
    Idx := LinkIndexById(ALinkId);
    if Idx >= 0 then
      Links[Idx].Text := Links[Idx].Text + S;
  end;

  function CurrentStyle: THtmlInlineStyle;
  var
    K: Integer;
    Mods: THtmlStyleMods;
  begin
    Result := EmptyHtmlInlineStyle;

    for K := 0 to High(StyleStack) do
    begin
      Mods := StyleStack[K].Mods;

      if Mods.HasBold then
        Result.Bold := Mods.Bold;

      if Mods.HasItalic then
        Result.Italic := Mods.Italic;

      if Mods.HasUnderline then
        Result.Underline := Mods.Underline;

      if Mods.HasStrikeOut then
        Result.StrikeOut := Mods.StrikeOut;

      if Mods.HasMono then
        Result.Mono := Mods.Mono;

      if Mods.HasSup then
      begin
        Result.Sup := Mods.Sup;

        if Mods.Sup then
          Result.Sub := False;
      end;

      if Mods.HasSub then
      begin
        Result.Sub := Mods.Sub;

        if Mods.Sub then
          Result.Sup := False;
      end;

      if Mods.HasColor then
      begin
        Result.Color := Mods.Color;
        Result.HasColor := True;
      end;

      if Mods.HasLink then
      begin
        Result.Link := Mods.Link;
        Result.Href := Mods.Href;
        Result.LinkId := Mods.LinkId;
      end;
    end;
  end;

  procedure ResetInline;
  begin
    SetLength(StyleStack, 0);
  end;

  procedure PushStyleMod(const ATagName: string; const AMods: THtmlStyleMods);
  var
    N: Integer;
  begin
    N := Length(StyleStack);

    SetLength(StyleStack, N + 1);

    StyleStack[N].TagName := LowerCase(ATagName);
    StyleStack[N].Mods := AMods;
  end;

  procedure PopStyleMod(const ATagName: string);
  var
    K, L: Integer;
  begin
    for K := High(StyleStack) downto 0 do
    begin
      if SameText(StyleStack[K].TagName, ATagName) then
      begin
        for L := K to High(StyleStack) - 1 do
          StyleStack[L] := StyleStack[L + 1];

        SetLength(StyleStack, Length(StyleStack) - 1);
        Exit;
      end;
    end;
  end;

  procedure ClearBlock;
  begin
    CurrentBlock.Kind := hbParagraph;
    CurrentBlock.Level := 0;
    CurrentBlock.Align := ctaLeft;
    CurrentBlock.HasAlign := False;
    CurrentBlock.Runs := nil;
    CurrentBlock.ListIndent := 0;
    CurrentBlock.ListBullet := '';
  end;

  procedure FlushBlock;
  begin
    if HasBlock then
    begin
      SetLength(Blocks, BlockCount + 1);
      Blocks[BlockCount] := CurrentBlock;
      Inc(BlockCount);
    end;

    HasBlock := False;
    ClearBlock;
  end;

  procedure ApplyBlockAlignFromTag(const ATag: string);
  var
    S: string;
    A: TCssTextAlign;
  begin
    if not HasBlock then
      Exit;

    // align attribute:
    // <p align="center">
    S := GetHtmlAttribute(ATag, 'align');
    if (S <> '') and TryParseTextAlignValue(S, A) then
    begin
      CurrentBlock.HasAlign := True;
      CurrentBlock.Align := A;
    end;

    // Style:
    // <div style="text-align:right">
    S := GetHtmlAttribute(ATag, 'style');
    if (S <> '') and TryGetTextAlignFromStyle(S, A) then
    begin
      CurrentBlock.HasAlign := True;
      CurrentBlock.Align := A;
    end;
  end;

  procedure StartBlock(Kind: THtmlBlockKind; ALevel: Integer);
  begin
    FlushBlock;
    ResetInline;

    CurrentBlock.Kind := Kind;
    CurrentBlock.Level := ALevel;
    CurrentBlock.Runs := nil;
    HasBlock := True;
  end;

  procedure StartStyledBlock(Kind: THtmlBlockKind; ALevel: Integer);
  begin
    StartBlock(Kind, ALevel);
    ApplyBlockAlignFromTag(Tag);
  end;

  procedure EnsureBlock;
  begin
    if not HasBlock then
    begin
      ClearBlock;
      HasBlock := True;
    end;
  end;

  procedure AppendRun(const S: string; const Style: THtmlInlineStyle);
  var
    N: Integer;
  begin
    if S = '' then
      Exit;

    EnsureBlock;

    if CurrentBlock.Kind = hbHr then
      Exit;

    N := Length(CurrentBlock.Runs);

    SetLength(CurrentBlock.Runs, N + 1);

    CurrentBlock.Runs[N].Text := S;
    CurrentBlock.Runs[N].Style := Style;
  end;

  procedure AddText(const S: string);
  var
    T: string;
    CS: THtmlInlineStyle;
  begin
    if S = '' then
      Exit;

    T := S;

    if (not HasBlock) and (Trim(T) = '') then
      Exit;

    EnsureBlock;

    if (CurrentBlock.Kind <> hbPre) and (CurrentBlock.Kind <> hbXmp) then
      T := NormalizeInlineSpaces(T)
    else
      T := NormalizeLineEndings(T);

    if T <> '' then
    begin
      CS := CurrentStyle;
      AppendRun(T, CS);

      if CS.Link and (CS.LinkId > 0) then
        AppendLinkText(CS.LinkId, T);
    end;
  end;

  procedure AddBr;
  begin
    EnsureBlock;
    AppendRun(#10, CurrentStyle);
  end;

  procedure AddHr;
  begin
    FlushBlock;
    ResetInline;

    SetLength(Blocks, BlockCount + 1);
    Blocks[BlockCount].Kind := hbHr;
    Blocks[BlockCount].Level := 0;
    Blocks[BlockCount].Align := ctaLeft;
    Blocks[BlockCount].HasAlign := False;
    Blocks[BlockCount].Runs := nil;
    Inc(BlockCount);

    HasBlock := False;
    ClearBlock;
  end;

  procedure PushList(AOrdered: Boolean);
  var
    N: Integer;
  begin
    FlushBlock;
    ResetInline;

    N := Length(ListStack);
    SetLength(ListStack, N + 1);
    ListStack[N].Ordered := AOrdered;
    ListStack[N].Counter := 0;
  end;

  procedure PopList;
  begin
    if Length(ListStack) > 0 then
      SetLength(ListStack, Length(ListStack) - 1);

    FlushBlock;
    ResetInline;
  end;

begin
  Blocks := nil;
  BlockCount := 0;

  HasBlock := False;
  ClearBlock;
  ResetInline;
  NextLinkId := 0;
  Links := nil;
  ListStack := nil;

  I := 1;

  while I <= Length(AText) do
  begin
    if AText[I] = '<' then
    begin
      if Copy(AText, I, 4) = '<!--' then
      begin
        J := PosEx('-->', AText, I + 4);
        if J = 0 then
          Break;

        I := J + 3;
        Continue;
      end;

      J := PosEx('>', AText, I + 1);
      if J = 0 then
        Break;

      TagContent := Copy(AText, I + 1, J - I - 1);
      I := J + 1;

      Tag := Trim(TagContent);

      if Tag = '' then
        Continue;

      if Tag[1] = '!' then
        Continue;

      Closing := False;
      SelfClosing := False;

      if Tag[1] = '/' then
      begin
        Closing := True;
        Delete(Tag, 1, 1);
        Tag := Trim(Tag);
      end;

      if (Tag <> '') and (Tag[Length(Tag)] = '/') then
      begin
        SelfClosing := True;
        Delete(Tag, Length(Tag), 1);
        Tag := Trim(Tag);
      end;

      P := 1;

      while (P <= Length(Tag)) and
            not (Tag[P] in [' ', #9, #10, #13]) do
      begin
        Inc(P);
      end;

      Name := LowerCase(Copy(Tag, 1, P - 1));
      Level := HtmlHeadingLevel(Name);

      if Level > 0 then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbHeading, Level);

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'p' then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbParagraph, 0);

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if (Name = 'div') or
              (Name = 'section') or
              (Name = 'article') or
              (Name = 'header') or
              (Name = 'footer') then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbParagraph, 0);

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'center' then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbParagraph, 0);
          CurrentBlock.HasAlign := True;
          CurrentBlock.Align := ctaCenter;

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'pre' then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbPre, 0);

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'xmp' then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else if not SelfClosing then
        begin
          J := FindXmpClosingTag(AText, I);

          if J = 0 then
          begin
            TextPart := Copy(AText, I, MaxInt);
            I := Length(AText) + 1;
          end
          else
          begin
            TextPart := Copy(AText, I, J - I);

            P := PosEx('>', AText, J + 5);
            if P = 0 then
              I := Length(AText) + 1
            else
              I := P + 1;
          end;

          if TextPart <> '' then
          begin
            StartStyledBlock(hbXmp, 0);
            AddText(TextPart);
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'hr' then
      begin
        if not Closing then
          AddHr;
      end
      else if Name = 'br' then
      begin
        if not Closing then
          AddBr;
      end
      else if Name = 'q' then
      begin
        if Closing then
          AddText('»')
        else
          AddText('«');
      end
      else if (Name = 'b') or (Name = 'strong') then
      begin
        if Closing then
        begin
          PopStyleMod('bold');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasBold := True;
          M.Bold := True;
          PushStyleMod('bold', M);
        end;
      end
      else if (Name = 'i') or (Name = 'em') then
      begin
        if Closing then
        begin
          PopStyleMod('italic');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasItalic := True;
          M.Italic := True;
          PushStyleMod('italic', M);
        end;
      end
      else if (Name = 'u') or (Name = 'ins') then
      begin
        if Closing then
        begin
          PopStyleMod('underline');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasUnderline := True;
          M.Underline := True;
          PushStyleMod('underline', M);
        end;
      end
      else if (Name = 'del') or (Name = 's') or (Name = 'strike') then
      begin
        if Closing then
        begin
          PopStyleMod('strike');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasStrikeOut := True;
          M.StrikeOut := True;
          PushStyleMod('strike', M);
        end;
      end
      else if (Name = 'code') or (Name = 'kbd') or
              (Name = 'samp') or (Name = 'tt') then
      begin
        if Closing then
        begin
          PopStyleMod('mono');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasMono := True;
          M.Mono := True;
          PushStyleMod('mono', M);
        end;
      end
      else if Name = 'sup' then
      begin
        if Closing then
        begin
          PopStyleMod('sup');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasSup := True;
          M.Sup := True;
          PushStyleMod('sup', M);
        end;
      end
      else if Name = 'sub' then
      begin
        if Closing then
        begin
          PopStyleMod('sub');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasSub := True;
          M.Sub := True;
          PushStyleMod('sub', M);
        end;
      end
      else if Name = 'font' then
      begin
        if Closing then
        begin
          PopStyleMod('font');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;

          AttrValue := GetHtmlAttribute(Tag, 'color');

          if (AttrValue <> '') and TryParseHtmlColor(AttrValue, C) then
          begin
            M.HasColor := True;
            M.Color := C;
          end;

          PushStyleMod('font', M);
        end;
      end
      else if Name = 'ul' then
      begin
        if Closing then
        begin
          PopList;
        end
        else
        begin
          PushList(False);
          if SelfClosing then
            PopList;
        end;
      end
      else if Name = 'ol' then
      begin
        if Closing then
        begin
          PopList;
        end
        else
        begin
          PushList(True);
          if SelfClosing then
            PopList;
        end;
      end
      else if Name = 'li' then
      begin
        if Closing then
        begin
          FlushBlock;
          ResetInline;
        end
        else
        begin
          StartStyledBlock(hbListItem, 0);

          CurrentBlock.ListIndent := Length(ListStack) - 1;
          if CurrentBlock.ListIndent < 0 then
            CurrentBlock.ListIndent := 0;

          if Length(ListStack) > 0 then
          begin
            if ListStack[High(ListStack)].Ordered then
            begin
              Inc(ListStack[High(ListStack)].Counter);
              CurrentBlock.ListBullet := IntToStr(ListStack[High(ListStack)].Counter) + '. ';
            end
            else
            begin
              CurrentBlock.ListBullet := '• ';
            end;
          end
          else
          begin
            CurrentBlock.ListBullet := '• ';
          end;

          if SelfClosing then
          begin
            FlushBlock;
            ResetInline;
          end;
        end;
      end
      else if Name = 'a' then
      begin
        if Closing then
        begin
          PopStyleMod('a');
        end
        else if not SelfClosing then
        begin
          M := EmptyHtmlStyleMods;
          M.HasLink := True;
          M.Link := True;
          M.Href := GetHtmlAttribute(Tag, 'href');

          Inc(NextLinkId);
          M.LinkId := NextLinkId;

          PushStyleMod('a', M);
          AddLinkInfo(NextLinkId, M.Href);
        end;
      end
      else if Name = 'span' then
      begin
        if Closing then
        begin
          PopStyleMod('span');
        end
        else if not SelfClosing then
        begin
          AttrValue := GetHtmlAttribute(Tag, 'style');
          M := ParseHtmlInlineStyle(AttrValue);
          PushStyleMod('span', M);
        end;
      end;
    end
    else
    begin
      J := PosEx('<', AText, I);
      if J = 0 then
        J := Length(AText) + 1;

      TextPart := Copy(AText, I, J - I);

      if TextPart <> '' then
      begin
        TextPart := NormalizeLineEndings(TextPart);
        TextPart := DecodeHtmlEntities(TextPart);
        AddText(TextPart);
      end;

      I := J;
    end;
  end;

  FlushBlock;
end;

procedure ParseHtmlBlocks(const AText: string; out Blocks: THtmlBlocks); overload;
var
  DummyLinks: TCssHtmlLinkInfos;
begin
  ParseHtmlBlocks(AText, Blocks, DummyLinks);
end;

{ ============================================================ }
{ Rounded-rect AA cache                                        }
{ ============================================================ }

{ --- Signed distance to a rounded box (centered at origin) --- }

function SdRoundBox(PX, PY, HW, HH, R: Double): Double;
var
  QX, QY: Double;
begin
  QX := Abs(PX) - HW + R;
  QY := Abs(PY) - HH + R;
  Result :=
    Min(Max(QX, QY), 0.0) +
    Sqrt(Sqr(Max(QX, 0.0)) + Sqr(Max(QY, 0.0))) - R;
end;

function ClampD(AValue, AMin, AMax: Double): Double; inline;
begin
  if AValue < AMin then Result := AMin
  else if AValue > AMax then Result := AMax
  else Result := AValue;
end;

procedure ClampCornerRadii(
  var RTL, RTR, RBR, RBL: Double;
  W, H: Double);
var
  F, F1, F2, F3, F4: Double;
begin
  F1 := 1.0; F2 := 1.0; F3 := 1.0; F4 := 1.0;

  if (RTL + RTR) > 0 then F1 := W / (RTL + RTR);
  if (RBR + RBL) > 0 then F2 := W / (RBR + RBL);
  if (RTL + RBL) > 0 then F3 := H / (RTL + RBL);
  if (RTR + RBR) > 0 then F4 := H / (RTR + RBR);

  F := F1;
  if F2 < F then F := F2;
  if F3 < F then F := F3;
  if F4 < F then F := F4;
  if F > 1.0 then F := 1.0;
  if F < 0.0 then F := 0.0;

  RTL := RTL * F; RTR := RTR * F;
  RBR := RBR * F; RBL := RBL * F;
end;

function SdRoundBoxPC(
  PX, PY, HW, HH, RTL, RTR, RBR, RBL: Double): Double;
var
  R, QX, QY: Double;
begin
  if (PX >= 0) and (PY < 0) then R := RTR
  else if (PX < 0) and (PY < 0) then R := RTL
  else if (PX < 0) and (PY >= 0) then R := RBL
  else R := RBR;

  QX := Abs(PX) - HW + R;
  QY := Abs(PY) - HH + R;

  Result :=
    Min(Max(QX, QY), 0.0) +
    Sqrt(Sqr(Max(QX, 0.0)) + Sqr(Max(QY, 0.0))) - R;
end;

function SdPerimeterAngle(
  PX, PY, HW, HH, RTL, RTR, RBR, RBL: Double): Double;
const
  EPS = 0.5;
var
  GX, GY: Double;
begin
  GX := SdRoundBoxPC(PX + EPS, PY, HW, HH, RTL, RTR, RBR, RBL) -
        SdRoundBoxPC(PX - EPS, PY, HW, HH, RTL, RTR, RBR, RBL);
  GY := SdRoundBoxPC(PX, PY + EPS, HW, HH, RTL, RTR, RBR, RBL) -
        SdRoundBoxPC(PX, PY - EPS, HW, HH, RTL, RTR, RBR, RBL);

  Result := ArcTan2(GY, GX);
end;

function LerpColor(C1, C2: TColor; T: Double): TColor;
var
  RGB1, RGB2: LongInt;
  R1, G1, B1, R2, G2, B2: Integer;
begin
  if T <= 0 then Exit(C1);
  if T >= 1 then Exit(C2);

  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);

  R1 := RGB1 and $FF; G1 := (RGB1 shr 8) and $FF; B1 := (RGB1 shr 16) and $FF;
  R2 := RGB2 and $FF; G2 := (RGB2 shr 8) and $FF; B2 := (RGB2 shr 16) and $FF;

  Result := RGBToColor(
    Round(R1 + (R2 - R1) * T),
    Round(G1 + (G2 - G1) * T),
    Round(B1 + (B2 - B1) * T)
  );
end;

procedure EvalGradientColor(
  const G: TCssGradient;
  PX, PY, HW, HH: Double;
  out R, GG, B: Byte);
var
  T, LocalT, DirX, DirY, Proj, L, MaxR: Double;
  I: Integer;
  Col: TColor;
  RGB: LongInt;
begin
  R := 0; GG := 0; B := 0;

  if Length(G.Stops) = 0 then
    Exit;

  if G.Kind = cgkLinear then
  begin
    DirX := Sin(G.Angle);
    DirY := -Cos(G.Angle);

    Proj := PX * DirX + PY * DirY;
    L := Abs(DirX) * (2 * HW) + Abs(DirY) * (2 * HH);

    if L > 1E-6 then
      T := Proj / L + 0.5
    else
      T := 0.5;
  end
  else
  begin
    MaxR := Sqrt(HW * HW + HH * HH);

    if MaxR > 1E-6 then
      T := Sqrt(PX * PX + PY * PY) / MaxR
    else
      T := 0;
  end;

  T := ClampD(T, 0, 1);

  if T <= G.Stops[0].Position then
    Col := G.Stops[0].Color
  else if T >= G.Stops[High(G.Stops)].Position then
    Col := G.Stops[High(G.Stops)].Color
  else
  begin
    Col := G.Stops[0].Color;

    for I := 0 to High(G.Stops) - 1 do
    begin
      if (T >= G.Stops[I].Position) and (T <= G.Stops[I + 1].Position) then
      begin
        if G.Stops[I + 1].Position - G.Stops[I].Position > 1E-6 then
          LocalT := (T - G.Stops[I].Position) /
                    (G.Stops[I + 1].Position - G.Stops[I].Position)
        else
          LocalT := 0;

        Col := LerpColor(G.Stops[I].Color, G.Stops[I + 1].Color, LocalT);
        Break;
      end;
    end;
  end;

  RGB := ColorToRGB(Col);
  R  := Byte(RGB and $FF);
  GG := Byte((RGB shr 8) and $FF);
  B  := Byte((RGB shr 16) and $FF);
end;

function PerimeterParam(PX, PY, HW, HH: Double): Double;
var
  Angle: Double;
begin
  if (HW <= 0) or (HH <= 0) then
    Exit(0);
  Angle := ArcTan2(PY / HH, PX / HW);  // -Pi..Pi
  Result := (Angle + Pi) / (2 * Pi);   // 0..1
end;

procedure RenderRoundedRectToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams;
  APadX, APadY: Integer);
var
  Img: TLazIntfImage;
  PW, PH, X, Y: Integer;
  BgR, BgG, BgB: Byte;
  BgRGB: TColor;
  FillR, FillG, FillB: Byte;
  BorderR, BorderG, BorderB: Byte;
  ShadowR, ShadowG, ShadowB: Byte;
  HasFill, HasBorder, HasShadow: Boolean;
  Pixel: TFPColor;
  HW, HH, RTL, RTR, RBR, RBL, BW: Double;
  Blur, Spread, ShadowOffX, ShadowOffY: Double;
  PX, PY, SDF, SDF_Shadow: Double;
  OuterCov, InnerCov, BorderCov, ShadowCov: Double;
  FillRGB, BorderRGB, ShadowRGB: TColor;
  CompR, CompG, CompB: Double;
  DashMask, Param: Double;
  IsDash, IsDot: Boolean;
  FFR, FFG, FFB: Byte;
  UseGrad: Boolean;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then
    Exit;

  PW := AW + APadX * 2;
  PH := AH + APadY * 2;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(PW, PH);

  HasFill   := (AParams.FillColor <> clNone) and
               (AParams.FillColor <> clDefault);
  HasBorder := (AParams.BorderWidth > 0) and
               (AParams.BorderColor <> clNone) and
               (AParams.BorderColor <> clDefault);
  HasShadow := AParams.Shadow.Used and AParams.Shadow.HasColor;

  UseGrad := AParams.HasGradient and
             (AParams.Gradient.Kind <> cgkNone) and
             (Length(AParams.Gradient.Stops) > 0);

  IsDash := AParams.BorderStyle = cbsDashed;
  IsDot  := AParams.BorderStyle = cbsDotted;

  if HasFill then
  begin
    FillRGB := ColorToRGB(AParams.FillColor);
    FillR := Byte(FillRGB and $FF);
    FillG := Byte((FillRGB shr 8) and $FF);
    FillB := Byte((FillRGB shr 16) and $FF);
  end
  else
  begin
    FillR := 0; FillG := 0; FillB := 0;
  end;

  if HasBorder then
  begin
    BorderRGB := ColorToRGB(AParams.BorderColor);
    BorderR := Byte(BorderRGB and $FF);
    BorderG := Byte((BorderRGB shr 8) and $FF);
    BorderB := Byte((BorderRGB shr 16) and $FF);
  end
  else
  begin
    BorderR := 0; BorderG := 0; BorderB := 0;
  end;

  if HasShadow then
  begin
    ShadowRGB := ColorToRGB(AParams.Shadow.Color);
    ShadowR := Byte(ShadowRGB and $FF);
    ShadowG := Byte((ShadowRGB shr 8) and $FF);
    ShadowB := Byte((ShadowRGB shr 16) and $FF);
  end
  else
  begin
    ShadowR := 0; ShadowG := 0; ShadowB := 0;
  end;

  Img := ABitmap.CreateIntfImage;
  try
    HW := AW / 2.0;
    HH := AH / 2.0;

    RTL := AParams.Radii.TL;
    RTR := AParams.Radii.TR;
    RBR := AParams.Radii.BR;
    RBL := AParams.Radii.BL;
    ClampCornerRadii(RTL, RTR, RBR, RBL, AW, AH);

    BW := AParams.BorderWidth;
    if BW < 0 then BW := 0;

    ShadowOffX := AParams.Shadow.OffsetX;
    ShadowOffY := AParams.Shadow.OffsetY;
    Blur       := AParams.Shadow.Blur;
    Spread     := AParams.Shadow.Spread;

    for Y := 0 to PH - 1 do
    begin
      for X := 0 to PW - 1 do
      begin
        PX := X + 0.5 - APadX - HW;
        PY := Y + 0.5 - APadY - HH;

        if (PX < 0) and (PY < 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[0])   // TL
        else if (PX >= 0) and (PY < 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[1])   // TR
        else if (PX >= 0) and (PY >= 0) then
          BgRGB := ColorToRGB(AParams.CornerBackColor[2])   // BR
        else
          BgRGB := ColorToRGB(AParams.CornerBackColor[3]);  // BL

        BgR := Byte(BgRGB and $FF);
        BgG := Byte((BgRGB shr 8) and $FF);
        BgB := Byte((BgRGB shr 16) and $FF);

        ShadowCov := 0;
        if HasShadow then
        begin
          SDF_Shadow := SdRoundBoxPC(
            PX - ShadowOffX, PY - ShadowOffY,
            HW + Spread, HH + Spread,
            RTL + Spread, RTR + Spread,
            RBR + Spread, RBL + Spread
          );

          if Blur > 0.5 then
            ShadowCov := ClampD(0.5 - SDF_Shadow / Blur, 0, 1)
          else
            ShadowCov := ClampD(0.5 - SDF_Shadow, 0, 1);
        end;

        SDF := SdRoundBoxPC(PX, PY, HW, HH, RTL, RTR, RBR, RBL);
        OuterCov := ClampD(0.5 - SDF, 0, 1);

        if HasBorder then
          InnerCov := ClampD(0.5 - (SDF + BW), 0, 1)
        else
          InnerCov := OuterCov;

        BorderCov := OuterCov - InnerCov;

        if HasBorder and (IsDash or IsDot) and (BorderCov > 0.001) then
        begin
          Param := SdPerimeterAngle(PX, PY, HW, HH, RTL, RTR, RBR, RBL);
          Param := (Param + Pi) / (2 * Pi);

          if IsDash then
            DashMask := Frac(Param * 24)
          else
            DashMask := Frac(Param * 48);

          if IsDash then
            if DashMask < 0.6 then DashMask := 1 else DashMask := 0
          else
            if DashMask < 0.35 then DashMask := 1 else DashMask := 0;

          BorderCov := BorderCov * DashMask;
        end;

        if ShadowCov > 0 then
          ShadowCov := ShadowCov * (1 - OuterCov);

        CompR := BgR * (1 - ShadowCov) + ShadowR * ShadowCov;
        CompG := BgG * (1 - ShadowCov) + ShadowG * ShadowCov;
        CompB := BgB * (1 - ShadowCov) + ShadowB * ShadowCov;

        if UseGrad then
        begin
          EvalGradientColor(AParams.Gradient, PX, PY, HW, HH, FFR, FFG, FFB);
          CompR := CompR * (1 - InnerCov) + FFR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FFG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FFB * InnerCov;
        end
        else if HasFill then
        begin
          CompR := CompR * (1 - InnerCov) + FillR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FillG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FillB * InnerCov;
        end;

        if HasBorder then
        begin
          CompR := CompR * (1 - BorderCov) + BorderR * BorderCov;
          CompG := CompG * (1 - BorderCov) + BorderG * BorderCov;
          CompB := CompB * (1 - BorderCov) + BorderB * BorderCov;
        end;

        Pixel.Red   := Round(ClampD(CompR, 0, 255)) * 257;
        Pixel.Green := Round(ClampD(CompG, 0, 255)) * 257;
        Pixel.Blue  := Round(ClampD(CompB, 0, 255)) * 257;
        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;
    end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

type
  TCssRoundedRectCacheEntry = class
    Signature: string;
    Bitmap: TBitmap;
    constructor Create;
    destructor Destroy; override;
  end;

  TCssRoundedRectCache = class
  private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetBitmap(
      AW, AH: Integer;
      const AParams: TCssRoundedBoxParams): TBitmap;
  end;

const
  CSS_ROUNDED_RECT_CACHE_LIMIT = 96;

constructor TCssRoundedRectCacheEntry.Create;
begin
  inherited;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf32bit;
end;

destructor TCssRoundedRectCacheEntry.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

constructor TCssRoundedRectCache.Create;
begin
  inherited;
  FEntries := TStringList.Create;
  FEntries.CaseSensitive := True;
  FEntries.Sorted := False;
end;

destructor TCssRoundedRectCache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited;
end;

procedure TCssRoundedRectCache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssRoundedRectCacheEntry(FEntries.Objects[I]).Free;

  FEntries.Clear;
end;

function BuildRoundedRectSignature(
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams): string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(AW).Append(',').Append(AH).Append('|');
    SB.Append(AParams.Radii.TL).Append(',')
      .Append(AParams.Radii.TR).Append(',')
      .Append(AParams.Radii.BR).Append(',')
      .Append(AParams.Radii.BL).Append('|');

    SB.Append(AParams.BorderWidth).Append(',')
      .Append(Ord(AParams.BorderStyle)).Append('|');

    SB.Append(IntToStr(AParams.FillColor)).Append(',')
      .Append(IntToStr(AParams.BorderColor)).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[0])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[1])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[2])).Append(',')
      .Append(IntToStr(AParams.CornerBackColor[3])).Append('|');

    SB.Append(Ord(AParams.Shadow.Used)).Append(';');
    if AParams.Shadow.Used then
      SB.Append(AParams.Shadow.OffsetX).Append(',')
        .Append(AParams.Shadow.OffsetY).Append(',')
        .Append(AParams.Shadow.Blur).Append(',')
        .Append(AParams.Shadow.Spread).Append(',')
        .Append(IntToStr(AParams.Shadow.Color));

    SB.Append('|').Append(Ord(AParams.HasGradient)).Append(';');
    if AParams.HasGradient and (AParams.Gradient.Kind <> cgkNone) then
    begin
      SB.Append(Ord(AParams.Gradient.Kind)).Append(',');
      SB.Append(FormatFloat('0.0000', AParams.Gradient.Angle)).Append(';');

      for I := 0 to High(AParams.Gradient.Stops) do
        SB.Append(FormatFloat('0.0000', AParams.Gradient.Stops[I].Position))
          .Append(':')
          .Append(IntToStr(AParams.Gradient.Stops[I].Color))
          .Append(';');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure ComputeShadowPad(
  const AShadow: TCssBoxShadow;
  out APadX, APadY: Integer);
begin
  if AShadow.Used then
  begin
    APadX := Abs(AShadow.OffsetX) + AShadow.Blur + AShadow.Spread + 2;
    APadY := Abs(AShadow.OffsetY) + AShadow.Blur + AShadow.Spread + 2;
  end
  else
  begin
    APadX := 0;
    APadY := 0;
  end;
end;

function TCssRoundedRectCache.GetBitmap(
  AW, AH: Integer;
  const AParams: TCssRoundedBoxParams): TBitmap;
var
  Sig: string;
  Idx, PadX, PadY: Integer;
  Entry: TCssRoundedRectCacheEntry;
begin
  Sig := BuildRoundedRectSignature(AW, AH, AParams);

  Idx := FEntries.IndexOf(Sig);

  if Idx >= 0 then
  begin
    Entry := TCssRoundedRectCacheEntry(FEntries.Objects[Idx]);

    FEntries.Delete(Idx);
    FEntries.AddObject(Sig, Entry);

    Exit(Entry.Bitmap);
  end;

  while FEntries.Count >= CSS_ROUNDED_RECT_CACHE_LIMIT do
  begin
    TCssRoundedRectCacheEntry(FEntries.Objects[0]).Free;
    FEntries.Delete(0);
  end;

  ComputeShadowPad(AParams.Shadow, PadX, PadY);

  Entry := TCssRoundedRectCacheEntry.Create;
  Entry.Signature := Sig;

  RenderRoundedRectToBitmap(Entry.Bitmap, AW, AH, AParams, PadX, PadY);

  FEntries.AddObject(Sig, Entry);
  Result := Entry.Bitmap;
end;

var
  GRoundedRectCache: TCssRoundedRectCache = nil;

procedure EnsureRoundedRectCache;
begin
  if GRoundedRectCache = nil then
    GRoundedRectCache := TCssRoundedRectCache.Create;
end;

procedure InvalidateRoundedRectCache;
begin
  if Assigned(GRoundedRectCache) then
    GRoundedRectCache.Clear;
end;

{ ============================================================ }
{ Anti-aliased triangle / circle                                }
{ ============================================================ }

type
  TCssAACacheEntry = class
    Signature: string;
    Bitmap: TBitmap;
    constructor Create;
    destructor Destroy; override;
  end;

  TCssAACache = class
  private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetBitmap(const ASignature: string): TBitmap; // nil if missing
    procedure PutBitmap(const ASignature: string; ABitmap: TBitmap);
  end;

const
  CSS_AA_CACHE_LIMIT = 128;

constructor TCssAACacheEntry.Create;
begin
  inherited;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf32bit;
end;

destructor TCssAACacheEntry.Destroy;
begin
  Bitmap.Free;
  inherited;
end;

constructor TCssAACache.Create;
begin
  inherited;
  FEntries := TStringList.Create;
  FEntries.CaseSensitive := True;
  FEntries.Sorted := False;
end;

destructor TCssAACache.Destroy;
begin
  Clear;
  FEntries.Free;
  inherited;
end;

procedure TCssAACache.Clear;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TCssAACacheEntry(FEntries.Objects[I]).Free;
  FEntries.Clear;
end;

function TCssAACache.GetBitmap(const ASignature: string): TBitmap;
var
  Idx: Integer;
  E: TCssAACacheEntry;
begin
  Idx := FEntries.IndexOf(ASignature);

  if Idx < 0 then
    Exit(nil);

  E := TCssAACacheEntry(FEntries.Objects[Idx]);

  // Move to the end (LRU).
  FEntries.Delete(Idx);
  FEntries.AddObject(ASignature, E);

  Result := E.Bitmap;
end;

procedure TCssAACache.PutBitmap(const ASignature: string; ABitmap: TBitmap);
var
  E: TCssAACacheEntry;
begin
  while FEntries.Count >= CSS_AA_CACHE_LIMIT do
  begin
    TCssAACacheEntry(FEntries.Objects[0]).Free;
    FEntries.Delete(0);
  end;

  E := TCssAACacheEntry.Create;
  E.Signature := ASignature;
  E.Bitmap.Assign(ABitmap);

  FEntries.AddObject(ASignature, E);
end;

var
  GAA_TriangleCache: TCssAACache = nil;

function EdgeDistanceSigned(
  const A, B: TPoint;
  PX, PY: Double;
  AOutSign: Double): Double; inline;
var
  DX, DY, L: Double;
begin
  DX := B.X - A.X;
  DY := B.Y - A.Y;
  Result := (DX * (PY - A.Y) - DY * (PX - A.X)) * AOutSign;
  L := Sqrt(DX * DX + DY * DY);
  if L > 1E-9 then
    Result := Result / L
  else
    Result := 0;
end;

procedure RenderTriangleToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  const AP1, AP2, AP3: TPoint;
  AColor, ABgColor: TColor);
var
  Img: TLazIntfImage;
  X, Y: Integer;
  BgR, BgG, BgB: Byte;
  FR, FG, FB: Byte;
  BgRGB, FillRGB: TColor;
  Pixel: TFPColor;
  PX, PY: Double;
  Area, Sign: Double;
  D12, D23, D31: Double;
  MinD, Cov: Double;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then
    Exit;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);

  BgRGB := ColorToRGB(ABgColor);
  BgR := Byte(BgRGB and $FF);
  BgG := Byte((BgRGB shr 8) and $FF);
  BgB := Byte((BgRGB shr 16) and $FF);

  FillRGB := ColorToRGB(AColor);
  FR := Byte(FillRGB and $FF);
  FG := Byte((FillRGB shr 8) and $FF);
  FB := Byte((FillRGB shr 16) and $FF);

  // Sign: inside is where all edge values are >= 0.
  Area := (AP2.X - AP1.X) * (AP3.Y - AP1.Y) - (AP2.Y - AP1.Y) * (AP3.X - AP1.X);
  if Area >= 0 then Sign := 1 else Sign := -1;

  Img := ABitmap.CreateIntfImage;
  try
    for Y := 0 to AH - 1 do
    begin
      for X := 0 to AW - 1 do
      begin
        PX := X + 0.5;
        PY := Y + 0.5;

        // Signed distances to the 3 edges (positive inside).
        D12 := EdgeDistanceSigned(AP1, AP2, PX, PY, Sign);
        D23 := EdgeDistanceSigned(AP2, AP3, PX, PY, Sign);
        D31 := EdgeDistanceSigned(AP3, AP1, PX, PY, Sign);

        MinD := D12;
        if D23 < MinD then MinD := D23;
        if D31 < MinD then MinD := D31;

        Cov := 0.5 + MinD;

        if Cov <= 0 then
        begin
          Pixel.Red   := BgR * 257;
          Pixel.Green := BgG * 257;
          Pixel.Blue  := BgB * 257;
        end
        else if Cov >= 1 then
        begin
          Pixel.Red   := FR * 257;
          Pixel.Green := FG * 257;
          Pixel.Blue  := FB * 257;
        end
        else
        begin
          Pixel.Red   := Round(FR * Cov + BgR * (1 - Cov)) * 257;
          Pixel.Green := Round(FG * Cov + BgG * (1 - Cov)) * 257;
          Pixel.Blue  := Round(FB * Cov + BgB * (1 - Cov)) * 257;
        end;

        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;
    end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

procedure RenderCircleToBitmap(
  ABitmap: TBitmap;
  AW, AH: Integer;
  AFillColor, ABorderColor: TColor;
  ABorderWidth: Integer;
  ABgColor: TColor);
var
  Img: TLazIntfImage;
  X, Y: Integer;
  BgR, BgG, BgB: Byte;
  FillR, FillG, FillB: Byte;
  BorR, BorG, BorB: Byte;
  BgRGB, FillRGB, BorRGB: TColor;
  Pixel: TFPColor;
  CX, CY, R: Double;
  Dist, OuterCov, InnerCov, BorderCov: Double;
  HasFill, HasBorder: Boolean;
  PX, PY, CompR, CompG, CompB: Double;
begin
  if (AW <= 0) or (AH <= 0) or (ABitmap = nil) then Exit;

  ABitmap.PixelFormat := pf32bit;
  ABitmap.SetSize(AW, AH);

  BgRGB := ColorToRGB(ABgColor);
  BgR := Byte(BgRGB and $FF);
  BgG := Byte((BgRGB shr 8) and $FF);
  BgB := Byte((BgRGB shr 16) and $FF);

  HasFill := (AFillColor <> clNone) and (AFillColor <> clDefault);
  HasBorder := (ABorderWidth > 0) and
               (ABorderColor <> clNone) and (ABorderColor <> clDefault);

  if HasFill then
  begin
    FillRGB := ColorToRGB(AFillColor);
    FillR := Byte(FillRGB and $FF);
    FillG := Byte((FillRGB shr 8) and $FF);
    FillB := Byte((FillRGB shr 16) and $FF);
  end
  else
  begin
    FillR := 0; FillG := 0; FillB := 0;
  end;

  if HasBorder then
  begin
    BorRGB := ColorToRGB(ABorderColor);
    BorR := Byte(BorRGB and $FF);
    BorG := Byte((BorRGB shr 8) and $FF);
    BorB := Byte((BorRGB shr 16) and $FF);
  end
  else
  begin
    BorR := 0; BorG := 0; BorB := 0;
  end;

  CX := AW / 2.0;
  CY := AH / 2.0;
  R := Min(AW, AH) / 2.0 - 0.5;
  if R < 0 then R := 0;

  Img := ABitmap.CreateIntfImage;
  try
    for Y := 0 to AH - 1 do
    begin
      for X := 0 to AW - 1 do
      begin
        PX := X + 0.5 - CX;
        PY := Y + 0.5 - CY;
        Dist := Sqrt(PX * PX + PY * PY);

        OuterCov := 0.5 + (R - Dist);
        if OuterCov < 0 then OuterCov := 0
        else if OuterCov > 1 then OuterCov := 1;

        InnerCov := 0.5 + (R - ABorderWidth - Dist);
        if InnerCov < 0 then InnerCov := 0
        else if InnerCov > 1 then InnerCov := 1;

        BorderCov := OuterCov - InnerCov;
        if BorderCov < 0 then BorderCov := 0;

        CompR := BgR;
        CompG := BgG;
        CompB := BgB;

        if HasFill and (InnerCov > 0) then
        begin
          CompR := CompR * (1 - InnerCov) + FillR * InnerCov;
          CompG := CompG * (1 - InnerCov) + FillG * InnerCov;
          CompB := CompB * (1 - InnerCov) + FillB * InnerCov;
        end;

        if HasBorder and (BorderCov > 0) then
        begin
          CompR := CompR * (1 - BorderCov) + BorR * BorderCov;
          CompG := CompG * (1 - BorderCov) + BorG * BorderCov;
          CompB := CompB * (1 - BorderCov) + BorB * BorderCov;
        end;

        Pixel.Red   := Round(CompR) * 257;
        Pixel.Green := Round(CompG) * 257;
        Pixel.Blue  := Round(CompB) * 257;
        Pixel.Alpha := $FFFF;
        Img.Colors[X, Y] := Pixel;
      end;
    end;

    ABitmap.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

{ ============================================================ }
{ TCssStyledControl — construction / destruction               }
{ ============================================================ }

constructor TCssStyledControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCssTag := 'control';

  FMonospaceFontName := 'Courier New';

  FHintHtmlMode := True;
  FHintCss := '';

  Width := 120;
  Height := 32;

  TabStop := True;

  FMouseInControl := False;
  FMousePressed := False;
  FFocused := False;
  FChecked := False;
  FAutoToggle := False;

  FHtmlMode := False;
  FSuppressClick := False;

  FShowFocusRect := True;
  FFocusColor := clDefault;
  FFocusColorSet := False;

  ResetStyle;
end;

destructor TCssStyledControl.Destroy;
begin
  if Assigned(FStyleProvider) and
     not (csDestroying in FStyleProvider.ComponentState) then
  begin
    FStyleProvider.UnRegisterControl(Self);
    FStyleProvider.RemoveFreeNotification(Self);
    RemoveFreeNotification(FStyleProvider);
  end;

  FStyleProvider := nil;

  inherited Destroy;
end;

procedure TCssStyledControl.DrawAntiAliasedTriangle(
  ACanvas: TCanvas;
  const AP1, AP2, AP3: TPoint;
  AColor: TColor;
  ABackgroundColor: TColor);
var
  MinX, MinY, MaxX, MaxY, W, H: Integer;
  Bg: TColor;
  Sig: string;
  Bmp: TBitmap;
  Buf: TBitmap;
  P1, P2, P3: TPoint;
begin
  if ACanvas = nil then Exit;
  if AColor = clNone then Exit;

  MinX := AP1.X; if AP2.X < MinX then MinX := AP2.X; if AP3.X < MinX then MinX := AP3.X;
  MinY := AP1.Y; if AP2.Y < MinY then MinY := AP2.Y; if AP3.Y < MinY then MinY := AP3.Y;
  MaxX := AP1.X; if AP2.X > MaxX then MaxX := AP2.X; if AP3.X > MaxX then MaxX := AP3.X;
  MaxY := AP1.Y; if AP2.Y > MaxY then MaxY := AP2.Y; if AP3.Y > MaxY then MaxY := AP3.Y;

  // Leave 1px margin for AA.
  Dec(MinX); Dec(MinY);
  Inc(MaxX); Inc(MaxY);

  W := MaxX - MinX;
  H := MaxY - MinY;

  if (W <= 0) or (H <= 0) then Exit;

  if ABackgroundColor = clNone then
    Bg := GetParentBackgroundColor
  else
    Bg := ABackgroundColor;

  P1 := Point(AP1.X - MinX, AP1.Y - MinY);
  P2 := Point(AP2.X - MinX, AP2.Y - MinY);
  P3 := Point(AP3.X - MinX, AP3.Y - MinY);

  Sig := Format('T|%d,%d|%d,%d|%d,%d|%d,%d|%d|%d',
    [W, H,
     P1.X, P1.Y,
     P2.X, P2.Y,
     P3.X, P3.Y,
     Integer(AColor), Integer(Bg)]);

  if GAA_TriangleCache = nil then
    GAA_TriangleCache := TCssAACache.Create;

  Bmp := GAA_TriangleCache.GetBitmap(Sig);

  if Bmp = nil then
  begin
    Buf := TBitmap.Create;
    try
      RenderTriangleToBitmap(Buf, W, H, P1, P2, P3, AColor, Bg);
      GAA_TriangleCache.PutBitmap(Sig, Buf);
      Bmp := GAA_TriangleCache.GetBitmap(Sig);
    finally
      Buf.Free;
    end;
  end;

  if Bmp <> nil then
    ACanvas.Draw(MinX, MinY, Bmp);
end;

procedure TCssStyledControl.DrawAntiAliasedCircle(
  ACanvas: TCanvas;
  const ARect: TRect;
  AFillColor: TColor;
  ABorderColor: TColor;
  ABorderWidth: Integer;
  ABackgroundColor: TColor);
var
  W, H: Integer;
  Bg: TColor;
  Sig: string;
  Buf: TBitmap;
  Bmp: TBitmap;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  if ABackgroundColor = clNone then
    Bg := GetParentBackgroundColor
  else
    Bg := ABackgroundColor;

  Sig := Format('C|%d,%d|%d|%d|%d|%d',
    [W, H, Integer(AFillColor), Integer(ABorderColor),
     ABorderWidth, Integer(Bg)]);

  if GAA_TriangleCache = nil then
    GAA_TriangleCache := TCssAACache.Create;

  Bmp := GAA_TriangleCache.GetBitmap(Sig);

  if Bmp = nil then
  begin
    Buf := TBitmap.Create;
    try
      RenderCircleToBitmap(Buf, W, H, AFillColor, ABorderColor,
        ABorderWidth, Bg);
      GAA_TriangleCache.PutBitmap(Sig, Buf);
      Bmp := GAA_TriangleCache.GetBitmap(Sig);
    finally
      Buf.Free;
    end;
  end;

  if Bmp <> nil then
    ACanvas.Draw(ARect.Left, ARect.Top, Bmp);
end;

procedure TCssStyledControl.DrawAntiAliasedRoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadii: TCssCornerRadii;
  AFillColor: TColor;
  ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor);
var
  Params: TCssRoundedBoxParams;
  Bg: TColor;
begin
  if ACanvas = nil then Exit;
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then Exit;

  if ABackgroundColor = clNone then
    Bg := GetParentBackgroundColor
  else
    Bg := ABackgroundColor;

  Params.Radii := ARadii;
  Params.FillColor := AFillColor;
  Params.BorderColor := ABorderColor;
  Params.BorderWidth := ABorderWidth;
  Params.BorderStyle := ABorderStyle;

  Params.CornerBackColor[0] := Bg;
  Params.CornerBackColor[1] := Bg;
  Params.CornerBackColor[2] := Bg;
  Params.CornerBackColor[3] := Bg;

  Params.Shadow.Used := False;
  Params.Shadow.HasColor := False;
  Params.Shadow.OffsetX := 0;
  Params.Shadow.OffsetY := 0;
  Params.Shadow.Blur := 0;
  Params.Shadow.Spread := 0;
  Params.Shadow.Color := clBlack;

  Params.HasGradient := False;
  Params.Gradient.Kind := cgkNone;
  SetLength(Params.Gradient.Stops, 0);

  DrawRoundedRectAA(ACanvas, ARect, Params);
end;

procedure TCssStyledControl.DrawAntiAliasedRoundedBox(
  ACanvas: TCanvas;
  const ARect: TRect;
  ARadius: Integer;
  AFillColor: TColor;
  ABorderColor: TColor;
  ABorderWidth: Integer;
  ABorderStyle: TCssBorderStyle;
  ABackgroundColor: TColor);
var
  Radii: TCssCornerRadii;
begin
  Radii.TL := ARadius;
  Radii.TR := ARadius;
  Radii.BR := ARadius;
  Radii.BL := ARadius;

  DrawAntiAliasedRoundedBox(
    ACanvas, ARect, Radii,
    AFillColor, ABorderColor, ABorderWidth,
    ABorderStyle, ABackgroundColor
  );
end;

procedure TCssStyledControl.DrawAntiAliasedCheckMark(
  ACanvas: TCanvas;
  const ARect: TRect;
  AColor: TColor);
var
  W, H: Integer;
  Coverage: array of Byte;
  LineWidth: Double;
  X1, Y1, X2, Y2, X3, Y3: Double;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then Exit;

  if W < 12 then
    LineWidth := 1.5
  else if W < 20 then
    LineWidth := 2.0
  else
    LineWidth := 2.5;

  SetLength(Coverage, W * H);

  X1 := W * 0.20;  Y1 := H * 0.50;
  X2 := W * 0.40;  Y2 := H * 0.75;
  X3 := W * 0.80;  Y3 := H * 0.22;

  BuildCheckMarkCoverage(
    Coverage, W, H,
    X1, Y1, X2, Y2, X3, Y3,
    LineWidth
  );

  BlendCoverageToCanvas(
    ACanvas,
    ARect.Left, ARect.Top,
    W, H,
    Coverage,
    AColor
  );
end;

{ ============================================================ }
{ TCssStyledControl — lifecycle                                }
{ ============================================================ }

procedure TCssStyledControl.Loaded;
begin
  inherited Loaded;
  ReapplyStyles;
end;

procedure TCssStyledControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FStyleProvider) then
  begin
    FStyleProvider := nil;

    if not (csDestroying in ComponentState) then
      ReapplyStyles;
  end;
end;

{ ============================================================ }
{ TCssStyledControl — public API                               }
{ ============================================================ }

procedure TCssStyledControl.ApplyStyleSheet(const ACss: string);
begin
  FStyleSheet := ACss;
  ApplyCss(ACss);
end;

procedure TCssStyledControl.ProviderStyleChanged;
begin
  if (csDestroying in ComponentState) or (csLoading in ComponentState) then
    Exit;

  ReapplyStyles;
end;

procedure TCssStyledControl.AssignEffectiveCssFontToFont(AFont: TFont);
begin
  AssignCssFontToFont(AFont);
end;

function TCssStyledControl.MeasureStyledTextSize(
  ACanvas: TCanvas;
  const AText: string;
  AvailableWidth: Integer): TSize;
begin
  if FHtmlMode then
  begin
    Result := MeasureHtmlTextSize(ACanvas, AText, AvailableWidth);
  end
  else
  begin
    AssignCssFontToFont(ACanvas.Font);

    Result.cx := ACanvas.TextWidth(AText);
    Result.cy := ACanvas.TextHeight('Ag');
  end;
end;

function TCssStyledControl.HtmlToPlainText(const AText: string): string;
var
  Blocks: THtmlBlocks;
  I, J: Integer;
  BlockText: string;
begin
  Result := '';

  if Trim(AText) = '' then
    Exit;

  ParseHtmlBlocks(AText, Blocks);

  for I := 0 to High(Blocks) do
  begin
    if Blocks[I].Kind = hbHr then
      Continue;

    BlockText := '';

    for J := 0 to High(Blocks[I].Runs) do
      BlockText := BlockText + Blocks[I].Runs[J].Text;

    // For sorting and searching it is more convenient to treat line breaks as spaces.
    BlockText := StringReplace(BlockText, #10, ' ', [rfReplaceAll]);
    BlockText := StringReplace(BlockText, #13, ' ', [rfReplaceAll]);
    BlockText := StringReplace(BlockText, #9, ' ', [rfReplaceAll]);

    BlockText := Trim(BlockText);

    if BlockText = '' then
      Continue;

    if Result <> '' then
      Result := Result + ' ';

    Result := Result + BlockText;
  end;

  // Additionally, normalize repeated spaces.
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);

  Result := Trim(Result);
end;

{ ============================================================ }
{ TCssStyledControl — style (re)application                    }
{ ============================================================ }

procedure TCssStyledControl.ReapplyStyles;
var
  EffectiveCss: string;
  OldBg: TColor;
begin
  OldBg := GetCssBackgroundColor;

  EffectiveCss := GetEffectiveStyleSheet;

  if EffectiveCss <> '' then
  begin
    ApplyCss(EffectiveCss);
  end
  else
  begin
    ResetStyle;
    ApplyDeclarations(FInlineStyle);
    StyleChanged;
    Invalidate;
  end;

  if GetCssBackgroundColor <> OldBg then
    NotifyUpperSiblingsRepaint;
end;

function TCssStyledControl.GetEffectiveStyleSheet: string;
begin
  Result := '';

  if Assigned(FStyleProvider) then
    Result := FStyleProvider.GetCssForControl(FStyleName);

  if Result = '' then
    Result := FStyleSheet;
end;

procedure TCssStyledControl.ApplyCss(const ACss: string);
type
  TMatchedRule = record
    Declarations: string;
    SpecA, SpecB, SpecC, Order: Integer;
    Target: Integer; // 0 = control, 1 = hint
  end;
var
  Css, SelectorBlock, Declarations, Sel: string;
  OpenPos, ClosePos, I, RuleCount: Integer;
  Selectors: TStringList;
  Rules: array of TMatchedRule;
  SpecA, SpecB, SpecC: Integer;
  BaseSel: string;
  HintTarget: Boolean;
  LinkTarget: Boolean;
  LinkHover: Boolean;

  procedure AddRule(
    const ADeclarations: string;
    A, B, C, Order, Target: Integer);
  begin
    SetLength(Rules, Order + 1);
    Rules[Order].Declarations := ADeclarations;
    Rules[Order].SpecA := A;
    Rules[Order].SpecB := B;
    Rules[Order].SpecC := C;
    Rules[Order].Order := Order;
    Rules[Order].Target := Target;
  end;

  function RuleComesAfter(const L, R: TMatchedRule): Boolean;
  begin
    if L.SpecA <> R.SpecA then
    begin
      Result := L.SpecA > R.SpecA;
      Exit;
    end;

    if L.SpecB <> R.SpecB then
    begin
      Result := L.SpecB > R.SpecB;
      Exit;
    end;

    if L.SpecC <> R.SpecC then
    begin
      Result := L.SpecC > R.SpecC;
      Exit;
    end;

    Result := L.Order > R.Order;
  end;

  procedure SortRules;
  var
    I, J: Integer;
    Key: TMatchedRule;
  begin
    for I := 1 to RuleCount - 1 do
    begin
      Key := Rules[I];
      J := I - 1;

      while (J >= 0) and RuleComesAfter(Rules[J], Key) do
      begin
        Rules[J + 1] := Rules[J];
        Dec(J);
      end;

      Rules[J + 1] := Key;
    end;
  end;

begin
  ResetStyle;

  RuleCount := 0;
  Rules := nil;
  FHintCss := '';

  Css := RemoveCssComments(ACss);

  while True do
  begin
    OpenPos := Pos('{', Css);
    if OpenPos = 0 then
      Break;

    ClosePos := PosEx('}', Css, OpenPos + 1);
    if ClosePos = 0 then
      Break;

    SelectorBlock := Trim(Copy(Css, 1, OpenPos - 1));
    Declarations := Trim(Copy(Css, OpenPos + 1, ClosePos - OpenPos - 1));

    if (SelectorBlock <> '') and (Declarations <> '') then
    begin
      Selectors := TStringList.Create;

      try
        SplitByChar(SelectorBlock, ',', Selectors);

        for I := 0 to Selectors.Count - 1 do
        begin
          Sel := Trim(Selectors[I]);

          LinkTarget := IsLinkSelector(Sel, LinkHover);
          if LinkTarget then
          begin
            AddRule(
              Declarations,
              0,
              1,
              1,
              RuleCount,
              2 + Ord(LinkHover)
            );

            Inc(RuleCount);
            Continue;
          end;

          HintTarget := IsHintSelector(Sel, BaseSel);

          if TryEvaluateSelector(BaseSel, SpecA, SpecB, SpecC) then
          begin
            AddRule(
              Declarations,
              SpecA,
              SpecB,
              SpecC,
              RuleCount,
              Ord(HintTarget)
            );

            Inc(RuleCount);
          end;
        end;
      finally
        Selectors.Free;
      end;
    end;

    Delete(Css, 1, ClosePos);
  end;

  SortRules;

  for I := 0 to RuleCount - 1 do
  begin
    if Rules[I].Target = 0 then
    begin
      ApplyDeclarations(Rules[I].Declarations);
    end
    else if Rules[I].Target = 1 then
    begin
      if FHintCss <> '' then
        FHintCss := FHintCss + '; ';

      FHintCss := FHintCss + Rules[I].Declarations;
    end
    else if Rules[I].Target = 2 then
    begin
      ApplyLinkDeclarations(FLinkNormal, Rules[I].Declarations);
    end
    else if Rules[I].Target = 3 then
    begin
      ApplyLinkDeclarations(FLinkHover, Rules[I].Declarations);
    end;
  end;

  ApplyDeclarations(FInlineStyle);

  StyleChanged;
  UpdateCursor;
  Invalidate;
end;

procedure TCssStyledControl.ResetStyle;
var
  SavedAlign: TCssTextAlign;
  SavedVAlign: TCssVAlign;
  SavedWordWrap: Boolean;
  HadInit: Boolean;
begin
  HadInit := FTextPropsInitialized;

  if HadInit then
  begin
    SavedAlign := FTextAlign;
    SavedVAlign := FVAlign;
    SavedWordWrap := FWordWrap;
  end;

  Cursor := crDefault;
  FCssCursor := crDefault;

  FHasBackground := False;
  FBackground := clNone;

  FHasTextColor := False;
  FTextColor := clWindowText;

  FBorderWidth := 0;
  FBorderColor := clBlack;
  FBorderStyle := cbsNone;
  FBorderRadiusTL := 0;
  FBorderRadiusTR := 0;
  FBorderRadiusBR := 0;
  FBorderRadiusBL := 0;

  FPadding := Rect(0, 0, 0, 0);

  FFontFamily := '';
  FFontPixelHeight := 0;
  FFontPointSize := 0;
  FFontBold := False;
  FFontItalic := False;

  FHasFontFamily := False;
  FHasFontPixelHeight := False;
  FHasFontPointSize := False;
  FHasFontBold := False;
  FHasFontItalic := False;

  FHintCss := '';

  FOpacity := 1.0;

  FTextShadow := False;
  FTextShadowColor := RGBToColor(0, 0, 0);
  FTextShadowX := 1;
  FTextShadowY := 1;

  FLinkNormal.Color := RGBToColor(0, 0, 238);
  FLinkNormal.HasColor := True;
  FLinkNormal.Underline := True;
  FLinkNormal.HasUnderline := True;
  FLinkNormal.Cursor := crDefault;
  FLinkNormal.HasCursor := False;

  FLinkHover.Color := RGBToColor(255, 0, 0);
  FLinkHover.HasColor := True;
  FLinkHover.Underline := True;
  FLinkHover.HasUnderline := True;
  FLinkHover.Cursor := crHandPoint;
  FLinkHover.HasCursor := True;

  FFocusColor := clDefault;
  FFocusColorSet := False;

  FBackgroundGradient.Kind := cgkNone;
  SetLength(FBackgroundGradient.Stops, 0);

  FBoxShadow.OffsetX := 0;
  FBoxShadow.OffsetY := 0;
  FBoxShadow.Blur := 0;
  FBoxShadow.Spread := 0;
  FBoxShadow.Color := clBlack;
  FBoxShadow.HasColor := False;
  FBoxShadow.Used := False;

  FHoverLinkId := 0;
  FLinkAreas := nil;
  FLinkInfos := nil;

  if HadInit then
  begin
    FTextAlign := SavedAlign;
    FVAlign    := SavedVAlign;
    FWordWrap  := SavedWordWrap;
  end
  else
  begin
    InitTextProps;
    FTextPropsInitialized := True;
  end;
end;

procedure TCssStyledControl.StyleChanged;
begin
  // Virtual method for descendants.
  // For example, TCssEdit will update the inner TEdit.
end;

procedure TCssStyledControl.RefreshStylesByState;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  ReapplyStyles;
end;

function TCssStyledControl.MatchPseudo(const APseudo: string): Boolean;
var
  P: string;
begin
  P := LowerCase(APseudo);
  Result := False;

  if P = 'hover' then
    Result := Enabled and GetEffectiveHoverState
  else if P = 'active' then
    Result := Enabled and FMousePressed
  else if P = 'focus' then
    Result := FFocused
  else if P = 'focus-visible' then
    Result := FFocused
  else if P = 'enabled' then
    Result := Enabled
  else if P = 'disabled' then
    Result := not Enabled
  else if P = 'checked' then
    Result := FChecked
  else if P = 'unchecked' then
    Result := not FChecked;
end;

function TCssStyledControl.TryEvaluateSelector(
  const ASelector: string;
  out SpecA, SpecB, SpecC: Integer): Boolean;
var
  TypeName, ID: string;
  ClassList, PseudoList: TStringList;
  HasAttribute, HasFunctional, HasPseudoElement: Boolean;
  I: Integer;
  TypeOK: Boolean;
  DummyHover: Boolean;
begin
  Result := False;

  SpecA := 0;
  SpecB := 0;
  SpecC := 0;

  if Trim(ASelector) = '' then
    Exit;

  if IsLinkSelector(ASelector, DummyHover) then
    Exit;

  ClassList := TStringList.Create;
  PseudoList := TStringList.Create;

  try
    ParseSimpleSelector(
      ASelector,
      TypeName,
      ID,
      ClassList,
      PseudoList,
      HasAttribute,
      HasFunctional,
      HasPseudoElement
    );

    if HasAttribute or HasFunctional or HasPseudoElement then
      Exit;

    TypeOK := True;

    if TypeName <> '' then
    begin
      if TypeName = '*' then
        TypeOK := True
      else
      begin
        TypeOK :=
          SameText(TypeName, FCssTag) or
          SameText(TypeName, ClassName) or
          SameText(TypeName, 'control') or
          SameText(TypeName, 'TCssStyledControl');
      end;
    end;

    if not TypeOK then
      Exit;

    if (ID <> '') and (not SameText(ID, FCssID)) then
      Exit;

    for I := 0 to ClassList.Count - 1 do
    begin
      if not CssClassContains(ClassList[I]) then
        Exit;
    end;

    for I := 0 to PseudoList.Count - 1 do
    begin
      if not MatchPseudo(PseudoList[I]) then
        Exit;
    end;

    Result := True;

    if (TypeName <> '') and (TypeName <> '*') then
      SpecC := 1;

    if ID <> '' then
      SpecA := 1;

    SpecB := ClassList.Count + PseudoList.Count;
  finally
    PseudoList.Free;
    ClassList.Free;
  end;
end;

{ ============================================================ }
{ TCssStyledControl — property setters                         }
{ ============================================================ }

procedure TCssStyledControl.SetCaption(const AValue: TCaption);
begin
  if FCaption = AValue then
    Exit;

  FCaption := AValue;
  Invalidate;
end;

procedure TCssStyledControl.SetCssClass(const AValue: string);
begin
  if FCssClass = AValue then
    Exit;

  FCssClass := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetCssID(const AValue: string);
begin
  if FCssID = AValue then
    Exit;

  FCssID := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetCssTag(const AValue: string);
begin
  if FCssTag = AValue then
    Exit;

  FCssTag := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetInlineStyle(const AValue: string);
begin
  if FInlineStyle = AValue then
    Exit;

  FInlineStyle := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetMonospaceFontName(const AValue: string);
var
  V: string;
begin
  V := AValue;
  if Trim(V) = '' then
    V := 'Courier New';

  if FMonospaceFontName = V then
    Exit;

  FMonospaceFontName := V;
  Invalidate;
end;

procedure TCssStyledControl.SetStyleProvider(AValue: TCssStyleProvider);
begin
  if FStyleProvider = AValue then
    Exit;

  if Assigned(FStyleProvider) and
     not (csDestroying in FStyleProvider.ComponentState) then
  begin
    FStyleProvider.UnRegisterControl(Self);
    FStyleProvider.RemoveFreeNotification(Self);
    RemoveFreeNotification(FStyleProvider);
  end;

  FStyleProvider := AValue;

  if Assigned(FStyleProvider) then
  begin
    FStyleProvider.RegisterControl(Self);

    // The control is notified if the provider is destroyed.
    FStyleProvider.FreeNotification(Self);

    // The provider is notified if the control is destroyed.
    Self.FreeNotification(FStyleProvider);
  end;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetStyleName(const AValue: string);
begin
  if FStyleName = AValue then
    Exit;

  FStyleName := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetHtmlMode(AValue: Boolean);
begin
  if FHtmlMode = AValue then
    Exit;

  FHtmlMode := AValue;
  HtmlModeChanged;
  Invalidate;
end;

procedure TCssStyledControl.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;

  FChecked := AValue;

  if not (csLoading in ComponentState) then
    ReapplyStyles;
end;

procedure TCssStyledControl.SetTextAlign(AValue: TCssTextAlign);
begin
  if FTextAlign = AValue then
    Exit;

  FTextAlign := AValue;
  Invalidate;
end;

procedure TCssStyledControl.SetVAlign(AValue: TCssVAlign);
begin
  if FVAlign = AValue then
    Exit;

  FVAlign := AValue;
  Invalidate;
end;

procedure TCssStyledControl.SetWordWrap(AValue: Boolean);
begin
  if FWordWrap = AValue then
    Exit;

  FWordWrap := AValue;
  Invalidate;
end;

procedure TCssStyledControl.SetHintHtmlMode(AValue: Boolean);
begin
  if FHintHtmlMode = AValue then
    Exit;

  FHintHtmlMode := AValue;
end;

procedure TCssStyledControl.SetShowFocusRect(AValue: Boolean);
begin
  if FShowFocusRect = AValue then Exit;
  FShowFocusRect := AValue;
  Invalidate;
end;

procedure TCssStyledControl.SetVisible(AValue: Boolean);
begin
  if Visible = AValue then
  begin
    inherited SetVisible(AValue);
    Exit;
  end;

  inherited SetVisible(AValue);

  NotifyUpperSiblingsRepaint;
end;

procedure TCssStyledControl.SetFocusColor(AValue: TColor);
begin
  if (FFocusColor = AValue) and FFocusColorSet then Exit;
  FFocusColor := AValue;
  FFocusColorSet := AValue <> clDefault;
  Invalidate;
end;

{ ============================================================ }
{ TCssStyledControl — property getters (CSS accessors)         }
{ ============================================================ }

function TCssStyledControl.GetCssBackgroundColor: TColor;
begin
  if FHasBackground then
    Result := FBackground
  else
    Result := Color;

  if Result = clDefault then
    Result := clBtnFace;

  Result := ApplyOpacity(Result);
end;

function TCssStyledControl.GetCssTextColor: TColor;
begin
  if FHasTextColor then
    Result := FTextColor
  else
    Result := Font.Color;

  if Result = clDefault then
    Result := clWindowText;
end;

function TCssStyledControl.GetCssBorderWidth: Integer;
begin
  if FBorderStyle = cbsNone then
    Result := 0
  else
    Result := FBorderWidth;
end;

function TCssStyledControl.GetCssPadding: TRect;
begin
  Result := FPadding;
end;

function TCssStyledControl.GetCssTextAlign: TCssTextAlign;
begin
  Result := FTextAlign;
end;

function TCssStyledControl.GetCssVAlign: TCssVAlign;
begin
  Result := FVAlign;
end;

function TCssStyledControl.GetCssWordWrap: Boolean;
begin
  Result := FWordWrap;
end;

function TCssStyledControl.GetCssBorderColor: TColor;
begin
  Result := FBorderColor;
end;

function TCssStyledControl.GetCssBorderRadius: Integer;
begin
  Result := FBorderRadiusTL;
end;

function TCssStyledControl.GetEffectiveTextColor: TColor;
begin
  Result := GetCssTextColor;

  if Result = clNone then
    Result := clWindowText;

  if Result = clDefault then
    Result := clWindowText;

  Result := ApplyOpacity(Result);
end;

function TCssStyledControl.GetEffectiveBorderColor: TColor;
begin
  Result := GetCssBorderColor;
  Result := ApplyOpacity(Result);
end;

function TCssStyledControl.GetOpacityBaseColor: TColor;
begin
  Result := Color;

  if Result = clNone then
    Result := clBtnFace;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssStyledControl.ApplyOpacity(AColor: TColor): TColor;
var
  Alpha: Integer;
  Fore, Base: TColor;
  R, G, B: Integer;
begin
  if FOpacity >= 0.999 then
    Exit(AColor);

  if AColor = clNone then
    Exit(AColor);

  if FOpacity <= 0.001 then
    Exit(GetOpacityBaseColor);

  Alpha := Round(FOpacity * 255);

  Fore := ColorToRGB(AColor);
  Base := ColorToRGB(GetOpacityBaseColor);

  R := ((Fore and $FF) * Alpha + (Base and $FF) * (255 - Alpha)) div 255;
  G := (((Fore shr 8) and $FF) * Alpha + ((Base shr 8) and $FF) * (255 - Alpha)) div 255;
  B := (((Fore shr 16) and $FF) * Alpha + ((Base shr 16) and $FF) * (255 - Alpha)) div 255;

  Result := RGBToColor(R, G, B);
end;

procedure TCssStyledControl.NotifyUpperSiblingsRepaint(
  AOldBounds: PRect);
var
  P: TWinControl;
  I, MyIndex: Integer;
  Sibling: TControl;
  OldR, NewR, SiblingR, R: TRect;
  CheckOld: Boolean;
begin
  if (csDestroying in ComponentState) or (csLoading in ComponentState) then
    Exit;

  P := Parent;
  if P = nil then
    Exit;

  MyIndex := -1;
  for I := 0 to P.ControlCount - 1 do
    if P.Controls[I] = Self then
    begin
      MyIndex := I;
      Break;
    end;

  if MyIndex < 0 then
    Exit;

  NewR := BoundsRect;
  CheckOld := AOldBounds <> nil;
  if CheckOld then
    OldR := AOldBounds^;

  for I := MyIndex + 1 to P.ControlCount - 1 do
  begin
    Sibling := P.Controls[I];

    if not (Sibling is TCssStyledControl) then
      Continue;

    if not Sibling.Visible then
      Continue;

    SiblingR := Sibling.BoundsRect;

    if IntersectRect(R, NewR, SiblingR) or
       (CheckOld and IntersectRect(R, OldR, SiblingR)) then
    begin
      Sibling.Invalidate;
    end;
  end;
end;

function TCssStyledControl.IsCaptionStored : Boolean;
begin
  Result := FCaption <> '';
end;

function TCssStyledControl.GetShowPrefix: Boolean;
begin
  Result := False;
end;

function TCssStyledControl.GetMouseInControlState: Boolean;
begin
  Result := FMouseInControl;
end;

function TCssStyledControl.GetMousePressedState: Boolean;
begin
  Result := FMousePressed;
end;

function TCssStyledControl.GetFocusedState: Boolean;
begin
  Result := FFocused;
end;

function TCssStyledControl.GetFocusColor: TColor;
begin
  // 1) Явно заданный цвет (в т.ч. из CSS focus-color).
  if FFocusColorSet then
    Exit(FFocusColor);

  // 2) Дефолтная цепочка: border → text.
  Result := GetCssBorderColor;

  if (Result = clNone) or (Result = clDefault) then
    Result := GetCssTextColor;

  if Result = clDefault then
    Result := clWindowText;
end;

function TCssStyledControl.GetEffectiveHoverState : Boolean;
begin
  Result := FMouseInControl
         or (FHoveredChildrenCount > 0)
         or (FExternalHoverCount > 0);
end;

function TCssStyledControl.GetStyledBackgroundColor: TColor;
begin
  Result := GetCssBackgroundColor;
end;

function TCssStyledControl.GetStyledBorderWidth: Integer;
begin
  Result := GetCssBorderWidth;
end;

function TCssStyledControl.GetStyledPadding: TRect;
begin
  Result := GetCssPadding;
end;

function TCssStyledControl.GetStyledBorderRadius: Integer;
begin
  Result := GetCssBorderRadius;
end;

function TCssStyledControl.GetStyledTextColor: TColor;
begin
  Result := GetCssTextColor;

  if Result = clNone then
    Result := clWindowText;
end;

{ ============================================================ }
{ TCssStyledControl — state setters                            }
{ ============================================================ }

procedure TCssStyledControl.SetMouseInControlState(AValue: Boolean);
begin
  if FMouseInControl = AValue then
    Exit;

  FMouseInControl := AValue;
  RefreshStylesByState;
end;

procedure TCssStyledControl.SetMousePressedState(AValue: Boolean);
begin
  if FMousePressed = AValue then
    Exit;

  FMousePressed := AValue;
  RefreshStylesByState;
end;

procedure TCssStyledControl.SetFocusedState(AValue: Boolean);
begin
  if FFocused = AValue then
    Exit;

  FFocused := AValue;
  RefreshStylesByState;
end;

procedure TCssStyledControl.SetCssCheckedState(AValue: Boolean);
begin
  if FChecked = AValue then
    Exit;

  FChecked := AValue;

  RefreshStylesByState;
end;

{ ============================================================ }
{ TCssStyledControl — CSS parsing helpers                      }
{ ============================================================ }

procedure TCssStyledControl.ApplyDeclarations(const ADeclarations: string);
var
  I, Start: Integer;
  Item: string;

  procedure ApplyOne(const AItem: string);
  var
    CPos, IPos: Integer;
    N, V, LV: string;
  begin
    if AItem = '' then
      Exit;

    CPos := Pos(':', AItem);
    if CPos = 0 then
      Exit;

    N := LowerCase(Trim(Copy(AItem, 1, CPos - 1)));
    V := Trim(Copy(AItem, CPos + 1, MaxInt));
    LV := LowerCase(V);

    IPos := Pos('!important', LV);
    if IPos > 0 then
      V := Trim(Copy(V, 1, IPos - 1));

    ApplyDeclaration(N, V);
  end;

begin
  Start := 1;

  for I := 1 to Length(ADeclarations) do
  begin
    if ADeclarations[I] = ';' then
    begin
      Item := Trim(Copy(ADeclarations, Start, I - Start));
      ApplyOne(Item);
      Start := I + 1;
    end;
  end;

  Item := Trim(Copy(ADeclarations, Start, MaxInt));
  ApplyOne(Item);
end;

procedure TCssStyledControl.ApplyDeclaration(const AName, AValue: string);
var
  LColor: TColor;
  Px, P: Integer;
  S: string;
  Weight: Integer;
  O: Double;
begin
  if AValue = '' then
    Exit;

  if AName = 'background' then
  begin
    ParseBackground(AValue);
  end
  else if AName = 'background-color' then
  begin
    if ParseColor(AValue, LColor) then
    begin
      FBackground := LColor;
      FHasBackground := True;
    end;
  end
  else if AName = 'color' then
  begin
    if ParseColor(AValue, LColor) then
    begin
      FTextColor := LColor;
      FHasTextColor := True;
    end;
  end
  else if AName = 'border' then
  begin
    ParseBorder(AValue);
  end
  else if AName = 'border-width' then
  begin
    if ParseLengthPx(FirstToken(AValue), Px) then
      FBorderWidth := Px;
  end
  else if AName = 'border-color' then
  begin
    if ParseColor(AValue, LColor) then
      FBorderColor := LColor
    else if ParseColor(FirstToken(AValue), LColor) then
      FBorderColor := LColor;
  end
  else if AName = 'border-style' then
  begin
    S := LowerCase(FirstToken(AValue));

    if (S = 'none') or (S = 'hidden') then
      FBorderStyle := cbsNone
    else if S = 'dotted' then
      FBorderStyle := cbsDotted
    else if S = 'dashed' then
      FBorderStyle := cbsDashed
    else
      FBorderStyle := cbsSolid;

    if (FBorderStyle <> cbsNone) and (FBorderWidth = 0) then
      FBorderWidth := 1;
  end
  else if AName = 'border-radius' then
  begin
    ParseBorderRadius(AValue);
  end
  else if AName = 'padding' then
  begin
    ParsePadding(AValue);
  end
  else if AName = 'padding-top' then
  begin
    if ParseLengthPx(FirstToken(AValue), Px) then
      FPadding.Top := Px;
  end
  else if AName = 'padding-right' then
  begin
    if ParseLengthPx(FirstToken(AValue), Px) then
      FPadding.Right := Px;
  end
  else if AName = 'padding-bottom' then
  begin
    if ParseLengthPx(FirstToken(AValue), Px) then
      FPadding.Bottom := Px;
  end
  else if AName = 'padding-left' then
  begin
    if ParseLengthPx(FirstToken(AValue), Px) then
      FPadding.Left := Px;
  end
  else if AName = 'font' then
  begin
    ParseFont(AValue);
  end
  else if AName = 'font-family' then
  begin
    ParseFontFamily(AValue);
  end
  else if AName = 'font-size' then
  begin
    ParseFontSize(AValue);
  end
  else if AName = 'font-weight' then
  begin
    S := LowerCase(AValue);

    if (S = 'bold') or (S = 'bolder') then
    begin
      FFontBold := True;
      FHasFontBold := True;
    end
    else if (S = 'normal') or (S = 'lighter') then
    begin
      FFontBold := False;
      FHasFontBold := True;
    end
    else if TryParseNumberPrefix(S, Weight) then
    begin
      FFontBold := Weight >= 600;
      FHasFontBold := True;
    end;
  end
  else if AName = 'font-style' then
  begin
    S := LowerCase(AValue);
    FFontItalic := (S = 'italic') or (S = 'oblique');
    FHasFontItalic := True;
  end
  else if AName = 'text-align' then
  begin
    S := LowerCase(AValue);

    if S = 'center' then
      FTextAlign := ctaCenter
    else if S = 'right' then
      FTextAlign := ctaRight
    else
      FTextAlign := ctaLeft;
  end
  else if AName = 'vertical-align' then
  begin
    S := LowerCase(AValue);

    if (S = 'middle') or (S = 'center') then
      FVAlign := cvaMiddle
    else if S = 'bottom' then
      FVAlign := cvaBottom
    else
      FVAlign := cvaTop;
  end
  else if AName = 'cursor' then
  begin
    FCssCursor := ParseCssCursor(AValue);
    UpdateCursor;
  end
  else if AName = 'opacity' then
  begin
    if TryParseCssFloat(AValue, O) then
    begin
      if O < 0 then
        O := 0;
      if O > 1 then
        O := 1;

      FOpacity := O;
    end;
  end
  else if AName = 'text-shadow' then
  begin
    ParseTextShadow(AValue);
  end
  else if AName = 'focus-color' then
  begin
    if ParseColor(AValue, LColor) then
    begin
      FFocusColor := LColor;
      FFocusColorSet := True;
    end;
  end
  else if AName = 'box-shadow' then
    ParseBoxShadow(AValue)
  else if AName = 'background-image' then
    ParseBackgroundGradient(AValue)
  else if AName = 'background' then
  begin
    // Если задан градиент — парсим как градиент, иначе как цвет.
    if (Pos('linear-gradient(', LowerCase(AValue)) = 1) or
       (Pos('radial-gradient(', LowerCase(AValue)) = 1) then
      ParseBackgroundGradient(AValue)
    else
      ParseBackground(AValue);
  end;
end;

procedure TCssStyledControl.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaTop);
  SetWordWrap(True);
end;

procedure TCssStyledControl.DrawFocusRect(ACanvas: TCanvas; const ARect: TRect);
var
  GeomR, LoopR: TRect;
  Radius: Integer;
  HW, HH, RR: Double;
  CX, CY: Double;
  SDOuter, SDInner, OuterCov, InnerCov, RingCov: Double;
  FocusRGB: TColor;
  FocusR, FocusG, FocusB: Byte;
  X, Y: Integer;
  CurPix: TColor;
  CurRGB: LongInt;
  CurR, CurG, CurB: Byte;
  BlendR, BlendG, BlendB: Integer;
begin
  if ACanvas = nil then Exit;

  GeomR := ARect;
  InflateRect(GeomR, -1, -1);
  if (GeomR.Right <= GeomR.Left) or (GeomR.Bottom <= GeomR.Top) then Exit;

  Radius := GetCssBorderRadius;
  if Radius > (GeomR.Bottom - GeomR.Top) div 2 then
    Radius := (GeomR.Bottom - GeomR.Top) div 2;
  if Radius > (GeomR.Right - GeomR.Left) div 2 then
    Radius := (GeomR.Right - GeomR.Left) div 2;

  if Radius <= 0 then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Color := GetFocusColor;
    ACanvas.Rectangle(GeomR.Left, GeomR.Top, GeomR.Right, GeomR.Bottom);
    Exit;
  end;

  FocusRGB := ColorToRGB(GetFocusColor);
  FocusR := Byte(FocusRGB and $FF);
  FocusG := Byte((FocusRGB shr 8) and $FF);
  FocusB := Byte((FocusRGB shr 16) and $FF);

  HW := (GeomR.Right - GeomR.Left) / 2.0;
  HH := (GeomR.Bottom - GeomR.Top) / 2.0;
  CX := GeomR.Left + HW;
  CY := GeomR.Top + HH;
  RR := Radius;

  // Clip iteration to the canvas bounds — pixels outside are simply not touched.
  LoopR := GeomR;
  if LoopR.Left < 0 then LoopR.Left := 0;
  if LoopR.Top < 0 then LoopR.Top := 0;
  if LoopR.Right > ACanvas.Width then LoopR.Right := ACanvas.Width;
  if LoopR.Bottom > ACanvas.Height then LoopR.Bottom := ACanvas.Height;

  for Y := LoopR.Top to LoopR.Bottom - 1 do
  begin
    for X := LoopR.Left to LoopR.Right - 1 do
    begin
      SDOuter := SdRoundBox(X + 0.5 - CX, Y + 0.5 - CY, HW, HH, RR);
      if SDOuter > 1.0 then
        Continue;

      SDInner := SdRoundBox(X + 0.5 - CX, Y + 0.5 - CY, HW - 1, HH - 1, RR - 1);

      OuterCov := ClampD(0.5 - SDOuter, 0, 1);
      InnerCov := ClampD(0.5 - SDInner, 0, 1);
      RingCov  := OuterCov - InnerCov;

      if RingCov <= 0 then
        Continue;

      if RingCov > 1 then
        RingCov := 1;

      CurPix := ACanvas.Pixels[X, Y];
      CurRGB := ColorToRGB(CurPix);
      CurR := Byte(CurRGB and $FF);
      CurG := Byte((CurRGB shr 8) and $FF);
      CurB := Byte((CurRGB shr 16) and $FF);

      BlendR := Round(FocusR * RingCov + CurR * (1 - RingCov));
      BlendG := Round(FocusG * RingCov + CurG * (1 - RingCov));
      BlendB := Round(FocusB * RingCov + CurB * (1 - RingCov));

      if BlendR < 0 then BlendR := 0 else if BlendR > 255 then BlendR := 255;
      if BlendG < 0 then BlendG := 0 else if BlendG > 255 then BlendG := 255;
      if BlendB < 0 then BlendB := 0 else if BlendB > 255 then BlendB := 255;

      ACanvas.Pixels[X, Y] := RGBToColor(BlendR, BlendG, BlendB);
    end;
  end;
end;

function TCssStyledControl.GetContentRect: TRect;
var
  B: Integer;
  P: TRect;
begin
  Result := ClientRect;
  B := GetCssBorderWidth;
  P := GetCssPadding;

  Result.Left   := Result.Left   + B + P.Left;
  Result.Top    := Result.Top    + B + P.Top;
  Result.Right  := Result.Right  - B - P.Right;
  Result.Bottom := Result.Bottom - B - P.Bottom;

  if Result.Right  < Result.Left then Result.Right  := Result.Left;
  if Result.Bottom < Result.Top  then Result.Bottom := Result.Top;
end;

function TCssStyledControl.GetContentRectNoScroll: TRect;
begin
  Result := GetContentRect;
end;

function TCssStyledControl.GetBorderTopOffset: Integer;
begin
  Result := 0;
end;

function TCssStyledControl.GetAlignment: TAlignment;
begin
  case GetCssTextAlign of
    ctaCenter: Result := taCenter;
    ctaRight:  Result := taRightJustify;
  else
    Result := taLeftJustify;
  end;
end;

procedure TCssStyledControl.SetAlignment(AValue: TAlignment);
begin
  case AValue of
    taCenter:        SetTextAlign(ctaCenter);
    taRightJustify:  SetTextAlign(ctaRight);
  else
    SetTextAlign(ctaLeft);
  end;
end;

function TCssStyledControl.GetLayout: TTextLayout;
begin
  case GetCssVAlign of
    cvaMiddle: Result := tlCenter;
    cvaBottom: Result := tlBottom;
  else
    Result := tlTop;
  end;
end;

procedure TCssStyledControl.SetLayout(AValue: TTextLayout);
begin
  case AValue of
    tlCenter: SetVAlign(cvaMiddle);
    tlBottom: SetVAlign(cvaBottom);
  else
    SetVAlign(cvaTop);
  end;
end;

function TCssStyledControl.GetWordWrapProp: Boolean;
begin
  Result := GetCssWordWrap;
end;

procedure TCssStyledControl.SetWordWrapProp(AValue: Boolean);
begin
  SetWordWrap(AValue);
end;

procedure TCssStyledControl.ParseBorder(const AValue: string);
var
  Tokens: TStringList;
  I, Px: Integer;
  LColor: TColor;
  Token: string;
  WidthSet: Boolean;
begin
  Tokens := TStringList.Create;
  WidthSet := False;

  try
    SplitBySpaces(LowerCase(Trim(AValue)), Tokens);

    for I := 0 to Tokens.Count - 1 do
    begin
      Token := Tokens[I];

      if Token = 'none' then
        FBorderStyle := cbsNone
      else if Token = 'hidden' then
        FBorderStyle := cbsNone
      else if Token = 'dotted' then
        FBorderStyle := cbsDotted
      else if Token = 'dashed' then
        FBorderStyle := cbsDashed
      else if (Token = 'solid') or (Token = 'double') or
              (Token = 'groove') or (Token = 'ridge') or
              (Token = 'inset') or (Token = 'outset') then
        FBorderStyle := cbsSolid
      else if ParseColor(Token, LColor) then
        FBorderColor := LColor
      else if ParseLengthPx(Token, Px) then
      begin
        FBorderWidth := Px;
        WidthSet := True;
      end;
    end;
  finally
    Tokens.Free;
  end;

  if (FBorderStyle <> cbsNone) and (not WidthSet) and (FBorderWidth = 0) then
    FBorderWidth := 1;
end;

procedure TCssStyledControl.ParsePadding(const AValue: string);
var
  Tokens: TStringList;
  I, N, Px: Integer;
  V: array[0..3] of Integer;
begin
  Tokens := TStringList.Create;

  try
    SplitBySpaces(AValue, Tokens);

    N := 0;

    for I := 0 to Tokens.Count - 1 do
    begin
      if ParseLengthPx(Tokens[I], Px) and (N < 4) then
      begin
        V[N] := Px;
        Inc(N);
      end;
    end;

    case N of
      1:
      begin
        FPadding := Rect(V[0], V[0], V[0], V[0]);
      end;

      2:
      begin
        FPadding.Top := V[0];
        FPadding.Bottom := V[0];
        FPadding.Left := V[1];
        FPadding.Right := V[1];
      end;

      3:
      begin
        FPadding.Top := V[0];
        FPadding.Left := V[1];
        FPadding.Right := V[1];
        FPadding.Bottom := V[2];
      end;

      4:
      begin
        FPadding.Top := V[0];
        FPadding.Right := V[1];
        FPadding.Bottom := V[2];
        FPadding.Left := V[3];
      end;
    end;
  finally
    Tokens.Free;
  end;
end;

procedure TCssStyledControl.ParseFont(const AValue: string);
var
  Tokens: TStringList;
  I, SizeIndex: Integer;
  Family, Token: string;
begin
  Tokens := TStringList.Create;

  try
    SplitBySpaces(Trim(AValue), Tokens);

    SizeIndex := -1;

    for I := 0 to Tokens.Count - 1 do
    begin
      if IsFontSizeToken(Tokens[I]) then
      begin
        SizeIndex := I;
        Break;
      end;
    end;

    if SizeIndex >= 0 then
    begin
      for I := 0 to SizeIndex - 1 do
      begin
        Token := LowerCase(Tokens[I]);

        if (Token = 'italic') or (Token = 'oblique') then
        begin
          FFontItalic := True;
          FHasFontItalic := True;
        end
        else if (Token = 'bold') or (Token = 'bolder') then
        begin
          FFontBold := True;
          FHasFontBold := True;
        end
        else if Token = 'normal' then
        begin
          FFontItalic := False;
          FHasFontItalic := True;
          FFontBold := False;
          FHasFontBold := True;
        end
        else if Token = 'lighter' then
        begin
          FFontBold := False;
          FHasFontBold := True;
        end;
      end;

      ParseFontSize(Tokens[SizeIndex]);

      Family := '';
      for I := SizeIndex + 1 to Tokens.Count - 1 do
        Family := Family + Tokens[I] + ' ';

      Family := Trim(Family);

      if Family <> '' then
        ParseFontFamily(Family);
    end
    else if Pos(',', AValue) > 0 then
    begin
      ParseFontFamily(AValue);
    end;
  finally
    Tokens.Free;
  end;
end;

procedure TCssStyledControl.ParseFontSize(const AValue: string);
var
  S: string;
  P, Num: Integer;
begin
  S := LowerCase(Trim(AValue));

  P := Pos('/', S);
  if P > 0 then
    S := Trim(Copy(S, 1, P - 1));

  if S = '' then
    Exit;

  if S = 'xx-small' then
    Num := 8
  else if S = 'x-small' then
    Num := 10
  else if S = 'small' then
    Num := 12
  else if S = 'medium' then
    Num := 14
  else if S = 'large' then
    Num := 16
  else if S = 'x-large' then
    Num := 20
  else if S = 'xx-large' then
    Num := 24
  else
  begin
    if TryParseNumberPrefix(S, Num) then
    begin
      if EndsText('pt', S) then
      begin
        FFontPointSize := Num;
        FHasFontPointSize := True;
        FHasFontPixelHeight := False;
        Exit;
      end
      else
      begin
        FFontPixelHeight := Num;
        FHasFontPixelHeight := True;
        FHasFontPointSize := False;
        Exit;
      end;
    end;

    Exit;
  end;

  FFontPixelHeight := Num;
  FHasFontPixelHeight := True;
  FHasFontPointSize := False;
end;

procedure TCssStyledControl.ParseFontFamily(const AValue: string);
var
  S: string;
begin
  S := ResolveFontFamily(AValue);
  if S <> '' then
  begin
    FFontFamily := S;
    FHasFontFamily := True;
  end;
end;

procedure TCssStyledControl.ParseBackground(const AValue: string);
var
  Tokens: TStringList;
  I: Integer;
  LColor: TColor;
begin
  if ParseColor(AValue, LColor) then
  begin
    FBackground := LColor;
    FHasBackground := True;
    Exit;
  end;

  Tokens := TStringList.Create;

  try
    SplitBySpaces(AValue, Tokens);

    for I := 0 to Tokens.Count - 1 do
    begin
      if ParseColor(Tokens[I], LColor) then
      begin
        FBackground := LColor;
        FHasBackground := True;
        Break;
      end;
    end;
  finally
    Tokens.Free;
  end;
end;

procedure TCssStyledControl.ParseBorderRadius(const AValue: string);
var
  Tokens: TStringList;
  Parts: array[0..3] of Integer;
  N, I, Px, P: Integer;
  S: string;
begin
  S := AValue;
  P := Pos('/', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);

  Tokens := TStringList.Create;
  try
    SplitBySpaces(S, Tokens);

    N := 0;
    for I := 0 to Tokens.Count - 1 do
    begin
      if ParseLengthPx(Tokens[I], Px) and (N < 4) then
      begin
        Parts[N] := Px;
        Inc(N);
      end;
    end;

    case N of
      1:
        begin
          FBorderRadiusTL := Parts[0];
          FBorderRadiusTR := Parts[0];
          FBorderRadiusBR := Parts[0];
          FBorderRadiusBL := Parts[0];
        end;
      2:
        begin
          FBorderRadiusTL := Parts[0];
          FBorderRadiusTR := Parts[1];
          FBorderRadiusBR := Parts[0];
          FBorderRadiusBL := Parts[1];
        end;
      3:
        begin
          FBorderRadiusTL := Parts[0];
          FBorderRadiusTR := Parts[1];
          FBorderRadiusBR := Parts[2];
          FBorderRadiusBL := Parts[1];
        end;
      4:
        begin
          FBorderRadiusTL := Parts[0];
          FBorderRadiusTR := Parts[1];
          FBorderRadiusBR := Parts[2];
          FBorderRadiusBL := Parts[3];
        end;
    end;
  finally
    Tokens.Free;
  end;
end;

procedure TCssStyledControl.ParseBoxShadow(const AValue: string);
var
  Tokens: TStringList;
  S: string;
  P, I, Px: Integer;
  C: TColor;
  FoundX, FoundY, FoundBlur, FoundSpread: Boolean;
  InsetSeen: Boolean;
begin
  FBoxShadow.OffsetX := 0;
  FBoxShadow.OffsetY := 0;
  FBoxShadow.Blur := 0;
  FBoxShadow.Spread := 0;
  FBoxShadow.Color := clBlack;
  FBoxShadow.HasColor := False;
  FBoxShadow.Used := False;

  S := Trim(AValue);
  if (S = '') or SameText(S, 'none') then
    Exit;

  P := 1;
  InsetSeen := False;
  while P <= Length(S) do
  begin
    if S[P] = ',' then
    begin
      S := Copy(S, 1, P - 1);
      Break;
    end;
    Inc(P);
  end;

  Tokens := TStringList.Create;
  try
    SplitBySpaces(Trim(S), Tokens);

    FoundX := False;
    FoundY := False;
    FoundBlur := False;
    FoundSpread := False;

    for I := 0 to Tokens.Count - 1 do
    begin
      if SameText(Tokens[I], 'inset') then
      begin
        InsetSeen := True;
        Continue;
      end;

      if ParseColor(Tokens[I], C) then
      begin
        FBoxShadow.Color := C;
        FBoxShadow.HasColor := True;
        Continue;
      end;

      if ParseLengthPx(Tokens[I], Px) then
      begin
        if not FoundX then
        begin
          FBoxShadow.OffsetX := Px;
          FoundX := True;
        end
        else if not FoundY then
        begin
          FBoxShadow.OffsetY := Px;
          FoundY := True;
        end
        else if not FoundBlur then
        begin
          FBoxShadow.Blur := Px;
          FoundBlur := True;
        end
        else if not FoundSpread then
        begin
          FBoxShadow.Spread := Px;
          FoundSpread := True;
        end;
      end;
    end;

    if not FBoxShadow.HasColor then
      FBoxShadow.Color := RGBToColor(0, 0, 0);

    FBoxShadow.Used :=
      (not InsetSeen) and
      (FoundX or FoundY or FoundBlur or FoundSpread);
  finally
    Tokens.Free;
  end;
end;

procedure TCssStyledControl.ParseBackgroundGradient(const AValue: string);
var
  S, Inner, FirstArg, Side, Arg, Token: string;
  OpenP, CloseP, Depth, I, J: Integer;
  Args, Tokens: TStringList;
  Kind: TCssGradientKind;
  Angle, AngleDeg: Double;
  StopStart, StopCount: Integer;
  StopList: array of TCssGradientStop;
  Stop: TCssGradientStop;
  Col: TColor;
  PosPct: Double;
  Found: Boolean;
begin
  FBackgroundGradient.Kind := cgkNone;
  SetLength(FBackgroundGradient.Stops, 0);

  S := Trim(AValue);
  if S = '' then Exit;

  if Pos('linear-gradient(', LowerCase(S)) = 1 then
    Kind := cgkLinear
  else if Pos('radial-gradient(', LowerCase(S)) = 1 then
    Kind := cgkRadial
  else
    Exit;

  OpenP := Pos('(', S);
  if OpenP = 0 then Exit;

  Depth := 1;
  I := OpenP + 1;
  CloseP := 0;
  while (I <= Length(S)) and (Depth > 0) do
  begin
    if S[I] = '(' then Inc(Depth)
    else if S[I] = ')' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        CloseP := I;
        Break;
      end;
    end;
    Inc(I);
  end;

  if CloseP = 0 then Exit;

  Inner := Copy(S, OpenP + 1, CloseP - OpenP - 1);

  Args := TStringList.Create;
  Tokens := TStringList.Create;
  try
    SplitByTopCommas(Inner, Args);

    Angle := Pi;
    StopStart := 0;

    if Args.Count > 0 then
    begin
      FirstArg := Trim(Args[0]);

      if Kind = cgkLinear then
      begin
        if TryParseGradientAngle(FirstArg, AngleDeg) then
        begin
          Angle := AngleDeg * Pi / 180;
          StopStart := 1;
        end
        else if Pos('to ', LowerCase(FirstArg)) = 1 then
        begin
          Side := LowerCase(Trim(Copy(FirstArg, 4, MaxInt)));

          if Side = 'right' then AngleDeg := 90
          else if Side = 'left' then AngleDeg := 270
          else if Side = 'top' then AngleDeg := 0
          else if Side = 'bottom' then AngleDeg := 180
          else if Side = 'top right' then AngleDeg := 45
          else if Side = 'top left' then AngleDeg := 315
          else if Side = 'bottom right' then AngleDeg := 135
          else if Side = 'bottom left' then AngleDeg := 225
          else AngleDeg := 180;

          Angle := AngleDeg * Pi / 180;
          StopStart := 1;
        end;
      end
      else
      begin
        if not ParseColor(FirstArg, Col) then
          StopStart := 1;
      end;
    end;

    StopCount := 0;
    SetLength(StopList, Args.Count - StopStart);

    for I := StopStart to Args.Count - 1 do
    begin
      Arg := Trim(Args[I]);
      if Arg = '' then Continue;

      Tokens.Clear;
      SplitBySpaces(Arg, Tokens);

      Stop.Position := -1;
      Stop.Color := clBlack;

      for J := 0 to Tokens.Count - 1 do
      begin
        Token := Tokens[J];

        if ParseColor(Token, Col) then
          Stop.Color := Col
        else if TryParseGradientPosition(Token, PosPct) then
          Stop.Position := PosPct;
      end;

      if StopCount >= Length(StopList) then
        SetLength(StopList, StopCount + 1);

      StopList[StopCount] := Stop;
      Inc(StopCount);
    end;

    SetLength(StopList, StopCount);

    if StopCount = 0 then
      Exit;

    EnsureStopPositions(StopList);

    FBackgroundGradient.Kind := Kind;
    FBackgroundGradient.Angle := Angle;
    SetLength(FBackgroundGradient.Stops, StopCount);

    for I := 0 to StopCount - 1 do
      FBackgroundGradient.Stops[I] := StopList[I];
  finally
    Tokens.Free;
    Args.Free;
  end;
end;

function TCssStyledControl.GetParentBackgroundColor: TColor;
var
  C: TControl;
  R: TColor;
begin
  Result := clBtnFace;

  C := Parent;
  while C <> nil do
  begin
    if C is TCssStyledControl then
      R := TCssStyledControl(C).GetCssBackgroundColor
    else
      R := C.Color;

    if (R <> clNone) and (R <> clDefault) then
      Exit(R);

    C := C.Parent;
  end;
end;

function TCssStyledControl.GetBackgroundBeneathAtClientPoint(
  const AClientPoint: TPoint): TColor;
var
  C: TControl;
  ParentControl: TWinControl;
  PtInParent: TPoint;
  SiblingRect: TRect;
  I, MyIndex: Integer;
  Sibling: TControl;
  R: TColor;
  ScreenPt, LocalPt: TPoint;
begin
  if Assigned(FExternalCornerBitmap) then
  begin
    ScreenPt := ClientToScreen(AClientPoint);
    LocalPt := Point(
      ScreenPt.X - FExternalCornerOrigin.X,
      ScreenPt.Y - FExternalCornerOrigin.Y
    );

    if (LocalPt.X >= 0) and (LocalPt.Y >= 0) and
       (LocalPt.X < FExternalCornerBitmap.Width) and
       (LocalPt.Y < FExternalCornerBitmap.Height) then
      Exit(FExternalCornerBitmap.Canvas.Pixels[LocalPt.X, LocalPt.Y]);
  end;

  PtInParent := Point(AClientPoint.X + Left, AClientPoint.Y + Top);
  C := Self;

  while C.Parent <> nil do
  begin
    ParentControl := C.Parent;

    MyIndex := -1;
    for I := 0 to ParentControl.ControlCount - 1 do
      if ParentControl.Controls[I] = C then
      begin
        MyIndex := I;
        Break;
      end;

    if MyIndex > 0 then
      for I := MyIndex - 1 downto 0 do
      begin
        Sibling := ParentControl.Controls[I];

        if not Sibling.Visible then
          Continue;

        SiblingRect := Sibling.BoundsRect;
        if not PtInRect(SiblingRect, PtInParent) then
          Continue;

        if Sibling is TCssStyledControl then
          R := TCssStyledControl(Sibling).GetCssBackgroundColor
        else
          R := Sibling.Color;

        if (R <> clNone) and (R <> clDefault) then
          Exit(R);
      end;

    if ParentControl is TCssStyledControl then
      R := TCssStyledControl(ParentControl).GetCssBackgroundColor
    else
      R := ParentControl.Color;

    if (R <> clNone) and (R <> clDefault) then
      Exit(R);

    PtInParent := Point(
      PtInParent.X + ParentControl.Left,
      PtInParent.Y + ParentControl.Top
    );
    C := ParentControl;
  end;

  Result := clBtnFace;
end;

procedure TCssStyledControl.DrawRoundedRectAA(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AParams: TCssRoundedBoxParams);
var
  W, H, PadX, PadY: Integer;
  Bmp: TBitmap;
begin
  if ACanvas = nil then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;

  if (W <= 0) or (H <= 0) then
    Exit;

  EnsureRoundedRectCache;

  Bmp := GRoundedRectCache.GetBitmap(W, H, AParams);

  ComputeShadowPad(AParams.Shadow, PadX, PadY);

  ACanvas.Draw(ARect.Left - PadX, ARect.Top - PadY, Bmp);
end;

function TCssStyledControl.GetCssBorderRadii: TCssCornerRadii;
begin
  Result.TL := FBorderRadiusTL;
  Result.TR := FBorderRadiusTR;
  Result.BR := FBorderRadiusBR;
  Result.BL := FBorderRadiusBL;
end;

function TCssStyledControl.GetCssGradient : TCssGradient;
begin
  Result := FBackgroundGradient;
end;

function TCssStyledControl.GetCssBoxShadow : TCssBoxShadow;
begin
  Result := FBoxShadow;
end;

procedure TCssStyledControl.ParseTextShadow(const AValue: string);
var
  Tokens: TStringList;
  I: Integer;
  LenCount: Integer;
  Px: Integer;
  C: TColor;
  Found: Boolean;
  S: string;
begin
  FTextShadow := False;
  FTextShadowX := 1;
  FTextShadowY := 1;
  FTextShadowColor := RGBToColor(0, 0, 0);

  S := LowerCase(Trim(AValue));
  if (S = '') or (S = 'none') then
    Exit;

  Tokens := TStringList.Create;
  try
    SplitBySpaces(AValue, Tokens);

    LenCount := 0;
    Found := False;

    for I := 0 to Tokens.Count - 1 do
    begin
      if (LenCount < 2) and ParseLengthPx(Tokens[I], Px) then
      begin
        if LenCount = 0 then
          FTextShadowX := Px
        else
          FTextShadowY := Px;

        Inc(LenCount);
        Found := True;
      end
      else if ParseColor(Tokens[I], C) then
      begin
        FTextShadowColor := C;
        Found := True;
      end;
    end;

    FTextShadow := Found and (LenCount > 0);

    if FTextShadow and (LenCount < 2) then
    begin
      FTextShadowX := 1;
      FTextShadowY := 1;
    end;
  finally
    Tokens.Free;
  end;
end;

function TCssStyledControl.ParseColor(const AValue: string; out AColor: TColor): Boolean;
var
  S, Hex, Nums, Token: string;
  P, I, Comp: Integer;
  R, G, B: Integer;
  Vals: array[0..2] of Integer;
begin
  Result := False;

  S := LowerCase(Trim(AValue));

  if S = '' then
    Exit;

  if S = 'transparent' then
  begin
    AColor := clNone;
    Exit(True);
  end;

  if S[1] = '#' then
  begin
    Hex := Copy(S, 2, MaxInt);

    if (Length(Hex) = 3) or (Length(Hex) = 4) then
    begin
      if not TryStrToInt('$' + Hex[1] + Hex[1], R) then Exit;
      if not TryStrToInt('$' + Hex[2] + Hex[2], G) then Exit;
      if not TryStrToInt('$' + Hex[3] + Hex[3], B) then Exit;
    end
    else if Length(Hex) >= 6 then
    begin
      if not TryStrToInt('$' + Copy(Hex, 1, 2), R) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 3, 2), G) then Exit;
      if not TryStrToInt('$' + Copy(Hex, 5, 2), B) then Exit;
    end
    else
      Exit;

    AColor := RGBToColor(R, G, B);
    Exit(True);
  end;

  if (Pos('rgb(', S) = 1) or (Pos('rgba(', S) = 1) then
  begin
    P := Pos('(', S);
    if P = 0 then
      Exit;

    Nums := Copy(S, P + 1, MaxInt);

    P := Pos(')', Nums);
    if P = 0 then
      Exit;

    Nums := Copy(Nums, 1, P - 1);

    Comp := 0;
    Token := '';

    for I := 1 to Length(Nums) + 1 do
    begin
      if (I > Length(Nums)) or (Nums[I] = ',') then
      begin
        Token := Trim(Token);

        if Comp < 3 then
        begin
          if EndsText('%', Token) then
          begin
            Token := Copy(Token, 1, Length(Token) - 1);

            if not TryParseNumberPrefix(Token, Vals[Comp]) then
              Exit;

            if Vals[Comp] < 0 then
              Vals[Comp] := 0;

            if Vals[Comp] > 100 then
              Vals[Comp] := 100;

            Vals[Comp] := Round(Vals[Comp] * 255 / 100);
          end
          else
          begin
            if not TryParseNumberPrefix(Token, Vals[Comp]) then
              Exit;
          end;
        end;

        Inc(Comp);
        Token := '';
      end
      else
      begin
        Token := Token + Nums[I];
      end;
    end;

    if Comp < 3 then
      Exit;

    for I := 0 to 2 do
    begin
      if Vals[I] < 0 then
        Vals[I] := 0;

      if Vals[I] > 255 then
        Vals[I] := 255;
    end;

    AColor := RGBToColor(Vals[0], Vals[1], Vals[2]);
    Exit(True);
  end;

  Result := TryNamedColor(S, AColor);
end;

function TCssStyledControl.TryNamedColor(const AName: string; out AColor: TColor): Boolean;
var
  S: string;
begin
  Result := True;
  S := LowerCase(AName);

  if S = 'black' then AColor := RGBToColor(0, 0, 0)
  else if S = 'white' then AColor := RGBToColor(255, 255, 255)
  else if S = 'red' then AColor := RGBToColor(255, 0, 0)
  else if S = 'green' then AColor := RGBToColor(0, 128, 0)
  else if S = 'blue' then AColor := RGBToColor(0, 0, 255)
  else if S = 'yellow' then AColor := RGBToColor(255, 255, 0)
  else if S = 'orange' then AColor := RGBToColor(255, 165, 0)
  else if S = 'purple' then AColor := RGBToColor(128, 0, 128)
  else if (S = 'gray') or (S = 'grey') then AColor := RGBToColor(128, 128, 128)
  else if S = 'silver' then AColor := RGBToColor(192, 192, 192)
  else if S = 'maroon' then AColor := RGBToColor(128, 0, 0)
  else if S = 'olive' then AColor := RGBToColor(128, 128, 0)
  else if S = 'lime' then AColor := RGBToColor(0, 255, 0)
  else if (S = 'aqua') or (S = 'cyan') then AColor := RGBToColor(0, 255, 255)
  else if S = 'teal' then AColor := RGBToColor(0, 128, 128)
  else if S = 'navy' then AColor := RGBToColor(0, 0, 128)
  else if (S = 'fuchsia') or (S = 'magenta') then AColor := RGBToColor(255, 0, 255)
  else if S = 'pink' then AColor := RGBToColor(255, 192, 203)
  else if S = 'brown' then AColor := RGBToColor(165, 42, 42)
  else if S = 'gold' then AColor := RGBToColor(255, 215, 0)
  else if S = 'khaki' then AColor := RGBToColor(240, 230, 140)
  else if S = 'beige' then AColor := RGBToColor(245, 245, 220)
  else if S = 'ivory' then AColor := RGBToColor(255, 255, 240)
  else if S = 'snow' then AColor := RGBToColor(255, 250, 250)
  else if S = 'tomato' then AColor := RGBToColor(255, 99, 71)
  else if S = 'coral' then AColor := RGBToColor(255, 127, 80)
  else if S = 'salmon' then AColor := RGBToColor(250, 128, 114)
  else if (S = 'darkgray') or (S = 'darkgrey') then AColor := RGBToColor(169, 169, 169)
  else if (S = 'lightgray') or (S = 'lightgrey') then AColor := RGBToColor(211, 211, 211)
  else if (S = 'dimgray') or (S = 'dimgrey') then AColor := RGBToColor(105, 105, 105)
  else if S = 'whitesmoke' then AColor := RGBToColor(245, 245, 245)
  else
    Result := False;
end;

function TCssStyledControl.ParseLengthPx(const AValue: string; out APx: Integer): Boolean;
var
  S: string;
  Num: Integer;
begin
  Result := False;
  APx := 0;

  S := LowerCase(Trim(AValue));

  if S = '' then
    Exit;

  if S = '0' then
    Exit(True);

  if S = 'thin' then
  begin
    APx := 1;
    Exit(True);
  end;

  if S = 'medium' then
  begin
    APx := 2;
    Exit(True);
  end;

  if S = 'thick' then
  begin
    APx := 4;
    Exit(True);
  end;

  if TryParseNumberPrefix(S, Num) then
  begin
    if EndsText('pt', S) then
      APx := Round(Num * 96 / 72)
    else
      APx := Num;

    Result := True;
  end;
end;

function TCssStyledControl.ParseCssColor(const AValue: string; out AColor: TColor): Boolean;
begin
  Result := ParseColor(AValue, AColor);
end;

function TCssStyledControl.ParseCssLengthPx(const AValue: string; out APx: Integer): Boolean;
begin
  Result := ParseLengthPx(AValue, APx);
end;

function TCssStyledControl.ParseCssCursor(const AValue: string): TCursor;
var
  S: string;
begin
  S := LowerCase(Trim(AValue));

  if S = 'pointer' then Result := crHandPoint
  else if S = 'hand' then Result := crHandPoint
  else if S = 'text' then Result := crIBeam
  else if S = 'wait' then Result := crHourGlass
  else if S = 'progress' then Result := crAppStart
  else if S = 'help' then Result := crHelp
  else if S = 'crosshair' then Result := crCross
  else if S = 'move' then Result := crSizeAll
  else if S = 'not-allowed' then Result := crNo
  else if S = 'no-drop' then Result := crNoDrop
  else if S = 'e-resize' then Result := crSizeWE
  else if S = 'w-resize' then Result := crSizeWE
  else if S = 'n-resize' then Result := crSizeNS
  else if S = 's-resize' then Result := crSizeNS
  else if S = 'ne-resize' then Result := crSizeNESW
  else if S = 'sw-resize' then Result := crSizeNESW
  else if S = 'nw-resize' then Result := crSizeNWSE
  else if S = 'se-resize' then Result := crSizeNWSE
  else if S = 'col-resize' then Result := crSizeWE
  else if S = 'row-resize' then Result := crSizeNS
  else if S = 'arrow' then Result := crArrow
  else if S = 'default' then Result := crDefault
  else if S = 'auto' then Result := crDefault
  else if S = 'inherit' then Result := crDefault
  else Result := crDefault;
end;

function TCssStyledControl.CssClassContains(const AClass: string): Boolean;
var
  List: TStringList;
  I: Integer;
begin
  Result := False;

  if Trim(FCssClass) = '' then
    Exit;

  List := TStringList.Create;

  try
    SplitBySpaces(FCssClass, List);

    for I := 0 to List.Count - 1 do
    begin
      if SameText(List[I], AClass) then
        Exit(True);
    end;
  finally
    List.Free;
  end;
end;

function TCssStyledControl.GetBorderPenStyle: TPenStyle;
begin
  case FBorderStyle of
    cbsDotted: Result := psDot;
    cbsDashed: Result := psDash;
  else
    Result := psSolid;
  end;
end;

{ ============================================================ }
{ TCssStyledControl — link handling                            }
{ ============================================================ }

function TCssStyledControl.IsLinkSelector(
  const ASelector: string;
  out AHover: Boolean): Boolean;
var
  TypeName, ID: string;
  ClassList, PseudoList: TStringList;
  HasAttribute, HasFunctional, HasPseudoElement: Boolean;
  I: Integer;
  P: string;
begin
  Result := False;
  AHover := False;

  ClassList := TStringList.Create;
  PseudoList := TStringList.Create;
  try
    ParseSimpleSelector(
      ASelector,
      TypeName,
      ID,
      ClassList,
      PseudoList,
      HasAttribute,
      HasFunctional,
      HasPseudoElement
    );

    if not SameText(TypeName, 'a') then
      Exit;

    if (ID <> '') or
       (ClassList.Count > 0) or
       HasAttribute or
       HasFunctional or
       HasPseudoElement then
    begin
      Exit;
    end;

    Result := True;

    for I := 0 to PseudoList.Count - 1 do
    begin
      P := PseudoList[I];

      if (P = 'hover') or (P = 'active') then
      begin
        AHover := True;
      end
      else if not ((P = 'link') or
                   (P = 'visited') or
                   (P = 'focus') or
                   (P = 'focus-visible')) then
      begin
        Result := False;
        Exit;
      end;
    end;
  finally
    PseudoList.Free;
    ClassList.Free;
  end;
end;

procedure TCssStyledControl.ApplyLinkDeclaration(
  var AStyle: TCssLinkStyle;
  const AName, AValue: string);
var
  C: TColor;
  S: string;
begin
  if AValue = '' then
    Exit;

  if AName = 'color' then
  begin
    if ParseColor(AValue, C) then
    begin
      AStyle.Color := C;
      AStyle.HasColor := True;
    end;
  end
  else if AName = 'text-decoration' then
  begin
    S := LowerCase(AValue);

    if Pos('none', S) > 0 then
    begin
      AStyle.Underline := False;
      AStyle.HasUnderline := True;
    end
    else if Pos('underline', S) > 0 then
    begin
      AStyle.Underline := True;
      AStyle.HasUnderline := True;
    end;
  end
  else if AName = 'cursor' then
  begin
    AStyle.Cursor := ParseCssCursor(AValue);
    AStyle.HasCursor := True;
  end;
end;

procedure TCssStyledControl.ApplyLinkDeclarations(
  var AStyle: TCssLinkStyle;
  const ADeclarations: string);
var
  I, Start: Integer;
  Item: string;

  procedure ApplyOne(const AItem: string);
  var
    CPos, IPos: Integer;
    N, V, LV: string;
  begin
    if AItem = '' then
      Exit;

    CPos := Pos(':', AItem);
    if CPos = 0 then
      Exit;

    N := LowerCase(Trim(Copy(AItem, 1, CPos - 1)));
    V := Trim(Copy(AItem, CPos + 1, MaxInt));
    LV := LowerCase(V);

    IPos := Pos('!important', LV);
    if IPos > 0 then
      V := Trim(Copy(V, 1, IPos - 1));

    ApplyLinkDeclaration(AStyle, N, V);
  end;

begin
  Start := 1;

  for I := 1 to Length(ADeclarations) do
  begin
    if ADeclarations[I] = ';' then
    begin
      Item := Trim(Copy(ADeclarations, Start, I - Start));
      ApplyOne(Item);
      Start := I + 1;
    end;
  end;

  Item := Trim(Copy(ADeclarations, Start, MaxInt));
  ApplyOne(Item);
end;

function TCssStyledControl.LinkAt(const P: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;

  if not FHtmlMode then
    Exit;

  for I := High(FLinkAreas) downto 0 do
  begin
    if PtInRect(FLinkAreas[I].Rect, P) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssStyledControl.GetLinkInfoById(ALinkId: Integer): TCssHtmlLinkInfo;
var
  I: Integer;
begin
  for I := 0 to High(FLinkInfos) do
  begin
    if FLinkInfos[I].LinkId = ALinkId then
    begin
      Result := FLinkInfos[I];
      Exit;
    end;
  end;

  Result.LinkId := 0;
  Result.Href := '';
  Result.Text := '';
end;

procedure TCssStyledControl.AddLinkArea(
  ALinkId: Integer;
  const AHref: string;
  const ARect: TRect);
var
  N: Integer;
begin
  if ALinkId <= 0 then
    Exit;

  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  N := Length(FLinkAreas);
  SetLength(FLinkAreas, N + 1);

  FLinkAreas[N].LinkId := ALinkId;
  FLinkAreas[N].Href := AHref;
  FLinkAreas[N].Rect := ARect;
end;

procedure TCssStyledControl.SetHoverLinkId(ALinkId: Integer);
begin
  if FHoverLinkId = ALinkId then
    Exit;

  FHoverLinkId := ALinkId;
  UpdateCursor;
  Invalidate;
end;

function TCssStyledControl.GetLinkCursor: TCursor;
begin
  if FLinkHover.HasCursor then
    Result := FLinkHover.Cursor
  else if FLinkNormal.HasCursor then
    Result := FLinkNormal.Cursor
  else
    Result := crHandPoint;
end;

procedure TCssStyledControl.UpdateCursor;
begin
  if FHoverLinkId > 0 then
    Cursor := GetLinkCursor
  else
    Cursor := FCssCursor;
end;

function TCssStyledControl.GetEffectiveLinkColor(AHover: Boolean): TColor;
begin
  if AHover and FLinkHover.HasColor then
    Result := FLinkHover.Color
  else if FLinkNormal.HasColor then
    Result := FLinkNormal.Color
  else
    Result := RGBToColor(0, 0, 238);

  Result := ApplyOpacity(Result);
end;

function TCssStyledControl.GetEffectiveLinkUnderline(AHover: Boolean): Boolean;
begin
  if AHover and FLinkHover.HasUnderline then
    Result := FLinkHover.Underline
  else if FLinkNormal.HasUnderline then
    Result := FLinkNormal.Underline
  else
    Result := True;
end;

procedure TCssStyledControl.MouseEnter;
begin
  inherited MouseEnter;

  if csDestroying in ComponentState then
    Exit;

  FMouseInControl := True;
  RefreshStylesByState;
  NotifyParentsHoverChanged(True);
end;

procedure TCssStyledControl.MouseLeave;
begin
  inherited MouseLeave;

  if csDestroying in ComponentState then
    Exit;

  FMouseInControl := False;

  if not MouseCapture then
    FMousePressed := False;

  SetHoverLinkId(0);
  RefreshStylesByState;
  NotifyParentsHoverChanged(False);
end;

procedure TCssStyledControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if csDestroying in ComponentState then
    Exit;

  if Enabled and (Button = mbLeft) then
  begin
    FMousePressed := True;
    MouseCapture := True;
    RefreshStylesByState;
  end;
end;

procedure TCssStyledControl.MouseUp(
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Integer);
var
  LinkIdx: Integer;
  PendingLinkClick: Boolean;
  LinkHref: string;
  LinkText: string;
  Info: TCssHtmlLinkInfo;
begin
  if csDestroying in ComponentState then
    Exit;

  PendingLinkClick := False;
  LinkIdx := -1;
  LinkHref := '';
  LinkText := '';

  if FMousePressed and Enabled and (Button = mbLeft) then
  begin
    LinkIdx := LinkAt(Point(X, Y));

    if LinkIdx >= 0 then
    begin
      LinkHref := FLinkAreas[LinkIdx].Href;

      Info := GetLinkInfoById(FLinkAreas[LinkIdx].LinkId);
      LinkText := Info.Text;

      PendingLinkClick := True;
      FSuppressClick := True;
    end;
  end;

  inherited MouseUp(Button, Shift, X, Y);

  if FMousePressed then
  begin
    FMousePressed := False;
    MouseCapture := False;
    RefreshStylesByState;
  end;

  if PendingLinkClick then
  begin
    FSuppressClick := False;
    DoLinkClick(LinkHref, LinkText);
  end
  else
  begin
    FSuppressClick := False;
  end;
end;

procedure TCssStyledControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if csDestroying in ComponentState then
    Exit;

  if not FHtmlMode then
  begin
    SetHoverLinkId(0);
    Exit;
  end;

  Idx := LinkAt(Point(X, Y));
  if Idx >= 0 then
    SetHoverLinkId(FLinkAreas[Idx].LinkId)
  else
    SetHoverLinkId(0);
end;

procedure TCssStyledControl.DoEnter;
begin
  inherited DoEnter;

  FFocused := True;
  RefreshStylesByState;
  NotifyParentsFocusChanged(True);
end;

procedure TCssStyledControl.DoExit;
begin
  inherited DoExit;

  FFocused := False;
  RefreshStylesByState;
  NotifyParentsFocusChanged(False);
end;

procedure TCssStyledControl.EnabledChanged;
begin
  inherited EnabledChanged;

  if not Enabled then
  begin
    FMousePressed := False;

    if not (csDestroying in ComponentState) then
      MouseCapture := False;
  end;

  RefreshStylesByState;
  NotifyUpperSiblingsRepaint;
end;

procedure TCssStyledControl.NotifyParentsFocusChanged(AFocused: Boolean);
var
  C: TControl;
begin
  C := Parent;
  while C <> nil do
  begin
    if C is TCssStyledControl then
      TCssStyledControl(C).ChildFocusChanged(AFocused);
    C := C.Parent;
  end;
end;

procedure TCssStyledControl.ChildHoverChanged(AChildHovered: Boolean);
var
  WasHovered, IsHovered: Boolean;
begin
  WasHovered := GetEffectiveHoverState;

  if AChildHovered then
    Inc(FHoveredChildrenCount)
  else if FHoveredChildrenCount > 0 then
    Dec(FHoveredChildrenCount);

  IsHovered := GetEffectiveHoverState;

  if WasHovered <> IsHovered then
  begin
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssStyledControl.NotifyParentsHoverChanged(AHovered: Boolean);
var
  C: TControl;
begin
  C := Parent;
  while C <> nil do
  begin
    if (C is TCssStyledControl) and
       not (csDestroying in C.ComponentState) then
      TCssStyledControl(C).ChildHoverChanged(AHovered);
    C := C.Parent;
  end;
end;

procedure TCssStyledControl.ChildFocusChanged(AChildFocused: Boolean);
begin
  // Do nothing
end;

procedure TCssStyledControl.Click;
begin
  if FSuppressClick then
  begin
    FSuppressClick := False;
    Exit;
  end;

  if FAutoToggle and Enabled then
    Checked := not Checked;

  inherited Click;
end;

procedure TCssStyledControl.DoLinkClick(const AHref, AText: string);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, AHref, AText);
end;

{ ============================================================ }
{ TCssStyledControl — hint handling                            }
{ ============================================================ }

function TCssStyledControl.UseCustomHint: Boolean;
var
  Src: TCssStyledControl;
begin
  Src := GetHintOwner;

  if Src = nil then
    Exit(False);

  Result :=
    Src.ShowHint and
    (Src.FHintHtmlMode or (Src.FHintCss <> ''));
end;

function TCssStyledControl.GetHintOwner: TCssStyledControl;
var
  C: TControl;
begin
  if Trim(Hint) <> '' then
    Exit(Self);

  C := Parent;
  while C <> nil do
  begin
    if (C is TCssStyledControl) and (Trim(C.Hint) <> '') then
      Exit(TCssStyledControl(C));
    C := C.Parent;
  end;

  Result := nil;
end;

type
  TCssStyledHintWindow = class(THintWindow)
  private
    FRenderer: TCssStyledControl;
    FHintText: string;

    procedure EnsureRenderer(const AHint: string; AData: Pointer);
    function DefaultHintCss: string;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function CalcHintRect(
      MaxWidth: Integer;
      const AHint: string;
      AData: Pointer): TRect; override;

    procedure ActivateHintData(
      Rect: TRect;
      const AHint: string;
      AData: Pointer); override;
  end;

constructor TCssStyledHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color := clNone;
end;

destructor TCssStyledHintWindow.Destroy;
begin
  FreeAndNil(FRenderer);
  inherited Destroy;
end;

function TCssStyledHintWindow.DefaultHintCss: string;
begin
  Result :=
    'background-color:#FFFFE1;' +
    'color:#000000;' +
    'border:1px solid #000000;' +
    'border-radius:0px;' +
    'padding:3px;' +
    'text-align:left;' +
    'vertical-align:top;';
end;

procedure TCssStyledHintWindow.EnsureRenderer(const AHint: string; AData: Pointer);
var
  Ctl: TCssStyledControl;
  Css: string;
begin
  FHintText := AHint;

  HandleNeeded;

  if FRenderer = nil then
  begin
    FRenderer := TCssStyledControl.Create(Self);
    FRenderer.Parent := Self;
    FRenderer.Visible := False;
    FRenderer.ParentFont := False;
    FRenderer.ParentColor := False;
  end;

  Ctl := nil;

  if AData <> nil then
  begin
    if TObject(AData) is TCssStyledControl then
      Ctl := TCssStyledControl(AData);
  end;

  if Assigned(Ctl) then
  begin
    Ctl.AssignEffectiveCssFontToFont(FRenderer.Font);
    FRenderer.HtmlMode := Ctl.HintHtmlMode;
  end
  else
  begin
    FRenderer.Font.Assign(Font);
    FRenderer.HtmlMode := True;
  end;

  Css := DefaultHintCss;

  if Assigned(Ctl) and (Ctl.FHintCss <> '') then
    Css := Css + Ctl.FHintCss;

  FRenderer.CssStyle := Css;
  FRenderer.Caption := AHint;
end;

function TCssStyledHintWindow.CalcHintRect(
  MaxWidth: Integer;
  const AHint: string;
  AData: Pointer): TRect;
var
  BW: Integer;
  Pad: TRect;
  AvailWidth: Integer;
  S: TSize;
  Bmp: TBitmap;
begin
  EnsureRenderer(AHint, AData);

  if MaxWidth <= 0 then
    MaxWidth := 400;

  BW := FRenderer.GetStyledBorderWidth;
  Pad := FRenderer.GetStyledPadding;

  AvailWidth := MaxWidth - 2 * BW - Pad.Left - Pad.Right;
  if AvailWidth < 10 then
    AvailWidth := 10;

  Bmp := TBitmap.Create;
  try
    Bmp.Width := 1;
    Bmp.Height := 1;

    // We measure the HTML on an independent canvas, without touching the renderer's Canvas.
    S := FRenderer.MeasureHtmlTextSize(Bmp.Canvas, AHint, AvailWidth);
  finally
    Bmp.Free;
  end;

  Result := Rect(
    0,
    0,
    S.cx + 2 * BW + Pad.Left + Pad.Right,
    S.cy + 2 * BW + Pad.Top + Pad.Bottom
  );
end;

procedure TCssStyledHintWindow.ActivateHintData(
  Rect: TRect;
  const AHint: string;
  AData: Pointer);
begin
  EnsureRenderer(AHint, AData);
  inherited ActivateHintData(Rect, AHint, AData);
end;

procedure TCssStyledHintWindow.Paint;
var
  R, TextR: TRect;
  BW: Integer;
  Pad: TRect;
  ScreenDC: HDC;
  Bmp: TBitmap;
  Origin: TPoint;
begin
  if FRenderer = nil then
  begin
    inherited Paint;
    Exit;
  end;

  R := ClientRect;

  Bmp := nil;
  ScreenDC := LCLIntf.GetDC(0);
  if ScreenDC <> 0 then
  begin
    try
      Origin := ClientToScreen(Point(0, 0));

      Bmp := TBitmap.Create;
      Bmp.PixelFormat := pf24bit;
      Bmp.Width := ClientWidth;
      Bmp.Height := ClientHeight;

      LCLIntf.BitBlt(
        Bmp.Canvas.Handle, 0, 0, Bmp.Width, Bmp.Height,
        ScreenDC, Origin.X, Origin.Y, SRCCOPY
      );

      FRenderer.SetExternalCornerSource(Bmp, Origin);
    finally
      LCLIntf.ReleaseDC(0, ScreenDC);
    end;
  end;

  try
    FRenderer.DrawStyledBackground(Canvas, R);

    BW := FRenderer.GetStyledBorderWidth;
    Pad := FRenderer.GetStyledPadding;

    TextR := R;
    TextR.Left := TextR.Left + BW + Pad.Left;
    TextR.Top := TextR.Top + BW + Pad.Top;
    TextR.Right := TextR.Right - BW - Pad.Right;
    TextR.Bottom := TextR.Bottom - BW - Pad.Bottom;

    if (TextR.Right > TextR.Left) and (TextR.Bottom > TextR.Top) then
      FRenderer.DrawCaptionToCanvas(Canvas, TextR, FHintText);
  finally
    FRenderer.SetExternalCornerSource(nil, Point(0, 0));
    Bmp.Free;
  end;
end;

procedure TCssStyledControl.CMHintShow(var Message: TCMHintShow);
var
  Src: TCssStyledControl;
  P: TPoint;
  CustomHint: string;
begin
  P := ScreenToClient(Mouse.CursorPos);

  if CustomHintForPoint(P, CustomHint) and (CustomHint <> '') then
  begin
    Src := GetHintOwner;
    if Src = nil then
      Src := Self;

    Message.HintInfo^.HintStr := CustomHint;
    Message.HintInfo^.HintWindowClass := TCssStyledHintWindow;
    Message.HintInfo^.HintData := Src;
    Message.Result := 0;
    Exit;
  end;

  Src := GetHintOwner;

  if (Src = nil) or
     (not Src.ShowHint) or
     (not (Src.FHintHtmlMode or (Src.FHintCss <> ''))) then
  begin
    inherited;
    Exit;
  end;

  Message.HintInfo^.HintWindowClass := TCssStyledHintWindow;
  Message.HintInfo^.HintData := Src;
  Message.Result := 0;
end;

function TCssStyledControl.CustomHintForPoint(const APoint : TPoint; out AHint : string) : Boolean;
begin
  AHint := '';
  Result := False;
end;

function TCssStyledControl.GetDefaultCaption : string;
begin
  Result := '';
end;

procedure TCssStyledControl.SetName(const NewName: TComponentName);
var
  WasEmpty: Boolean;
begin
  WasEmpty := (Name = '');

  if WasEmpty and
     (NewName <> '') and
     (csDesigning in ComponentState) and
     (not (csLoading in ComponentState)) and
     (FCaption = '') then
  begin
    FCaption := GetDefaultCaption;
  end;

  inherited SetName(NewName);
end;

{ ============================================================ }
{ TCssStyledControl — font helpers                             }
{ ============================================================ }

procedure TCssStyledControl.AssignCssFontToFont(AFont: TFont);
begin
  AFont.Assign(Font);

  if FHasFontFamily and (FFontFamily <> '') then
    AFont.Name := FFontFamily;

  if FHasFontPixelHeight and (FFontPixelHeight > 0) then
    AFont.Height := -FFontPixelHeight
  else if FHasFontPointSize and (FFontPointSize > 0) then
    AFont.Size := FFontPointSize;

  if FHasFontBold then
  begin
    if FFontBold then
      AFont.Style := AFont.Style + [fsBold]
    else
      AFont.Style := AFont.Style - [fsBold];
  end;

  if FHasFontItalic then
  begin
    if FFontItalic then
      AFont.Style := AFont.Style + [fsItalic]
    else
      AFont.Style := AFont.Style - [fsItalic];
  end;

  AFont.Color := GetEffectiveTextColor;
end;

procedure TCssStyledControl.UpdateCanvasFont;
begin
  AssignCssFontToFont(Canvas.Font);
end;

procedure TCssStyledControl.HtmlModeChanged;
begin
  // Nothing to do by default.
  // Descendants may override.
end;

function TCssStyledControl.ShouldPaintCaption: Boolean;
begin
  Result := True;
end;

{ ============================================================ }
{ TCssStyledControl — painting                                 }
{ ============================================================ }

procedure TCssStyledControl.DrawStyledText(const ARect: TRect; const AText: string);
begin
  DrawStyledTextToCanvas(Canvas, ARect, AText);
end;

procedure TCssStyledControl.DrawStyledTextToCanvas(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AText: string);
var
  TS: TTextStyle;
  ShadowRect: TRect;
  SavedColor: TColor;
begin
  if AText = '' then
    Exit;

  ACanvas.Brush.Style := bsClear;

  TS := ACanvas.TextStyle;
  TS.Alignment := taLeftJustify;
  TS.Layout := tlTop;
  TS.Wordbreak := FWordWrap;
  TS.Clipping := True;
  TS.Opaque := False;
  TS.ShowPrefix := GetShowPrefix;

  case FTextAlign of
    ctaLeft: TS.Alignment := taLeftJustify;
    ctaCenter: TS.Alignment := taCenter;
    ctaRight: TS.Alignment := taRightJustify;
  end;

  case FVAlign of
    cvaTop: TS.Layout := tlTop;
    cvaMiddle: TS.Layout := tlCenter;
    cvaBottom: TS.Layout := tlBottom;
  end;

  if FTextShadow then
  begin
    SavedColor := ACanvas.Font.Color;
    ACanvas.Font.Color := ApplyOpacity(FTextShadowColor);

    ShadowRect := ARect;
    OffsetRect(ShadowRect, FTextShadowX, FTextShadowY);

    ACanvas.TextRect(
      ShadowRect,
      ShadowRect.Left,
      ShadowRect.Top,
      AText,
      TS
    );

    ACanvas.Font.Color := SavedColor;
  end;

  ACanvas.TextRect(ARect, ARect.Left, ARect.Top, AText, TS);
end;

procedure TCssStyledControl.DrawStyledBackground(
  ACanvas: TCanvas; const ARect: TRect);
var
  BG: TColor;
  BorderVisible: Boolean;
  DrawR: TRect;
  Radii: TCssCornerRadii;
  Params: TCssRoundedBoxParams;
  NeedAA: Boolean;
  TL, TR, BR, BL: TPoint;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  BG := GetCssBackgroundColor;
  BorderVisible := (FBorderStyle <> cbsNone) and (FBorderWidth > 0);
  Radii := GetCssBorderRadii;

  NeedAA :=
    (Radii.TL > 0) or (Radii.TR > 0) or (Radii.BR > 0) or (Radii.BL > 0) or
    FBoxShadow.Used or
    (FBackgroundGradient.Kind <> cgkNone);

  if NeedAA then
  begin
    TL := Point(ARect.Left,     ARect.Top);
    TR := Point(ARect.Right - 1, ARect.Top);
    BR := Point(ARect.Right - 1, ARect.Bottom - 1);
    BL := Point(ARect.Left,     ARect.Bottom - 1);

    Params.Radii := Radii;
    Params.FillColor := BG;
    Params.BorderColor := ApplyOpacity(FBorderColor);
    Params.BorderWidth := FBorderWidth;
    Params.BorderStyle := FBorderStyle;
    Params.Shadow := FBoxShadow;
    Params.Gradient := FBackgroundGradient;
    Params.HasGradient := FBackgroundGradient.Kind <> cgkNone;

    Params.CornerBackColor[0] := GetBackgroundBeneathAtClientPoint(TL);
    Params.CornerBackColor[1] := GetBackgroundBeneathAtClientPoint(TR);
    Params.CornerBackColor[2] := GetBackgroundBeneathAtClientPoint(BR);
    Params.CornerBackColor[3] := GetBackgroundBeneathAtClientPoint(BL);

    DrawRoundedRectAA(ACanvas, ARect, Params);
  end
  else
  begin
    if BG = clNone then
      BG := GetParentBackgroundColor;

    if BG <> clNone then
    begin
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := BG;
      ACanvas.FillRect(ARect);
    end;

    if BorderVisible then
    begin
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Width := FBorderWidth;
      ACanvas.Pen.Color := ApplyOpacity(FBorderColor);
      ACanvas.Pen.Style := GetBorderPenStyle;

      DrawR := ARect;

      if FBorderWidth > 1 then
        InflateRect(DrawR, -(FBorderWidth div 2), -(FBorderWidth div 2));

      ACanvas.Rectangle(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom);
    end;
  end;
end;

procedure TCssStyledControl.DrawCaptionToCanvas(ACanvas: TCanvas;
  const ARect: TRect; const AText: string);
begin
  if FHtmlMode then
    DrawHtmlText(ACanvas, ARect, AText, GetCssTextColor)
  else
  begin
    AssignCssFontToFont(ACanvas.Font);
    DrawStyledTextToCanvas(ACanvas, ARect, AText);
  end;
end;

procedure TCssStyledControl.DrawHtmlText(const ARect: TRect; const AText: string);
begin
  DrawHtmlText(Canvas, ARect, AText);
end;

procedure TCssStyledControl.DrawHtmlText(ACanvas: TCanvas; const ARect: TRect;
  const AText: string);
var
  Blocks: THtmlBlocks;
  BaseFont: TFont;
  BaseHeight: Integer;
  TS: TTextStyle;
  Y: Integer;
  BlockIndex: Integer;
  FirstBlock: Boolean;
  MeasureOnly: Boolean;
  TotalHeight: Integer;
  StartY: Integer;
  SavedColor: TColor;

  procedure DrawTextWithShadow(const S: string; X, Y: Integer);
  var
    SavedColor: TColor;
  begin
    if FTextShadow then
    begin
      SavedColor := ACanvas.Font.Color;
      ACanvas.Font.Color := ApplyOpacity(FTextShadowColor);

      ACanvas.TextRect(
        ARect,
        X + FTextShadowX,
        Y + FTextShadowY,
        S,
        TS
      );

      ACanvas.Font.Color := SavedColor;
    end;

    ACanvas.TextRect(ARect, X, Y, S, TS);
  end;

  procedure SetupFont(const Block: THtmlBlock; const Style: THtmlInlineStyle);
  var
    Scale: Double;
    H: Integer;
  begin
    ACanvas.Font.Assign(BaseFont);

    if (Block.Kind = hbPre) or Style.Mono then
      ACanvas.Font.Name := FMonospaceFontName;

    if Block.Kind = hbHeading then
    begin
      case Block.Level of
        1: Scale := 1.7;
        2: Scale := 1.5;
        3: Scale := 1.3;
        4: Scale := 1.2;
        5: Scale := 1.1;
      else
        Scale := 1.0;
      end;

      ACanvas.Font.Height := -Round(BaseHeight * Scale);
      ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
    end;

    if Style.Bold then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];

    if Style.Italic then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];

    if Style.Underline then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];

    if Style.StrikeOut then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsStrikeOut];

    if Style.Link then
    begin
      if Style.HasColor and (Style.Color <> clNone) then
        ACanvas.Font.Color := ApplyOpacity(Style.Color)
      else
        ACanvas.Font.Color := GetEffectiveLinkColor(FHoverLinkId = Style.LinkId);

      if GetEffectiveLinkUnderline(FHoverLinkId = Style.LinkId) then
        ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
    end
    else if Style.HasColor and (Style.Color <> clNone) then
    begin
      ACanvas.Font.Color := ApplyOpacity(Style.Color);
    end;

    if Style.Sup or Style.Sub then
    begin
      H := ACanvas.TextHeight('Ag');
      if H > 0 then
        ACanvas.Font.Height := -Round(H * 0.7);
    end;
  end;

  function BlockMargin(const Block: THtmlBlock; First: Boolean): Integer;
  begin
    Result := 0;

    if First then
      Exit;

    case Block.Kind of
      hbHeading:
      begin
        case Block.Level of
          1: Result := Round(BaseHeight * 0.7);
          2: Result := Round(BaseHeight * 0.6);
          3: Result := Round(BaseHeight * 0.5);
        else
          Result := Round(BaseHeight * 0.4);
        end;
      end;

      hbParagraph:
        Result := Round(BaseHeight * 0.5);

      hbPre, hbXmp:
        Result := Round(BaseHeight * 0.4);

      hbHr:
        Result := Round(BaseHeight * 0.4);

      hbListItem:
        Result := Round(BaseHeight * 0.2);
    end;
  end;

  procedure DrawHrBlock;
  begin
    if not MeasureOnly then
    begin
      ACanvas.Pen.Color := BaseFont.Color;
      ACanvas.Pen.Width := 1;
      ACanvas.Pen.Style := psSolid;

      ACanvas.MoveTo(ARect.Left, Y + 1);
      ACanvas.LineTo(ARect.Right, Y + 1);
    end;

    Y := Y + 3;
  end;

  procedure DrawInlineBlock(const Block: THtmlBlock);
  var
    Line: array of THtmlWord;
    LineWidth: Integer;
    PendingSpace: Boolean;
    ContentDrawn: Boolean;
    RunIndex: Integer;
    EffectiveAlign: TCssTextAlign;

    IndentWidth: Integer;
    BulletWidth: Integer;
    ContentWidth: Integer;
    BulletDrawn: Boolean;

    procedure FlushLine(Force: Boolean);
    var
      I, X, LineH, H, Offset: Integer;
      StartX, ContentRight: Integer;
    begin
      if (Length(Line) = 0) and (not Force) then
        Exit;

      LineH := 0;

      for I := 0 to High(Line) do
      begin
        SetupFont(Block, Line[I].Style);
        H := ACanvas.TextHeight('Ag');
        if H > LineH then
          LineH := H;
      end;

      if LineH = 0 then
        LineH := BaseHeight;

      if not MeasureOnly then
      begin
        EffectiveAlign := FTextAlign;
        if Block.HasAlign then
          EffectiveAlign := Block.Align;

        if Block.Kind = hbListItem then
        begin
          if not BulletDrawn and (Block.ListBullet <> '') then
          begin
            ACanvas.Font.Assign(BaseFont);
            H := ACanvas.TextHeight('Ag');
            Offset := (LineH - H) div 2;

            DrawTextWithShadow(
              Block.ListBullet,
              ARect.Left + IndentWidth,
              Y + Offset
            );

            BulletDrawn := True;
          end;

          StartX := ARect.Left + IndentWidth + BulletWidth;
          ContentRight := StartX + ContentWidth;

          if EffectiveAlign = ctaCenter then
            X := StartX + (ContentWidth - LineWidth) div 2
          else if EffectiveAlign = ctaRight then
            X := ContentRight - LineWidth
          else
            X := StartX;
        end
        else
        begin
          if EffectiveAlign = ctaCenter then
            X := ARect.Left + (ARect.Width - LineWidth) div 2
          else if EffectiveAlign = ctaRight then
            X := ARect.Right - LineWidth
          else
            X := ARect.Left;
        end;

        for I := 0 to High(Line) do
        begin
          SetupFont(Block, Line[I].Style);

          if (I > 0) and Line[I].SpaceBefore then
            X := X + ACanvas.TextWidth(' ');

          H := ACanvas.TextHeight('Ag');
          Offset := (LineH - H) div 2;

          if Line[I].Style.Sup then
            Offset := Offset - Round(LineH * 0.25)
          else if Line[I].Style.Sub then
            Offset := Offset + Round(LineH * 0.15);

          if Line[I].Style.Link then
          begin
            AddLinkArea(
              Line[I].Style.LinkId,
              Line[I].Style.Href,
              Rect(X, Y + Offset, X + Line[I].Width, Y + Offset + H)
            );
          end;

          DrawTextWithShadow(Line[I].Text, X, Y + Offset);

          X := X + Line[I].Width;
        end;
      end;

      Y := Y + LineH + 1;
      ContentDrawn := True;
      Line := nil;
      LineWidth := 0;
    end;

    procedure AddWord(
      const S: string;
      const Style: THtmlInlineStyle;
      SpaceBefore: Boolean);
    var
      W, AddW: Integer;
      HasPrev: Boolean;
    begin
      if S = '' then
        Exit;

      SetupFont(Block, Style);
      W := ACanvas.TextWidth(S);

      HasPrev := Length(Line) > 0;
      SpaceBefore := SpaceBefore and HasPrev;

      AddW := W;
      if SpaceBefore then
        AddW := AddW + ACanvas.TextWidth(' ');

      if (ContentWidth > 0) and
         (LineWidth + AddW > ContentWidth) and
         HasPrev then
      begin
        FlushLine(False);
        SpaceBefore := False;
      end;

      SetLength(Line, Length(Line) + 1);

      Line[High(Line)].Text := S;
      Line[High(Line)].Style := Style;
      Line[High(Line)].Width := W;
      Line[High(Line)].SpaceBefore := SpaceBefore;

      if SpaceBefore then
        LineWidth := LineWidth + ACanvas.TextWidth(' ');

      LineWidth := LineWidth + W;
    end;

    procedure ProcessNormalText(const S: string; const Style: THtmlInlineStyle);
    var
      I, Start: Integer;
    begin
      I := 1;
      while I <= Length(S) do
      begin
        if S[I] = #10 then
        begin
          FlushLine(True);
          PendingSpace := False;
          Inc(I);
        end
        else if (S[I] = ' ') or (S[I] = #9) or (S[I] = #13) then
        begin
          PendingSpace := True;
          Inc(I);
        end
        else
        begin
          Start := I;
          while (I <= Length(S)) and
                not ((S[I] = ' ') or (S[I] = #9) or
                     (S[I] = #13) or (S[I] = #10)) do
          begin
            Inc(I);
          end;

          AddWord(Copy(S, Start, I - Start), Style, PendingSpace);
          PendingSpace := False;
        end;
      end;
    end;

  begin
    Line := nil;
    LineWidth := 0;
    PendingSpace := False;
    ContentDrawn := False;

    IndentWidth := 0;
    BulletWidth := 0;
    ContentWidth := ARect.Width;
    BulletDrawn := False;

    if Block.Kind = hbListItem then
    begin
      IndentWidth := Block.ListIndent * Round(BaseHeight * 1.2);

      ACanvas.Font.Assign(BaseFont);
      BulletWidth := ACanvas.TextWidth(Block.ListBullet);

      ContentWidth := ARect.Width - IndentWidth - BulletWidth;
      if ContentWidth < 10 then
        ContentWidth := 10;
    end;

    for RunIndex := 0 to High(Block.Runs) do
      ProcessNormalText(Block.Runs[RunIndex].Text, Block.Runs[RunIndex].Style);

    if (Block.Kind = hbListItem) and (not ContentDrawn) then
      FlushLine(True)
    else
      FlushLine(False);

    if not ContentDrawn then
    begin
      Y := Y + BaseHeight;
      ContentDrawn := True;
    end;
  end;

  procedure DrawPreBlock(const Block: THtmlBlock);
  var
    X, LineH, H, Offset: Integer;
    RunIndex: Integer;
    S, Part: string;
    P: Integer;
    CurrentStyle: THtmlInlineStyle;

    procedure DrawPrePart(const ATextPart: string; const Style: THtmlInlineStyle);
    var
      W: Integer;
    begin
      if ATextPart = '' then
        Exit;

      SetupFont(Block, Style);

      H := ACanvas.TextHeight('Ag');
      if H > LineH then
        LineH := H;

      Offset := (LineH - H) div 2;

      if Style.Sup then
        Offset := Offset - Round(LineH * 0.25)
      else if Style.Sub then
        Offset := Offset + Round(LineH * 0.15);

      W := ACanvas.TextWidth(ATextPart);

      if Style.Link then
      begin
        AddLinkArea(
          Style.LinkId,
          Style.Href,
          Rect(X, Y + Offset, X + W, Y + Offset + H)
        );
      end;

      DrawTextWithShadow(ATextPart, X, Y + Offset);

      X := X + W;
    end;

    procedure NewPreLine;
    begin
      Y := Y + LineH + 1;
      X := ARect.Left;

      SetupFont(Block, EmptyHtmlInlineStyle);
      LineH := ACanvas.TextHeight('Ag');
    end;

  begin
    X := ARect.Left;

    SetupFont(Block, EmptyHtmlInlineStyle);
    LineH := ACanvas.TextHeight('Ag');

    for RunIndex := 0 to High(Block.Runs) do
    begin
      CurrentStyle := Block.Runs[RunIndex].Style;
      S := Block.Runs[RunIndex].Text;

      while True do
      begin
        P := Pos(#10, S);

        if P = 0 then
        begin
          DrawPrePart(S, CurrentStyle);
          Break;
        end;

        Part := Copy(S, 1, P - 1);
        DrawPrePart(Part, CurrentStyle);

        S := Copy(S, P + 1, MaxInt);

        NewPreLine;
      end;
    end;

    Y := Y + LineH + 1;
  end;

begin
  SavedColor := ACanvas.Font.Color;

  AssignCssFontToFont(ACanvas.Font);

  if (SavedColor = clNone) or (SavedColor = clDefault) then
    SavedColor := GetEffectiveTextColor;

  ACanvas.Font.Color := SavedColor;

  // Reset only the style, not the color.
  ACanvas.Font.Style := [];

  FLinkAreas := nil;
  FLinkInfos := nil;

  if Trim(AText) = '' then
    Exit;

  ParseHtmlBlocks(AText, Blocks, FLinkInfos);

  if Length(Blocks) = 0 then
    Exit;

  BaseFont := TFont.Create;

  try
    BaseFont.Assign(ACanvas.Font);

    BaseHeight := ACanvas.TextHeight('Ag');
    if BaseHeight <= 0 then
      BaseHeight := 14;

    TS := ACanvas.TextStyle;

    TS.Alignment := taLeftJustify;
    TS.Layout := tlTop;
    TS.Wordbreak := False;
    TS.Clipping := True;
    TS.Opaque := False;
    TS.ShowPrefix := False;

    ACanvas.Brush.Style := bsClear;

    // First pass: measure height only.
    MeasureOnly := True;
    Y := 0;
    FirstBlock := True;

    for BlockIndex := 0 to High(Blocks) do
    begin
      Y := Y + BlockMargin(Blocks[BlockIndex], FirstBlock);

      case Blocks[BlockIndex].Kind of
        hbHr:
          DrawHrBlock;

        hbPre, hbXmp:
          DrawPreBlock(Blocks[BlockIndex]);
      else
        DrawInlineBlock(Blocks[BlockIndex]);
      end;

      FirstBlock := False;
    end;

    TotalHeight := Y;

    // Determine the starting position from vertical-align.
    case GetCssVAlign of
      cvaMiddle:
      begin
        if TotalHeight < ARect.Height then
          StartY := ARect.Top + (ARect.Height - TotalHeight) div 2
        else
          StartY := ARect.Top;
      end;

      cvaBottom:
      begin
        if TotalHeight < ARect.Height then
          StartY := ARect.Top + (ARect.Height - TotalHeight)
        else
          StartY := ARect.Top;
      end;
    else
      StartY := ARect.Top;
    end;

    // Second pass: actual rendering.
    MeasureOnly := False;
    Y := StartY;
    FirstBlock := True;

    for BlockIndex := 0 to High(Blocks) do
    begin
      Y := Y + BlockMargin(Blocks[BlockIndex], FirstBlock);

      case Blocks[BlockIndex].Kind of
        hbHr:
          DrawHrBlock;

        hbPre, hbXmp:
          DrawPreBlock(Blocks[BlockIndex]);
      else
        DrawInlineBlock(Blocks[BlockIndex]);
      end;

      FirstBlock := False;

      if Y > ARect.Bottom then
        Break;
    end;
  finally
    BaseFont.Free;
  end;
end;

procedure TCssStyledControl.DrawHtmlText(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AText: string;
  ADefaultTextColor: TColor);
var
  SavedColor: TColor;
begin
  SavedColor := ACanvas.Font.Color;

  if ADefaultTextColor = clNone then
    ADefaultTextColor := clWindowText;

  if ADefaultTextColor = clDefault then
    ADefaultTextColor := GetCssTextColor;

  ACanvas.Font.Color := ApplyOpacity(ADefaultTextColor);
  try
    DrawHtmlText(ACanvas, ARect, AText);
  finally
    ACanvas.Font.Color := SavedColor;
  end;
end;

procedure TCssStyledControl.DrawHtmlTextWithAlign(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AText: string;
  AAlign: TCssTextAlign;
  AVAlign: TCssVAlign);
var
  OldAlign: TCssTextAlign;
  OldVAlign: TCssVAlign;
  SavedColor: TColor;
begin
  OldAlign := FTextAlign;
  OldVAlign := FVAlign;

  FTextAlign := AAlign;
  FVAlign := AVAlign;

  SavedColor := ACanvas.Font.Color;
  ACanvas.Font.Color := GetEffectiveTextColor;
  try
    DrawHtmlText(ACanvas, ARect, AText);
  finally
    ACanvas.Font.Color := SavedColor;
    FTextAlign := OldAlign;
    FVAlign := OldVAlign;
  end;
end;

procedure TCssStyledControl.DrawHtmlTextWithAlign(
  ACanvas: TCanvas;
  const ARect: TRect;
  const AText: string;
  AAlign: TCssTextAlign;
  AVAlign: TCssVAlign;
  ADefaultTextColor: TColor);
var
  OldAlign: TCssTextAlign;
  OldVAlign: TCssVAlign;
  SavedColor: TColor;
begin
  OldAlign := FTextAlign;
  OldVAlign := FVAlign;

  FTextAlign := AAlign;
  FVAlign := AVAlign;

  SavedColor := ACanvas.Font.Color;

  if ADefaultTextColor = clNone then
    ADefaultTextColor := clWindowText;

  if ADefaultTextColor = clDefault then
    ADefaultTextColor := GetCssTextColor;

  ACanvas.Font.Color := ApplyOpacity(ADefaultTextColor);
  try
    DrawHtmlText(ACanvas, ARect, AText);
  finally
    ACanvas.Font.Color := SavedColor;
    FTextAlign := OldAlign;
    FVAlign := OldVAlign;
  end;
end;

procedure TCssStyledControl.BlendCoverageToCanvas(
  ACanvas: TCanvas;
  ALeft, ATop, AWidth, AHeight: Integer;
  const ACoverage: array of Byte;
  AColor: TColor);
var
  X, Y, Idx: Integer;
  Cov, InvCov: Double;
  LineRGB, BgRGB: TColor;
  LR, LG, LB: Byte;
  BR, BG, BB: Byte;
  R, G, B: Integer;
  DstColor: TColor;
begin
  if ACanvas = nil then Exit;
  if (AWidth <= 0) or (AHeight <= 0) then Exit;
  if Length(ACoverage) < AWidth * AHeight then Exit;

  LineRGB := ColorToRGB(AColor);
  LR := Byte(LineRGB and $FF);
  LG := Byte((LineRGB shr 8) and $FF);
  LB := Byte((LineRGB shr 16) and $FF);

  for Y := 0 to AHeight - 1 do
    for X := 0 to AWidth - 1 do
    begin
      Idx := Y * AWidth + X;
      if ACoverage[Idx] = 0 then
        Continue;

      Cov := ACoverage[Idx] / 255.0;
      InvCov := 1.0 - Cov;

      DstColor := ACanvas.Pixels[ALeft + X, ATop + Y];
      BgRGB := ColorToRGB(DstColor);
      BR := Byte(BgRGB and $FF);
      BG := Byte((BgRGB shr 8) and $FF);
      BB := Byte((BgRGB shr 16) and $FF);

      R := Round(LR * Cov + BR * InvCov);
      G := Round(LG * Cov + BG * InvCov);
      B := Round(LB * Cov + BB * InvCov);

      ACanvas.Pixels[ALeft + X, ATop + Y] := RGBToColor(R, G, B);
    end;
end;

procedure TCssStyledControl.Paint;
var
  R, DrawR, TextR: TRect;
  BG: TColor;
  BorderVisible: Boolean;
  Radii: TCssCornerRadii;
  Params: TCssRoundedBoxParams;
  NeedAA: Boolean;
begin
  R := ClientRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
  begin
    inherited Paint;
    Exit;
  end;

  if FHasBackground then
    BG := FBackground
  else
    BG := Color;

  if BG = clDefault then
    BG := clBtnFace;

  BorderVisible := (FBorderStyle <> cbsNone) and (FBorderWidth > 0);
  Radii := GetCssBorderRadii;

  NeedAA :=
    (Radii.TL > 0) or (Radii.TR > 0) or (Radii.BR > 0) or (Radii.BL > 0) or
    FBoxShadow.Used or
    (FBackgroundGradient.Kind <> cgkNone);

  if NeedAA then
  begin
    DrawR := R;
    DrawR.Top := DrawR.Top + GetBorderTopOffset;

    Params.Radii := Radii;
    Params.FillColor := BG;
    Params.BorderColor := ApplyOpacity(FBorderColor);
    Params.BorderWidth := FBorderWidth;
    Params.BorderStyle := FBorderStyle;
    Params.Shadow := FBoxShadow;
    Params.Gradient := FBackgroundGradient;
    Params.HasGradient := FBackgroundGradient.Kind <> cgkNone;
    Params.CornerBackColor[0] := GetBackgroundBeneathAtClientPoint(Point(R.Left, R.Top));
    Params.CornerBackColor[1] := GetBackgroundBeneathAtClientPoint(Point(R.Right - 1, R.Top));
    Params.CornerBackColor[2] := GetBackgroundBeneathAtClientPoint(Point(R.Right - 1, R.Bottom - 1));
    Params.CornerBackColor[3] := GetBackgroundBeneathAtClientPoint(Point(R.Left, R.Bottom - 1));

    DrawRoundedRectAA(Canvas, DrawR, Params);
  end
  else
  begin
    if BG = clNone then
      BG := GetParentBackgroundColor;

    if BG <> clNone then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := BG;
      Canvas.FillRect(R);
    end;

    if BorderVisible then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Width := FBorderWidth;
      Canvas.Pen.Color := ApplyOpacity(FBorderColor);
      Canvas.Pen.Style := GetBorderPenStyle;

      DrawR := R;
      DrawR.Top := DrawR.Top + GetBorderTopOffset;

      if FBorderWidth > 1 then
        InflateRect(DrawR, -(FBorderWidth div 2), -(FBorderWidth div 2));

      Canvas.Rectangle(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom);
    end;
  end;

  TextR := R;

  TextR.Left   := TextR.Left   + FBorderWidth + FPadding.Left;
  TextR.Top    := TextR.Top    + FBorderWidth + FPadding.Top;
  TextR.Right  := TextR.Right  - FBorderWidth - FPadding.Right;
  TextR.Bottom := TextR.Bottom - FBorderWidth - FPadding.Bottom;

  if (TextR.Right > TextR.Left) and (TextR.Bottom > TextR.Top) then
  begin
    UpdateCanvasFont;
    if ShouldPaintCaption then
    begin
      if FHtmlMode then
        DrawHtmlText(TextR, Caption)
      else
        DrawStyledText(TextR, Caption);
    end;
  end;

  inherited Paint;
end;

procedure TCssStyledControl.ChangeBounds(
  ALeft, ATop, AWidth, AHeight: Integer;
  KeepBase: Boolean);
var
  OldBounds: TRect;
begin
  OldBounds := BoundsRect;
  inherited ChangeBounds(ALeft, ATop, AWidth, AHeight, KeepBase);
  NotifyUpperSiblingsRepaint(@OldBounds);
end;

{ ============================================================ }
{ TCssStyledControl — HTML measuring                           }
{ ============================================================ }

function TCssStyledControl.MeasureHtmlTextSize(
  ACanvas: TCanvas;
  const AText: string;
  AvailableWidth: Integer): TSize;
var
  Blocks: THtmlBlocks;
  BaseFont: TFont;
  BaseHeight: Integer;
  FirstBlock: Boolean;
  TotalHeight: Integer;
  MaxWidth: Integer;
  BlockIndex: Integer;
  S: TSize;

  procedure SetupMeasureFont(
    const Block: THtmlBlock;
    const Style: THtmlInlineStyle);
  var
    Scale: Double;
    H: Integer;
  begin
    ACanvas.Font.Assign(BaseFont);

    if (Block.Kind = hbPre) or Style.Mono then
      ACanvas.Font.Name := FMonospaceFontName;

    if Block.Kind = hbHeading then
    begin
      case Block.Level of
        1: Scale := 1.7;
        2: Scale := 1.5;
        3: Scale := 1.3;
        4: Scale := 1.2;
        5: Scale := 1.1;
      else
        Scale := 1.0;
      end;

      ACanvas.Font.Height := -Round(BaseHeight * Scale);
      ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
    end;

    if Style.Bold then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];

    if Style.Italic then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];

    if Style.Underline then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];

    if Style.StrikeOut then
      ACanvas.Font.Style := ACanvas.Font.Style + [fsStrikeOut];

    if Style.Sup or Style.Sub then
    begin
      H := ACanvas.TextHeight('Ag');

      if H > 0 then
        ACanvas.Font.Height := -Round(H * 0.7);
    end;
  end;

  function MeasureBlockMargin(
    const Block: THtmlBlock;
    First: Boolean): Integer;
  begin
    Result := 0;

    if First then
      Exit;

    case Block.Kind of
      hbHeading:
      begin
        case Block.Level of
          1: Result := Round(BaseHeight * 0.7);
          2: Result := Round(BaseHeight * 0.6);
          3: Result := Round(BaseHeight * 0.5);
        else
          Result := Round(BaseHeight * 0.4);
        end;
      end;

      hbParagraph:
        Result := Round(BaseHeight * 0.5);

      hbPre, hbXmp:
        Result := Round(BaseHeight * 0.4);

      hbHr:
        Result := Round(BaseHeight * 0.4);

      hbListItem:
        Result := Round(BaseHeight * 0.2);
    end;
  end;

  function MeasureInlineBlock(const Block: THtmlBlock): TSize;
  var
    LineWidth: Integer;
    LineHeight: Integer;
    MaxLineW: Integer;
    TotalH: Integer;
    PendingSpace: Boolean;
    RunIndex: Integer;

    IndentWidth: Integer;
    BulletWidth: Integer;
    ContentWidth: Integer;

    procedure BreakLine(Force: Boolean);
    var
      EffectiveW: Integer;
    begin
      if (LineWidth > 0) or Force then
      begin
        EffectiveW := LineWidth;

        if Block.Kind = hbListItem then
          EffectiveW := IndentWidth + BulletWidth + LineWidth;

        if EffectiveW > MaxLineW then
          MaxLineW := EffectiveW;

        if LineHeight = 0 then
          LineHeight := BaseHeight;

        TotalH := TotalH + LineHeight + 1;

        LineWidth := 0;
        LineHeight := 0;
      end;

      PendingSpace := False;
    end;

    procedure AddWord(
      const Word: string;
      const Style: THtmlInlineStyle;
      SpaceBefore: Boolean);
    var
      W, SpaceW, AddW, H: Integer;
    begin
      if Word = '' then
        Exit;

      SetupMeasureFont(Block, Style);

      W := ACanvas.TextWidth(Word);
      H := ACanvas.TextHeight('Ag');

      AddW := W;

      if SpaceBefore and (LineWidth > 0) then
      begin
        SpaceW := ACanvas.TextWidth(' ');
        AddW := AddW + SpaceW;
      end;

      if (ContentWidth > 0) and
         (LineWidth > 0) and
         (LineWidth + AddW > ContentWidth) then
      begin
        BreakLine(False);
      end;

      if SpaceBefore and (LineWidth > 0) then
        LineWidth := LineWidth + ACanvas.TextWidth(' ');

      LineWidth := LineWidth + W;

      if H > LineHeight then
        LineHeight := H;
    end;

    procedure ProcessText(
      const S: string;
      const Style: THtmlInlineStyle);
    var
      I, StartPos: Integer;
    begin
      I := 1;
      while I <= Length(S) do
      begin
        if S[I] = #10 then
        begin
          BreakLine(True);
          Inc(I);
        end
        else if (S[I] = ' ') or (S[I] = #9) or (S[I] = #13) then
        begin
          PendingSpace := True;
          Inc(I);
        end
        else
        begin
          StartPos := I;
          while (I <= Length(S)) and
                not ((S[I] = ' ') or (S[I] = #9) or
                     (S[I] = #13) or (S[I] = #10)) do
          begin
            Inc(I);
          end;

          AddWord(Copy(S, StartPos, I - StartPos), Style, PendingSpace);
          PendingSpace := False;
        end;
      end;
    end;

  begin
    IndentWidth := 0;
    BulletWidth := 0;
    ContentWidth := AvailableWidth;

    if Block.Kind = hbListItem then
    begin
      IndentWidth := Block.ListIndent * Round(BaseHeight * 1.2);

      ACanvas.Font.Assign(BaseFont);
      BulletWidth := ACanvas.TextWidth(Block.ListBullet);

      if AvailableWidth > 0 then
      begin
        ContentWidth := AvailableWidth - IndentWidth - BulletWidth;
        if ContentWidth < 10 then
          ContentWidth := 10;
      end;
    end;

    LineWidth := 0;
    LineHeight := 0;
    MaxLineW := 0;
    TotalH := 0;
    PendingSpace := False;

    for RunIndex := 0 to High(Block.Runs) do
    begin
      ProcessText(
        Block.Runs[RunIndex].Text,
        Block.Runs[RunIndex].Style
      );
    end;

    BreakLine(False);

    if TotalH = 0 then
    begin
      TotalH := BaseHeight;

      if Block.Kind = hbListItem then
        MaxLineW := IndentWidth + BulletWidth;
    end;

    Result.cx := MaxLineW;
    Result.cy := TotalH;
  end;

  function MeasurePreBlock(const Block: THtmlBlock): TSize;
  var
    RunIndex: Integer;
    S, Line: string;
    P: Integer;
    W, H: Integer;
  begin
    Result.cx := 0;
    Result.cy := 0;

    for RunIndex := 0 to High(Block.Runs) do
    begin
      S := Block.Runs[RunIndex].Text;

      if S = '' then
        Continue;

      SetupMeasureFont(Block, Block.Runs[RunIndex].Style);

      while True do
      begin
        P := Pos(#10, S);

        if P = 0 then
        begin
          Line := S;

          W := ACanvas.TextWidth(Line);
          H := ACanvas.TextHeight('Ag');

          if W > Result.cx then
            Result.cx := W;

          Result.cy := Result.cy + H + 1;

          Break;
        end;

        Line := Copy(S, 1, P - 1);

        W := ACanvas.TextWidth(Line);
        H := ACanvas.TextHeight('Ag');

        if W > Result.cx then
          Result.cx := W;

        Result.cy := Result.cy + H + 1;

        S := Copy(S, P + 1, MaxInt);
      end;
    end;

    if Result.cy = 0 then
      Result.cy := BaseHeight;
  end;

begin
  Result.cx := 0;
  Result.cy := 0;

  if Trim(AText) = '' then
    Exit;

  ParseHtmlBlocks(AText, Blocks);

  if Length(Blocks) = 0 then
    Exit;

  AssignCssFontToFont(ACanvas.Font);

  BaseFont := TFont.Create;

  try
    BaseFont.Assign(ACanvas.Font);

    BaseHeight := ACanvas.TextHeight('Ag');

    if BaseHeight <= 0 then
      BaseHeight := 14;

    TotalHeight := 0;
    MaxWidth := 0;
    FirstBlock := True;

    for BlockIndex := 0 to High(Blocks) do
    begin
      TotalHeight := TotalHeight +
        MeasureBlockMargin(Blocks[BlockIndex], FirstBlock);

      case Blocks[BlockIndex].Kind of
        hbHr:
        begin
          TotalHeight := TotalHeight + 3;

          S.cx := 0;
          S.cy := 0;

          if MaxWidth < 1 then
            MaxWidth := 1;
        end;

        hbPre, hbXmp:
        begin
          S := MeasurePreBlock(Blocks[BlockIndex]);
        end;
      else
        S := MeasureInlineBlock(Blocks[BlockIndex]);
      end;

      TotalHeight := TotalHeight + S.cy;

      if S.cx > MaxWidth then
        MaxWidth := S.cx;

      FirstBlock := False;
    end;

    Result.cx := MaxWidth;
    Result.cy := TotalHeight;
  finally
    BaseFont.Free;
  end;
end;

function TCssStyledControl.MeasureHtmlTextSize(
  const AText: string;
  AvailableWidth: Integer): TSize;
begin
  Result := MeasureHtmlTextSize(Canvas, AText, AvailableWidth);
end;

{ ============================================================ }
{ TCssStyledControl — link hit testing (public API)            }
{ ============================================================ }

function TCssStyledControl.TryGetLinkAt(
  const P: TPoint;
  out AHref, AText: string): Boolean;
var
  Idx: Integer;
  Info: TCssHtmlLinkInfo;
begin
  Result := False;
  AHref := '';
  AText := '';

  Idx := LinkAt(P);
  if Idx < 0 then
    Exit;

  AHref := FLinkAreas[Idx].Href;
  Info := GetLinkInfoById(FLinkAreas[Idx].LinkId);
  AText := Info.Text;

  Result := True;
end;

procedure TCssStyledControl.ClickLinkAtPoint(const P: TPoint);
var
  Href, LText: string;
begin
  if TryGetLinkAt(P, Href, LText) then
    DoLinkClick(Href, LText);
end;

procedure TCssStyledControl.UpdateEnabledVisualState;
begin
  RefreshStylesByState;
  Invalidate;
end;

procedure TCssStyledControl.SetExternalHoverState(AHover: Boolean);
var
  WasHovered: Boolean;
begin
  if csDestroying in ComponentState then
    Exit;

  WasHovered := GetEffectiveHoverState;

  if AHover then
    Inc(FExternalHoverCount)
  else if FExternalHoverCount > 0 then
    Dec(FExternalHoverCount);

  if WasHovered <> GetEffectiveHoverState then
  begin
    RefreshStylesByState;
    Invalidate;
  end;
end;

procedure TCssStyledControl.SetExternalCornerSource(ABitmap : TBitmap; const AOrigin : TPoint);
begin
  FExternalCornerBitmap := ABitmap;
  FExternalCornerOrigin := AOrigin;
end;

{ ============================================================ }
{ TCssStyleProvider                                            }
{ ============================================================ }

constructor TCssStyleProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FStyles := TStringList.Create;
  FControls := TList.Create;

  FDefaultStyleName := 'default';
end;

destructor TCssStyleProvider.Destroy;
begin
  FLoading := True;

  ClearStyles(True);

  FControls.Clear;

  FreeAndNil(FStyles);
  FreeAndNil(FControls);

  inherited Destroy;
end;

procedure TCssStyleProvider.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent is TCssStyledControl) then
    UnRegisterControl(TCssStyledControl(AComponent));
end;

procedure TCssStyleProvider.InvalidateRawCss;
begin
  if not FApplyingCssText then
    FRawCssText := '';
end;

function TCssStyleProvider.HasCssContent(const AText: string): Boolean;
begin
  Result := Trim(RemoveCssComments(AText)) <> '';
end;

function TCssStyleProvider.SerializeStylesToCss: string;
var
  I: Integer;
  L: TStringList;
  DefaultName: string;
begin
  Result := '';

  if FStyles.Count = 0 then
    Exit;

  DefaultName := Trim(FDefaultStyleName);
  if DefaultName = '' then
    DefaultName := 'default';

  // If there is only one style and it is the current default style,
  // we can return it without the service @variant marker.
  if (FStyles.Count = 1) and SameText(FStyles[0], DefaultName) then
  begin
    Result := TStringList(FStyles.Objects[0]).Text;
    Exit;
  end;

  L := TStringList.Create;
  try
    for I := 0 to FStyles.Count - 1 do
    begin
      L.Add('@variant ' + FStyles[I]);
      L.Add(TStringList(FStyles.Objects[I]).Text);

      if I < FStyles.Count - 1 then
        L.Add('');
    end;

    Result := L.Text;
  finally
    L.Free;
  end;
end;

function TCssStyleProvider.GetStyleCount: Integer;
begin
  Result := FStyles.Count;
end;

function TCssStyleProvider.GetStyleName(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FStyles.Count) then
    Result := FStyles[Index]
  else
    Result := '';
end;

function TCssStyleProvider.IndexOfStyle(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to FStyles.Count - 1 do
  begin
    if SameText(FStyles[I], AName) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssStyleProvider.HasStyle(const AName: string): Boolean;
begin
  Result := IndexOfStyle(AName) >= 0;
end;

procedure TCssStyleProvider.ClearStyles(Silent: Boolean);
var
  I: Integer;
begin
  InvalidateRawCss;

  for I := 0 to FStyles.Count - 1 do
    FStyles.Objects[I].Free;

  FStyles.Clear;

  if not Silent then
    DoChange;
end;

procedure TCssStyleProvider.Clear;
begin
  ClearStyles(False);
end;

procedure TCssStyleProvider.AddOrUpdateStyle(const AName, ACss: string);
var
  LName: string;
  Idx: Integer;
  List: TStringList;
begin
  InvalidateRawCss;

  LName := Trim(AName);
  if LName = '' then
    LName := FDefaultStyleName;
  if LName = '' then
    LName := 'default';

  Idx := IndexOfStyle(LName);

  if Idx < 0 then
  begin
    List := TStringList.Create;
    FStyles.AddObject(LName, List);
  end
  else
  begin
    List := TStringList(FStyles.Objects[Idx]);
  end;

  List.Text := ACss;
  DoChange;
end;

procedure TCssStyleProvider.RemoveStyle(const AName: string);
var
  Idx: Integer;
begin
  InvalidateRawCss;

  Idx := IndexOfStyle(AName);
  if Idx >= 0 then
  begin
    FStyles.Objects[Idx].Free;
    FStyles.Delete(Idx);
    DoChange;
  end;
end;

function TCssStyleProvider.GetCss(const AName: string): string;
var
  Idx: Integer;
begin
  Idx := IndexOfStyle(AName);

  if Idx >= 0 then
    Result := TStringList(FStyles.Objects[Idx]).Text
  else
    Result := '';
end;

procedure TCssStyleProvider.SetCss(const AName, ACss: string);
begin
  AddOrUpdateStyle(AName, ACss);
end;

function TCssStyleProvider.GetCssText: string;
begin
  if FRawCssText <> '' then
    Result := FRawCssText
  else
    Result := SerializeStylesToCss;
end;

procedure TCssStyleProvider.SetCssText(const AValue: string);
begin
  FRawCssText := AValue;

  FApplyingCssText := True;
  try
    LoadFromCss(AValue);
  finally
    FApplyingCssText := False;
  end;
end;

procedure TCssStyleProvider.SetDefaultStyleName(const AValue: string);
begin
  if FDefaultStyleName = AValue then
    Exit;

  FDefaultStyleName := AValue;

  DoChange;
end;

procedure TCssStyleProvider.SetFileName(const AValue: string);
begin
  if FFileName = AValue then
    Exit;

  FFileName := AValue;

  if (FFileName <> '') and FileExists(FFileName) then
    LoadFromFile(FFileName);
end;

function TCssStyleProvider.GetCssForControl(const AStyleName: string): string;
var
  LName: string;
begin
  Result := '';

  LName := Trim(AStyleName);

  if LName <> '' then
  begin
    Result := GetCss(LName);
    if Result <> '' then
      Exit;
  end;

  if FDefaultStyleName <> '' then
  begin
    Result := GetCss(FDefaultStyleName);
    if Result <> '' then
      Exit;
  end;

  if FStyles.Count > 0 then
    Result := TStringList(FStyles.Objects[0]).Text
  else
    Result := '';
end;

function TCssStyleProvider.IsVariantLine(const ALine: string; out AName: string): Boolean;
var
  S: string;
begin
  Result := False;
  AName := '';

  S := Trim(ALine);

  if S = '' then
    Exit;

  if LowerCase(Copy(S, 1, 8)) = '@variant' then
  begin
    AName := Trim(Copy(S, 9, MaxInt));
    Result := AName <> '';
    Exit;
  end;

  if (S[1] = '[') and (S[Length(S)] = ']') then
  begin
    AName := Trim(Copy(S, 2, Length(S) - 2));
    Result := AName <> '';
  end;
end;

procedure TCssStyleProvider.LoadFromStrings(const AStrings: TStrings);
var
  I: Integer;
  Line, VariantName, CurrentName: string;
  CurrentCss: TStringList;
begin
  FLoading := True;

  try
    ClearStyles(True);

    CurrentName := FDefaultStyleName;
    if CurrentName = '' then
      CurrentName := 'default';

    CurrentCss := TStringList.Create;

    try
      for I := 0 to AStrings.Count - 1 do
      begin
        Line := AStrings[I];

        if IsVariantLine(Line, VariantName) then
        begin
          if HasCssContent(CurrentCss.Text) then
            AddOrUpdateStyle(CurrentName, CurrentCss.Text);

          CurrentName := VariantName;
          CurrentCss.Clear;
        end
        else
        begin
          CurrentCss.Add(Line);
        end;
      end;

      if HasCssContent(CurrentCss.Text) then
        AddOrUpdateStyle(CurrentName, CurrentCss.Text);
    finally
      CurrentCss.Free;
    end;
  finally
    FLoading := False;
  end;

  DoChange;
end;

procedure TCssStyleProvider.LoadFromFile(const AFileName: string);
var
  L: TStringList;
begin
  FFileName := AFileName;

  L := TStringList.Create;

  try
    L.LoadFromFile(AFileName);
    LoadFromStrings(L);
  finally
    L.Free;
  end;
end;

procedure TCssStyleProvider.LoadFromCss(const ACss: string);
var
  L: TStringList;
begin
  L := TStringList.Create;

  try
    L.Text := ACss;
    LoadFromStrings(L);
  finally
    L.Free;
  end;
end;

procedure TCssStyleProvider.SaveToFile(const AFileName: string);
var
  L: TStringList;
  I: Integer;
begin
  L := TStringList.Create;

  try
    for I := 0 to FStyles.Count - 1 do
    begin
      L.Add('@variant ' + FStyles[I]);
      L.Add(TStringList(FStyles.Objects[I]).Text);
      L.Add('');
    end;

    L.SaveToFile(AFileName);

    FFileName := AFileName;
  finally
    L.Free;
  end;
end;

procedure TCssStyleProvider.RegisterControl(AControl: TCssStyledControl);
begin
  if FControls.IndexOf(AControl) < 0 then
    FControls.Add(AControl);
end;

procedure TCssStyleProvider.UnRegisterControl(AControl: TCssStyledControl);
var
  Idx: Integer;
begin
  Idx := FControls.IndexOf(AControl);

  if Idx >= 0 then
    FControls.Delete(Idx);
end;

procedure TCssStyleProvider.DoChange;
var
  I: Integer;
begin
  if FLoading or (csDestroying in ComponentState) then
    Exit;

  InvalidateRoundedRectCache;

  for I := FControls.Count - 1 downto 0 do
    TCssStyledControl(FControls[I]).ProviderStyleChanged;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

initialization

finalization
  FreeAndNil(GRoundedRectCache);
  FreeAndNil(GAA_TriangleCache);
end.

end.
