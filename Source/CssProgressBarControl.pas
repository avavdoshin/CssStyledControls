unit CssProgressBarControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, ExtCtrls,
  LMessages, IntfGraphics, FPImage, CssStyledControl, CssAntiAlias;

type
  TCssProgressBarOrientation = (pbHorizontal, pbVertical);
  TCssProgressBarState = (pbsNormal, pbsError, pbsPaused);
  TCssProgressBarStyle = (pbContinuous, pbMarquee);

  TCssProgressBar = class(TCssStyledControl)
  private
    // Range / position
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FStep: Integer;

    // Behavior
    FOrientation: TCssProgressBarOrientation;
    FBarState: TCssProgressBarState;
    FStyle: TCssProgressBarStyle;
    FShowText: Boolean;
    FSmooth: Boolean;
    FMarqueeInterval: Integer;

    // Smooth position animation
    FDisplayPos: Double;      // displayed value, in [FMin..FMax]
    FAnimTarget: Double;
    FAnimStart: Double;
    FAnimStartTime: QWord;

    // Marquee
    FMarqueePos: Double;      // 0..1
    FMarqueeDir: Integer;     // +1 / -1
    FMarqueeLastTime: QWord;

    FMarqueeAmplitude: Double;
    FMarqueeAmplitudeTarget: Double;
    FMarqueeAmpStart: Double;
    FMarqueeAmpStartTime: QWord;

    // Shared timer (position + marquee)
    FTimer: TIdleTimer;
    FLastTickMS: QWord;

    // CSS appearance
    FProgressColor: TColor;
    FProgressColorSet: Boolean;
    FProgressErrorColor: TColor;
    FProgressErrorColorSet: Boolean;
    FProgressPausedColor: TColor;
    FProgressPausedColorSet: Boolean;
    FProgressRadius: Integer;
    FProgressRadiusSet: Boolean;
    FProgressTextColor: TColor;
    FProgressTextColorSet: Boolean;

    // Setters
    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetStep(AValue: Integer);
    procedure SetOrientation(AValue: TCssProgressBarOrientation);
    procedure SetBarState(AValue: TCssProgressBarState);
    procedure SetStyle(AValue: TCssProgressBarStyle);
    procedure SetShowText(AValue: Boolean);
    procedure SetSmooth(AValue: Boolean);
    procedure SetMarqueeInterval(AValue: Integer);

    // Appearance getters
    function GetProgressColor: TColor;
    function GetProgressRadius: Integer;
    function GetEffectiveProgressColor: TColor;
    function GetEffectiveProgressRadius: Integer;
    function GetEffectiveProgressTextColor: TColor;

    // Animation
    procedure UpdateTimer;
    procedure TimerTick(Sender: TObject);
    procedure StartPositionAnimation;
    procedure SnapPositionAnimation;
    function GetDisplayFraction: Double;

    // Helpers
    function RangeSpan: Integer;
    function ClampPosition(AValue: Integer): Integer;
    function IsMarquee: Boolean;
  protected
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure HtmlModeChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    function ShouldPaintCaption: Boolean; override;

    procedure Paint; override;
    procedure Resize; override;

    function GetDefaultCaption: string; override;

    procedure SetVisible(AValue: Boolean); override;

    procedure CMShowingChanged(var Message: TLMessage); message CM_SHOWINGCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure StepIt;
    procedure StepBy(ADelta: Integer);

    property DisplayFraction: Double read GetDisplayFraction;
  published
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 0;
    property Step: Integer read FStep write SetStep default 10;

    property Orientation: TCssProgressBarOrientation
      read FOrientation write SetOrientation default pbHorizontal;
    property State: TCssProgressBarState
      read FBarState write SetBarState default pbsNormal;
    property Style: TCssProgressBarStyle
      read FStyle write SetStyle default pbContinuous;

    property ShowText: Boolean read FShowText write SetShowText default False;
    property Smooth: Boolean read FSmooth write SetSmooth default True;
    property MarqueeInterval: Integer
      read FMarqueeInterval write SetMarqueeInterval default 30;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

