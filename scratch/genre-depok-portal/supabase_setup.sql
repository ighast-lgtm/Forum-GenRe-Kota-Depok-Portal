-- =========================================================================
-- SQL MIGRATION & SEED DATA SUPABASE: PORTAL FORUM GENRE KOTA DEPOK
-- Menyiapkan Skema Database Realtime & Akun Otomatis 32+ Pengurus Resmi
-- =========================================================================

-- 1. EXTENSION & SCHEMA DASAR
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL PROFIL PENGURUS (TERHUBUNG KE AUTH.USERS)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    nama_lengkap TEXT NOT NULL,
    jabatan TEXT NOT NULL,
    bidang_divisi TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('inti', 'kabid', 'kadiv', 'staff')),
    avatar TEXT DEFAULT '👤',
    telepon_wa TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABEL SURAT-MENYURAT DINAS
CREATE TABLE IF NOT EXISTS public.surat (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nomor_surat TEXT NOT NULL,
    jenis TEXT NOT NULL,
    perihal TEXT NOT NULL,
    pemohon_id UUID REFERENCES public.profiles(id),
    pemohon_nama TEXT NOT NULL,
    divisi TEXT NOT NULL,
    tujuan TEXT NOT NULL,
    keterangan TEXT,
    urgensi TEXT DEFAULT 'Sedang',
    status TEXT DEFAULT 'Menunggu Review Kabid',
    file_pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABEL REIMBURSEMENT
CREATE TABLE IF NOT EXISTS public.reimburse (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proker TEXT NOT NULL,
    pemohon_id UUID REFERENCES public.profiles(id),
    pemohon_nama TEXT NOT NULL,
    divisi TEXT NOT NULL,
    nominal BIGINT NOT NULL,
    keterangan TEXT,
    bank TEXT NOT NULL,
    rekening TEXT NOT NULL,
    status TEXT DEFAULT 'Menunggu Approval Bendahara',
    foto_struk_url TEXT,
    bukti_transfer_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABEL BUKU KAS BESAR (MUTASI MASUK & KELUAR)
CREATE TABLE IF NOT EXISTS public.kas_mutasi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tgl DATE NOT NULL DEFAULT CURRENT_DATE,
    deskripsi TEXT NOT NULL,
    jenis TEXT NOT NULL CHECK (jenis IN ('Masuk', 'Keluar')),
    nominal BIGINT NOT NULL,
    kategori TEXT NOT NULL,
    sumber_dana TEXT NOT NULL,
    dicatat_oleh TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABEL PAPAN PENGUMUMAN & KEHADIRAN
CREATE TABLE IF NOT EXISTS public.pengumuman (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    judul TEXT NOT NULL,
    kategori TEXT NOT NULL CHECK (kategori IN ('Urgent', 'Umum', 'Kecamatan')),
    target TEXT NOT NULL,
    isi TEXT NOT NULL,
    penulis TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.pengumuman_kehadiran (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pengumuman_id UUID REFERENCES public.pengumuman(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    confirmed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(pengumuman_id, user_id)
);

-- 7. TABEL TIKET REQUEST INFORMASI ANTARBIDANG
CREATE TABLE IF NOT EXISTS public.tiket_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    judul TEXT NOT NULL,
    pemohon_id UUID REFERENCES public.profiles(id),
    pemohon_nama TEXT NOT NULL,
    divisi_asal TEXT NOT NULL,
    target_bidang TEXT NOT NULL,
    prioritas TEXT DEFAULT 'Sedang',
    deadline DATE,
    deskripsi TEXT NOT NULL,
    respons TEXT,
    status TEXT DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Selesai')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================================
-- AKTIFKAN FITUR REALTIME PADA SUPABASE
-- =========================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.surat;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reimburse;
ALTER PUBLICATION supabase_realtime ADD TABLE public.kas_mutasi;
ALTER PUBLICATION supabase_realtime ADD TABLE public.pengumuman;
ALTER PUBLICATION supabase_realtime ADD TABLE public.pengumuman_kehadiran;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tiket_info;

-- =========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reimburse ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kas_mutasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengumuman ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengumuman_kehadiran ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tiket_info ENABLE ROW LEVEL SECURITY;

-- Kebijakan Profil: Semua yang terautentikasi bisa membaca daftar profil
CREATE POLICY "Semua pengurus dapat melihat profil" ON public.profiles FOR SELECT TO authenticated USING (true);

-- Kebijakan Kas Mutasi: Hanya Pengurus Inti (level 'inti') yang dapat melihat dan mengisi kas
CREATE POLICY "Hanya Pengurus Inti dapat melihat buku kas" ON public.kas_mutasi FOR SELECT TO authenticated 
USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.level = 'inti')
);

CREATE POLICY "Hanya Pengurus Inti dapat menambah mutasi kas" ON public.kas_mutasi FOR INSERT TO authenticated 
WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.level = 'inti')
);

-- =========================================================================
-- DAFTAR AKUN 32+ PENGURUS RESMI FORUM GENRE KOTA DEPOK (PRIMARY SHEET)
-- Siap di-import / didaftarkan langsung ke Supabase Auth
-- Default Password Awal: GenReDepok2026!
-- =========================================================================

