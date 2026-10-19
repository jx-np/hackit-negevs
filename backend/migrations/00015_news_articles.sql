-- +goose Up
-- +goose StatementBegin
-- Scam-awareness news articles shown on the home screen. Each article carries
-- one row per locale; the public API returns every locale at once so the client
-- can pick the language. icon is a client-side icon name, never image data.
CREATE TABLE IF NOT EXISTS news_articles (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    icon text NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS news_article_translations (
    article_id bigint NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
    locale text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    PRIMARY KEY (article_id, locale)
);

CREATE INDEX IF NOT EXISTS news_articles_order_idx ON news_articles (sort_order, id) WHERE active = true;

-- Seed the pilot articles (en / ms / ta / zh). Idempotent, so a database
-- provisioned from init.sql (which already has the tables) is unaffected.
INSERT INTO news_articles (slug, icon, sort_order, active) VALUES
    ('news-1', 'message_square_warning', 1, true),
    ('news-2', 'package',                2, true),
    ('news-3', 'phone_call',             3, true)
ON CONFLICT (slug) DO NOTHING;

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
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS news_article_translations;
DROP TABLE IF EXISTS news_articles;
-- +goose StatementEnd
