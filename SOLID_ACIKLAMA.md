## SOLID İhlalleri

### 1. SRP – Single Responsibility Principle İhlali

`SiparisYoneticisi` sınıfı çok fazla sorumluluk üstlenmektedir. Bu sınıf siparişi kaydetmenin yanında ödeme işlemi yapmakta, e-posta ve SMS göndermekte, fatura oluşturmakta ve kargo işlemlerini de gerçekleştirmektedir.

Bu durum Single Responsibility Principle ilkesine aykırıdır. Bir sınıfın değişmesi için tek bir nedeni olması gerekir. Refactoring sonrasında bu işlemler ayrı servis ve sınıflara bölünmüştür.

### 2. OCP – Open/Closed Principle İhlali

Orijinal projede ödeme yöntemleri `odemeYap()` metodu içerisinde `if/else` bloklarıyla kontrol edilmektedir.

Yeni bir ödeme yöntemi eklemek istediğimizde mevcut `SiparisYoneticisi` sınıfını değiştirmemiz gerekmektedir. Aynı problem indirim kuponlarında da bulunmaktadır.

Refactoring işleminde ödeme yöntemleri ayrı sınıflara taşınmış ve `OdemeYontemi` soyutlaması oluşturulmuştur. Böylece yeni ödeme yöntemleri mevcut kod değiştirilmeden eklenebilir.

### 3. LSP – Liskov Substitution Principle İhlali

`DijitalUrun`, `Urun` sınıfından kalıtım almaktadır. Ancak üst sınıftaki `kargoUcretiHesapla()` metodunu kullanmak yerine exception fırlatmaktadır.

Bu nedenle `Urun` beklenen bir yerde `DijitalUrun` kullanıldığında programın davranışı bozulabilir.

Refactoring sonrasında kargo hesaplama sorumluluğu ürün sınıflarından çıkarılarak ayrı bir `KargoUcretiHesaplayici` servisine verilmiştir. Dijital ürünlerin kargo ücreti 0 TL olarak ele alınmıştır.

### 4. ISP – Interface Segregation Principle İhlali

`ISiparisIslemleri` arayüzü sipariş kaydetme, ödeme, kargo, mail, SMS ve fatura gibi birbirinden farklı birçok metodu tek bir interface içerisinde toplamaktadır.

Bu interface'i uygulayan bir sınıf ihtiyacı olmayan metotları da implement etmek zorunda kalabilir.

Refactoring sonrasında veritabanı, ödeme, mail, SMS, fatura ve kargo işlemleri farklı arayüzlere ayrılmıştır.

### 5. DIP – Dependency Inversion Principle İhlali

Orijinal `SiparisYoneticisi` sınıfı `SqliteVeritabani`, `SmtpMailServisi` ve `NetgsmSmsServisi` sınıflarını doğrudan oluşturmaktadır.

Bu nedenle sınıf doğrudan somut implementasyonlara bağımlıdır.

Refactoring sonrasında bağımlılıklar constructor üzerinden interface olarak alınmaktadır. Böylece farklı servislerin kullanılması ve kodun test edilmesi kolaylaşmıştır.

## Clean Code Düzenlemeleri

Refactoring sırasında sınıfların sorumlulukları ayrıldı, anlamlı değişken ve sınıf isimleri kullanıldı, uzun metotların görevleri farklı sınıflara bölündü, magic string kullanımını azaltmak amacıyla enum kullanıldı ve bağımlılıklar constructor injection ile dışarıdan alınabilir hale getirildi.

Sonuç olarak kod daha okunabilir, genişletilebilir, test edilebilir ve bakım yapılabilir bir yapıya dönüştürüldü.
