unit CssSplitterControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, Forms, LCLType,
  LCLIntf, ExtCtrls, CssStyledControl;

type
  TCssResizeStyle = (
    crsUpdate,
    crsLine
  );

  TCssSplitter = class(TCssStyledControl)
  private
    // Drag state
    FDragging: Boolean;
    FDownScreenPos: TPoint;
    FLastScreenPos: TPoint;
    FBaseRect: TRect;

    // Drag line (crsLine mode)
    FLineRect: TRect;
    FLineVisible: Boolean;

    // Behavior
    FMinSize: Integer;
    FResizeStyle: TCssResizeStyle;
    FAutoSnap: Boolean;
    FSnapThreshold: Integer;

    // Grip appearance
    FGripColor: TColor;
    FGripColorSet: Boolean;
    FGripCount: Integer;
    FGripSize: Integer;
    FGripSpacing: Integer;

    // Events
    FOnCanResize: TCanResizeEvent;
    FOnMoved: TNotifyEvent;

    // Property setters
    procedure SetMinSize(AValue: Integer);
    procedure SetResizeStyle(AValue: TCssResizeStyle);

    // Thickness (orientation-independent Width/Height)
    function GetSplitterWidth: Integer;
    procedure SetSplitterWidth(AValue: Integer);
    function GetSplitterHeight: Integer;
    procedure SetSplitterHeight(AValue: Integer);

    // Orientation
    function IsVertical: Boolean;

    // Resize target
    function FindResizeControl: TControl;
    procedure EnsureZOrderForResize;

    // Cursor
    procedure UpdateCursor;

    // Drag line
    procedure DrawDragLine(const R: TRect);
    procedure HideDragLine;

    // Resize
    procedure ApplyResize(ADelta: Integer);
    procedure DoMoved;

    // Appearance
    function GetGripColor: TColor;
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure StyleChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure SetAlign(AValue: TAlign); override;

    // Painting
    procedure Paint; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Component notification
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Thickness: Width always means the splitter's thickness
    // (as in the standard TSplitter).
    property Width: Integer read GetSplitterWidth write SetSplitterWidth default 5;
    property Height: Integer read GetSplitterHeight write SetSplitterHeight default 150;

    // Behavior
    property Align write SetAlign default alLeft;
    property MinSize: Integer read FMinSize write SetMinSize default 25;
    property ResizeStyle: TCssResizeStyle read FResizeStyle write SetResizeStyle default crsUpdate;
    property AutoSnap: Boolean read FAutoSnap write FAutoSnap default True;
    property SnapThreshold: Integer read FSnapThreshold write FSnapThreshold default 8;

    // Grip appearance
    property GripCount: Integer read FGripCount write FGripCount default 3;
    property GripSize: Integer read FGripSize write FGripSize default 2;
    property GripSpacing: Integer read FGripSpacing write FGripSpacing default 3;

    // Events
    property OnCanResize: TCanResizeEvent read FOnCanResize write FOnCanResize;
    property OnMoved: TNotifyEvent read FOnMoved write FOnMoved;

    // Standard properties
    property Anchors;
    property Color;
    property Constraints;
    property CssTag;
    property CssID;
    property CssClass;
    property CssStyle;
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

    // Standard events
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

implementation

{ TCssSplitter }

constructor TCssSplitter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents, csSetCaption];
  DoubleBuffered := True;
  TabStop := False;

  inherited Width := 5;
  inherited Height := 150;

  Align := alLeft;

  FMinSize := 25;
  FResizeStyle := crsUpdate;
  FAutoSnap := True;
  FSnapThreshold := 8;

  FDragging := False;
  FLineVisible := False;

  FGripColorSet := False;
  FGripColor := clNone;
  FGripCount := 3;
  FGripSize := 2;
  FGripSpacing := 3;

  UpdateCursor;
end;

destructor TCssSplitter.Destroy;
begin
  HideDragLine;

  inherited Destroy;
end;

procedure TCssSplitter.Loaded;
begin
  inherited Loaded;

  UpdateCursor;
end;

procedure TCssSplitter.UpdateCursor;
begin
  // Apply the standard splitter cursor only if it has not been
  // overridden (e.g. via a CSS `cursor` property or manually at runtime).
  if inherited Cursor = crDefault then
  begin
    if IsVertical then
      inherited Cursor := crHSplit
    else
      inherited Cursor := crVSplit;
  end;
end;

// --- Width/Height: the splitter thickness does not depend on orientation. ---

function TCssSplitter.GetSplitterWidth: Integer;
begin
  if IsVertical then
    Result := inherited Width
  else
    Result := inherited Height;
end;

procedure TCssSplitter.SetSplitterWidth(AValue: Integer);
begin
  if IsVertical then
    inherited Width := AValue
  else
    inherited Height := AValue;
