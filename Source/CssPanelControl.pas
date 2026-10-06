unit CssPanelControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, LCLIntf, CssStyledControl, Forms;

type
  TCssPanel = class(TCssStyledControl)
  private
    FPropagatingEnabled: Boolean;
    FShowFocusWhenChildFocused: Boolean;
    FShowFocusWhenChildFocusedSet: Boolean;
    FHasFocusedChild: Boolean;

    { Guards against recursion: assigning BorderSpacing on a child
      triggers a Realign, which calls back into AlignControls. }
    FSyncingCaptionSpacing: Boolean;

    { Last caption height that this panel assigned to its anchored
      children. 0 means "we have not assigned anything yet". Used to
      tell our own values apart from user-supplied ones: a child whose
      BorderSpacing.Top equals this value is treated as ours and may
      be updated; any other non-zero value is respected as user data. }
    FAppliedCaptionSpacing: Integer;

    FResyncPending: Boolean;

    procedure PropagateEnabledToChildren;
    procedure ForceDesignTimeRepaint;
    function  HasFocusedChild: Boolean;
    procedure UpdateFocusedChildState;

    { Height of the caption strip that must be reserved above the
      content, in device pixels. 0 when there is no caption. }
    function  GetCaptionContentOffset: Integer;

    { True only when the child's top edge is anchored to the panel's
      own top edge. Returns False when the child uses AnchorSide to
      anchor its top to a sibling, or when it is anchored to another
      edge of the panel. }
    function  IsAnchoredToPanelTop(AControl: TControl): Boolean;

    { Assigns BorderSpacing.Top to one anchored child so that it sits
      below the caption. ACapH is the value computed once per pass by
      AutoSpaceAllChildren.

      Overwrites:
        - a zero value, meaning the child has not been spaced yet;
        - a value that equals FAppliedCaptionSpacing, meaning it is
          ours from a previous pass.
      Never overwrites anything else. }
    procedure AutoSpaceAnchoredChild(AControl: TControl; ACapH: Integer);

    { Runs AutoSpaceAnchoredChild for every child and remembers the
      caption height used for this pass. }
    procedure AutoSpaceAllChildren;

    procedure QueueAutoSpace;
    procedure DoQueuedAutoSpace(AData: PtrInt);
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure Paint; override;
    procedure ChildFocusChanged(AChildFocused: Boolean); override;

    // Hover
    function GetEffectiveHoverState: Boolean; override;

    // State changes
    procedure EnabledChanged; override;
    procedure SetEnabled(AValue: Boolean); override;

    // Layout
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure AdjustClientRect(var ARect: TRect); override;

    // Caption helpers
    function GetCaptionHeight(AvailableWidth: Integer): Integer;
    function ShouldPaintCaption: Boolean; override;
    procedure SetCaption(const AValue: TCaption); override;

    function GetDefaultCaption: string; override;
    procedure Resize; override;
    procedure ChangeScale(M, D: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    function IsFocusWithin: Boolean;

    { Re-runs caption spacing for the current children. Can be called
      manually after adding children from code, if the automatic pass
      in AlignControls has not run yet. }
    procedure RefreshChildSpacing;
  published
    // Standard properties
    property Align;
    property Anchors;
    property AutoSize;
    property Caption;
    property Color;
    property Constraints;
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

    // Text layout
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property Layout: TTextLayout read GetLayout write SetLayout;
    property WordWrap: Boolean read GetWordWrapProp write SetWordWrapProp;

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

{ TCssPanel }

constructor TCssPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];

  Width := 185;
  Height := 41;

  FPropagatingEnabled := False;
  FShowFocusWhenChildFocused := False;
  FHasFocusedChild := False;
  FSyncingCaptionSpacing := False;
  FAppliedCaptionSpacing := 0;
end;

function TCssPanel.IsFocusWithin : Boolean;
begin
  Result := FHasFocusedChild;
end;

procedure TCssPanel.PropagateEnabledToChildren;
var
  I: Integer;
begin
  if FPropagatingEnabled then
    Exit;

  FPropagatingEnabled := True;
  try
    for I := 0 to ControlCount - 1 do
    begin
      if Controls[I].Enabled <> Enabled then
        Controls[I].Enabled := Enabled;
    end;
  finally
    FPropagatingEnabled := False;
  end;
end;

procedure TCssPanel.ForceDesignTimeRepaint;
var
  I: Integer;
begin
  if FPropagatingEnabled then
    Exit;

  FPropagatingEnabled := True;
  try
    for I := 0 to ControlCount - 1 do
      Controls[I].Enabled := Enabled;

    UpdateEnabledVisualState;

    for I := 0 to ControlCount - 1 do
      if Controls[I] is TCssStyledControl then
        TCssStyledControl(Controls[I]).UpdateEnabledVisualState;

    if Parent <> nil then
      Parent.Invalidate;
  finally
    FPropagatingEnabled := False;
  end;
