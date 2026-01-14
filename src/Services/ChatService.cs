using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Core;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly string _endpoint;
        private readonly DefaultAzureCredential _credential;

        public ChatService(IConfiguration configuration, HttpClient httpClient)
        {
            _configuration = configuration;
            _httpClient = httpClient;
            _endpoint = (_configuration["AI_FOUNDRY_ENDPOINT"] ?? string.Empty).TrimEnd('/');
            _credential = new DefaultAzureCredential();
        }

        public async Task<string> SendMessageAsync(string userMessage)
        {
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
