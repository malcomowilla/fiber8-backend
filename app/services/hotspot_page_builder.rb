# app/services/hotspot_page_builder.rb
class HotspotPageBuilder
  def initialize(account, design_override: nil, platform_domain: nil)
    @account = account
    @settings = account.hotspot_setting
    @design = design_override || @settings&.page_design || {}
    @subdomain = account.subdomain
    @platform_domain = platform_domain || PlatformDomainResolvable::DEFAULT_PLATFORM_DOMAIN
  end

  def compile(preview: false)
    @preview = preview
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{header["title"] || @settings&.hotspot_name}</title>
        #{google_font_link}
        <style>#{compiled_css}</style>
      </head>
      <body>
        <div id="app">#{skeleton_html}</div>
        <script>
          window.__HOTSPOT_CONFIG__ = #{config_json};
        </script>
        <script>#{compiled_js}</script>
      </body>
      </html>
    HTML
  end

  private

  def theme = @design["theme"] || {}
  def typography = @design["typography"] || {}
  def layout = @design["layout"] || {}
  def header = @design["header"] || {}
  def footer_cfg = @design["footer"] || {}
  def features = @design["features"] || {}

  def google_font_link
    url = typography["google_font_url"]
    url.present? ? %(<link rel="stylesheet" href="#{url}">) : ""
  end

  def api_base_url
    short_subdomain = @account.subdomain.to_s.split(".").first
    base = short_subdomain.present? ? "#{short_subdomain}.#{@platform_domain}" : @platform_domain
    "https://#{base}"
  end

  # Cloudinary (or any) URLs are already absolute (https://...) and are
  # returned untouched. Only bare relative paths get the platform domain
  # prefixed on. NOTE: if a logo still fails to load on the router itself,
  # the most likely cause is MikroTik's walled garden blocking the asset
  # host (e.g. res.cloudinary.com) before the client has authenticated —
  # that has to be whitelisted on the router
  # (/ip hotspot walled-garden add dst-host=*.cloudinary.com action=allow),
  # this helper can't fix that part.
  def absolute_url(path)
    return nil if path.blank?
    path.start_with?("http://", "https://") ? path : "#{api_base_url}#{path.start_with?('/') ? '' : '/'}#{path}"
  end

  def config_json
    {
      subdomain: @subdomain,
      api_base: api_base_url,
      hotspot_name: @settings&.hotspot_name,
      hotspot_phone: @settings&.phone_number,
      hotspot_email: @settings&.email,
      features: features,
      header: header,
      footer: footer_cfg,
      # When true (only ever set from preview_page_design), the compiled page
      # still renders ads/packages/promos so the designer's iframe shows what
      # a customer will actually see, but suppresses tracking + reward side
      # effects so previewing never pollutes real ad analytics. It ALSO
      # unlocks sample/mock fallback content (see loadPackages/loadAds/
      # loadPromotions below) whenever the real API returns nothing yet —
      # this NEVER happens on the published page, only in the designer.
      preview: !!@preview,
        mikrotik_mac: "$(mac)",
    mikrotik_ip: "$(ip)",
    }.to_json
  end

  def compiled_css
    <<~CSS
      :root {
        --primary:         #{theme["primary"]         || "#38bdf8"};
        --secondary:       #{theme["secondary"]       || "#a78bfa"};
        --accent:          #{theme["accent"]          || "#34d399"};
        --btn-primary:     #{theme["button_primary"]  || theme["primary"] || "#38bdf8"};
        --btn-secondary:   #{theme["button_secondary"]|| theme["secondary"] || "#a78bfa"};
        --background:      #{theme["background"]      || "#020617"};
        --surface:         #{theme["surface"]         || "#0f172a"};
        --text:            #{theme["text"]             || "#e2e8f0"};
        --muted:           #{theme["muted"]            || "#64748b"};
        --radius:          #{layout["corner_radius"]   || 24}px;
        --font:            '#{typography["font_family"] || "Plus Jakarta Sans"}', sans-serif;
        --font-size:       #{typography["base_size"]   || 14}px;
      }
      * { box-sizing: border-box; margin: 0; padding: 0; font-family: var(--font); }
      body {
        background: radial-gradient(circle at 20% -10%, color-mix(in srgb, var(--primary) 12%, transparent), transparent 60%),
                    radial-gradient(circle at 90% 110%, color-mix(in srgb, var(--secondary) 10%, transparent), transparent 60%),
                    var(--background);
        color: var(--text); font-size: var(--font-size); min-height: 100vh;
      }
      .card {
        max-width: #{layout["card_width"] || 420}px;
        margin: 48px auto;
        background: color-mix(in srgb, var(--surface) 75%, transparent);
        backdrop-filter: blur(20px);
        border: 1px solid color-mix(in srgb, var(--text) 10%, transparent);
        border-radius: var(--radius);
        overflow: hidden;
        box-shadow: 0 30px 60px -20px rgba(0,0,0,.5);
      }
      .header { text-align: center; padding: 32px 24px 20px; border-bottom: 1px solid color-mix(in srgb, var(--text) 8%, transparent); }
      .header .wifi-badge {
        width: 56px; height: 56px; margin: 0 auto 12px; border-radius: 18px;
        display: flex; align-items: center; justify-content: center; font-size: 24px;
        background: color-mix(in srgb, var(--primary) 12%, transparent);
        border: 1px solid color-mix(in srgb, var(--primary) 25%, transparent);
      }
      .header img.logo { max-height: 56px; margin: 0 auto 12px; display: block; }
      .header h1 { font-size: #{typography["heading_size"] || 24}px; font-weight: #{typography["weight_heading"] || 700}; }
      .header p { color: var(--muted); margin-top: 4px; }
      .tabs { display: flex; gap: 6px; padding: 16px; }
      .tab { flex: 1; text-align: center; padding: 10px; border-radius: 12px; cursor: pointer; color: var(--muted); font-size: 12px; font-weight: 600; transition: background .15s, color .15s; }
      .tab.active { background: color-mix(in srgb, var(--primary) 14%, transparent); color: var(--primary); }
      .panel { padding: 0 20px 24px; }
      .field { width: 100%; padding: 14px; border-radius: 12px; border: 1px solid color-mix(in srgb, var(--text) 12%, transparent); background: color-mix(in srgb, var(--surface) 70%, transparent); color: var(--text); margin-bottom: 12px; }
      .btn { width: 100%; padding: 14px; border-radius: 12px; border: none; font-weight: 700; color: #fff; cursor: pointer;
             background: linear-gradient(135deg, var(--btn-primary), var(--btn-secondary)); transition: transform .1s, opacity .15s; }
      .btn:hover { opacity: .92; transform: translateY(-1px); }
      .pkg { display: flex; justify-content: space-between; align-items: center; padding: 14px; border-radius: 14px;
             border: 1px solid color-mix(in srgb, var(--text) 10%, transparent); margin-bottom: 10px; cursor: pointer; transition: border-color .15s; }


.pkg-freetrial { display: flex; align-items: flex-start; gap: 10px; padding: 14px;
  border-radius: 14px; margin-bottom: 12px;
  background: color-mix(in srgb, #facc15 7%, transparent);
  border: 1px solid color-mix(in srgb, #facc15 20%, transparent); }
.pkg-freetrial .icon { flex-shrink:0; font-size:15px; margin-top:1px; }
.pkg-freetrial-title { font-weight:700; font-size:13px; color:var(--text); }
.pkg-freetrial-sub { font-size:11px; color:var(--muted); margin-top:2px; line-height:1.5; }
.pkg-freetrial-btn { width:100%; margin-top:10px; padding:11px; border-radius:12px; border:none;
  font-weight:700; font-size:13px; color:#1a1206; cursor:pointer;
  background: linear-gradient(135deg,#facc15,#f59e0b); }
.pkg-freetrial-btn:disabled { opacity:.6; cursor:not-allowed; }

      .pkg.selected { border-color: var(--primary); background: color-mix(in srgb, var(--primary) 6%, transparent); }
      .pkg-skeleton { height: 62px; border-radius: 14px; margin-bottom: 10px; background: color-mix(in srgb, var(--text) 6%, transparent); animation: pulse 1.4s ease-in-out infinite; }
      @keyframes pulse { 0%,100% { opacity: .5; } 50% { opacity: 1; } }
      .status { padding: 12px; border-radius: 12px; margin-bottom: 12px; font-size: 13px; }
      .status.error { background: rgba(239,68,68,.1); color: #fca5a5; }
      .status.success { background: rgba(52,211,153,.1); color: #6ee7b7; }
      .status.processing { background: rgba(251,191,36,.1); color: #fcd34d; }
      .footer { text-align: center; padding: 16px; color: color-mix(in srgb, var(--muted) 55%, var(--text) 45%); font-size: 12px; }
      .support-line { text-align: center; font-size: 13px; }
      .support-line .footer-support { color: var(--text); font-weight: 600; }
      .support-line .footer-phone { color: var(--primary); font-weight: 700; text-decoration: none; }
      .support-line .footer-phone:hover { text-decoration: underline; }
      /* Top placement: a slim strip directly under the header, above tabs/promos */
      .support-top {
        padding: 10px 20px;
        border-bottom: 1px solid color-mix(in srgb, var(--text) 8%, transparent);
        background: color-mix(in srgb, var(--primary) 5%, transparent);
      }
      /* Bottom placement: sits inside the existing footer element */
      .support-bottom { padding: 0; }
      .promo { position: relative; overflow: hidden; border-radius: 16px; margin-bottom: 10px; padding: 14px;
               border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent);
               background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 10%, transparent), color-mix(in srgb, var(--surface) 60%, transparent)); }
      .promo .badge { display: inline-flex; gap: 4px; align-items:center; padding: 3px 9px; border-radius: 999px; font-size: 10px; font-weight: 800;
                      background: color-mix(in srgb, var(--accent) 20%, transparent); color: var(--accent); }
      .promo .price { font-weight: 800; font-size: 18px; }
      .promo .price-old { text-decoration: line-through; color: var(--muted); font-size: 12px; margin-left: 6px; }
      .promo-timer { font-family: 'Space Mono', monospace; font-size: 11px; font-weight: 700; color: var(--accent); white-space: nowrap; }
      .promo-stock { margin-top: 10px; }
      .promo-stock-label { font-size: 10px; color: var(--muted); margin-bottom: 4px; }
      .promo-stock-bar { height: 4px; border-radius: 4px; background: color-mix(in srgb, var(--text) 12%, transparent); overflow: hidden; }
      .promo-stock-fill { height: 100%; border-radius: 4px; transition: width .3s ease; }
      .mock-tag { display: inline-block; font-size: 9px; font-weight: 800; letter-spacing: .04em; text-transform: uppercase;
                  padding: 2px 6px; border-radius: 6px; background: color-mix(in srgb, var(--text) 12%, transparent); color: var(--muted); margin-left: 6px; }
      .ad-card { border-radius: 16px; overflow: hidden; background: color-mix(in srgb, var(--surface) 90%, transparent);
                 border: 1px solid color-mix(in srgb, var(--text) 10%, transparent); box-shadow: 0 20px 40px rgba(0,0,0,.35); }

                 .ad-card.fullscreen { display: flex; flex-direction: column; height: 100%; border-radius: 0; border: none; box-shadow: none; }

      /* ── Guided pay-step UI ──────────────────────────────────────── */
      .tap-hint { font-size: 12px; color: var(--muted); margin-bottom: 10px; }
      .step-back { display: flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 700; color: var(--muted);
                   margin-bottom: 14px; cursor: pointer; user-select: none; }
      .step-back:hover { color: var(--text); }
      .pkg-recap { display: flex; justify-content: space-between; align-items: center; padding: 16px;
                   border-radius: 16px; background: color-mix(in srgb, var(--primary) 7%, transparent);
                   border: 1px solid color-mix(in srgb, var(--primary) 22%, transparent); margin-bottom: 16px; }
      .pkg-recap-name { font-weight: 700; }
      .pkg-recap-sub { color: var(--muted); font-size: 12px; margin-top: 2px; }
      .pkg-recap-price { font-weight: 800; font-size: 18px; white-space: nowrap; margin-left: 12px; }
      .pay-instructions { display: flex; gap: 10px; align-items: flex-start; font-size: 13px; color: var(--text);
                           background: color-mix(in srgb, var(--primary) 6%, transparent);
                           border: 1px solid color-mix(in srgb, var(--primary) 15%, transparent);
                           border-radius: 14px; padding: 12px 14px; margin-bottom: 16px; line-height: 1.5; }
      .pay-instructions .num {
        flex-shrink: 0; width: 20px; height: 20px; border-radius: 50%; display: flex; align-items: center;
        justify-content: center; font-size: 11px; font-weight: 800; background: var(--primary); color: #fff;
      }
      .field-label { display: block; font-size: 11px; font-weight: 700; color: var(--muted);
                      text-transform: uppercase; letter-spacing: .04em; margin-bottom: 6px; }
    CSS
  end

  def skeleton_html
    logo_src = absolute_url(header["logo_url"])
    logo = (header["show_logo"] != false && logo_src.present?) ? %(<img class="logo" src="#{logo_src}" alt="" onerror="this.style.display='none'">) : ""
    wifi_icon = header["show_wifi_icon"] != false ? %(<div class="wifi-badge">📶</div>) : ""
    title = header["network_name"].presence || @settings&.hotspot_name || "Free WiFi"
    preview_badge = @preview ? %(<div style="position:fixed;top:8px;left:50%;transform:translateX(-50%);z-index:10000;background:rgba(2,6,23,.85);color:var(--primary);font:600 11px/1 sans-serif;padding:5px 12px;border-radius:20px;white-space:nowrap;">Preview — ad views aren't counted</div>) : ""
    <<~HTML
      #{preview_badge}
      <div class="card">
        <div class="header">
          #{wifi_icon}
          #{logo}
          <h1>#{title}</h1>
          <p>#{header["tagline"] || "Connect to the internet"}</p>
        </div>
        <div id="support-top"></div>
        <div id="promo-root" class="panel"></div>
        <div class="tabs" id="tabs"></div>
        <div class="panel" id="panel"></div>
        <div class="footer" id="footer"></div>
      </div>
      <div id="ad-root"></div>
    HTML
  end

  # Vanilla JS port of the packages/voucher/mpesa/promotions/ads/autologin flow.
  # Talks to the same /api endpoints your React HotspotPage.jsx,
  # HotspotAdOverlay.jsx and HotspotPromotionCard.jsx already use — this is
  # what actually ships to the router via publish_hotspot_page, so behavior
  # must not diverge from the live React version.
  #
  # cfg.preview (only ever true from preview_page_design):
  #   - suppresses tracking calls and reward-granting side effects
  #   - shows SAMPLE/MOCK content (clearly tagged "Sample") whenever the
  #     real API returns an empty list, so the designer can see the layout
  #     before any packages/ads/promos are configured. This mock content
  #     NEVER renders on the published page — cfg.preview is always false
  #     there, so real customers only ever see real data (or nothing).
  #   - also skips the autologin/session-check flow entirely, since there's
  #     nothing to reconnect to inside the designer's iframe.
  def compiled_js
    <<~JS
      (function () {
        const cfg = window.__HOTSPOT_CONFIG__;
      const qs = new URLSearchParams(window.location.search);

const rawMac = cfg.mikrotik_mac;
const rawIp  = cfg.mikrotik_ip;
const macSubstituted = rawMac && !rawMac.includes('$(');
const ipSubstituted  = rawIp  && !rawIp.includes('$(');

const mac = macSubstituted ? rawMac : (qs.get('mac') || localStorage.getItem('hotspot_mac'));
const ip  = ipSubstituted  ? rawIp  : (qs.get('ip')  || localStorage.getItem('hotspot_ip'));

if (mac) localStorage.setItem('hotspot_mac', mac);
if (ip)  localStorage.setItem('hotspot_ip', ip);

// Username isn't router-substituted like mac/ip — it only ever arrives via
// a query param (e.g. after a redirect from a previous session) or from
// whatever we stored locally last time. Mirrors the mac/ip pattern above.
const username = qs.get('username') || localStorage.getItem('hotspot_username');
if (username) localStorage.setItem('hotspot_username', username);

        const headers = { 'X-Subdomain': cfg.subdomain, 'Content-Type': 'application/json' };
        const api = (path) => cfg.api_base + path;

        const MOCK_PACKAGES = [
          { id: 'mock-1', name: 'Quick Browse', valid: '1 Hour', price: 20 },
          { id: 'mock-2', name: 'Daily Unlimited', valid: '24 Hours', price: 100 },
          { id: 'mock-3', name: 'Weekly Saver', valid: '7 Days', price: 500 },
        ];
        const MOCK_PROMO = {
          id: 'mock-promo', name: 'Weekend Special', description: '20% off the Daily Unlimited package',
          badge_text: '20% OFF', promotional_price: 80, original_price: 100,
          package_name: 'Daily Unlimited',
          show_countdown_timer: true, seconds_remaining: 5 * 3600,
          show_stock_indicator: true, max_redemptions: 50, remaining_stock: 12,
        };
        const MOCK_AD = {
          id: 'mock-ad', media_type: 'image', ad_title: 'Your Ad Here',
          media_url: 'data:image/svg+xml;utf8,' + encodeURIComponent(
            '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="140"><rect width="100%" height="100%" fill="#1e293b"/><text x="50%" y="50%" fill="#94a3b8" font-family="sans-serif" font-size="14" text-anchor="middle">Sample ad image</text></svg>'
          ),
          position: 'bottom-right', reward_type: 'none', ad_link: null,
        };

        // payStep controls the guided packages flow: 'list' shows all
        // packages; 'pay' shows a focused recap + phone-number step for
        // the one the customer tapped, so there's no scrolling required
        // and no ambiguity about what to do next.
        let state = { tab: 'packages', packages: [], packagesLoaded: false, promos: [], selected: null, payStep: 'list', status: null, message: '' };
let queryModal = { status: null, message: '' };
let connectedInfo = null;
let stkQueryInterval = null;
let promoState = {};          // { [promoId]: secondsRemaining } — ticks down locally between refreshes
let promoTimerInterval = null;
let expandedAdId = null;
let freeTrialState = {}; 


        function supportHtml() {
          const label = (cfg.footer && cfg.footer.support_label) || 'Need help?';
          const phone = (cfg.footer && cfg.footer.support_phone) || cfg.hotspot_phone || '';
          const phoneHtml = phone ? ' · <a class="footer-phone" href="tel:' + phone.replace(/\\s+/g, '') + '">' + phone + '</a>' : '';
          return '<span class="footer-support">' + label + '</span>' + phoneHtml +
            (cfg.hotspot_email ? ' · ' + cfg.hotspot_email : '');
        }

        function renderFooter() {
          // footer.show_support (default true) lets the admin hide the
          // support contact line entirely. footer.support_position
          // ('top' | 'bottom', default 'bottom') decides whether it renders
          // as a strip right under the header, or in the page footer.
          const showSupport = !(cfg.footer && cfg.footer.show_support === false);
          const position = (cfg.footer && cfg.footer.support_position) || 'bottom';

          const topEl = document.getElementById('support-top');
          const footerEl = document.getElementById('footer');

          if (!showSupport) {
            if (topEl) topEl.innerHTML = '';
            footerEl.innerHTML = '';
            return;
          }

          const html = '<div class="support-line">' + supportHtml() + '</div>';
          if (position === 'top') {
            if (topEl) topEl.innerHTML = html;
            footerEl.innerHTML = '';
          } else {
            if (topEl) topEl.innerHTML = '';
            footerEl.innerHTML = html;
          }
        }

        function render() {
          document.getElementById('tabs').innerHTML = tabsHtml();
          document.getElementById('panel').innerHTML = panelHtml();
          renderFooter();
          bindEvents();
        }

document.querySelectorAll('[data-freetrial]').forEach(el =>
  el.onclick = () => {
    const pkg = state.packages.find(p => String(p.id) === el.dataset.freetrial);
    if (pkg) startFreeTrial(pkg);
  });


        function tabsHtml() {
          const tabs = [];
          if (cfg.features.show_packages)   tabs.push(['packages', 'Buy Package']);
          if (cfg.features.show_voucher)    tabs.push(['voucher', 'Voucher']);
          if (cfg.features.show_mpesa_code) tabs.push(['mpesa', 'M-Pesa Code']);
          return tabs.map(([id, label]) =>
            \`<div class="tab \${state.tab === id ? 'active' : ''}" data-tab="\${id}">\${label}</div>\`
          ).join('');
        }

        function statusHtml() {
          if (!state.status) return '';
          return \`<div class="status \${state.status}">\${state.message}</div>\`;
        }

        function formatCountdown(seconds) {
          if (seconds == null) return '';
          if (seconds <= 0) return 'Ending now';
          const d = Math.floor(seconds / 86400);
          const h = Math.floor((seconds % 86400) / 3600);
          const m = Math.floor((seconds % 3600) / 60);
          const s = Math.floor(seconds % 60);
          if (d > 0) return d + 'd ' + h + 'h ' + m + 'm';
          if (h > 0) return h + 'h ' + m + 'm ' + s + 's';
          return m + 'm ' + s + 's';
        }

        function promoHtml() {
          if (!state.promos.length) return '';
          return state.promos.map(p => {
            const stockRatio = (p.max_redemptions && p.remaining_stock != null)
              ? Math.max(p.remaining_stock / p.max_redemptions, 0)
              : null;
            const secondsLeft = promoState[p.id] != null ? promoState[p.id] : p.seconds_remaining;
            const showTimer = p.show_countdown_timer && secondsLeft != null;
            const showStock = p.show_stock_indicator && stockRatio != null;
            return \`
            <div class="promo" data-promo="\${p.id}">
              <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
                <span class="badge">🔥 \${p.badge_text || (p.savings_percent + '% OFF')}</span>
                \${showTimer ? '<span class="promo-timer" data-promo-timer="' + p.id + '">' + formatCountdown(secondsLeft) + '</span>' : ''}
                \${cfg.preview && String(p.id).startsWith('mock-') ? '<span class="mock-tag">Sample</span>' : ''}
              </div>
              <p style="font-weight:700;font-size:13px;">\${p.name}</p>
              \${p.description ? \`<p style="color:var(--muted);font-size:12px;margin:4px 0 8px;">\${p.description}</p>\` : ''}
              <div style="display:flex;justify-content:space-between;align-items:flex-end;">
                <div>
                  <span class="price">Ksh \${Number(p.promotional_price).toFixed(2)}</span>
                  <span class="price-old">Ksh \${Number(p.original_price).toFixed(2)}</span>
                </div>
                <button class="btn" style="width:auto;padding:8px 14px;font-size:12px;" data-promo-claim="\${p.id}">Claim Offer</button>
              </div>
              \${showStock ? \`
                <div class="promo-stock">
                  <div class="promo-stock-label">👥 \${p.remaining_stock} left</div>
                  <div class="promo-stock-bar"><div class="promo-stock-fill" style="width:\${Math.round(stockRatio * 100)}%;background:\${stockRatio < 0.2 ? '#f87171' : '#fbbf24'}"></div></div>
                </div>
              \` : ''}
            </div>
          \`;
          }).join('');
        }

        function startPromoTimers() {
          if (promoTimerInterval) clearInterval(promoTimerInterval);
          state.promos.forEach(p => {
            if (promoState[p.id] == null && p.seconds_remaining != null) promoState[p.id] = p.seconds_remaining;
          });
          promoTimerInterval = setInterval(() => {
            Object.keys(promoState).forEach(id => {
              if (promoState[id] > 0) promoState[id] -= 1;
              const el = document.querySelector('[data-promo-timer="' + id + '"]');
              if (el) el.textContent = formatCountdown(promoState[id]);
            });
          }, 1000);
        }

        function panelHtml() {
          if (state.tab === 'packages') {
            if (!state.packagesLoaded) {
              return statusHtml() + '<div class="pkg-skeleton"></div><div class="pkg-skeleton"></div><div class="pkg-skeleton"></div>';
            }
            const isMock = cfg.preview && state.packages.length && String(state.packages[0].id).startsWith('mock-');


            // ── Focused pay step: shown the instant a package is tapped,
            // so a non-technical customer never has to scroll to find the
            // phone-number field or guess what to do next. ──────────────
            if (state.payStep === 'pay' && state.selected) {
              return statusHtml() + \`
                <div class="step-back" data-back-to-list>← Back to packages</div>
                <div class="pkg-recap">
                  <div>
                    <div class="pkg-recap-name">\${state.selected.name}</div>
                    \${state.selected.valid ? '<div class="pkg-recap-sub">' + state.selected.valid + '</div>' : ''}
                  </div>
                  <div class="pkg-recap-price">Ksh \${state.selected.price}</div>
                </div>
                <div class="pay-instructions">
                  <span class="num">1</span>
                  <span>Enter your M-Pesa phone number below, then tap <strong>Pay</strong>. You'll get a prompt on your phone — enter your M-Pesa PIN to finish connecting.</span>
                </div>
                <label class="field-label">M-Pesa Phone Number</label>
                <input class="field" id="phone" inputmode="tel" placeholder="07XX XXX XXX" value="\${state.phone || ''}">
                <button class="btn" id="pay-btn">Pay Ksh \${state.selected.price} via M-Pesa</button>
              \`;
            }

            const freeTrialPkgs = state.packages.filter(p => p.enable_free_trial);
            const paidPkgs = state.packages.filter(p => !p.enable_free_trial);

            const list = paidPkgs.map(p => \`
              <div class="pkg" data-pkg="\${p.id}">
                <div><strong>\${p.name}</strong>\${isMock ? '<span class="mock-tag">Sample</span>' : ''}<br><small>\${p.valid || ''}</small></div>
                <div>Ksh \${p.price}</div>
              </div>\`).join('');
            const empty = !state.packages.length
              ? '<p style="color:var(--muted);font-size:12px;padding:8px 0;">No packages configured yet.</p>'
              : '';
            const hint = paidPkgs.length ? '<p class="tap-hint">Tap a package to continue</p>' : '';
            return statusHtml() + freeTrialHtml(freeTrialPkgs) + hint + list + empty;
          }
          if (state.tab === 'voucher') {
            return statusHtml() + \`
              <input class="field" id="voucher-code" placeholder="Enter voucher code">
              <button class="btn" id="voucher-btn">Connect with Voucher</button>\`;
          }
          if (state.tab === 'mpesa') {
            return statusHtml() + \`
              <input class="field" id="tx-code" placeholder="e.g. QHJ1234ABC">
              <button class="btn" id="mpesa-btn">Verify & Connect</button>\`;
          }
          return '';
        }



        function bindEvents() {
          document.querySelectorAll('[data-tab]').forEach(el =>
            el.onclick = () => { state.tab = el.dataset.tab; state.status = null; state.payStep = 'list'; state.selected = null; render(); });

          document.querySelectorAll('[data-pkg]').forEach(el =>
            el.onclick = () => {
              state.selected = state.packages.find(p => String(p.id) === el.dataset.pkg);
              state.payStep = 'pay';
              render();
              requestAnimationFrame(() => {
                const card = document.querySelector('.card');
                if (card) card.scrollIntoView({ behavior: 'smooth', block: 'start' });
              });
            });

          document.querySelectorAll('[data-back-to-list]').forEach(el =>
            el.onclick = () => { state.payStep = 'list'; state.selected = null; state.status = null; render(); });

          const payBtn = document.getElementById('pay-btn');
          if (payBtn) payBtn.onclick = () => {
            state.phone = document.getElementById('phone').value;
            payPackage();
          };

          const voucherBtn = document.getElementById('voucher-btn');
          if (voucherBtn) voucherBtn.onclick = () => {
            connectVoucher(document.getElementById('voucher-code').value);
          };

          const mpesaBtn = document.getElementById('mpesa-btn');
          if (mpesaBtn) mpesaBtn.onclick = () => {
            connectReceipt(document.getElementById('tx-code').value);
          };

          document.querySelectorAll('[data-promo-claim]').forEach(el =>
            el.onclick = () => {
              const promo = state.promos.find(p => String(p.id) === el.dataset.promoClaim);
              if (!promo) return;
              if (cfg.preview && String(promo.id).startsWith('mock-')) {
                // Sample promo — just switch tabs and preview the pricing, no real package to select.
                state.tab = 'packages';
                state.payStep = 'list';
                render();
                return;
              }
              const pkg = state.packages.find(p => String(p.id) === String(promo.package_id));
              state.selected = pkg ? { ...pkg, price: promo.promotional_price } : { id: promo.package_id, name: promo.package_name, price: promo.promotional_price };
              state.tab = 'packages';
              state.payStep = 'pay';
              render();
              requestAnimationFrame(() => {
                const card = document.querySelector('.card');
                if (card) card.scrollIntoView({ behavior: 'smooth', block: 'start' });
              });
            });
        }

        function setStatus(status, message) { state.status = status; state.message = message; render(); }


function renderQueryModal() {
  let root = document.getElementById('query-modal-root');
  if (!root) {
    root = document.createElement('div');
    root.id = 'query-modal-root';
    document.body.appendChild(root);
  }
  if (!queryModal.status) { root.innerHTML = ''; return; }

  const titles = {
    processing: 'Payment Processing', success: 'Payment Successful',
    cancelled: 'Payment Cancelled', no_response: 'No Response',
    invalid_initiator: 'Invalid Information', error: 'Payment Error',
  };
  const icons = {
    processing: '⏳', success: '✅', cancelled: '❌',
    no_response: 'ℹ️', invalid_initiator: '⚠️', error: '⚠️',
  };

  root.innerHTML = `
    <div style="position:fixed;inset:0;z-index:20000;display:flex;align-items:center;justify-content:center;background:rgba(2,6,23,.75);backdrop-filter:blur(6px);">
      <div style="background:var(--surface);color:var(--text);border-radius:20px;max-width:380px;width:90%;padding:24px;text-align:center;box-shadow:0 30px 60px rgba(0,0,0,.5);">
        <div style="font-size:32px;margin-bottom:10px;">${icons[queryModal.status] || 'ℹ️'}</div>
        <h3 style="font-size:18px;font-weight:700;margin-bottom:10px;">${titles[queryModal.status] || 'Status'}</h3>
        <p style="font-size:14px;color:var(--muted);margin-bottom:20px;line-height:1.5;">${queryModal.message}</p>
        ${queryModal.status === 'processing' ? `
          <div style="margin:0 auto 16px;width:36px;height:36px;border:3px solid color-mix(in srgb, var(--primary) 25%, transparent);border-top-color:var(--primary);border-radius:50%;animation:spin 0.8s linear infinite;"></div>
          <div style="display:flex;gap:8px;">
            <button id="qm-stop" class="btn" style="background:color-mix(in srgb, var(--text) 12%, transparent);color:var(--text);">Stop Checking</button>
            <button id="qm-check" class="btn">Check Now</button>
          </div>
        ` : `
          <button id="qm-close" class="btn">Close</button>
        `}
      </div>
    </div>
    <style>@keyframes spin { to { transform: rotate(360deg); } }</style>
  `;

  const stopBtn = document.getElementById('qm-stop');
  if (stopBtn) stopBtn.onclick = () => {
    if (stkQueryInterval) { clearInterval(stkQueryInterval); stkQueryInterval = null; }
    queryModal = { status: null, message: '' };
    renderQueryModal();
  };
  const checkBtn = document.getElementById('qm-check');
  if (checkBtn) checkBtn.onclick = () => {
    if (stkQueryInterval) { clearInterval(stkQueryInterval); stkQueryInterval = null; }
    startQueryStatus();
  };
  const closeBtn = document.getElementById('qm-close');
  if (closeBtn) closeBtn.onclick = () => {
    queryModal = { status: null, message: '' };
    renderQueryModal();
  };
}

// Full-screen "Connected!" overlay, matching React's <ConnectedScreen/> — shown
// after voucher / receipt / M-Pesa / autologin success, with a manual
// "Start Browsing" escape hatch in addition to the automatic redirect below.
function renderConnectedScreen() {
  let root = document.getElementById('connected-root');
  if (!root) {
    root = document.createElement('div');
    root.id = 'connected-root';
    document.body.appendChild(root);
  }
  if (!connectedInfo) { root.innerHTML = ''; return; }

  const rows = [
    ['Username', connectedInfo.username],
    ['Package', connectedInfo.package],
    ['Expires', connectedInfo.expiration],
  ].filter(([, v]) => v);

  root.innerHTML = `
    <div style="position:fixed;inset:0;z-index:21000;display:flex;align-items:center;justify-content:center;background:rgba(2,6,23,.92);backdrop-filter:blur(20px);">
      <div style="background:color-mix(in srgb, var(--surface) 90%, transparent);border:1px solid color-mix(in srgb, var(--accent) 25%, transparent);border-radius:24px;max-width:360px;width:90%;padding:32px 28px;text-align:center;box-shadow:0 0 60px rgba(52,211,153,.15);">
        <div style="width:64px;height:64px;margin:0 auto 20px;border-radius:20px;background:color-mix(in srgb, var(--accent) 15%, transparent);border:1px solid color-mix(in srgb, var(--accent) 30%, transparent);display:flex;align-items:center;justify-content:center;font-size:28px;">✅</div>
        <h2 style="font-size:22px;font-weight:800;color:var(--text);margin-bottom:4px;">Connected!</h2>
        <p style="font-size:13px;color:var(--muted);margin-bottom:22px;">You're online — enjoy browsing.</p>
        ${rows.length ? `
          <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:22px;text-align:left;">
            ${rows.map(([l, v]) => `
              <div style="display:flex;justify-content:space-between;align-items:center;padding:10px 14px;border-radius:12px;background:color-mix(in srgb, var(--text) 6%, transparent);">
                <span style="font-size:11px;color:var(--muted);">${l}</span>
                <span style="font-size:13px;font-weight:700;color:var(--text);">${v}</span>
              </div>
            `).join('')}
          </div>
        ` : ''}
        <button id="connected-start-btn" class="btn">Start Browsing →</button>
      </div>
    </div>
  `;

  const startBtn = document.getElementById('connected-start-btn');
  if (startBtn) startBtn.onclick = () => { window.location.href = '$(link-orig)'; };
}




function renderExpandedAd() {
  let root = document.getElementById('ad-expanded-root');
  if (!root) {
    root = document.createElement('div');
    root.id = 'ad-expanded-root';
    document.body.appendChild(root);
  }
  if (!expandedAdId) { root.innerHTML = ''; return; }

  const s = adState[expandedAdId];
  if (!s || s.completed) { expandedAdId = null; root.innerHTML = ''; return; }

  const ad = s.ad;
  const isVideo = ad.media_type === 'video';
  const isImage = ad.media_type === 'image';

  const rewardLabel = rewardLabelFor(ad);
  const skipCountdown = Math.max(0, (ad.skip_after || 5) - ((ad.ad_duration || 15) - s.secondsLeft));

  const media = isImage
    ? \`<img src="\${ad.media_url}" alt="\${ad.ad_title || 'Ad'}" style="width:100%;max-height:65vh;object-fit:contain;display:block;">\`
    : isVideo
      ? \`<video id="ad-expanded-video" src="\${ad.media_url}" autoplay controls playsinline style="width:100%;max-height:65vh;object-fit:contain;display:block;"></video>\`
      : '';

  const rewardBanner = isVideo ? \`
    <div style="display:flex;align-items:center;gap:10px;padding:12px 16px;background:linear-gradient(90deg,color-mix(in srgb, var(--accent) 15%, transparent),color-mix(in srgb, var(--secondary) 12%, transparent));border-bottom:1px solid color-mix(in srgb, var(--accent) 20%, transparent);">
      <div style="width:28px;height:28px;border-radius:50%;background:color-mix(in srgb, var(--accent) 20%, transparent);display:flex;align-items:center;justify-content:center;flex-shrink:0;">🎁</div>
      <div style="flex:1;min-width:0;">
        <p style="margin:0;font-size:13px;font-weight:600;color:var(--accent);">Watch this ad to unlock free internet!</p>
        <p style="margin:2px 0 0;font-size:12px;color:var(--accent);">Reward: <strong>\${rewardLabel}</strong></p>
      </div>
    </div>\` : '';

  root.innerHTML = \`
    <div id="ad-expanded-backdrop" style="position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.93);backdrop-filter:blur(16px);padding:16px;">
      <p style="position:absolute;top:16px;right:20px;font-size:12px;color:rgba(255,255,255,.7);">Press ESC or click outside to close</p>
      <div id="ad-expanded-panel" style="position:relative;width:100%;max-width:720px;border-radius:20px;overflow:hidden;box-shadow:0 30px 60px rgba(0,0,0,.5);background:color-mix(in srgb, var(--surface) 98%, transparent);border:1px solid color-mix(in srgb, var(--text) 12%, transparent);">
        \${rewardBanner}
        \${media}
        <div style="padding:14px 16px;display:flex;align-items:center;justify-content:space-between;gap:12px;">
          <div style="display:flex;align-items:center;gap:8px;min-width:0;flex:1;">
            <span style="font-size:11px;font-weight:800;padding:2px 8px;border-radius:6px;background:color-mix(in srgb, var(--primary) 15%, transparent);color:var(--primary);">Ad</span>
            \${ad.ad_title ? \`<span style="font-size:13px;font-weight:600;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">\${ad.ad_title}</span>\` : ''}
          </div>
          <div style="display:flex;align-items:center;gap:8px;flex-shrink:0;">
            \${isVideo && ad.can_skip && s.skipReady ? \`<button id="ad-expanded-skip" style="display:flex;align-items:center;gap:5px;font-size:13px;padding:7px 12px;border-radius:10px;font-weight:700;border:none;background:color-mix(in srgb, var(--accent) 18%, transparent);color:var(--accent);cursor:pointer;">Skip Ad ⏭</button>\` : ''}
            \${isVideo && ad.can_skip && !s.skipReady ? \`<span style="font-size:12px;padding:7px 12px;border-radius:10px;background:color-mix(in srgb, var(--text) 8%, transparent);color:var(--muted);">\${skipCountdown}s remaining</span>\` : ''}
            \${ad.ad_link ? \`<button id="ad-expanded-visit" style="display:flex;align-items:center;gap:5px;font-size:13px;padding:7px 12px;border-radius:10px;font-weight:700;border:none;background:color-mix(in srgb, var(--primary) 15%, transparent);color:var(--primary);cursor:pointer;">Visit ↗</button>\` : ''}
            \${isImage ? \`<button id="ad-expanded-dismiss" style="display:flex;align-items:center;gap:5px;font-size:13px;padding:7px 12px;border-radius:10px;font-weight:600;border:none;background:color-mix(in srgb, var(--text) 10%, transparent);color:var(--muted);cursor:pointer;">✕ Close Ad</button>\` : ''}
            <button id="ad-expanded-collapse" style="display:flex;align-items:center;justify-content:center;width:32px;height:32px;border-radius:10px;border:none;background:color-mix(in srgb, var(--text) 10%, transparent);color:var(--muted);cursor:pointer;">⤡</button>
          </div>
        </div>
        \${isVideo ? \`<div style="height:3px;background:color-mix(in srgb, var(--text) 10%, transparent);"><div style="height:100%;width:\${((ad.ad_duration || 15) - s.secondsLeft) / (ad.ad_duration || 15) * 100}%;background:linear-gradient(90deg,var(--accent),var(--secondary));transition:width 1s linear;"></div></div>\` : ''}
      </div>
    </div>\`;

  const backdrop = document.getElementById('ad-expanded-backdrop');
  const panel = document.getElementById('ad-expanded-panel');
  if (backdrop) backdrop.onclick = () => collapseExpandedAd();
  if (panel) panel.onclick = (e) => e.stopPropagation();

  const collapseBtn = document.getElementById('ad-expanded-collapse');
  if (collapseBtn) collapseBtn.onclick = () => collapseExpandedAd();

  const dismissBtn = document.getElementById('ad-expanded-dismiss');
  if (dismissBtn) dismissBtn.onclick = () => { collapseExpandedAd(); completeAd(ad.id, 'dismissed'); };

  const skipBtn = document.getElementById('ad-expanded-skip');
  if (skipBtn) skipBtn.onclick = () => { collapseExpandedAd(); completeAd(ad.id, 'skipped'); };

  const visitBtn = document.getElementById('ad-expanded-visit');
  if (visitBtn) visitBtn.onclick = () => {
    trackAdEvent(ad.id, 'click');
    if (ad.ad_link && !cfg.preview) window.open(ad.ad_link, '_blank');
  };

  if (isVideo) {
    const inlineVideo = document.getElementById('ad-video-' + ad.id);
    const expandedVideo = document.getElementById('ad-expanded-video');
    if (inlineVideo && expandedVideo) {
      expandedVideo.currentTime = inlineVideo.currentTime || 0;
      inlineVideo.pause();
    }
    if (expandedVideo) {
      expandedVideo.onended = () => { collapseExpandedAd(); completeAd(ad.id, 'completed'); };
    }
  }
}

function collapseExpandedAd() {
  const s = expandedAdId && adState[expandedAdId];
  if (s && s.ad.media_type === 'video') {
    const inlineVideo = document.getElementById('ad-video-' + expandedAdId);
    const expandedVideo = document.getElementById('ad-expanded-video');
    if (inlineVideo && expandedVideo) {
      inlineVideo.currentTime = expandedVideo.currentTime || 0;
      inlineVideo.play().catch(() => {});
    }
  }
  expandedAdId = null;
  renderExpandedAd();
}

function startQueryStatus() {
  if (stkQueryInterval) clearInterval(stkQueryInterval);

  stkQueryInterval = setInterval(async () => {
    const checkout_request_id = localStorage.getItem('checkout_request_id');
    if (!checkout_request_id) { clearInterval(stkQueryInterval); stkQueryInterval = null; return; }

    try {
      const res = await fetch(api('/api/query_status'), {
        method: 'POST', headers,
        body: JSON.stringify({ checkout_request_id })
      });
      const data = await res.json();
      if (!res.ok) return;

      const code = data.response && data.response.ResultCode;
      switch (code) {
        case '0':
          clearInterval(stkQueryInterval); stkQueryInterval = null;
          queryModal = { status: null, message: '' };
          renderQueryModal();
          localStorage.removeItem('checkout_request_id');
          onConnected({ package: state.selected && state.selected.name });
          break;
        case '4999':
          queryModal = { status: 'processing', message: 'The transaction is still under processing. Please wait…' };
          renderQueryModal();
          break;
        case '1037':
          clearInterval(stkQueryInterval); stkQueryInterval = null;
          queryModal = { status: 'no_response', message: 'No response received from user. Please complete the M-Pesa prompt.' };
          renderQueryModal();
          localStorage.removeItem('checkout_request_id');
          break;
        case '1032':
          clearInterval(stkQueryInterval); stkQueryInterval = null;
          queryModal = { status: 'cancelled', message: 'Payment was cancelled. Please try again.' };
          renderQueryModal();
          localStorage.removeItem('checkout_request_id');
          break;
        case '2001':
          clearInterval(stkQueryInterval); stkQueryInterval = null;
          queryModal = { status: 'invalid_initiator', message: 'The initiator information is invalid.' };
          renderQueryModal();
          localStorage.removeItem('checkout_request_id');
          break;
        default:
          clearInterval(stkQueryInterval); stkQueryInterval = null;
          queryModal = { status: 'error', message: (data.response && data.response.ResultDesc) || 'Payment failed. Please try again.' };
          renderQueryModal();
          localStorage.removeItem('checkout_request_id');
      }
    } catch (e) { /* keep polling on transient errors */ }
  }, 5000);
}


        
        async function loadPackages() {
          try {
            const res = await fetch(api('/api/allow_get_hotspot_packages'), { headers });
            const data = res.ok ? await res.json() : [];
            state.packages = (cfg.preview && (!data || !data.length)) ? MOCK_PACKAGES : (data || []);
          } catch (e) {
           console.error('Failed to load packages (check CORS / walled-garden):', e);
            document.getElementById('panel').innerHTML = '<div class="status error">DEBUG: ' + e.message + '</div>';
            state.packages = cfg.preview ? MOCK_PACKAGES : [];
          } finally {
            state.packagesLoaded = true;
            render();
          }
        }

        async function loadPromotions() {
          try {
            const res = await fetch(api('/api/hotspot_active_promotions'), { headers });
            const data = res.ok ? await res.json() : [];
            state.promos = (cfg.preview && (!data || !data.length)) ? [MOCK_PROMO] : (data || []);
          } catch (e) {
            console.error('Failed to load promotions:', e);
            state.promos = cfg.preview ? [MOCK_PROMO] : [];
          }
          const root = document.getElementById('promo-root');
          if (root) root.innerHTML = promoHtml();
          bindEvents();
          startPromoTimers();
        }



async function startFreeTrial(pkg) {
  freeTrialState[pkg.id] = { loading: true, success: false, error: null };
  render();
  try {
    const res = await fetch(api('/api/grant_free_trial'), {
      method: 'POST', headers,
      body: JSON.stringify({ mac, ip, package: pkg.name })
    });
    const data = await res.json();
    if (res.ok) {
      freeTrialState[pkg.id] = { loading: false, success: true, error: null };
      onConnected({ package: pkg.name });
    } else {
      freeTrialState[pkg.id] = { loading: false, success: false, error: data.error || 'Could not start free trial.' };
      render();
    }
  } catch (e) {
    freeTrialState[pkg.id] = { loading: false, success: false, error: 'Network error. Check your connection and try again.' };
    render();
  }
}



function freeTrialHtml(trialPkgs) {
          if (cfg.features.show_free_trial === false) return '';
          if (!trialPkgs || !trialPkgs.length) return '';
          return trialPkgs.map(p => {
            const s = freeTrialState[p.id] || {};
            const mins = p.free_trial_duration_minutes;
            return \`
              <div class="pkg-freetrial">
                <span class="icon">⚡</span>
                <div style="flex:1;">
                  <div class="pkg-freetrial-title">Free Trial — \${mins} min</div>
                  <div class="pkg-freetrial-sub">Get \${mins} minute\${mins !== 1 ? 's' : ''} of free internet access.</div>
                  \${s.error ? '<div class="status error" style="margin-top:8px;margin-bottom:0;">' + s.error + '</div>' : ''}
                  \${!s.success ? '<button class="pkg-freetrial-btn" data-freetrial="' + p.id + '" ' + (s.loading ? 'disabled' : '') + '>' + (s.loading ? 'Starting trial…' : 'Start Free Trial') + '</button>' : ''}
                </div>
              </div>\`;
          }).join('');
        }




async function payPackage() {
  queryModal = { status: 'processing', message: 'STK push sent — enter your M-Pesa PIN on your phone to complete payment.' };
  renderQueryModal();
  try {
    const res = await fetch(api('/api/make_payment'), {
      method: 'POST', headers,
      body: JSON.stringify({ phone_number: state.phone, amount: state.selected.price, package: state.selected.name, mac, ip })
    });
    const data = await res.json();
    if (res.ok) {
      localStorage.setItem('checkout_request_id', data.checkout_request_id);
      startQueryStatus();
    } else {
      queryModal = { status: 'error', message: data.message || 'Payment failed' };
      renderQueryModal();
    }
  } catch (e) {
    console.error(e);
    queryModal = { status: 'error', message: 'Network error — check your connection' };
    renderQueryModal();
  }
}

        function pollPaymentStatus() {
          let elapsed = 0;
          const iv = setInterval(async () => {
            elapsed += 5000;
            try {
              const res = await fetch(api('/api/receipt_number_status'), {
                method: 'POST', headers, body: JSON.stringify({ mac, ip })
              });
              const data = await res.json();
              if (data.connected) {
                clearInterval(iv);
                onConnected({ username: data.username, package: data.package, expiration: data.expiration });
                return;
              }
            } catch (e) { console.error(e); }
            if (elapsed >= 120000) {
              clearInterval(iv);
              setStatus('error', 'Timed out. Please check your M-Pesa SMS and try the receipt tab.');
            }
          }, 5000);
        }

        async function connectVoucher(code) {
          setStatus('processing', 'Connecting…');
          try {
            const res = await fetch(api('/api/login_with_hotspot_voucher'), {
              method: 'POST', headers, body: JSON.stringify({ voucher: code, mac, ip })
            });
            const data = await res.json();
            if (res.ok) {
              onConnected({ username: data.username, package: data.package, expiration: data.expiration });
            } else {
              setStatus('error', data.error || 'Invalid voucher code. Please check and try again.');
            }
          } catch (e) { console.error(e); setStatus('error', 'Network error. Check your connection and try again.'); }
        }

        async function connectReceipt(code) {
          setStatus('processing', 'Verifying your M-Pesa transaction…');
          try {
            const res = await fetch(api('/api/login_with_receipt_number'), {
              method: 'POST', headers, body: JSON.stringify({ receipt_number: code, mac, ip })
            });
            if (res.ok) {
              setStatus('processing', 'Transaction found — activating your session…');
              pollPaymentStatus();
            } else {
              const data = await res.json().catch(() => ({}));
              setStatus('error', data.error || 'Transaction not found. Check the code and try again.');
            }
          } catch (e) { console.error(e); setStatus('error', 'Network error. Check your connection and try again.'); }
        }

        function onConnected(details) {
          details = details || {};
          connectedInfo = {
            username: details.username || username || '',
            package: details.package || (state.selected && state.selected.name) || '',
            expiration: details.expiration || '',
          };
          // Critical for autologin: nothing else in this file ever wrote
          // hotspot_username to localStorage. Without this, `username` is
          // null on every future page load and tryAutoLogin() bails out
          // before it even makes a request. This is what lets the NEXT
          // visit from this device recognize it and reconnect silently.
          if (connectedInfo.username) localStorage.setItem('hotspot_username', connectedInfo.username);
          renderConnectedScreen();
          setStatus('success', 'Connected! Redirecting…');
          setTimeout(() => { window.location.href = '$(link-orig)'; }, 4000);
        }

        // ── Autologin / autoreconnect ───────────────────────────────────
        // Mirrors React's voucherAutoLogin(): if the account has
        // enable_autologin on, and this mac/ip is recognized from a prior
        // session, silently re-establish the connection instead of making
        // the customer buy/enter anything again. No-op only in preview —
        // mac/ip are always available (router-substituted), so this always
        // attempts the check; `username` (if we happen to have one stored)
        // is passed as an extra hint but is never required.
       async function tryAutoLogin() {
          try {
            const custRes = await fetch(api('/api/allow_get_hotspot_customization'), { headers });
            if (!custRes.ok) { console.info('[autologin] skipped: could not load customization settings'); return; }
            const custRaw = await custRes.json();
            const cust = Array.isArray(custRaw) ? custRaw[0] : custRaw;
            if (!cust || !cust.enable_autologin) { console.info('[autologin] skipped: enable_autologin is off'); return; }

            const sessionRes = await fetch(
              api('/api/check_session?username=' + encodeURIComponent(username || '') +
                  '&mac=' + encodeURIComponent(mac || '') +
                  '&ip=' + encodeURIComponent(ip || '')),
              { headers }
            );
            const sessionData = await sessionRes.json();
            if (!sessionRes.ok || !sessionData.session_active) {
              console.info('[autologin] skipped: no active session for mac', mac);
              return;
            }

            const loginRes = await fetch(api('/api/login_with_hotspot_voucher'), {
              method: 'POST', headers,
              body: JSON.stringify({
                voucher: sessionData.username,
                stored_mac: localStorage.getItem('hotspot_mac'),
                stored_ip: localStorage.getItem('hotspot_ip'),
                mac, ip: sessionData.ip || ip,
              }),
            });
            const loginData = await loginRes.json();
            if (loginRes.ok) {
              console.info('[autologin] reconnected as', loginData.username || sessionData.username);
              onConnected({
                username: loginData.username || sessionData.username,
                package: loginData.package || sessionData.package,
                expiration: loginData.expiration || sessionData.expiration,
              });
            } else {
              console.info('[autologin] session was active but re-login was rejected:', loginData.error || loginRes.status);
            }
          } catch (e) {
            console.error('[autologin] failed:', e);
          }
        }

        // ── Ads ──────────────────────────────────────────────────────────
      const AD_POSITIONS = {
  'top-banner':    'position:fixed;top:0;left:0;right:0;z-index:9999;',
  'bottom-banner': 'position:fixed;bottom:0;left:0;right:0;z-index:9999;',
  'bottom-right':  'position:fixed;bottom:16px;right:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
  'bottom-left':   'position:fixed;bottom:16px;left:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
  'top-left':      'position:fixed;top:16px;left:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
  'top-right':     'position:fixed;top:16px;right:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
  'center-modal':  'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(2,6,23,.8);backdrop-filter:blur(12px);',
  'fullscreen':    'position:fixed;inset:0;z-index:9999;display:flex;flex-direction:column;background:rgba(2,6,23,.96);',
};

        const adState = {};
        const adTimers = {};
        const adSkipTimers = {};

        function rewardLabelFor(ad) {
          if (ad.reward_type === 'specific')    return ad.package_name || 'Internet Package';
          if (ad.reward_type === 'free_browse') return ad.free_minutes >= 60 ? (ad.free_minutes / 60) + 'hr Free Internet' : ad.free_minutes + 'min Free Internet';
          if (ad.reward_type === 'choice')      return 'Choose Your Package';
          return 'Free Internet Access';
        }

        function trackAdEvent(adId, eventType) {
          if (!adId || cfg.preview) return;
          fetch(api('/api/track_ad_event'), {
            method: 'POST', headers,
            body: JSON.stringify({ event_type: eventType, ad_id: adId })
          }).catch(() => {});
        }

        function grantAdReward(ad) {
          if (cfg.preview) return;
          if (ad.reward_type === 'free_browse') {
            fetch(api('/api/grant_free_browsing'), {
              method: 'POST', headers,
              body: JSON.stringify({ mac, ip, minutes: ad.free_minutes })
            }).catch(() => {});
          }
          if (ad.reward_type === 'specific' && ad.selected_package) {
            const pkg = state.packages.find(p => String(p.id) === String(ad.selected_package));
            if (pkg) { state.selected = pkg; state.tab = 'packages'; state.payStep = 'pay'; render(); }
          }
        }

        function customDesignHtml(ad) {
          let elements = [];
          try { elements = JSON.parse(ad.design_config || '[]'); } catch (_) {}
          const bg = ad.design_background || '#0ea5e9';
          const w = parseInt(ad.design_canvas_w) || 320;
          const h = parseInt(ad.design_canvas_h) || 280;

          const parts = elements.map(el => {
            if (el.type === 'text') {
              return \`<div style="position:absolute;left:\${el.x}px;top:\${el.y}px;width:\${el.width}px;font-family:'\${el.fontFamily}';font-size:\${el.fontSize}px;color:\${el.color};font-weight:\${el.fontWeight};font-style:\${el.fontStyle};text-decoration:\${el.textDecoration};text-align:\${el.align};line-height:1.3;">\${el.content}</div>\`;
            }
            if (el.type === 'button' || el.type === 'badge') {
              return \`<div style="position:absolute;left:\${el.x}px;top:\${el.y}px;width:\${el.width}px;height:\${el.height}px;background:\${el.bg};border-radius:\${el.radius}px;display:flex;align-items:center;justify-content:center;font-family:'\${el.fontFamily}';font-size:\${el.fontSize}px;color:\${el.color};font-weight:600;">\${el.content}</div>\`;
            }
            if (el.type === 'shape') {
              const isCircle = el.shape === 'circle';
              return \`<div style="position:absolute;left:\${el.x}px;top:\${el.y}px;width:\${el.size}px;height:\${isCircle ? el.size : el.size * 0.6}px;background:\${el.bg};border-radius:\${isCircle ? '50%' : (el.shape === 'badge' ? '50px' : '6px')};opacity:\${el.opacity};"></div>\`;
            }
            if (el.type === 'image' && el.src) {
              return \`<div style="position:absolute;left:\${el.x}px;top:\${el.y}px;width:\${el.width}px;height:\${el.height}px;overflow:hidden;border-radius:8px;"><img src="\${el.src}" style="width:100%;height:100%;object-fit:cover;"></div>\`;
            }
            return '';
          }).join('');

          const visitBtn = ad.ad_link
            ? \`<button data-ad-visit="\${ad.id}" style="position:absolute;bottom:8px;left:8px;display:flex;align-items:center;gap:4px;padding:4px 10px;border-radius:20px;border:none;background:rgba(0,0,0,.5);color:#fff;font-size:11px;font-weight:600;cursor:pointer;">Visit ↗</button>\`
            : '';
          const closeBtn = \`<button data-ad-dismiss="\${ad.id}" style="position:absolute;top:8px;right:8px;width:24px;height:24px;border-radius:50%;background:rgba(0,0,0,.5);border:none;color:#fff;cursor:pointer;">✕</button>\`;

          return \`<div data-ad-track="\${ad.id}" style="position:relative;width:\${w}px;max-width:320px;height:\${h}px;background:\${bg};border-radius:10px;overflow:hidden;cursor:pointer;">\${parts}\${visitBtn}\${closeBtn}</div>\`;
        }

     function adCardHtml(ad) {
  const s = adState[ad.id];
  if (!s || s.completed) return '';
  const isVideo = ad.media_type === 'video';
  const isImage = ad.media_type === 'image';
  const isCustom = ad.media_type === 'custom_design';
  const isMock = cfg.preview && String(ad.id) === 'mock-ad';
  const isFullscreen = ad.position === 'fullscreen';

  let media = '';
  if (isImage) {
    media = isFullscreen
      ? \`<img src="\${ad.media_url}" style="width:100%;flex:1;object-fit:contain;display:block;">\`
      : \`<img src="\${ad.media_url}" style="width:100%;max-height:220px;object-fit:cover;display:block;">\`;
  } else if (isVideo) {
    media = isFullscreen
      ? \`<video id="ad-video-\${ad.id}" src="\${ad.media_url}" autoplay playsinline style="width:100%;flex:1;object-fit:contain;display:block;"></video>\`
      : \`<video id="ad-video-\${ad.id}" src="\${ad.media_url}" autoplay playsinline style="width:100%;max-height:220px;object-fit:cover;display:block;"></video>\`;
  } else if (isCustom) {
    media = customDesignHtml(ad);
  }

  let footer = '';
  if (!isCustom) {
    const skipCountdown = Math.max(0, (ad.skip_after || 5) - ((ad.ad_duration || 15) - s.secondsLeft));
    footer = \`
      <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:10px 14px;">
        <div style="display:flex;align-items:center;gap:6px;min-width:0;flex:1;">
          <span style="font-weight:700;font-size:11px;padding:2px 6px;border-radius:4px;background:color-mix(in srgb, var(--primary) 15%, transparent);color:var(--primary);">Ad</span>
          \${isMock ? '<span class="mock-tag">Sample</span>' : ''}
          \${ad.ad_title ? \`<span style="font-size:12px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">\${ad.ad_title}</span>\` : ''}
        </div>
        <div style="display:flex;align-items:center;gap:6px;flex-shrink:0;">
          \${(isImage || isVideo) ? \`<button data-ad-expand="\${ad.id}" style="display:flex;align-items:center;justify-content:center;width:26px;height:26px;border-radius:8px;border:none;background:color-mix(in srgb, var(--text) 10%, transparent);color:var(--muted);cursor:pointer;font-size:13px;">⤢</button>\` : ''}
          \${ad.ad_link ? \`<button data-ad-visit="\${ad.id}" style="display:flex;align-items:center;gap:4px;font-size:11px;padding:5px 10px;border-radius:8px;font-weight:700;border:none;background:color-mix(in srgb, var(--primary) 15%, transparent);color:var(--primary);cursor:pointer;">Visit ↗</button>\` : ''}
          \${isVideo && ad.can_skip && s.skipReady ? \`<button data-ad-skip="\${ad.id}" style="display:flex;align-items:center;gap:4px;font-size:11px;padding:5px 10px;border-radius:8px;font-weight:700;border:none;background:color-mix(in srgb, var(--accent) 15%, transparent);color:var(--accent);cursor:pointer;">Skip ⏭</button>\` : ''}
          \${isVideo && ad.can_skip && !s.skipReady ? \`<span style="font-size:11px;padding:5px 10px;border-radius:8px;background:color-mix(in srgb, var(--text) 8%, transparent);color:var(--muted);">Skip in \${skipCountdown}s</span>\` : ''}
          \${isImage ? \`<button data-ad-dismiss="\${ad.id}" style="width:26px;height:26px;border-radius:50%;border:none;background:color-mix(in srgb, var(--text) 12%, transparent);color:var(--muted);cursor:pointer;">✕</button>\` : ''}
        </div>
      </div>\`;
  }

  const banner = isVideo ? \`
    <div style="display:flex;align-items:center;gap:10px;padding:10px 14px;background:linear-gradient(90deg,color-mix(in srgb, var(--accent) 15%, transparent),color-mix(in srgb, var(--secondary) 12%, transparent));border-bottom:1px solid color-mix(in srgb, var(--accent) 20%, transparent);">
      <div style="width:26px;height:26px;border-radius:50%;background:color-mix(in srgb, var(--accent) 20%, transparent);display:flex;align-items:center;justify-content:center;flex-shrink:0;">🎁</div>
      <div style="flex:1;min-width:0;">
        <p style="margin:0;font-size:12px;font-weight:600;color:var(--accent);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">Watch this ad to unlock free internet!</p>
        <p style="margin:2px 0 0;font-size:11px;color:var(--accent);">Reward: <strong>\${rewardLabelFor(ad)}</strong></p>
      </div>
      <div style="flex-shrink:0;display:flex;align-items:center;gap:4px;padding:3px 8px;border-radius:20px;background:rgba(0,0,0,.4);">
        <span style="font-size:11px;font-weight:700;color:#fcd34d;">\${s.secondsLeft}s</span>
      </div>
    </div>\` : '';

  const progress = isVideo
    ? \`<div style="height:2px;background:color-mix(in srgb, var(--text) 10%, transparent);"><div style="height:100%;background:linear-gradient(90deg,var(--accent),var(--secondary));width:\${((ad.ad_duration || 15) - s.secondsLeft) / (ad.ad_duration || 15) * 100}%;transition:width 1s linear;"></div></div>\`
    : '';

  const isFull = ad.position === 'fullscreen';
  return \`
    <div class="ad-card\${isFull ? ' fullscreen' : ''}" style="position:relative;\${isFull ? 'height:100%;' : ''}">
      \${banner}
      \${media}
      \${footer}
      \${progress}
    </div>\`;
}



function renderAds() {
  const root = document.getElementById('ad-root');
  if (!root) return;
  root.innerHTML = Object.values(adState)
    .filter(s => !s.completed)
    .map(s => {
      const isFullscreen = s.ad.position === 'fullscreen';
      const wrapperStyle = isFullscreen ? 'width:100%;height:100%;' : 'width:100%;max-width:340px;margin:0 auto;';
      return `<div style="${AD_POSITIONS[s.ad.position] || AD_POSITIONS['bottom-right']}"><div style="${wrapperStyle}">${adCardHtml(s.ad)}</div></div>`;
    })
    .join('');
  bindAdEvents();
}

      function bindAdEvents() {
  document.querySelectorAll('[data-ad-visit]').forEach(el => {
    el.onclick = (e) => {
      e.stopPropagation();
      const id = el.dataset.adVisit;
      const ad = adState[id]?.ad;
      trackAdEvent(id, 'click');
      if (ad?.ad_link && !cfg.preview) window.open(ad.ad_link, '_blank');
    };
  });
  document.querySelectorAll('[data-ad-skip]').forEach(el => {
    el.onclick = (e) => { e.stopPropagation(); completeAd(el.dataset.adSkip, 'skipped'); };
  });
  document.querySelectorAll('[data-ad-dismiss]').forEach(el => {
    el.onclick = (e) => { e.stopPropagation(); completeAd(el.dataset.adDismiss, 'dismissed'); };
  });
  document.querySelectorAll('[data-ad-track]').forEach(el => {
    el.onclick = () => trackAdEvent(el.dataset.adTrack, 'click');
  });
  document.querySelectorAll('[data-ad-expand]').forEach(el => {
    el.onclick = (e) => {
      e.stopPropagation();
      expandedAdId = el.dataset.adExpand;
      renderExpandedAd();
    };
  });
}

       function completeAd(adId, reason) {
  const s = adState[adId];
  if (!s || s.completed) return;
  clearInterval(adTimers[adId]);
  clearTimeout(adSkipTimers[adId]);
  s.completed = true;

  const isVideo = s.ad.media_type === 'video';
  if (isVideo) trackAdEvent(adId, reason === 'skipped' ? 'video_skipped' : 'video_completed');
  else if (s.ad.media_type === 'image') trackAdEvent(adId, 'dismissed');

  if (isVideo) grantAdReward(s.ad);

  if (expandedAdId === adId) {
    expandedAdId = null;
    renderExpandedAd();
  }

  renderAds();
}

        function startAdTimers(ad) {
          const s = adState[ad.id];
          if (ad.media_type !== 'video' || s.completed) return;

          if (ad.can_skip) {
            adSkipTimers[ad.id] = setTimeout(() => {
              s.skipReady = true;
              renderAds();
            }, (ad.skip_after || 5) * 1000);
          }

          adTimers[ad.id] = setInterval(() => {
            if (s.secondsLeft <= 1) {
              clearInterval(adTimers[ad.id]);
              s.secondsLeft = 0;
              completeAd(ad.id, 'completed');
              return;
            }
            s.secondsLeft -= 1;
            renderAds();
          }, 1000);
        }

        async function loadAds() {
          try {
            const res = await fetch(api('/api/allow_get_ads'), { headers });
            let list = [];
            if (res.ok) {
              const raw = await res.json();
              list = Array.isArray(raw) ? raw : [raw];
            }
            let eligible = list.filter(ad => ad.ad_enabled && (ad.ad_link || ad.media_url || ad.media_type === 'custom_design'));

            if (!eligible.length && cfg.preview) eligible = [MOCK_AD];
            if (!eligible.length) return;

            const byPosition = {};
            eligible.forEach(ad => {
              const pos = ad.position || 'bottom-right';
              (byPosition[pos] = byPosition[pos] || []).push(ad);
            });
            const chosen = Object.values(byPosition).map(group => {
              if (group.length === 1) return group[0];
              const key = 'ad_rotation_' + (group[0].position || 'bottom-right');
              const last = parseInt(localStorage.getItem(key) || '0', 10);
              const next = (last + 1) % group.length;
              if (!cfg.preview) localStorage.setItem(key, String(next));
              return group[next];
            });

            chosen.forEach(ad => {
              adState[ad.id] = {
                ad,
                secondsLeft: ad.media_type === 'video' ? (ad.ad_duration || 15) : 0,
                skipReady: false,
                completed: false,
                viewTracked: false,
              };
            });

            renderAds();

            Object.values(adState).forEach(s => {
              if (!s.viewTracked) { trackAdEvent(s.ad.id, 'Ad View'); s.viewTracked = true; }
              startAdTimers(s.ad);
            });
          } catch (e) {
            console.error('Failed to load ads:', e);
            if (cfg.preview) {
              adState[MOCK_AD.id] = { ad: MOCK_AD, secondsLeft: 0, skipReady: false, completed: false, viewTracked: true };
              renderAds();
            }
          }
        }
document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && expandedAdId) collapseExpandedAd(); });
        if (cfg.features.show_ads !== false) loadAds();
        loadPromotions();
        loadPackages();
        render();
        tryAutoLogin();
      })();
    JS
  end
end