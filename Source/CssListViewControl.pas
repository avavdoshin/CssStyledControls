unit CssListViewControl;

{$mode objfpc}{$H+}

{ TCssListView - a CSS-styled list view control for Lazarus / Free Pascal (LCL).

  The control mirrors the commonly used behaviour of the standard TListView:

    - vsReport / vsList / vsSmallIcon / vsIcon view styles;
    - columns with resizing, alignment, visibility and header click sorting;
    - items with sub-items, SVG images, state images, checkboxes and user data;
    - single / multi selection with Ctrl and Shift, row selection, hot tracking,
      marquee selection in list and icon views;
    - keyboard navigation, incremental search and inline caption editing;
    - vertical and horizontal scrolling drawn with TCssScrollBar;
    - sorting through SortType / SortColumn / SortDirection / AlphaSort and
      the OnCompare event.

  Appearance is driven by CSS exactly like the other controls in the library.
  In addition to the standard background / border / text declarations the
  following list-view specific declarations are read:

    header-background, header-color, header-hover-background, header-height,
    sort-marker-color, header-padding,
    item-background, item-color, item-hover-background, item-hover-color,
    item-selected-background, item-selected-color,
    selection-background, selection-color, hover-background,
    grid-color, line-color,
    item-height, row-height, item-padding, column-padding, icon-spacing,
    scrollbar-size, check-color,
    placeholder, placeholder-color,
    disabled-background, disabled-color.

  All coordinates in the public API are in control pixels. }

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, LCLIntf,
  Forms, CssStyledControl, CssScrollControl, CssCheckboxControl, CssEditControl,
  CssSvgImgList;

type
  TCssListView = class;
  TCssListItem = class;
  TCssListColumn = class;

  TCssListViewStyle = (lvsIcon, lvsSmallIcon, lvsList, lvsReport);
  TCssListSortType = (lstNone, lstData, lstText, lstBoth);
  TCssListSortDirection = (lsdNone, lsdAscending, lsdDescending);

  TCssListItemEvent = procedure(Sender: TObject; Item: TCssListItem) of object;
  TCssListItemSelectEvent = procedure(Sender: TObject; Item: TCssListItem;
    Selected: Boolean) of object;
  TCssListColumnEvent = procedure(Sender: TObject; Column: TCssListColumn) of object;
  TCssListCompareEvent = procedure(Sender: TObject; Item1, Item2: TCssListItem;
    Data: Integer; var Compare: Integer) of object;
  TCssListEditingEvent = procedure(Sender: TObject; Item: TCssListItem;
    var AllowEdit: Boolean) of object;
  TCssListEditedEvent = procedure(Sender: TObject; Item: TCssListItem;
    const NewText: string) of object;
  TCssListDrawItemEvent = procedure(Sender: TObject; Item: TCssListItem;
    const ARect: TRect; ItemIndex: Integer; var DefaultDraw: Boolean) of object;

  { A single column of a TCssListView.  Width is measured in control pixels.
    Column 0 shows the item caption and sub-item 0, column 1 shows sub-item 1
    and so on. }
  TCssListColumn = class(TCollectionItem)
  private
    FCaption: string;
    FWidth: Integer;
    FMinWidth: Integer;
    FAlignment: TAlignment;
    FVisible: Boolean;
    FAutoSize: Boolean;
    FImageIndex: Integer;
    function GetListView: TCssListView;
    procedure SetCaption(const AValue: string);
    procedure SetWidth(AValue: Integer);
    procedure SetMinWidth(AValue: Integer);
    procedure SetAlignment(AValue: TAlignment);
    procedure SetVisible(AValue: Boolean);
    procedure SetAutoSize(AValue: Boolean);
    procedure SetImageIndex(AValue: Integer);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property ListView: TCssListView read GetListView;
  published
    property Caption: string read FCaption write SetCaption;
    property Width: Integer read FWidth write SetWidth default 120;
    property MinWidth: Integer read FMinWidth write SetMinWidth default 24;
    property Alignment: TAlignment read FAlignment write SetAlignment
      default taLeftJustify;
    property Visible: Boolean read FVisible write SetVisible default True;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
  end;

  { One item of a TCssListView.  Caption is shown in column 0, SubItems[0]
    in column 1, SubItems[1] in column 2, etc. }
  TCssListItem = class(TCollectionItem)
  private
    FCaption: string;
    FSubItems: TStringList;
    FImageIndex: Integer;
    FStateIndex: Integer;
    FOverlayIndex: Integer;
    FChecked: Boolean;
    FData: Pointer;
    FIndent: Integer;
    function GetListView: TCssListView;
    function GetSelected: Boolean;
    procedure SetSelected(AValue: Boolean);
    procedure SetCaption(const AValue: string);
    procedure SetSubItems(AValue: TStrings);
    procedure SetImageIndex(AValue: Integer);
    procedure SetStateIndex(AValue: Integer);
    procedure SetOverlayIndex(AValue: Integer);
    procedure SetChecked(AValue: Boolean);
    procedure SetData(AValue: Pointer);
    procedure SetIndent(AValue: Integer);
    procedure SubItemsChanged(Sender: TObject);
    function GetSubItemText(AIndex: Integer): string;
    function GetSubItems: TStrings;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property ListView: TCssListView read GetListView;
    property Selected: Boolean read GetSelected write SetSelected;
    property Data: Pointer read FData write SetData;
  published
    property Caption: string read FCaption write SetCaption;
    property SubItems: TStrings read GetSubItems write SetSubItems;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property StateIndex: Integer read FStateIndex write SetStateIndex default -1;
    property OverlayIndex: Integer read FOverlayIndex write SetOverlayIndex default -1;
    property Checked: Boolean read FChecked write SetChecked default False;
    property Indent: Integer read FIndent write SetIndent default 0;
  end;

  TCssListItems = class(TCollection)
  private
    FListView: TCssListView;
    function GetItem(Index: Integer): TCssListItem;
    procedure SetItem(Index: Integer; AValue: TCssListItem);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
    procedure Notify(Item: TCollectionItem;
      Action: TCollectionNotification); override;
  public
    constructor Create(AListView: TCssListView);
    function Add: TCssListItem;
    function Insert(Index: Integer): TCssListItem;
    function AddItem(const ACaption: string): TCssListItem;
    property ListView: TCssListView read FListView;
    property Items[Index: Integer]: TCssListItem read GetItem write SetItem; default;
  end;

  TCssListColumns = class(TCollection)
  private
    FListView: TCssListView;
    function GetItem(Index: Integer): TCssListColumn;
    procedure SetItem(Index: Integer; AValue: TCssListColumn);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AListView: TCssListView);
    function Add: TCssListColumn;
    function Insert(Index: Integer): TCssListColumn;
    function AddItem(const ACaption: string; AWidth: Integer = 120): TCssListColumn;
    property ListView: TCssListView read FListView;
    property Items[Index: Integer]: TCssListColumn read GetItem write SetItem; default;
  end;

  TCssListView = class(TCssStyledControl)
  private
    FItems: TCssListItems;
    FColumns: TCssListColumns;

    // Behaviour
    FViewStyle: TCssListViewStyle;
    FMultiSelect: Boolean;
    FRowSelect: Boolean;
    FReadOnly: Boolean;
    FShowColumnHeaders: Boolean;
    FCheckboxes: Boolean;
    FGridLines: Boolean;
    FHotTrack: Boolean;
    FHideSelection: Boolean;
    FShowImages: Boolean;
    FShowItemFocusRect: Boolean;

    // Metrics (0 = derive from CSS / defaults)
    FItemHeight: Integer;
    FHeaderHeight: Integer;
    FScrollBarSize: Integer;
    FHeaderPadding: Integer;
    FItemPadding: Integer;
    FIconSpacing: Integer;

    // Images
    FSmallImages: TCssSvgImgList;
    FLargeImages: TCssSvgImgList;
    FStateImages: TCssSvgImgList;
    FImageVariant: string;
    FSmallImageWidth: Integer;
    FSmallImageHeight: Integer;
    FLargeImageWidth: Integer;
    FLargeImageHeight: Integer;

    // Sorting
    FSortType: TCssListSortType;
    FSortColumn: Integer;
    FSortDirection: TCssListSortDirection;
    FAutoSort: Boolean;

    // Scroll state
    FTopIndex: Integer;       // report: first visible row
    FTopOffset: Integer;      // icon / small icon: vertical pixel offset
    FLeftOffset: Integer;     // report / list: horizontal pixel offset
    FVScroll: TCssScrollBar;
    FHScroll: TCssScrollBar;
    FVScrollRect: TRect;
    FHScrollRect: TRect;
    FScrollCapture: TCssScrollBar;
    FScrollUpdating: Boolean;
    FScrollBarCssClass: string;
    FScrollBarCssStyle: string;

    // Selection / mouse
    FSelection: TList;
    FFocusedItem: TCssListItem;
    FFocusedColumn: Integer;
    FAnchorItem: TCssListItem;
    FHoverItem: TCssListItem;
    FHotHeaderColumn: Integer;
    FUpdateCount: Integer;
    FUpdating: Boolean;
    FLastMouse: TPoint;
    FMouseDown: Boolean;
    FMouseDownItem: TCssListItem;
    FRubberBanding: Boolean;
    FRubberStart: TPoint;
    FRubberRect: TRect;
    FRubberAdditive: Boolean;
    FSearchText: string;
    FSearchTime: QWord;

    // Column resizing
    FResizingColumn: Integer;
    FResizeStartX: Integer;
    FResizeStartWidth: Integer;
    FResizeStartLeft: Integer;

    // Inline editing
    FEdit: TCssEdit;
    FEditingItem: TCssListItem;
    FEditOldText: string;
    FEditClosing: Boolean;
    FEditCssClass: string;

    // Checkbox helpers
    FCheckBoxNormal: TCssCheckBox;
    FCheckBoxChecked: TCssCheckBox;
    FCheckBoxHover: TCssCheckBox;
    FCheckBoxCheckedHover: TCssCheckBox;
    FCheckBoxCssClass: string;
    FCheckBoxCssStyle: string;
    FCheckBoxInlineCss: string;

    // Placeholder
    FPlaceholder: string;
    FPlaceholderColor: TColor;
    FPlaceholderColorSet: Boolean;

    // CSS colours
    FHeaderBackground: TColor;
    FHeaderBackgroundSet: Boolean;
    FHeaderColor: TColor;
    FHeaderColorSet: Boolean;
    FHeaderHoverBackground: TColor;
    FHeaderHoverBackgroundSet: Boolean;
    FItemBackground: TColor;
    FItemBackgroundSet: Boolean;
    FItemColor: TColor;
    FItemColorSet: Boolean;
    FItemHoverBackground: TColor;
    FItemHoverBackgroundSet: Boolean;
    FItemHoverColor: TColor;
    FItemHoverColorSet: Boolean;
    FItemSelectedBackground: TColor;
    FItemSelectedBackgroundSet: Boolean;
    FItemSelectedColor: TColor;
    FItemSelectedColorSet: Boolean;
    FSelectionBackground: TColor;
    FSelectionBackgroundSet: Boolean;
    FSelectionColor: TColor;
    FSelectionColorSet: Boolean;
    FHoverBackground: TColor;
    FHoverBackgroundSet: Boolean;
    FGridColor: TColor;
    FGridColorSet: Boolean;
    FLineColor: TColor;
    FLineColorSet: Boolean;
    FSortMarkerColor: TColor;
    FSortMarkerColorSet: Boolean;
    FDisabledBackground: TColor;
    FDisabledBackgroundSet: Boolean;
    FDisabledColor: TColor;
    FDisabledColorSet: Boolean;
    FCheckColor: TColor;
    FCheckColorSet: Boolean;

    // Events
    FOnSelectItem: TCssListItemSelectEvent;
    FOnChange: TNotifyEvent;
    FOnItemChecked: TCssListItemEvent;
    FOnItemActivate: TCssListItemEvent;
    FOnColumnClick: TCssListColumnEvent;
    FOnCompare: TCssListCompareEvent;
    FOnInsert: TCssListItemEvent;
    FOnDeletion: TCssListItemEvent;
    FOnEditing: TCssListEditingEvent;
    FOnEdited: TCssListEditedEvent;
    FOnDrawItem: TCssListDrawItemEvent;

    procedure SetItems(AValue: TCssListItems);
    procedure SetColumns(AValue: TCssListColumns);
    procedure SetViewStyle(AValue: TCssListViewStyle);
    procedure SetMultiSelect(AValue: Boolean);
    procedure SetRowSelect(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetShowColumnHeaders(AValue: Boolean);
    procedure SetCheckboxes(AValue: Boolean);
    procedure SetGridLines(AValue: Boolean);
    procedure SetHotTrack(AValue: Boolean);
    procedure SetHideSelection(AValue: Boolean);
    procedure SetShowImages(AValue: Boolean);
    procedure SetItemHeight(AValue: Integer);
    procedure SetHeaderHeight(AValue: Integer);
    procedure SetScrollBarSize(AValue: Integer);
    procedure SetHeaderPadding(AValue: Integer);
    procedure SetItemPadding(AValue: Integer);
    procedure SetIconSpacing(AValue: Integer);
    procedure SetSmallImages(AValue: TCssSvgImgList);
    procedure SetLargeImages(AValue: TCssSvgImgList);
    procedure SetStateImages(AValue: TCssSvgImgList);
    procedure SetImageVariant(const AValue: string);
    procedure SetSmallImageWidth(AValue: Integer);
    procedure SetSmallImageHeight(AValue: Integer);
    procedure SetLargeImageWidth(AValue: Integer);
    procedure SetLargeImageHeight(AValue: Integer);
    procedure SetSortType(AValue: TCssListSortType);
    procedure SetSortColumn(AValue: Integer);
    procedure SetSortDirection(AValue: TCssListSortDirection);
    procedure SetAutoSort(AValue: Boolean);
    procedure SetScrollBarCssClass(const AValue: string);
    procedure SetScrollBarCssStyle(const AValue: string);
    procedure SetCheckBoxCssClass(const AValue: string);
    procedure SetCheckBoxCssStyle(const AValue: string);
    procedure SetEditCssClass(const AValue: string);
    procedure SetPlaceholder(const AValue: string);
    procedure SetPlaceholderColor(AValue: TColor);
    procedure SetShowItemFocusRect(AValue: Boolean);
    function  BeginContentClip: Integer;
    function  PushClipRect(const ARect: TRect): Integer;
    procedure PopClipRect(ASavedDC: Integer);
    procedure RestoreRoundedBorder;

    // CSS accessors
    function GetHeaderBackground: TColor;
    function GetHeaderTextColor: TColor;
    function GetHeaderHoverBackground: TColor;
    function GetItemBackground: TColor;
    function GetItemTextColor: TColor;
    function GetItemHoverBackground: TColor;
    function GetItemHoverTextColor: TColor;
    function GetItemSelectedBackground: TColor;
    function GetItemSelectedTextColor: TColor;
    function GetSelectionBackground: TColor;
    function GetSelectionColor: TColor;
    function GetHoverBackground: TColor;
    function GetGridColor: TColor;
    function GetLineColor: TColor;
    function GetSortMarkerColor: TColor;
    function GetDisabledBackground: TColor;
    function GetDisabledColor: TColor;
    function GetCheckColor: TColor;
    function GetPlaceholderColor: TColor;
    function GetEffectiveImageVariant: string;
    function GetEffectiveItemHeight: Integer;
    function GetEffectiveHeaderHeight: Integer;
    function GetEffectiveScrollBarSize: Integer;
    function GetEffectiveHeaderPadding: Integer;
    function GetEffectiveItemPadding: Integer;

    // Geometry
    function GetHeaderRect: TRect;
    function GetViewRect: TRect;
    function GetColumnWidth(AIndex: Integer): Integer;
    function GetColumnLeft(AIndex: Integer): Integer;
    function GetTotalColumnsWidth: Integer;
    function GetColumnAt(X: Integer): Integer;
    function GetHeaderResizeColumnAt(X: Integer): Integer;
    function GetPageRows: Integer;
    function GetItemsPerListColumn: Integer;
    function GetIconColumnCount: Integer;
    function GetArrowTargetIndex(AKey: Word; AIndex: Integer): Integer;
    function GetReportItemRect(AIndex: Integer): TRect;
    function GetListItemRect(AIndex: Integer): TRect;
    function GetSmallIconItemRect(AIndex: Integer): TRect;
    function GetIconItemRect(AIndex: Integer): TRect;
    function GetItemRect(AIndex: Integer): TRect;
    function GetItemCellRect(AIndex, AColumn: Integer): TRect;
    function GetItemTextRect(AIndex, AColumn: Integer): TRect;
    function GetCheckBoxSize: Integer;
    function GetCheckBoxRect(AIndex, AColumn: Integer): TRect;
    function GetSmallImageSize: TSize;
    function GetLargeImageSize: TSize;
    function GetStateImageSize: TSize;
    function GetItemIndexAt(X, Y: Integer): Integer;
    function IndexOfItem(AItem: TCssListItem): Integer;
    function ItemFromIndex(AIndex: Integer): TCssListItem;
    function GetItemCount: Integer;
    function GetSelCount: Integer;
    function GetItemIndex: Integer;
    procedure SetItemIndex(AValue: Integer);
    function GetSelectedItem: TCssListItem;
    function GetTopItem: TCssListItem;
    procedure SetTopItem(AValue: TCssListItem);
    function GetVisibleRowCount: Integer;
    function GetRowStep: Integer;
    function GetIconRowStep: Integer;
    function GetListItemStep: Integer;
    function GetListViewportWidth: Integer;
    function GetListViewportHeight: Integer;

    // Scrolling
    procedure UpdateScrollBars;
    procedure SetTopIndex(AValue: Integer);
    procedure SetTopOffset(AValue: Integer);
    procedure SetLeftOffset(AValue: Integer);
    procedure DoVScroll(Sender: TObject);
    procedure DoHScroll(Sender: TObject);
    procedure ScrollBarMouseDown(X, Y: Integer; out AHandled: Boolean);
    procedure ScrollBarMouseMove(X, Y: Integer; out AHandled: Boolean);
    procedure ScrollBarMouseUp;
    procedure DrawInternalScrollBars;
    function ScrollBarAt(X, Y: Integer): TCssScrollBar;

    // Selection
    function IsItemSelected(AItem: TCssListItem): Boolean;
    procedure SetItemSelection(AItem: TCssListItem; AValue: Boolean;
      ANotify: Boolean);
    procedure ClearSelectionInternal(ANotify: Boolean);
    procedure SetFocusedItem(AItem: TCssListItem);
    procedure SetFocusedColumn(AValue: Integer);
    function  GetEffectiveFocusedColumn: Integer;
    procedure SelectRange(AFrom, ATo: TCssListItem; AAdditive: Boolean);
    procedure NotifySelectionChange(AItem: TCssListItem; ASelected: Boolean);
    procedure SelectItemOnMouse(AItem: TCssListItem; Shift: TShiftState);
    procedure UpdateRubberBand(Shift: TShiftState);
    procedure ApplyRubberBandSelection;
    procedure CancelRubberBand;
    procedure NavigateTo(AIndex: Integer; Shift: TShiftState);
    procedure AutoSizeColumn(AIndex: Integer);

    // Painting
    procedure DrawHeader;
    procedure DrawHeaderCell(AIndex: Integer; const ARect: TRect);
    procedure DrawHeaderText(const ARect: TRect; const AText: string;
      AAlign: TAlignment);
    procedure DrawSortArrow(const ARect: TRect; ADirection: TCssListSortDirection);
    procedure DrawItems;
    procedure DrawReportRow(AIndex: Integer);
    procedure DrawListRow(AIndex: Integer);
    procedure DrawSmallIconRow(AIndex: Integer);
    procedure DrawIconRow(AIndex: Integer);
    procedure DrawItemCell(AIndex, AColumn: Integer; const ARect: TRect;
      ASelected, AHovered: Boolean);
    procedure DrawCheckBox(AIndex, AColumn: Integer; const ARect: TRect;
      ASelected, AHovered: Boolean);
    procedure DrawItemImage(AIndex, AColumn: Integer; const ARect: TRect);
    procedure DrawStateImage(AIndex, AColumn: Integer; const ARect: TRect);
    procedure DrawItemText(AIndex, AColumn: Integer; const ARect: TRect;
      ASelected, AHovered: Boolean);
    procedure DrawPlaceholder(const ARect: TRect);
    procedure DrawRubberBand;
    procedure DrawFocusMark(const ARect: TRect; ASelectedCell: Boolean);
    procedure DrawColumnGrid;
    procedure ApplyTextStyle(var AStyle: TTextStyle; AAlign: TAlignment;
      AVertical: Boolean = True);

    // Checkbox helpers
    function CreateCheckBoxHelper(AChecked, AHover: Boolean): TCssCheckBox;
    function ComposeCheckBoxCssStyle: string;
    procedure SetupCheckBoxHelper(CB: TCssCheckBox; AChecked, AHover: Boolean);
    procedure UpdateCheckBoxStyle;
    procedure FreeCheckBoxHelpers;

    // Editing
    procedure BeginEditInternal(AItem: TCssListItem);
    procedure EndEditInternal(ACancel: Boolean);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditExit(Sender: TObject);

    // Sorting
    function GetSortText(AItem: TCssListItem; AColumn: Integer): string;
    function CompareItems(AItem1, AItem2: TCssListItem): Integer;
    procedure SortInternal(AColumn: Integer;
      ADirection: TCssListSortDirection; ATextOnly: Boolean);

  protected
    procedure Loaded; override;
    procedure StyleChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
    procedure EnabledChanged; override;
    procedure Resize; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: char); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    function AddItem(const ACaption: string): TCssListItem;
    procedure Clear;
    procedure SelectAll;
    procedure ClearSelection;

    function GetItemAt(X, Y: Integer): TCssListItem;
    function GetSubItemAt(X, Y: Integer): Integer;
    function ItemRect(AIndex: Integer): TRect;
    function SubItemRect(AIndex, ASubItem: Integer): TRect;
    procedure ScrollIntoView(AItem: TCssListItem); overload;
    procedure ScrollIntoView(AIndex: Integer); overload;

    procedure BeginEdit(AItem: TCssListItem);
    procedure EndEdit(ACancel: Boolean);

    procedure Sort;
    function AlphaSort: Boolean;
    procedure CustomSort(ACompare: TCssListCompareEvent);

    // Internal notifications used by TCssListItem / TCssListItems.
    procedure ItemsChanged(AItem: TCollectionItem);
    procedure DoItemInserted(AItem: TCssListItem);
    procedure DoItemDeleting(AItem: TCssListItem);
    procedure DoItemChecked(AItem: TCssListItem);
    procedure SetItemSelectionFromItem(AItem: TCssListItem; AValue: Boolean);

    property ItemCount: Integer read GetItemCount;
    property SelCount: Integer read GetSelCount;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property Selected: TCssListItem read GetSelectedItem;
    property TopItem: TCssListItem read GetTopItem write SetTopItem;
    property VisibleRowCount: Integer read GetVisibleRowCount;
    property Images: TCssSvgImgList read FSmallImages write SetSmallImages;
    property FocusedItem: TCssListItem read FFocusedItem;
    property FocusedColumn: Integer read FFocusedColumn write SetFocusedColumn
      default 0;

  published
    property Columns: TCssListColumns read FColumns write SetColumns;
    property Items: TCssListItems read FItems write SetItems;
    property ViewStyle: TCssListViewStyle read FViewStyle write SetViewStyle
      default lvsReport;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect
      default False;
    property RowSelect: Boolean read FRowSelect write SetRowSelect default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property ShowColumnHeaders: Boolean read FShowColumnHeaders
      write SetShowColumnHeaders default True;
    property Checkboxes: Boolean read FCheckboxes write SetCheckboxes
      default False;
    property GridLines: Boolean read FGridLines write SetGridLines default False;
    property HotTrack: Boolean read FHotTrack write SetHotTrack default False;
    property HideSelection: Boolean read FHideSelection write SetHideSelection
      default True;
    property ShowImages: Boolean read FShowImages write SetShowImages
      default True;
    property ShowItemFocusRect: Boolean
      read FShowItemFocusRect write SetShowItemFocusRect default False;

    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight
      default 0;
    property ScrollBarSize: Integer read FScrollBarSize write SetScrollBarSize
      default 0;
    property HeaderPadding: Integer read FHeaderPadding write SetHeaderPadding
      default 0;
    property ItemPadding: Integer read FItemPadding write SetItemPadding
      default 0;
    property IconSpacing: Integer read FIconSpacing write SetIconSpacing
      default 0;

    property SmallImages: TCssSvgImgList read FSmallImages write SetSmallImages;
    property LargeImages: TCssSvgImgList read FLargeImages write SetLargeImages;
    property StateImages: TCssSvgImgList read FStateImages write SetStateImages;
    property ImageVariant: string read FImageVariant write SetImageVariant;
    property SmallImageWidth: Integer read FSmallImageWidth
      write SetSmallImageWidth default 0;
    property SmallImageHeight: Integer read FSmallImageHeight
      write SetSmallImageHeight default 0;
    property LargeImageWidth: Integer read FLargeImageWidth
      write SetLargeImageWidth default 0;
    property LargeImageHeight: Integer read FLargeImageHeight
      write SetLargeImageHeight default 0;

    property SortType: TCssListSortType read FSortType write SetSortType
      default lstNone;
    property SortColumn: Integer read FSortColumn write SetSortColumn default -1;
    property SortDirection: TCssListSortDirection read FSortDirection
      write SetSortDirection default lsdAscending;
    property AutoSort: Boolean read FAutoSort write SetAutoSort default False;

    property ScrollBarCssClass: string read FScrollBarCssClass
      write SetScrollBarCssClass;
    property ScrollBarCssStyle: string read FScrollBarCssStyle
      write SetScrollBarCssStyle;
    property CheckBoxCssClass: string read FCheckBoxCssClass
      write SetCheckBoxCssClass;
    property CheckBoxCssStyle: string read FCheckBoxCssStyle
      write SetCheckBoxCssStyle;
    property EditCssClass: string read FEditCssClass write SetEditCssClass;
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property PlaceholderColor: TColor read FPlaceholderColor
      write SetPlaceholderColor default clNone;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Color;
    property Constraints;
    property CssTag;
    property CssID;
    property CssClass;
    property CssStyle;
    property StyleProvider;
    property StyleName;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    property OnSelectItem: TCssListItemSelectEvent read FOnSelectItem
      write FOnSelectItem;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnItemChecked: TCssListItemEvent read FOnItemChecked
      write FOnItemChecked;
    property OnItemActivate: TCssListItemEvent read FOnItemActivate
      write FOnItemActivate;
    property OnColumnClick: TCssListColumnEvent read FOnColumnClick
      write FOnColumnClick;
    property OnCompare: TCssListCompareEvent read FOnCompare write FOnCompare;
    property OnInsert: TCssListItemEvent read FOnInsert write FOnInsert;
    property OnDeletion: TCssListItemEvent read FOnDeletion write FOnDeletion;
    property OnEditing: TCssListEditingEvent read FOnEditing write FOnEditing;
    property OnEdited: TCssListEditedEvent read FOnEdited write FOnEdited;
    property OnDrawItem: TCssListDrawItemEvent read FOnDrawItem write FOnDrawItem;

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
    property OnResize;
  end;

