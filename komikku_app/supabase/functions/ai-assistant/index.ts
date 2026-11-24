// Supabase Edge Function: ai-assistant
// Menangani permintaan asisten AI (chat rekomendasi dan ringkasan sinopsis) via Google Gemini 2.5 Flash
// Sesuai SRS 2.6.3, FR-AI, dan TC-11 & TC-12

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  // 1. Tangani preflight OPTIONS request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 2. Verifikasi Header Authorization (JWT Pengguna)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Permintaan tidak terautentikasi (Header Authorization tidak ada)." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Konfigurasi server Supabase belum lengkap." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "Kunci API Gemini (GEMINI_API_KEY) belum dikonfigurasi di Supabase Secrets." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Inisialisasi Supabase client dengan JWT pengguna untuk menjalankan operasi dengan RLS
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Rate Limiting: Maksimal 20 permintaan per hari per pengguna (FR-AI-08 & TC-12)
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD (UTC)

    const { data: usageData, error: usageSelectError } = await supabase
      .from("ai_usage")
      .select("count")
      .eq("user_id", user.id)
      .eq("date", today)
      .maybeSingle();

    if (usageSelectError) {
      console.error("Gagal memeriksa ai_usage:", usageSelectError);
    }

    const currentCount = usageData?.count ?? 0;
    if (currentCount >= 20) {
      return new Response(
        JSON.stringify({
          error: "Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari.",
        }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Perbarui atau sisipkan kuota pemakaian
    if (usageData) {
      const { error: updateError } = await supabase
        .from("ai_usage")
        .update({ count: currentCount + 1 })
        .eq("user_id", user.id)
        .eq("date", today);
      if (updateError) {
        console.error("Gagal memperbarui ai_usage:", updateError);
      }
    } else {
      const { error: insertError } = await supabase
        .from("ai_usage")
        .insert({ user_id: user.id, date: today, count: 1 });
      if (insertError) {
        console.error("Gagal menyisipkan ai_usage:", insertError);
      }
    }

    // 4. Parse request body
    const body = await req.json();
    const mode = body.mode || "chat"; // "chat" | "summarize"
    const message = body.message || "";
    const context = body.context;

    if (!message.trim()) {
      return new Response(
        JSON.stringify({ error: "Pesan atau sinopsis tidak boleh kosong." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Susun System Prompt & User Prompt sesuai kebutuhan (FR-AI-03, FR-AI-04, FR-AI-05)
    let systemInstruction = "";
    let userPrompt = message;

    if (mode === "summarize") {
      systemInstruction =
        "Kamu adalah asisten cerdas KomikKu yang ahli dalam merangkum sinopsis komik, manga, manhwa, dan manhua.\n" +
        "Tugasmu: Rangkum sinopsis komik yang diberikan dalam Bahasa Indonesia menjadi tepat 3 poin penting yang padat, menarik, dan mudah dipahami.\n" +
        "Gunakan format daftar bernomor atau bullet point persis seperti contoh berikut:\n" +
        "• [Poin 1: Premis utama cerita]\n" +
        "• [Poin 2: Konflik utama atau tantangan karakter]\n" +
        "• [Poin 3: Daya tarik atau keunikan cerita]\n" +
        "Jangan menambahkan pembuka atau penutup yang bertele-tele. Langsung berikan 3 poin.";
      userPrompt = `Berikut adalah sinopsis komik yang perlu diringkas:\n\n${message}`;
    } else {
      // Mode Chat
      let contextInfo = "";
      if (context) {
        const favGenres = Array.isArray(context.favorite_genres) && context.favorite_genres.length > 0
          ? context.favorite_genres.join(", ")
          : "Belum ada data";
        const recentComics = Array.isArray(context.recent) && context.recent.length > 0
          ? context.recent.map((c: any) => typeof c === "string" ? c : (c.manga_title || c.title || "")).filter(Boolean).join(", ")
          : "Belum ada data";

        contextInfo =
          `\n\nKonteks Pembaca Saat Ini:\n` +
          `- Genre Favorit: ${favGenres}\n` +
          `- Komik Terakhir Dibaca: ${recentComics}\n` +
          `Gunakan konteks di atas untuk memberikan rekomendasi yang lebih relevan dan personal jika pengguna meminta rekomendasi umum atau komik serupa.`;
      }

      systemInstruction =
        "Kamu adalah asisten KomikKu, seorang pakar komik, manga, manhwa, dan manhua yang ramah, santun, dan berpengetahuan luas.\n" +
        "Patuhi aturan-aturan berikut tanpa terkecuali:\n" +
        "1. Jawab selalu dalam Bahasa Indonesia yang singkat, ramah, dan bersahabat.\n" +
        "2. HANYA bahas topik komik, manga, manhwa, manhua, webtoon, anime, atau industri komik. Jika pengguna bertanya hal di luar komik, tolak dengan sopan dan ajak kembali berdiskusi tentang komik.\n" +
        "3. Bila memberikan rekomendasi komik, berikan maksimal 5 rekomendasi terbaik.\n" +
        "4. Setiap judul rekomendasi WAJIB ditulis dalam format satu baris per judul seperti format ini agar dapat dideteksi oleh aplikasi:\n" +
        "   Judul Komik — Alasan singkat mengapa direkomendasikan\n" +
        "   Contoh:\n" +
        "   Solo Leveling — Aksi pertarungan seru dengan sistem leveling yang adiktif.\n" +
        "   One Piece — Petualangan bajak laut yang luar biasa dengan dunia yang sangat luas.\n" +
        "5. Jangan pernah mengarang judul komik yang fiktif. Jika kamu tidak yakin, katakan bahwa kamu belum memiliki informasi tentang komik tersebut." +
        contextInfo;
    }

    // 6. Panggil Gemini 2.5 Flash API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: userPrompt }],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1024,
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error("Gemini API Error:", geminiResponse.status, errText);
      return new Response(
        JSON.stringify({
          error: `Gagal memproses permintaan AI dari penyedia layanan (Status ${geminiResponse.status}).`,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const geminiJson = await geminiResponse.json();
    const reply =
      geminiJson.candidates?.[0]?.content?.parts?.[0]?.text ??
      "Maaf, asisten tidak dapat memberikan jawaban untuk pertanyaan tersebut.";

    // 7. Kembalikan response berhasil
    return new Response(
      JSON.stringify({ reply }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (err: any) {
    console.error("Internal Error in ai-assistant:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Terjadi kesalahan internal pada server AI." }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