const
  PROGRESS_ANIM_DURATION_MS = 250;
  PROGRESS_TIMER_INTERVAL_MS = 16;

  procedure CropBitmapToOpaque(ABitmap: TBitmap);
  var
    Img, NewImg: TLazIntfImage;
    X, Y, MinX, MinY, MaxX, MaxY, NW, NH: Integer;
    Pix: TFPColor;
    NewBmp: TBitmap;
  begin
    if (ABitmap = nil) or ABitmap.Empty then Exit;

    Img := ABitmap.CreateIntfImage;
    if Img = nil then Exit;
    try
      MinX := Img.Width;
      MinY := Img.Height;
      MaxX := -1;
      MaxY := -1;

      for Y := 0 to Img.Height - 1 do
        for X := 0 to Img.Width - 1 do
        begin
          Pix := Img.Colors[X, Y];
          if (Pix.Alpha shr 8) > 4 then
          begin
            if X < MinX then MinX := X;
            if Y < MinY then MinY := Y;
            if X > MaxX then MaxX := X;
            if Y > MaxY then MaxY := Y;
          end;
        end;

      if (MaxX < 0) or (MaxY < 0) then Exit;

      if MinX > 0 then Dec(MinX);
      if MinY > 0 then Dec(MinY);
      if MaxX < Img.Width  - 1 then Inc(MaxX);
      if MaxY < Img.Height - 1 then Inc(MaxY);

      NW := MaxX - MinX + 1;
      NH := MaxY - MinY + 1;

      if (NW = Img.Width) and (NH = Img.Height) then Exit;

      NewBmp := TBitmap.Create;
      try
        NewBmp.PixelFormat := pf32bit;
        NewBmp.SetSize(NW, NH);

        NewImg := NewBmp.CreateIntfImage;
        try
          for Y := 0 to NH - 1 do
            for X := 0 to NW - 1 do
              NewImg.Colors[X, Y] := Img.Colors[MinX + X, MinY + Y];
          NewBmp.LoadFromIntfImage(NewImg);
        finally
          NewImg.Free;
        end;

        ABitmap.Assign(NewBmp);
      finally
        NewBmp.Free;
      end;
    finally
      Img.Free;
    end;
  end;

  function RenderTextMask(ACanvas: TCanvas; const AText: string;
    AVertical: Boolean): TBitmap;
  const
    SS = 3;
    PAD = 2;
  var
    Src, Dst, Rot: TBitmap;
    SrcImg, DstImg, RotImg: TLazIntfImage;
    BaseHeight: Integer;
    SSW, SSH, DstW, DstH: Integer;
    X, Y, XX, YY: Integer;
    SrcPix, DstPix: TFPColor;
    Sum: Int64;
    Count: Integer;

    procedure ApplyFont;
    begin
      Src.Canvas.Font.Assign(ACanvas.Font);
      Src.Canvas.Font.Color := clWhite;
      Src.Canvas.Font.Quality := fqNonAntialiased;
      Src.Canvas.Font.Height := BaseHeight * SS;
    end;

  begin
    Result := nil;
    if AText = '' then Exit;

    BaseHeight := ACanvas.Font.Height;
    if BaseHeight = 0 then
      BaseHeight := -13;

    Src := TBitmap.Create;
    try
      Src.PixelFormat := pf24bit;

      ApplyFont;
      SSW := Src.Canvas.TextWidth(AText) + PAD * SS * 2;
      SSH := Src.Canvas.TextHeight(AText) + PAD * SS * 2;
      if (SSW <= 0) or (SSH <= 0) then Exit;

      Src.SetSize(SSW, SSH);
      ApplyFont;

      Src.Canvas.Brush.Style := bsSolid;
      Src.Canvas.Brush.Color := clBlack;
      Src.Canvas.FillRect(0, 0, SSW, SSH);
      Src.Canvas.Brush.Style := bsClear;
      Src.Canvas.TextOut(PAD * SS, PAD * SS, AText);

      DstW := SSW div SS;
      DstH := SSH div SS;
      if (DstW <= 0) or (DstH <= 0) then Exit;

      Dst := TBitmap.Create;
      try
        Dst.PixelFormat := pf32bit;
        Dst.SetSize(DstW, DstH);

        SrcImg := Src.CreateIntfImage;
        try
          DstImg := Dst.CreateIntfImage;
          try
            Count := SS * SS;

            for Y := 0 to DstH - 1 do
              for X := 0 to DstW - 1 do
              begin
                Sum := 0;
                for YY := 0 to SS - 1 do
                  for XX := 0 to SS - 1 do
                  begin
                    SrcPix := SrcImg.Colors[X * SS + XX, Y * SS + YY];
                    Inc(Sum, SrcPix.Red shr 8);
                  end;

                DstPix.Red   := $FFFF;
                DstPix.Green := $FFFF;
                DstPix.Blue  := $FFFF;
                DstPix.Alpha := (Sum * 257) div Count;

                DstImg.Colors[X, Y] := DstPix;
              end;

            Dst.LoadFromIntfImage(DstImg);
          finally
            DstImg.Free;
          end;
        finally
          SrcImg.Free;
        end;

        CropBitmapToOpaque(Dst);

        if AVertical then
        begin
          Rot := TBitmap.Create;
          try
            Rot.PixelFormat := pf32bit;
            Rot.SetSize(Dst.Height, Dst.Width);

            DstImg := Dst.CreateIntfImage;
            try
              RotImg := Rot.CreateIntfImage;
              try
                for Y := 0 to DstImg.Height - 1 do
                  for X := 0 to DstImg.Width - 1 do
                    RotImg.Colors[Y, DstImg.Width - 1 - X] :=
                      DstImg.Colors[X, Y];
                Rot.LoadFromIntfImage(RotImg);
              finally
                RotImg.Free;
              end;
            finally
              DstImg.Free;
            end;

            Result := Rot;
            Rot := nil;
          finally
            if Rot <> nil then Rot.Free;
          end;
        end
        else
        begin
          Result := Dst;
          Dst := nil;
        end;
      finally
        if Dst <> nil then Dst.Free;
      end;
    finally
      Src.Free;
    end;
  end;

  procedure BlendTextMask(ACanvas: TCanvas; AX, AY: Integer;
    ABmp: TBitmap; AColor: TColor; const AClipR: TRect);
  var
    Img: TLazIntfImage;
    X, Y, DX, DY: Integer;
    Pix: TFPColor;
    A: Integer;
    SR, SG, SB, DR, DG, DB, R, G, B: Integer;
    DstColor: TColor;
  begin
    if (ACanvas = nil) or (ABmp = nil) or ABmp.Empty then Exit;
    if (AClipR.Right <= AClipR.Left) or (AClipR.Bottom <= AClipR.Top) then Exit;

    Img := ABmp.CreateIntfImage;
    if Img = nil then Exit;

    try
      SR :=  AColor         and $FF;
      SG := (AColor shr  8) and $FF;
      SB := (AColor shr 16) and $FF;

      for Y := 0 to Img.Height - 1 do
      begin
        DY := AY + Y;
        if (DY < AClipR.Top) or (DY >= AClipR.Bottom) then Continue;

        for X := 0 to Img.Width - 1 do
        begin
          DX := AX + X;
          if (DX < AClipR.Left) or (DX >= AClipR.Right) then Continue;

          Pix := Img.Colors[X, Y];
          A := Pix.Alpha shr 8;
          if A = 0 then Continue;

          if A = 255 then
            ACanvas.Pixels[DX, DY] := RGBToColor(SR, SG, SB)
          else
          begin
            DstColor := ColorToRGB(ACanvas.Pixels[DX, DY]);
            DR :=  DstColor         and $FF;
            DG := (DstColor shr  8) and $FF;
            DB := (DstColor shr 16) and $FF;

            R := (SR * A + DR * (255 - A)) div 255;
            G := (SG * A + DG * (255 - A)) div 255;
            B := (SB * A + DB * (255 - A)) div 255;

            ACanvas.Pixels[DX, DY] := RGBToColor(R, G, B);
          end;
        end;
      end;
    finally
      Img.Free;
    end;
  end;

