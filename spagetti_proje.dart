enum UrunTipi {
  fiziksel,
  dijital,
}

class Urun {
  final String id;
  final String ad;
  final double fiyat;
  int stok;
  final UrunTipi tip;

  Urun({
    required this.id,
    required this.ad,
    required this.fiyat,
    required this.stok,
    required this.tip,
  });

  bool get stoktaVar => stok > 0;

  void stokAzalt() {
    if (!stoktaVar) {
      throw Exception('$ad stokta bulunmuyor.');
    }

    stok--;
  }
}

// --------------------
// Repository
// --------------------

abstract class SiparisRepository {
  void kaydet(String siparisId, double tutar);
}

class SqliteSiparisRepository implements SiparisRepository {
  @override
  void kaydet(String siparisId, double tutar) {
    print(
      "DB çalıştırıldı: "
      "INSERT INTO siparisler VALUES ('$siparisId', $tutar)",
    );
  }
}

// --------------------
// Ödeme
// --------------------

abstract class OdemeYontemi {
  void ode(double tutar);
}

class KrediKartiOdeme implements OdemeYontemi {
  @override
  void ode(double tutar) {
    print('$tutar TL kredi kartından POS ile çekildi.');
  }
}

class HavaleOdeme implements OdemeYontemi {
  @override
  void ode(double tutar) {
    print('$tutar TL havale kontrol edildi.');
  }
}

class KapidaOdeme implements OdemeYontemi {
  @override
  void ode(double tutar) {
    print('$tutar TL kapıda tahsil edilecek.');
  }
}

class CryptoOdeme implements OdemeYontemi {
  @override
  void ode(double tutar) {
    print('$tutar TL USDT transferi onaylandı.');
  }
}

// --------------------
// Bildirim Servisleri
// --------------------

abstract class MailServisi {
  void gonder(String alici, String mesaj);
}

class SmtpMailServisi implements MailServisi {
  @override
  void gonder(String alici, String mesaj) {
    print('SMTP Mail gönderildi: $alici');
  }
}

abstract class SmsServisi {
  void gonder(String telefon, String mesaj);
}

class NetgsmSmsServisi implements SmsServisi {
  @override
  void gonder(String telefon, String mesaj) {
    print('SMS iletildi: $telefon');
  }
}

// --------------------
// Fatura
// --------------------

abstract class FaturaServisi {
  void olustur(String siparisId);
}

class PdfFaturaServisi implements FaturaServisi {
  @override
  void olustur(String siparisId) {
    print('Fatura PDF oluşturuldu: $siparisId');
  }
}

// --------------------
// Kargo
// --------------------

abstract class KargoServisi {
  double ucretHesapla(Urun urun);

  void gonder(String siparisId, String adres);
}

class MngKargoServisi implements KargoServisi {
  static const double standartKargoUcreti = 29.90;

  @override
  double ucretHesapla(Urun urun) {
    if (urun.tip == UrunTipi.dijital) {
      return 0;
    }

    return standartKargoUcreti;
  }

  @override
  void gonder(String siparisId, String adres) {
    print('MNG Kargo takip fişi basıldı: $adres');
  }
}

// --------------------
// İndirim
// --------------------

abstract class IndirimServisi {
  double uygula(String kuponKodu, double tutar);
}

class KuponIndirimServisi implements IndirimServisi {
  final Map<String, double Function(double)> kuponlar = {
    'INDIRIM10': (tutar) => tutar * 0.90,
    'YAZ20': (tutar) => tutar * 0.80,
    'SEPETTE50': (tutar) => tutar - 50,
  };

  @override
  double uygula(String kuponKodu, double tutar) {
    final indirim = kuponlar[kuponKodu];

    if (indirim == null) {
      return tutar;
    }

    final indirimliTutar = indirim(tutar);

    return indirimliTutar < 0 ? 0 : indirimliTutar;
  }
}

// --------------------
// Sipariş
// --------------------

class SiparisBilgileri {
  final String siparisId;
  final String musteriAdi;
  final String email;
  final String telefon;
  final String adres;
  final String kuponKodu;

  SiparisBilgileri({
    required this.siparisId,
    required this.musteriAdi,
    required this.email,
    required this.telefon,
    required this.adres,
    required this.kuponKodu,
  });
}

