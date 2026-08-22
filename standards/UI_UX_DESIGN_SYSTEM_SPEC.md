# Canonical UI/UX Design System Specification

## 1. Mục tiêu

Mọi màn hình phải nhìn và hoạt động như cùng một sản phẩm, không phải tập hợp page độc lập. Design system là contract giữa product, designer, frontend, QA và AI Agent. Một màn hình chỉ được coi là hoàn thành khi có đủ visual states, interaction states, responsive behavior, accessibility evidence và mapping tới API state.

Dự án hiện có các primitive như `Button`, `Input`, `Select`, `Textarea`, `Modal`, `Skeleton`, `LoadingSpinner`, `Badge` trong `src/components/ui/`; chuẩn này yêu cầu các primitive trở thành nguồn dùng chung, không copy class tùy ý vào từng page.

## 2. Design tokens

Chi tiết token layer, semantic naming, light/dark/system resolution, typography roles, forced colors, reduced motion và direction-aware layout nằm trong `THEME_AND_DESIGN_TOKENS_SPEC.md`. Tài liệu này là contract bắt buộc khi change ảnh hưởng theme hoặc design system.

Tokens phải nằm ở một nguồn trung tâm và dùng qua CSS variables/Tailwind mapping. Không hardcode màu semantic trong feature component.

```css
:root {
  --color-brand-primary: #2563eb;
  --color-brand-primary-hover: #1d4ed8;
  --color-success: #059669;
  --color-warning: #d97706;
  --color-danger: #e11d48;
  --color-info: #0284c7;
  --color-surface: #ffffff;
  --color-surface-muted: #f8fafc;
  --color-border: #e2e8f0;
  --color-text: #0f172a;
  --color-text-muted: #64748b;
  --focus-ring: #2563eb;
}
```

Mỗi token cần semantic name, contrast check, dark-mode value nếu có, usage restriction và screenshot/test reference. Nếu project khai báo hỗ trợ dark/system/high-contrast thì không được để token ở trạng thái “nếu có”; phải có mapping và evidence cho từng mode đã công bố. Không dùng màu chỉ để truyền tải trạng thái; trạng thái phải có text/icon/ARIA bổ trợ.

## 3. Typography, spacing và layout

| Nhóm | Chuẩn đề xuất |
|---|---|
| Font | Một font UI chính, fallback system; không dùng quá 2 font family; phải kiểm tra glyph/dấu theo locale |
| Heading | `h1` một lần/page; thứ bậc không bỏ cấp chỉ vì muốn nhỏ hơn |
| Body | Base 16px; line-height đủ đọc; label và helper text có hierarchy rõ |
| Spacing | Scale thống nhất 4/8px; component không tự phát minh khoảng cách |
| Radius | Token cho control/card/modal; không trộn radius ngẫu nhiên |
| Container | Max width và gutter nhất quán theo breakpoint |
| Z-index | Token layers cho dropdown, sticky, modal, toast; không dùng số tùy ý |
| Motion | Có reduced-motion path; animation không là điều kiện duy nhất để hiểu trạng thái |
| Locale expansion | Không fixed-width theo tiếng Anh; test text dài, pseudo-locale, số lớn và font fallback |

## 4. Component contract

Mỗi component dùng chung phải mô tả props, slot, keyboard, focus, visual states và telemetry boundary.

### Button

`Button` có variant `default`, `destructive`, `outline`, `secondary`, `ghost`, `link`, `success`, `warning`; size `default`, `sm`, `lg`, `icon`; `isLoading` phải disable mutation và giữ label accessible. Icon-only button bắt buộc có accessible name/tooltip. Không dùng `div` giả button cho action.

### Form control

Mọi input phải có visible label hoặc accessible name, helper/error text liên kết bằng `aria-describedby`, required state, autocomplete phù hợp, invalid state và submit behavior. Error phải xuất hiện cạnh field và summary nếu form dài. Không xóa input người dùng đã nhập khi request fail.

### Modal/dialog

Modal phải có title, description khi cần, focus trap, Escape policy, restore focus, scroll lock, cancel/confirm semantics và unsaved-change policy. Destructive action phải xác nhận rõ đối tượng và consequence. Modal không được che focus của user.

### Table/list/card

Table phải có header semantics, sorting/filter state, row empty state, loading skeleton, error retry, pagination/cursor state và mobile fallback. Card dùng cho summary; không thay table khi user cần so sánh nhiều record.

### Toast/notification

Toast dùng cho transient feedback, không thay inline error và không chứa dữ liệu nhạy cảm. Không toast storm khi nhiều request cùng fail. Message phải có localization key và severity.

## 5. State matrix bắt buộc cho mỗi screen

Mọi screen spec phải có các state sau, kể cả state hiếm xảy ra:

