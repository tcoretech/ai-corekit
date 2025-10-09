from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
from flair.data import Sentence
from flair.models import SequenceTagger
import re
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(title="Flair PII Detection API", version="1.0.0")

# Load models at startup
logger.info("Loading Flair NER models...")
tagger_de = SequenceTagger.load('de-ner-large')
tagger_en = SequenceTagger.load('ner-large')
logger.info("Models loaded successfully")

# German PII Patterns
GERMAN_PATTERNS = {
    'IBAN': r'[A-Z]{2}\d{2}\s?[\w\s]{4,34}',
    'PHONE_DE': r'(\+49|0049|0)\s?[1-9]\d{1,14}',
    'EMAIL': r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    'STEUER_ID': r'\d{2}\s?\d{3}\s?\d{3}\s?\d{3}',
    'PLZ': r'\b\d{5}\b',
    'SOZIALVERSICHERUNG': r'\d{2}\s?\d{6}\s?[A-Z]\s?\d{3}',
    'PERSONALAUSWEIS': r'[A-Z0-9]{9}',
}

# Request/Response models
class AnalyzeRequest(BaseModel):
    text: str
    language: str = "de"
    include_patterns: bool = True

class Entity(BaseModel):
    text: str
    type: str
    start: int
    end: int
    score: Optional[float] = None

class AnalyzeResponse(BaseModel):
    entities: List[Entity]
    has_pii: bool
    risk_score: int

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "models": ["de-ner-large", "ner-large"]}

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze_text(request: AnalyzeRequest):
    """Analyze text for PII entities"""
    try:
        entities = []
        
        # Select appropriate tagger
        tagger = tagger_de if request.language == "de" else tagger_en
        
        # NER Detection
        sentence = Sentence(request.text)
        tagger.predict(sentence)
        
        for entity in sentence.get_spans('ner'):
            entities.append(Entity(
                text=entity.text,
                type=entity.tag,
                start=entity.start_position,
                end=entity.end_position,
                score=entity.score
            ))
        
        # Pattern-based detection (especially for German)
        if request.include_patterns and request.language == "de":
            for pattern_name, pattern_regex in GERMAN_PATTERNS.items():
                for match in re.finditer(pattern_regex, request.text, re.IGNORECASE):
                    # Avoid duplicates
                    if not any(e.start <= match.start() < e.end for e in entities):
                        entities.append(Entity(
                            text="***REDACTED***",  # Don't expose actual PII
                            type=pattern_name,
                            start=match.start(),
                            end=match.end(),
                            score=1.0
                        ))
        
        # Calculate risk score
        risk_score = min(len(entities) * 20, 100)
        
        return AnalyzeResponse(
            entities=entities,
            has_pii=len(entities) > 0,
            risk_score=risk_score
        )
    
    except Exception as e:
        logger.error(f"Analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/anonymize")
async def anonymize_text(request: AnalyzeRequest):
    """Anonymize detected PII in text"""
    try:
        # First analyze
        analysis = await analyze_text(request)
        
        # Replace entities with placeholders
        anonymized_text = request.text
        offset = 0
        
        # Sort entities by start position (reverse)
        sorted_entities = sorted(analysis.entities, key=lambda e: e.start, reverse=True)
        
        for entity in sorted_entities:
            placeholder = f"[{entity.type}]"
            anonymized_text = (
                anonymized_text[:entity.start] + 
                placeholder + 
                anonymized_text[entity.end:]
            )
        
        return {
            "original_length": len(request.text),
            "anonymized_text": anonymized_text,
            "entities_found": len(analysis.entities),
            "risk_score": analysis.risk_score
        }
    
    except Exception as e:
        logger.error(f"Anonymization error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "service": "Flair PII Detection API",
        "version": "1.0.0",
        "endpoints": ["/health", "/analyze", "/anonymize"],
        "languages": ["en", "de"],
        "models": {
            "de": "de-ner-large",
            "en": "ner-large"
        }
    }
