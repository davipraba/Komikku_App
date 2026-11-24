-- ====================================================================
-- KomikKu Database Schema & Security (Supabase PostgreSQL)
-- Fase 2: Tabel profiles, Trigger Registrasi, dan Kebijakan RLS
-- ====================================================================

-- 1. Buat tabel public.profiles jika belum ada
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Aktifkan Row Level Security (RLS) pada tabel profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan RLS untuk profiles:
-- Pengguna hanya dapat membaca profil miliknya sendiri
DROP POLICY IF EXISTS "Pengguna dapat membaca profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna dapat membaca profil sendiri"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Pengguna hanya dapat memperbarui profil miliknya sendiri
DROP POLICY IF EXISTS "Pengguna dapat memperbarui profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna dapat memperbarui profil sendiri"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Pengguna hanya dapat menambahkan profil miliknya sendiri
DROP POLICY IF EXISTS "Pengguna dapat menyisipkan profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna dapat menyisipkan profil sendiri"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 4. Fungsi & Trigger otomatis untuk membuat profil baru saat registrasi
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
    );
    RETURN new;
END;
$$;

-- Pasang trigger ke tabel auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- Fase 5: Tabel bookstores, Kebijakan RLS, dan Data Dummy (LBS Sekitar UPN)
-- ====================================================================

-- 5. Buat tabel public.bookstores
CREATE TABLE IF NOT EXISTS public.bookstores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. Aktifkan Row Level Security (RLS) pada tabel bookstores
ALTER TABLE public.bookstores ENABLE ROW LEVEL SECURITY;

-- 7. Kebijakan RLS: Publik & Authenticated dapat membaca data toko buku (Read-Only)
DROP POLICY IF EXISTS "Semua pengguna dapat melihat data toko buku" ON public.bookstores;
CREATE POLICY "Semua pengguna dapat melihat data toko buku"
    ON public.bookstores
    FOR SELECT
    USING (true);

-- 8. Sisipkan Data Toko Buku & Perpustakaan di sekitar UPN "Veteran" Yogyakarta
INSERT INTO public.bookstores (name, lat, lng, address) VALUES
('Perpustakaan UPN "Veteran" Yogyakarta (Kampus 1)', -7.76185, 110.40915, 'Jl. SWK 104 (Lingkar Utara), Condongcatur, Sleman'),
('Toko Buku Togamas Affandi Gejayan', -7.77125, 110.38920, 'Jl. Affandi (Gejayan) No. 5, Caturtunggal, Depok, Sleman'),
('Gramedia Plaza Ambarrukmo', -7.78280, 110.40110, 'Plaza Ambarrukmo Lt. 2, Jl. Laksda Adisucipto, Sleman'),
('Periplus Bookstore Mal Ambarrukmo', -7.78275, 110.40125, 'Plaza Ambarrukmo GF-A25, Jl. Laksda Adisucipto, Sleman'),
('Toko Buku Social Agency Baru (SAB) Kaliurang', -7.75380, 110.38090, 'Jl. Kaliurang KM. 5 No. 34, Caturtunggal, Sleman'),
('Perpustakaan Daerah Grhatama Pustaka DIY', -7.79870, 110.40790, 'Jl. Janti No. 238, Wonocatur, Banguntapan, Bantul'),
('Gramedia Sudirman Yogyakarta', -7.78290, 110.37520, 'Jl. Jend. Sudirman No. 54-56, Kotabaru, Yogyakarta'),
('Perpustakaan Kota Yogyakarta Kotabaru', -7.78650, 110.37350, 'Jl. Suroto No. 9, Kotabaru, Gondokusuman, Yogyakarta')
ON CONFLICT DO NOTHING;

-- ====================================================================
-- Fase 6: Tabel favorites, reading_history, reviews & RLS Cloud Sync
-- ====================================================================

-- 9. Tabel favorites (Sinkronisasi Cloud)
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    manga_id TEXT NOT NULL,
    title TEXT NOT NULL,
    cover_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
    CONSTRAINT unique_user_manga_favorite UNIQUE (user_id, manga_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pengguna dapat mengelola favorit sendiri" ON public.favorites;
CREATE POLICY "Pengguna dapat mengelola favorit sendiri"
    ON public.favorites
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 10. Tabel reading_history (Sinkronisasi Cloud)
CREATE TABLE IF NOT EXISTS public.reading_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    manga_id TEXT NOT NULL,
    manga_title TEXT NOT NULL,
    cover_url TEXT,
    chapter_id TEXT NOT NULL,
    chapter_label TEXT NOT NULL,
    last_page INTEGER DEFAULT 1 NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_user_manga_history UNIQUE (user_id, manga_id)
);

ALTER TABLE public.reading_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pengguna dapat mengelola riwayat sendiri" ON public.reading_history;
CREATE POLICY "Pengguna dapat mengelola riwayat sendiri"
    ON public.reading_history
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 11. Tabel reviews (Rating 1..5 & Ulasan Komunitas)
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    manga_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_user_manga_review UNIQUE (user_id, manga_id),
    CONSTRAINT fk_review_profile FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS Reviews:
-- Semua pengguna terautentikasi dapat membaca ulasan
DROP POLICY IF EXISTS "Semua pengguna dapat melihat ulasan" ON public.reviews;
CREATE POLICY "Semua pengguna dapat melihat ulasan"
    ON public.reviews
    FOR SELECT
    USING (true);

-- Pengguna hanya dapat menambah ulasan milik sendiri
DROP POLICY IF EXISTS "Pengguna dapat menyisipkan ulasan sendiri" ON public.reviews;
CREATE POLICY "Pengguna dapat menyisipkan ulasan sendiri"
    ON public.reviews
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Pengguna hanya dapat memperbarui ulasan milik sendiri
DROP POLICY IF EXISTS "Pengguna dapat memperbarui ulasan sendiri" ON public.reviews;
CREATE POLICY "Pengguna dapat memperbarui ulasan sendiri"
    ON public.reviews
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Pengguna hanya dapat menghapus ulasan milik sendiri
DROP POLICY IF EXISTS "Pengguna dapat menghapus ulasan sendiri" ON public.reviews;
CREATE POLICY "Pengguna dapat menghapus ulasan sendiri"
    ON public.reviews
    FOR DELETE
    USING (auth.uid() = user_id);

-- ====================================================================
-- Fase 7: Tabel ai_usage (Rate Limit Edge Function Asisten AI)
-- ====================================================================

-- 12. Tabel ai_usage (Maks 20 permintaan per hari per pengguna)
CREATE TABLE IF NOT EXISTS public.ai_usage (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE NOT NULL,
    count INTEGER DEFAULT 1 NOT NULL,
    PRIMARY KEY (user_id, date)
);

ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pengguna dapat mengelola ai_usage sendiri" ON public.ai_usage;
CREATE POLICY "Pengguna dapat mengelola ai_usage sendiri"
    ON public.ai_usage
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);



