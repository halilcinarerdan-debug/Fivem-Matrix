--[[
    ox_inventory ITEM KAYIT REFERANSI — vbs_core_matrix
    =====================================================================
    Bu dosya vbs_core_matrix tarafından OKUNMAZ / ÇALIŞTIRILMAZ.
    ox_inventory kendi item kataloğunu SADECE kendi resource'u içindeki
    data/items.lua (veya yeni sürümlerde data/items/*.lua) dosyasından
    okur; üçüncü parti bir resource'un (vbs_core_matrix gibi) runtime'da
    ox_inventory'ye yeni item enjekte etmesi için desteklenen bir yol
    yoktur. Bu yüzden aşağıdaki tüm item'lar, sunucu operatörü tarafından
    ox_inventory resource'unun kendi data/items.lua dosyasına ELLE
    eklenmelidir; aksi halde vbs_core_matrix'in bu item'ları hedefleyen
    AddItem/RemoveItem/Search/GetSlot çağrıları başarısız olur veya
    sessizce hiçbir şey yapmaz.

    Kullanım: Aşağıdaki blokları kopyalayıp ox_inventory/data/items.lua
    dosyasındaki `return { ... }` tablosunun içine yapıştırın.
    Weight/stack/close değerleri makul varsayılanlardır; sunucunuzun
    ekonomi dengesine göre serbestçe değiştirebilirsiniz.
--]]

return {
    -- KATMAN 1-3: Karaborsa / silah parçaları
    ['weapon_spare_barrel'] = {
        label = 'Yedek Namlu', weight = 900, stack = true, close = true,
        description = 'Silah söküm/montaj tezgahında namlu değişimi için kullanılır.'
    },
    ['burner_phone'] = {
        label = 'Yakılabilir Telefon (Sahte IMEI)', weight = 150, stack = true, close = true,
        description = 'İzlenemez iletişim için kullanılan tek kullanımlık hat.'
    },

    -- KATMAN 7: Silah söküm/montaj sarf malzemeleri
    ['yiv_set_raybasi'] = {
        label = 'Yiv-Set Raybası', weight = 400, stack = true, close = true,
    },
    ['namlu_celik_tiraslama'] = {
        label = 'Namlu Çeliği Tıraşlama Sıvısı', weight = 300, stack = true, close = true,
    },
    ['mekanik_igne_yayi'] = {
        label = 'Mekanik İğne Yayı', weight = 100, stack = true, close = true,
    },

    -- Üretim zinciri
    ['meth_raw_batch'] = {
        label = 'Ham Metamfetamin Partisi', weight = 1000, stack = true, close = true,
    },
    ['meth_bag'] = {
        label = 'Metamfetamin Torbası', weight = 250, stack = true, close = true,
    },
    ['coke_brick'] = {
        label = 'Kokain Kalıbı', weight = 1000, stack = true, close = true,
    },
    ['cutting_agent'] = {
        label = 'Seyreltme Maddesi', weight = 200, stack = true, close = true,
    },

    -- KATMAN 3/7/9: Adli tıp / balistik
    ['shell_casing_evidence'] = {
        label = 'Kovan (Adli Delil)', weight = 20, stack = true, close = true,
    },

    -- KATMAN 5/7/10: Cihaz imhası / veri kurtarma
    ['partially_destroyed_device'] = {
        label = 'Kısmen Tahrip Edilmiş Cihaz', weight = 200, stack = false, close = true,
        description = '24 saatlik adli veri kurtarma sürecine tabi müsadere edilmiş cihaz.'
    },
    ['chemical_acid_bottle'] = {
        label = 'Sülfürik Asit Şişesi', weight = 500, stack = true, close = true,
        description = 'Kovan/kasa asit banyosu ve kanıt sabotajı için kullanılır.'
    },

    -- KATMAN 5: Fiziki kapı zırhlama
    ['door_lock_heavy'] = {
        label = 'Ağır Kapı Kilidi', weight = 3000, stack = true, close = true,
    },

    -- KATMAN 6: HUMINT / rüşvet
    ['valuable_watch'] = {
        label = 'Değerli Saat', weight = 200, stack = true, close = true,
        description = 'Rüşvet teklifi için kullanılabilecek değerli eşya.'
    },
    ['interrogation_report'] = {
        label = 'Sorgu Tutanağı Evrağı', weight = 10, stack = true, close = true,
        description = 'Rüşvet alan memurdan elde edilen fiziksel istihbarat evrağı.'
    },

    -- Diagnostics (isteğe bağlı — sadece /matrixdiag deep=true testleri için)
    ['matrix_diagnostic_token'] = {
        label = '[DIAGNOSTICS] Test Token', weight = 0, stack = true, close = true,
        description = 'Sadece stres testleri sırasında kullanılır; satılamaz/görünmez yapılabilir.'
    },

    --[[
        Standart ox_inventory silah/mühimmat item'ları (weapon_assaultrifle,
        weapon_combatpistol, ammo_rifle, ammo_pistol) ox_inventory ile birlikte
        zaten gelir — bunları ayrıca eklemenize gerek yoktur.
    --]]
}
