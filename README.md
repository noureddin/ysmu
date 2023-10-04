# معجم يسمو للمصطلحات التقنية الحديثة

- المصطلحات المتفق عليها مع شرح سبب اختيارها وأمثلة عليها:  
  https://noureddin.github.io/ysmu

- المصطلحات المتفق عليها بغير شرح (للتطبيقات والمعاجم المجمعة):  
  https://github.com/noureddin/ysmu/raw/main/ysmu.tsv

- المصطلحات المرشحة للاتفاق، التي ستصير «متفق عليها» بعد ساعات غالبا:  
  https://noureddin.github.io/ysmu/candidate

- المصطلحات **التجريبية** التي لم يتفق المجتمع عليها بعد:  
  https://noureddin.github.io/ysmu/experimental

- موارد وإرشادات وملاحظات عامة:  
  https://noureddin.github.io/ysmu/notes

- قائمة روابط جميع المصطلحات:  
  https://noureddin.github.io/ysmu/link

## تواصل

عبر [مسائل GitHub](https://github.com/noureddin/ysmu/issues/)
أو غرفة الترجمة في مجتمع أسس على شبكة ماتركس: [‪#localization:aosus.org‬](https://matrix.to/#/#localization:aosus.org)

## الرخصة

[المشاع الإبداعي الصفرية (CC0)](https://creativecommons.org/choose/zero/) (مكافئة للملكية العامة).

## مراحل المصطلحات

- **المصطلحات المتفق عليها:** هي المصطلحات التي وافق عليها أعضاء غرفة الترجمة في مجتمع أسس بعد نقاش و/أو تصويت. ([صفحتها ⬉](https://noureddin.github.io/ysmu/))
- **المصطلحات المرشحة للاتفاق:** هي المصطلحات التي في مرحلة التصويت، أو في آخر مرحلة النقاش. ([صفحتها ⬉](https://noureddin.github.io/ysmu/candidate/))
- **المصطلحات التجريبية:** هي المصطلحات التي لم يتفق عليها المجتمع بعد، وقد يكون نقاشها في بدايته أو لم يبدأ بعد أصلا. ([صفحتها ⬉](https://noureddin.github.io/ysmu/experimental/))
- **المصطلحات المؤجلة:** هي المصطلحات التي لن يبدأ النقاش فيها قريبا ونريد إبعادها قليلا للتركيز على المصطلحات الأخرى. ([صفحتها ⬉](https://noureddin.github.io/ysmu/unstaged/))

وكل مجموعة من هذا المصطلحات تظهر في صفحة خاصة بها، والمصطلحات المتفق عليها فقط هي التي تصل إلى [ملف المعجم المختصر](https://github.com/noureddin/ysmu/raw/main/ysmu.tsv).

## تنظيم المستودع

يُقسم هذا المستودع إلى أربعة أقسام منطقية:

### البيانات:

- مجلد `w`: فيه المصطلحات المتفق عليها.
- مجلد `c`: فيه المصطلحات المرشحة للاتفاق.
- مجلد `x`: فيه المصطلحات التجريبية.
- مجلد `u`: فيه المصطلحات المؤجلة.
- ملف `notes/src`: فيه إرشادات وموارد وملاحظات عامة قد تهم من يهتم بمثل هذا المشروع.
- ملف `longnames.tsv`: يحتوي كل سطر منه على خانتين مفصولتين بمسافة جدولة، الأولى فيها اختصارات المصطلحات المستخدمة في المعجم (انظر فصل «الاختصارات» أدناه)، والأخرى هي الاسم الطويل.

### المعالجة:

- مجلد `p`: فيه بُريمج التحويل والمكتبات المساعدة، وهو يحوّل ملفات البيانات إلى صفحات الويب والمعجم المختصر.
- ملف `Makefile`: ليُرشد برنامج `make` لإعداد الملفات عند أي تغيير في البيانات.

### النواتج:

- ملف `index.html`: صفحة ويب المصطلحات المتفق عليها. [اذهب إليها ⬉](https://noureddin.github.io/ysmu/)
- ملف `candidate/index.html`: صفحة ويب المصطلحات المرشحة للاتفاق. [اذهب إليها ⬉](https://noureddin.github.io/ysmu/candidate/)
- ملف `experimental/index.html`: صفحة ويب المصطلحات التجريبية. [اذهب إليها ⬉](https://noureddin.github.io/ysmu/experimental/)
- ملف `notes/index.html`:  هي ناتج تصيير `notes/src`، أي صفحة ويب الموارد والإرشادات. [اذهب إليها ⬉](https://noureddin.github.io/ysmu/notes/)
- ملف `ysmu.tsv`: المصطلحات المتفق عليها بغير شرح وبصيغة مناسبة للتطبيقات. [اذهب إليه ⬉](https://github.com/noureddin/ysmu/raw/main/ysmu.tsv)
- ملف `link/index.html`: قائمة روابط جميع المصطلحات. [اذهب إليها ⬉](https://noureddin.github.io/ysmu/link/)
- ملفات `link/*/index.html`: صفحات توجيه إلى المصطلح بغض النظر عن مرحلته الحالية (`*` هي اسم المصطلح الإنجليزي).

### السواكن:

- ملف `MARK.md`: وصف إنساني للغة تنسيق المدخلات المستعملة في هذا المشروع.
- ملف `style.css`: ضبط شكل صفحات الويب.
- ملف `LICENSE`: نص رخصة المشاع الإبداعي الصفرية باللغة الإنجليزية.
- ملف `README.md`: هذا الملف.

## صيغ الملفات

تحتوي مجلدات المصطلحات (مثل مجلد `w`) على ملف لكل مصطلح إنجليزي، بحروف صغيرة، وبشرطة سفلية (`_`) بدلا من المسافة إن وجدت.

يتكون ملف كل مصطلح من نص عادي، فقرته الأولى هي الترجمة المختصرة التي تعرضها المعاجم، وهي التى تذهب إلى «ملف المعجم المختصر».

وتُتبع الفقرة الأولى بفقرات تشرح سبب اختيار هذا المصطلح أو توضح أمثلة على استخدام أو ما يناسب عموما.

وقد يُنهى ملف المصطلح بقائمة «انظر أيضا» للإشارة إلى مصطلحات (إنجليزية) أخرى في المعجم.

وتستخدم ملفات المصطلحات لغةً تنسيقية خفيفة مشروحة في ملف `MARK.md`.

ويستخدم ملف الإرشادات `notes/src` نسخة موسعة من نفس اللغة التنسيقية، وهي مشروحة في ملف `MARK.md` أيضا.

## الاختصارات

لا نستخدم الاختصارات، مثل اختصار repository إلى repo.

ولكن الاختصارات الشائعة للعبارات الطويلة مثل VPN اختصار virtual private network نستخدمها.

كيف «نستخدم» الاختصارات؟

- تستخدم اسمًا للملف (في مجلدات المصطلحات مثل `w`) **بدلا من** الاسم الطويل
- تستخدم في الروابط الداخلية (داخل مرحلة المعجم الواحدة) والروابط الثابتة (روابط `/link/`) **إضافةً إلى** الاسم الطويل
- تذكر في العنوان وأسماء الروابط بعد الاسم الطويل

