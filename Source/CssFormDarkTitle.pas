unit CssFormDarkTitle;

{$mode objfpc}{$H+}

{
  CssFormDarkTitle
  ---------------------------------------------------------------------------
  Cross-platform helper for controlling the native form title bar theme.

  On Windows 10 1809+ and Windows 11 it uses undocumented uxtheme.dll
  ordinals and DwmSetWindowAttribute to paint the form's native title bar
  dark or light, following the active TCssStyleProvider variant.

  On Linux and macOS every public method is a safe no-op; the unit compiles
  and links without any Windows-specific dependencies on those platforms.

  Integration
  -----------
  Two ways to use the unit:

  1. Per form:
       TCssFormDarkTitle.AttachForm(Form1, CssStyleProvider1);

  2. Automatically, for every form that becomes visible:
       TCssFormDarkTitle.EnableAutoAttach(CssStyleProvider1);

  Either way, switching the provider's DefaultStyleName repaints the
  native title bar of every attached form.

  By default a variant whose name contains "dark" (case-insensitive) is
  treated as dark. Pass an explicit list of variant names to override.
}

interface

uses
  Classes, SysUtils, Forms, CssStyledControl;

type
  { Static helper class. All methods are safe to call on any platform;
    on non-Windows platforms they simply do nothing. }
  TCssFormDarkTitle = class
  public
    { True if the current platform supports dark native title bars. }
    class function IsSupported: Boolean;

    { Enable or disable the dark title bar for a single form.
      On non-Windows platforms this is a no-op. }
    class procedure SetDarkTitle(AForm: TForm; ADark: Boolean);

    { Read the current OS preference and apply it to the form.
      On non-Windows platforms this is a no-op. }
    class procedure ApplySystemTheme(AForm: TForm);

    { Attach a form so that its title bar follows the given provider.
      The heuristic "variant name contains 'dark'" is used. }
    class procedure AttachForm(AForm: TForm; AProvider: TCssStyleProvider); overload;

    { Same as above, but you specify which variant names mean "dark".
      Names are matched case-insensitively. }
    class procedure AttachForm(AForm: TForm; AProvider: TCssStyleProvider;
      const ADarkVariantNames: array of string); overload;

    { Remove the automatic hook. Safe to call even if AttachForm was
      never called for this form. }
    class procedure DetachForm(AForm: TForm);

    { Re-evaluate the dark state of an attached form right now. }
    class procedure RefreshForm(AForm: TForm);

    { Attach every form that already exists in the application. }
    class procedure AttachAllForms(AProvider: TCssStyleProvider); overload;
    class procedure AttachAllForms(AProvider: TCssStyleProvider;
      const ADarkVariantNames: array of string); overload;

    { Detach every form that is currently attached. }
    class procedure DetachAllForms;

    { Re-evaluate the dark state of every form in the application. }
    class procedure RefreshAllForms;

    { Enable automatic attachment. Every form that becomes visible from
      this moment on will be attached to the given provider; forms that
      already exist are attached immediately.

      Calling EnableAutoAttach again replaces the previous provider.
      Call DisableAutoAttach to stop the automatic behavior; forms that
      are already attached remain attached. }
    class procedure EnableAutoAttach(AProvider: TCssStyleProvider); overload;
    class procedure EnableAutoAttach(AProvider: TCssStyleProvider;
      const ADarkVariantNames: array of string); overload;

    { Stop automatic attachment. Already-attached forms stay attached;
      call DetachAllForms if you want to detach them too. }
    class procedure DisableAutoAttach;

    { True if automatic attachment is currently active. }
    class function IsAutoAttachEnabled: Boolean;
  end;

implementation

uses
  Controls
  {$IFDEF WINDOWS}
  , Windows, UxTheme
  {$ENDIF}
  ;

{ ============================================================ }
{ Windows implementation                                       }
{ ============================================================ }

{$IFDEF WINDOWS}

const
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE_NEW = 20;

  LOAD_LIBRARY_SEARCH_SYSTEM32 = $00000800;