/*
DAFTAR KREDENSIAL LOGIN PENGURUS:
-----------------------------------------------------------------------------------------------------------------------------
No | Nama Lengkap                  | Jabatan                             | Email Akun                    | Default Password
-----------------------------------------------------------------------------------------------------------------------------
1  | Muhammad Ighasta Mughis       | Ketua Umum                          | ketua@genredepok.or.id        | GenReDepok2026!
2  | Muhamad Arfan                 | Wakil Ketua Umum                    | wakil@genredepok.or.id        | GenReDepok2026!
3  | Raihan Satria Elezar          | Sekretaris Umum                     | sekretaris@genredepok.or.id   | GenReDepok2026!
4  | Nazwa Zahira                  | Bendahara Controller                | bendahara1@genredepok.or.id   | GenReDepok2026!
5  | Tiara Maulidia                | Bendahara Treasure (BUMF)           | bendahara2@genredepok.or.id   | GenReDepok2026!
6  | Roidah A'isyi Shofwah         | Kepala Bidang Internal              | kabid.internal@genredepok.or.id| GenReDepok2026!
7  | Agnia Khumaira                | Kepala Bidang Eksternal             | kabid.eksternal@genredepok.or.id| GenReDepok2026!
8  | Teuku Andika Jalaluddin Rumi  | Kepala Bidang Branding              | kabid.branding@genredepok.or.id| GenReDepok2026!
9  | Muhammad Fauzan Al-Anshori    | Kadiv Program Reguler               | fauzan.reguler@genredepok.or.id| GenReDepok2026!
10 | Fathir Muhammad Ramadhan      | Kadiv Program Non-Reguler           | fathir.nonreg@genredepok.or.id | GenReDepok2026!
11 | Muhamad Rizkan H.             | Kadiv Forum GenRe Kecamatan         | rizkan.kecamatan@genredepok.or.id| GenReDepok2026!
12 | Melani Sofyan Putri           | Kadiv Duta GenRe                    | melani.duta@genredepok.or.id  | GenReDepok2026!
13 | Ade Rifki Perdian             | Kadiv PIK-R                         | ade.pikr@genredepok.or.id     | GenReDepok2026!
14 | Muhammad Diva                 | Kadiv Public Relation               | diva.pr@genredepok.or.id      | GenReDepok2026!
15 | Allya Nurul Febyana           | Kadiv Social Media                  | allya.sosmed@genredepok.or.id | GenReDepok2026!
16 | Annisa Revy Alifiah           | Kadiv Design                        | annisa.design@genredepok.or.id| GenReDepok2026!
17 | Plt. Koordinator              | Kadiv Video Editor                  | kadiv.video@genredepok.or.id  | GenReDepok2026!
18 | Radit                         | Staff Divisi Program Reguler        | radit@genredepok.or.id        | GenReDepok2026!
19 | Rayya                         | Staff Divisi Program Reguler        | rayya@genredepok.or.id        | GenReDepok2026!
20 | Fairuz                        | Staff Divisi Program Reguler        | fairuz@genredepok.or.id       | GenReDepok2026!
21 | Darlo                         | Staff Divisi Non-Reguler            | darlo@genredepok.or.id        | GenReDepok2026!
22 | Tius                          | Staff Divisi Non-Reguler            | tius@genredepok.or.id         | GenReDepok2026!
23 | Ahmad Abidzahr                | Staff Divisi Non-Reguler            | abidzahr@genredepok.or.id     | GenReDepok2026!
24 | Sahara Ramadhani              | Staff Divisi Non-Reguler            | sahara@genredepok.or.id       | GenReDepok2026!
25 | Frida Fatma Salsabila         | Staff Divisi Forum GenRe Kec        | frida@genredepok.or.id        | GenReDepok2026!
26 | Sinta Khairunisa              | Staff Divisi Forum GenRe Kec        | sinta@genredepok.or.id        | GenReDepok2026!
27 | Muhammad Shidqi Fadhali       | Staff Divisi Forum GenRe Kec        | shidqi@genredepok.or.id       | GenReDepok2026!
28 | Alya Citra Lestari            | Staff Divisi Duta GenRe             | alya.duta@genredepok.or.id    | GenReDepok2026!
29 | Khalimatussaqdiah             | Staff Divisi Duta GenRe             | khalima@genredepok.or.id      | GenReDepok2026!
30 | Natasya Wulandari Priyanto    | Staff Divisi PIK-R                  | natasya@genredepok.or.id      | GenReDepok2026!
31 | Sulthon Prawirotomo           | Staff Divisi PIK-R                  | sulthon@genredepok.or.id      | GenReDepok2026!
32 | Raihan Sukmajaya              | Staff Divisi Public Relation        | raihan.pr@genredepok.or.id    | GenReDepok2026!
33 | A'idah Husniyah               | Staff Divisi Public Relation        | aidah@genredepok.or.id        | GenReDepok2026!
34 | Nur Anisah                    | Staff Divisi Public Relation        | nur.anisah@genredepok.or.id   | GenReDepok2026!
35 | Muhammad Faza                 | Staff Divisi Social Media           | faza@genredepok.or.id         | GenReDepok2026!
36 | Ahmad Kafka                   | Staff Divisi Social Media           | kafka@genredepok.or.id        | GenReDepok2026!
37 | Siti Nur Faizah               | Staff Divisi Design                 | faizah@genredepok.or.id       | GenReDepok2026!
38 | Adrian Saputra Kaban          | Staff Divisi Video Editor           | adrian.video@genredepok.or.id | GenReDepok2026!
-----------------------------------------------------------------------------------------------------------------------------
*/
