# Theme and Design Tokens Specification

## 1. Purpose

Tài liệu này là contract chung cho typography, color, spacing, layout, radius, elevation, motion và theme của mọi web app dùng Web App Factory. Mục tiêu là một component có thể chạy nhất quán trong light, dark, system preference, high-contrast, reduced-motion và nhiều locale mà không sửa business logic.

Design token phải đi qua ba lớp: **primitive token** là giá trị nền; **semantic token** là ý nghĩa sản phẩm; **component token** là mapping của component. Feature không được dùng trực tiếp hex, RGB, shadow, font size hoặc z-index tùy ý.

## 2. Token layers and ownership

| Layer | Ví dụ | Có được dùng trong feature không? | Owner |
|---|---|---:|---|
| Primitive | `blue.600`, `gray.950`, `space.4`, `font.size.2` | Không trực tiếp | Design system |
| Semantic | `color.surface.canvas`, `color.text.primary`, `color.action.danger` | Có | Design system/product |
| Component | `button.primary.background`, `dialog.border` | Chỉ qua shared component | Component owner |
| Content | `message.checkout.payment_failed` | Qua i18n catalog | Product/content |

Mọi token phải có name, type, description, owner, allowed usage, theme values, contrast evidence, deprecation status và consumer impact. Token rename hoặc meaning change là contract change, phải có migration note.

## 3. Naming convention

Dùng namespace ổn định và phân biệt token với raw value:

```text
color.<role>.<variant>.<state>
typography.<role>.<property>
space.<step>
radius.<role>
elevation.<level>
motion.<role>.<property>
breakpoint.<name>
z.<layer>
```

Ví dụ:

```text
color.surface.canvas
color.surface.raised
color.text.primary
color.text.muted
color.border.subtle
color.action.primary.default
color.action.primary.hover
color.status.danger.foreground
color.status.danger.background
typography.body.font-family
typography.body.font-size
```

Không đặt semantic token theo màu vật lý như `color.blue-button`; màu xanh có thể thay đổi hoặc khác giữa light/dark. Không đặt token theo page nếu ý nghĩa có thể dùng chung.

## 4. Color architecture

### 4.1 Required semantic roles

| Role group | Minimum roles |
|---|---|
| Surface | canvas, raised, sunken, overlay, inverse |
| Text | primary, secondary, muted, disabled, inverse, link |
| Border | default, subtle, strong, focus |
| Action | primary/default-hover/active/disabled, secondary, destructive |
| Status | success, warning, danger, info; mỗi role có foreground/background/border |
| Data visualization | categorical series, sequential scale, diverging scale, selected/hovered |
| Focus | focus ring and focus offset |

Màu không được là tín hiệu duy nhất. Trạng thái phải có text, icon, pattern hoặc ARIA semantics bổ trợ. Chart phải có legend, label/tooltip và distinction không chỉ dựa vào hue.

### 4.2 Theme values

Theme dùng cùng semantic names nhưng giá trị khác nhau. Mỗi theme phải kiểm tra text, icon, border, focus, chart, disabled và overlay.

```css
:root {
  color-scheme: light dark;
  --color-surface-canvas: #ffffff;
  --color-surface-raised: #f8fafc;
  --color-text-primary: #0f172a;
  --color-text-muted: #64748b;
  --color-border-default: #cbd5e1;
  --color-action-primary: #2563eb;
  --color-action-primary-contrast: #ffffff;
  --color-status-danger: #be123c;
  --color-focus-ring: #1d4ed8;
}

[data-theme="dark"] {
  --color-surface-canvas: #0f172a;
  --color-surface-raised: #1e293b;
  --color-text-primary: #f8fafc;
  --color-text-muted: #cbd5e1;
  --color-border-default: #475569;
  --color-action-primary: #60a5fa;
  --color-action-primary-contrast: #0f172a;
  --color-status-danger: #fb7185;
  --color-focus-ring: #93c5fd;
}
```

`color-scheme` cho phép browser UI như form controls, scrollbar và canvas phản ánh theme; phần UI của application vẫn phải dùng token và `prefers-color-scheme`/theme selector đúng cách [1] [2].

## 5. Theme resolution contract

Mỗi project hỗ trợ tối đa ba user choices: `light`, `dark`, `system`. `system` đọc OS/browser preference; `light` và `dark` là explicit override.

| Step | Rule |
|---:|---|
| 1 | Xác định user override từ cookie hoặc storage có schema version |
| 2 | Nếu không có override, dùng `system` |
| 3 | `system` resolve theo `prefers-color-scheme` |
| 4 | Gán `data-theme` và `color-scheme` trước khi hydrate UI |
| 5 | Đồng bộ theme picker, `<meta name="color-scheme">`, SSR và client |
| 6 | Ghi preference nếu user cho phép; không ghi theme vào analytics nếu không cần |

Theme state machine:

```text
UNRESOLVED
  → SYSTEM_LIGHT | SYSTEM_DARK
  → EXPLICIT_LIGHT | EXPLICIT_DARK
  → SYSTEM_LIGHT | SYSTEM_DARK (khi user chọn System)
```

SSR/hydration không được tạo flash hoặc mismatch do server render light còn client chuyển dark. Nếu không thể biết preference trên server, render token-safe shell hoặc inline resolver tối thiểu trước CSS; không đọc `window` trong Server Component.

## 6. Typography contract

Typography phải khai báo font family, fallback, weight, size, line-height, letter spacing, max measure và locale/script behavior. Fallback không được làm mất dấu tiếng Việt hoặc ký tự của locale hỗ trợ.

