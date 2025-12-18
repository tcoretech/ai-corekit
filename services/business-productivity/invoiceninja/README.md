### What is Invoice Ninja?

Invoice Ninja is a professional invoicing and payment platform supporting 40+ payment gateways, multi-currency billing, and client portal. It's perfect for freelancers, agencies, and small businesses needing comprehensive billing automation with GDPR compliance.

### Features

- **40+ Payment Gateways:** Stripe, PayPal, Braintree, Square, Authorize.net, and many more
- **Multi-Currency Support:** Bill clients in any currency with automatic conversion
- **Recurring Billing:** Automated subscription and retainer invoicing
- **Client Portal:** Self-service portal for clients to view/pay invoices
- **Expense Tracking:** Convert expenses into billable invoices
- **Native n8n Node:** Seamless integration with n8n workflows

### Initial Setup

**First Login to Invoice Ninja:**

1. Navigate to `https://invoices.yourdomain.com`
2. Login with admin credentials from installation report:
   - **Email:** Your email address (set during installation)
   - **Password:** Check `.env` file for `INVOICENINJA_ADMIN_PASSWORD`
3. Complete initial setup:
   - Company details and logo (Settings → Company Details)
   - Tax rates and invoice customization (Settings → Tax Settings)
   - Payment gateway configuration (Settings → Payment Settings)
   - Email templates (Settings → Email Settings)
   - Invoice number format (Settings → Invoice Settings)

**⚠️ IMPORTANT - APP_KEY:**

- Invoice Ninja requires a Laravel APP_KEY for encryption
- This is automatically generated during installation
- If missing, generate manually:
  ```bash
  docker run --rm invoiceninja/invoiceninja:5 php artisan key:generate --show
  # Add the complete output (including "base64:") to .env as INVOICENINJA_APP_KEY
  ```

**Post-Setup Security:**

After first login, remove these from `.env` for security:
- `IN_USER_EMAIL` environment variable
- `IN_PASSWORD` environment variable

These are only needed for initial account creation.

### n8n Integration Setup

Invoice Ninja has **native n8n node support** for seamless integration!

**Create Invoice Ninja Credentials in n8n:**

1. In n8n, go to Credentials → New → Invoice Ninja API
2. Configure:
   - **URL:** `http://invoiceninja:8000` (internal) or `https://invoices.yourdomain.com` (external)
   - **API Token:** Generate in Invoice Ninja (Settings → Account Management → API Tokens)
   - **Secret** (optional): For webhook validation

**Generate API Token in Invoice Ninja:**

1. Login to Invoice Ninja
2. Settings → Account Management → API Tokens
3. Click "New Token"
4. Name: "n8n Integration"
5. Select permissions (usually "All")
6. Copy token immediately (shown only once!)

**Internal URL for n8n:** `http://invoiceninja:8000`

### Example Workflows

#### Example 1: Automated Invoice Generation from Kimai

```javascript
// Create invoices automatically from tracked time

// 1. Schedule Trigger - Weekly on Friday at 5 PM

// 2. HTTP Request - Get week's time entries from Kimai
Method: GET
URL: http://kimai:8001/api/timesheets
Headers:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Query Parameters:
  begin: {{$now.startOf('week').toISO()}}
  end: {{$now.endOf('week').toISO()}}

// 3. Code Node - Group by customer and format items
const entries = $json;
const byCustomer = {};

entries.forEach(entry => {
  const customerId = entry.project.customer.id;
  const customerName = entry.project.customer.name;
  
  if (!byCustomer[customerId]) {
    byCustomer[customerId] = {
      client_id: customerId,
      client_name: customerName,
      items: [],
      total: 0
    };
  }
  
  const hours = entry.duration / 3600; // Convert seconds to hours
  const rate = entry.hourlyRate || 0;
  const amount = hours * rate;
  
  byCustomer[customerId].items.push({
    product_key: entry.project.name,
    notes: entry.description,
    quantity: hours.toFixed(2),
    cost: rate,
    tax_name1: "VAT",
    tax_rate1: 19 // Adjust for your region
  });
  
  byCustomer[customerId].total += amount;
});

return Object.values(byCustomer);

// 4. Loop Over Customers

// 5. Invoice Ninja Node - Create Invoice
Operation: Create
Resource: Invoice
Fields:
  client_id: {{$json.client_id}}
  line_items: {{$json.items}}
  due_date: {{$now.plus(30, 'days').toISO()}}
  public_notes: "Invoice for week {{$now.week()}}"

// 6. Invoice Ninja Node - Send Invoice
Operation: Send
Resource: Invoice
Invoice ID: {{$('Create Invoice').json.id}}

// 7. Slack Notification
Channel: #invoicing
Message: |
  📄 Invoice created and sent
  
  Client: {{$json.client_name}}
  Amount: €{{$json.total.toFixed(2)}}
  Invoice: {{$('Create Invoice').json.number}}
```

