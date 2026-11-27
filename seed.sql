-- （任意）動作確認用のサンプルデータ。不要なら実行しないでください。
-- 削除するときは一番下の2行を実行します。

with e as (
  insert into public.engineers (name, role) values
    ('佐藤 健太', 'バックエンド / Go'),
    ('鈴木 美咲', 'フロントエンド / React'),
    ('高橋 翔',   'インフラ / AWS'),
    ('田中 葵',   'PM / 要件定義')
  returning id, name
)
insert into public.projects (title, client, engineer_id, price, start_month, end_month, note)
select v.title, v.client, e.id, v.price, v.s, v.e, v.note
from (values
  ('EC基盤リプレイス', 'A商事',          '佐藤 健太', 800000, '2026-04', null,      '[sample]'),
  ('決済API保守',      'Bペイ',          '佐藤 健太', 300000, '2026-09', '2027-03', '[sample] 週2日'),
  ('管理画面刷新',     'C不動産',        '鈴木 美咲', 700000, '2026-06', '2026-12', '[sample]'),
  ('LP制作',           'Dフーズ',        '鈴木 美咲', 250000, '2026-11', '2026-11', '[sample]'),
  ('クラウド移行',     'E製作所',        '高橋 翔',   850000, '2026-03', '2026-10', '[sample]'),
  ('監視基盤構築',     'A商事',          '高橋 翔',   600000, '2027-01', null,      '[sample]'),
  ('新規サービスPMO',  'Fホールディングス','田中 葵',  900000, '2026-07', null,      '[sample]')
) as v(title, client, ename, price, s, e, note)
join e on e.name = v.ename;

-- サンプル削除：
-- delete from public.projects where note like '[sample]%';
-- delete from public.engineers where name in ('佐藤 健太','鈴木 美咲','高橋 翔','田中 葵') and id not in (select engineer_id from public.projects);
