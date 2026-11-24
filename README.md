# Dinamika Upah Rata-Rata, Infrastruktur, dan Ketergantungan Spasial Antar-Kabupaten/Kota di Indonesia

> *Pendekatan Ekonometrika Spasial Regional (Global Moran's I, OLS, SAR, SDM, dan SEM) Berbasis Simulasi Data Agregat Kabupaten/Kota ($N = 100$) di Stata*

**Penyusun:** Qorinul Huda

---

## Ringkasan Studi Kasus

Studi kasus ini menelaah bagaimana tingkat upah rata-rata kabupaten/kota (`avg_wage_sp`) dipengaruhi oleh karakteristik ekonomi dan pembangunan daerah—seperti rata-rata lama sekolah (`rls_kab`), indeks infrastruktur (`infra_kab`), upah minimum riil (`umk_riil`), serta pangsa pekerja formal (`share_formal`)—sekaligus memperhitungkan keterkaitan geografis dan efek limpahan (*spatial spillover*) antarwilayah berdekatan pada $N = 100$ kabupaten/kota yang terbagi ke dalam beberapa klaster wilayah (`pulau`).

Untuk menjaga keutuhan data dasar, koordinat geografis sintetis (`lon`, `lat`), matriks pembobot jarak terbalik (*Inverse Distance Weighting*, $W$) yang dinormalisasi baris, *spatial lag* (`W*X`), variabel instrumen spasial, serta keluaran spasial (`avg_wage_sp` dan `W_avg_wage_sp`) disimpan ke dalam dataset baru **`data_spasial_simulasi_kabkota.dta`** tanpa mengubah **`data_agregat_simulasi_kabkota.dta`**.

---

## Struktur Repositori

| Berkas | Deskripsi |
| :--- | :--- |
| `Analisis spasial.do` | Skrip utama Stata untuk membangkitkan koordinat dan matriks $W$ di Mata, menyimpan dataset spasial baru, menghitung Moran's I, mengestimasi OLS, SAR, SDM, dan SEM, serta mengurai *Direct*, *Indirect (Spillover)*, dan *Total Effects*. |
| `data_agregat_simulasi_kabkota.dta` | Dataset awal simulasi agregat tingkat kabupaten/kota ($N = 100$) yang dipertahankan keasliannya. |
| `data_spasial_simulasi_kabkota.dta` | Dataset turunan berformat `.dta` yang memuat koordinat sintetis, variabel *spatial lag*, instrumen spasial, dan variabel upah dengan efek spasial. |
| `_W_idw.csv` | Berkas pendukung matriks pembobot spasial jarak terbalik (*Inverse Distance Weighting*). |
| `README.md` | Dokumentasi studi kasus, metodologi, struktur berkas, dan panduan reproduktibilitas proyek. |

---

## Kerangka Metodologi Ekonometrika Spasial

1. **Matriks Pembobot Spasial ($W$) & Diagnostik Autokorelasi**
   * Jarak antarkabupaten/kota dihitung dari koordinat bujur (`lon`) dan lintang (`lat`) menggunakan jarak Haversine (km) di dalam **Mata**, lalu diubah menjadi bobot *inverse distance* dan dinormalisasi per baris ($\sum_j w_{ij} = 1$).
   * Keberadaan klastering spasial diuji melalui nilai **Global Moran's I** pada residual regresi OLS awal.

2. **Spesifikasi Model Empiris**
   * **OLS (*Ordinary Least Squares*)**: Acuan baseline non-spasial tanpa memperhitungkan ketergantungan spasial.
   * **SAR (*Spatial Autoregressive Model*)**: Menangkap ketergantungan upah kabupaten/kota terhadap upah daerah tetangga ($\rho W Y$), diestimasi dengan `ivregress 2sls` menggunakan instrumen spasial eksternal.
   * **SDM (*Spatial Durbin Model*)**: Memasukkan variabel independen ($X$) sekaligus *spatial lag* variabel independen ($W X$) dan *spatial lag* variabel dependen ($W Y$) untuk menguji efek limpahan langsung maupun tidak langsung.
   * **SEM (*Spatial Error Model*)**: Menangkap keterkaitan spasial pada guncangan/faktor tak teramati antarwilayah ($\lambda W u$) melalui transformasi *Spatial GLS*.

3. **Dekomposisi Efek Spasial pada SDM**
   * **Direct Effect**: Dampak perubahan variabel di suatu kabupaten/kota terhadap upah di kabupaten/kota itu sendiri (termasuk efek umpan balik spasial).
   * **Indirect Effect (*Spillover*)**: Dampak limpahan perubahan variabel di suatu kabupaten/kota terhadap upah kabupaten/kota tetangga.
   * **Total Effect**: Jumlah keseluruhan dari *Direct Effect* dan *Indirect Effect*.

---

## Panduan Reproduktibilitas

1. Tempatkan seluruh berkas (`Analisis spasial.do`, `data_agregat_simulasi_kabkota.dta`, `data_spasial_simulasi_kabkota.dta`, dan `_W_idw.csv`) dalam satu direktori kerja yang sama di Stata.
2. Atur direktori kerja aktif di Stata menggunakan perintah `cd`, lalu buka **`Analisis spasial.do`**.
3. Jalankan skrip secara berurutan atau sekaligus (*one-click run*), dan pastikan setiap blok `mata: ... end` dieksekusi penuh dari baris `mata:` hingga `end`.

---

*Penyusun: Qorinul Huda — Dokumentasi Studi Kasus & Ekonometrika Spasial Regional (Stata).*
