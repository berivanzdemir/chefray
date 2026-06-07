import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// KVKK / Privacy Policy modal.
///
/// Shows a scrollable full-text popup with proper Turkish KVKK content.
/// Use [KvkkModal.show] to open it.
class KvkkModal extends StatelessWidget {
  final String title;
  final String content;

  const KvkkModal._({required this.title, required this.content});

  // ── Factory constructors ─────────────────────────────────────────────────

  static Future<void> showKvkk(BuildContext context) {
    return _show(context, title: 'KVKK Aydınlatma Metni', content: _kvkkText);
  }

  static Future<void> showPrivacy(BuildContext context) {
    return _show(context, title: 'Gizlilik Politikası', content: _privacyText);
  }

  static Future<void> _show(BuildContext context,
      {required String title, required String content}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KvkkModal._(title: title, content: content),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Handle ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: AppColors.divider, height: 20),
              ),

              // ── Scrollable content ─────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  children: _parseContent(content),
                ),
              ),

              // ── Footer CTA ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 8, 24, 16 + MediaQuery.paddingOf(context).bottom),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Anladım, Kapat',
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.textDark)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Parses simple markdown-like sections:
  /// Lines starting with "## " become bold headings.
  List<Widget> _parseContent(String text) {
    final widgets = <Widget>[];
    for (final line in text.split('\n')) {
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(
              line.substring(3),
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.65,
                color: AppColors.textMedium,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

// ── Static text content ───────────────────────────────────────────────────────

const _kvkkText = '''
## Veri Sorumlusu

ChefRay, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında veri sorumlusu sıfatıyla hareket etmektedir. Bu metin, kullanıcılarımızın kişisel verilerinin nasıl toplandığı, işlendiği ve korunduğuna ilişkin bilgilendirme amacıyla hazırlanmıştır.

## Toplanan Kişisel Veriler

Ad-soyad, e-posta adresi ve şifre bilgileriniz hesap oluşturma amacıyla toplanmaktadır. Uygulamayı kullandığınızda yüklediğiniz kan testi sonuçları ve besin tercihleri, yalnızca size özel tarif önerileri oluşturmak için işlenmektedir.

## Veri İşleme Amaçları

• Kimlik doğrulama ve hesap yönetimi
• Yapay zeka destekli kişiselleştirilmiş tarif önerisi üretimi
• Kan değerlerinize göre beslenme analizi
• Uygulama performansının iyileştirilmesi
• Yasal yükümlülüklerin yerine getirilmesi

## Veri Güvenliği

Kişisel verileriniz endüstri standardı şifreleme (TLS/AES-256) ile korunmaktadır. Kan testi sonuçlarınız cihazınızda işlenir; sunucularımıza yalnızca anonim analiz verileri iletilir. Verileriniz asla üçüncü taraflarla paylaşılmaz veya satılmaz.

## Saklama Süresi

Kişisel verileriniz hesabınız aktif olduğu süre boyunca saklanır. Hesabınızı sildiğinizde tüm kişisel verileriniz 30 gün içinde kalıcı olarak silinir.

## Haklarınız

KVKK'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:

• Verilerinizin işlenip işlenmediğini öğrenme
• İşlenen verileriniz hakkında bilgi talep etme
• İşleme amacını ve amaca uygunluğunu öğrenme
• Eksik veya yanlış verilerin düzeltilmesini isteme
• Kişisel verilerinizin silinmesini veya yok edilmesini isteme
• Otomatik sistemler aracılığıyla aleyhinize bir sonuç ortaya çıkmasına itiraz etme

## İletişim

Veri koruma talepleriniz için bize ulaşabilirsiniz:
E-posta: kvkk@chefray.app
''';

const _privacyText = '''
## Gizlilik Taahhüdümüz

ChefRay olarak kullanıcı gizliliği en temel önceliğimizdir. Bu politika, verilerinizle nasıl davrandığımızı şeffaf biçimde açıklamaktadır. Sağlık verileriniz son derece hassas olduğundan özel koruma önlemleri uygulanmaktadır.

## Ne Topluyoruz?

Hesap bilgileri: Ad, e-posta, şifreli parola özeti.
Sağlık verileri: Uygulamanıza yüklediğiniz kan testi değerleri ve besin tercihleri.
Kullanım verileri: Hangi tariflerin kaydedildiği ve pişirildiğine dair anonim istatistikler.

## Ne Toplamıyoruz?

• Konum bilgisi
• Kamera veya mikrofon erişimi
• Cihaz rehberi
• Sosyal medya profili
• Finansal bilgi

## Çerezler ve Takip

Uygulamamız analitik amaçlı yalnızca birinci taraf oturum çerezleri kullanmaktadır. Üçüncü taraf reklam ağlarına veri aktarımı yapılmamaktadır.

## Yapay Zeka ve Verileriniz

Tarif önerisi oluşturmak için kullandığımız yapay zeka modeli, kan değerlerinizi yalnızca anlık işlem süresinde kullanır ve bunları kalıcı olarak saklamaz. Model eğitiminde kullanıcı sağlık verileri kullanılmaz.

## Üçüncü Taraf Paylaşımı

Verileriniz hiçbir koşulda:
• Reklam şirketlerine
• Veri aracılarına
• Sigorta şirketlerine
• Diğer üçüncü taraflara satılmaz veya kiralanmaz.

## Değişiklikler

Bu politikada yapılacak önemli değişiklikler uygulama içi bildirim ile duyurulacaktır. Güncel sürüme her zaman chefray.app/gizlilik adresinden ulaşabilirsiniz.

## İletişim

Gizlilik sorularınız için: gizlilik@chefray.app
''';
