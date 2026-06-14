# 🌿 Sage — a Generative UI cooking assistant

> *Cook with what you have.*

Sage is a small Flutter app that demonstrates **Generative UI (GenUI)**: instead of replying with a wall of text, the AI **assembles a real, interactive screen** out of the app's own widgets — preference chips, recipe cards, a full recipe you can tweak — shaped by what you actually asked for.

Tell it *"something quick with paneer"* and it builds the UI: chips to confirm what's on hand, a few recipe cards to choose from, and a full recipe that it can adapt in place (*"no blender"* → it rewrites the steps).

Built with the experimental [**Flutter GenUI SDK**](https://docs.flutter.dev/ai/genui), the open [**A2UI**](https://a2ui.org/) (Agent‑to‑User Interface) protocol, and **Gemini** via Firebase AI Logic.

> 📊 This repo also contains the companion conference talk deck: [`genui-talk.html`](genui-talk.html) — *"Building Generative Interfaces with Flutter's GenUI SDK."*

---

## 🎬 Demo

https://github.com/user-attachments/assets/47bd5109-9174-4370-aac9-2e3c9aa338a5

>
> *The full loop: "something quick with paneer" → preference chips → recipe cards → the full recipe → an in‑place "no blender" rewrite.*

<!-- 💡 For a guaranteed inline player on GitHub: open this README in the GitHub web editor, drag sage_demo.mp4 into it, and GitHub will generate an auto-embedding https://github.com/user-attachments/assets/... URL. Replace the <video> src above with that URL. -->

---

## ✨ The core idea: the app owns the facts, the model owns the words

This is the principle the whole app is built around:

- **Facts** — recipe titles, cook times, ingredients, and default steps — live in a fixed local database ([`lib/recipe_db.dart`](lib/recipe_db.dart)). The model can **never invent** these.
- **Words** — the friendly one‑line *reason* on a card, and an *adapted* set of steps + a note when you ask for a change — are the only things the model writes freely.

The model only ever references a recipe **by its `id`**. It proposes; your data disposes. That single constraint is what stops it hallucinating recipes that don't exist.

---

## 🔁 How it works

Sage follows a strict, model‑steered flow — one turn at a time:

1. **Gather** — you ask for something; the model shows **chips** (built‑in `ChoicePicker`) to confirm ingredients & time. *It does not list recipes yet.*
2. **Suggest** — once it knows enough, it shows 2–3 **`RecipeCard`s**, each carrying only a `recipeId` + a friendly `reason`.
3. **Cook** — you tap a card → the model renders the full **`RecipeView`** (image, ingredients, numbered steps) from your data.
4. **Adapt** — tap an adjustment chip (*No blender*, *Make it spicier*, *Fewer steps*) → it re‑renders the **same** recipe with an adapted `steps` list and a short note explaining the change.

Each interaction loops back to the model, which sends a fresh **surface** — so the previous screens stay in the transcript instead of being overwritten.

### The pieces

| Piece | Role | In this repo |
|---|---|---|
| **Conversation** | Orchestrates the turn loop between user, model, and UI | [`main.dart`](lib/main.dart) |
| **Transport + A2UI** | Streams the model's reply back as declarative UI (data, not code) | [`agent/recipe_backend.dart`](lib/agent/recipe_backend.dart) |
| **Catalog → CatalogItem** | The contract: the only widgets the model may use (`name` · `dataSchema` · `widgetBuilder`) | [`catalog/recipe_catalog.dart`](lib/catalog/recipe_catalog.dart) |
| **Surface** | Where a reply renders as real, native Flutter widgets | `SurfaceController` in [`main.dart`](lib/main.dart) |
| **Data model & binding** | Schema‑checked data fills each widget; taps dispatch events back to the conversation | [`recipe_db.dart`](lib/recipe_db.dart) + the catalog items |

---

## 🧩 The custom catalog

The app starts from the SDK's `BasicCatalogItems` (Text, Column, ChoicePicker, …), **removes** image/video/audio so the model can't render media it would have to invent, and **adds** two custom widgets:

- **`RecipeCard`** ([`catalog/recipe_card.dart`](lib/catalog/recipe_card.dart)) — schema accepts only `recipeId` (required) + `reason` (optional).
- **`RecipeView`** ([`catalog/recipe_view.dart`](lib/catalog/recipe_view.dart)) — accepts `recipeId` (required) + optional `steps` (the adaptation) + `note`.

Domain steering (persona, the gather → suggest → view flow, the "be honest if you don't have it" rule, and the unique‑surface rule) lives as system‑prompt fragments in [`recipe_catalog.dart`](lib/catalog/recipe_catalog.dart). Registering a widget makes it *possible* for the model to use; the prompt fragments make it *likely*.

---

## 📁 Project structure

```text
lib/
├── main.dart                    # App UI: chat transcript, composer, SurfaceController + Conversation
├── recipe_db.dart               # The trusted source of facts (fixed recipe list)
├── firebase_options.dart        # Firebase config — gitignored; run `flutterfire configure`
├── agent/
│   └── recipe_backend.dart      # The seam to Gemini via Firebase AI Logic + A2uiTransportAdapter
└── catalog/
    ├── recipe_catalog.dart      # The catalog + system-prompt steering
    ├── recipe_card.dart         # Custom RecipeCard widget + schema
    └── recipe_view.dart         # Custom RecipeView widget + schema (adaptation)
```

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK (Dart `^3.10.9`)
- A **Firebase project** with **Firebase AI Logic** (Gemini API) enabled
- The [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)

### Setup

```bash
# 1. Clone
git clone https://github.com/jakansha2001/recipe_genui.git
cd recipe_genui

# 2. Install dependencies
flutter pub get

# 3. Connect YOUR Firebase project (regenerates lib/firebase_options.dart)
flutterfire configure

# 4. Run
flutter run
```

> ℹ️ The Firebase config files (`firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) are **gitignored and not included** in this repo. Run `flutterfire configure` with **your own** Firebase project (with Firebase AI Logic enabled) to generate them before the app will build and run.

The model is set in [`recipe_backend.dart`](lib/agent/recipe_backend.dart) (`gemini-3.1-flash-lite` by default) — swap it there. Because genui is backend‑agnostic, changing providers means touching only that one file.

---

## 🛠 Tech stack

- **[genui](https://pub.dev/packages/genui)** `^0.9.2` — the Flutter Generative UI SDK
- **[firebase_ai](https://pub.dev/packages/firebase_ai)** `^3.12.2` + **firebase_core** — Gemini via Firebase AI Logic
- **[json_schema_builder](https://pub.dev/packages/json_schema_builder)** — declaring each widget's data schema
- **[image_picker](https://pub.dev/packages/image_picker)** — attach a fridge photo (gallery) to a request
- **[google_fonts](https://pub.dev/packages/google_fonts)** — Inter / Outfit type

---

## ⚠️ A note on stability

The `genui` package is **experimental / alpha** — the API still changes between versions. Pin your version and expect to refactor when upgrading. This app is a learning demo, not production‑hardened.

---

## 📚 Learn more

- [Flutter GenUI SDK docs](https://docs.flutter.dev/ai/genui) · [Get started](https://docs.flutter.dev/ai/genui/get-started)
- [Official GenUI codelab](https://codelabs.developers.google.com/codelabs/genui-intro)
- [A2UI — the protocol](https://a2ui.org/) · [Google's announcement](https://developers.googleblog.com/introducing-a2ui-an-open-project-for-agent-driven-interfaces/)
- [Flutter + A2UI = GenUI (Flutter team video)](https://www.youtube.com/watch?v=tXeyaV1gVJk)

---

## 👤 Author

**Akansha Jain** — Senior Software Engineer · Organiser, Flutter Delhi & FFDG New Delhi
🌐 [akanshajain.dev](https://akanshajain.dev) · 💻 [github.com/jakansha2001](https://github.com/jakansha2001)

---

*Built to show that the best AI feature isn't another chat box — it's the screen you didn't have to design.*