implementation

uses
  CssUtils, CssAntiAlias;

function ListAlignmentToCss(AAlign: TAlignment): TCssTextAlign;
begin
  case AAlign of
    taCenter: Result := ctaCenter;
    taRightJustify: Result := ctaRight;
  else
    Result := ctaLeft;
  end;
end;

function CompareListItems(Item1, Item2: TCollectionItem;
  Context: Pointer): Integer;
begin
  Result := TCssListView(Context).CompareItems(
    TCssListItem(Item1), TCssListItem(Item2));
end;

{ TCssListColumn }

constructor TCssListColumn.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FCaption := '';
  FWidth := 120;
  FMinWidth := 24;
  FAlignment := taLeftJustify;
  FVisible := True;
  FAutoSize := False;
  FImageIndex := -1;
end;

function TCssListColumn.GetListView: TCssListView;
begin
  if Collection is TCssListColumns then
    Result := TCssListColumns(Collection).ListView
  else
    Result := nil;
end;

function TCssListColumn.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TCssListColumn.Assign(Source: TPersistent);
var
  Src: TCssListColumn;
begin
  if Source is TCssListColumn then
  begin
    Src := TCssListColumn(Source);

    FCaption := Src.FCaption;
    FWidth := Src.FWidth;
    FMinWidth := Src.FMinWidth;
    FAlignment := Src.FAlignment;
    FVisible := Src.FVisible;
    FAutoSize := Src.FAutoSize;
    FImageIndex := Src.FImageIndex;

    Changed(False);
  end
  else
    inherited Assign(Source);
end;

procedure TCssListColumn.SetCaption(const AValue: string);
begin
  if FCaption = AValue then
    Exit;

  FCaption := AValue;

  if FAutoSize then
    Width := 0;

  Changed(False);
end;

procedure TCssListColumn.SetWidth(AValue: Integer);
begin
  if AValue < FMinWidth then
    AValue := FMinWidth;

  if FWidth = AValue then
    Exit;

  FWidth := AValue;
  Changed(False);
end;

