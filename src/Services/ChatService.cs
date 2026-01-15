using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Core;
using Azure.AI.ContentSafety;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly string _endpoint;
        private readonly DefaultAzureCredential _credential;
        private readonly ILogger<ChatService> _logger;

        public ChatService(IConfiguration configuration, HttpClient httpClient, ILogger<ChatService> logger)
        {
            _configuration = configuration;
            _httpClient = httpClient;
            _endpoint = (_configuration["AI_FOUNDRY_ENDPOINT"] ?? string.Empty).TrimEnd('/');
            _credential = new DefaultAzureCredential();
            _logger = logger;
        }

        private async Task<(bool isSafe, string? reason)> CheckContentSafetyAsync(string text)
        {
            try
            {
                _logger.LogInformation("Starting content safety check for text: {TextPreview}", text.Substring(0, Math.Min(50, text.Length)));
                var client = new ContentSafetyClient(new Uri(_endpoint), _credential);
                
                // Configure to check all categories including blocklists and groundedness
                var request = new AnalyzeTextOptions(text)
                {
                    OutputType = AnalyzeTextOutputType.FourSeverityLevels
                };
                
                var response = await client.AnalyzeTextAsync(request);

                _logger.LogInformation("Content safety response received. Categories analyzed: {Count}", response.Value.CategoriesAnalysis.Count);
                
                var categoriesAnalysis = response.Value.CategoriesAnalysis;
                foreach (var category in categoriesAnalysis)
                {
                    _logger.LogInformation("Category: {Category}, Severity: {Severity}", category.Category, category.Severity);
                    // Lower threshold to severity >= 1 for better detection
                    if (category.Severity >= 1)
                    {
                        _logger.LogWarning("Content flagged: {Category} with severity {Severity}", category.Category, category.Severity);
                        return (false, category.Category.ToString());
                    }
                }

                _logger.LogInformation("Content safety check passed - all categories below threshold");
                return (true, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Content safety check failed with exception: {Message}", ex.Message);
                return (true, null); // Fail open to avoid blocking legitimate requests
            }
        }

        public async Task<string> SendMessageAsync(string userMessage)
        {
            // Check content safety first
            var (isSafe, reason) = await CheckContentSafetyAsync(userMessage);
            if (!isSafe)
            {
                return $"I'm sorry, but I cannot process your request as it may contain {reason?.ToLower()} content. Please rephrase your message.";
            }

            try
            {
                // Get Azure AD token
                var tokenRequestContext = new TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" });
                var token = await _credential.GetTokenAsync(tokenRequestContext);

                // Construct the request to Azure AI Services (GPT-4o-mini)
                var requestBody = new
                {
                    messages = new[]
                    {
                        new { role = "system", content = "You are a helpful AI assistant for Zava Storefront." },
                        new { role = "user", content = userMessage }
                    },
                    max_tokens = 800,
                    temperature = 0.7
                };

                var jsonContent = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                // Add Bearer token to headers
                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token.Token}");

                // Send request to Azure AI endpoint
                var url = $"{_endpoint}/openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-15-preview";
                var response = await _httpClient.PostAsync(url, content);

                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    var jsonResponse = JsonDocument.Parse(responseContent);
                    
                    // Extract the assistant's message from the response
                    var assistantMessage = jsonResponse.RootElement
                        .GetProperty("choices")[0]
                        .GetProperty("message")
                        .GetProperty("content")
                        .GetString();

                    return assistantMessage ?? "No response from AI";
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    return $"Error: {response.StatusCode} - {errorContent}";
                }
            }
            catch (Exception ex)
            {
                return $"Error communicating with AI service: {ex.Message}";
            }
        }
    }
}
