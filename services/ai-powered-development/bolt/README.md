# ⚡ bolt.diy - AI App Builder

### What is bolt.diy?

bolt.diy is an AI-powered full-stack development platform that allows you to build complete web applications using natural language prompts. Based on StackBlitz's bolt technology, it combines AI assistance with a live development environment, enabling rapid prototyping and MVP creation without deep coding knowledge.

### Features

- **AI-Powered Development**: Describe your app in natural language, watch it build in real-time
- **Full-Stack Support**: Frontend (React, Vue, Svelte) and backend (Node.js, Python) in one environment
- **Live Preview**: See changes instantly with hot module replacement
- **Code Export**: Download complete projects with all dependencies
- **Multi-Model Support**: Works with OpenAI, Anthropic, Groq, and other LLM providers
- **WebContainer Technology**: Runs Node.js directly in the browser for instant feedback

### Initial Setup

**First Access to bolt.diy:**
1. Navigate to `https://bolt.yourdomain.com`
2. No login required - bolt.diy starts immediately
3. Configure API keys for your preferred AI model:
   - Click the settings icon (⚙️) in the top right
   - Add your API key (OpenAI, Anthropic, Groq, etc.)
   - Select your preferred model (Claude Sonnet 3.5, GPT-4, etc.)

**Recommended Models:**
- **Claude 3.5 Sonnet**: Best for complex full-stack applications
- **GPT-4**: Excellent for React and frontend development
- **Groq (Llama)**: Fast, good for quick prototypes
- **Ollama**: Local models, requires Ollama service enabled

### n8n Integration Setup

While bolt.diy doesn't have a direct n8n node, you can integrate generated apps with n8n workflows:

**Workflow Pattern: AI App Generation Pipeline**

```javascript
// 1. Manual Trigger or Webhook
// User submits app requirements

// 2. Code Node: Prepare bolt.diy prompt
const appSpec = {
  description: $json.userRequest,
  features: $json.requiredFeatures,
  tech_stack: "React + Node.js + PostgreSQL"
};

const boltPrompt = `Create a ${appSpec.tech_stack} application:
${appSpec.description}

Required features:
${appSpec.features.join('\n')}

Include authentication, database models, and REST API.`;

return { prompt: boltPrompt };

// 3. Manual Step: Developer uses bolt.diy
// → Open bolt.yourdomain.com
// → Paste the generated prompt
// → Review and iterate with AI
// → Export the generated code

// 4. GitHub Node: Create repository
// Upload exported code to GitHub

// 5. Webhook: Trigger deployment pipeline
// → Vercel/Netlify for frontend
// → Railway/Fly.io for backend
```

**Internal URL:** `http://bolt:5173` (for internal service-to-service communication)

### Example Use Cases

#### Example 1: Rapid MVP Development

**Scenario**: Build a SaaS landing page with authentication in 10 minutes

```
Prompt: "Create a modern SaaS landing page for an AI writing assistant called 'WriteWise'. 
Include:
- Hero section with gradient background
- Features section (3 key features)
- Pricing table (Free, Pro, Enterprise)
- Email signup form with Supabase integration
- Responsive design with Tailwind CSS"

Result: Complete React app with:
- Modern UI components
- Working form validation
- Supabase auth integration
- Mobile-responsive layout
- Ready to deploy
```

#### Example 2: Internal Tool Creation

**Scenario**: Build a custom admin dashboard for your team

```
Prompt: "Create an admin dashboard for managing AI CoreKit services:
- Service status overview (running/stopped)
- Resource usage charts (CPU, RAM, disk)
- Quick actions (restart services, view logs)
- Authentication with username/password
- Dark mode support
- Use Express.js backend, React frontend"

Result: Full-stack admin tool that you can:
- Deploy internally
- Connect to Docker API
- Customize with additional prompts
- Export and self-host
```

#### Example 3: API Wrapper Development

**Scenario**: Create a custom API client for your AI services

```
Prompt: "Build a Node.js API wrapper for Ollama with:
- TypeScript support
- Streaming responses
- Conversation history management
- Rate limiting
- Error handling with retries
- Express server with REST endpoints"

Result: Production-ready API wrapper you can:
- Use in n8n workflows
- Deploy as microservice
- Extend with custom logic
```

### Development Workflow

**Iterative Development with bolt.diy:**

1. **Initial Prompt**: Start with a clear, detailed description
2. **Review Generated Code**: Check structure and dependencies
3. **Refine with Follow-ups**: 
   - "Add user authentication"
   - "Make it mobile-responsive"
   - "Add error handling to the API calls"
