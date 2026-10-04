unit CssMemoControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, StdCtrls, LazUTF8,
  ExtCtrls, ClipBrd, LCLType, Forms, CssStyledControl, CssScrollControl;

type
  TCssMemo = class(TCssStyledControl)
  private
    // Lines
    FLines: TStringList;

    // Caret in "line / character in line" coordinates
    FCaretX, FCaretY: Integer;

    // Selection in absolute character offsets (-1..-1 = no selection)
    FSelStart, FSelEnd: Integer;
    FSelAnchor: Integer;

    // Scrolling
    FTopLine: Integer;
    FLeftPixel: Integer;

    // Behavior
    FWordWrap: Boolean;
    FReadOnly: Boolean;
    FScrollBars: TScrollStyle;

    // Scrollbars
    FVScroll: TCssScrollBar;
    FHScroll: TCssScrollBar;
    FMemoScrollBarCssClass: string;
    FMemoScrollBarCssStyle: string;

    // Caret blinking
    FCaretTimer: TTimer;
    FCaretVisible: Boolean;

    // Mouse selection
    FMouseSelecting: Boolean;

    // Internal state
    FUpdating: Boolean;

    // Events
    FOnChange: TNotifyEvent;

    // Editor CSS colors
    FSelBackground: TColor;
    FSelBackgroundSet: Boolean;
    FSelColor: TColor;
    FSelColorSet: Boolean;
    FCaretColor: TColor;
    FCaretColorSet: Boolean;

    // Placeholder
    FPlaceholder: string;
    FPlaceholderColor: TColor;
    FPlaceholderColorSet: Boolean;
    FPlaceholderAlign: TCssTextAlign;
    FPlaceholderAlignSet: Boolean;
    FPlaceholderVAlign: TCssVAlign;
    FPlaceholderVAlignSet: Boolean;
    FPlaceholderFontBold: Boolean;
    FPlaceholderFontBoldSet: Boolean;
    FPlaceholderFontItalic: Boolean;
    FPlaceholderFontItalicSet: Boolean;
    FPlaceholderFontUnderline: Boolean;
    FPlaceholderFontUnderlineSet: Boolean;
    FPlaceholderFontStrikeOut: Boolean;
    FPlaceholderFontStrikeOutSet: Boolean;

    // Property getters/setters
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetLines: TStrings;
    procedure SetLines(AValue: TStrings);
    procedure LinesChanged(Sender: TObject);

    procedure SetWordWrap(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetScrollBars(AValue: TScrollStyle);
    procedure SetMemoScrollBarCssClass(const AValue: string);
    procedure SetMemoScrollBarCssStyle(const AValue: string);

    procedure SetPlaceholder(const AValue: string);
    function GetPlaceholderColor: TColor;
    function GetPlaceholderAlign: TCssTextAlign;
    function GetPlaceholderVAlign: TCssVAlign;
    function IsTextEmpty: Boolean;

    function GetSelBackground: TColor;
    function GetSelColor: TColor;
    function GetCaretColor: TColor;

    // Caret/selection setters
    procedure SetCaretXY(AX, AY: Integer);
    procedure SetSelBounds(AStart, AEnd: Integer);

    // Geometry
    function GetTextRect: TRect;
    function LineHeight: Integer;
    function CharWidth: Integer;
    function VisibleLines: Integer;
    function VisibleChars: Integer;
    function GetMaxLineWidth: Integer;

    // Caret <-> offset conversions
    function OffsetToCaret(AOffset: Integer; out AX, AY: Integer): Boolean;
    function CaretToOffset(AX, AY: Integer): Integer;
    function PointToCaret(X, Y: Integer; out AX, AY: Integer): Boolean;

    // Word navigation
    function IsWordChar(const Ch: string): Boolean;
    procedure CalcWordLeft(AX, AY: Integer; out NewX, NewY: Integer);
    procedure CalcWordRight(AX, AY: Integer; out NewX, NewY: Integer);

    // Scrolling
    procedure EnsureCaretVisible;
    procedure UpdateScrollBars;
    procedure VScrollChanged(Sender: TObject);
    procedure HScrollChanged(Sender: TObject);
    procedure ApplyScrollBarStyle;

    // Caret blinking
    procedure CaretTimerTick(Sender: TObject);
    procedure ShowCaretNow;

    // Editing
    procedure InsertTextAtCaret(const S: string);
    procedure DeleteSelection;
    procedure DeleteCharAtCaret(Backward: Boolean);
    procedure InsertLineBreak;

    // Clipboard
    function GetSelectionText: string;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;

    // Change notification
    procedure DoChange;
  protected
    // Initialization and style
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Painting
    procedure Paint; override;

    // State
    procedure EnabledChanged; override;

    // Sizing
    procedure Resize; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure UTF8KeyPress(var Key: TUTF8Char); override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure MouseLeave; override;

    // Focus
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Text operations
    procedure Clear;
    procedure SelectAll;

    property SelStart: Integer read FSelStart;
    property SelEnd: Integer read FSelEnd;
    property SelectionText: string read GetSelectionText;
  published
    // Text
    property Lines: TStrings read GetLines write SetLines;
    property Text: string read GetText write SetText;
    property Placeholder: string read FPlaceholder write SetPlaceholder;

    // Behavior
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars default ssNone;
    property MemoScrollBarCssClass: string read FMemoScrollBarCssClass write SetMemoScrollBarCssClass;
    property MemoScrollBarCssStyle: string read FMemoScrollBarCssStyle write SetMemoScrollBarCssStyle;

    // Standard properties
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

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

{ TCssMemo }

constructor TCssMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  TabStop := True;

  // Create the lines first.
  FLines := TStringList.Create;
  FLines.OnChange := @LinesChanged;

  FCaretX := 0;
  FCaretY := 0;
  FSelStart := -1;
  FSelEnd := -1;

  FTopLine := 0;
  FLeftPixel := 0;

  FWordWrap := False;
  FReadOnly := False;
  FScrollBars := ssNone;

  FMouseSelecting := False;
  FSelAnchor := -1;
  FUpdating := False;

  FCaretVisible := False;

  // Placeholder initialization
  FPlaceholder := '';
  FPlaceholderColor := clNone;
  FPlaceholderColorSet := False;
  FPlaceholderAlign := ctaLeft;
  FPlaceholderAlignSet := False;
  FPlaceholderVAlign := cvaTop;
  FPlaceholderVAlignSet := False;
  FPlaceholderFontBold := False;
  FPlaceholderFontBoldSet := False;
  FPlaceholderFontItalic := False;
  FPlaceholderFontItalicSet := False;
  FPlaceholderFontUnderline := False;
  FPlaceholderFontUnderlineSet := False;
  FPlaceholderFontStrikeOut := False;
  FPlaceholderFontStrikeOutSet := False;

  FMemoScrollBarCssClass := 'memo-scrollbar';
  FMemoScrollBarCssStyle := '';

  // Create scrollbars before setting sizes.
  FVScroll := TCssScrollBar.Create(Self);
  FVScroll.Parent := Self;
  FVScroll.Kind := sbVertical;
  FVScroll.Visible := False;
  FVScroll.TabStop := False;
  FVScroll.OnChange := @VScrollChanged;
  FVScroll.SetBounds(0, 0, 0, 0);

  FHScroll := TCssScrollBar.Create(Self);
  FHScroll.Parent := Self;
  FHScroll.Kind := sbHorizontal;
  FHScroll.Visible := False;
  FHScroll.TabStop := False;
  FHScroll.OnChange := @HScrollChanged;
  FHScroll.SetBounds(0, 0, 0, 0);

  ApplyScrollBarStyle;

  // Create the caret timer.
  FCaretTimer := TTimer.Create(Self);
  FCaretTimer.Interval := 500;
  FCaretTimer.OnTimer := @CaretTimerTick;
  FCaretTimer.Enabled := False;

  // Set sizes only after all internal objects are created.
  Width := 200;
  Height := 120;
end;

destructor TCssMemo.Destroy;
begin
  FLines.OnChange := nil;
  FreeAndNil(FLines);

  inherited Destroy;
end;

procedure TCssMemo.CreateWnd;
begin
  inherited CreateWnd;

  UpdateScrollBars;
end;

procedure TCssMemo.Loaded;
begin
  inherited Loaded;

  ApplyScrollBarStyle;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaTop);
  SetWordWrap(False);