end;

function TCssSplitter.GetSplitterHeight: Integer;
begin
  if IsVertical then
    Result := inherited Height
  else
    Result := inherited Width;
end;

procedure TCssSplitter.SetSplitterHeight(AValue: Integer);
begin
  if IsVertical then
    inherited Height := AValue
  else
    inherited Width := AValue;
end;

// --- Align: swap Width and Height when orientation changes. ---

procedure TCssSplitter.SetAlign(AValue: TAlign);
var
  OldVertical, NewVertical: Boolean;
  Tmp: Integer;
begin
  if Align = AValue then
    Exit;

  OldVertical := IsVertical;
  inherited Align := AValue;
  NewVertical := IsVertical;

  // If orientation changed, transfer thickness between Width and Height.
  if OldVertical <> NewVertical then
  begin
    Tmp := inherited Width;
    inherited Width := inherited Height;
    inherited Height := Tmp;
  end;

  UpdateCursor;
end;

procedure TCssSplitter.SetMinSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FMinSize = AValue then
    Exit;

  FMinSize := AValue;
end;

procedure TCssSplitter.SetResizeStyle(AValue: TCssResizeStyle);
begin
  if FResizeStyle = AValue then
    Exit;

  FResizeStyle := AValue;
end;

function TCssSplitter.IsVertical: Boolean;
begin
  Result := (Align = alLeft) or (Align = alRight);
end;

function TCssSplitter.FindResizeControl: TControl;
var
  P: TWinControl;
  I, MyIdx: Integer;
  C: TControl;
begin
  Result := nil;

  P := Parent;
  if P = nil then
    Exit;

  MyIdx := -1;

  for I := 0 to P.ControlCount - 1 do
  begin
    if P.Controls[I] = Self then
    begin
      MyIdx := I;
      Break;
    end;
  end;

  if MyIdx < 0 then
    Exit;

  case Align of
    alLeft:
    begin
      for I := MyIdx - 1 downto 0 do
      begin
        C := P.Controls[I];

        if (C.Align = alLeft) and C.Visible then
          Exit(C);
      end;

      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        C := P.Controls[I];

        if (C.Align = alLeft) and C.Visible then
          Exit(C);
      end;
    end;

    alRight:
    begin
      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        C := P.Controls[I];

        if (C.Align = alRight) and C.Visible then
          Exit(C);
      end;

      for I := MyIdx - 1 downto 0 do
      begin
        C := P.Controls[I];

        if (C.Align = alRight) and C.Visible then
          Exit(C);
      end;
    end;

    alTop:
    begin
      for I := MyIdx - 1 downto 0 do
      begin
        C := P.Controls[I];

        if (C.Align = alTop) and C.Visible then
          Exit(C);
      end;

      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        C := P.Controls[I];

        if (C.Align = alTop) and C.Visible then
          Exit(C);
      end;
    end;

    alBottom:
    begin
      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        C := P.Controls[I];

        if (C.Align = alBottom) and C.Visible then
          Exit(C);
      end;

      for I := MyIdx - 1 downto 0 do
      begin
        C := P.Controls[I];

        if (C.Align = alBottom) and C.Visible then
          Exit(C);
      end;
    end;

    else
  end;
end;

procedure TCssSplitter.EnsureZOrderForResize;
var
  P: TWinControl;
  C: TControl;
  MyIdx, I: Integer;
  FoundOnCorrectSide: Boolean;
begin
  P := Parent;
  if P = nil then
    Exit;

  MyIdx := -1;

  for I := 0 to P.ControlCount - 1 do
  begin
    if P.Controls[I] = Self then
    begin
      MyIdx := I;
      Break;
    end;
  end;

  if MyIdx < 0 then
    Exit;

  FoundOnCorrectSide := False;
  C := nil;

  case Align of
    alLeft:
    begin
      for I := MyIdx - 1 downto 0 do
      begin
        if (P.Controls[I].Align = alLeft) and P.Controls[I].Visible then
        begin
          FoundOnCorrectSide := True;
          Break;
        end;
      end;

      if not FoundOnCorrectSide then
      begin
        for I := MyIdx + 1 to P.ControlCount - 1 do
        begin
          if (P.Controls[I].Align = alLeft) and P.Controls[I].Visible then
          begin
            C := P.Controls[I];
            Break;
          end;
        end;

        if C <> nil then
          BringToFront;
      end;
    end;

    alRight:
    begin
      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        if (P.Controls[I].Align = alRight) and P.Controls[I].Visible then
        begin
          FoundOnCorrectSide := True;
          Break;
        end;
      end;

      if not FoundOnCorrectSide then
      begin
        for I := MyIdx - 1 downto 0 do
        begin
          if (P.Controls[I].Align = alRight) and P.Controls[I].Visible then
          begin
            C := P.Controls[I];
            Break;
          end;
        end;

        if C <> nil then
          SendToBack;
      end;
    end;

    alTop:
    begin
      for I := MyIdx - 1 downto 0 do
      begin
        if (P.Controls[I].Align = alTop) and P.Controls[I].Visible then
        begin
          FoundOnCorrectSide := True;
          Break;
        end;
      end;

      if not FoundOnCorrectSide then
      begin
        for I := MyIdx + 1 to P.ControlCount - 1 do
        begin
          if (P.Controls[I].Align = alTop) and P.Controls[I].Visible then
          begin
            C := P.Controls[I];
            Break;
          end;
        end;

        if C <> nil then
          BringToFront;
      end;
    end;

    alBottom:
    begin
      for I := MyIdx + 1 to P.ControlCount - 1 do
      begin
        if (P.Controls[I].Align = alBottom) and P.Controls[I].Visible then
        begin
          FoundOnCorrectSide := True;
          Break;
        end;
      end;

      if not FoundOnCorrectSide then
      begin
        for I := MyIdx - 1 downto 0 do
        begin
          if (P.Controls[I].Align = alBottom) and P.Controls[I].Visible then
          begin
            C := P.Controls[I];
            Break;
          end;
        end;

        if C <> nil then
          SendToBack;
      end;
    end;

    else
  end;
