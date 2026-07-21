const {onCall} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {GoogleGenerativeAI} = require("@google/generative-ai");
const Groq = require("groq-sdk");
const logger = require("firebase-functions/logger");

const EMBEDDING_MODEL = "gemini-embedding-001";
const EMBEDDING_DIMENSIONS = 768;

exports.askJasper = onCall({
  secrets: ["GEMINI_API_KEY", "GROQ_API_KEY"],
}, async (request) => {
  try {
    const question = request.data.question;

    if (!question || typeof question !== "string" ||
        question.trim().length === 0) {
      return {
        answer: "Ask Jasper a question such as \"Where can I find Dolo 650?\"" +
                " or \"Which pharmacy near me has insulin?\"",
      };
    }

    const geminiApiKey = process.env.GEMINI_API_KEY;
    const groqApiKey = process.env.GROQ_API_KEY;

    if (!geminiApiKey || !groqApiKey) {
      logger.error(
          "API keys missing from environment (GEMINI_API_KEY or GROQ_API_KEY).",
      );
      return {answer: "Jasper could not answer right now, please try again."};
    }

    const db = getFirestore();

    // 1. Embed the user's question
    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const embeddingModel = genAI.getGenerativeModel({model: EMBEDDING_MODEL});

    const embedResult = await embeddingModel.embedContent({
      content: {parts: [{text: question}], role: "user"},
      taskType: "RETRIEVAL_QUERY",
      outputDimensionality: EMBEDDING_DIMENSIONS,
    });
    const queryVector = embedResult.embedding.values;

    // 2. Search medicine_kb via Vector Search
    const kbSnapshot = await db.collection("medicine_kb")
        .findNearest("embedding", FieldValue.vector(queryVector), {
          limit: 5,
          distanceMeasure: "COSINE",
        })
        .get();

    if (kbSnapshot.empty) {
      return {
        answer: "Jasper could not find a matching available medicine for " +
                `"${question}". Please try again later or adjust the name.`,
      };
    }

    const matchedMedicineIds = [];
    const medicineDetails = [];

    kbSnapshot.forEach((doc) => {
      matchedMedicineIds.push(doc.id);
      medicineDetails.push(doc.data());
    });

    // 3. Query available stock for these medicines
    // Note: Firestore 'in' queries support max 10 elements. We have at most 5.
    const stockSnapshot = await db.collection("stock")
        .where("medicineId", "in", matchedMedicineIds)
        .where("isAvailable", "==", true)
        .get();

    if (stockSnapshot.empty) {
      return {
        answer: "Jasper could not find a matching available medicine for " +
                `"${question}". Please try again later or adjust the name.`,
      };
    }

    const stockItems = [];
    const pharmacyIdsSet = new Set();

    stockSnapshot.forEach((doc) => {
      const data = doc.data();
      stockItems.push(data);
      if (data.pharmacyId) {
        pharmacyIdsSet.add(data.pharmacyId);
      }
    });

    const pharmacyIds = Array.from(pharmacyIdsSet);

    // 4. Query pharmacies
    const pharmacies = {};
    if (pharmacyIds.length > 0) {
      // Chunking if >10 pharmacies just in case,
      // though we only have up to 5 medicines.
      for (let i = 0; i < pharmacyIds.length; i += 10) {
        const chunk = pharmacyIds.slice(i, i + 10);
        const pharmSnapshot = await db.collection("pharmacies")
            .where("pharmacyId", "in", chunk)
            .get();

        pharmSnapshot.forEach((doc) => {
          pharmacies[doc.id] = doc.data();
        });
      }
    }

    // 5. Build prompt
    let promptContext = "You are Jasper, the MedFinder assistant.\n" +
      "Answer any question the user asks.\n" +
      "If the question is about medicine availability or pharmacies, " +
      "use the store data below.\n" +
      "For general questions about medicines, side effects, dosage, " +
      "or health, provide helpful information.\n\n" +
      `Question: ${question}\n\nAvailable store data:\n`;

    stockItems.forEach((stock) => {
      const pharm = pharmacies[stock.pharmacyId];
      const pharmName = (pharm && pharm.name) || "Unknown pharmacy";
      const pharmAddress = (pharm && pharm.address) || "unknown";
      const pharmPhone = (pharm && pharm.phone) || "unknown";
      const price = stock.price != null ?
        Number(stock.price).toFixed(2) : "unknown";

      promptContext += `- ${stock.medicineName} at ${pharmName}: ` +
        `${stock.quantity} unit(s) available, price ${price}, ` +
        `address ${pharmAddress}, phone ${pharmPhone}.\n`;
    });

    promptContext += "\nWrite a concise, friendly, and helpful " +
      "answer as Jasper.";

    // 6. Call Groq
    const groq = new Groq({apiKey: groqApiKey});
    const completion = await groq.chat.completions.create({
      messages: [{role: "user", content: promptContext}],
      model: "llama-3.3-70b-versatile",
    });

    const answer = (completion.choices &&
      completion.choices[0] &&
      completion.choices[0].message &&
      completion.choices[0].message.content) || "";

    if (!answer.trim()) {
      return {
        answer: "Jasper could not find a matching available medicine for " +
                `"${question}". Please try again later or adjust the name.`,
      };
    }

    return {answer: answer.trim()};
  } catch (error) {
    logger.error("Error in askJasper:", error);
    return {answer: "Jasper could not answer right now, please try again."};
  }
});
