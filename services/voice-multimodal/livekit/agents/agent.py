import os
from livekit.agents import (
    AutoSubscribe,
    JobContext,
    WorkerOptions,
    cli,
)
from livekit.agents import Agent, AgentSession
from livekit.plugins import openai, silero

USE_OPENAI = bool(os.getenv("OPENAI_API_KEY"))
print(f"[LiveKit Agent] Starting in {'OpenAI' if USE_OPENAI else 'Local'} mode")

async def entrypoint(ctx: JobContext):
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    
    agent = Agent(
        instructions="You are a helpful AI voice assistant. Keep responses concise and conversational."
    )
    
    if USE_OPENAI:
        session = AgentSession(
            vad=silero.VAD.load(),
            stt=openai.STT(model="whisper-1"),
            llm=openai.LLM(model="gpt-4o-mini"),
            tts=openai.TTS(voice="alloy"),
        )
    else:
        class WhisperSTT(openai.STT):
            def __init__(self):
                super().__init__(
                    base_url=os.getenv("WHISPER_URL", "http://faster-whisper:8000") + "/v1",
                    api_key="not-needed",
                    model="whisper-1"
                )
        
        class OllamaLLM(openai.LLM):
            def __init__(self):
                super().__init__(
                    base_url=os.getenv("OLLAMA_URL", "http://ollama:11434") + "/v1",
                    api_key="ollama",
                    model=os.getenv("OLLAMA_MODEL", "qwen2.5:7b-instruct-q4_K_M")
                )
        
        class LocalTTS(openai.TTS):
            def __init__(self):
                super().__init__(
                    base_url=os.getenv("TTS_URL", "http://openedai-speech:8000") + "/v1",
                    api_key="not-needed",
                    voice="alloy"
                )
        
        session = AgentSession(
            vad=silero.VAD.load(),
            stt=WhisperSTT(),
            llm=OllamaLLM(),
            tts=LocalTTS(),
        )
    
    # Start session and keep running
    await session.start(agent=agent, room=ctx.room)
    
    # Generate initial greeting
    await session.generate_reply(
        instructions="greet the user briefly and ask how you can help"
    )

if __name__ == "__main__":
    cli.run_app(WorkerOptions(
        entrypoint_fnc=entrypoint,
        api_key=os.getenv("LIVEKIT_API_KEY"),
        api_secret=os.getenv("LIVEKIT_API_SECRET"),
        ws_url=os.getenv("LIVEKIT_URL", "ws://livekit-server:7880"),
    ))