type
  TShouldAppsUseDarkModeFunc = function: BOOL; stdcall;
  TAllowDarkModeForWindowFunc = function (hWnd: HWND; Allow: BOOL): BOOL; stdcall;
  TSetPreferredAppModeFunc = function (Mode: Integer): Integer; stdcall;
  TRefreshImmersiveColorPolicyStateProc = procedure; stdcall;
  TDwmSetWindowAttributeFunc = function (hWnd: HWND; dwAttribute: DWORD;
    pvAttribute: Pointer; cbAttribute: DWORD): HRESULT; stdcall;
  TRtlGetNtVersionNumbersProc = procedure (var Major, Minor, Build: Cardinal); stdcall;

  TWin32Api = record
    Initialized: Boolean;
    Supported: Boolean;
    BuildNumber: Cardinal;

    ShouldAppsUseDarkMode: TShouldAppsUseDarkModeFunc;
    AllowDarkModeForWindow: TAllowDarkModeForWindowFunc;
    SetPreferredAppMode: TSetPreferredAppModeFunc;
    RefreshImmersiveColorPolicyState: TRefreshImmersiveColorPolicyStateProc;
    DwmSetWindowAttribute: TDwmSetWindowAttributeFunc;
  end;

var
  GWin32: TWin32Api;

procedure InitWin32;
var
  NtDll, UxTheme, DwmApi: HMODULE;
  RtlGetNtVersionNumbers: TRtlGetNtVersionNumbersProc;
  Major, Minor, Build: Cardinal;
begin
  if GWin32.Initialized then
    Exit;

  GWin32.Initialized := True;
  GWin32.Supported := False;
  GWin32.BuildNumber := 0;

  NtDll := GetModuleHandleW('ntdll.dll');
  if NtDll <> 0 then
  begin
    RtlGetNtVersionNumbers := TRtlGetNtVersionNumbersProc(
      GetProcAddress(NtDll, 'RtlGetNtVersionNumbers'));
    if Assigned(RtlGetNtVersionNumbers) then
    begin
      Major := 0; Minor := 0; Build := 0;
      RtlGetNtVersionNumbers(Major, Minor, Build);
      GWin32.BuildNumber := Build and $0FFFFFFF;
    end;
  end;

  UxTheme := LoadLibraryExW('uxtheme.dll', 0, LOAD_LIBRARY_SEARCH_SYSTEM32);
  if UxTheme = 0 then
    Exit;

  DwmApi := LoadLibrary('dwmapi.dll');
  if DwmApi = 0 then
    Exit;

  GWin32.ShouldAppsUseDarkMode := TShouldAppsUseDarkModeFunc(
    GetProcAddress(UxTheme, MAKEINTRESOURCEA(132)));
  GWin32.AllowDarkModeForWindow := TAllowDarkModeForWindowFunc(
    GetProcAddress(UxTheme, MAKEINTRESOURCEA(133)));
  GWin32.SetPreferredAppMode := TSetPreferredAppModeFunc(
    GetProcAddress(UxTheme, MAKEINTRESOURCEA(135)));
  GWin32.RefreshImmersiveColorPolicyState := TRefreshImmersiveColorPolicyStateProc(
    GetProcAddress(UxTheme, MAKEINTRESOURCEA(104)));
  GWin32.DwmSetWindowAttribute := TDwmSetWindowAttributeFunc(
    GetProcAddress(DwmApi, 'DwmSetWindowAttribute'));

  if Assigned(GWin32.ShouldAppsUseDarkMode) and
     Assigned(GWin32.AllowDarkModeForWindow) and
     Assigned(GWin32.SetPreferredAppMode) and
     Assigned(GWin32.RefreshImmersiveColorPolicyState) and
     Assigned(GWin32.DwmSetWindowAttribute) then
  begin
    GWin32.Supported := True;

    // PamAllowDark (1): the app declares that it can render dark mode,
    // but lets each window be controlled individually.
    GWin32.SetPreferredAppMode(1);
    GWin32.RefreshImmersiveColorPolicyState;
  end;
end;
{$ENDIF WINDOWS}

{ ============================================================ }
{ Per-form attachment hook                                     }
{ ============================================================ }

type
  TCssFormDarkTitleHook = class(TComponent)
  private
    FForm: TForm;
    FProvider: TCssStyleProvider;
    FDarkVariantNames: TStringList;
    FPrevOnDestroy: TNotifyEvent;
    FPrevOnShow: TNotifyEvent;
    FPrevProviderOnChange: TNotifyEvent;
    procedure ChainedProviderChanged(Sender: TObject);
    procedure FormDestroyed(Sender: TObject);
    procedure FormShown(Sender: TObject);
    procedure ApplyCurrentState;
  public
    constructor Create(AForm: TForm; AProvider: TCssStyleProvider;
      const ADarkVariantNames: array of string);
    destructor Destroy; override;
    procedure Refresh;
  end;

