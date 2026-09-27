unit CssVirtualTreeControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, GraphType, Types, LCLType, Forms,
  CssStyledControl, CssScrollControl, CssEditControl, CssCheckboxControl;

type
  TCssVirtualNodeState = (
    cvsExpanded,
    cvsSelected,
    cvsHasChildren,
    cvsChecked,
    cvsChildrenLoaded,
    cvsDisabled
  );
  TCssVirtualNodeStates = set of TCssVirtualNodeState;

  TCssVirtualTreeTextType = (vttNormal, vttStatic);

  TCssTreeHAlign = (
    thaInherit,
    thaLeft,
    thaCenter,
    thaRight
  );

  TCssTreeVAlign = (
    tvaInherit,
    tvaTop,
    tvaMiddle,
    tvaBottom
  );

  TCssVirtualTreeCellAlign = record
    Column: Integer;
    HAlign: TCssTreeHAlign;
    VAlign: TCssTreeVAlign;
  end;

  TCssVirtualNode = class
  public
    Parent: TCssVirtualNode;
    FirstChild: TCssVirtualNode;
    LastChild: TCssVirtualNode;
    PrevSibling: TCssVirtualNode;
    NextSibling: TCssVirtualNode;
    ChildCount: Integer;
    AbsoluteIndex: Integer;
    States: TCssVirtualNodeStates;
    Data: Pointer;

    // Per-node alignment
    HAlign: TCssTreeHAlign;
    VAlign: TCssTreeVAlign;

    // Per-node per-cell alignment overrides
    CellAligns: array of TCssVirtualTreeCellAlign;
  end;

  TCssVirtualStringTree = class;

  TCssGetNodeDataSizeEvent = procedure(
    Sender: TObject;
    var NodeDataSize: Integer
  ) of object;

  TCssInitNodeEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode
  ) of object;

  TCssFreeNodeEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode
  ) of object;

  TCssGetTextEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    Column: Integer;
    TextType: TCssVirtualTreeTextType;
    var CellText: string
  ) of object;

  TCssNodeClickEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    Column: Integer
  ) of object;

  TCssExpandingEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    var Allowed: Boolean
  ) of object;

  TCssNotifyNodeEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode
  ) of object;

  TCssCompareEvent = function(
    Sender: TObject;
    Node1, Node2: TCssVirtualNode;
    Column: Integer
  ): Integer of object;

  TCssEditingEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    Column: Integer;
    var Allowed: Boolean
  ) of object;

  TCssNewTextEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    Column: Integer;
    const NewText: string
  ) of object;

  TCssHeaderClickEvent = procedure(
    Sender: TObject;
    Column: Integer
  ) of object;

  TCssDrawCellEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode;
    Column: Integer;
    const CellRect: TRect;
    var Handled: Boolean
  ) of object;

  TCssLoadChildrenEvent = procedure(
    Sender: TObject;
    Node: TCssVirtualNode
  ) of object;

  TCssDragNodesEvent = procedure(
    Sender: TObject;
    Nodes: TList;
    TargetNode: TCssVirtualNode;
    var Allowed: Boolean
  ) of object;

  TCssDropNodesEvent = procedure(
    Sender: TObject;
    Nodes: TList;
    TargetNode: TCssVirtualNode
  ) of object;

  TCssDropNodesExEvent = procedure(
    Sender: TObject;
    SourceTree: TCssVirtualStringTree;
    Nodes: TList;
    TargetNode: TCssVirtualNode
  ) of object;

  TCssColumnResizeEvent = procedure(
    Sender: TObject;
    Column: Integer
  ) of object;

  TCssSortDirection = (csdNone, csdAscending, csdDescending);

  TCssVirtualTreeSortColumn = record
    Column: Integer;
    Direction: TCssSortDirection;
  end;

  TCssVirtualTreeDragObject = class(TDragControlObject)
  private
    FTree: TCssVirtualStringTree;
    FNodes: TList;
  public
    constructor Create(ATree: TCssVirtualStringTree; ANodes: TList); reintroduce;
    destructor Destroy; override;

    property Tree: TCssVirtualStringTree read FTree;
    property Nodes: TList read FNodes;
  end;

  TCssVirtualTreeColumn = class(TCollectionItem)
  private
    FText: string;
    FWidth: Integer;
    FHeaderHAlign: TCssTreeHAlign;
    FHeaderVAlign: TCssTreeVAlign;
    FCellHAlign: TCssTreeHAlign;
    FCellVAlign: TCssTreeVAlign;

    procedure SetText(const AValue: string);
    procedure SetWidth(AValue: Integer);
    procedure SetHeaderHAlign(AValue: TCssTreeHAlign);
    procedure SetHeaderVAlign(AValue: TCssTreeVAlign);
    procedure SetCellHAlign(AValue: TCssTreeHAlign);
    procedure SetCellVAlign(AValue: TCssTreeVAlign);
  published
    property Text: string read FText write SetText;
    property Width: Integer read FWidth write SetWidth default 100;

    property HeaderHAlign: TCssTreeHAlign
      read FHeaderHAlign write SetHeaderHAlign default thaInherit;

    property HeaderVAlign: TCssTreeVAlign
      read FHeaderVAlign write SetHeaderVAlign default tvaInherit;

    property CellHAlign: TCssTreeHAlign
      read FCellHAlign write SetCellHAlign default thaInherit;

    property CellVAlign: TCssTreeVAlign
      read FCellVAlign write SetCellVAlign default tvaInherit;
  end;

  TCssVirtualTreeColumns = class(TCollection)
  private
    FOwner: TCssVirtualStringTree;
    function GetItem(Index: Integer): TCssVirtualTreeColumn;
    procedure SetItem(Index: Integer; AValue: TCssVirtualTreeColumn);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TCssVirtualStringTree); reintroduce;
    function Add: TCssVirtualTreeColumn;
    property Items[Index: Integer]: TCssVirtualTreeColumn
      read GetItem write SetItem; default;
  end;

  TCssVirtualStringTree = class(TCssStyledControl)
  private
    // Tree data
    FRoot: TCssVirtualNode;
    FVisibleNodes: TList;
    FColumns: TCssVirtualTreeColumns;
    FNodeDataSize: Integer;

    // Layout
    FHeaderVisible: Boolean;
    FHeaderHeight: Integer;
    FIndent: Integer;
    FItemHeight: Integer;
    FScrollBarSize: Integer;
    FTopNode: Integer;
    FHorzOffset: Integer;

    // Selection & hover
    FSelectedNode: TCssVirtualNode;
    FHoverNode: TCssVirtualNode;
    FLastMouse: TPoint;
    FSelectionList: TList;
    FAnchorNode: TCssVirtualNode;
    FMultiSelect: Boolean;

    // Scrollbars
    FVScroll: TCssScrollBar;
    FHScroll: TCssScrollBar;
    FVScrollRect: TRect;
    FHScrollRect: TRect;
    FScrollCapture: TCssScrollBar;
    FAlwaysReserveScrollBar: Boolean;

    // Internal update flags
    FUpdatingScroll: Boolean;
    FUpdateCount: Integer;
    FNeedRebuild: Boolean;

    // Checkboxes
    FShowCheckboxes: Boolean;

    // Editing
    FAllowEditing: Boolean;
    FEditingNode: TCssVirtualNode;
    FEditingColumn: Integer;
    FEdit: TCssEdit;
    FEditOldText: string;
    FEditClosing: Boolean;
    FEditStyleName: string;

    // Drag & drop
    FAllowDrag: Boolean;
    FAllowDrop: Boolean;
    FDragPending: Boolean;
    FDragStartPoint: TPoint;
    FDropTargetNode: TCssVirtualNode;

    // Lazy loading
    FLazyLoading: Boolean;
    FOnLoadChildren: TCssLoadChildrenEvent;

    // Sorting
    FAutoSort: Boolean;
    FSortColumns: array of TCssVirtualTreeSortColumn;

    // Fixed layout
    FFixedColumns: Integer;
    FFixedHeader: Boolean;

    // Incremental search
    FIncrementalSearch: Boolean;
    FSearchText: string;
    FSearchTime: QWord;

    // Column resizing
    FAllowColumnResize: Boolean;
    FColumnResizeTolerance: Integer;
    FMinColumnWidth: Integer;
    FResizingColumn: Integer;
    FResizeStartX: Integer;
    FResizeStartWidth: Integer;
    FOnColumnResizing: TCssColumnResizeEvent;
    FOnColumnResized: TCssColumnResizeEvent;

    // Alignment (tree-level)
    FHeaderHAlign: TCssTreeHAlign;
    FHeaderVAlign: TCssTreeVAlign;
    FCellHAlign: TCssTreeHAlign;
    FCellVAlign: TCssTreeVAlign;

    FHeaderHAlignCss: TCssTreeHAlign;
    FHeaderHAlignCssSet: Boolean;
    FHeaderVAlignCss: TCssTreeVAlign;
    FHeaderVAlignCssSet: Boolean;
    FCellHAlignCss: TCssTreeHAlign;
    FCellHAlignCssSet: Boolean;
    FCellVAlignCss: TCssTreeVAlign;
    FCellVAlignCssSet: Boolean;

    // CSS colors
    FHeaderBackground: TColor;    FHeaderBackgroundSet: Boolean;
    FHeaderColor: TColor;         FHeaderColorSet: Boolean;
    FSelectionBackground: TColor; FSelectionBackgroundSet: Boolean;
    FSelectionColor: TColor;      FSelectionColorSet: Boolean;
    FHoverBackground: TColor;     FHoverBackgroundSet: Boolean;
    FLineColor: TColor;           FLineColorSet: Boolean;
    FButtonColor: TColor;         FButtonColorSet: Boolean;
    FCheckColor: TColor;          FCheckColorSet: Boolean;
    FDropTargetBackground: TColor; FDropTargetBackgroundSet: Boolean;
    FSortMarkerColor: TColor;     FSortMarkerColorSet: Boolean;
    FDisabledBackground: TColor;  FDisabledBackgroundSet: Boolean;
    FDisabledColor: TColor;       FDisabledColorSet: Boolean;

    // Checkbox helpers
    FCheckBoxNormal: TCssCheckBox;
    FCheckBoxChecked: TCssCheckBox;
    FCheckBoxHover: TCssCheckBox;
    FCheckBoxCheckedHover: TCssCheckBox;

    FCheckBoxCssClass: string;
    FCheckBoxCssStyle: string;
    FCheckBoxInlineCss: string;

    // Events
    FOnGetNodeDataSize: TCssGetNodeDataSizeEvent;
    FOnInitNode: TCssInitNodeEvent;
    FOnFreeNode: TCssFreeNodeEvent;
    FOnGetText: TCssGetTextEvent;
    FOnNodeClick: TCssNodeClickEvent;
    FOnSelectionChanged: TNotifyEvent;

    FOnExpanding: TCssExpandingEvent;
    FOnExpanded: TCssNotifyNodeEvent;
    FOnCollapsing: TCssExpandingEvent;
    FOnCollapsed: TCssNotifyNodeEvent;

    FOnCheckedChanged: TCssNotifyNodeEvent;

    FOnEditing: TCssEditingEvent;
    FOnNewText: TCssNewTextEvent;

    FOnCompareNodes: TCssCompareEvent;
    FOnHeaderClick: TCssHeaderClickEvent;
    FOnDrawCell: TCssDrawCellEvent;

    FOnDragOverNodes: TCssDragNodesEvent;
    FOnDropNodes: TCssDropNodesEvent;
    FOnDropNodesEx: TCssDropNodesExEvent;

    // --- Tree structure ---
    function GetVisibleCount: Integer;
    function GetVisibleNode(Index: Integer): TCssVirtualNode;

    procedure BuildVisibleList;
    procedure NeedRebuild;
    procedure RebuildVisible;

    procedure InternalDeleteNode(Node: TCssVirtualNode);
    procedure EnsureNodeDataSize;

    procedure DoInitNode(Node: TCssVirtualNode);
    procedure DoFreeNode(Node: TCssVirtualNode);
    procedure DoGetText(Node: TCssVirtualNode; Column: Integer; var AText: string);

    procedure DoLoadChildren(Node: TCssVirtualNode);
    procedure EnsureChildrenLoaded(Node: TCssVirtualNode);

    function GetNodeDepth(Node: TCssVirtualNode): Integer;
    function IsNodeInSubTree(Node, SubRoot: TCssVirtualNode): Boolean;
    function IsNodeInSubTreeOfAny(Node: TCssVirtualNode; Nodes: TList): Boolean;

    // --- Geometry & layout ---
    function GetHeaderHeight: Integer;
    function GetTreeRect: TRect;
    function GetPageRows: Integer;

    function GetTotalWidth: Integer;
    function GetTotalHeight: Integer;

    function GetFixedWidth: Integer;
    function GetScrollAreaRect: TRect;
    function GetFixedAreaRect: TRect;

    function GetColumnWidth(Index: Integer): Integer;
    function GetColumnLeft(Index: Integer): Integer;

    function GetButtonRect(Node: TCssVirtualNode; const RowR: TRect): TRect;
    function GetCheckBoxSize: Integer;
    function GetCheckRect(Node: TCssVirtualNode; const RowR: TRect): TRect;
    function GetTextStartX(Node: TCssVirtualNode; const RowR: TRect): Integer;

    function GetNodeAt(X, Y: Integer): TCssVirtualNode;
    function GetColumnAt(X: Integer): Integer;
    function GetHeaderColumnAt(X: Integer): Integer;
    function GetCellRect(Node: TCssVirtualNode; Column: Integer): TRect;
    function GetCellText(Node: TCssVirtualNode; Column: Integer): string;

    function GetHeaderResizeColumnAt(X: Integer): Integer;
    function GetColumnClipRect(Column: Integer; const VertR: TRect): TRect;

    // --- Property setters ---
    procedure SetHeaderVisible(AValue: Boolean);
    procedure SetHeaderHeight(AValue: Integer);
    procedure SetIndent(AValue: Integer);
    procedure SetItemHeight(AValue: Integer);
    procedure SetScrollBarSize(AValue: Integer);

    procedure SetFixedColumns(AValue: Integer);
    procedure SetFixedHeader(AValue: Boolean);
    procedure SetEditStyleName(const AValue: string);

    procedure SetColumns(AValue: TCssVirtualTreeColumns);
    procedure SetNodeDataSize(AValue: Integer);
    procedure SetTopNode(AValue: Integer);
    procedure SetHorzOffset(AValue: Integer);
    procedure SetSelectedNode(AValue: TCssVirtualNode);

    procedure SetAlwaysReserveScrollBar(AValue: Boolean);

    // --- Scroll handling ---
    procedure DoVScroll(Sender: TObject);
    procedure DoHScroll(Sender: TObject);
    procedure UpdateScrollBars;

    // --- CSS color getters ---
    function GetHeaderBackground: TColor;
    function GetHeaderTextColor: TColor;
    function GetSelectionBackground: TColor;
    function GetSelectionColor: TColor;
    function GetHoverBackground: TColor;
    function GetLineColor: TColor;
    function GetButtonColor: TColor;
    function GetCheckColor: TColor;
    function GetDropTargetBackground: TColor;
    function GetSortMarkerColor: TColor;
    function GetDisabledBackground: TColor;
    function GetDisabledColor: TColor;
    function GetParentBackgroundColor: TColor;

    // --- Drawing ---
    procedure DrawHeader(const R: TRect);
    procedure DrawHeaderCell(Index: Integer; const HeaderR: TRect);
    procedure DrawSortMarkers(const HeaderR: TRect);

    procedure DrawNodeRow(Node: TCssVirtualNode; RowIndex: Integer; const TreeR: TRect);

    procedure DrawCellContent(
      Node: TCssVirtualNode;
      Column: Integer;
      const RowR: TRect;
      IsSelected: Boolean);

    procedure DrawCellText(
      Node: TCssVirtualNode;
      Column: Integer;
      const CellR: TRect;
      const S: string;
      TextColor: TColor;
      const ClipR: TRect);

    procedure DrawButton(Node: TCssVirtualNode; const RowR: TRect);
    procedure DrawCheckBox(Node: TCssVirtualNode; const RowR: TRect);

    procedure DrawInternalScrollBars;
    procedure DrawRoundedCornerMask;

    // --- Selection helpers ---
    procedure SelectVisibleIndex(Index: Integer);
    procedure MoveSelection(Delta: Integer; Shift: TShiftState);

    function IsSelected(Node: TCssVirtualNode): Boolean;
    procedure InternalClearSelection(NotifyChange: Boolean);
    procedure InternalAddToSelection(Node: TCssVirtualNode; NotifyChange: Boolean);
    procedure InternalRemoveFromSelection(Node: TCssVirtualNode; NotifyChange: Boolean);
    procedure SelectRange(A, B: TCssVirtualNode);
    procedure SelectionChanged;

    // --- Editing ---
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditExit(Sender: TObject);

    // --- Sorting ---
    function GetSortIndex(Column: Integer): Integer;
    procedure DeleteSortIndex(Index: Integer);
    function CompareNodesMulti(Node1, Node2: TCssVirtualNode): Integer;
    procedure SortList(AList: TList);

    function GetPrimarySortColumn: Integer;
    function GetPrimarySortAscending: Boolean;
    procedure SetPrimarySortColumn(AValue: Integer);
    procedure SetPrimarySortAscending(AValue: Boolean);

    // --- Search ---
    procedure FindSearchNode;

    // --- Drag & drop ---
    procedure InternalStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure InternalEndDrag(Sender, Target: TObject; X, Y: Integer);

    // --- Checkbox helpers ---
    function CreateCheckBoxHelper(AChecked, AHover: Boolean): TCssCheckBox;
    procedure SetupCheckBoxHelper(CB: TCssCheckBox; AChecked, AHover: Boolean);
    function ComposeCheckBoxCssStyle: string;
    procedure SetCheckBoxCssClass(const AValue: string);
    procedure SetCheckBoxCssStyle(const AValue: string);
    procedure UpdateCheckBoxStyle;

    // --- Alignment resolution ---
    procedure SetHeaderHAlign(AValue: TCssTreeHAlign);
    procedure SetHeaderVAlign(AValue: TCssTreeVAlign);
    procedure SetCellHAlign(AValue: TCssTreeHAlign);
    procedure SetCellVAlign(AValue: TCssTreeVAlign);

    function FindCellAlignIndex(Node: TCssVirtualNode; Column: Integer): Integer;
    procedure RemoveCellAlign(Node: TCssVirtualNode; Index: Integer);
    procedure RemoveCellAlignIfInherit(Node: TCssVirtualNode; Index: Integer);

    function ResolveHeaderHAlign(Column: Integer): TCssTextAlign;
    function ResolveHeaderVAlign(Column: Integer): TCssVAlign;
    function ResolveCellHAlign(Node: TCssVirtualNode; Column: Integer): TCssTextAlign;
    function ResolveCellVAlign(Node: TCssVirtualNode; Column: Integer): TCssVAlign;

    // --- Navigation / clamp helpers ---
    function ClampVisibleIndex(AValue: Integer): Integer;
    function FindEnabledVisibleIndex(ATarget, ADirection: Integer): Integer;
    function FindNearestEnabledVisibleIndex(AIndex: Integer): Integer;
    function ShouldAutoSort: Boolean;
    procedure AutoSortNode(Node: TCssVirtualNode; Recursive: Boolean);

    // --- Scrollbar lookup ---
    function ScrollBarAt(X, Y: Integer): TCssScrollBar;
  protected
    // Initialization and style
    procedure Loaded; override;
    procedure InitTextProps; override;
    procedure StyleChanged; override;
    procedure ResetStyle; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;

    // Painting
    procedure Paint; override;

    // Sizing
    procedure Resize; override;

    // Mouse events
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure DblClick; override;

    // Keyboard events
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: char); override;

    // Mouse wheel
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;

    // Drag & drop (VCL hooks)
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState;
      var Accept: Boolean); override;

    // State changes
    procedure EnabledChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Batch updates
    procedure BeginUpdate;
    procedure EndUpdate;

    // Structure
    function AddChild(AParent: TCssVirtualNode): TCssVirtualNode;
    procedure DeleteNode(Node: TCssVirtualNode);
    procedure DeleteChildren(Node: TCssVirtualNode);
    procedure ClearAll;

    // Expansion
    procedure ExpandNode(Node: TCssVirtualNode);
    procedure CollapseNode(Node: TCssVirtualNode);
    procedure ToggleNode(Node: TCssVirtualNode);

    procedure FullExpand;
    procedure FullCollapse;

    // Navigation
    procedure MakeVisible(Node: TCssVirtualNode);
    procedure ScrollIntoView(Node: TCssVirtualNode);

    function GetNodeData(Node: TCssVirtualNode): Pointer;
    function GetFirstVisible: TCssVirtualNode;
    function GetNextVisible(Node: TCssVirtualNode): TCssVirtualNode;

    // Selection
    procedure SelectAll;
    procedure ClearSelection;
    procedure AddToSelection(Node: TCssVirtualNode);
    procedure RemoveFromSelection(Node: TCssVirtualNode);
    function GetSelectedCount: Integer;
    function GetSelectedNode(Index: Integer): TCssVirtualNode;

    // Checkboxes
    procedure SetChecked(Node: TCssVirtualNode; AValue: Boolean);
    procedure ToggleCheck(Node: TCssVirtualNode);
    function IsChecked(Node: TCssVirtualNode): Boolean;

    // Editing
    procedure StartEditing(Node: TCssVirtualNode; Column: Integer);
    procedure EndEditing(Cancel: Boolean);

    // Sorting
    procedure ClearSortColumns;
    function GetSortDirection(Column: Integer): TCssSortDirection;
    procedure SetSortColumn(Column: Integer; Direction: TCssSortDirection;
      AddToExisting: Boolean);
    procedure SortBySortColumns;
    procedure SortNodeChildren(Node: TCssVirtualNode; Recursive: Boolean);

    // Lazy loading
    procedure ReloadChildren(Node: TCssVirtualNode);

    // Drag & drop
    procedure MoveNode(Source, NewParent: TCssVirtualNode);
    procedure MoveNodes(Nodes: TList; NewParent: TCssVirtualNode);
    procedure DragDrop(Source: TObject; X, Y: Integer); override;

    // Auto-sizing
    procedure AutoSizeColumns(IncludeHeader: Boolean);

    procedure RefreshCheckBoxStyle;

    // Enabled state
    function IsNodeEnabled(Node: TCssVirtualNode): Boolean;
    function IsNodeDisabled(Node: TCssVirtualNode): Boolean;
    procedure SetNodeEnabled(Node: TCssVirtualNode; AValue: Boolean);
    procedure DisableNode(Node: TCssVirtualNode);
    procedure EnableNode(Node: TCssVirtualNode);

    function PlainCellText(Node: TCssVirtualNode; Column: Integer): string;

    // Whole-node alignment
    procedure SetNodeHAlign(Node: TCssVirtualNode; AValue: TCssTreeHAlign);
    procedure SetNodeVAlign(Node: TCssVirtualNode; AValue: TCssTreeVAlign);
    procedure SetNodeAlign(Node: TCssVirtualNode; HAlign: TCssTreeHAlign;
      VAlign: TCssTreeVAlign);

    // Per-cell alignment
    procedure SetCellHAlign(Node: TCssVirtualNode; Column: Integer;
      AValue: TCssTreeHAlign);
    procedure SetCellVAlign(Node: TCssVirtualNode; Column: Integer;
      AValue: TCssTreeVAlign);
    procedure SetCellAlign(Node: TCssVirtualNode; Column: Integer;
      HAlign: TCssTreeHAlign; VAlign: TCssTreeVAlign);
    procedure ClearCellAligns(Node: TCssVirtualNode);

    // Alignment getters
    function GetNodeHAlign(Node: TCssVirtualNode): TCssTreeHAlign;
    function GetNodeVAlign(Node: TCssVirtualNode): TCssTreeVAlign;
    function GetCellHAlign(Node: TCssVirtualNode; Column: Integer): TCssTreeHAlign;
    function GetCellVAlign(Node: TCssVirtualNode; Column: Integer): TCssTreeVAlign;
    function GetEffectiveCellHAlign(Node: TCssVirtualNode;
      Column: Integer): TCssTextAlign;
    function GetEffectiveCellVAlign(Node: TCssVirtualNode;
      Column: Integer): TCssVAlign;

    // Exposed style helpers
    property CheckBoxStyle: TCssCheckBox read FCheckBoxNormal;
    property CheckBoxCheckedStyle: TCssCheckBox read FCheckBoxChecked;
    property CheckBoxHoverStyle: TCssCheckBox read FCheckBoxHover;
    property CheckBoxCheckedHoverStyle: TCssCheckBox read FCheckBoxCheckedHover;

    // Exposed state
    property RootNode: TCssVirtualNode read FRoot;
    property VisibleCount: Integer read GetVisibleCount;
    property SelectedNode: TCssVirtualNode read FSelectedNode write SetSelectedNode;
    property TopNode: Integer read FTopNode write SetTopNode;
  published
    property Columns: TCssVirtualTreeColumns read FColumns write SetColumns;

    property HeaderVisible: Boolean read FHeaderVisible write SetHeaderVisible default True;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 22;
    property Indent: Integer read FIndent write SetIndent default 20;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 22;
    property NodeDataSize: Integer read FNodeDataSize write SetNodeDataSize default 0;
    property ScrollBarSize: Integer read FScrollBarSize write SetScrollBarSize default 16;
    property AlwaysReserveScrollBar: Boolean read FAlwaysReserveScrollBar write SetAlwaysReserveScrollBar default True;

    property MultiSelect: Boolean read FMultiSelect write FMultiSelect default False;
    property ShowCheckboxes: Boolean read FShowCheckboxes write FShowCheckboxes default False;

    property AllowEditing: Boolean read FAllowEditing write FAllowEditing default False;
    property AllowDrag: Boolean read FAllowDrag write FAllowDrag default False;
    property AllowDrop: Boolean read FAllowDrop write FAllowDrop default False;

    property LazyLoading: Boolean read FLazyLoading write FLazyLoading default False;

    property AutoSort: Boolean read FAutoSort write FAutoSort default False;
    property SortColumn: Integer
      read GetPrimarySortColumn write SetPrimarySortColumn default -1;
    property SortAscending: Boolean
      read GetPrimarySortAscending write SetPrimarySortAscending default True;

    property FixedColumns: Integer read FFixedColumns write SetFixedColumns default 0;
    property FixedHeader: Boolean read FFixedHeader write SetFixedHeader default True;

    property IncrementalSearch: Boolean
      read FIncrementalSearch write FIncrementalSearch default True;

    property EditStyleName: string read FEditStyleName write SetEditStyleName;

    property HtmlMode;
    property TextAlign: TCssTextAlign
      read GetCssTextAlign write SetTextAlign default ctaLeft;
    property VerticalAlign: TCssVAlign
      read GetCssVAlign write SetVAlign default cvaMiddle;
    property CheckBoxCssClass: string read FCheckBoxCssClass write SetCheckBoxCssClass;
    property CheckBoxCssStyle: string read FCheckBoxCssStyle write SetCheckBoxCssStyle;

    property HeaderHAlign: TCssTreeHAlign
      read FHeaderHAlign write SetHeaderHAlign default thaInherit;

    property HeaderVAlign: TCssTreeVAlign
      read FHeaderVAlign write SetHeaderVAlign default tvaInherit;

    property CellHAlign: TCssTreeHAlign
      read FCellHAlign write SetCellHAlign default thaInherit;

    property CellVAlign: TCssTreeVAlign
      read FCellVAlign write SetCellVAlign default tvaInherit;

    property AllowColumnResize: Boolean
      read FAllowColumnResize write FAllowColumnResize default True;

    property ColumnResizeTolerance: Integer
      read FColumnResizeTolerance write FColumnResizeTolerance default 4;

    property MinColumnWidth: Integer
      read FMinColumnWidth write FMinColumnWidth default 12;

    property OnColumnResizing: TCssColumnResizeEvent
      read FOnColumnResizing write FOnColumnResizing;

    property OnColumnResized: TCssColumnResizeEvent
      read FOnColumnResized write FOnColumnResized;

    // Standard properties
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property TabStop;
    property Visible;

    property DragMode;
    property DragKind;

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

    // Tree events
    property OnGetNodeDataSize: TCssGetNodeDataSizeEvent
      read FOnGetNodeDataSize write FOnGetNodeDataSize;

    property OnInitNode: TCssInitNodeEvent
      read FOnInitNode write FOnInitNode;

    property OnFreeNode: TCssFreeNodeEvent
      read FOnFreeNode write FOnFreeNode;

    property OnGetText: TCssGetTextEvent
      read FOnGetText write FOnGetText;

    property OnNodeClick: TCssNodeClickEvent
      read FOnNodeClick write FOnNodeClick;

    property OnSelectionChanged: TNotifyEvent
      read FOnSelectionChanged write FOnSelectionChanged;

    property OnExpanding: TCssExpandingEvent
      read FOnExpanding write FOnExpanding;

    property OnExpanded: TCssNotifyNodeEvent
      read FOnExpanded write FOnExpanded;

    property OnCollapsing: TCssExpandingEvent
      read FOnCollapsing write FOnCollapsing;

    property OnCollapsed: TCssNotifyNodeEvent
      read FOnCollapsed write FOnCollapsed;

    property OnCheckedChanged: TCssNotifyNodeEvent
      read FOnCheckedChanged write FOnCheckedChanged;

    property OnEditing: TCssEditingEvent
      read FOnEditing write FOnEditing;

    property OnNewText: TCssNewTextEvent
      read FOnNewText write FOnNewText;

    property OnCompareNodes: TCssCompareEvent
      read FOnCompareNodes write FOnCompareNodes;

    property OnHeaderClick: TCssHeaderClickEvent
      read FOnHeaderClick write FOnHeaderClick;

    property OnDrawCell: TCssDrawCellEvent
      read FOnDrawCell write FOnDrawCell;

    property OnLoadChildren: TCssLoadChildrenEvent
      read FOnLoadChildren write FOnLoadChildren;

    property OnDragOverNodes: TCssDragNodesEvent
      read FOnDragOverNodes write FOnDragOverNodes;

    property OnDropNodes: TCssDropNodesEvent
      read FOnDropNodes write FOnDropNodes;

    property OnDropNodesEx: TCssDropNodesExEvent
      read FOnDropNodesEx write FOnDropNodesEx;
  end;