end;

function TCssPanel.HasFocusedChild: Boolean;
var
  H: HWND;
  aFocused: TWinControl;
  C: TControl;
begin
  Result := False;

  H := GetFocus;
  if H = 0 then
    Exit;

  aFocused := FindControl(H);
  if aFocused = nil then
    Exit;

  C := aFocused;
  while C <> nil do
  begin
    if C = Self then
      Exit(True);
    C := C.Parent;
  end;
end;

procedure TCssPanel.UpdateFocusedChildState;
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

function TCssPanel.GetCaptionContentOffset: Integer;
var
  B: Integer;
  Pad: TRect;
begin
  Result := 0;

  if Caption = '' then
    Exit;

  if not HandleAllocated then
    Exit;

  B := GetCssBorderWidth;
  Pad := GetCssPadding;

  Result := GetCaptionHeight(
    ClientWidth - B * 2 - Pad.Left - Pad.Right);

  if Result < 0 then
    Result := 0;
end;

function TCssPanel.IsAnchoredToPanelTop(AControl: TControl): Boolean;
begin
  Result := False;
  if AControl = nil then Exit;
  if not (akTop in AControl.Anchors) then Exit;
  Result := (AControl.AnchorSide[akTop].Control = Self)
            and (AControl.AnchorSide[akTop].Side = asrTop);
end;

procedure TCssPanel.AutoSpaceAnchoredChild(AControl: TControl; ACapH: Integer);
var
  Current: Integer;
begin
  if AControl = nil then
    Exit;

  Current := AControl.BorderSpacing.Top;

  if AControl.Align <> alNone then
  begin
    { Aligned children get the caption offset via AdjustClientRect.
      If BorderSpacing.Top is our own leftover from the pass that ran
      while the child was still alNone, clear it - otherwise the offset
      would be applied twice. }
    if (Current <> 0) and (Current = FAppliedCaptionSpacing) then
      AControl.BorderSpacing.Top := 0;
    Exit;
  end;

  if not IsAnchoredToPanelTop(AControl) then
  begin
    { Same idea: a child that stopped being anchored to the panel's
      top edge must not keep our stale spacing. }
    if (Current <> 0) and (Current = FAppliedCaptionSpacing) then
      AControl.BorderSpacing.Top := 0;
    Exit;
  end;

  if (Current <> 0) and (Current <> FAppliedCaptionSpacing) then
    Exit;

  if Current = ACapH then
    Exit;

  AControl.BorderSpacing.Top := ACapH;
end;

procedure TCssPanel.AutoSpaceAllChildren;
var
  I, CapH: Integer;
begin
  if FSyncingCaptionSpacing then
    Exit;

  { During a layout transition the panel may briefly end up with zero
    size (e.g. while anchors are being resolved). In that state the
    caption measurement returns 0 and any BorderSpacing assignment we
    make would be garbage; skip until a stable size is available. }
  if (Width <= 0) or (Height <= 0) then
    Exit;

  FSyncingCaptionSpacing := True;
  DisableAlign;
  try
    CapH := GetCaptionContentOffset;

    for I := 0 to ControlCount - 1 do
      AutoSpaceAnchoredChild(Controls[I], CapH);

    FAppliedCaptionSpacing := CapH;
  finally
    EnableAlign;
    FSyncingCaptionSpacing := False;
  end;
end;

procedure TCssPanel.QueueAutoSpace;
begin
  if FResyncPending then
    Exit;
  if csDestroying in ComponentState then
    Exit;

  FResyncPending := True;
  Application.QueueAsyncCall(@DoQueuedAutoSpace, 0);
end;

procedure TCssPanel.DoQueuedAutoSpace(AData: PtrInt);
begin
  FResyncPending := False;

  if csDestroying in ComponentState then
    Exit;

  AutoSpaceAllChildren;
end;

procedure TCssPanel.RefreshChildSpacing;
begin
  AutoSpaceAllChildren;
end;

procedure TCssPanel.Loaded;
begin
  inherited Loaded;

  if not Enabled then
    PropagateEnabledToChildren;

  UpdateFocusedChildState;

  { Covers children created by code where Parent was assigned before
    Anchors, so the AlignControls pass could not have seen the final
    anchored state yet. }
  AutoSpaceAllChildren;
end;

procedure TCssPanel.InitTextProps;
begin
  SetTextAlign(ctaCenter);
  SetVAlign(cvaTop);
  SetWordWrap(True);
end;

procedure TCssPanel.StyleChanged;
begin
  inherited StyleChanged;

  { Border, padding, font and other CSS-driven values may have changed,
    so the caption height and the child layout must be recalculated. }
  Realign;
  AutoSpaceAllChildren;
end;

procedure TCssPanel.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Realign;
  AutoSpaceAllChildren;
  Invalidate;
