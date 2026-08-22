# Internationalization and Localization Specification

## 1. Purpose

Tài liệu này chuẩn hóa cách web app hỗ trợ nhiều ngôn ngữ, vùng, script, timezone, currency và hướng đọc. **Internationalization (i18n)** là thiết kế hệ thống không phụ thuộc một ngôn ngữ; **localization (l10n)** là nội dung và format cụ thể cho locale. Mục tiêu là đổi locale không làm đổi business state, API contract, permission, money precision hoặc audit meaning.

## 2. Boundary contract

| Layer | Responsibility | Không được làm |
|---|---|---|
| Domain/backend | Stable IDs, enum values, error codes, UTC timestamps, decimal/minor-unit money | Trả label dịch làm source of truth |
| API contract | Locale-independent schema; optional localized projection khi được thiết kế | Đổi field/status theo ngôn ngữ |
| Presentation | Translate message key, format date/number/money/unit, direction | Suy luận business state từ translated text |
| Content catalog | Message key, translations, variables, context, review status | Dùng nguyên câu làm key |
| Product/legal | Terminology, tone, disclosure, regional content and policy | Để agent tự quyết định legal wording |
| QA | Missing key, plural, expansion, RTL, visual and accessibility evidence | Chỉ test default locale |

## 3. Locale registry

Mỗi project có registry versioned:

```json
{
  "defaultLocale": "vi-VN",
  "supportedLocales": ["vi-VN", "en-US"],
  "fallbackLocale": "en-US",
  "timeZonePolicy": "user-preference-or-project-default",
  "direction": {
    "vi-VN": "ltr",
    "en-US": "ltr"
  }
}
```

Locale identifier dùng BCP 47 language tag, ví dụ `vi-VN`, `en-US`, `zh-Hans-CN` hoặc `ar`. Không dùng một mã ngắn mơ hồ nếu product cần phân biệt region, numbering, calendar, currency hoặc legal copy. Registry phải khai báo display name, direction, supported date/number/currency behavior, message coverage, owner và status.

## 4. Locale resolution

Resolution phải deterministic và có thể audit. Một flow mặc định:

```text
explicit user preference
  → account/profile preference
  → locale in URL or route
  → accepted browser languages
  → project default locale
  → stable fallback locale
```

`explicit` và `account` preference phải có precedence đã document. Không để server và client chọn locale khác nhau gây hydration mismatch. Locale resolved phải được truyền rõ vào formatter và translation provider; không dựa vào process-global mutable locale trong concurrent request.

| Concern | Required behavior |
|---|---|
| SSR | Server render bằng locale đã resolve; client hydrate cùng locale |
| URL | Quyết định có prefix `/vi/`, domain hoặc cookie; ghi canonical/redirect policy |
| Persistence | Cookie/account preference có version, expiry/privacy policy |
| Unsupported locale | Fallback có log/telemetry, không crash page |
| Locale switch | Giữ route/context/form data nếu an toàn; không làm mất unsaved input |
| Cache | Cache key chứa locale và direction khi output phụ thuộc vào chúng |
| SEO | `lang`, canonical, hreflang/metadata theo product scope |

## 5. Message catalog contract

Message key ổn định, phân nhóm theo bounded context và purpose:

```json
{
  "checkout.payment.failed": {
    "message": "Thanh toán chưa hoàn tất. Vui lòng thử lại.",
    "description": "Shown after a payment provider failure",
    "variables": [],
    "status": "reviewed"
  },
  "cart.items_count": {
    "message": "{count, plural, =0 {Chưa có sản phẩm} one {# sản phẩm} other {# sản phẩm}}",
    "description": "Cart item count",
    "variables": ["count"],
    "status": "reviewed"
  }
}
```

Catalog phải khai báo key, default/source message, variables/type, context, translator, review status, last reviewed date và sensitive-content note nếu có. Translation không được chèn secret, raw token, untrusted HTML hoặc payment data.

Message key rules:

| Rule | Requirement |
|---|---|
| Naming | `<domain>.<surface>.<meaning>`; không dùng câu làm key |
| Variables | Whitelist tên/type; missing/extra variable là validation error |
| Rich text | Dùng structured placeholders/components; sanitize untrusted content |
| Status | `draft`, `translated`, `reviewed`, `deprecated` |
| Deprecation | Giữ key trong compatibility window hoặc migration map |
| Error | Map stable backend `code` → message key ở presentation layer |
| Logging | Log missing key/key ID, không log raw PII hoặc full user content |

## 6. Fallback and missing translations

Fallback chain phải được khai báo theo locale và scope, ví dụ `vi-VN → vi → en-US → stable key`. Fallback không được làm thay đổi layout contract mà không được test. Production không nên hiển thị raw key cho user trừ khi có safe emergency policy; missing key phải alert/metric và tạo ticket.

Không silently fallback một phần message có thể làm sai legal/financial meaning. Terms, consent, price, refund, privacy, payment, health, safety và moderation copy cần translation review riêng; nếu thiếu bản dịch chính thức, UI phải giữ trạng thái `NEEDS_HUMAN_REVIEW`.

## 7. Plural, select and grammar

Dùng message-format/ICU-compatible mechanism hoặc abstraction tương đương để xử lý plural, ordinal, gender/select, date/time/number interpolation. Không nối chuỗi bằng `+`, không tự giả định chỉ có singular/plural kiểu tiếng Anh và không viết `count === 1` rải trong component.

