# Eco-track-AI
# Eco-Track AI — Member 3: Database & Emission Factors

## About this project

**Eco-Track AI** estimates the carbon footprint of a household's grocery
shopping directly from a photo of the bill. The pipeline:

1. **Upload a bill** — user takes a photo or uploads an image
2. **OCR extraction**  — text is pulled from the image using
   PaddleOCR, cleaned, and split into individual line items
3. **Product identification**  — each OCR'd item name is matched
   against a master product list (using this database's `products` table
   and aliases) via classification, semantic matching, and confidence scoring
4. **Emission calculation** — for each matched product, its
   emission factor (kg CO2e per unit) is looked up and multiplied by
   quantity: `Carbon Footprint = Σ(Quantity × Emission Factor)`
5. **Results & dashboard** — total emissions, a category-wise
   breakdown, a sustainability score, and suggestions are shown to the user