{ TCssProgressBar }

constructor TCssProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];

  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FStep := 10;

  FOrientation := pbHorizontal;
  FBarState := pbsNormal;
  FStyle := pbContinuous;
  FShowText := False;
  FSmooth := True;
  FMarqueeInterval := 30;

  FDisplayPos := FPosition;
  FAnimTarget := FPosition;
  FAnimStart := FPosition;
  FAnimStartTime := 0;

  FMarqueePos := 0;
  FMarqueeDir := 1;
  FMarqueeLastTime := 0;

  FMarqueeAmplitude := 0;
  FMarqueeAmplitudeTarget := 0;
  FMarqueeAmpStart := 0;
  FMarqueeAmpStartTime := 0;

  Width := 180;
  Height := 20;

  TabStop := False;
  ShowFocusRect := False;

  FLastTickMS := 0;

  FTimer := TIdleTimer.Create(Self);
  FTimer.AutoEnabled := False;
  FTimer.Interval := PROGRESS_TIMER_INTERVAL_MS;
  FTimer.OnTimer := @TimerTick;
end;

destructor TCssProgressBar.Destroy;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;

  inherited Destroy;
end;

function TCssProgressBar.RangeSpan: Integer;
begin
  Result := FMax - FMin;
  if Result < 0 then Result := 0;