#### Example 2: Payment Reminder Automation

```javascript
// Send automated reminders for overdue invoices

// 1. Schedule Trigger - Daily at 9 AM

// 2. Invoice Ninja Node - Get Overdue Invoices
Operation: Get All
Resource: Invoice
Filters:
  status_id: 2 // Sent
  is_deleted: false

// 3. Code Node - Filter overdue with balance
const invoices = $json;
const today = new Date();

const overdue = invoices.filter(inv => {
  const dueDate = new Date(inv.due_date);
  const balance = parseFloat(inv.balance);
  return dueDate < today && balance > 0;
});

return overdue.map(inv => ({
  ...inv,
  days_overdue: Math.floor((today - new Date(inv.due_date)) / (1000 * 60 * 60 * 24))
}));

// 4. Loop Over Invoices

// 5. IF Node - Check days overdue
Condition: {{$json.days_overdue >= 7}}

// 6. Invoice Ninja Node - Send Reminder
Operation: Send
Resource: Invoice
Invoice ID: {{$json.id}}
Template: reminder1 // or reminder2, reminder3 based on days

// 7. Slack Notification
Channel: #collections
Message: |
  ⚠️ Reminder sent
  
  Invoice: {{$json.number}}
  Client: {{$json.client.name}}
  Amount: €{{$json.balance}}
  Days Overdue: {{$json.days_overdue}}
```

#### Example 3: Stripe Payment Webhook Processing

```javascript
// Handle successful payments automatically

// 1. Webhook Trigger - Stripe payment.succeeded

// 2. Code Node - Extract invoice ID
const invoiceId = $json.body.metadata.invoice_id;
const amount = $json.body.amount / 100; // Convert from cents
const stripeId = $json.body.id;

return {
  invoiceId: invoiceId,
  amount: amount,
  transactionReference: stripeId
};

// 3. Invoice Ninja Node - Get Invoice
Operation: Get
Resource: Invoice
Invoice ID: {{$json.invoiceId}}

// 4. Invoice Ninja Node - Create Payment
Operation: Create
Resource: Payment
Fields:
  invoice_id: {{$json.invoiceId}}
  amount: {{$('Extract').json.amount}}
  payment_date: {{$now.toISO()}}
  transaction_reference: {{$('Extract').json.transactionReference}}
  type_id: 1 // Credit Card

// 5. Send Email - Payment confirmation
To: {{$('Get Invoice').json.client.email}}
Subject: Payment Received - Invoice {{$('Get Invoice').json.number}}
Message: |
  Dear {{$('Get Invoice').json.client.name}},
  
  We have received your payment of €{{$('Extract').json.amount}}.
  
  Invoice: {{$('Get Invoice').json.number}}
  Transaction: {{$('Extract').json.transactionReference}}
  
  Thank you for your business!

// 6. Slack Notification
Channel: #payments
Message: |
  💰 Payment received!
  
  Client: {{$('Get Invoice').json.client.name}}
  Amount: €{{$('Extract').json.amount}}
  Invoice: {{$('Get Invoice').json.number}}
```

#### Example 4: Expense to Invoice Conversion

```javascript
// Convert approved expenses into client invoices

// 1. Invoice Ninja Webhook Trigger - expense.approved
// Or Schedule Trigger to check for new approved expenses

// 2. Invoice Ninja Node - Get Expense
Operation: Get
Resource: Expense
Expense ID: {{$json.id}}

// 3. Invoice Ninja Node - Get Client
Operation: Get
Resource: Client
Client ID: {{$json.client_id}}

// 4. Invoice Ninja Node - Create Invoice from Expense
Operation: Create
Resource: Invoice
Fields:
  client_id: {{$json.client_id}}
  line_items: [{
    product_key: "EXPENSE",
    notes: "{{$('Get Expense').json.public_notes}}",
    quantity: 1,
    cost: {{$('Get Expense').json.amount}},
    tax_name1: "VAT",
    tax_rate1: 19
  }]
  public_notes: "Reimbursable expense from {{$('Get Expense').json.date}}"

// 5. Invoice Ninja Node - Mark Expense as Invoiced
Operation: Update
Resource: Expense
Expense ID: {{$('Get Expense').json.id}}
Fields:
  invoice_id: {{$('Create Invoice').json.id}}
  should_be_invoiced: false

// 6. Invoice Ninja Node - Send Invoice
Operation: Send
Resource: Invoice
Invoice ID: {{$('Create Invoice').json.id}}
```

