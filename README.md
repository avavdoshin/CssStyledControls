# CssStyledControls

A set of visual controls for **Lazarus / Free Pascal (LCL)** that are fully stylable with **CSS** and support **HTML formatting** for their text content.

The library brings a modern, web-like approach to desktop GUI development: instead of tweaking dozens of properties by hand, you describe the look of every control in a single CSS file — complete with selectors, pseudo-classes, cascading, specificity, CSS variants (themes), and inline styles.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Included Controls](#included-controls)
- [CSS Overview](#css-overview)
- [General CSS Properties](#general-css-properties)
- [Per-Control CSS Properties](#per-control-css-properties)
- [HTML Formatting](#html-formatting)
- [Link Handling](#link-handling)
- [Tooltips with CSS and HTML](#tooltips-with-css-and-html)
- [Style Provider API](#style-provider-api)
- [Design-Time Support](#design-time-support)
- [Example Theme](#example-theme)
- [License](#license)

---

## Features

- **Full CSS styling** — every control reads its appearance from CSS rules, including background, borders, radius, padding, fonts, colors, alignment, opacity, text shadows, and more.
- **CSS selectors** — match by class name, `CssTag`, `CssID`, `CssClass`, pseudo-classes (`:hover`, `:active`, `:focus`, `:disabled`, `:checked`, …) and combinators.
- **Pseudo-classes** — `:hover`, `:active`, `:focus`, `:focus-visible`, `:enabled`, `:disabled`, `:checked`, `:unchecked`.
- **Cascading and specificity** — later rules and more specific rules win, exactly like in the browser.
- **Themes / variants** — a single CSS file can contain several `@variant <name>` blocks (e.g. `light` and `dark`), switchable at runtime through `TCssStyleProvider`.
- **HTML text rendering** — `HtmlMode` renders captions, list items, menu items, tree cells, and hints as HTML with inline styles, lists, headings, code blocks, links, etc.
- **Clickable links** — `<a href="...">` inside HTML content raises `OnLinkClick`, changes the cursor, and supports `a`, `a:hover`, `a:active` CSS rules.
- **CSS-styled tooltips** — tooltips can be styled with the `::hint` selector and rendered as HTML.
- **Nested child styling** — composite controls (`TCssComboBox`, `TCssCheckGroup`, `TCssRadioGroup`, `TCssListBox`, `TCssVirtualStringTree`) expose `*CssClass` / `*CssStyle` properties so you can style their internal children too.
- **Design-time editor** — `TCssStyleProvider` ships with a multi-line CSS editor and a file picker, and can be edited from the Object Inspector.
- **No external dependencies** — pure LCL, works on Windows, Linux, and macOS.

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/avavdoshin/CssStyledControls.git
   ```

2. Open the package `CssStyledControls.lpk` in Lazarus (`Package → Open Package File…`).

3. Click **Compile**, then **Use → Install**.

   The design-time package `CssStyledControlsDesign.lpk` should be installed together with it (it adds the CSS editor and file picker to the Object Inspector).

4. The component palette gets a new tab `CSSStyledControls` with all controls and the `TCssStyleProvider` component.

---

## Quick Start

1. Drop a `TCssStyleProvider` onto a form (or a data module).
2. Fill its `CssText` property (or set `FileName` to a `.css` file), for example:

   ```css
   TCssButton {
     background-color: #2563EB;
     color: #FFFFFF;
     border: 1px solid #2563EB;
     border-radius: 6px;
     padding: 6px 14px;
     text-align: center;
     vertical-align: middle;
   }
   TCssButton:hover  { background-color: #1D4ED8; }
   TCssButton:active { background-color: #1E40AF; }
   TCssButton:disabled {
     background-color: #F1F5F9;
     color: #94A3B8;
     border-color: #E2E8F0;
   }
   ```

3. Drop a `TCssButton` (or any other `TCss*` control) onto the same form and assign its `StyleProvider` property to the provider created in step 1. Every control that references the provider is automatically restyled whenever the CSS text changes.

4. (Optional) Set `HtmlMode := True` on a control and use HTML in its `Caption`:

   ```html
   <b>Save</b> <span style="color:#f00">now</span>
   ```

---

## Included Controls

| Control                   | Description                                                             |
| ------------------------- | ----------------------------------------------------------------------- |
| `TCssStyledControl`       | Base class of all CSS-styled controls. Contains the CSS engine.         |
| `TCssStyleProvider`       | Non-visual component that holds CSS text and pushes it to controls.     |
| `TCssButton`              | Push button with `Default`, `Cancel` and `ModalResult` support.         |
| `TCssCheckBox`            | Tri-state check box (`Checked`, `State`, `AllowGrayed`).                |
| `TCssCheckGroup`          | Group of check boxes laid out in columns, with per-item state.          |
| `TCssRadioButton`         | Radio button (auto-unchecks siblings).                                  |
| `TCssRadioGroup`          | Group of radio buttons laid out in columns.                             |
| `TCssComboBox`            | Dropdown combo box (`ccsDropDown`, `ccsDropDownList`).                  |
| `TCssEdit`                | Single-line editor with selection, clipboard, undo, placeholder.        |
| `TCssMemo`                | Multi-line editor with word-wrap, scrollbars, selection, clipboard.     |
| `TCssLabel`               | Label with `FocusControl`, `ShowAccelChar`, `Transparent`.              |
| `TCssListBox`             | List box with multi-select, hover, per-item colors, custom scrollbar.   |
| `TCssPanel`               | Container panel.                                                        |
| `TCssGroupBox`            | Group box with optional caption on the border.                          |
| `TCssScrollBar`           | Custom scrollbar (can be drawn standalone or inside another control).   |
| `TCssSplitter`            | Splitter with grip and live/ghost preview.                              |
| `TCssMainMenu`            | Menu bar with dropdowns.                                                |
| `TCssPopupMenu`           | Popup menu component (non-visual) with `Popup` / `AutoPopup`.           |
| `TCssTabControl`          | Tab strip without pages.                                                |
| `TCssPageControl`         | Tab control with pages (`TCssTabSheet`).                                |
| `TCssTabSheet`            | A single page of a `TCssPageControl`.                                   |
| `TCssVirtualStringTree`   | Virtual tree view with columns, checkboxes, editing, drag & drop.       |

---

## CSS Overview

### Where the CSS Lives

There are three ways to give a control its CSS rules, applied in this order (later sources override earlier ones):

1. `TCssStyleProvider` — the recommended way for an application-wide theme. Assign the provider to a control's `StyleProvider` property.
2. `StyleName` — selects a specific variant inside the provider. If empty, the provider's `DefaultStyleName` is used.
3. `CssStyle` — inline declarations applied after everything else. Equivalent to the HTML `style="..."` attribute.

Additionally, `CssTag`, `CssID`, and `CssClass` define how the control is matched by selectors.

### Selectors

A selector is a chain of simple selectors. The engine parses the **last** simple selector in the chain (descendant/child combinators are accepted but only the rightmost part is matched, like in a simplified CSS).

Supported simple selector components:

| Syntax                     | Matches                                                                 |
| -------------------------- | ----------------------------------------------------------------------- |
| `*`                        | Any control.                                                            |
| `Name`                     | The control's class name (`TCssButton`), `CssTag`, `'control'`, or `'TCssStyledControl'`. |
| `#id`                      | `CssID`.                                                                |
| `.class`                   | One of the classes in `CssClass` (space-separated list, several allowed). |
| `:pseudo`                  | A pseudo-class (see below).                                             |
| `a`, `a:hover`, `a:active` | Rules for HTML links inside `HtmlMode` text.                            |
| `::hint`                   | Rules for the control's tooltip.                                        |

Example:

```css
TCssButton                 { /* by class name */ }
button.primary             { /* by tag + class  */ }
#saveButton                { /* by id           */ }
TCssButton:hover           { /* pseudo-class    */ }
a                          { /* html link       */ }
a:hover                    { /* hovered link    */ }
::hint                     { /* tooltip         */ }
```

### Pseudo-Classes

| Pseudo-class       | Active when…                                            |
| ------------------ | ------------------------------------------------------- |
| `:hover`           | The mouse is over the control.                          |
| `:active`          | The left mouse button is pressed on the control.        |
| `:focus`           | The control has focus.                                  |
| `:focus-visible`   | Same as `:focus`.                                       |
| `:enabled`         | `Enabled = True`.                                       |
| `:disabled`        | `Enabled = False`.                                      |
| `:checked`         | `Checked = True`.                                       |
| `:unchecked`       | `Checked = False`.                                      |

### Specificity and Cascade

Rules are sorted by a simplified specificity tuple, then by source order:

1. **A** — number of `#id` parts (`0` or `1`).
2. **B** — number of `.class` and `:pseudo` parts.
3. **C** — `1` if a type/tag name was present, else `0`.

If everything is equal, rules that appear later in the CSS text win. Inline styles (`CssStyle`) are applied last of all.

### Themes (Variants)

A single CSS text may contain several named variants. Each variant starts with a marker:

```css
@variant light
TCssButton { background-color: #2563EB; color: #FFFFFF; }

@variant dark
TCssButton { background-color: #3B82F6; color: #FFFFFF; }
```

The alternative bracket syntax is also accepted:

```css
[light]
TCssButton { /* ... */ }

[dark]
TCssButton { /* ... */ }
```

At runtime, choose the theme by setting the provider's `DefaultStyleName` or a control's `StyleName`:

```pascal
CssStyleProvider1.DefaultStyleName := 'dark';
// or per control:
CssButton1.StyleName := 'dark';
```

A file without any `@variant` marker is treated as a single variant named by `DefaultStyleName` (`'default'` by default).

---

## General CSS Properties

These declarations are understood by **every** `TCssStyledControl` descendant.

### Background

| Property            | Example                          | Notes                                                 |
| ------------------- | -------------------------------- | ----------------------------------------------------- |
| `background`        | `background: #fff;`              | Shorthand; picks the first color token.               |
| `background-color`  | `background-color: transparent;` | `transparent` means "do not fill".                    |

### Text

| Property          | Values                                        | Notes                                                 |
| ----------------- | --------------------------------------------- | ----------------------------------------------------- |
| `color`           | CSS color                                     | Text color.                                           |
| `text-align`      | `left` \| `center` \| `right`                 | Horizontal alignment of caption/text.                 |
| `vertical-align`  | `top` \| `middle` / `center` \| `bottom`      | Vertical alignment.                                   |
| `text-shadow`     | `1px 1px #000` / `none`                       | `<dx> <dy> [color]`.                                  |
| `font`            | `italic bold 12pt 'Segoe UI'`                 | Shorthand; the first recognized size wins.            |
| `font-family`     | `'Segoe UI', Arial`                           | First family is used.                                 |
| `font-size`       | `12pt` \| `14px` \| `medium` \| `large` …     | pt is converted to px.                                |
| `font-weight`     | `normal` \| `bold` \| `100`…`900`             | 600 and above ⇒ bold.                                 |
| `font-style`      | `normal` \| `italic` \| `oblique`             |                                                       |

### Border

| Property          | Example                                    | Notes                                                 |
| ----------------- | ------------------------------------------ | ----------------------------------------------------- |
| `border`          | `1px solid #ccc`                           | Shorthand for width / style / color.                  |
| `border-width`    | `1px`, `2px`, `thin`, `medium`, `thick`    |                                                       |
| `border-color`    | `#cccccc`                                  |                                                       |
| `border-style`    | `none` \| `solid` \| `dotted` \| `dashed`  |                                                       |
| `border-radius`   | `6px`                                      | Single value (corners are uniform).                   |

### Spacing

| Property                                                          | Notes                            |
| ----------------------------------------------------------------- | -------------------------------- |
| `padding`                                                         | 1–4 values, CSS shorthand.       |
| `padding-top`, `padding-right`, `padding-bottom`, `padding-left`  | Individual sides.                |

### Interaction and Effects

| Property       | Values                                | Notes                                                |
| -------------- | ------------------------------------- | ---------------------------------------------------- |
| `cursor`       | `pointer`, `text`, `wait`, `move`, …  | Maps to LCL cursor constants.                        |
| `opacity`      | `0.0` … `1.0` (or `50%`)              | Blends the control's colors with its parent color.   |
| `focus-color`  | CSS color                             | Color of the focus rectangle.                        |

### Colors

The following formats are accepted anywhere a color is expected:

- `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`
- `rgb(r, g, b)`, `rgba(r, g, b, a)` with values `0..255` or `0..100%`
- Named colors: `black`, `white`, `red`, `green`, `blue`, `yellow`, `orange`, `purple`, `gray` / `grey`, `silver`, `maroon`, `olive`, `lime`, `aqua` / `cyan`, `teal`, `navy`, `fuchsia` / `magenta`, `pink`, `brown`, `gold`, `khaki`, `beige`, `ivory`, `snow`, `tomato`, `coral`, `salmon`, `darkgray`, `lightgray`, `dimgray`, `whitesmoke`
- `transparent`

### Lengths

Lengths accept `px`, `pt` (converted to px at 96 DPI), unit-less numbers (treated as px), and the keywords `thin` (1), `medium` (2), `thick` (4).

---

## Per-Control CSS Properties

Each control adds its own set of declarations on top of the general ones. All of them are reset by `ResetStyle` and can be overridden via `:hover`, `:active`, `:focus`, `:disabled`, `:checked`, etc.

### TCssButton

No extra properties. Use the standard pseudo-classes.

Additional Pascal properties: `Default`, `Cancel`, `ModalResult`.

### TCssCheckBox

| Property                  | Notes                                              |
| ------------------------- | -------------------------------------------------- |
| `checkbox-background`     | Fill color of the box.                             |
| `checkbox-border-color`   | Border color of the box.                           |
| `checkbox-border-width`   | Border width of the box.                           |
| `checkbox-radius`         | Corner radius of the box.                          |
| `check-color`             | Color of the check mark.                           |

### TCssRadioButton

| Property               | Notes                                              |
| ---------------------- | -------------------------------------------------- |
| `radio-background`     | Fill color of the circle.                          |
| `radio-border-color`   | Border color of the circle.                        |
| `radio-border-width`   | Border width of the circle.                        |
| `radio-radius`         | Corner radius (when < half of the box).            |
| `dot-color`            | Color of the inner dot.                            |

### TCssCheckGroup / TCssRadioGroup

Both are subclasses of `TCssGroupCaptionControl`, so they support `Caption` with `CaptionMode` (`gcmInside`, `gcmOnBorder`) and `CaptionBackgroundColor`.

They expose `CheckBoxCssClass` / `CheckBoxCssStyle` (resp. `RadioCssClass` / `RadioCssStyle`) so their children are styled by a separate CSS rule:

```css
TCssCheckGroup  { /* ... */ }
.checkbox       { /* applied to the child checkboxes */ }
```

### TCssComboBox

| Property                          | Notes                                     |
| --------------------------------- | ----------------------------------------- |
| `combo-button-background`         | Fill of the dropdown button.              |
| `combo-button-hover-background`   | Fill on hover.                            |
| `combo-button-active-background`  | Fill while pressed.                       |
| `combo-button-arrow-color`        | Color of the triangle.                    |
| `combo-button-radius`             | Corner radius of the button.              |

Child controls have their own `*CssClass` / `*CssStyle` properties:

- `EditCssClass`, `EditCssStyle` — the embedded editor.
- `ListBoxCssClass`, `ListBoxCssStyle` — the popup list box.
- `ScrollBarCssClass`, `ScrollBarCssStyle` — the popup scrollbar.

### TCssEdit

| Property                       | Notes                                              |
| ------------------------------ | -------------------------------------------------- |
| `placeholder-color`            | Color of the placeholder text.                     |
| `placeholder-align`            | `left` \| `center` \| `right`.                     |
| `placeholder-font-weight`      | `normal` / `bold` / numeric.                       |
| `placeholder-font-style`       | `normal` / `italic` / `oblique`.                   |
| `placeholder-text-decoration`  | `underline`, `line-through`, `none`.               |

### TCssMemo

| Property                       | Notes                                              |
| ------------------------------ | -------------------------------------------------- |
| `selection-background`         | Background of the selection.                       |
| `selection-color`              | Text color of the selection.                       |
| `caret-color`                  | Caret color.                                       |
| `placeholder-color`            | Color of the placeholder text.                     |
| `placeholder-align`            | `left` \| `center` \| `right`.                     |
| `placeholder-vertical-align`   | `top` \| `middle` / `center` \| `bottom`.          |
| `placeholder-font-weight`      | `normal` / `bold` / numeric.                       |
| `placeholder-font-style`       | `normal` / `italic` / `oblique`.                   |
| `placeholder-text-decoration`  | `underline`, `line-through`, `none`.               |

### TCssListBox

| Property                    | Notes                                              |
| --------------------------- | -------------------------------------------------- |
| `item-background`           | Default item background.                           |
| `item-color`                | Default item text color.                           |
| `item-hover-background`     | Item background on hover.                          |
| `item-hover-color`          | Item text color on hover.                          |
| `item-selected-background`  | Selected item background.                          |
| `item-selected-color`       | Selected item text color.                          |
| `item-height`               | Row height.                                        |

Plus `ScrollBarCssClass` / `ScrollBarCssStyle` for the embedded scrollbar.

### TCssScrollBar

| Property                    | Notes                                              |
| --------------------------- | -------------------------------------------------- |
| `scrolltrack-background`    | Track (groove) background.                         |
| `thumb-background`          | Thumb fill.                                        |
| `thumb-hover-background`    | Thumb fill on hover.                               |
| `thumb-active-background`   | Thumb fill while dragging.                         |
| `thumb-border-color`        | Thumb border.                                      |
| `thumb-radius`              | Thumb corner radius.                               |
| `arrow-color`               | Arrow color.                                       |

### TCssSplitter

| Property        | Notes                                              |
| --------------- | -------------------------------------------------- |
| `grip-color`    | Color of the grip dots.                            |
| `grip-count`    | Number of dots (integer, e.g. `3`).                |
| `grip-size`     | Size of a dot in px.                               |
| `grip-spacing`  | Gap between dots in px.                            |

### Menus (TCssMainMenu, TCssPopupMenu, TCssMenuBase)

| Property                    | Notes                                              |
| --------------------------- | -------------------------------------------------- |
| `menu-background`           | Background of the dropdown.                        |
| `menu-border-color`         | Border of the dropdown.                            |
| `menu-item-height`          | Height of an item.                                 |
| `menu-text-color`           | Text color of items.                               |
| `menu-hover-background`     | Item background on hover.                          |
| `menu-hover-text-color`     | Item text color on hover.                          |
| `menu-disabled-text-color`  | Text color of disabled items.                      |
| `menu-separator-color`      | Separator color.                                   |
| `menu-shortcut-color`       | Shortcut text color.                               |

`TCssMainMenu` additionally supports:

| Property              | Notes                                              |
| --------------------- | -------------------------------------------------- |
| `menubar-background`  | Background of the menu bar itself.                 |

### Tabs (TCssTabControl, TCssPageControl)

| Property                    | Notes                                              |
| --------------------------- | -------------------------------------------------- |
| `tab-background`            | Background of an inactive tab.                     |
| `tab-hover-background`      | Background of a hovered tab.                       |
| `tab-active-background`     | Background of the active tab.                      |
| `tab-text-color`            | Text color of inactive tabs.                       |
| `tab-active-text-color`     | Text color of the active tab.                      |
| `tab-border-color`          | Tab border.                                        |
| `tab-radius`                | Tab corner radius.                                 |
| `tab-spacing`               | Gap between tabs.                                  |
| `tab-padding`               | Horizontal padding inside a tab (used with auto-size). |
| `tab-auto-size`             | `true` / `false` / `1` / `0`.                      |
| `tab-cursor`                | Cursor over an inactive tab.                       |

`cursor` is applied to the content area (over the active tab and empty space).

### TCssVirtualStringTree

| Property                                                                   | Notes                                              |
| -------------------------------------------------------------------------- | -------------------------------------------------- |
| `header-background`                                                        | Header fill.                                       |
| `header-color`                                                             | Header text color.                                 |
| `selection-background`                                                     | Selected row fill.                                 |
| `selection-color`                                                          | Selected row text.                                 |
| `hover-background`                                                         | Hovered row fill.                                  |
| `line-color`                                                               | Grid / separator color.                            |
| `button-color`                                                             | Expand/collapse button color.                      |
| `checkbox-background`                                                      | Passed to the internal checkbox helpers.           |
| `checkbox-border-color`                                                    | Idem.                                              |
| `checkbox-border-width`                                                    | Idem.                                              |
| `checkbox-radius`                                                          | Idem.                                              |
| `check-color`                                                              | Idem.                                              |
| `drop-target-background`                                                   | Highlight of the drop target row.                  |
| `sort-marker-color`                                                        | Sort arrow color.                                  |
| `disabled-background`                                                      | Background of a disabled row.                      |
| `disabled-color`                                                           | Text color of a disabled row.                      |
| `header-height`                                                            | Header height in px.                               |
| `row-height`, `item-height`                                                | Row height in px.                                  |
| `indent`                                                                   | Indent per tree level in px.                       |
| `scrollbar-size`                                                           | Size of the internal scrollbars in px.             |
| `header-text-align`, `header-align`                                        | `left` \| `center` \| `right`.                     |
| `header-vertical-align`, `header-valign`                                   | `top` \| `middle` \| `bottom`.                     |
| `cell-text-align`, `row-text-align`, `node-text-align`                     | `left` \| `center` \| `right`.                     |
| `cell-vertical-align`, `row-vertical-align`, `node-vertical-align`         | `top` \| `middle` \| `bottom`.                     |
| `html-mode`                                                                | `true` / `false` — enables HTML in cells.          |

Child controls also expose `CheckBoxCssClass` / `CheckBoxCssStyle` and `EditStyleName` for the inline editor.

---

## HTML Formatting

Every `TCssStyledControl` supports HTML rendering. Enable it with:

```pascal
CssLabel1.HtmlMode := True;
CssLabel1.Caption  := '<b>Hello</b>, <i>world</i>!';
```

`HtmlMode` affects the rendering of `Caption` in:

- `TCssButton`, `TCssCheckBox`, `TCssRadioButton`, `TCssLabel`, `TCssPanel`, `TCssGroupBox`
- `TCssEdit` (placeholder only), `TCssMemo` (placeholder only)
- `TCssComboBox` (list items)
- `TCssListBox` (items)
- `TCssCheckGroup`, `TCssRadioGroup` (item captions)
- `TCssMainMenu`, `TCssPopupMenu` (item captions)
- `TCssTabControl` / `TCssPageControl` (tab captions)
- `TCssVirtualStringTree` (cell text, when `OnGetText` returns HTML)
- `TCssStyledHintWindow` (tooltips, if `HintHtmlMode` is `True`)

### Supported Tags

| Tag                                                                             | Effect                                      |
| ------------------------------------------------------------------------------- | ------------------------------------------- |
| `<h1>` … `<h6>`                                                                  | Heading (bold, larger font).                |
| `<p>`, `<div>`, `<section>`, `<article>`, `<header>`, `<footer>`                 | Block element.                              |
| `<center>`                                                                       | Centered block.                             |
| `<pre>`, `<xmp>`                                                                 | Preformatted monospace block (line breaks preserved). |
| `<hr>`                                                                           | Horizontal rule.                            |
| `<br>`                                                                           | Line break.                                 |
| `<q>`                                                                            | Adds « and » around the text.               |
| `<b>`, `<strong>`                                                                | Bold.                                       |
| `<i>`, `<em>`                                                                    | Italic.                                     |
| `<u>`, `<ins>`                                                                   | Underline.                                  |
| `<del>`, `<s>`, `<strike>`                                                       | Strike-through.                             |
| `<code>`, `<kbd>`, `<samp>`, `<tt>`                                              | Monospace font.                             |
| `<sup>`                                                                          | Superscript.                                |
| `<sub>`                                                                          | Subscript.                                  |
| `<font color="...">`                                                             | Text color.                                 |
| `<span style="...">`                                                             | Inline style (see below).                   |
| `<ul>`, `<ol>`, `<li>`                                                           | Bullet / numbered list.                     |
| `<a href="...">`                                                                 | Link (see below).                           |

### Supported Inline Styles

Only a small subset of CSS is supported inside `style="..."`:

- `color`
- `font-weight`
- `font-style`
- `text-decoration`

### Block Attributes

- `align="left|center|right"` on `<p>`, `<div>`, `<h1>` … `<h6>`, `<center>`.
- `style="text-align: ..."` on the same elements.

### Entities

The parser decodes: `&nbsp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&amp;`.

### Measuring

All controls measure HTML using the same parser, so `AutoSize` and layout are correct. Use `MeasureHtmlTextSize` if you need to know the size programmatically.

Use `HtmlToPlainText` to strip HTML from a string:

```pascal
Plain := CssLabel1.HtmlToPlainText('<b>Hello</b> <i>world</i>');  // "Hello world"
```

---

## Link Handling

HTML text can contain links:

```pascal
CssLabel1.HtmlMode := True;
CssLabel1.Caption  := 'Visit <a href="https://example.com">our site</a>.';

CssLabel1.OnLinkClick := @LabelLinkClick;

procedure TForm1.LabelLinkClick(Sender: TObject; const AHref, AText: string);
begin
  ShellExecute(0, 'open', PChar(AHref), nil, nil, SW_SHOWNORMAL);
end;
```

Links are highlighted according to the `a`, `a:hover`, `a:active` rules:

```css
a        { color: #2563EB; text-decoration: underline; cursor: pointer; }
a:hover  { color: #1D4ED8; }
a:active { color: #1E40AF; }
```

The cursor automatically becomes `crHandPoint` (or whatever the CSS `cursor` says) when the mouse is over a link.

You can also query the link at a point programmatically:

```pascal
var Href, Text: string;
if CssLabel1.TryGetLinkAt(Point(X, Y), Href, Text) then
  Memo1.Lines.Add(Href + ' -> ' + Text);

CssLabel1.ClickLinkAtPoint(Point(X, Y));
```

---

## Tooltips with CSS and HTML

Set `ShowHint := True`, `Hint := '...'` and (optionally) `HintHtmlMode := True`. Then style the hint with the `::hint` selector:

```css
::hint {
  background-color: #F8FAFC;
  color: #0F172A;
  border: 1px solid #94A3B8;
  border-radius: 6px;
  padding: 6px 10px;
  font-size: 9pt;
  text-align: left;
  vertical-align: top;
}
```

If `HintHtmlMode` is `True`, the hint text is rendered as HTML; otherwise it is plain text.

The hint is drawn by an internal `TCssStyledHintWindow` that uses the same CSS engine, so all general properties (background, border, radius, padding, font, shadow) are supported.

---

## Style Provider API

`TCssStyleProvider` is a non-visual component that holds the CSS text and notifies all registered controls when it changes.

### Key Properties

| Property            | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| `CssText`           | Full CSS text (may contain `@variant` blocks).                    |
| `FileName`          | Path to a `.css` file — loaded automatically on assignment.       |
| `DefaultStyleName`  | Variant used by controls whose `StyleName` is empty.              |
| `StyleCount`        | Number of loaded variants (read-only).                            |
| `StyleNames[Index]` | Name of a variant (read-only).                                    |
| `CssByName[Name]`   | Get/set the CSS text of a single variant.                         |
| `OnChange`          | Fired after the provider's content changes.                       |

### Key Methods

```pascal
CssStyleProvider1.Clear;
CssStyleProvider1.AddOrUpdateStyle('light', 'TCssButton { ... }');
CssStyleProvider1.RemoveStyle('dark');
CssStyleProvider1.HasStyle('light');                  // Boolean
CssStyleProvider1.GetCss('light');                    // string
CssStyleProvider1.SetCss('light', '...');
CssStyleProvider1.LoadFromFile('theme.css');
CssStyleProvider1.LoadFromStrings(Memo1.Lines);
CssStyleProvider1.LoadFromCss('TCssButton { ... }');
CssStyleProvider1.SaveToFile('theme.css');
CssStyleProvider1.RegisterControl(CssButton1);
CssStyleProvider1.UnRegisterControl(CssButton1);
```

### Switching Themes at Runtime

```pascal
procedure TForm1.SetDarkTheme;
begin
  CssStyleProvider1.DefaultStyleName := 'dark';
end;

procedure TForm1.SetLightTheme;
begin
  CssStyleProvider1.DefaultStyleName := 'light';
end;
```

All controls that reference the provider are restyled automatically.

---

## Design-Time Support

Installing `CssStyledControlsDesign.lpk` adds:

- A **multi-line CSS editor** for the `CssText` property of `TCssStyleProvider`.
- A **file picker** for the `FileName` property.
- A **component editor** with an `Edit CSS…` verb on `TCssStyleProvider`.

Right-click a `TCssStyleProvider` on a form and choose **Edit CSS…** to open the editor.

---

## Example Theme

A ready-to-use theme with **light** and **dark** variants is shipped as `ModernTheme.css`. Load it into a `TCssStyleProvider`:

```pascal
CssStyleProvider1.LoadFromFile('ModernTheme.css');
CssStyleProvider1.DefaultStyleName := 'light';   // or 'dark'
```

The file contains rules for every control in the library, so simply dropping a `TCssButton`, `TCssEdit`, `TCssVirtualStringTree`, etc., and assigning the provider gives you a consistent modern look immediately.

---

## License

This library is released under the **MIT License**. See `LICENSE` for details.

Contributions, bug reports, and pull requests are welcome!