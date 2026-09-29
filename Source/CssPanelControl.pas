unit CssPanelControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, CssStyledControl;

type
  TCssPanel = class(TCssStyledControl)
  private
    FPropagatingEnabled: Boolean;
    procedure PropagateEnabledToChildren;
    procedure ForceDesignTimeRepaint;
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;

    // State changes
    procedure EnabledChanged; override;
    procedure SetEnabled(AValue: Boolean); override;

    // Layout
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
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

  Caption := 'CssPanel';

  Width := 185;
  Height := 41;

  FPropagatingEnabled := False;
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

procedure TCssPanel.Loaded;
begin
  inherited Loaded;

  if not Enabled then
    PropagateEnabledToChildren;
end;

procedure TCssPanel.InitTextProps;
begin
  SetTextAlign(ctaCenter);
  SetVAlign(cvaMiddle);
  SetWordWrap(True);
end;

procedure TCssPanel.StyleChanged;
begin
  inherited StyleChanged;

  // If border/padding changed, we need to recalculate the layout
  // of child controls with Align.
  Realign;
end;

procedure TCssPanel.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  if AutoSize then
    AdjustSize;

  Invalidate;
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
end;

end.