#### Example 5: Recurring Invoice Monitoring

```javascript
// Monitor and alert on recurring invoice issues

// 1. Schedule Trigger - Daily at 8 AM

// 2. Invoice Ninja Node - Get Recurring Invoices
Operation: Get All
Resource: Recurring Invoice
Filters:
  status_id: 2 // Active

// 3. Code Node - Check for issues
const recurring = $json;
const issues = [];

recurring.forEach(inv => {
  // Check if next send date is in past (failed to send)
  const nextSend = new Date(inv.next_send_date);
  const today = new Date();
  
  if (nextSend < today && inv.auto_bill === 'always') {
    issues.push({
      client: inv.client.name,
      invoice: inv.number,
      issue: 'Failed to auto-bill',
      nextSend: inv.next_send_date
    });
  }
  
  // Check if payment method expired
  if (inv.client.gateway_tokens?.length === 0) {
    issues.push({
      client: inv.client.name,
      invoice: inv.number,
      issue: 'No payment method on file'
    });
  }
});

return issues;

// 4. IF Node - Check if issues exist
Condition: {{$json.length > 0}}

// 5. Slack Alert
Channel: #billing-issues
Message: |
  ⚠️ Recurring Invoice Issues Detected
  
  {{#each $json}}
  - {{this.client}}: {{this.issue}} (Invoice: {{this.invoice}})
  {{/each}}
```

### Payment Gateway Configuration

Invoice Ninja supports 40+ payment gateways. Most popular:

**Stripe Setup:**

1. Settings → Payment Settings → Configure Gateways
2. Select Stripe → Configure
3. Add API keys from Stripe Dashboard
4. Enable payment methods (Cards, ACH, SEPA, etc.)
5. Configure webhook: `https://invoices.yourdomain.com/stripe/webhook`
6. In Stripe Dashboard, add webhook URL and select events

**PayPal Setup:**

1. Settings → Payment Settings → Configure Gateways
2. Select PayPal → Configure
3. Add Client ID and Secret from PayPal Developer
4. Set return URL: `https://invoices.yourdomain.com/paypal/completed`
5. Test in sandbox mode first

**Webhook Security:**

- Each gateway provides webhook endpoints
- Use webhook secrets for validation in n8n
- Test with Stripe CLI or PayPal sandbox first

### Client Portal Features

The client portal allows customers to:

- View and pay invoices online
- Download invoices and receipts as PDF
- View payment history
- Update contact information
- Approve quotes
- Access without separate registration (magic link)

**Portal URL:** `https://invoices.yourdomain.com/client/login`

**Customization:**

1. Settings → Client Portal
2. Enable/disable features
3. Customize terms and privacy policy
4. Set payment methods available to clients
5. Upload custom logo and colors

### Advanced API Usage

For operations not in the native node, use HTTP Request:

```javascript
// Bulk invoice actions
Method: POST
URL: http://invoiceninja:8000/api/v1/invoices/bulk
Headers:
  X-API-TOKEN: {{$credentials.apiToken}}
  Content-Type: application/json
Body: {
  "ids": [1, 2, 3],
  "action": "send" // or "download", "archive", "delete"
}

// Custom reports
Method: GET
URL: http://invoiceninja:8000/api/v1/reports/clients
Headers:
  X-API-TOKEN: {{$credentials.apiToken}}
Query: {
  "date_range": "this_year",
  "report_keys": ["name", "balance", "paid_to_date"]
}

// Recurring invoice management
Method: POST
URL: http://invoiceninja:8000/api/v1/recurring_invoices
Headers:
  X-API-TOKEN: {{$credentials.apiToken}}
Body: {
  "client_id": 1,
  "frequency_id": 4, // Monthly
  "auto_bill": "always",
  "line_items": {{$json.items}}
}
```

### Multi-Language & Localization

Invoice Ninja supports 30+ languages:

```javascript
// Set invoice language per client
Invoice Ninja Node: Update Client
Fields: {
  settings: {
    language_id: "2", // German (de)
    currency_id: "2", // EUR
    country_id: "276" // Germany
  }
}
```

**Available Languages:** English, German, French, Spanish, Italian, Dutch, Portuguese, and 20+ more