end;

procedure TCssMemo.StyleChanged;
begin
  inherited StyleChanged;

  ApplyScrollBarStyle;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  // In Memo mode, HTML content can be shown as a preview,
  // but editing remains plain text.
  Invalidate;
end;

procedure TCssMemo.ResetStyle;
begin
  FSelBackgroundSet := False;
  FSelColorSet := False;
  FCaretColorSet := False;

  // NEW: reset placeholder
  FPlaceholderColorSet := False;
  FPlaceholderColor := clNone;
  FPlaceholderAlignSet := False;
  FPlaceholderAlign := ctaLeft;
  FPlaceholderVAlignSet := False;
  FPlaceholderVAlign := cvaTop;
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

procedure TCssMemo.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  S: string;
begin
  if AName = 'selection-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FSelBackground := C;
      FSelBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'selection-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FSelColor := C;
      FSelColorSet := True;
    end;
    Exit;
  end;

  if AName = 'caret-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FCaretColor := C;
      FCaretColorSet := True;
    end;
    Exit;
  end;

  // NEW: CSS properties for placeholder
  if AName = 'placeholder-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FPlaceholderColor := C;
      FPlaceholderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'placeholder-align' then
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
  end;

  if AName = 'placeholder-vertical-align' then
  begin
    S := LowerCase(AValue);
    FPlaceholderVAlignSet := True;

    if (S = 'middle') or (S = 'center') then
      FPlaceholderVAlign := cvaMiddle
    else if S = 'bottom' then
      FPlaceholderVAlign := cvaBottom
    else
      FPlaceholderVAlign := cvaTop;

    Exit;
  end;

  if AName = 'placeholder-font-weight' then
  begin
    S := LowerCase(AValue);
    FPlaceholderFontBoldSet := True;
    FPlaceholderFontBold := (S = 'bold') or (S = 'bolder');
    Exit;
  end;

  if AName = 'placeholder-font-style' then
  begin
    S := LowerCase(AValue);
    FPlaceholderFontItalicSet := True;
    FPlaceholderFontItalic := (S = 'italic') or (S = 'oblique');
    Exit;
  end;

  if AName = 'placeholder-text-decoration' then
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

function TCssMemo.GetText: string;
begin
  Result := FLines.Text;
end;

procedure TCssMemo.SetText(const AValue: string);
begin
  FUpdating := True;
  try
    FLines.Text := AValue;
  finally
    FUpdating := False;
  end;

  FCaretX := 0;
  FCaretY := 0;
  FSelStart := -1;
  FSelEnd := -1;
  FTopLine := 0;
  FLeftPixel := 0;

  UpdateScrollBars;
  Invalidate;
end;

function TCssMemo.GetLines: TStrings;
begin
  Result := FLines;
end;

procedure TCssMemo.SetLines(AValue: TStrings);
begin
  FUpdating := True;
  try
    if AValue = nil then
      FLines.Clear
    else
      FLines.Assign(AValue);
  finally
    FUpdating := False;
  end;

  LinesChanged(Self);
end;

procedure TCssMemo.LinesChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  if FCaretY >= FLines.Count then
  begin
    FCaretY := FLines.Count - 1;

    if FCaretY < 0 then
      FCaretY := 0;

    FCaretX := 0;
  end;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.SetWordWrap(AValue: Boolean);
begin
  if FWordWrap = AValue then
    Exit;

  FWordWrap := AValue;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.SetReadOnly(AValue: Boolean);
begin
  if FReadOnly = AValue then
    Exit;

  FReadOnly := AValue;
  Invalidate;
end;

procedure TCssMemo.SetScrollBars(AValue: TScrollStyle);
begin
  if FScrollBars = AValue then
    Exit;

  FScrollBars := AValue;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.SetMemoScrollBarCssClass(const AValue: string);
begin
  if FMemoScrollBarCssClass = AValue then
    Exit;

  FMemoScrollBarCssClass := AValue;

  ApplyScrollBarStyle;
  Invalidate;
end;

procedure TCssMemo.SetMemoScrollBarCssStyle(const AValue: string);
begin
  if FMemoScrollBarCssStyle = AValue then
    Exit;

  FMemoScrollBarCssStyle := AValue;

  ApplyScrollBarStyle;
  Invalidate;
end;

procedure TCssMemo.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder = AValue then
    Exit;

  FPlaceholder := AValue;

  if IsTextEmpty then
    Invalidate;
end;

function TCssMemo.IsTextEmpty: Boolean;
begin
  // Text is considered empty if there are no lines or all lines are empty.
  if FLines.Count = 0 then
    Result := True
  else
    Result := Trim(FLines.Text) = '';
