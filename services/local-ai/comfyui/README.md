# 🎨 ComfyUI - Image Generation

### What is ComfyUI?

ComfyUI is a powerful node-based interface for Stable Diffusion and other AI image generation models. Unlike simple prompt-to-image tools, ComfyUI provides a visual workflow system where you connect nodes to create complex image generation pipelines. It's highly customizable, supports multiple models, and is perfect for both beginners and advanced users who want full control over their AI image generation process.

### Features

- **Node-Based Workflow** - Visual programming for image generation pipelines
- **Multiple Model Support** - FLUX, SDXL, SD 1.5, ControlNet, LoRA, and more
- **Custom Workflows** - Save and share complete generation pipelines
- **Advanced Control** - ControlNet, IP-Adapter, inpainting, outpainting
- **Batch Processing** - Generate multiple variations efficiently
- **API Support** - Programmatic access for n8n integration
- **Model Manager** - Easy model installation and management
- **Community Workflows** - Thousands of pre-built workflows available
- **Custom Nodes** - Extensible with community-created node packs
- **High Performance** - Optimized for GPU acceleration

### Initial Setup

**First Login to ComfyUI:**

1. Navigate to `https://comfyui.yourdomain.com`
2. The interface loads immediately - no login required
3. You'll see the default workflow (text-to-image)
4. **Important:** No models are pre-installed - you must download them first

**ComfyUI is ready to use, but needs models!**

### Download Essential Models

ComfyUI requires AI models to generate images. Here's how to get started:

**Option 1: Download via Web UI (Easiest)**

1. Click **Manager** button (bottom right)
2. Select **Install Models**
3. Choose model category:
   - **Checkpoints:** Base models (FLUX, SDXL, SD 1.5)
   - **LoRA:** Style modifiers
   - **ControlNet:** Pose/edge control
   - **VAE:** Image encoders/decoders
4. Click **Install** next to desired model
5. Wait for download to complete

**Option 2: Manual Download**

```bash
# Access ComfyUI models directory
cd /var/lib/docker/volumes/${PROJECT_NAME:-localai}_comfyui_data/_data/models

# Download FLUX.1-schnell (fast, recommended for beginners)
cd checkpoints
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors

# Download SDXL (versatile, good quality)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# Download VAE (required for SDXL)
cd ../vae
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

# Restart ComfyUI to detect new models
docker compose restart comfyui
```

**Recommended Models for Beginners:**

| Model | Size | Best For | Download Priority |
|-------|------|----------|-------------------|
| **FLUX.1-schnell** | 23GB | Fast generation, great quality | ⭐ Essential |
| **SDXL Base 1.0** | 6.5GB | Versatile, photorealistic | ⭐ Essential |
| **SD 1.5** | 4GB | Fast, wide LoRA support | ⭐⭐ Recommended |
| **SDXL Turbo** | 6.5GB | Ultra-fast, 1-step generation | ⭐⭐ Recommended |

**Model Storage Locations:**

```
checkpoints/     - Base models (FLUX, SDXL, SD 1.5)
loras/          - Style modifiers
controlnet/     - Pose and edge control models
vae/            - Image encoders/decoders
upscale_models/ - AI upscalers
embeddings/     - Textual inversion embeddings
```

### Basic Image Generation

**Simple Text-to-Image:**

1. Load the default workflow (or refresh page)
2. Find the **Load Checkpoint** node
3. Select your downloaded model from dropdown
4. Find the **CLIP Text Encode (Prompt)** node
5. Enter your positive prompt: `"a beautiful landscape with mountains and lake, golden hour, 8k, highly detailed"`
6. Enter negative prompt: `"blurry, low quality, distorted"`
7. Click **Queue Prompt** (right sidebar)
8. Wait for generation (10-60 seconds depending on model)
9. Image appears in **Save Image** node

**Workflow Controls:**

- **Queue Prompt:** Start generation
- **Clear:** Remove all queued prompts
- **Manager:** Install models and custom nodes
- **Load:** Import saved workflows
- **Save:** Export current workflow

### n8n Integration Setup

**ComfyUI API Configuration:**

ComfyUI provides a REST API for programmatic image generation from n8n.

**Internal URL for n8n:** `http://comfyui:8188`

**API Endpoints:**
- `/prompt` - Queue a generation job
- `/history` - Get generation history
- `/queue` - Check queue status
- `/view` - Retrieve generated images

