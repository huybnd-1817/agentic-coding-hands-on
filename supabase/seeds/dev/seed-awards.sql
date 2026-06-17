-- seed-awards
-- Seeds the canonical 6 SAA 2026 award categories. Safe to re-run: deletes
-- any code not in the canonical set, then upserts the canonical rows.
-- Copy supplied by the user (Vietnamese descriptions verbatim).

delete from public.awards
where code not in (
  'top_talent',
  'top_project',
  'top_project_leader',
  'best_manager',
  'signature_2026_creator',
  'mvp'
);

insert into public.awards (code, name_en, name_vi, description_en, description_vi, sort_order)
values
  (
    'top_talent',
    'Top Talent',
    'Top Talent',
    'The Top Talent award honors all-rounded outstanding individuals — those who consistently demonstrate solid expertise, superior performance, and deliver value beyond expectations, earning high regard from clients and teammates. With a readiness to take on every mission the organization entrusts to them, they inspire, drive motivation, and create positive influence across the whole team.',
    'Giải thưởng Top Talent vinh danh những cá nhân xuất sắc toàn diện – những người không ngừng khẳng định năng lực chuyên môn vững vàng, hiệu suất công việc vượt trội, luôn mang lại giá trị vượt kỳ vọng, được đánh giá cao bởi khách hàng và đồng đội. Với tinh thần sẵn sàng nhận mọi nhiệm vụ tổ chức giao phó, họ luôn là nguồn cảm hứng, thúc đẩy động lực và tạo ảnh hưởng tích cực đến cả tập thể.',
    1
  ),
  (
    'top_project',
    'Top Project',
    'Top Project',
    'The Top Project award honors outstanding project teams with business results beyond expectations, optimal operational efficiency, and a dedicated working spirit. These projects feature high technical complexity, strong resource and cost optimization, valuable ideas proposed to clients, exceptional profitability, and positive client feedback. Members strictly adhere to internal development standards, setting a model of excellence and professionalism.',
    'Giải thưởng Top Project vinh danh các tập thể dự án xuất sắc với kết quả kinh doanh vượt kỳ vọng, hiệu quả vận hành tối ưu và tinh thần làm việc tận tâm. Đây là các dự án có độ phức tạp kỹ thuật cao, hiệu quả tối ưu hóa nguồn lực và chi phí tốt, đề xuất các ý tưởng có giá trị cho khách hàng, đem lại lợi nhuận vượt trội và nhận được phản hồi tích cực từ khách hàng. Các thành viên tuân thủ nghiêm ngặt các tiêu chuẩn phát triển nội bộ trong phát triển dự án, tạo nên một hình mẫu về sự xuất sắc và chuyên nghiệp.',
    2
  ),
  (
    'top_project_leader',
    'Top Project Leader',
    'Top Project Leader',
    'The Top Project Leader award honors outstanding project managers — those who combine strong management capability, the power to inspire, and an "Aim High – Be Agile" mindset across every problem and context. Under their leadership, team members not only overcome challenges and reach goals together but also keep the fire of enthusiasm alive, hold the Wasshoi spirit, and grow into a finer, happier version of themselves.',
    'Giải thưởng Top Project Leader vinh danh những nhà quản lý dự án xuất sắc – những người hội tụ năng lực quản lý vững vàng, khả năng truyền cảm hứng mạnh mẽ, và tư duy "Aim High – Be Agile" trong mọi bài toán và bối cảnh. Dưới sự dẫn dắt của họ, các thành viên không chỉ cùng nhau vượt qua thử thách và đạt được mục tiêu đề ra, mà còn giữ vững ngọn lửa nhiệt huyết, tinh thần Wasshoi, và trưởng thành để trở thành phiên bản tinh hoa – hạnh phúc hơn của chính mình.',
    3
  ),
  (
    'best_manager',
    'Best Manager',
    'Best Manager',
    'The Best Manager award honors exemplary leaders — those who guide their teams to results beyond expectations and create standout impact on business performance and the organization''s sustainable growth. Under their leadership, the team conquers and masters every objective through multi-tasking, effective collaboration, and a flexible technology-driven mindset for the digital era. They inspire the collective to become confident and energized, ready to embrace — and even drive — revolutionary change.',
    'Giải thưởng Best Manager vinh danh những nhà lãnh đạo tiêu biểu – người đã dẫn dắt đội ngũ của mình tạo ra kết quả vượt kỳ vọng, tác động nổi bật đến hiệu quả kinh doanh và sự phát triển bền vững của tổ chức. Dưới sự lãnh đạo của họ, đội ngũ luôn chinh phục và làm chủ mọi mục tiêu bằng năng lực đa nhiệm, khả năng phối hợp hiệu quả, và tư duy ứng dụng công nghệ linh hoạt trong kỷ nguyên số. Họ truyền cảm hứng để tập thể trở nên tự tin tràn đầy năng lượng, sẵn sàng đón nhận, thậm chí dẫn dắt tạo ra những thay đổi có tính cách mạng.',
    4
  ),
  (
    'signature_2026_creator',
    'Signature 2026 - Creator',
    'Signature 2026 - Creator',
    'The Signature award honors individuals or teams embodying the distinctive spirit Sun* pursues in each era. In 2025, the Signature award honors the Creator — individuals/teams carrying a proactive and perceptive mindset, always seeing opportunity in challenge and leading from the front. They sense issues early, identify and provide pragmatic solutions, and deliver clear value to projects, clients, or the organization. With a generative mindset and the distinctive Sun* "Creator" spirit, they not only respond positively to change but actively create improvements, helping shape new standards for how Sun* people create value.',
    'Giải thưởng Signature vinh danh cá nhân hoặc tập thể thể hiện tinh thần đặc trưng mà Sun* hướng tới trong từng thời kỳ. Trong năm 2025, giải thưởng Signature vinh danh Creator - cá nhân/tập thể mang tư duy chủ động và nhạy bén, luôn nhìn thấy cơ hội trong thách thức và tiên phong trong hành động. Họ là những người nhạy bén với vấn đề, nhanh chóng nhận diện và đưa ra những giải pháp thực tiễn, mang lại giá trị rõ rệt cho dự án, khách hàng hoặc tổ chức. Với tư duy kiến tạo và tinh thần "Creator" đặc trưng của Sun*, họ không chỉ phản ứng tích cực trước sự thay đổi mà còn chủ động tạo ra cải tiến, góp phần định hình chuẩn mực mới cho cách mà người Sun* tạo giá trị.',
    5
  ),
  (
    'mvp',
    'MVP (Most Valuable Person)',
    'MVP (Most Valuable Person)',
    'The MVP award honors the most outstanding individual of the year — the standout face representing the entire Sun* collective. They have shown superior capability, persistent dedication, and far-reaching influence, leaving a strong imprint on Sun*''s journey through the year. Not only standing out for performance and results, they are also an inspiration that spreads — through their thinking, action, and positive influence on the team. The MVP embodies all the qualities of an excellent Sun* person while bearing the great responsibility of becoming a model representing Sun*''s people and spirit, helping lead the team to new heights.',
    'Giải thưởng MVP vinh danh cá nhân xuất sắc nhất năm – gương mặt tiêu biểu đại diện cho toàn bộ tập thể Sun*. Họ là người đã thể hiện năng lực vượt trội, tinh thần cống hiến bền bỉ, và tầm ảnh hưởng sâu rộng, để lại dấu ấn mạnh mẽ trong hành trình của Sun* suốt năm qua. Không chỉ nổi bật bởi hiệu suất và kết quả công việc, họ còn là nguồn cảm hứng lan tỏa – thông qua suy nghĩ, hành động và ảnh hưởng tích cực của mình đối với tập thể. MVP là người hội tụ đầy đủ phẩm chất của người Sun* ưu tú, đồng thời mang trên mình trọng trách lớn lao: trở thành hình mẫu đại diện cho con người và tinh thần Sun*, góp phần dẫn dắt tập thể vươn tới những đỉnh cao mới.',
    6
  )
on conflict (code) do update set
  name_en        = excluded.name_en,
  name_vi        = excluded.name_vi,
  description_en = excluded.description_en,
  description_vi = excluded.description_vi,
  sort_order     = excluded.sort_order;
