require("dotenv").config({path: ".env.local"});

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
    const history = request.data.history || [];

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

    const matchedMedicineIds = [];
    if (!kbSnapshot.empty) {
      kbSnapshot.forEach((doc) => {
        matchedMedicineIds.push(doc.id);
      });
    }

    // 3. Query available stock for these medicines
    const stockItems = [];
    const pharmacyIdsSet = new Set();

    if (matchedMedicineIds.length > 0) {
      const stockSnapshot = await db.collection("stock")
          .where("medicineId", "in", matchedMedicineIds)
          .where("isAvailable", "==", true)
          .get();

      if (!stockSnapshot.empty) {
        stockSnapshot.forEach((doc) => {
          const data = doc.data();
          stockItems.push(data);
          if (data.pharmacyId) {
            pharmacyIdsSet.add(data.pharmacyId);
          }
        });
      }
    }

    const pharmacyIds = Array.from(pharmacyIdsSet);

    // 4. Query pharmacies
    const pharmacies = {};
    if (pharmacyIds.length > 0) {
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
    let storeDataString = "";
    if (stockItems.length > 0) {
      stockItems.forEach((stock) => {
        const pharm = pharmacies[stock.pharmacyId];
        const pharmName = (pharm && pharm.name) || "Unknown pharmacy";
        const pharmAddress = (pharm && pharm.address) || "unknown";
        const pharmPhone = (pharm && pharm.phone) || "unknown";
        const price = stock.price != null ?
          Number(stock.price).toFixed(2) : "unknown";

        storeDataString += `- ${stock.medicineName} at ${pharmName}: ` +
          `${stock.quantity} unit(s) available, price ${price}, ` +
          `address ${pharmAddress}, phone ${pharmPhone}.\n`;
      });
    } else {
      storeDataString = "(No matching stock data available)";
    }

    const sysPrompt = "You are Jasper, the MedFinder assistant.\n\n" +
      "IMPORTANT INSTRUCTIONS:\n" +
      "1. Answer any question the user asks helpfully and concisely.\n" +
      "2. If the user asks about medicine availability, pharmacies, or stock, use the store data provided below.\n" +
      "3. For general medical questions (side effects, dosage, health), provide helpful, safe information.\n" +
      "4. Do NOT introduce yourself (e.g., \"Hi, I am Jasper\") unless it is the very first message of the conversation.\n" +
      "5. Use the conversation history to understand context for follow-up questions (e.g., if the user asks \"What is the price?\", check the history for the medicine they are referring to).\n" +
      "6. Write concise, friendly, and helpful answers in plain short sentences. Do not use overly long paragraphs.\n\n" +
      "AVAILABLE STORE DATA:\n" +
      "====================================\n" +
      storeDataString + "\n" +
      "====================================\n";

    // 6. Call Groq
    const groq = new Groq({apiKey: groqApiKey});
    
    const messages = [{ role: "system", content: sysPrompt }];
    if (history.length > 0) {
      messages.push(...history);
    } else {
      messages.push({ role: "user", content: question });
    }

    const completion = await groq.chat.completions.create({
      messages: messages,
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