constructor TCssFormDarkTitleHook.Create(AForm: TForm;
  AProvider: TCssStyleProvider; const ADarkVariantNames: array of string);
var
  I: Integer;
begin
  inherited Create(AForm);

  FForm := AForm;
  FProvider := AProvider;

  FDarkVariantNames := TStringList.Create;
  for I := Low(ADarkVariantNames) to High(ADarkVariantNames) do
    FDarkVariantNames.Add(ADarkVariantNames[I]);

  if FProvider <> nil then
  begin
    FPrevProviderOnChange := FProvider.OnChange;
    FProvider.OnChange := @ChainedProviderChanged;
  end;

  if FForm <> nil then
  begin
    FPrevOnShow := FForm.OnShow;
    FForm.OnShow := @FormShown;

    FPrevOnDestroy := FForm.OnDestroy;
    FForm.OnDestroy := @FormDestroyed;
  end;

  ApplyCurrentState;
end;

destructor TCssFormDarkTitleHook.Destroy;
begin
  if FProvider <> nil then
  begin
    if FProvider.OnChange = @ChainedProviderChanged then
      FProvider.OnChange := FPrevProviderOnChange;
    FProvider := nil;
  end;

  if FForm <> nil then
  begin
    if FForm.OnShow = @FormShown then
      FForm.OnShow := FPrevOnShow;
    if FForm.OnDestroy = @FormDestroyed then
      FForm.OnDestroy := FPrevOnDestroy;
    FForm := nil;
  end;

  FDarkVariantNames.Free;
  inherited Destroy;
end;

procedure TCssFormDarkTitleHook.FormDestroyed(Sender: TObject);
begin
  if FProvider <> nil then
  begin
    if FProvider.OnChange = @ChainedProviderChanged then
      FProvider.OnChange := FPrevProviderOnChange;
    FProvider := nil;
  end;

  FForm := nil;

  if Assigned(FPrevOnDestroy) then
    FPrevOnDestroy(Sender);
end;

procedure TCssFormDarkTitleHook.FormShown(Sender: TObject);
begin
  if Assigned(FPrevOnShow) then
    FPrevOnShow(Sender);

  ApplyCurrentState;
end;

procedure TCssFormDarkTitleHook.ChainedProviderChanged(Sender: TObject);
begin
  if Assigned(FPrevProviderOnChange) then
    FPrevProviderOnChange(Sender);
  ApplyCurrentState;
end;

procedure TCssFormDarkTitleHook.Refresh;
begin
  ApplyCurrentState;
end;

procedure TCssFormDarkTitleHook.ApplyCurrentState;
var
  I: Integer;
  VariantName: string;
  IsDark: Boolean;
begin
  if (FProvider = nil) or (FForm = nil) then
    Exit;

  // Wait until the form actually has a native handle. This prevents
  // premature handle creation when the hook is installed before the
  // form is shown.
  if not FForm.HandleAllocated then
    Exit;

  VariantName := FProvider.DefaultStyleName;
  IsDark := False;

  if FDarkVariantNames.Count > 0 then
  begin
    for I := 0 to FDarkVariantNames.Count - 1 do
      if SameText(VariantName, FDarkVariantNames[I]) then
      begin
        IsDark := True;
        Break;
      end;
  end
  else
    IsDark := Pos('dark', LowerCase(VariantName)) > 0;

  TCssFormDarkTitle.SetDarkTitle(FForm, IsDark);
end;

{ ============================================================ }
{ Automatic attachment                                         }
{ ============================================================ }

type
  { The event type used by Screen.AddHandlerFormVisibleChanged in this
    LCL version. Matches the exact signature the compiler expects. }
  TCssFormVisibleEvent = procedure(Sender: TObject; Form: TCustomForm) of object;

  TCssFormDarkTitleAutoAttach = class
  private
    FProvider: TCssStyleProvider;
    FDarkVariantNames: TStringList;
    FEvent: TCssFormVisibleEvent;
    procedure AttachOne(AForm: TForm);
  public
    constructor Create(AProvider: TCssStyleProvider;
      const ADarkVariantNames: array of string);
    destructor Destroy; override;

    procedure ApplyToExistingForms;
    procedure FormVisibleChanged(Sender: TObject; Form: TCustomForm);

    property Provider: TCssStyleProvider read FProvider;
    property Event: TCssFormVisibleEvent read FEvent;
  end;

