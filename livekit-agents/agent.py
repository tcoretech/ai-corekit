import os
from livekit.agents import (
    AutoSubscribe,
    JobContext,
    WorkerOptions,
    cli,
    llm,
)
from livekit.agents.voice_assistant import VoiceAssistant
from livekit.plugins import openai, silero

# Check if OpenAI API key is available
USE_OPENAI = bool(os.getenv("OPENAI_API_KEY"))

# STT: Use OpenAI if available, otherwise local Whisper
if USE_OPENAI:
    stt_plugin = openai.STT(model="whisper-1")
else:
    class WhisperSTT(openai.STT):
        def __init__(self):
            super().__init__(
                base_url=os.getenv("WHISPER_URL", "http://faster-whisper:8000") + "/v1",
                api_key="not-needed",
                model="whisper-1"
            )
    stt_plugin = WhisperSTT()

# LLM: Use OpenAI if available, otherwise local Ollama
if USE_OPENAI:
    llm_plugin = openai.LLM(model="gpt-4o-mini")
else:
    class OllamaLLM(openai.LLM):
        def __init__(self):
            super().__init__(
                base_url=os.getenv("OLLAMA_URL", "http://ollama:11434") + "/v1",
                api_key="ollama",
                model=os.getenv("OLLAMA_MODEL", "qwen2.5:7b-instruct-q4_K_M")
            )
    llm_plugin = OllamaLLM()

# TTS: Use OpenAI if available, otherwise local TTS
if USE_OPENAI:
    tts_plugin = openai.TTS(voice="alloy")
else:
    class OpenedAITTS(openai.TTS):
        def __init__(self):
            super().__init__(
                base_url=os.getenv("TTS_URL", "http://openedai-speech:8000") + "/v1",
                api_key="not-needed",
                voice="alloy"
            )
    tts_plugin = OpenedAITTS()

async def entrypoint(ctx: JobContext):
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    
    mode = "OpenAI" if USE_OPENAI else "Local (Ollama/Whisper/TTS)"
    print(f"[LiveKit Agent] Running in {mode} mode")
    
    initial_ctx = llm.ChatContext().append(
        role="system",
        text="You are a helpful AI voice assistant. Keep responses concise and conversational."
    )
    
    assistant = VoiceAssistant(
        vad=silero.VAD.load(),
        stt=stt_plugin,
        llm=llm_plugin,
        tts=tts_plugin,
        chat_ctx=initial_ctx,
    )
    
    assistant.start(ctx.room)
    
    await assistant.say(
        "Hello! How can I help you today?",
        allow_interruptions=True
    )

if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
