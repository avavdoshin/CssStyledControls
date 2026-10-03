unit CssGroupCaptionControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Types, CssStyledControl;

type
  TCssGroupCaptionControl = class(TCssStyledControl)
  private
    // Fields
    FCaptionMode: TCssGroupCaptionMode;
    FCaptionBackgroundColor: TColor;
    FGroupCaption: TCaption;

    // Property accessors
    function GetGroupCaptionText: TCaption;
    procedure SetGroupCaptionText(const AValue: TCaption);
    procedure SetCaptionMode(AValue: TCssGroupCaptionMode);
    procedure SetCaptionBackgroundColor(AValue: TColor);
  protected
    // Caption handling
    procedure SetCaption(const AValue: TCaption); override;

    // Geometry helpers
    function GetCaptionHeight(AvailableWidth: Integer): Integer;
    function GetCaptionBackground: TColor;
    function GetTopOffset: Integer;
    procedure GetCaptionDrawRect(out ARect: TRect; out ACaptionW: Integer);
    function GetBorderTopOffset: Integer; override;
    procedure InitTextProps; override;

    // Layout
    procedure LayoutItems; virtual;

    // Initialization and style
    procedure HtmlModeChanged; override;
    procedure StyleChanged; override;

  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: TCaption read GetGroupCaptionText write SetGroupCaptionText;
    property CaptionMode: TCssGroupCaptionMode
      read FCaptionMode write SetCaptionMode default gcmInside;
    property CaptionBackgroundColor: TColor
      read FCaptionBackgroundColor write SetCaptionBackgroundColor default clDefault;
  end;

implementation

{ TCssGroupCaptionControl }

constructor TCssGroupCaptionControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  inherited SetCaption('');

  FCaptionMode := gcmInside;
  FCaptionBackgroundColor := clDefault;
  FGroupCaption := 'Group';
end;

function TCssGroupCaptionControl.GetGroupCaptionText: TCaption;
begin
  Result := FGroupCaption;
end;

procedure TCssGroupCaptionControl.SetGroupCaptionText(const AValue: TCaption);
begin
  if FGroupCaption = AValue then
    Exit;

  FGroupCaption := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssGroupCaptionControl.SetCaption(const AValue: TCaption);
begin
  inherited SetCaption('');
  SetGroupCaptionText(AValue);
end;

procedure TCssGroupCaptionControl.SetCaptionMode(AValue: TCssGroupCaptionMode);
begin
  if FCaptionMode = AValue then
    Exit;

  FCaptionMode := AValue;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssGroupCaptionControl.SetCaptionBackgroundColor(AValue: TColor);
begin
  if FCaptionBackgroundColor = AValue then
    Exit;

  FCaptionBackgroundColor := AValue;

  Invalidate;
end;

function TCssGroupCaptionControl.GetCaptionBackground: TColor;
begin
  Result := FCaptionBackgroundColor;

  if Result = clDefault then
    Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := Color;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssGroupCaptionControl.GetCaptionHeight(AvailableWidth: Integer): Integer;
var
  S: TSize;
begin
  if FGroupCaption = '' then
    Exit(0);

  if not HandleAllocated then
    Exit(18);

  AssignCssFontToFont(Canvas.Font);

  if HtmlMode then
  begin
    S := MeasureHtmlTextSize(FGroupCaption, AvailableWidth);
    Result := S.cy;
  end
  else
    Result := Canvas.TextHeight('Ag');

  Result := Result + 4;
end;

function TCssGroupCaptionControl.GetTopOffset: Integer;
var
  B, CapH: Integer;
begin
  B := GetCssBorderWidth;
  CapH := GetCaptionHeight(Width - B * 2);

  if FCaptionMode = gcmInside then
    Result := B + CapH
  else if CapH > B then
    Result := CapH
  else
    Result := B;
end;

procedure TCssGroupCaptionControl.GetCaptionDrawRect(out ARect: TRect; out ACaptionW: Integer);
var
  B: Integer;
  P: TRect;
  CapH, ContentWidth: Integer;
  S: TSize;
  CaptionX, CaptionY, CaptionW: Integer;
  LAlign: TCssTextAlign;
begin
  ARect := Rect(0, 0, 0, 0);
  ACaptionW := 0;

  if FGroupCaption = '' then
    Exit;

  B := GetCssBorderWidth;
  P := GetCssPadding;

  ContentWidth := ClientWidth - B * 2 - P.Left - P.Right;

  if ContentWidth < 0 then
    ContentWidth := 0;

  CapH := GetCaptionHeight(ContentWidth);

  if CapH <= 0 then
    Exit;

  AssignCssFontToFont(Canvas.Font);

  if HtmlMode then
    S := MeasureHtmlTextSize(FGroupCaption, ContentWidth)
  else
  begin
    S.cx := Canvas.TextWidth(FGroupCaption);
    S.cy := Canvas.TextHeight('Ag');
  end;

  CaptionW := S.cx + 6;

  if CaptionW < 10 then
    CaptionW := 10;

  LAlign := GetCssTextAlign;

  if FCaptionMode = gcmInside then
    CaptionY := B + P.Top
  else
    CaptionY := 0;

  case LAlign of
    ctaCenter:
      CaptionX := B + P.Left + (ContentWidth - CaptionW) div 2;

    ctaRight:
      CaptionX := B + P.Left + ContentWidth - CaptionW;
  else
    CaptionX := B + P.Left;
  end;

  if CaptionX < 0 then
    CaptionX := 0;

  ARect := Rect(CaptionX - 3, CaptionY, CaptionX + CaptionW + 3, CaptionY + CapH);

  if ARect.Left < 0 then
    ARect.Left := 0;

  if ARect.Top < 0 then
    ARect.Top := 0;

  if ARect.Right > ClientWidth then
    ARect.Right := ClientWidth;

  if ARect.Bottom > ClientHeight then
    ARect.Bottom := ClientHeight;

  ACaptionW := CaptionW;
end;

function TCssGroupCaptionControl.GetBorderTopOffset: Integer;
var
  B: Integer;
begin
  if FCaptionMode <> gcmOnBorder then
    Exit(0);

  B := GetCssBorderWidth;
  Result := GetCaptionHeight(Width - B * 2) div 2;
end;

procedure TCssGroupCaptionControl.InitTextProps;
begin
  SetTextAlign(ctaLeft);
  SetVAlign(cvaMiddle);
  SetWordWrap(False);
end;

procedure TCssGroupCaptionControl.LayoutItems;
begin
  // For descendants.
end;

procedure TCssGroupCaptionControl.HtmlModeChanged;
begin
  inherited HtmlModeChanged;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

procedure TCssGroupCaptionControl.StyleChanged;
begin
  inherited StyleChanged;

  LayoutItems;

  if AutoSize then
    AdjustSize;

  Invalidate;
end;

end.
