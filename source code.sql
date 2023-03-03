CREATE TABLE musteri.tb_musteri (
  id BIGSERIAL,
  durum_id INTEGER DEFAULT 0 NOT NULL,
  musteri_tipi_id INTEGER NOT NULL,
  kayit_tarihi TIMESTAMP(6) WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  kayit_kullanici INTEGER DEFAULT 1 NOT NULL,
  veri_isleme_izni BOOLEAN DEFAULT false NOT NULL,
  CONSTRAINT tb_musteri_pkey PRIMARY KEY(id)
)
WITH (oids = false);


CREATE TABLE musteri.tb_nufus_data (
  id SERIAL,
  uyruk_id INTEGER DEFAULT 1 NOT NULL,
  kimlik_no VARCHAR(20),
  ad VARCHAR(70) DEFAULT ' '::character varying NOT NULL,
  soyad VARCHAR(70) DEFAULT ' '::character varying NOT NULL,
  dogum_tarihi DATE,
  baba_adi VARCHAR(70),
  anne_adi VARCHAR(70),
  cinsiyet_id INTEGER,
  dogum_yeri TEXT,
  kimlik_tipi_id SMALLINT DEFAULT 2,
  kimlik_seri_no VARCHAR(20)
)
WITH (oids = false);

CREATE TABLE musteri.tb_musteri_bireysel (
  id BIGSERIAL,
  musteri_id BIGINT NOT NULL,
  nufus_id BIGINT NOT NULL,
  CONSTRAINT tb_bireysel_musteri_id_key UNIQUE(musteri_id),
  CONSTRAINT tb_bireysel_pkey PRIMARY KEY(id),
  CONSTRAINT tb_bireysel_fk_nufus_id FOREIGN KEY (nufus_id)
    REFERENCES musteri.tb_nufus_data(id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT tb_musteri_bireysel_fk FOREIGN KEY (musteri_id)
    REFERENCES musteri.tb_musteri(id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


CREATE TABLE musteri.tb_musteri_iletisim (
  id BIGSERIAL,
  musteri_id BIGINT NOT NULL,
  iletisim_tipi_id INTEGER NOT NULL,
  deger VARCHAR(50) NOT NULL
)
WITH (oids = false);


/*Gerçek, Tüzel, Kamu  */
CREATE TABLE musteri.tb_musteri_tipi (
  id INTEGER NOT NULL,
  musteri_tipi VARCHAR(50) NOT NULL,
  etiket VARCHAR(50)
)
WITH (oids = false);

/*Ev Telefonu, Cep Telefonu, E-Posta, vb..*/
CREATE TABLE musteri.tb_iletisim_tipi (
  id INTEGER NOT NULL,
  iltesim_tipi VARCHAR(50) NOT NULL,
  format VARCHAR(50),
  hata_mesaji VARCHAR(100),
  etiket VARCHAR(50)
)
WITH (oids = false);



CREATE TABLE ktv.tb_musteri_hizmet (
  id BIGSERIAL,
  musteri_id BIGINT NOT NULL,
  hizmet_turu INTEGER,  /* Kablo tv, Internet, Vsat*/
  hizmet_durumu_id INTEGER DEFAULT 1,
  hizmet_no VARCHAR(15) NOT NULL,
  abonelik_tarihi TIMESTAMP(0)
  aciklama VARCHAR(20),
  arandi boolean DEFAULT False,
  CONSTRAINT tb_musteri_hizmet_pkey PRIMARY KEY(id)
)
WITH (oids = false);






Soru 1 )
    Müşterilerin Adı, Soyadı,  Iletişim (Telfon,Mail vb olan tüm bilsis) ve aldığı tün hizmetler tek satırda gelecek şekilde liste oluşturlması


Müsteri bazlı Hizmet sayısı değişe bilir. Örneğin 1 veya 5 adet olabilir. ne varsa hepsini yazacak
Müsteri bazlı İletişim sayısı değişe bilir. Örneğin telefon,mail vb.. olabilir. ne varsa hepsini yazacak
----------------------------------------------------------------------
Müşteri No  | Adı  Soyadı | Aldığı Hizmetler  | İletişim bilgileri |
----------------------------------------------------------------------
            |             | Tüm Hizmetler     | Tüm Bilgileri      |
            |             | sabit değil       | Yanyana            |
----------------------------------------------------------------------
            |             |                   |                    |
----------------------------------------------------------------------
            |             |                   |                    |
----------------------------------------------------------------------

Soru 2)
    Son bir haftada  gün bazlı kaç kişi abone olmuş listesi

----------------------------------------------------------------------
Paztersi | Salı | Çarşamba | Perşembe | Cuma | C.Tesi | Pazar  |
----------------------------------------------------------------------
XX Adet  |X Adet|XX Adet   |XX Adet   |X Adet|XX Adet |XX Adet  |
----------------------------------------------------------------------

Soru 3)

