import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requestsByIp = new Map<string, { count: number; resetAt: number }>();
const limit = 8;
const windowMs = 60 * 60 * 1000;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function slugify(value: string) {
  return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 90);
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Используй POST-запрос." }, 405);

  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const now = Date.now();
  const bucket = requestsByIp.get(ip);
  if (bucket && bucket.resetAt > now && bucket.count >= limit) {
    return json({ error: "Лимит генераций достигнут. Попробуй ещё раз через час." }, 429);
  }
  requestsByIp.set(ip, !bucket || bucket.resetAt <= now
    ? { count: 1, resetAt: now + windowMs }
    : { ...bucket, count: bucket.count + 1 });

  let word: string;
  try {
    const body = await request.json();
    word = typeof body?.word === "string" ? body.word.trim() : "";
  } catch {
    return json({ error: "Не удалось прочитать слово." }, 400);
  }
  if (!word || word.length > 80 || /[\r\n<>]/.test(word)) {
    return json({ error: "Введи одно испанское слово или короткое выражение (до 80 символов)." }, 400);
  }

  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!openAiKey || !supabaseUrl || !serviceRoleKey) {
    return json({ error: "Сервер генерации не настроен: администратору нужно добавить секреты OpenAI и Supabase." }, 503);
  }

  try {
    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openAiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        temperature: 0.3,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: "Ты создаёшь учебные карточки для изучающего современный испанский Испании и русского носителя. Ответь только JSON-объектом с ключами display, translation, pronunciation, example, exampleTranslation, cloze, clozeTranslation. display — нормативная словарная форма; для существительного добавь правильный артикль el/la, для множественного числа los/las, для остальных частей речи не добавляй артикль. translation — краткий наиболее частый перевод на русский. pronunciation — IPA для кастильского испанского (Испания), в квадратных скобках. example — естественное короткое предложение на испанском из повседневной жизни, где слово/выражение употреблено в подходящей форме. exampleTranslation — точный естественный русский перевод примера. cloze — то же или другое естественное предложение, где целевое слово/выражение заменено ровно на _____. clozeTranslation — русский перевод полного предложения с целевым словом. Не используй HTML или Markdown."
          },
          { role: "user", content: `Подготовь карточки для испанского слова или выражения: ${word}` },
        ],
      }),
    });
    const aiData = await aiResponse.json();
    if (!aiResponse.ok) {
      console.error("OpenAI request failed", aiResponse.status, aiData?.error?.type);
      return json({ error: "ИИ не смог подготовить карточки. Попробуй ещё раз." }, 502);
    }

    const raw = aiData?.choices?.[0]?.message?.content;
    const generated = typeof raw === "string" ? JSON.parse(raw) : null;
    const fields = ["display", "translation", "pronunciation", "example", "exampleTranslation", "cloze", "clozeTranslation"];
    if (!generated || fields.some((field) => typeof generated[field] !== "string" || !generated[field].trim())) {
      throw new Error("Invalid generated card data");
    }

    const slug = slugify(word) || crypto.randomUUID();
    const category = `AI word · ${generated.display}`;
    const cards = [
      {
        type: "Recognition",
        card_id: `ai-word-${slug}-recognition`,
        front: generated.display,
        back: `${generated.translation}\n\nПример: ${generated.example}\nПеревод: ${generated.exampleTranslation}\nПроизношение: ${generated.pronunciation}`,
        category: `${category} · Recognition`,
      },
      {
        type: "Recall",
        card_id: `ai-word-${slug}-recall`,
        front: generated.translation,
        back: `${generated.display}\n\nПроизношение: ${generated.pronunciation}\nПример: ${generated.example}\nПеревод: ${generated.exampleTranslation}`,
        category: `${category} · Recall`,
      },
      {
        type: "Cloze",
        card_id: `ai-word-${slug}-cloze`,
        front: `${generated.cloze}\n\nПеревод: ${generated.clozeTranslation}`,
        back: `${generated.display.replace(/^(el|la|los|las)\s+/i, "")}\n\nПроизношение: ${generated.pronunciation}`,
        category: `${category} · Cloze`,
      },
    ];

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { error } = await supabase.rpc("add_generated_word_cards", {
      p_word: word,
      p_cards: cards,
    });
    if (error) {
      console.error("Card insert failed", error.code);
      throw new Error("Не удалось сохранить карточки в общей колоде.");
    }
    return json({ word: generated, cards: cards.map(({ type, card_id }) => ({ type, card_id })) });
  } catch (error) {
    console.error("Word generation failed", error instanceof Error ? error.message : "unknown");
    return json({ error: error instanceof Error && error.message.includes("сохранить")
      ? error.message
      : "Не удалось создать карточки. Проверь слово и повтори попытку." }, 500);
  }
});