implementation

uses
  CssUtils;

{ Helper functions }

function VTreeIntersect(const A, B: TRect): TRect;
begin
  Result := A;

  if Result.Left < B.Left then
    Result.Left := B.Left;

  if Result.Top < B.Top then
    Result.Top := B.Top;

  if Result.Right > B.Right then
    Result.Right := B.Right;

  if Result.Bottom > B.Bottom then
    Result.Bottom := B.Bottom;

  if (Result.Right <= Result.Left) or (Result.Bottom <= Result.Top) then
    Result := Rect(0, 0, 0, 0);
end;

function ParseTreeHAlignCss(
  const AValue: string;
  out AAlign: TCssTreeHAlign): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AValue));

  Result := True;

  if (S = 'left') or (S = 'start') then
    AAlign := thaLeft
  else if S = 'center' then
    AAlign := thaCenter
  else if (S = 'right') or (S = 'end') then
    AAlign := thaRight
  else
    Result := False;
end;

function ParseTreeVAlignCss(
  const AValue: string;
  out AAlign: TCssTreeVAlign): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AValue));

  Result := True;

  if S = 'top' then
    AAlign := tvaTop
  else if (S = 'middle') or (S = 'center') then
    AAlign := tvaMiddle
  else if S = 'bottom' then
    AAlign := tvaBottom
  else
    Result := False;
end;

function CssVAlignToTextLayout(AValue: TCssVAlign): TTextLayout;
begin
  case AValue of
    cvaTop:
      Result := tlTop;

    cvaMiddle:
      Result := tlCenter;

    cvaBottom:
      Result := tlBottom;

  else
    Result := tlTop;
  end;
end;

{ TCssVirtualTreeDragObject }

constructor TCssVirtualTreeDragObject.Create(
  ATree: TCssVirtualStringTree;
  ANodes: TList
);
begin
  inherited Create(ATree);
  FTree := ATree;
  FNodes := ANodes;
end;

destructor TCssVirtualTreeDragObject.Destroy;
begin
  FreeAndNil(FNodes);
  inherited Destroy;
end;

{ TCssVirtualTreeColumn }

procedure TCssVirtualTreeColumn.SetText(const AValue: string);
begin
  if FText = AValue then
    Exit;

  FText := AValue;
  Changed(False);
end;

procedure TCssVirtualTreeColumn.SetWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FWidth = AValue then
    Exit;

  FWidth := AValue;
  Changed(False);
end;

procedure TCssVirtualTreeColumn.SetHeaderHAlign(AValue: TCssTreeHAlign);
begin
  if FHeaderHAlign = AValue then
    Exit;

  FHeaderHAlign := AValue;
  Changed(False);
end;

procedure TCssVirtualTreeColumn.SetHeaderVAlign(AValue: TCssTreeVAlign);
begin
  if FHeaderVAlign = AValue then
    Exit;

  FHeaderVAlign := AValue;
  Changed(False);
end;

procedure TCssVirtualTreeColumn.SetCellHAlign(AValue: TCssTreeHAlign);
begin
  if FCellHAlign = AValue then
    Exit;

  FCellHAlign := AValue;
  Changed(False);
end;

procedure TCssVirtualTreeColumn.SetCellVAlign(AValue: TCssTreeVAlign);
begin
  if FCellVAlign = AValue then
    Exit;

  FCellVAlign := AValue;
  Changed(False);
end;

{ TCssVirtualTreeColumns }

constructor TCssVirtualTreeColumns.Create(AOwner: TCssVirtualStringTree);
begin
  inherited Create(TCssVirtualTreeColumn);
  FOwner := AOwner;
end;

function TCssVirtualTreeColumns.Add: TCssVirtualTreeColumn;
begin
  Result := TCssVirtualTreeColumn(inherited Add);
  Result.Width := 100;
end;

function TCssVirtualTreeColumns.GetItem(Index: Integer): TCssVirtualTreeColumn;
begin
  Result := TCssVirtualTreeColumn(inherited GetItem(Index));
end;

procedure TCssVirtualTreeColumns.SetItem(
  Index: Integer;
  AValue: TCssVirtualTreeColumn
);
begin
  inherited SetItem(Index, AValue);
end;

procedure TCssVirtualTreeColumns.Update(Item: TCollectionItem);
begin
  inherited Update(Item);

  if Assigned(FOwner) and
     not (csLoading in FOwner.ComponentState) and
     not (csDestroying in FOwner.ComponentState) then
  begin
    FOwner.UpdateScrollBars;
    FOwner.Invalidate;
  end;
end;

{ TCssVirtualStringTree }

constructor TCssVirtualStringTree.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OnStartDrag := @InternalStartDrag;
  OnEndDrag := @InternalEndDrag;

  Caption := '';
  Width := 320;
  Height := 220;
  TabStop := True;

  SetVAlign(cvaMiddle);
  SetWordWrap(False);

  FRoot := TCssVirtualNode.Create;
  FVisibleNodes := TList.Create;
  FColumns := TCssVirtualTreeColumns.Create(Self);
  FSelectionList := TList.Create;

  FHeaderVisible := True;
  FHeaderHeight := 22;
  FIndent := 20;
  FItemHeight := 22;
  FScrollBarSize := 16;

  FTopNode := 0;
  FHorzOffset := 0;

  FMultiSelect := False;
  FShowCheckboxes := False;

  FAllowEditing := False;
  FAllowDrag := False;
  FAllowDrop := False;

  FLazyLoading := False;

  FAutoSort := False;
  SetLength(FSortColumns, 0);

  FFixedColumns := 0;
  FFixedHeader := True;

  FIncrementalSearch := True;
  FSearchText := '';
  FSearchTime := 0;

  FEditingNode := nil;
  FEditingColumn := -1;
  FEditClosing := False;
  FEditStyleName := '';

  FDragPending := False;
  FDragStartPoint := Point(0, 0);
  FDropTargetNode := nil;
  FLastMouse := Point(0, 0);

  FEdit := TCssEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Visible := False;
  FEdit.TabStop := False;
  FEdit.CssClass := 'css-tree-edit';
  FEdit.OnKeyDown := @EditKeyDown;
  FEdit.OnExit := @EditExit;

  FCheckBoxCssClass := 'css-tree-checkbox checkbox';
  FCheckBoxCssStyle := '';
  FCheckBoxInlineCss := '';

  FCheckBoxNormal := CreateCheckBoxHelper(False, False);
  FCheckBoxChecked := CreateCheckBoxHelper(True, False);
  FCheckBoxHover := CreateCheckBoxHelper(False, True);
  FCheckBoxCheckedHover := CreateCheckBoxHelper(True, True);

  FVScroll := TCssScrollBar.Create(Self);
  FVScroll.Kind := sbVertical;
  FVScroll.TabStop := False;
  FVScroll.Visible := False;
  FVScroll.CssClass := 'css-tree-scrollbar vscroll';
  FVScroll.OnChange := @DoVScroll;
  FVScroll.SetBounds(0, 0, 0, 0);

  FHScroll := TCssScrollBar.Create(Self);
  FHScroll.Kind := sbHorizontal;
  FHScroll.TabStop := False;
  FHScroll.Visible := False;
  FHScroll.CssClass := 'css-tree-scrollbar hscroll';
  FHScroll.OnChange := @DoHScroll;
  FHScroll.SetBounds(0, 0, 0, 0);

  DragMode := dmManual;
  DragKind := dkDrag;

  FVScrollRect := Rect(0, 0, 0, 0);
  FHScrollRect := Rect(0, 0, 0, 0);
  FScrollCapture := nil;

  FAllowColumnResize := True;
  FColumnResizeTolerance := 4;
  FMinColumnWidth := 12;

  FResizingColumn := -1;
  FResizeStartX := 0;
  FResizeStartWidth := 0;

  FAlwaysReserveScrollBar := True;
end;

destructor TCssVirtualStringTree.Destroy;
begin
  while FRoot.FirstChild <> nil do
    InternalDeleteNode(FRoot.FirstChild);

  FreeAndNil(FRoot);
  FreeAndNil(FVisibleNodes);
  FreeAndNil(FColumns);
  FreeAndNil(FSelectionList);

  inherited Destroy;
end;

// --- Update batching ---

procedure TCssVirtualStringTree.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCssVirtualStringTree.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if (FUpdateCount = 0) and FNeedRebuild then
  begin
    FNeedRebuild := False;
    RebuildVisible;
  end;
end;

// --- Column resize lookup ---

function TCssVirtualStringTree.GetHeaderResizeColumnAt(X: Integer): Integer;
var
  I: Integer;
  ColLeft, ColRight: Integer;
  Tol: Integer;
begin
  Result := -1;

  if not Assigned(FColumns) or (FColumns.Count = 0) then
    Exit;

  Tol := FColumnResizeTolerance;

  if Tol < 1 then
    Tol := 1;

  for I := 0 to FColumns.Count - 1 do
  begin
    // Do not allow resizing of fixed columns.
    if I < FFixedColumns then
      Continue;

    ColLeft := GetColumnLeft(I);
    ColRight := ColLeft + FColumns[I].Width;

    if Abs(X - ColRight) <= Tol then
      Exit(I);
  end;