end;

function TCssProgressBar.ClampPosition(AValue: Integer): Integer;
begin
  if AValue < FMin then
    Result := FMin
  else if AValue > FMax then
    Result := FMax
  else
    Result := AValue;
end;

function TCssProgressBar.IsMarquee: Boolean;
begin
  Result := FStyle = pbMarquee;
end;

function TCssProgressBar.GetDisplayFraction: Double;
var
  Span: Integer;
begin
  if IsMarquee then
    Exit(0);

  Span := RangeSpan;
  if Span <= 0 then
    Exit(0);

  Result := (FDisplayPos - FMin) / Span;
  if Result < 0 then Result := 0;
  if Result > 1 then Result := 1;
end;

procedure TCssProgressBar.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  if AValue > FMax then FMax := AValue;

  FMin := AValue;

  if FPosition < FMin then
    Position := FMin
  else if FPosition > FMax then
    Position := FMax
  else
  begin
    if FDisplayPos < FMin then FDisplayPos := FMin;
    if FDisplayPos > FMax then FDisplayPos := FMax;
    Invalidate;
  end;
end;

procedure TCssProgressBar.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  if AValue < FMin then AValue := FMin;

  FMax := AValue;

  if FPosition > FMax then
    Position := FMax
  else
  begin
    if FDisplayPos > FMax then FDisplayPos := FMax;
    Invalidate;
  end;
end;

procedure TCssProgressBar.SetPosition(AValue: Integer);
var
  Span: Integer;
begin
  AValue := ClampPosition(AValue);

  if FPosition = AValue then Exit;

  FPosition := AValue;

  if IsMarquee then
  begin
    Span := RangeSpan;
    if Span > 0 then
      FMarqueeAmplitudeTarget := (FPosition - FMin) / Span
    else
      FMarqueeAmplitudeTarget := 0;

    if FMarqueeAmplitudeTarget < 0 then FMarqueeAmplitudeTarget := 0;
    if FMarqueeAmplitudeTarget > 1 then FMarqueeAmplitudeTarget := 1;

    FMarqueeAmpStart := FMarqueeAmplitude;
    FMarqueeAmpStartTime := GetTickCount64;

    UpdateTimer;
    Invalidate;
    Exit;
  end;

  if FSmooth and HandleAllocated and Showing then
    StartPositionAnimation
  else
    SnapPositionAnimation;

  Invalidate;
end;