end;

function TCssMemo.GetPlaceholderColor: TColor;
begin
  if FPlaceholderColorSet and (FPlaceholderColor <> clNone) then
    Result := FPlaceholderColor
  else
    Result := RGBToColor(150, 150, 150); // gray by default
end;

function TCssMemo.GetPlaceholderAlign: TCssTextAlign;
begin
  if FPlaceholderAlignSet then
    Result := FPlaceholderAlign
  else
    Result := ctaLeft;
end;

function TCssMemo.GetPlaceholderVAlign: TCssVAlign;
begin
  if FPlaceholderVAlignSet then
    Result := FPlaceholderVAlign
  else
    Result := cvaTop;
end;

function TCssMemo.GetSelBackground: TColor;
begin
  if FSelBackgroundSet then
    Result := FSelBackground
  else
    Result := clHighlight;
end;

function TCssMemo.GetSelColor: TColor;
begin
  if FSelColorSet then
    Result := FSelColor
  else
    Result := clHighlightText;
end;

function TCssMemo.GetCaretColor: TColor;
begin
  if FCaretColorSet then
    Result := FCaretColor
  else
    Result := GetCssTextColor;
end;

procedure TCssMemo.SetCaretXY(AX, AY: Integer);
begin
  if AY < 0 then
    AY := 0;

  if AY >= FLines.Count then
  begin
    if FLines.Count = 0 then
      AY := 0
    else
      AY := FLines.Count - 1;
  end;

  if AX < 0 then
    AX := 0;

  if (FLines.Count > 0) and (AX > Length(FLines[AY])) then
    AX := Length(FLines[AY]);

  if (FCaretX = AX) and (FCaretY = AY) then
    Exit;

  FCaretX := AX;
  FCaretY := AY;

  ShowCaretNow;
  EnsureCaretVisible;
  Invalidate;
end;

procedure TCssMemo.SetSelBounds(AStart, AEnd: Integer);
var
  Tmp, MaxOffset: Integer;
begin
  if (AStart < 0) or (AEnd < 0) or (AStart = AEnd) then
  begin
    FSelStart := -1;
    FSelEnd := -1;
    Invalidate;
    Exit;
  end;

  // Normalize: FSelStart is always <= FSelEnd
  if AStart > AEnd then
  begin
    Tmp := AStart;
    AStart := AEnd;
    AEnd := Tmp;
  end;

  // Maximum allowed offset (end of text)
  if FLines.Count > 0 then
    MaxOffset := CaretToOffset(UTF8Length(FLines[FLines.Count - 1]), FLines.Count - 1)
  else
    MaxOffset := 0;

  if AStart < 0 then
    AStart := 0;

  if AEnd > MaxOffset then
    AEnd := MaxOffset;

  if AStart = AEnd then
  begin
    FSelStart := -1;
    FSelEnd := -1;
  end
  else
  begin
    FSelStart := AStart;
    FSelEnd := AEnd;
  end;

  Invalidate;
end;

function TCssMemo.GetTextRect: TRect;
begin
  Result := inherited GetContentRect;

  if Assigned(FVScroll) and FVScroll.Visible and (Result.Right <> Result.Left) then
    Result.Right := Result.Right - FVScroll.Width;

  if Assigned(FHScroll) and FHScroll.Visible and (Result.Top <> Result.Bottom) then
    Result.Bottom := Result.Bottom - FHScroll.Height;
end;

function TCssMemo.LineHeight: Integer;
begin
  AssignCssFontToFont(Canvas.Font);

  Result := Canvas.TextHeight('Ag') + ScalePx(2);

  if Result < ScalePx(4) then
    Result := ScalePx(4);
end;

function TCssMemo.CharWidth: Integer;
begin
  AssignCssFontToFont(Canvas.Font);

  Result := Canvas.TextWidth(' ');

  if Result < 1 then
    Result := 1;
end;

function TCssMemo.VisibleLines: Integer;
var
  R: TRect;
begin
  R := GetTextRect;
  Result := (R.Bottom - R.Top) div LineHeight;

  if Result < 0 then
    Result := 0;
end;

function TCssMemo.VisibleChars: Integer;
var
  R: TRect;
begin
  R := GetTextRect;
  Result := (R.Right - R.Left) div CharWidth;

  if Result < 0 then
    Result := 0;
end;

function TCssMemo.GetMaxLineWidth: Integer;
var
  I, W: Integer;
begin
  Result := 0;

  if not HandleAllocated then
    Exit;

  AssignCssFontToFont(Canvas.Font);

  for I := 0 to FLines.Count - 1 do
  begin
    W := Canvas.TextWidth(FLines[I]);

    if W > Result then
      Result := W;
  end;
end;

function TCssMemo.CaretToOffset(AX, AY: Integer): Integer;
var
  I, LB: Integer;
begin
  Result := 0;

  if FLines.Count = 0 then
    Exit;

  LB := UTF8Length(sLineBreak);

  if AY < 0 then
    AY := 0;

  if AY >= FLines.Count then
    AY := FLines.Count - 1;

  for I := 0 to AY - 1 do
    Result := Result + UTF8Length(FLines[I]) + LB;

  if AX < 0 then
    AX := 0;

  if AX > UTF8Length(FLines[AY]) then
    AX := UTF8Length(FLines[AY]);

  Result := Result + AX;
end;

function TCssMemo.OffsetToCaret(AOffset: Integer; out AX, AY: Integer): Boolean;
var
  I, L, LB: Integer;
begin
  Result := False;
  AX := 0;
  AY := 0;

  if AOffset < 0 then
    AOffset := 0;

  if FLines.Count = 0 then
  begin
    Result := True;
    Exit;
  end;

  LB := UTF8Length(sLineBreak);
  I := 0;

  while I < FLines.Count do
  begin
    L := UTF8Length(FLines[I]);

    if AOffset <= L then
    begin
      AX := AOffset;
      AY := I;
      Result := True;
      Exit;
    end;

    AOffset := AOffset - L - LB;

    if AOffset < 0 then
    begin
      if I + 1 < FLines.Count then
      begin
        AX := 0;
        AY := I + 1;
      end
      else
      begin
        AX := L;
        AY := I;
      end;

      Result := True;
      Exit;
    end;

    Inc(I);
  end;

  AY := FLines.Count - 1;
  AX := UTF8Length(FLines[AY]);
  Result := True;
