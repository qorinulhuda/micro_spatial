********************************************************************************
* PROJECT : EKONOMETRIKA SPASIAL REGIONAL (OLS, SAR, SDM, & SEM) DENGAN STATA
*           Simulasi Ketergantungan Spasial Upah & Infrastruktur Kab/Kota
* DATASET : data_agregat_simulasi_kabkota.dta -> data_spasial_simulasi_kabkota.dta
* AUTHOR  : Qorinul Huda
********************************************************************************

clear all
set more off
set seed 20261124

** =============================================================================
** TAHAP 1: PEMBUATAN KOORDINAT & DATASET SPASIAL BARU
** =============================================================================
	use "data_agregat_simulasi_kabkota.dta", clear

	* Membentuk koordinat bujur (lon) dan lintang (lat) sintetis per wilayah pulau
	gen double lon = 95 + (pulau - 1)*6 + rnormal(0, 1.2)
	gen double lat = -6 + mod(pulau, 2)*4 + rnormal(0, 1.0)

	la var lon "Koordinat Bujur Sintetis (Longitude)"
	la var lat "Koordinat Lintang Sintetis (Latitude)"

	* Simpan sebagai dataset baru agar dataset agregat awal tidak tertimpa
	save "data_spasial_simulasi_kabkota.dta", replace


** =============================================================================
** TAHAP 2: MATRIKS BOBOT SPASIAL (W), W*X, INSTRUMEN SPASIAL, & Y SPASIAL
** =============================================================================
	* Bersihkan variabel spasial jika skrip dijalankan ulang
	capture drop W_rls W_infra W_umk W_formal iv_sp_1 iv_sp_2 avg_wage_sp W_avg_wage_sp

	* Jalankan seluruh blok mata: ... end secara bersamaan (jangan terpotong)
	mata:
		lon = st_data(., "lon")
		lat = st_data(., "lat")
		n   = rows(lon)
		W   = J(n, n, 0)

		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (i != j) {
					dlat = (lat[j] - lat[i]) * pi() / 180
					dlon = (lon[j] - lon[i]) * pi() / 180
					a    = sin(dlat/2)^2 + cos(lat[i]*pi()/180)*cos(lat[j]*pi()/180)*sin(dlon/2)^2
					dist = 2 * 6371 * asin(sqrt(min((1, a))))
					if (dist > 0) W[i,j] = 1 / dist
				}
			}
		}

		row_s = rowsum(W)
		for (i=1; i<=n; i++) {
			if (row_s[i] > 0) W[i,.] = W[i,.] / row_s[i]
		}

		x_rls    = st_data(., "rls_kab")
		x_infra  = st_data(., "infra_kab")
		x_umk    = st_data(., "umk_riil")
		x_formal = st_data(., "share_formal")

		w_rls    = W * x_rls
		w_infra  = W * x_infra
		w_umk    = W * x_umk
		w_formal = W * x_formal

		// Instrumen spasial eksternal (tidak masuk sebagai regressor X maupun W*X)
		z1 = rnormal(n, 1, 0, 1)
		z2 = rnormal(n, 1, 0, 1)
		iv1 = W * z1
		iv2 = W * z2

		eps_sp = rnormal(n, 1, 0, 0.12)
		xb_sp  = 1.20 :+ 0.045*x_rls :+ 0.012*x_infra :+ 0.08*x_umk :+ 0.015*w_rls :+ 0.008*w_infra :+ 0.15*iv1 :+ 0.12*iv2 :+ eps_sp
		y_sp   = lusolve(I(n) - 0.42 * W, xb_sp)
		wy_sp  = W * y_sp

		st_store(., st_addvar("double", "W_rls"),         w_rls)
		st_store(., st_addvar("double", "W_infra"),       w_infra)
		st_store(., st_addvar("double", "W_umk"),         w_umk)
		st_store(., st_addvar("double", "W_formal"),      w_formal)
		st_store(., st_addvar("double", "iv_sp_1"),       iv1)
		st_store(., st_addvar("double", "iv_sp_2"),       iv2)
		st_store(., st_addvar("double", "avg_wage_sp"),   y_sp)
		st_store(., st_addvar("double", "W_avg_wage_sp"), wy_sp)
		st_matrix("W_mat", W)
	end

	la var W_rls         "Spatial Lag Rata-rata Lama Sekolah Tetangga (W*X1)"
	la var W_infra       "Spatial Lag Indeks Infrastruktur Tetangga (W*X2)"
	la var W_umk         "Spatial Lag UMK Riil Tetangga (W*X3)"
	la var W_formal      "Spatial Lag Pangsa Pekerja Formal Tetangga (W*X4)"
	la var iv_sp_1       "Instrumen Spasial Eksternal 1 (IV untuk W*Y)"
	la var iv_sp_2       "Instrumen Spasial Eksternal 2 (IV untuk W*Y)"
	la var avg_wage_sp   "Log Upah Kab/Kota dengan Efek Spasial (Y)"
	la var W_avg_wage_sp "Spatial Lag Log Upah Tetangga (W*Y)"

	save "data_spasial_simulasi_kabkota.dta", replace