4. **Test in Live Preview**: Interact with the app in real-time
5. **Export Code**: Download complete project with package.json
6. **Deploy**: Push to GitHub, deploy to hosting platform

**Best Practices:**
- **Be Specific**: Detailed prompts produce better results
- **Iterate Gradually**: Add features one at a time
- **Test Frequently**: Use the live preview to catch issues early
- **Export Often**: Save progress before major changes
- **Use Good Models**: Claude 3.5 Sonnet or GPT-4 for complex apps

### Troubleshooting

**"Blocked Request" or App Not Loading:**

bolt.diy uses Vite which can have issues with reverse proxies. This fork includes automatic hostname configuration.

```bash
# 1. Check if BOLT_HOSTNAME is set correctly in .env
grep BOLT_HOSTNAME .env
# Should show: BOLT_HOSTNAME=bolt.yourdomain.com

# 2. Verify bolt.diy is running
docker ps | grep bolt

# 3. Check bolt.diy logs for errors
docker logs bolt -f

# 4. Restart the service
docker compose restart bolt

# 5. Clear browser cache and try again
# Chrome: Ctrl+Shift+Delete → Clear cached images and files
```

**AI Model Not Responding:**

```bash
# 1. Verify API key is correct in bolt.diy settings
# Click settings icon → Check API key format

# 2. Test API key separately
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'

# 3. Check rate limits on your AI provider dashboard
# OpenAI: platform.openai.com/usage
# Anthropic: console.anthropic.com
```

**Generated Code Not Working:**

```bash
# 1. Check browser console for errors (F12)
# Look for dependency or syntax errors

# 2. Review the package.json
# Ensure all dependencies are compatible

# 3. Try a simpler prompt first
# Build complexity gradually

# 4. Use a better AI model
# Switch from Groq to Claude 3.5 Sonnet

# 5. Export and test locally
npm install
npm run dev
```

**Slow Generation Speed:**

```bash
# 1. Use Groq for faster responses (trade-off: quality)
# Settings → Select Groq → Choose llama-3.1-70b

# 2. Break large requests into smaller prompts
# Instead of: "Build entire app"
# Use: "Build homepage" → "Add API" → "Add auth"

# 3. Check your network connection
# bolt.diy streams responses in real-time

# 4. Monitor resource usage
docker stats bolt
# High CPU? The browser might be struggling with large projects
```

**Cannot Export or Download Code:**

```bash
# 1. Check browser download settings
# Ensure downloads are not blocked

# 2. Try different browser
# Firefox, Chrome, Safari all work differently

# 3. Copy code manually if export fails
# Click on each file → Copy content → Paste to local editor

# 4. Check bolt.diy logs
docker logs bolt | grep -i error
```

### Integration with AI CoreKit Services

**bolt.diy + Supabase:**
- Generate complete CRUD apps with Supabase backend
- Automatic database schema creation
- Real-time subscriptions support
- Auth integration built-in

**bolt.diy + n8n:**
- Export generated APIs as n8n HTTP Request targets
- Build custom UI for n8n workflows
- Create admin dashboards for workflow management

**bolt.diy + Ollama:**
- Use local models for code generation (if Ollama enabled)
- No API costs for development
- Full privacy for sensitive projects

**bolt.diy + ComfyUI:**
- Generate image processing interfaces
- Build custom ComfyUI workflow editors
- Create galleries for generated images

### Resources

- **Official Repository**: [github.com/stackblitz-labs/bolt.diy](https://github.com/stackblitz-labs/bolt.diy)
- **Documentation**: [docs.bolt.new](https://docs.bolt.new) (bolt.new is the hosted version)
- **Community Examples**: Check r/bolt_diy for inspiration
- **Video Tutorials**: Search "bolt.diy tutorial" on YouTube
- **Best Practices**: [github.com/stackblitz-labs/bolt.diy/discussions](https://github.com/stackblitz-labs/bolt.diy/discussions)

### Security Notes

- **No Authentication**: bolt.diy has no built-in auth - protected by Caddy basic auth if configured
- **API Keys**: Never commit API keys to generated code repositories
- **Public Deployment**: Generated apps may contain your prompts - review before sharing
- **Code Review**: Always review AI-generated code before production use
- **Environment Variables**: Use .env files for sensitive configuration
- **HTTPS Only**: Only access bolt.diy via HTTPS to protect API keys in transit