### Example Workflows

#### Example 1: AI Social Media Content Generator

Automatically generate images for social media posts:

```javascript
// Generate branded social media images from text prompts

// 1. Schedule Trigger - Daily at 9 AM
// Or: Webhook for on-demand generation

// 2. Code Node - Prepare prompts
const topics = [
  "modern minimalist workspace",
  "healthy breakfast bowl",
  "sunset at the beach",
  "cozy coffee shop"
];

const selectedTopic = topics[Math.floor(Math.random() * topics.length)];

const comfyWorkflow = {
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 1000000),
      "steps": 20,
      "cfg": 8,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "6": {
    "inputs": {
      "text": `${selectedTopic}, professional photography, high quality, 8k, trending on artstation`,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "blurry, low quality, distorted, ugly, bad anatomy",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "social_media",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return {
  json: {
    prompt: comfyWorkflow,
    topic: selectedTopic
  }
};

// 3. HTTP Request Node - Send to ComfyUI
Method: POST
URL: http://comfyui:8188/prompt
Headers:
  Content-Type: application/json
Body (JSON):
{
  "prompt": {{$json.prompt}},
  "client_id": "n8n-workflow"
}

// 4. Wait Node - Wait for generation
Amount: 60
Unit: seconds

// 5. HTTP Request Node - Get generated image
Method: GET
URL: http://comfyui:8188/history/{{$('Queue Generation').json.prompt_id}}
Response Format: JSON

// 6. Code Node - Extract image data
const history = $input.first().json;
const promptId = Object.keys(history)[0];
const outputs = history[promptId].outputs;

// Find the image output
let imageInfo;
for (const nodeId in outputs) {
  if (outputs[nodeId].images) {
    imageInfo = outputs[nodeId].images[0];
    break;
  }
}

return {
  json: {
    filename: imageInfo.filename,
    subfolder: imageInfo.subfolder,
    type: imageInfo.type
  }
};

// 7. HTTP Request Node - Download image
Method: GET
URL: http://comfyui:8188/view?filename={{$json.filename}}&subfolder={{$json.subfolder}}&type={{$json.type}}
Response Format: File
Output Property Name: data

// 8. Move Binary - Rename file
Mode: Move to new property
From Property: data
To Property: image
New File Name: social_{{$now.format('YYYY-MM-DD')}}.png

// 9. Google Drive Node - Upload to Drive
Operation: Upload
File: {{$binary.image}}
Folder: Social Media Content
Name: {{$('Code - Extract').json.filename}}

// 10. Slack Node - Share with team
Channel: #marketing
Message: |
  🎨 New social media image generated!
  
  Topic: {{$('Prepare Prompts').json.topic}}
  
  📁 Available in Google Drive: Social Media Content
  
Attachments: {{$binary.image}}
```

#### Example 2: Product Photography Automation

Generate consistent product images for e-commerce:

