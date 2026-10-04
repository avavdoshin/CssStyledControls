unit CssGroupControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, LCLIntf,
  CssStyledControl, CssGroupCaptionControl;

type
  TCssGroupBox = class(TCssGroupCaptionControl)
  private
    FPropagatingEnabled: Boolean;
    FDisabledByParent: TList;
    FShowFocusWhenChildFocused: Boolean;
    FShowFocusWhenChildFocusedSet: Boolean;
    FHasFocusedChild: Boolean;
    procedure PropagateEnabledToChildren;
    function  FControlsContain(AControl: TControl): Boolean;
    function  HasFocusedChild: Boolean;
    procedure UpdateFocusedChildState;
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
    procedure AdjustClientRect(var ARect: TRect); override;

    // State changes
    procedure EnabledChanged; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    // Style declaration
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Focus tracking
    procedure ChildFocusChanged(AChildFocused: Boolean); override;
    function  GetEffectiveHoverState: Boolean; override;

    procedure SetCaption(const AValue: TCaption); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

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

  FPropagatingEnabled := False;
  FDisabledByParent := TList.Create;

  FShowFocusWhenChildFocused := False;
  FShowFocusWhenChildFocusedSet := False;
  FHasFocusedChild := False;
end;

destructor TCssGroupBox.Destroy;
begin
  FreeAndNil(FDisabledByParent);
  inherited Destroy;
end;

procedure TCssGroupBox.Loaded;
begin
  inherited Loaded;

  PropagateEnabledToChildren;

  if AutoSize then
    AdjustSize;

  UpdateFocusedChildState;
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
  CaptionRect, DrawRect: TRect;
  CaptionW: Integer;
  TopBorderY: Integer;
begin
  inherited Paint;

  R := Rect(0, 0, Width, Height);

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
    if CaptionMode = gcmOnBorder then
    begin
      GetCaptionDrawRect(CaptionRect, CaptionW);

      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GetCaptionBackground;
      Canvas.FillRect(CaptionRect);
    end;

    GetCaptionDrawArea(DrawRect);
    DrawCaptionToCanvas(Canvas, DrawRect, Caption);
  end;

  if FShowFocusWhenChildFocused and
     ShowFocusRect and
     FHasFocusedChild and
     Enabled then
  begin
    DrawFocusRect(Canvas, ClientRect);
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

  if NewWidth < ScalePx(50) then
    NewWidth := ScalePx(50);

  if NewHeight < ScalePx(50) then
    NewHeight := ScalePx(50);

  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);

  inherited AdjustSize;
end;

procedure TCssGroupBox.AlignControls(AControl: TControl; var Rect: TRect);
var
  B: Integer;
  P: TRect;
begin
  B := GetCssBorderWidth;
  P := GetCssPadding;

  Rect.Left := Rect.Left + B + P.Left;
  Rect.Top := Rect.Top + P.Top;
  Rect.Right := Rect.Right - B - P.Right;
  Rect.Bottom := Rect.Bottom - B - P.Bottom;

  if Rect.Right < Rect.Left then
    Rect.Right := Rect.Left;

  if Rect.Bottom < Rect.Top then
    Rect.Bottom := Rect.Top;

  inherited AlignControls(AControl, Rect);
end;

procedure TCssGroupBox.AdjustClientRect(var ARect : TRect);
begin
  inherited AdjustClientRect(ARect);
  ARect.Top := ARect.Top + GetTopOffset;
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

  if (Operation = opRemove) and
     (AComponent is TControl) and
     Assigned(FDisabledByParent) then
  begin
    FDisabledByParent.Remove(AComponent);
  end;
end;

procedure TCssGroupBox.ApplyDeclaration(const AName, AValue: string);
var
  S: string;
begin
  if AName = 'focus-within' then
  begin
    S := LowerCase(Trim(AValue));

    FShowFocusWhenChildFocused := (S = 'true') or (S = '1') or (S = 'yes');
    FShowFocusWhenChildFocusedSet := True;

    Invalidate;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssGroupBox.ChildFocusChanged(AChildFocused : Boolean);
begin
  UpdateFocusedChildState;
end;

function TCssGroupBox.GetEffectiveHoverState: Boolean;
begin
  if FShowFocusWhenChildFocused and FHasFocusedChild then
    Exit(False);

  Result := inherited GetEffectiveHoverState;
end;

procedure TCssGroupBox.SetCaption(const AValue : TCaption);
begin
  if Caption = AValue then
    Exit;

  inherited SetCaption(AValue);
  Realign;
end;

procedure TCssGroupBox.PropagateEnabledToChildren;
var
  I, Idx: Integer;
  Child: TControl;
begin
  if csLoading in ComponentState then
    Exit;

  if FPropagatingEnabled then
    Exit;

  FPropagatingEnabled := True;
  try
    if not Enabled then
    begin
      for I := 0 to ControlCount - 1 do
      begin
        Child := Controls[I];

        if not Child.Enabled then
          Continue;

        if FDisabledByParent.IndexOf(Child) < 0 then
          FDisabledByParent.Add(Child);

        Child.Enabled := False;
      end;
    end
    else
    begin
      for I := FDisabledByParent.Count - 1 downto 0 do
      begin
        Child := TControl(FDisabledByParent[I]);
        Idx := FDisabledByParent.IndexOf(Child);

        if Idx >= 0 then
          FDisabledByParent.Delete(Idx);

        if FControlsContain(Child) then
          Child.Enabled := True;
      end;
    end;
  finally
    FPropagatingEnabled := False;
  end;
end;

function TCssGroupBox.FControlsContain(AControl: TControl): Boolean;
var
  I: Integer;
begin
  for I := 0 to ControlCount - 1 do
    if Controls[I] = AControl then
      Exit(True);

  Result := False;
end;

function TCssGroupBox.HasFocusedChild: Boolean;
var
  H: HWND;
  FocusedCtl: TWinControl;
  C: TControl;
begin
  Result := False;

  H := GetFocus;
  if H = 0 then
    Exit;

  FocusedCtl := FindControl(H);
  if FocusedCtl = nil then
    Exit;

  C := FocusedCtl;
  while C <> nil do
  begin
    if C = Self then
      Exit(True);
    C := C.Parent;
  end;
end;

procedure TCssGroupBox.UpdateFocusedChildState;
var
  NewState: Boolean;
begin
  NewState := HasFocusedChild;

  if NewState <> FHasFocusedChild then
  begin
    FHasFocusedChild := NewState;

    if FShowFocusWhenChildFocused then
    begin
      RefreshStylesByState;
      Invalidate;
    end;
  end;
end;

end.
