-- Reference / demo data for Community Scam Shield.
-- Safe to re-run: uses ON CONFLICT upserts keyed on natural unique columns.
-- Taxonomy (categories, tags) is required before any community post can be
-- created. Guidance and resources power the "Get help now" endpoints.

-- Scam-type categories (reports.category_id). name_key/description_key are i18n keys.
INSERT INTO categories (slug, name_key, description_key) VALUES
	('scam_call',   'category.scam_call',   'category.scam_call.desc'),
	('scam_text',   'category.scam_text',   'category.scam_text.desc'),
	('phishing',    'category.phishing',    'category.phishing.desc'),
	('ecommerce',   'category.ecommerce',   'category.ecommerce.desc'),
	('investment',  'category.investment',  'category.investment.desc'),
	('job_scam',    'category.job_scam',    'category.job_scam.desc'),
	('impersonation','category.impersonation','category.impersonation.desc'),
	('other',       'category.other',       'category.other.desc')
ON CONFLICT (slug) DO UPDATE SET name_key = EXCLUDED.name_key, description_key = EXCLUDED.description_key;

-- Tags.
INSERT INTO tags (slug, name_key) VALUES
	('bank-impersonation', 'tag.bank_impersonation'),
	('otp-scam',           'tag.otp_scam'),
	('phishing',           'tag.phishing'),
	('prize-scam',         'tag.prize_scam'),
	('delivery-scam',      'tag.delivery_scam'),
	('money-request',      'tag.money_request'),
	('suspicious-link',    'tag.suspicious_link'),
	('government-impersonation', 'tag.government_impersonation'),
	('other',              'tag.other')
ON CONFLICT (slug) DO UPDATE SET name_key = EXCLUDED.name_key;

-- Official resources (vetted catalog). verified_at is required by the schema.
INSERT INTO resources (slug, country_code, url, contact_instructions, owner_name, verified_at, active) VALUES
	('scamshield',       'SG', 'https://www.scamshield.gov.sg', 'Call the ScamShield Helpline 1799', 'Content Team', now(), true),
	('police-hotline',   'SG', 'https://www.police.gov.sg',     'Call the Police Hotline 1800-255-0000, or 999 for emergencies', 'Content Team', now(), true),
	('acm-dbs',          'SG', 'https://www.dbs.com.sg/personal/support/contact-us', 'Call DBS anti-scam hotline', 'Content Team', now(), true)
ON CONFLICT (slug) DO UPDATE SET url = EXCLUDED.url, contact_instructions = EXCLUDED.contact_instructions,
	owner_name = EXCLUDED.owner_name, verified_at = EXCLUDED.verified_at, active = true;

INSERT INTO resource_translations (resource_id, locale, name, description)
SELECT r.id, 'en-SG', t.name, t.description
FROM resources r
JOIN (VALUES
	('scamshield',     'ScamShield',          'National anti-scam helpline and reporting app'),
	('police-hotline', 'Singapore Police Force', 'Report scams and seek urgent help'),
	('acm-dbs',        'DBS Anti-Scam',       'Report suspicious bank activity to DBS')
) AS t(slug, name, description) ON t.slug = r.slug
ON CONFLICT (resource_id, locale) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- Guidance scenarios.
INSERT INTO guidance (content_key, scenario, urgency, sort_order, active) VALUES
	('guidance.just_received',     'just_received',     'normal',  1, true),
	('guidance.clicked_link',      'clicked_link',      'urgent',  1, true),
	('guidance.shared_credentials','shared_credentials','urgent',  1, true),
	('guidance.sent_money',        'sent_money',        'emergency', 1, true)
ON CONFLICT (content_key) DO UPDATE SET scenario = EXCLUDED.scenario, urgency = EXCLUDED.urgency,
	sort_order = EXCLUDED.sort_order, active = true;

INSERT INTO guidance_translations (guidance_id, locale, title, body)
SELECT g.id, 'en-SG', t.title, t.body
FROM guidance g
JOIN (VALUES
	('guidance.just_received',      'You received a suspicious message', 'Do not reply, tap links, or call numbers in the message. Verify the sender through an official channel you look up yourself.'),
	('guidance.clicked_link',       'You clicked a suspicious link',     'Do not enter any details. Close the page, clear it from history, and if you entered anything, change those passwords now from the official app.'),
	('guidance.shared_credentials', 'You shared a password or OTP',      'Change the password immediately on the official site, enable 2FA, and contact the organisation. If it is a bank, call them now.'),
	('guidance.sent_money',         'You sent money',                    'Contact your bank immediately to try to stop or reverse the transfer, then report to the Police and ScamShield.')
) AS t(content_key, title, body) ON t.content_key = g.content_key
ON CONFLICT (guidance_id, locale) DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body;