```javascript
// Create professional product photos with consistent style

// 1. Webhook Trigger - Receive product details
// Payload: { "product_name": "Modern Chair", "color": "blue", "style": "minimalist" }

// 2. Code Node - Build detailed prompt
const product = $json.product_name;
const color = $json.color;
const style = $json.style || "modern";

const positivePrompt = `professional product photography of ${product}, ${color} color, ${style} style, white background, studio lighting, high resolution, sharp focus, commercial photography, e-commerce photo`;

const negativePrompt = "blurry, shadows, cluttered background, distorted, low quality, watermark";

// Load workflow template
const workflow = {
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "6": {
    "inputs": {
      "text": positivePrompt,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": negativePrompt,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 999999),
      "steps": 25,
      "cfg": 7.5,
      "sampler_name": "dpmpp_2m",
      "scheduler": "karras",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 4  // Generate 4 variations
    },
    "class_type": "EmptyLatentImage"
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": `product_${product.replace(/\s+/g, '_')}`,
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return {
  json: {
    workflow,
    product,
    positivePrompt
  }
};

// 3. HTTP Request - Queue generation
Method: POST
URL: http://comfyui:8188/prompt
Body: { "prompt": {{$json.workflow}} }

// 4. Wait - Allow generation time
Amount: 90
Unit: seconds

// 5. HTTP Request - Retrieve results
Method: GET
URL: http://comfyui:8188/history/{{$('Queue Generation').json.prompt_id}}

// 6. Code Node - Process all generated images
const history = $input.first().json;
const promptId = Object.keys(history)[0];
const outputs = history[promptId].outputs;

const images = [];
for (const nodeId in outputs) {
  if (outputs[nodeId].images) {
    outputs[nodeId].images.forEach(img => {
      images.push({
        filename: img.filename,
        subfolder: img.subfolder,
        type: img.type
      });
    });
  }
}

return images.map(img => ({ json: img }));

// 7. Loop Over Items - Process each variation

// 8. HTTP Request - Download image
Method: GET
URL: http://comfyui:8188/view?filename={{$json.filename}}&subfolder={{$json.subfolder}}&type={{$json.type}}
Response Format: File

// 9. Supabase Node - Store in database
Operation: Insert
Table: product_images
Data:
  product_id: {{$('Webhook').json.product_id}}
  image_url: Generated URL
  style: {{$('Webhook').json.style}}
  color: {{$('Webhook').json.color}}
  created_at: {{$now.toISO()}}

// 10. S3/Cloudflare R2 - Upload to CDN (optional)
// For production serving

// 11. Email Node - Notify product team (after loop ends)
To: product-team@company.com
Subject: Product Images Generated: {{$('Build Prompt').json.product}}
Body: |
  ✅ Product photography completed!
  
  Product: {{$('Build Prompt').json.product}}
  Variations: 4 images generated
  Style: {{$('Webhook').json.style}}
  
  Images available in product database.
  
  Prompt used: {{$('Build Prompt').json.positivePrompt}}
```

#### Example 3: AI Art Pipeline with Style Transfer

Create consistent branded artwork:

```javascript
// Generate artwork matching brand guidelines

// 1. Schedule Trigger - Weekly content generation

// 2. Read Binary Files - Load style reference image
File Path: /data/shared/brand_style_reference.png

// 3. Code Node - Prepare workflow with ControlNet
const workflow = {
  // Load models
  "1": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  
  // Load ControlNet for style transfer
  "2": {
    "inputs": {
      "control_net_name": "control_v11p_sd15_canny.pth"
    },
    "class_type": "ControlNetLoader"
  },
  
  // Prompts
  "6": {
    "inputs": {
      "text": "abstract digital art, vibrant colors, geometric shapes, modern design, professional illustration",
      "clip": ["1", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "ugly, blurry, low quality, distorted",
      "clip": ["1", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  
  // Generation settings
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 999999),
      "steps": 30,
      "cfg": 8.5,
      "sampler_name": "dpmpp_2m_sde",
      "scheduler": "karras",
      "denoise": 0.85,
      "model": ["1", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  
  // Latent image
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  
  // Decode and save
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["1", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "branded_art",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return { json: { workflow } };

// 4. HTTP Request - Generate
Method: POST
URL: http://comfyui:8188/prompt
Body: { "prompt": {{$json.workflow}} }

// 5. Wait - Generation time
Amount: 120 seconds

// 6. HTTP Request - Retrieve image
// ... (similar to previous examples)

// 7. OpenAI Vision Node - Verify brand compliance
Model: gpt-4o
System: "You are a brand compliance checker. Analyze if the image matches brand guidelines."
User: "Does this image match our brand style? Be specific."
Image: {{$binary.image}}

// 8. IF Node - Check AI approval
Condition: {{$json.message.content}} contains "matches"

// Branch: Approved
// 9a. Move to production folder
// 10a. Post to social media

// Branch: Rejected
// 9b. Queue for manual review
// 10b. Notify design team
```

### Custom Workflows

**Save Your Workflow:**

1. Create your workflow in ComfyUI
2. Click **Save** button
3. Enter filename: `my_workflow.json`
4. Workflow saved to `/output/workflows/`

**Load Saved Workflow:**

1. Click **Load** button
2. Select your workflow from list
3. Workflow loads automatically

**Share Workflows:**

- Export JSON from ComfyUI
- Share via GitHub, Civitai, or ComfyUI forums
- Import others' workflows with **Load**

### Troubleshooting

**Issue 1: "No model loaded" Error**

```bash
# Check installed models
docker exec comfyui ls -la /app/models/checkpoints/

# Verify model is .safetensors format
# Models must be in correct subdirectory

# Download missing model
docker exec comfyui wget -P /app/models/checkpoints/ \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# Restart ComfyUI
docker compose restart comfyui
```