| Role | Default guidance | Required test |
|---|---|---|
| Display | Chỉ dùng cho hero/marketing; giới hạn line length | Long text, responsive, dark |
| H1/H2/H3 | Hierarchy semantic, không bỏ cấp để đạt kích thước | Screen reader heading outline |
| Body | Base khoảng 16px, line-height dễ đọc | Zoom/reflow, locale expansion |
| Label | Rõ hierarchy, không dùng màu làm meaning duy nhất | Contrast, truncation |
| Caption/helper | Không dùng size nhỏ để giấu thông tin quan trọng | Contrast, text expansion |
| Numeric/data | Chọn tabular/lining numeral khi cần so sánh | Locale number/currency |
| Code/ID | Monospace chỉ khi cần phân biệt ký tự | Overflow/copy |

Typography scale phải là token, không dùng magic number. Font loading failure phải có fallback hợp lệ; không để layout shift làm mất action. Text không được bị cắt bằng CSS nếu làm mất nghĩa, trạng thái hoặc giá trị tiền.

Locale-specific typography phải test Vietnamese diacritics, English, long Latin strings, CJK nếu hỗ trợ, Arabic/RTL nếu hỗ trợ và pseudo-locale. Line-height/word-break không được giả định chỉ có tiếng Anh.

## 7. Layout and non-color tokens

| Token group | Rule |
|---|---|
| Spacing | Dùng scale 4/8 hoặc scale đã được project phê duyệt |
| Container | Có max width/gutter theo content và breakpoint |
| Radius | Semantic role cho control/card/dialog, không trộn ngẫu nhiên |
| Elevation | Layer và shadow phải có light/dark value, không dùng shadow làm boundary duy nhất |
| Z-index | Token layer cho base, sticky, dropdown, popover, modal, toast |
| Breakpoint | Content-driven, không chỉ theo thiết bị |
| Motion | Duration/easing token và reduced-motion alternative |
| Direction | Dùng logical properties (`margin-inline`, `inset-inline`, `border-start-start`) cho layout đa hướng [3] |

## 8. Component contract

Shared component chỉ được dùng semantic/component token. Component phải hoạt động trong mọi theme đã hỗ trợ và có state matrix: default, hover, active, focus-visible, disabled, loading, error, selected, high-contrast và reduced-motion khi applicable.

Component không được hardcode text; dùng i18n key. Component không được suy luận màu từ business status; nhận semantic variant đã được contract. Icon phải có accessible name nếu là action và không được phụ thuộc vào màu để truyền meaning.

## 9. Accessibility and special modes

Mục tiêu mặc định là WCAG 2.2 AA. WCAG là các success criteria có thể kiểm thử và nên được đánh giá kết hợp automated checks với human evaluation [4].

| Mode | Requirement |
|---|---|
| Light/dark | Contrast, focus, disabled, chart and overlay evidence ở cả hai theme |
| System | OS change cập nhật đúng nếu user chọn system |
| High contrast/forced colors | Controls vẫn nhìn thấy, border/focus không biến mất |
| Reduced motion | Tắt/giảm animation, giữ nguyên state và progress meaning |
| Zoom/reflow | Không mất content/action khi zoom hoặc viewport hẹp |
| Keyboard | Focus-visible, logical order, no trap, modal restore |
| Screen reader | Heading/role/name/value/status announcement |

Không dùng `opacity` thấp để biểu diễn disabled nếu contrast hoặc affordance không còn hiểu được. Focus indicator phải đủ nổi bật trên cả nền sáng và tối.

## 10. Theme QA and evidence

Mỗi screen quan trọng phải có matrix:

| Dimension | Minimum coverage |
|---|---|
| Theme | Light, dark, system light, system dark |
| Viewport | Mobile, tablet, desktop |
| Content | Empty, normal, long text, large number, error, permission |
| Locale | Default locale, second locale, pseudo-locale; RTL nếu supported |
| Accessibility | Keyboard, screen reader smoke, zoom/reflow, reduced motion, contrast |
| Runtime | Initial, loading, offline, stale, slow network, unknown error |

Evidence tối thiểu gồm screenshot/visual diff có theme+locale label, token/contrast report, keyboard trace, overflow result và reviewer decision. Snapshot phải dùng fixture, timezone, font và locale deterministic.

## 11. Gate and anti-patterns

| Gate | BLOCK khi |
|---|---|
| Token gate | Feature có raw color/spacing/font/z-index ngoài token mà không có ADR |
| Theme gate | Có dark mode nhưng thiếu semantic mapping hoặc contrast evidence |
| Hydration gate | Theme gây flash/mismatch hoặc client-only resolver làm vỡ SSR |
| Typography gate | Locale/text expansion gây cắt label, mất action hoặc vỡ layout |
| Accessibility gate | Focus/contrast/reduced-motion chỉ pass ở một theme |
| Direction gate | RTL dùng hardcoded left/right làm layout sai |
| Regression gate | Shared token/component change thiếu impact list và visual diff |

Các anti-pattern bị từ chối gồm raw hex trong feature CSS/JSX, màu status không có semantic token, chỉ đổi nền thành tối nhưng giữ text/border light, theme chỉ tồn tại trong settings UI nhưng không áp vào document, dùng `innerHTML` để chèn translated HTML không sanitize và test chỉ bằng screenshot happy path.

## References

[1]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme "MDN — prefers-color-scheme"
[2]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme "MDN — color-scheme"
[3]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values "MDN — CSS logical properties and values"
[4]: https://www.w3.org/TR/WCAG22/ "W3C — Web Content Accessibility Guidelines 2.2"