| State | Hành vi bắt buộc |
|---|---|
| Initial | Hiển thị skeleton/placeholder phù hợp, không layout jump lớn |
| Loading | Disable đúng mutation, giữ context và cho biết progress |
| Success | Hiển thị data, freshness và action tiếp theo |
| Empty | Giải thích vì sao rỗng và CTA hợp lệ; không giả như lỗi |
| Error 4xx | Mapping `code`, field errors, retry hoặc action sửa |
| Error 401/403 | Login/permission explanation không lộ resource nhạy cảm |
| Error 409 | Hiển thị conflict và refresh/resolve path |
| Error 429 | Tuân `Retry-After`, không retry storm |
| Error 5xx/offline | Giữ snapshot nếu an toàn, retry có kiểm soát |
| Partial/realtime stale | Hiển thị freshness, resync hoặc last known state |
| Disabled/read-only | Giải thích reason nếu user có thể hiểu được |

## 6. API-to-UI state mapping

Frontend không được đoán state từ message tiếng Việt. Mapping theo `statusCode`, `code`, `data`, `meta`, `revision` và permission projection.

```text
HTTP 401 / AUTH_REQUIRED       → session-expired / login CTA
HTTP 403 / FORBIDDEN           → no-permission state
HTTP 404 / NOT_FOUND           → resource-not-found state
HTTP 409 / STATE_CONFLICT      → conflict state + refresh
HTTP 422 / VALIDATION_ERROR    → field errors + summary
HTTP 429 / RATE_LIMITED        → cooldown, no blind loop
HTTP 5xx / SERVICE_UNAVAILABLE → retry/offline fallback
```

Mutation phải có optimistic policy rõ ràng. Chỉ optimistic update khi operation reversible và có rollback; payment, payout, registration slot và score authority cần server confirmation.

## 7. Responsive behavior

Screen spec phải mô tả tối thiểu mobile 360px, tablet 768px và desktop 1280px, cùng breakpoint behavior cho nav, table, form, modal, chart, live score và chat. Không chỉ resize screenshot; phải xác định content priority, order, overflow, touch target và keyboard path.

Các action quan trọng phải đạt touch target phù hợp; WCAG 2.2 có success criterion về Target Size (Minimum) và Accessible Authentication (Minimum), nên auth/OTP không được yêu cầu thao tác gây khó cho user.[1]

## 8. Accessibility target

Mục tiêu mặc định là WCAG 2.2 Level AA. WCAG 2.2 tổ chức yêu cầu theo bốn nguyên tắc perceivable, operable, understandable và robust, và yêu cầu đánh giá kết hợp automated testing với human evaluation.[1]

Acceptance checklist:

| Area | Evidence |
|---|---|
| Keyboard | Tab order, visible focus, Escape, Enter/Space, no keyboard trap |
| Screen reader | Role/name/value, headings, labels, live region, error announcement |
| Contrast | Text/control contrast checked in light/dark states |
| Focus | Focus không bị sticky header/modal che; restore focus sau dialog |
| Motion | Reduced motion; không truyền meaning chỉ qua animation |
| Forms | Label, autocomplete, required, error pointer, recovery không mất dữ liệu |
| Auth | Password manager, paste/assistive technology, OTP accessible |
| Responsive | Zoom/reflow, mobile keyboard, touch target, orientation |
| Media | Alt text, captions/transcript khi có video/audio |

## 9. Content, localization và privacy

Quy tắc đầy đủ về locale registry, fallback, catalog, plural/select, date/number/currency/timezone, SSR, text expansion, RTL và translation review nằm trong `I18N_L10N_SPEC.md`. UI text dùng message key, không hardcode câu rải trong component. Date, number, money và timezone format ở presentation layer theo locale; enum/status value không dịch trong backend. Text người dùng nhập phải phân biệt trusted label với untrusted rich text.

PII, payment amount, email, phone và moderation content chỉ render sau khi API projection cho phép. Không đưa secret/token vào URL, DOM data attribute, analytics event hoặc error toast.

## 10. Theme/i18n acceptance artifacts

Khi screen hoặc shared component có theme/locale impact, change phải liên kết `theme-config.json`, `translation-catalog.json` và/hoặc `locale-qa-matrix.md` theo `THEME_I18N_GATES.md`. Không coi nút đổi theme/ngôn ngữ hoặc một screenshot happy path là bằng chứng đủ.

## 11. UX acceptance criteria

Một screen được pass khi:

1. Có screen spec chứa purpose, persona, entry/exit, happy path, edge cases và state matrix.
2. Dùng primitive/token đã có hoặc có ADR cho component mới.
3. Có API contract và mapping lỗi/status không đoán bằng text.
4. Có mobile/desktop keyboard path.
5. Có loading, empty, validation, conflict, offline/5xx state.
6. Có evidence screenshot hoặc browser trace cho các trạng thái quan trọng.
7. Có accessibility automated checks và human keyboard review.
8. Có responsive regression và visual diff khi component dùng chung thay đổi.

## References

[1]: [W3C Web Content Accessibility Guidelines (WCAG) 2.2](https://www.w3.org/TR/WCAG22/)
