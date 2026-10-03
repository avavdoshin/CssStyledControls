unit CssLabelControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, CssStyledControl;

type
  TCssLabel = class(TCssStyledControl)
  private
    // Fields
    FFocusControl: TWinControl;
    FShowAccelChar: Boolean;
    FTransparent: Boolean;

    // Property accessors
    procedure SetFocusControl(AValue: TWinControl);
    procedure SetShowAccelChar(AValue: Boolean);
    procedure SetTransparent(AValue: Boolean);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;

    // Caption
    procedure SetCaption(const AValue: TCaption); override;
    function GetShowPrefix: Boolean; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Component notification
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    function GetDefaultCaption: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Sizing
    procedure AdjustSize; override;
  published
    // Text layout
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property Layout: TTextLayout read GetLayout write SetLayout;
    property WordWrap: Boolean read GetWordWrapProp write SetWordWrapProp;

    property AutoSize;

    // Behavior
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property ShowAccelChar: Boolean read FShowAccelChar write SetShowAccelChar;
    property Transparent: Boolean read FTransparent write SetTransparent;

    // Standard properties
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    // Events
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

function MeasureLabelSize(
  ACanvas: TCanvas;
  const AText: string;
  AWordWrap: Boolean;
  AMaxWidth: Integer): TSize;
var
  Lines: TStringList;
  I, P, StartPos: Integer;
  Line, Word: string;
  LineH, W, SpaceW, LineW: Integer;
begin
  Result.cx := 0;
  Result.cy := 0;

  Lines := TStringList.Create;

  try
    Lines.Text := AText;

    if Lines.Count = 0 then
      Lines.Add('');

    LineH := ACanvas.TextHeight('Ag');

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];

      if (not AWordWrap) or (AMaxWidth <= 0) then
      begin
        W := ACanvas.TextWidth(Line);

        if W > Result.cx then
          Result.cx := W;

        Result.cy := Result.cy + LineH;
      end
      else
      begin
        LineW := 0;
        P := 1;

        while P <= Length(Line) do
        begin
          while (P <= Length(Line)) and (Line[P] = ' ') do
            Inc(P);

          if P > Length(Line) then
            Break;

          StartPos := P;

          while (P <= Length(Line)) and (Line[P] <> ' ') do
            Inc(P);

          Word := Copy(Line, StartPos, P - StartPos);
          W := ACanvas.TextWidth(Word);
          SpaceW := ACanvas.TextWidth(' ');

          if (LineW > 0) and (LineW + SpaceW + W > AMaxWidth) then
          begin
            if LineW > Result.cx then
              Result.cx := LineW;

            Result.cy := Result.cy + LineH;
            LineW := W;
          end
          else
          begin
            if LineW > 0 then
              LineW := LineW + SpaceW;

            LineW := LineW + W;
          end;
        end;

        if LineW > Result.cx then
          Result.cx := LineW;

        Result.cy := Result.cy + LineH;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

{ TCssLabel }

constructor TCssLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  TabStop := False;

  Width := 75;
  Height := 20;

  FFocusControl := nil;
  FShowAccelChar := True;
  FTransparent := False;

  AutoSize := True;
end;

destructor TCssLabel.Destroy;
begin
  if Assigned(FFocusControl) then
    FFocusControl.RemoveFreeNotification(Self);

  inherited Destroy;
end;

procedure TCssLabel.Loaded;
begin
  inherited Loaded;

  if AutoSize then
    AdjustSize;
end;

procedure TCssLabel.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaTop);
  SetWordWrap(False);
end;

procedure TCssLabel.StyleChanged;
begin
  inherited StyleChanged;

  if AutoSize then
    AdjustSize;
end;

procedure TCssLabel.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

function TCssLabel.GetShowPrefix: Boolean;
begin
  Result := FShowAccelChar and not HtmlMode;
end;

procedure TCssLabel.SetCaption(const AValue: TCaption);
begin
  if Caption = AValue then
    Exit;

  inherited SetCaption(AValue);

  if AutoSize then
    AdjustSize;
end;

procedure TCssLabel.SetFocusControl(AValue: TWinControl);
begin
  if FFocusControl = AValue then
    Exit;

  if Assigned(FFocusControl) then
    FFocusControl.RemoveFreeNotification(Self);

  FFocusControl := AValue;

  if Assigned(FFocusControl) then
    FFocusControl.FreeNotification(Self);
end;

procedure TCssLabel.SetShowAccelChar(AValue: Boolean);
begin
  if FShowAccelChar = AValue then
    Exit;

  FShowAccelChar := AValue;
  Invalidate;
end;

procedure TCssLabel.SetTransparent(AValue: Boolean);
begin
  if FTransparent = AValue then
    Exit;

  FTransparent := AValue;
  Invalidate;
end;

procedure TCssLabel.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FFocusControl) then
    FFocusControl := nil;
end;

function TCssLabel.GetDefaultCaption : string;
begin
  Result := 'CssLabel';
end;

procedure TCssLabel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Enabled and Assigned(FFocusControl) and FFocusControl.CanFocus then
    FFocusControl.SetFocus;
end;

procedure TCssLabel.AdjustSize;
var
  S: TSize;
  P: TRect;
  B: Integer;
  LText: string;
  AvailWidth: Integer;
  NewWidth, NewHeight: Integer;
begin
  if (csDestroying in ComponentState) or
     (csLoading in ComponentState) or
     (Align <> alNone) or
     (not AutoSize) or
     (not HandleAllocated) then
  begin
    inherited AdjustSize;
    Exit;
  end;

  AssignCssFontToFont(Canvas.Font);

  B := GetCssBorderWidth;
  P := GetCssPadding;

  LText := Caption;

  if HtmlMode then
  begin
    if WordWrap then
    begin
      AvailWidth := Width - (B * 2) - P.Left - P.Right;

      if AvailWidth > 0 then
      begin
        S := MeasureHtmlTextSize(LText, AvailWidth);
        NewWidth := Width;
      end
      else
      begin
        S := MeasureHtmlTextSize(LText, 0);
        NewWidth := S.cx + (B * 2) + P.Left + P.Right;
      end;
    end
    else
    begin
      S := MeasureHtmlTextSize(LText, 0);
      NewWidth := S.cx + (B * 2) + P.Left + P.Right;
    end;

    NewHeight := S.cy + (B * 2) + P.Top + P.Bottom;
  end
  else
  begin
    if WordWrap then
    begin
      AvailWidth := Width - (B * 2) - P.Left - P.Right;

      if AvailWidth > 0 then
      begin
        S := MeasureLabelSize(Canvas, LText, True, AvailWidth);
        NewWidth := Width;
      end
      else
      begin
        S := MeasureLabelSize(Canvas, LText, False, 0);
        NewWidth := S.cx + (B * 2) + P.Left + P.Right;
      end;
    end
    else
    begin
      S := MeasureLabelSize(Canvas, LText, False, 0);
      NewWidth := S.cx + (B * 2) + P.Left + P.Right;
    end;

    NewHeight := S.cy + (B * 2) + P.Top + P.Bottom;
  end;

  if NewWidth < 0 then
    NewWidth := 0;

  if NewHeight < 0 then
    NewHeight := 0;

  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);

  inherited AdjustSize;
end;

end.