var
  GAutoAttach: TCssFormDarkTitleAutoAttach = nil;

constructor TCssFormDarkTitleAutoAttach.Create(AProvider: TCssStyleProvider;
  const ADarkVariantNames: array of string);
var
  I: Integer;
begin
  inherited Create;
  FProvider := AProvider;

  FDarkVariantNames := TStringList.Create;
  for I := Low(ADarkVariantNames) to High(ADarkVariantNames) do
    FDarkVariantNames.Add(ADarkVariantNames[I]);

  // Assign the method pointer directly. The event type matches the
  // signature expected by Screen.AddHandlerFormVisibleChanged in this
  // LCL version (two parameters, register calling convention).
  FEvent := @FormVisibleChanged;
end;

destructor TCssFormDarkTitleAutoAttach.Destroy;
begin
  FDarkVariantNames.Free;
  inherited Destroy;
end;

procedure TCssFormDarkTitleAutoAttach.AttachOne(AForm: TForm);
var
  Arr: array of string;
  I: Integer;
begin
  if AForm = nil then
    Exit;

  if FDarkVariantNames.Count = 0 then
    TCssFormDarkTitle.AttachForm(AForm, FProvider)
  else
  begin
    SetLength(Arr, FDarkVariantNames.Count);
    for I := 0 to FDarkVariantNames.Count - 1 do
      Arr[I] := FDarkVariantNames[I];
    TCssFormDarkTitle.AttachForm(AForm, FProvider, Arr);
  end;
end;

procedure TCssFormDarkTitleAutoAttach.ApplyToExistingForms;
var
  I: Integer;
  F: TCustomForm;
begin
  for I := 0 to Screen.FormCount - 1 do
  begin
    F := Screen.Forms[I];
    if F is TForm then
      AttachOne(TForm(F));
  end;
end;

procedure TCssFormDarkTitleAutoAttach.FormVisibleChanged(Sender: TObject;
  Form: TCustomForm);
begin
  if Form = nil then
    Exit;
  if not (Form is TForm) then
    Exit;
  if not Form.Visible then
    Exit;

  AttachOne(TForm(Form));
end;

{ ============================================================ }
{ TCssFormDarkTitle                                            }
{ ============================================================ }

class function TCssFormDarkTitle.IsSupported: Boolean;
begin
  {$IFDEF WINDOWS}
  InitWin32;
  Result := GWin32.Supported;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

class procedure TCssFormDarkTitle.SetDarkTitle(AForm: TForm; ADark: Boolean);
{$IFDEF WINDOWS}
var
  Value: BOOL;
  Attr: DWORD;
  HW: HWND;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  if AForm = nil then
    Exit;
  if not IsSupported then
    Exit;

  HW := AForm.Handle;
  if HW = 0 then
    Exit;
  if not IsWindow(HW) then
    Exit;

  // 1. Immerse the window in the dark uxtheme class.
  SetWindowTheme(HW, 'DarkMode_Explorer', nil);
  SendMessageW(HW, WM_THEMECHANGED, 0, 0);

  // 2. Allow the dark DWM mode for this specific window.
  GWin32.AllowDarkModeForWindow(HW, True);

  // 3. Pick the correct attribute id for the current Windows build.
  if GWin32.BuildNumber < 19041 then
    Attr := DWMWA_USE_IMMERSIVE_DARK_MODE_OLD
  else
    Attr := DWMWA_USE_IMMERSIVE_DARK_MODE_NEW;

  Value := BOOL(Ord(ADark));
  GWin32.DwmSetWindowAttribute(HW, Attr, @Value, SizeOf(Value));

  // 4. Redraw the non-client area (title bar and borders).
  SetWindowPos(HW, 0, 0, 0, 0, 0,
    SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
    SWP_NOACTIVATE or SWP_NOOWNERZORDER);

  // 5. Force DWM to repaint the caption on Windows 10 22H2 and older.
  SendMessageW(HW, WM_NCACTIVATE, 0, 0);
  SendMessageW(HW, WM_NCACTIVATE, 1, 0);
  {$ELSE}
  if AForm = nil then
    Exit;
  if ADark then
    Exit;
  {$ENDIF}
