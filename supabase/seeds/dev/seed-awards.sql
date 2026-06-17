-- seed-awards
-- Seeds the six SAA 2025 award categories using copy from the [iOS] Home
-- MoMorph design (screen OuH1BUTYT0). Safe to re-run: upserts on `code`.

insert into public.awards (code, name_en, name_vi, description_en, description_vi, sort_order)
values
  (
    'top_talent',
    'Top Talent',
    'Top Talent',
    'Recognizes the most outstanding individual contributors of the year.',
    'Vinh danh những cá nhân nổi bật nhất trong năm.',
    1
  ),
  (
    'top_project',
    'Top Project',
    'Top Project',
    'Honors the most impactful project delivered to clients and the company.',
    'Vinh danh dự án có tác động lớn nhất tới khách hàng và công ty.',
    2
  ),
  (
    'top_culture_fit',
    'Top Culture Fit',
    'Top Culture Fit',
    'Awarded to Sunners who best embody Sun* culture and core values.',
    'Trao cho những Sunner thể hiện rõ nhất văn hoá và giá trị cốt lõi của Sun*.',
    3
  ),
  (
    'top_new_sunner',
    'Top New Sunner',
    'Top New Sunner',
    'Celebrates new joiners who made an exceptional first-year impact.',
    'Tôn vinh những Sunner mới có dấu ấn đặc biệt trong năm đầu tiên.',
    4
  ),
  (
    'top_manager',
    'Top Manager',
    'Top Manager',
    'Recognizes leaders who built outstanding teams and outcomes this year.',
    'Vinh danh những quản lý xây dựng đội ngũ và kết quả nổi bật trong năm.',
    5
  ),
  (
    'top_mentor',
    'Top Mentor',
    'Top Mentor',
    'Honors Sunners whose mentorship lifted peers and new joiners alike.',
    'Tôn vinh những Sunner có đóng góp xuất sắc trong việc dẫn dắt đồng đội.',
    6
  )
on conflict (code) do update set
  name_en        = excluded.name_en,
  name_vi        = excluded.name_vi,
  description_en = excluded.description_en,
  description_vi = excluded.description_vi,
  sort_order     = excluded.sort_order;