end;

procedure TCssSplitter.ResetStyle;
begin
  FGripColorSet := False;
  FGripColor := clNone;

  inherited ResetStyle;
end;

procedure TCssSplitter.StyleChanged;
begin
  inherited StyleChanged;

  // After CSS styles are applied, the cursor may be reset to crDefault
  // (the base TCssStyledControl class does this in ResetStyle).
  // We call UpdateCursor to restore the splitter cursor
  // if a custom cursor is not set via CSS.
  UpdateCursor;
end;

procedure TCssSplitter.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'grip-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FGripColor := C;
      FGripColorSet := True;
    end;
    Exit;
  end
  else if AName = 'grip-count' then
  begin
    if TryStrToInt(AValue, Px) and (Px >= 0) then
      FGripCount := Px;
    Exit;
  end
  else if AName = 'grip-size' then
  begin
    if ParseCssLengthPx(AValue, Px) and (Px >= 0) then
      FGripSize := Px;
    Exit;
  end
  else if AName = 'grip-spacing' then
  begin
    if ParseCssLengthPx(AValue, Px) and (Px >= 0) then
      FGripSpacing := Px;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

function TCssSplitter.GetGripColor: TColor;
begin
  if FGripColorSet and (FGripColor <> clNone) then
    Result := FGripColor
  else
    Result := GetCssTextColor;

  if Result = clDefault then
    Result := clBtnShadow;
end;

procedure TCssSplitter.Paint;
var
  R, GripR: TRect;
  BG, GripC: TColor;
  CX, CY, I, Offset, TotalLen: Integer;
begin
  inherited Paint;

  R := ClientRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  BG := GetCssBackgroundColor;

  if BG <> clNone then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := BG;
    Canvas.FillRect(R);
  end;

  if (FGripCount > 0) and (FGripSize > 0) then
  begin
    GripC := GetGripColor;

    if GripC <> clNone then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GripC;
      Canvas.Pen.Style := psClear;

      CX := (R.Left + R.Right) div 2;
      CY := (R.Top + R.Bottom) div 2;

      TotalLen := FGripCount * FGripSize + (FGripCount - 1) * FGripSpacing;

      if IsVertical then
      begin
        Offset := CY - TotalLen div 2;
        GripR.Left := CX - FGripSize div 2;
        GripR.Right := GripR.Left + FGripSize;

        for I := 0 to FGripCount - 1 do
        begin
          GripR.Top := Offset;
          GripR.Bottom := GripR.Top + FGripSize;
          Canvas.FillRect(GripR);
          Inc(Offset, FGripSize + FGripSpacing);
        end;
      end
      else
      begin
        Offset := CX - TotalLen div 2;
        GripR.Top := CY - FGripSize div 2;
        GripR.Bottom := GripR.Top + FGripSize;

        for I := 0 to FGripCount - 1 do
        begin
          GripR.Left := Offset;
          GripR.Right := GripR.Left + FGripSize;
          Canvas.FillRect(GripR);
          Inc(Offset, FGripSize + FGripSpacing);
        end;
      end;
    end;
  end;
end;

procedure TCssSplitter.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if Button <> mbLeft then
    Exit;

  EnsureZOrderForResize;

  if FindResizeControl = nil then
    Exit;

  if Parent <> nil then
  begin
    Parent.Realign;
    Parent.Invalidate;
  end;

  Invalidate;

  FDragging := True;
  FDownScreenPos := ClientToScreen(Point(X, Y));
  FLastScreenPos := FDownScreenPos;
  FBaseRect := BoundsRect;

  MouseCapture := True;
