-- =====================================================================
-- MATRIX MASTER MANIFESTO / server/layer_directives.lua
-- KATMAN 1-10 (bkz. shared/config.lua "MASTER MANIFESTO" bloğu).
--
-- Bu dosya paylaşımlı Matrix.* ad alanına EKLER; mevcut hiçbir dosyanın
-- formülü/tablosu/event'i DEĞİŞTİRİLMEZ. Yükleme sırası (fxmanifest.lua):
-- forensics/bureau/blackmarket/underworld_network/gang_hoods/workbench
-- ZATEN yüklü olduğu İÇİN listede ONLARDAN SONRA, matrix_diagnostics.lua'dan
-- ÖNCE yer alır (Matrix.Bureau/Matrix.Forensics/Matrix.BlackMarket/
-- Matrix.FragmentedIntel/Matrix.VendorPool fonksiyonlarını doğrudan çağırır).
--
-- ★ TEK KASITLI İSTİSNA: /namludegistir komutu bu dosyada TEKRAR
-- RegisterCommand edilir (server/forensics.lua'nın TANIMI DEĞİŞTİRİLMEDİ,
-- yalnızca çalışma zamanında SONRAKİ kayıt önceki komutu gölgeler) —
-- KATMAN 7'nin "60 saniyelik rijit tezgah kilidi" gereği; forensics.lua'nın
-- kendisi hâlâ Matrix.Forensics.WipeBallisticRecord'u (DEĞİŞMEDİ) sağlar.
-- =====================================================================


Matrix.LayerDirectives = Matrix.LayerDirectives or {}
Matrix.CellIsolation    = Matrix.CellIsolation or {}


local pairs, ipairs, type, tostring, tonumber = pairs, ipairs, type, tostring, tonumber
local math_min, math_max, math_floor          = math.min, math.max, math.floor
local math_huge                               = math.huge
local os_time                                 = os.time


local function Reply(src, msg)
    if type(src) == 'number' and src > 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { '[DIREKTIF]', msg } })
    else
        print(('[MATRIX:LAYERDIRECTIVES:CONSOLE] %s'):format(msg))
    end
end


local function VectorDistance(a, b)
    if not a or not b then return math_huge end
    local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end


local function ChecksumOf(raw, salt)
    local sum = 0
    for i = 1, #raw do
        sum = (sum + (raw:byte(i) * (i + salt))) % 0xFFFFFFF
    end
    return sum
end