end;

// --- Visible count / header / tree rect ---

function TCssVirtualStringTree.GetVisibleCount: Integer;
begin
  if Assigned(FVisibleNodes) then
    Result := FVisibleNodes.Count
  else
    Result := 0;
end;

function TCssVirtualStringTree.GetHeaderHeight: Integer;
begin
  if FHeaderVisible then
    Result := FHeaderHeight
  else
    Result := 0;
end;

function TCssVirtualStringTree.GetTreeRect: TRect;
begin
  Result := GetContentRect;
  Result.Top := Result.Top + GetHeaderHeight;

  if (FScrollBarSize > 0) and
     (FAlwaysReserveScrollBar or
      (Assigned(FVScroll) and FVScroll.Visible)) then
    Result.Right := Result.Right - FScrollBarSize;

  if (FScrollBarSize > 0) and
     (FAlwaysReserveScrollBar or
      (Assigned(FHScroll) and FHScroll.Visible)) then
    Result.Bottom := Result.Bottom - FScrollBarSize;

  if Result.Right < Result.Left then
    Result.Right := Result.Left;

  if Result.Bottom < Result.Top then
    Result.Bottom := Result.Top;
end;

function TCssVirtualStringTree.GetPageRows: Integer;
var
  R: TRect;
begin
  if FItemHeight <= 0 then
    Exit(1);

  R := GetTreeRect;
  Result := R.Height div FItemHeight;

  if Result < 1 then
    Result := 1;
end;

// --- Total width / height ---

function TCssVirtualStringTree.GetTotalWidth: Integer;
var
  I: Integer;
begin
  Result := 0;

  if not Assigned(FColumns) then
    Exit;

  for I := CssMax(0, FFixedColumns) to FColumns.Count - 1 do
    Inc(Result, FColumns[I].Width);
end;

function TCssVirtualStringTree.GetTotalHeight: Integer;
begin
  Result := VisibleCount * FItemHeight;
end;

// --- Fixed area and scroll area ---

function TCssVirtualStringTree.GetFixedWidth: Integer;
var
  I: Integer;
begin
  Result := 0;

  if not Assigned(FColumns) then
    Exit;

  for I := 0 to CssMin(FFixedColumns, FColumns.Count) - 1 do
    Inc(Result, FColumns[I].Width);
end;

function TCssVirtualStringTree.GetScrollAreaRect: TRect;
begin
  Result := GetTreeRect;
  Result.Left := Result.Left + GetFixedWidth;

  if Result.Right < Result.Left then
    Result.Right := Result.Left;
end;

function TCssVirtualStringTree.GetFixedAreaRect: TRect;
var
  R: TRect;
begin
  R := GetTreeRect;
  Result := R;
  Result.Right := R.Left + GetFixedWidth;

  if Result.Right > R.Right then
    Result.Right := R.Right;
end;

// --- Column geometry ---

function TCssVirtualStringTree.GetColumnWidth(Index: Integer): Integer;
begin
  if Assigned(FColumns) and (Index >= 0) and (Index < FColumns.Count) then
    Result := FColumns[Index].Width
  else
    Result := 0;
end;

function TCssVirtualStringTree.GetColumnLeft(Index: Integer): Integer;
var
  I: Integer;
  FixedW: Integer;
begin
  if not Assigned(FColumns) or (FColumns.Count = 0) then
  begin
    Result := GetTreeRect.Left - FHorzOffset;
    Exit;
  end;

  if Index < FFixedColumns then
  begin
    Result := GetTreeRect.Left;

    for I := 0 to Index - 1 do
      Inc(Result, FColumns[I].Width);
  end
  else
  begin
    FixedW := GetFixedWidth;
    Result := GetTreeRect.Left + FixedW - FHorzOffset;

    for I := FFixedColumns to Index - 1 do
      Inc(Result, FColumns[I].Width);
  end;
end;

// --- Node depth / subtree ---

function TCssVirtualStringTree.GetNodeDepth(Node: TCssVirtualNode): Integer;
begin
  Result := 0;

  if Node = nil then
    Exit;

  Node := Node.Parent;

  while (Node <> nil) and (Node <> FRoot) do
  begin
    Inc(Result);
    Node := Node.Parent;
  end;
end;

function TCssVirtualStringTree.IsNodeInSubTree(
  Node, SubRoot: TCssVirtualNode): Boolean;
begin
  Result := False;

  if (Node = nil) or (SubRoot = nil) then
    Exit;

  while Node <> nil do
  begin
    if Node = SubRoot then
      Exit(True);

    Node := Node.Parent;
  end;
end;

function TCssVirtualStringTree.IsNodeInSubTreeOfAny(
  Node: TCssVirtualNode;
  Nodes: TList): Boolean;
var
  I: Integer;
  Other: TCssVirtualNode;
begin
  Result := False;

  if Node = nil then
    Exit;

  for I := 0 to Nodes.Count - 1 do
  begin
    Other := TCssVirtualNode(Nodes[I]);

    if Other = Node then
      Continue;

    if IsNodeInSubTree(Node, Other) then
      Exit(True);
  end;
end;

// --- Property setters ---