end;

procedure TCssPanel.ResetStyle;
begin
  inherited ResetStyle;
end;

procedure TCssPanel.ApplyDeclaration(const AName, AValue: string);
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

procedure TCssPanel.Paint;
var
  B: Integer;
  P: TRect;
  CaptionR: TRect;
  CapH: Integer;
begin
  inherited Paint;

  if Caption <> '' then
  begin
    B := GetCssBorderWidth;
    P := GetCssPadding;

    CaptionR := ClientRect;
    CaptionR.Left := CaptionR.Left + B + P.Left;
    CaptionR.Top := CaptionR.Top + B + P.Top;
    CaptionR.Right := CaptionR.Right - B - P.Right;

    CapH := GetCaptionHeight(CaptionR.Width);
    CaptionR.Bottom := CaptionR.Top + CapH;

    if (CaptionR.Right > CaptionR.Left) and
       (CaptionR.Bottom > CaptionR.Top) then
    begin
      DrawCaptionToCanvas(Canvas, CaptionR, Caption);
    end;
  end;

  if FShowFocusWhenChildFocused and
     ShowFocusRect and
     FHasFocusedChild and
     Enabled then
  begin
    DrawFocusRect(Canvas, ClientRect);
  end;
end;

procedure TCssPanel.ChildFocusChanged(AChildFocused : Boolean);
begin
  UpdateFocusedChildState;
end;

function TCssPanel.GetEffectiveHoverState : Boolean;
begin
  if FShowFocusWhenChildFocused and FHasFocusedChild then
    Exit(False);

  Result := inherited GetEffectiveHoverState;
end;

procedure TCssPanel.EnabledChanged;
begin
  inherited EnabledChanged;
end;

procedure TCssPanel.SetEnabled(AValue : Boolean);
begin
  inherited SetEnabled(AValue);

  if csDesigning in ComponentState then
    ForceDesignTimeRepaint;
end;

procedure TCssPanel.AlignControls(AControl: TControl; var Rect: TRect);
var
  B: Integer;
  P: TRect;
begin
  B := GetCssBorderWidth;
  P := GetCssPadding;

  Rect.Left := Rect.Left + B + P.Left;
  Rect.Top := Rect.Top + B + P.Top;
  Rect.Right := Rect.Right - B - P.Right;
  Rect.Bottom := Rect.Bottom - B - P.Bottom;

  if Rect.Right < Rect.Left then
    Rect.Right := Rect.Left;

  if Rect.Bottom < Rect.Top then
    Rect.Bottom := Rect.Top;

  inherited AlignControls(AControl, Rect);

  if (AControl <> nil) and
     (not Enabled) and
     AControl.Enabled and
     (not FPropagatingEnabled) then
  begin
    FPropagatingEnabled := True;
    try
      AControl.Enabled := False;
    finally
      FPropagatingEnabled := False;
    end;
  end;

  { AControl = nil means a full layout pass, which is what happens when
    a child is added or removed. This is the point where newly added
    anchored children get their caption offset. }
  if AControl = nil then
    QueueAutoSpace;
end;

procedure TCssPanel.AdjustClientRect(var ARect: TRect);
var
  CapH: Integer;
begin
  inherited AdjustClientRect(ARect);

  CapH := GetCaptionHeight(ARect.Width);
  if CapH > 0 then
    ARect.Top := ARect.Top + CapH;
end;

function TCssPanel.GetCaptionHeight(AvailableWidth: Integer): Integer;
var
  S: TSize;
begin
  Result := 0;

  if Caption = '' then
    Exit;

  if (not HandleAllocated) or (AvailableWidth <= 0) then
    Exit(0);

  AssignCssFontToFont(Canvas.Font);

  if HtmlMode then
  begin
    S := MeasureHtmlTextSize(Caption, AvailableWidth);
    Result := S.cy;
  end
  else
    Result := Canvas.TextHeight('Ag');

    Inc(Result, ScalePx(2));
end;

function TCssPanel.ShouldPaintCaption : Boolean;
begin
  Result := False;
end;

procedure TCssPanel.SetCaption(const AValue : TCaption);
begin
  if Caption = AValue then
    Exit;

  inherited SetCaption(AValue);

  if not (csLoading in ComponentState) then
  begin
    Realign;
    AutoSpaceAllChildren;
  end;
end;

function TCssPanel.GetDefaultCaption : string;
begin
  Result := 'CssPanel';
end;

procedure TCssPanel.Resize;
begin
  inherited Resize;

  { The panel width may have changed, which can re-wrap an HTML caption
    onto more or fewer lines and change the caption height. }
  QueueAutoSpace;
end;

procedure TCssPanel.ChangeScale(M, D : Integer);
begin
  inherited ChangeScale(M, D);

  { Font and DPI changed, so the caption height changed as well. }
  AutoSpaceAllChildren;
end;

end.
