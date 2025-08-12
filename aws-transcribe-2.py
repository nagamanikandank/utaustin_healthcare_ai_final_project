# transcribe_to_stdout.py
import asyncio
import sys
import os
import json
import argparse

from amazon_transcribe.client import TranscribeStreamingClient
from amazon_transcribe.handlers import TranscriptResultStreamHandler
from amazon_transcribe.model import TranscriptEvent
from amazon_transcribe.utils import apply_realtime_delay

try:
    import aiofile
except ImportError:
    print("Missing dependency: aiofile. Install with: pip install aiofile", file=sys.stderr)
    sys.exit(2)

os.environ["AWS_ACCESS_KEY_ID"] = ""
os.environ["AWS_SECRET_ACCESS_KEY"] = ""
os.environ["AWS_SESSION_TOKEN"] = ""

SAMPLE_RATE = 16000
BYTES_PER_SAMPLE = 2
CHANNEL_NUMS = 1
CHUNK_SIZE = 1024 * 8

class CollectingHandler(TranscriptResultStreamHandler):
    def __init__(self, output_stream):
        super().__init__(output_stream)
        self._final_parts = []

    async def handle_transcript_event(self, transcript_event: TranscriptEvent):
        for result in transcript_event.transcript.results:
            # Only collect final results, not partials
            if not result.is_partial:
                for alt in result.alternatives:
                    text = alt.transcript.strip()
                    if text:
                        self._final_parts.append(text)

    def final_text(self) -> str:
        # Combine with spaces; tweak as needed
        return " ".join(self._final_parts).strip()

async def _run(audio_path: str, region: str):
    # Create client for the region
    client = TranscribeStreamingClient(region=region)

    # Start transcription stream
    stream = await client.start_stream_transcription(
        language_code="en-US",
        media_sample_rate_hz=SAMPLE_RATE,
        media_encoding="pcm",  # Expecting PCM16 audio
    )

    async def write_audio():
        # If your input is a WAV file with PCM16, this simple read usually works.
        # For other encodings, convert to PCM16 16kHz mono before streaming.
        async with aiofile.AIOFile(audio_path, "rb") as afp:
            reader = aiofile.Reader(afp, chunk_size=CHUNK_SIZE)
            await apply_realtime_delay(
                stream, reader, BYTES_PER_SAMPLE, SAMPLE_RATE, CHANNEL_NUMS
            )
        await stream.input_stream.end_stream()

    handler = CollectingHandler(stream.output_stream)
    await asyncio.gather(write_audio(), handler.handle_events())

    # Print a single JSON object to stdout
    print(json.dumps({"transcript": handler.final_text()}), flush=True)

def main():
    parser = argparse.ArgumentParser(description="Transcribe audio and print JSON to stdout.")
    parser.add_argument("audio_path", help="Path to WAV/PCM16 mono 16kHz audio file")
    parser.add_argument("--region", default=os.getenv("AWS_REGION", "us-east-1"))
    args = parser.parse_args()

    audio_path = args.audio_path
    if not os.path.isfile(audio_path):
        print(f"Audio file not found: {audio_path}", file=sys.stderr)
        sys.exit(1)

    # Credentials: rely on environment/credential chain (preferred).
    # Avoid hardcoding in code.
    # Ensure AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY are set, or use a profile.

    try:
        asyncio.run(_run(audio_path, args.region))
    except Exception as e:
        # Make sure Flutter receives a non-zero exit code on failure
        print(f"Transcription error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
