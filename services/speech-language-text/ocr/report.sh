#!/bin/bash
# Report for ocr

echo
echo "================================= OCR Bundle ==========================="
echo
echo "Two OCR engines are available for text extraction:"
echo
echo "▶ Tesseract OCR (Fast Mode):"
echo "  Internal URL: http://tesseract-ocr:8884"
echo "  Best for: Clean scans, bulk processing, text-heavy documents"
echo "  Speed: ~3-4 seconds per image"
echo "  Supports: 90+ languages"
echo
echo "▶ EasyOCR (Quality Mode):"
echo "  Internal URL: http://easyocr:2000"
echo "  Secret Key: ${EASYOCR_SECRET_KEY:-<not_set_in_env>}"
echo "  Best for: Photos, receipts, invoices with numbers, natural images"
echo "  Speed: ~7-8 seconds per image"
echo "  Supports: 80+ languages"
echo
echo "n8n Integration:"
echo "  Use HTTP Request node with the URLs above"
echo "  Tesseract: POST multipart/form-data with 'file' and 'options' fields"
echo "  EasyOCR: POST application/json with 'image_url' and 'secret_key' fields"
echo
echo "Documentation:"
echo "  Tesseract: https://github.com/hertzg/tesseract-server"
echo "  EasyOCR: https://github.com/JaidedAI/EasyOCR"
