/**
 * embedKnowledgeBase.js
 *
 * One-time script to read all documents from the `medicines` Firestore
 * collection, generate text embeddings via Gemini's text-embedding-004 model,
 * and write the results into the `medicine_kb` collection using Firestore's
 * native VectorValue field type.
 *
 * Run from inside the functions/ directory:
 *   node embedKnowledgeBase.js
 *
 * Prerequisites:
 *   - GEMINI_API_KEY must be set in .env (or the environment)
 *   - Either a service account key file (recommended on Windows):
 *       Set GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json in .env
 *       and place the downloaded JSON key at functions/serviceAccountKey.json
 *   - OR Google Cloud Application Default Credentials:
 *       gcloud auth application-default login
 *
 * Collections touched: medicines (read-only), medicine_kb (write)
 * Collections NOT touched: stock, pharmacies
 */

"use strict";

// ---------------------------------------------------------------------------
// Load environment variables from .env (same as Firebase tooling)
// ---------------------------------------------------------------------------
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const EMBEDDING_MODEL = "gemini-embedding-001";
const EMBEDDING_DIMENSIONS = 768; // Firestore supports max 2048 dims; we use 768 via outputDimensionality
const DELAY_MS = 200; // delay between Gemini API calls to avoid rate limiting
const SOURCE_COLLECTION = "medicines";
const TARGET_COLLECTION = "medicine_kb";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Sleep for `ms` milliseconds. */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Build the plain-text string sent to the embedding model. */
function buildTextForEmbedding({ name, category, description }) {
  return `${name}. Category: ${category}. ${description}`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // --- Validate environment ------------------------------------------------
  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (!geminiApiKey) {
    console.error("❌ GEMINI_API_KEY is not set. Aborting.");
    process.exit(1);
  }

  // --- Initialise Firebase Admin -------------------------------------------
  // Prefer a service account key (more reliable on Windows due to TLS issues
  // with the ADC OAuth2 token endpoint). Falls back to ADC if no key is set.
  const projectId = process.env.FIREBASE_PROJECT_ID || "medfinder-ef4f1";
  const serviceAccountKeyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  let credential;
  if (serviceAccountKeyPath) {
    const keyPath = path.resolve(__dirname, serviceAccountKeyPath);
    console.log(`🔑 Using service account key: ${keyPath}`);
    credential = admin.credential.cert(require(keyPath));
  } else {
    console.log("🔑 Using Application Default Credentials (ADC)");
    credential = admin.credential.applicationDefault();
  }

  admin.initializeApp({ credential, projectId });
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;

  // --- Initialise Gemini client --------------------------------------------
  const genAI = new GoogleGenerativeAI(geminiApiKey);
  const embeddingModel = genAI.getGenerativeModel({ model: EMBEDDING_MODEL });

  // --- Fetch all medicines -------------------------------------------------
  console.log(`\n📦 Fetching documents from '${SOURCE_COLLECTION}' collection…`);
  let snapshot;
  try {
    snapshot = await db.collection(SOURCE_COLLECTION).get();
  } catch (err) {
    console.error(`❌ Failed to read '${SOURCE_COLLECTION}' collection:`, err.message);
    process.exit(1);
  }

  if (snapshot.empty) {
    console.warn(`⚠️  No documents found in '${SOURCE_COLLECTION}'. Nothing to embed.`);
    process.exit(0);
  }

  const docs = snapshot.docs;
  console.log(`✅ Found ${docs.length} medicine document(s). Starting embedding…\n`);

  // --- Process each document -----------------------------------------------
  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < docs.length; i++) {
    const doc = docs[i];
    const data = doc.data();

    const { medicineId, name, category, description } = data;
    const docId = medicineId || doc.id; // fall back to Firestore doc ID if field missing

    try {
      // Build embedding input text
      const inputText = buildTextForEmbedding({ name, category, description });

      // Call Gemini embedding API (outputDimensionality truncates to 768 via MRL;
      // Firestore VectorValue supports at most 2048 dimensions)
      const result = await embeddingModel.embedContent({
        content: { parts: [{ text: inputText }], role: "user" },
        taskType: "RETRIEVAL_DOCUMENT",
        outputDimensionality: EMBEDDING_DIMENSIONS,
      });

      const embeddingValues = result.embedding.values;

      // Sanity-check the dimension
      if (embeddingValues.length !== EMBEDDING_DIMENSIONS) {
        throw new Error(
          `Unexpected embedding dimension: got ${embeddingValues.length}, expected ${EMBEDDING_DIMENSIONS}`
        );
      }

      // Write to medicine_kb using the medicineId as the document ID
      await db.collection(TARGET_COLLECTION).doc(docId).set({
        medicineId: docId,
        name: name || "",
        category: category || "",
        description: description || "",
        embedding: FieldValue.vector(embeddingValues),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(
        `[${i + 1}/${docs.length}] ✅ Embedded ${docId} - ${name}`
      );
      successCount++;
    } catch (err) {
      console.error(
        `[${i + 1}/${docs.length}] ❌ Failed to embed ${docId} (${name || "unknown"}): ${err.message}`
      );
      failCount++;
    }

    // Delay between calls (skip delay after the last document)
    if (i < docs.length - 1) {
      await sleep(DELAY_MS);
    }
  }

  // --- Summary -------------------------------------------------------------
  console.log("\n─────────────────────────────────────────");
  console.log(`📊 Embedding complete.`);
  console.log(`   ✅ Success : ${successCount}`);
  console.log(`   ❌ Failed  : ${failCount}`);
  console.log(`   📄 Total   : ${docs.length}`);
  console.log("─────────────────────────────────────────\n");

  if (failCount > 0) {
    console.warn(
      `⚠️  ${failCount} document(s) failed to embed. Check the logs above for details.`
    );
  }

  // Exit with non-zero if any documents failed
  process.exit(failCount > 0 ? 1 : 0);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
main().catch((err) => {
  console.error("💥 Unexpected fatal error:", err);
  process.exit(1);
});