Çağrı merkezimizde 300 adet personel bulunmaktadır. Bu personel eş zamanlı olarak bir gün önce sisteme dahil olan müşterilere hoşgeldin araması yapması istenmektedir.
Bunun için bir önceki gün hizmet kaydı olan rasgele 10 adet kayıt her bir personelin önüne gelecek. Bu işlem sırasında gelen kayıtların hizmet bilgisi üzerinde buluna arandi alanı True olarka işaretlenecek.
Ayrıca  bir müşteri tek bir personelin önüne düşecek. çifte arama yapılmayacak.

Listede Müşterinin Adı, Soyadı, Telefon numarası(Cep veya Sabit), hizmet türü bilgisi bulunmalıdır.





------------------------------------------------------------
cevap-1
------------------------------------------------------------
SELECT
    ad,
    soyad,
    deger
FROM
    tb_musteri_iletisim
INNER JOIN tb_nufus_data
    ON tb_nufus_data.id= tb_musteri_iletisim.musteri_id;
------------------------------------------------------------
------------------------------------------------------------
  m.id,
  nd.ad,
  nd.soyad,
  array_to_string(array_agg(mh.hizmet_turu||' - '||mh.hizmet_no)OVER (PARTITION BY m.id), ', ') AS Hizmetler,
  mi1.iletisim
 from
musteri.tb_musteri m
left join  musteri.tb_musteri_bireysel  mb on mb.musteri_id = m.id
left join musteri.tb_nufus_data nd on nd.id = mb.nufus_id
left join musteri.tb_musteri_hizmet mh on mh.musteri_id = m.id
left join (

Select DISTINCT
mi.musteri_id, array_to_string(array_agg(mi.iletisim_tipi_id||' - '||mi.deger)OVER (PARTITION BY mi.musteri_id), ', ') AS iletisim
 from
musteri.tb_musteri_iletisim mi ) as mi1  on mi1.musteri_id = m.id
------------------------------------------------------------
cevap-2
------------------------------------------------------------
SELECT
       to_char(kayit_tarihi, 'day')
         AS  Son_Bir_Hafta_Kayitlari,
       COUNT(id) AS Kayit_Sayisi
FROM tb_musteri
WHERE kayit_tarihi >= NOW() - interval '7 day'
GROUP BY to_char(kayit_tarihi, 'day');
------------------------------------------------------------
------------------------------------------------------------
CREATE EXTENSION tablefunc;
Select *
from crosstab(
$$
    SELECT
       to_char(kayit_tarihi, 'day')
       AS  Son_Bir_Hafta_Kayitlari,
       COUNT(id) AS Kayit_Sayisi 
FROM tb_musteri
WHERE kayit_tarihi >= NOW() - interval '7 day'
GROUP BY to_char(kayit_tarihi, 'day');
    $$
) AS ct ("Adetler" text,
"Pazartesi" bigint, "Salı" bigint,
"Çarşamba" bigint,"Perşembe" bigint,
"Cuma" bigint,"Cumartesi" bigint,"Pazar" bigint);
------------------------------------------------------------
cevap-3
------------------------------------------------------------

WITH istenilen AS
(
    SELECT
      mh.musteri_id,
      md.ad,
      md.soyad,
      mi.deger,
      mh.hizmet_turu,
      mh.arandi
     
     
FROM tb_nufus_data md
INNER JOIN tb_musteri_iletisim mi
    ON md.id = mi.musteri_id
INNER JOIN tb_musteri_hizmet mh
    ON mi.musteri_id = mh.musteri_id
    WHERE mh.abonelik_tarihi >= CURRENT_DATE - interval '7 day'
    AND mh.arandi = '0'
    ORDER BY RANDOM() LIMIT 1
    FOR UPDATE
  )  
    UPDATE tb_musteri_hizmet mh  
    SET arandi = '1'
    FROM istenilen ist
    WHERE ist.musteri_id = mh.id
    returning * ;
    






