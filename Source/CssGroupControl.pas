unit CssGroupControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType,
  CssStyledControl, CssGroupCaptionControl;

type
  TCssGroupBox = class(TCssGroupCaptionControl)
  private
    procedure PropagateEnabledToChildren;
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;

    // Painting
    procedure Paint; override;

    // Sizing and layout
    procedure Resize; override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;

    // State changes
    procedure EnabledChanged; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Sizing and layout
    procedure AdjustSize; override;
  published
    // Standard properties
    property AutoSize;
    property Align;
    property Anchors;
    property Constraints;
    property Color;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    // Events
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint;
    property OnResize;
  end;

implementation

{ TCssGroupBox }

constructor TCssGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];

  TabStop := False;

  Width := 185;
  Height := 105;
end;

procedure TCssGroupBox.Loaded;
begin
  inherited Loaded;

  PropagateEnabledToChildren;

  if AutoSize then
    AdjustSize;
end;

procedure TCssGroupBox.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssGroupBox.StyleChanged;
begin
  inherited StyleChanged;

  Realign;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssGroupBox.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  Realign;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssGroupBox.Paint;
var
  R, BorderR: TRect;
  B: Integer;
  Radius: Integer;
  BorderColor: TColor;
  LBorderWidth: Integer;
  BG: TColor;
  CaptionRect: TRect;
  CaptionW: Integer;
  TopBorderY: Integer;
begin
  inherited Paint;

  R := ClientRect;

  B := GetCssBorderWidth;
  Radius := GetCssBorderRadius;
  BorderColor := GetCssBorderColor;
  LBorderWidth := B;

  BG := GetCssBackgroundColor;

  if BG = clNone then
    BG := clBtnFace;

  if BG = clDefault then
    BG := clBtnFace;

  // Background
  if BG <> clNone then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := BG;
  end
  else
  begin
    Canvas.Brush.Style := bsClear;
  end;

  // Border
  if LBorderWidth > 0 then
  begin
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := LBorderWidth;
    Canvas.Pen.Color := BorderColor;
  end
  else
  begin
    Canvas.Pen.Style := psClear;
    Canvas.Pen.Width := 1;
  end;

  BorderR := R;

  if LBorderWidth > 1 then
    InflateRect(BorderR, -(LBorderWidth div 2), -(LBorderWidth div 2));

  if CaptionMode = gcmOnBorder then
  begin
    // In OnBorder mode the top line is drawn with a gap for the caption.
    GetCaptionDrawRect(CaptionRect, CaptionW);

    // First fill the entire group background.
    if Radius > 0 then
      Canvas.RoundRect(BorderR.Left, BorderR.Top, BorderR.Right, BorderR.Bottom, Radius, Radius)
    else
      Canvas.Rectangle(BorderR.Left, BorderR.Top, BorderR.Right, BorderR.Bottom);

    // Now erase the background in the caption area to "break" the top line.
    if Caption <> '' then
    begin
      TopBorderY := BorderR.Top;

      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GetCaptionBackground;
      Canvas.Pen.Style := psClear;

      Canvas.FillRect(
        Rect(
          CaptionRect.Left,
          TopBorderY,
          CaptionRect.Right,
          TopBorderY + LBorderWidth + 1
        )
      );
    end;
  end
  else
  begin
    if Radius > 0 then
      Canvas.RoundRect(BorderR.Left, BorderR.Top, BorderR.Right, BorderR.Bottom, Radius, Radius)
    else
      Canvas.Rectangle(BorderR.Left, BorderR.Top, BorderR.Right, BorderR.Bottom);
  end;

  // Draw the caption.
  if Caption <> '' then
  begin
    GetCaptionDrawRect(CaptionRect, CaptionW);

    if CaptionMode = gcmOnBorder then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GetCaptionBackground;
      Canvas.FillRect(CaptionRect);
    end;

    DrawCaptionToCanvas(Canvas, CaptionRect, Caption);
  end;
end;

procedure TCssGroupBox.Resize;
begin
  inherited Resize;

  Invalidate;
end;

procedure TCssGroupBox.AdjustSize;
var
  B: Integer;
  P: TRect;
  CapH: Integer;
  I: Integer;
  MaxRight, MaxBottom: Integer;
  Child: TControl;
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

  B := GetCssBorderWidth;
  P := GetCssPadding;

  CapH := GetCaptionHeight(Width - (B * 2));

  if CapH = 0 then
    CapH := 0;

  MaxRight := 0;
  MaxBottom := 0;

  for I := 0 to ControlCount - 1 do
  begin
    Child := Controls[I];

    if not Child.Visible then
      Continue;

    if Child.Left + Child.Width > MaxRight then
      MaxRight := Child.Left + Child.Width;

    if Child.Top + Child.Height > MaxBottom then
      MaxBottom := Child.Top + Child.Height;
  end;

  NewWidth :=
    (B * 2) +
    P.Left +
    P.Right +
    MaxRight;

  NewHeight :=
    GetTopOffset +
    P.Top +
    P.Bottom +
    B +
    MaxBottom;

  if NewWidth < 50 then
    NewWidth := 50;

  if NewHeight < 50 then
    NewHeight := 50;

  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);

  inherited AdjustSize;
end;

procedure TCssGroupBox.AlignControls(AControl: TControl; var Rect: TRect);
var
  B: Integer;
  P: TRect;
  TopOffset: Integer;
begin
  B := GetCssBorderWidth;
  P := GetCssPadding;
  TopOffset := GetTopOffset;

  Rect.Left := Rect.Left + B + P.Left;
  Rect.Top := Rect.Top + TopOffset + P.Top;
  Rect.Right := Rect.Right - B - P.Right;
  Rect.Bottom := Rect.Bottom - B - P.Bottom;

  if Rect.Right < Rect.Left then
    Rect.Right := Rect.Left;

  if Rect.Bottom < Rect.Top then
    Rect.Bottom := Rect.Top;

  inherited AlignControls(AControl, Rect);
end;

procedure TCssGroupBox.EnabledChanged;
begin
  inherited EnabledChanged;

  PropagateEnabledToChildren;
  Invalidate;
end;

procedure TCssGroupBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
end;

procedure TCssGroupBox.PropagateEnabledToChildren;
var
  I: Integer;
begin
  if csLoading in ComponentState then
    Exit;

  for I := 0 to ControlCount - 1 do
  begin
    if Controls[I] is TControl then
      Controls[I].Enabled := Enabled;
  end;
end;

end.