**Solution:**
- Ensure models are in `/models/checkpoints/` directory
- Use `.safetensors` format (not `.ckpt`)
- Refresh ComfyUI page after adding models
- Check model filename matches exactly in workflow

**Issue 2: Out of Memory / CUDA Errors**

```bash
# Check GPU memory usage
docker exec comfyui nvidia-smi

# Reduce batch size in workflow
# Change from batch_size: 4 to batch_size: 1

# Use smaller models
# SDXL Turbo (6GB) instead of FLUX (23GB)

# Enable low VRAM mode in ComfyUI settings
# Settings → Execution → Enable CPU fallback
```

**Solution:**
- Use lower resolution (512x512 or 768x768)
- Reduce batch size to 1
- Use quantized models (fp16 instead of fp32)
- Close other GPU applications
- Upgrade GPU or use cloud GPU

**Issue 3: Slow Generation Times**

```bash
# Check if GPU is being used
docker exec comfyui nvidia-smi

# Verify CUDA is working
docker exec comfyui python -c "import torch; print(torch.cuda.is_available())"

# Enable xFormers for faster generation
# Add to docker-compose.yml:
#   environment:
#     - COMMANDLINE_ARGS=--use-xformers
```

**Solution:**
- Use SDXL Turbo or LCM models for faster generation
- Reduce step count (15-20 steps instead of 30-50)
- Use efficient samplers: `euler_a`, `dpm++ 2m`
- Enable TensorRT optimization
- Use lower CFG scale (6-8 instead of 10-15)

**Issue 4: API Connection Errors from n8n**

```bash
# Test API connectivity
curl http://comfyui:8188/system_stats

# Check ComfyUI logs
docker logs comfyui --tail 50

# Verify ComfyUI is running
docker ps | grep comfyui

# Restart if needed
docker compose restart comfyui
```

**Solution:**
- Use internal URL: `http://comfyui:8188` from n8n
- Ensure ComfyUI container is running
- Check prompt JSON is valid
- Increase HTTP request timeout to 120 seconds
- Monitor queue: `http://comfyui:8188/queue`

### Resources

- **Official GitHub:** https://github.com/comfyanonymous/ComfyUI
- **Documentation:** https://docs.comfy.org/
- **Model Downloads:** https://civitai.com/ (largest model library)
- **Community Workflows:** https://comfyworkflows.com/
- **Custom Nodes:** https://github.com/ltdrdata/ComfyUI-Manager
- **API Documentation:** https://github.com/comfyanonymous/ComfyUI/wiki/API
- **Discord Community:** https://discord.gg/comfyui
- **Video Tutorials:** https://www.youtube.com/c/OlivioSarikas

### Best Practices

**Model Management:**
1. **Start small** - Download SDXL first, add others as needed
2. **Organize models** - Use subfolders for different model types
3. **Regular cleanup** - Remove unused models to save space
4. **Test models** - Always test new models with simple prompts first
5. **Backup workflows** - Export important workflows regularly

**Prompt Engineering:**
- **Be specific** - "red sports car" vs "vintage red Ferrari 250 GTO"
- **Use quality tags** - "8k, highly detailed, professional photography"
- **Negative prompts** - Always include: "blurry, low quality, distorted"
- **Style modifiers** - "in the style of [artist/movement]"
- **Composition** - Specify: "close-up", "wide angle", "bird's eye view"

**Performance Optimization:**
1. **Resolution** - Start at 512x512, upscale later if needed
2. **Steps** - 20-30 steps is usually sufficient
3. **CFG Scale** - 7-8 for most cases, higher for more prompt adherence
4. **Sampler** - `euler_a` or `dpmpp_2m` for speed
5. **Batch generation** - Generate multiple variations in one run

**n8n Integration Tips:**
1. **Async processing** - Always include Wait node after queueing
2. **Error handling** - Add Try/Catch around ComfyUI calls
3. **Rate limiting** - Don't queue more than 3-5 prompts concurrently
4. **Image storage** - Save to S3/Drive immediately after generation
5. **Monitoring** - Log generation times and success rates

**Security:**
- ComfyUI has no authentication by default
- Use Caddy reverse proxy for HTTPS and basic auth
- Don't expose ComfyUI directly to internet
- API access through n8n only (internal network)
- Regular backups of models and workflows