class SiparisServisi {
  static const double kdvOrani = 0.20;

  final SiparisRepository repository;
  final MailServisi mailServisi;
  final SmsServisi smsServisi;
  final FaturaServisi faturaServisi;
  final KargoServisi kargoServisi;
  final IndirimServisi indirimServisi;

  SiparisServisi({
    required this.repository,
    required this.mailServisi,
    required this.smsServisi,
    required this.faturaServisi,
    required this.kargoServisi,
    required this.indirimServisi,
  });

  void siparisTamamla({
    required SiparisBilgileri bilgiler,
    required List<Urun> sepet,
    required OdemeYontemi odemeYontemi,
  }) {
    if (!_stokKontrolEt(sepet)) {
      return;
    }

    final araToplam = _araToplamHesapla(sepet);

    final indirimliTutar = indirimServisi.uygula(
      bilgiler.kuponKodu,
      araToplam,
    );

    final sonTutar = _kdvEkle(indirimliTutar);

    odemeYontemi.ode(sonTutar);

    repository.kaydet(
      bilgiler.siparisId,
      sonTutar,
    );

    _stoklariGuncelle(sepet);

    faturaServisi.olustur(
      bilgiler.siparisId,
    );

    mailServisi.gonder(
      bilgiler.email,
      'Sayın ${bilgiler.musteriAdi}, '
      'siparişiniz alındı. Tutar: $sonTutar TL',
    );

    smsServisi.gonder(
      bilgiler.telefon,
      'Siparişiniz onaylandı: ${bilgiler.siparisId}',
    );

    if (_fizikselUrunVarMi(sepet)) {
      kargoServisi.gonder(
        bilgiler.siparisId,
        bilgiler.adres,
      );
    }
  }

  bool _stokKontrolEt(List<Urun> sepet) {
    for (final urun in sepet) {
      if (!urun.stoktaVar) {
        print('Hata: ${urun.ad} tükenmiş!');
        return false;
      }
    }

    return true;
  }

  double _araToplamHesapla(List<Urun> sepet) {
    double toplam = 0;

    for (final urun in sepet) {
      toplam += urun.fiyat;
      toplam += kargoServisi.ucretHesapla(urun);
    }

    return toplam;
  }

  double _kdvEkle(double tutar) {
    final kdv = tutar * kdvOrani;
    return tutar + kdv;
  }

  void _stoklariGuncelle(List<Urun> sepet) {
    for (final urun in sepet) {
      urun.stokAzalt();
    }
  }

  bool _fizikselUrunVarMi(List<Urun> sepet) {
    return sepet.any(
      (urun) => urun.tip == UrunTipi.fiziksel,
    );
  }
}

// --------------------
// Main
// --------------------

void main() {
  final repository = SqliteSiparisRepository();
  final mailServisi = SmtpMailServisi();
  final smsServisi = NetgsmSmsServisi();
  final faturaServisi = PdfFaturaServisi();
  final kargoServisi = MngKargoServisi();
  final indirimServisi = KuponIndirimServisi();

  final siparisServisi = SiparisServisi(
    repository: repository,
    mailServisi: mailServisi,
    smsServisi: smsServisi,
    faturaServisi: faturaServisi,
    kargoServisi: kargoServisi,
    indirimServisi: indirimServisi,
  );

  final urun1 = Urun(
    id: '1',
    ad: 'Kablosuz Mouse',
    fiyat: 450.0,
    stok: 5,
    tip: UrunTipi.fiziksel,
  );

  final urun2 = Urun(
    id: '2',
    ad: 'Flutter Kursu E-Kitap',
    fiyat: 150.0,
    stok: 100,
    tip: UrunTipi.dijital,
  );

  final sepet = <Urun>[
    urun1,
    urun2,
  ];

  final bilgiler = SiparisBilgileri(
    siparisId: 'SP-9921',
    musteriAdi: 'Selahaddin',
    email: 'selahaddin@kodvance.com',
    telefon: '05551112233',
    adres: 'Kadıköy / İstanbul',
    kuponKodu: 'INDIRIM10',
  );

  siparisServisi.siparisTamamla(
    bilgiler: bilgiler,
    sepet: sepet,
    odemeYontemi: KrediKartiOdeme(),
  );
}
