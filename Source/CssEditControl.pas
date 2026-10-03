unit CssEditControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types,
  ExtCtrls, ClipBrd, LCLType, Forms, CssStyledControl;

type
  TCssEdit = class(TCssStyledControl)
  private
    // Text content and caret
    FText: string;
    FCaret: Integer;
    FAnchor: Integer;
    FScrollX: Integer;

    // Behavior
    FReadOnly: Boolean;
    FMaxLength: Integer;
    FPasswordChar: Char;

    // Mouse selection
    FMouseSelecting: Boolean;

    // Caret blinking
    FCaretVisible: Boolean;
    FCaretTimer: TTimer;

    // Undo
    FUndoText: string;
    FUndoCaret: Integer;
    FCanUndo: Boolean;

    // Events
    FOnChange: TNotifyEvent;

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

    // Property getters/setters
    function GetCaptionText: TCaption;
    procedure SetCaptionText(const AValue: TCaption);
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetSelStart: Integer;
    procedure SetSelStart(AValue: Integer);
    function GetSelLength: Integer;
    procedure SetSelLength(AValue: Integer);
    function GetSelText: string;
    procedure SetSelText(const AValue: string);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetMaxLength(AValue: Integer);
    procedure SetPasswordChar(AValue: Char);
    procedure SetPlaceholder(const AValue: string);
    function GetPlaceholderColor: TColor;
    function GetPlaceholderAlign: TCssTextAlign;

    // Selection helpers
    function HasSelection: Boolean;
    function SelStartByte: Integer;
    function SelEndByte: Integer;
    function GetEditTextRect: TRect;
    function GetDisplayText: string;
    function XToCaret(X: Integer): Integer;

    // Font
    procedure ApplyEditFont;

    // Caret management
    procedure EnsureCaretInView;
    procedure ShowCaret;
    procedure HideCaret;
    procedure CaretTimerTick(Sender: TObject);
    procedure SetCaretByte(APos: Integer; AExtend: Boolean);

    // Text operations
    procedure DoChange;
    procedure SaveUndo;
    procedure InternalDeleteSelection;
    procedure DeleteSelection;
    procedure InsertText(const AValue: string);

    // Caret movement
    procedure MoveLeft(AExtend: Boolean);
    procedure MoveRight(AExtend: Boolean);
    procedure MoveWordLeft(AExtend: Boolean);
    procedure MoveWordRight(AExtend: Boolean);
    procedure MoveHome(AExtend: Boolean);
    procedure MoveEnd(AExtend: Boolean);

    // Deletion
    procedure DeleteCharLeft;
    procedure DeleteCharRight;

    // Selection
    procedure SelectWordAt(APos: Integer);
  protected
    // Initialization and style
    procedure Loaded; override;
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
    procedure DblClick; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure UTF8KeyPress(var Key: TUTF8Char); override;

    // Focus
    procedure DoEnter; override;
    procedure DoExit; override;

    // State changes
    procedure EnabledChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Selection
    procedure SelectAll;

    // Text operations
    procedure Clear;

    // Clipboard
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;

    // Undo
    procedure Undo;
    procedure ClearUndo;
  published
    // Text properties
    property Caption: TCaption read GetCaptionText write SetCaptionText;
    property Text: string read GetText write SetText;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelText: string read GetSelText write SetSelText;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property MaxLength: Integer read FMaxLength write SetMaxLength;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar;
    property Placeholder: string read FPlaceholder write SetPlaceholder;

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
  end;

implementation

uses
  CssUtils;