end;

function TCssMemo.PointToCaret(X, Y: Integer; out AX, AY: Integer): Boolean;
var
  R: TRect;
  LH: Integer;
  LineText: string;
  I, N, W, Acc, TargetX: Integer;
begin
  Result := False;
  AX := 0;
  AY := 0;

  if FLines.Count = 0 then
  begin
    Result := True;
    Exit;
  end;

  R := GetTextRect;
  LH := LineHeight;

  AY := FTopLine + ((Y - R.Top) div LH);

  if AY < 0 then
    AY := 0;

  if AY >= FLines.Count then
    AY := FLines.Count - 1;

  if AY < 0 then
    Exit;

  LineText := FLines[AY];

  // Account for horizontal scrolling
  TargetX := X - R.Left + FLeftPixel;

  Acc := 0;
  AX := 0;
  N := UTF8Length(LineText);

  for I := 1 to N do
  begin
    W := Canvas.TextWidth(UTF8Copy(LineText, I, 1));

    if TargetX < Acc + W then
    begin
      if TargetX >= Acc + (W div 2) then
        AX := I
      else
        AX := I - 1;

      Result := True;
      Exit;
    end;

    Acc := Acc + W;
  end;

  AX := N;
  Result := True;
end;

function TCssMemo.IsWordChar(const Ch: string): Boolean;
var
  C: Char;