procedure TCssProgressBar.SetStep(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  FStep := AValue;
end;

procedure TCssProgressBar.SetOrientation(AValue: TCssProgressBarOrientation);
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;
  Invalidate;
end;

procedure TCssProgressBar.SetBarState(AValue: TCssProgressBarState);
begin
  if FBarState = AValue then Exit;
  FBarState := AValue;
  Invalidate;
end;

procedure TCssProgressBar.SetStyle(AValue: TCssProgressBarStyle);
var
  Span: Integer;
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;

  if IsMarquee then
  begin
    FMarqueePos := 0;
    FMarqueeDir := 1;
    FMarqueeLastTime := GetTickCount64;

    Span := RangeSpan;
    if Span > 0 then
      FMarqueeAmplitude := (FPosition - FMin) / Span
    else
      FMarqueeAmplitude := 0;

    if FMarqueeAmplitude < 0 then FMarqueeAmplitude := 0;
    if FMarqueeAmplitude > 1 then FMarqueeAmplitude := 1;

    FMarqueeAmplitudeTarget := FMarqueeAmplitude;
    FMarqueeAmpStart := FMarqueeAmplitude;
    FMarqueeAmpStartTime := GetTickCount64;
  end
  else
  begin
    FDisplayPos := FPosition;
    FAnimTarget := FPosition;
    FAnimStart := FPosition;
  end;

  UpdateTimer;
  Invalidate;
end;

procedure TCssProgressBar.SetShowText(AValue: Boolean);
begin
  if FShowText = AValue then Exit;
  FShowText := AValue;
  Invalidate;
end;

procedure TCssProgressBar.SetSmooth(AValue: Boolean);
begin
  if FSmooth = AValue then Exit;
  FSmooth := AValue;

  if not FSmooth then
    SnapPositionAnimation;
end;

procedure TCssProgressBar.SetMarqueeInterval(AValue: Integer);
begin
  if AValue < 5 then AValue := 5;
  FMarqueeInterval := AValue;
end;

procedure TCssProgressBar.SetVisible(AValue: Boolean);
begin
  inherited SetVisible(AValue);
  UpdateTimer;
end;

procedure TCssProgressBar.CMShowingChanged(var Message: TLMessage);
begin
  inherited;
  UpdateTimer;
end;

procedure TCssProgressBar.StartPositionAnimation;
begin
  FAnimStart := FDisplayPos;
  FAnimTarget := FPosition;
  FAnimStartTime := GetTickCount64;

  UpdateTimer;
end;

procedure TCssProgressBar.SnapPositionAnimation;
begin
  FDisplayPos := FPosition;
  FAnimTarget := FPosition;
  FAnimStart := FPosition;
  UpdateTimer;
  Invalidate;
end;

procedure TCssProgressBar.UpdateTimer;
var
  NeedTimer: Boolean;
  Designer: Boolean;
begin
  if FTimer = nil then Exit;

  Designer := csDesigning in ComponentState;
  NeedTimer := False;

  if not Designer then
  begin
    if IsMarquee and Showing then
      NeedTimer := True
    else if FSmooth and (FDisplayPos <> FAnimTarget) and Showing then
      NeedTimer := True;
  end;

  FTimer.Enabled := NeedTimer;
end;

procedure TCssProgressBar.TimerTick(Sender: TObject);
var
  Elapsed: QWord;
  T: Double;
  NowMS: QWord;
  DtMs, aStep: Double;
begin
  NowMS := GetTickCount64;
  if NowMS - FLastTickMS < 10 then
    Exit;
  FLastTickMS := NowMS;

  if IsMarquee then
  begin
    if FMarqueeLastTime = 0 then
      FMarqueeLastTime := NowMS;

    DtMs := NowMS - FMarqueeLastTime;
    FMarqueeLastTime := NowMS;

    if FMarqueeInterval > 0 then
      aStep := DtMs / (FMarqueeInterval * 20)
    else
      aStep := DtMs / 600;

    if aStep > 0.5 then aStep := 0.5;

    FMarqueePos := FMarqueePos + FMarqueeDir * aStep;

    if FMarqueePos >= 1 then
    begin
      FMarqueePos := 1;
      FMarqueeDir := -1;
    end
    else if FMarqueePos <= 0 then
    begin
      FMarqueePos := 0;
      FMarqueeDir := 1;
    end;

    if FMarqueeAmplitude <> FMarqueeAmplitudeTarget then
    begin
      Elapsed := NowMS - FMarqueeAmpStartTime;

      if Elapsed >= PROGRESS_ANIM_DURATION_MS then
        FMarqueeAmplitude := FMarqueeAmplitudeTarget
      else
      begin
        T := Elapsed / PROGRESS_ANIM_DURATION_MS;
        T := 1 - (1 - T) * (1 - T) * (1 - T);
        FMarqueeAmplitude := FMarqueeAmpStart +
          (FMarqueeAmplitudeTarget - FMarqueeAmpStart) * T;
      end;
    end;

    Repaint;
  end;

  if (not IsMarquee) and FSmooth and (FDisplayPos <> FAnimTarget) then
  begin
    Elapsed := NowMS - FAnimStartTime;

    if Elapsed >= PROGRESS_ANIM_DURATION_MS then
    begin
      FDisplayPos := FAnimTarget;
      UpdateTimer;
    end
    else
    begin
      T := Elapsed / PROGRESS_ANIM_DURATION_MS;
      T := 1 - (1 - T) * (1 - T) * (1 - T);
      FDisplayPos := FAnimStart + (FAnimTarget - FAnimStart) * T;
    end;

    Repaint;
  end;
end;

procedure TCssProgressBar.StepIt;
begin
  StepBy(FStep);
end;

procedure TCssProgressBar.StepBy(ADelta: Integer);
begin
  Position := ClampPosition(FPosition + ADelta);
end;

procedure TCssProgressBar.Loaded;
var
  Span: Integer;
begin
  inherited Loaded;

  FDisplayPos := FPosition;
  FAnimTarget := FPosition;

  Span := RangeSpan;
  if Span > 0 then
    FMarqueeAmplitude := (FPosition - FMin) / Span
  else
    FMarqueeAmplitude := 0;

  if FMarqueeAmplitude < 0 then FMarqueeAmplitude := 0;
  if FMarqueeAmplitude > 1 then FMarqueeAmplitude := 1;

  FMarqueeAmplitudeTarget := FMarqueeAmplitude;
  FMarqueeAmpStart := FMarqueeAmplitude;
  FMarqueeAmpStartTime := GetTickCount64;

  UpdateTimer;
end;

procedure TCssProgressBar.InitTextProps;
begin
  SetTextAlign(ctaCenter);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssProgressBar.StyleChanged;
begin
  inherited StyleChanged;
  Invalidate;
end;

procedure TCssProgressBar.HtmlModeChanged;
begin
  inherited HtmlModeChanged;
  Invalidate;
end;

function TCssProgressBar.ShouldPaintCaption: Boolean;
begin
  Result := False;
end;

function TCssProgressBar.GetDefaultCaption: string;
begin
  Result := '';
end;

procedure TCssProgressBar.ResetStyle;
begin
  FProgressColorSet := False;
  FProgressErrorColorSet := False;
  FProgressPausedColorSet := False;
  FProgressRadiusSet := False;
  FProgressTextColorSet := False;

  inherited ResetStyle;
end;

procedure TCssProgressBar.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'progress-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FProgressColor := C;
      FProgressColorSet := True;
    end;
    Exit;
  end;

  if AName = 'progress-text-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FProgressTextColor := C;
      FProgressTextColorSet := True;
    end;
    Exit;
  end;

  if AName = 'progress-error-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FProgressErrorColor := C;
      FProgressErrorColorSet := True;
    end;
    Exit;
  end;

  if AName = 'progress-paused-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FProgressPausedColor := C;
      FProgressPausedColorSet := True;
    end;
    Exit;
  end;

  if AName = 'progress-radius' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FProgressRadius := Px;
      FProgressRadiusSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

function TCssProgressBar.GetProgressColor: TColor;
begin
  if FProgressColorSet then
    Result := FProgressColor
  else
    Result := RGBToColor(37, 99, 235);
end;

function TCssProgressBar.GetProgressRadius: Integer;
begin
  if FProgressRadiusSet then
    Result := FProgressRadius
  else
    Result := -1;
end;

function TCssProgressBar.GetEffectiveProgressColor: TColor;
begin
  case FBarState of
    pbsError:
      if FProgressErrorColorSet then
        Result := FProgressErrorColor
      else
        Result := RGBToColor(220, 38, 38);

    pbsPaused:
      if FProgressPausedColorSet then
        Result := FProgressPausedColor
      else
        Result := RGBToColor(245, 158, 11);
  else
    Result := GetProgressColor;
  end;
end;

function TCssProgressBar.GetEffectiveProgressRadius: Integer;
var
  R: Integer;
  Pad: TRect;
begin
  R := GetProgressRadius;
  if R >= 0 then
    Exit(R);

  Pad := GetCssPadding;

  R := GetCssBorderRadius - GetCssBorderWidth - Pad.Left;
  if Pad.Top > Pad.Left then
    R := GetCssBorderRadius - GetCssBorderWidth - Pad.Top;

  if R < 0 then R := 0;
  Result := R;
end;

function TCssProgressBar.GetEffectiveProgressTextColor: TColor;
var
  RGB: LongInt;
  R, G, B, Lum: Integer;
begin
  if FProgressTextColorSet then
    Exit(FProgressTextColor);

  RGB := ColorToRGB(GetEffectiveProgressColor);
  R :=  RGB         and $FF;
  G := (RGB shr  8) and $FF;
  B := (RGB shr 16) and $FF;

  Lum := (R * 30 + G * 59 + B * 11) div 100;

  if Lum >= 128 then
    Result := clBlack
  else
    Result := clWhite;
end;

procedure TCssProgressBar.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TCssProgressBar.Paint;
var
  ContentR, FillR: TRect;
  Fraction, PosFraction: Double;
  FillColor, TrackColor: TColor;
  TrackTextColor, FillTextColor: TColor;
  FillRadius, Span: Integer;
  FillRadii: TCssCornerRadii;
  PercentText: string;
  Mask: TBitmap;
  TextDX, TextDY: Integer;
  ClipTrack, ClipFill, R: TRect;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
begin
  inherited Paint;

  ContentR := GetContentRect;
  if (ContentR.Right <= ContentR.Left) or (ContentR.Bottom <= ContentR.Top) then
    Exit;

  TrackColor := GetCssBackgroundColor;
  if TrackColor = clNone then
    TrackColor := GetParentBackgroundColor;

  FillColor := GetEffectiveProgressColor;
  FillRadius := GetEffectiveProgressRadius;
  TrackTextColor := GetEffectiveTextColor;
  FillTextColor := GetEffectiveProgressTextColor;

  if IsMarquee then
    Fraction := FMarqueePos * FMarqueeAmplitude
  else
    Fraction := GetDisplayFraction;

  if Fraction < 0 then Fraction := 0;
  if Fraction > 1 then Fraction := 1;

  if FOrientation = pbHorizontal then
    FillR := Rect(
      ContentR.Left, ContentR.Top,
      ContentR.Left + Round((ContentR.Right - ContentR.Left) * Fraction),
      ContentR.Bottom)
  else
    FillR := Rect(
      ContentR.Left,
      ContentR.Bottom - Round((ContentR.Bottom - ContentR.Top) * Fraction),
      ContentR.Right, ContentR.Bottom);

  // Заливка
  if (FillR.Right > FillR.Left) and (FillR.Bottom > FillR.Top) then
  begin
    FillRadii.TL := FillRadius;
    FillRadii.TR := FillRadius;
    FillRadii.BR := FillRadius;
    FillRadii.BL := FillRadius;

    DrawAntiAliasedRoundedBox(
      Canvas, FillR, FillRadii,
      FillColor, clNone, 0, cbsNone, TrackColor);
  end;

  if not FShowText then Exit;

  Span := RangeSpan;
  if Span > 0 then
    PosFraction := (FPosition - FMin) / Span
  else
    PosFraction := 0;

  PercentText := Format('%d%%', [Round(PosFraction * 100)]);

  AssignCssFontToFont(Canvas.Font);
  Canvas.Brush.Style := bsClear;

  Mask := RenderTextMask(Canvas, PercentText, FOrientation = pbVertical);
  if Mask = nil then Exit;

  try
    HAlign := GetCssTextAlign;
    VAlign := GetCssVAlign;

    case HAlign of
      ctaLeft:   TextDX := ContentR.Left;
      ctaRight:  TextDX := ContentR.Right - Mask.Width;
    else
      TextDX := ContentR.Left + (ContentR.Width - Mask.Width) div 2;
    end;

    case VAlign of
      cvaTop:    TextDY := ContentR.Top;
      cvaBottom: TextDY := ContentR.Bottom - Mask.Height;
    else
      TextDY := ContentR.Top + (ContentR.Height - Mask.Height) div 2;
    end;

    if TextDX < ContentR.Left then TextDX := ContentR.Left;
    if TextDY < ContentR.Top  then TextDY := ContentR.Top;

    if FOrientation = pbHorizontal then
    begin
      ClipTrack := Rect(FillR.Right, ContentR.Top,
                        ContentR.Right, ContentR.Bottom);
      ClipFill  := Rect(ContentR.Left, ContentR.Top,
                        FillR.Right, ContentR.Bottom);
    end
    else
    begin
      ClipTrack := Rect(ContentR.Left, ContentR.Top,
                        ContentR.Right, FillR.Top);
      ClipFill  := Rect(ContentR.Left, FillR.Top,
                        ContentR.Right, FillR.Bottom);
    end;

    if not IntersectRect(R, ClipTrack, ContentR) then
      ClipTrack := Rect(0, 0, 0, 0)
    else
      ClipTrack := R;

    if not IntersectRect(R, ClipFill, ContentR) then
      ClipFill := Rect(0, 0, 0, 0)
    else
      ClipFill := R;

    if (ClipTrack.Right > ClipTrack.Left) and
       (ClipTrack.Bottom > ClipTrack.Top) then
      BlendTextMask(Canvas, TextDX, TextDY, Mask, TrackTextColor, ClipTrack);

    if (ClipFill.Right > ClipFill.Left) and
       (ClipFill.Bottom > ClipFill.Top) then
      BlendTextMask(Canvas, TextDX, TextDY, Mask, FillTextColor, ClipFill);
  finally
    Mask.Free;
  end;
end;

initialization
  RegisterClass(TCssProgressBar);

finalization
  UnregisterClass(TCssProgressBar);

end.