function NormalizeSingleLine(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, #13#10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '', [rfReplaceAll]);
end;

function CssUtf8CharLen(Lead: Byte): Integer;
begin
  if Lead < $80 then
    Result := 1
  else if (Lead >= $C2) and (Lead <= $DF) then
    Result := 2
  else if (Lead >= $E0) and (Lead <= $EF) then
    Result := 3
  else if (Lead >= $F0) and (Lead <= $F4) then
    Result := 4
  else
    Result := 1;
end;

function CssNextCharPos(const S: string; Pos: Integer): Integer;
var
  L: Integer;
begin
  if Pos < 0 then
    Pos := 0;
  if Pos >= Length(S) then
    Exit(Length(S));
  L := CssUtf8CharLen(Byte(S[Pos + 1]));
  Result := Pos + L;
  if Result > Length(S) then
    Result := Length(S);
end;

function CssPrevCharPos(const S: string; Pos: Integer): Integer;
var
  I: Integer;
begin
  if Pos > Length(S) then
    Pos := Length(S);
  if Pos <= 0 then
    Exit(0);
  I := Pos;
  while (I > 1) and ((Byte(S[I]) and $C0) = $80) do
    Dec(I);
  Result := I - 1;
  if Result < 0 then
    Result := 0;
end;

function CssCharCount(const S: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  I := 0;
  while I < Length(S) do
  begin
    I := CssNextCharPos(S, I);
    Inc(Result);
  end;
end;

function CssCharToBytePos(const S: string; CharIndex: Integer): Integer;
var
  I, C: Integer;
begin
  if CharIndex <= 0 then
    Exit(0);
  I := 0;
  C := 0;
  while (I < Length(S)) and (C < CharIndex) do
  begin
    I := CssNextCharPos(S, I);
    Inc(C);
  end;
  Result := I;
end;

function CssByteToCharPos(const S: string; BytePos: Integer): Integer;
var
  I, C: Integer;
begin
  if BytePos <= 0 then
    Exit(0);
  if BytePos > Length(S) then
    BytePos := Length(S);
  I := 0;
  C := 0;
  while (I < BytePos) and (I < Length(S)) do
  begin
    I := CssNextCharPos(S, I);
    Inc(C);
  end;
  Result := C;
end;

function CssCopyChars(const S: string; StartChar, CharCount: Integer): string;
var
  B1, B2: Integer;
begin
  if CharCount <= 0 then
    Exit('');
  if StartChar < 1 then
    StartChar := 1;
  B1 := CssCharToBytePos(S, StartChar - 1);
  B2 := CssCharToBytePos(S, StartChar - 1 + CharCount);
  if B2 > Length(S) then
    B2 := Length(S);
  if B1 >= B2 then
    Result := ''
  else
    Result := Copy(S, B1 + 1, B2 - B1);
end;

function IsEditDelimiter(const S: string; Pos: Integer): Boolean;
var
  Ch: Char;
begin
  if (Pos < 0) or (Pos >= Length(S)) then
    Exit(True);
  Ch := S[Pos + 1];
  if Ord(Ch) >= 128 then
    Exit(False);
  Result := not (Ch in ['a'..'z', 'A'..'Z', '0'..'9', '_']);
end;

function NextWordPos(const S: string; Pos: Integer): Integer;
begin
  Result := Pos;
  if Result < 0 then
    Result := 0;
  if Result >= Length(S) then
    Exit(Length(S));
  while (Result < Length(S)) and IsEditDelimiter(S, Result) do
    Result := CssNextCharPos(S, Result);
  while (Result < Length(S)) and not IsEditDelimiter(S, Result) do
    Result := CssNextCharPos(S, Result);
end;

function PrevWordPos(const S: string; Pos: Integer): Integer;
begin
  Result := Pos;
  if Result > Length(S) then
    Result := Length(S);
  if Result <= 0 then
    Exit(0);
  Result := CssPrevCharPos(S, Result);
  while (Result > 0) and IsEditDelimiter(S, Result) do
    Result := CssPrevCharPos(S, Result);
  while (Result > 0) and not IsEditDelimiter(S, Result) do
    Result := CssPrevCharPos(S, Result);
  if Result <= 0 then
    Exit(0);
  Result := CssNextCharPos(S, Result);
  if Result > Pos then
    Result := Pos;
end;

procedure ClampRect(var ARect: TRect; const Limit: TRect);
begin
  if ARect.Left < Limit.Left then
    ARect.Left := Limit.Left;
  if ARect.Top < Limit.Top then
    ARect.Top := Limit.Top;
  if ARect.Right > Limit.Right then
    ARect.Right := Limit.Right;
  if ARect.Bottom > Limit.Bottom then
    ARect.Bottom := Limit.Bottom;
  if ARect.Right < ARect.Left then
    ARect.Right := ARect.Left;
  if ARect.Bottom < ARect.Top then
    ARect.Bottom := ARect.Top;
end;

function RectWidth(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

{ TCssEdit }

constructor TCssEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := True;

  Width := 121;
  Height := 25;

  FText := '';
  FCaret := 0;
  FAnchor := 0;
  FScrollX := 0;

  FReadOnly := False;
  FMaxLength := 0;
  FPasswordChar := #0;

  FMouseSelecting := False;

  FCaretVisible := False;
  FCanUndo := False;

  FPlaceholder := '';
  FPlaceholderColor := clNone;
  FPlaceholderColorSet := False;

  FCaretTimer := TTimer.Create(Self);
  FCaretTimer.Enabled := False;
  FCaretTimer.Interval := 500;
  FCaretTimer.OnTimer := @CaretTimerTick;

  HtmlMode := False;
end;

destructor TCssEdit.Destroy;
begin
  FCaretTimer.Enabled := False;

  inherited Destroy;
end;

procedure TCssEdit.Loaded;
begin
  inherited Loaded;

  EnsureCaretInView;
  Invalidate;
end;

function TCssEdit.GetCaptionText: TCaption;
begin
  Result := FText;
end;

procedure TCssEdit.SetCaptionText(const AValue: TCaption);
begin
  SetText(AValue);
end;

function TCssEdit.GetText: string;
begin
  Result := FText;
end;

procedure TCssEdit.SetText(const AValue: string);
var
  S: string;
begin
  S := NormalizeSingleLine(AValue);

  if FText = S then
    Exit;

  FText := S;

  if FCaret > Length(FText) then
    FCaret := Length(FText);

  FAnchor := FCaret;
  FScrollX := 0;

  ClearUndo;

  if not (csLoading in ComponentState) then
    DoChange
  else
    Invalidate;
end;

function TCssEdit.GetSelStart: Integer;
begin
  Result := CssByteToCharPos(FText, SelStartByte);
end;

procedure TCssEdit.SetSelStart(AValue: Integer);
var
  B: Integer;
begin
  if AValue < 0 then
    AValue := 0;

  B := CssCharToBytePos(FText, AValue);
  FCaret := B;
  FAnchor := B;

  Invalidate;
end;

function TCssEdit.GetSelLength: Integer;
begin
  Result := CssCharCount(GetSelText);
end;

procedure TCssEdit.SetSelLength(AValue: Integer);
var
  StartChar, EndChar, Total: Integer;
begin
  if AValue < 0 then
    AValue := 0;

  Total := CssCharCount(FText);
  StartChar := GetSelStart;
  EndChar := StartChar + AValue;

  if EndChar > Total then
    EndChar := Total;

  FAnchor := CssCharToBytePos(FText, StartChar);
  FCaret := CssCharToBytePos(FText, EndChar);

  Invalidate;
end;

function TCssEdit.GetSelText: string;
var
  B, E: Integer;
begin
  if HasSelection then
  begin
    B := SelStartByte;
    E := SelEndByte;
    Result := Copy(FText, B + 1, E - B);
  end
  else
    Result := '';
end;

procedure TCssEdit.SetSelText(const AValue: string);
begin
  if not ReadOnly then
    InsertText(AValue);
end;

procedure TCssEdit.SetReadOnly(AValue: Boolean);
begin
  if FReadOnly = AValue then
    Exit;

  FReadOnly := AValue;

  Invalidate;
end;

procedure TCssEdit.SetMaxLength(AValue: Integer);
begin
  if FMaxLength = AValue then
    Exit;

  FMaxLength := AValue;

  if (FMaxLength > 0) and (CssCharCount(FText) > FMaxLength) then
  begin
    FText := CssCopyChars(FText, 1, FMaxLength);

    if FCaret > Length(FText) then
      FCaret := Length(FText);

    if FAnchor > Length(FText) then
      FAnchor := Length(FText);

    DoChange;
  end;

  Invalidate;
end;

procedure TCssEdit.SetPasswordChar(AValue: Char);
begin
  if FPasswordChar = AValue then
    Exit;

  FPasswordChar := AValue;

  Invalidate;
end;

procedure TCssEdit.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder = AValue then
    Exit;

  FPlaceholder := AValue;

  if (FText = '') then
    Invalidate;
end;

function TCssEdit.GetPlaceholderColor: TColor;
begin
  if FPlaceholderColorSet and (FPlaceholderColor <> clNone) then
    Result := FPlaceholderColor
  else
    Result := RGBToColor(150, 150, 150);
end;

function TCssEdit.GetPlaceholderAlign: TCssTextAlign;
begin
  if FPlaceholderAlignSet then
    Result := FPlaceholderAlign
  else
    Result := ctaLeft; // Default is left
end;

function TCssEdit.HasSelection: Boolean;
begin
  Result := FCaret <> FAnchor;
end;

function TCssEdit.SelStartByte: Integer;
begin
  Result := CssMin(FCaret, FAnchor);
end;

function TCssEdit.SelEndByte: Integer;
begin
  Result := CssMax(FCaret, FAnchor);
end;

function TCssEdit.GetEditTextRect: TRect;
begin
  Result := inherited GetContentRect;
end;

function TCssEdit.GetDisplayText: string;
begin
  if FPasswordChar <> #0 then
    Result := StringOfChar(FPasswordChar, CssCharCount(FText))
  else
    Result := FText;
end;

function TCssEdit.XToCaret(X: Integer): Integer;
var
  R: TRect;
  Display: string;
  Pos, NextPos, Accum, CharW: Integer;
begin
  R := GetEditTextRect;
  ApplyEditFont;
  Display := GetDisplayText;

  X := X - R.Left + FScrollX;

  if X <= 0 then
    Exit(0);

  Pos := 0;
  Accum := 0;

  while Pos < Length(Display) do
  begin
    NextPos := CssNextCharPos(Display, Pos);
    CharW := Canvas.TextWidth(Copy(Display, Pos + 1, NextPos - Pos));

    if X < Accum + CharW then
    begin
      if X < Accum + (CharW div 2) then
        Exit(Pos)
      else
        Exit(NextPos);
    end;

    Accum := Accum + CharW;
    Pos := NextPos;
  end;

  Result := Length(Display);
end;

procedure TCssEdit.ApplyEditFont;
begin
  AssignCssFontToFont(Canvas.Font);
  Canvas.Font.Color := GetCssTextColor;
end;

procedure TCssEdit.EnsureCaretInView;
var
  R: TRect;
  Display: string;
  CaretX, W: Integer;
begin
  if not HandleAllocated then
    Exit;

  R := GetEditTextRect;
  ApplyEditFont;

  Display := GetDisplayText;
  CaretX := Canvas.TextWidth(Copy(Display, 1, FCaret));
  W := RectWidth(R);

  if CaretX < FScrollX then
    FScrollX := CaretX - 2
  else if CaretX > FScrollX + W then
    FScrollX := CaretX - W + 2;

  if FScrollX < 0 then
    FScrollX := 0;
end;

procedure TCssEdit.ShowCaret;
begin
  FCaretVisible := True;

  if Focused and Enabled then
    FCaretTimer.Enabled := True;
end;

procedure TCssEdit.HideCaret;
begin
  FCaretVisible := False;
  FCaretTimer.Enabled := False;
end;

procedure TCssEdit.CaretTimerTick(Sender: TObject);
begin
  if Focused and Enabled then
  begin
    FCaretVisible := not FCaretVisible;
    Invalidate;
  end
  else
  begin
    FCaretTimer.Enabled := False;
  end;
end;

procedure TCssEdit.SetCaretByte(APos: Integer; AExtend: Boolean);
begin
  if APos < 0 then
    APos := 0;

  if APos > Length(FText) then
    APos := Length(FText);

  if AExtend then
  begin
    FCaret := APos;
  end
  else
  begin
    FCaret := APos;
    FAnchor := APos;
  end;

  EnsureCaretInView;
  ShowCaret;
  Invalidate;
end;

procedure TCssEdit.DoChange;
begin
  EnsureCaretInView;
  ShowCaret;
  Invalidate;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCssEdit.SaveUndo;
begin
  FUndoText := FText;
  FUndoCaret := FCaret;
  FCanUndo := True;
end;

procedure TCssEdit.InternalDeleteSelection;
var
  B, E: Integer;
begin
  if not HasSelection then
    Exit;

  B := SelStartByte;
  E := SelEndByte;

  Delete(FText, B + 1, E - B);

  FCaret := B;
  FAnchor := B;
end;

procedure TCssEdit.DeleteSelection;
begin
  if ReadOnly then
    Exit;

  if not HasSelection then
    Exit;

  SaveUndo;
  InternalDeleteSelection;
  DoChange;
end;

procedure TCssEdit.InsertText(const AValue: string);
var
  Ins: string;
  Available, CurrentLen: Integer;
begin
  if ReadOnly then
    Exit;

  Ins := NormalizeSingleLine(AValue);

  if Ins = '' then
    Exit;

  if FMaxLength > 0 then
  begin
    CurrentLen := CssCharCount(FText);

    if HasSelection then
      CurrentLen := CurrentLen - CssCharCount(GetSelText);

    Available := FMaxLength - CurrentLen;

    if Available <= 0 then
      Exit;

    if CssCharCount(Ins) > Available then
      Ins := CssCopyChars(Ins, 1, Available);

    if Ins = '' then
      Exit;
  end;

  SaveUndo;
  InternalDeleteSelection;

  if FCaret < 0 then
    FCaret := 0;

  if FCaret > Length(FText) then
    FCaret := Length(FText);

  Insert(Ins, FText, FCaret + 1);
  FCaret := FCaret + Length(Ins);
  FAnchor := FCaret;

  DoChange;
end;

procedure TCssEdit.MoveLeft(AExtend: Boolean);
var
  NewPos: Integer;
begin
  if (not AExtend) and HasSelection then
    NewPos := SelStartByte
  else
    NewPos := CssPrevCharPos(FText, FCaret);

  SetCaretByte(NewPos, AExtend);
end;

procedure TCssEdit.MoveRight(AExtend: Boolean);
var
  NewPos: Integer;
begin
  if (not AExtend) and HasSelection then
    NewPos := SelEndByte
  else
    NewPos := CssNextCharPos(FText, FCaret);

  SetCaretByte(NewPos, AExtend);
end;

procedure TCssEdit.MoveWordLeft(AExtend: Boolean);
var
  NewPos: Integer;
begin
  if (not AExtend) and HasSelection then
    NewPos := SelStartByte
  else
    NewPos := PrevWordPos(FText, FCaret);

  SetCaretByte(NewPos, AExtend);
end;

procedure TCssEdit.MoveWordRight(AExtend: Boolean);
var
  NewPos: Integer;
begin
  if (not AExtend) and HasSelection then
    NewPos := SelEndByte
  else
    NewPos := NextWordPos(FText, FCaret);

  SetCaretByte(NewPos, AExtend);
end;

procedure TCssEdit.MoveHome(AExtend: Boolean);
begin
  SetCaretByte(0, AExtend);
end;

procedure TCssEdit.MoveEnd(AExtend: Boolean);
begin
  SetCaretByte(Length(FText), AExtend);
end;

procedure TCssEdit.DeleteCharLeft;
var
  PrevPos: Integer;
begin
  if ReadOnly then
    Exit;

  if FCaret <= 0 then
    Exit;

  PrevPos := CssPrevCharPos(FText, FCaret);

  SaveUndo;
  Delete(FText, PrevPos + 1, FCaret - PrevPos);

  FCaret := PrevPos;
  FAnchor := PrevPos;

  DoChange;
end;

procedure TCssEdit.DeleteCharRight;
var
  NextPos: Integer;
begin
  if ReadOnly then
    Exit;

  if FCaret >= Length(FText) then
    Exit;

  NextPos := CssNextCharPos(FText, FCaret);

  SaveUndo;
  Delete(FText, FCaret + 1, NextPos - FCaret);

  DoChange;
end;

procedure TCssEdit.SelectWordAt(APos: Integer);
var
  L, R: Integer;
begin
  if FText = '' then
    Exit;

  if APos < 0 then
    APos := 0;

  if APos > Length(FText) then
    APos := Length(FText);

  L := APos;
  R := APos;

  while (L > 0) and not IsEditDelimiter(FText, CssPrevCharPos(FText, L)) do
    L := CssPrevCharPos(FText, L);

  while (R < Length(FText)) and not IsEditDelimiter(FText, R) do
    R := CssNextCharPos(FText, R);

  FAnchor := L;
  FCaret := R;

  Invalidate;
end;

procedure TCssEdit.SelectAll;
begin
  FAnchor := 0;
  FCaret := Length(FText);

  Invalidate;
end;

procedure TCssEdit.Clear;
begin
  if not ReadOnly then
    SetText('');
end;

procedure TCssEdit.CopyToClipboard;
begin
  if HasSelection then
    Clipboard.AsText := GetSelText;
end;

procedure TCssEdit.CutToClipboard;
begin
  if ReadOnly then
    Exit;

  if HasSelection then
  begin
    CopyToClipboard;
    DeleteSelection;
  end;
end;

procedure TCssEdit.PasteFromClipboard;
begin
  if ReadOnly then
    Exit;

  InsertText(Clipboard.AsText);
end;

procedure TCssEdit.Undo;
begin
  if not FCanUndo then
    Exit;

  FText := FUndoText;
  FCaret := FUndoCaret;
  FAnchor := FCaret;
  FCanUndo := False;

  DoChange;
end;

procedure TCssEdit.ClearUndo;
begin
  FCanUndo := False;
end;

procedure TCssEdit.ResetStyle;
begin
  inherited ResetStyle;

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
end;

procedure TCssEdit.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  S: string;
begin
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
  else if AName = 'placeholder-font-weight' then // NEW
  begin
    S := LowerCase(AValue);
    FPlaceholderFontBoldSet := True;
    FPlaceholderFontBold := (S = 'bold') or (S = 'bolder');
    Exit;
  end
  else if AName = 'placeholder-font-style' then // NEW
  begin
    S := LowerCase(AValue);
    FPlaceholderFontItalicSet := True;
    FPlaceholderFontItalic := (S = 'italic') or (S = 'oblique');
    Exit;
  end
  else if AName = 'placeholder-text-decoration' then // NEW
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

procedure TCssEdit.Paint;
var
  R: TRect;
  Display, Before, Selected, After: string;
  X, Y, H, SelB, SelE, SelW: Integer;
  BG, FG, PlaceholderC: TColor;
  TS: TTextStyle;
  SelRect: TRect;
  PlaceholderAlignment: TCssTextAlign;
  SavedFontStyle: TFontStyles; // NEW
begin
  inherited Paint;

  R := GetEditTextRect;
  ApplyEditFont;

  BG := GetCssBackgroundColor;
  FG := GetCssTextColor;

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

  H := Canvas.TextHeight('Ag');
  Y := R.Top + ((R.Bottom - R.Top) - H) div 2;

  if Y < R.Top then
    Y := R.Top;

  TS := Canvas.TextStyle;
  TS.Layout := tlTop;
  TS.Wordbreak := False;
  TS.Clipping := True;
  TS.Opaque := False;
  TS.ShowPrefix := False;
  TS.SystemFont := False;

  // Show placeholder when text is empty AND the component is NOT focused
  if (FText = '') and (FPlaceholder <> '') and (not Focused) then
  begin
    PlaceholderC := GetPlaceholderColor;
    PlaceholderAlignment := GetPlaceholderAlign;

    Canvas.Font.Color := PlaceholderC;

    // NEW: Apply font styles for the placeholder
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

    // Set alignment for the placeholder
    case PlaceholderAlignment of
      ctaCenter: TS.Alignment := taCenter;
      ctaRight:  TS.Alignment := taRightJustify;
    else
      TS.Alignment := taLeftJustify;
    end;

    Canvas.TextRect(R, R.Left, Y, FPlaceholder, TS);

    // NEW: Restore the original font style
    Canvas.Font.Style := SavedFontStyle;
    Exit;
  end;

  // Normal text drawing
  Display := GetDisplayText;
  Canvas.Font.Color := FG;
  TS.Alignment := taLeftJustify; // Main text is always left-aligned

  if Focused and HasSelection then
  begin
    SelB := SelStartByte;
    SelE := SelEndByte;

    Before := Copy(Display, 1, SelB);
    Selected := Copy(Display, SelB + 1, SelE - SelB);
    After := Copy(Display, SelE + 1, Length(Display) - SelE);

    X := R.Left - FScrollX;
    Canvas.TextRect(R, X, Y, Before, TS);
    X := X + Canvas.TextWidth(Before);

    SelW := Canvas.TextWidth(Selected);

    if SelW > 0 then
    begin
      SelRect := Rect(X, R.Top, X + SelW, R.Bottom);
      ClampRect(SelRect, R);

      Canvas.Brush.Color := clHighlight;
      Canvas.FillRect(SelRect);

      Canvas.Font.Color := clHighlightText;
      Canvas.TextRect(R, X, Y, Selected, TS);
      Canvas.Font.Color := FG;

      X := X + SelW;
    end;

    Canvas.TextRect(R, X, Y, After, TS);
  end
  else
  begin
    Canvas.TextRect(R, R.Left - FScrollX, Y, Display, TS);
  end;

  if Focused and FCaretVisible and Enabled then
  begin
    X := R.Left - FScrollX + Canvas.TextWidth(Copy(Display, 1, FCaret));
    Canvas.Pen.Color := FG;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(X, Y);
    Canvas.LineTo(X, Y + H);
  end;
end;

procedure TCssEdit.KeyDown(var Key: Word; Shift: TShiftState);
var
  Extend: Boolean;
  ParentForm: TCustomForm;
begin
  inherited KeyDown(Key, Shift);

  if Key = 0 then
    Exit;

  if not Enabled then
    Exit;

  Extend := ssShift in Shift;

  case Key of
    VK_TAB:
      begin
        if not (ssAlt in Shift) then
        begin
          ParentForm := CssUtils.FindParentForm(Self);

          if Assigned(ParentForm) then
          begin
            ParentForm.SelectNext(
              Self,
              not (ssShift in Shift),
              True
            );
            Key := 0;
          end;
        end;
      end;

    VK_LEFT:
      begin
        if ssCtrl in Shift then
          MoveWordLeft(Extend)
        else
          MoveLeft(Extend);

        Key := 0;
      end;

    VK_RIGHT:
      begin
        if ssCtrl in Shift then
          MoveWordRight(Extend)
        else
          MoveRight(Extend);

        Key := 0;
      end;

    VK_HOME:
      begin
        MoveHome(Extend);
        Key := 0;
      end;

    VK_END:
      begin
        MoveEnd(Extend);
        Key := 0;
      end;

    VK_DELETE:
      begin
        if not ReadOnly then
        begin
          if HasSelection then
            DeleteSelection
          else
            DeleteCharRight;
        end;
        Key := 0;
      end;

    VK_BACK:
      begin
        if not ReadOnly then
        begin
          if HasSelection then
            DeleteSelection
          else
            DeleteCharLeft;
        end;
        Key := 0;
      end;

    Ord('A'):
      begin
        if ssCtrl in Shift then
        begin
          SelectAll;
          Key := 0;
        end;
      end;

    Ord('C'):
      begin
        if ssCtrl in Shift then
        begin
          CopyToClipboard;
          Key := 0;
        end;
      end;

    Ord('X'):
      begin
        if ssCtrl in Shift then
        begin
          CutToClipboard;
          Key := 0;
        end;
      end;

    Ord('V'):
      begin
        if ssCtrl in Shift then
        begin
          PasteFromClipboard;
          Key := 0;
        end;
      end;
  end;
end;

procedure TCssEdit.UTF8KeyPress(var Key: TUTF8Char);
begin
  inherited UTF8KeyPress(Key);

  if Key = '' then
    Exit;

  if not Enabled then
    Exit;

  if ReadOnly then
    Exit;

  if (Length(Key) = 1) and (Key[1] < #32) then
    Exit;

  InsertText(Key);
  Key := '';
end;

procedure TCssEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if Button = mbLeft then
  begin
    if CanFocus then
      SetFocus;

    FMouseSelecting := True;
    MouseCapture := True;

    FCaret := XToCaret(X);

    if not (ssShift in Shift) then
      FAnchor := FCaret;

    ShowCaret;
    EnsureCaretInView;
    Invalidate;
  end;
end;

procedure TCssEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  if FMouseSelecting then
  begin
    FCaret := XToCaret(X);
    EnsureCaretInView;
    Invalidate;
  end;
end;

procedure TCssEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  FMouseSelecting := False;
  MouseCapture := False;
end;

procedure TCssEdit.DblClick;
begin
  inherited DblClick;

  if Enabled then
    SelectWordAt(FCaret);
end;

procedure TCssEdit.DoEnter;
begin
  inherited DoEnter;

  ShowCaret;
  Invalidate;
end;

procedure TCssEdit.DoExit;
begin
  inherited DoExit;

  HideCaret;
  Invalidate;
end;

procedure TCssEdit.Resize;
begin
  inherited Resize;

  EnsureCaretInView;
  Invalidate;
end;

procedure TCssEdit.StyleChanged;
begin
  inherited StyleChanged;

  EnsureCaretInView;
  Invalidate;
end;

procedure TCssEdit.EnabledChanged;
begin
  inherited EnabledChanged;

  if not Enabled then
    HideCaret;

  Invalidate;
end;

procedure TCssEdit.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

end.