end;

procedure TCssSplitter.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Delta: Integer;
  ScreenPos: TPoint;
  R: TRect;
begin
  inherited MouseMove(Shift, X, Y);

  if not FDragging then
    Exit;

  ScreenPos := ClientToScreen(Point(X, Y));

  if FindResizeControl = nil then
    Exit;

  if FResizeStyle = crsLine then
  begin
    if IsVertical then
      Delta := ScreenPos.X - FDownScreenPos.X
    else
      Delta := ScreenPos.Y - FDownScreenPos.Y;

    R := FBaseRect;

    if IsVertical then
      OffsetRect(R, Delta, 0)
    else
      OffsetRect(R, 0, Delta);

    if not FLineVisible then
    begin
      FLineRect := R;
      FLineVisible := True;
      DrawDragLine(FLineRect);
    end
    else if (FLineRect.Left <> R.Left) or (FLineRect.Top <> R.Top) then
    begin
      DrawDragLine(FLineRect);
      FLineRect := R;
      DrawDragLine(FLineRect);
    end;
  end
  else
  begin
    if IsVertical then
      Delta := ScreenPos.X - FLastScreenPos.X
    else
      Delta := ScreenPos.Y - FLastScreenPos.Y;

    if Delta <> 0 then
    begin
      ApplyResize(Delta);
      FLastScreenPos := ScreenPos;
    end;
  end;
end;

procedure TCssSplitter.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Delta: Integer;
  ScreenPos: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);

  if not FDragging then
    Exit;

  FDragging := False;
  MouseCapture := False;

  if FResizeStyle = crsLine then
  begin
    if FLineVisible then
    begin
      DrawDragLine(FLineRect);
      FLineVisible := False;
    end;

    ScreenPos := ClientToScreen(Point(X, Y));

    if IsVertical then
      Delta := ScreenPos.X - FDownScreenPos.X
    else
      Delta := ScreenPos.Y - FDownScreenPos.Y;

    if Delta <> 0 then
      ApplyResize(Delta);
  end;
end;

procedure TCssSplitter.DrawDragLine(const R: TRect);
var
  ScreenDC: HDC;
  ScreenR: TRect;
  P1, P2: TPoint;
  ScreenCanvas: TCanvas;
begin
  if Parent = nil then
    Exit;

  P1 := Parent.ClientToScreen(Point(R.Left, R.Top));
  P2 := Parent.ClientToScreen(Point(R.Right, R.Bottom));
  ScreenR := Rect(P1.X, P1.Y, P2.X, P2.Y);

  ScreenDC := LCLIntf.GetDC(0);

  if ScreenDC = 0 then
    Exit;

  try
    ScreenCanvas := TCanvas.Create;
    try
      ScreenCanvas.Handle := ScreenDC;
      ScreenCanvas.Pen.Mode := pmNot;
      ScreenCanvas.Pen.Style := psSolid;
      ScreenCanvas.Pen.Color := clBlack;
      ScreenCanvas.Brush.Style := bsSolid;
      ScreenCanvas.Brush.Color := clBlack;
      ScreenCanvas.Rectangle(ScreenR);
      ScreenCanvas.Handle := 0;
    finally
      ScreenCanvas.Free;
    end;
  finally
    LCLIntf.ReleaseDC(0, ScreenDC);
  end;
end;

procedure TCssSplitter.HideDragLine;
begin
  if FLineVisible then
  begin
    DrawDragLine(FLineRect);
    FLineVisible := False;
  end;
end;

procedure TCssSplitter.ApplyResize(ADelta: Integer);
var
  C: TControl;
  NewSize: Integer;
  CanR: Boolean;
begin
  if ADelta = 0 then
    Exit;

  C := FindResizeControl;

  if C = nil then
    Exit;

  case Align of
    alLeft:   NewSize := C.Width + ADelta;
    alRight:  NewSize := C.Width - ADelta;
    alTop:    NewSize := C.Height + ADelta;
    alBottom: NewSize := C.Height - ADelta;
  else
    Exit;
  end;

  if NewSize < FMinSize then
    NewSize := FMinSize;

  CanR := True;

  if Assigned(FOnCanResize) then
    FOnCanResize(Self, NewSize, CanR);

  if not CanR then
    Exit;

  case Align of
    alLeft, alRight: C.Width := NewSize;
    alTop, alBottom: C.Height := NewSize;
    else
  end;

  if Parent <> nil then
  begin
    Parent.Realign;
    Parent.Invalidate;
  end;

  Invalidate;

  DoMoved;
end;

procedure TCssSplitter.DoMoved;
begin
  if Assigned(FOnMoved) then
    FOnMoved(Self);
end;

procedure TCssSplitter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
end;

end.
