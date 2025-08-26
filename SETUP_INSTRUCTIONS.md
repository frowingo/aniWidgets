# Xcode Konfigürasyon Talimatları

## 1. SharedKit Swift Package'ı Ekleme

1. Xcode'da projeyi açın
2. Project Navigator'da projeyi seçin
3. Project Editor'da "Package Dependencies" sekmesine gidin
4. "+" butonuna tıklayın
5. "Add Local..." seçeneğini seçin
6. SharedKit klasörünü seçin (/Users/frowing/Projects/aniWidgets/aniWidgets/SharedKit)
7. "Add Package" butonuna tıklayın

## 2. Target Dependencies Ayarlama

### aniWidgets (Ana Uygulama) Target:
1. Project Editor'da "aniWidgets" target'ını seçin
2. "Frameworks, Libraries, and Embedded Content" bölümüne gidin
3. "+" butonuna tıklayın
4. "SharedKit" paketini seçin ve "Add" deyin

### MiniWidgets (Widget Extension) Target:
1. Project Editor'da "MiniWidgets" target'ını seçin
2. "Frameworks, Libraries, and Embedded Content" bölümüne gidin
3. "+" butonuna tıklayın
4. "SharedKit" paketini seçin ve "Add" deyin

## 3. App Groups Aktivasyonu

### Ana Uygulama için:
1. Project Editor'da "aniWidgets" target'ını seçin
2. "Signing & Capabilities" sekmesine gidin
3. "+" butonuna tıklayın
4. "App Groups" capability'sini ekleyin
5. "group.Iworf.aniWidgets" App Group ID'sini ekleyin

### Widget Extension için:
1. Project Editor'da "MiniWidgets" target'ını seçin
2. "Signing & Capabilities" sekmesine gidin
3. "+" butonuna tıklayın
4. "App Groups" capability'sini ekleyin
5. "group.Iworf.aniWidgets" App Group ID'sini ekleyin (aynı ID!)

## 4. TestDesigns Bundle Resources

### MiniWidgets target için:
1. Project Navigator'da "MiniWidgets" target'ını seçin
2. Project Editor'da "Build Phases" sekmesine gidin
3. "Copy Bundle Resources" bölümünü açın
4. "+" butonuna tıklayın
5. "Add Other..." > "Add Files..." seçin
6. TestDesigns klasörünü seçin
7. "Create folder references" seçeneğini işaretleyin
8. "Add" butonuna tıklayın

## 5. Import Statements Kontrolü

Eğer SharedKit import'unda hata alırsanız:
1. Product > Clean Build Folder yapın
2. Xcode'u kapatıp açın
3. SharedKit paketini kaldırıp tekrar ekleyin

## 6. Test Etme

1. Projeyi derleyin (Cmd+B)
2. iOS Simulator'da çalıştırın
3. Ana uygulamada "Güncelle" butonuna basın
4. Widget'ı Home Screen'e ekleyin
5. Widget'ın güncellenmesini gözlemleyin

## Beklenen Log Çıktıları

Console'da aşağıdaki logları görmeli siniz:
- "Successfully loaded JSON file: current_widget_data.json"
- "Timeline requested for slot X"
- "Loaded current widget design from App Group: designId"

## App Group Container Yolu

Debug için App Group container yolunu görmek için SettingsView'da "View App Group Container" butonuna basın.
Yol console'da yazdırılacak.

## Sorun Giderme

1. **SharedKit import hatası**: Package dependency'yi kontrol edin
2. **App Group hatası**: Capability'leri ve aynı ID'yi kontrol edin
3. **TestDesigns bulunamıyor**: Bundle Resources'ı kontrol edin
4. **Widget güncellenmiyor**: Timeline reload fonksiyonunu kontrol edin