| Case | Required test |
|---|---|
| Zero | Có message riêng nếu ngôn ngữ cần |
| One/many | Đúng rule locale |
| Decimal | Hiển thị theo locale và business rule |
| Gender/select | Không tạo sentence grammar sai |
| Long variable | Không overflow, không tạo unsafe HTML |
| Missing variable | Fail ở test/build, fallback an toàn runtime |

## 8. Date, time, number, currency and units

API giữ timestamp ISO 8601 UTC và money có amount + currency theo canonical data spec. Presentation format theo locale/timezone đã resolve. `Intl` cung cấp locale-sensitive string comparison, number/date/time formatting và các constructor như `Intl.DateTimeFormat`, `Intl.NumberFormat`, `Intl.PluralRules`, `Intl.RelativeTimeFormat` [1].

| Data | Contract |
|---|---|
| Instant | API UTC; UI chọn timezone và hiển thị timezone khi ambiguity ảnh hưởng quyết định |
| Date-only | Không tự convert timezone; giữ `YYYY-MM-DD` semantics |
| Number | Không format thành string trước domain calculation |
| Money | Amount precision/currency từ API; UI format, không tự đổi tỷ giá |
| Percent | Chốt scale (`0.15` hay `15`) và locale output |
| Duration | Chốt unit/rounding; không suy luận từ formatted text |
| Relative time | Có absolute fallback cho audit/critical timestamp |
| Sorting/search | Chọn collation/normalization; không sort raw display string tùy ý |

Timezone mặc định, DST behavior, calendar/numbering system và currency display phải có owner. Test boundary quanh UTC midnight, DST nếu region có, negative/large numbers, zero, rounding và VND/other currency nếu hỗ trợ.

## 9. Typography and content expansion

Mỗi locale cần font fallback, line-height, word-break, script support, punctuation và text direction phù hợp. Test text expansion tối thiểu cho navigation, button, tab, table header, form error, modal, toast, chart legend, email/notification preview và empty state. Không dùng fixed width để che message dài; không truncate label nếu làm mất action hoặc legal meaning.

Pseudo-localization nên tạo ký tự accent, text expansion, bidi markers và placeholder stress để phát hiện layout bug trước khi có bản dịch thật. User-generated content không được dịch tự động trong UI trừ khi feature có contract, consent, provenance và safety review riêng.

## 10. RTL and bidirectional text

Khi có locale RTL, set `lang` và `dir="rtl"` ở document/root scope, cho phép component inherit direction và dùng CSS logical properties thay cho hardcoded `left/right`. Icon chỉ hướng như back/forward, chart axis, pagination, swipe gesture và numeric identifiers phải có semantic review; không mirror mọi icon một cách máy móc.

| Area | RTL requirement |
|---|---|
| Layout | `margin-inline`, `padding-inline`, `inset-inline`, logical border/radius |
| Text | Bidi isolation cho user content, IDs, email, URL và code |
| Navigation | Thứ tự/arrow semantics theo direction, keyboard order hợp lý |
| Tables/charts | Numeric alignment, axis/legend, horizontal scroll và sort indicator |
| Forms | Label/error/help association không phụ thuộc vị trí trái/phải |
| Icons | Chỉ mirror khi meaning là directional |
| Mixed content | Test Arabic/Hebrew + Latin + numbers + punctuation |

Nếu project chưa hỗ trợ RTL, phải ghi rõ `unsupported with rationale` thay vì gọi UI là internationalized hoàn chỉnh.

## 11. Translation lifecycle

| Stage | Owner | Evidence |
|---|---|---|
| Source copy | Product/content | Context, intent, variables, tone |
| Terminology | Domain owner | Glossary and forbidden translations |
| Translation | Translator/localizer | Catalog diff, locale coverage |
| Review | Native/domain reviewer | Reviewed status and comments |
| Integration | Frontend | Key schema, fallback, format wiring |
| QA | QA/design | Locale matrix, pseudo-locale, screenshots |
| Release | Release owner | Locale/version, known gaps, rollback |

Translation changes phải versioned cùng code hoặc content release; message key rename cần migration. Legal, privacy, payment, consent, refund, safety và App Store copy không được tự động chấp thuận chỉ vì đã dịch xong.

## 12. QA matrix and release gates

| Gate | Check | Block when |
|---|---|---|
| Catalog | Key/variable/schema lint | Missing key, extra variable, invalid format |
| Resolution | SSR/client/URL/cookie/account consistency | Hydration mismatch or nondeterministic locale |
| Formatting | Date/time/number/currency/plural fixtures | Wrong timezone, rounding, plural or currency semantics |
| Expansion | Pseudo-locale and long-copy visual test | Clipped text, lost action, overflow or broken table/modal |
| RTL | Direction, logical CSS, bidi and icon semantics | Hardcoded physical properties break layout |
| Accessibility | `lang`, labels, screen reader, contrast, focus | Locale/theme changes accessibility behavior |
| Content | Reviewer/owner status for critical copy | Legal/payment/privacy/safety copy is unreviewed |
| Observability | Missing-key metric and fallback telemetry | Missing translation is invisible in production |

Definition of done cho locale mới là registry update, catalog coverage, fallback decision, formatter tests, pseudo-locale visual evidence, accessibility review, translation owner approval và release note. “Có nút đổi ngôn ngữ” chưa đủ để gọi là đa ngôn ngữ.

## References

[1]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl "MDN — Intl"
[2]: https://developer.mozilla.org/en-US/docs/Glossary/BCP_47_language_tag "MDN — BCP 47 language tag"
[3]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values "MDN — CSS logical properties and values"
[4]: https://www.w3.org/TR/WCAG22/ "W3C — Web Content Accessibility Guidelines 2.2"