begin
  if Ch = '' then
  begin
    Result := False;
    Exit;
  end;

  if Length(Ch) = 1 then
  begin
    C := Ch[1];
    Result := (C in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
  end
  else
  begin
    // Multi-byte UTF-8 characters are considered word characters
    // (this covers Cyrillic and other letters)
    Result := True;
  end;
end;

procedure TCssMemo.CalcWordLeft(AX, AY: Integer; out NewX, NewY: Integer);
var
  Line: string;
  Pos: Integer;
begin
  NewX := AX;
  NewY := AY;

  if FLines.Count = 0 then
    Exit;

  if (AY < 0) or (AY >= FLines.Count) then
    Exit;

  Line := FLines[AY];
  Pos := AX;

  // If the caret is at the beginning of a line, move to the end of the previous one
  if Pos <= 0 then
  begin
    if AY > 0 then
    begin
      NewY := AY - 1;
      NewX := UTF8Length(FLines[NewY]);
    end;
    Exit;
  end;

  // Skip whitespace/punctuation backwards
  while (Pos > 0) and (not IsWordChar(UTF8Copy(Line, Pos, 1))) do
    Dec(Pos);

  // Skip word characters backwards
  while (Pos > 0) and IsWordChar(UTF8Copy(Line, Pos, 1)) do
    Dec(Pos);

  NewX := Pos;
  NewY := AY;
end;

procedure TCssMemo.CalcWordRight(AX, AY: Integer; out NewX, NewY: Integer);
var
  Line: string;
  Pos, Len: Integer;
begin
  NewX := AX;
  NewY := AY;

  if FLines.Count = 0 then
    Exit;

  if (AY < 0) or (AY >= FLines.Count) then
    Exit;

  Line := FLines[AY];
  Len := UTF8Length(Line);
  Pos := AX;

  // If the caret is at the end of a line, move to the beginning of the next one
  if Pos >= Len then
  begin
    if AY < FLines.Count - 1 then
    begin
      NewY := AY + 1;
      NewX := 0;
    end;
    Exit;
  end;

  // Skip word characters forward
  while (Pos < Len) and IsWordChar(UTF8Copy(Line, Pos + 1, 1)) do
    Inc(Pos);

  // Skip whitespace/punctuation forward
  while (Pos < Len) and (not IsWordChar(UTF8Copy(Line, Pos + 1, 1))) do
    Inc(Pos);

  NewX := Pos;
  NewY := AY;
end;

procedure TCssMemo.EnsureCaretVisible;
var
  R: TRect;
  Prefix: string;
  CaretPixelX: Integer;
  MaxTop: Integer;
begin
  MaxTop := FLines.Count - VisibleLines;

  if MaxTop < 0 then
    MaxTop := 0;

  if FCaretY < FTopLine then
    FTopLine := FCaretY
  else if FCaretY >= FTopLine + VisibleLines then
    FTopLine := FCaretY - VisibleLines + 1;

  if FTopLine < 0 then
    FTopLine := 0;

  if FTopLine > MaxTop then
    FTopLine := MaxTop;

  // Horizontal scrolling
  if FHScroll.Visible then
  begin
    if (FCaretY >= 0) and (FCaretY < FLines.Count) then
    begin
      R := GetTextRect;

      AssignCssFontToFont(Canvas.Font);

      Prefix := UTF8Copy(FLines[FCaretY], 1, FCaretX);
      CaretPixelX := Canvas.TextWidth(Prefix);

      if CaretPixelX < FLeftPixel then
        FLeftPixel := CaretPixelX
      else if CaretPixelX > FLeftPixel + (R.Right - R.Left) then
        FLeftPixel := CaretPixelX - (R.Right - R.Left);

      if FLeftPixel < 0 then
        FLeftPixel := 0;
    end;
  end;

  FUpdating := True;
  try
    if FVScroll.Visible then
      FVScroll.Position := FTopLine;

    if FHScroll.Visible then
      FHScroll.Position := FLeftPixel;
  finally
    FUpdating := False;
  end;
end;

procedure TCssMemo.UpdateScrollBars;
var
  SBSize: Integer;
var
  R: TRect;
  B: Integer;
  P: TRect;
  LineCount: Integer;
  MaxLineWidth: Integer;
  AvailW, AvailH: Integer;
  VisLines: Integer;
  NeedV, NeedH: Boolean;
  ForceV, ForceH: Boolean;
  AutoV, AutoH: Boolean;
  VMax, HMax: Integer;
  HWidth: Integer;
begin
  if not Assigned(FVScroll) or not Assigned(FHScroll) then
    Exit;

  SBSize := ScalePx(16);

  R := ClientRect;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  R.Left := R.Left + B + P.Left;
  R.Top := R.Top + B + P.Top;
  R.Right := R.Right - B - P.Right;
  R.Bottom := R.Bottom - B - P.Bottom;

  LineCount := FLines.Count;
  MaxLineWidth := GetMaxLineWidth;

  AvailW := R.Right - R.Left;
  AvailH := R.Bottom - R.Top;

  if AvailW < 0 then
    AvailW := 0;

  if AvailH < 0 then
    AvailH := 0;

  ForceV := FScrollBars in [ssVertical, ssBoth];
  ForceH := (not FWordWrap) and (FScrollBars in [ssHorizontal, ssBoth]);

  AutoV := FScrollBars in [ssAutoVertical, ssAutoBoth];
  AutoH := (not FWordWrap) and (FScrollBars in [ssAutoHorizontal, ssAutoBoth]);

  if ForceV then
    NeedV := True
  else if AutoV then
    NeedV := (AvailH > 0) and (LineCount > 0) and
             (LineCount > (AvailH div LineHeight))
  else
    NeedV := False;

  if ForceH then
    NeedH := True
  else if AutoH then
    NeedH := (MaxLineWidth > AvailW)
  else
    NeedH := False;

  if AutoH and (not NeedH) and NeedV then
  begin
    if MaxLineWidth > (AvailW - SBSize) then
      NeedH := True;
  end;

  if AutoV and (not NeedV) and NeedH then
  begin
    if (LineCount > 0) and
       (LineCount > ((AvailH - SBSize) div LineHeight)) then
      NeedV := True;
  end;

  if NeedV then
    AvailW := AvailW - SBSize;

  if NeedH then
    AvailH := AvailH - SBSize;

  if AvailW < 0 then
    AvailW := 0;

  if AvailH < 0 then
    AvailH := 0;

  // Vertical scrollbar
  if NeedV then
  begin
    VisLines := AvailH div LineHeight;

    if VisLines < 1 then
      VisLines := 1;

    // Maximum index of the top line
    VMax := LineCount - VisLines;

    if VMax < 0 then
      VMax := 0;

    FVScroll.Visible := True;
    FVScroll.SetBounds(R.Right - SBSize, R.Top, SBSize, R.Bottom - R.Top);

    FVScroll.Min := 0;
    FVScroll.Max := VMax;          // FIXED
    FVScroll.PageSize := VisLines;

    if FTopLine > VMax then
      FTopLine := VMax;

    if FTopLine < 0 then
      FTopLine := 0;

    FUpdating := True;
    try
      FVScroll.Position := FTopLine;
    finally
      FUpdating := False;
    end;
  end
  else
  begin
    FVScroll.Visible := False;
    FVScroll.SetBounds(0, 0, 0, 0);
    FTopLine := 0;
  end;

  // Horizontal scrollbar
  if NeedH then
  begin
    // Maximum pixel offset
    HMax := MaxLineWidth - AvailW;

    if HMax < 0 then
      HMax := 0;

    HWidth := R.Right - R.Left;

    if NeedV then
      HWidth := HWidth - SBSize;

    FHScroll.Visible := True;
    FHScroll.SetBounds(R.Left, R.Bottom - SBSize, HWidth, SBSize);

    FHScroll.Min := 0;
    FHScroll.Max := HMax;          // FIXED
    FHScroll.PageSize := AvailW;

    if FLeftPixel > HMax then
      FLeftPixel := HMax;

    if FLeftPixel < 0 then
      FLeftPixel := 0;

    FUpdating := True;
    try
      FHScroll.Position := FLeftPixel;
    finally
      FUpdating := False;
    end;
  end
  else
  begin
    FHScroll.Visible := False;
    FHScroll.SetBounds(0, 0, 0, 0);
    FLeftPixel := 0;
  end;

  Invalidate;
end;

procedure TCssMemo.VScrollChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  FTopLine := FVScroll.Position;
  Invalidate;
end;

procedure TCssMemo.HScrollChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  FLeftPixel := FHScroll.Position;

  if FLeftPixel < 0 then
    FLeftPixel := 0;

  Invalidate;
end;

procedure TCssMemo.ApplyScrollBarStyle;
begin
  if not Assigned(FVScroll) then
    Exit;

  FVScroll.CssTag        := 'scrollbar';
  FVScroll.CssClass      := FMemoScrollBarCssClass;
  FVScroll.CssStyle      := FMemoScrollBarCssStyle;
  FVScroll.StyleProvider := StyleProvider;
  FVScroll.StyleName     := StyleName;
  FVScroll.Enabled       := Enabled;

  if not Assigned(FHScroll) then
    Exit;

  FHScroll.CssTag        := 'scrollbar';
  FHScroll.CssClass      := FMemoScrollBarCssClass;
  FHScroll.CssStyle      := FMemoScrollBarCssStyle;
  FHScroll.StyleProvider := StyleProvider;
  FHScroll.StyleName     := StyleName;
  FHScroll.Enabled       := Enabled;
end;

procedure TCssMemo.CaretTimerTick(Sender: TObject);
begin
  if not Focused then
  begin
    FCaretTimer.Enabled := False;
    Exit;
  end;

  FCaretVisible := not FCaretVisible;
  Invalidate;
end;

procedure TCssMemo.ShowCaretNow;
begin
  FCaretVisible := True;

  if Focused and Enabled then
    FCaretTimer.Enabled := True
  else
    FCaretTimer.Enabled := False;
end;

procedure TCssMemo.InsertTextAtCaret(const S: string);
var
  FullText: string;
  CharOffset, ByteOffset, CX, CY: Integer;
begin
  if FReadOnly then
    Exit;

  if S = '' then
    Exit;

  if (FSelStart >= 0) and (FSelEnd > FSelStart) then
    DeleteSelection;

  if FLines.Count = 0 then
    FLines.Add('');

  if FCaretY >= FLines.Count then
    FCaretY := FLines.Count - 1;

  FullText := Text;

  CharOffset := CaretToOffset(FCaretX, FCaretY);
  ByteOffset := Length(UTF8Copy(FullText, 1, CharOffset));

  Insert(S, FullText, ByteOffset + 1);

  FUpdating := True;
  try
    FLines.Text := FullText;
  finally
    FUpdating := False;
  end;

  OffsetToCaret(CharOffset + UTF8Length(S), CX, CY);

  FCaretX := CX;
  FCaretY := CY;

  FSelStart := -1;
  FSelEnd := -1;

  UpdateScrollBars;
  EnsureCaretVisible;
  Invalidate;

  DoChange;
end;

procedure TCssMemo.DeleteSelection;
var
  S: string;
  BStart, BEnd, CX, CY: Integer;
begin
  if FReadOnly then
    Exit;

  if (FSelStart < 0) or (FSelEnd <= FSelStart) then
    Exit;

  S := Text;

  BStart := Length(UTF8Copy(S, 1, FSelStart));
  BEnd := Length(UTF8Copy(S, 1, FSelEnd));

  Delete(S, BStart + 1, BEnd - BStart);

  FUpdating := True;
  try
    FLines.Text := S;
  finally
    FUpdating := False;
  end;

  OffsetToCaret(FSelStart, CX, CY);

  FCaretX := CX;
  FCaretY := CY;

  FSelStart := -1;
  FSelEnd := -1;

  UpdateScrollBars;
  EnsureCaretVisible;
  Invalidate;

  DoChange;
end;

procedure TCssMemo.DeleteCharAtCaret(Backward: Boolean);
var
  Line, Prefix: string;
  StartByte, CharLen, PrevLen: Integer;
begin
  if FReadOnly then
    Exit;

  if (FSelStart >= 0) and (FSelEnd > FSelStart) then
  begin
    DeleteSelection;
    Exit;
  end;

  if (FCaretY < 0) or (FCaretY >= FLines.Count) then
    Exit;

  Line := FLines[FCaretY];

  FUpdating := True;
  try
    if Backward then
    begin
      if FCaretX > 0 then
      begin
        Prefix := UTF8Copy(Line, 1, FCaretX - 1);
        StartByte := Length(Prefix) + 1;
        CharLen := Length(UTF8Copy(Line, FCaretX, 1));

        Delete(Line, StartByte, CharLen);
        FLines[FCaretY] := Line;

        Dec(FCaretX);
      end
      else if FCaretY > 0 then
      begin
        PrevLen := UTF8Length(FLines[FCaretY - 1]);
        FLines[FCaretY - 1] := FLines[FCaretY - 1] + FLines[FCaretY];
        FLines.Delete(FCaretY);

        Dec(FCaretY);
        FCaretX := PrevLen;
      end;
    end
    else
    begin
      if FCaretX < UTF8Length(Line) then
      begin
        Prefix := UTF8Copy(Line, 1, FCaretX);
        StartByte := Length(Prefix) + 1;
        CharLen := Length(UTF8Copy(Line, FCaretX + 1, 1));

        Delete(Line, StartByte, CharLen);
        FLines[FCaretY] := Line;
      end
      else if FCaretY < FLines.Count - 1 then
      begin
        FLines[FCaretY] := FLines[FCaretY] + FLines[FCaretY + 1];
        FLines.Delete(FCaretY + 1);
      end;
    end;
  finally
    FUpdating := False;
  end;

  FSelStart := -1;
  FSelEnd := -1;

  UpdateScrollBars;
  EnsureCaretVisible;
  Invalidate;

  DoChange;
end;

procedure TCssMemo.InsertLineBreak;
begin
  InsertTextAtCaret(sLineBreak);
end;

function TCssMemo.GetSelectionText: string;
var
  S: string;
  BStart, BEnd: Integer;
begin
  Result := '';

  if (FSelStart < 0) or (FSelEnd < 0) or (FSelStart = FSelEnd) then
    Exit;

  S := Text;

  BStart := Length(UTF8Copy(S, 1, FSelStart));
  BEnd := Length(UTF8Copy(S, 1, FSelEnd));

  if BStart > BEnd then
    Exit;

  if BEnd > Length(S) then
    BEnd := Length(S);

  Result := Copy(S, BStart + 1, BEnd - BStart);
end;

procedure TCssMemo.CopyToClipboard;
var
  S: string;
begin
  S := GetSelectionText;

  if S <> '' then
    Clipboard.AsText := S;
end;

procedure TCssMemo.CutToClipboard;
begin
  if FReadOnly then
    Exit;

  CopyToClipboard;
  DeleteSelection;
end;

procedure TCssMemo.PasteFromClipboard;
begin
  if FReadOnly then
    Exit;

  InsertTextAtCaret(Clipboard.AsText);
end;

procedure TCssMemo.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCssMemo.Clear;
begin
  Text := '';
end;

procedure TCssMemo.SelectAll;
var
  LastLine, LastCol, EndOffset: Integer;
begin
  if FLines.Count = 0 then
    Exit;

  LastLine := FLines.Count - 1;
  LastCol := UTF8Length(FLines[LastLine]);
  EndOffset := CaretToOffset(LastCol, LastLine);

  FSelAnchor := 0;
  FSelStart := 0;
  FSelEnd := EndOffset;

  FCaretX := LastCol;
  FCaretY := LastLine;

  Invalidate;
end;

procedure TCssMemo.KeyDown(var Key: Word; Shift: TShiftState);
var
  ExtendSel: Boolean;
  NewX, NewY: Integer;
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  // ===== Clipboard hotkeys =====

  // Copy: Ctrl+C or Ctrl+Insert
  if (ssCtrl in Shift) and ((Key = Ord('C')) or (Key = VK_INSERT)) then
  begin
    CopyToClipboard;
    Key := 0;
    Exit;
  end;

  // Cut: Ctrl+X or Shift+Delete
  if ((ssCtrl in Shift) and (Key = Ord('X'))) or
     ((ssShift in Shift) and (Key = VK_DELETE)) then
  begin
    CutToClipboard;
    Key := 0;
    Exit;
  end;

  // Paste: Ctrl+V or Shift+Insert
  if ((ssCtrl in Shift) and (Key = Ord('V'))) or
     ((ssShift in Shift) and (Key = VK_INSERT)) then
  begin
    PasteFromClipboard;
    Key := 0;
    Exit;
  end;

  // Select all: Ctrl+A
  if (ssCtrl in Shift) and (Key = Ord('A')) then
  begin
    SelectAll;
    Key := 0;
    Exit;
  end;

  // ===== Selection and navigation =====

  ExtendSel := ssShift in Shift;

  // If a new selection is started via Shift, set the anchor
  if ExtendSel then
  begin
    if (FSelStart < 0) and (FSelEnd < 0) then
      FSelAnchor := CaretToOffset(FCaretX, FCaretY);
  end;

  NewX := FCaretX;
  NewY := FCaretY;

  case Key of
    VK_LEFT:
    begin
      if ssCtrl in Shift then
        CalcWordLeft(FCaretX, FCaretY, NewX, NewY)
      else
      begin
        if FCaretX > 0 then
          Dec(NewX)
        else if FCaretY > 0 then
        begin
          Dec(NewY);
          NewX := UTF8Length(FLines[NewY]);
        end;
      end;
    end;

    VK_RIGHT:
    begin
      if ssCtrl in Shift then
        CalcWordRight(FCaretX, FCaretY, NewX, NewY)
      else
      begin
        if (FLines.Count > 0) and (FCaretX < UTF8Length(FLines[FCaretY])) then
          Inc(NewX)
        else if FCaretY < FLines.Count - 1 then
        begin
          Inc(NewY);
          NewX := 0;
        end;
      end;
    end;

    VK_UP:
    begin
      if FCaretY > 0 then
      begin
        Dec(NewY);
        if NewX > UTF8Length(FLines[NewY]) then
          NewX := UTF8Length(FLines[NewY]);
      end;
    end;

    VK_DOWN:
    begin
      if FCaretY < FLines.Count - 1 then
      begin
        Inc(NewY);
        if NewX > UTF8Length(FLines[NewY]) then
          NewX := UTF8Length(FLines[NewY]);
      end;
    end;

    VK_HOME:
      NewX := 0;

    VK_END:
    begin
      if FLines.Count > 0 then
        NewX := UTF8Length(FLines[FCaretY])
      else
        NewX := 0;
    end;

    VK_PRIOR:
    begin
      NewY := FCaretY - VisibleLines;
      if NewY < 0 then
        NewY := 0;
      if (FLines.Count > 0) and (NewX > UTF8Length(FLines[NewY])) then
        NewX := UTF8Length(FLines[NewY]);
    end;

    VK_NEXT:
    begin
      NewY := FCaretY + VisibleLines;
      if NewY >= FLines.Count then
        NewY := FLines.Count - 1;
      if NewY < 0 then
        NewY := 0;
      if (FLines.Count > 0) and (NewX > UTF8Length(FLines[NewY])) then
        NewX := UTF8Length(FLines[NewY]);
    end;

    VK_BACK:
    begin
      DeleteCharAtCaret(True);
      Key := 0;
      Exit;
    end;

    VK_DELETE:
    begin
      DeleteCharAtCaret(False);
      Key := 0;
      Exit;
    end;

    VK_RETURN:
    begin
      InsertLineBreak;
      Key := 0;
      Exit;
    end;
  end;

  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT] then
  begin
    SetCaretXY(NewX, NewY);

    if ExtendSel then
      SetSelBounds(FSelAnchor, CaretToOffset(NewX, NewY))
    else
      SetSelBounds(-1, -1);

    Key := 0;
  end;