### Migration from Other Systems

Invoice Ninja can import from:

- QuickBooks
- FreshBooks
- Wave
- Zoho Invoice
- CSV files

**Import Process:**

1. Settings → Import
2. Select source system
3. Upload export file
4. Map fields
5. Review and confirm

### Troubleshooting

**500 Internal Server Error:**

```bash
# 1. Run database migrations
docker exec invoiceninja php artisan migrate --force

# 2. Clear cache
docker exec invoiceninja php artisan optimize:clear
docker exec invoiceninja php artisan optimize

# 3. Check logs
docker logs invoiceninja --tail 100

# 4. Check .env file
docker exec invoiceninja cat .env | grep APP_KEY
# Should show: APP_KEY=base64:...
```

**PDFs not generating:**

```bash
# 1. Check PDF generator
docker exec invoiceninja php artisan ninja:check-pdf

# 2. Test Chromium (default PDF generator)
docker exec invoiceninja which chromium-browser

# 3. If issues persist, switch to PhantomJS
# In .env: PDF_GENERATOR=phantom

# 4. Restart container
docker compose restart invoiceninja
```

**Email delivery issues:**

```bash
# 1. Test mail configuration
docker exec invoiceninja php artisan tinker
>>> Mail::raw('Test', function($m) { $m->to('test@example.com')->subject('Test'); });

# 2. Check mail settings in .env
docker exec invoiceninja env | grep MAIL

# 3. Check Mailpit/Docker-Mailserver logs
docker logs mailpit --tail 50
# or
docker logs mailserver --tail 50

# 4. Verify SMTP credentials
```

**API returns 401 Unauthorized:**

```bash
# 1. Verify API token
# Login to Invoice Ninja → Settings → API Tokens

# 2. Check token permissions

# 3. Test API connection
curl -H "X-API-TOKEN: YOUR_TOKEN" \
  http://invoiceninja:8000/api/v1/clients

# 4. Regenerate token if needed
```

**Database connection errors:**

```bash
# 1. Check MySQL container
docker ps | grep invoiceninja_db

# 2. Test database connection
docker exec invoiceninja_db mysql -u invoiceninja \
  -p${INVOICENINJA_DB_PASSWORD} invoiceninja -e "SHOW TABLES;"

# 3. Check .env database settings
docker exec invoiceninja env | grep DB

# 4. Restart both containers
docker compose restart invoiceninja_db invoiceninja
```

### Tips for Invoice Ninja + n8n Integration

**Best Practices:**

1. **Use Internal URLs:** From n8n, use `http://invoiceninja:8000` (faster, no SSL overhead)
2. **API Rate Limits:** Default 300 requests per minute - add delays for bulk operations
3. **Webhook Events:** Enable in Settings → Account Management → Webhooks
4. **PDF Generation:** Uses Chromium internally, may need 1-2 seconds per invoice
5. **Currency Handling:** Always specify currency_id for multi-currency setups
6. **Tax Calculations:** Configure tax rates before creating invoices
7. **Backup:** Regular database backups recommended for financial data

**Common Automation Patterns:**

- Time tracking → Invoice generation
- Payment received → Update accounting software
- Overdue invoices → Escalating reminders
- Expense approval → Client billing
- Recurring invoices → Payment retry logic
- Invoice created → Add to CRM pipeline

**Data Security:**

- APP_KEY encrypts sensitive data
- Regular database backups essential
- Use strong API tokens
- Webhook signature validation
- GDPR-compliant data handling

### Performance Optimization

For large-scale operations:

```yaml
# Increase PHP memory in docker-compose.yml
environment:
  - PHP_MEMORY_LIMIT=512M
  
# Enable Redis caching (already configured)
  - CACHE_DRIVER=redis
  - SESSION_DRIVER=redis
  - QUEUE_CONNECTION=redis
```

**Queue Processing:**

- Invoice Ninja uses queues for emails and PDFs
- Monitor with: `docker exec invoiceninja php artisan queue:work --stop-when-empty`
- For production: Set up queue worker as daemon

### Resources

- **Documentation:** https://invoiceninja.github.io/
- **API Reference:** https://api-docs.invoicing.co/
- **Forum:** https://forum.invoiceninja.com/
- **GitHub:** https://github.com/invoiceninja/invoiceninja
- **YouTube:** [Invoice Ninja Channel](https://www.youtube.com/channel/UCXjmYgQdCTpvHZSQ0x6VFRA)
- **n8n Node Docs:** Search "Invoice Ninja" in n8n node library