end;

class procedure TCssFormDarkTitle.ApplySystemTheme(AForm: TForm);
begin
  {$IFDEF WINDOWS}
  if not IsSupported then
    Exit;
  SetDarkTitle(AForm, GWin32.ShouldAppsUseDarkMode() <> False);
  {$ELSE}
  if AForm = nil then
    Exit;
  {$ENDIF}
end;

class procedure TCssFormDarkTitle.AttachForm(AForm: TForm;
  AProvider: TCssStyleProvider);
begin
  AttachForm(AForm, AProvider, []);
end;

class procedure TCssFormDarkTitle.AttachForm(AForm: TForm;
  AProvider: TCssStyleProvider; const ADarkVariantNames: array of string);
var
  I: Integer;
begin
  if (AForm = nil) or (AProvider = nil) then
    Exit;

  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I] is TCssFormDarkTitleHook then
      Exit;

  TCssFormDarkTitleHook.Create(AForm, AProvider, ADarkVariantNames);
end;

class procedure TCssFormDarkTitle.DetachForm(AForm: TForm);
var
  I: Integer;
begin
  if AForm = nil then
    Exit;

  for I := AForm.ComponentCount - 1 downto 0 do
    if AForm.Components[I] is TCssFormDarkTitleHook then
      AForm.Components[I].Free;
end;

class procedure TCssFormDarkTitle.RefreshForm(AForm: TForm);
var
  I: Integer;
begin
  if AForm = nil then
    Exit;

  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I] is TCssFormDarkTitleHook then
      TCssFormDarkTitleHook(AForm.Components[I]).Refresh;
end;

class procedure TCssFormDarkTitle.AttachAllForms(AProvider: TCssStyleProvider);
begin
  AttachAllForms(AProvider, []);
end;

class procedure TCssFormDarkTitle.AttachAllForms(AProvider: TCssStyleProvider;
  const ADarkVariantNames: array of string);
var
  I: Integer;
  F: TCustomForm;
begin
  if AProvider = nil then
    Exit;

  for I := 0 to Screen.FormCount - 1 do
  begin
    F := Screen.Forms[I];
    if F is TForm then
      AttachForm(TForm(F), AProvider, ADarkVariantNames);
  end;
end;

class procedure TCssFormDarkTitle.DetachAllForms;
var
  I: Integer;
  F: TCustomForm;
begin
  for I := 0 to Screen.FormCount - 1 do
  begin
    F := Screen.Forms[I];
    if F is TForm then
      DetachForm(TForm(F));
  end;
end;

class procedure TCssFormDarkTitle.RefreshAllForms;
var
  I: Integer;
  F: TCustomForm;
begin
  for I := 0 to Screen.FormCount - 1 do
  begin
    F := Screen.Forms[I];
    if F is TForm then
      RefreshForm(TForm(F));
  end;
end;

class procedure TCssFormDarkTitle.EnableAutoAttach(AProvider: TCssStyleProvider);
begin
  EnableAutoAttach(AProvider, []);
end;

class procedure TCssFormDarkTitle.EnableAutoAttach(AProvider: TCssStyleProvider;
  const ADarkVariantNames: array of string);
begin
  // Replace any previously installed auto-attach.
  DisableAutoAttach;

  if AProvider = nil then
    Exit;

  GAutoAttach := TCssFormDarkTitleAutoAttach.Create(AProvider, ADarkVariantNames);

  Screen.AddHandlerFormVisibleChanged(GAutoAttach.Event, True);

  // Attach forms that already exist right now. Forms that are not yet
  // visible will be attached by FormVisibleChanged when they are shown.
  GAutoAttach.ApplyToExistingForms;
end;

class procedure TCssFormDarkTitle.DisableAutoAttach;
begin
  if GAutoAttach = nil then
    Exit;

  Screen.RemoveHandlerFormVisibleChanged(GAutoAttach.Event);
  FreeAndNil(GAutoAttach);
end;

class function TCssFormDarkTitle.IsAutoAttachEnabled: Boolean;
begin
  Result := GAutoAttach <> nil;
end;

initialization

finalization
  TCssFormDarkTitle.DisableAutoAttach;
end.