local function GetPed(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return ped
end


local function GetCitizenId(src)
    local state = Matrix.GetOrCreatePlayerState(src)
    return state and state.citizenid
end


local function FindNearestTrapHouse(coords)
    local nearestId, nearestDist = nil, math_huge
    for id, house in pairs(Matrix.TrapHouses or {}) do
        local d = VectorDistance(coords, house.coords)
        if d < nearestDist then nearestId, nearestDist = id, d end
    end
    return nearestId, nearestDist
end


-- =====================================================================
-- [KATMAN 1] RESMİ/TEKNİK HUD BÜLTEN BİÇİMLEYİCİLERİ
-- F6/F10 panellerindeki narratif dile SON — yalnızca adli/askeri/kurumsal
-- format. Bu fonksiyonlar saf metin üreticileridir (yan etkisiz); mevcut
-- BuildSnapshot/HUD render zincirine DOKUNULMAZ — yeni komutlar ve
-- KATMAN 3/5/7 event zincirleri bunları Reply() ile kullanıcıya basar.
-- =====================================================================
function Matrix.LayerDirectives.FormatSignalAnomalyBulletin(trapHouseId)
    local heat = (Matrix.Bureau and Matrix.Bureau.GetHeat and Matrix.Bureau.GetHeat(trapHouseId)) or 0.0
    local ceiling = (Config.Bureau and Config.Bureau.CyberLeakMaxIntensity) or 5.0
    local ratio = Matrix.Clamp(heat / math_max(ceiling, 0.0001), 0.0, 1.0)
    local level = (ratio >= 0.75) and 'KRİTİK' or (ratio >= 0.40) and 'YÜKSEK' or 'DÜŞÜK'
    return ('[SİNYAL ANOMALİSİ: Spektrum Analizi Yoğun Dinleme Algıladı. IMSI Catcher Hücre Sızıntı Katsayısı: %s. Konum Deşifre Riski %s.]')
        :format(level, (ratio >= 0.40) and 'Yüksek' or 'Düşük')
end


function Matrix.LayerDirectives.FormatLogisticsElementBulletin(botId)
    local bot = Matrix.Bots[botId]
    if not bot then return '[Lojistik Unsur: KAYIT BULUNAMADI]' end
    local movementMult = (Matrix.Wounds and Matrix.Wounds.GetMovementMultiplier and Matrix.Wounds.GetMovementMultiplier(botId)) or 1.0
    local penaltyPct = math_floor((1.0 - movementMult) * 100 + 0.5)
    return ('[Lojistik Unsur #%d - Alt Ekstremite Travması: %%%d İntikal Hızı Cezası Aktif. Hücre Sevkiyat Gecikme Matrisi Devrede.]')
        :format(botId, penaltyPct)
end


function Matrix.LayerDirectives.FormatForensicBulletin(matchCertainty)
    matchCertainty = tonumber(matchCertainty) or 0.0
    local level = (matchCertainty >= 0.75) and 'Yüksek' or 'Düşük'
    return ('[Adli Tıp Kanıt Kontrolü: Balistik Striasyon Eşleşme Oranı %s. Ceza Mahkemesi Dosyası Birleştirme Süreci Başlatıldı.]'):format(level)
end


RegisterCommand('sinyaldurum', function(src, args)
    local trapHouseId = tonumber(args[1])
    if not trapHouseId then Reply(src, 'Kullanim: /sinyaldurum [trapHouseId]'); return end
    Reply(src, Matrix.LayerDirectives.FormatSignalAnomalyBulletin(trapHouseId))
end, false)


RegisterCommand('lojistikunsurdurum', function(src, args)
    local botId = tonumber(args[1])
    if not botId then Reply(src, 'Kullanim: /lojistikunsurdurum [botId]'); return end
    Reply(src, Matrix.LayerDirectives.FormatLogisticsElementBulletin(botId))
end, false)


-- =====================================================================
-- Ortak yardımcı: bir citizenid'nin matrix_player_state satırını (KATMAN 3
-- wound/fear alanları dahil) ACID biçimde günceller. RAM'de yüklüyse
-- (Matrix.PlayerState[citizenid]) orayı da senkronize eder.
-- =====================================================================
local function EscalatePlayerWound(citizenid, zone, delta, cortisolCap, fearMax)
    MySQL.query.await([[
        INSERT INTO matrix_player_state (citizenid, wound_zone, leg_injury, arm_injury, cortisol_level, fear_index, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            wound_zone    = VALUES(wound_zone),
            leg_injury    = LEAST(1.0, leg_injury + ?),
            arm_injury    = LEAST(1.0, arm_injury + ?),
            cortisol_level= GREATEST(cortisol_level, ?),
            fear_index    = ?,
            updated_at    = NOW()
    ]], {
        citizenid, zone,
        (zone == 'leg') and delta or 0.0,
        (zone == 'arm') and delta or 0.0,
        cortisolCap, fearMax,
        (zone == 'leg') and delta or 0.0,
        (zone == 'arm') and delta or 0.0,
        cortisolCap, fearMax
    })

    local ram = Matrix.PlayerState[citizenid]
    if ram and ram.biology then
        ram.biology.cortisol_level = math_max(ram.biology.cortisol_level or 0.0, cortisolCap)
    end
end


-- Bekleyen (pending) bir dava kaydına bir "ağırlaştırılmış suçlama"
-- ekler/açar. multiplier > 1.0 iken conviction_weight ÇARPIMSAL büyür
-- (server/bureau.lua Matrix.Bureau.TrialConviction* İLE AYNI "tavanlı
-- geometrik büyüme" felsefesi, yalnızca bu mekaniğe özgü sabit).
function Matrix.LayerDirectives.EscalateTrialConviction(citizenid, chargeLabel, multiplier, tamper, officerSrc, defendantSrc)
    if not citizenid then return end

    local pending = MySQL.single.await(
        'SELECT id, conviction_weight FROM matrix_trial_records WHERE defendant_citizenid = ? AND verdict = ? ORDER BY opened_at DESC LIMIT 1',
        { citizenid, 'pending' })

    local newWeight
    if pending then
        newWeight = Matrix.Clamp(math_max(tonumber(pending.conviction_weight) or 0.0, 0.05) * multiplier, 0.0, 1.0)
        MySQL.prepare([[
            UPDATE matrix_trial_records
            SET conviction_weight = ?, aggravated_charge = ?, evidence_tampering = evidence_tampering + ?
            WHERE id = ?
        ]], { newWeight, chargeLabel, tamper and 1 or 0, pending.id })
    else
        newWeight = Matrix.Clamp(multiplier - 1.0, 0.05, 1.0)
        MySQL.insert([[
            INSERT INTO matrix_trial_records
                (defendant_citizenid, dna_id, conviction_weight, verdict, aggravated_charge, evidence_tampering, opened_at)
            VALUES (?, ?, ?, 'pending', ?, ?, NOW())
        ]], { citizenid, ('DNA-PLR-%s'):format(citizenid), newWeight, chargeLabel, tamper and 1 or 0 })
    end

    Matrix.Log('LAYERDIRECTIVES',
        '[MAHKEME ESKALASYONU] %s -> "%s" (x%.2f) -> Mahkumiyet Skoru=%.3f (kanit-sabotaji:%s)',
        citizenid, chargeLabel, multiplier, newWeight, tostring(tamper))

    -- KATMAN 8: %100 mahkumiyet -> mevcut Karakter Wipe zincirini (DEĞİŞMEDİ)
    -- doğrudan tetikle (aynı ExecuteVerdict, gang_hoods.lua /kanityukle İLE
    -- AYNI çağrı deseni).
    if newWeight >= 1.0 and Matrix.Bureau and Matrix.Bureau.ExecuteVerdict then
        pcall(Matrix.Bureau.ExecuteVerdict, officerSrc or 0, {
            defendant_citizenid = citizenid,
            defendant_src        = defendantSrc,
            lie_count             = 1
        })
    end

    return newWeight
end


-- =====================================================================
-- [KATMAN 3] KONTROLLÜ TAKTİK GÜÇ UYGULAMASI (/kontrollugucuygula)
-- Not: bu kod tabanında eski "anlık/whip-tarzı" bir zorlama mekaniği
-- BULUNMADI (grep ile doğrulandı) — kaldırılacak bir eski mekanik yoktur;
-- bu, resmi/kurumsal çerçevede SIFIRDAN eklenen tek mekaniktir.
-- =====================================================================
RegisterCommand(Config.TacticalForce.Command, function(src, args)
    local targetCitizenId = args[1]
    local zone             = args[2]
    if type(targetCitizenId) ~= 'string' or type(zone) ~= 'string'
        or not Config.TacticalForce.ZoneDamage[zone] then
        Reply(src, ('Kullanim: /%s [hedefCitizenId] [leg|arm|head|torso]'):format(Config.TacticalForce.Command))
        return
    end

    local ped = GetPed(src)
    local coords = ped and GetEntityCoords(ped) or nil

    local delta        = Config.TacticalForce.ZoneDamage[zone]
    local cortisolCap   = Config.TacticalForce.CortisolCap or 0.90
    local fearMax        = Config.TacticalForce.FearIndexMax or 1.0

    EscalatePlayerWound(targetCitizenId, zone, delta, cortisolCap, fearMax)

    -- KATMAN 9 köprüsü: hedef bir lisanslı insan-satıcıysa (vendor_license=1)
    -- ve korku eşiği maksimuma ulaştıysa, düşman güvenli-ev koordinatları
    -- sızdırılır (spec: "vendor whose fear threshold is broken defects").
    local vendorRow = MySQL.single.await('SELECT vendor_license FROM matrix_player_state WHERE citizenid = ?', { targetCitizenId })
    if vendorRow and tonumber(vendorRow.vendor_license) == 1 then
        MySQL.prepare('UPDATE matrix_player_state SET vendor_compromised = 1 WHERE citizenid = ?', { targetCitizenId })
        if Matrix.FragmentedIntel and Matrix.FragmentedIntel.Add then
            Matrix.FragmentedIntel.Add(targetCitizenId, 'defected_vendor', 'enemy_safehouse', 0.50)
        end
        Reply(src, ('[TEZGAHÇI DEFECT ETTİ] %s korku esigini kirdi -- guvenli-ev istihbarati sizdirildi.'):format(targetCitizenId))
    end

    -- Büro şafak baskını mi-uygulama-arasında (interrupt) devreye girdi mi?
    local interrupted = false
    if coords then
        for id, house in pairs(Matrix.TrapHouses or {}) do
            if house.raid_ordered and VectorDistance(coords, house.coords) <= (Config.TacticalForce.BureauInterruptRadius or 150.0) then
                interrupted = true
                break
            end
        end
    end

    if interrupted then
        local dnaId = ('DNA-PLR-%s'):format(targetCitizenId)
        MySQL.insert([[
            INSERT INTO matrix_forensic_evidence
                (ballistic_id, evidence_type, striation_quality, fingerprint_id, fingerprint_quality,
                 match_certainty, sealed_as_crime_weapon, inflicted_force_striation, coords_x, coords_y, coords_z, created_at)
            VALUES (?, 'biyolojik_travma', ?, ?, 1.0, 1.0, 1, ?, ?, ?, ?, NOW())
        ]], {
            ('FORCE-%s-%d'):format(targetCitizenId, os_time()), delta, dnaId, delta,
            coords and coords.x or 0.0, coords and coords.y or 0.0, coords and coords.z or 0.0
        })

        local newWeight = Matrix.LayerDirectives.EscalateTrialConviction(
            targetCitizenId, Config.TacticalForce.AggravatedChargeLabel,
            Config.TacticalForce.AggravatedConvictionWeightMultiplier, false, src, nil)

        Reply(src, Matrix.LayerDirectives.FormatForensicBulletin(1.0))
        Reply(src, ('[BÜRO BASKINI ORTASINDA YAKALANDI] "%s" dava dosyasina islendi -- Mahkumiyet Skoru=%.3f'):format(
            Config.TacticalForce.AggravatedChargeLabel, newWeight))
    else
        Reply(src, ('[KONTROLLÜ TAKTİK GÜÇ UYGULAMASI] Hedef=%s Bölge=%s -- kortizol %%%.0f seviyesine kilitlendi, korku endeksi maksimuma cikti.'):format(
            targetCitizenId, zone, cortisolCap * 100))
    end
end, false)


-- =====================================================================
-- [KATMAN 2] GERÇEK OYUNCU KARABORSA TEZGAHI
-- =====================================================================
local ActiveHumanVendors = {} -- [citizenid] = { src=, coords=, stand_id= }


local function DeterministicVendorCoords(citizenid)
    local dbName = GetConvar('mysql_connection_string', GetCurrentResourceName())
    local raw = ('%s#%s#HUMANVENDOR#%s'):format(GetCurrentResourceName(), tostring(dbName), tostring(citizenid))
    local sum = ChecksumOf(raw, 61)
    local angle  = sum % 360
    local radius = (Config.HumanVendor.SpreadRadiusMeters or 700.0) * (0.30 + ((sum % 1000) / 1000.0) * 0.70)
    local x = 0.0 + radius * math.cos(math.rad(angle))
    local y = 0.0 + radius * math.sin(math.rad(angle))
    return vector3(x, y, 30.0)
end


RegisterCommand(Config.HumanVendor.OpenCommand, function(src)
    local citizenid = GetCitizenId(src)
    if not citizenid then Reply(src, 'Profil cozulemedi.'); return end

    local row = MySQL.single.await('SELECT vendor_license FROM matrix_player_state WHERE citizenid = ?', { citizenid })
    if not row or tonumber(row.vendor_license) ~= 1 then
        Reply(src, 'Karaborsa Tezgahi Lisansiniz yok -- once yeralti rusveti + HUMINT fisilti zincirini tamamlayin.')
        return
    end

    local coords = DeterministicVendorCoords(citizenid)
    ActiveHumanVendors[citizenid] = { src = src, coords = coords }

    MySQL.insert('INSERT INTO matrix_human_vendor_stands (citizenid, coord_x, coord_y, coord_z, opened_at) VALUES (?, ?, ?, ?, NOW())',
        { citizenid, coords.x, coords.y, coords.z })

    Reply(src, ('[TEZGAH ACILDI] Sabit koordinat: %.1f, %.1f, %.1f -- yalnizca KENDI envanterinizdeki gercek esyalari satabilirsiniz.'):format(
        coords.x, coords.y, coords.z))
end, false)


RegisterCommand(Config.HumanVendor.InteractCommand, function(src, args)
    local vendorCitizenId = args[1]
    local item = args[2]
    local count = tonumber(args[3]) or 1
    local price = tonumber(args[4])
    if type(vendorCitizenId) ~= 'string' or type(item) ~= 'string' or not price then
        Reply(src, ('Kullanim: /%s [saticiCitizenId] [item] [adet] [fiyat]'):format(Config.HumanVendor.InteractCommand))
        return
    end

    local vendor = ActiveHumanVendors[vendorCitizenId]
    if not vendor then Reply(src, 'Bu satici su an bir tezgah actirmamis.'); return end

    local ped = GetPed(src)
    local coords = ped and GetEntityCoords(ped) or nil
    if not coords or VectorDistance(coords, vendor.coords) > (Config.HumanVendor.InteractRadius or 6.0) then
        Reply(src, 'Tezgahin yaninda degilsiniz.')
        return
    end

    -- Yalnizca saticinin KENDI ox_inventory envanterinden gercek esya
    -- satilir -- hicbir sey icat/kopyalanmaz.
    local haveOk, have = pcall(function() return exports['ox_inventory']:Search(vendor.src, 'count', item) end)
    have = (haveOk and tonumber(have)) or 0
    if have < count then
        Reply(src, 'Saticinin envanterinde bu esyadan yeterli miktar yok.')
        return
    end

    local buyerPlayer = Matrix.QBX:GetPlayer(src)
    if not buyerPlayer then return end
    local cash = (buyerPlayer.PlayerData.money and buyerPlayer.PlayerData.money.cash) or 0
    if cash < price then Reply(src, 'Yetersiz nakit.'); return end

    local chargeOk = pcall(function() return buyerPlayer.Functions.RemoveMoney('cash', price, 'human-vendor-purchase') end)
    if not chargeOk then Reply(src, 'Odeme basarisiz.'); return end

    local moveOk = pcall(function() return exports['ox_inventory']:RemoveItem(vendor.src, item, count) end)
    if moveOk then moveOk = pcall(function() return exports['ox_inventory']:AddItem(src, item, count) end) end

    if not moveOk then
        pcall(function() buyerPlayer.Functions.AddMoney('cash', price, 'human-vendor-refund') end)
        Reply(src, 'Transfer basarisiz, odeme iade edildi.')
        return
    end

    local vendorPlayer = Matrix.QBX:GetPlayer(vendor.src)
    if vendorPlayer then pcall(function() vendorPlayer.Functions.AddMoney('cash', price, 'human-vendor-sale') end) end

    Reply(src, ('Satin alindi: %s x%d ($%.0f).'):format(item, count, price))
    if vendor.src then TriggerClientEvent('matrix:client:actionNotify', vendor.src, true, ('Tezgahinizdan %s x%d satildi ($%.0f).'):format(item, count, price)) end
end, false)


-- Bir insan-satici serbestce muhbirlik yapmayi secebilir -- kendini
-- compromised=1 olarak isaretler (baskin/kontrollugucuygula icin hedef
-- haline gelir).
RegisterCommand(Config.HumanVendor.InformCommand, function(src)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    MySQL.prepare('UPDATE matrix_player_state SET vendor_compromised = 1 WHERE citizenid = ?', { citizenid })
    Reply(src, 'Buroya bilgi vermeye basladiniz -- artik cetenizin gozunde bir hedefsiniz.')
end, false)


-- Bir lisans, HUMINT rüşvet + fısıltı zincirinin (Config.FragmentedIntel'e
-- işlenen kümülatif intel_fragments >= 1.0) tamamlanmasıyla verilir --
-- Katman 6'nin ZATEN VAR OLAN keşif motoruna BAĞLANIR, ikinci bir eşik
-- İCAT EDİLMEZ.
local function TryGrantVendorLicense(citizenid)
    local row = MySQL.single.await(
        'SELECT SUM(intel_fragments) AS total FROM matrix_fragmented_intel WHERE citizenid = ? AND contact_type IN (?, ?)',
        { citizenid, 'bribery', 'wiretap' })
    local total = row and tonumber(row.total) or 0.0
    if total >= (Config.FragmentedIntel.DiscoveredThreshold or 1.0) then
        MySQL.prepare('UPDATE matrix_player_state SET vendor_license = 1 WHERE citizenid = ?', { citizenid })
        return true
    end
    return false
end


RegisterCommand('lisansdurum', function(src)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    local granted = TryGrantVendorLicense(citizenid)
    Reply(src, granted and 'Karaborsa Tezgahi Lisansi VERILDI.' or 'Henuz yeterli HUMINT/rusvet zinciriniz yok.')
end, false)


-- =====================================================================
-- [KATMAN 4] BÜROKRATİK/LOJİSTİK GECİKME MOTORU
-- =====================================================================
local SUPPLY_PRICES = {
    door_lock_heavy      = 12000.0,
    chemical_acid_bottle = 1800.0,
    weapon_spare_barrel  = 2200.0
}


RegisterCommand(Config.SupplyChain.PurchaseCommand, function(src, args)
    local item = args[1]
    if type(item) ~= 'string' or not Config.SupplyChain.TrackedItems[item] then
        Reply(src, ('Kullanim: /%s [door_lock_heavy|chemical_acid_bottle|weapon_spare_barrel]'):format(Config.SupplyChain.PurchaseCommand))
        return
    end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local price = SUPPLY_PRICES[item] or 5000.0
    local player = Matrix.QBX:GetPlayer(src)
    if not player then return end
    local cash = (player.PlayerData.money and player.PlayerData.money.cash) or 0
    if cash < price then Reply(src, 'Yetersiz nakit.'); return end

    local chargeOk = pcall(function() return player.Functions.RemoveMoney('cash', price, 'supply-chain-purchase') end)
    if not chargeOk then Reply(src, 'Odeme basarisiz.'); return end

    local batchId = ('BATCH-%s-%d'):format(citizenid, os_time())
    local addOk = pcall(function() return exports['ox_inventory']:AddItem(src, item, 1, { citizenid = citizenid, batch_id = batchId }) end)
    if not addOk then
        pcall(function() player.Functions.AddMoney('cash', price, 'supply-chain-refund') end)
        Reply(src, 'Teslimat basarisiz, odeme iade edildi.')
        return
    end

    MySQL.insert('INSERT INTO matrix_batch_sync_queue (citizenid, item_ref, batch_id, synced, created_at) VALUES (?, ?, ?, 0, NOW())',
        { citizenid, item, batchId })

    Reply(src, ('%s satin alindi. Bu satis ANINDA Buro\'ya ulasmaz -- %d dakikalik toplu senkronizasyon penceresine kuyruklandi.'):format(
        item, math_floor((Config.Diagnostics.BatchSyncIntervalSeconds or 900) / 60)))
end, false)


-- ★ CRITICAL FIX: eski "fire-and-forget MySQL.prepare (await edilmeden) +
-- sonuc dogrulanmadan basari loglama" deseni terk edildi (bkz.
-- server/logistics.lua FlushDirtyFleet / server/market.lua
-- FlushDirtyMarketZones ile AYNI desen). Simdi TUM satirlar TEK bir toplu
-- MySQL.transaction.await icinde kilitlenir; basari SADECE transaction
-- gercekten basariyla donduysa loglanir -- basarisiz olursa satirlar
-- synced = 0 olarak KALIR ve bir sonraki flush turunda tekrar denenir
-- (veri kaybi YOK, cift-loglama YOK).
local function FlushSupplyChainBatch()
    local rows = MySQL.query.await('SELECT id, citizenid, item_ref, batch_id FROM matrix_batch_sync_queue WHERE synced = 0 LIMIT 500') or {}
    if #rows == 0 then return end

    local queries = {}
    for _, row in ipairs(rows) do
        queries[#queries + 1] = {
            query = 'UPDATE matrix_batch_sync_queue SET synced = 1, synced_at = NOW() WHERE id = ? AND synced = 0',
            values = { row.id }
        }
    end

    local ok, result = pcall(function() return MySQL.transaction.await(queries) end)
    if ok and result ~= false then
        Matrix.Log('LAYERDIRECTIVES', '[TOPLU SENKRONIZASYON] %d bekleyen tedarik satisi Buro DB\'sine islendi.', #rows)
    else
        Matrix.Log('LAYERDIRECTIVES', '[HATA][KRITIK] FlushSupplyChainBatch transaction basarisiz -- satirlar synced=0 olarak korundu, tekrar denenecek: %s',
            tostring(result))
    end
end


CreateThread(function()
    while true do
        Wait((Config.Diagnostics.BatchSyncIntervalSeconds or 900) * 1000)
        local ok, err = pcall(FlushSupplyChainBatch)
        if not ok then Matrix.Log('LAYERDIRECTIVES', '[HATA] FlushSupplyChainBatch basarisiz (yutuldu): %s', tostring(err)) end
    end
end)


-- ALPR tespiti: ANINDA algilanir ama Büro yoğunluk sayacına yalnızca
-- Config.SupplyChain.AlprIntensityDelaySeconds (180s) SONRA yansir.
function Matrix.LayerDirectives.OnALPRDetection(trapHouseId, citizenid, plate)
    trapHouseId = tonumber(trapHouseId)
    if not trapHouseId or not Matrix.TrapHouses[trapHouseId] then return end

    CreateThread(function()
        Wait((Config.SupplyChain.AlprIntensityDelaySeconds or 180) * 1000)
        if Matrix.Bureau and Matrix.Bureau.AdvanceDecryption then
            Matrix.Bureau.AdvanceDecryption(trapHouseId, 0.03)
        end
        Matrix.Log('LAYERDIRECTIVES', '[ALPR GECIKMELI ISLEM] Trap #%d icin %ds gecikmeli desifre kazanci uygulandi (plaka:%s).',
            trapHouseId, Config.SupplyChain.AlprIntensityDelaySeconds or 180, tostring(plate))
    end)
end


RegisterNetEvent('matrix:server:layerDirectives:alprDetection', function(trapHouseId, plate)
    local src = source
    local citizenid = GetCitizenId(src)
    Matrix.LayerDirectives.OnALPRDetection(trapHouseId, citizenid, plate)
end)


-- Frisk/durdurma sirasinda kontrabant bulunursa: illegal_supply_log
-- adli kanit olarak islenir VE +%40 Mahkumiyet Skoru uygulanir.
function Matrix.LayerDirectives.OnFriskContraband(citizenid, itemRef, plate)
    MySQL.insert([[
        INSERT INTO matrix_illegal_supply_log (citizenid, item_ref, plate, conviction_weight_applied, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { citizenid, itemRef, plate, Config.SupplyChain.FriskConvictionWeightBonus or 0.40 })

    if citizenid then
        Matrix.LayerDirectives.EscalateTrialConviction(citizenid, 'Yasadisi Tedarik Zinciri Tasiyiciligi',
            1.0 + (Config.SupplyChain.FriskConvictionWeightBonus or 0.40), false, 0, nil)
    end
end


RegisterCommand('kontrabantihbar', function(src, args)
    local citizenid = args[1]
    local itemRef = args[2]
    local plate = args[3]
    if type(citizenid) ~= 'string' or type(itemRef) ~= 'string' then
        Reply(src, 'Kullanim: /kontrabantihbar [citizenid] [item] [plaka(opsiyonel)]')
        return
    end
    Matrix.LayerDirectives.OnFriskContraband(citizenid, itemRef, plate)
    Reply(src, 'Kontrabant adli kanit olarak islendi, Mahkumiyet Skoru guncellendi.')
end, false)


-- =====================================================================
-- [KATMAN 5] door_lock_heavy — 120 SANİYELİK RİJİT FİZİKSEL KURULUM
-- =====================================================================
RegisterCommand(Config.DoorLockInstall.Command, function(src, args)
    local trapHouseId = tonumber(args[1])
    if not trapHouseId or not Matrix.TrapHouses[trapHouseId] then
        Reply(src, ('Kullanim: /%s [trapHouseId]'):format(Config.DoorLockInstall.Command))
        return
    end

    local item = Config.DoorLockInstall.Item
    local haveOk, have = pcall(function() return exports['ox_inventory']:Search(src, 'count', item) end)
    have = (haveOk and tonumber(have)) or 0
    if have < 1 then
        Reply(src, ('Envanterinizde %s bulunamadi (bkz. /%s).'):format(item, Config.SupplyChain.PurchaseCommand))
        return
    end

    local removeOk = pcall(function() return exports['ox_inventory']:RemoveItem(src, item, 1) end)
    if not removeOk then Reply(src, 'Kilit tuketilemedi.'); return end

    local citizenid = GetCitizenId(src)
    MySQL.insert('INSERT INTO matrix_door_lock_installs (trap_house_id, citizenid, completed, created_at) VALUES (?, ?, 0, NOW())',
        { trapHouseId, citizenid })

    Reply(src, ('[KURULUM BAŞLADI] %d saniyelik rijit fiziksel kurulum döngüsü -- telsiz KULLANAMAZSINIZ ve SAVUNMASIZSINIZ.'):format(
        Config.DoorLockInstall.InstallSeconds or 120))

    -- Telsiz kilidi (mevcut Matrix.Radio.ApplyStatic ile AYNI köprü).
    if Matrix.Radio and Matrix.Radio.ApplyStatic then
        Matrix.Radio.ApplyStatic(src, Config.DoorLockInstall.RadioStaticDuringInstall or 1.0, 'door-lock-install')
    end
    TriggerClientEvent('matrix:client:layerDirectives:setDefenseless', src, true)

    -- RegisterCommand callback'i kendi coroutine'inde çalışır -- burada
    -- Wait() ETMEK yalnızca BU çağrıyı bloklar, master ticker'ı ETKİLEMEZ.
    Wait((Config.DoorLockInstall.InstallSeconds or 120) * 1000)

    TriggerClientEvent('matrix:client:layerDirectives:setDefenseless', src, false)
    if Matrix.Radio and Matrix.Radio.ApplyStatic then
        Matrix.Radio.ApplyStatic(src, 0.0, 'door-lock-install-complete')
    end

    -- Baskin sirasinda yarida kesildi mi? (raid_ordered mevcut trap house'ta
    -- true ise) -- KATMAN 8 kanit sabotaji ceza zinciri.
    local house = Matrix.TrapHouses[trapHouseId]
    if house and house.raid_ordered then
        MySQL.prepare('UPDATE matrix_door_lock_installs SET completed = 0 WHERE trap_house_id = ? AND citizenid = ? ORDER BY id DESC LIMIT 1',
            { trapHouseId, citizenid })
        if citizenid then
            Matrix.LayerDirectives.EscalateTrialConviction(citizenid, 'Kanit/Kurulum Sabotaji Sirasinda Yakalanma',
                (Config.EvidenceTampering and Config.EvidenceTampering.ConvictionWeightMultiplier) or 1.50, true, src, src)
        end
        Reply(src, '[KESINTIYE UGRADI] Buro baskini kurulumu yarida kesti -- kanit sabotaji olarak islendi.')
        return
    end

    MySQL.prepare('UPDATE matrix_door_lock_installs SET completed = 1 WHERE trap_house_id = ? AND citizenid = ? ORDER BY id DESC LIMIT 1',
        { trapHouseId, citizenid })

    local levelRow = MySQL.single.await('SELECT level FROM matrix_door_reinforcement WHERE trap_house_id = ?', { trapHouseId })
    local currentLevel = (levelRow and tonumber(levelRow.level)) or 0
    local newLevel = math_min(currentLevel + 1, (Config.DoorReinforcement and Config.DoorReinforcement.MaxLevel) or 3)
    MySQL.query.await([[
        INSERT INTO matrix_door_reinforcement (trap_house_id, level, installed_by_citizenid, updated_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE level = VALUES(level), installed_by_citizenid = VALUES(installed_by_citizenid), updated_at = NOW()
    ]], { trapHouseId, newLevel, citizenid })

    Reply(src, ('[KURULUM TAMAMLANDI] Trap #%d kapi sürgü seviyesi %d oldu.'):format(trapHouseId, newLevel))
end, false)


-- =====================================================================
-- [KATMAN 5/7/10] ELE GEÇİRİLMİŞ CİHAZ FORENSIC RECOVERY — 24 GERÇEK SAAT
-- server-restart-proof (recovery_target_epoch matrix_device_recovery'de
-- kalıcı bir DB kolonu; RAM'de tutulmaz).
-- =====================================================================
function Matrix.LayerDirectives.IsDeviceRecovered(deviceId)
    local row = MySQL.single.await('SELECT recovery_target_epoch, unlocked FROM matrix_device_recovery WHERE device_id = ?', { deviceId })
    if not row then return false end
    if tonumber(row.unlocked) == 1 then return true end
    return os_time() >= (tonumber(row.recovery_target_epoch) or math_huge)
end


-- ★ CRITICAL FIX: /cihazcozumle (manuel kontrol) ve otonom
-- ProcessDeviceRecoveryUnlocks (60s periyodik tarama) AYNI satiri
-- ikisi de "SELECT sonra UPDATE" (check-then-act) ile isliyordu. Ikisi
-- de MySQL.*.await ile "yield" ettigi icin (coroutine baglaminda diger
-- komut/thread'ler araya girebilir), su senaryo mumkundu: oyuncu suresi
-- dolar dolmaz /cihazcozumle calistirir -> unlocked=1 yapip doner ama
-- matrix_forensic_evidence satiri EKLEMEZ; ardindan periyodik tarama
-- "WHERE unlocked = 0" filtresine bu satiri artik yakalayamadigi icin
-- kanit HICBIR ZAMAN adli olarak damgalanmaz (kalici veri kaybi).
-- Cozum: unlock + adli damgalama TEK bir atomik fonksiyonda, affected-rows
-- kontrolu ile birlestirildi -- "UPDATE ... WHERE unlocked = 0" SADECE
-- BIR cagrinin 0->1 gecisini "kazanmasini" saglar (InnoDB row-lock ile
-- atomik); kanit satiri SADECE o kazanan cagri tarafindan, SADECE BIR
-- kez eklenir. Iki yol da (manuel komut ve periyodik tarama) artik bu
-- TEK fonksiyonu cagiriyor.
local function UnlockDeviceRecoveryAndStamp(deviceId, citizenid)
    local affected = MySQL.update.await(
        'UPDATE matrix_device_recovery SET unlocked = 1, fragments_decoded = ? WHERE device_id = ? AND unlocked = 0',
        { Config.DeviceRecovery.FragmentsTotal or 24, deviceId })

    if not (tonumber(affected) and tonumber(affected) > 0) then
        return false -- zaten baska bir cagri tarafindan kazanildi/kilitlendi
    end

    MySQL.insert([[
        INSERT INTO matrix_forensic_evidence
            (ballistic_id, evidence_type, striation_quality, fingerprint_id, fingerprint_quality,
             match_certainty, sealed_as_crime_weapon, recovery_target_epoch, created_at)
        VALUES (?, 'cyber', 1.0, ?, 1.0, 1.0, 1, 0, NOW())
    ]], { ('DEVICE-%s'):format(deviceId), ('DNA-PLR-%s'):format(citizenid or 'UNKNOWN') })

    Matrix.Log('LAYERDIRECTIVES', '[CIHAZ COZULDU] %s adli olarak damgalandi (24s gercek-zaman doldu).', deviceId)
    return true
end


RegisterCommand(Config.DeviceRecovery.Command, function(src, args)
    local slot = tonumber(args[1])
    if not slot then Reply(src, ('Kullanim: /%s [envanterSlotu]'):format(Config.DeviceRecovery.Command)); return end

    local okSlot, item = pcall(function() return exports['ox_inventory']:GetSlot(src, slot) end)
    if not okSlot or type(item) ~= 'table' or item.name ~= Config.DeviceRecovery.Item then
        Reply(src, ('Belirtilen slotta bir %s bulunamadi.'):format(Config.DeviceRecovery.Item))
        return
    end

    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local meta = item.metadata or {}
    local deviceId = meta.device_id
    if type(deviceId) ~= 'string' then
        deviceId = ('DEV-%s-%d'):format(citizenid, os_time())
        local targetEpoch = os_time() + (Config.DeviceRecovery.DurationRealSeconds or 86400)

        MySQL.insert([[
            INSERT INTO matrix_device_recovery (device_id, citizenid, recovery_target_epoch, fragments_decoded, unlocked, created_at)
            VALUES (?, ?, ?, 0, 0, NOW())
        ]], { deviceId, citizenid, targetEpoch })

        Matrix.Inventory.MergeMetadata(tostring(src), slot, { device_id = deviceId, recovery_target_epoch = targetEpoch })
        Reply(src, ('[ÇÖZÜMLEME BAŞLADI] Cihaz kimliği: %s -- 24 GERÇEK SAAT sürecek. Bu süre dolmadan kanıt olarak KULLANILAMAZ.'):format(deviceId))
        return
    end

    local row = MySQL.single.await('SELECT recovery_target_epoch, fragments_decoded, unlocked FROM matrix_device_recovery WHERE device_id = ?', { deviceId })
    if not row then Reply(src, 'Cihaz kaydi bulunamadi.'); return end

    local targetEpoch = tonumber(row.recovery_target_epoch) or 0
    local remaining = targetEpoch - os_time()
    if remaining > 0 then
        local hoursLeft = math.ceil(remaining / 3600)
        Reply(src, ('[ÇÖZÜLÜYOR] %s -- %d saat kaldı. Henüz mahkemede kanıt olarak kullanılamaz.'):format(deviceId, hoursLeft))
    else
        UnlockDeviceRecoveryAndStamp(deviceId, citizenid)
        Reply(src, ('[ÇÖZÜLDÜ] %s -- 24 saatlik gerçek-zamanlı çözümleme tamamlandı, adli olarak damgalandı.'):format(deviceId))
    end
end, false)


-- Sunucu açılışında VE periyodik olarak: süresi dolmuş ama henüz
-- unlocked=0 kalan cihazlar otonom olarak açılır ve adli olarak
-- postmark'lanır (spec: "auto-unlocks and gets forensically postmarked
-- the moment it elapses").
local function ProcessDeviceRecoveryUnlocks()
    local rows = MySQL.query.await(
        'SELECT id, device_id, citizenid FROM matrix_device_recovery WHERE unlocked = 0 AND recovery_target_epoch > 0 AND recovery_target_epoch <= ?',
        { os_time() }) or {}

    for _, row in ipairs(rows) do
        UnlockDeviceRecoveryAndStamp(row.device_id, row.citizenid)
    end
end


CreateThread(function()
    Wait(5000)
    local ok, err = pcall(ProcessDeviceRecoveryUnlocks)
    if not ok then Matrix.Log('LAYERDIRECTIVES', '[HATA] ProcessDeviceRecoveryUnlocks ilk calisma basarisiz: %s', tostring(err)) end
    while true do
        Wait(60000)
        local tickOk, tickErr = pcall(ProcessDeviceRecoveryUnlocks)
        if not tickOk then Matrix.Log('LAYERDIRECTIVES', '[HATA] ProcessDeviceRecoveryUnlocks hata (yutuldu): %s', tostring(tickErr)) end
    end
end)


-- =====================================================================
-- [KATMAN 7] İNTERAKTİF DONANIM KANIT SABOTAJI
-- =====================================================================

-- 15 saniyelik termit imha geri sayımı -- /telefonuyoket bureau.lua'da
-- ZATEN VAR olan Matrix.Bureau.SabotagePhoneLine'ı çağırıyordu (ANINDA);
-- bkz. server/bureau.lua RegisterCommand('telefonuyoket', ...) — bu
-- dosyada DEĞİL, orada 15sn'lik "yerinde kal" kilidi additive olarak
-- eklendi (SabotagePhoneLine fonksiyonunun kendisi DEĞİŞMEDİ).

-- Kovan/kasa asit banyosu: chemical_acid_bottle tüketir, striation_quality
-- (Q_kovan) zamanla eritir.
RegisterCommand(Config.HardwareSabotage.AcidBathCommand, function(src, args)
    local evidenceId = tonumber(args[1])
    if not evidenceId then Reply(src, ('Kullanim: /%s [kanitId]'):format(Config.HardwareSabotage.AcidBathCommand)); return end

    local haveOk, have = pcall(function() return exports['ox_inventory']:Search(src, 'count', Config.HardwareSabotage.AcidBottleItem) end)
    have = (haveOk and tonumber(have)) or 0
    if have < 1 then Reply(src, 'Asit sisesi bulunamadi.'); return end

    local removeOk = pcall(function() return exports['ox_inventory']:RemoveItem(src, Config.HardwareSabotage.AcidBottleItem, 1) end)
    if not removeOk then Reply(src, 'Asit sisesi tuketilemedi.'); return end

    local affected = MySQL.update.await(
        'UPDATE matrix_forensic_evidence SET striation_quality = GREATEST(0.0, striation_quality - ?) WHERE id = ? AND sealed_as_crime_weapon = 0',
        { Config.HardwareSabotage.AcidErosionPerApplication or 0.20, evidenceId })

    if tonumber(affected) and tonumber(affected) > 0 then
        Reply(src, '[ASIT BANYOSU] Kovan striasyon kalitesi eritildi.')
    else
        Reply(src, 'Bu kanit satiri bulunamadi ya da zaten muhurlenmis (dokunulamaz).')
    end
end, false)


-- Paravan şirket degausser'i: henüz senkronize edilmemiş (900s penceresi
-- içindeki) toplu senkronizasyon kayıtlarını manyetik olarak siler.
RegisterCommand(Config.HardwareSabotage.DegaussCommand, function(src)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end

    local affected = MySQL.update.await('DELETE FROM matrix_batch_sync_queue WHERE citizenid = ? AND synced = 0', { citizenid })
    Reply(src, ('[DEGAUSSER] %s satirlik henuz senkronize edilmemis tedarik kaydi manyetik olarak silindi.'):format(tostring(affected or 0)))
end, false)


-- ★ /namludegistir'in KATMAN 7 sürümü — forensics.lua'daki tanımı
-- GÖLGELER (dosya-başı yorumuna bkz). 60 saniyelik rijit tezgah kilidi.
RegisterCommand('namludegistir', function(src, args)
    local weaponSlot = tonumber(args[1])
    if not weaponSlot then
        Reply(src, 'Kullanim: /namludegistir [silahSlotu] (F10 menusunden kullanin)')
        return
    end

    local okSlot, weaponItem = pcall(function() return exports['ox_inventory']:GetSlot(src, weaponSlot) end)
    if not okSlot or type(weaponItem) ~= 'table' or type(weaponItem.name) ~= 'string' then
        Reply(src, 'Belirtilen slotta silah bulunamadi.')
        return
    end
    if not (Config.BlackMarket and Config.BlackMarket.ReplaceableWeaponItems and Config.BlackMarket.ReplaceableWeaponItems[weaponItem.name]) then
        Reply(src, 'Bu silah turu icin namlu degisimi desteklenmiyor.')
        return
    end

    local barrelItem = Config.BlackMarket and Config.BlackMarket.SpareBarrelItem
    local countOk, barrelCount = pcall(function() return exports['ox_inventory']:Search(src, 'count', barrelItem) end)
    barrelCount = (countOk and tonumber(barrelCount)) or 0
    if barrelCount < 1 then
        Reply(src, 'Yedek Namlu bulunamadi.')
        return
    end

    local removeOk = pcall(function() return exports['ox_inventory']:RemoveItem(src, barrelItem, 1) end)
    if not removeOk then Reply(src, 'Yedek Namlu tuketilemedi.'); return end

    local oldMeta   = weaponItem.metadata or {}
    local oldSerial = oldMeta.weapon_serial
    local citizenid = GetCitizenId(src)
    local trapHouseId = nil
    do
        local ped = GetPed(src)
        local coords = ped and GetEntityCoords(ped) or nil
        if coords then trapHouseId = FindNearestTrapHouse(coords) end
    end

    Reply(src, ('[TEZGAH KİLİDİ] %d saniyelik rijit namlu sokum/degisim döngüsü basladi -- yerinizde kalin.'):format(
        Config.HardwareSabotage.BarrelSwapLockSeconds or 60))
    TriggerClientEvent('matrix:client:layerDirectives:setDefenseless', src, true)

    Wait((Config.HardwareSabotage.BarrelSwapLockSeconds or 60) * 1000)

    TriggerClientEvent('matrix:client:layerDirectives:setDefenseless', src, false)

    local house = trapHouseId and Matrix.TrapHouses[trapHouseId]
    local interrupted = house and house.raid_ordered

    if interrupted then
        -- El konulan parcalar dismantled_criminal_evidence olarak muhurlenir
        -- ve eski namlunun Q_kovan=1.0 capraz-eslestirmesi agir dosyaya girer.
        if type(oldSerial) == 'string' and oldSerial ~= '' then
            MySQL.insert('INSERT INTO matrix_dismantled_evidence (citizenid, weapon_serial, striation_quality, created_at) VALUES (?, ?, 1.0, NOW())',
                { citizenid, oldSerial })
        end
        if citizenid then
            Matrix.LayerDirectives.EscalateTrialConviction(citizenid, 'Silah Sokum/Kanit Sabotaji Sirasinda Yakalanma',
                (Config.EvidenceTampering and Config.EvidenceTampering.ConvictionWeightMultiplier) or 1.50, true, src, src)
        end
        Reply(src, '[YAKALANDI] Buro namlu degisimini yarida kesti -- el konulan parcalar agir dosyaya islendi.')
        return
    end

    local newSerial
    if Matrix.BlackMarket and Matrix.BlackMarket.GenerateWeaponSerial then
        newSerial = Matrix.BlackMarket.GenerateWeaponSerial(citizenid or tostring(src), weaponItem.name)
    else
        newSerial = ('BM-%s-%07X'):format(weaponItem.name:sub(-6):upper(), (GetGameTimer() + weaponSlot) % 0xFFFFFFF)
    end

    if type(oldSerial) == 'string' and oldSerial ~= '' and Matrix.Forensics and Matrix.Forensics.WipeBallisticRecord then
        pcall(Matrix.Forensics.WipeBallisticRecord, oldSerial)
    end

    Matrix.Inventory.MergeMetadata(tostring(src), weaponSlot, {
        weapon_serial   = newSerial,
        shots_fired     = 0,
        durability      = 100.0,
        jam_accumulator = 0.0,
        jammed          = false,
        description     = '[YENI NAMLU TAKILDI -- 60sn TEZGAH KILIDI TAMAMLANDI]\nBuro balistik arsivi tamamen silindi.'
    })

    TriggerClientEvent('matrix:client:weaponJamStateChanged', src, weaponSlot, false)
    Reply(src, '[NAMLU DEGISTIRILDI] Buro balistik arsivi tamamen kor edildi.')
end, false)


-- =====================================================================
-- [KATMAN 6] SOSYAL İNTEL/HUMINT ENGİNE — ek komutlar (matrix_fragmented_
-- intel/matrix_vendor_pool ZATEN VAR, bkz. server/underworld_network.lua)
-- =====================================================================
RegisterCommand('biraismarla', function(src, args)
    local vendorId = tonumber(args[1])
    if not vendorId then Reply(src, 'Kullanim: /biraismarla [saticiId]'); return end

    local player = Matrix.QBX:GetPlayer(src)
    if not player then return end
    local price = 50.0
    local cash = (player.PlayerData.money and player.PlayerData.money.cash) or 0
    if cash < price then Reply(src, 'Yetersiz nakit.'); return end
    pcall(function() player.Functions.RemoveMoney('cash', price, 'humint-bira-ismarla') end)

    local citizenid = GetCitizenId(src)
    if citizenid and Matrix.FragmentedIntel and Matrix.FragmentedIntel.Add then
        Matrix.FragmentedIntel.Add(citizenid, 'vendor', tostring(vendorId), 0.20)
    end
    Reply(src, '[HUMINT] Bira ısmarlandı -- +0.20 istihbarat parçası.')
end, false)
RegisterCommand('fisilda', function(src, args) ExecuteCommand(('biraismarla %s'):format(args[1] or '')) end, false)


RegisterCommand('rusvetteklifver', function(src, args)
    local officerSrc = tonumber(args[1])
    if not officerSrc then Reply(src, 'Kullanim: /rusvetteklifver [memurSrc]'); return end

    local player = Matrix.QBX:GetPlayer(src)
    if not player then return end
    local amount = 5000.0
    local cash = (player.PlayerData.money and player.PlayerData.money.cash) or 0
    local hasWatch = pcall(function() return (exports['ox_inventory']:Search(src, 'count', 'valuable_watch') or 0) > 0 end)
    if cash < amount and not hasWatch then Reply(src, 'Yetersiz nakit (veya degerli bir saat).'); return end

    local ok = Matrix.Bureau and Matrix.Bureau.ProcessBribeOffer and select(1, Matrix.Bureau.ProcessBribeOffer(officerSrc, src, amount))
    if ok then
        pcall(function() exports['ox_inventory']:AddItem(src, 'interrogation_report', 1) end)
        local citizenid = GetCitizenId(src)
        if citizenid and Matrix.FragmentedIntel and Matrix.FragmentedIntel.Add then
            Matrix.FragmentedIntel.Add(citizenid, 'doctor', 'phantom_doctor', 0.40)
        end
        Reply(src, '[RUSVET BASARILI] Sorgu raporu alindi -- Hayalet Cerrah konum sifresine +0.40 istihbarat.')
    else
        Reply(src, 'Yalniz sokak memuru rusveti reddetti.')
    end
end, false)


-- Evsizlere para üstü/sıcak kahve — deterministik (RNG'siz), sabit
-- istihbarat kazancı; en yakın düşman mahalleye bağlanır.
RegisterCommand('sadakaver', function(src)
    local ped = GetPed(src)
    local coords = ped and GetEntityCoords(ped) or nil
    if not coords then return end

    local nearestHoodId, nearestDist = nil, math_huge
    for id, hood in pairs(Matrix.GangHoods and Matrix.GangHoods.Hoods or {}) do
        local d = VectorDistance(coords, hood.coords)
        if d < nearestDist then nearestHoodId, nearestDist = id, d end
    end
    if not nearestHoodId then Reply(src, 'Yakinda bir dusman mahallesi tespit edilemedi.'); return end

    local citizenid = GetCitizenId(src)
    if citizenid and Matrix.FragmentedIntel and Matrix.FragmentedIntel.Add then
        Matrix.FragmentedIntel.Add(citizenid, 'gang_hood_intel', tostring(nearestHoodId), 0.15)
    end
    Reply(src, ('[SADAKA] Bir evsiz size en yakin mahalle #%d hakkinda ipucu verdi (+0.15 istihbarat).'):format(nearestHoodId))
end, false)


-- =====================================================================
-- [KATMAN 8] HÜCRE İZOLASYON İHLALİ (CONTEXT DRIFT)
-- =====================================================================
function Matrix.CellIsolation.Guard(bot, domain)
    if not bot or not bot.role then return false end
    local allowed = Config.CellIsolation.Domains[bot.role]
    if not allowed then return false end -- bilinmeyen role -> yetki alani yok

    local ok = false
    for _, d in ipairs(allowed) do
        if d == domain then ok = true; break end
    end

    if ok then return true end

    -- İhlal: kaydet, botu 'disbanded' moduna dondur (alt-hucrenin
    -- kaskadli sizmasini onlemek icin), false don.
    -- ★ CRITICAL FIX: eski fire-and-forget MySQL.insert (await edilmeden)
    -- burada YANLIS -- Guard() SENKRON false dondugu icin, cagiran taraf
    -- (ornegin server/matrix_diagnostics.lua RunCellIsolationViolationCheck)
    -- Guard()'dan hemen sonra ayni satiri DOGRULAMAK icin okuyabilir; insert
    -- await edilmezse okuma, yazmadan ONCE yarisabilir (race) ve ihlal
    -- satiri henuz DB'ye ulasmadan "yazilmadi" gibi gorunebilir. .await
    -- eklenerek Guard() DONMEDEN once yazmanin gercekten TAMAMLANDIGI
    -- garanti edilir (server/bureau.lua'daki diger denetim-kritik
    -- yazilarla AYNI disiplin).
    MySQL.insert.await('INSERT INTO matrix_cell_isolation_violations (bot_id, role, attempted_domain, created_at) VALUES (?, ?, ?, NOW())',
        { bot.id, bot.role, domain })

    bot.status = 'disbanded'
    if Matrix.MarkBotDirty then Matrix.MarkBotDirty(bot.id) end

    Matrix.Log('LAYERDIRECTIVES',
        '[HÜCRE İZOLASYON İHLALİ] Bot #%d (role=%s) yetki-disi alana (%s) erismeye calisti -- izinler DONDURULDU.',
        bot.id, bot.role, domain)
    return false
end


-- =====================================================================
-- [KATMAN 9] ÇİFT AJANLAR — arka planda düşman-finansmanlı satıcıların
-- (matrix_vendor_pool.gang_loyalty <= EnemyLoyaltyThreshold) trap house
-- konumlarını periyodik olarak sızdırması. Mevcut TriggerPropaganda
-- (heat/momentum artışı) İLE AYNI kanal kullanılır -- server/hitsquad.lua
-- ZATEN bu heat eşiğini okuyup kurye pususu tetikliyor (KATMAN 8), ikinci
-- bir ambush motoru İCAT EDİLMEZ.
--
-- NOT: satin alinan silahlara jam_accumulator enjeksiyonu ZATEN server/
-- underworld_network.lua'da (EnemyLoyaltySabotageThreshold=0.45) var --
-- 0.30 (bu esik) HER ZAMAN 0.45'in altinda oldugundan cift-ajan saticilar
-- BU MEVCUT sabotaji otomatik miras alir, ikinci bir enjeksiyon noktasi
-- İCAT EDİLMEZ.
-- =====================================================================
local function ProcessDoubleAgentLeaks()
    if not (Matrix.VendorPool and Matrix.VendorPool.Vendors) then return end
    local threshold = Config.DoubleAgent.EnemyLoyaltyThreshold or 0.30

    for vendorId, vendor in pairs(Matrix.VendorPool.Vendors) do
        if vendor.status == 'active' and (vendor.gang_loyalty or 1.0) <= threshold then
            local trapId = FindNearestTrapHouse(vendor.coords)
            if trapId and Matrix.Bureau and Matrix.Bureau.TriggerPropaganda then
                Matrix.Bureau.TriggerPropaganda(trapId)
                Matrix.Log('LAYERDIRECTIVES',
                    '[ÇİFT AJAN] Satici #%d (loyalty=%.2f) arka planda Trap #%d konumunu dusman istihbaratina sizdirdi.',
                    vendorId, vendor.gang_loyalty, trapId)
            end
        end
    end
end


CreateThread(function()
    while true do
        Wait((Config.DoubleAgent.ScanIntervalSeconds or 240) * 1000)
        local ok, err = pcall(ProcessDoubleAgentLeaks)
        if not ok then Matrix.Log('LAYERDIRECTIVES', '[HATA] ProcessDoubleAgentLeaks basarisiz (yutuldu): %s', tostring(err)) end
    end
end)


exports('GetSignalAnomalyBulletin', function(trapHouseId) return Matrix.LayerDirectives.FormatSignalAnomalyBulletin(trapHouseId) end)
exports('GetLogisticsElementBulletin', function(botId) return Matrix.LayerDirectives.FormatLogisticsElementBulletin(botId) end)
exports('IsDeviceRecovered', function(deviceId) return Matrix.LayerDirectives.IsDeviceRecovered(deviceId) end)
exports('CellIsolationGuard', function(botId, domain)
    local bot = Matrix.Bots and Matrix.Bots[tonumber(botId)]
    return Matrix.CellIsolation.Guard(bot, domain)
end)
