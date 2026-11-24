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
    const openAiUrl = "https://api.openai.com/v1/chat/completions";
    const openAiRequestBody = {
      model: "gpt-4.1-mini",
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "anki_cards",
          strict: true,
          schema: {
            type: "object",
            properties: {
              recognition: {
                type: "object",
                properties: { front: { type: "string" }, back: { type: "string" } },
                required: ["front", "back"],
                additionalProperties: false,
              },
              recall: {
                type: "object",
                properties: { front: { type: "string" }, back: { type: "string" } },
                required: ["front", "back"],
                additionalProperties: false,
              },
              cloze: {
                type: "object",
                properties: { front: { type: "string" }, back: { type: "string" } },
                required: ["front", "back"],
                additionalProperties: false,
              },
            },
            required: ["recognition", "recall", "cloze"],
            additionalProperties: false,
          },
        },
      },
      messages: [
        { role: "user", content: `создай три типа anki style карточек для слова "${word}":

1. **Recognition** — испанское слово → вспомнить перевод.
2. **Recall** — русский перевод → вспомнить испанское слово.
3. **Cloze** — предложение на испанском с пропущенным изучаемым словом и переводом предложения → вспомнить и вставить слово.

Например, для слова \`cielo\`:

- Recognition: \`el cielo\` → \`небо\`.
- Recall: \`небо\` → \`el cielo\`.
- Cloze: \`Hoy el _____ está despejado.\` → \`cielo\`.` },
      ],
    };
    console.info("OpenAI request", JSON.stringify({
      method: "POST",
      url: openAiUrl,
      body: openAiRequestBody,
    }));

    const requestStartedAt = Date.now();
    const aiResponse = await fetch(openAiUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${openAiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify(openAiRequestBody),
    });
    const responseText = await aiResponse.text();
    let aiData: any;
    try {
      aiData = JSON.parse(responseText);
    } catch {
      aiData = { raw: responseText };
    }
    console.info("OpenAI response", JSON.stringify({
      status: aiResponse.status,
      requestId: aiResponse.headers.get("x-request-id"),
      durationMs: Date.now() - requestStartedAt,
      body: aiData,
    }));
    if (!aiResponse.ok) {
      console.error("OpenAI request failed", aiResponse.status, aiData?.error?.type);
      return json({ error: "ИИ не смог подготовить карточки. Попробуй ещё раз." }, 502);
    }

    const choice = aiData?.choices?.[0];
    if (choice?.message?.refusal) {
      throw new Error("OpenAI refused to generate cards");
    }
    if (choice?.finish_reason === "length") {
      throw new Error("OpenAI response was incomplete");
    }
    const raw = choice?.message?.content;
    const generated = typeof raw === "string" ? JSON.parse(raw) : null;
    const cardTypes = ["recognition", "recall", "cloze"];
    if (!generated || cardTypes.some((type) =>
      typeof generated[type]?.front !== "string" || !generated[type].front.trim() ||
      typeof generated[type]?.back !== "string" || !generated[type].back.trim()
    )) {
      throw new Error("Invalid generated card data");
    }

    const slug = slugify(word) || crypto.randomUUID();
    const category = `AI word · ${word}`;
    const cards = [
      {
        type: "Recognition",
        card_id: `ai-word-${slug}-recognition`,
        front: generated.recognition.front,
        back: generated.recognition.back,
        category: `${category} · Recognition`,
      },
      {
        type: "Recall",
        card_id: `ai-word-${slug}-recall`,
        front: generated.recall.front,
        back: generated.recall.back,
        category: `${category} · Recall`,
      },
      {
        type: "Cloze",
        card_id: `ai-word-${slug}-cloze`,
        front: generated.cloze.front,
        back: generated.cloze.back,
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
    return json({ word, cards: cards.map(({ type, card_id, front, back }) => ({ type, card_id, front, back })) });
  } catch (error) {
    console.error("Word generation failed", error instanceof Error ? error.message : "unknown");
    return json({ error: error instanceof Error && error.message.includes("сохранить")
      ? error.message
      : "Не удалось создать карточки. Проверь слово и повтори попытку." }, 500);
  }
});