-- Link guidance to relevant resources.
INSERT INTO guidance_resources (guidance_id, resource_id, sort_order)
SELECT g.id, r.id, 0
FROM guidance g, resources r
WHERE (g.scenario = 'just_received'     AND r.slug = 'scamshield')
   OR (g.scenario = 'clicked_link'      AND r.slug = 'scamshield')
   OR (g.scenario = 'shared_credentials' AND r.slug IN ('scamshield', 'acm-dbs'))
   OR (g.scenario = 'sent_money'        AND r.slug IN ('police-hotline', 'acm-dbs'))
ON CONFLICT (guidance_id, resource_id) DO NOTHING;

-- Home-screen news articles. Every locale is stored; GET /news returns them all
-- at once so the client picks the language. icon is a client-side icon name.
INSERT INTO news_articles (slug, icon, sort_order, active) VALUES
	('news-1', 'message_square_warning', 1, true),
	('news-2', 'package',                2, true),
	('news-3', 'phone_call',             3, true)
ON CONFLICT (slug) DO UPDATE SET icon = EXCLUDED.icon, sort_order = EXCLUDED.sort_order, active = true;

INSERT INTO news_article_translations (article_id, locale, title, body)
SELECT a.id, t.locale, t.title, t.body
FROM news_articles a
JOIN (VALUES
	('news-1', 'en', 'Fake bank SMS on the rise',
	 'Scammers are sending texts that look like your bank. Never tap links in a text message.'),
	('news-1', 'ms', 'SMS bank palsu semakin meningkat',
	 'Penipu menghantar mesej yang kelihatan seperti bank anda. Jangan klik pautan dalam mesej.'),
	('news-1', 'ta', 'போலி வங்கி SMS அதிகரிப்பு',
	 'மோசடி செய்பவர்கள் உங்கள் வங்கியிலிருந்து வருவது போல் செய்திகள் அனுப்புகிறார்கள். செய்தியில் உள்ள இணைப்புகளைத் தட்ட வேண்டாம்.'),
	('news-1', 'zh', '假银行短信增多',
	 '诈骗者发送看起来像银行的短信。切勿点击短信中的链接。'),

	('news-2', 'en', 'Parcel delivery scams',
	 'Getting a message about a package you didn''t order? Don''t click the link — it''s a common trick to steal your details.'),
	('news-2', 'ms', 'Penipuan penghantaran bungkusan',
	 'Menerima mesej tentang bungkusan yang tidak anda pesan? Jangan klik pautan — ia satu helah biasa untuk mencuri maklumat anda.'),
	('news-2', 'ta', 'பார்சல் டெலிவரி மோசடிகள்',
	 'நீங்கள் ஆர்டர் செய்யாத பார்சல் பற்றிய செய்தி வருகிறதா? இணைப்பைத் தட்ட வேண்டாம் — இது உங்கள் தகவலைத் திருட ஒரு பொதுவான தந்திரம்.'),
	('news-2', 'zh', '包裹递送骗局',
	 '收到一条关于你没有订购的包裹的消息？不要点击链接——这是窃取你信息的常见伎俩。'),

	('news-3', 'en', 'Government impersonation calls',
	 'No government agency will ask for your PIN or password over the phone. Hang up and call the official number.'),
	('news-3', 'ms', 'Panggilan penyamaran kerajaan',
	 'Tiada agensi kerajaan akan meminta PIN atau kata laluan anda melalui telefon. Tutup dan hubungi nombor rasmi.'),
	('news-3', 'ta', 'அரசு ஆள்மாறாட்ட அழைப்புகள்',
	 'எந்த அரசு நிறுவனமும் தொலைபேசியில் உங்கள் PIN அல்லது கடவுச்சொல்லைக் கேட்காது. தொலைபேசியை வைத்துவிட்டு அதிகாரப்பூர்வ எண்ணை அழைக்கவும்.'),
	('news-3', 'zh', '冒充政府来电',
	 '没有政府机构会通过电话索要您的PIN或密码。挂断电话并拨打官方号码。')
) AS t(slug, locale, title, body) ON t.slug = a.slug
ON CONFLICT (article_id, locale) DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body;