end;

procedure TCssMemo.UTF8KeyPress(var Key: TUTF8Char);
begin
  inherited UTF8KeyPress(Key);

  if not Enabled then
    Exit;

  if FReadOnly then
    Exit;

  if Key = '' then
    Exit;

  InsertTextAtCaret(Key);

  Key := '';
end;

procedure TCssMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CX, CY: Integer;
  Offset: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if CanFocus then
    SetFocus;

  if Button <> mbLeft then
    Exit;

  if not PointToCaret(X, Y, CX, CY) then
    Exit;

  SetCaretXY(CX, CY);

  Offset := CaretToOffset(CX, CY);

  FMouseSelecting := True;
  FSelAnchor := Offset;

  SetSelBounds(-1, -1);

  MouseCapture := True;
end;

procedure TCssMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CX, CY: Integer;
  Offset: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  if not FMouseSelecting then
    Exit;

  if not PointToCaret(X, Y, CX, CY) then
    Exit;

  SetCaretXY(CX, CY);

  Offset := CaretToOffset(CX, CY);

  SetSelBounds(FSelAnchor, Offset);
end;

procedure TCssMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FMouseSelecting then
  begin
    FMouseSelecting := False;
    MouseCapture := False;
  end;
end;

function TCssMemo.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
const
  LinesPerNotch = 3;
