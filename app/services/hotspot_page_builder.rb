# app/services/hotspot_page_builder.rb
class HotspotPageBuilder
  def initialize(account, design_override: nil)
    @account = account
    @settings = account.hotspot_setting
    @design = design_override || @settings&.page_design || {}
    @subdomain = account.subdomain
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

  def config_json
    {
      subdomain: @subdomain,
      api_base: api_base_url,
      hotspot_name: @settings&.hotspot_name,
      hotspot_phone: @settings&.phone_number,
      hotspot_email: @settings&.email,
      features: features,
      # When true (only ever set from preview_page_design), the compiled page
      # still renders ads/packages so the designer's iframe shows what a
      # customer will actually see, but suppresses tracking + reward side
      # effects so previewing never pollutes real ad analytics or grants
      # real free browsing.
      preview: !!@preview,
    }.to_json
  end

  # Your API's real domain — router fetches this over the internet, not locally.
  def api_base_url
    base = @account.subdomain.present? ? "#{@account.subdomain}.aitechs.co.ke" : "aitechs.co.ke"
    "https://#{base}"
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
      body { background: var(--background); color: var(--text); font-size: var(--font-size); min-height: 100vh; }
      .card {
        max-width: #{layout["card_width"] || 420}px;
        margin: 48px auto;
        background: rgba(15,23,42,.72);
        backdrop-filter: blur(20px);
        border: 1px solid rgba(148,163,184,.1);
        border-radius: var(--radius);
        overflow: hidden;
      }
      .header { text-align: center; padding: 32px 24px 20px; border-bottom: 1px solid rgba(148,163,184,.08); }
      .header img.logo { max-height: 56px; margin: 0 auto 12px; display: block; }
      .header h1 { font-size: #{typography["heading_size"] || 24}px; font-weight: #{typography["weight_heading"] || 700}; }
      .header p { color: var(--muted); margin-top: 4px; }
      .tabs { display: flex; gap: 6px; padding: 16px; }
      .tab { flex: 1; text-align: center; padding: 10px; border-radius: 12px; cursor: pointer; color: var(--muted); font-size: 12px; font-weight: 600; }
      .tab.active { background: rgba(56,189,248,.12); color: var(--primary); }
      .panel { padding: 0 20px 24px; }
      .field { width: 100%; padding: 14px; border-radius: 12px; border: 1px solid rgba(148,163,184,.15); background: rgba(30,41,59,.5); color: var(--text); margin-bottom: 12px; }
      .btn { width: 100%; padding: 14px; border-radius: 12px; border: none; font-weight: 700; color: #fff; cursor: pointer;
             background: linear-gradient(135deg, var(--primary), var(--accent)); }
      .pkg { display: flex; justify-content: space-between; align-items: center; padding: 14px; border-radius: 14px;
             border: 1px solid rgba(148,163,184,.1); margin-bottom: 10px; cursor: pointer; }
      .pkg.selected { border-color: var(--primary); background: rgba(56,189,248,.06); }
      .status { padding: 12px; border-radius: 12px; margin-bottom: 12px; font-size: 13px; }
      .status.error { background: rgba(239,68,68,.1); color: #fca5a5; }
      .status.success { background: rgba(52,211,153,.1); color: #6ee7b7; }
      .status.processing { background: rgba(251,191,36,.1); color: #fcd34d; }
      .footer { text-align: center; padding: 16px; color: var(--muted); font-size: 12px; }
    CSS
  end




def skeleton_html
  logo = (header["show_logo"] != false && header["logo_url"].present?) ? %(<img class="logo" src="#{header['logo_url']}">) : ""
  wifi_icon = header["show_wifi_icon"] != false ? %(<div class="wifi-badge">📶</div>) : ""
  title = header["network_name"].presence || @settings&.hotspot_name || "Free WiFi"
  preview_badge = @preview ? %(<div style="position:fixed;top:8px;left:50%;transform:translateX(-50%);z-index:10000;background:rgba(2,6,23,.85);color:#38bdf8;font:600 11px/1 sans-serif;padding:5px 12px;border-radius:20px;letter-spacing:.02em;white-space:nowrap;">Preview — ad views aren't counted</div>) : ""
  <<~HTML
    #{preview_badge}
    <div class="card">
      <div class="header">
        #{wifi_icon}
        #{logo}
        <h1>#{title}</h1>
        <p>#{header["tagline"] || "Connect to the internet"}</p>
      </div>
      <div class="tabs" id="tabs"></div>
      <div class="panel" id="panel"></div>
      <div class="footer" id="footer">
        #{footer_cfg["support_label"] || "Need help?"} #{footer_cfg["support_phone"]}
      </div>
    </div>
    <div id="ad-root"></div>
  HTML
end




  # Vanilla JS port of the packages/voucher/mpesa flow, PLUS the ad overlay
  # (fetch / render / countdown / skip / reward / tracking). Everything here
  # talks to the same /api endpoints your React HotspotPage.jsx and
  # HotspotAdOverlay.jsx already use — this is what actually ships to the
  # router via publish_hotspot_page, so ad behavior must not diverge from
  # the live React version, or ads configured in the admin never show up
  # on the real captive portal.
  #
  # cfg.preview (only ever true from preview_page_design) renders everything
  # visually as-is, but suppresses tracking calls and reward-granting side
  # effects, so designing/previewing never skews real ad analytics.
  def compiled_js
    <<~JS
      (function () {
        const cfg = window.__HOTSPOT_CONFIG__;
        const qs = new URLSearchParams(window.location.search);
        const mac = qs.get('mac') || localStorage.getItem('hotspot_mac');
        const ip  = qs.get('ip')  || localStorage.getItem('hotspot_ip');
        if (qs.get('mac')) localStorage.setItem('hotspot_mac', qs.get('mac'));
        if (qs.get('ip'))  localStorage.setItem('hotspot_ip', qs.get('ip'));

        const headers = { 'X-Subdomain': cfg.subdomain, 'Content-Type': 'application/json' };
        const api = (path) => cfg.api_base + path;

        let state = { tab: 'packages', packages: [], selected: null, status: null, message: '' };

        function render() {
          document.getElementById('tabs').innerHTML = tabsHtml();
          document.getElementById('panel').innerHTML = panelHtml();
          document.getElementById('footer').innerHTML =
            (cfg.hotspot_phone ? cfg.hotspot_phone : '') + (cfg.hotspot_email ? ' · ' + cfg.hotspot_email : '');
          bindEvents();
        }

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

        function panelHtml() {
          if (state.tab === 'packages') {
            const list = state.packages.map(p => \`
              <div class="pkg \${state.selected?.id === p.id ? 'selected' : ''}" data-pkg="\${p.id}">
                <div><strong>\${p.name}</strong><br><small>\${p.valid || ''}</small></div>
                <div>Ksh \${p.price}</div>
              </div>\`).join('');
            const payBtn = state.selected
              ? \`<input class="field" id="phone" placeholder="07XX XXX XXX" value="\${state.phone || ''}">
                 <button class="btn" id="pay-btn">Pay Ksh \${state.selected.price} via M-Pesa</button>\`
              : '';
            return statusHtml() + list + payBtn;
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
            el.onclick = () => { state.tab = el.dataset.tab; state.status = null; render(); });

          document.querySelectorAll('[data-pkg]').forEach(el =>
            el.onclick = () => {
              state.selected = state.packages.find(p => String(p.id) === el.dataset.pkg);
              render();
            });

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
        }

        function setStatus(status, message) { state.status = status; state.message = message; render(); }

        async function loadPackages() {
          const res = await fetch(api('/api/allow_get_hotspot_packages'), { headers });
          state.packages = res.ok ? await res.json() : [];
          render();
        }

        async function payPackage() {
          setStatus('processing', 'Sending STK push…');
          const res = await fetch(api('/api/make_payment'), {
            method: 'POST', headers,
            body: JSON.stringify({ phone_number: state.phone, amount: state.selected.price, package: state.selected.name, mac, ip })
          });
          const data = await res.json();
          if (res.ok) { localStorage.setItem('checkout_request_id', data.checkout_request_id); pollPaymentStatus(); }
          else setStatus('error', data.message || 'Payment failed');
        }

        function pollPaymentStatus() {
          const iv = setInterval(async () => {
            const res = await fetch(api('/api/receipt_number_status'), {
              method: 'POST', headers, body: JSON.stringify({ mac, ip })
            });
            const data = await res.json();
            if (data.connected) { clearInterval(iv); onConnected(); }
          }, 5000);
        }

        async function connectVoucher(code) {
          setStatus('processing', 'Connecting…');
          const res = await fetch(api('/api/login_with_hotspot_voucher'), {
            method: 'POST', headers, body: JSON.stringify({ voucher: code, mac, ip })
          });
          const data = await res.json();
          if (res.ok) onConnected(); else setStatus('error', data.error || 'Invalid voucher');
        }

        async function connectReceipt(code) {
          setStatus('processing', 'Verifying transaction…');
          const res = await fetch(api('/api/login_with_receipt_number'), {
            method: 'POST', headers, body: JSON.stringify({ receipt_number: code, mac, ip })
          });
          if (res.ok) pollPaymentStatus(); else setStatus('error', 'Transaction not found');
        }

        function onConnected() {
          // Backend has already granted access via SSH/ip-binding (same pattern
          // as your existing flow) — just send the user on their way.
          setStatus('success', 'Connected! Redirecting…');
          setTimeout(() => { window.location.href = '$(link-orig)'; }, 1500);
        }

        // ── Ads ──────────────────────────────────────────────────────────
        // Ported from HotspotAdOverlay.jsx / HotspotCustomAd.jsx so this
        // vanilla page matches what admins configure and preview, instead
        // of silently dropping ads on publish.

        const AD_POSITIONS = {
          'top-banner':    'position:fixed;top:0;left:0;right:0;z-index:9999;',
          'bottom-banner': 'position:fixed;bottom:0;left:0;right:0;z-index:9999;',
          'bottom-right':  'position:fixed;bottom:16px;right:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
          'bottom-left':   'position:fixed;bottom:16px;left:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
          'top-left':      'position:fixed;top:16px;left:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
          'top-right':     'position:fixed;top:16px;right:16px;z-index:9999;width:320px;max-width:calc(100vw - 32px);',
          'center-modal':  'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(2,6,23,.8);backdrop-filter:blur(12px);',
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
          if (!adId || cfg.preview) return; // never count views/clicks while just previewing
          fetch(api('/api/track_ad_event'), {
            method: 'POST', headers,
            body: JSON.stringify({ event_type: eventType, ad_id: adId })
          }).catch(() => {});
        }

        function grantAdReward(ad) {
          // Reward granting is a video-only, watch-to-unlock mechanic — mirrors
          // handleAdComplete in HotspotAdOverlay.jsx. Image/custom-design ads
          // are click-to-visit and never grant a reward on close.
          if (cfg.preview) return; // never actually grant anything while previewing
          if (ad.reward_type === 'free_browse') {
            fetch(api('/api/grant_free_browsing'), {
              method: 'POST', headers,
              body: JSON.stringify({ mac, ip, minutes: ad.free_minutes })
            }).catch(() => {});
          }
          if (ad.reward_type === 'specific' && ad.selected_package) {
            const pkg = state.packages.find(p => String(p.id) === String(ad.selected_package));
            if (pkg) { state.selected = pkg; state.tab = 'packages'; render(); }
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

          let media = '';
          if (isImage) {
            media = \`<img src="\${ad.media_url}" style="width:100%;max-height:220px;object-fit:cover;display:block;">\`;
          } else if (isVideo) {
            media = \`<video id="ad-video-\${ad.id}" src="\${ad.media_url}" autoplay playsinline style="width:100%;max-height:220px;object-fit:cover;display:block;"></video>\`;
          } else if (isCustom) {
            media = customDesignHtml(ad);
          }

          let footer = '';
          if (!isCustom) {
            const skipCountdown = Math.max(0, (ad.skip_after || 5) - ((ad.ad_duration || 15) - s.secondsLeft));
            footer = \`
              <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:10px 14px;">
                <div style="display:flex;align-items:center;gap:6px;min-width:0;flex:1;">
                  <span style="font-weight:700;font-size:11px;padding:2px 6px;border-radius:4px;background:rgba(56,189,248,.15);color:#38bdf8;">Ad</span>
                  \${ad.ad_title ? \`<span style="font-size:12px;color:#cbd5e1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">\${ad.ad_title}</span>\` : ''}
                </div>
                <div style="display:flex;align-items:center;gap:6px;flex-shrink:0;">
                  \${ad.ad_link ? \`<button data-ad-visit="\${ad.id}" style="display:flex;align-items:center;gap:4px;font-size:11px;padding:5px 10px;border-radius:8px;font-weight:700;border:none;background:rgba(56,189,248,.15);color:#38bdf8;cursor:pointer;">Visit ↗</button>\` : ''}
                  \${isVideo && ad.can_skip && s.skipReady ? \`<button data-ad-skip="\${ad.id}" style="display:flex;align-items:center;gap:4px;font-size:11px;padding:5px 10px;border-radius:8px;font-weight:700;border:none;background:rgba(52,211,153,.15);color:#34d399;cursor:pointer;">Skip ⏭</button>\` : ''}
                  \${isVideo && ad.can_skip && !s.skipReady ? \`<span style="font-size:11px;padding:5px 10px;border-radius:8px;background:rgba(148,163,184,.08);color:#64748b;">Skip in \${skipCountdown}s</span>\` : ''}
                  \${isImage ? \`<button data-ad-dismiss="\${ad.id}" style="width:26px;height:26px;border-radius:50%;border:none;background:rgba(148,163,184,.15);color:#94a3b8;cursor:pointer;">✕</button>\` : ''}
                </div>
              </div>\`;
          }

          const banner = isVideo ? \`
            <div style="display:flex;align-items:center;gap:10px;padding:10px 14px;background:linear-gradient(90deg,rgba(16,185,129,.15),rgba(99,102,241,.12));border-bottom:1px solid rgba(16,185,129,.2);">
              <div style="width:26px;height:26px;border-radius:50%;background:rgba(16,185,129,.2);display:flex;align-items:center;justify-content:center;flex-shrink:0;">🎁</div>
              <div style="flex:1;min-width:0;">
                <p style="margin:0;font-size:12px;font-weight:600;color:#6ee7b7;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">Watch this ad to unlock free internet!</p>
                <p style="margin:2px 0 0;font-size:11px;color:#34d399;">Reward: <strong>\${rewardLabelFor(ad)}</strong></p>
              </div>
              <div style="flex-shrink:0;display:flex;align-items:center;gap:4px;padding:3px 8px;border-radius:20px;background:rgba(0,0,0,.4);">
                <span style="font-size:11px;font-weight:700;color:#fcd34d;">\${s.secondsLeft}s</span>
              </div>
            </div>\` : '';

          const progress = isVideo
            ? \`<div style="height:2px;background:rgba(148,163,184,.1);"><div style="height:100%;background:linear-gradient(90deg,#34d399,#6366f1);width:\${((ad.ad_duration || 15) - s.secondsLeft) / (ad.ad_duration || 15) * 100}%;transition:width 1s linear;"></div></div>\`
            : '';

          return \`
            <div style="border-radius:16px;overflow:hidden;background:rgba(10,16,30,.96);border:1px solid rgba(148,163,184,.12);box-shadow:0 20px 40px rgba(0,0,0,.4);position:relative;">
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
            .map(s => \`<div style="\${AD_POSITIONS[s.ad.position] || AD_POSITIONS['bottom-right']}"><div style="width:100%;max-width:340px;margin:0 auto;">\${adCardHtml(s.ad)}</div></div>\`)
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
            if (!res.ok) return;
            const raw = await res.json();
            const list = Array.isArray(raw) ? raw : [raw];
            const eligible = list.filter(ad => ad.ad_enabled && (ad.ad_link || ad.media_url || ad.media_type === 'custom_design'));
            if (!eligible.length) return;

            // One ad per position; if several share a slot, rotate which one
            // wins this page load so each eventually gets shown and tracked —
            // same behavior as HotspotAdOverlay.jsx. Skipped entirely while
            // previewing so designing never mutates real rotation state.
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
          } catch (_) {}
        }

        // Sections > Ads toggle in the page designer now actually controls
        // whether this runs at all.
        if (cfg.features.show_ads !== false) loadAds();

        loadPackages();
        render();
      })();
    JS
  end
end