** =============================================================================
** TAHAP 3: UJI MORAN'S I & ESTIMASI MODEL SPASIAL (OLS, SAR, SDM, & SEM)
** =============================================================================
	use "data_spasial_simulasi_kabkota.dta", clear

	* 1. Baseline OLS non-spasial dan hitung Global Moran's I pada residual OLS
	reg avg_wage_sp rls_kab infra_kab umk_riil share_formal
	estimates store ols_nonspasial
	predict double res_ols, residuals

	mata:
		e = st_data(., "res_ols")
		W = st_matrix("W_mat")
		n = rows(e)
		num = e' * W * e
		den = e' * e
		s0  = sum(W)
		moran_i = (n / s0) * (num / den)
		printf("Global Moran I pada residual OLS = %9.4f\n", moran_i)
	end
	drop res_ols

	* 2. Estimasi SAR (Spatial Lag of Y: W_avg_wage_sp diinstrumenkan dengan iv_sp_1 & iv_sp_2)
	ivregress 2sls avg_wage_sp rls_kab infra_kab umk_riil share_formal (W_avg_wage_sp = iv_sp_1 iv_sp_2), vce(robust)
	estimates store sar_2sls

	* 3. Estimasi SDM (Spatial Durbin: memuat X dan W*X, W_avg_wage_sp diinstrumenkan dengan iv_sp_1 & iv_sp_2)
	ivregress 2sls avg_wage_sp rls_kab infra_kab umk_riil share_formal W_rls W_infra W_umk W_formal (W_avg_wage_sp = iv_sp_1 iv_sp_2), vce(robust)
	estimates store sdm_2sls

	* 4. Estimasi SEM (Spatial Error Model via Spatial GLS)
	reg avg_wage_sp rls_kab infra_kab umk_riil share_formal
	predict double u_sem, residuals
	mata:
		u = st_data(., "u_sem")
		W = st_matrix("W_mat")
		wu = W * u
		lam = (wu' * u) / (wu' * wu)
		printf("Estimasi parameter spatial error lambda = %9.4f\n", lam)
		st_numscalar("lambda_hat", lam)
	end
	gen double y_sem_star  = avg_wage_sp - scalar(lambda_hat)*W_avg_wage_sp
	gen double x1_sem_star = rls_kab - scalar(lambda_hat)*W_rls
	gen double x2_sem_star = infra_kab - scalar(lambda_hat)*W_infra
	gen double x3_sem_star = umk_riil - scalar(lambda_hat)*W_umk
	gen double x4_sem_star = share_formal - scalar(lambda_hat)*W_formal
	reg y_sem_star x1_sem_star x2_sem_star x3_sem_star x4_sem_star, vce(robust)
	estimates store sem_gls
	drop u_sem y_sem_star x1_sem_star x2_sem_star x3_sem_star x4_sem_star

	* 5. Tabel perbandingan koefisien antar-model
	estimates table ols_nonspasial sar_2sls sdm_2sls sem_gls, b(%9.4f) se(%9.4f) stats(N r2) title("Perbandingan Model Spasial: OLS vs SAR vs SDM vs SEM")


** =============================================================================
** TAHAP 4: UJI SPILLOVER (W*X) & EFEK LANGSUNG / TIDAK LANGSUNG (SDM)
** =============================================================================
	* Uji signifikansi bersama variabel spatial lag (W*X) pada SDM
	estimates restore sdm_2sls
	test W_rls W_infra W_umk W_formal

	* Menghitung rata-rata Direct Effect, Indirect (Spillover) Effect, & Total Effect
	* menggunakan st_matrixcolstripe("e(b)") agar indeks kolom koefisien selalu tepat
	mata:
		real scalar col_pos(string scalar name) {
			string matrix cs
			real scalar k, i
			cs = st_matrixcolstripe("e(b)")
			k  = rows(cs)
			for (i=1; i<=k; i++) {
				if (cs[i, 2] == name) return(i)
			}
			return(0)
		}

		b = st_matrix("e(b)")
		c_rho  = col_pos("W_avg_wage_sp")
		c_rls  = col_pos("rls_kab")
		c_wrls = col_pos("W_rls")
		c_inf  = col_pos("infra_kab")
		c_winf = col_pos("W_infra")

		rho = b[1, c_rho]
		W   = st_matrix("W_mat")
		n   = rows(W)
		M   = lusolve(I(n) - rho * W, I(n))

		S_rls   = M * (I(n) * b[1, c_rls] + W * b[1, c_wrls])
		dir_rls = trace(S_rls) / n
		tot_rls = sum(S_rls) / n
		ind_rls = tot_rls - dir_rls

		S_inf   = M * (I(n) * b[1, c_inf] + W * b[1, c_winf])
		dir_inf = trace(S_inf) / n
		tot_inf = sum(S_inf) / n
		ind_inf = tot_inf - dir_inf

		printf("\n--- Dekomposisi Efek SDM ---\n")
		printf("rls_kab   -> Direct: %9.4f | Indirect (Spillover): %9.4f | Total: %9.4f\n", dir_rls, ind_rls, tot_rls)
		printf("infra_kab -> Direct: %9.4f | Indirect (Spillover): %9.4f | Total: %9.4f\n", dir_inf, ind_inf, tot_inf)
	end