var
  MaxTop: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);

  if Result then
    Exit;

  if not Enabled then
    Exit;

  if ssCtrl in Shift then
  begin
    // Ctrl + wheel — horizontal scroll
    if FHScroll.Visible then
    begin
      FLeftPixel := FLeftPixel - WheelDelta;

      if FLeftPixel < 0 then
        FLeftPixel := 0;

      if FLeftPixel > FHScroll.Max then
        FLeftPixel := FHScroll.Max;

      FHScroll.Position := FLeftPixel;

      Invalidate;
    end;
  end
  else
  begin
    // Wheel — vertical scroll
    MaxTop := FLines.Count - VisibleLines;

    if MaxTop < 0 then
      MaxTop := 0;

    if WheelDelta > 0 then
      FTopLine := FTopLine - LinesPerNotch
    else
      FTopLine := FTopLine + LinesPerNotch;

    if FTopLine < 0 then
      FTopLine := 0;

    if FTopLine > MaxTop then
      FTopLine := MaxTop;

    if FVScroll.Visible then
      FVScroll.Position := FTopLine;

    Invalidate;
  end;

  Result := True;
end;

procedure TCssMemo.MouseLeave;
begin
  if Assigned(FVScroll) then
    FVScroll.ExternalMouseLeave;

  if Assigned(FHScroll) then
    FHScroll.ExternalMouseLeave;

  inherited MouseLeave;
end;

procedure TCssMemo.DoEnter;
begin
  inherited DoEnter;

  ShowCaretNow;
  Invalidate;
end;

procedure TCssMemo.DoExit;
begin
  inherited DoExit;

  FCaretVisible := False;
  FCaretTimer.Enabled := False;
  Invalidate;
end;

procedure TCssMemo.Resize;
begin
  inherited Resize;

  if csDestroying in ComponentState then
    Exit;

  if not Assigned(FVScroll) or not Assigned(FHScroll) then
    Exit;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssMemo.Paint;
var
  R: TRect;
  LH: Integer;
  I, Y, DrawLine: Integer;
  LineText, Prefix: string;
  LB, BaseOffset, LineStartOffset, LineEndOffset: Integer;
  SelS, SelE: Integer;
  SelRect: TRect;
  X1, X2, Pix1, Pix2: Integer;
  CaretPixelX, CaretPixelY: Integer;
  TS: TTextStyle;
  SavedFontStyle: TFontStyles;
  TextH, TextY: Integer;
  PlaceholderAlignment: TCssTextAlign;
  PlaceholderVAlignment: TCssVAlign;
  BG: TColor;
