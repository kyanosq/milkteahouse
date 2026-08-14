# Connectors & Credentials

This skill calls paid third-party APIs. Set these environment variables before
use (never commit real keys):

| Variable | Service | Used for | Where to get |
|---|---|---|---|
| `GOOGLE_API_KEY` | Google AI Studio (Gemini) | Precise images, character refs | https://aistudio.google.com/apikey |
| `XAI_API_KEY` | xAI Grok | Cheap images, textures, video for sprites | https://console.x.ai/ |
| `TRIPO3D_API_KEY` | Tripo3D | Image-to-3D GLB, rigging, retargeting | https://platform.tripo3d.ai/ |

Example (`~/.zshrc`):

```bash
export GOOGLE_API_KEY="<your-key>"
export XAI_API_KEY="<your-key>"
export TRIPO3D_API_KEY="<your-key>"
```

Cost reference (from upstream): image 2–15¢ · video 5¢/s · GLB 30–60¢ ·
rig +25¢ · retarget 10¢/clip. The skill requires user confirmation before the
first paid generation.