procedure TCssListColumn.SetMinWidth(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FMinWidth = AValue then
    Exit;

  FMinWidth := AValue;

  if FWidth < FMinWidth then
    FWidth := FMinWidth;

  Changed(False);
end;

procedure TCssListColumn.SetAlignment(AValue: TAlignment);
begin
  if FAlignment = AValue then
    Exit;

  FAlignment := AValue;
  Changed(False);
end;

procedure TCssListColumn.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then
    Exit;

  FVisible := AValue;
  Changed(False);
end;

procedure TCssListColumn.SetAutoSize(AValue: Boolean);
begin
  if FAutoSize = AValue then
    Exit;

  FAutoSize := AValue;
  Changed(False);
end;

procedure TCssListColumn.SetImageIndex(AValue: Integer);
begin
  if FImageIndex = AValue then
    Exit;

  FImageIndex := AValue;
  Changed(False);
end;

{ TCssListItem }

constructor TCssListItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FSubItems := TStringList.Create;
  FSubItems.OnChange := @SubItemsChanged;

  FCaption := '';
  FImageIndex := -1;
  FStateIndex := -1;
  FOverlayIndex := -1;
  FChecked := False;
  FData := nil;
  FIndent := 0;
end;

destructor TCssListItem.Destroy;
begin
  FSubItems.OnChange := nil;
  FreeAndNil(FSubItems);

  inherited Destroy;
end;

function TCssListItem.GetListView: TCssListView;
begin
  if Collection is TCssListItems then
    Result := TCssListItems(Collection).ListView
  else
    Result := nil;
end;

function TCssListItem.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TCssListItem.Assign(Source: TPersistent);
var
  Src: TCssListItem;
begin
  if Source is TCssListItem then
  begin
    Src := TCssListItem(Source);

    FCaption := Src.FCaption;
    FSubItems.Assign(Src.FSubItems);
    FImageIndex := Src.FImageIndex;
    FStateIndex := Src.FStateIndex;
    FOverlayIndex := Src.FOverlayIndex;
    FChecked := Src.FChecked;
    FData := Src.FData;
    FIndent := Src.FIndent;

    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TCssListItem.GetSelected: Boolean;
var
  LV: TCssListView;
begin
  LV := GetListView;
  Result := Assigned(LV) and LV.IsItemSelected(Self);
end;

procedure TCssListItem.SetSelected(AValue: Boolean);
var
  LV: TCssListView;
begin
  LV := GetListView;

  if Assigned(LV) then
    LV.SetItemSelectionFromItem(Self, AValue);
end;

procedure TCssListItem.SetCaption(const AValue: string);
begin
  if FCaption = AValue then
    Exit;

  FCaption := AValue;
  Changed(False);
end;

procedure TCssListItem.SetSubItems(AValue: TStrings);
begin
  if AValue = nil then
  begin
    if FSubItems.Count > 0 then
      FSubItems.Clear;
    Exit;
  end;

  if AValue = FSubItems then
    Exit;

  FSubItems.Assign(AValue);
end;

procedure TCssListItem.SetImageIndex(AValue: Integer);
begin
  if FImageIndex = AValue then
    Exit;

  FImageIndex := AValue;
  Changed(False);
end;

procedure TCssListItem.SetStateIndex(AValue: Integer);
begin
  if FStateIndex = AValue then
    Exit;

  FStateIndex := AValue;
  Changed(False);
end;

procedure TCssListItem.SetOverlayIndex(AValue: Integer);
begin
  if FOverlayIndex = AValue then
    Exit;

  FOverlayIndex := AValue;
  Changed(False);
end;

procedure TCssListItem.SetChecked(AValue: Boolean);
var
  LV: TCssListView;
begin
  if FChecked = AValue then
    Exit;

  FChecked := AValue;
  Changed(False);

  LV := GetListView;

  if Assigned(LV) then
    LV.DoItemChecked(Self);
end;

procedure TCssListItem.SetData(AValue: Pointer);
begin
  if FData = AValue then
    Exit;

  FData := AValue;
  Changed(False);
end;

procedure TCssListItem.SetIndent(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FIndent = AValue then
    Exit;

  FIndent := AValue;
  Changed(False);
end;

procedure TCssListItem.SubItemsChanged(Sender: TObject);
begin
  Changed(False);
end;

function TCssListItem.GetSubItemText(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < FSubItems.Count) then
    Result := FSubItems[AIndex]
  else
    Result := '';
end;

function TCssListItem.GetSubItems: TStrings;
begin
  Result := FSubItems;
end;

{ TCssListItems }

constructor TCssListItems.Create(AListView: TCssListView);
begin
  inherited Create(TCssListItem);
  FListView := AListView;
end;

function TCssListItems.GetOwner: TPersistent;
begin
  Result := FListView;
end;

function TCssListItems.GetItem(Index: Integer): TCssListItem;
begin
  Result := TCssListItem(inherited GetItem(Index));
end;

procedure TCssListItems.SetItem(Index: Integer; AValue: TCssListItem);
begin
  inherited SetItem(Index, AValue);
end;

function TCssListItems.Add: TCssListItem;
begin
  Result := TCssListItem(inherited Add);
end;

function TCssListItems.Insert(Index: Integer): TCssListItem;
begin
  Result := TCssListItem(inherited Insert(Index));
end;

function TCssListItems.AddItem(const ACaption: string): TCssListItem;
begin
  Result := Add;
  Result.Caption := ACaption;
end;

procedure TCssListItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);

  if FListView <> nil then
    FListView.ItemsChanged(Item);
end;

procedure TCssListItems.Notify(Item: TCollectionItem;
  Action: TCollectionNotification);
begin
  inherited Notify(Item, Action);

  if FListView = nil then
    Exit;

  case Action of
    cnAdded:
      FListView.DoItemInserted(TCssListItem(Item));

    cnExtracting, cnDeleting:
      FListView.DoItemDeleting(TCssListItem(Item));
  end;
end;

{ TCssListColumns }

constructor TCssListColumns.Create(AListView: TCssListView);
begin
  inherited Create(TCssListColumn);
  FListView := AListView;
end;

function TCssListColumns.GetOwner: TPersistent;
begin
  Result := FListView;
end;

function TCssListColumns.GetItem(Index: Integer): TCssListColumn;
begin
  Result := TCssListColumn(inherited GetItem(Index));
end;

procedure TCssListColumns.SetItem(Index: Integer; AValue: TCssListColumn);
begin
  inherited SetItem(Index, AValue);
end;

function TCssListColumns.Add: TCssListColumn;
begin
  Result := TCssListColumn(inherited Add);
end;

function TCssListColumns.Insert(Index: Integer): TCssListColumn;
begin
  Result := TCssListColumn(inherited Insert(Index));
end;

function TCssListColumns.AddItem(const ACaption: string;
  AWidth: Integer): TCssListColumn;
begin
  Result := Add;
  Result.Caption := ACaption;
  Result.Width := AWidth;
end;

procedure TCssListColumns.Update(Item: TCollectionItem);
begin
  inherited Update(Item);

  if FListView <> nil then
  begin
    FListView.UpdateScrollBars;
    FListView.Invalidate;
  end;
end;

procedure TCssListView.SetItems(AValue: TCssListItems);
begin
  if AValue = FItems then
    Exit;

  BeginUpdate;
  try
    if AValue = nil then
      FItems.Clear
    else
      FItems.Assign(AValue);
  finally
    EndUpdate;
  end;
end;

procedure TCssListView.SetColumns(AValue: TCssListColumns);
begin
  if AValue = FColumns then
    Exit;

  BeginUpdate;
  try
    if AValue = nil then
      FColumns.Clear
    else
      FColumns.Assign(AValue);
  finally
    EndUpdate;
  end;
end;

procedure TCssListView.SetViewStyle(AValue: TCssListViewStyle);
begin
  if FViewStyle = AValue then
    Exit;

  FViewStyle := AValue;

  FTopIndex := 0;
  FTopOffset := 0;
  FLeftOffset := 0;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetMultiSelect(AValue: Boolean);
var
  I: Integer;
  Keep: TCssListItem;
begin
  if FMultiSelect = AValue then
    Exit;

  FMultiSelect := AValue;

  if not FMultiSelect and (FSelection.Count > 1) then
  begin
    Keep := FFocusedItem;

    if Keep = nil then
      Keep := TCssListItem(FSelection[0]);

    for I := FSelection.Count - 1 downto 0 do
      if TCssListItem(FSelection[I]) <> Keep then
        SetItemSelection(TCssListItem(FSelection[I]), False, True);
  end;

  Invalidate;
end;

procedure TCssListView.SetRowSelect(AValue: Boolean);
begin
  if FRowSelect = AValue then
    Exit;

  FRowSelect := AValue;
  Invalidate;
end;

procedure TCssListView.SetReadOnly(AValue: Boolean);
begin
  if FReadOnly = AValue then
    Exit;

  FReadOnly := AValue;

  if FReadOnly then
    EndEdit(True);
end;

procedure TCssListView.SetShowColumnHeaders(AValue: Boolean);
begin
  if FShowColumnHeaders = AValue then
    Exit;

  FShowColumnHeaders := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetCheckboxes(AValue: Boolean);
begin
  if FCheckboxes = AValue then
    Exit;

  FCheckboxes := AValue;

  if FCheckboxes then
    UpdateCheckBoxStyle;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetGridLines(AValue: Boolean);
begin
  if FGridLines = AValue then
    Exit;

  FGridLines := AValue;
  Invalidate;
end;

procedure TCssListView.SetHotTrack(AValue: Boolean);
begin
  if FHotTrack = AValue then
    Exit;

  FHotTrack := AValue;

  if not FHotTrack then
    FHoverItem := nil;

  Invalidate;
end;

procedure TCssListView.SetHideSelection(AValue: Boolean);
begin
  if FHideSelection = AValue then
    Exit;

  FHideSelection := AValue;
  Invalidate;
end;

procedure TCssListView.SetShowImages(AValue: Boolean);
begin
  if FShowImages = AValue then
    Exit;

  FShowImages := AValue;
  Invalidate;
end;

procedure TCssListView.SetItemHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetHeaderHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FHeaderHeight = AValue then
    Exit;

  FHeaderHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetScrollBarSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FScrollBarSize = AValue then
    Exit;

  FScrollBarSize := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetHeaderPadding(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FHeaderPadding = AValue then
    Exit;

  FHeaderPadding := AValue;
  Invalidate;
end;

procedure TCssListView.SetItemPadding(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FItemPadding = AValue then
    Exit;

  FItemPadding := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetIconSpacing(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FIconSpacing = AValue then
    Exit;

  FIconSpacing := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetSmallImages(AValue: TCssSvgImgList);
begin
  if FSmallImages = AValue then
    Exit;

  if FSmallImages <> nil then
    FSmallImages.RemoveFreeNotification(Self);

  FSmallImages := AValue;

  if FSmallImages <> nil then
    FSmallImages.FreeNotification(Self);

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetLargeImages(AValue: TCssSvgImgList);
begin
  if FLargeImages = AValue then
    Exit;

  if FLargeImages <> nil then
    FLargeImages.RemoveFreeNotification(Self);

  FLargeImages := AValue;

  if FLargeImages <> nil then
    FLargeImages.FreeNotification(Self);

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetStateImages(AValue: TCssSvgImgList);
begin
  if FStateImages = AValue then
    Exit;

  if FStateImages <> nil then
    FStateImages.RemoveFreeNotification(Self);

  FStateImages := AValue;

  if FStateImages <> nil then
    FStateImages.FreeNotification(Self);

  Invalidate;
end;

procedure TCssListView.SetImageVariant(const AValue: string);
begin
  if FImageVariant = AValue then
    Exit;

  FImageVariant := AValue;
  Invalidate;
end;

procedure TCssListView.SetSmallImageWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FSmallImageWidth = AValue then
    Exit;

  FSmallImageWidth := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetSmallImageHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FSmallImageHeight = AValue then
    Exit;

  FSmallImageHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetLargeImageWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FLargeImageWidth = AValue then
    Exit;

  FLargeImageWidth := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetLargeImageHeight(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FLargeImageHeight = AValue then
    Exit;

  FLargeImageHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetSortType(AValue: TCssListSortType);
begin
  if FSortType = AValue then
    Exit;

  FSortType := AValue;
  Invalidate;

  if (FSortType <> lstNone) and
     not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) then
    Sort;
end;

procedure TCssListView.SetSortColumn(AValue: Integer);
begin
  if AValue < -1 then
    AValue := -1;

  if FSortColumn = AValue then
    Exit;

  FSortColumn := AValue;
  Invalidate;

  if (FSortType <> lstNone) and (FSortColumn >= 0) and
     not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) then
    Sort;
end;

procedure TCssListView.SetSortDirection(AValue: TCssListSortDirection);
begin
  if FSortDirection = AValue then
    Exit;

  FSortDirection := AValue;
  Invalidate;

  if (FSortType <> lstNone) and
     not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) then
    Sort;
end;

procedure TCssListView.SetAutoSort(AValue: Boolean);
begin
  if FAutoSort = AValue then
    Exit;

  FAutoSort := AValue;
end;

procedure TCssListView.SetScrollBarCssClass(const AValue: string);
begin
  if FScrollBarCssClass = AValue then
    Exit;

  FScrollBarCssClass := AValue;

  if Assigned(FVScroll) then
    FVScroll.CssClass := Trim(AValue + ' vscroll');

  if Assigned(FHScroll) then
    FHScroll.CssClass := Trim(AValue + ' hscroll');

  Invalidate;
end;

procedure TCssListView.SetScrollBarCssStyle(const AValue: string);
begin
  if FScrollBarCssStyle = AValue then
    Exit;

  FScrollBarCssStyle := AValue;

  if Assigned(FVScroll) then
    FVScroll.CssStyle := AValue;

  if Assigned(FHScroll) then
    FHScroll.CssStyle := AValue;

  Invalidate;
end;

procedure TCssListView.SetCheckBoxCssClass(const AValue: string);
begin
  if FCheckBoxCssClass = AValue then
    Exit;

  FCheckBoxCssClass := AValue;
  UpdateCheckBoxStyle;
  Invalidate;
end;

procedure TCssListView.SetCheckBoxCssStyle(const AValue: string);
begin
  if FCheckBoxCssStyle = AValue then
    Exit;

  FCheckBoxCssStyle := AValue;
  UpdateCheckBoxStyle;
  Invalidate;
end;

procedure TCssListView.SetEditCssClass(const AValue: string);
begin
  if FEditCssClass = AValue then
    Exit;

  FEditCssClass := AValue;

  if Assigned(FEdit) then
    FEdit.CssClass := AValue;
end;

procedure TCssListView.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder = AValue then
    Exit;

  FPlaceholder := AValue;
  Invalidate;
end;

procedure TCssListView.SetPlaceholderColor(AValue: TColor);
begin
  if FPlaceholderColor = AValue then
    Exit;

  FPlaceholderColor := AValue;
  FPlaceholderColorSet := True;
  Invalidate;
end;

procedure TCssListView.SetShowItemFocusRect(AValue: Boolean);
begin
  if FShowItemFocusRect = AValue then
    Exit;
  FShowItemFocusRect := AValue;
  Invalidate;
end;

function TCssListView.BeginContentClip: Integer;
var
  Radii: TCssCornerRadii;
  R: TRect;
  RMax: Integer;
  Rgn: HRGN;
begin
  Result := 0;

  Radii := GetCssBorderRadii;

  if (Radii.TL <= 0) and (Radii.TR <= 0) and
     (Radii.BR <= 0) and (Radii.BL <= 0) then
    Exit;

  R := ClientRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  RMax := Radii.TL;
  if Radii.TR > RMax then RMax := Radii.TR;
  if Radii.BR > RMax then RMax := Radii.BR;
  if Radii.BL > RMax then RMax := Radii.BL;

  if RMax < 0 then
    RMax := 0;

  Result := SaveDC(Canvas.Handle);

  if Result = 0 then
    Exit;

  Rgn := CreateRoundRectRgn(
    R.Left, R.Top, R.Right + 1, R.Bottom + 1, 2 * RMax, 2 * RMax);

  if Rgn <> 0 then
  begin
    ExtSelectClipRGN(Canvas.Handle, Rgn, RGN_AND);
    DeleteObject(Rgn);
  end;
end;

function TCssListView.PushClipRect(const ARect: TRect): Integer;
var
  Rgn: HRGN;
begin
  Result := 0;

  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  Result := SaveDC(Canvas.Handle);

  if Result = 0 then
    Exit;

  Rgn := CreateRectRgn(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);

  if Rgn <> 0 then
  begin
    ExtSelectClipRGN(Canvas.Handle, Rgn, RGN_AND);
    DeleteObject(Rgn);
  end;
end;

procedure TCssListView.PopClipRect(ASavedDC: Integer);
begin
  if ASavedDC <> 0 then
  begin
    RestoreDC(Canvas.Handle, ASavedDC);
    // RestoreDC also restores the pen/brush/font that were selected in
    // the DC when the state was saved. Tell the LCL canvas to reselect
    // its own handles, otherwise a later "Pen.Color := <same value>"
    // becomes a no-op and leaves the restored (usually black) pen active.
    Canvas.Refresh;
  end;
end;

procedure TCssListView.RestoreRoundedBorder;
var
  Radii: TCssCornerRadii;
  R: TRect;
  BW, RMax: Integer;
begin
  BW := GetCssBorderWidth;

  if BW <= 0 then
    Exit;

  Radii := GetCssBorderRadii;

  if (Radii.TL <= 0) and (Radii.TR <= 0) and
     (Radii.BR <= 0) and (Radii.BL <= 0) then
    Exit;

  RMax := Radii.TL;
  if Radii.TR > RMax then RMax := Radii.TR;
  if Radii.BR > RMax then RMax := Radii.BR;
  if Radii.BL > RMax then RMax := Radii.BL;

  // DrawAARoundedRectRing insets its geometry by one pixel, so pass a
  // rect inflated by one to line the ring up with the outer border edge.
  R := ClientRect;
  InflateRect(R, 1, 1);

  CssAntiAlias.DrawAARoundedRectRing(
    Canvas, R, RMax, BW, GetEffectiveBorderColor);
end;

procedure TCssListView.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FSmallImages then
    begin
      FSmallImages := nil;
      UpdateScrollBars;
    end
    else if AComponent = FLargeImages then
    begin
      FLargeImages := nil;
      UpdateScrollBars;
    end
    else if AComponent = FStateImages then
      FStateImages := nil;
  end;

  inherited Notification(AComponent, Operation);
end;

// --- CSS colour accessors ---

function TCssListView.GetHeaderBackground: TColor;
begin
  if FHeaderBackgroundSet then
    Exit(FHeaderBackground);

  Result := GetCssBackgroundColor;

  if (Result = clNone) or (Result = clDefault) then
    Result := clBtnFace;
end;

function TCssListView.GetHeaderTextColor: TColor;
begin
  if FHeaderColorSet then
    Exit(FHeaderColor);

  Result := GetEffectiveTextColor;
end;

function TCssListView.GetHeaderHoverBackground: TColor;
begin
  if FHeaderHoverBackgroundSet then
    Exit(FHeaderHoverBackground);

  Result := GetHoverBackground;
end;

function TCssListView.GetItemBackground: TColor;
begin
  if FItemBackgroundSet then
    Exit(FItemBackground);

  Result := GetCssBackgroundColor;

  if (Result = clNone) or (Result = clDefault) then
    Result := clWindow;
end;

function TCssListView.GetItemTextColor: TColor;
begin
  if FItemColorSet then
    Exit(FItemColor);

  Result := GetEffectiveTextColor;
end;

function TCssListView.GetItemHoverBackground: TColor;
begin
  if FItemHoverBackgroundSet then
    Exit(FItemHoverBackground);

  Result := GetHoverBackground;
end;

function TCssListView.GetItemHoverTextColor: TColor;
begin
  if FItemHoverColorSet then
    Exit(FItemHoverColor);

  Result := GetItemTextColor;
end;

function TCssListView.GetItemSelectedBackground: TColor;
begin
  if FItemSelectedBackgroundSet then
    Exit(FItemSelectedBackground);

  Result := GetSelectionBackground;
end;

function TCssListView.GetItemSelectedTextColor: TColor;
begin
  if FItemSelectedColorSet then
    Exit(FItemSelectedColor);

  Result := GetSelectionColor;
end;

function TCssListView.GetSelectionBackground: TColor;
begin
  if FSelectionBackgroundSet then
    Exit(FSelectionBackground);

  Result := RGBToColor(51, 153, 255);
end;

function TCssListView.GetSelectionColor: TColor;
begin
  if FSelectionColorSet then
    Exit(FSelectionColor);

  Result := RGBToColor(255, 255, 255);
end;

function TCssListView.GetHoverBackground: TColor;
begin
  if FHoverBackgroundSet then
    Exit(FHoverBackground);

  Result := RGBToColor(229, 243, 255);
end;

function TCssListView.GetGridColor: TColor;
begin
  if FGridColorSet then
    Exit(FGridColor);

  Result := RGBToColor(215, 220, 225);
end;

function TCssListView.GetLineColor: TColor;
begin
  if FLineColorSet then
    Exit(FLineColor);

  Result := GetGridColor;
end;

function TCssListView.GetSortMarkerColor: TColor;
begin
  if FSortMarkerColorSet then
    Exit(FSortMarkerColor);

  Result := GetItemTextColor;
end;

function TCssListView.GetDisabledBackground: TColor;
begin
  if FDisabledBackgroundSet then
    Exit(FDisabledBackground);

  Result := GetItemBackground;
end;

function TCssListView.GetDisabledColor: TColor;
begin
  if FDisabledColorSet then
    Exit(FDisabledColor);

  Result := RGBToColor(160, 160, 160);
end;

function TCssListView.GetCheckColor: TColor;
begin
  if FCheckColorSet then
    Exit(FCheckColor);

  Result := GetItemTextColor;
end;

function TCssListView.GetPlaceholderColor: TColor;
begin
  if FPlaceholderColorSet and (FPlaceholderColor <> clNone) then
    Exit(FPlaceholderColor);

  Result := RGBToColor(150, 150, 150);
end;

function TCssListView.GetEffectiveImageVariant: string;
begin
  if FImageVariant <> '' then
    Exit(FImageVariant);

  if StyleName <> '' then
    Exit(StyleName);

  if Assigned(StyleProvider) and (StyleProvider.DefaultStyleName <> '') then
    Exit(StyleProvider.DefaultStyleName);

  Result := '';
end;

function TCssListView.GetEffectiveItemHeight: Integer;
begin
  if FItemHeight > 0 then
    Result := FItemHeight
  else
    Result := ScalePx(22);
end;

function TCssListView.GetEffectiveHeaderHeight: Integer;
begin
  if FHeaderHeight > 0 then
    Result := FHeaderHeight
  else
    Result := ScalePx(24);
end;

function TCssListView.GetEffectiveScrollBarSize: Integer;
begin
  if FScrollBarSize > 0 then
    Result := FScrollBarSize
  else
    Result := ScalePx(16);
end;

function TCssListView.GetEffectiveHeaderPadding: Integer;
begin
  if FHeaderPadding > 0 then
    Result := FHeaderPadding
  else
    Result := ScalePx(8);
end;

function TCssListView.GetEffectiveItemPadding: Integer;
begin
  if FItemPadding > 0 then
    Result := FItemPadding
  else
    Result := ScalePx(4);
end;

constructor TCssListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width := 320;
  Height := 220;
  TabStop := True;

  SetVAlign(cvaMiddle);
  SetWordWrap(False);

  FItems := TCssListItems.Create(Self);
  FColumns := TCssListColumns.Create(Self);
  FSelection := TList.Create;

  FViewStyle := lvsReport;
  FMultiSelect := False;
  FRowSelect := False;
  FReadOnly := False;
  FShowColumnHeaders := True;
  FCheckboxes := False;
  FGridLines := False;
  FHotTrack := False;
  FHideSelection := True;
  FShowImages := True;
  FShowItemFocusRect := False;

  FItemHeight := 0;
  FHeaderHeight := 0;
  FScrollBarSize := 0;
  FHeaderPadding := 0;
  FItemPadding := 0;
  FIconSpacing := 0;

  FSmallImages := nil;
  FLargeImages := nil;
  FStateImages := nil;
  FImageVariant := '';
  FSmallImageWidth := 0;
  FSmallImageHeight := 0;
  FLargeImageWidth := 0;
  FLargeImageHeight := 0;

  FSortType := lstNone;
  FSortColumn := -1;
  FSortDirection := lsdAscending;
  FAutoSort := False;

  FTopIndex := 0;
  FTopOffset := 0;
  FLeftOffset := 0;

  FScrollBarCssClass := 'listview-scrollbar';
  FScrollBarCssStyle := '';
  FScrollCapture := nil;
  FScrollUpdating := False;

  FFocusedItem := nil;
  FFocusedColumn := 0;
  FAnchorItem := nil;
  FHoverItem := nil;
  FHotHeaderColumn := -1;

  FUpdateCount := 0;
  FUpdating := False;

  FResizingColumn := -1;
  FResizeStartX := 0;
  FResizeStartWidth := 0;
  FResizeStartLeft := 0;

  FLastMouse := Point(0, 0);
  FMouseDown := False;
  FMouseDownItem := nil;
  FRubberBanding := False;
  FRubberRect := Rect(0, 0, 0, 0);
  FSearchText := '';
  FSearchTime := 0;

  FCheckBoxNormal := nil;
  FCheckBoxChecked := nil;
  FCheckBoxHover := nil;
  FCheckBoxCheckedHover := nil;
  FCheckBoxCssClass := 'listview-checkbox checkbox';
  FCheckBoxCssStyle := '';
  FCheckBoxInlineCss := '';
  FCheckColor := clNone;
  FCheckColorSet := False;

  FPlaceholder := '';
  FPlaceholderColor := clNone;
  FPlaceholderColorSet := False;

  FVScroll := TCssScrollBar.Create(Self);
  FVScroll.Kind := sbVertical;
  FVScroll.TabStop := False;
  FVScroll.Visible := False;
  FVScroll.CssClass := Trim(FScrollBarCssClass + ' vscroll');
  FVScroll.OnChange := @DoVScroll;
  FVScroll.SetBounds(0, 0, 0, 0);

  FHScroll := TCssScrollBar.Create(Self);
  FHScroll.Kind := sbHorizontal;
  FHScroll.TabStop := False;
  FHScroll.Visible := False;
  FHScroll.CssClass := Trim(FScrollBarCssClass + ' hscroll');
  FHScroll.OnChange := @DoHScroll;
  FHScroll.SetBounds(0, 0, 0, 0);

  FEdit := TCssEdit.Create(Self);
  FEdit.ControlStyle := FEdit.ControlStyle + [csNoDesignVisible];
  FEdit.Parent := Self;
  FEdit.Visible := False;
  FEdit.TabStop := False;
  FEditCssClass := 'listview-edit';
  FEdit.CssClass := FEditCssClass;
  FEdit.OnKeyDown := @EditKeyDown;
  FEdit.OnExit := @EditExit;

  FEditingItem := nil;
  FEditOldText := '';
  FEditClosing := False;

  UpdateScrollBars;
end;

destructor TCssListView.Destroy;
begin
  FEditClosing := True;

  if Assigned(FEdit) then
  begin
    FEdit.OnKeyDown := nil;
    FEdit.OnExit := nil;
    FEdit.Visible := False;
  end;

  if Assigned(FItems) then
    FItems.FListView := nil;

  if Assigned(FColumns) then
    FColumns.FListView := nil;

  FreeCheckBoxHelpers;

  FreeAndNil(FSelection);
  FreeAndNil(FEdit);
  FreeAndNil(FVScroll);
  FreeAndNil(FHScroll);
  FreeAndNil(FItems);
  FreeAndNil(FColumns);

  inherited Destroy;
end;

procedure TCssListView.BeginUpdate;
begin
  Inc(FUpdateCount);
  FUpdating := True;
end;

procedure TCssListView.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount = 0 then
  begin
    FUpdating := False;

    if not (csDestroying in ComponentState) then
    begin
      UpdateScrollBars;
      Invalidate;
    end;
  end;
end;

function TCssListView.AddItem(const ACaption: string): TCssListItem;
begin
  Result := FItems.AddItem(ACaption);
end;

procedure TCssListView.Clear;
begin
  BeginUpdate;
  try
    FItems.Clear;
    FTopIndex := 0;
    FTopOffset := 0;
    FLeftOffset := 0;
    FFocusedItem := nil;
    FAnchorItem := nil;
    FHoverItem := nil;
  finally
    EndUpdate;
  end;
end;

procedure TCssListView.SelectAll;
var
  I: Integer;
begin
  if not FMultiSelect then
  begin
    if FItems.Count > 0 then
      SetItemIndex(0);
    Exit;
  end;

  BeginUpdate;
  try
    for I := 0 to FItems.Count - 1 do
      SetItemSelection(FItems[I], True, True);
  finally
    EndUpdate;
  end;
end;

procedure TCssListView.ClearSelection;
begin
  ClearSelectionInternal(True);
  Invalidate;
end;

procedure TCssListView.ItemsChanged(AItem: TCollectionItem);
begin
  if FUpdating or (FUpdateCount > 0) then
    Exit;

  UpdateScrollBars;
  Invalidate;

  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TCssListView.DoItemInserted(AItem: TCssListItem);
begin
  if FUpdating or (FUpdateCount > 0) then
    Exit;

  UpdateScrollBars;
  Invalidate;

  if Assigned(FOnInsert) then
    FOnInsert(Self, AItem);

  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TCssListView.DoItemDeleting(AItem: TCssListItem);
begin
  if Assigned(FEdit) and (FEditingItem = AItem) then
    EndEditInternal(True);

  if IsItemSelected(AItem) then
    SetItemSelection(AItem, False, True);

  if FFocusedItem = AItem then
    FFocusedItem := nil;

  if FAnchorItem = AItem then
    FAnchorItem := nil;

  if FHoverItem = AItem then
    FHoverItem := nil;

  if FMouseDownItem = AItem then
    FMouseDownItem := nil;

  if not FUpdating and (FUpdateCount = 0) then
  begin
    UpdateScrollBars;
    Invalidate;

    if Assigned(FOnDeletion) then
      FOnDeletion(Self, AItem);

    if Assigned(FOnChange) and not (csLoading in ComponentState) then
      FOnChange(Self);
  end;
end;

procedure TCssListView.DoItemChecked(AItem: TCssListItem);
begin
  Invalidate;

  if Assigned(FOnItemChecked) then
    FOnItemChecked(Self, AItem);
end;

procedure TCssListView.SetItemSelectionFromItem(AItem: TCssListItem;
  AValue: Boolean);
begin
  SetItemSelection(AItem, AValue, True);
end;

// --- Selection helpers ---

function TCssListView.IsItemSelected(AItem: TCssListItem): Boolean;
begin
  Result := Assigned(AItem) and (FSelection.IndexOf(AItem) >= 0);
end;

procedure TCssListView.NotifySelectionChange(AItem: TCssListItem;
  ASelected: Boolean);
begin
  Invalidate;

  if Assigned(FOnSelectItem) then
    FOnSelectItem(Self, AItem, ASelected);
end;

procedure TCssListView.SetItemSelection(AItem: TCssListItem;
  AValue: Boolean; ANotify: Boolean);
var
  Idx: Integer;
begin
  if AItem = nil then
    Exit;

  Idx := FSelection.IndexOf(AItem);

  if AValue then
  begin
    if Idx >= 0 then
      Exit;

    if not FMultiSelect then
      ClearSelectionInternal(ANotify);

    FSelection.Add(AItem);

    if FFocusedItem = nil then
      FFocusedItem := AItem;

    if ANotify then
      NotifySelectionChange(AItem, True)
    else
      Invalidate;
  end
  else
  begin
    if Idx < 0 then
      Exit;

    FSelection.Delete(Idx);

    if FFocusedItem = AItem then
      FFocusedItem := nil;

    if ANotify then
      NotifySelectionChange(AItem, False)
    else
      Invalidate;
  end;
end;

procedure TCssListView.ClearSelectionInternal(ANotify: Boolean);
begin
  while FSelection.Count > 0 do
    SetItemSelection(TCssListItem(FSelection[FSelection.Count - 1]), False, ANotify);

  FFocusedItem := nil;
  FAnchorItem := nil;

  if not ANotify then
    Invalidate;
end;

procedure TCssListView.SetFocusedItem(AItem: TCssListItem);
begin
  if FFocusedItem = AItem then
    Exit;

  FFocusedItem := AItem;
  Invalidate;
end;

procedure TCssListView.SetFocusedColumn(AValue: Integer);
var
  I, L, W, VW, NewOffset: Integer;
  VR: TRect;
begin
  if FColumns.Count = 0 then
    Exit;

  if AValue < 0 then
    AValue := 0;

  if AValue >= FColumns.Count then
    AValue := FColumns.Count - 1;

  // Skip hidden columns in the requested direction.
  if GetColumnWidth(AValue) <= 0 then
  begin
    if AValue >= FFocusedColumn then
    begin
      I := AValue;

      while (I < FColumns.Count) and (GetColumnWidth(I) <= 0) do
        Inc(I);

      if I >= FColumns.Count then
        Exit;
    end
    else
    begin
      I := AValue;

      while (I >= 0) and (GetColumnWidth(I) <= 0) do
        Dec(I);

      if I < 0 then
        Exit;
    end;

    AValue := I;
  end;

  if FFocusedColumn = AValue then
    Exit;

  FFocusedColumn := AValue;

  // Keep the newly focused column inside the visible area.
  L := GetColumnLeft(AValue);
  W := GetColumnWidth(AValue);
  VR := GetViewRect;
  VW := VR.Right - VR.Left;

  if VW > 0 then
  begin
    NewOffset := FLeftOffset;

    if L < NewOffset then
      NewOffset := L
    else if L + W > NewOffset + VW then
      NewOffset := L + W - VW;

    if NewOffset <> FLeftOffset then
      SetLeftOffset(NewOffset);
  end;

  Invalidate;
end;

function TCssListView.GetEffectiveFocusedColumn: Integer;
var
  I: Integer;
begin
  Result := 0;

  if FColumns.Count = 0 then
    Exit;

  Result := FFocusedColumn;

  if Result < 0 then
    Result := 0;

  if Result >= FColumns.Count then
    Result := FColumns.Count - 1;

  if GetColumnWidth(Result) > 0 then
    Exit;

  for I := 0 to FColumns.Count - 1 do
    if GetColumnWidth(I) > 0 then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TCssListView.SelectRange(AFrom, ATo: TCssListItem;
  AAdditive: Boolean);
var
  I, Idx1, Idx2, Tmp: Integer;
begin
  if (AFrom = nil) or (ATo = nil) then
  begin
    if ATo <> nil then
      SetItemSelection(ATo, True, True);
    Exit;
  end;

  Idx1 := IndexOfItem(AFrom);
  Idx2 := IndexOfItem(ATo);

  if (Idx1 < 0) or (Idx2 < 0) then
  begin
    SetItemSelection(ATo, True, True);
    Exit;
  end;

  if Idx1 > Idx2 then
  begin
    Tmp := Idx1;
    Idx1 := Idx2;
    Idx2 := Tmp;
  end;

  if not AAdditive then
    ClearSelectionInternal(True);

  for I := Idx1 to Idx2 do
    SetItemSelection(FItems[I], True, True);
end;

procedure TCssListView.SetItemIndex(AValue: Integer);
var
  Item: TCssListItem;
begin
  if (AValue < 0) or (AValue >= FItems.Count) then
  begin
    ClearSelectionInternal(True);
    Invalidate;
    Exit;
  end;

  Item := FItems[AValue];

  ClearSelectionInternal(True);
  SetItemSelection(Item, True, True);
  FFocusedItem := Item;
  FAnchorItem := Item;

  ScrollIntoView(Item);
  Invalidate;
end;

function TCssListView.GetItemIndex: Integer;
begin
  Result := -1;

  if Assigned(FFocusedItem) and IsItemSelected(FFocusedItem) then
    Result := IndexOfItem(FFocusedItem)
  else if FSelection.Count > 0 then
    Result := IndexOfItem(TCssListItem(FSelection[0]));
end;

function TCssListView.GetSelectedItem: TCssListItem;
begin
  if Assigned(FFocusedItem) and IsItemSelected(FFocusedItem) then
    Result := FFocusedItem
  else if FSelection.Count > 0 then
    Result := TCssListItem(FSelection[0])
  else
    Result := nil;
end;

function TCssListView.GetSelCount: Integer;
begin
  Result := FSelection.Count;
end;

function TCssListView.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

function TCssListView.GetTopItem: TCssListItem;
begin
  Result := ItemFromIndex(FTopIndex);
end;

procedure TCssListView.SetTopItem(AValue: TCssListItem);
begin
  SetTopIndex(IndexOfItem(AValue));
end;

function TCssListView.GetVisibleRowCount: Integer;
var
  H: Integer;
begin
  H := GetViewRect.Height;

  case FViewStyle of
    lvsReport:
      Result := CssMax(1, H div CssMax(1, GetRowStep));
    lvsList:
      Result := CssMax(1, H div CssMax(1, GetListItemStep));
    lvsSmallIcon:
      Result := CssMax(1, H div CssMax(1, GetIconRowStep));
    lvsIcon:
      Result := CssMax(1, H div CssMax(1, GetIconRowStep));
  else
    Result := 1;
  end;
end;

function TCssListView.GetRowStep: Integer;
begin
  Result := CssMax(1, GetEffectiveItemHeight);
end;

function TCssListView.GetIconRowStep: Integer;
var
  S: TSize;
begin
  S := GetLargeImageSize;
  Result := CssMax(GetRowStep, S.cy + ScalePx(26));
end;

function TCssListView.GetListItemStep: Integer;
begin
  Result := GetRowStep;
end;

function TCssListView.GetListViewportWidth: Integer;
begin
  Result := GetViewRect.Width;
end;

function TCssListView.GetListViewportHeight: Integer;
begin
  Result := GetViewRect.Height;
end;

function TCssListView.ItemFromIndex(AIndex: Integer): TCssListItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := FItems[AIndex]
  else
    Result := nil;
end;

function TCssListView.IndexOfItem(AItem: TCssListItem): Integer;
begin
  if Assigned(AItem) and (AItem.Collection = FItems) then
    Result := AItem.Index
  else
    Result := -1;
end;

function TCssListView.GetHeaderRect: TRect;
var
  R: TRect;
begin
  Result := Rect(0, 0, 0, 0);

  if (FViewStyle <> lvsReport) or (not FShowColumnHeaders) then
    Exit;

  R := GetContentRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  Result := Rect(R.Left, R.Top, R.Right, R.Top + GetEffectiveHeaderHeight);
end;

function TCssListView.GetViewRect: TRect;
var
  R: TRect;
  H: Integer;
begin
  R := GetContentRect;

  H := GetHeaderRect.Height;

  if H > 0 then
    Inc(R.Top, H);

  if Assigned(FVScroll) and FVScroll.Visible then
    Dec(R.Right, GetEffectiveScrollBarSize);

  if Assigned(FHScroll) and FHScroll.Visible then
    Dec(R.Bottom, GetEffectiveScrollBarSize);

  if R.Right < R.Left then
    R.Right := R.Left;

  if R.Bottom < R.Top then
    R.Bottom := R.Top;

  Result := R;
end;

function TCssListView.GetColumnWidth(AIndex: Integer): Integer;
begin
  if (AIndex >= 0) and (AIndex < FColumns.Count) and FColumns[AIndex].Visible then
    Result := CssMax(FColumns[AIndex].MinWidth, FColumns[AIndex].Width)
  else
    Result := 0;
end;

function TCssListView.GetColumnLeft(AIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;

  for I := 0 to AIndex - 1 do
    Inc(Result, GetColumnWidth(I));
end;

function TCssListView.GetTotalColumnsWidth: Integer;
var
  I: Integer;
begin
  Result := 0;

  for I := 0 to FColumns.Count - 1 do
    Inc(Result, GetColumnWidth(I));
end;

function TCssListView.GetColumnAt(X: Integer): Integer;
var
  I, L, W: Integer;
  Base: Integer;
begin
  Result := -1;

  if FColumns.Count = 0 then
    Exit;

  Base := GetViewRect.Left - FLeftOffset;
  L := Base;

  for I := 0 to FColumns.Count - 1 do
  begin
    W := GetColumnWidth(I);

    if W <= 0 then
      Continue;

    if (X >= L) and (X < L + W) then
    begin
      Result := I;
      Exit;
    end;

    Inc(L, W);
  end;
end;

function TCssListView.GetHeaderResizeColumnAt(X: Integer): Integer;
var
  I, L, W: Integer;
  Base: Integer;
begin
  Result := -1;

  if FColumns.Count = 0 then
    Exit;

  Base := GetViewRect.Left - FLeftOffset;
  L := Base;

  for I := 0 to FColumns.Count - 1 do
  begin
    W := GetColumnWidth(I);

    if W <= 0 then
      Continue;

    Inc(L, W);

    if Abs(X - L) <= ScalePx(3) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TCssListView.GetPageRows: Integer;
begin
  Result := GetVisibleRowCount;
end;

function TCssListView.GetItemsPerListColumn: Integer;
var
  R: TRect;
begin
  R := GetViewRect;
  Result := CssMax(1, R.Height div CssMax(1, GetListItemStep));
end;

function TCssListView.GetIconColumnCount: Integer;
var
  R: TRect;
  S: TSize;
  CellW: Integer;
begin
  R := GetViewRect;

  if FViewStyle = lvsSmallIcon then
  begin
    CellW := GetColumnWidth(0);

    if CellW <= 0 then
      CellW := ScalePx(160);

    CellW := CssMax(CellW, ScalePx(64));
  end
  else
  begin
    S := GetLargeImageSize;
    CellW := CssMax(ScalePx(76), S.cx + ScalePx(28));

    if GetColumnWidth(0) > 0 then
      CellW := CssMax(CellW, GetColumnWidth(0));
  end;

  Result := CssMax(1, R.Width div CellW);
end;

function TCssListView.GetArrowTargetIndex(AKey: Word; AIndex: Integer): Integer;
var
  ACount, Rows, Cells, Col, Row, TargetCol, Target: Integer;

  function LastItemInColumn(AColumn: Integer): Integer;
  begin
    if (ACount <= 0) or (Cells <= 0) then
      Exit(-1);

    if AColumn < 0 then
      Exit(-1);

    if AColumn >= ACount then
      Exit(ACount - 1);

    Result := AColumn + ((ACount - 1 - AColumn) div Cells) * Cells;

    if Result >= ACount then
      Result := ACount - 1;
  end;

begin
  ACount := FItems.Count;

  if ACount <= 0 then
    Exit(-1);

  if AIndex < 0 then
    Exit(0);

  if AIndex >= ACount then
    AIndex := ACount - 1;

  Result := AIndex;

  case FViewStyle of
    lvsReport:
      begin
        if AKey = VK_UP then
          Result := AIndex - 1
        else if AKey = VK_DOWN then
          Result := AIndex + 1;
      end;

    lvsList:
      begin
        Rows := GetItemsPerListColumn;
        Col := AIndex div Rows;
        Row := AIndex mod Rows;

        if AKey = VK_UP then
        begin
          if Row > 0 then
            Result := AIndex - 1;
        end
        else if AKey = VK_DOWN then
        begin
          if (Row < Rows - 1) and (AIndex + 1 < ACount) then
            Result := AIndex + 1;
        end
        else if AKey = VK_LEFT then
        begin
          if Col > 0 then
          begin
            Target := (Col - 1) * Rows + Row;

            if Target >= ACount then
              Target := ACount - 1;

            Result := Target;
          end;
        end
        else if AKey = VK_RIGHT then
        begin
          TargetCol := Col + 1;

          if TargetCol * Rows < ACount then
          begin
            Target := TargetCol * Rows + Row;

            if Target >= ACount then
              Target := ACount - 1;

            Result := Target;
          end;
        end;
      end;

    lvsSmallIcon, lvsIcon:
      begin
        Cells := GetIconColumnCount;
        Col := AIndex mod Cells;
        Row := AIndex div Cells;

        if AKey = VK_UP then
        begin
          if Row > 0 then
          begin
            Target := (Row - 1) * Cells + Col;

            if Target >= ACount then
              Target := LastItemInColumn(Col);

            Result := Target;
          end;
        end
        else if AKey = VK_DOWN then
        begin
          Target := (Row + 1) * Cells + Col;

          if Target >= ACount then
            Target := LastItemInColumn(Col);

          Result := Target;
        end
        else if AKey = VK_LEFT then
        begin
          if Col > 0 then
          begin
            Target := Row * Cells + (Col - 1);

            if Target >= ACount then
              Target := LastItemInColumn(Col - 1);

            Result := Target;
          end;
        end
        else if AKey = VK_RIGHT then
        begin
          if Col + 1 < Cells then
          begin
            Target := Row * Cells + (Col + 1);

            if Target >= ACount then
              Target := LastItemInColumn(Col + 1);

            Result := Target;
          end;
        end;
      end;
  end;

  if Result < 0 then
    Result := 0;

  if Result >= ACount then
    Result := ACount - 1;
end;

function TCssListView.GetReportItemRect(AIndex: Integer): TRect;
var
  R: TRect;
  W: Integer;
  ItemTop: Integer;
begin
  R := GetViewRect;

  W := GetTotalColumnsWidth;

  if W <= 0 then
    W := R.Width;

  ItemTop := R.Top + (AIndex - FTopIndex) * GetRowStep;

  Result := Rect(
    R.Left - FLeftOffset,
    ItemTop,
    R.Left - FLeftOffset + W,
    ItemTop + GetRowStep
  );
end;

function TCssListView.GetListItemRect(AIndex: Integer): TRect;
var
  R: TRect;
  CellW, CellH, Rows, Col, Row: Integer;
begin
  R := GetViewRect;

  CellW := GetColumnWidth(0);

  if CellW <= 0 then
    CellW := ScalePx(160);

  CellW := CssMax(CellW, ScalePx(48));

  CellH := CssMax(1, GetListItemStep);
  Rows := CssMax(1, R.Height div CellH);

  Col := AIndex div Rows;
  Row := AIndex mod Rows;

  Result := Rect(
    R.Left - FLeftOffset + Col * CellW,
    R.Top + Row * CellH,
    R.Left - FLeftOffset + (Col + 1) * CellW,
    R.Top + Row * CellH + CellH
  );
end;

function TCssListView.GetSmallIconItemRect(AIndex: Integer): TRect;
var
  R: TRect;
  CellW, CellH, Cols, Col, Row: Integer;
begin
  R := GetViewRect;

  CellW := GetColumnWidth(0);

  if CellW <= 0 then
    CellW := ScalePx(160);

  CellW := CssMax(CellW, ScalePx(64));

  CellH := CssMax(1, GetListItemStep);
  Cols := CssMax(1, R.Width div CellW);

  Col := AIndex mod Cols;
  Row := AIndex div Cols;

  Result := Rect(
    R.Left - FLeftOffset + Col * CellW,
    R.Top - FTopOffset + Row * CellH,
    R.Left - FLeftOffset + (Col + 1) * CellW,
    R.Top - FTopOffset + Row * CellH + CellH
  );
end;

function TCssListView.GetIconItemRect(AIndex: Integer): TRect;
var
  R: TRect;
  S: TSize;
  CellW, CellH, Cols, Col, Row: Integer;
begin
  R := GetViewRect;

  S := GetLargeImageSize;

  CellW := CssMax(ScalePx(76), S.cx + ScalePx(28));

  if GetColumnWidth(0) > 0 then
    CellW := CssMax(CellW, GetColumnWidth(0));

  CellH := CssMax(1, GetIconRowStep);
  Cols := CssMax(1, R.Width div CellW);

  Col := AIndex mod Cols;
  Row := AIndex div Cols;

  Result := Rect(
    R.Left - FLeftOffset + Col * CellW,
    R.Top - FTopOffset + Row * CellH,
    R.Left - FLeftOffset + (Col + 1) * CellW,
    R.Top - FTopOffset + Row * CellH + CellH
  );
end;

function TCssListView.GetItemRect(AIndex: Integer): TRect;
begin
  case FViewStyle of
    lvsReport:    Result := GetReportItemRect(AIndex);
    lvsList:      Result := GetListItemRect(AIndex);
    lvsSmallIcon: Result := GetSmallIconItemRect(AIndex);
    lvsIcon:      Result := GetIconItemRect(AIndex);
  else
    Result := Rect(0, 0, 0, 0);
  end;
end;

function TCssListView.GetItemCellRect(AIndex, AColumn: Integer): TRect;
var
  R: TRect;
  L, W: Integer;
begin
  R := GetItemRect(AIndex);

  if FViewStyle <> lvsReport then
  begin
    if AColumn = 0 then
      Exit(R)
    else
      Exit(Rect(0, 0, 0, 0));
  end;

  if FColumns.Count = 0 then
  begin
    if AColumn = 0 then
      Exit(R)
    else
      Exit(Rect(0, 0, 0, 0));
  end;

  if (AColumn < 0) or (AColumn >= FColumns.Count) then
    Exit(Rect(0, 0, 0, 0));

  W := GetColumnWidth(AColumn);

  if W <= 0 then
    Exit(Rect(0, 0, 0, 0));

  L := GetViewRect.Left - FLeftOffset + GetColumnLeft(AColumn);

  Result := Rect(L, R.Top, L + W, R.Bottom);
end;

function TCssListView.GetItemTextRect(AIndex, AColumn: Integer): TRect;
var
  R: TRect;
  P: Integer;
  Item: TCssListItem;
  SZ: TSize;
begin
  R := GetItemCellRect(AIndex, AColumn);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit(Rect(0, 0, 0, 0));

  P := GetEffectiveItemPadding;

  Inc(R.Left, P);
  Dec(R.Right, P);

  if AColumn = 0 then
  begin
    Item := ItemFromIndex(AIndex);

    if Assigned(Item) then
      Inc(R.Left, Item.Indent);

    if FCheckboxes then
      Inc(R.Left, GetCheckBoxSize + P);

    if FShowImages and Assigned(FStateImages) and Assigned(Item) and
       (Item.StateIndex >= 0) then
    begin
      SZ := GetStateImageSize;
      Inc(R.Left, SZ.cx + P);
    end;

    if FShowImages and Assigned(FSmallImages) and Assigned(Item) and
       (Item.ImageIndex >= 0) then
    begin
      if FViewStyle = lvsReport then
      begin
        SZ := GetSmallImageSize;
        Inc(R.Left, SZ.cx + P);
      end;
    end;

    if (FViewStyle = lvsList) or (FViewStyle = lvsSmallIcon) then
    begin
      if FShowImages and Assigned(FSmallImages) and Assigned(Item) and
         (Item.ImageIndex >= 0) then
      begin
        SZ := GetSmallImageSize;
        Inc(R.Left, SZ.cx + P);
      end;
    end;
  end;

  if R.Right < R.Left then
    R.Right := R.Left;

  Result := R;
end;

function TCssListView.GetCheckBoxSize: Integer;
var
  Measured, MaxSize: Integer;
begin
  Result := ScalePx(13);

  if Assigned(FCheckBoxNormal) then
  begin
    Measured := ScalePx(16);

    if HandleAllocated then
      Measured := FCheckBoxNormal.MeasureBoxSize(Canvas);

    MaxSize := GetEffectiveItemHeight - ScalePx(4);

    if MaxSize > ScalePx(25) then
      MaxSize := ScalePx(25);

    if MaxSize < ScalePx(9) then
      MaxSize := ScalePx(9);

    Result := CssMin(Measured, MaxSize);
  end
  else
  begin
    Result := CssMin(ScalePx(13), GetEffectiveItemHeight - ScalePx(4));
  end;

  if Result < ScalePx(9) then
    Result := ScalePx(9);
end;

function TCssListView.GetCheckBoxRect(AIndex, AColumn: Integer): TRect;
var
  R: TRect;
  SZ, X, Y, P: Integer;
  Item: TCssListItem;
begin
  Result := Rect(0, 0, 0, 0);

  if not FCheckboxes then
    Exit;

  if (FViewStyle = lvsReport) and (AColumn <> 0) then
    Exit;

  R := GetItemCellRect(AIndex, AColumn);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  SZ := GetCheckBoxSize;
  P := GetEffectiveItemPadding;

  Item := ItemFromIndex(AIndex);

  X := R.Left + P;

  if Assigned(Item) then
    Inc(X, Item.Indent);

  if (FViewStyle = lvsIcon) then
  begin
    X := R.Left + P;
    Y := R.Top + P;
  end
  else
    Y := R.Top + (R.Height - SZ) div 2;

  Result := Rect(X, Y, X + SZ, Y + SZ);
end;

function TCssListView.GetSmallImageSize: TSize;
var
  IL: TCssSvgImgList;
begin
  IL := FSmallImages;

  Result.cx := FSmallImageWidth;
  Result.cy := FSmallImageHeight;

  if Result.cx <= 0 then
  begin
    if Assigned(IL) and (IL.Width > 0) then
      Result.cx := IL.Width
    else
      Result.cx := ScalePx(16);
  end;

  if Result.cy <= 0 then
  begin
    if Assigned(IL) and (IL.Height > 0) then
      Result.cy := IL.Height
    else
      Result.cy := ScalePx(16);
  end;
end;

function TCssListView.GetLargeImageSize: TSize;
var
  IL: TCssSvgImgList;
begin
  if Assigned(FLargeImages) then
    IL := FLargeImages
  else
    IL := FSmallImages;

  Result.cx := FLargeImageWidth;
  Result.cy := FLargeImageHeight;

  if Result.cx <= 0 then
  begin
    if Assigned(IL) and (IL.Width > 0) then
      Result.cx := IL.Width
    else
      Result.cx := ScalePx(32);
  end;

  if Result.cy <= 0 then
  begin
    if Assigned(IL) and (IL.Height > 0) then
      Result.cy := IL.Height
    else
      Result.cy := ScalePx(32);
  end;
end;

function TCssListView.GetStateImageSize: TSize;
var
  IL: TCssSvgImgList;
begin
  IL := FStateImages;

  Result.cx := ScalePx(16);
  Result.cy := ScalePx(16);

  if Assigned(IL) then
  begin
    if IL.Width > 0 then
      Result.cx := IL.Width;

    if IL.Height > 0 then
      Result.cy := IL.Height;
  end;
end;

function TCssListView.GetItemIndexAt(X, Y: Integer): Integer;
var
  R: TRect;
  Row, Col, Rows, Cols, CellW, CellH, Idx: Integer;
begin
  Result := -1;

  R := GetViewRect;

  if not PtInRect(R, Point(X, Y)) then
    Exit;

  case FViewStyle of
    lvsReport:
      begin
        Row := (Y - R.Top) div CssMax(1, GetRowStep) + FTopIndex;

        if (Row < 0) or (Row >= FItems.Count) then
          Exit;

        Idx := Row;
      end;

    lvsList:
      begin
        CellW := GetColumnWidth(0);

        if CellW <= 0 then
          CellW := ScalePx(160);

        CellW := CssMax(CellW, ScalePx(48));
        CellH := CssMax(1, GetListItemStep);
        Rows := CssMax(1, R.Height div CellH);

        if X < R.Left - FLeftOffset then
          Exit;

        Col := (X - (R.Left - FLeftOffset)) div CellW;
        Row := (Y - R.Top) div CellH;

        if (Row < 0) or (Row >= Rows) then
          Exit;

        Idx := Col * Rows + Row;
      end;

    lvsSmallIcon:
      begin
        CellW := GetColumnWidth(0);

        if CellW <= 0 then
          CellW := ScalePx(160);

        CellW := CssMax(CellW, ScalePx(64));
        CellH := CssMax(1, GetListItemStep);
        Cols := CssMax(1, R.Width div CellW);

        if (Y < R.Top - FTopOffset) then
          Exit;

        Row := (Y - (R.Top - FTopOffset)) div CellH;
        Col := (X - (R.Left - FLeftOffset)) div CellW;

        Idx := Row * Cols + Col;
      end;

    lvsIcon:
      begin
        CellW := CssMax(ScalePx(76), GetLargeImageSize.cx + ScalePx(28));

        if GetColumnWidth(0) > 0 then
          CellW := CssMax(CellW, GetColumnWidth(0));

        CellH := CssMax(1, GetIconRowStep);
        Cols := CssMax(1, R.Width div CellW);

        if (Y < R.Top - FTopOffset) then
          Exit;

        Row := (Y - (R.Top - FTopOffset)) div CellH;
        Col := (X - (R.Left - FLeftOffset)) div CellW;

        Idx := Row * Cols + Col;
      end;
  else
    Idx := -1;
  end;

  if (Idx >= 0) and (Idx < FItems.Count) then
    Result := Idx;
end;

function TCssListView.GetItemAt(X, Y: Integer): TCssListItem;
begin
  Result := ItemFromIndex(GetItemIndexAt(X, Y));
end;

function TCssListView.GetSubItemAt(X, Y: Integer): Integer;
var
  Idx: Integer;
begin
  Result := -1;

  if FViewStyle <> lvsReport then
    Exit;

  Idx := GetItemIndexAt(X, Y);

  if Idx < 0 then
    Exit;

  if FColumns.Count = 0 then
    Exit(0);

  Result := GetColumnAt(X);
end;

function TCssListView.ItemRect(AIndex: Integer): TRect;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := GetItemRect(AIndex);
end;

function TCssListView.SubItemRect(AIndex, ASubItem: Integer): TRect;
begin
  Result := GetItemCellRect(AIndex, ASubItem);
end;

procedure TCssListView.UpdateScrollBars;
var
  CR, BaseR: TRect;
  HeaderH, SB, ViewW, ViewH: Integer;
  TotalW, TotalH: Integer;
  NeedV, NeedH: Boolean;
  Rows, Cols, CellW, CellH: Integer;
  VBarSize: Integer;
  NewMax: Integer;
begin
  if (FVScroll = nil) or (FHScroll = nil) then
    Exit;

  if csDestroying in ComponentState then
    Exit;

  CR := GetContentRect;
  HeaderH := GetHeaderRect.Height;

  BaseR := CR;
  Inc(BaseR.Top, HeaderH);

  if BaseR.Top > BaseR.Bottom then
    BaseR.Top := BaseR.Bottom;

  SB := GetEffectiveScrollBarSize;

  ViewW := CssMax(0, BaseR.Right - BaseR.Left);
  ViewH := CssMax(0, BaseR.Bottom - BaseR.Top);

  NeedV := False;
  NeedH := False;
  TotalW := ViewW;
  TotalH := ViewH;

  case FViewStyle of
    lvsReport:
      begin
        TotalW := GetTotalColumnsWidth;

        if TotalW <= 0 then
          TotalW := ViewW;

        TotalH := FItems.Count * GetRowStep;

        NeedV := TotalH > ViewH;

        if NeedV then
          ViewW := CssMax(0, ViewW - SB);

        NeedH := TotalW > ViewW;

        if NeedH then
        begin
          ViewH := CssMax(0, ViewH - SB);
          NeedV := TotalH > ViewH;
        end;
      end;

    lvsList:
      begin
        CellW := GetColumnWidth(0);

        if CellW <= 0 then
          CellW := ScalePx(160);

        CellW := CssMax(CellW, ScalePx(48));
        CellH := CssMax(1, GetListItemStep);

        Rows := CssMax(1, ViewH div CellH);
        Cols := (FItems.Count + Rows - 1) div Rows;

        if Cols < 1 then
          Cols := 1;

        TotalW := Cols * CellW;
        TotalH := ViewH;

        NeedH := TotalW > ViewW;

        if NeedH then
        begin
          ViewH := CssMax(0, ViewH - SB);
          Rows := CssMax(1, ViewH div CellH);
          Cols := (FItems.Count + Rows - 1) div Rows;

          if Cols < 1 then
            Cols := 1;

          TotalW := Cols * CellW;
          NeedH := TotalW > ViewW;
        end;
      end;

    lvsSmallIcon, lvsIcon:
      begin
        if FViewStyle = lvsIcon then
        begin
          CellW := CssMax(ScalePx(76), GetLargeImageSize.cx + ScalePx(28));

          if GetColumnWidth(0) > 0 then
            CellW := CssMax(CellW, GetColumnWidth(0));

          CellH := CssMax(1, GetIconRowStep);
        end
        else
        begin
          CellW := GetColumnWidth(0);

          if CellW <= 0 then
            CellW := ScalePx(160);

          CellW := CssMax(CellW, ScalePx(64));
          CellH := CssMax(1, GetListItemStep);
        end;

        Cols := CssMax(1, ViewW div CellW);
        Rows := (FItems.Count + Cols - 1) div Cols;
        TotalH := Rows * CellH;
        TotalW := ViewW;

        NeedV := TotalH > ViewH;

        if NeedV then
        begin
          ViewW := CssMax(0, ViewW - SB);
          Cols := CssMax(1, ViewW div CellW);
          Rows := (FItems.Count + Cols - 1) div Cols;
          TotalH := Rows * CellH;
          NeedV := TotalH > ViewH;
        end;
      end;
  end;

  if NeedV then
  begin
    if FViewStyle = lvsReport then
    begin
      if FTopIndex < 0 then
        FTopIndex := 0;

      if FTopIndex > CssMax(0, FItems.Count - 1) then
        FTopIndex := CssMax(0, FItems.Count - 1);
    end
    else if FTopOffset < 0 then
      FTopOffset := 0
    else if FTopOffset > CssMax(0, TotalH - ViewH) then
      FTopOffset := CssMax(0, TotalH - ViewH);
  end
  else
  begin
    if FViewStyle = lvsReport then
      FTopIndex := 0
    else
      FTopOffset := 0;
  end;

  if NeedH then
  begin
    if FLeftOffset < 0 then
      FLeftOffset := 0;

    if FLeftOffset > CssMax(0, TotalW - ViewW) then
      FLeftOffset := CssMax(0, TotalW - ViewW);
  end
  else
    FLeftOffset := 0;

  FScrollUpdating := True;
  try
    FVScroll.Visible := NeedV;
    FHScroll.Visible := NeedH;

    if NeedV then
    begin
      VBarSize := 0;

      if NeedH then
        VBarSize := SB;

      FVScrollRect := Rect(
        CR.Right - SB,
        BaseR.Top,
        CR.Right,
        BaseR.Bottom - VBarSize
      );

      FVScroll.SetBounds(0, 0, SB, CssMax(1, FVScrollRect.Height));

      if FViewStyle = lvsReport then
      begin
        FVScroll.Min := 0;
        FVScroll.Max := CssMax(0, FItems.Count - 1);
        FVScroll.PageSize := CssMax(0, GetPageRows);
        FVScroll.SmallChange := 1;
        FVScroll.LargeChange := CssMax(1, GetPageRows);
        FVScroll.Position := FTopIndex;
      end
      else
      begin
        NewMax := CssMax(0, TotalH - ViewH);
        FVScroll.Min := 0;
        FVScroll.Max := NewMax;
        FVScroll.PageSize := ViewH;
        FVScroll.SmallChange := CssMax(1, GetRowStep);
        FVScroll.LargeChange := CssMax(1, ViewH);
        FVScroll.Position := FTopOffset;
      end;
    end
    else
    begin
      FVScrollRect := Rect(0, 0, 0, 0);
      FVScroll.SetBounds(0, 0, 0, 0);
      FVScroll.Min := 0;
      FVScroll.Max := 0;
      FVScroll.Position := 0;
    end;

    if NeedH then
    begin
      VBarSize := 0;

      if NeedV then
        VBarSize := SB;

      FHScrollRect := Rect(
        CR.Left,
        BaseR.Bottom - SB,
        CR.Right - VBarSize,
        BaseR.Bottom
      );

      FHScroll.SetBounds(0, 0, CssMax(1, FHScrollRect.Width), SB);
      FHScroll.Min := 0;
      FHScroll.Max := CssMax(0, TotalW - ViewW);
      FHScroll.PageSize := ViewW;
      FHScroll.SmallChange := ScalePx(16);
      FHScroll.LargeChange := CssMax(1, ViewW);
      FHScroll.Position := FLeftOffset;
    end
    else
    begin
      FHScrollRect := Rect(0, 0, 0, 0);
      FHScroll.SetBounds(0, 0, 0, 0);
      FHScroll.Min := 0;
      FHScroll.Max := 0;
      FHScroll.Position := 0;
    end;
  finally
    FScrollUpdating := False;
  end;
end;

procedure TCssListView.SetTopIndex(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if AValue > CssMax(0, FItems.Count - 1) then
    AValue := CssMax(0, FItems.Count - 1);

  if FTopIndex = AValue then
    Exit;

  FTopIndex := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetTopOffset(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FTopOffset = AValue then
    Exit;

  FTopOffset := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SetLeftOffset(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FLeftOffset = AValue then
    Exit;

  FLeftOffset := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.DoVScroll(Sender: TObject);
begin
  if FScrollUpdating then
    Exit;

  if FViewStyle = lvsReport then
    SetTopIndex(FVScroll.Position)
  else
    SetTopOffset(FVScroll.Position);
end;

procedure TCssListView.DoHScroll(Sender: TObject);
begin
  if FScrollUpdating then
    Exit;

  SetLeftOffset(FHScroll.Position);
end;

function TCssListView.ScrollBarAt(X, Y: Integer): TCssScrollBar;
begin
  Result := nil;

  if Assigned(FVScroll) and FVScroll.Visible and
     (FVScrollRect.Right > FVScrollRect.Left) and
     (FVScrollRect.Bottom > FVScrollRect.Top) and
     PtInRect(FVScrollRect, Point(X, Y)) then
  begin
    Result := FVScroll;
    Exit;
  end;

  if Assigned(FHScroll) and FHScroll.Visible and
     (FHScrollRect.Right > FHScrollRect.Left) and
     (FHScrollRect.Bottom > FHScrollRect.Top) and
     PtInRect(FHScrollRect, Point(X, Y)) then
    Result := FHScroll;
end;

procedure TCssListView.ScrollBarMouseDown(X, Y: Integer; out AHandled: Boolean);
var
  SB: TCssScrollBar;
  P: TPoint;
begin
  AHandled := False;
  SB := ScrollBarAt(X, Y);

  if SB = nil then
    Exit;

  AHandled := True;

  if SB = FVScroll then
    P := Point(X - FVScrollRect.Left, Y - FVScrollRect.Top)
  else
    P := Point(X - FHScrollRect.Left, Y - FHScrollRect.Top);

  if SB.ExternalMouseDown(mbLeft, [], P.X, P.Y) then
  begin
    FScrollCapture := SB;
    MouseCapture := True;
    Invalidate;
  end;
end;

procedure TCssListView.ScrollBarMouseMove(X, Y: Integer; out AHandled: Boolean);
var
  P: TPoint;
begin
  AHandled := False;

  if FScrollCapture = nil then
    Exit;

  AHandled := True;

  if FScrollCapture = FVScroll then
    P := Point(X - FVScrollRect.Left, Y - FVScrollRect.Top)
  else
    P := Point(X - FHScrollRect.Left, Y - FHScrollRect.Top);

  if FScrollCapture.ExternalMouseMove([], P.X, P.Y) then
    Invalidate;
end;

procedure TCssListView.ScrollBarMouseUp;
begin
  if FScrollCapture = nil then
    Exit;

  FScrollCapture.ExternalMouseUp;
  FScrollCapture := nil;
  MouseCapture := False;
  Invalidate;
end;

procedure TCssListView.DrawInternalScrollBars;
begin
  if Assigned(FVScroll) and FVScroll.Visible and
     (FVScrollRect.Right > FVScrollRect.Left) and
     (FVScrollRect.Bottom > FVScrollRect.Top) then
    FVScroll.DrawToCanvas(Canvas, FVScrollRect);

  if Assigned(FHScroll) and FHScroll.Visible and
     (FHScrollRect.Right > FHScrollRect.Left) and
     (FHScrollRect.Bottom > FHScrollRect.Top) then
    FHScroll.DrawToCanvas(Canvas, FHScrollRect);
end;

procedure TCssListView.ScrollIntoView(AItem: TCssListItem);
var
  Idx: Integer;
  R, VR: TRect;
begin
  Idx := IndexOfItem(AItem);

  if Idx < 0 then
    Exit;

  case FViewStyle of
    lvsReport:
      begin
        if Idx < FTopIndex then
          FTopIndex := Idx
        else if Idx >= FTopIndex + GetPageRows then
          FTopIndex := Idx - GetPageRows + 1;

        if FTopIndex < 0 then
          FTopIndex := 0;
      end;

    lvsList:
      begin
        R := GetListItemRect(Idx);
        VR := GetViewRect;

        if R.Left < VR.Left then
          FLeftOffset := CssMax(0, FLeftOffset - (VR.Left - R.Left))
        else if R.Right > VR.Right then
          FLeftOffset := FLeftOffset + (R.Right - VR.Right);
      end;

    lvsSmallIcon, lvsIcon:
      begin
        R := GetItemRect(Idx);
        VR := GetViewRect;

        if R.Top < VR.Top then
          FTopOffset := CssMax(0, FTopOffset - (VR.Top - R.Top))
        else if R.Bottom > VR.Bottom then
          FTopOffset := FTopOffset + (R.Bottom - VR.Bottom);
      end;
  end;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.ScrollIntoView(AIndex: Integer);
begin
  ScrollIntoView(ItemFromIndex(AIndex));
end;

procedure TCssListView.Paint;
var
  ClipDC: Integer;
begin
  // Draw the background without the inherited border. The border is drawn
  // once at the end, after the content, so selected rows cannot leave a
  // second blended stroke on the rounded corners.
  DrawBackgroundOnly(Canvas, ClientRect);

  if not Assigned(FItems) then
    Exit;

  UpdateCanvasFont;

  ClipDC := BeginContentClip;
  try
    if GetHeaderRect.Height > 0 then
      DrawHeader;

    DrawItems;
    DrawInternalScrollBars;

    if FRubberBanding then
      DrawRubberBand;
  finally
    PopClipRect(ClipDC);
  end;

  RestoreRoundedBorder;

  if Assigned(OnPaint) then
    OnPaint(Self);
end;

procedure TCssListView.ApplyTextStyle(var AStyle: TTextStyle;
  AAlign: TAlignment; AVertical: Boolean);
begin
  AStyle := Canvas.TextStyle;
  AStyle.Alignment := AAlign;

  if AVertical then
    AStyle.Layout := tlCenter
  else
    AStyle.Layout := tlTop;

  AStyle.SingleLine := True;
  AStyle.WordBreak := False;
  AStyle.EndEllipsis := True;
  AStyle.Clipping := True;
end;

procedure TCssListView.DrawHeader;
var
  R, CellR: TRect;
  I, L, W: Integer;
  SavedDC: Integer;
begin
  R := GetHeaderRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := GetHeaderBackground;
  Canvas.FillRect(R);

  SavedDC := PushClipRect(R);
  try
    if FColumns.Count = 0 then
    begin
      Canvas.Pen.Color := GetLineColor;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(R.Left, R.Bottom - 1);
      Canvas.LineTo(R.Right, R.Bottom - 1);
      Exit;
    end;

    L := GetViewRect.Left - FLeftOffset;

    for I := 0 to FColumns.Count - 1 do
    begin
      W := GetColumnWidth(I);

      if W <= 0 then
        Continue;

      CellR := Rect(L, R.Top, L + W, R.Bottom);
      Inc(L, W);

      if CellR.Right <= R.Left then
        Continue;

      if CellR.Left >= R.Right then
        Break;

      if (CellR.Left < R.Left) or (CellR.Right > R.Right) then
      begin
        if CellR.Left < R.Left then
          CellR.Left := R.Left;

        if CellR.Right > R.Right then
          CellR.Right := R.Right;
      end;

      DrawHeaderCell(I, CellR);
    end;

    Canvas.Pen.Color := GetLineColor;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(R.Left, R.Bottom - 1);
    Canvas.LineTo(R.Right, R.Bottom - 1);
  finally
    PopClipRect(SavedDC);
  end;
end;

procedure TCssListView.DrawHeaderCell(AIndex: Integer; const ARect: TRect);
var
  Col: TCssListColumn;
  TR: TRect;
  TextR: TRect;
  S: string;
  ImgSize: TSize;
  ArrowR: TRect;
  Bmp: TBitmap;
  Tint: TColor;
  Bg: TColor;
begin
  if (AIndex < 0) or (AIndex >= FColumns.Count) then
    Exit;

  Col := FColumns[AIndex];
  Bg := GetHeaderBackground;

  if FHotTrack and (FHotHeaderColumn = AIndex) then
  begin
    Bg := GetHeaderHoverBackground;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Bg;
    Canvas.FillRect(ARect);
  end;

  if (AIndex < FColumns.Count - 1) then
  begin
    Canvas.Pen.Color := GetLineColor;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(ARect.Right - 1, ARect.Top + ScalePx(4));
    Canvas.LineTo(ARect.Right - 1, ARect.Bottom - ScalePx(4));
  end;

  UpdateCanvasFont;
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := GetHeaderTextColor;

  TextR := ARect;
  Inc(TextR.Left, GetEffectiveHeaderPadding);
  Dec(TextR.Right, GetEffectiveHeaderPadding);

  if (FSortType <> lstNone) and (FSortColumn = AIndex) and
     (FSortDirection <> lsdNone) then
  begin
    Dec(TextR.Right, ScalePx(14));
    ArrowR := Rect(
      ARect.Right - ScalePx(16),
      ARect.Top + (ARect.Height - ScalePx(8)) div 2,
      ARect.Right - ScalePx(6),
      ARect.Top + (ARect.Height + ScalePx(8)) div 2
    );
    DrawSortArrow(ArrowR, FSortDirection);
  end;

  Tint := GetHeaderTextColor;

  if (Col.ImageIndex >= 0) and Assigned(FSmallImages) and
     (Col.ImageIndex < FSmallImages.Count) then
  begin
    ImgSize := GetSmallImageSize;

    if ImgSize.cx > ScalePx(20) then
      ImgSize.cx := ScalePx(20);

    if ImgSize.cy > ScalePx(20) then
      ImgSize.cy := ScalePx(20);

    Bmp := FSmallImages.GetBitmap(
      Col.ImageIndex,
      ImgSize.cx,
      ImgSize.cy,
      Tint,
      GetEffectiveImageVariant
    );

    try
      DrawSvgBitmapWithAlpha(
        Canvas,
        TextR.Left,
        ARect.Top + (ARect.Height - ImgSize.cy) div 2,
        Bmp
      );
    finally
      Bmp.Free;
    end;

    Inc(TextR.Left, ImgSize.cx + ScalePx(4));
  end;

  S := Col.Caption;

  if TextR.Right > TextR.Left then
    DrawHeaderText(TextR, S, Col.Alignment);
end;

procedure TCssListView.DrawHeaderText(const ARect: TRect;
  const AText: string; AAlign: TAlignment);
var
  TS: TTextStyle;
begin
  if HtmlMode then
    DrawHtmlTextWithAlign(Canvas, ARect, AText,
      ListAlignmentToCss(AAlign), cvaMiddle, Canvas.Font.Color)
  else
  begin
    ApplyTextStyle(TS, AAlign);
    Canvas.TextRect(ARect, ARect.Left, ARect.Top, AText, TS);
  end;
end;

procedure TCssListView.DrawSortArrow(const ARect: TRect;
  ADirection: TCssListSortDirection);
var
  CX, CY, W, H: Integer;
  P1, P2, P3: TPoint;
  Bg: TColor;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  CX := (ARect.Left + ARect.Right) div 2;
  CY := (ARect.Top + ARect.Bottom) div 2;
  W := CssMin(ARect.Width, ScalePx(7));
  H := CssMin(ARect.Height, ScalePx(5));

  if W < 2 then
    W := 2;

  if H < 2 then
    H := 2;

  Bg := GetHeaderBackground;

  if ADirection = lsdDescending then
  begin
    P1 := Point(CX - W div 2, CY - H div 2);
    P2 := Point(CX + W div 2, CY - H div 2);
    P3 := Point(CX, CY + H div 2);
  end
  else
  begin
    P1 := Point(CX - W div 2, CY + H div 2);
    P2 := Point(CX + W div 2, CY + H div 2);
    P3 := Point(CX, CY - H div 2);
  end;

  DrawAntiAliasedTriangle(Canvas, P1, P2, P3, GetSortMarkerColor, Bg);
end;

procedure TCssListView.DrawItems;
var
  R: TRect;
  SavedDC: Integer;
  First, Last, I: Integer;
  Rows, Cols, CellW, CellH, FirstRow, LastRow: Integer;
begin
  R := GetViewRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  SavedDC := PushClipRect(R);
  try
    if FItems.Count = 0 then
    begin
      DrawPlaceholder(R);
      Exit;
    end;

    case FViewStyle of
      lvsReport:
        begin
          First := FTopIndex;
          Last := CssMin(FItems.Count - 1, FTopIndex + GetPageRows);

          for I := First to Last do
            DrawReportRow(I);

          if FGridLines then
            DrawColumnGrid;
        end;

      lvsList:
        begin
          CellW := GetColumnWidth(0);

          if CellW <= 0 then
            CellW := ScalePx(160);

          CellW := CssMax(CellW, ScalePx(48));
          CellH := CssMax(1, GetListItemStep);
          Rows := CssMax(1, R.Height div CellH);

          First := CssMax(0, (FLeftOffset div CellW) * Rows);
          Last := CssMin(
            FItems.Count - 1,
            ((FLeftOffset + R.Width) div CellW + 1) * Rows - 1
          );

          for I := First to Last do
            DrawListRow(I);
        end;

      lvsSmallIcon:
        begin
          CellW := GetColumnWidth(0);

          if CellW <= 0 then
            CellW := ScalePx(160);

          CellW := CssMax(CellW, ScalePx(64));
          CellH := CssMax(1, GetListItemStep);
          Cols := CssMax(1, R.Width div CellW);

          FirstRow := CssMax(0, FTopOffset div CellH);
          LastRow := (FTopOffset + R.Height) div CellH;

          First := FirstRow * Cols;
          Last := CssMin(FItems.Count - 1, (LastRow + 1) * Cols - 1);

          for I := First to Last do
            DrawSmallIconRow(I);
        end;

      lvsIcon:
        begin
          CellW := CssMax(ScalePx(76), GetLargeImageSize.cx + ScalePx(28));

          if GetColumnWidth(0) > 0 then
            CellW := CssMax(CellW, GetColumnWidth(0));

          CellH := CssMax(1, GetIconRowStep);
          Cols := CssMax(1, R.Width div CellW);

          FirstRow := CssMax(0, FTopOffset div CellH);
          LastRow := (FTopOffset + R.Height) div CellH;

          First := FirstRow * Cols;
          Last := CssMin(FItems.Count - 1, (LastRow + 1) * Cols - 1);

          for I := First to Last do
            DrawIconRow(I);
        end;
    end;
  finally
    PopClipRect(SavedDC);
  end;
end;

procedure TCssListView.DrawColumnGrid;
var
  R: TRect;
  I, L, W: Integer;
begin
  if not FGridLines or (FColumns.Count = 0) then
    Exit;

  R := GetViewRect;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := GetGridColor;

  L := R.Left - FLeftOffset;

  for I := 0 to FColumns.Count - 1 do
  begin
    W := GetColumnWidth(I);

    if W <= 0 then
      Continue;

    Inc(L, W);

    if (L > R.Left) and (L < R.Right) then
    begin
      Canvas.MoveTo(L - 1, R.Top);
      Canvas.LineTo(L - 1, R.Bottom);
    end;
  end;
end;

procedure TCssListView.DrawPlaceholder(const ARect: TRect);
var
  TS: TTextStyle;
  S: string;
begin
  if FPlaceholder = '' then
    Exit;

  S := FPlaceholder;

  UpdateCanvasFont;
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := GetPlaceholderColor;

  ApplyTextStyle(TS, taCenter);
  TS.Layout := tlCenter;

  Canvas.TextRect(ARect, ARect.Left, ARect.Top, S, TS);
end;

procedure TCssListView.DrawFocusMark(const ARect: TRect;
  ASelectedCell: Boolean);
var
  R: TRect;
  MarkColor: TColor;
begin
  R := ARect;
  Inc(R.Left, 1);
  Inc(R.Top, 1);
  Dec(R.Right, 1);
  Dec(R.Bottom, 1);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  if ASelectedCell then
  begin
    MarkColor := GetItemSelectedTextColor;

    if (MarkColor = clNone) or (MarkColor = clDefault) then
      MarkColor := clWhite;
  end
  else
    MarkColor := GetItemTextColor;

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := MarkColor;

  Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

  Canvas.Pen.Style := psSolid;
end;

procedure TCssListView.DrawRubberBand;
var
  R: TRect;
begin
  R := FRubberRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := GetFocusColor;

  Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

  Canvas.Pen.Style := psSolid;
end;

procedure TCssListView.DrawReportRow(AIndex: Integer);
var
  Item: TCssListItem;
  RowR, ViewR, CellR: TRect;
  Col: Integer;
  IsSel, IsHov, DefaultDraw: Boolean;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  Item := FItems[AIndex];
  RowR := GetReportItemRect(AIndex);
  ViewR := GetViewRect;

  if (RowR.Bottom <= ViewR.Top) or (RowR.Top >= ViewR.Bottom) then
    Exit;

  IsSel := IsItemSelected(Item);

  if FHideSelection and (not Focused) then
    IsSel := False;

  IsHov := (FHoverItem = Item);

  DefaultDraw := True;

  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Item, RowR, AIndex, DefaultDraw);

  if DefaultDraw then
  begin
    if FColumns.Count = 0 then
      DrawItemCell(AIndex, 0, RowR, IsSel, IsHov)
    else
    begin
      for Col := 0 to FColumns.Count - 1 do
      begin
        CellR := GetItemCellRect(AIndex, Col);

        if (CellR.Right <= CellR.Left) or (CellR.Bottom <= CellR.Top) then
          Continue;

        if (CellR.Right <= ViewR.Left) or (CellR.Left >= ViewR.Right) then
          Continue;

        DrawItemCell(AIndex, Col, CellR, IsSel, IsHov);
      end;
    end;

    if FGridLines then
    begin
      Canvas.Pen.Style := psSolid;
      Canvas.Pen.Width := 1;
      Canvas.Pen.Color := GetGridColor;
      Canvas.MoveTo(ViewR.Left, RowR.Bottom - 1);
      Canvas.LineTo(ViewR.Right, RowR.Bottom - 1);
    end;
  end;

  if FShowItemFocusRect and Focused and (FFocusedItem = Item) and ShowFocusRect then
  begin
    if FColumns.Count > 0 then
      CellR := GetItemCellRect(AIndex, GetEffectiveFocusedColumn)
    else
      CellR := RowR;

    DrawFocusMark(CellR,
      IsSel and (FRowSelect or (FColumns.Count = 0) or
      (GetEffectiveFocusedColumn = 0)));
  end;
end;

procedure TCssListView.DrawListRow(AIndex: Integer);
var
  Item: TCssListItem;
  R, ViewR: TRect;
  IsSel, IsHov, DefaultDraw: Boolean;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  Item := FItems[AIndex];
  R := GetListItemRect(AIndex);
  ViewR := GetViewRect;

  if (R.Bottom <= ViewR.Top) or (R.Top >= ViewR.Bottom) or
     (R.Right <= ViewR.Left) or (R.Left >= ViewR.Right) then
    Exit;

  IsSel := IsItemSelected(Item);

  if FHideSelection and (not Focused) then
    IsSel := False;

  IsHov := (FHoverItem = Item);
  DefaultDraw := True;

  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Item, R, AIndex, DefaultDraw);

  if DefaultDraw then
    DrawItemCell(AIndex, 0, R, IsSel, IsHov);

  if FShowItemFocusRect and Focused and (FFocusedItem = Item) and ShowFocusRect then
    DrawFocusMark(R, IsSel);
end;

procedure TCssListView.DrawSmallIconRow(AIndex: Integer);
var
  Item: TCssListItem;
  R, ViewR: TRect;
  IsSel, IsHov, DefaultDraw: Boolean;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  Item := FItems[AIndex];
  R := GetSmallIconItemRect(AIndex);
  ViewR := GetViewRect;

  if (R.Bottom <= ViewR.Top) or (R.Top >= ViewR.Bottom) or
     (R.Right <= ViewR.Left) or (R.Left >= ViewR.Right) then
    Exit;

  IsSel := IsItemSelected(Item);

  if FHideSelection and (not Focused) then
    IsSel := False;

  IsHov := (FHoverItem = Item);
  DefaultDraw := True;

  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Item, R, AIndex, DefaultDraw);

  if DefaultDraw then
    DrawItemCell(AIndex, 0, R, IsSel, IsHov);

  if FShowItemFocusRect and Focused and (FFocusedItem = Item) and ShowFocusRect then
    DrawFocusMark(R, IsSel);
end;

procedure TCssListView.DrawIconRow(AIndex: Integer);
var
  Item: TCssListItem;
  R, ViewR, TextR, ImgR, CheckR: TRect;
  IsSel, IsHov, DefaultDraw: Boolean;
  SZ: TSize;
  P, TextTop: Integer;
  Bmp: TBitmap;
  Tint: TColor;
  TS: TTextStyle;
  IL: TCssSvgImgList;
  Bg: TColor;
  CheckSize: Integer;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  Item := FItems[AIndex];
  R := GetIconItemRect(AIndex);
  ViewR := GetViewRect;

  if (R.Bottom <= ViewR.Top) or (R.Top >= ViewR.Bottom) or
     (R.Right <= ViewR.Left) or (R.Left >= ViewR.Right) then
    Exit;

  IsSel := IsItemSelected(Item);

  if FHideSelection and (not Focused) then
    IsSel := False;

  IsHov := (FHoverItem = Item);
  DefaultDraw := True;

  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Item, R, AIndex, DefaultDraw);

  if not DefaultDraw then
  begin
    if Focused and (FFocusedItem = Item) and ShowFocusRect then
      DrawFocusMark(R, IsSel);
    Exit;
  end;

  Bg := GetItemBackground;

  if IsSel then
    Bg := GetItemSelectedBackground
  else if FHotTrack and IsHov then
    Bg := GetItemHoverBackground;

  if IsSel or (FHotTrack and IsHov) then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Bg;
    Canvas.FillRect(R);
  end;

  P := GetEffectiveItemPadding;

  if FCheckboxes then
  begin
    CheckR := GetCheckBoxRect(AIndex, 0);
    DrawCheckBox(AIndex, 0, CheckR, IsSel, IsHov);
    CheckSize := CheckR.Bottom - CheckR.Top + P;
  end
  else
  begin
    CheckR := Rect(0, 0, 0, 0);
    CheckSize := 0;
  end;

  if Assigned(FLargeImages) then
    IL := FLargeImages
  else
    IL := FSmallImages;

  TextTop := R.Top + P + CheckSize;

  if FShowImages and Assigned(IL) and (Item.ImageIndex >= 0) and
     (Item.ImageIndex < IL.Count) then
  begin
    SZ := GetLargeImageSize;
    ImgR := Rect(
      R.Left + (R.Width - SZ.cx) div 2,
      TextTop,
      R.Left + (R.Width - SZ.cx) div 2 + SZ.cx,
      TextTop + SZ.cy
    );

    if not Enabled then
      Tint := GetDisabledColor
    else if IsSel then
      Tint := GetItemSelectedTextColor
    else
      Tint := GetItemTextColor;

    Bmp := IL.GetBitmap(
      Item.ImageIndex,
      SZ.cx,
      SZ.cy,
      Tint,
      GetEffectiveImageVariant
    );

    try
      DrawSvgBitmapWithAlpha(Canvas, ImgR.Left, ImgR.Top, Bmp);
    finally
      Bmp.Free;
    end;

    TextTop := ImgR.Bottom + ScalePx(4);
  end;

  TextR := Rect(R.Left + P, TextTop, R.Right - P, R.Bottom - P);

  if TextR.Bottom <= TextR.Top then
    TextR.Bottom := TextR.Top + ScalePx(16);

  UpdateCanvasFont;
  Canvas.Brush.Style := bsClear;

  if not Enabled then
    Canvas.Font.Color := GetDisabledColor
  else if IsSel then
    Canvas.Font.Color := GetItemSelectedTextColor
  else if FHotTrack and IsHov then
    Canvas.Font.Color := GetItemHoverTextColor
  else
    Canvas.Font.Color := GetItemTextColor;

  TS := Canvas.TextStyle;
  TS.Alignment := taCenter;
  TS.Layout := tlTop;
  TS.SingleLine := False;
  TS.WordBreak := True;
  TS.EndEllipsis := True;
  TS.Clipping := True;

  Canvas.TextRect(TextR, TextR.Left, TextR.Top, Item.Caption, TS);

  if FShowItemFocusRect and Focused and (FFocusedItem = Item) and ShowFocusRect then
    DrawFocusMark(R, IsSel);
end;

procedure TCssListView.DrawItemCell(AIndex, AColumn: Integer;
  const ARect: TRect; ASelected, AHovered: Boolean);
var
  IsSelCell, IsHovCell: Boolean;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  IsSelCell := ASelected and
    (FRowSelect or (AColumn = 0) or (FViewStyle <> lvsReport));

  IsHovCell := FHotTrack and AHovered and
    (FRowSelect or (AColumn = 0) or (FViewStyle <> lvsReport));

  Canvas.Brush.Style := bsSolid;

  if IsSelCell then
  begin
    Canvas.Brush.Color := GetItemSelectedBackground;
    Canvas.FillRect(ARect);
  end
  else if IsHovCell then
  begin
    Canvas.Brush.Color := GetItemHoverBackground;
    Canvas.FillRect(ARect);
  end;

  if AColumn = 0 then
  begin
    if FCheckboxes then
      DrawCheckBox(AIndex, AColumn, GetCheckBoxRect(AIndex, AColumn),
        ASelected, AHovered);

    if FShowImages then
    begin
      DrawStateImage(AIndex, AColumn, ARect);
      DrawItemImage(AIndex, AColumn, ARect);
    end;
  end;

  DrawItemText(AIndex, AColumn, ARect, ASelected, AHovered);
end;

procedure TCssListView.DrawCheckBox(AIndex, AColumn: Integer;
  const ARect: TRect; ASelected, AHovered: Boolean);
var
  Helper: TCssCheckBox;
  Item: TCssListItem;
  CheckR: TRect;
  IsChecked, IsHover, IsSelCell: Boolean;
  Bg: TColor;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  Item := ItemFromIndex(AIndex);

  if Item = nil then
    Exit;

  if (FCheckBoxNormal = nil) or (FCheckBoxChecked = nil) or
     (FCheckBoxHover = nil) or (FCheckBoxCheckedHover = nil) then
    UpdateCheckBoxStyle;

  CheckR := ARect;
  IsChecked := Item.Checked;
  IsHover := AHovered and PtInRect(CheckR, FLastMouse);

  if IsChecked then
  begin
    if IsHover then
      Helper := FCheckBoxCheckedHover
    else
      Helper := FCheckBoxChecked;
  end
  else
  begin
    if IsHover then
      Helper := FCheckBoxHover
    else
      Helper := FCheckBoxNormal;
  end;

  if not Assigned(Helper) then
    Exit;

  IsSelCell := ASelected and
    (FRowSelect or (AColumn = 0) or (FViewStyle <> lvsReport));

  if IsSelCell then
    Bg := GetItemSelectedBackground
  else if FHotTrack and AHovered then
    Bg := GetItemHoverBackground
  else
    Bg := GetItemBackground;

  Helper.SetExternalBackgroundColor(Bg);
  try
    Helper.DrawToCanvas(Canvas, CheckR);
  finally
    Helper.SetExternalBackgroundColor(clNone);
  end;
end;

procedure TCssListView.DrawStateImage(AIndex, AColumn: Integer;
  const ARect: TRect);
var
  Item: TCssListItem;
  R: TRect;
  SZ: TSize;
  Base, P: Integer;
  Bmp: TBitmap;
  Tint: TColor;
begin
  if not Assigned(FStateImages) then
    Exit;

  Item := ItemFromIndex(AIndex);

  if Item = nil then
    Exit;

  if (Item.StateIndex < 0) or (Item.StateIndex >= FStateImages.Count) then
    Exit;

  P := GetEffectiveItemPadding;
  SZ := GetStateImageSize;

  Base := ARect.Left + P + Item.Indent;

  if FCheckboxes then
    Inc(Base, GetCheckBoxSize + P);

  R := Rect(
    Base,
    ARect.Top + (ARect.Height - SZ.cy) div 2,
    Base + SZ.cx,
    ARect.Top + (ARect.Height - SZ.cy) div 2 + SZ.cy
  );

  if not Enabled then
    Tint := GetDisabledColor
  else
    Tint := GetItemTextColor;

  Bmp := FStateImages.GetBitmap(
    Item.StateIndex,
    SZ.cx,
    SZ.cy,
    Tint,
    GetEffectiveImageVariant
  );

  try
    DrawSvgBitmapWithAlpha(Canvas, R.Left, R.Top, Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TCssListView.DrawItemImage(AIndex, AColumn: Integer;
  const ARect: TRect);
var
  Item: TCssListItem;
  IL: TCssSvgImgList;
  R: TRect;
  SZ: TSize;
  Base, P, Y: Integer;
  Bmp: TBitmap;
  Tint: TColor;
begin
  if not FShowImages then
    Exit;

  Item := ItemFromIndex(AIndex);

  if Item = nil then
    Exit;

  if (AColumn <> 0) or (Item.ImageIndex < 0) then
    Exit;

  if FViewStyle = lvsIcon then
  begin
    if Assigned(FLargeImages) then
      IL := FLargeImages
    else
      IL := FSmallImages;
  end
  else
    IL := FSmallImages;

  if not Assigned(IL) then
    Exit;

  if (Item.ImageIndex < 0) or (Item.ImageIndex >= IL.Count) then
    Exit;

  P := GetEffectiveItemPadding;

  if FViewStyle = lvsIcon then
    SZ := GetLargeImageSize
  else
    SZ := GetSmallImageSize;

  Base := ARect.Left + P + Item.Indent;

  if FCheckboxes then
    Inc(Base, GetCheckBoxSize + P);

  if Assigned(FStateImages) and (Item.StateIndex >= 0) and
     (Item.StateIndex < FStateImages.Count) then
    Inc(Base, GetStateImageSize.cx + P);

  Y := ARect.Top + (ARect.Height - SZ.cy) div 2;

  R := Rect(Base, Y, Base + SZ.cx, Y + SZ.cy);

  if not Enabled then
    Tint := GetDisabledColor
  else
    Tint := GetItemTextColor;

  Bmp := IL.GetBitmap(
    Item.ImageIndex,
    SZ.cx,
    SZ.cy,
    Tint,
    GetEffectiveImageVariant
  );

  try
    DrawSvgBitmapWithAlpha(Canvas, R.Left, R.Top, Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TCssListView.DrawItemText(AIndex, AColumn: Integer;
  const ARect: TRect; ASelected, AHovered: Boolean);
var
  Item: TCssListItem;
  R: TRect;
  S: string;
  TS: TTextStyle;
  CellAlign: TAlignment;
  IsSelCell, IsHovCell: Boolean;
begin
  Item := ItemFromIndex(AIndex);

  if Item = nil then
    Exit;

  R := GetItemTextRect(AIndex, AColumn);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  if AColumn = 0 then
    S := Item.Caption
  else
    S := Item.GetSubItemText(AColumn - 1);

  if S = '' then
    Exit;

  CellAlign := taLeftJustify;

  if (FColumns.Count > 0) and (AColumn >= 0) and (AColumn < FColumns.Count) then
    CellAlign := FColumns[AColumn].Alignment;

  IsSelCell := ASelected and
    (FRowSelect or (AColumn = 0) or (FViewStyle <> lvsReport));

  IsHovCell := FHotTrack and AHovered and
    (FRowSelect or (AColumn = 0) or (FViewStyle <> lvsReport));

  UpdateCanvasFont;
  Canvas.Brush.Style := bsClear;

  if not Enabled then
    Canvas.Font.Color := GetDisabledColor
  else if IsSelCell then
    Canvas.Font.Color := GetItemSelectedTextColor
  else if IsHovCell then
    Canvas.Font.Color := GetItemHoverTextColor
  else
    Canvas.Font.Color := GetItemTextColor;

  if HtmlMode then
    DrawHtmlTextWithAlign(Canvas, R, S,
      ListAlignmentToCss(CellAlign), cvaMiddle, Canvas.Font.Color)
  else
  begin
    ApplyTextStyle(TS, CellAlign);
    Canvas.TextRect(R, R.Left, R.Top, S, TS);
  end;
end;

// --- Checkbox helpers ---

function TCssListView.CreateCheckBoxHelper(AChecked,
  AHover: Boolean): TCssCheckBox;
begin
  Result := TCssCheckBox.Create(Self);

  Result.TabStop := False;
  Result.AutoSize := False;
  Result.ShowFocusRect := False;
  Result.CssTag := 'checkbox';
  Result.ToggleAnimation := False;
  Result.Caption := '';

  Result.SetVisualState(AChecked, AHover);
end;

function TCssListView.ComposeCheckBoxCssStyle: string;
begin
  Result := Trim(FCheckBoxCssStyle);

  if FCheckBoxInlineCss <> '' then
  begin
    if Result <> '' then
      Result := Result + ';';

    Result := Result + FCheckBoxInlineCss;
  end;
end;

procedure TCssListView.SetupCheckBoxHelper(CB: TCssCheckBox;
  AChecked, AHover: Boolean);
var
  S: string;
begin
  if CB = nil then
    Exit;

  S := ComposeCheckBoxCssStyle;

  CB.StyleProvider := StyleProvider;
  CB.StyleName := StyleName;

  CB.CssTag := 'checkbox';
  CB.CssClass := FCheckBoxCssClass;

  CB.ParentColor := False;
  CB.Color := GetCssBackgroundColor;

  CB.ParentFont := False;
  CB.Font.Assign(Font);
  CB.Font.Color := GetCssTextColor;

  CB.Enabled := Enabled;
  CB.ShowFocusRect := False;
  CB.AutoSize := False;
  CB.TabStop := False;

  CB.SetVisualState(AChecked, AHover);

  CB.CssStyle := S;
end;

procedure TCssListView.UpdateCheckBoxStyle;
begin
  if not FCheckboxes and (FCheckBoxNormal = nil) and
     (FCheckBoxChecked = nil) and (FCheckBoxHover = nil) and
     (FCheckBoxCheckedHover = nil) then
    Exit;

  if not Assigned(FCheckBoxNormal) then
    FCheckBoxNormal := CreateCheckBoxHelper(False, False);

  if not Assigned(FCheckBoxChecked) then
    FCheckBoxChecked := CreateCheckBoxHelper(True, False);

  if not Assigned(FCheckBoxHover) then
    FCheckBoxHover := CreateCheckBoxHelper(False, True);

  if not Assigned(FCheckBoxCheckedHover) then
    FCheckBoxCheckedHover := CreateCheckBoxHelper(True, True);

  SetupCheckBoxHelper(FCheckBoxNormal, False, False);
  SetupCheckBoxHelper(FCheckBoxChecked, True, False);
  SetupCheckBoxHelper(FCheckBoxHover, False, True);
  SetupCheckBoxHelper(FCheckBoxCheckedHover, True, True);
end;

procedure TCssListView.FreeCheckBoxHelpers;
begin
  FreeAndNil(FCheckBoxNormal);
  FreeAndNil(FCheckBoxChecked);
  FreeAndNil(FCheckBoxHover);
  FreeAndNil(FCheckBoxCheckedHover);
end;

// --- Inline editing ---

procedure TCssListView.BeginEdit(AItem: TCssListItem);
begin
  BeginEditInternal(AItem);
end;

procedure TCssListView.BeginEditInternal(AItem: TCssListItem);
var
  Allowed: Boolean;
  R: TRect;
begin
  if FReadOnly or (not Enabled) or (AItem = nil) then
    Exit;

  if IndexOfItem(AItem) < 0 then
    Exit;

  if FEditingItem <> nil then
    EndEditInternal(True);

  if not HandleAllocated then
    HandleNeeded;

  if not HandleAllocated then
    Exit;

  Allowed := True;

  if Assigned(FOnEditing) then
    FOnEditing(Self, AItem, Allowed);

  if not Allowed then
    Exit;

  ScrollIntoView(AItem);

  R := GetItemTextRect(IndexOfItem(AItem), 0);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  FEditOldText := AItem.Caption;

  FEdit.StyleProvider := StyleProvider;
  FEdit.CssClass := FEditCssClass;
  FEdit.ParentColor := False;
  FEdit.Color := GetItemBackground;
  FEdit.Font.Assign(Font);
  FEdit.Text := AItem.Caption;

  FEdit.SetBounds(
    R.Left + 1,
    R.Top + 1,
    CssMax(1, R.Width - 2),
    CssMax(1, R.Height - 2)
  );

  FEdit.HandleNeeded;
  FEdit.Visible := True;
  FEdit.Enabled := True;
  FEdit.BringToFront;

  if CanFocus then
    SetFocus;

  if FEdit.CanFocus then
    FEdit.SetFocus;

  if FEdit.Focused then
    FEdit.SelectAll;

  FEditingItem := AItem;
  Invalidate;
end;

procedure TCssListView.EndEdit(ACancel: Boolean);
begin
  EndEditInternal(ACancel);
end;

procedure TCssListView.EndEditInternal(ACancel: Boolean);
var
  Item: TCssListItem;
  S: string;
begin
  if FEditingItem = nil then
    Exit;

  if FEditClosing then
    Exit;

  FEditClosing := True;
  try
    Item := FEditingItem;
    S := FEdit.Text;

    FEditingItem := nil;

    if Assigned(FEdit) then
      FEdit.Visible := False;

    if not ACancel and (S <> FEditOldText) then
    begin
      Item.Caption := S;

      if Assigned(FOnEdited) then
        FOnEdited(Self, Item, S);
    end;

    if HandleAllocated and CanFocus then
      SetFocus;

    Invalidate;
  finally
    FEditClosing := False;
  end;
end;

procedure TCssListView.EditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    EndEditInternal(False);
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    EndEditInternal(True);
  end;
end;

procedure TCssListView.EditExit(Sender: TObject);
begin
  if FEditingItem <> nil then
    EndEditInternal(False);
end;

// --- Sorting ---

function TCssListView.GetSortText(AItem: TCssListItem;
  AColumn: Integer): string;
begin
  if AItem = nil then
    Exit('');

  if AColumn <= 0 then
    Result := AItem.Caption
  else
    Result := AItem.GetSubItemText(AColumn - 1);

  if HtmlMode then
    Result := HtmlToPlainText(Result);
end;

function TCssListView.CompareItems(AItem1, AItem2: TCssListItem): Integer;
var
  D1, D2: PtrInt;
  Col: Integer;
begin
  Result := 0;

  if (AItem1 = nil) or (AItem2 = nil) then
  begin
    if AItem1 = AItem2 then
      Exit(0);

    if AItem1 = nil then
      Exit(-1)
    else
      Exit(1);
  end;

  if Assigned(FOnCompare) then
  begin
    FOnCompare(Self, AItem1, AItem2, 0, Result);
  end
  else
  begin
    Col := FSortColumn;

    if Col < 0 then
      Col := 0;

    if FSortType = lstData then
    begin
      D1 := PtrInt(AItem1.Data);
      D2 := PtrInt(AItem2.Data);

      if D1 < D2 then
        Result := -1
      else if D1 > D2 then
        Result := 1
      else
        Result := 0;
    end
    else if FSortType = lstBoth then
    begin
      D1 := PtrInt(AItem1.Data);
      D2 := PtrInt(AItem2.Data);

      if D1 < D2 then
        Result := -1
      else if D1 > D2 then
        Result := 1
      else
        Result := CompareText(
          GetSortText(AItem1, Col),
          GetSortText(AItem2, Col)
        );
    end
    else
      Result := CompareText(
        GetSortText(AItem1, Col),
        GetSortText(AItem2, Col)
      );
  end;

  if FSortDirection = lsdDescending then
    Result := -Result;
end;

procedure TCssListView.SortInternal(AColumn: Integer;
  ADirection: TCssListSortDirection; ATextOnly: Boolean);
begin
  if FItems.Count < 2 then
  begin
    Invalidate;
    Exit;
  end;

  if AColumn < 0 then
    AColumn := 0;

  FSortColumn := AColumn;
  FSortDirection := ADirection;

  if ATextOnly then
    FSortType := lstText;

  BeginUpdate;
  try
    FItems.Sort(@CompareListItems, Self);
  finally
    EndUpdate;
  end;

  UpdateScrollBars;
  Invalidate;

  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TCssListView.Sort;
begin
  if FSortType = lstNone then
    Exit;

  SortInternal(FSortColumn, FSortDirection, False);
end;

function TCssListView.AlphaSort: Boolean;
var
  Direction: TCssListSortDirection;
begin
  Direction := lsdAscending;
  SortInternal(0, Direction, True);
  Result := True;
end;

procedure TCssListView.CustomSort(ACompare: TCssListCompareEvent);
var
  OldCompare: TCssListCompareEvent;
  OldDirection: TCssListSortDirection;
begin
  OldCompare := FOnCompare;
  OldDirection := FSortDirection;

  FOnCompare := ACompare;
  FSortDirection := lsdAscending;

  BeginUpdate;
  try
    FItems.Sort(@CompareListItems, Self);
  finally
    EndUpdate;
    FOnCompare := OldCompare;
    FSortDirection := OldDirection;
  end;

  UpdateScrollBars;
  Invalidate;
end;

function CssUnquoteValue(const AValue: string): string;
var
  S: string;
begin
  S := Trim(AValue);

  if (Length(S) >= 2) and
     ((S[1] = '"') or (S[1] = '''')) and
     (S[Length(S)] = S[1]) then
    S := Copy(S, 2, Length(S) - 2);

  Result := S;
end;

procedure TCssListView.ApplyDeclaration(const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
begin
  if AName = 'header-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FHeaderBackground := C;
      FHeaderBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'header-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FHeaderColor := C;
      FHeaderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'header-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FHeaderHoverBackground := C;
      FHeaderHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'header-height' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FHeaderHeight := Px;
      UpdateScrollBars;
    end;
    Exit;
  end;

  if AName = 'header-padding' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      FHeaderPadding := Px;
    Exit;
  end;

  if AName = 'sort-marker-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FSortMarkerColor := C;
      FSortMarkerColorSet := True;
    end;
    Exit;
  end;

  if (AName = 'item-background') or (AName = 'item-bg') then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemBackground := C;
      FItemBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemColor := C;
      FItemColorSet := True;
    end;
    Exit;
  end;

  if AName = 'item-hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemHoverBackground := C;
      FItemHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-hover-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemHoverColor := C;
      FItemHoverColorSet := True;
    end;
    Exit;
  end;

  if AName = 'item-selected-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemSelectedBackground := C;
      FItemSelectedBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'item-selected-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FItemSelectedColor := C;
      FItemSelectedColorSet := True;
    end;
    Exit;
  end;

  if AName = 'selection-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FSelectionBackground := C;
      FSelectionBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'selection-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FSelectionColor := C;
      FSelectionColorSet := True;
    end;
    Exit;
  end;

  if AName = 'hover-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FHoverBackground := C;
      FHoverBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'grid-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FGridColor := C;
      FGridColorSet := True;
    end;
    Exit;
  end;

  if AName = 'line-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FLineColor := C;
      FLineColorSet := True;
    end;
    Exit;
  end;

  if (AName = 'item-height') or (AName = 'row-height') then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FItemHeight := Px;
      UpdateScrollBars;
    end;
    Exit;
  end;

  if (AName = 'item-padding') or (AName = 'column-padding') then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FItemPadding := Px;
      UpdateScrollBars;
    end;
    Exit;
  end;

  if AName = 'icon-spacing' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FIconSpacing := Px;
      UpdateScrollBars;
    end;
    Exit;
  end;

  if AName = 'scrollbar-size' then
  begin
    if ParseCssLengthPx(AValue, Px) then
    begin
      FScrollBarSize := Px;
      UpdateScrollBars;
    end;
    Exit;
  end;

  if AName = 'check-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FCheckColor := C;
      FCheckColorSet := True;
    end;
    Exit;
  end;

  if AName = 'placeholder' then
  begin
    FPlaceholder := CssUnquoteValue(AValue);
    Exit;
  end;

  if AName = 'placeholder-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FPlaceholderColor := C;
      FPlaceholderColorSet := True;
    end;
    Exit;
  end;

  if AName = 'disabled-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FDisabledBackground := C;
      FDisabledBackgroundSet := True;
    end;
    Exit;
  end;

  if AName = 'disabled-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FDisabledColor := C;
      FDisabledColorSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

procedure TCssListView.ResetStyle;
begin
  FHeaderBackgroundSet := False;
  FHeaderColorSet := False;
  FHeaderHoverBackgroundSet := False;
  FItemBackgroundSet := False;
  FItemColorSet := False;
  FItemHoverBackgroundSet := False;
  FItemHoverColorSet := False;
  FItemSelectedBackgroundSet := False;
  FItemSelectedColorSet := False;
  FSelectionBackgroundSet := False;
  FSelectionColorSet := False;
  FHoverBackgroundSet := False;
  FGridColorSet := False;
  FLineColorSet := False;
  FSortMarkerColorSet := False;
  FDisabledBackgroundSet := False;
  FDisabledColorSet := False;
  FCheckColorSet := False;
  FPlaceholderColorSet := False;

  inherited ResetStyle;
end;

procedure TCssListView.StyleChanged;
begin
  inherited StyleChanged;

  UpdateCheckBoxStyle;

  if Assigned(FVScroll) then
  begin
    FVScroll.StyleProvider := StyleProvider;
    FVScroll.StyleName := StyleName;
  end;

  if Assigned(FHScroll) then
  begin
    FHScroll.StyleProvider := StyleProvider;
    FHScroll.StyleName := StyleName;
  end;

  if Assigned(FEdit) then
  begin
    FEdit.StyleProvider := StyleProvider;
    FEdit.StyleName := StyleName;
  end;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.Loaded;
begin
  inherited Loaded;

  if FCheckboxes then
    UpdateCheckBoxStyle;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.Resize;
begin
  inherited Resize;
  UpdateScrollBars;
end;

procedure TCssListView.EnabledChanged;
begin
  inherited EnabledChanged;

  if Assigned(FCheckBoxNormal) then
    FCheckBoxNormal.Enabled := Enabled;

  if Assigned(FCheckBoxChecked) then
    FCheckBoxChecked.Enabled := Enabled;

  if Assigned(FCheckBoxHover) then
    FCheckBoxHover.Enabled := Enabled;

  if Assigned(FCheckBoxCheckedHover) then
    FCheckBoxCheckedHover.Enabled := Enabled;

  if not Enabled then
    EndEditInternal(True);

  Invalidate;
end;

procedure TCssListView.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TCssListView.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TCssListView.AutoSizeColumn(AIndex: Integer);
var
  I, W, MaxW, P, Extra: Integer;
  S: string;
  Item: TCssListItem;
begin
  if (AIndex < 0) or (AIndex >= FColumns.Count) then
    Exit;

  UpdateCanvasFont;

  P := GetEffectiveItemPadding;
  S := FColumns[AIndex].Caption;

  if HtmlMode then
    S := HtmlToPlainText(S);

  MaxW := Canvas.TextWidth(S) + 2 * P + ScalePx(12);

  if (FSortType <> lstNone) and (FSortColumn = AIndex) then
    Inc(MaxW, ScalePx(16));

  for I := 0 to FItems.Count - 1 do
  begin
    Item := FItems[I];
    S := GetSortText(Item, AIndex);
    W := Canvas.TextWidth(S) + 2 * P + ScalePx(8);

    if W > MaxW then
      MaxW := W;
  end;

  Extra := 0;

  if AIndex = 0 then
  begin
    if FCheckboxes then
      Inc(Extra, GetCheckBoxSize + P);

    if FShowImages and Assigned(FSmallImages) then
      Inc(Extra, GetSmallImageSize.cx + P);

    if FShowImages and Assigned(FStateImages) then
      Inc(Extra, GetStateImageSize.cx + P);
  end;

  Inc(MaxW, Extra);

  if MaxW < FColumns[AIndex].MinWidth then
    MaxW := FColumns[AIndex].MinWidth;

  FColumns[AIndex].Width := MaxW;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssListView.SelectItemOnMouse(AItem: TCssListItem;
  Shift: TShiftState);
begin
  if AItem = nil then
    Exit;

  if not FMultiSelect then
  begin
    ClearSelectionInternal(True);
    SetItemSelection(AItem, True, True);
    FFocusedItem := AItem;
    FAnchorItem := AItem;
    Exit;
  end;

  if ssShift in Shift then
  begin
    if FAnchorItem = nil then
      FAnchorItem := AItem;

    SelectRange(FAnchorItem, AItem, ssCtrl in Shift);
    FFocusedItem := AItem;
  end
  else if ssCtrl in Shift then
  begin
    SetItemSelection(AItem, not IsItemSelected(AItem), True);
    FFocusedItem := AItem;
    FAnchorItem := AItem;
  end
  else
  begin
    ClearSelectionInternal(True);
    SetItemSelection(AItem, True, True);
    FFocusedItem := AItem;
    FAnchorItem := AItem;
  end;
end;

procedure TCssListView.NavigateTo(AIndex: Integer; Shift: TShiftState);
var
  Item: TCssListItem;
begin
  if FItems.Count = 0 then
    Exit;

  if AIndex < 0 then
    AIndex := 0;

  if AIndex >= FItems.Count then
    AIndex := FItems.Count - 1;

  Item := FItems[AIndex];

  if FMultiSelect and (ssShift in Shift) then
  begin
    if FAnchorItem = nil then
    begin
      if Assigned(FFocusedItem) then
        FAnchorItem := FFocusedItem
      else if FSelection.Count > 0 then
        FAnchorItem := TCssListItem(FSelection[0])
      else
        FAnchorItem := Item;
    end;

    SelectRange(FAnchorItem, Item, ssCtrl in Shift);
    FFocusedItem := Item;
    ScrollIntoView(Item);
    Invalidate;
  end
  else
    SetItemIndex(AIndex);
end;

procedure TCssListView.UpdateRubberBand(Shift: TShiftState);
var
  I: Integer;
  R: TRect;
begin
  FRubberRect := Rect(
    CssMin(FRubberStart.X, FLastMouse.X),
    CssMin(FRubberStart.Y, FLastMouse.Y),
    CssMax(FRubberStart.X, FLastMouse.X),
    CssMax(FRubberStart.Y, FLastMouse.Y)
  );

  if not FRubberAdditive then
    ClearSelectionInternal(False);

  for I := 0 to FItems.Count - 1 do
  begin
    R := GetItemRect(I);

    if (R.Left < FRubberRect.Right) and (R.Right > FRubberRect.Left) and
       (R.Top < FRubberRect.Bottom) and (R.Bottom > FRubberRect.Top) then
      SetItemSelection(FItems[I], True, True);
  end;

  Invalidate;
end;

procedure TCssListView.ApplyRubberBandSelection;
begin
  Invalidate;
end;

procedure TCssListView.CancelRubberBand;
begin
  FRubberBanding := False;
  FRubberRect := Rect(0, 0, 0, 0);
  MouseCapture := False;
  FMouseDown := False;
  Invalidate;
end;

procedure TCssListView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  HeaderR: TRect;
  Idx, Col, ResizeCol: Integer;
  Item: TCssListItem;
  CheckR: TRect;
  Handled: Boolean;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if CanFocus then
    SetFocus;

  if Button <> mbLeft then
    Exit;

  if FEditingItem <> nil then
    EndEditInternal(False);

  FLastMouse := Point(X, Y);

  ScrollBarMouseDown(X, Y, Handled);

  if Handled then
  begin
    FMouseDown := False;
    Exit;
  end;

  HeaderR := GetHeaderRect;

  if (HeaderR.Height > 0) and PtInRect(HeaderR, Point(X, Y)) then
  begin
    ResizeCol := GetHeaderResizeColumnAt(X);

    if ResizeCol >= 0 then
    begin
      FResizingColumn := ResizeCol;
      FResizeStartX := X;
      FResizeStartWidth := FColumns[ResizeCol].Width;
      MouseCapture := True;
      Cursor := crSizeWE;
      Exit;
    end;

    Col := GetColumnAt(X);

    if Col >= 0 then
    begin
      if FAutoSort then
      begin
        if FSortColumn = Col then
        begin
          if FSortDirection = lsdDescending then
            FSortDirection := lsdAscending
          else
            FSortDirection := lsdDescending;
        end
        else
        begin
          FSortColumn := Col;
          FSortDirection := lsdAscending;
        end;

        FSortType := lstText;
        SortInternal(Col, FSortDirection, False);
      end;

      if Assigned(FOnColumnClick) then
        FOnColumnClick(Self, FColumns[Col]);
    end;

    Invalidate;
    Exit;
  end;

  Idx := GetItemIndexAt(X, Y);
  Item := ItemFromIndex(Idx);

  if Item <> nil then
  begin
    if (FViewStyle = lvsReport) and (FColumns.Count > 0) then
    begin
      Col := GetColumnAt(X);

      if Col >= 0 then
        SetFocusedColumn(Col);
    end;

    if FCheckboxes then
    begin
      CheckR := GetCheckBoxRect(Idx, 0);

      if PtInRect(CheckR, Point(X, Y)) then
      begin
        Item.Checked := not Item.Checked;

        if not IsItemSelected(Item) then
          SelectItemOnMouse(Item, Shift)
        else
          SetFocusedItem(Item);

        FMouseDown := False;
        Exit;
      end;
    end;

    SelectItemOnMouse(Item, Shift);
    FMouseDownItem := Item;
    FMouseDown := True;
    Exit;
  end;

  FMouseDownItem := nil;
  FMouseDown := True;

  if not (ssCtrl in Shift) and not (ssShift in Shift) then
    ClearSelectionInternal(True);

  if FMultiSelect and (FViewStyle <> lvsReport) then
  begin
    FRubberBanding := False;
    FRubberAdditive := ssCtrl in Shift;
    FRubberStart := Point(X, Y);
    FRubberRect := Rect(X, Y, X, Y);
    MouseCapture := True;
  end;
end;

procedure TCssListView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewWidth, NewHot, Idx: Integer;
  HeaderR: TRect;
  Item: TCssListItem;
  Handled: Boolean;
begin
  inherited MouseMove(Shift, X, Y);

  FLastMouse := Point(X, Y);

  ScrollBarMouseMove(X, Y, Handled);

  if Handled then
    Exit;

  if FResizingColumn >= 0 then
  begin
    if FResizingColumn < FColumns.Count then
    begin
      NewWidth := FResizeStartWidth + (X - FResizeStartX);

      if NewWidth < FColumns[FResizingColumn].MinWidth then
        NewWidth := FColumns[FResizingColumn].MinWidth;

      FColumns[FResizingColumn].Width := NewWidth;
      UpdateScrollBars;
      Invalidate;
    end;

    Cursor := crSizeWE;
    Exit;
  end;

  if not Enabled then
    Exit;

  HeaderR := GetHeaderRect;

  if (HeaderR.Height > 0) and PtInRect(HeaderR, Point(X, Y)) then
  begin
    if GetHeaderResizeColumnAt(X) >= 0 then
      Cursor := crSizeWE
    else
      Cursor := crDefault;

    NewHot := GetColumnAt(X);

    if NewHot <> FHotHeaderColumn then
    begin
      FHotHeaderColumn := NewHot;
      Invalidate;
    end;

    Exit;
  end;

  if FHotHeaderColumn >= 0 then
  begin
    FHotHeaderColumn := -1;
    Invalidate;
  end;

  Cursor := crDefault;

  if FMouseDown and (FViewStyle <> lvsReport) and
     (FMultiSelect) and
     ((Abs(X - FRubberStart.X) > ScalePx(4)) or
      (Abs(Y - FRubberStart.Y) > ScalePx(4))) then
  begin
    FRubberBanding := True;
    UpdateRubberBand(Shift);
    Exit;
  end;

  Idx := GetItemIndexAt(X, Y);
  Item := ItemFromIndex(Idx);

  if Item <> FHoverItem then
  begin
    FHoverItem := Item;

    if FHotTrack or FCheckboxes then
      Invalidate;
  end;
end;

procedure TCssListView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FScrollCapture <> nil then
  begin
    ScrollBarMouseUp;
    Exit;
  end;

  if FResizingColumn >= 0 then
  begin
    FResizingColumn := -1;
    MouseCapture := False;
    Cursor := crDefault;
    Invalidate;
    Exit;
  end;

  if FRubberBanding then
  begin
    ApplyRubberBandSelection;
    CancelRubberBand;
    Exit;
  end;

  FMouseDown := False;
  FMouseDownItem := nil;
end;

procedure TCssListView.MouseLeave;
begin
  inherited MouseLeave;

  if not FMouseDown then
  begin
    FHoverItem := nil;
    FHotHeaderColumn := -1;
    Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TCssListView.DblClick;
var
  P: TPoint;
  Idx, Col: Integer;
  Item: TCssListItem;
begin
  inherited DblClick;

  if not Enabled then
    Exit;

  P := ScreenToClient(Mouse.CursorPos);

  if (GetHeaderRect.Height > 0) and PtInRect(GetHeaderRect, P) then
  begin
    Col := GetHeaderResizeColumnAt(P.X);

    if Col >= 0 then
      AutoSizeColumn(Col);

    Exit;
  end;

  Idx := GetItemIndexAt(P.X, P.Y);
  Item := ItemFromIndex(Idx);

  if Item = nil then
    Exit;

  if Assigned(FOnItemActivate) then
    FOnItemActivate(Self, Item);

  if not FReadOnly then
    BeginEditInternal(Item);
end;

procedure TCssListView.KeyDown(var Key: Word; Shift: TShiftState);
var
  Idx, NewIdx, Page: Integer;
  Item: TCssListItem;
begin
  inherited KeyDown(Key, Shift);

  if FEditingItem <> nil then
    Exit;

  if not Enabled then
    Exit;

  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    SelectAll;
    Key := 0;
    Exit;
  end;

  Idx := GetItemIndex;
  Page := CssMax(1, GetPageRows);

  case Key of
    VK_UP:
      begin
        if FViewStyle = lvsReport then
          NavigateTo(Idx - 1, Shift)
        else
        begin
          NewIdx := GetArrowTargetIndex(VK_UP, Idx);

          if NewIdx <> Idx then
            NavigateTo(NewIdx, Shift);
        end;

        Key := 0;
      end;

    VK_DOWN:
      begin
        if FViewStyle = lvsReport then
          NavigateTo(Idx + 1, Shift)
        else
        begin
          NewIdx := GetArrowTargetIndex(VK_DOWN, Idx);

          if NewIdx <> Idx then
            NavigateTo(NewIdx, Shift);
        end;

        Key := 0;
      end;

    VK_LEFT:
      begin
        if FViewStyle = lvsReport then
          SetFocusedColumn(FFocusedColumn - 1)
        else
        begin
          NewIdx := GetArrowTargetIndex(VK_LEFT, Idx);

          if NewIdx <> Idx then
            NavigateTo(NewIdx, Shift);
        end;

        Key := 0;
      end;

    VK_RIGHT:
      begin
        if FViewStyle = lvsReport then
          SetFocusedColumn(FFocusedColumn + 1)
        else
        begin
          NewIdx := GetArrowTargetIndex(VK_RIGHT, Idx);

          if NewIdx <> Idx then
            NavigateTo(NewIdx, Shift);
        end;

        Key := 0;
      end;

    VK_HOME:
      begin
        NavigateTo(0, Shift);
        Key := 0;
      end;

    VK_END:
      begin
        NavigateTo(FItems.Count - 1, Shift);
        Key := 0;
      end;

    VK_PRIOR:
      begin
        if Idx < 0 then
          Idx := 0;

        NavigateTo(Idx - Page, Shift);
        Key := 0;
      end;

    VK_NEXT:
      begin
        if Idx < 0 then
          Idx := 0;

        NavigateTo(Idx + Page, Shift);
        Key := 0;
      end;

    VK_SPACE:
      begin
        Item := ItemFromIndex(Idx);

        if Item = nil then
          Exit;

        if FCheckboxes then
          Item.Checked := not Item.Checked
        else if FMultiSelect then
          SetItemSelection(Item, not IsItemSelected(Item), True);

        Key := 0;
      end;

    VK_RETURN:
      begin
        Item := ItemFromIndex(Idx);

        if (Item <> nil) and Assigned(FOnItemActivate) then
          FOnItemActivate(Self, Item);

        Key := 0;
      end;

    VK_F2:
      begin
        Item := ItemFromIndex(Idx);

        if (Item <> nil) and (not FReadOnly) then
          BeginEditInternal(Item);

        Key := 0;
      end;

    VK_ESCAPE:
      begin
        if FRubberBanding then
          CancelRubberBand;
      end;
  end;
end;

procedure TCssListView.KeyPress(var Key: char);
var
  I, Idx, StartIdx, Count: Integer;
  S: string;
  NowTick: QWord;
begin
  inherited KeyPress(Key);

  if FEditingItem <> nil then
    Exit;

  if not Enabled then
    Exit;

  if Key < ' ' then
    Exit;

  Count := FItems.Count;

  if Count = 0 then
    Exit;

  NowTick := GetTickCount64;

  if (FSearchTime = 0) or (NowTick - FSearchTime > 1000) then
    FSearchText := '';

  FSearchTime := NowTick;
  FSearchText := FSearchText + Key;

  StartIdx := GetItemIndex;

  if StartIdx < 0 then
    StartIdx := 0
  else
    Inc(StartIdx);

  if StartIdx >= Count then
    StartIdx := 0;

  for I := 0 to Count - 1 do
  begin
    Idx := (StartIdx + I) mod Count;
    S := FItems[Idx].Caption;

    if (Length(S) >= Length(FSearchText)) and
       SameText(Copy(S, 1, Length(FSearchText)), FSearchText) then
    begin
      SetItemIndex(Idx);
      Break;
    end;
  end;

  Key := #0;
end;

function TCssListView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Delta, Lines: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);

  if not Enabled then
    Exit;

  Delta := WheelDelta div 120;

  if Delta = 0 then
  begin
    if WheelDelta > 0 then
      Delta := 1
    else if WheelDelta < 0 then
      Delta := -1;
  end;

  if Delta = 0 then
    Exit;

  if (ssShift in Shift) and Assigned(FHScroll) and FHScroll.Visible then
  begin
    FHScroll.Position := FHScroll.Position - Delta * 3 * FHScroll.SmallChange;
    Result := True;
    Exit;
  end;

  if Assigned(FVScroll) and FVScroll.Visible then
  begin
    if FViewStyle = lvsReport then
      Lines := 3
    else
      Lines := 3 * CssMax(1, GetRowStep);

    FVScroll.Position := FVScroll.Position - Delta * Lines;
    Result := True;
    Exit;
  end;

  if Assigned(FHScroll) and FHScroll.Visible then
  begin
    FHScroll.Position := FHScroll.Position - Delta * 3 * FHScroll.SmallChange;
    Result := True;
  end;
end;

end.