procedure TCssVirtualStringTree.SetHeaderVisible(AValue: Boolean);
begin
  if FHeaderVisible = AValue then
    Exit;

  FHeaderVisible := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetHeaderHeight(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FHeaderHeight = AValue then
    Exit;

  FHeaderHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetIndent(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FIndent = AValue then
    Exit;

  FIndent := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetItemHeight(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  if FItemHeight = AValue then
    Exit;

  FItemHeight := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetScrollBarSize(AValue: Integer);
begin
  if AValue < 8 then
    AValue := 8;

  if FScrollBarSize = AValue then
    Exit;

  FScrollBarSize := AValue;
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetFixedColumns(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FFixedColumns = AValue then
    Exit;

  FFixedColumns := AValue;

  SetHorzOffset(FHorzOffset);
  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetFixedHeader(AValue: Boolean);
begin
  if FFixedHeader = AValue then
    Exit;

  FFixedHeader := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetEditStyleName(const AValue: string);
begin
  if FEditStyleName = AValue then
    Exit;

  FEditStyleName := AValue;

  if Assigned(FEdit) and (AValue <> '') then
    FEdit.StyleName := AValue;
end;

procedure TCssVirtualStringTree.SetColumns(AValue: TCssVirtualTreeColumns);
begin
  FResizingColumn := -1;

  if AValue = nil then
    FColumns.Clear
  else
    FColumns.Assign(AValue);
end;

procedure TCssVirtualStringTree.SetNodeDataSize(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;

  if FNodeDataSize = AValue then
    Exit;

  FNodeDataSize := AValue;
end;

procedure TCssVirtualStringTree.SetTopNode(AValue: Integer);
var
  MaxTop: Integer;
begin
  if AValue < 0 then
    AValue := 0;

  MaxTop := CssMax(0, VisibleCount - GetPageRows);

  if AValue > MaxTop then
    AValue := MaxTop;

  if FTopNode = AValue then
    Exit;

  FTopNode := AValue;

  if not FUpdatingScroll and Assigned(FVScroll) then
  begin
    FUpdatingScroll := True;
    try
      FVScroll.Position := FTopNode;
    finally
      FUpdatingScroll := False;
    end;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.SetHorzOffset(AValue: Integer);
var
  ScrollW: Integer;
  MaxOffset: Integer;
begin
  ScrollW := GetScrollAreaRect.Width;

  if ScrollW <= 0 then
    MaxOffset := 0
  else
    MaxOffset := CssMax(0, GetTotalWidth - ScrollW);

  if AValue < 0 then
    AValue := 0;

  if AValue > MaxOffset then
    AValue := MaxOffset;

  if FHorzOffset = AValue then
    Exit;

  FHorzOffset := AValue;

  if not FUpdatingScroll and Assigned(FHScroll) then
  begin
    FUpdatingScroll := True;
    try
      FHScroll.Position := FHorzOffset;
    finally
      FUpdatingScroll := False;
    end;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.SetSelectedNode(AValue: TCssVirtualNode);
begin
  if (AValue <> nil) and IsNodeDisabled(AValue) then
    Exit;

  if FSelectedNode = AValue then
    Exit;

  InternalClearSelection(False);

  FSelectedNode := AValue;
  FAnchorNode := AValue;

  if AValue <> nil then
    InternalAddToSelection(AValue, False);

  SelectionChanged;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetAlwaysReserveScrollBar(AValue: Boolean);
begin
  if FAlwaysReserveScrollBar = AValue then
    Exit;

  FAlwaysReserveScrollBar := AValue;

  UpdateScrollBars;
  Invalidate;
end;

// --- Scrollbar notifications ---

procedure TCssVirtualStringTree.DoVScroll(Sender: TObject);
begin
  if FUpdatingScroll then
    Exit;

  EndEditing(True);
  SetTopNode(FVScroll.Position);
end;

procedure TCssVirtualStringTree.DoHScroll(Sender: TObject);
begin
  if FUpdatingScroll then
    Exit;

  EndEditing(True);
  SetHorzOffset(FHScroll.Position);
end;

// --- Scrollbar layout ---

procedure TCssVirtualStringTree.UpdateScrollBars;
var
  ContentR: TRect;
  HeaderH: Integer;
  TreeH, TreeW: Integer;
  FixedW, ScrollW: Integer;
  TotalH, TotalW: Integer;
  PageRows: Integer;
  VVis, HVis: Boolean;
  Radius: Integer;
  VTopGap, VBottomGap: Integer;
  HLeftGap, HRightGap: Integer;
  VHeight, HWidth: Integer;
begin
  if not Assigned(FVScroll) or not Assigned(FHScroll) then
    Exit;

  if not Assigned(FVisibleNodes) then
    Exit;

  ContentR := GetContentRect;
  HeaderH := GetHeaderHeight;

  TreeH := ContentR.Height - HeaderH;
  if TreeH < 0 then
    TreeH := 0;

  TreeW := ContentR.Width;

  FixedW := GetFixedWidth;
  if FixedW > TreeW then
    FixedW := TreeW;

  ScrollW := TreeW - FixedW;
  if ScrollW < 0 then
    ScrollW := 0;

  TotalH := GetTotalHeight;
  TotalW := GetTotalWidth;

  VVis := TotalH > TreeH;

  if VVis then
    ScrollW := ScrollW - FScrollBarSize;

  HVis := (TotalW > 0) and (TotalW > ScrollW);

  if HVis then
  begin
    TreeH := TreeH - FScrollBarSize;
    if TreeH < 0 then
      TreeH := 0;

    VVis := TotalH > TreeH;

    ScrollW := TreeW - FixedW;
    if VVis then
      ScrollW := ScrollW - FScrollBarSize;
  end;

  if ScrollW < 0 then
    ScrollW := 0;

  Radius := GetCssBorderRadius;

  VTopGap := 0;
  VBottomGap := 0;

  if VVis then
  begin
    // If there is no header, the vertical scrollbar may poke into the
    // top-right corner.
    if HeaderH = 0 then
      VTopGap := Radius;

    // If there is no horizontal scrollbar, the vertical one reaches the
    // bottom corner.
    if not HVis then
      VBottomGap := Radius
    else if FScrollBarSize < Radius then
      VBottomGap := Radius - FScrollBarSize;

    if VTopGap < 0 then
      VTopGap := 0;

    if VBottomGap < 0 then
      VBottomGap := 0;
  end;

  HLeftGap := 0;
  HRightGap := 0;

  if HVis then
  begin
    // If there are no fixed columns, the horizontal scrollbar may poke into
    // the bottom-left corner.
    if FixedW = 0 then
      HLeftGap := Radius;

    // If there is no vertical scrollbar, the horizontal one reaches the
    // right corner.
    if not VVis then
      HRightGap := Radius
    else if FScrollBarSize < Radius then
      HRightGap := Radius - FScrollBarSize;

    if HLeftGap < 0 then
      HLeftGap := 0;

    if HRightGap < 0 then
      HRightGap := 0;
  end;

  if VVis then
  begin
    VHeight := TreeH - VTopGap - VBottomGap;

    if VHeight < 1 then
      VHeight := 1;

    FVScrollRect := Rect(
      ContentR.Right - FScrollBarSize,
      ContentR.Top + HeaderH + VTopGap,
      ContentR.Right,
      ContentR.Top + HeaderH + VTopGap + VHeight
    );

    // Hidden state object. Use its dimensions for calculations.
    FVScroll.SetBounds(0, 0, FScrollBarSize, VHeight);
  end
  else
  begin
    FVScrollRect := Rect(0, 0, 0, 0);
    FVScroll.SetBounds(0, 0, 0, 0);
  end;

  FVScroll.Visible := VVis;

  if HVis then
  begin
    HWidth := ScrollW - HLeftGap - HRightGap;

    if HWidth < 1 then
      HWidth := 1;

    FHScrollRect := Rect(
      ContentR.Left + FixedW + HLeftGap,
      ContentR.Bottom - FScrollBarSize,
      ContentR.Left + FixedW + HLeftGap + HWidth,
      ContentR.Bottom
    );

    // Hidden state object. Use its dimensions for calculations.
    FHScroll.SetBounds(0, 0, HWidth, FScrollBarSize);
  end
  else
  begin
    FHScrollRect := Rect(0, 0, 0, 0);
    FHScroll.SetBounds(0, 0, 0, 0);
  end;

  FHScroll.Visible := HVis;

  PageRows := 1;
  if (TreeH > 0) and (FItemHeight > 0) then
    PageRows := TreeH div FItemHeight;

  if PageRows < 1 then
    PageRows := 1;

  FUpdatingScroll := True;
  try
    FVScroll.Min := 0;
    FVScroll.PageSize := PageRows;
    FVScroll.LargeChange := PageRows;
    FVScroll.SmallChange := 1;
    FVScroll.Max := CssMax(0, VisibleCount - PageRows);
    FVScroll.Position := FTopNode;
    FVScroll.Enabled := VisibleCount > PageRows;

    FHScroll.Min := 0;
    FHScroll.PageSize := CssMax(0, ScrollW);
    FHScroll.LargeChange := CssMax(1, ScrollW);
    FHScroll.SmallChange := FItemHeight;
    FHScroll.Max := CssMax(0, TotalW - ScrollW);
    FHScroll.Position := FHorzOffset;
    FHScroll.Enabled := (TotalW > 0) and (TotalW > ScrollW);
  finally
    FUpdatingScroll := False;
  end;
end;

// --- Visible list building ---

procedure TCssVirtualStringTree.BuildVisibleList;

  procedure AddChildren(Parent: TCssVirtualNode);
  var
    Child: TCssVirtualNode;
  begin
    Child := Parent.FirstChild;

    while Child <> nil do
    begin
      Child.AbsoluteIndex := FVisibleNodes.Add(Child);

      if (cvsExpanded in Child.States) and (Child.ChildCount > 0) then
        AddChildren(Child);

      Child := Child.NextSibling;
    end;
  end;

begin
  FVisibleNodes.Clear;
  AddChildren(FRoot);
end;

procedure TCssVirtualStringTree.NeedRebuild;
begin
  if FUpdateCount > 0 then
    FNeedRebuild := True
  else
    RebuildVisible;
end;

procedure TCssVirtualStringTree.RebuildVisible;
var
  PageRows, MaxTop: Integer;
begin
  if not Assigned(FVisibleNodes) then
    Exit;

  if FUpdateCount > 0 then
  begin
    FNeedRebuild := True;
    Exit;
  end;

  BuildVisibleList;
  UpdateScrollBars;

  PageRows := GetPageRows;
  MaxTop := CssMax(0, VisibleCount - PageRows);

  if FTopNode > MaxTop then
  begin
    FTopNode := MaxTop;

    FUpdatingScroll := True;
    try
      if Assigned(FVScroll) then
        FVScroll.Position := FTopNode;
    finally
      FUpdatingScroll := False;
    end;
  end;

  Invalidate;
end;

function TCssVirtualStringTree.GetVisibleNode(Index: Integer): TCssVirtualNode;
begin
  if Assigned(FVisibleNodes) and (Index >= 0) and (Index < FVisibleNodes.Count) then
    Result := TCssVirtualNode(FVisibleNodes[Index])
  else
    Result := nil;
end;

// --- Node deletion / data ---

procedure TCssVirtualStringTree.InternalDeleteNode(Node: TCssVirtualNode);
var
  Child, Next: TCssVirtualNode;
begin
  if Node = nil then
    Exit;

  Child := Node.FirstChild;

  while Child <> nil do
  begin
    Next := Child.NextSibling;
    InternalDeleteNode(Child);
    Child := Next;
  end;

  DoFreeNode(Node);

  if Assigned(Node.Data) then
    FreeMem(Node.Data);

  if Node.Parent <> nil then
  begin
    if Node.PrevSibling <> nil then
      Node.PrevSibling.NextSibling := Node.NextSibling
    else
      Node.Parent.FirstChild := Node.NextSibling;

    if Node.NextSibling <> nil then
      Node.NextSibling.PrevSibling := Node.PrevSibling
    else
      Node.Parent.LastChild := Node.PrevSibling;

    Dec(Node.Parent.ChildCount);

    if Node.Parent.ChildCount = 0 then
    begin
      Exclude(Node.Parent.States, cvsHasChildren);
      Exclude(Node.Parent.States, cvsExpanded);
    end;
  end;

  if Assigned(FSelectionList) then
    FSelectionList.Remove(Node);

  if FSelectedNode = Node then
    FSelectedNode := nil;

  if FHoverNode = Node then
    FHoverNode := nil;

  if FAnchorNode = Node then
    FAnchorNode := nil;

  if FDropTargetNode = Node then
    FDropTargetNode := nil;

  if FEditingNode = Node then
  begin
    FEditingNode := nil;
    FEditingColumn := -1;

    if Assigned(FEdit) then
      FEdit.Visible := False;
  end;

  Node.Free;
end;

procedure TCssVirtualStringTree.EnsureNodeDataSize;
begin
  if Assigned(FOnGetNodeDataSize) then
    FOnGetNodeDataSize(Self, FNodeDataSize);

  if FNodeDataSize < 0 then
    FNodeDataSize := 0;
end;

procedure TCssVirtualStringTree.DoInitNode(Node: TCssVirtualNode);
begin
  if Assigned(FOnInitNode) then
    FOnInitNode(Self, Node);
end;

procedure TCssVirtualStringTree.DoFreeNode(Node: TCssVirtualNode);
begin
  if Assigned(FOnFreeNode) and not (csDestroying in ComponentState) then
    FOnFreeNode(Self, Node);
end;

procedure TCssVirtualStringTree.DoGetText(
  Node: TCssVirtualNode;
  Column: Integer;
  var AText: string);
begin
  AText := '';

  if Assigned(FOnGetText) then
    FOnGetText(Self, Node, Column, vttNormal, AText);
end;

procedure TCssVirtualStringTree.DoLoadChildren(Node: TCssVirtualNode);
begin
  if Assigned(FOnLoadChildren) then
    FOnLoadChildren(Self, Node);

  Include(Node.States, cvsChildrenLoaded);

  // If children were just loaded, keep auto-sort up to date.
  AutoSortNode(Node, False);
end;

procedure TCssVirtualStringTree.EnsureChildrenLoaded(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  if not FLazyLoading then
    Exit;

  if not (cvsHasChildren in Node.States) then
    Exit;

  if Node.ChildCount > 0 then
    Exit;

  if cvsChildrenLoaded in Node.States then
    Exit;

  BeginUpdate;
  try
    DoLoadChildren(Node);
  finally
    EndUpdate;
  end;
end;

// --- CSS color getters ---

function TCssVirtualStringTree.GetHeaderBackground: TColor;
begin
  if FHeaderBackgroundSet then
    Exit(FHeaderBackground);

  Result := GetCssBackgroundColor;

  if Result = clNone then
    Result := clBtnFace;

  if Result = clDefault then
    Result := clBtnFace;
end;

function TCssVirtualStringTree.GetHeaderTextColor: TColor;
begin
  if FHeaderColorSet then
    Exit(FHeaderColor);

  Result := GetCssTextColor;

  if Result = clDefault then
    Result := clWindowText;
end;

function TCssVirtualStringTree.GetSelectionBackground: TColor;
begin
  if FSelectionBackgroundSet then
    Exit(FSelectionBackground);

  Result := RGBToColor(51, 153, 255);
end;

function TCssVirtualStringTree.GetSelectionColor: TColor;
begin
  if FSelectionColorSet then
    Exit(FSelectionColor);

  Result := RGBToColor(255, 255, 255);
end;

function TCssVirtualStringTree.GetHoverBackground: TColor;
begin
  if FHoverBackgroundSet then
    Exit(FHoverBackground);

  Result := RGBToColor(229, 243, 255);
end;

function TCssVirtualStringTree.GetLineColor: TColor;
begin
  if FLineColorSet then
    Exit(FLineColor);

  Result := RGBToColor(215, 215, 215);
end;

function TCssVirtualStringTree.GetButtonColor: TColor;
begin
  if FButtonColorSet then
    Exit(FButtonColor);

  Result := GetCssTextColor;

  if Result = clDefault then
    Result := clWindowText;
end;

function TCssVirtualStringTree.GetCheckColor: TColor;
begin
  if FCheckColorSet then
    Exit(FCheckColor);

  Result := RGBToColor(30, 120, 30);
end;

function TCssVirtualStringTree.GetDropTargetBackground: TColor;
begin
  if FDropTargetBackgroundSet then
    Exit(FDropTargetBackground);

  Result := RGBToColor(200, 235, 200);
end;

function TCssVirtualStringTree.GetSortMarkerColor: TColor;
begin
  if FSortMarkerColorSet then
    Exit(FSortMarkerColor);

  Result := GetCssTextColor;

  if Result = clDefault then
    Result := clWindowText;
end;

function TCssVirtualStringTree.GetDisabledBackground: TColor;
begin
  if FDisabledBackgroundSet then
    Result := FDisabledBackground
  else
    Result := RGBToColor(240, 240, 240);
end;

function TCssVirtualStringTree.GetDisabledColor: TColor;
begin
  if FDisabledColorSet then
    Result := FDisabledColor
  else
    Result := RGBToColor(160, 160, 160);
end;

// --- Header drawing ---

procedure TCssVirtualStringTree.DrawHeader(const R: TRect);
var
  SavedClip: TRect;
  FixedR, ScrollR: TRect;
  I: Integer;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  FixedR := GetFixedAreaRect;
  FixedR.Top := R.Top;
  FixedR.Bottom := R.Bottom;

  ScrollR := GetScrollAreaRect;
  ScrollR.Top := R.Top;
  ScrollR.Bottom := R.Bottom;

  SavedClip := Canvas.ClipRect;
  Canvas.ClipRect := R;
  try
    UpdateCanvasFont;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetHeaderBackground;
    Canvas.FillRect(R);

    Canvas.Pen.Width := 1;
    Canvas.Pen.Color := GetLineColor;

    Canvas.MoveTo(R.Left, R.Bottom - 1);
    Canvas.LineTo(R.Right, R.Bottom - 1);
  finally
    Canvas.ClipRect := SavedClip;
  end;

  Canvas.Font.Color := GetHeaderTextColor;
  Canvas.Brush.Style := bsClear;

  if ScrollR.Right > ScrollR.Left then
  begin
    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := ScrollR;
    try
      for I := CssMax(0, FFixedColumns) to FColumns.Count - 1 do
        DrawHeaderCell(I, R);
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;

  if FixedR.Right > FixedR.Left then
  begin
    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := FixedR;
    try
      for I := 0 to CssMin(FFixedColumns, FColumns.Count) - 1 do
        DrawHeaderCell(I, R);

      Canvas.Pen.Color := GetLineColor;
      Canvas.Pen.Width := 1;

      Canvas.MoveTo(FixedR.Right - 1, FixedR.Top);
      Canvas.LineTo(FixedR.Right - 1, FixedR.Bottom);
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;

  DrawSortMarkers(R);
end;

procedure TCssVirtualStringTree.DrawHeaderCell(
  Index: Integer;
  const HeaderR: TRect
);
var
  X, W, TextX, TextW: Integer;
  CellR: TRect;
  ContentR: TRect;
  S: string;
  TS: TTextStyle;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
begin
  if (Index < 0) or (Index >= FColumns.Count) then
    Exit;

  X := GetColumnLeft(Index);
  W := FColumns[Index].Width;

  CellR := Rect(
    X,
    HeaderR.Top,
    X + W,
    HeaderR.Bottom
  );

  if CellR.Right <= CellR.Left then
    Exit;

  Canvas.Pen.Color := GetLineColor;
  Canvas.Pen.Width := 1;

  Canvas.MoveTo(CellR.Right - 1, HeaderR.Top + 3);
  Canvas.LineTo(CellR.Right - 1, HeaderR.Bottom - 3);

  S := FColumns[Index].Text;

  HAlign := ResolveHeaderHAlign(Index);
  VAlign := ResolveHeaderVAlign(Index);

  if HtmlMode then
  begin
    ContentR := CellR;

    ContentR.Left := ContentR.Left + 4;
    ContentR.Right := ContentR.Right - 4;

    if ContentR.Right > ContentR.Left then
    begin
      DrawHtmlTextWithAlign(
        Canvas,
        ContentR,
        S,
        HAlign,
        VAlign,
        GetHeaderTextColor
      );
    end;

    Exit;
  end;

  TextW := Canvas.TextWidth(S);

  case HAlign of
    ctaCenter:
      TextX := CellR.Left + CssMax(0, (CellR.Width - TextW) div 2);

    ctaRight:
      TextX := CellR.Right - TextW - 4;

  else
    TextX := CellR.Left + 4;
  end;

  TS := Canvas.TextStyle;
  TS.Alignment := taLeftJustify;
  TS.Layout := CssVAlignToTextLayout(VAlign);
  TS.Wordbreak := False;
  TS.Clipping := True;
  TS.Opaque := False;
  TS.ShowPrefix := False;

  Canvas.TextRect(CellR, TextX, HeaderR.Top, S, TS);
end;

procedure TCssVirtualStringTree.DrawSortMarkers(const HeaderR: TRect);
var
  I, Col, X, W, CY: Integer;
  CellR, ClipR, SavedClip: TRect;
begin
  for I := 0 to High(FSortColumns) do
  begin
    Col := FSortColumns[I].Column;

    if (Col < 0) or (Col >= FColumns.Count) then
      Continue;

    if FSortColumns[I].Direction = csdNone then
      Continue;

    X := GetColumnLeft(Col);
    W := GetColumnWidth(Col);

    CellR := Rect(
      X,
      HeaderR.Top,
      X + W,
      HeaderR.Bottom
    );

    if Col < FFixedColumns then
      ClipR := GetFixedAreaRect
    else
      ClipR := GetScrollAreaRect;

    ClipR.Top := HeaderR.Top;
    ClipR.Bottom := HeaderR.Bottom;

    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := ClipR;
    try
      CY := (HeaderR.Top + HeaderR.Bottom) div 2;

      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := GetSortMarkerColor;
      Canvas.Pen.Style := psSolid;
      Canvas.Pen.Color := GetSortMarkerColor;
      Canvas.Pen.Width := 1;

      if FSortColumns[I].Direction = csdAscending then
      begin
        Canvas.Polygon([
          Point(CellR.Right - 12, CY + 3),
          Point(CellR.Right - 8, CY - 3),
          Point(CellR.Right - 4, CY + 3)
        ]);
      end
      else
      begin
        Canvas.Polygon([
          Point(CellR.Right - 12, CY - 3),
          Point(CellR.Right - 8, CY + 3),
          Point(CellR.Right - 4, CY - 3)
        ]);
      end;

      if Length(FSortColumns) > 1 then
      begin
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Color := GetSortMarkerColor;
        Canvas.TextOut(
          CellR.Right - 24,
          HeaderR.Top + 2,
          IntToStr(I + 1)
        );
      end;
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;
end;

// --- Node row drawing ---

procedure TCssVirtualStringTree.DrawNodeRow(
  Node: TCssVirtualNode;
  RowIndex: Integer;
  const TreeR: TRect
);
var
  RowR: TRect;
  ScrollR, FixedR, SavedClip: TRect;
  I: Integer;
  IsSelectedRow: Boolean;
  IsHover: Boolean;
  IsDropTarget: Boolean;
  IsDisabled: Boolean;
  S: string;
  TextColor: TColor;
  ContentR: TRect;
  TS: TTextStyle;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
  TextW, TextH: Integer;
  X, Y: Integer;
  ContentW, RowH: Integer;
begin
  if Node = nil then
    Exit;

  RowR := Rect(
    TreeR.Left,
    TreeR.Top + (RowIndex - FTopNode) * FItemHeight,
    TreeR.Right,
    TreeR.Top + (RowIndex - FTopNode + 1) * FItemHeight
  );

  if RowR.Bottom <= TreeR.Top then
    Exit;

  if RowR.Top >= TreeR.Bottom then
    Exit;

  IsDisabled := IsNodeDisabled(Node);

  // A disabled node must not appear selected, hovered, or be a drop target.
  IsSelectedRow :=
    (IsSelected(Node) or (Node = FSelectedNode)) and
    (not IsDisabled);

  IsHover :=
    (Node = FHoverNode) and
    (not IsDisabled);

  IsDropTarget :=
    (Node = FDropTargetNode) and
    (not IsDisabled);

  if IsDisabled and FDisabledBackgroundSet then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetDisabledBackground;
    Canvas.FillRect(RowR);
  end
  else if IsDropTarget then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetDropTargetBackground;
    Canvas.FillRect(RowR);
  end
  else if IsSelectedRow then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetSelectionBackground;
    Canvas.FillRect(RowR);
  end
  else if IsHover then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := GetHoverBackground;
    Canvas.FillRect(RowR);
  end;

  // Branch with no columns.
  if FColumns.Count = 0 then
  begin
    S := GetCellText(Node, 0);

    TextColor := GetCssTextColor;

    if IsDisabled then
      TextColor := GetDisabledColor
    else if IsSelectedRow and FSelectionColorSet then
      TextColor := GetSelectionColor;

    ContentR := RowR;
    ContentR.Left := GetTextStartX(Node, RowR);

    if ContentR.Right <= ContentR.Left then
      Exit;

    HAlign := ResolveCellHAlign(Node, 0);
    VAlign := ResolveCellVAlign(Node, 0);

    if HtmlMode then
    begin
      DrawHtmlTextWithAlign(
        Canvas,
        ContentR,
        S,
        HAlign,
        VAlign,
        TextColor
      );
    end
    else
    begin
      UpdateCanvasFont;

      Canvas.Font.Color := TextColor;
      Canvas.Brush.Style := bsClear;

      TextW := Canvas.TextWidth(S);
      ContentW := ContentR.Right - ContentR.Left;

      case HAlign of
        ctaCenter:
          X := ContentR.Left + CssMax(0, (ContentW - TextW) div 2);

        ctaRight:
          X := ContentR.Right - TextW - 3;

      else
        X := ContentR.Left + 3;
      end;

      if X < ContentR.Left then
        X := ContentR.Left;

      RowH := RowR.Bottom - RowR.Top;
      TextH := Canvas.TextHeight('Ag');

      if TextH >= RowH then
        Y := RowR.Top
      else
      begin
        case VAlign of
          cvaTop:
            Y := RowR.Top + 1;

          cvaMiddle:
            Y := RowR.Top + ((RowH - TextH) div 2);

          cvaBottom:
            Y := RowR.Bottom - TextH - 1;

        else
          Y := RowR.Top;
        end;
      end;

      TS := Canvas.TextStyle;
      TS.Alignment := taLeftJustify;

      // Vertical position already computed manually via Y.
      TS.Layout := tlTop;

      TS.Wordbreak := False;
      TS.Clipping := True;
      TS.Opaque := False;
      TS.ShowPrefix := False;

      Canvas.TextRect(ContentR, X, Y, S, TS);
    end;

    Exit;
  end;

  ScrollR := GetScrollAreaRect;
  ScrollR.Top := RowR.Top;
  ScrollR.Bottom := RowR.Bottom;

  FixedR := GetFixedAreaRect;
  FixedR.Top := RowR.Top;
  FixedR.Bottom := RowR.Bottom;

  if ScrollR.Right > ScrollR.Left then
  begin
    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := ScrollR;
    try
      if FFixedColumns <= 0 then
      begin
        if FShowCheckboxes then
          DrawCheckBox(Node, RowR);

        DrawButton(Node, RowR);
      end;

      for I := CssMax(0, FFixedColumns) to FColumns.Count - 1 do
        DrawCellContent(Node, I, RowR, IsSelectedRow);
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;

  if (FFixedColumns > 0) and (FixedR.Right > FixedR.Left) then
  begin
    SavedClip := Canvas.ClipRect;
    Canvas.ClipRect := FixedR;
    try
      if FShowCheckboxes then
        DrawCheckBox(Node, RowR);

      DrawButton(Node, RowR);

      for I := 0 to CssMin(FFixedColumns, FColumns.Count) - 1 do
        DrawCellContent(Node, I, RowR, IsSelectedRow);

      Canvas.Pen.Color := GetLineColor;
      Canvas.Pen.Width := 1;

      Canvas.MoveTo(FixedR.Right - 1, RowR.Top);
      Canvas.LineTo(FixedR.Right - 1, RowR.Bottom);
    finally
      Canvas.ClipRect := SavedClip;
    end;
  end;

  if FLineColorSet then
  begin
    Canvas.Pen.Color := GetLineColor;
    Canvas.Pen.Width := 1;

    Canvas.MoveTo(TreeR.Left, RowR.Bottom - 1);
    Canvas.LineTo(TreeR.Right, RowR.Bottom - 1);
  end;
end;

procedure TCssVirtualStringTree.DrawCellContent(
  Node: TCssVirtualNode;
  Column: Integer;
  const RowR: TRect;
  IsSelected: Boolean
);
var
  CellR: TRect;
  ClipR: TRect;
  ContentR: TRect;
  S: string;
  Handled: Boolean;
  TextColor: TColor;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
  IsDisabled: Boolean;
begin
  if (Column < 0) or (Column >= FColumns.Count) then
    Exit;

  CellR := Rect(
    GetColumnLeft(Column),
    RowR.Top,
    GetColumnLeft(Column) + FColumns[Column].Width,
    RowR.Bottom
  );

  if CellR.Right <= CellR.Left then
    Exit;

  // Rectangle where cell content is actually allowed to be drawn.
  // For the scrollable part, for example, it will be clipped to the area
  // before the vertical scrollbar.
  ClipR := GetColumnClipRect(Column, RowR);

  Handled := False;

  if Assigned(FOnDrawCell) then
    FOnDrawCell(Self, Node, Column, CellR, Handled);

  if Handled then
    Exit;

  S := GetCellText(Node, Column);

  IsDisabled := IsNodeDisabled(Node);

  TextColor := GetCssTextColor;

  if IsDisabled then
    TextColor := GetDisabledColor
  else if IsSelected and FSelectionColorSet then
    TextColor := GetSelectionColor;

  HAlign := ResolveCellHAlign(Node, Column);
  VAlign := ResolveCellVAlign(Node, Column);

  if HtmlMode then
  begin
    ContentR := CellR;

    if Column = 0 then
      ContentR.Left := GetTextStartX(Node, RowR);

    // Clip the text area to the actual clip rect.
    ContentR := VTreeIntersect(ContentR, ClipR);

    if (ContentR.Right > ContentR.Left) and
       (ContentR.Bottom > ContentR.Top) then
    begin
      DrawHtmlTextWithAlign(
        Canvas,
        ContentR,
        S,
        HAlign,
        VAlign,
        TextColor
      );
    end;
  end
  else
  begin
    DrawCellText(
      Node,
      Column,
      CellR,
      S,
      TextColor,
      ClipR
    );
  end;

  if FLineColorSet then
  begin
    // Draw the vertical separator only if it actually falls
    // within the visible/allowed area.
    if (CellR.Right - 1 >= ClipR.Left) and
       (CellR.Right - 1 < ClipR.Right) then
    begin
      Canvas.Pen.Color := GetLineColor;
      Canvas.Pen.Width := 1;

      Canvas.MoveTo(CellR.Right - 1, RowR.Top + 2);
      Canvas.LineTo(CellR.Right - 1, RowR.Bottom - 2);
    end;
  end;
end;

procedure TCssVirtualStringTree.DrawCellText(
  Node: TCssVirtualNode;
  Column: Integer;
  const CellR: TRect;
  const S: string;
  TextColor: TColor;
  const ClipR: TRect
);
var
  ContentR: TRect;
  DrawR: TRect;
  TS: TTextStyle;
  TextW, TextH: Integer;
  X, Y: Integer;
  HAlign: TCssTextAlign;
  VAlign: TCssVAlign;
begin
  if S = '' then
    Exit;

  ContentR := CellR;

  if Column = 0 then
    ContentR.Left := GetTextStartX(Node, CellR);

  DrawR := VTreeIntersect(ContentR, ClipR);

  if (DrawR.Right <= DrawR.Left) or (DrawR.Bottom <= DrawR.Top) then
    Exit;

  UpdateCanvasFont;

  Canvas.Font.Color := TextColor;
  Canvas.Brush.Style := bsClear;

  // If you have added per-cell alignment support,
  // use the resolve functions.
  // If not yet, you can temporarily use:
  //   HAlign := GetCssTextAlign;
  //   VAlign := cvaMiddle;
  HAlign := ResolveCellHAlign(Node, Column);
  VAlign := ResolveCellVAlign(Node, Column);

  TextW := Canvas.TextWidth(S);

  case HAlign of
    ctaCenter:
      X := ContentR.Left + CssMax(0, (ContentR.Width - TextW) div 2);

    ctaRight:
      X := ContentR.Right - TextW - 3;

  else
    X := ContentR.Left + 3;
  end;

  // Important: do not align X by DrawR, otherwise the text will "jump"
  // during horizontal scrolling.
  if X < ContentR.Left then
    X := ContentR.Left;

  TextH := Canvas.TextHeight('Ag');

  if TextH > DrawR.Height then
    Y := DrawR.Top
  else
  begin
    case VAlign of
      cvaTop:
        Y := DrawR.Top + 1;

      cvaMiddle:
        Y := DrawR.Top + ((DrawR.Height - TextH) div 2);

      cvaBottom:
        Y := DrawR.Bottom - TextH - 1;

    else
      Y := DrawR.Top;
    end;
  end;

  TS := Canvas.TextStyle;
  TS.Alignment := taLeftJustify;

  // Vertical alignment has already been computed manually via Y,
  // so we keep tlTop.
  TS.Layout := tlTop;

  TS.Wordbreak := False;
  TS.Clipping := True;
  TS.Opaque := False;
  TS.ShowPrefix := False;

  Canvas.TextRect(DrawR, X, Y, S, TS);
end;

// --- Button and checkbox drawing ---

procedure TCssVirtualStringTree.DrawButton(
  Node: TCssVirtualNode;
  const RowR: TRect);
var
  R: TRect;
  MidY: Integer;
begin
  if Node = nil then
    Exit;

  if not (cvsHasChildren in Node.States) then
    Exit;

  R := GetButtonRect(Node, RowR);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  Canvas.Pen.Width := 1;
  if IsNodeDisabled(Node) then
    Canvas.Pen.Color := GetDisabledColor
  else
    Canvas.Pen.Color := GetButtonColor;
  Canvas.Brush.Style := bsClear;

  Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

  MidY := (R.Top + R.Bottom) div 2;

  Canvas.MoveTo(R.Left + 2, MidY);
  Canvas.LineTo(R.Right - 2, MidY);

  if not (cvsExpanded in Node.States) then
  begin
    Canvas.MoveTo((R.Left + R.Right) div 2, R.Top + 2);
    Canvas.LineTo((R.Left + R.Right) div 2, R.Bottom - 2);
  end;
end;

procedure TCssVirtualStringTree.DrawCheckBox(
  Node: TCssVirtualNode;
  const RowR: TRect);
var
  R: TRect;
  Helper: TCssCheckBox;
  LIsChecked: Boolean;
  IsHover: Boolean;
begin
  if Node = nil then
    Exit;

  if not FShowCheckboxes then
    Exit;

  R := GetCheckRect(Node, RowR);

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  LIsChecked := cvsChecked in Node.States;

  IsHover :=
    Enabled and
    (FHoverNode = Node) and
    PtInRect(R, FLastMouse);

  if LIsChecked then
  begin
    if IsHover and Assigned(FCheckBoxCheckedHover) then
      Helper := FCheckBoxCheckedHover
    else
      Helper := FCheckBoxChecked;
  end
  else
  begin
    if IsHover and Assigned(FCheckBoxHover) then
      Helper := FCheckBoxHover
    else
      Helper := FCheckBoxNormal;
  end;

  if Assigned(Helper) then
    Helper.DrawToCanvas(Canvas, R);
end;

// --- Button/checkbox/text geometry ---

function TCssVirtualStringTree.GetButtonRect(
  Node: TCssVirtualNode;
  const RowR: TRect): TRect;
var
  Depth: Integer;
  Size: Integer;
  X, Y: Integer;
  FirstLeft: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  if Node = nil then
    Exit;

  Depth := GetNodeDepth(Node);

  Size := CssMin(9, FItemHeight - 4);
  if Size < 7 then
    Size := 7;

  FirstLeft := GetColumnLeft(0);

  X := FirstLeft + 2;

  if FShowCheckboxes then
    Inc(X, GetCheckBoxSize + 4);

  Inc(X, Depth * FIndent + 2);

  Y := RowR.Top + (FItemHeight - Size) div 2;

  Result := Rect(X, Y, X + Size, Y + Size);
end;

function TCssVirtualStringTree.GetCheckBoxSize: Integer;
var
  Measured: Integer;
  MaxSize: Integer;
begin
  Result := 13;

  if Assigned(FCheckBoxNormal) then
  begin
    Measured := 16;

    if HandleAllocated then
      Measured := FCheckBoxNormal.MeasureBoxSize(Canvas);

    MaxSize := FItemHeight - 4;

    if MaxSize > 25 then
      MaxSize := 25;

    if MaxSize < 9 then
      MaxSize := 9;

    Result := CssMin(Measured, MaxSize);
  end
  else
  begin
    Result := CssMin(13, FItemHeight - 4);
  end;

  if Result < 9 then
    Result := 9;
end;

function TCssVirtualStringTree.GetCheckRect(
  Node: TCssVirtualNode;
  const RowR: TRect): TRect;
var
  Size: Integer;
  X, Y: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  if Node = nil then
    Exit;

  Size := GetCheckBoxSize;

  X := GetColumnLeft(0) + 2;
  Y := RowR.Top + (FItemHeight - Size) div 2;

  Result := Rect(X, Y, X + Size, Y + Size);
end;

function TCssVirtualStringTree.GetTextStartX(
  Node: TCssVirtualNode;
  const RowR: TRect): Integer;
var
  CheckR, ButtonR: TRect;
begin
  Result := GetColumnLeft(0) + 2;

  if FShowCheckboxes then
  begin
    CheckR := GetCheckRect(Node, RowR);
    Result := CheckR.Right + 3;
  end;

  if cvsHasChildren in Node.States then
  begin
    ButtonR := GetButtonRect(Node, RowR);
    Result := ButtonR.Right + 3;
  end
  else
  begin
    Result := Result + GetNodeDepth(Node) * FIndent + 3;
  end;
end;

// --- Hit testing ---

function TCssVirtualStringTree.GetNodeAt(X, Y: Integer): TCssVirtualNode;
var
  TreeR: TRect;
  Row: Integer;
begin
  Result := nil;

  TreeR := GetTreeRect;

  if not PtInRect(TreeR, Point(X, Y)) then
    Exit;

  if FItemHeight <= 0 then
    Exit;

  Row := FTopNode + (Y - TreeR.Top) div FItemHeight;
  Result := GetVisibleNode(Row);
end;

function TCssVirtualStringTree.GetColumnAt(X: Integer): Integer;
var
  TreeR: TRect;
  FixedW, FixedRight: Integer;
  Acc, I: Integer;
begin
  Result := -1;

  if not Assigned(FColumns) then
    Exit;

  TreeR := GetTreeRect;

  if FColumns.Count = 0 then
  begin
    if X >= TreeR.Left then
      Result := 0;

    Exit;
  end;

  if X < TreeR.Left then
    Exit;

  FixedW := GetFixedWidth;
  FixedRight := TreeR.Left + FixedW;

  if X < FixedRight then
  begin
    Acc := 0;

    for I := 0 to CssMin(FFixedColumns, FColumns.Count) - 1 do
    begin
      Inc(Acc, FColumns[I].Width);

      if X < TreeR.Left + Acc then
        Exit(I);
    end;
  end
  else
  begin
    X := X - FixedRight + FHorzOffset;
    Acc := 0;

    for I := FFixedColumns to FColumns.Count - 1 do
    begin
      Inc(Acc, FColumns[I].Width);

      if X < Acc then
        Exit(I);
    end;
  end;
end;

function TCssVirtualStringTree.GetHeaderColumnAt(X: Integer): Integer;
begin
  Result := GetColumnAt(X);
end;

function TCssVirtualStringTree.GetCellRect(
  Node: TCssVirtualNode;
  Column: Integer): TRect;
var
  Idx: Integer;
  TreeR: TRect;
  RowTop: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  if Node = nil then
    Exit;

  Idx := FVisibleNodes.IndexOf(Node);
  if Idx < 0 then
    Exit;

  TreeR := GetTreeRect;
  RowTop := TreeR.Top + (Idx - FTopNode) * FItemHeight;

  if (Column < 0) or (FColumns.Count = 0) then
  begin
    Result := Rect(TreeR.Left, RowTop, TreeR.Right, RowTop + FItemHeight);
  end
  else
  begin
    Result := Rect(
      GetColumnLeft(Column),
      RowTop,
      GetColumnLeft(Column) + FColumns[Column].Width,
      RowTop + FItemHeight
    );
  end;
end;

function TCssVirtualStringTree.GetCellText(
  Node: TCssVirtualNode;
  Column: Integer): string;
begin
  Result := '';
  DoGetText(Node, Column, Result);
end;

// --- Navigation helpers ---

procedure TCssVirtualStringTree.SelectVisibleIndex(Index: Integer);
var
  EnabledIndex: Integer;
begin
  EnabledIndex := FindNearestEnabledVisibleIndex(Index);

  if EnabledIndex < 0 then
    Exit;

  SetSelectedNode(GetVisibleNode(EnabledIndex));
  ScrollIntoView(FSelectedNode);
end;

procedure TCssVirtualStringTree.MoveSelection(
  Delta: Integer;
  Shift: TShiftState);
var
  Current: Integer;
  NewIndex: Integer;
  Direction: Integer;
  Node: TCssVirtualNode;
begin
  if VisibleCount = 0 then
    Exit;

  if Delta > 0 then
    Direction := 1
  else if Delta < 0 then
    Direction := -1
  else
    Direction := 1;

  Current := FVisibleNodes.IndexOf(FSelectedNode);

  if Current < 0 then
  begin
    if Direction > 0 then
      NewIndex := 0
    else
      NewIndex := VisibleCount - 1;
  end
  else
  begin
    NewIndex := ClampVisibleIndex(Current + Delta);
  end;

  NewIndex := FindEnabledVisibleIndex(NewIndex, Direction);

  if NewIndex < 0 then
    Exit;

  Node := GetVisibleNode(NewIndex);

  if Node = nil then
    Exit;

  if FMultiSelect and (ssShift in Shift) then
  begin
    if FAnchorNode = nil then
    begin
      SetSelectedNode(Node);
      FAnchorNode := Node;
    end
    else
    begin
      SelectRange(FAnchorNode, Node);
    end;
  end
  else
  begin
    SetSelectedNode(Node);
    FAnchorNode := Node;
  end;

  ScrollIntoView(Node);
end;

// --- Selection internals ---

function TCssVirtualStringTree.IsSelected(Node: TCssVirtualNode): Boolean;
begin
  Result := Assigned(Node) and (FSelectionList.IndexOf(Node) >= 0);
end;

procedure TCssVirtualStringTree.InternalClearSelection(NotifyChange: Boolean);
var
  I: Integer;
  Node: TCssVirtualNode;
begin
  for I := 0 to FSelectionList.Count - 1 do
  begin
    Node := TCssVirtualNode(FSelectionList[I]);
    Exclude(Node.States, cvsSelected);
  end;

  FSelectionList.Clear;

  if NotifyChange then
    SelectionChanged;
end;

procedure TCssVirtualStringTree.InternalAddToSelection(
  Node: TCssVirtualNode;
  NotifyChange: Boolean);
begin
  if Node = nil then
    Exit;

  if IsNodeDisabled(Node) then
    Exit;

  if FSelectionList.IndexOf(Node) < 0 then
  begin
    FSelectionList.Add(Node);
    Include(Node.States, cvsSelected);

    if NotifyChange then
      SelectionChanged;
  end;
end;

procedure TCssVirtualStringTree.InternalRemoveFromSelection(
  Node: TCssVirtualNode;
  NotifyChange: Boolean);
var
  Idx: Integer;
begin
  if Node = nil then
    Exit;

  Idx := FSelectionList.IndexOf(Node);

  if Idx >= 0 then
  begin
    FSelectionList.Delete(Idx);
    Exclude(Node.States, cvsSelected);

    if NotifyChange then
      SelectionChanged;
  end;
end;

procedure TCssVirtualStringTree.SelectRange(A, B: TCssVirtualNode);
var
  I1, I2, I: Integer;
begin
  if A = nil then
    A := FSelectedNode;

  if (A <> nil) and IsNodeDisabled(A) then
    A := FSelectedNode;

  if (A <> nil) and IsNodeDisabled(A) then
    Exit;

  if B = nil then
    Exit;

  if IsNodeDisabled(B) then
    Exit;

  I1 := FVisibleNodes.IndexOf(A);
  I2 := FVisibleNodes.IndexOf(B);

  if (I1 < 0) or (I2 < 0) then
    Exit;

  if I1 > I2 then
  begin
    I := I1;
    I1 := I2;
    I2 := I;
  end;

  InternalClearSelection(False);

  for I := I1 to I2 do
    InternalAddToSelection(GetVisibleNode(I), False);

  FSelectedNode := B;
  FAnchorNode := A;

  SelectionChanged;
  Invalidate;
end;

procedure TCssVirtualStringTree.SelectionChanged;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

// --- Editing ---

procedure TCssVirtualStringTree.EditKeyDown(
  Sender: TObject;
  var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
    begin
      EndEditing(False);
      Key := 0;
    end;

    VK_ESCAPE:
    begin
      EndEditing(True);
      Key := 0;
    end;
  end;
end;

procedure TCssVirtualStringTree.EditExit(Sender: TObject);
begin
  if FEditClosing then
    Exit;

  EndEditing(False);
end;

// --- Sorting ---

function TCssVirtualStringTree.GetSortIndex(Column: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to High(FSortColumns) do
  begin
    if FSortColumns[I].Column = Column then
      Exit(I);
  end;
end;

procedure TCssVirtualStringTree.DeleteSortIndex(Index: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index > High(FSortColumns)) then
    Exit;

  for I := Index to High(FSortColumns) - 1 do
    FSortColumns[I] := FSortColumns[I + 1];

  SetLength(FSortColumns, Length(FSortColumns) - 1);
end;

function TCssVirtualStringTree.CompareNodesMulti(
  Node1, Node2: TCssVirtualNode): Integer;
var
  I, Col: Integer;
  S1, S2: string;
begin
  Result := 0;

  for I := 0 to High(FSortColumns) do
  begin
    Col := FSortColumns[I].Column;

    if FSortColumns[I].Direction = csdNone then
      Continue;

    if Assigned(FOnCompareNodes) then
    begin
      Result := FOnCompareNodes(Self, Node1, Node2, Col);
    end
    else
    begin
      S1 := PlainCellText(Node1, Col);
      S2 := PlainCellText(Node2, Col);
      Result := AnsiCompareText(S1, S2);
    end;

    if FSortColumns[I].Direction = csdDescending then
      Result := -Result;

    if Result <> 0 then
      Exit;
  end;
end;

procedure TCssVirtualStringTree.SortList(AList: TList);
var
  I, J: Integer;
  Key: TCssVirtualNode;
begin
  for I := 1 to AList.Count - 1 do
  begin
    Key := TCssVirtualNode(AList[I]);
    J := I - 1;

    while (J >= 0) and
          (CompareNodesMulti(TCssVirtualNode(AList[J]), Key) > 0) do
    begin
      AList[J + 1] := AList[J];
      Dec(J);
    end;

    AList[J + 1] := Key;
  end;
end;

function TCssVirtualStringTree.GetPrimarySortColumn: Integer;
begin
  if Length(FSortColumns) > 0 then
    Result := FSortColumns[0].Column
  else
    Result := -1;
end;

function TCssVirtualStringTree.GetPrimarySortAscending: Boolean;
begin
  if Length(FSortColumns) > 0 then
    Result := FSortColumns[0].Direction = csdAscending
  else
    Result := True;
end;

procedure TCssVirtualStringTree.SetPrimarySortColumn(AValue: Integer);
var
  Dir: TCssSortDirection;
begin
  if AValue < 0 then
  begin
    ClearSortColumns;
    Exit;
  end;

  Dir := GetSortDirection(AValue);

  if Dir = csdNone then
    Dir := csdAscending;

  SetSortColumn(AValue, Dir, False);
  SortBySortColumns;
end;

procedure TCssVirtualStringTree.SetPrimarySortAscending(AValue: Boolean);
var
  Col: Integer;
begin
  Col := GetPrimarySortColumn;

  if Col < 0 then
    Exit;

  if AValue then
    SetSortColumn(Col, csdAscending, False)
  else
    SetSortColumn(Col, csdDescending, False);

  SortBySortColumns;
end;

// --- Incremental search ---

procedure TCssVirtualStringTree.FindSearchNode;
var
  I: Integer;
  Node: TCssVirtualNode;
  S: string;
begin
  if FSearchText = '' then
    Exit;

  for I := 0 to VisibleCount - 1 do
  begin
    Node := GetVisibleNode(I);

    if Node = nil then
      Continue;

    if IsNodeDisabled(Node) then
      Continue;

    S := LowerCase(PlainCellText(Node, 0));

    if Pos(FSearchText, S) = 1 then
    begin
      SetSelectedNode(Node);
      MakeVisible(Node);
      Exit;
    end;
  end;
end;

// --- Painting ---

procedure TCssVirtualStringTree.Paint;
var
  ContentR: TRect;
  TreeR: TRect;
  HeaderR: TRect;
  SavedClip: TRect;
  I, LastRow: Integer;
  Node: TCssVirtualNode;
begin
  inherited Paint;

  if not Assigned(FVisibleNodes) then
    Exit;

  UpdateCanvasFont;

  ContentR := GetContentRect;
  TreeR := GetTreeRect;

  if FHeaderVisible then
  begin
    HeaderR := Rect(
      ContentR.Left,
      ContentR.Top,
      TreeR.Right,
      ContentR.Top + GetHeaderHeight
    );

    DrawHeader(HeaderR);
  end;

  if (TreeR.Right <= TreeR.Left) or (TreeR.Bottom <= TreeR.Top) then
  begin
    DrawInternalScrollBars;
    DrawRoundedCornerMask;
    Exit;
  end;

  SavedClip := Canvas.ClipRect;
  Canvas.ClipRect := TreeR;
  try
    LastRow := CssMin(VisibleCount - 1, FTopNode + GetPageRows - 1);

    for I := FTopNode to LastRow do
    begin
      Node := GetVisibleNode(I);
      if Node <> nil then
        DrawNodeRow(Node, I, TreeR);
    end;
  finally
    Canvas.ClipRect := SavedClip;
  end;

  DrawInternalScrollBars;
  DrawRoundedCornerMask;
end;

// --- CSS declaration handling ---

procedure TCssVirtualStringTree.ApplyDeclaration(
  const AName, AValue: string);
var
  C: TColor;
  Px: Integer;
  HA: TCssTreeHAlign;
  VA: TCssTreeVAlign;
begin
  if AValue = '' then
    Exit;

  if AName = 'html-mode' then
  begin
    HtmlMode := SameText(AValue, 'true') or
                SameText(AValue, '1') or
                SameText(AValue, 'yes');
    Exit;
  end;

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

  if AName = 'line-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FLineColor := C;
      FLineColorSet := True;
    end;

    Exit;
  end;

  if AName = 'button-color' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FButtonColor := C;
      FButtonColorSet := True;
    end;

    Exit;
  end;

  if (AName = 'checkbox-background') or
     (AName = 'checkbox-border-color') or
     (AName = 'checkbox-border-width') or
     (AName = 'checkbox-radius') or
     (AName = 'check-color') then
  begin
    FCheckBoxInlineCss := FCheckBoxInlineCss + AName + ':' + AValue + ';';

    if AName = 'check-color' then
    begin
      if ParseCssColor(AValue, C) then
      begin
        FCheckColor := C;
        FCheckColorSet := True;
      end;
    end;

    Exit;
  end;

  if AName = 'drop-target-background' then
  begin
    if ParseCssColor(AValue, C) then
    begin
      FDropTargetBackground := C;
      FDropTargetBackgroundSet := True;
    end;

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

  if AName = 'header-height' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      SetHeaderHeight(Px);

    Exit;
  end;

  if (AName = 'row-height') or (AName = 'item-height') then
  begin
    if ParseCssLengthPx(AValue, Px) then
      SetItemHeight(Px);

    Exit;
  end;

  if AName = 'indent' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      SetIndent(Px);

    Exit;
  end;

  if AName = 'scrollbar-size' then
  begin
    if ParseCssLengthPx(AValue, Px) then
      SetScrollBarSize(Px);

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

  if (AName = 'header-text-align') or
     (AName = 'header-align') then
  begin
    if ParseTreeHAlignCss(AValue, HA) then
    begin
      FHeaderHAlignCss := HA;
      FHeaderHAlignCssSet := True;
    end;
    Exit;
  end;

  if (AName = 'header-vertical-align') or
     (AName = 'header-valign') then
  begin
    if ParseTreeVAlignCss(AValue, VA) then
    begin
      FHeaderVAlignCss := VA;
      FHeaderVAlignCssSet := True;
    end;
    Exit;
  end;

  if (AName = 'cell-text-align') or
     (AName = 'row-text-align') or
     (AName = 'node-text-align') then
  begin
    if ParseTreeHAlignCss(AValue, HA) then
    begin
      FCellHAlignCss := HA;
      FCellHAlignCssSet := True;
    end;
    Exit;
  end;

  if (AName = 'cell-vertical-align') or
     (AName = 'row-vertical-align') or
     (AName = 'node-vertical-align') then
  begin
    if ParseTreeVAlignCss(AValue, VA) then
    begin
      FCellVAlignCss := VA;
      FCellVAlignCssSet := True;
    end;
    Exit;
  end;

  inherited ApplyDeclaration(AName, AValue);
end;

// --- Style / loaded / init ---

procedure TCssVirtualStringTree.ResetStyle;
begin
  FHeaderBackgroundSet := False;
  FHeaderColorSet := False;

  FSelectionBackgroundSet := False;
  FSelectionColorSet := False;

  FHoverBackgroundSet := False;

  FLineColorSet := False;
  FButtonColorSet := False;
  FCheckColorSet := False;

  FDropTargetBackgroundSet := False;
  FSortMarkerColorSet := False;
  FCheckBoxInlineCss := '';

  FDisabledBackgroundSet := False;
  FDisabledColorSet := False;

  FHeaderHAlignCss := thaInherit;
  FHeaderHAlignCssSet := False;

  FHeaderVAlignCss := tvaInherit;
  FHeaderVAlignCssSet := False;

  FCellHAlignCss := thaInherit;
  FCellHAlignCssSet := False;

  FCellVAlignCss := tvaInherit;
  FCellVAlignCssSet := False;

  inherited ResetStyle;
end;

procedure TCssVirtualStringTree.InitTextProps;
begin
  SetWordWrap(False);
  SetVAlign(cvaMiddle);
end;

procedure TCssVirtualStringTree.StyleChanged;
begin
  inherited StyleChanged;

  UpdateCheckBoxStyle;

  if Assigned(FVScroll) and Assigned(FHScroll) then
  begin
    FVScroll.StyleProvider := StyleProvider;
    FHScroll.StyleProvider := StyleProvider;
  end;

  if Assigned(FEdit) then
  begin
    FEdit.StyleProvider := StyleProvider;

    if FEditStyleName <> '' then
      FEdit.StyleName := FEditStyleName;
  end;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.Resize;
begin
  EndEditing(True);

  inherited Resize;

  UpdateScrollBars;
  Invalidate;
end;

procedure TCssVirtualStringTree.Loaded;
begin
  inherited Loaded;

  UpdateCheckBoxStyle;

  RebuildVisible;
  UpdateScrollBars;
end;

// --- Mouse handling ---

procedure TCssVirtualStringTree.MouseDown(
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Integer);
var
  Node: TCssVirtualNode;
  TreeR: TRect;
  RowIndex: Integer;
  RowR: TRect;
  ButtonR: TRect;
  CheckR: TRect;
  Col: Integer;
  CurDir, NewDir: TCssSortDirection;
  SB: TCssScrollBar;
  P: TPoint;
  ResizeCol: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not Enabled then
    Exit;

  if CanFocus then
    SetFocus;

  if Button <> mbLeft then
    Exit;

  EndEditing(False);

  FLastMouse := Point(X, Y);

  SB := ScrollBarAt(X, Y);

  if SB <> nil then
  begin
    if SB = FVScroll then
      P := Point(X - FVScrollRect.Left, Y - FVScrollRect.Top)
    else
      P := Point(X - FHScrollRect.Left, Y - FHScrollRect.Top);

    if SB.ExternalMouseDown(Button, Shift, P.X, P.Y) then
    begin
      FScrollCapture := SB;
      MouseCapture := True;
      Invalidate;
    end;

    Exit;
  end;

  TreeR := GetTreeRect;

  if FHeaderVisible and (Y < TreeR.Top) then
  begin
    if FAllowColumnResize and (Button = mbLeft) then
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
    end;

    Col := GetHeaderColumnAt(X);

    if Assigned(FOnHeaderClick) then
      FOnHeaderClick(Self, Col);

    if FAutoSort and (Col >= 0) then
    begin
      CurDir := GetSortDirection(Col);

      if ssCtrl in Shift then
      begin
        case CurDir of
          csdNone:
            NewDir := csdAscending;
          csdAscending:
            NewDir := csdDescending;
        else
          NewDir := csdNone;
        end;

        SetSortColumn(Col, NewDir, True);
      end
      else
      begin
        if CurDir = csdAscending then
          NewDir := csdDescending
        else
          NewDir := csdAscending;

        SetSortColumn(Col, NewDir, False);
      end;

      SortBySortColumns;
    end;

    Exit;
  end;

  Node := GetNodeAt(X, Y);

  if Node = nil then
  begin
    SetSelectedNode(nil);
    Exit;
  end;

  if IsNodeDisabled(Node) then
    Exit;

  RowIndex := FVisibleNodes.IndexOf(Node);

  if RowIndex < 0 then
    Exit;

  RowR := Rect(
    TreeR.Left,
    TreeR.Top + (RowIndex - FTopNode) * FItemHeight,
    TreeR.Right,
    TreeR.Top + (RowIndex - FTopNode + 1) * FItemHeight
  );

  if FShowCheckboxes then
  begin
    CheckR := GetCheckRect(Node, RowR);

    if PtInRect(CheckR, Point(X, Y)) then
    begin
      ToggleCheck(Node);
      SetSelectedNode(Node);
      Exit;
    end;
  end;

  ButtonR := GetButtonRect(Node, RowR);

  if (cvsHasChildren in Node.States) and PtInRect(ButtonR, Point(X, Y)) then
  begin
    ToggleNode(Node);
    SetSelectedNode(Node);
    Exit;
  end;

  if FMultiSelect and (ssCtrl in Shift) then
  begin
    if IsSelected(Node) then
      RemoveFromSelection(Node)
    else
      AddToSelection(Node);

    FAnchorNode := Node;
  end
  else if FMultiSelect and (ssShift in Shift) then
  begin
    if FAnchorNode = nil then
      FAnchorNode := FSelectedNode;

    SelectRange(FAnchorNode, Node);
  end
  else
  begin
    SetSelectedNode(Node);
    FAnchorNode := Node;
  end;

  Col := GetColumnAt(X);

  if Assigned(FOnNodeClick) then
    FOnNodeClick(Self, Node, Col);

  if FAllowDrag then
  begin
    FDragPending := True;
    FDragStartPoint := Point(X, Y);
  end;
end;

procedure TCssVirtualStringTree.MouseMove(
  Shift: TShiftState;
  X, Y: Integer
);
var
  Node: TCssVirtualNode;
  P: TPoint;
  LChanged: Boolean;
  NewWidth: Integer;
  TreeR: TRect;
begin
  inherited MouseMove(Shift, X, Y);

  if not Enabled then
    Exit;

  FLastMouse := Point(X, Y);

  // 1. Active scrollbar drag.
  if FScrollCapture <> nil then
  begin
    if FScrollCapture = FVScroll then
      P := Point(X - FVScrollRect.Left, Y - FVScrollRect.Top)
    else
      P := Point(X - FHScrollRect.Left, Y - FHScrollRect.Top);

    if FScrollCapture.ExternalMouseMove(Shift, P.X, P.Y) then
      Invalidate;

    Exit;
  end;

  // 2. Active column resize.
  if FResizingColumn >= 0 then
  begin
    if FResizingColumn < FColumns.Count then
    begin
      NewWidth := FResizeStartWidth + (X - FResizeStartX);

      if NewWidth < FMinColumnWidth then
        NewWidth := FMinColumnWidth;

      if FColumns[FResizingColumn].Width <> NewWidth then
      begin
        FColumns[FResizingColumn].Width := NewWidth;

        if Assigned(FOnColumnResizing) then
          FOnColumnResizing(Self, FResizingColumn);
      end;
    end
    else
    begin
      FResizingColumn := -1;
    end;

    Cursor := crSizeWE;
    Exit;
  end;

  // 3. Hover over the vertical scrollbar.
  if Assigned(FVScroll) and
     FVScroll.Visible and
     PtInRect(FVScrollRect, Point(X, Y)) then
  begin
    if Cursor = crSizeWE then
      Cursor := crDefault;

    if FVScroll.ExternalMouseMove(
      Shift,
      X - FVScrollRect.Left,
      Y - FVScrollRect.Top) then
    begin
      Invalidate;
    end;

    Exit;
  end;

  // 4. Hover over the horizontal scrollbar.
  if Assigned(FHScroll) and
     FHScroll.Visible and
     PtInRect(FHScrollRect, Point(X, Y)) then
  begin
    if Cursor = crSizeWE then
      Cursor := crDefault;

    if FHScroll.ExternalMouseMove(
      Shift,
      X - FHScrollRect.Left,
      Y - FHScrollRect.Top) then
    begin
      Invalidate;
    end;

    Exit;
  end;

  // 5. If the cursor left the scrollbars, reset their hover state.
  LChanged := False;

  if Assigned(FVScroll) and FVScroll.Visible then
    LChanged := FVScroll.ExternalMouseLeave or LChanged;

  if Assigned(FHScroll) and FHScroll.Visible then
    LChanged := FHScroll.ExternalMouseLeave or LChanged;

  if LChanged then
    Invalidate;

  // 6. Cursor for column resizing.
  if FAllowColumnResize and FHeaderVisible then
  begin
    TreeR := GetTreeRect;

    if Y < TreeR.Top then
    begin
      if GetHeaderResizeColumnAt(X) >= 0 then
        Cursor := crSizeWE
      else if Cursor = crSizeWE then
        Cursor := crDefault;
    end
    else
    begin
      if Cursor = crSizeWE then
        Cursor := crDefault;
    end;
  end
  else
  begin
    if Cursor = crSizeWE then
      Cursor := crDefault;
  end;

  // 7. Start node dragging.
  if FDragPending and
     ((Abs(X - FDragStartPoint.X) > 4) or
      (Abs(Y - FDragStartPoint.Y) > 4)) then
  begin
    FDragPending := False;
    BeginDrag(True);
    Exit;
  end;

  // 8. Hover for nodes, but not for disabled ones.
  Node := GetNodeAt(X, Y);

  if (Node <> nil) and IsNodeDisabled(Node) then
    Node := nil;

  if Node <> FHoverNode then
  begin
    FHoverNode := Node;
    Invalidate;
  end;
end;

procedure TCssVirtualStringTree.MouseUp(
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Integer
);
var
  ResizedCol: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);

  // Finish scrollbar interaction.
  if FScrollCapture <> nil then
  begin
    FScrollCapture.ExternalMouseUp;
    MouseCapture := False;
    FScrollCapture := nil;
    Invalidate;
    Exit;
  end;

  // Finish column resize.
  if FResizingColumn >= 0 then
  begin
    ResizedCol := FResizingColumn;

    FResizingColumn := -1;
    MouseCapture := False;

    if Cursor = crSizeWE then
      Cursor := crDefault;

    if Assigned(FOnColumnResized) and
       (ResizedCol >= 0) and
       (ResizedCol < FColumns.Count) then
    begin
      FOnColumnResized(Self, ResizedCol);
    end;

    Invalidate;
    Exit;
  end;

  FDragPending := False;
end;

procedure TCssVirtualStringTree.MouseLeave;
var
  LChanged: Boolean;
begin
  // If a column resize is in progress, do not reset the state.
  if FResizingColumn >= 0 then
    Exit;

  if not FDragPending then
    FHoverNode := nil;

  LChanged := False;

  if Assigned(FVScroll) and FVScroll.Visible then
    LChanged := FVScroll.ExternalMouseLeave or LChanged;

  if Assigned(FHScroll) and FHScroll.Visible then
    LChanged := FHScroll.ExternalMouseLeave or LChanged;

  if LChanged then
    Invalidate;

  inherited MouseLeave;

  Invalidate;
end;

// --- Keyboard ---

procedure TCssVirtualStringTree.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  if not Enabled then
    Exit;

  if FEditingNode <> nil then
    Exit;

  if FMultiSelect and (ssCtrl in Shift) and (Key = Ord('A')) then
  begin
    SelectAll;
    Key := 0;
    Exit;
  end;

  case Key of
    VK_UP:
    begin
      MoveSelection(-1, Shift);
      Key := 0;
    end;

    VK_DOWN:
    begin
      MoveSelection(1, Shift);
      Key := 0;
    end;

    VK_PRIOR:
    begin
      MoveSelection(-GetPageRows, Shift);
      Key := 0;
    end;

    VK_NEXT:
    begin
      MoveSelection(GetPageRows, Shift);
      Key := 0;
    end;

    VK_HOME:
    begin
      SelectVisibleIndex(0);
      Key := 0;
    end;

    VK_END:
    begin
      SelectVisibleIndex(VisibleCount - 1);
      Key := 0;
    end;

    VK_F2:
    begin
      if FAllowEditing then
        StartEditing(FSelectedNode, 0);

      Key := 0;
    end;

    VK_LEFT:
    begin
      if FSelectedNode <> nil then
      begin
        if (cvsHasChildren in FSelectedNode.States) and
           (cvsExpanded in FSelectedNode.States) then
        begin
          CollapseNode(FSelectedNode);
        end
        else if (FSelectedNode.Parent <> nil) and
                (FSelectedNode.Parent <> FRoot) then
        begin
          SetSelectedNode(FSelectedNode.Parent);
          ScrollIntoView(FSelectedNode);
        end;
      end;

      Key := 0;
    end;

    VK_RIGHT:
    begin
      if FSelectedNode <> nil then
      begin
        EnsureChildrenLoaded(FSelectedNode);

        if cvsHasChildren in FSelectedNode.States then
        begin
          if not (cvsExpanded in FSelectedNode.States) then
            ExpandNode(FSelectedNode)
          else if FSelectedNode.FirstChild <> nil then
          begin
            SetSelectedNode(FSelectedNode.FirstChild);
            ScrollIntoView(FSelectedNode);
          end;
        end;
      end;

      Key := 0;
    end;

    VK_SPACE:
    begin
      if FShowCheckboxes and (FSelectedNode <> nil) then
        ToggleCheck(FSelectedNode)
      else if FSelectedNode <> nil then
        ToggleNode(FSelectedNode);

      Key := 0;
    end;
  end;
end;

procedure TCssVirtualStringTree.KeyPress(var Key: char);
var
  CurrentTime: QWord;
begin
  inherited KeyPress(Key);

  if not FIncrementalSearch then
    Exit;

  if FEditingNode <> nil then
    Exit;

  if Key = #8 then
  begin
    if FSearchText <> '' then
      Delete(FSearchText, Length(FSearchText), 1);

    FindSearchNode;
    Key := #0;
    Exit;
  end;

  if Key < #32 then
    Exit;

  CurrentTime := GetTickCount64;

  if CurrentTime - FSearchTime > 1000 then
    FSearchText := '';

  FSearchTime := CurrentTime;
  FSearchText := FSearchText + LowerCase(Key);

  FindSearchNode;
  Key := #0;
end;

procedure TCssVirtualStringTree.DblClick;
var
  Node: TCssVirtualNode;
  Col: Integer;
begin
  inherited DblClick;

  if not Enabled then
    Exit;

  Node := GetNodeAt(FLastMouse.X, FLastMouse.Y);
  if Node = nil then
    Exit;

  if IsNodeDisabled(Node) then
    Exit;

  Col := GetColumnAt(FLastMouse.X);

  if FAllowEditing then
    StartEditing(Node, Col)
  else
    ToggleNode(Node);
end;

// --- Mouse wheel ---

function TCssVirtualStringTree.DoMouseWheel(
  Shift: TShiftState;
  WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);

  if Result or not Enabled then
    Exit;

  if ssShift in Shift then
  begin
    if WheelDelta > 0 then
      SetHorzOffset(FHorzOffset - FItemHeight * 3)
    else if WheelDelta < 0 then
      SetHorzOffset(FHorzOffset + FItemHeight * 3)
    else
      Exit;
  end
  else
  begin
    if WheelDelta > 0 then
      SetTopNode(FTopNode - 3)
    else if WheelDelta < 0 then
      SetTopNode(FTopNode + 3)
    else
      Exit;
  end;

  Result := True;
end;

// --- Drag & drop ---

procedure TCssVirtualStringTree.InternalStartDrag(
  Sender: TObject;
  var DragObject: TDragObject);
var
  Nodes: TList;
  I: Integer;
begin
  if not FAllowDrag then
    Exit;

  Nodes := TList.Create;
  try
    if FSelectionList.Count > 0 then
    begin
      for I := 0 to FSelectionList.Count - 1 do
        Nodes.Add(FSelectionList[I]);
    end
    else if FSelectedNode <> nil then
    begin
      Nodes.Add(FSelectedNode);
    end;

    if Nodes.Count = 0 then
      Exit;

    DragObject := TCssVirtualTreeDragObject.Create(Self, Nodes);
    Nodes := nil;
  finally
    Nodes.Free;
  end;
end;

procedure TCssVirtualStringTree.InternalEndDrag(
  Sender, Target: TObject;
  X, Y: Integer);
begin
  FDropTargetNode := nil;
  FDragPending := False;

  Invalidate;
end;

procedure TCssVirtualStringTree.DragOver(
  Source: TObject;
  X, Y: Integer;
  State: TDragState;
  var Accept: Boolean);
var
  Target: TCssVirtualNode;
  DragObj: TCssVirtualTreeDragObject;
  Nodes: TList;
  I: Integer;
  Allowed: Boolean;
begin
  inherited DragOver(Source, X, Y, State, Accept);

  Accept := False;

  if not FAllowDrop then
    Exit;

  Target := GetNodeAt(X, Y);

  if (Target <> nil) and IsNodeDisabled(Target) then
    Target := nil;

  if Target <> FDropTargetNode then
  begin
    FDropTargetNode := Target;
    Invalidate;
  end;

  if not (Source is TCssVirtualTreeDragObject) then
    Exit;

  DragObj := TCssVirtualTreeDragObject(Source);
  Nodes := DragObj.Nodes;

  if Nodes = nil then
    Exit;

  if Target <> nil then
  begin
    for I := 0 to Nodes.Count - 1 do
    begin
      if IsNodeInSubTree(Target, TCssVirtualNode(Nodes[I])) then
        Exit;
    end;
  end;

  Allowed := True;

  if Assigned(FOnDragOverNodes) then
    FOnDragOverNodes(Self, Nodes, Target, Allowed);

  Accept := Allowed;
end;

procedure TCssVirtualStringTree.DragDrop(Source: TObject; X, Y: Integer);
var
  Target: TCssVirtualNode;
  DragObj: TCssVirtualTreeDragObject;
  Nodes: TList;
  SourceTree: TCssVirtualStringTree;
begin
  inherited DragDrop(Source, X, Y);

  Target := GetNodeAt(X, Y);

  if (Target <> nil) and IsNodeDisabled(Target) then
    Target := nil;

  if Target = nil then
    Target := FRoot;

  if Source is TCssVirtualTreeDragObject then
  begin
    DragObj := TCssVirtualTreeDragObject(Source);
    Nodes := DragObj.Nodes;
    SourceTree := DragObj.Tree;

    if FAllowDrop and Assigned(Nodes) then
    begin
      if Assigned(FOnDropNodesEx) then
      begin
        FOnDropNodesEx(Self, SourceTree, Nodes, Target);
      end
      else if SourceTree = Self then
      begin
        if Assigned(FOnDropNodes) then
          FOnDropNodes(Self, Nodes, Target)
        else
          MoveNodes(Nodes, Target);
      end;
    end;
  end;

  FDropTargetNode := nil;
  Invalidate;
end;

// --- Structure ---

function TCssVirtualStringTree.AddChild(
  AParent: TCssVirtualNode): TCssVirtualNode;
begin
  if AParent = nil then
    AParent := FRoot;

  EnsureNodeDataSize;

  Result := TCssVirtualNode.Create;
  Result.Parent := AParent;

  if AParent.ChildCount = 0 then
  begin
    AParent.FirstChild := Result;
    AParent.LastChild := Result;
  end
  else
  begin
    Result.PrevSibling := AParent.LastChild;
    AParent.LastChild.NextSibling := Result;
    AParent.LastChild := Result;
  end;

  Inc(AParent.ChildCount);
  Include(AParent.States, cvsHasChildren);
  Include(AParent.States, cvsChildrenLoaded);

  if FNodeDataSize > 0 then
  begin
    GetMem(Result.Data, FNodeDataSize);
    FillChar(Result.Data^, FNodeDataSize, 0);
  end;

  DoInitNode(Result);

  if ShouldAutoSort then
    SortNodeChildren(AParent, False);

  NeedRebuild;
end;

procedure TCssVirtualStringTree.DeleteNode(Node: TCssVirtualNode);
begin
  if (Node = nil) or (Node = FRoot) then
    Exit;

  BeginUpdate;
  try
    if IsNodeInSubTree(FSelectedNode, Node) then
      FSelectedNode := nil;

    if IsNodeInSubTree(FHoverNode, Node) then
      FHoverNode := nil;

    InternalDeleteNode(Node);
    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

procedure TCssVirtualStringTree.DeleteChildren(Node: TCssVirtualNode);
begin
  if Node = nil then
    Node := FRoot;

  BeginUpdate;
  try
    if (FSelectedNode <> nil) and
       (FSelectedNode <> Node) and
       IsNodeInSubTree(FSelectedNode, Node) then
    begin
      FSelectedNode := nil;
    end;

    if (FHoverNode <> nil) and
       (FHoverNode <> Node) and
       IsNodeInSubTree(FHoverNode, Node) then
    begin
      FHoverNode := nil;
    end;

    while Node.FirstChild <> nil do
      InternalDeleteNode(Node.FirstChild);

    if Node <> FRoot then
    begin
      Exclude(Node.States, cvsExpanded);

      if Node.ChildCount = 0 then
        Exclude(Node.States, cvsHasChildren);
    end;

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

procedure TCssVirtualStringTree.ClearAll;
begin
  BeginUpdate;
  try
    FSelectedNode := nil;
    FHoverNode := nil;
    FAnchorNode := nil;
    FDropTargetNode := nil;

    FSelectionList.Clear;

    while FRoot.FirstChild <> nil do
      InternalDeleteNode(FRoot.FirstChild);

    FTopNode := 0;
    FHorzOffset := 0;

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

// --- Expansion ---

procedure TCssVirtualStringTree.ExpandNode(Node: TCssVirtualNode);
var
  Allowed: Boolean;
begin
  if Node = nil then
    Exit;

  if cvsExpanded in Node.States then
    Exit;

  EnsureChildrenLoaded(Node);

  Allowed := True;

  if Assigned(FOnExpanding) then
    FOnExpanding(Self, Node, Allowed);

  if not Allowed then
    Exit;

  // Children may have just been loaded,
  // so we need to sort them before expanding.
  AutoSortNode(Node, False);

  Include(Node.States, cvsExpanded);

  NeedRebuild;

  if Assigned(FOnExpanded) then
    FOnExpanded(Self, Node);
end;

procedure TCssVirtualStringTree.CollapseNode(Node: TCssVirtualNode);
var
  Allowed: Boolean;
begin
  if Node = nil then
    Exit;

  if not (cvsExpanded in Node.States) then
    Exit;

  Allowed := True;

  if Assigned(FOnCollapsing) then
    FOnCollapsing(Self, Node, Allowed);

  if not Allowed then
    Exit;

  Exclude(Node.States, cvsExpanded);
  NeedRebuild;

  if Assigned(FOnCollapsed) then
    FOnCollapsed(Self, Node);
end;

procedure TCssVirtualStringTree.ToggleNode(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  if IsNodeDisabled(Node) then
    Exit;

  if cvsExpanded in Node.States then
    CollapseNode(Node)
  else
    ExpandNode(Node);
end;

procedure TCssVirtualStringTree.FullExpand;

  procedure DoFull(Node: TCssVirtualNode);
  var
    Child: TCssVirtualNode;
  begin
    Child := Node.FirstChild;

    while Child <> nil do
    begin
      EnsureChildrenLoaded(Child);

      if (Child.ChildCount > 0) or (cvsHasChildren in Child.States) then
        Include(Child.States, cvsExpanded);

      DoFull(Child);
      Child := Child.NextSibling;
    end;
  end;

begin
  BeginUpdate;
  try
    DoFull(FRoot);

    if ShouldAutoSort then
      SortNodeChildren(FRoot, True);

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

procedure TCssVirtualStringTree.FullCollapse;

  procedure DoFull(Node: TCssVirtualNode);
  var
    Child: TCssVirtualNode;
  begin
    Child := Node.FirstChild;

    while Child <> nil do
    begin
      Exclude(Child.States, cvsExpanded);
      DoFull(Child);
      Child := Child.NextSibling;
    end;
  end;

begin
  BeginUpdate;
  try
    DoFull(FRoot);
    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

// --- Navigation / visibility ---

procedure TCssVirtualStringTree.MakeVisible(Node: TCssVirtualNode);
var
  P: TCssVirtualNode;
begin
  if Node = nil then
    Exit;

  BeginUpdate;
  try
    P := Node.Parent;

    while (P <> nil) and (P <> FRoot) do
    begin
      EnsureChildrenLoaded(P);
      Include(P.States, cvsExpanded);
      P := P.Parent;
    end;

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;

  ScrollIntoView(Node);
end;

procedure TCssVirtualStringTree.ScrollIntoView(Node: TCssVirtualNode);
var
  Idx: Integer;
  PageRows: Integer;
begin
  if Node = nil then
    Exit;

  Idx := FVisibleNodes.IndexOf(Node);
  if Idx < 0 then
    Exit;

  PageRows := GetPageRows;

  if Idx < FTopNode then
    SetTopNode(Idx)
  else if Idx >= FTopNode + PageRows then
    SetTopNode(Idx - PageRows + 1);
end;

function TCssVirtualStringTree.GetNodeData(Node: TCssVirtualNode): Pointer;
begin
  if Node = nil then
    Result := nil
  else
    Result := Node.Data;
end;

function TCssVirtualStringTree.GetFirstVisible: TCssVirtualNode;
begin
  Result := GetVisibleNode(0);
end;

function TCssVirtualStringTree.GetNextVisible(
  Node: TCssVirtualNode): TCssVirtualNode;
var
  I: Integer;
begin
  Result := nil;

  if Node = nil then
    Exit;

  I := FVisibleNodes.IndexOf(Node);

  if (I >= 0) and (I < FVisibleNodes.Count - 1) then
    Result := GetVisibleNode(I + 1);
end;

// --- Public selection ---

procedure TCssVirtualStringTree.SelectAll;
var
  I: Integer;
  EnabledIndex: Integer;
begin
  if not FMultiSelect then
    Exit;

  InternalClearSelection(False);

  for I := 0 to VisibleCount - 1 do
    InternalAddToSelection(GetVisibleNode(I), False);

  EnabledIndex := FindNearestEnabledVisibleIndex(0);

  if EnabledIndex >= 0 then
    FSelectedNode := GetVisibleNode(EnabledIndex)
  else
    FSelectedNode := nil;

  SelectionChanged;
  Invalidate;
end;

procedure TCssVirtualStringTree.ClearSelection;
begin
  InternalClearSelection(False);

  FSelectedNode := nil;
  FAnchorNode := nil;

  SelectionChanged;
  Invalidate;
end;

procedure TCssVirtualStringTree.AddToSelection(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  if not FMultiSelect then
  begin
    SetSelectedNode(Node);
    Exit;
  end;

  InternalAddToSelection(Node, True);
  FSelectedNode := Node;

  Invalidate;
end;

procedure TCssVirtualStringTree.RemoveFromSelection(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  InternalRemoveFromSelection(Node, True);

  if FSelectedNode = Node then
  begin
    if FSelectionList.Count > 0 then
      FSelectedNode := TCssVirtualNode(FSelectionList.Last)
    else
      FSelectedNode := nil;
  end;

  Invalidate;
end;

function TCssVirtualStringTree.GetSelectedCount: Integer;
begin
  Result := FSelectionList.Count;
end;

function TCssVirtualStringTree.GetSelectedNode(
  Index: Integer): TCssVirtualNode;
begin
  if (Index >= 0) and (Index < FSelectionList.Count) then
    Result := TCssVirtualNode(FSelectionList[Index])
  else
    Result := nil;
end;

// --- Checkbox API ---

procedure TCssVirtualStringTree.SetChecked(
  Node: TCssVirtualNode;
  AValue: Boolean);
begin
  if Node = nil then
    Exit;

  if AValue then
    Include(Node.States, cvsChecked)
  else
    Exclude(Node.States, cvsChecked);

  Invalidate;

  if Assigned(FOnCheckedChanged) then
    FOnCheckedChanged(Self, Node);
end;

procedure TCssVirtualStringTree.ToggleCheck(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  if IsNodeDisabled(Node) then
    Exit;

  SetChecked(Node, not (cvsChecked in Node.States));
end;

function TCssVirtualStringTree.IsChecked(Node: TCssVirtualNode): Boolean;
begin
  Result := Assigned(Node) and (cvsChecked in Node.States);
end;

// --- Editing API ---

procedure TCssVirtualStringTree.StartEditing(
  Node: TCssVirtualNode;
  Column: Integer);
var
  Allowed: Boolean;
  R: TRect;
  S: string;
begin
  if not FAllowEditing then
    Exit;

  if Node = nil then
    Exit;

  if IsNodeDisabled(Node) then
    Exit;

  if FEditingNode <> nil then
    EndEditing(True);

  Allowed := True;

  if Assigned(FOnEditing) then
    FOnEditing(Self, Node, Column, Allowed);

  if not Allowed then
    Exit;

  FEditingNode := Node;
  FEditingColumn := Column;

  S := GetCellText(Node, Column);
  FEditOldText := S;
  FEdit.Text := S;

  R := GetCellRect(Node, Column);

  if Column = 0 then
    R.Left := GetTextStartX(Node, R);

  FEdit.SetBounds(
    R.Left + 1,
    R.Top + 1,
    CssMax(1, R.Width - 2),
    CssMax(1, R.Height - 2)
  );

  FEdit.Visible := True;
  FEdit.SetFocus;
  FEdit.SelectAll;

  Invalidate;
end;

procedure TCssVirtualStringTree.EndEditing(Cancel: Boolean);
var
  Node: TCssVirtualNode;
  Col: Integer;
  S: string;
begin
  if FEditingNode = nil then
    Exit;

  if FEditClosing then
    Exit;

  FEditClosing := True;
  try
    Node := FEditingNode;
    Col := FEditingColumn;
    S := FEdit.Text;

    FEditingNode := nil;
    FEditingColumn := -1;

    FEdit.Visible := False;

    if not Cancel and (S <> FEditOldText) and Assigned(FOnNewText) then
      FOnNewText(Self, Node, Col, S);

    if HandleAllocated and CanFocus then
      SetFocus;

    Invalidate;
  finally
    FEditClosing := False;
  end;
end;

// --- Sorting API ---

procedure TCssVirtualStringTree.ClearSortColumns;
begin
  SetLength(FSortColumns, 0);
  Invalidate;
end;

function TCssVirtualStringTree.GetSortDirection(
  Column: Integer): TCssSortDirection;
var
  I: Integer;
begin
  I := GetSortIndex(Column);

  if I < 0 then
    Result := csdNone
  else
    Result := FSortColumns[I].Direction;
end;

procedure TCssVirtualStringTree.SetSortColumn(
  Column: Integer;
  Direction: TCssSortDirection;
  AddToExisting: Boolean);
var
  I: Integer;
begin
  if Column < 0 then
    Exit;

  I := GetSortIndex(Column);

  if not AddToExisting then
  begin
    SetLength(FSortColumns, 0);

    if Direction <> csdNone then
    begin
      SetLength(FSortColumns, 1);
      FSortColumns[0].Column := Column;
      FSortColumns[0].Direction := Direction;
    end;
  end
  else
  begin
    if I >= 0 then
    begin
      if Direction = csdNone then
        DeleteSortIndex(I)
      else
        FSortColumns[I].Direction := Direction;
    end
    else if Direction <> csdNone then
    begin
      SetLength(FSortColumns, Length(FSortColumns) + 1);
      FSortColumns[High(FSortColumns)].Column := Column;
      FSortColumns[High(FSortColumns)].Direction := Direction;
    end;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.SortBySortColumns;
begin
  BeginUpdate;
  try
    SortNodeChildren(FRoot, True);
  finally
    EndUpdate;
  end;
end;

procedure TCssVirtualStringTree.SortNodeChildren(
  Node: TCssVirtualNode;
  Recursive: Boolean);
var
  List: TList;
  Child: TCssVirtualNode;
  I: Integer;
begin
  if Node = nil then
    Node := FRoot;

  if Length(FSortColumns) = 0 then
    Exit;

  BeginUpdate;
  try
    if Node.ChildCount > 1 then
    begin
      List := TList.Create;
      try
        Child := Node.FirstChild;

        while Child <> nil do
        begin
          List.Add(Child);
          Child := Child.NextSibling;
        end;

        SortList(List);

        Node.FirstChild := nil;
        Node.LastChild := nil;
        Node.ChildCount := 0;

        for I := 0 to List.Count - 1 do
        begin
          Child := TCssVirtualNode(List[I]);
          Child.PrevSibling := Node.LastChild;
          Child.NextSibling := nil;

          if Node.LastChild = nil then
            Node.FirstChild := Child
          else
            Node.LastChild.NextSibling := Child;

          Node.LastChild := Child;
          Inc(Node.ChildCount);
        end;
      finally
        List.Free;
      end;
    end;

    if Recursive then
    begin
      Child := Node.FirstChild;

      while Child <> nil do
      begin
        SortNodeChildren(Child, True);
        Child := Child.NextSibling;
      end;
    end;

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

// --- Lazy loading ---

procedure TCssVirtualStringTree.ReloadChildren(Node: TCssVirtualNode);
begin
  if Node = nil then
    Node := FRoot;

  BeginUpdate;
  try
    DeleteChildren(Node);

    Exclude(Node.States, cvsChildrenLoaded);

    if (Node = FRoot) or (cvsExpanded in Node.States) then
    begin
      EnsureChildrenLoaded(Node);
      AutoSortNode(Node, False);
    end;

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

// --- Drag & drop structure ---

procedure TCssVirtualStringTree.MoveNode(
  Source, NewParent: TCssVirtualNode);
begin
  if (Source = nil) or (Source = FRoot) then
    Exit;

  if NewParent = nil then
    NewParent := FRoot;

  if Source = NewParent then
    Exit;

  if IsNodeInSubTree(NewParent, Source) then
    Exit;

  BeginUpdate;
  try
    // Detach
    if Source.PrevSibling <> nil then
      Source.PrevSibling.NextSibling := Source.NextSibling
    else
      Source.Parent.FirstChild := Source.NextSibling;

    if Source.NextSibling <> nil then
      Source.NextSibling.PrevSibling := Source.PrevSibling
    else
      Source.Parent.LastChild := Source.PrevSibling;

    Dec(Source.Parent.ChildCount);

    if Source.Parent.ChildCount = 0 then
    begin
      Exclude(Source.Parent.States, cvsHasChildren);
      Exclude(Source.Parent.States, cvsExpanded);
    end;

    // Attach
    Source.Parent := NewParent;
    Source.PrevSibling := NewParent.LastChild;
    Source.NextSibling := nil;

    if NewParent.ChildCount = 0 then
    begin
      NewParent.FirstChild := Source;
    end
    else
    begin
      NewParent.LastChild.NextSibling := Source;
    end;

    NewParent.LastChild := Source;
    Inc(NewParent.ChildCount);
    Include(NewParent.States, cvsHasChildren);

    FNeedRebuild := True;
  finally
    EndUpdate;
  end;
end;

procedure TCssVirtualStringTree.MoveNodes(
  Nodes: TList;
  NewParent: TCssVirtualNode);
var
  I: Integer;
  Node: TCssVirtualNode;
begin
  if Nodes = nil then
    Exit;

  if NewParent = nil then
    NewParent := FRoot;

  BeginUpdate;
  try
    for I := 0 to Nodes.Count - 1 do
    begin
      Node := TCssVirtualNode(Nodes[I]);

      if Node = nil then
        Continue;

      if Node = FRoot then
        Continue;

      if IsNodeInSubTree(NewParent, Node) then
        Continue;

      if IsNodeInSubTreeOfAny(Node, Nodes) then
        Continue;

      MoveNode(Node, NewParent);
    end;
  finally
    EndUpdate;
  end;
end;

// --- Auto-size columns ---

procedure TCssVirtualStringTree.AutoSizeColumns(IncludeHeader: Boolean);
var
  I, J: Integer;
  MaxW, W: Integer;
  S: string;
  Node: TCssVirtualNode;
  Size: TSize;
begin
  if FColumns.Count = 0 then
    Exit;

  UpdateCanvasFont;

  for I := 0 to FColumns.Count - 1 do
  begin
    MaxW := 16;

    if IncludeHeader then
    begin
      W := Canvas.TextWidth(FColumns[I].Text) + 24;

      if W > MaxW then
        MaxW := W;
    end;

    for J := 0 to VisibleCount - 1 do
    begin
      Node := GetVisibleNode(J);
      S := GetCellText(Node, I);

      if HtmlMode then
        Size := MeasureHtmlTextSize(S, 0)
      else
        Size.cx := Canvas.TextWidth(S);

      W := Size.cx + 16;

      if W > MaxW then
        MaxW := W;
    end;

    FColumns[I].Width := MaxW;
  end;

  UpdateScrollBars;
  Invalidate;
end;

// --- Scrollbar utilities ---

function TCssVirtualStringTree.ScrollBarAt(
  X, Y: Integer): TCssScrollBar;
var
  P: TPoint;
begin
  Result := nil;
  P := Point(X, Y);

  if Assigned(FVScroll) and FVScroll.Visible and PtInRect(FVScrollRect, P) then
    Exit(FVScroll);

  if Assigned(FHScroll) and FHScroll.Visible and PtInRect(FHScrollRect, P) then
    Exit(FHScroll);
end;

procedure TCssVirtualStringTree.DrawInternalScrollBars;
begin
  if Assigned(FVScroll) and
     FVScroll.Visible and
     (FVScrollRect.Right > FVScrollRect.Left) and
     (FVScrollRect.Bottom > FVScrollRect.Top) then
  begin
    FVScroll.DrawToCanvas(Canvas, FVScrollRect);
  end;

  if Assigned(FHScroll) and
     FHScroll.Visible and
     (FHScrollRect.Right > FHScrollRect.Left) and
     (FHScrollRect.Bottom > FHScrollRect.Top) then
  begin
    FHScroll.DrawToCanvas(Canvas, FHScrollRect);
  end;
end;

// --- Rounded-corner masking ---

function TCssVirtualStringTree.GetParentBackgroundColor: TColor;
begin
  Result := clNone;

  if Parent <> nil then
    Result := Parent.Brush.Color;

  if Result = clNone then
    Result := Color;

  if Result = clDefault then
    Result := clBtnFace;
end;

procedure TCssVirtualStringTree.DrawRoundedCornerMask;
var
  R: TRect;
  Radius: Integer;
  MaskColor: TColor;
  Pts: array of TPoint;
  PtCount: Integer;

  procedure AddPt(X, Y: Integer);
  begin
    SetLength(Pts, PtCount + 1);
    Pts[PtCount] := Point(X, Y);
    Inc(PtCount);
  end;

  procedure DrawCorner(Corner: Integer);
  var
    I: Integer;
    CX, CY: Integer;
    StartAngle, EndAngle, Angle: Double;
  begin
    PtCount := 0;
    SetLength(Pts, 0);

    case Corner of
      // Top-left
      0:
      begin
        AddPt(R.Left, R.Top);
        AddPt(R.Left + Radius, R.Top);

        CX := R.Left + Radius;
        CY := R.Top + Radius;

        StartAngle := Pi * 1.5;
        EndAngle := Pi;

        for I := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (I / 16);
          AddPt(
            CX + Round(Radius * Cos(Angle)),
            CY + Round(Radius * Sin(Angle))
          );
        end;

        AddPt(R.Left, R.Top + Radius);
      end;

      // Top-right
      1:
      begin
        AddPt(R.Right, R.Top);
        AddPt(R.Right - Radius, R.Top);

        CX := R.Right - Radius;
        CY := R.Top + Radius;

        StartAngle := Pi * 1.5;
        EndAngle := Pi * 2;

        for I := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (I / 16);
          AddPt(
            CX + Round(Radius * Cos(Angle)),
            CY + Round(Radius * Sin(Angle))
          );
        end;

        AddPt(R.Right, R.Top + Radius);
      end;

      // Bottom-right
      2:
      begin
        AddPt(R.Right, R.Bottom);
        AddPt(R.Right, R.Bottom - Radius);

        CX := R.Right - Radius;
        CY := R.Bottom - Radius;

        StartAngle := 0;
        EndAngle := Pi * 0.5;

        for I := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (I / 16);
          AddPt(
            CX + Round(Radius * Cos(Angle)),
            CY + Round(Radius * Sin(Angle))
          );
        end;

        AddPt(R.Right - Radius, R.Bottom);
      end;

      // Bottom-left
      3:
      begin
        AddPt(R.Left, R.Bottom);
        AddPt(R.Left + Radius, R.Bottom);

        CX := R.Left + Radius;
        CY := R.Bottom - Radius;

        StartAngle := Pi * 0.5;
        EndAngle := Pi;

        for I := 0 to 16 do
        begin
          Angle := StartAngle + (EndAngle - StartAngle) * (I / 16);
          AddPt(
            CX + Round(Radius * Cos(Angle)),
            CY + Round(Radius * Sin(Angle))
          );
        end;

        AddPt(R.Left, R.Bottom - Radius);
      end;
    end;

    if PtCount > 2 then
      Canvas.Polygon(Pts);
  end;

begin
  Radius := GetCssBorderRadius;

  if Radius <= 0 then
    Exit;

  R := ClientRect;

  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  if Radius > (R.Right - R.Left) div 2 then
    Radius := (R.Right - R.Left) div 2;

  if Radius > (R.Bottom - R.Top) div 2 then
    Radius := (R.Bottom - R.Top) div 2;

  if Radius <= 0 then
    Exit;

  MaskColor := GetParentBackgroundColor;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := MaskColor;
  Canvas.Pen.Style := psClear;

  DrawCorner(0);
  DrawCorner(1);
  DrawCorner(2);
  DrawCorner(3);

  Canvas.Pen.Style := psSolid;
end;

// --- Column clip rect ---

function TCssVirtualStringTree.GetColumnClipRect(
  Column: Integer;
  const VertR: TRect): TRect;
begin
  if Column < FFixedColumns then
    Result := GetFixedAreaRect
  else
    Result := GetScrollAreaRect;

  Result.Top := VertR.Top;
  Result.Bottom := VertR.Bottom;

  if Result.Right < Result.Left then
    Result.Right := Result.Left;

  if Result.Bottom < Result.Top then
    Result.Bottom := Result.Top;
end;

// --- Alignment (tree-level) ---

procedure TCssVirtualStringTree.SetHeaderHAlign(AValue: TCssTreeHAlign);
begin
  if FHeaderHAlign = AValue then
    Exit;

  FHeaderHAlign := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetHeaderVAlign(AValue: TCssTreeVAlign);
begin
  if FHeaderVAlign = AValue then
    Exit;

  FHeaderVAlign := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetCellHAlign(AValue: TCssTreeHAlign);
begin
  if FCellHAlign = AValue then
    Exit;

  FCellHAlign := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetCellVAlign(AValue: TCssTreeVAlign);
begin
  if FCellVAlign = AValue then
    Exit;

  FCellVAlign := AValue;
  Invalidate;
end;

// --- Per-node alignment helpers ---

function TCssVirtualStringTree.FindCellAlignIndex(
  Node: TCssVirtualNode;
  Column: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  if Node = nil then
    Exit;

  for I := 0 to High(Node.CellAligns) do
  begin
    if Node.CellAligns[I].Column = Column then
      Exit(I);
  end;
end;

procedure TCssVirtualStringTree.RemoveCellAlign(
  Node: TCssVirtualNode;
  Index: Integer);
var
  I, Count: Integer;
begin
  if Node = nil then
    Exit;

  Count := Length(Node.CellAligns);

  if (Index < 0) or (Index >= Count) then
    Exit;

  for I := Index to Count - 2 do
    Node.CellAligns[I] := Node.CellAligns[I + 1];

  SetLength(Node.CellAligns, Count - 1);
end;

procedure TCssVirtualStringTree.RemoveCellAlignIfInherit(
  Node: TCssVirtualNode;
  Index: Integer);
begin
  if Node = nil then
    Exit;

  if (Index < 0) or (Index >= Length(Node.CellAligns)) then
    Exit;

  if (Node.CellAligns[Index].HAlign = thaInherit) and
     (Node.CellAligns[Index].VAlign = tvaInherit) then
  begin
    RemoveCellAlign(Node, Index);
  end;
end;

procedure TCssVirtualStringTree.SetNodeHAlign(
  Node: TCssVirtualNode;
  AValue: TCssTreeHAlign);
begin
  if Node = nil then
    Exit;

  if Node.HAlign = AValue then
    Exit;

  Node.HAlign := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetNodeVAlign(
  Node: TCssVirtualNode;
  AValue: TCssTreeVAlign);
begin
  if Node = nil then
    Exit;

  if Node.VAlign = AValue then
    Exit;

  Node.VAlign := AValue;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetNodeAlign(
  Node: TCssVirtualNode;
  HAlign: TCssTreeHAlign;
  VAlign: TCssTreeVAlign);
begin
  if Node = nil then
    Exit;

  Node.HAlign := HAlign;
  Node.VAlign := VAlign;

  Invalidate;
end;

procedure TCssVirtualStringTree.SetCellHAlign(
  Node: TCssVirtualNode;
  Column: Integer;
  AValue: TCssTreeHAlign);
var
  Index: Integer;
begin
  if Node = nil then
    Exit;

  Index := FindCellAlignIndex(Node, Column);

  if AValue = thaInherit then
  begin
    if Index >= 0 then
    begin
      Node.CellAligns[Index].HAlign := thaInherit;
      RemoveCellAlignIfInherit(Node, Index);
    end;
  end
  else
  begin
    if Index < 0 then
    begin
      Index := Length(Node.CellAligns);
      SetLength(Node.CellAligns, Index + 1);

      Node.CellAligns[Index].Column := Column;
      Node.CellAligns[Index].HAlign := AValue;
      Node.CellAligns[Index].VAlign := tvaInherit;
    end
    else
    begin
      Node.CellAligns[Index].HAlign := AValue;
    end;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.SetCellVAlign(
  Node: TCssVirtualNode;
  Column: Integer;
  AValue: TCssTreeVAlign);
var
  Index: Integer;
begin
  if Node = nil then
    Exit;

  Index := FindCellAlignIndex(Node, Column);

  if AValue = tvaInherit then
  begin
    if Index >= 0 then
    begin
      Node.CellAligns[Index].VAlign := tvaInherit;
      RemoveCellAlignIfInherit(Node, Index);
    end;
  end
  else
  begin
    if Index < 0 then
    begin
      Index := Length(Node.CellAligns);
      SetLength(Node.CellAligns, Index + 1);

      Node.CellAligns[Index].Column := Column;
      Node.CellAligns[Index].HAlign := thaInherit;
      Node.CellAligns[Index].VAlign := AValue;
    end
    else
    begin
      Node.CellAligns[Index].VAlign := AValue;
    end;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.SetCellAlign(
  Node: TCssVirtualNode;
  Column: Integer;
  HAlign: TCssTreeHAlign;
  VAlign: TCssTreeVAlign);
var
  Index: Integer;
begin
  if Node = nil then
    Exit;

  Index := FindCellAlignIndex(Node, Column);

  if (HAlign = thaInherit) and (VAlign = tvaInherit) then
  begin
    if Index >= 0 then
      RemoveCellAlign(Node, Index);
  end
  else
  begin
    if Index < 0 then
    begin
      Index := Length(Node.CellAligns);
      SetLength(Node.CellAligns, Index + 1);
      Node.CellAligns[Index].Column := Column;
    end;

    Node.CellAligns[Index].HAlign := HAlign;
    Node.CellAligns[Index].VAlign := VAlign;
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.ClearCellAligns(Node: TCssVirtualNode);
begin
  if Node = nil then
    Exit;

  SetLength(Node.CellAligns, 0);
  Invalidate;
end;

function TCssVirtualStringTree.GetNodeHAlign(
  Node: TCssVirtualNode): TCssTreeHAlign;
begin
  if Node = nil then
    Result := thaInherit
  else
    Result := Node.HAlign;
end;

function TCssVirtualStringTree.GetNodeVAlign(
  Node: TCssVirtualNode): TCssTreeVAlign;
begin
  if Node = nil then
    Result := tvaInherit
  else
    Result := Node.VAlign;
end;

function TCssVirtualStringTree.GetCellHAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssTreeHAlign;
var
  Index: Integer;
begin
  Result := thaInherit;

  if Node = nil then
    Exit;

  Index := FindCellAlignIndex(Node, Column);

  if Index >= 0 then
    Result := Node.CellAligns[Index].HAlign;
end;

function TCssVirtualStringTree.GetCellVAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssTreeVAlign;
var
  Index: Integer;
begin
  Result := tvaInherit;

  if Node = nil then
    Exit;

  Index := FindCellAlignIndex(Node, Column);

  if Index >= 0 then
    Result := Node.CellAligns[Index].VAlign;
end;

function TCssVirtualStringTree.GetEffectiveCellHAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssTextAlign;
begin
  Result := ResolveCellHAlign(Node, Column);
end;

function TCssVirtualStringTree.GetEffectiveCellVAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssVAlign;
begin
  Result := ResolveCellVAlign(Node, Column);
end;

// --- Alignment resolution ---

function TCssVirtualStringTree.ResolveHeaderHAlign(
  Column: Integer): TCssTextAlign;
var
  A: TCssTreeHAlign;
begin
  A := thaInherit;

  if Assigned(FColumns) and
     (Column >= 0) and
     (Column < FColumns.Count) then
  begin
    A := FColumns[Column].FHeaderHAlign;
  end;

  if A = thaInherit then
    A := FHeaderHAlign;

  if (A = thaInherit) and FHeaderHAlignCssSet then
    A := FHeaderHAlignCss;

  case A of
    thaLeft:
      Result := ctaLeft;

    thaCenter:
      Result := ctaCenter;

    thaRight:
      Result := ctaRight;

  else
    Result := GetCssTextAlign;
  end;
end;

function TCssVirtualStringTree.ResolveHeaderVAlign(
  Column: Integer): TCssVAlign;
var
  A: TCssTreeVAlign;
begin
  A := tvaInherit;

  if Assigned(FColumns) and
     (Column >= 0) and
     (Column < FColumns.Count) then
  begin
    A := FColumns[Column].FHeaderVAlign;
  end;

  if A = tvaInherit then
    A := FHeaderVAlign;

  if (A = tvaInherit) and FHeaderVAlignCssSet then
    A := FHeaderVAlignCss;

  case A of
    tvaTop:
      Result := cvaTop;

    tvaMiddle:
      Result := cvaMiddle;

    tvaBottom:
      Result := cvaBottom;

  else
    Result := GetCssVAlign;
  end;
end;

function TCssVirtualStringTree.ResolveCellHAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssTextAlign;
var
  A: TCssTreeHAlign;
  Index: Integer;
begin
  A := thaInherit;

  if Node <> nil then
  begin
    Index := FindCellAlignIndex(Node, Column);

    if Index >= 0 then
      A := Node.CellAligns[Index].HAlign;

    if A = thaInherit then
      A := Node.HAlign;
  end;

  if (A = thaInherit) and
     Assigned(FColumns) and
     (Column >= 0) and
     (Column < FColumns.Count) then
  begin
    A := FColumns[Column].FCellHAlign;
  end;

  if A = thaInherit then
    A := FCellHAlign;

  if (A = thaInherit) and FCellHAlignCssSet then
    A := FCellHAlignCss;

  case A of
    thaLeft:
      Result := ctaLeft;

    thaCenter:
      Result := ctaCenter;

    thaRight:
      Result := ctaRight;

  else
    Result := GetCssTextAlign;
  end;
end;

function TCssVirtualStringTree.ResolveCellVAlign(
  Node: TCssVirtualNode;
  Column: Integer): TCssVAlign;
var
  A: TCssTreeVAlign;
  Index: Integer;
begin
  A := tvaInherit;

  if Node <> nil then
  begin
    Index := FindCellAlignIndex(Node, Column);

    if Index >= 0 then
      A := Node.CellAligns[Index].VAlign;

    if A = tvaInherit then
      A := Node.VAlign;
  end;

  if (A = tvaInherit) and
     Assigned(FColumns) and
     (Column >= 0) and
     (Column < FColumns.Count) then
  begin
    A := FColumns[Column].FCellVAlign;
  end;

  if A = tvaInherit then
    A := FCellVAlign;

  if (A = tvaInherit) and FCellVAlignCssSet then
    A := FCellVAlignCss;

  case A of
    tvaTop:
      Result := cvaTop;

    tvaMiddle:
      Result := cvaMiddle;

    tvaBottom:
      Result := cvaBottom;

  else
    Result := GetCssVAlign;
  end;
end;

// --- Checkbox helpers ---

function TCssVirtualStringTree.CreateCheckBoxHelper(
  AChecked, AHover: Boolean): TCssCheckBox;
begin
  Result := TCssCheckBox.Create(Self);

  Result.TabStop := False;
  Result.AutoSize := False;
  Result.ShowFocusRect := False;
  Result.CssTag := 'checkbox';
  Result.Caption := '';

  Result.SetVisualState(AChecked, AHover);
end;

function TCssVirtualStringTree.ComposeCheckBoxCssStyle: string;
begin
  Result := Trim(FCheckBoxCssStyle);

  if FCheckBoxInlineCss <> '' then
  begin
    if Result <> '' then
      Result := Result + ';';

    Result := Result + FCheckBoxInlineCss;
  end;
end;

procedure TCssVirtualStringTree.SetupCheckBoxHelper(
  CB: TCssCheckBox;
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

procedure TCssVirtualStringTree.UpdateCheckBoxStyle;
begin
  SetupCheckBoxHelper(FCheckBoxNormal, False, False);
  SetupCheckBoxHelper(FCheckBoxChecked, True, False);
  SetupCheckBoxHelper(FCheckBoxHover, False, True);
  SetupCheckBoxHelper(FCheckBoxCheckedHover, True, True);
end;

procedure TCssVirtualStringTree.RefreshCheckBoxStyle;
begin
  UpdateCheckBoxStyle;
end;

procedure TCssVirtualStringTree.SetCheckBoxCssClass(const AValue: string);
begin
  if FCheckBoxCssClass = AValue then
    Exit;

  FCheckBoxCssClass := AValue;
  UpdateCheckBoxStyle;
  Invalidate;
end;

procedure TCssVirtualStringTree.SetCheckBoxCssStyle(const AValue: string);
begin
  if FCheckBoxCssStyle = AValue then
    Exit;

  FCheckBoxCssStyle := AValue;
  UpdateCheckBoxStyle;
  Invalidate;
end;

// --- Enabled state ---

procedure TCssVirtualStringTree.EnabledChanged;
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

  Invalidate;
end;

// --- Node enabled/disabled API ---

function TCssVirtualStringTree.IsNodeDisabled(Node: TCssVirtualNode): Boolean;
begin
  Result := Assigned(Node) and (cvsDisabled in Node.States);
end;

function TCssVirtualStringTree.IsNodeEnabled(Node: TCssVirtualNode): Boolean;
begin
  Result := Assigned(Node) and not (cvsDisabled in Node.States);
end;

procedure TCssVirtualStringTree.SetNodeEnabled(
  Node: TCssVirtualNode;
  AValue: Boolean);
begin
  if Node = nil then
    Exit;

  if AValue then
  begin
    if not (cvsDisabled in Node.States) then
      Exit;

    Exclude(Node.States, cvsDisabled);
  end
  else
  begin
    if cvsDisabled in Node.States then
      Exit;

    Include(Node.States, cvsDisabled);

    // A disabled node must not remain selected.
    if IsSelected(Node) then
      RemoveFromSelection(Node);

    if FSelectedNode = Node then
      FSelectedNode := nil;

    if FHoverNode = Node then
      FHoverNode := nil;

    if FAnchorNode = Node then
      FAnchorNode := nil;

    if FDropTargetNode = Node then
      FDropTargetNode := nil;

    if FEditingNode = Node then
      EndEditing(True);
  end;

  Invalidate;
end;

procedure TCssVirtualStringTree.DisableNode(Node: TCssVirtualNode);
begin
  SetNodeEnabled(Node, False);
end;

procedure TCssVirtualStringTree.EnableNode(Node: TCssVirtualNode);
begin
  SetNodeEnabled(Node, True);
end;

// --- Plain text helper ---

function TCssVirtualStringTree.PlainCellText(
  Node: TCssVirtualNode;
  Column: Integer): string;
begin
  Result := GetCellText(Node, Column);

  if HtmlMode then
    Result := HtmlToPlainText(Result);
end;

// --- Navigation clamp helpers ---

function TCssVirtualStringTree.ClampVisibleIndex(AValue: Integer): Integer;
var
  Count: Integer;
begin
  Count := VisibleCount;

  if Count <= 0 then
    Exit(-1);

  if AValue < 0 then
    Result := 0
  else if AValue >= Count then
    Result := Count - 1
  else
    Result := AValue;
end;

function TCssVirtualStringTree.FindEnabledVisibleIndex(
  ATarget, ADirection: Integer): Integer;
var
  Count: Integer;
  I: Integer;
  Node: TCssVirtualNode;
begin
  Result := -1;

  Count := VisibleCount;

  if Count <= 0 then
    Exit;

  I := ClampVisibleIndex(ATarget);

  if I < 0 then
    Exit;

  if ADirection = 0 then
    ADirection := 1;

  while (I >= 0) and (I < Count) do
  begin
    Node := GetVisibleNode(I);

    if (Node <> nil) and (not IsNodeDisabled(Node)) then
      Exit(I);

    I := I + ADirection;
  end;
end;

function TCssVirtualStringTree.FindNearestEnabledVisibleIndex(
  AIndex: Integer): Integer;
begin
  Result := FindEnabledVisibleIndex(AIndex, 1);

  if Result < 0 then
    Result := FindEnabledVisibleIndex(AIndex, -1);
end;

function TCssVirtualStringTree.ShouldAutoSort: Boolean;
begin
  Result := FAutoSort and (Length(FSortColumns) > 0);
end;

procedure TCssVirtualStringTree.AutoSortNode(
  Node: TCssVirtualNode;
  Recursive: Boolean);
begin
  if ShouldAutoSort then
    SortNodeChildren(Node, Recursive);
end;

end.
