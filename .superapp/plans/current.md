---
title: Supabase ve GitHub Hedeflerini Düzelt
status: approved
updatedAt: 2026-09-08T20:15:38.867Z
approvedAt: 2026-09-08T20:15:38.867Z
proposal:
  messageId: chm_01m21ag4smfq88h717sa7zc0g2
  toolCallId: call_MqsPxbIe8Wj900mAdXli9cVg
---
Phase 5 altyapısı yanlış Superapp Cloud projesinden kullanıcının Supabase projesine taşınacak ve mevcut commit geçmişi kullanıcının GitHub reposuna gönderilecek.

**Onaylanan hedefler**
- Supabase proje ref: `amshmuuxomoquggqepik`
- Supabase Dashboard: `https://supabase.com/dashboard/project/amshmuuxomoquggqepik`
- GitHub repo: `https://github.com/STAAU/colorly`
- Mevcut uygulama ve Coloring Engine korunacak; proje yeniden kurulmayacak.
- Yanlış kullanılan Supabase ref’i `mqpwhaxmeamlgydhkdnc` artık uygulama veya üretim backend hedefi olmayacak.

**Varsayım / erişim gereksinimi**
- Hedef Supabase projesi Superapp çalışma alanına yetkili şekilde bağlanmalıdır. Sadece Dashboard URL’si; migration, Edge Function ve secret deploy etmek için yeterli kimlik doğrulama sağlamaz.
- GitHub reposuna push için bağlı GitHub hesabının `STAAU/colorly` yazma yetkisi olmalıdır.

## Now

### Sonuç
Uygulama yalnızca `amshmuuxomoquggqepik` Supabase projesini kullanır; Phase 5 veritabanı, limit otoritesi ve webhook bu projede çalışır; doğrulanan kaynak kodu ve commit geçmişi `STAAU/colorly` reposuna gönderilir.

### Uygulama adımları
1. **Hedef Supabase bağlantısını doğrula**
   - Superapp Cloud yerine `amshmuuxomoquggqepik` projesine yetkili bağlantı kur.
   - Hedef proje URL’sini ve publishable key’i doğrudan Supabase’den doğrula; secret/service-role değerlerini uygulama kaynaklarına yazma.

2. **Phase 5 şemasını hedef projeye taşı**
   - `subscription_plan_limits`, `user_entitlements`, `generation_usage` ve webhook idempotency tablolarını aynı migration sözleşmesiyle oluştur.
   - Free günlük ve Premium aylık limitleri tek backend tablosunda tut.
   - RLS, servis rolü izinleri, advisory transaction lock ve server-time dönem hesaplarını yeniden uygula.

3. **Edge Function’ları hedef projeye deploy et**
   - JWT doğrulamalı `generation-access` fonksiyonunu deploy et.
   - Secret ile korunan ve tekrar gönderilen olaylara dayanıklı `revenuecat-webhook` fonksiyonunu deploy et.
   - `REVENUECAT_WEBHOOK_AUTHORIZATION` değerini yalnızca hedef Supabase Secrets içinde sakla.

4. **iOS bağlantısını düzelt**
   - `NativeKidsColoringEnginePrototype/Services/SubscriptionManager.swift` içindeki eski Supabase URL/key yapılandırmasını hedef projenin doğrulanmış public değerleriyle değiştir.
   - `GenerationAccessService` ve anonim Supabase kimliğinin aynı hedef client/session üzerinden çalıştığını doğrula.
   - RevenueCat müşteri kimliğini bu hedef Supabase kullanıcısının kararlı UUID’siyle eşleştirmeye devam et.

5. **Yanlış proje bağımlılığını kaldır**
   - Kaynak kodunda `mqpwhaxmeamlgydhkdnc` referansı kalmadığını ara.
   - Yanlış projedeki verileri otomatik silme; silme ayrı ve geri döndürülemez bir karar olarak tutulacak.

6. **GitHub hedefini düzelt ve gönder**
   - Mevcut Superapp storage remote’u yerine `https://github.com/STAAU/colorly.git` hedefini doğrula/ayarla.
   - Phase 5 commitleri dahil mevcut dalı push et; geçmişi force-push ile yeniden yazma.
   - Push sonrası remote dal SHA’sının yerel HEAD ile aynı olduğunu doğrula.

### Doğrulama
- Hedef Supabase’de tabloları, RLS politikalarını, fonksiyon izinlerini ve Edge Function durumlarını kontrol et.
- Yanlış webhook authorization ile `401`, kimliksiz generation isteğiyle `401`, geçerli anonim kullanıcıyla server-owned limit sonucu alındığını doğrula.
- Supabase security advisor’da çözülmemiş kritik/yüksek bulgu olmadığını doğrula.
- iPhone hedefini yeniden build et.
- `Engine/` ve `Canvas/` altında değişiklik olmadığını doğrula.
- Kaynakta eski Supabase ref’i kalmadığını doğrula.
- GitHub `STAAU/colorly` remote HEAD’inin yerel commit ile eşleştiğini doğrula.

### Riskler
- Hedef Supabase yetkilendirmesi bağlanmadan migration ve Edge Function deploy edilemez.
- Hedef projede aynı isimli mevcut tablolar/fonksiyonlar varsa önce uyumluluk kontrolü gerekir; veri kaybına yol açan `drop` işlemleri uygulanmaz.
- GitHub repo mevcut ve farklı bir geçmişe sahipse force-push yapılmaz; geçmişler güvenli biçimde birleştirilmeden gönderim durdurulur.

## Next

1. **RevenueCat webhook hedefini güncelle** — RevenueCat Dashboard’daki webhook URL’sini yeni `amshmuuxomoquggqepik` Edge Function adresine ve aynı authorization değerine bağla.
2. **App Store Connect abonelik kayıtlarını tamamla** — Monthly/Yearly ürünleri ve RevenueCat App Store credentials olmadan gerçek sandbox satın alma testi tamamlanamaz.
3. **Fiziksel cihaz kabul testi** — satın alma, restore, entitlement relaunch, limit, expiration ve offline davranışlarını gerçek iPhone’da doğrula.

## Later

- Yanlış Superapp Cloud projesini veya içindeki Phase 5 tablolarını silmek; açık onay olmadan yapılmayacak.
- Reklam, coin, lifetime purchase, community veya başka monetizasyon modelleri.
- Coloring Engine değişiklikleri.
- Otomatik testler bu düzeltme kapsamında değildir.