begin
  inherited Paint;

  R := GetTextRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  LH := LineHeight;

  AssignCssFontToFont(Canvas.Font);

  BG := GetCssBackgroundColor;

  if BG = clNone then
  begin
    if (Parent <> nil) and (Parent is TCssStyledControl) then
      BG := TCssStyledControl(Parent).GetCssBackgroundColor;

    if BG = clNone then
    begin
      if Parent <> nil then
        BG := Parent.Brush.Color
      else
        BG := clWindow;
    end;
  end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BG;
  Canvas.FillRect(R);

  TS := Default(TTextStyle);
  FillChar(TS, SizeOf(TS), 0);
  TS.Clipping := True;
  TS.Alignment := taLeftJustify;
  TS.Layout := tlTop;
  TS.Opaque := False;

  if FSelStart >= 0 then
  begin
    SelS := FSelStart;
    SelE := FSelEnd;
  end
  else
  begin
    SelS := -1;
    SelE := -1;
  end;

  // NEW: draw placeholder when text is empty AND component is not focused
  if IsTextEmpty and (FPlaceholder <> '') and (not Focused) then
  begin
    Canvas.Font.Color := GetPlaceholderColor;

    // Apply font styles for placeholder
    SavedFontStyle := Canvas.Font.Style;

    if FPlaceholderFontBoldSet then
    begin
      if FPlaceholderFontBold then
        Canvas.Font.Style := Canvas.Font.Style + [fsBold]
      else
        Canvas.Font.Style := Canvas.Font.Style - [fsBold];
    end;

    if FPlaceholderFontItalicSet then
    begin
      if FPlaceholderFontItalic then
        Canvas.Font.Style := Canvas.Font.Style + [fsItalic]
      else
        Canvas.Font.Style := Canvas.Font.Style - [fsItalic];
    end;

    if FPlaceholderFontUnderlineSet then
    begin
      if FPlaceholderFontUnderline then
        Canvas.Font.Style := Canvas.Font.Style + [fsUnderline]
      else
        Canvas.Font.Style := Canvas.Font.Style - [fsUnderline];
    end;

    if FPlaceholderFontStrikeOutSet then
    begin
      if FPlaceholderFontStrikeOut then
        Canvas.Font.Style := Canvas.Font.Style + [fsStrikeOut]
      else
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
    end;

    // Horizontal alignment
    PlaceholderAlignment := GetPlaceholderAlign;
    case PlaceholderAlignment of
      ctaCenter: TS.Alignment := taCenter;
      ctaRight:  TS.Alignment := taRightJustify;
    else
      TS.Alignment := taLeftJustify;
    end;

    // Vertical alignment
    TextH := Canvas.TextHeight(FPlaceholder);
    PlaceholderVAlignment := GetPlaceholderVAlign;

    case PlaceholderVAlignment of
      cvaMiddle:
        TextY := R.Top + ((R.Bottom - R.Top) - TextH) div 2;
      cvaBottom:
        TextY := R.Bottom - TextH;
    else
      TextY := R.Top;
    end;

    if TextY < R.Top then
      TextY := R.Top;

    Canvas.TextRect(R, R.Left, TextY, FPlaceholder, TS);

    // Restore font style
    Canvas.Font.Style := SavedFontStyle;
    Exit; // Do NOT draw the main text or caret
  end;

  // Normal line drawing (existing code)
  LB := UTF8Length(sLineBreak);
  BaseOffset := 0;

  for I := 0 to FTopLine - 1 do
  begin
    if I < FLines.Count then
      BaseOffset := BaseOffset + UTF8Length(FLines[I]) + LB;
  end;

  for I := 0 to VisibleLines - 1 do
  begin
    DrawLine := FTopLine + I;

    if DrawLine >= FLines.Count then
      Break;

    Y := R.Top + I * LH;
    LineText := FLines[DrawLine];
    LineStartOffset := BaseOffset;
    LineEndOffset := LineStartOffset + UTF8Length(LineText);

    if (SelS >= 0) and (SelE > SelS) then
    begin
      if (LineEndOffset > SelS) and (LineStartOffset < SelE) then
      begin
        X1 := SelS - LineStartOffset;
        X2 := SelE - LineStartOffset;

        if X1 < 0 then
          X1 := 0;

        if X2 > UTF8Length(LineText) then
          X2 := UTF8Length(LineText);

        if X2 > X1 then
        begin
          Pix1 := Canvas.TextWidth(UTF8Copy(LineText, 1, X1));
          Pix2 := Canvas.TextWidth(UTF8Copy(LineText, 1, X2));

          SelRect := Rect(
            R.Left + Pix1 - FLeftPixel,
            Y,
            R.Left + Pix2 - FLeftPixel,
            Y + LH
          );

          if SelRect.Left < R.Left then
            SelRect.Left := R.Left;

          if SelRect.Right > R.Right then
            SelRect.Right := R.Right;

          if SelRect.Right > SelRect.Left then
          begin
            Canvas.Brush.Color := GetSelBackground;
            Canvas.FillRect(SelRect);
          end;
        end;
      end;
    end;

    Canvas.Font.Color := GetCssTextColor;

    if LineText <> '' then
      Canvas.TextRect(R, R.Left - FLeftPixel, Y + 1, LineText, TS);

    BaseOffset := LineEndOffset + LB;
  end;

  // Caret
  if Focused and FCaretVisible and Enabled then
  begin
    CaretPixelX := -1;
    CaretPixelY := -1;

    if FLines.Count = 0 then
    begin
      // If the line list is empty, the caret is drawn at the very beginning of the text area
      CaretPixelX := R.Left - FLeftPixel;
      CaretPixelY := R.Top;
    end
    else if (FCaretY >= 0) and (FCaretY < FLines.Count) then
    begin
      Prefix := UTF8Copy(FLines[FCaretY], 1, FCaretX);
      CaretPixelX := R.Left + Canvas.TextWidth(Prefix) - FLeftPixel;
      CaretPixelY := R.Top + (FCaretY - FTopLine) * LH;
    end;

    if (CaretPixelX >= R.Left) and (CaretPixelX <= R.Right) and
       (CaretPixelY >= R.Top) and (CaretPixelY + LH <= R.Bottom) then
    begin
      Canvas.Pen.Style := psSolid;
      Canvas.Pen.Width := 1;
      Canvas.Pen.Color := GetCaretColor;
      Canvas.MoveTo(CaretPixelX, CaretPixelY + 1);
      Canvas.LineTo(CaretPixelX, CaretPixelY + LH - 1);
    end;
  end;
end;

procedure TCssMemo.EnabledChanged;
begin
  inherited EnabledChanged;

  if Assigned(FVScroll) then FVScroll.Enabled := Enabled;
  if Assigned(FHScroll) then FHScroll.Enabled := Enabled;

  Invalidate;
end;

end.
